--[[LAC = LAC or {}

function LAC.ReceiveSnapData(len, ply)
	if ( IsValid( ply ) and ply:IsPlayer() ) then
        -- ee
	end
end
net.Receive("LACTS", LAC.ReceiveSnapData)


function LAC.CallSnap(calling_ply, target_ply)
    if (!IsValid(calling_ply)) then return end
    if (calling_ply:IsBot()) then return end

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
timer.Create( "ReplaceULXSpec", 10, 0, LAC.ReplaceULX) ]]