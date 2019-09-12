LAC = LAC or {}

function LAC.ReceiveDataCvar(len, ply)

	local player = ply
	if ( IsValid( player ) and player:IsPlayer() ) then
		local cvarName = net.ReadString()
		local cvarData = net.ReadString()
		
		local plyName = player:Name()
		local plyID = player:SteamID()
		
		if (cvarName == nil or cvarData == nil) then 
			LAC.LogClientError("LAC has detected a malformed cvar message! From:" .. plyName, plyID)
			return
		end
		
		local serverValue = GetConVar( cvarName ):GetString()

		print("Server value: " .. serverValue)
		print("Client value: " .. cvarData)
		
		if ((serverValue != "" and serverValue != nil) and serverValue != cvarData) then
			LAC.LogClientDetections("LAC has detected an incorrect Cvar! PlayerName: " .. plyName, plyID)
			return
		end
		
	end
end
net.Receive("LACDataC", LAC.ReceiveDataCvar)


LAC.LogMainFile("Cvar Detection Loaded.")