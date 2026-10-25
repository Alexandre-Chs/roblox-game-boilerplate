--!strict

-- "rbxassetid://..." strings. Empty means silent. Never invent ids: find and verify them
-- with the roblox-sfx skill, then record their licence in assets/catalog.json.
-- Lengths below were measured in Studio (Sound.TimeLength), not taken from the listing.
return table.freeze({
	Music = "rbxassetid://120416151765277", -- Seaside Smile, 133.8 s loop
	Sfx = table.freeze({
		Click = "rbxassetid://88442833509532", -- ui-simple-button-click, 0.03 s
		Coin = "rbxassetid://93529351909119", -- retro coin pickup, 0.48 s
		Purchase = "rbxassetid://134810204798705", -- Cash Register, 2.09 s
		Reward = "rbxassetid://1840076509", -- Through the Roof (sting), 2.26 s
		Error = "rbxassetid://87519554692663", -- ui-simple-negative-error, 0.31 s
		Open = "rbxassetid://9120733724", -- Whoosh Rising Swish Airy 2, 1.45 s
	}),
})
