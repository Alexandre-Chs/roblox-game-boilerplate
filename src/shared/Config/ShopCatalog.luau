--!strict

-- Placeholder items for the starter shop. Replace with the game's real catalog.
-- Prices are in Cash; the server is the only place a purchase is decided.
-- Icon: an emoji placeholder, or an "rbxassetid://..." image once real icons exist.
export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"
export type Item = {
	Id: string,
	Name: string,
	Price: number,
	Order: number,
	Icon: string,
	Rarity: Rarity,
}

local items: { Item } = {
	{ Id = "RedHat", Name = "Red Hat", Price = 3, Order = 1, Icon = "🎩", Rarity = "Common" },
	{ Id = "SpeedBoots", Name = "Speed Boots", Price = 10, Order = 2, Icon = "👟", Rarity = "Rare" },
	{ Id = "MagicWand", Name = "Magic Wand", Price = 25, Order = 3, Icon = "🪄", Rarity = "Epic" },
	{ Id = "GoldenCrown", Name = "Golden Crown", Price = 50, Order = 4, Icon = "👑", Rarity = "Legendary" },
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
