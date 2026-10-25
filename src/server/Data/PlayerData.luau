--!strict

export type Data = {
	SchemaVersion: number,
	Cash: number,
	LastSeenAt: number,
	Receipts: { [string]: number },
	Inventory: { [string]: boolean },
	Settings: { [string]: number },
	Daily: { LastClaimDay: number, Streak: number },
	-- Shop item id currently equipped, "" for none.
	Equipped: string,
	-- Promo codes and one-time social rewards already granted (code or reward name -> true).
	Redeemed: { [string]: boolean },
	-- Starter quests completed (Config/Tutorial id -> true); each paid its reward once.
	Tutorial: { [string]: boolean },
}

local PlayerData = {}

PlayerData.Template = {
	SchemaVersion = 1,
	Cash = 0,
	LastSeenAt = 0,
	Receipts = {},
	Inventory = {},
	Settings = { MusicVolume = 0.5, SfxVolume = 0.8 },
	Daily = { LastClaimDay = 0, Streak = 0 },
	Equipped = "",
	Redeemed = {},
	Tutorial = {},
} :: Data

local function natural(value: any): boolean
	return type(value) == "number"
		and value == value
		and math.abs(value) < math.huge
		and value >= 0
		and value % 1 == 0
end

-- Server bookkeeping: saved, never replicated to the client, never changed through DataService:Set.
PlayerData.Private = table.freeze({ SchemaVersion = true, LastSeenAt = true, Receipts = true })

-- The table given to the player's replica: every non-private key. Nested tables are shared
-- with the profile, so nested changes made through the replica are saved too. DataService:Set
-- copies top-level values back to the profile.
function PlayerData.PublicView(data: { [string]: any }): { [string]: any }
	local view = {}
	for key, value in data do
		if not PlayerData.Private[key] then
			view[key] = value
		end
	end
	return view
end

local function volume(value: any): boolean
	return type(value) == "number" and value >= 0 and value <= 1
end

-- Server-side check for a setting sent by a client. Returns the value to store, or nil to reject.
function PlayerData.CleanSetting(name: any, value: any): number?
	if type(name) ~= "string" or PlayerData.Template.Settings[name] == nil or type(value) ~= "number" then
		return nil
	end
	if value ~= value then
		return nil
	end
	return math.clamp(math.round(value * 100) / 100, 0, 1)
end

function PlayerData.Validate(data: any): boolean
	if type(data) ~= "table" or (data.SchemaVersion ~= nil and data.SchemaVersion ~= 1) then
		return false
	end
	for _, key in { "Cash", "LastSeenAt" } do
		if data[key] ~= nil and not natural(data[key]) then
			return false
		end
	end
	if data.Receipts ~= nil then
		if type(data.Receipts) ~= "table" then
			return false
		end
		for purchaseId, grantedAt in data.Receipts do
			if type(purchaseId) ~= "string" or #purchaseId == 0 or not natural(grantedAt) then
				return false
			end
		end
	end
	if data.Inventory ~= nil then
		if type(data.Inventory) ~= "table" then
			return false
		end
		for itemId, owned in data.Inventory do
			if type(itemId) ~= "string" or owned ~= true then
				return false
			end
		end
	end
	if data.Equipped ~= nil and type(data.Equipped) ~= "string" then
		return false
	end
	for _, key in { "Redeemed", "Tutorial" } do
		local set = data[key]
		if set ~= nil then
			if type(set) ~= "table" then
				return false
			end
			for name, done in set do
				if type(name) ~= "string" or done ~= true then
					return false
				end
			end
		end
	end
	if data.Settings ~= nil then
		if type(data.Settings) ~= "table" then
			return false
		end
		-- Unknown keys are tolerated so removing a setting never locks players out.
		for _, value in data.Settings do
			if not volume(value) then
				return false
			end
		end
	end
	if data.Daily ~= nil then
		if type(data.Daily) ~= "table" then
			return false
		end
		for _, key in { "LastClaimDay", "Streak" } do
			if data.Daily[key] ~= nil and not natural(data.Daily[key]) then
				return false
			end
		end
	end
	return true
end

function PlayerData.Migrate(_data: any) end

return PlayerData
