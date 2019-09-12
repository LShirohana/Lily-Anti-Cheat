LAC = LAC or {}

-- This system @ the start will be inflexible and probably wont be updated to use 40 different admin mods. 
-- ULX is where it'll start, most likely.
util.AddNetworkString( "LACData" )
util.AddNetworkString( "LACDataC" )
util.AddNetworkString( "LACHeart" )
util.AddNetworkString( "LACMisc" ) 

-- cvar system initial.
include("detections/modules/sv_cvars.lua")



LAC.LogEvent("Detection System Loaded.", LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)