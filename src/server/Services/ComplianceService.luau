--!strict

-- Reads each player's PolicyService rules once and mirrors the ones the game uses as
-- player attributes, so the shop can hide restricted offers without yielding.
-- If the lookup fails the player is treated as restricted (the safe default).
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local ComplianceService = { Name = "ComplianceService", Dependencies = {} }
local trove = Trove.new()

local function refresh(player: Player)
	local ok, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	if not ok and player.Parent == Players then
		-- One retry: a transient failure would otherwise restrict the player all session.
		task.wait(5)
		ok, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	end
	if player.Parent ~= Players then
		return
	end
	local info: any = if ok then policy else nil
	player:SetAttribute(
		"PaidRandomItemsRestricted",
		if info then info.ArePaidRandomItemsRestricted == true else true
	)
	player:SetAttribute("PolicyLoaded", true)
end

function ComplianceService.Init(_self: any, _registry: { [string]: any }) end

-- False until the policy is known, so restricted offers are hidden while loading.
function ComplianceService.RandomItemsAllowed(_self: any, player: Player): boolean
	return player:GetAttribute("PolicyLoaded") == true
		and player:GetAttribute("PaidRandomItemsRestricted") ~= true
end

function ComplianceService.Start(_self: any)
	trove:Connect(Players.PlayerAdded, refresh)
	for _, player in Players:GetPlayers() do
		task.spawn(refresh, player)
	end
end

function ComplianceService.Destroy(_self: any)
	trove:Clean()
end

return ComplianceService
