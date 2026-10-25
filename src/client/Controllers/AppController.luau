--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
type TroveInstance = typeof(Trove.new())

type State = {
	Name: string,
	_trove: TroveInstance?,
}

local AppController = {
	Name = "AppController",
	_trove = nil :: TroveInstance?,
}
local registry: { [string]: any } = {}

function AppController.Init(self: State, controllers: { [string]: any })
	registry = controllers
	self._trove = Trove.new()
end

-- The printed lines are the Studio smoke test markers listed in docs/testing.md.
function AppController.Start(self: State)
	print(`[{GameConfig.Name}] Client controllers ready`)
	local dataController = registry.DataController
	local function loaded()
		print(`[{GameConfig.Name}] Player data loaded`)
	end
	if dataController:IsLoaded() then
		loaded()
	elseif self._trove then
		self._trove:Add(dataController.Loaded:Once(loaded))
	end
	task.spawn(function()
		local sentAt = os.clock()
		local serverTime = Packets.Ping:Fire()
		if serverTime then
			print(`[{GameConfig.Name}] Packet round trip {math.round((os.clock() - sentAt) * 1000)} ms`)
		end
	end)
end

function AppController.Destroy(self: State)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return AppController
