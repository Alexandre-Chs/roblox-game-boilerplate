--!strict

-- Awards Roblox badges (ids in Config/Badges; 0 = not created yet, skipped).
-- Other services call Award; failures are retried on the next trigger, never thrown.
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Badges = require(ReplicatedStorage.Config.Badges)
local Trove = require(ReplicatedStorage.Packages.Trove)

local AchievementService = { Name = "AchievementService", Dependencies = { "DataService" } }
local services: { [string]: any } = {}
local trove = Trove.new()
local awarded: { [Player]: { [string]: true } } = {}

function AchievementService.Init(_self: any, registry: { [string]: any })
	services = registry
end

-- Never yields the caller.
function AchievementService.Award(_self: any, player: Player, name: string)
	local id = Badges[name]
	assert(id ~= nil, `Unknown badge {name}`)
	local done = awarded[player]
	if not done or done[name] then
		return
	end
	done[name] = true
	if id == 0 then
		if RunService:IsStudio() then
			print(`[AchievementService] {name} earned (no badge id yet)`)
		end
		return
	end
	task.spawn(function()
		local ok, problem = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, id)
		if not ok then
			done[name] = nil
			warn(`[AchievementService] {name} not awarded: {problem}`)
		end
	end)
end

function AchievementService.Start(_self: any)
	local dataService = services.DataService
	trove:Connect(dataService.PlayerLoaded, function(player: Player)
		awarded[player] = {}
		AchievementService:Award(player, "Welcome")
	end)
	trove:Connect(dataService.PlayerReleasing, function(player: Player)
		awarded[player] = nil
	end)
end

function AchievementService.Destroy(_self: any)
	trove:Clean()
	table.clear(awarded)
end

return AchievementService
