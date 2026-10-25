--!strict

-- First-session hints from Config/Tutorial, driven by the saved PlayerData.Tutorial step.
-- The banner names the goal; an arrow points at a Hud button, and for coins a beam
-- leads from the character to the nearest coin.
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
	local hint: GuiObject? = Find(gui, "Hint", "GuiObject")
	local label: TextLabel? = if hint then Find(hint, "Label", "TextLabel") else nil
	local icon: ImageLabel? = if hint then Find(hint, "Icon", "ImageLabel") else nil
	local arrow: GuiObject? = Find(gui, "Arrow", "GuiObject")
	local step = trove:Extend()

	local function pointArrow(targetName: string)
		local hud = player.PlayerGui:FindFirstChild("Hud")
		local target = hud and hud:FindFirstChild(targetName, true)
		if not (arrow and target and target:IsA("GuiObject")) then
			return
		end
		local pointer: GuiObject = arrow
		local button: GuiObject = target
		pointer.Visible = true
		step:Connect(RunService.RenderStepped, function()
			-- Left of the button, pointing at it (the art points down, so it is rotated).
			pointer.Position = UDim2.fromOffset(
				button.AbsolutePosition.X - 6,
				button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2
			)
		end)
	end

	local function beamToCoins()
		local attachment0 = step:Add(Instance.new("Attachment"))
		local attachment1 = step:Add(Instance.new("Attachment"))
		local beam = step:Add(Instance.new("Beam"))
		beam.Attachment0 = attachment0
		beam.Attachment1 = attachment1
		beam.Width0, beam.Width1 = 0.6, 0.6
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(Color3.fromRGB(255, 214, 64))
		beam.Transparency = NumberSequence.new(0.2)
		beam.LightEmission = 0.6
		local elapsed = 0
		step:Connect(RunService.Heartbeat, function(dt: number)
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

	local function show(completed: any)
		step:Clean()
		local current = TutorialSteps.Current(if type(completed) == "number" then completed else 0, Tutorial)
		if hint then
			hint.Visible = current ~= nil
		end
		if arrow then
			arrow.Visible = false
		end
		if not current then
			return
		end
		if label then
			label.Text = current.Text
		end
		if icon then
			icon.Image = current.Icon
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
