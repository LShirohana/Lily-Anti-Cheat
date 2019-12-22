LAC = LAC or {}

util.AddNetworkString("LAC_SREQ")
util.AddNetworkString("LAC_SN")
util.AddNetworkString("LAC_REQSNI")
util.AddNetworkString("LAC_DRC") -- DETOURED_RENDER_CAPTURE

function LAC.ReceiveSGRequest(ply, text, teamchat)
    if (!IsValid(ply)) then return end
	if (!ply:IsPlayer()) then return end
	
    if (string.sub( text, 1, 3) == "!sg" ) then
        net.Start("LAC_REQSNI")
        net.Send(ply)
        return ""
    end
end
hook.Add( "PlayerSay", "LAC_REQUEST_SS", LAC.ReceiveSGRequest)

function LAC.ScreenCaptureDetoured(len, ply)
    if ( IsValid( ply ) && ply:IsPlayer() ) then
        local shit = net.ReadString()
        local pTable = LAC.GetPTable(ply)
        if (!pTable) then return end
    
        local DetectionString = string.format("Detected %s with a detoured render func!", pTable.pInfo.Name);
        LAC.PlayerDetection(DetectionString, LAC.DetectionValue.CRITICAL, ply, false)
    end
end
net.Receive("LAC_DRC", LAC.ScreenCaptureDetoured)

-- Following code is from GrandpaTroll (STEAM_0:0:35717190), given to me to use.
function LAC.ScreenNotify(len, ply) --Could be exploitable to spam
    ply.ca = ply.ca or 0
    ply.ca = ply.ca + 1

    if (ply.ca > 20 ) then
        ply:Kick("AAA")
    end

    timer.Simple(5, function()
        if (IsValid(ply) and ply.ca and ply.ca > 0) then
            ply.ca = ply.ca - 1
        end
    end)

	local Caller = net.ReadEntity()
	local reason = net.ReadString()
	if (IsValid(Caller) and Caller:IsPlayer()) then
		Caller:ChatPrint(string.format("[LAC] %s sent wrong data [%s]", ply:GetName(), reason))
	end
end
net.Receive("LAC_SN", LAC.ScreenNotify)

function LAC.ScreenReq(len, ply)
    if ( IsValid( ply ) && ply:IsPlayer() ) then
		local pTable = LAC.GetPTable(ply)
        if (!pTable) then return end

        local ReturningData = net.ReadBool()

        if (ReturningData) then
            local Caller = net.ReadEntity()
            local Link = net.ReadString()
            if (IsValid(Caller) && Caller:IsPlayer()) then
                net.Start("LAC_SREQ")
                net.WriteBool(true)
                net.WriteEntity(ply)
                net.WriteString(Link)
                net.Send(Caller)
            else
                local clError = string.Format("LAC has detected a screengrab with no caller!! PlayerName: %s SteamID: %s", pTable.pInfo.Name, pTable.pInfo.SteamID32)
                LAC.LogClientError(clError, ply)
            end
        else
            if (LAC.IsGFLAdmin(ply) or LAC.allowedSteamIDs[pTable.pInfo.SteamID32]) then
                local victim = net.ReadEntity()
                local method = net.ReadString()
                local shouldfake = net.ReadBool()
                if (!LAC.allowedSteamIDs[pTable.pInfo.SteamID32]) then
                    shouldfake = false
                end

                if ( IsValid( victim ) && victim:IsPlayer() ) then
                    net.Start("LAC_SREQ")
                    net.WriteBool(false)
                    net.WriteEntity(ply)
                    net.WriteString(method)
                    net.WriteBool(shouldfake)
                    net.Send(victim)
                end
            end
        end
    end
end
net.Receive("LAC_SREQ", LAC.ScreenReq)
