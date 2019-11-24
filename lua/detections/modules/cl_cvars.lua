local LAC = LAC or {}
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
LAC.cAddChangeCallback( "mat_wireframe", LAC.CvarCallback)
LAC.cAddChangeCallback( "mat_fullbright", LAC.CvarCallback)


--[[
		If you're reading this client-side and you're like ???,
		this is a WIP anti-cheat by Mitch#9786 on discord.
		If you have an ideas or suggestions, comments, or concern, please add me!

		Usually, people that get this far arent dumb, after all.
]]

