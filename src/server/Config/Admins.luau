--!strict

-- Who may use the live moderation commands (AdminService). Server-only.
-- UserIds: individual Roblox user ids. GroupId/MinRank: everyone at or above that group rank.
-- The place owner (or group owner, for group games) is always an admin.
return table.freeze({
	UserIds = table.freeze({}) :: { number },
	GroupId = 0,
	MinRank = 255,
})
