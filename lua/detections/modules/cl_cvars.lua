-- god help you if you unlocalize this.... ya noobers...
local LAC = LAC or {}
-- time to localize bois
LAC.cAddChangeCallback = cvars.AddChangeCallback

function LAC.CvarCallback( cvarName, oldValue, newValue )
	if (cvarName == nil or cvarName == "") then return end
	if (newValue == nil) then return end
	
	net.Start("LACDataC")
		net.WriteString(cvarName)
		net.WriteString(tostring(newValue))
	net.SendToServer()
end

LAC.cAddChangeCallback( "sv_cheats", LAC.CvarCallback)
LAC.cAddChangeCallback( "sv_allowcslua", LAC.CvarCallback)