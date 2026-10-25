--!strict

-- Pure purchase rules: no services, no instances, tested in tests/run.luau.
export type Result = "Ok" | "UnknownItem" | "AlreadyOwned" | "NotEnoughCash"

local Purchasing = {}

function Purchasing.Check(
	data: { Cash: number, Inventory: { [string]: boolean } },
	catalog: { [string]: any }, -- id -> item (ShopCatalog.ById)
	itemId: any,
	priceOf: (item: any) -> number -- the price charged today (DailyDeal.Price)
): Result
	local item = if type(itemId) == "string" then catalog[itemId] else nil
	if not item then
		return "UnknownItem"
	end
	if data.Inventory[itemId] then
		return "AlreadyOwned"
	end
	if data.Cash < priceOf(item) then
		return "NotEnoughCash"
	end
	return "Ok"
end

return Purchasing
