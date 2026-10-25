--!strict
local PlayerData = require("../src/server/Data/PlayerData")
local RateLimit = require("../src/shared/Utils/RateLimit")
local Purchasing = require("../src/server/Services/ShopService/Purchasing")
local DailyReward = require("../src/shared/Utils/DailyReward")
local DailyDeal = require("../src/shared/Utils/DailyDeal")
local Commands = require("../src/server/Services/DebugService/Commands")
local Redeeming = require("../src/server/Services/CodesService/Redeeming")
local Equipping = require("../src/server/Services/InventoryService/Equipping")
local Ranking = require("../src/server/Services/LeaderboardService/Ranking")
local CoinReward = require("../src/shared/Utils/CoinReward")
local TutorialSteps = require("../src/shared/Utils/TutorialSteps")

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
local function full(item)
	return item.Price
end
local function halved(item)
	return item.Price // 2
end
assert(Purchasing.Check({ Cash = 5, Inventory = {} }, catalog, "Hat", full) == "Ok")
assert(Purchasing.Check({ Cash = 4, Inventory = {} }, catalog, "Hat", full) == "NotEnoughCash")
assert(
	Purchasing.Check({ Cash = 2, Inventory = {} }, catalog, "Hat", halved) == "Ok",
	"the deal price is what is checked"
)
assert(Purchasing.Check({ Cash = 9, Inventory = { Hat = true } }, catalog, "Hat", full) == "AlreadyOwned")
assert(Purchasing.Check({ Cash = 9, Inventory = {} }, catalog, "Nope", full) == "UnknownItem")
assert(Purchasing.Check({ Cash = 9, Inventory = {} }, catalog, 42, full) == "UnknownItem")
assert(Purchasing.Check({ Cash = 9, Inventory = {} }, catalog, "__index", full) == "UnknownItem")

-- Daily deal: one item per day, rotating in Order, discounted, never free
local dealItems = { { Id = "B", Order = 2, Price = 10 }, { Id = "A", Order = 1, Price = 3 } }
assert(
	DailyDeal.ItemId(0, dealItems) == "A"
		and DailyDeal.ItemId(1, dealItems) == "B"
		and DailyDeal.ItemId(2, dealItems) == "A"
)
assert(DailyDeal.ItemId(5, {}) == nil)
assert(
	DailyDeal.Price(dealItems[1], 1, dealItems, 0.3) == 7
		and DailyDeal.Price(dealItems[1], 0, dealItems, 0.3) == 10
)
assert(DailyDeal.Price({ Id = "A", Price = 1 }, 0, dealItems, 0.9) == 1)
assert(DailyDeal.SecondsLeft(86400 * 5) == 86400 and DailyDeal.SecondsLeft(86400 * 5 + 86399) == 1)
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

-- New player data fields
assert(PlayerData.Validate({
	Equipped = "RedHat",
	Redeemed = { Code_WELCOME = true },
	Tutorial = { FirstCoin = true },
}))
assert(not PlayerData.Validate({ Equipped = 5 }))
assert(not PlayerData.Validate({ Redeemed = { Code_X = 1 } }))
assert(not PlayerData.Validate({ Tutorial = 2 }))
assert(not PlayerData.Validate({ Tutorial = { FirstCoin = 1 } }))

-- Promo codes
assert(Redeeming.Normalize("  welcome ") == "WELCOME")
assert(
	Redeeming.Normalize("bad code") == nil
		and Redeeming.Normalize("") == nil
		and Redeeming.Normalize(5) == nil
)
local codes = { WELCOME = { Coins = 50, Expires = 0 }, OLD = { Coins = 5, Expires = 100 } }
assert(Redeeming.Check({}, codes, "WELCOME", 1000) == "Ok")
assert(Redeeming.Check({}, codes, "NOPE", 1000) == "Invalid")
assert(Redeeming.Check({}, codes, nil, 1000) == "Invalid")
assert(Redeeming.Check({}, codes, "OLD", 100) == "Expired")
assert(Redeeming.Check({}, codes, "OLD", 99) == "Ok")
assert(Redeeming.Check({ [Redeeming.Key("WELCOME")] = true }, codes, "WELCOME", 1000) == "AlreadyRedeemed")

-- Equipping
local owned = { Inventory = { RedHat = true } }
local shop = { RedHat = {}, SpeedBoots = {} }
assert(Equipping.Check(owned, shop, "RedHat") == "Ok")
assert(Equipping.Check(owned, shop, "") == "Ok")
assert(Equipping.Check(owned, shop, "SpeedBoots") == "NotOwned")
assert(Equipping.Check(owned, shop, "Nope") == "UnknownItem")
assert(Equipping.Check(owned, shop, 3) == "UnknownItem")

-- Leaderboard merge: live values win, highest first, ties by UserId, capped
local top = Ranking.Merge(
	{ { UserId = 1, Name = "a", Value = 50 }, { UserId = 2, Name = "b", Value = 40 } },
	{ { UserId = 2, Name = "b", Value = 90 }, { UserId = 3, Name = "c", Value = 50 } },
	2
)
assert(#top == 2 and top[1].UserId == 2 and top[1].Value == 90 and top[2].UserId == 1)

-- Coin payout with friend bonus
local community = { FriendBonus = 0.1, MaxFriends = 3 }
assert(CoinReward.Amount(1, 1, 0, community, 0) == 1)
assert(CoinReward.Amount(1, 2, 0, community, 0.99) == 2)
assert(CoinReward.Amount(1, 1, 1, community, 0.05) == 2)
assert(CoinReward.Amount(1, 1, 1, community, 0.5) == 1)
assert(CoinReward.Amount(10, 1, 9, community, 0.99) == 13)

-- Starter quests: any order, each pays once
local steps = {
	{ Id = "FirstCoin", Reward = 10 },
	{ Id = "OpenedShop", Reward = 10 },
	{ Id = "FirstPurchase", Reward = 20 },
}
assert(TutorialSteps.Find({}, steps, "FirstPurchase") == steps[3])
assert(TutorialSteps.Find({ FirstPurchase = true }, steps, "FirstPurchase") == nil)
assert(TutorialSteps.Find({}, steps, "Unknown") == nil)
assert(TutorialSteps.Current({ FirstCoin = true }, steps) == steps[2])
assert(TutorialSteps.Current({ FirstCoin = true, OpenedShop = true, FirstPurchase = true }, steps) == nil)
assert(TutorialSteps.Count({ FirstCoin = true, Other = true }, steps) == 1)

print(
	"PASS player data validation, settings, daily streak, debug commands, shop rules, rate limiting, codes, equipping, leaderboard, coin bonus and starter quests"
)
assert(require("./purchases"))
assert(require("./sessions"))
assert(require("./lifecycle"))
assert(require("./telemetry"))
