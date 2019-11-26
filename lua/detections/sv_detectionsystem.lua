LAC = LAC or {}

-- gmsv_lacutil_win32.dll or gmsv_lacutil_linux.dll
require("lacutil")

-- We will be adding many more network strings in the future, as well as dynamic ones.
util.AddNetworkString( "LACData" )
util.AddNetworkString( "LACDataC" )
util.AddNetworkString( "LACHeart" )
util.AddNetworkString( "LACMisc" ) 

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

function LAC.StartCommand(player, CUserCmd)
	if (!IsValid(player)) then return end
	if (player:IsBot()) then return end -- fk off bot >:(

	local PlayerInfoTable = LAC.GetPTable(player);
	if (PlayerInfoTable == nil) then 
		LAC.Players[id64] = {}; -- Just incase the AC runs after someone has already joined.
	end

	PlayerInfoTable.Name = player:Name()
	PlayerInfoTable.SteamID32 = player:SteamID()
	PlayerInfoTable.SteamID64 = player:SteamID64()
	--PlayerInfoTable.CurrentCmdViewAngles = CUserCmd:GetViewAngles()
	--PlayerInfoTable.CommandNum = CUserCmd:CommandNumber()

	LAC.CheckContextMenu(player, CUserCmd);
	if (player:Alive() && player:Health() > 0) then
		LAC.CheckMovement(player, CUserCmd);
	end

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

function LAC.CheckContextMenu(player, CUserCmd)
	if (gmod.GetGamemode().Name != "Trouble in Terrorist Town") then return end -- Context menu is allowed in other gamemodes, not TTT

	local pTable = LAC.GetPTable(player)
	if (pTable.Detected) then return end -- player has been detected, Id rather not spam our detection logs.

	local ContextMenuIsOpen = IsInContextMenu(CUserCmd)

	if (ContextMenuIsOpen) then
		local DetectionString = string.format("LAC has detected a player using context menu! PlayerName: %s SteamID: %s", pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
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
local maxSideMove = GetConVar("cl_sidespeed"):GetInt() -- Internally these are floats, but if you're setting your cl_forwardmove to 450.4 you're kinda dumb
local maxForwardMove = GetConVar("cl_forwardspeed"):GetInt()

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

function LAC.CheckMovement(player, CUserCmd)
	local up = math.abs( CUserCmd:GetUpMove() )
	local side = math.abs( CUserCmd:GetSideMove() )
	local forward = math.abs( CUserCmd:GetForwardMove() )

	if (up + side + forward == 0) then return end -- Not moving.

	local pTable = LAC.GetPTable(player)
	if (pTable.Detected) then return end

	if (forward > maxForwardMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! fMove= %f PlayerName: %s SteamID: %s", forward, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

	if (side > maxSideMove) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! sMove= %f PlayerName: %s SteamID: %s", side, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

	if (up != 0) then
		local DetectionString = string.format("LAC has detected a player with >improper movement! uMove= %f PlayerName: %s SteamID: %s", up, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

	if (player.UsesController != nil) then return end

	if (forward != 0 && possibleFValues[forward] == nil) then
		local DetectionString = string.format("LAC has detected a player with improper movement! fMove= %f PlayerName: %s SteamID: %s", forward, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

	if (side != 0 && possibleSValues[side] == nil) then
		local DetectionString = string.format("LAC has detected a player with improper movement! sMove= %f PlayerName: %s SteamID: %s", side, pTable.Name, pTable.SteamID32);
		LAC.LogClientDetections(DetectionString, player)
	end

end

--[[
Note:
Joystick starts @ 114 and ends @ 161.
]]

function LAC.CheckKeyPresses(player, button)
	if (!IsValid(player)) then return end
	if (player:IsBot()) then return end -- pretty sure bots dont trigger this but whatever
	if (player.UsesController != nil) then return end
	
	--[[
	if (button >= 72 && button <= 77) then 
		-- Possibly opening a menu
	end]]
		
	if (button >= 114 && button <= 161) then 
		player.UsesController = true;
	end
end
hook.Add("PlayerButtonDown", "LAC_PLAYERBUTTONDOWN", LAC.CheckKeyPresses)

--[[
	Load detection sub-modules that get sent to the client/interact with them.
		TODO: Make it dynamic rather than statically generated.
]]--

include("detections/modules/sv_cvars.lua")
 -- last thing in the file, or, should be lol.
--LAC.LogMainFile("Detection System Loaded.")