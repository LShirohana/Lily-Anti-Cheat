LAC = LAC or {}

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
		print("disconnect id is nill/bot")
	end

	LAC.Players[playerIdentifier] = nil; -- data is not relevant any longer. Might change in future idk.
end

function LAC.StartCommand(player, CUserCmd)
	if ( player:IsBot() ) then return end -- fk off bot >:(

	local playerIdentifier = player:SteamID64()
	LAC.Players[playerIdentifier] = 
	{
		GameName = player:Nick(),
		CurrentCmdViewAngles = CUserCmd:GetViewAngles(),
		CommandNum = CUserCmd:CommandNumber()
	};

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

--[[
	Load detection sub-modules that get sent to the client/interact with them.
		TODO: Make it dynamic rather than statically generated.
]]--
include("detections/modules/sv_cvars.lua")






 -- last thing in the file, or, should be lol.
LAC.LogMainFile("Detection System Loaded.")