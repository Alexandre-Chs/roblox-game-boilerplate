--!strict

-- Example screen showing replicated player data. Pairs with assets/ui/Hud.model.json.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local Hud = {}

function Hud.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local found = gui:FindFirstChild("Cash", true)
	local label: TextLabel? = if found and found:IsA("TextLabel") then found else nil
	if not label then
		warn(`[Hud] {gui:GetFullName()} needs a TextLabel named Cash`)
	end

	local shopButton = gui:FindFirstChild("ShopButton", true)
	if shopButton and shopButton:IsA("TextButton") then
		trove:Connect(shopButton.Activated, function()
			if context.Controllers.UIController:IsOpen("Shop") then
				context.Close("Shop")
			else
				context.Open("Shop")
			end
		end)
	end

	trove:Add(context.Controllers.DataController:Observe({ "Cash" }, function(cash: any)
		if label then
			label.Text = if type(cash) == "number" then `Coins: {cash}` else "Coins: ..."
		end
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
