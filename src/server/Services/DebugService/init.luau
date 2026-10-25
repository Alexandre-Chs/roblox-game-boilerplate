--!strict

-- Studio-only chat commands for testing. Does nothing in a live server: RunService:IsStudio()
-- is false there, so no command exists and no player can trigger these.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local DailyReward = require(ReplicatedStorage.Utils.DailyReward)
local ShopCatalog = require(ReplicatedStorage.Config.ShopCatalog)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Commands = require(script.Parent.Parent.Utils.ChatCommands)

local DebugService =
	{ Name = "DebugService", Dependencies = { "DataService", "NotificationService", "GamePassService" } }
local services: { [string]: any } = {}
local trove = Trove.new()

local HELP = "/cash <n>, /reset, /unlock, /daily, /pass <Name>, /notify <text>"

local handlers: { [string]: (player: Player, args: { string }) -> string } = {
	cash = function(player, args)
		local amount = Commands.Amount(args[1])
		if not amount then
			return "Usage: /cash <whole number>"
		end
		return if services.DataService:AdjustCash(player, amount)
			then `Cash adjusted by {amount}`
			else "Cash change refused"
	end,
	reset = function(player)
		local dataService = services.DataService
		dataService:Set(player, { "Cash" }, 0)
		dataService:Set(player, { "Inventory" }, {})
		dataService:Set(player, { "Daily" }, { LastClaimDay = 0, Streak = 0 })
		dataService:Set(player, { "Equipped" }, "")
		dataService:Set(player, { "Redeemed" }, {})
		dataService:Set(player, { "Tutorial" }, {})
		return "Cash, inventory, equipped item, codes, daily streak and starter quests reset"
	end,
	unlock = function(player)
		for _, item in ShopCatalog.Items do
			services.DataService:Set(player, { "Inventory", item.Id }, true)
		end
		return "All shop items unlocked"
	end,
	daily = function(player)
		local data = services.DataService:GetData(player)
		if not data then
			return "Data not loaded"
		end
		-- Pretend the last claim was yesterday so the streak continues.
		services.DataService:Set(player, { "Daily", "LastClaimDay" }, DailyReward.Today(os.time()) - 1)
		return "Daily reward claimable again"
	end,
	pass = function(player, args)
		local name = args[1]
		if not name then
			return "Usage: /pass <Name from Monetization.GamePasses>"
		end
		local owned = not services.GamePassService:Owns(player, name)
		services.GamePassService:SetOwnedForTesting(player, name, owned)
		return `Pass {name} {if owned then "granted" else "removed"} (testing only)`
	end,
	notify = function(_player, args)
		return table.concat(args, " ")
	end,
}

function DebugService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function DebugService.Start(_self: any)
	if not RunService:IsStudio() then
		return
	end
	local folder = trove:Add(Instance.new("Folder"))
	folder.Name = "DebugCommands"
	for name in handlers do
		local command = Instance.new("TextChatCommand")
		command.Name = name
		command.PrimaryAlias = `/{name}`
		command.Parent = folder
		trove:Connect(command.Triggered, function(source: TextSource, text: string)
			local player = Players:GetPlayerByUserId(source.UserId)
			local commandName, args = Commands.Parse(text)
			local handler = commandName and handlers[commandName]
			if player and handler then
				services.NotificationService:Send(player, handler(player, args))
			end
		end)
	end
	folder.Parent = TextChatService
	print(`[DebugService] Studio commands ready: {HELP}`)
end

function DebugService.Destroy(_self: any)
	trove:Clean()
end

return DebugService
