--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local function signal()
	local callbacks = {}
	return {
		Connect = function(_self, callback)
			table.insert(callbacks, callback)
			return { Disconnect = function() end }
		end,
		Fire = function(_self, ...)
			for _, callback in callbacks do
				callback(...)
			end
		end,
	}
end

local function load(studio: boolean, failing: boolean?)
	local calls, printed, warned = {}, {}, {}
	local guid = 0
	local analytics = setmetatable({}, {
		__index = function(_self, method)
			return function(_analytics, ...)
				if failing then
					error("throttled")
				end
				table.insert(calls, { method, ... })
			end
		end,
	})
	local services = {
		AnalyticsService = analytics,
		HttpService = {
			GenerateGUID = function()
				guid += 1
				return `guid{guid}`
			end,
		},
		RunService = {
			IsStudio = function()
				return studio
			end,
		},
		ReplicatedStorage = {},
	}
	local shopOpened = { OnServerEvent = signal() }
	local service = luau.load(fs.readFile("src/server/Services/TelemetryService.luau"), {
		environment = {
			game = {
				GetService = function(_self, name)
					return services[name]
				end,
			},
			require = function()
				return { ShopOpened = shopOpened }
			end,
			Enum = {
				AnalyticsEconomyFlowType = { Source = "Source", Sink = "Sink" },
			},
			print = function(text)
				table.insert(printed, text)
			end,
			warn = function(text)
				table.insert(warned, text)
			end,
		},
	})()
	local data = { PlayerLoaded = signal(), PlayerReleasing = signal() }
	data.GetData = function()
		return { Cash = 7 }
	end
	service:Init({ DataService = data })
	service:Start()
	return service, data, shopOpened, calls, printed, warned
end

local player = {}
local shopType = { Name = "Shop" }

-- Live server: onboarding steps are sent once, the shop funnel needs an opening first.
local service, data, shopOpened, calls, printed = load(false)
data.PlayerLoaded:Fire(player)
service:Onboarding(player, "FirstCoin")
service:Onboarding(player, "FirstCoin")
assert(#calls == 2 and calls[1][3] == 1 and calls[1][4] == "Joined" and calls[2][4] == "FirstCoin")
service:ShopStep(player, "Purchased", "RedHat")
assert(#calls == 2, "Purchased before Opened is ignored")
shopOpened.OnServerEvent:Fire(player)
service:ShopStep(player, "Purchased", "RedHat")
assert(
	calls[4][1] == "LogFunnelStepEvent"
		and calls[4][3] == "Shop"
		and calls[4][4] == "guid1"
		and calls[4][5] == 1
)
assert(calls[5][4] == "guid1" and calls[5][5] == 2 and calls[5][7].Item == "RedHat")
shopOpened.OnServerEvent:Fire(player)
assert(calls[6][4] == "guid2", "each opening starts a new funnel session")
service:Economy(player, "Sink", 3, shopType, "RedHat")
local economy = calls[#calls]
assert(
	economy[1] == "LogEconomyEvent"
		and economy[3] == "Sink"
		and economy[5] == 3
		and economy[6] == 7
		and economy[7] == "Shop"
)
assert(#printed == 0)
assert(not pcall(service.Onboarding, service, player, "Typo"), "unknown steps fail loudly")
data.PlayerReleasing:Fire(player)
service:Onboarding(player, "FirstPurchase")
assert(calls[#calls] == economy, "nothing is sent after the player leaves")

-- Studio prints instead of calling Roblox.
local studioService, studioData, _, studioCalls, studioPrinted = load(true)
studioData.PlayerLoaded:Fire(player)
studioService:Custom(player, "DailyStreak", 2)
assert(
	#studioCalls == 0
		and studioPrinted[1] == "[Analytics] onboarding 1 Joined"
		and studioPrinted[2] == "[Analytics] custom DailyStreak 2"
)

-- Analytics failures never throw into gameplay.
local failingService, failingData, _, _, _, warned = load(false, true)
failingData.PlayerLoaded:Fire(player)
failingService:Custom(player, "X")
assert(#warned == 2)

print("PASS telemetry: onboarding once, shop funnel sessions, economy, Studio printing, failures contained")
return true
