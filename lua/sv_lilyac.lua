--[[
	Hello! This is LAC, or Lily Anti Cheat
	created by Lily/Mitch @ /id/veryflower or STEAM_0:1:8115
	This is a beta-version, which is currently working slightly.

	Credits to helpers/Ideas/Etc:
		!cake, for CAC -- borrowed (stole) his ideas for detections
		Aromatic -- Module base and ideas.
		GrandpaTroll -- Heavy help on ideas and screengrab add-on
		Keith -- Ideas for more detections.
		LeyStryku -- Helping me sort out false detections and other stuffers
		Wolfie -- Helping me figur out more detections yey
		Nick -- Optimizations
		Zero -- moral support and debugging
		My teachers in Uni -- literally helped me write database stuff and architecture lmao
	
	There is no planned GUI for the anti-cheat because:
		* I am terrible at design and menus, and have always sucked at it.
		* Most users aren't very knowledgeable on how cheats work and so on, therefore providing options for them is pointless.
		
	While it might happen in the future, it won't happen until the very end, at the least.
	
	The file(s) will be annotated where neccesary.
	If you have any questions as to how this works, feel free to message me! I love to talk about programming.
	
	If you are reading this and you are not supposed to, you should contact me and tell me how you did it!!!
	After all, programming is not any fun unless you learn, right?
--]]

--Initial creation of the anti-cheat.
LAC = LAC or {}
LAC.MsgC = MsgC
LAC.include = include
LAC.MsgC(Color(240,10,10), "LAC Server-side Starting up!\n")
LAC.Version = 0.09
LAC.TickInterval = math.floor((1 / engine.TickInterval()))

-- To prevent multiple copies of the AC from running.
if (LAC && LAC.Options && LAC.GetOptionValue("LAC_PreventReload")) then
	LAC.LogEvent("System is already loaded! Preventing reload.", LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)
	return
end

-- hash used to sanitize users input. do not change unless you want 24/7 false results once implemented.
LAC.Detect = "A9B90B05C64DF362333F4F44C8D5D8CA00F823B3"

--[[ 
	Modules for the anti-cheat load here.
		Load order currently:
			Options
			Logging
			Detection
				Server-side MISC detections (CUserCmd, angles, Bhop, ETC)
				Cvar Detection (Change callback + ask clients for their values via challenges)
--]]

-- Options for the AC
LAC.include("options/sv_options.lua")
LAC.InitializeOptions()

-- Now to check the global option of should we even run the AC!
if (!LAC.GetOptionValue("LAC_Enabled")) then
	LAC.MsgC(Color(10,240,10), string.format("LAC Version %.2f has been shut off in the config. Preventing further loading.\n", LAC.Version))
	LAC.LogMainFile("LAC has been disabled by config.")
	return
end


-- Log System
LAC.include("eventlog/sv_eventlog.lua")
-- Message/Informing System
LAC.include("inform/sv_inform.lua")
-- Player Processing/Punishiment
LAC.include("infoprocessing/sv_playerprocessing.lua")
LAC.include("infoprocessing/sv_punishmentsystem.lua")
-- Detection System (and sub-systems)
LAC.include("detections/sv_detectionsystem.lua")

LAC.MsgC(Color(10,240,10), string.format("LAC Version %.2f Finished Loading!\n", LAC.Version))