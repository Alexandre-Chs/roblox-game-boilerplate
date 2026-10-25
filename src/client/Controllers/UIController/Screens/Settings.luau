--!strict

-- Volume settings saved in the player's profile. Each row has Minus, Value and Plus.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

-- Row name in assets/ui/Settings.model.json -> key in PlayerData.Settings.
local ROWS: { [string]: string } = { Music = "MusicVolume", Effects = "SfxVolume" }

local Settings = {}

function Settings.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local data = context.Controllers.DataController
	local close: GuiButton? = Find(gui, "Close", "GuiButton")
	if close then
		trove:Connect(close.Activated, function()
			context.Close("Settings")
		end)
	end

	for rowName, key in ROWS do
		local row: GuiObject? = Find(gui, rowName, "GuiObject")
		if not row then
			continue
		end
		local value: TextLabel? = Find(row, "Value", "TextLabel")
		local minus: GuiButton? = Find(row, "Minus", "GuiButton")
		local plus: GuiButton? = Find(row, "Plus", "GuiButton")
		trove:Add(data:Observe({ "Settings", key }, function(volume: any)
			if value then
				value.Text = if type(volume) == "number" then `{math.round(volume * 100)}%` else "..."
			end
		end))
		local function change(direction: number)
			local current = data:Get({ "Settings", key })
			if type(current) ~= "number" then
				return
			end
			local nextValue =
				math.clamp(math.round((current + direction * GameConfig.SettingsStep) * 10) / 10, 0, 1)
			if nextValue ~= current then
				Packets.SetSetting:Fire(key, nextValue)
				context.Controllers.SoundController:PlaySfx("Click")
			end
		end
		if minus then
			trove:Connect(minus.Activated, function()
				change(-1)
			end)
		end
		if plus then
			trove:Connect(plus.Activated, function()
				change(1)
			end)
		end
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

return Settings
