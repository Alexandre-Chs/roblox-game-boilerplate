--!strict

-- Caches game pass ownership as player attributes (Pass_<Name>) so servers and clients
-- can read it without yielding. Ids live in Config/Monetization; 0 means not created.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)

local GamePassService = { Name = "GamePassService" }
local connections: { RBXScriptConnection } = {}

local function attribute(name: string): string
	return `Pass_{name}`
end

local function refresh(player: Player)
	for name, id in Monetization.GamePasses do
		if id ~= 0 then
			local ok, owns =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
			if ok and owns and player.Parent == Players then
				player:SetAttribute(attribute(name), true)
			elseif not ok then
				warn(`[GamePassService] Ownership check failed for {name}: {owns}`)
			end
		end
	end
end

function GamePassService.Init(_self: any, _registry: { [string]: any }) end

function GamePassService.Owns(_self: any, player: Player, name: string): boolean
	return player:GetAttribute(attribute(name)) == true
end

-- Studio testing only (DebugService); real ownership always comes from Roblox.
function GamePassService.SetOwnedForTesting(_self: any, player: Player, name: string, owned: boolean)
	player:SetAttribute(attribute(name), if owned then true else nil)
end

function GamePassService.Start(_self: any)
	table.insert(connections, Players.PlayerAdded:Connect(refresh))
	table.insert(
		connections,
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(
			function(player: Player, passId: number, purchased: boolean)
				if not purchased then
					return
				end
				for name, id in Monetization.GamePasses do
					if id == passId then
						player:SetAttribute(attribute(name), true)
					end
				end
			end
		)
	)
	for _, player in Players:GetPlayers() do
		task.spawn(refresh, player)
	end
end

function GamePassService.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return GamePassService
