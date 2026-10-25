--!strict

-- Shows each player's coins in the Roblox player list (the "leaderstats" convention).
local LeaderstatsService = { Name = "LeaderstatsService", Dependencies = { "DataService" } }
local services: { [string]: any } = {}
local values: { [Player]: IntValue } = {}

function LeaderstatsService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function LeaderstatsService.Start(_self: any)
	local dataService = services.DataService
	dataService.PlayerLoaded:Connect(function(player: Player, data: any)
		local folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = data.Cash
		coins.Parent = folder
		folder.Parent = player
		values[player] = coins
	end)
	dataService.Changed:Connect(function(player: Player, path: { any }, value: any)
		local coins = values[player]
		if coins and path[1] == "Cash" and #path == 1 and type(value) == "number" then
			coins.Value = value
		end
	end)
	-- Connections live as long as DataService's signals; see docs/architecture.md, Player data.
	dataService.PlayerReleasing:Connect(function(player: Player)
		values[player] = nil
	end)
end

function LeaderstatsService.Destroy(_self: any)
	table.clear(values)
end

return LeaderstatsService
