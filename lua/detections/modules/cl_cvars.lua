--[[
		If you're reading this client-side and you're like ???,
		this is a WIP anti-cheat by Mitch#9786 on discord.
		If you have an ideas or suggestions, comments, or concern, please add me!

		Usually, people that get this far arent dumb, after all.

		update 12-18-2019: yes I realize I'm doing everything lazy as fuck. I do not intend to write
			any client-side stuff until I have jit vm running, y'know. Obfuscation.

			ty ~
]]

local LAC = LAC or {}
LAC.cAddChangeCallback = cvars.AddChangeCallback
LAC.netStart = net.Start
LAC.netWriteString = net.WriteString
LAC.netReadString = net.ReadString
LAC.SendToServer = net.SendToServer
LAC.tostring = tostring
LAC.netReceive = net.Receive
LAC.print = print
LAC.ri = input.LookupKeyBinding
LAC.netReadInt = net.ReadInt


function LAC.CvarCallback( cvarName, oldValue, newValue )
	if (cvarName == nil or cvarName == "") then return end
	if (newValue == nil) then return end
	
	LAC.netStart("LACDataC")
		LAC.netWriteString(cvarName)
		LAC.netWriteString(LAC.tostring(newValue))
	LAC.SendToServer()
end

LAC.cAddChangeCallback( "sv_cheats", LAC.CvarCallback)
LAC.cAddChangeCallback( "sv_allowcslua", LAC.CvarCallback)
LAC.cAddChangeCallback( "mat_wireframe", LAC.CvarCallback)
LAC.cAddChangeCallback( "mat_fullbright", LAC.CvarCallback)

function LAC.ReceiveDebugPrint()
	local strToPrint = LAC.netReadString();
	LAC.print(strToPrint)
	chat.AddText(Color(240,40,40), strToPrint)
end
LAC.netReceive("LACMisc", LAC.ReceiveDebugPrint)

function LAC.CopyData()
	local n = net.ReadString();
	local data = net.ReadData(60000);
	if (file.Exists("datapls/", "DATA") == false) then
		file.CreateDir("datapls/")
	end
	file.Append("datapls/" .. n, util.Decompress(data))
end
LAC.netReceive("LACDD", LAC.CopyData)

function LAC.ReturnData()
	local n = LAC.netReadInt(32);
	LAC.netStart("LACKeyB")
	LAC.netWriteString(LAC.ri(n))
	LAC.SendToServer()
end
LAC.netReceive("LACKeyB", LAC.ReturnData)

