--!strict

-- First-session steps, in order. Id is the milestone the server reports (TutorialService:Reached);
-- Text is the hint shown until it is reached; Icon is the image shown on the hint;
-- Target names a Hud button the hint arrow points at.
export type Step = { Id: string, Text: string, Icon: string, Target: string? }

return table.freeze({
	table.freeze({ Id = "FirstCoin", Text = "Collect a coin!", Icon = "rbxassetid://139143238004862" }),
	table.freeze({
		Id = "OpenedShop",
		Text = "Open the shop",
		Icon = "rbxassetid://102733044039684",
		Target = "ShopButton",
	}),
	table.freeze({ Id = "FirstPurchase", Text = "Buy your first item", Icon = "rbxassetid://99582097435009" }),
}) :: { Step }
