--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monetization = require(ReplicatedStorage.Config.Monetization)

export type Grant = (player: Player, services: { [string]: any }) -> boolean

-- Developer product id -> grant. Grants only change profile data and never yield.
local Products: { [number]: Grant } = {}

for name, pack in Monetization.CoinPacks do
	if pack.Id ~= 0 then
		Products[pack.Id] = function(player: Player, services: { [string]: any }): boolean
			if not services.DataService:AdjustCash(player, pack.Coins) then
				return false
			end
			services.TelemetryService:Economy(
				player,
				"Source",
				pack.Coins,
				Enum.AnalyticsEconomyTransactionType.IAP,
				name
			)
			return true
		end
	end
end

return Products
