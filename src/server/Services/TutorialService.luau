--!strict

-- Saves first-session tutorial progress (PlayerData.Tutorial, steps in Config/Tutorial).
-- Systems report milestones with Reached; the Tutorial screen shows the next hint.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Tutorial = require(ReplicatedStorage.Config.Tutorial)
local TutorialSteps = require(ReplicatedStorage.Utils.TutorialSteps)
local Trove = require(ReplicatedStorage.Packages.Trove)

local TutorialService = { Name = "TutorialService", Dependencies = { "DataService" } }
local services: { [string]: any } = {}
local trove = Trove.new()

function TutorialService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function TutorialService.Reached(_self: any, player: Player, milestone: string)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	local nextStep = TutorialSteps.Advance(data.Tutorial, Tutorial, milestone)
	if nextStep ~= data.Tutorial then
		services.DataService:Set(player, { "Tutorial" }, nextStep)
	end
end

function TutorialService.Start(_self: any)
	trove:Add(Packets.ShopOpened.OnServerEvent:Connect(function(player: Player)
		TutorialService:Reached(player, "OpenedShop")
	end) :: any)
end

function TutorialService.Destroy(_self: any)
	trove:Clean()
end

return TutorialService
