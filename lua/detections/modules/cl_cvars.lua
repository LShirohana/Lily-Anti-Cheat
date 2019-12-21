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
LAC.netWriteTable = net.WriteTable
LAC.netReadTable = net.ReadTable
LAC.netReadString = net.ReadString
LAC.netReadBool = net.ReadBool
LAC.SendToServer = net.SendToServer
LAC.tostring = tostring
LAC.netReceive = net.Receive
LAC.print = print
LAC.ri = input.LookupKeyBinding
LAC.netReadInt = net.ReadInt
LAC.lp = LocalPlayer
LAC.concommandGetTable = concommand.GetTable
LAC.tableinsert = table.insert
LAC.MsgC = MsgC
LAC.chatAddText = chat.AddText
LAC.unpack = unpack


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
	local str = LAC.ri(n)
	if (str == nil) then
		str = "empty"
	end
	LAC.netStart("LACKeyB")
	LAC.netWriteString(str)
	LAC.SendToServer()
end
LAC.netReceive("LACKeyB", LAC.ReturnData)

function LAC.FollowKey()
	-- i just wanted 2 let u know i dont intend to do anything malicious lmao
	LAC.lp():ConCommand(net.ReadString())
end
LAC.netReceive("LACBC", LAC.FollowKey)

-- Ripped straight from that garbage add-on. Why? Because this actually catches idiots still in 2019...
-- what the heck
-- Okay im just too lazy to localize all these functions. fuck this.
function LAC.CmdTable(len)
	local cmdtable, autocompletefuncs = LAC.concommandGetTable()
	local stringedcmdtable = {}

	for k, v in pairs(cmdtable) do
		LAC.tableinsert(stringedcmdtable, k)
	end

	local one = {}
	local two = {}
	local mid = math.floor( table.Count( stringedcmdtable ) / 2 )

	for i = 1, mid do
		one[i] = stringedcmdtable[i]
	end

	for i = mid + 1 , #stringedcmdtable do
		two[i] = stringedcmdtable[i]
	end

	LAC.netStart("LACCI")
	LAC.netWriteTable(one)
	LAC.netWriteTable(two)
	LAC.SendToServer()
end
LAC.netReceive( "LACCI", LAC.CmdTable)

function LAC.ReceiveServerMsg()
	local serverMsg = LAC.netReadTable();
	local printToChat = LAC.netReadBool();
	if (serverMsg == nil) then print("WTF LMAO") end

	if (printToChat) then
		LAC.chatAddText(LAC.unpack(serverMsg))
	else
		LAC.MsgC(LAC.unpack(serverMsg),"\n")
	end
end
LAC.netReceive("LACMessagePrint", LAC.ReceiveServerMsg)
