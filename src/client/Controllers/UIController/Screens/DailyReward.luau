--!strict

-- Daily login reward. Opens by itself once per session when a reward is waiting.
-- The server decides the claim; this screen only previews it with the shared rules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DailyReward = require(ReplicatedStorage.Utils.DailyReward)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local Screen = {}

function Screen.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local info: TextLabel? = Find(gui, "Info", "TextLabel")
	local claim: TextButton? = Find(gui, "Claim", "TextButton")
	local close: TextButton? = Find(gui, "Close", "TextButton")
	local autoOpened = false
	local busy = false

	local function preview(): (boolean, number, number)
		local state = context.Controllers.DataController:Get({ "Daily" })
		if type(state) ~= "table" then
			return false, 0, 0
		end
		return DailyReward.Evaluate(
			state,
			DailyReward.Today(workspace:GetServerTimeNow()),
			GameConfig.DailyRewards
		)
	end

	local function refresh()
		local claimable, streak, reward = preview()
		if info then
			info.Text = if claimable
				then `Day {streak}: {reward} coins`
				else "Come back tomorrow for your next reward."
		end
		if claim then
			claim.Visible = claimable
		end
		if claimable and not autoOpened then
			autoOpened = true
			-- Deferred: UIController registers this screen only after new() returns.
			task.defer(context.Open, "DailyReward")
		end
	end

	trove:Add(context.Controllers.DataController:Observe({ "Daily" }, function(state: any)
		if type(state) == "table" then
			refresh()
		end
	end))
	if close then
		trove:Connect(close.Activated, function()
			context.Close("DailyReward")
		end)
	end
	if claim then
		trove:Connect(claim.Activated, function()
			if busy then
				return
			end
			busy = true
			task.spawn(function()
				local ok = Packets.ClaimDaily:Fire()
				busy = false
				if ok == true then
					context.Controllers.SoundController:PlaySfx("Reward")
					context.Close("DailyReward")
				elseif ok == nil then
					context.Notify("No answer, try again.")
				end
			end)
		end)
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			refresh()
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

return Screen
