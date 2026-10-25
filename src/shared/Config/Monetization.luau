--!strict

-- Roblox ids for paid items. Id 0 means "not created yet": the offer stays inert and the
-- shop shows "Soon". Create passes and products on the Creator Dashboard of each experience
-- (test and prod have different ids, see docs/release.md) and paste the ids here.
-- Robux prices are read from Roblox at runtime, never hard-coded.
export type GamePass = { Id: number, Name: string, Description: string, Icon: string, Order: number }
export type CoinPack = {
	Id: number,
	Coins: number,
	Order: number,
	Icon: string,
	Badge: string?,
	Bonus: string?,
}
export type Monetization = {
	GamePasses: { [string]: GamePass },
	-- Developer products that grant coins; granted by PurchaseService/Products.luau.
	CoinPacks: { [string]: CoinPack },
}

local gamePasses: { [string]: GamePass } = {
	DoubleCoins = {
		Id = 0,
		Name = "2x Coins",
		Description = "Double every coin you pick up. Forever.",
		Icon = "⚡",
		Order = 1,
	},
}

-- Tiered packs: the badges and bonus labels anchor the bigger packs as better value.
local coinPacks: { [string]: CoinPack } = {
	Coins100 = { Id = 0, Coins = 100, Order = 1, Icon = "🪙" },
	Coins550 = { Id = 0, Coins = 550, Order = 2, Icon = "💰", Badge = "POPULAR", Bonus = "+10% bonus" },
	Coins1800 = { Id = 0, Coins = 1800, Order = 3, Icon = "💎", Badge = "BEST VALUE", Bonus = "+20% bonus" },
}

local Monetization: Monetization = table.freeze({
	GamePasses = table.freeze(gamePasses),
	CoinPacks = table.freeze(coinPacks),
})

return Monetization
