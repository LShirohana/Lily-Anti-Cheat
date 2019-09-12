LAC = LAC or {}
LAC.ServerLogDirectory = "lac/"
LAC.ServerPlayerDetections = "players"
LAC.MainLogFile = "logs"

local ostime = os.time
local osdate = os.date

function LAC.GetDate(form)
	-- European format. im sorry lmao
	if (form == nil or form == "") then
		return osdate( "[%H:%M:%S - %d/%m/%Y] " , ostime())
	else
		return osdate( form, ostime())
	end
end

function LAC.LogEvent(eventString, fileName, fileDir)
	if (eventString == nil or eventString == "") then return end
	local fullDirName = (LAC.ServerLogDirectory .. fileDir)

	if (file.Exists(fullDirName, "DATA") == false) then
		file.CreateDir(fullDirName)
	end

	local date = LAC.GetDate()
	local stringToWrite = date .. eventString .. "\n"
	file.Append( fullDirName .. "/" .. fileName .. ".txt", stringToWrite)
end

LAC.LogEvent("Event Log System Loaded.", LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)

