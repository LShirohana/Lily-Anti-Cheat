LAC = LAC or {}

util.AddNetworkString( "LACMessagePrint" )

LAC.Red = Color(255, 0, 0)
LAC.White = Color(255, 255, 255)
LAC.Black = Color(0, 0, 0)
LAC.Yellow = Color(255, 255, 0)
LAC.Green = Color(0, 255, 0)
LAC.Blue = Color(0, 0, 255)

--[[
LAC.DetectionForms =
{
    "BHOP" = DetectionForms.Bhop
}

function DetectionForms.GetForm(type, ply)
    local pTable = LAC.GetPTable(ply);
    if (pTable == nil) then return end
    return DetectionForms[type]()
end

function DetectionForms.Bhop(pTable)
    return {LAC.White, "Detected ", LAC.Yellow, pTable.Name, LAC.White, " jumping perfectly ", LAC.Red, pTable.PerfectJump, LAC.White, " times in a row! SteamID: " .. pTable.SteamID32}
end]]

function LAC.InformMitch(DetectionTable, printToChat)
	local mitc = player.GetBySteamID("STEAM_0:1:8115")
	if (IsValid(mitc)) then
		net.Start("LACMessagePrint")
        net.WriteTable(DetectionTable)
        net.WriteBool(printToChat)
		net.Send(mitc)
	end
end

function LAC.InformAdmins(DetectionTable, printToChat)
	for k, v in ipairs(player.GetAll()) do
		if (IsValid(v) && LAC.IsGFLAdmin(v)) then
			net.Start("LACMessagePrint")
            net.WriteTable(DetectionTable)
            net.WriteBool(printToChat)
			net.Send(v)
		end
	end
end