LAC = LAC or {}
require("lacutil") -- gmsv_lacutil_win32.dll or gmsv_lacutil_linux.dll

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

function LAC.PlayerSpawn(player)
	if (player:IsBot() or !IsValid(player)) then return end

	local playerIdentifier = player:SteamID64()

	-- Minor debug :^)
	if (playerIdentifier == "90071996842377216" or playerIdentifier == "") then
		--print("what the fuck?")
		-- Probably kick player here, since thats rlly weird.
	end

	LAC.Players[playerIdentifier] = 
	{
		GameName = player:Nick(), 
		CurrentCmdViewAngles = nil,
		CommandNum = nil
	}; -- TODO: store more relevant data
end

function LAC.PlayerDisconnect(player)
	--[[ 
		Most likely, the entity will be deleted on the next tick, no clue if it's even valid on the current tick, 
		cache id to make sure we have it 
	]]--
	local playerIdentifier = player:SteamID64()

	-- Minor debug :^)
	if (playerIdentifier == "90071996842377216" or playerIdentifier == "") then
		--print("disconnect id is nil/bot")
	end

	LAC.Players[playerIdentifier] = nil; -- data is not relevant any longer. Might change in future idk.
end

function LAC.StartCommand(player, CUserCmd)
	if (LAC == nil) then return end
	if (!IsValid(player)) then return end
	if (player:IsBot()) then return end -- fk off bot >:(

	local playerIdentifier = player:SteamID64()

	if (playerIdentifier == nil) then return end -- this is nil if you're in a singleplayer game btw.
	local PlayerInfoTable = LAC.Players[playerIdentifier];
	if (PlayerInfoTable == nil) then 
		LAC.Players[playerIdentifier] = {};
	end
	PlayerInfoTable.GameName = player:Name()
	PlayerInfoTable.SteamID = player:SteamID64()
	PlayerInfoTable.CurrentCmdViewAngles = CUserCmd:GetViewAngles()
	PlayerInfoTable.CommandNum = CUserCmd:CommandNumber()

	LAC.CheckContextMenu(player, CUserCmd);
	LAC.CheckMovement(player, CUserCmd);

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
	if (gmod.GetGamemode().GAMEMODE_NAME != "terrortown") then return end -- Context menu is allowed in other gamemodes, not TTT

	local plyName = player:Name()
	
	local playerIdentifier = player:SteamID64()
	local PlayerInfoTable = LAC.Players[playerIdentifier]
	if (PlayerInfoTable.Detected) then return end -- player has been detected, Id rather not spam our detection logs.

	local ContextMenuIsOpen = IsInContextMenu(cmd)

	if (ContextMenuIsOpen) then
		LAC.LogClientDetections("LAC has detected a player using context menu! PlayerName: " .. plyName, player)
	end

	--local x = GetContextViewAngles(cmd)
	--if (x == Vector(0,0,0) || x == Vector(0,0,1)) then return end
end


--[[
	Credit mostly to leystryku for his ideas and 
	such for movechecking n shit.
]]
local maxSideMove = GetConVar("cl_sidespeed"):GetInt()
local maxForwardMove = GetConVar("cl_forwardspeed"):GetInt()

function LAC.CheckMovement(player, CUserCmd)
	local up = math.abs( CUserCmd:GetUpMove() )
	local side = math.abs( CUserCmd:GetSideMove() )
	local forward = math.abs( CUserCmd:GetForwardMove() )

	if (up + side + forward == 0) then return end -- Not moving.

	local playerIdentifier = player:SteamID64()
	if (playerIdentifier == nil) then return end
	local PlayerInfoTable = LAC.Players[playerIdentifier]
	if (PlayerInfoTable.Detected) then return end -- player has been detected, Id rather not spam our detection logs.

	if (forward > maxForwardMove) then
		LAC.LogClientDetections("LAC has detected a player with g improper movement! fMove= " .. forward .. " PlayerName: " .. PlayerInfoTable.GameName, player)
	end

	if (side > maxSideMove) then
		LAC.LogClientDetections("LAC has detected a player with g improper movement! sMove= " .. side .. " PlayerName: " .. PlayerInfoTable.GameName, player)
	end

	if (up != 0) then
		LAC.LogClientDetections("LAC has detected a player with improper movement! uMove= " .. up .. " PlayerName: " .. PlayerInfoTable.GameName, player)
	end

	if (forward != 0 && forward != maxForwardMove && forward != (maxForwardMove * 0.5)) then
		LAC.LogClientDetections("LAC has detected a player with improper movement! fMove= " .. forward .. " PlayerName: " .. PlayerInfoTable.GameName, player)
	end

	if (side != 0 && side != maxSideMove && side != (maxSideMove * 0.5)) then
		LAC.LogClientDetections("LAC has detected a player with improper movement! sMove= " .. side .. " PlayerName: " .. PlayerInfoTable.GameName, player)
	end

	--[[
	Testing Notes:
	The only values I've witnessed are:

	Forward values
	0	=	true
	5000	=	true
	10000	=	true

	Side values
	0	=	true
	5000	=	true
	10000	=	true

	Up values
	0	=	true

	Anything other than these values effectively mean someone is most likely cheating. The reason I assume this 
	is because I dont see any possible way to get any other value.
	With this in mind, I will probably make detection logs for people with values that differ from this.
	]]

end

--[[
	Load detection sub-modules that get sent to the client/interact with them.
		TODO: Make it dynamic rather than statically generated.
]]--
include("detections/modules/sv_cvars.lua")






 -- last thing in the file, or, should be lol.
--LAC.LogMainFile("Detection System Loaded.")