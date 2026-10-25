--!strict

return table.freeze({
	Name = "Roblox House Starter",
	-- Example features; delete each block with its feature (docs/architecture.md, Example features).
	Coin = table.freeze({
		Value = 1,
		RespawnSeconds = 10,
	}),
	-- Coins granted per streak day; the cycle restarts after the last entry.
	DailyRewards = table.freeze({ 5, 10, 15, 20, 25, 30, 50 }),
	-- Share of the price taken off the shop's daily deal (Utils/DailyDeal).
	ShopDealDiscount = 0.3,
	-- Volume change per Settings button press. Defaults live in PlayerData.Template.Settings.
	SettingsStep = 0.1,
})
