--!strict

-- "rbxassetid://..." strings. Empty means silent. Never invent ids: find and verify them
-- with the roblox-sfx skill, then record their licence in assets/catalog.json.
return table.freeze({
	Music = "",
	Sfx = table.freeze({
		Click = "",
		Coin = "",
		Purchase = "",
		Reward = "",
	}),
})
