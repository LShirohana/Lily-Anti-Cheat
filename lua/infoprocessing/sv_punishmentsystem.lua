LAC = LAC or {}

--[[
1. Figure out what type of detection it is. Bhop/Aimbot/Movement/Etc.
2. Determine the action based on what type of detection it is.
3. Determine if I should even inform admins/myself.
4. Create a message to inform admins or me on what it is, stylize it nicely.
6. SendMessage
]]

LAC.DetectionValue = {
    OBVIOUS = 5,
	CRITICAL = 4,
	UNLIKELY_FALSE = 3,
	ANOMALY = 2,
	SUSPICIOUS = 1,
	LOGGING_PURPOSES = 0,
}

function LAC.PlayerDetection(reasonDetected, detectValue, ply, tellAdmins, additionalLog)
	--if (!LAC.GetOptionValue("LAC_DetectionSystem")) then return end -- if you want this option. idk
	local pTable = LAC.GetPTable(ply)
	if (pTable == nil) then return end
	if (additionalLog == nil) then additionalLog = "" end

	 -- Player already marked for ban. F
	 if (pTable.DetectionInfo.Detected) then
		return
	end

	if (detectValue >= LAC.DetectionValue.CRITICAL) then
		pTable.DetectionInfo.Detected = true
		pTable.DetectionInfo.ConfidentDetected = true
	end

	if (detectValue == LAC.DetectionValue.OBVIOUS) then
		pTable.DetectionInfo.Detected = true
		pTable.DetectionInfo.ConfidentDetected = true
		if (ulx && isfunction(ulx.sbanid)) then
			LAC.LogClientDetections(reasonDetected .. " SteamID: " .. pTable.pInfo.SteamID32 .. " " .. additionalLog, ply)
			RunConsoleCommand("ulx", "sbanid", pTable.pInfo.SteamID32, 0, "Lily Anti-Cheat")
			return
		end
	end

	if (detectValue == LAC.DetectionValue.UNLIKELY_FALSE) then
		pTable.DetectionInfo.UnlikelyDetections = pTable.DetectionInfo.UnlikelyDetections + 1
	end

	if (detectValue == LAC.DetectionValue.ANOMALY) then
		pTable.DetectionInfo.AnomalyDetections = pTable.DetectionInfo.AnomalyDetections + 1
	end

	if (pTable.DetectionInfo.UnlikelyDetections > 10) then
		pTable.DetectionInfo.Detected = true
	end

	if (pTable.DetectionInfo.AnomalyDetections > LAC.TickInterval * 1.5) then
		pTable.DetectionInfo.Detected = true
	end

	--InitiatePunishment(ply); based on severity etcetc
	local MessageToAdmins = {LAC.Black, "[", LAC.Red, "LAC", LAC.Black, "] ", LAC.White, reasonDetected, LAC.Black, " SteamID: ", LAC.White, pTable.pInfo.SteamID32}
	if (tellAdmins) then
		LAC.InformAdmins(MessageToAdmins, true)
	end

	LAC.InformMitch(MessageToAdmins, true)

	-- Logging to server that a detection has occurred.
	LAC.LogClientDetections(reasonDetected .. " SteamID: " .. pTable.pInfo.SteamID32 .. " " .. additionalLog, ply)
end

local CurTime = CurTime
local mathRandom = math.random
local mathrand = math.Rand

function LAC.ReduceDamageOfCheaters(target, dmginfo)
	if (!IsValid(target) or !target:IsPlayer()) then return end
	local attacker = dmginfo:GetAttacker()
	if (!IsValid(attacker) or !attacker:IsPlayer()) then return end

	local pTable = LAC.GetPTable(attacker)
	if (pTable == nil) then return end

	if (pTable.DetectionInfo.ConfidentDetected) then
		dmginfo:ScaleDamage( mathrand(0.05, 0.40) )
	end
end

function LAC.CheaterPacketLoss(ply, cmd)
	if (!IsValid(ply) or !ply:IsPlayer()) then return end

	local pTable = LAC.GetPTable(ply)
	if (pTable == nil) then return end

	if (pTable.DetectionInfo.ConfidentDetected) then
		local pocketSand = mathRandom(50)
		if (pocketSand < 40) then
			cmd:RemoveKey(IN_JUMP)
			cmd:RemoveKey(IN_ATTACK)
			if (pocketSand < 20) then
				cmd:SetForwardMove(0)
				cmd:SetSideMove(0)
				cmd:ClearMovement() 
				--[[if (pocketSand < 2) then
					cmd:SetButtons( IN_RELOAD)
				end]]
			end
		end
	end
end

hook.Add("StartCommand", "LAC_CONFIDENT_CHEATER_PACKETLOSS", LAC.CheaterPacketLoss)
hook.Add("EntityTakeDamage", "LAC_CONFIDENT_CHEATER_DMGREDUCTION", LAC.ReduceDamageOfCheaters)