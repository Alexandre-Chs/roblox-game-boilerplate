--!strict

-- Owned shop items with Equip / Equipped buttons. The server decides (InventoryService).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UiImages = require(ReplicatedStorage.Config.UiImages)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local Inventory = {}

local function setText(parent: Instance, name: string, text: string)
	local label = parent:FindFirstChild(name, true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

function Inventory.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local data = context.Controllers.DataController
	local close: GuiButton? = Find(gui, "Close", "GuiButton")
	local grid: GuiObject? = Find(gui, "Grid", "GuiObject")
	local empty: GuiObject? = Find(gui, "Empty", "GuiObject")
	local template: GuiObject? = Find(gui, "ItemTemplate", "GuiObject")
	local cards = trove:Extend()
	local busy = false

	if close then
		trove:Connect(close.Activated, function()
			context.Close("Inventory")
		end)
	end

	local function render()
		cards:Clean()
		if not (grid and template) then
			return
		end
		local owned = data:Get({ "Inventory" })
		local equipped = data:Get({ "Equipped" })
		local count = 0
		for _, item in ShopCatalog.Items do
			if type(owned) == "table" and owned[item.Id] == true then
				count += 1
				local card = cards:Add(template:Clone())
				card.Name = item.Id
				card.LayoutOrder = item.Order
				card.Visible = true
				local isEquipped = equipped == item.Id
				setText(card, "ItemName", item.Name)
				setText(card, "Label", if isEquipped then "Equipped" else "Equip")
				local icon = card:FindFirstChild("Icon")
				if icon and icon:IsA("ImageLabel") then
					icon.Image = item.Icon
				end
				local mark = card:FindFirstChild("EquippedMark")
				if mark and mark:IsA("GuiObject") then
					mark.Visible = isEquipped
				end
				local button = card:FindFirstChild("Equip")
				if button and button:IsA("ImageButton") then
					button.Image = if isEquipped then UiImages.ButtonGrey else UiImages.ButtonGreen
					cards:Connect(button.Activated, function()
						if busy then
							return
						end
						busy = true
						context.Controllers.SoundController:PlaySfx("Click")
						task.spawn(function()
							local ok = Packets.Equip:Fire(if isEquipped then "" else item.Id)
							busy = false
							if ok == nil then
								context.Notify("No answer, try again.")
							end
						end)
					end)
				end
				card.Parent = grid
			end
		end
		if empty then
			empty.Visible = count == 0
		end
	end

	if template then
		template.Visible = false
	end
	trove:Add(data:Observe({ "Inventory" }, render))
	trove:Add(data:Observe({ "Equipped" }, render))

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

return Inventory
