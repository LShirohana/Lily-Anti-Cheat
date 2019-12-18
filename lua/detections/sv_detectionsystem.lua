LAC = LAC or {}

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

--[[ 
	All server-side detections will probably remain in this file for ease of reading,
	 and splitting them into different files is most likely pointless.

	 Let us create a player list and so on as well.
]]
LAC.Players = LAC.Players or {}

--[[
	helper functions
]]

function LAC.GetPTable(ply)
	return LAC.Players[ply:SteamID64()]
end

function LAC.IsButtonDown(buttons, IN_BUTTON)
	return (bit.band(buttons, IN_BUTTON) != 0);
end

function LAC.IsTTT()
	return (gmod.GetGamemode().Name == "Trouble in Terrorist Town")
end

-- Currently, only informs me, because other admins dont know wtf they're reading.
function LAC.InformMitch(reason)
	local mitc = player.GetBySteamID("STEAM_0:1:8115")
	if (IsValid(mitc)) then
		net.Start("LACMisc")
		net.WriteString(reason)
		net.Send(mitc)
	end
end

function LAC.IsGFLAdmin(ply)
	return ply:IsUserGroup("trialadmin") or ply:IsAdmin()
end

function LAC.InformAdmins(reason)
	for k, v in ipairs(player.GetAll()) do
		if (IsValid(v) && LAC.IsGFLAdmin(v)) then
			net.Start("LACMisc")
			net.WriteString(reason)
			net.Send(v)
		end
	end
end

function LAC.InitializePlayerTable(ply)
	LAC.Players[ply:SteamID64()] = 
	{
		Name = ply:Nick(), 
		DetectCount = 0,
		Detected = false,
		SteamID32 = ply:SteamID(),
		SteamID64 = ply:SteamID64(),
		CurrentCmdViewAngles = nil,
		DeltaAngleValues = {},
		DDeltaAngleValues = {},
		CommandNum = nil,
		PerfectJump = 0,
		OnGround = false,
		InJump = false,
		HitByExplosive = false,
		SuspiciousKeyUsage = 0,
	};
end

-- Things that are suspicious, but definitely not bannable, such as someone pressing insert lol.
function LAC.PlayerSuspiciousDetection(reason, ply)
	LAC.InformMitch(reason)
	LAC.InformAdmins(reason)
	LAC.LogClientDetections(reason, ply)
end

function LAC.PlayerDetection(reason, ply)
	local pTable = LAC.GetPTable(ply)
	if (pTable.Detected) then return end
	pTable.DetectCount = pTable.DetectCount + 1
	
	if (pTable.DetectCount > 12) then
		pTable.Detected = true
	end
	
	timer.Simple( 60, function()
		pTable.Detected = false
		if (pTable.DetectCount > 0) then
			pTable.DetectCount = pTable.DetectCount - 1
		end
	end)

	-- This is for debug, so i can see detections live while in the server,
	-- helps me figure out what caused a false detection, if it does happen.
	LAC.InformMitch(reason)

	-- Logging to server that a detection has occurred.
	LAC.LogClientDetections(reason, ply)
end

function LAC.PlayerSpawn(ply)
	if (!IsValid(ply) or ply:IsBot()) then return end

	local id64 = ply:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		-- 90071996842377216 is the id of a bot.
		return
	end

	LAC.InitializePlayerTable(ply)
end

function LAC.PlayerDisconnect(ply)
	if (!IsValid(ply) or ply:IsBot()) then return end

	local id64 = ply:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		return
	end

	LAC.Players[id64] = nil;
end

--[[
	Following 2 detections is from CAC almost C&P
	Edited/tinkered with as I think is neccesary, because ya
]]

local math_deg = math.deg
local math_acos = math.acos
local math_min = math.min
local math_abs = math.abs
local SysTime = SysTime
local table_insert = table.insert
local math_sqrt = math.sqrt

local function getMean( t )
	local sum = 0
	local count= 0

	for k, v in ipairs(t) do
		sum = sum + v
		count = count + 1
	end

	return (sum / count)
end

local function stDev( t )
	local m
	local vm
	local sum = 0
	local count = 0
	local result
	m = getMean( t )
	for k,v in ipairs(t) do
		vm = v - m
		sum = sum + (vm * vm)
		count = count + 1
	end
	result = math_sqrt(sum / (count-1))
	return result
end

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

