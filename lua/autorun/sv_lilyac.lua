local shared_files_to_include =
			{
			"detections/modules/cl_cvars.lua"
			}

if (SERVER) then
	include("lilyac.lua")
	for k, v in pairs(shared_files_to_include) do
		AddCSLuaFile(v)
	end
end

if (CLIENT) then
	for k, v in pairs(shared_files_to_include) do
		include(v)
	end
end