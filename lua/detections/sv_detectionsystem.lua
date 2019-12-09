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

function LAC.PlayerDetection(reason, ply)
	local steamid64 = ply:SteamID64()
	local PlayerInfoTable = LAC.Players[steamid64]
	PlayerInfoTable.DetectCount = PlayerInfoTable.DetectCount or 0

	PlayerInfoTable.DetectCount = PlayerInfoTable.DetectCount + 1
	
	if (PlayerInfoTable.DetectCount > 12) then
		PlayerInfoTable.Detected = true
		PlayerInfoTable.DetectCount = 0
	end
	
	timer.Simple( 60, function()
		PlayerInfoTable.Detected = false
	end)

	-- This is for debug, so i can see detections live while in the server.
	local mitc = player.GetBySteamID("STEAM_0:1:8115")
	if (IsValid(mitc)) then
		net.Start("LACMisc")
		net.WriteString(reason)
		net.Send(mitc)
	end

	LAC.LogClientDetections(reason, ply)
end

function LAC.PlayerSpawn(ply)
	if (!IsValid(ply) or ply:IsBot()) then return end

	local id64 = ply:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		-- 90071996842377216 is the id of a bot.
		return
	end

	LAC.Players[id64] = 
	{
		Name = ply:Nick(), 
		CurrentCmdViewAngles = nil,
		CommandNum = nil
	};
end

function LAC.PlayerDisconnect(ply)
	if (!IsValid(ply) or ply:IsBot()) then return end

	local id64 = ply:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		return
	end

	LAC.Players[id64] = nil;
end

