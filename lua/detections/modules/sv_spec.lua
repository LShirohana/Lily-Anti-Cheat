LAC = LAC or {}

function LAC.Spectate(calling_ply, target_ply)
    if (!IsValid(calling_ply)) then return end
    if (calling_ply:IsBot()) then return end
    
    if (calling_ply.SpecTarget == nil) then
        calling_ply.SpecTarget = target_ply;
        calling_ply:Freeze(true)

        net.Start("LACSpec")
        net.WriteEntity(target_ply)
        net.WriteBool(true)
        net.Send(calling_ply)
        return
    end

    if (calling_ply.SpecTarget == target_ply) then
        calling_ply.SpecTarget = nil;
        calling_ply:Freeze(false)

        net.Start("LACSpec")
        net.WriteEntity(target_ply)
        net.WriteBool(false)
        net.Send(calling_ply)
        return
    end
    -- just overwriting ulx's shitty spectate.
end

function LAC.ReplaceULX()
    if (ulx) then -- get fuucked ulx
        local spectate = ulx.command( CATEGORY_NAME, "ulx spectate", LAC.Spectate, "!spectate", true )
        spectate:addParam{ type=ULib.cmds.PlayerArg, target="!^" }
        spectate:defaultAccess( ULib.ACCESS_ADMIN )
        spectate:help( "Spectate target." )

        timer.Remove("ReplaceULXSpec")
    end
end
timer.Create( "ReplaceULXSpec", 10, 0, LAC.ReplaceULX) 