local _R_CUserCmd_KeyDown  = debug.getregistry().CUserCmd.KeyDown
local _R_Entity_IsOnGround = debug.getregistry().Entity.IsOnGround

function LAC.BhopDetector(ply, moveData, CUserCmd)
	if (!ply:IsValid()) then return end
	if (!ply:IsPlayer()) then return end
	local pTable = LAC.GetPTable(ply);
	if (pTable == nil) then return end
	if (ply:Health() <= 0 or not ply:Alive() or ply:Team() == TEAM_SPECTATOR) then return end
	
	local PreviouslyOnGround = pTable.OnGround
	local WasInJump	= pTable.InJump
	
	local CurrentlyOnGround = _R_Entity_IsOnGround(ply)
	local CurrentlyInJump   = _R_CUserCmd_KeyDown(CUserCmd, IN_JUMP)
	
	if (!PreviouslyOnGround && CurrentlyOnGround) then -- If I just landed (Not on ground, but now I am)
		if (!WasInJump && CurrentlyInJump) then -- And pressed +jump the instant I landed (I didnt press +jump, now I am)
			pTable.PerfectJump = pTable.PerfectJump + 1

			if (pTable.PerfectJump > 13) then
				local DetectionString = string.format("LAC has detected a player jumping perfectly " .. pTable.PerfectJump .. " times in a row! PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
				LAC.PlayerDetection(DetectionString, ply)
				LAC.PlayerSuspiciousDetection(DetectionString, ply)
			end
		else
			pTable.PerfectJump = 0
		end
	elseif (CurrentlyOnGround) then
		if (WasInJump ~= CurrentlyInJump) then
			pTable.PerfectJump = 0
		end
	end
	
	pTable.OnGround = CurrentlyOnGround
	pTable.InJump   = CurrentlyInJump
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

	pTable.Name = ply:Name()
	-- Explosives fuck up your viewangles, which will trigger aimbot detection, so I set it to false every usercommand, and only true on EntityTakeDamage
	pTable.HitByExplosive = false

	if (pTable.Detected) then return end

	if (LAC.IsTTT()) then
		LAC.CheckContextMenu(ply, CUserCmd);
		LAC.CheckMovement(ply, CUserCmd)
	end
	LAC.CheckEyeAngles(ply, CUserCmd); -- idk, being safe.

	--[[
		Havent done anything with this function yet
			TODO: 
			Aimbot check
			triggerbot check
			bhop check
			spamming check
	]]
end

function LAC.CheckContextMenu(ply, CUserCmd)
	local pTable = LAC.GetPTable(ply)
	local ContextMenuIsOpen = IsInContextMenu(CUserCmd)

	if (ContextMenuIsOpen) then -- F
		local DetectionString = string.format("LAC has detected a player using context menu! PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
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

    if (math.abs(viewangles.pitch) > 90) then
		local DetectionString = string.format("LAC has detected a player with a pitch of %f PlayerName: %s SteamID: %s", viewangles.pitch, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
    end

	--[[
	if (viewangles.pitch > maxPitch) then
		local DetectionString = string.format("LAC has detected a player with a pitch of %f PlayerName: %s SteamID: %s", viewangles.pitch, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
	end

	if (viewangles.pitch < (-maxPitch)) then
		local DetectionString = string.format("LAC has detected a player with a pitch of %f PlayerName: %s SteamID: %s", viewangles.pitch, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
	end]]

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

	-- Not moving.
	if (upmoveAbs == 0 && sidemoveAbs == 0 && forwardmoveAbs == 0) then return end

	-- If fmove is greater than max fmove
	if (forwardmoveAbs > maxForwardMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! fMove= %f PlayerName: %s SteamID: %s", forwardmove, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
	end

	-- If smove is greater than max smove
	if (sidemoveAbs > maxSideMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! sMove= %f PlayerName: %s SteamID: %s", sidemove, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
	end

	-- If upmove is greater than ... well, 0. It shouldnt be above 0.
	-- update: apparently you can actually trigger this by doing +moveup jesus christ
	if (upmoveAbs > maxUpMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! uMove= %f PlayerName: %s SteamID: %s", upmove, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
	end

	if (pTable.UsesController == true) then return end

	if (forwardmove != 0) then

		if (possibleFValues[forwardmoveAbs] == nil) then
			local DetectionString = string.format("LAC has detected a player with improper movement! fMove= %f PlayerName: %s SteamID: %s", forwardmove, pTable.Name, pTable.SteamID32);
			LAC.PlayerDetection(DetectionString, ply)
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
			local DetectionString = string.format("LAC has detected a player with improper movement! sMove= %f PlayerName: %s SteamID: %s", sidemove, pTable.Name, pTable.SteamID32);
			LAC.PlayerDetection(DetectionString, ply)
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

	if (LAC.IsButtonDown(buttons, IN_BULLRUSH)) then
		local DetectionString = string.format("LAC has detected a player with improper movement! IN_BULLRUSH PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
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

		if (tonumber(cvarData) == 1) then
			pTable.UsesController = true;
			--print(plyName .. " IS USING A CONTROLLER!")
			return
		end
		
	end
end
net.Receive("LACH", LAC.ReceiveJoystick)

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
		
		local DetectionString = string.format("LAC has detected a player with out-of-order SM! PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
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
			pTable.SuspiciousKeyUsage = pTable.SuspiciousKeyUsage + 1

			timer.Simple( 60, function()
				if (pTable.SuspiciousKeyUsage > 0) then
					pTable.SuspiciousKeyUsage = pTable.SuspiciousKeyUsage - 1
				end
			end)

			if (pTable.SuspiciousKeyUsage < 3) then
				local DetectionString = string.format("LAC has detected a player pressing a possible cheat menu key while standing still! (%s) PlayerName: %s SteamID: %s", keyTable[button], pTable.Name, pTable.SteamID32);
				if (!ply:Alive()) then
					DetectionString = string.format("LAC has detected a player pressing a possible cheat menu key while dead! (%s) PlayerName: %s SteamID: %s", keyTable[button], pTable.Name, pTable.SteamID32);
				end
				LAC.PlayerSuspiciousDetection(DetectionString, ply)
			end
		end
		-- Possibly opening a menu, the velocity is because if someone is in menu, they wouldnt be moving (since 99% of menus prevent other keys from being pressed)
	end
		
	if (button >= 114 && button <= 161) then 
		pTable.UsesController = true;
	end
end

--[[
	This is a debug ban im implementing while im on the server. TL;DR this will ban someone for cheating when I call it. 
	For security purposes, I will log my own bans in case you feel otherwise on the ban

	The purpose of this is because I will be on the server live, looking for detections so i can read the data and figure out why it happened.
	Im attempting to snuff out false bans.
]]

local allowedSteamIDs = 
{
	["STEAM_0:1:8115"] = true
}

function LAC.DebugCheaterBan(ply, text, teamchat)
	if (!IsValid(ply)) then return end
	if (!ply:IsPlayer()) then return end
	
	if (string.sub( text, 1, 3) == "!db" ) then
		if (allowedSteamIDs[ply:SteamID()]) then
			local steamid = string.sub( text, 5)
			RunConsoleCommand("ulx", "sbanid", steamid, 0, "Lily Anti-Cheat")
			LAC.LogMainFile("Mitch has ran ulx sbanid on " .. steamid .. ".")
		end
	end
end

function LAC.PreventSpamConnecting(name, ip)
	-- seriously, why do we even print that they're joining on PlayerConnect? Do it on PlayerAuthed, christ.

end

local plydirectory = "lac/players/"
function LAC.SendDataDumps(ply, text, teamchat)
	if (!IsValid(ply)) then return end
	if (!ply:IsPlayer()) then return end
	
	if (string.sub( text, 1, 5) == "!data" ) then
		if (allowedSteamIDs[ply:SteamID()]) then
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
				end

				if (length > 60000) then
					LAC.LogMainFile("data file too big to send, filename: " .. v)
				end
			end
		end
	end
end

--[[
	add da hooks
]]

hook.Add("PlayerInitialSpawn", "LAC_SPAWN", LAC.PlayerSpawn)
hook.Add("PlayerInitialSpawn", "LAC_CONTROLLER_SPAWN", LAC.ControllerQuestion)
hook.Add("PlayerDisconnected", "LAC_DISCONNECT", LAC.PlayerDisconnect)
hook.Add("StartCommand", "LAC_STARTCOMMAND", LAC.StartCommand)
hook.Add("PlayerSay", "LAC_DEBUGBAN", LAC.DebugCheaterBan)
hook.Add("PlayerSay", "LAC_DATADUMP", LAC.SendDataDumps)
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
 -- last thing in the file, or, should be lol.
--LAC.LogMainFile("Detection System Loaded.")