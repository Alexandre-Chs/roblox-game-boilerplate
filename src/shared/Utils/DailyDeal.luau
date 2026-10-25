--!strict

-- Pure rules for the shop's daily deal, shared by ShopService (charges the price) and the
-- Shop screen (shows it). One catalog item per UTC day is discounted.
local DailyDeal = {}

function DailyDeal.Today(unixSeconds: number): number
	return unixSeconds // 86400
end

-- Seconds until the deal changes (next UTC midnight).
function DailyDeal.SecondsLeft(unixSeconds: number): number
	return 86400 - math.floor(unixSeconds) % 86400
end

-- The discounted item id for a day, rotating through items in Order.
-- items: catalog entries with Id and Order (ShopCatalog.Items).
function DailyDeal.ItemId(day: number, items: { any }): string?
	if #items == 0 then
		return nil
	end
	local sorted = table.clone(items)
	table.sort(sorted, function(a, b)
		return a.Order < b.Order
	end)
	return sorted[day % #sorted + 1].Id
end

-- Price actually charged for an item on a day. Never below 1.
function DailyDeal.Price(
	item: any, -- a catalog entry with Id and Price
	day: number,
	items: { any },
	discount: number
): number
	if DailyDeal.ItemId(day, items) ~= item.Id then
		return item.Price
	end
	return math.max(1, math.floor(item.Price * (1 - discount) + 0.5))
end

return DailyDeal
