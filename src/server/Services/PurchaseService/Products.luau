--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)

export type Grant = (player: Player, services: { [string]: any }) -> boolean

-- Developer product id -> grant. Grants only change profile data and never yield.
local Products: { [number]: Grant } = {}

for _, pack in Monetization.CoinPacks do
	if pack.Id ~= 0 then
		Products[pack.Id] = function(player: Player, services: { [string]: any }): boolean
			return services.DataService:AdjustCash(player, pack.Coins)
		end
	end
end

return Products
