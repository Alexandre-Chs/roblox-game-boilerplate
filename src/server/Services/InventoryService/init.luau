--!strict

-- Equips one owned shop item at a time and applies its Effect to the character.
-- The equipped id is saved (PlayerData.Equipped) and mirrored as the Equipped player attribute.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Packets = require(ReplicatedStorage.Packets)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Equipping = require(script.Equipping)

local InventoryService = { Name = "InventoryService", Dependencies = { "DataService", "TutorialService" } }
local services: { [string]: any } = {}
local trove = Trove.new()

local function apply(player: Player)
	local data = services.DataService:GetData(player)
	local item = if data then ShopCatalog.ById[data.Equipped] else nil
	player:SetAttribute("Equipped", if item then item.Id else nil)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local effect = item and item.Effect
		humanoid.WalkSpeed = if effect and effect.WalkSpeed then effect.WalkSpeed else GameConfig.WalkSpeed
	end
end

local function equip(player: Player, itemId: any): (boolean, string)
	local dataService = services.DataService
	local data = dataService:GetData(player)
	if not data then
		return false, "NotLoaded"
	end
	local result = Equipping.Check(data, ShopCatalog.ById, itemId)
	if result ~= "Ok" then
		return false, result
	end
	dataService:Set(player, { "Equipped" }, itemId)
	apply(player)
	if itemId ~= "" then
		services.TutorialService:Reached(player, "Equipped")
	end
	return true, "Ok"
end

function InventoryService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function InventoryService.Start(_self: any)
	Packets.Equip.OnServerInvoke = equip
	local function watch(player: Player)
		trove:Connect(player.CharacterAdded, function()
			apply(player)
		end)
		apply(player)
	end
	trove:Connect(services.DataService.PlayerLoaded, watch)
	for _, player in Players:GetPlayers() do
		if services.DataService:GetData(player) then
			watch(player)
		end
	end
end

function InventoryService.Destroy(_self: any)
	Packets.Equip.OnServerInvoke = nil
	trove:Clean()
end

return InventoryService
