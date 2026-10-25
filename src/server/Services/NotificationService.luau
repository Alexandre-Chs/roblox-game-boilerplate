--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Locale = require(ReplicatedStorage.Utils.Locale)
local Packets = require(ReplicatedStorage.Packets)

-- Sends short toast messages to one player. Shown by the client Notifications screen.
-- Also prepares each player's translator, so server code can build text with Locale.Format(player, ...).
local NotificationService = { Name = "NotificationService", Dependencies = {} }
local connection: RBXScriptConnection? = nil

function NotificationService.Send(_self: any, player: Player, text: string)
	-- Packet.String carries at most 255 bytes.
	Packets.Notify:FireClient(player, string.sub(text, 1, 200))
end

function NotificationService.Init(_self: any, _registry: { [string]: any }) end

function NotificationService.Start(_self: any)
	connection = Players.PlayerAdded:Connect(Locale.Prepare)
	for _, player in Players:GetPlayers() do
		Locale.Prepare(player)
	end
end

function NotificationService.Destroy(_self: any)
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return NotificationService
