--!strict

-- First-session steps, in order. Id is the milestone the server reports (TutorialService:Reached);
-- Text is the hint shown until it is reached; Target names a Hud button the hint points at.
export type Step = { Id: string, Text: string, Target: string? }

return table.freeze({
	table.freeze({ Id = "FirstCoin", Text = "Collect a coin!" }),
	table.freeze({ Id = "OpenedShop", Text = "Open the shop", Target = "ShopButton" }),
	table.freeze({ Id = "FirstPurchase", Text = "Buy your first item" }),
}) :: { Step }
