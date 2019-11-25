LAC = LAC or {}

function LAC.ReceiveDataCvar(len, ply)

	local player = ply
	if ( IsValid( player ) and player:IsPlayer() ) then
		local cvarName = net.ReadString()
		local cvarData = net.ReadString()
		
		local plyName = player:Name()
		local plyID = player:SteamID()
		
		if (cvarName == nil or cvarData == nil) then 
			LAC.LogClientError("LAC has detected a malformed cvar message! From:" .. plyName .. " SteamID: " .. plyID, player)
			return
		end
		
		local serverValue = GetConVar( cvarName ):GetString()
		if (serverValue == "" or serverValue == nil) then return end

		--[[
			print("Server value: " .. serverValue)
			print("Client value: " .. cvarData)
		]]

		if (serverValue != cvarData) then
			LAC.LogClientDetections("LAC has detected an incorrect Cvar! PlayerName: " .. plyName .. " SteamID: " .. plyID, player)
			return
		end
		
	end
end
net.Receive("LACDataC", LAC.ReceiveDataCvar)

function LAC.BeginDataCvarChallenge(player)

	if ( !IsValid(player) or player:IsBot() ) then return end

	-- We cannot rely on a client to send their cvars via a callback, it's better to ask them occasionally, for the hell of it.
	local possibleCvars = 
	{
		"sv_cheats",
		"sv_allowcslua",
		"mat_wireframe",
		"mat_fullbright"
	}

	local chosenCvar = possibleCvars[math.random(1, #possibleCvars)]
	local chosenCvarString = "cvars.String(\"" .. chosenCvar .. "\")" -- jesus christ 

	local challengeCode = 
	[[
	net.Start("LACDataC")
		net.WriteString("]] .. chosenCvar .. [[")
		net.WriteString(]] .. chosenCvarString .. [[)
	net.SendToServer()
	]]

	--print(challengeCode)
	player:SendLua(challengeCode)
end

function LAC.ChooseRandomPlayerForCvarChallenge()
	local plys = player.GetHumans()
	local chosenPlayer = plys[math.random(1, #plys)]
	LAC.BeginDataCvarChallenge(chosenPlayer)
end
timer.Create("LAC_CvarRandomChallenge", 5, 0, LAC.ChooseRandomPlayerForCvarChallenge)

--LAC.LogMainFile("Cvar Detection Loaded.")