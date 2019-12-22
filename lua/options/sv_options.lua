LAC = LAC or {}
LAC.Options = LAC.Options or {} -- dont wanna reset our options accidentally.

--[[
	The following are available options for the anti-cheat. 
	You can make more here and so forth, simply go to the function "LAC.InitializeOptions" to set them.
	
		LAC_Enabled
		LAC_BanSystem
			LAC_BanSystemInternal
		LAC_DetectionSystem
		LAC_PreventReload
	
--]]

function LAC.InitializeOptions()
	LAC.SetOptionValue("LAC_Enabled", true, "Global Switch to turn the AC on and off.")
	LAC.SetOptionValue("LAC_BanSystem", "default", "The type of ban system to use. Leave to default unless you'd like to override it.")
	LAC.SetOptionValue("LAC_DetectionSystem", true, "Turn on the detection system.")
	LAC.SetOptionValue("LAC_PreventReload", true, "Prevent the AC from being reloaded due to lua-refresh.")
	
	LAC.SetBanSystem() -- This sets the default BanSystem. Keep @ the end.
end

function LAC.SetOptionValue(option, value, description)
	if (option == nil or option == "") then return end
	if (value == nil or value == "") then return end
	if (description == nil) then description = "" end -- Its okay to not describe it.
	
	LAC.Options[option] = {val = value, desc = decription};
end

function LAC.GetOptionValue(option)
	if (option == nil or option == "") then return end
	local optionValue = LAC.Options[option].val

	-- If you access an invalid option, it'll return nil rather than cause an error.
	return optionValue or nil
end

function LAC.GetOptionDesc(option)
	if (option == nil or option == "") then return end
	
	-- If you access an invalid option, it'll return nil rather than cause an error.
	return LAC.Options[option].desc or nil
end

function LAC.SetBanSystem()
	-- To make this way easier to read, I do this lmao.
	local GOV = LAC.GetOptionValue
	local SOV = LAC.SetOptionValue
	local BanSystemOption = GOV("LAC_BanSystem")
	
	if (BanSystemOption == nil) then -- If its nil (???????????), then default to source sdk bans for safety
		SOV("LAC_BanSystemInternal", "sdk", "Internally chosen ban system")
		return
	end
	
	if (BanSystemOption != "default") then 
		SOV("LAC_BanSystemInternal", BanSystemOption, "Internally chosen ban system") 
		return 
	end;

	if (ulx) then
		SOV("LAC_BanSystemInternal", "ulx", "Internally chosen ban system")
		return
	end
	
	--[[
	Adding new admin mods takes like 3 seconds, for now, it only suppors default gmod/ulx. 
	Bug me if you need me to add more!
	--]]
end