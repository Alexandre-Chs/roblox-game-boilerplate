--!strict

-- Starter quests checklist (Config/Tutorial) from the saved PlayerData.Tutorial set. The first open
-- quest is highlighted; an arrow points at its Hud button, and for coins a beam leads from
-- the character to the nearest coin. The server pays each quest (TutorialService).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Config.Tutorial)
local TutorialSteps = require(ReplicatedStorage.Utils.TutorialSteps)
local Find = require(script.Parent.Parent.Find)
local Types = require(script.Parent.Parent.Types)

local Screen = {}

local function nearestCoin(from: Vector3): BasePart?
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, coin in CollectionService:GetTagged("Coin") do
		if coin:IsA("BasePart") and coin.Transparency < 1 and coin:IsDescendantOf(workspace) then
			local distance = (coin.Position - from).Magnitude
			if distance < bestDistance then
				best, bestDistance = coin, distance
			end
		end
	end
	return best
end

function Screen.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local player = Players.LocalPlayer
	local panel: GuiObject? = Find(gui, "Quests", "GuiObject")
	local list: GuiObject? = Find(gui, "List", "GuiObject")
	local template: GuiObject? = Find(gui, "RowTemplate", "GuiObject")
	local progress: TextLabel? = Find(gui, "Progress", "TextLabel")
	local arrow: GuiObject? = Find(gui, "Arrow", "GuiObject")
	local guide = trove:Extend()
	local rows: { [string]: GuiObject } = {}

	local function setText(row: Instance, name: string, text: string)
		local label = row:FindFirstChild(name, true)
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end

	-- One row per quest, in Config/Tutorial order; the panel grows to fit them.
	if panel and list and template then
		template.Visible = false
		for index, quest in Tutorial do
			local row = template:Clone()
			row.Name = quest.Id
			row.LayoutOrder = index
			row.Visible = true
			setText(row, "Label", quest.Text)
			setText(row, "Reward", `+{quest.Reward}`)
			local icon = row:FindFirstChild("Icon")
			if icon and icon:IsA("ImageLabel") then
				icon.Image = quest.Icon
			end
			row.Parent = list
			rows[quest.Id] = row
		end
		panel.Size = UDim2.fromOffset(panel.Size.X.Offset, 58 + #Tutorial * 46 + 18)
	end

	local function pointArrow(targetName: string)
		local hud = player.PlayerGui:FindFirstChild("Hud")
		local target = hud and hud:FindFirstChild(targetName, true)
		if not (arrow and target and target:IsA("GuiObject")) then
			return
		end
		local pointer: GuiObject = arrow
		local button: GuiObject = target
		pointer.Visible = true
		guide:Connect(RunService.RenderStepped, function()
			-- Left of the button, pointing at it (the art points down, so it is rotated).
			pointer.Position = UDim2.fromOffset(
				button.AbsolutePosition.X - 6,
				button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2
			)
		end)
	end

	local function beamToCoins()
		local attachment0 = guide:Add(Instance.new("Attachment"))
		local attachment1 = guide:Add(Instance.new("Attachment"))
		local beam = guide:Add(Instance.new("Beam"))
		beam.Attachment0 = attachment0
		beam.Attachment1 = attachment1
		beam.Width0, beam.Width1 = 0.6, 0.6
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(Color3.fromRGB(255, 214, 64))
		beam.Transparency = NumberSequence.new(0.2)
		beam.LightEmission = 0.6
		local elapsed = 0
		guide:Connect(RunService.Heartbeat, function(dt: number)
			elapsed += dt
			if elapsed < 0.25 then
				return
			end
			elapsed = 0
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local coin = if root and root:IsA("BasePart") then nearestCoin(root.Position) else nil
			if root and coin then
				attachment0.Parent = root
				attachment1.Parent = coin
				beam.Parent = root
			else
				beam.Parent = nil
			end
		end)
	end

	local function show(value: any)
		guide:Clean()
		local done: { [string]: boolean } = if type(value) == "table" then value else {}
		local current = TutorialSteps.Current(done, Tutorial)
		if panel then
			panel.Visible = current ~= nil
		end
		if arrow then
			arrow.Visible = false
		end
		if progress then
			progress.Text = `{TutorialSteps.Count(done, Tutorial)}/{#Tutorial}`
		end
		for id, row in rows do
			local finished = done[id] == true
			local highlight = row:FindFirstChild("Highlight")
			if highlight and highlight:IsA("GuiObject") then
				highlight.Visible = current ~= nil and current.Id == id
			end
			for _, name in { "CoinIcon", "Reward" } do
				local piece = row:FindFirstChild(name)
				if piece and piece:IsA("GuiObject") then
					piece.Visible = not finished
				end
			end
			local mark = row:FindFirstChild("Done")
			if mark and mark:IsA("GuiObject") then
				mark.Visible = finished
			end
			local label = row:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then
				label.TextTransparency = if finished then 0.5 else 0
			end
		end
		if not current then
			return
		end
		if current.Target then
			pointArrow(current.Target)
		elseif current.Id == "FirstCoin" then
			beamToCoins()
		end
	end

	trove:Add(context.Controllers.DataController:Observe({ "Tutorial" }, show))

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

return Screen
