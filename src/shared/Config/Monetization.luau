--!strict

-- Roblox ids for paid items. 0 means "not created yet": the feature stays inert and the
-- shop says so. Create passes and products on the Creator Dashboard of each experience
-- (test and prod have different ids, see docs/release.md) and paste the ids here.
export type Monetization = {
	GamePasses: { [string]: number },
	CoinPacks: { [string]: { Id: number, Coins: number } },
}

local Monetization: Monetization = table.freeze({
	GamePasses = table.freeze({
		DoubleCoins = 0,
	}),
	-- Developer products that grant coins; granted by PurchaseService/Products.luau.
	CoinPacks = table.freeze({
		Coins100 = table.freeze({ Id = 0, Coins = 100 }),
	}),
})

return Monetization
