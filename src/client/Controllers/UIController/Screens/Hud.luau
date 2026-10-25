--!strict

-- Always-visible overlay: coin counter, playtime gift and the buttons that open the modal screens.
-- Pairs with assets/ui/Hud.model.json.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local PlaytimeGifts = require(ReplicatedStorage.Utils.PlaytimeGifts)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UiImages = require(ReplicatedStorage.Config.UiImages)
local Effects = require(script.Parent.Parent.Effects)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

-- Button name in the Hud model -> modal screen it toggles.
local BUTTONS: { [string]: string } = {
	ShopButton = "Shop",
	InventoryButton = "Inventory",
	DailyButton = "DailyReward",
	RewardsButton = "Rewards",
	SettingsButton = "Settings",
}

local Hud = {}

function Hud.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controllers = context.Controllers
	local label: TextLabel? = Find(gui, "Cash", "TextLabel")

	-- The Shop button shows a SALE badge until the shop is opened once.
	local shopButton: GuiButton? = Find(gui, "ShopButton", "GuiButton")
	local saleBadge = shopButton and shopButton:FindFirstChild("Badge")
	local function stopSale()
		if saleBadge and saleBadge:IsA("GuiObject") then
			saleBadge.Visible = false
		end
	end

	for buttonName, screenName in BUTTONS do
		local button: GuiButton? = Find(gui, buttonName, "GuiButton")
		if button then
			trove:Connect(button.Activated, function()
				controllers.SoundController:PlaySfx("Click")
				if screenName == "Shop" then
					stopSale()
				end
				if controllers.UIController:IsOpen(screenName) then
					context.Close(screenName)
				else
					context.Open(screenName)
				end
			end)
		end
	end

	-- Playtime gift: counts down from the server-set SessionStart, turns gold when ready.
	local gift: ImageButton? = Find(gui, "GiftButton", "ImageButton")
	if gift then
		local button: ImageButton = gift
		local player = Players.LocalPlayer
		local busy = false
		local giftLabel = button:FindFirstChild("Label")
		local function refresh()
			local started = player:GetAttribute("SessionStart")
			local count = player:GetAttribute("GiftsClaimed")
			if type(started) ~= "number" or type(count) ~= "number" then
				button.Visible = false
				return
			end
			local claimed = {}
			for index = 1, count do
				claimed[index] = true
			end
			local index, wait =
				PlaytimeGifts.Next(workspace:GetServerTimeNow() - started, GameConfig.PlaytimeGifts, claimed)
			button.Visible = index ~= nil
			button.Image = if wait == 0 then UiImages.ButtonYellow else UiImages.ButtonGreen
			if giftLabel and giftLabel:IsA("TextLabel") then
				giftLabel.Text = if wait == 0
					then "Claim!"
					else string.format("%d:%02d", math.ceil(wait) // 60, math.ceil(wait) % 60)
			end
		end
		trove:Connect(button.Activated, function()
			if busy then
				return
			end
			busy = true
			controllers.SoundController:PlaySfx("Click")
			task.spawn(function()
				local ok = Packets.ClaimPlaytimeGift:Fire()
				busy = false
				if ok == true then
					controllers.SoundController:PlaySfx("Reward")
				end
				refresh()
			end)
		end)
		local loop = task.spawn(function()
			while true do
				refresh()
				task.wait(1)
			end
		end)
		trove:Add(function()
			task.cancel(loop)
		end)
	end

	local previous: number? = nil
	trove:Add(controllers.DataController:Observe({ "Cash" }, function(cash: any)
		if type(cash) ~= "number" then
			if label then
				label.Text = "..."
			end
			return
		end
		if label then
			label.Text = tostring(cash)
		end
		if previous and cash > previous then
			controllers.SoundController:PlaySfx("Coin")
			if label then
				Effects.Pop(label, 1.06)
			end
		end
		previous = cash
	end))

	return {
		Modal = false,
		StartsOpen = true,
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

return Hud
