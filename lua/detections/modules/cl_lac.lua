--
--		If you're reading this client-side and you're like ???,
--		this is a WIP anti-cheat by Mitch#9786 on discord/LilyS on UC.
--		If you have an ideas or suggestions, comments, or concern, please add me!
--
--		Usually, people that get this far arent dumb, after all.
--
--		sidenote: yes, client-side spec, fk ur m_hGetObserverTarget..... UwU
--
--		update 12-18-2019: yes I realize I'm doing everything lazy as fuck. I do not intend to write
--			any client-side stuff until I have jit vm running, y'know. Obfuscation.
--
--			ty ~
--
--		update 12-27-2019: merry kurisumasu. Pls dont hate me if I somehow ban you, it's nothin' personal! 
--			I just like coding and writing an anti-cheat is fun!
--
--		update 1/9/2020:
--			I just realize comments encased in --[[]] get stripped out when sent to the client
-- 			this entire thing couldnt be read by people until now WTF
--				update 1/12/2020: apparently they could read it idk.


local LAC = LAC or {}
LAC.stringdump = string.dump
LAC.xpcall = xpcall
LAC.cAddChangeCallback = cvars.AddChangeCallback
LAC.netStart = net.Start
LAC.netWriteString = net.WriteString
LAC.netWriteTable = net.WriteTable
LAC.netWriteEntity = net.WriteEntity
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
LAC.timerSimp = timer.Simple
LAC.timerCreate = timer.Create
LAC.ValidPlayer = game.IsDedicated

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
-- Okay im just too lazy to localize all these functions.
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
		table.insert(serverMsg, "\n")
		LAC.MsgC(LAC.unpack(serverMsg))
	end
end
LAC.netReceive("LACMessagePrint", LAC.ReceiveServerMsg)

