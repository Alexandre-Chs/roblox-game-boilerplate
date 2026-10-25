--!strict

-- Pure moderation helpers for AdminService, tested in tests/run.luau.
local Moderation = {}

export type Admins = { UserIds: { number }, GroupId: number, MinRank: number }
export type Target = { Name: string, DisplayName: string, UserId: number }

-- rank is the speaker's rank in Admins.GroupId (0 when not in it or no group).
function Moderation.IsAdmin(userId: number, admins: Admins, ownerId: number, rank: number): boolean
	if userId == ownerId or table.find(admins.UserIds, userId) then
		return true
	end
	return admins.GroupId ~= 0 and rank >= admins.MinRank
end

-- Finds one player by exact name/display name, then by unique prefix (case-insensitive).
function Moderation.FindTarget<T>(players: { T }, query: string?): (T?, string?)
	if not query or query == "" then
		return nil, "Name a player"
	end
	local lowered = string.lower(query)
	local prefixed: { T } = {}
	for _, player in players do
		local target = player :: any
		local name, display = string.lower(target.Name), string.lower(target.DisplayName)
		if name == lowered or display == lowered then
			return player, nil
		end
		if string.sub(name, 1, #lowered) == lowered or string.sub(display, 1, #lowered) == lowered then
			table.insert(prefixed, player)
		end
	end
	if #prefixed == 1 then
		return prefixed[1], nil
	end
	return nil, if #prefixed == 0 then `No player matches {query}` else `{query} matches several players`
end

-- "30m", "12h", "7d" -> seconds; "perm" -> -1 (permanent); anything else -> nil.
function Moderation.Duration(text: string?): number?
	if not text then
		return nil
	end
	local lowered = string.lower(text)
	if lowered == "perm" or lowered == "permanent" then
		return -1
	end
	local amount, unit = string.match(lowered, "^(%d+)([mhd])$")
	local value = tonumber(amount)
	if not value or value <= 0 then
		return nil
	end
	return value * ({ m = 60, h = 3600, d = 86400 } :: { [string]: number })[unit :: string]
end

return Moderation
