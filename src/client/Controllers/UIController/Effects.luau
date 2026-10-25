--!strict

-- Reusable UI motion for screens: press feedback, pops, shines and pulses.
-- Every looping tween is added to the caller's Trove so it stops with the screen.
local TweenService = game:GetService("TweenService")

local Effects = {}

local function scaleOf(object: GuiObject, name: string): UIScale
	local existing = object:FindFirstChild(name)
	if existing and existing:IsA("UIScale") then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = name
	scale.Parent = object
	return scale
end

local function tween(object: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	local info = TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(object, info, goal):Play()
end

-- Grows on hover, squashes on press. Works with mouse and touch.
function Effects.Press(trove: any, button: GuiButton)
	local scale = scaleOf(button, "PressScale")
	trove:Connect(button.MouseEnter, function()
		tween(scale, 0.12, { Scale = 1.06 })
	end)
	trove:Connect(button.MouseLeave, function()
		tween(scale, 0.12, { Scale = 1 })
	end)
	trove:Connect(button.MouseButton1Down, function()
		tween(scale, 0.08, { Scale = 0.92 })
	end)
	trove:Connect(button.MouseButton1Up, function()
		tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end

-- Springs an element in from a smaller size. Use on frames, not on buttons using Press.
function Effects.Pop(object: GuiObject, from: number?)
	local scale = scaleOf(object, "PopScale")
	scale.Scale = from or 0.85
	tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Sweeps a light band across a UIGradient forever (Offset -1 -> 1, then a pause).
function Effects.Shine(trove: any, gradient: UIGradient)
	gradient.Offset = Vector2.new(-1, 0)
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.8)
	local shine = trove:Add(TweenService:Create(gradient, info, { Offset = Vector2.new(1, 0) }))
	shine:Play()
end

-- Breathes a UIScale between 1 and amount forever. Returns the tween so callers can stop it.
function Effects.Pulse(trove: any, object: GuiObject, amount: number): Tween
	local scale = scaleOf(object, "PulseScale")
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulse = trove:Add(TweenService:Create(scale, info, { Scale = amount }))
	pulse:Play()
	return pulse
end

-- Fades a frame's background to a target transparency.
function Effects.Fade(object: GuiObject, transparency: number, seconds: number?)
	tween(object, seconds or 0.2, { BackgroundTransparency = transparency })
end

return Effects
