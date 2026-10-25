--!strict

-- Loading screen. Runs from ReplicatedFirst before anything else replicates, so it builds
-- its GUI in code instead of from assets/ui. It hides once AppController sets the local
-- player's ClientReady attribute (data loaded), or after a timeout so a fault never traps the player.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local TIMEOUT = 20
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Loading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
background.Parent = gui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.5)
label.Size = UDim2.new(0.6, 0, 0, 48)
label.BackgroundTransparency = 1
label.Text = "Loading..."
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 217, 51)
label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
label.Parent = background

gui.Parent = player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()

if not game:IsLoaded() then
	game.Loaded:Wait()
end
local deadline = os.clock() + TIMEOUT
while player:GetAttribute("ClientReady") ~= true and os.clock() < deadline do
	task.wait(0.1)
end

local fade = TweenInfo.new(0.4)
TweenService:Create(background, fade, { BackgroundTransparency = 1 }):Play()
local tween = TweenService:Create(label, fade, { TextTransparency = 1 })
tween:Play()
tween.Completed:Wait()
gui:Destroy()
