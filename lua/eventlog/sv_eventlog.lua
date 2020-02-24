LAC = LAC or {}

local ostime = os.time
local osdate = os.date

LAC.sqlQuery = sql.Query
LAC.sqlBegin = sql.Begin
LAC.sqlCommit = sql.Commit
LAC.sqlSQLStr = sql.SQLStr

LAC.BeginSQLQuery =  LAC.BeginSQLQuery or true

if (!sql.TableExists( "player_lac" )) then
	LAC.sqlQuery( [[CREATE TABLE IF NOT EXISTS player_lac( player_id INTEGER NOT NULL PRIMARY KEY, recent_ip TEXT NOT NULL, banned_status INTEGER NOT NULL);]] )
	LAC.sqlQuery( "CREATE INDEX IDX_LAC_PLAYER ON player_lac ( player_id DESC );" )
end

if (!sql.TableExists( "detections_lac" )) then
	LAC.sqlQuery( [[CREATE TABLE IF NOT EXISTS detections_lac( id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, player_id INTEGER NOT NULL, date INTEGER NOT NULL, reason TEXT NOT NULL, ban_severity INTEGER NOT NULL);]]);
	LAC.sqlQuery( "CREATE INDEX IDX_LAC_DETECTIONS ON detections_lac ( player_id DESC );" )
end

if (!sql.TableExists( "logs_lac" )) then
	LAC.sqlQuery( [[CREATE TABLE IF NOT EXISTS logs_lac( id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, date INTEGER NOT NULL, log_string TEXT NOT NULL);]] )
end

-- lol
if (true) then
	LAC.sqlQuery( [[CREATE VIEW IF NOT EXISTS playersToBan AS
	SELECT
		detections_lac.player_id,
		MAX(detections_lac.ban_severity) AS ban_severity,
		MIN(detections_lac.date) AS date
	FROM
		detections_lac
	INNER JOIN 
		player_lac ON player_lac.player_id = detections_lac.player_id
	WHERE
		player_lac.banned_status == 1
	GROUP BY
		detections_lac.player_id;]] )
end

function LAC.GetDate(form)
	-- European format sorta. im sorry lmao
	if (form == nil or form == "") then
		return osdate( "[%H:%M:%S - %m/%d/%Y] ", ostime())
	else
		return osdate( form, ostime())
	end
end

function LAC.LogNeutralEvent(log)
	if (LAC.BeginSQLQuery) then
		LAC.sqlBegin()
		LAC.BeginSQLQuery = false
	end

	LAC.sqlQuery( "INSERT into logs_lac ( date, log_string) VALUES ( " .. ostime() .. ", " .. LAC.sqlSQLStr(log) .. " );")
end

function LAC.LogDetection(uid, reason, banvalue)
	if (LAC.BeginSQLQuery) then
		LAC.sqlBegin()
		LAC.BeginSQLQuery = false
	end

	local query =  "INSERT into detections_lac ( player_id, date, reason, ban_severity) VALUES ( " .. uid .. ", " .. ostime() .. ", " .. LAC.sqlSQLStr(reason) .. ", " .. banvalue .. " );"
	LAC.sqlQuery(query)
end

--[[
banned_status values:
0 = not banned
1 = will be banned
2 = already banned
]]

function LAC.GetBanStatus(uid)
	local row = sql.QueryRow( "SELECT player_id, banned_status FROM player_lac WHERE player_id = " .. uid .. ";" )
	if (row) then
		return row.banned_status
	else
		return 0
	end
end

function LAC.SetBanStatus(uid, value)
	LAC.sqlQuery( "UPDATE player_lac SET banned_status = " .. value .. " WHERE player_id = " .. uid .. ";")
end

function LAC.GetPlayersToBan()
	return sql.Query("SELECT * FROM playersToBan")
end

function LAC.LogPlayer(ply)
	local uid = ply:SteamID64()
	local ip = ply:IPAddress()

	local row = sql.QueryRow( "SELECT player_id FROM player_lac WHERE player_id = " .. uid .. ";" )

	if (LAC.BeginSQLQuery) then
		LAC.sqlBegin()
		LAC.BeginSQLQuery = false
	end

	if (row) then
		LAC.sqlQuery( "UPDATE player_lac SET recent_ip = " .. LAC.sqlSQLStr(ip) .. " WHERE player_id = " .. uid .. ";")
	else
		LAC.sqlQuery( "INSERT into player_lac ( player_id, recent_ip, banned_status) VALUES (" .. uid .. ", " .. LAC.sqlSQLStr(ip) .. ", " .. 0 .. ");")
	end
end

-- I batch all queries and then commit all of em @ think.
function LAC.CommitAllQueries()
	if (!LAC.BeginSQLQuery) then
		LAC.sqlCommit()
		LAC.BeginSQLQuery = true
	end
end
hook.Add("Tick", "LAC_SQLITE_COMMIT", LAC.CommitAllQueries)

function LAC.LastQueryCommit()
	LAC.sqlCommit() -- GOGOGO
end
hook.Add("ShutDown", "LAC_SQLITE_COMMIT_SHUTDOWN", LAC.LastQueryCommit)

--[[
PlayerTable:
	PLAYER_ID primkey
	NAME_HISTORY
	IP_ADDRESS

DETECTION_TABLE:
	ID AUTOINCREMENT INT NOT NULL
	PLAYER_ID 
	DATE
	REASON
	VALUE
	BANNED_BOOL

LOG_TABLE
	ID AUTOINCREMENT INT NOT NULL
	TIME
	LOG_STRING
]]

--[[

-- old stuff goes here
local fileappend = file.Append

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

function LAC.LogServerError(eventString)
	LAC.LogEvent(eventString, LAC.GetDate("%d-%m-%Y-log"), LAC.ServerErrorsDirectoryName)
end

function LAC.LogClientError(eventString, ply)
	local steamid64 = ply:SteamID64()
	LAC.LogEvent(eventString, steamid64, LAC.ClientErrorDirectoryName)
end

function LAC.LogClientDetections(eventString, ply)
	local steamid64 = ply:SteamID64()
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
	local stringToWrite = date  .. "[" .. LAC.Version .. "] " .. eventString .. "\n"
	fileappend( fullDirName .. "/" .. fileName .. ".txt", stringToWrite)
end]]

--LAC.LogEvent("Event Log System Loaded.", LAC.GetDate("%d-%m-%Y-log"), LAC.MainLogFile)