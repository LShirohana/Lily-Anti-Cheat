LAC = LAC or {}
LAC.MsgC = MsgC

-- hash used to sanitize users input. do not change unless you want 24/7 false results once implemented.
LAC.Detect = A9B90B05C64DF362333F4F44C8D5D8CA00F823B3

LAC.MsgC(Color(240,10,10), "LAC Starting up!\n")

-- created by Lily @ /id/veryflower. License to use is extended to GFL until I say otherwise. 

-- logging.
include("eventlog/sv_eventlog.lua")

-- detection system.
include("detections/sv_detectionsystem.lua")



LAC.MsgC(Color(10,240,10), "LAC Finished Loading!\n")