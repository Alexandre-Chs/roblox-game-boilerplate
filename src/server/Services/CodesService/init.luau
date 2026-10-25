--!strict

-- Redeems promo codes from Config/Codes (server-only) once per player.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Codes = require(script.Parent.Parent.Config.Codes)
local Redeeming = require(script.Redeeming)

local CodesService = { Name = "CodesService", Dependencies = { "DataService", "TelemetryService" } }
local services: { [string]: any } = {}

local MESSAGES: { [string]: string } = {
	Invalid = "That code does not exist.",
	Expired = "That code has expired.",
	AlreadyRedeemed = "You already used that code.",
}

local function redeem(player: Player, text: any): (boolean, string)
	local dataService = services.DataService
	local data = dataService:GetData(player)
	if not data then
		return false, "Try again in a moment."
	end
	local code = Redeeming.Normalize(text)
	local result = Redeeming.Check(data.Redeemed, Codes, code, os.time())
	if result ~= "Ok" or not code then
		return false, MESSAGES[result] or "That code does not exist."
	end
	local reward = Codes[code].Coins
	-- No yield between the check and both writes, so a code cannot pay twice.
	if not dataService:AdjustCash(player, reward) then
		return false, "Try again in a moment."
	end
	dataService:Set(player, { "Redeemed", Redeeming.Key(code) }, true)
	services.TelemetryService:Economy(
		player,
		"Source",
		reward,
		Enum.AnalyticsEconomyTransactionType.Gameplay,
		`Code_{code}`
	)
	return true, `Code redeemed: +{reward} coins`
end

function CodesService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function CodesService.Start(_self: any)
	Packets.RedeemCode.OnServerInvoke = redeem
end

function CodesService.Destroy(_self: any)
	Packets.RedeemCode.OnServerInvoke = nil
end

return CodesService
