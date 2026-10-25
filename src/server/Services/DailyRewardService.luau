--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DailyReward = require(ReplicatedStorage.Utils.DailyReward)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)

local DailyRewardService = {
	Name = "DailyRewardService",
	Dependencies = { "DataService", "NotificationService", "TelemetryService", "AchievementService" },
}
local services: { [string]: any } = {}

function DailyRewardService.Init(_self: any, registry: { [string]: any })
	services = registry
end

-- Returns (claimed, coins). The server clock decides the day, never the client.
function DailyRewardService.Claim(_self: any, player: Player): (boolean, number)
	local dataService = services.DataService
	local data = dataService:GetData(player)
	if not data then
		return false, 0
	end
	local claimable, streak, reward =
		DailyReward.Evaluate(data.Daily, DailyReward.Today(os.time()), GameConfig.DailyRewards)
	if not claimable or not dataService:AdjustCash(player, reward) then
		return false, 0
	end
	dataService:Set(player, { "Daily" }, { LastClaimDay = DailyReward.Today(os.time()), Streak = streak })
	services.NotificationService:Send(player, `Day {streak} reward: +{reward} coins`)
	services.TelemetryService:Economy(
		player,
		"Source",
		reward,
		Enum.AnalyticsEconomyTransactionType.TimedReward,
		`DailyDay{streak}`
	)
	services.TelemetryService:Custom(player, "DailyStreak", streak)
	if streak >= 7 then
		services.AchievementService:Award(player, "Streak7")
	end
	return true, reward
end

function DailyRewardService.Start(_self: any)
	Packets.ClaimDaily.OnServerInvoke = function(player: Player)
		return DailyRewardService:Claim(player)
	end
end

function DailyRewardService.Destroy(_self: any)
	Packets.ClaimDaily.OnServerInvoke = nil
end

return DailyRewardService
