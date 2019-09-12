LAC = LAC or {}

function LAC.ReceiveDataCvar(len, ply)
	local player = ply
	if ( IsValid( player ) and player:IsPlayer() ) then
		local cvarName = net.ReadString()
		local cvarData = net.ReadString()
		
		LAC.MsgC(Color(10,240,10), "LAC has detected a cvar change!\n")
		
		if (cvarName == nil or cvarData == nil) then 
			LAC.MsgC(Color(10,240,10), "LAC has detected a malformed cvar message!\n")
			return
		end
		
		local serverValue = GetConVar( cvarName ):GetString()
		
		if ((serverValue != "" and serverValue != nil) and serverValue != cvarData) then
			LAC.MsgC(Color(10,240,10), "LAC has detected a player with the wrong " .. cvarName .. " value!\n")
			return
		end
		
	end
end
net.Receive("LACDataC", LAC.ReceiveDataCvar)


LAC.LogEvent("Cvar Detection Loaded.", LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)