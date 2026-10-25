--!strict

-- Starter quests (Config/Tutorial). Systems report milestones with Reached; the first time a
-- quest's milestone is reached it is saved in PlayerData.Tutorial and pays its reward.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Tutorial = require(ReplicatedStorage.Config.Tutorial)
local TutorialSteps = require(ReplicatedStorage.Utils.TutorialSteps)
local Trove = require(ReplicatedStorage.Packages.Trove)

local TutorialService = {
	Name = "TutorialService",
	Dependencies = { "DataService", "NotificationService", "TelemetryService" },
}
local services: { [string]: any } = {}
local trove = Trove.new()

function TutorialService.Init(_self: any, registry: { [string]: any })
	services = registry
end

-- Never yields. Unknown or already completed milestones do nothing.
function TutorialService.Reached(_self: any, player: Player, milestone: string)
	local dataService = services.DataService
	local data = dataService:GetData(player)
	local quest = if data then TutorialSteps.Find(data.Tutorial, Tutorial, milestone) else nil
	if not quest or not dataService:AdjustCash(player, quest.Reward) then
		return
	end
	dataService:Set(player, { "Tutorial", quest.Id }, true)
	services.TelemetryService:Economy(
		player,
		"Source",
		quest.Reward,
		Enum.AnalyticsEconomyTransactionType.Onboarding,
		`Quest_{quest.Id}`
	)
	services.NotificationService:Send(player, `Quest complete: +{quest.Reward} coins`)
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
