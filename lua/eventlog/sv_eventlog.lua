LAC = LAC or {}

-- Known directories for writing logs and events.

-- Main directory, all subsequent directories are after this. EG: "lac/players"
LAC.ServerLogDirectory = "lac/"

-- Directory for player logs
LAC.ServerPlayerDetections = "players"

-- Lua errors from the server
LAC.ServerErrors = "errors"

-- Lua errors from the client. client errors -> clierrors
LAC.ClientErrors = "clierrors"

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
	LAC.LogEvent(eventString, LAC.GetDate("%d-%m-%Y-log"), LAC.ServerErrors)
end

function LAC.LogClientError(eventString, id)
	LAC.LogEvent(eventString, id, LAC.ClientErrors)
end

function LAC.LogClientDetections(eventString, id)
	LAC.LogEvent(eventString, id, LAC.ServerPlayerDetections)
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
		LAC.LogServerError("No filename passed!")
		fileName = "LogFile" -- Default file name
	end
	
	if (fileDir == nil or fileDir == "") then
		LAC.LogServerError("No directory name passed!")
		fileDir = LAC.ServerErrors -- default directory, if something is in here, something went wrong.
	end
	
	local fullDirName = (LAC.ServerLogDirectory .. fileDir)

	if (file.Exists(fullDirName, "DATA") == false) then
		file.CreateDir(fullDirName)
	end

	local date = LAC.GetDate() -- default format is gud
	local stringToWrite = date .. eventString .. "\n"
	fileappend( fullDirName .. "/" .. fileName .. ".txt", stringToWrite)
end

LAC.LogEvent("Event Log System Loaded.", LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)