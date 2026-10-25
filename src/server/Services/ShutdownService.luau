--!strict

-- Soft shutdown: when Roblox closes a server for an update (or the last server of a version),
-- players are teleported to a temporary reserved server, which sends them straight back to a
-- fresh public server running the new version. Without it they would be disconnected.
-- Data is safe either way: leaving releases and saves each profile (DataService).
-- Studio, empty servers and private or reserved servers close normally (sending a VIP server
-- to a public one would break it). Needs a published place.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Seconds a player waits in the holding server so the old servers finish closing first.
local HOLD_SECONDS = 8
local MESSAGE = "Updating the game: moving you to a fresh server..."

local ShutdownService = { Name = "ShutdownService", Dependencies = {} }
local trove = Trove.new()

local function isHoldingServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

local function teleport(players: { Player }, options: TeleportOptions?): boolean
	local ok, problem = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, players, options)
	if not ok then
		warn(`[ShutdownService] Teleport failed: {problem}`)
	end
	return ok
end

local function onClose()
	local players = Players:GetPlayers()
	if RunService:IsStudio() or #players == 0 or game.PrivateServerId ~= "" then
		return
	end
	for _, player in players do
		-- Packets directly: NotificationService may already be destroyed during close.
		Packets.Notify:FireClient(player, MESSAGE)
	end
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	options:SetTeleportData({ SoftShutdown = true })
	-- Teleports are disabled during some shutdowns (moderation); then close at once.
	if not teleport(players, options) then
		return
	end
	-- BindToClose allows 30 seconds; keep the server alive while teleports finish.
	local deadline = os.clock() + 25
	while #Players:GetPlayers() > 0 and os.clock() < deadline do
		task.wait(1)
	end
end

function ShutdownService.Init(_self: any, _registry: { [string]: any }) end

function ShutdownService.Start(_self: any)
	game:BindToClose(onClose)
	if not isHoldingServer() then
		return
	end
	-- A reserved server: only players sent here by a soft shutdown go back to a public server.
	-- Other reserved servers the game creates (private matches) are left alone.
	local function arrived(player: Player)
		local data = player:GetJoinData().TeleportData
		if type(data) ~= "table" or (data :: any).SoftShutdown ~= true then
			return
		end
		-- Delayed: at PlayerAdded the client screens do not exist yet and the toast would be lost.
		task.delay(3, function()
			if player.Parent == Players then
				Packets.Notify:FireClient(player, MESSAGE)
			end
		end)
		task.delay(HOLD_SECONDS, function()
			if player.Parent == Players then
				teleport({ player }, nil)
			end
		end)
	end
	trove:Connect(Players.PlayerAdded, arrived)
	for _, player in Players:GetPlayers() do
		arrived(player)
	end
end

function ShutdownService.Destroy(_self: any)
	trove:Clean()
end

return ShutdownService
