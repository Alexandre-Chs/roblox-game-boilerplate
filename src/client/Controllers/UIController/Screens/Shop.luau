--!strict

-- Placeholder shop: coin items from Config/ShopCatalog plus Robux offers from
-- Config/Monetization. Pairs with assets/ui/Shop.model.json; the server decides every purchase.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)
local Packets = require(ReplicatedStorage.Packets)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local MESSAGES = {
	Ok = "Purchased!",
	NotEnoughCash = "Not enough coins.",
	AlreadyOwned = "You already own this.",
	UnknownItem = "This item is not for sale.",
	NotLoaded = "Still loading, try again.",
}
local NOT_CONFIGURED = "Not on sale yet: set its id in Config/Monetization."

local Shop = {}

function Shop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local player = Players.LocalPlayer
	local list: ScrollingFrame? = Find(gui, "List", "ScrollingFrame")
	local template: Frame? = Find(gui, "ItemTemplate", "Frame")
	local close: TextButton? = Find(gui, "Close", "TextButton")
	local passButton: TextButton? = Find(gui, "DoubleCoins", "TextButton")
	local packButton: TextButton? = Find(gui, "Coins100", "TextButton")
	local busy = false

	if close then
		trove:Connect(close.Activated, function()
			context.Close("Shop")
		end)
	end

	if list and template then
		template.Visible = false
		for _, item in ShopCatalog.Items do
			local row = template:Clone()
			row.Name = item.Id
			row.LayoutOrder = item.Order
			row.Visible = true
			row.Parent = list
			trove:Add(row)
			local label: TextLabel? = Find(row, "ItemName", "TextLabel")
			local buy: TextButton? = Find(row, "Buy", "TextButton")
			if label then
				label.Text = item.Name
			end
			if not buy then
				continue
			end
			trove:Add(controllers.DataController:Observe({ "Inventory", item.Id }, function(owned: any)
				buy.Text = if owned == true then "Owned" else `{item.Price} coins`
				buy.AutoButtonColor = owned ~= true
			end))
			trove:Connect(buy.Activated, function()
				-- Debounce so normal clicks never reach the server rate limit.
				if busy or controllers.DataController:Get({ "Inventory", item.Id }) == true then
					return
				end
				busy = true
				task.spawn(function()
					local ok, reason = Packets.BuyItem:Fire(item.Id)
					busy = false
					if ok == true then
						controllers.SoundController:PlaySfx("Purchase")
					end
					context.Notify(
						if ok == nil then "No answer, try again." else MESSAGES[reason] or tostring(reason)
					)
				end)
			end)
		end
	end

	-- Robux offers. Roblox shows its own purchase dialog; grants happen on the server.
	if passButton then
		local id = Monetization.GamePasses.DoubleCoins
		local function refresh()
			passButton.Text = if player:GetAttribute("Pass_DoubleCoins") == true
				then "2x Coins: owned"
				else "2x Coins (Robux)"
		end
		refresh()
		trove:Connect(player:GetAttributeChangedSignal("Pass_DoubleCoins"), refresh)
		trove:Connect(passButton.Activated, function()
			if player:GetAttribute("Pass_DoubleCoins") == true then
				return
			end
			if id == 0 then
				context.Notify(NOT_CONFIGURED)
				return
			end
			MarketplaceService:PromptGamePassPurchase(player, id)
		end)
	end
	if packButton then
		local pack = Monetization.CoinPacks.Coins100
		packButton.Text = `+{pack.Coins} coins (Robux)`
		trove:Connect(packButton.Activated, function()
			if pack.Id == 0 then
				context.Notify(NOT_CONFIGURED)
				return
			end
			MarketplaceService:PromptProductPurchase(player, pack.Id)
		end)
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Shop
