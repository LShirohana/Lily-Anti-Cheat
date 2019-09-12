local LAC = {}

LAC.shared_files_to_include =
			{
			"detections/modules/cl_cvars.lua"
			}

LAC.include = include
LAC.AddCSLuaFile = AddCSLuaFile

if (SERVER) then
	LAC.include("sv_lilyac.lua")
	
	for k, v in pairs(LAC.shared_files_to_include) do
		LAC.AddCSLuaFile(v)
	end
end

if (CLIENT) then
	for k, v in pairs(LAC.shared_files_to_include) do
		LAC.include(v)
	end
end