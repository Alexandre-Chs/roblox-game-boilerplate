--!strict

-- Global top list across servers. Every GameConfig.Leaderboard.RefreshSeconds it writes each
-- player's stat to an OrderedDataStore, reads the top entries and publishes them as JSON in the
-- ReplicatedStorage attribute "Leaderboard" ({ { UserId, Name, Value } }). When DataStores are
-- unavailable (Studio without API access) the list holds this server's players only.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Ranking = require(script.Ranking)

local LeaderboardService = { Name = "LeaderboardService", Dependencies = { "DataService" } }
local services: { [string]: any } = {}
local trove = Trove.new()
local store: OrderedDataStore? = nil
local stored: { Ranking.Entry } = {}
-- Last value written per user, so a leave right after a refresh does not write the same value twice.
local saved: { [number]: number } = {}
local names: { [number]: string } = {}

local function statOf(player: Player): number?
	local data = services.DataService:GetData(player)
	local value = if data then (data :: any)[GameConfig.Leaderboard.Stat] else nil
	return if type(value) == "number" then math.floor(value) else nil
end

local function nameOf(userId: number): string
	local cached = names[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local resolved = if ok and type(name) == "string" then name else `Player {userId}`
	names[userId] = resolved
	return resolved
end

-- Studio without API access refuses every call; stop trying instead of warning each minute.
local function failed(action: string, problem: any)
	local text = tostring(problem)
	if string.find(text, "403") or string.find(text, "Studio") then
		store = nil
		warn(`[LeaderboardService] DataStores unavailable; showing this server only ({text})`)
	else
		warn(`[LeaderboardService] {action} failed: {text}`)
	end
end

local function save(player: Player)
	local value = statOf(player)
	local activeStore = store
	if activeStore and value and saved[player.UserId] ~= value then
		local ok, problem = pcall(activeStore.SetAsync, activeStore, tostring(player.UserId), value)
		if ok then
			-- Recorded only on success, so a failed write is retried at the next refresh.
			saved[player.UserId] = value
		else
			failed("Save", problem)
		end
	end
end

local function fetch()
	local activeStore = store
	if not activeStore then
		return
	end
	local ok, pages = pcall(activeStore.GetSortedAsync, activeStore, false, GameConfig.Leaderboard.Size)
	if not ok then
		failed("Read", pages)
		return
	end
	local list: { Ranking.Entry } = {}
	for _, item in (pages :: any):GetCurrentPage() do
		local userId = tonumber(item.key)
		if userId then
			table.insert(list, { UserId = userId, Name = nameOf(userId), Value = item.value })
		end
	end
	stored = list
end

local function publish()
	local live: { Ranking.Entry } = {}
	for _, player in Players:GetPlayers() do
		local value = statOf(player)
		if value then
			-- Usernames everywhere: stored rows can only resolve usernames, so a player's name does not change when they leave.
			names[player.UserId] = player.Name
			table.insert(live, { UserId = player.UserId, Name = player.Name, Value = value })
		end
	end
	local top = Ranking.Merge(stored, live, GameConfig.Leaderboard.Size)
	ReplicatedStorage:SetAttribute("Leaderboard", HttpService:JSONEncode(top))
end

function LeaderboardService.Init(_self: any, registry: { [string]: any })
	services = registry
	local storeName = `Top{GameConfig.Leaderboard.Stat}{if RunService:IsStudio() then "_Studio" else ""}`
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, storeName)
	store = if ok then result else nil
end

function LeaderboardService.Start(_self: any)
	trove:Connect(services.DataService.PlayerLoaded, publish)
	-- Not in the trove: DataService fires PlayerReleasing for everyone during shutdown, after our
	-- Destroy, and that final save must still happen (docs/architecture.md, Player data).
	services.DataService.PlayerReleasing:Connect(function(player: Player)
		task.spawn(function()
			save(player)
			saved[player.UserId] = nil
		end)
	end)
	local loop = task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				save(player)
			end
			fetch()
			publish()
			task.wait(GameConfig.Leaderboard.RefreshSeconds)
		end
	end)
	trove:Add(function()
		task.cancel(loop)
	end)
end

function LeaderboardService.Destroy(_self: any)
	trove:Clean()
end

return LeaderboardService
