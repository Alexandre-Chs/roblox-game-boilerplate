--!strict

-- Placeholder shop screen. Pairs with assets/ui/Shop.model.json; the server decides every purchase.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local MESSAGES = {
	Ok = "Purchased!",
	NotEnoughCash = "Not enough coins.",
	AlreadyOwned = "You already own this.",
	UnknownItem = "This item is not for sale.",
	NotLoaded = "Still loading, try again.",
}

local function find(parent: Instance, name: string, class: string): any
	local found = parent:FindFirstChild(name, true)
	if found and found:IsA(class) then
		return found
	end
	warn(`[Shop] {parent:GetFullName()} needs a {class} named {name}`)
	return nil
end

local Shop = {}

function Shop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local list: ScrollingFrame? = find(gui, "List", "ScrollingFrame")
	local template: Frame? = find(gui, "ItemTemplate", "Frame")
	local message: TextLabel? = find(gui, "Message", "TextLabel")
	local close: TextButton? = find(gui, "Close", "TextButton")
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
			local label: TextLabel? = find(row, "ItemName", "TextLabel")
			local buy: TextButton? = find(row, "Buy", "TextButton")
			if label then
				label.Text = item.Name
			end
			if not buy then
				continue
			end
			trove:Add(
				context.Controllers.DataController:Observe({ "Inventory", item.Id }, function(owned: any)
					buy.Text = if owned == true then "Owned" else `{item.Price} coins`
					buy.AutoButtonColor = owned ~= true
				end)
			)
			trove:Connect(buy.Activated, function()
				-- Debounce so normal clicks never reach the server rate limit.
				if busy or context.Controllers.DataController:Get({ "Inventory", item.Id }) == true then
					return
				end
				busy = true
				task.spawn(function()
					local ok, reason = Packets.BuyItem:Fire(item.Id)
					busy = false
					if message then
						message.Text = if ok == nil
							then "No answer, try again."
							else MESSAGES[reason] or tostring(reason)
					end
				end)
			end)
		end
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			if message then
				message.Text = ""
			end
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
