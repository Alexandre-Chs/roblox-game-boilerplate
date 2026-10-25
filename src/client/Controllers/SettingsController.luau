--!strict

-- Applies the saved display settings on this client: LowGraphics turns off global shadows and
-- Lighting post-effects; ReduceMotion makes UI motion instant (UIController/Effects).
-- Volumes are applied by SoundController.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Effects = require(script.Parent.UIController.Effects)

local SettingsController = { Name = "SettingsController", Dependencies = { "DataController" } }
local registry: { [string]: any } = {}
local trove = Trove.new()
-- Lighting values as authored, restored when LowGraphics is turned off.
local authored: { [Instance]: boolean } = {}
local authoredShadows = true

local function setLowGraphics(low: boolean)
	Lighting.GlobalShadows = if low then false else authoredShadows
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("PostEffect") then
			if authored[effect] == nil then
				authored[effect] = effect.Enabled
			end
			effect.Enabled = if low then false else authored[effect]
		end
	end
end

function SettingsController.Init(_self: any, controllers: { [string]: any })
	registry = controllers
end

function SettingsController.Start(_self: any)
	authoredShadows = Lighting.GlobalShadows
	local data = registry.DataController
	trove:Add(data:Observe({ "Settings", "LowGraphics" }, function(value: any)
		setLowGraphics(value == 1)
	end))
	trove:Add(data:Observe({ "Settings", "ReduceMotion" }, function(value: any)
		Effects.Reduced = value == 1
	end))
end

function SettingsController.Destroy(_self: any)
	trove:Clean()
	setLowGraphics(false)
	Effects.Reduced = false
end

return SettingsController
