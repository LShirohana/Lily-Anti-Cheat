LAC = LAC or {}
LAC.Players = LAC.Players or {}

include("sv_utility.lua")

--[[
	helper functions
]]

function LAC.GetPTable(ply)
    if (IsValid(ply)) then
        return LAC.Players[ply:SteamID64()]
    else
        return nil
    end
end

-- This is called assuming you verified ply b4 calling.
function LAC.InitializePlayerTable(ply)
	LAC.Players[ply:SteamID64()] = 
	{
		pInfo = 
		{
			Name = ply:Nick(), 
			SteamID32 = ply:SteamID(),
            SteamID64 = ply:SteamID64(),
            UsesController = false,
		},

		DetectionInfo = 
		{
            ConfidentDetected = false,
            Detected = false,
            UnlikelyDetections = 0,
            AnomalyDetections = 0,
		},

		InputData =
		{
            TimesTriggered = 0,
            TriggerHistory = {},
        },
        
        AngleDetection = 
        {
            InformedAdminsMax = 4,
            InformedAdmins = 0,
        },

		AimbotDetection = 
		{
			DeltaAngleValues = {},
			DDeltaAngleValues = {},
			HitByExplosive = false,
		},

		BhopDetection = 
		{
            InformedAdminsMax = 4,
            InformedAdmins = 0,

			PerfectJump = 0,
			JumpCounter2 = 0,
			TickTable = {},
			JumpHistory = {},
			OnGround = false,
			InJump = false,
		},

		KeyData = 
		{
			SuspiciousKeyUsage = 0,
		},

		HeartBeatInfo =
		{
			RespondedTimer = 0
		},
	};
end

function LAC.PlayerSpawn(ply, steamid, uniqueid)
	if (!IsValid(ply) or ply:IsBot()) then return end

	local id64 = ply:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		-- 90071996842377216 is the id of a bot.
		return
	end

	LAC.LogPlayer(ply)
	LAC.InitializePlayerTable(ply)
end

function LAC.PlayerDisconnect(ply)
	if (!IsValid(ply) or ply:IsBot()) then return end

	local id64 = ply:SteamID64()
	if (id64 == "90071996842377216" or id64 == "") then
		return
	end

	LAC.Players[id64] = nil;
end

function LAC.BanPlayer(uid)
	local steamid32 = util.SteamIDFrom64( tostring(uid) )
	LAC.SetBanStatus(uid, 2)
	RunConsoleCommand("ulx", "sbanid", steamid32, 0, "Lily Anti-Cheat")
end

hook.Add("PlayerAuthed", "LAC_SPAWN", LAC.PlayerSpawn)
hook.Add("PlayerDisconnected", "LAC_DISCONNECT", LAC.PlayerDisconnect)