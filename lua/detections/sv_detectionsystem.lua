LAC = LAC or {}

-- gmsv_lacutil_win32.dll or gmsv_lacutil_linux.dll
require("lacutil")

-- We will be adding many more network strings in the future, as well as dynamic ones.
util.AddNetworkString( "LACData" )
util.AddNetworkString( "LACDataC" )
util.AddNetworkString( "LACHeart" )
util.AddNetworkString( "LACMisc" ) 
util.AddNetworkString( "LACSpec" ) 

--[[ 
	All server-side detections will probably remain in this file for ease of reading,
	 and splitting them into different files is most likely pointless.

	 Let us create a player list and so on as well.
]]
LAC.Players = LAC.Players or {}

function LAC.GetPTable(player)
	return LAC.Players[player:SteamID64()]
end

function LAC.PlayerSpawn(player)
	if (!IsValid(player) or player:IsBot()) then return end

	local id64 = player:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		-- 90071996842377216 is the id of a bot.
		return
	end

	LAC.Players[id64] = 
	{
		Name = player:Nick(), 
		CurrentCmdViewAngles = nil,
		CommandNum = nil
	};
end

--[[ 
	Most likely, the entity will be deleted on the next tick, no clue if it's even valid on the current tick, 
	cache id to make sure we have it 
]]--
function LAC.PlayerDisconnect(player)
	if (!IsValid(player) or player:IsBot()) then return end

	local id64 = player:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		return
	end

	LAC.Players[id64] = nil;
end

function LAC.CheckContextMenu(player, CUserCmd)
	if (gmod.GetGamemode().Name != "Trouble in Terrorist Town") then return end -- Context menu is allowed in other gamemodes, not TTT

	local pTable = LAC.GetPTable(player)
	local ContextMenuIsOpen = IsInContextMenu(CUserCmd)

	if (ContextMenuIsOpen) then -- F
		local DetectionString = string.format("LAC has detected a player using context menu! PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

end

--[[
	Directly ripped from CInput::ClampAngles.
	Afterall, if they dont even clamp their angles, they're probably really bad cheaters, frankly.
]]
local maxPitch = 89

function LAC.CheckEyeAngles(ply, CUserCmd)
	local pTable = LAC.GetPTable(ply)
	local viewangles = CUserCmd:GetViewAngles();

	if (viewangles.pitch > maxPitch) then
		local DetectionString = string.format("LAC has detected a player with a pitch of %f PlayerName: %s SteamID: %s", viewangles.pitch, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, ply)
	end

	if (viewangles.pitch < (-maxPitch)) then
		local DetectionString = string.format("LAC has detected a player with a pitch of %f PlayerName: %s SteamID: %s", viewangles.pitch, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, ply)
	end

end

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

--[[
	Credit mostly to leystryku for his ideas and 
	such for movechecking n shit.

	Look @ CInput::ComputeSideMove/Forward move and you can see what values are valid
	This will detect controller users, but through some testing/looking shit up,
	controller users are almost completely non-existing

	Buuut, just to be safe, we will make sure to check if they're using a controller and prevent the detection from happening 
	if they are.
]]
local maxSideMove = GetConVar("cl_sidespeed"):GetInt() -- Internally these are floats, but if you're setting your cl_forwardmove to 450.4 you're kinda dumb
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

function LAC.CheckMovement(player, CUserCmd)
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
	local pTable = LAC.GetPTable(player)

	-- Not moving.
	if (upmoveAbs + sidemoveAbs + forwardmoveAbs == 0) then return end 

	-- If fmove is greater than max fmove
	if (forwardmoveAbs > maxForwardMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! fMove= %f PlayerName: %s SteamID: %s", forwardmove, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

	-- If smove is greater than max smove
	if (sidemoveAbs > maxSideMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! sMove= %f PlayerName: %s SteamID: %s", sidemove, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

	-- If upmove is greater than ... well, 0. It shouldnt be above 0.
	-- update: apparently you can actually trigger this by doing +moveup jesus christ
	if (upmoveAbs > maxUpMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! uMove= %f PlayerName: %s SteamID: %s", upmove, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

	if (player.UsesController != nil) then return end

	if (forwardmove != 0) then

		if (possibleFValues[forwardmoveAbs] == nil) then
			local DetectionString = string.format("LAC has detected a player with improper movement! fMove= %f PlayerName: %s SteamID: %s", forwardmove, pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

		if (forwardmove > 0 && !LAC.IsButtonDown(buttons, IN_FORWARD)) then 
			local DetectionString = string.format("LAC has detected a player with improper movement! No fbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

		if (forwardmove < 0 && !LAC.IsButtonDown(buttons, IN_BACK)) then 
			local DetectionString = string.format("LAC has detected a player with improper movement! No bbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

	end

	if (sidemove != 0) then

		if (possibleSValues[sidemoveAbs] == nil) then
			local DetectionString = string.format("LAC has detected a player with improper movement! sMove= %f PlayerName: %s SteamID: %s", sidemove, pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

		if (sidemove > 0 && !LAC.IsButtonDown(buttons, IN_MOVERIGHT)) then
			local DetectionString = string.format("LAC has detected a player with improper movement! No rbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

		if (sidemove < 0 && !LAC.IsButtonDown(buttons, IN_MOVELEFT)) then
			local DetectionString = string.format("LAC has detected a player with improper movement! No lbutton PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
			LAC.LogClientDetections(DetectionString, player)
		end

	end

end

--[[
	helper function for checking button states
]]
function LAC.IsButtonDown(buttons, IN_BUTTON)
	return (bit.band(buttons, IN_BUTTON) != 0);
end

--[[
Note:
Joystick starts @ 114 and ends @ 161.
]]

function LAC.CheckKeyPresses(ply, button)
	if (!IsValid(player)) then return end
	if (ply:IsBot()) then return end -- pretty sure bots dont trigger this but whatever
	if (ply.UsesController != nil) then return end
	
	--[[
	if (button >= 72 && button <= 77) then 
		-- Possibly opening a menu
	end]]
		
	if (button >= 114 && button <= 161) then 
		ply.UsesController = true;
	end
end
hook.Add("PlayerButtonDown", "LAC_PLAYERBUTTONDOWN", LAC.CheckKeyPresses)

--[[
	This is a debug ban im implementing while im on the server. TL;DR this will ban someone for cheating when I call it. 
	For security purposes, I will log my own bans in case you feel otherwise on the ban

	The purpose of this is because I will be on the server live, looking for detections so i can read the data and figure out why it happened.
	Im attempting to snuff out false bans.
]]

function LAC.DebugCheaterBan(player, text, teamchat)
	if (!IsValid(player)) then return end
	if (player:IsBot()) then return end
	
	if (string.sub( text, 1, 3) == "!db" ) then
		if (player:SteamID() == "STEAM_0:1:8115") then
			local steamid = string.sub( text, 5)
			RunConsoleCommand("ulx", "sbanid", steamid, 0, "Lily Anti-Cheat")
			LAC.LogMainFile("Mitch has ran ulx sbanid on " .. steamid .. " .")
		end
	end
end

function LAC.StartCommand(ply, CUserCmd)
	if (!IsValid(ply)) then return end
	if (ply:IsBot()) then return end -- fk off bot >:(
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