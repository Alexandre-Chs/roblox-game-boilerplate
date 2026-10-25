--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local PlayerData = require(ServerScriptService.Data.PlayerData)

-- Stores per-player preferences sent by the Settings screen.
local SettingsService = { Name = "SettingsService", Dependencies = { "DataService" } }
local services: { [string]: any } = {}
local connection: { Disconnect: (self: any) -> () }? = nil

function SettingsService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function SettingsService.Start(_self: any)
	connection = Packets.SetSetting.OnServerEvent:Connect(function(player: Player, name: any, value: any)
		local clean = PlayerData.CleanSetting(name, value)
		if clean ~= nil then
			services.DataService:Set(player, { "Settings", name }, clean)
		end
	end) :: any
end

function SettingsService.Destroy(_self: any)
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return SettingsService
