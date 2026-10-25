--!strict

-- Daily login reward. Opens by itself once per session when a reward is waiting.
-- The server decides the claim; this screen only previews it with the shared rules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DailyReward = require(ReplicatedStorage.Utils.DailyReward)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UiImages = require(ReplicatedStorage.Config.UiImages)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local Screen = {}

function Screen.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local info: TextLabel? = Find(gui, "Info", "TextLabel")
	local claim: GuiButton? = Find(gui, "Claim", "GuiButton")
	local close: GuiButton? = Find(gui, "Close", "GuiButton")
	local days: GuiObject? = Find(gui, "Days", "GuiObject")
	local dayTemplate: GuiObject? = Find(gui, "DayTemplate", "GuiObject")
	-- One tile per reward in the cycle, cloned from the authored template.
	local tiles: { GuiObject } = {}
	if days and dayTemplate then
		for day, amount in GameConfig.DailyRewards do
			local tile = dayTemplate:Clone()
			tile.Name = `Day{day}`
			tile.LayoutOrder = day
			tile.Visible = true
			local fields: { [string]: string } = { Day = `Day {day}`, Amount = tostring(amount) }
			for field, value in fields do
				local label = tile:FindFirstChild(field)
				if label and label:IsA("TextLabel") then
					label.Text = value
				end
			end
			tile.Parent = days
			tiles[day] = tile
		end
	end
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
		-- Position in the cycle: tiles before it are claimed; it is today's tile when claimable.
		local current = if streak > 0 then (streak - 1) % #tiles + 1 else 0
		for day, tile in tiles do
			local claimed = day < current or (day == current and not claimable)
			local art = tile:FindFirstChild("Tile")
			if art and art:IsA("ImageLabel") then
				art.Image = if claimed
					then UiImages.DayTileClaimed
					elseif day == current then UiImages.DayTileToday
					else UiImages.DayTile
			end
			local check = tile:FindFirstChild("Check", true)
			if check and check:IsA("GuiObject") then
				check.Visible = claimed
			end
		end
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