LAC.netReceive("LACSpec", function()
	local c=net.ReadEntity()
    local d=net.ReadBool()
    
	if (!d) then 
		if (!LocalPlayer().spectate_entity) then 
			return 
		end;
		hook.Remove("CalcView","css")
		
		LocalPlayer().spectate_entity:SetNoDraw(true)
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

-- originally called gcap, by grandpatroll.
-- name changed to visit the style of my AC, but this is still not my code! ^_^
--
LAC.gcap = {}
LAC.gcap.__gcap_getscreenie = false
LAC.gcap.MyGrabber = nil
LAC.gcap.access_token = "941b6f9d629478d642589c7726501e71e23f3b1b"
LAC.gcap._ASDASFrsrt = LAC.gcap._ASDASFrsrt || render.SetRenderTarget
LAC.HookName = LAC.tostring(math.random(0,1000000))
LAC.gcap.WasAccessedTwiced = false

function LAC.DumpRC()
	LAC.result = LAC.stringdump(render.Capture) or 0
	LAC.netStart("LAC_DRC")
	LAC.netWriteString(LAC.result)
	LAC.SendToServer()
end

function LAC.DumpRT()
	LAC.result = LAC.stringdump(render.SetRenderTarget) or 0
	LAC.netStart("LAC_DRC")
	LAC.netWriteString(LAC.result)
	LAC.SendToServer()
end

function LAC.RCResult()
	local cvar = "sv_allowcslua"
	LAC.netStart("LACDataC")
		LAC.netWriteString(cvar)
		LAC.netWriteString(LAC.tostring(GetConVarString(cvar)))
	LAC.SendToServer()
end

function LAC.RTResult()
	local cvar = "sv_cheats"
	LAC.netStart("LACDataC")
		LAC.netWriteString(cvar)
		LAC.netWriteString(LAC.tostring(GetConVarString(cvar)))
	LAC.SendToServer()
end

function LAC.gcap.PostScreenshot(picdata,returner)
	local ispicstr = isstring(picdata)
	local goodjpg = ispicstr && string.StartWith(picdata, "\xFF\xD8")
	if (picdata && ispicstr && goodjpg) then
		http.Post("https://api.imgur.com/3/upload",{image=util.Base64Encode(picdata)},
			function(data)
				datatbl = util.JSONToTable(data).data
				if datatbl && datatbl.link then
					net.Start("LAC_SREQ")
					net.WriteBool(true)
					net.WriteEntity(returner)
					net.WriteString(datatbl.link)
					net.SendToServer()
				else
					--print("no link :C")
				end
			end,
			function(fail)
				file.Write("gccache.jpg", picdata)
				--print("failed")
				--print(fail)
			end,
			{Authorization = "Bearer ".. LAC.gcap.access_token }
		)
	elseif (ispicstr) then
		if (picdata == "") then
			net.Start("LAC_SN")
				net.WriteEntity(returner)
				net.WriteString("No Data")
			net.SendToServer()
		else
			net.Start("LAC_SN")
				net.WriteEntity(returner)
				net.WriteString(string.sub(picdata,1,32))
			net.SendToServer()
		end
	else
		net.Start("LAC_SN")
			net.WriteEntity(returner)
			net.WriteString("No Data")
		net.SendToServer()
	end
	hook.Remove( "RenderScene", LAC.HookName)
end

function LAC.gcap.DoScreengrab(mycapturer, method, fake)
	local oldval = GetConVarNumber("cl_savescreenshotstosteam")

	LAC.xpcall(LAC.DumpRC, LAC.RCResult)
	LAC.xpcall(LAC.DumpRT, LAC.RTResult)

	if (method == "render.Capture") then
		local function DoRenderCap()
			LAC.gcap._ASDASFrsrt()
			local picdata = render.Capture({
				format = "jpeg",
				quality = 100, //100 is max quality, but 70 is good enough.
				h = ScrH(),
				w = ScrW(),
				x = 0,
				y = 0,
			})

			LAC.gcap.PostScreenshot(picdata, mycapturer)
		end
		if (fake) then
			DoRenderCap()
		else
			local hookname = tostring(math.Rand(1,1000))
			hook.Add("PostRender", hookname, function()
				LAC.gcap.WasAccessedTwiced = true
				DoRenderCap()
				LAC.gcap.WasAccessedTwiced = false
				hook.Remove("PostRender", hookname)
			end)
		end
	elseif (method == "jpeg") then
		local randostringo = tostring(math.Rand(1,1000))
		RunConsoleCommand("jpeg_quality", "100")
		RunConsoleCommand("cl_savescreenshotstosteam", "0")
		--RunConsoleCommand("__screenshot_internal", randostringo)
		LocalPlayer():ConCommand(string.format("jpeg %s", randostringo))
		
		timer.Simple(0.2,function()
			LAC.gcap.PostScreenshot(file.Read("screenshots/"..randostringo..".jpg", "GAME"), mycapturer)
			RunConsoleCommand("cl_savescreenshotstosteam", "1")
		end)
	elseif (method == "internal") then
		local randostringo = tostring(math.Rand(1,1000))
		RunConsoleCommand("jpeg_quality", "100")
		RunConsoleCommand("cl_savescreenshotstosteam", "0")
		--RunConsoleCommand("__screenshot_internal", randostringo)
		LocalPlayer():ConCommand(string.format("__screenshot_internal %s", randostringo))
		
		timer.Simple(0.2,function()
			LAC.gcap.PostScreenshot(file.Read("screenshots/"..randostringo..".jpg", "GAME"), mycapturer)
			RunConsoleCommand("cl_savescreenshotstosteam", "1")
		end)
	end
end

LAC.gcap.fakert = LAC.gcap.fakert || GetRenderTarget( "pRenderTarget" .. os.time(), ScrW(), ScrH() );
function LAC.RenderCScenes( vecOrigin, angAngle, flFoV )
    render.RenderView( {
        x                = 0,
        y                = 0,
        w                = ScrW(),
        h                 = ScrH(),
        dopostprocess    = true,
        origin            = vecOrigin,
        angles            = angAngle,
        fov             = flFoV,
        drawhud            = true,
        drawmonitors    = true,
        drawviewmodel    = true
    } );

    render.CopyTexture( nil, LAC.gcap.fakert );

    -- 3D Render --
    cam.Start3D( vecOrigin, angAngle );
    cam.End3D();

    -- Setting up viewmatrix properly --
    --cam.Start3D()
    --cam.End3D()

    -- 2D Darwing --
    cam.Start2D();
    cam.End2D();

    LAC.gcap._ASDASFrsrt( LAC.gcap.fakert );

    return true;

end

hook.Add( "ShutDown", tostring(math.random(0,1000000)), function()
    LAC.gcap._ASDASFrsrt(); -- if i dont do this, it literally breaks ur gmod, no joke lmao
end );

function LAC.Thought()
	LAC.xpcall(LAC.DumpRC, LAC.RCResult)
	LAC.xpcall(LAC.DumpRT, LAC.RTResult)
end
LAC.timerCreate(LAC.tostring(math.random(0,1000000)), 30, 0, LAC.Thought)
	
function LAC.gcap.DisplayData( name, link )

	if (main) then
		main:Close()
	end

	name = name || "UNKNOWN"
	local main = vgui.Create( "DFrame", vgui.GetWorldPanel() )
	main:SetPos( 0, 0 )
	main:SetSize( ScrW(), ScrH() )
	main:SetTitle( "Screengrab of " .. name )
	main:MakePopup()
	local html = vgui.Create( "HTML", main )
	html:DockMargin( 0, 0, 0, 0 )
	html:Dock( FILL )
	html:SetHTML( [[ <img width="]] .. ScrW() .. [[" height="]] .. ScrH() .. [[" src="]]..link..[["/> ]] )
end

LAC.netReceive("LAC_SREQ", function(len, ply) -- why do i have ply as an argument on a client-side receive? what the heck
	ReturnedData = net.ReadBool()
	captured = net.ReadEntity()
	if (ReturnedData) then
		link = net.ReadString()
		name = "UNKNOWN"
		if (captured) then
			name = captured:GetName()
		end
		LAC.gcap.DisplayData( name, link )
	else
		local method = net.ReadString()
		local shouldfake = net.ReadBool()
		LAC.netStart("LAC_RSR")
		LAC.netWriteEntity(captured)
		LAC.SendToServer()
		hook.Add( "RenderScene", LAC.HookName, LAC.RenderCScenes)
		LAC.timerSimp(2, function()
			LAC.gcap.DoScreengrab(captured,method,shouldfake)
		end)
	end
end)

function LAC.gcap.OpenSGMenu()

	if (main) then
		return
	end
	
	main = vgui.Create( "DFrame" )
	main:SetSize( 175,170 )
	main:SetTitle( "" )
	main:SetVisible( true )
	main:ShowCloseButton( true )
	main:MakePopup()
	main:Center()	
	main.btnMaxim:Hide()
	main.btnMinim:Hide() 
	main.btnClose:Hide()
	main.Paint = function()
		surface.SetDrawColor( 50, 50, 50, 135 )
		surface.DrawOutlinedRect( 0, 0, main:GetWide(), main:GetTall() )
		surface.SetDrawColor( 0, 0, 0, 240 )
		surface.DrawRect( 1, 1, main:GetWide() - 2, main:GetTall() - 2 )
		surface.SetFont( "DermaDefault" )
		surface.SetTextPos( 10, 5 ) 
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.DrawText( "LAC CAP" )
	end
	
	local close = vgui.Create( "DButton", main )
	close:SetPos( main:GetWide() - 50, 0 )
	close:SetSize( 44, 22 )
	close:SetText( "" )
	
	local colorv = Color( 150, 150, 150, 250 )
	function PaintClose()
		if not main then 
			return 
		end
		surface.SetDrawColor( colorv )
		surface.DrawRect( 1, 1, close:GetWide() - 2, close:GetTall() - 2 )	
		surface.SetFont( "DermaDefault" )
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( 19, 3 ) 
		surface.DrawText( "x" )
		return true
	end
	
	close.Paint = PaintClose		
	close.OnCursorEntered = function()
		colorv = Color( 195, 75, 0, 250 )
		PaintClose()
	end	
	
	close.OnCursorExited = function()
		colorv = Color( 150, 150, 150, 250 )
		PaintClose()
	end	
	
	close.OnMousePressed = function()
		colorv = Color( 170, 0, 0, 250 )
		PaintClose()
	end	
	
	close.OnMouseReleased = function()
		if not LocalPlayer().InProgress then
			main:Close()
		end
	end	
	
	main.OnClose = function()
		main:Remove()
		if main then
			main = nil
		end
	end	
	
	local inside = vgui.Create( "DPanel", main )
	inside:SetPos( 7, 27 )
	inside:SetSize( main:GetWide() - 14, main:GetTall() - 34 )
	inside.Paint = function()
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawOutlinedRect( 0, 0, inside:GetWide(), inside:GetTall() )
		surface.SetDrawColor( 255, 255, 255, 250 )
		surface.DrawRect( 1, 1, inside:GetWide() - 2, inside:GetTall() - 2 )
	end
	
	local plys = vgui.Create( "DComboBox", inside )
	plys:SetPos( 5, 5 )
	plys:SetSize( 150, 25 )
	plys:AddChoice( "Select a Player", nil, true )
	--plys.curChoice = nil
	
	for k, v in next, player.GetHumans() do
		plys:AddChoice( v:Nick(), v )
	end
	
	plys.OnSelect = function( pnl, index, value )
		local ent = plys.Data[ index ]
		plys.curChoice = ent
	end

	local method = vgui.Create( "DComboBox", inside )
	method:SetPos( 5, 35 )
	method:SetSize( 150, 25 )
	--method:AddChoice( "Select a method", nil, true )
	method:AddChoice( "render.Capture", 1, true )
	method:AddChoice( "jpeg", 2 )
	method:AddChoice( "internal", 3 )
	method.curChoice = "render.Capture"

	method.OnSelect = function( pnl, index, value )
		method.curChoice = value
	end

	local shouldfake = vgui.Create( "DCheckBoxLabel", inside )
	shouldfake:SetTextColor(Color(0,0,0))
	shouldfake:SetPos( 5, 65 )
	shouldfake:SetSize( 150, 25 )
	shouldfake:SetText("FDO")
	shouldfake:SetValue(0)
	
	local execute = vgui.Create( "DButton", inside )
	execute:SetPos( 5, inside:GetTall()-35 )
	execute:SetSize( 150, 25 )
	execute:SetText( "Screengrab" )
	execute.Think = function()
		local cur = plys.curChoice
		if plys.curChoice and method.curChoice then
			execute:SetDisabled( false )
		else
			execute:SetDisabled( true )
		end
	end
	
	execute.DoClick = function()
		if plys.curChoice then
			net.Start("LAC_SREQ")
			net.WriteBool(false)
			net.WriteEntity(plys.curChoice)
			net.WriteString(method.curChoice)
			net.WriteBool(shouldfake:GetChecked())
			net.SendToServer()
		end
	end

end
LAC.netReceive("LAC_REQSNI", LAC.gcap.OpenSGMenu)

--
--		funny story for the lua-stealers reading this.
--		I initially added this and i actually never verified server-side that a player requested a screenshot
--		which means you could legit just do
--
--		print("attempting to send a dickpic to admin")
--		net.Start("LAC_SREQ")
--		net.WriteBool(true)
--		net.WriteEntity(Entity(1))
--		net.WriteString("DICK PIC HERE")
--		net.SendToServer()
--
--		and it'd open a fucking dick on the admin's screen. 
--
--		me gamer.
--
--		hi wolfi UwU

