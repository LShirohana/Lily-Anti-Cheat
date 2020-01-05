LAC = LAC or {}

function LAC.IsButtonDown(buttons, IN_BUTTON)
	return (bit.band(buttons, IN_BUTTON) != 0);
end

function LAC.IsTTT()
	return (gmod.GetGamemode().Name == "Trouble in Terrorist Town")
end

-- lmao pls
LAC.devID = 
{
	["STEAM_0:1:8115"] = true
}

function LAC.IsGFLAdmin(ply)
	return ply:IsUserGroup("trialadmin") or ply:IsAdmin() or LAC.devID[ply:SteamID()]
end

-- This uses ipairs!! Dont have non-numeric keys!!
function LAC.getMean( t )
	local sum = 0
	local count= 0

	for k, v in ipairs(t) do
		sum = sum + v
		count = count + 1
	end

	return (sum / count)
end

local math_sqrt = math.sqrt
-- This uses ipairs!! Dont have non-numeric keys!!
function LAC.stDev( t )
	local m
	local vm
	local sum = 0
	local count = 0
	local result
	m = getMean( t )
	for k,v in ipairs(t) do
		vm = v - m
		sum = sum + (vm * vm)
		count = count + 1
	end
	result = math_sqrt(sum / (count-1))
	return result
end