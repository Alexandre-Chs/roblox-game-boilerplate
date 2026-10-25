--!strict

-- Starter quests shown top-left until all are done. Each pays Reward coins once.
-- Id is the milestone a system reports (TutorialService:Reached); quests can be done in any
-- order. Icon is shown on the quest's row; Target names a Hud button the arrow points at.
export type Step = { Id: string, Text: string, Reward: number, Icon: string, Target: string? }

return table.freeze({
	table.freeze({
		Id = "FirstCoin",
		Text = "Collect a coin",
		Reward = 10,
		Icon = "rbxassetid://139143238004862",
	}),
	table.freeze({
		Id = "ClaimedDaily",
		Text = "Claim your daily reward",
		Reward = 10,
		Icon = "rbxassetid://93885493960847",
		Target = "DailyButton",
	}),
	table.freeze({
		Id = "OpenedShop",
		Text = "Open the shop",
		Reward = 10,
		Icon = "rbxassetid://102733044039684",
		Target = "ShopButton",
	}),
	table.freeze({
		Id = "FirstPurchase",
		Text = "Buy an item",
		Reward = 20,
		Icon = "rbxassetid://99582097435009",
		Target = "ShopButton",
	}),
	table.freeze({
		Id = "Equipped",
		Text = "Equip an item",
		Reward = 20,
		Icon = "rbxassetid://101111661935537",
		Target = "InventoryButton",
	}),
}) :: { Step }
