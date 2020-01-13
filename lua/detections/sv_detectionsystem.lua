LAC = LAC or {}

include("infoprocessing/sv_playerprocessing.lua")

-- gmsv_lacutil_win32.dll or gmsv_lacutil_linux.dll
require("lacutil")

-- We will be adding many more network strings in the future, as well as dynamic ones.
util.AddNetworkString( "LACData" )
util.AddNetworkString( "LACDataC" )
util.AddNetworkString( "LACHeart" )
util.AddNetworkString( "LACMisc" ) 
util.AddNetworkString( "LACSpec" ) 
util.AddNetworkString( "LACH" )
util.AddNetworkString( "LACTS" )
util.AddNetworkString( "ULX_PSD" )
util.AddNetworkString( "LACDD" )
util.AddNetworkString( "LACKeyB" )
util.AddNetworkString( "LACBC" )
util.AddNetworkString( "LACCI" ) -- catchidiots
util.AddNetworkString( "LACHB" ) -- heartbeat

--[[ 
	All server-side detections will probably remain in this file for ease of reading,
	 and splitting them into different files is most likely pointless.
]]

--[[
	Following 2 detections is from CAC almost C&P
	Edited/tinkered with as I think is neccesary, because ya
	update: lots stolen from CAC tl;dr

	UPDATE2: not very reliable. removed temporarily.


local math_deg = math.deg
local math_acos = math.acos
local math_min = math.min
local math_abs = math.abs
local SysTime = SysTime
local table_insert = table.insert

function LAC.AimbotSnap(ply, moveData, CUserCmd)
	if (!ply:IsValid()) then return end
	if (!ply:IsPlayer()) then return end
	local pTable = LAC.GetPTable(ply);
	if (pTable == nil) then return end
	if (ply:Health() <= 0 or not ply:Alive() or ply:Team() == TEAM_SPECTATOR) then return end
	
	local angles  = moveData:GetAngles()
	local forward = angles:Forward()
	
	-- CMoveData:GetAngles () doesn't catch context menu aiming
	local eyeTrace = ply:GetEyeTrace()
	forward = eyeTrace.HitPos - eyeTrace.StartPos
	forward:Normalize()
	
	if (pTable.PreviousAngles && pTable.PreviousForward) then
		local deltaAngle = math_deg(math_acos(math_min(math_abs(forward:Dot (pTable.PreviousForward)), 1)))
		
		if (deltaAngle > 0.05) then
			table_insert(pTable.DeltaAngleValues, deltaAngle)
		end
		
		if (pTable.PreviousDAngle) then
			local deltaDeltaAngle = math_abs(deltaAngle - pTable.PreviousDAngle)
			
			if (deltaDeltaAngle > 0.05) then
				local ddSize = #pTable.DDeltaAngleValues
				table_insert(pTable.DDeltaAngleValues, deltaDeltaAngle)
				
				if (ddSize) >= 180 && deltaDeltaAngle > getMean(pTable.DDeltaAngleValues) + 4 * stDev(pTable.DDeltaAngleValues) then -- confidence interval check
					pTable.LastSnapEventTime = SysTime()
					pTable.LastSnapDDAngle = deltaDeltaAngle
				end
			end
		end
		
		pTable.PreviousDAngle = deltaAngle
	end

	pTable.PreviousAngles  = angles
	pTable.PreviousForward = forward
end

function LAC.WasHitByExplosive(target, dmginfo)
	if (IsValid(target) && target:IsPlayer() && dmginfo:IsExplosionDamage()) then
		local pTable = LAC.GetPTable(target);
		if (pTable == nil) then return end

		pTable.HitByExplosive = true
	end
end

-- victim, inflictor, attacker
function LAC.AimbotPlayerKill(victim, inflictor, attacker)
	if (!victim:IsValid() || !attacker:IsValid()) then return end
	if (!victim:IsPlayer() || !attacker:IsPlayer()) then return end

	local pTable = LAC.GetPTable(attacker);
	if (pTable == nil) then return end

	if (victim == attacker) then return end
	
	if (pTable.LastSnapEventTime && (SysTime() - pTable.LastSnapEventTime < 0.20) && !pTable.HitByExplosive) then
		local name = victim:GetClass()
		if (victim:IsPlayer()) then
			name = victim:GetName()
		end
		--attacker:ChatPrint("detec")
		-- This is not very accurate, since projectiles trigger it :/
		local DetectionString = string.format("LAC has detected a player snapping " .. string.format("%.2f", pTable.LastSnapDDAngle) .. " degrees towards " .. name .. ". PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, attacker)
	end
end
]]

local _R_CUserCmd_KeyDown  = debug.getregistry().CUserCmd.KeyDown
local _R_Entity_IsOnGround = debug.getregistry().Entity.IsOnGround

function LAC.ResetBhopValues(ply)
	local pTable = LAC.GetPTable(ply);
	pTable.BhopDetection.PerfectJump = 0
	pTable.BhopDetection.JumpCounter2 = 0
	for i = #pTable.BhopDetection.TickTable, 1, -1 do
		pTable.BhopDetection.TickTable[i] = nil
	end
end

function LAC.BhopDetector(ply, moveData, CUserCmd)
	if (!ply:IsValid()) then return end
	if (!ply:IsPlayer()) then return end
	local pTable = LAC.GetPTable(ply);
	if (pTable == nil) then return end
	if (ply:Health() <= 0 or not ply:Alive() or ply:Team() == TEAM_SPECTATOR) then return end
	
	local PreviouslyOnGround = pTable.BhopDetection.OnGround
	local WasInJump	= pTable.BhopDetection.InJump
	
	local CurrentlyOnGround = _R_Entity_IsOnGround(ply)
	local CurrentlyInJump   = _R_CUserCmd_KeyDown(CUserCmd, IN_JUMP)
	
	if (PreviouslyOnGround && !CurrentlyOnGround) then
		pTable.BhopDetection.JumpCounter2 = 0
	elseif (!PreviouslyOnGround && CurrentlyOnGround) then -- If I just landed (Not on ground, but now I am)
		if (!WasInJump && CurrentlyInJump) then -- And pressed +jump the instant I landed (I didnt press +jump, now I am)
			pTable.BhopDetection.PerfectJump = pTable.BhopDetection.PerfectJump + 1

			if (pTable.BhopDetection.PerfectJump > 14 && pTable.BhopDetection.InformedAdmins < pTable.BhopDetection.InformedAdminsMax) then
				local a, b, c = 0, 0, 0
				for i = 1, #pTable.BhopDetection.TickTable do
					local x = pTable.BhopDetection.TickTable[i]
					a = a + 1 -- iterations
					b = b + x
					c = c + x * x
				end

				local consistency = (c - b * b / a) / a

				if (consistency < 0.6) then
					pTable.BhopDetection.InformedAdmins = pTable.BhopDetection.InformedAdmins + 1
					local pattern = ""
					for k, v in ipairs(pTable.BhopDetection.JumpHistory) do
						pattern = pattern .. v
					end

					-- LAC.PlayerDetection(reasonDetected, detectValue, ply, tellAdmins, additionalLog)
					local DetectionString = string.format("Detected %s jumping perfectly %i times in a row!", pTable.pInfo.Name, pTable.BhopDetection.PerfectJump);
					LAC.PlayerDetection(DetectionString, LAC.DetectionValue.UNLIKELY_FALSE, ply, true, pattern .. " C:" .. tostring(consistency))
				end
			end
		else
			LAC.ResetBhopValues(ply)
		end
	elseif (CurrentlyOnGround) then
		if (WasInJump ~= CurrentlyInJump) then
			LAC.ResetBhopValues(ply)
		end
	end

	if (!CurrentlyOnGround && WasInJump && !CurrentlyInJump && pTable.BhopDetection.JumpCounter2 >= 0) then
		pTable.BhopDetection.TickTable[#pTable.BhopDetection.TickTable + 1] = pTable.BhopDetection.JumpCounter2
		pTable.BhopDetection.JumpCounter2 = -math.huge
	end
	
	local instantPattern = ""
	if (CurrentlyInJump) then
		instantPattern = "+"
	else
		instantPattern = "-"
	end
	if (CurrentlyOnGround) then
		instantPattern = "(" .. instantPattern .. ")"
	end

	table.insert(pTable.BhopDetection.JumpHistory, instantPattern)
	if (#pTable.BhopDetection.JumpHistory > 98) then
		table.remove(pTable.BhopDetection.JumpHistory, 1)
	end

	pTable.BhopDetection.JumpCounter2 = pTable.BhopDetection.JumpCounter2 + 1
	
	pTable.BhopDetection.OnGround = CurrentlyOnGround
	pTable.BhopDetection.InJump   = CurrentlyInJump
end

function LAC.StartCommand(ply, CUserCmd)
	if (!IsValid(ply)) then return end
	if (ply:IsBot()) then return end -- fk off bot >:(
	if (CUserCmd:IsForced()) then return end
	if (ply:Health() <= 0 or not ply:Alive() or ply:Team() == TEAM_SPECTATOR) then return end

	local pTable = LAC.GetPTable(ply);
	if (pTable == nil) then 
		LAC.InitializePlayerTable(ply) -- Just incase the AC runs after someone has already joined.
		pTable = LAC.GetPTable(ply);
	end

	--[[
	Notes from Nick:
		move name info set to a diff hook. this is called too often.
		pass by ref since tables in lua are passed by ref
		initialize ptable to nil -> possibly not worth. currently decided against.
		cannot merge all hooks due to organization. Either redo organization or decide against it. Probably former.

	]]

	pTable.pInfo.Name = ply:Name()

	if (LAC.IsTTT()) then
		LAC.CheckContextMenu(ply, CUserCmd);
		LAC.CheckMovement(ply, CUserCmd)
	end
	LAC.CheckEyeAngles(ply, CUserCmd); -- idk, being safe.

	--[[
		Havent done anything with this function yet
			TODO: 
			//Aimbot check
			triggerbot check
			//bhop check
			spamming check
	]]
end

function LAC.CheckContextMenu(ply, CUserCmd)
	local pTable = LAC.GetPTable(ply)
	local ContextMenuIsOpen = IsInContextMenu(CUserCmd)

	if (ContextMenuIsOpen) then -- F
		local DetectionString = string.format("Detected %s using context menu!", pTable.pInfo.Name);
		LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
	end
end

--[[
	Directly ripped from CInput::ClampAngles.
	Afterall, if they dont even clamp their angles, they're probably really bad cheaters, frankly.
	update: This somehow detects idiots, so now I'm lead to believe people are fucking setting pitch to 350 on the server or some shit.

	update2: --following code is from GrandpaTroll because apparently antiaim does things differently, idk why.
	eee
]]

function LAC.CheckEyeAngles(ply, CUserCmd)
	local pTable = LAC.GetPTable(ply)
	local viewangles = CUserCmd:GetViewAngles();

	--Game engine will send 0-360 for angles (Don't ask why.)
	if (viewangles.pitch > 180) then
		viewangles.pitch = viewangles.pitch - 360
	end

    if (math.abs(viewangles.pitch) > 90 && pTable.AngleDetection.InformedAdmins < pTable.AngleDetection.InformedAdminsMax) then
		local DetectionString = string.format("Detected %s with a pitch of %f! Possibly using anti-aim!", pTable.pInfo.Name, viewangles.pitch);
		LAC.PlayerDetection(DetectionString, LAC.DetectionValue.UNLIKELY_FALSE, ply, true)
    end
end

--[[
	Credit mostly to leystryku for his ideas and 
	such for movechecking n shit.

	Look @ CInput::ComputeSideMove/Forward move and you can see what values are valid
	This will detect controller users, but through some testing/looking shit up,
	controller users are almost completely non-existing

	Buuut, just to be safe, we will make sure to check if they're using a controller and prevent the detection from happening 
	if they are.
]]
-- Internally these are floats, but if you're setting your cl_forwardmove to 450.4 you're kinda dumb
-- TODO: move the following code below into a helper function where I just call IsPossibleMoveValue(int)
local maxSideMove = GetConVar("cl_sidespeed"):GetInt()
local maxForwardMove = GetConVar("cl_forwardspeed"):GetInt()
local maxUpMove = GetConVar("cl_upspeed"):GetInt()

local possibleFValues = {}
possibleFValues[maxForwardMove * 0.25] = true
possibleFValues[maxForwardMove * 0.5] = true
possibleFValues[maxForwardMove * 0.75] = true
possibleFValues[maxForwardMove] = true
	
local possibleSValues = {}
possibleSValues[maxSideMove * 0.25] = true
possibleSValues[maxSideMove * 0.5] = true
possibleSValues[maxSideMove * 0.75] = true
possibleSValues[maxSideMove] = true

local possibleUValues = {}
possibleUValues[maxUpMove * 0.25] = true
possibleUValues[maxUpMove * 0.5] = true
possibleUValues[maxUpMove * 0.75] = true
possibleUValues[maxUpMove] = true


function LAC.CheckMovement(ply, CUserCmd)

	-- Original values
	local upmove = CUserCmd:GetUpMove()
	local sidemove = CUserCmd:GetSideMove()
	local forwardmove = CUserCmd:GetForwardMove()
	-- Absolute values
	local upmoveAbs = math.abs( upmove )
	local sidemoveAbs = math.abs( sidemove)
	local forwardmoveAbs = math.abs( forwardmove )
	-- yey buttons
	local buttons = CUserCmd:GetButtons();
	-- playerinfo table
	local pTable = LAC.GetPTable(ply)
	local commandNumber = CUserCmd:CommandNumber()

	-- Not moving.
	if (upmoveAbs == 0 && sidemoveAbs == 0 && forwardmoveAbs == 0) then return end

	-- If fmove is greater than max fmove
	if (forwardmoveAbs > maxForwardMove) then
		local DetectionString = string.format("Detected %s with >improper movement! fMove= %f", pTable.pInfo.Name, forwardmove);
		LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
	end

	-- If smove is greater than max smove
	if (sidemoveAbs > maxSideMove) then
		local DetectionString = string.format("Detected %s with >improper movement! sMove= %f", pTable.pInfo.Name, sidemove);
		LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
	end

	-- If upmove is greater than ... well, 0. It shouldnt be above 0.
	-- update: apparently you can actually trigger this by doing +moveup jesus christ
	if (upmoveAbs > maxUpMove) then
		local DetectionString = string.format("Detected %s with >improper movement! uMove= %f", pTable.pInfo.Name, upmove);
		LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
	end

	--if (pTable.pInfo.UsesController == true) then return end
	-- itll write into the logs if they're using one, so I'd rather log results regardless, rather then prevent further detections.

	if (forwardmove != 0) then

		if (possibleFValues[forwardmoveAbs] == nil) then
			local debugInfolol = string.format("PacketLoss: %f Ping: %f MoveType: %i Buttons: %i Flags: %i", ply:PacketLoss(), ply:Ping(), ply:GetMoveType(), buttons, ply:GetFlags())
			local DetectionString = string.format("Detected %s with improper movement! fMove= %f", pTable.pInfo.Name, forwardmove);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.ANOMALY, ply, false, debugInfolol)
		end

			--[[
			// not 100% reliable unfortunately.
		if (forwardmove > 0 && !LAC.IsButtonDown(buttons, IN_FORWARD)) then 
			local DetectionString = string.format("LAC has detected a player with improper movement! No fbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

		if (forwardmove < 0 && !LAC.IsButtonDown(buttons, IN_BACK)) then 
			local DetectionString = string.format("LAC has detected a player with improper movement! No bbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end
		]]

	end

	if (sidemove != 0) then
		if (possibleSValues[sidemoveAbs] == nil) then
			local debugInfolol = string.format("PacketLoss: %f Ping: %f MoveType: %i Buttons: %i Flags: %i", ply:PacketLoss(), ply:Ping(), ply:GetMoveType(), buttons, ply:GetFlags())
			local DetectionString = string.format("Detected %s with improper movement! sMove= %f", pTable.pInfo.Name, sidemove);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.ANOMALY, ply, false, debugInfolol)
		end

		--[[
			// not 100% reliable unfortunately.
		if (sidemove > 0 && !LAC.IsButtonDown(buttons, IN_MOVERIGHT)) then
			local DetectionString = string.format("LAC has detected a player with improper movement! No rbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

		if (sidemove < 0 && !LAC.IsButtonDown(buttons, IN_MOVELEFT)) then
			local DetectionString = string.format("LAC has detected a player with improper movement! No lbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end]]

	end

	if (upmove != 0) then
		if (possibleUValues[upmoveAbs] == nil) then
			local debugInfolol = string.format("PacketLoss: %f Ping: %f MoveType: %i Buttons: %i Flags: %i", ply:PacketLoss(), ply:Ping(), ply:GetMoveType(), buttons, ply:GetFlags())
			local DetectionString = string.format("Detected %s with improper movement! uMove= %f", pTable.pInfo.Name, upmove);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.ANOMALY, ply, false, debugInfolol)
		end
	end

	if (CUserCmd:KeyDown(IN_BULLRUSH)) then
		local DetectionString = string.format("Detected %s with IN_BULLRUSH down!", pTable.pInfo.Name);
		LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
	end

end

--[[
Note:
Joystick starts @ 114 and ends @ 161.
]]

function LAC.ControllerQuestion(ply)
	if ( !IsValid(ply) or ply:IsBot() ) then return end

	local chosenCvar = "joystick"
	local chosenCvarString = "cvars.String(\"" .. chosenCvar .. "\")" -- jesus christ 

	local challengeCode = 
	[[
	net.Start("LACH")
		net.WriteString("]] .. chosenCvar .. [[")
		net.WriteString(]] .. chosenCvarString .. [[)
	net.SendToServer()
	]]

	--print(challengeCode)
	ply:SendLua(challengeCode)
end

function LAC.ReceiveJoystick(len, ply)
	if ( IsValid( ply ) and ply:IsPlayer() ) then
		local cvarName = net.ReadString()
		local cvarData = net.ReadString()
		
		local plyName = ply:Name()
		local plyID = ply:SteamID()

		local pTable = LAC.GetPTable(ply)
		if (!pTable) then return end
		
		if (cvarName == nil or cvarData == nil) then 
			LAC.LogClientError("LAC has detected a malformed cvar message! Cvar= " .. cvarName .. " = " ..  cvarData .. " PlayerName: " .. plyName .. " SteamID: " .. plyID, player)
			return
		end

		if (tonumber(cvarData) == 1 && !pTable.pInfo.UsesController) then
			pTable.pInfo.UsesController = true;
			local DetectionString = string.format("%s uses a controller! ConvarCheck", pTable.pInfo.Name);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.LOGGING_PURPOSES, ply, false)
			return
		end
		
	end
end
net.Receive("LACH", LAC.ReceiveJoystick)

-- bad heartbeat that verifies somethin' is being sent.
function LAC.ReceiveHeartBeat(len, ply)
	if ( IsValid( ply ) && ply:IsPlayer() && LAC.IsTTT()) then
		
		local pTable = LAC.GetPTable(ply)
		if (!pTable) then return end
		local value = net.ReadString()

		if (value != "false") then
			local DetectionString = string.format("Detected %s with a HB value of: %s", pTable.pInfo.Name, value);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
		end

		pTable.HeartBeatInfo.RespondedTimer = 0
	end
end
net.Receive("LACHB", LAC.ReceiveHeartBeat)

--[[
	Warning, if the timer on this and the timer on the client-side LACHB timer is different, you will kick people. dont do this.
]]
function LAC.KeepHeartBeat()
	if (!LAC.IsTTT()) then return end

	local plys = player.GetHumans()
	for k, v in ipairs(plys) do
		if ( IsValid( v ) && v:IsPlayer() ) then
			local pTable = LAC.GetPTable(v)
			if (!pTable) then return end

			if (pTable.HeartBeatInfo.RespondedTimer > 8) then
				local DetectionString = string.format("Detected %s not responding to HB.", pTable.pInfo.Name);
				LAC.PlayerDetection(DetectionString, LAC.DetectionValue.SUSPICIOUS, v, false)
				v:Kick("LAC")
			end

			pTable.HeartBeatInfo.RespondedTimer = pTable.HeartBeatInfo.RespondedTimer + 1
		end
	end
end
timer.Create("LAC_HEARTBEAT_CHECKER", 30, 0, LAC.KeepHeartBeat)

--[[
client-side portion that i'd send

local smc = {}
hook.Add("CreateMove", "Mouse_Click", function(cmd)
	local cmd = cmd:CommandNumber()
	if (cmd == 0) then return end
	if (smc[cmd] != nil) then
		net.Start("ULX_PSD")
		net.SendToServer()
	end
	smc[cmd] = 0
end)

hook.Add("SetupMove", "LiquidPhysics", function(ply, mv, cmd)
	if (cmd:CommandNumber() == 0) then return end
	smc[cmd:CommandNumber()] = true
end)
]]

function LAC.ReceiveEnginePred(len, ply)
	if ( IsValid( ply ) && ply:IsPlayer() ) then
		
		local pTable = LAC.GetPTable(ply)
		if (!pTable) then return end
		
		local DetectionString = string.format("Detected %s with out-of-order SM!", pTable.pInfo.Name);
		LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
	end
end
net.Receive("ULX_PSD", LAC.ReceiveEnginePred)

local keyTable = 
{
	[72] = "INSERT",
	[73] = "DELETE",
	[74] = "HOME",
	[75] = "END",
	[76] = "PAGEUP",
	[77] = "PAGEDOWN"
}

-- smh
function LAC.CheckKeyPresses(ply, button)
	if (!IsValid(ply)) then return end
	if (ply:IsBot()) then return end -- pretty sure bots dont trigger this but whatever

	local pTable = LAC.GetPTable(ply)
	if (!pTable) then return end

	if (button >= 72 && button <= 77) then
		if (ply:GetAbsVelocity():IsZero()) then
			if (pTable.KeyData.SuspiciousKeyUsage < 3) then

				net.Start("LACKeyB")
				net.WriteInt(button, 32)
				net.Send(ply)

				pTable.KeyData.SuspiciousKeyUsage = pTable.KeyData.SuspiciousKeyUsage + 1

				timer.Simple( 180, function()
					if (pTable.KeyData.SuspiciousKeyUsage > 0) then
						pTable.KeyData.SuspiciousKeyUsage = pTable.KeyData.SuspiciousKeyUsage - 1
					end
				end)

				local DetectionString = string.format("Detected %s pressing suspicious key (%s)!", pTable.pInfo.Name, keyTable[button]);
				LAC.PlayerDetection(DetectionString, LAC.DetectionValue.SUSPICIOUS, ply, false)
			end
		end
		-- Possibly opening a menu, the velocity is because if someone is in menu, they wouldnt be moving (since 99% of menus prevent other keys from being pressed)
	end
		
	if (!pTable.pInfo.UsesController) then
		if (button >= 114 && button <= 161) then 
			pTable.pInfo.UsesController = true;
			local DetectionString = string.format("%s uses a controller! ButtonPressed: %i", pTable.pInfo.Name, button);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.LOGGING_PURPOSES, ply, false)
		end
	end
end

local OkayKeys =
{
	"+voicerecord",
	"ttt_toggle_disguise",
	"kill", -- yeah i literally saw someone bind DELETE to kill. lmao
	"toggleconsole",
}

function LAC.ReceiveBindInfo(len, ply)
	if ( IsValid( ply ) && ply:IsPlayer() ) then
		local pTable = LAC.GetPTable(ply)
		if (!pTable) then return end
		local bindStr = net.ReadString()

		if (table.HasValue(OkayKeys, bindStr)) then return end

		if (pTable.KeyData.SuspiciousKeyUsage < 4) then
			local DetectionString = string.format("Detected %s pressing a suspicious key binded to: (%s)!", pTable.pInfo.Name, bindStr);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.SUSPICIOUS, ply, true)
		end
	end
end
net.Receive("LACKeyB", LAC.ReceiveBindInfo)

--[[
	This is a debug ban im implementing while im on the server. TL;DR this will ban someone for cheating when I call it. 
	For security purposes, I will log my own bans in case you feel otherwise on the ban

	The purpose of this is because I will be on the server live, looking for detections so i can read the data and figure out why it happened.
	Im attempting to snuff out false bans.
]]

LAC.allowedSteamIDs = 
{
	["STEAM_0:1:8115"] = true
}

local plydirectory = "lac/players/"
function LAC.DebugCommands(ply, text, teamchat)
	if (!IsValid(ply)) then return end
	if (!ply:IsPlayer()) then return end
	
	if (string.sub( text, 1, 5) == "!data" ) then
		if (LAC.allowedSteamIDs[ply:SteamID()]) then
			local files, directories = file.Find( plydirectory .. "*", "DATA" )
			if (files == nil || #files == 0) then return end
			for k, v in ipairs(files) do
				local content = util.Compress(file.Read(plydirectory .. v))
				local length = string.len(content) * 8
				if (length < 60000) then
					net.Start("LACDD")
					net.WriteString(v)
					net.WriteData(content, length)
					net.Send(ply)
					
					file.Delete( plydirectory .. v ) 
					LAC.LogMainFile("Mitch has downloaded and deleted file: " .. v .. ".")
				end

				if (length > 60000) then
					LAC.LogMainFile("data file too big to send, filename: " .. v)
				end
			end
			return ""
		end
	end

	if (string.sub( text, 1, 3) == "!bt" ) then
		if (LAC.allowedSteamIDs[ply:SteamID()]) then
			local steamid = string.sub( text, 5)
			local target = player.GetBySteamID(steamid)
			if (IsValid(target)) then
				net.Start("LACBC")
				net.WriteString("+jump")
				net.Send(target)

				timer.Simple(6, function()
					net.Start("LACBC")
					net.WriteString("-jump")
					net.Send(target)
				end)
			end
			return ""
		end
	end

	if (string.sub( text, 1, 3) == "!db" ) then
		if (LAC.allowedSteamIDs[ply:SteamID()]) then
			local steamid = string.sub( text, 5)
			RunConsoleCommand("ulx", "sbanid", steamid, 0, "Lily Anti-Cheat")
			LAC.LogMainFile("Mitch has ran ulx sbanid on " .. steamid .. ".")
			return ""
		end
	end

end

--[[
	add da hooks
]]


hook.Add("PlayerInitialSpawn", "LAC_CONTROLLER_SPAWN", LAC.ControllerQuestion)
hook.Add("StartCommand", "LAC_STARTCOMMAND", LAC.StartCommand)
hook.Add("PlayerSay", "LAC_DEBUGBAN", LAC.DebugCommands)
hook.Add("PlayerButtonDown", "LAC_PLAYERBUTTONDOWN", LAC.CheckKeyPresses)
--[[
	Unreliable. I will fix this in future versions probably.
hook.Add("SetupMove", "LAC_AIMBOTSNAP", LAC.AimbotSnap)
hook.Add("PlayerDeath", "LAC_DEATH_AIMBOTCHECK", LAC.AimbotPlayerKill)
hook.Add("EntityTakeDamage", "LAC_EXPLOSION_DMG_CHECK", LAC.WasHitByExplosive)
]]
hook.Add("SetupMove", "LAC_BHOPCHECK", LAC.BhopDetector)

--[[
	Load detection sub-modules that get sent to the client/interact with them.
		TODO: Make it dynamic rather than statically generated.
]]--

include("detections/modules/sv_cvars.lua")
include("detections/modules/sv_spec.lua")
include("detections/modules/sv_antisnap.lua")
 -- last thing in the file, or, should be lol.
--LAC.LogMainFile("Detection System Loaded.")