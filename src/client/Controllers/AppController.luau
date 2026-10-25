--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")
local TextChatService = game:GetService("TextChatService")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Locale = require(ReplicatedStorage.Utils.Locale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
type TroveInstance = typeof(Trove.new())

type State = {
	Name: string,
	_trove: TroveInstance?,
}

local AppController = {
	Name = "AppController",
	Dependencies = { "DataController" },
	_trove = nil :: TroveInstance?,
}
local registry: { [string]: any } = {}

function AppController.Init(self: State, controllers: { [string]: any })
	registry = controllers
	self._trove = Trove.new()
end

-- The printed lines are the Studio smoke test markers listed in docs/testing.md.
function AppController.Start(self: State)
	print(`[{GameConfig.Name}] Client controllers ready`)
	Locale.Prepare(Players.LocalPlayer)
	-- The starter quests sit top-left, so the chat window moves to the bottom-left.
	TextChatService.ChatWindowConfiguration.VerticalAlignment = Enum.VerticalAlignment.Bottom
	-- Forward client script errors to ErrorReportService, each distinct message once a minute.
	-- Keyed without numbers so a looping error with a changing value counts once; capped size.
	local reported: { [string]: number } = {}
	local count = 0
	if self._trove then
		self._trove:Connect(ScriptContext.Error, function(message: string)
			local key = string.gsub(message, "%d+", "#")
			local last = reported[key]
			if last and os.clock() - last < 60 then
				return
			end
			if not last then
				count += 1
				if count > 100 then
					table.clear(reported)
					count = 1
				end
			end
			reported[key] = os.clock()
			Packets.ReportError:Fire(string.sub(message, 1, 200))
		end)
	end
	local dataController = registry.DataController
	local function loaded()
		print(`[{GameConfig.Name}] Player data loaded`)
		-- The ReplicatedFirst loading screen waits for this attribute.
		Players.LocalPlayer:SetAttribute("ClientReady", true)
	end
	if dataController:IsLoaded() then
		loaded()
	elseif self._trove then
		self._trove:Add(dataController.Loaded:Once(loaded))
	end
	task.spawn(function()
		local sentAt = os.clock()
		local serverTime = Packets.Ping:Fire()
		if serverTime then
			print(`[{GameConfig.Name}] Packet round trip {math.round((os.clock() - sentAt) * 1000)} ms`)
		end
	end)
end

function AppController.Destroy(self: State)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return AppController
