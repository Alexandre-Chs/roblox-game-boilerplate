--!strict

-- Thin wrapper over Roblox AnalyticsService (results: Creator Dashboard > Analytics).
-- Roblox records these only from published servers. In Studio every event is printed
-- as "[Analytics] ..." instead, so playtests can check that events fire at the right time.
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)

-- First-session funnel. Steps are logged at most once per player per server.
local ONBOARDING = { "Joined", "FirstCoin", "OpenedShop", "FirstPurchase" }
-- Recurring shop funnel: one session per shop opening.
local SHOP_STEPS = { "Opened", "Purchased" }
local CURRENCY = "Coins"

local TelemetryService = { Name = "TelemetryService", Dependencies = { "DataService" } }
local services: { [string]: any } = {}
local sentOnboarding: { [Player]: { [number]: true } } = {}
local shopSessions: { [Player]: string } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}
local studio = RunService:IsStudio()

local function send(label: string, call: () -> ...any)
	if studio then
		print(`[Analytics] {label}`)
		return
	end
	-- Analytics must never break gameplay: failures are only warned.
	local ok, problem = pcall(call)
	if not ok then
		warn(`[TelemetryService] {label} failed: {problem}`)
	end
end

function TelemetryService.Onboarding(_self: any, player: Player, stepName: string)
	local step = table.find(ONBOARDING, stepName)
	assert(step, `Unknown onboarding step {stepName}`)
	local sent = sentOnboarding[player]
	if not sent or sent[step] then
		return
	end
	sent[step] = true
	send(`onboarding {step} {stepName}`, function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

-- flow: "Source" (coins earned) or "Sink" (coins spent). amount is always positive.
function TelemetryService.Economy(
	_self: any,
	player: Player,
	flow: "Source" | "Sink",
	amount: number,
	transactionType: Enum.AnalyticsEconomyTransactionType,
	itemSku: string
)
	local data = services.DataService:GetData(player)
	local balance = if data then data.Cash else 0
	send(`economy {flow} {amount} {transactionType.Name} {itemSku} balance {balance}`, function()
		AnalyticsService:LogEconomyEvent(
			player,
			if flow == "Source"
				then Enum.AnalyticsEconomyFlowType.Source
				else Enum.AnalyticsEconomyFlowType.Sink,
			CURRENCY,
			math.abs(amount),
			balance,
			transactionType.Name,
			itemSku
		)
	end)
end

function TelemetryService.Custom(_self: any, player: Player, eventName: string, value: number?)
	send(`custom {eventName} {value or 1}`, function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
end

-- One grouped script error (ErrorReportService). side is "Server" or "Client"; key is short and
-- free of numbers so the dashboard groups occurrences of the same bug.
function TelemetryService.Error(_self: any, player: Player, side: string, key: string)
	send(`error {side} {key}`, function()
		AnalyticsService:LogCustomEvent(player, "ScriptError", 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = side,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = key,
		})
	end)
end

-- Shop funnel step; "Opened" starts a new funnel session.
function TelemetryService.ShopStep(_self: any, player: Player, stepName: string, itemId: string?)
	local step = table.find(SHOP_STEPS, stepName)
	assert(step, `Unknown shop step {stepName}`)
	if step == 1 then
		shopSessions[player] = HttpService:GenerateGUID(false)
	end
	local session = shopSessions[player]
	if not session then
		return
	end
	local fields = if itemId then { Item = itemId } else nil
	send(`shop {step} {stepName}{if itemId then " " .. itemId else ""}`, function()
		AnalyticsService:LogFunnelStepEvent(player, "Shop", session, step, stepName, fields)
	end)
end

function TelemetryService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function TelemetryService.Start(_self: any)
	local dataService = services.DataService
	dataService.PlayerLoaded:Connect(function(player: Player)
		sentOnboarding[player] = {}
		TelemetryService:Onboarding(player, "Joined")
	end)
	dataService.PlayerReleasing:Connect(function(player: Player)
		sentOnboarding[player] = nil
		shopSessions[player] = nil
	end)
	table.insert(
		connections,
		Packets.ShopOpened.OnServerEvent:Connect(function(player: Player)
			TelemetryService:Onboarding(player, "OpenedShop")
			TelemetryService:ShopStep(player, "Opened")
		end) :: any
	)
end

function TelemetryService.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return TelemetryService
