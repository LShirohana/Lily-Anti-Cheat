LAC = LAC or {}

-- We will be adding many more network strings in the future, as well as dynamic ones.
util.AddNetworkString( "LACData" )
util.AddNetworkString( "LACDataC" )
util.AddNetworkString( "LACHeart" )
util.AddNetworkString( "LACMisc" ) 

--[[
	Load detection sub-modules.
		TODO: Make it dynamic rather than statically generated.
]]--
include("detections/modules/sv_cvars.lua")



LAC.LogMainFile("Detection System Loaded.")