--!strict

-- Short toasts at the bottom of the screen. Any system calls UIController:Notify(text),
-- screens call context.Notify(text), services call NotificationService:Send(player, text).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local DURATION = 3
local MAX_VISIBLE = 4

local Notifications = {}

function Notifications.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local stack: Frame? = Find(gui, "Stack", "Frame")
	local template: TextLabel? = Find(gui, "Toast", "TextLabel")
	local shown: { TextLabel } = {}
	-- Live timers only; each removes itself, so nothing accumulates (unlike trove:Add per toast).
	local timers: { [thread]: true } = {}
	local order = 0

	if stack and template then
		local toastTemplate: TextLabel = template
		toastTemplate.Visible = false
		trove:Connect(context.Controllers.UIController.Notified, function(text: string)
			if #shown >= MAX_VISIBLE then
				local oldest = table.remove(shown, 1)
				if oldest then
					oldest:Destroy()
				end
			end
			order += 1
			local toast = toastTemplate:Clone()
			toast.Name = "Toast"
			toast.Text = text
			toast.LayoutOrder = order
			toast.Visible = true
			toast.Parent = stack
			table.insert(shown, toast)
			local timer: thread
			timer = task.delay(DURATION, function()
				timers[timer] = nil
				local index = table.find(shown, toast)
				if index then
					table.remove(shown, index)
				end
				toast:Destroy()
			end)
			timers[timer] = true
		end)
	end

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
			for timer in timers do
				task.cancel(timer)
			end
			table.clear(timers)
			for _, toast in shown do
				toast:Destroy()
			end
			table.clear(shown)
		end,
	}
end

return Notifications
