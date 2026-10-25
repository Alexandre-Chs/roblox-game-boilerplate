--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- This script can run before its siblings (Registry, Controllers, Components) and
-- ReplicatedStorage have finished replicating. Wait for the initial replication to
-- finish before requiring anything, or requires fail with "is not a valid member".
if not game:IsLoaded() then
	game.Loaded:Wait()
end
for _, name in { "Registry", "Controllers", "Components" } do
	script.Parent:WaitForChild(name)
end
ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Trove")
ReplicatedStorage:WaitForChild("ReplicaShared")
ReplicatedStorage:WaitForChild("ReplicaClient")

local Lifecycle = require(ReplicatedStorage:WaitForChild("Lifecycle"))
local controllers = require(script.Parent.Registry)
local runtime = Lifecycle.new(controllers)

script.Destroying:Connect(function()
	runtime:Destroy()
end)

runtime:Start()
script:SetAttribute("Ready", true)
