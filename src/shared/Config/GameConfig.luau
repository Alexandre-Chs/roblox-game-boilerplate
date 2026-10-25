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
	-- Global top list (LeaderboardService): the PlayerData number ranked and how often it refreshes.
	Leaderboard = table.freeze({
		Stat = "Cash",
		Size = 10,
		RefreshSeconds = 60,
	}),
	-- Community rewards (CommunityService). GroupId 0 hides the group reward.
	Community = table.freeze({
		GroupId = 0,
		GroupReward = 100,
		-- Extra coin share per friend in the same server, capped at MaxFriends.
		FriendBonus = 0.1,
		MaxFriends = 3,
		-- Seconds of play before the client asks once per session to favorite the game.
		FavoritePromptAfter = 300,
	}),
	-- Default character speed; equipped items may raise it (ShopCatalog Effect.WalkSpeed).
	WalkSpeed = 16,
})
