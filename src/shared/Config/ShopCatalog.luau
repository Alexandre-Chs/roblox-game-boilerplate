--!strict

-- Placeholder items for the starter shop. Replace with the game's real catalog.
-- Prices are in Cash; the server is the only place a purchase is decided.
export type Item = {
	Id: string,
	Name: string,
	Price: number,
	Order: number,
}

local items: { Item } = {
	{ Id = "RedHat", Name = "Red Hat", Price = 3, Order = 1 },
	{ Id = "SpeedBoots", Name = "Speed Boots", Price = 10, Order = 2 },
	{ Id = "GoldenCrown", Name = "Golden Crown", Price = 50, Order = 3 },
}

local byId: { [string]: Item } = {}
for _, item in items do
	assert(byId[item.Id] == nil, `Duplicate shop item {item.Id}`)
	byId[item.Id] = table.freeze(item)
end

return table.freeze({
	Items = table.freeze(items),
	ById = table.freeze(byId),
})
