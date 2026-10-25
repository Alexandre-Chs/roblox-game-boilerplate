--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)

local GameService = { Name = "GameService", Dependencies = {} }

function GameService.Init(_self: any, _services: { [string]: any }) end

function GameService.Start(_self: any)
	Packets.Ping.OnServerInvoke = function(_player: Player)
		return workspace:GetServerTimeNow()
	end
	print(`[{GameConfig.Name}] Server services ready`)
end

function GameService.Destroy(_self: any)
	Packets.Ping.OnServerInvoke = nil
end

return GameService
