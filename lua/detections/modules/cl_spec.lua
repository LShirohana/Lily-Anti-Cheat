net.Receive("LACSpec", function()
	local c=net.ReadEntity()
    local d=net.ReadBool()
    
	if (!d) then 
		if (!LocalPlayer().spectate_entity) then 
			return 
		end;
		hook.Remove("CalcView","css")
		LocalPlayer().spectate_entity=nil;
		chat.AddText("You have stopped spectating ", c)
		return 
	end;
	
	LocalPlayer().spectate_entity=c;
	hook.Add("CalcView","css",function(e,f,g,h)

		if (!IsValid(c)) then return end

		local i={}
		i.origin=c:EyePos()
		i.angles=c:EyeAngles()
		i.fov=h;
		i.drawviewer=true;
		c:SetNoDraw(true)

		return i 
    end)
    
	chat.AddText("You are now spectating ", c)
end)

--[[
		If you're reading this client-side and you're like ???,
		this is a WIP anti-cheat by Mitch#9786 on discord.
		If you have an ideas or suggestions, comments, or concern, please add me!

        Usually, people that get this far arent dumb, after all.
        
        sidenote: yes, client-side spec, fk ur m_hGetObserverTarget..... UwU
]]