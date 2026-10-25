--!strict

-- Groups script errors from the server (ScriptContext.Error) and from clients (ReportError packet,
-- sent by AppController) and logs each distinct error at most once a minute per side through
-- TelemetryService:Error (Creator Dashboard custom event "ScriptError"). In Studio it prints them.
-- Roblox's own Creator Dashboard Error Report also lists errors; this adds grouping by message
-- and client errors tied to a player. Analytics keeps a limited number of distinct custom field
-- values and buckets the rest as "Other", so read rare errors in the Error Report instead.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Errors = require(script.Errors)

local WINDOW = 60

local ErrorReportService = { Name = "ErrorReportService", Dependencies = { "TelemetryService" } }
local services: { [string]: any } = {}
local trove = Trove.new()
local seen: { [string]: number } = {}

local function report(side: "Server" | "Client", message: string, player: Player?)
	local key = Errors.Key(message)
	if not Errors.Throttle(seen, `{side} {key}`, os.clock(), WINDOW) then
		return
	end
	-- Custom events need a player; a server error is attributed to anyone present.
	local reporter = player or Players:GetPlayers()[1]
	if reporter then
		services.TelemetryService:Error(reporter, side, key)
	end
end

function ErrorReportService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function ErrorReportService.Start(_self: any)
	trove:Connect(ScriptContext.Error, function(message: string)
		report("Server", message, nil)
	end)
	trove:Add(Packets.ReportError.OnServerEvent:Connect(function(player: Player, message: any)
		if type(message) == "string" then
			report("Client", message, player)
		end
	end) :: any)
end

function ErrorReportService.Destroy(_self: any)
	trove:Clean()
	table.clear(seen)
end

return ErrorReportService
