--!strict

-- Playtime gifts (GameConfig.PlaytimeGifts): each unlocks after its minutes of play in this
-- session and is claimed once. The session start is the player attribute SessionStart (server
-- time) and the claimed count is GiftsClaimed, so the Hud shows a countdown without packets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local PlaytimeGifts = require(ReplicatedStorage.Utils.PlaytimeGifts)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlaytimeService = {
	Name = "PlaytimeService",
	Dependencies = { "DataService", "NotificationService", "TelemetryService" },
}
local services: { [string]: any } = {}
local trove = Trove.new()
local claimed: { [Player]: { [number]: boolean } } = {}

local function joined(player: Player)
	claimed[player] = {}
	player:SetAttribute("SessionStart", workspace:GetServerTimeNow())
	player:SetAttribute("GiftsClaimed", 0)
end

local function claim(player: Player): (boolean, number)
	local taken = claimed[player]
	local started = player:GetAttribute("SessionStart")
	if not taken or type(started) ~= "number" then
		return false, 0
	end
	local index, wait =
		PlaytimeGifts.Next(workspace:GetServerTimeNow() - started, GameConfig.PlaytimeGifts, taken)
	if not index or wait > 0 then
		return false, 0
	end
	local coins = GameConfig.PlaytimeGifts[index].Coins
	if not services.DataService:AdjustCash(player, coins) then
		return false, 0
	end
	taken[index] = true
	player:SetAttribute("GiftsClaimed", index)
	services.NotificationService:Send(player, `Playtime gift: +{coins} coins`)
	services.TelemetryService:Economy(
		player,
		"Source",
		coins,
		Enum.AnalyticsEconomyTransactionType.TimedReward,
		`PlaytimeGift{index}`
	)
	return true, coins
end

function PlaytimeService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function PlaytimeService.Start(_self: any)
	Packets.ClaimPlaytimeGift.OnServerInvoke = claim
	trove:Connect(Players.PlayerAdded, joined)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		claimed[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		joined(player)
	end
end

function PlaytimeService.Destroy(_self: any)
	Packets.ClaimPlaytimeGift.OnServerInvoke = nil
	trove:Clean()
	table.clear(claimed)
end

return PlaytimeService
