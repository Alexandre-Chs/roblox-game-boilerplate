--!strict

-- Always-visible overlay: coin counter and the buttons that open the modal screens.
-- Pairs with assets/ui/Hud.model.json.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Effects = require(script.Parent.Parent.Effects)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

-- Button name in the Hud model -> modal screen it toggles.
local BUTTONS: { [string]: string } =
	{ ShopButton = "Shop", DailyButton = "DailyReward", SettingsButton = "Settings" }

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
