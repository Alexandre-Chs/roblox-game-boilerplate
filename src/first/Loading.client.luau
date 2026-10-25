--!strict

-- Loading screen. Runs from ReplicatedFirst before anything else replicates, so it builds
-- its GUI in code instead of from assets/ui; its image ids come from the generated LoadingImages. It hides once AppController sets the local
-- player's ClientReady attribute (data loaded), or after a timeout so a fault never traps the player.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Images = require(script.Parent.LoadingImages)

local TIMEOUT = 20
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Loading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false

local background = Instance.new("ImageLabel")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(120, 190, 235)
background.Image = Images.Background
background.ScaleType = Enum.ScaleType.Crop
background.Parent = gui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 0.5, -10)
label.Size = UDim2.new(0.6, 0, 0, 54)
label.BackgroundTransparency = 1
label.Text = "Loading..."
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeColor3 = Color3.fromRGB(74, 33, 13)
label.TextStrokeTransparency = 0
label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
label.Parent = background

local function bar(image: string, parent: GuiObject): ImageLabel
	local piece = Instance.new("ImageLabel")
	piece.BackgroundTransparency = 1
	piece.Image = image
	piece.ScaleType = Enum.ScaleType.Slice
	piece.SliceCenter = Images.BarSlice
	piece.SliceScale = 0.5
	piece.Parent = parent
	return piece
end
local track = bar(Images.Track, background)
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.5, 0, 0.5, 10)
track.Size = UDim2.new(0.5, 0, 0, 28)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(420, 28)
sizeLimit.Parent = track
-- The fill creeps towards 90% while waiting and completes when the client is ready.
local fill = bar(Images.Fill, track)
fill.Size = UDim2.fromScale(0.08, 1)
local creep = TweenService:Create(
	fill,
	TweenInfo.new(TIMEOUT / 2, Enum.EasingStyle.Quart),
	{ Size = UDim2.fromScale(0.9, 1) }
)

gui.Parent = player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()
creep:Play()

if not game:IsLoaded() then
	game.Loaded:Wait()
end
local deadline = os.clock() + TIMEOUT
while player:GetAttribute("ClientReady") ~= true and os.clock() < deadline do
	task.wait(0.1)
end

creep:Cancel()
local done = TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(1, 1) })
done:Play()
done.Completed:Wait()

local fade = TweenInfo.new(0.4)
for _, object in { background, track, fill } do
	TweenService:Create(object, fade, { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
end
local tween = TweenService:Create(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
tween:Play()
tween.Completed:Wait()
gui:Destroy()
