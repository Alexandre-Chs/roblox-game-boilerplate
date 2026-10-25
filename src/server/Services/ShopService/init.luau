--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Purchasing = require(script.Purchasing)

local ShopService = { Name = "ShopService", Dependencies = { "DataService" } }
local services: { [string]: any } = {}

local function buy(player: Player, itemId: any): (boolean, string)
	local dataService = services.DataService
	local data = dataService:GetData(player)
	if not data then
		return false, "NotLoaded"
	end
	local result = Purchasing.Check(data, ShopCatalog.ById, itemId)
	if result ~= "Ok" then
		return false, result
	end
	-- No yield between the check and both writes, so the price cannot be spent twice.
	if not dataService:AdjustCash(player, -ShopCatalog.ById[itemId].Price) then
		return false, "NotEnoughCash"
	end
	dataService:Set(player, { "Inventory", itemId }, true)
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
