--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local DailyDeal = require(ReplicatedStorage.Utils.DailyDeal)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Purchasing = require(script.Purchasing)

local ShopService = {
	Name = "ShopService",
	Dependencies = {
		"DataService",
		"TelemetryService",
		"AchievementService",
		"TutorialService",
		"ComplianceService",
	},
}
local services: { [string]: any } = {}

local function buy(player: Player, itemId: any): (boolean, string)
	local dataService = services.DataService
	local data = dataService:GetData(player)
	if not data then
		return false, "NotLoaded"
	end
	-- The server clock decides which item is on deal; the client only displays it.
	local day = DailyDeal.Today(os.time())
	local function priceOf(item: any): number
		return DailyDeal.Price(item, day, ShopCatalog.Items, GameConfig.ShopDealDiscount)
	end
	local item = ShopCatalog.ById[itemId]
	if item and item.Random and not services.ComplianceService:RandomItemsAllowed(player) then
		return false, "Unavailable"
	end
	local result = Purchasing.Check(data, ShopCatalog.ById, itemId, priceOf)
	if result ~= "Ok" then
		return false, result
	end
	local price = priceOf(ShopCatalog.ById[itemId])
	-- No yield between the check and both writes, so the price cannot be spent twice.
	if not dataService:AdjustCash(player, -price) then
		return false, "NotEnoughCash"
	end
	dataService:Set(player, { "Inventory", itemId }, true)
	local telemetry = services.TelemetryService
	telemetry:Economy(player, "Sink", price, Enum.AnalyticsEconomyTransactionType.Shop, itemId)
	telemetry:ShopStep(player, "Purchased", itemId)
	telemetry:Onboarding(player, "FirstPurchase")
	services.AchievementService:Award(player, "FirstPurchase")
	services.TutorialService:Reached(player, "FirstPurchase")
	return true, "Ok"
end

function ShopService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function ShopService.Start(_self: any)
	Packets.BuyItem.OnServerInvoke = buy
end

function ShopService.Destroy(_self: any)
	Packets.BuyItem.OnServerInvoke = nil
end

return ShopService