function LAC.CheckContextMenu(ply, CUserCmd)
	if (gmod.GetGamemode().Name != "Trouble in Terrorist Town") then return end -- Context menu is allowed in other gamemodes, not TTT

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
]]
local maxPitch = 361
function LAC.CheckEyeAngles(ply, CUserCmd)
	local pTable = LAC.GetPTable(ply)
	local viewangles = CUserCmd:GetViewAngles();

	if (viewangles.pitch > maxPitch) then
		local DetectionString = string.format("LAC has detected a player with a pitch of %f PlayerName: %s SteamID: %s", viewangles.pitch, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
	end

	if (viewangles.pitch < (-maxPitch)) then
		local DetectionString = string.format("LAC has detected a player with a pitch of %f PlayerName: %s SteamID: %s", viewangles.pitch, pTable.Name, pTable.SteamID32);
		LAC.PlayerDetection(DetectionString, ply)
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
	-- Hasnt been thoroughly tested on other gamemodes
	if (gmod.GetGamemode().Name != "Trouble in Terrorist Town") then return end

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
	if (upmoveAbs + sidemoveAbs + forwardmoveAbs == 0) then return end 

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
			LAC.LogClientError("LAC has detected a malformed cvar message! From:" .. plyName .. " SteamID: " .. plyID, ply)
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

-- This does not work too well but yolo
function LAC.CheckKeyPresses(ply, button)
	if (!IsValid(player)) then return end
	if (ply:IsBot()) then return end -- pretty sure bots dont trigger this but whatever

	local pTable = LAC.GetPTable(ply)
	if (!pTable) then return end
	
	--[[
	if (button >= 72 && button <= 77) then 
		-- Possibly opening a menu
	end]]
		
	if (button >= 114 && button <= 161) then 
		pTable.UsesController = true;
		--print("CONTROLLER CURRENTLY IN USE")
	end
end
hook.Add("PlayerButtonDown", "LAC_PLAYERBUTTONDOWN", LAC.CheckKeyPresses)

--[[
	This is a debug ban im implementing while im on the server. TL;DR this will ban someone for cheating when I call it. 
	For security purposes, I will log my own bans in case you feel otherwise on the ban

	The purpose of this is because I will be on the server live, looking for detections so i can read the data and figure out why it happened.
	Im attempting to snuff out false bans.
]]

function LAC.DebugCheaterBan(ply, text, teamchat)
	if (!IsValid(ply)) then return end
	if (!ply:IsPlayer()) then return end
	
	if (string.sub( text, 1, 3) == "!db" ) then
		if (ply:SteamID() == "STEAM_0:1:8115") then
			local steamid = string.sub( text, 5)
			RunConsoleCommand("ulx", "sbanid", steamid, 0, "Lily Anti-Cheat")
			LAC.LogMainFile("Mitch has ran ulx sbanid on " .. steamid .. " .")
		end
	end
end

function LAC.StartCommand(ply, CUserCmd)
	if (!IsValid(ply)) then return end
	if (ply:IsBot()) then return end -- fk off bot >:(
	if (CUserCmd:IsForced()) then return end
	if (ply:Health() <= 0 or not ply:Alive() or ply:Team() == TEAM_SPECTATOR) then return end

	local pTable = LAC.GetPTable(ply);
	if (pTable == nil) then 
		LAC.Players[ply:SteamID64()] = {}; -- Just incase the AC runs after someone has already joined.
	end

	pTable.Name = ply:Name()
	pTable.SteamID32 = ply:SteamID()
	pTable.SteamID64 = ply:SteamID64()

	if (pTable.Detected) then return end

	LAC.CheckContextMenu(ply, CUserCmd);
	LAC.CheckMovement(ply, CUserCmd)
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

hook.Add("PlayerInitialSpawn", "LAC_SPAWN", LAC.PlayerSpawn)
hook.Add("PlayerInitialSpawn", "LAC_CONTROLLER_SPAWN", LAC.ControllerQuestion)
hook.Add("PlayerDisconnected", "LAC_DISCONNECT", LAC.PlayerDisconnect)
hook.Add("StartCommand", "LAC_STARTCOMMAND", LAC.StartCommand)
hook.Add("PlayerSay", "LAC_DEBUGBAN", LAC.DebugCheaterBan)

--[[
	Load detection sub-modules that get sent to the client/interact with them.
		TODO: Make it dynamic rather than statically generated.
]]--

include("detections/modules/sv_cvars.lua")
include("detections/modules/sv_spec.lua")
 -- last thing in the file, or, should be lol.
--LAC.LogMainFile("Detection System Loaded.")



--[[
	This is an attempt at catching aimbotters via massive angle jumps.
	idk lol
	This is currently not called since Ive yet to implement it properly. Just some code references that I had help using leystryku.


function LAC.CheckAimAngles(ply, CUserCmd)
	local pTable = LAC.GetPTable(ply)
	local viewangles = CUserCmd:GetViewAngles();
	local acos = math.acos
	local deg = math.deg
	local abs = math.abs


	if (pTable.AimingTable == nil) then 
		pTable.AimingTable = {}
	end

	local aimingRecord = 
	{
		buttons = CUserCmd:GetButtons(),
		angles = CUserCmd:GetViewAngles(),
		--AimingAtSomeone = IsValid(ply:GetEyeTrace().Entity),
	}
	
	table.insert(pTable.AimingTable, aimingRecord)
	local aimRecordSize = #pTable.AimingTable
	--print("records currently: " ..aimRecordSize)

	local LastRecord = nil
	local degreeAverage = 0;
	local degreeTotal = 0;

	for i = 1, aimRecordSize do
		if (i == 1) then 
			LastRecord = pTable.AimingTable[i];
			continue;
		end
		
		local CurAngle = pTable.AimingTable[i].angles:Forward()
		local PrevAngle = LastRecord.angles:Forward()

		if (abs(abs(CurAngle.x) - abs(PrevAngle.x)) < 1) then 
			local dot = CurAngle:Dot(PrevAngle)
			local degreeDiff = deg(acos(dot))
			--print(degreeDiff)
			degreeTotal = degreeTotal + degreeDiff
		end
	end

	degreeAverage = degreeTotal / aimRecordSize
	if (degreeAverage > 1) then
		print(degreeAverage)
	end

	if (aimRecordSize > 35) then
		local delete = (aimRecordSize - 34)

		for i = 1, delete do
			table.remove(pTable.AimingTable, 1)
		end
	end

end
]]