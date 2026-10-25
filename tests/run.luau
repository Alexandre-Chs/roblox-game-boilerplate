--!strict
local PlayerData = require("../src/server/Data/PlayerData")
local RateLimit = require("../src/shared/Utils/RateLimit")
local Purchasing = require("../src/server/Services/ShopService/Purchasing")
local DailyReward = require("../src/shared/Utils/DailyReward")
local Commands = require("../src/server/Services/DebugService/Commands")

assert(PlayerData.Validate(table.clone(PlayerData.Template)))
assert(PlayerData.Validate({ Cash = 0 }))
for _, cash in { -1, 0.5, math.huge, 0 / 0, "100" } do
	assert(not PlayerData.Validate({ Cash = cash }))
end
assert(not PlayerData.Validate({ SchemaVersion = 999 }))
assert(not PlayerData.Validate({ Receipts = { ["x"] = -1 } }))
assert(PlayerData.Validate({ Receipts = { ["purchase-1"] = 1 } }))

local limiter = RateLimit.new(2, 1000)
assert(limiter:Allow("a"))
assert(limiter:Allow("a"))
assert(not limiter:Allow("a"))
assert(limiter:Allow("b"))
limiter:Remove("a")
assert(limiter:Allow("a"))
assert(not pcall(RateLimit.new, 0, 1))
assert(not pcall(RateLimit.new, 1, 0))
assert(PlayerData.Validate({ Inventory = { RedHat = true } }))
assert(not PlayerData.Validate({ Inventory = { RedHat = 1 } }))
assert(not PlayerData.Validate({ Inventory = { [1] = true } }))

local catalog = { Hat = { Price = 5 } }
assert(Purchasing.Check({ Cash = 5, Inventory = {} }, catalog, "Hat") == "Ok")
assert(Purchasing.Check({ Cash = 4, Inventory = {} }, catalog, "Hat") == "NotEnoughCash")
assert(Purchasing.Check({ Cash = 9, Inventory = { Hat = true } }, catalog, "Hat") == "AlreadyOwned")
assert(Purchasing.Check({ Cash = 9, Inventory = {} }, catalog, "Nope") == "UnknownItem")
assert(Purchasing.Check({ Cash = 9, Inventory = {} }, catalog, 42) == "UnknownItem")
assert(Purchasing.Check({ Cash = 9, Inventory = {} }, catalog, "__index") == "UnknownItem")
-- Private bookkeeping never reaches the replica; nested tables stay shared with the profile.
local profileData = table.clone(PlayerData.Template)
profileData.Inventory = {}
local view = PlayerData.PublicView(profileData)
assert(view.Receipts == nil and view.SchemaVersion == nil and view.LastSeenAt == nil)
assert(view.Cash == 0 and view.Inventory == profileData.Inventory)

-- Settings and daily data
assert(PlayerData.Validate({ Settings = { MusicVolume = 0, SfxVolume = 1, Removed = 0.3 } }))
assert(not PlayerData.Validate({ Settings = { MusicVolume = 2 } }))
assert(not PlayerData.Validate({ Settings = { MusicVolume = "loud" } }))
assert(PlayerData.Validate({ Daily = { LastClaimDay = 20000, Streak = 3 } }))
assert(not PlayerData.Validate({ Daily = { Streak = -1 } }))
assert(PlayerData.CleanSetting("MusicVolume", 0.333) == 0.33)
assert(PlayerData.CleanSetting("MusicVolume", 7) == 1 and PlayerData.CleanSetting("SfxVolume", -1) == 0)
assert(
	PlayerData.CleanSetting("Unknown", 0.5) == nil and PlayerData.CleanSetting("MusicVolume", 0 / 0) == nil
)
assert(PlayerData.CleanSetting(42, 0.5) == nil and PlayerData.CleanSetting("SfxVolume", "1") == nil)

-- Daily streak: first claim, same day, consecutive days, a gap, and the cycle wrap
local rewards = { 5, 10, 15 }
local ok, streak, reward = DailyReward.Evaluate({ LastClaimDay = 0, Streak = 0 }, 100, rewards)
assert(ok and streak == 1 and reward == 5)
assert(not DailyReward.Evaluate({ LastClaimDay = 100, Streak = 1 }, 100, rewards))
ok, streak, reward = DailyReward.Evaluate({ LastClaimDay = 99, Streak = 2 }, 100, rewards)
assert(ok and streak == 3 and reward == 15)
ok, streak, reward = DailyReward.Evaluate({ LastClaimDay = 99, Streak = 3 }, 100, rewards)
assert(ok and streak == 4 and reward == 5)
ok, streak = DailyReward.Evaluate({ LastClaimDay = 97, Streak = 6 }, 100, rewards)
assert(ok and streak == 1)
assert(DailyReward.Today(86400 * 3 + 5) == 3)

-- Studio debug command parsing
local name, args = Commands.Parse("  /Cash 100  ")
assert(name == "cash" and args[1] == "100" and #args == 1)
assert(Commands.Parse("hello") == nil and Commands.Parse("/") == nil)
assert(Commands.Amount("-5") == -5 and Commands.Amount("1.5") == nil and Commands.Amount("1e12") == nil)
assert(Commands.Amount(nil) == nil and Commands.Amount("abc") == nil)
print("PASS player data validation, settings, daily streak, debug commands, shop rules and rate limiting")
assert(require("./purchases"))
assert(require("./sessions"))
assert(require("./lifecycle"))
assert(require("./telemetry"))
