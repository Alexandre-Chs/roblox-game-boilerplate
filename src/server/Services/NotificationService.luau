--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)

-- Sends short toast messages to one player. Shown by the client Notifications screen.
local NotificationService = { Name = "NotificationService" }

function NotificationService.Send(_self: any, player: Player, text: string)
	-- Packet.String carries at most 255 bytes.
	Packets.Notify:FireClient(player, string.sub(text, 1, 200))
end

function NotificationService.Init(_self: any, _registry: { [string]: any }) end

function NotificationService.Start(_self: any) end

function NotificationService.Destroy(_self: any) end

return NotificationService
