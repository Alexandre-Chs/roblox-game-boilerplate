--!strict

-- Always-visible overlay: coin counter and the buttons that open the modal screens.
-- Pairs with assets/ui/Hud.model.json.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
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

	for buttonName, screenName in BUTTONS do
		local button: TextButton? = Find(gui, buttonName, "TextButton")
		if button then
			trove:Connect(button.Activated, function()
				controllers.SoundController:PlaySfx("Click")
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
				label.Text = "Coins: ..."
			end
			return
		end
		if label then
			label.Text = `Coins: {cash}`
		end
		if previous and cash > previous then
			controllers.SoundController:PlaySfx("Coin")
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
