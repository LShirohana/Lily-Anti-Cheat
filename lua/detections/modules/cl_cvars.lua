if (SERVER) then return end

-- god help you if you unlocalize this.... ya noobers...
local LAC = LAC or {}

function LAC.CvarCallback( cvarName, oldValue, newValue )
	if (cvarName == nil or cvarName == "") then return end
	if (newValue == nil) then return end
	
	net.Start("LACDataC")
		net.WriteString(cvarName)
		net.WriteString(tostring(newValue))
	net.SendToServer()
end

cvars.AddChangeCallback( "sv_cheats", LAC.CvarCallback)