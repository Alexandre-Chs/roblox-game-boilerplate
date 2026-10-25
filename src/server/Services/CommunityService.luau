--!strict

-- Social rewards: a one-time coin reward for joining the Roblox group (GameConfig.Community)
-- and a friends-in-server count (player attribute FriendsInServer) that boosts coin pickups.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local GROUP_KEY = "Social_Group"

local CommunityService = {
	Name = "CommunityService",
	Dependencies = { "DataService", "TelemetryService" },
}
local services: { [string]: any } = {}
local trove = Trove.new()
-- friends[a][b] is true when a and b are Roblox friends; both are in this server.
local friends: { [Player]: { [Player]: true } } = {}

local function recount(player: Player)
	local count = 0
	local set = friends[player]
	if set then
		for other in set do
			if other.Parent == Players then
				count += 1
			end
		end
	end
	player:SetAttribute("FriendsInServer", count)
end

local function added(player: Player)
	friends[player] = {}
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(player.IsFriendsWithAsync, player, other.UserId)
			if ok and isFriend and friends[player] and friends[other] then
				friends[player][other] = true
				friends[other][player] = true
				recount(other)
			end
		end
	end
	recount(player)
end

local function removed(player: Player)
	local mine = friends[player]
	friends[player] = nil
	if not mine then
		return
	end
	for other in mine do
		local theirs = friends[other]
		if theirs then
			theirs[player] = nil
			recount(other)
		end
	end
end

local function claimGroup(player: Player): (boolean, string)
	local config = GameConfig.Community
	local dataService = services.DataService
	local data = dataService:GetData(player)
	if config.GroupId == 0 then
		return false, "No group yet."
	elseif not data then
		return false, "Try again in a moment."
	elseif data.Redeemed[GROUP_KEY] then
		return false, "Group reward already claimed."
	end
	local ok, inGroup = pcall(player.IsInGroupAsync, player, config.GroupId)
	if not ok then
		return false, "Roblox did not answer, try again."
	elseif not inGroup then
		return false, "Join the group first, then claim."
	end
	-- Re-read after the yield: a second request may have claimed meanwhile.
	data = dataService:GetData(player)
	if not data or data.Redeemed[GROUP_KEY] or not dataService:AdjustCash(player, config.GroupReward) then
		return false, "Group reward already claimed."
	end
	dataService:Set(player, { "Redeemed", GROUP_KEY }, true)
	services.TelemetryService:Economy(
		player,
		"Source",
		config.GroupReward,
		Enum.AnalyticsEconomyTransactionType.Gameplay,
		"GroupReward"
	)
	return true, `Thanks for joining! +{config.GroupReward} coins`
end

function CommunityService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function CommunityService.FriendsInServer(_self: any, player: Player): number
	local count = player:GetAttribute("FriendsInServer")
	return if type(count) == "number" then count else 0
end

function CommunityService.Start(_self: any)
	Packets.ClaimGroupReward.OnServerInvoke = claimGroup
	trove:Connect(Players.PlayerAdded, added)
	trove:Connect(Players.PlayerRemoving, removed)
	for _, player in Players:GetPlayers() do
		task.spawn(added, player)
	end
end

function CommunityService.Destroy(_self: any)
	Packets.ClaimGroupReward.OnServerInvoke = nil
	trove:Clean()
	table.clear(friends)
end

return CommunityService
