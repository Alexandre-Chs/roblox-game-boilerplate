--!strict

-- Live moderation chat commands for admins (src/server/Config/Admins.luau, plus the place
-- owner; in Studio everyone). Unlike DebugService these exist on live servers, hidden from
-- autocomplete, and every command re-checks the speaker on the server before acting.
--   /kick <player> [reason]          remove from this server
--   /ban <player> <30m|12h|7d|perm> [reason]   Roblox ban across the universe (Players:BanAsync)
--   /unban <userId>                  lift a ban
--   /announce <text>                 notify everyone in this server
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Admins = require(script.Parent.Parent.Config.Admins)
local Commands = require(script.Parent.Parent.Utils.ChatCommands)
local Moderation = require(script.Moderation)

local AdminService = { Name = "AdminService", Dependencies = { "NotificationService" } }
local services: { [string]: any } = {}
local trove = Trove.new()
local ranks: { [Player]: number } = {}

local function rankOf(player: Player): number
	local cached = ranks[player]
	if cached then
		return cached
	end
	local rank = 0
	if Admins.GroupId ~= 0 then
		-- The highest rank among the player's roles in the group; 0 when not a member or on failure.
		local ok, result: any =
			pcall(GroupService.GetRolesInGroupAsync, GroupService, player.UserId, Admins.GroupId)
		if ok and type(result) == "table" and result.IsMember then
			for _, role in result.Roles or {} do
				if type(role.Rank) == "number" then
					rank = math.max(rank, role.Rank)
				end
			end
		end
	end
	ranks[player] = rank
	return rank
end

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	local ownerId = if game.CreatorType == Enum.CreatorType.User then game.CreatorId else 0
	return Moderation.IsAdmin(player.UserId, Admins, ownerId, rankOf(player))
end

local function reasonFrom(args: { string }, first: number): string
	local reason = table.concat(args, " ", first)
	return if reason == "" then "Removed by a moderator" else string.sub(reason, 1, 200)
end

local handlers: { [string]: (admin: Player, args: { string }) -> string } = {
	kick = function(admin, args)
		local target, problem = Moderation.FindTarget(Players:GetPlayers(), args[1])
		if not target then
			return problem or "No player"
		end
		local reason = reasonFrom(args, 2)
		print(`[AdminService] {admin.Name} kicked {target.Name}: {reason}`)
		target:Kick(reason)
		return `Kicked {target.Name}`
	end,
	ban = function(admin, args)
		local target, problem = Moderation.FindTarget(Players:GetPlayers(), args[1])
		local duration = Moderation.Duration(args[2])
		if not target then
			return problem or "No player"
		elseif not duration then
			return "Usage: /ban <player> <30m|12h|7d|perm> [reason]"
		end
		local reason = reasonFrom(args, 3)
		local ok, failure = pcall(Players.BanAsync, Players, {
			UserIds = { target.UserId },
			Duration = duration,
			DisplayReason = reason,
			PrivateReason = `Banned by {admin.Name} ({admin.UserId})`,
			ExcludeAltAccounts = false,
			ApplyToUniverse = true,
		})
		if not ok then
			return `Ban failed: {failure}`
		end
		print(`[AdminService] {admin.Name} banned {target.Name} for {args[2]}: {reason}`)
		return `Banned {target.Name} ({args[2]})`
	end,
	unban = function(admin, args)
		local userId = tonumber(args[1])
		if not userId then
			return "Usage: /unban <userId>"
		end
		local ok, failure =
			pcall(Players.UnbanAsync, Players, { UserIds = { userId }, ApplyToUniverse = true })
		if not ok then
			return `Unban failed: {failure}`
		end
		print(`[AdminService] {admin.Name} unbanned {userId}`)
		return `Unbanned {userId}`
	end,
	announce = function(_admin, args)
		local text = string.sub(table.concat(args, " "), 1, 200)
		if text == "" then
			return "Usage: /announce <text>"
		end
		for _, player in Players:GetPlayers() do
			services.NotificationService:Send(player, `📢 {text}`)
		end
		return "Announced"
	end,
}

function AdminService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function AdminService.Start(_self: any)
	local folder = trove:Add(Instance.new("Folder"))
	folder.Name = "AdminCommands"
	for name in handlers do
		local command = Instance.new("TextChatCommand")
		command.Name = name
		command.PrimaryAlias = `/{name}`
		command.AutocompleteVisible = false
		command.Parent = folder
		trove:Connect(command.Triggered, function(source: TextSource, text: string)
			local admin = Players:GetPlayerByUserId(source.UserId)
			if not admin or not isAdmin(admin) then
				return
			end
			local commandName, args = Commands.Parse(text)
			local handler = commandName and handlers[commandName]
			if handler then
				task.spawn(function()
					services.NotificationService:Send(admin, handler(admin, args))
				end)
			end
		end)
	end
	folder.Parent = TextChatService
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		ranks[player] = nil
	end)
end

function AdminService.Destroy(_self: any)
	trove:Clean()
	table.clear(ranks)
end

return AdminService
