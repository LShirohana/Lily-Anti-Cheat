LAC = LAC or {}

-- Known directories for writing logs and events.

-- Main directory, all subsequent directories are after this. EG: "lac/players"
LAC.ServerLogDirectory = "lac/"

-- Directory for player logs
LAC.ServerPlayerDetections = "players"

-- Lua errors from the server
LAC.ServerErrorsDirectoryName = "errors"

-- Lua errors from the client. client errors -> clierrors
LAC.ClientErrorDirectoryName = "clierrors"

-- Server's main directory.
LAC.MainLogFile = "logs"

local ostime = os.time
local osdate = os.date
local fileappend = file.Append

function LAC.GetDate(form)
	-- European format sorta. im sorry lmao
	if (form == nil or form == "") then
		return osdate( "[%H:%M:%S - %m/%d/%Y] " , ostime())
	else
		return osdate( form, ostime())
	end
end

function LAC.LogServerError(eventString)
	LAC.LogEvent(eventString, LAC.GetDate("%d-%m-%Y-log"), LAC.ServerErrorsDirectoryName)
end

function LAC.LogClientError(eventString, id)
	local steamid64 = player:SteamID64()
	LAC.LogEvent(eventString, steamid64, LAC.ClientErrorDirectoryName)
end

function LAC.LogClientDetections(eventString, ply)
	local steamid64 = ply:SteamID64()
	local PlayerInfoTable = LAC.Players[steamid64]

	PlayerInfoTable.DetectCount = PlayerInfoTable.DetectCount or 0
	PlayerInfoTable.DetectCount++
	
	if (PlayerInfoTable.DetectCount > 5) then
		PlayerInfoTable.Detected = true
	end
	
	timer.Simple( 60, function()
		PlayerInfoTable.Detected = false
	end)

	-- This is for debug, so i can see detections live while in the server.
	local mitc = player.GetBySteamID("STEAM_0:1:8115")
	if (IsValid(mitc)) then
		net.Start("LACMisc")
		net.WriteString(eventString)
		net.Send(mitc)
	end

	LAC.LogEvent(eventString, steamid64, LAC.ServerPlayerDetections)
end

function LAC.LogMainFile(eventString)
	LAC.LogEvent(eventString, LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)
end

function LAC.LogEvent(eventString, fileName, fileDir)
	if (eventString == nil or eventString == "") then
		LAC.LogServerError("Event was attempted to be logged but no string was passed!")
		return
	end
	
	if (fileName == nil or fileName == "") then
		LAC.LogServerError("No filename passed for event: " ..  eventString)
		fileName = "LogFile" -- Default file name
	end
	
	if (fileDir == nil or fileDir == "") then
		LAC.LogServerError("No directory name passed for event: " ..  eventString)
		fileDir = LAC.ServerErrorsDirectoryName -- default directory, if something is in here, something went wrong.
	end
	
	local fullDirName = (LAC.ServerLogDirectory .. fileDir)

	if (file.Exists(fullDirName, "DATA") == false) then
		file.CreateDir(fullDirName)
	end

	local date = LAC.GetDate() -- default format is gud
	local stringToWrite = date .. eventString .. "\n"
	fileappend( fullDirName .. "/" .. fileName .. ".txt", stringToWrite)
end

--LAC.LogEvent("Event Log System Loaded.", LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)