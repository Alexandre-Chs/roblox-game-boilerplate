--!strict
local PlayerData = require("../src/server/Data/PlayerData")
local RateLimit = require("../src/shared/Utils/RateLimit")
local Purchasing = require("../src/server/Services/ShopService/Purchasing")
local DailyReward = require("../src/shared/Utils/DailyReward")
local DailyDeal = require("../src/shared/Utils/DailyDeal")
local Commands = require("../src/server/Utils/ChatCommands")
local Redeeming = require("../src/server/Services/CodesService/Redeeming")
local Equipping = require("../src/server/Services/InventoryService/Equipping")
local Ranking = require("../src/server/Services/LeaderboardService/Ranking")
local CoinReward = require("../src/shared/Utils/CoinReward")
local TutorialSteps = require("../src/shared/Utils/TutorialSteps")
local PlaytimeGifts = require("../src/shared/Utils/PlaytimeGifts")
local Moderation = require("../src/server/Services/AdminService/Moderation")
local Errors = require("../src/server/Services/ErrorReportService/Errors")
local Abbreviate = require("../src/shared/Utils/Abbreviate")
local Locale = require("../src/shared/Utils/Locale")
local DeviceScale = require("../src/client/Controllers/UIController/DeviceScale")
local Motion = require("../src/shared/Utils/Motion")

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

-- Display toggles are stored as 0 or 1
assert(
	PlayerData.CleanSetting("LowGraphics", 0.37) == 0 and PlayerData.CleanSetting("ReduceMotion", 0.9) == 1
)
assert(PlayerData.CleanSetting("MusicVolume", 0.37) == 0.37 and PlayerData.CleanSetting("Nope", 1) == nil)

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
assert(Redeeming.Check({}, codes, "OLD", 100) == "Invalid")
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

-- Coin payout with friend and Premium bonus
local community = { FriendBonus = 0.1, MaxFriends = 3 }
assert(CoinReward.Bonus(0, community, false, 0.1) == 0)
assert(math.abs(CoinReward.Bonus(9, community, true, 0.1) - 0.4) < 1e-9)
assert(CoinReward.Amount(1, 1, 0, 0) == 1)
assert(CoinReward.Amount(1, 2, 0, 0.99) == 2)
assert(CoinReward.Amount(1, 1, 0.1, 0.05) == 2)
assert(CoinReward.Amount(1, 1, 0.1, 0.5) == 1)
assert(CoinReward.Amount(10, 1, 0.3, 0.99) == 13)

-- Playtime gifts unlock in order, once each
local gifts = { { Minutes = 5, Coins = 25 }, { Minutes = 15, Coins = 50 } }
local index, wait = PlaytimeGifts.Next(60, gifts, {})
assert(index == 1 and wait == 240)
index, wait = PlaytimeGifts.Next(400, gifts, {})
assert(index == 1 and wait == 0)
index, wait = PlaytimeGifts.Next(400, gifts, { [1] = true })
assert(index == 2 and wait == 500)
assert(PlaytimeGifts.Next(5000, gifts, { [1] = true, [2] = true }) == nil)

-- Moderation
local admins = { UserIds = { 7 }, GroupId = 10, MinRank = 200 }
assert(Moderation.IsAdmin(7, admins, 1, 0) and Moderation.IsAdmin(1, admins, 1, 0))
assert(Moderation.IsAdmin(9, admins, 1, 200) and not Moderation.IsAdmin(9, admins, 1, 199))
assert(not Moderation.IsAdmin(9, { UserIds = {}, GroupId = 0, MinRank = 0 }, 1, 255))
local roster = {
	{ Name = "Builder", DisplayName = "Bob", UserId = 1 },
	{ Name = "Bobby", DisplayName = "Rob", UserId = 2 },
}
assert(Moderation.FindTarget(roster, "bob") == roster[1])
assert(Moderation.FindTarget(roster, "bui") == roster[1])
assert(Moderation.FindTarget(roster, "zz") == nil and Moderation.FindTarget(roster, nil) == nil)
local pair = { roster[2], { Name = "Bobcat", DisplayName = "C", UserId = 3 } }
assert((Moderation.FindTarget(pair, "bobc") :: any).UserId == 3)
assert(Moderation.FindTarget(pair, "bob") == nil)
assert(
	Moderation.Duration("30m") == 1800
		and Moderation.Duration("2d") == 172800
		and Moderation.Duration("perm") == -1
)
assert(
	Moderation.Duration("0h") == nil and Moderation.Duration("x") == nil and Moderation.Duration(nil) == nil
)

-- Error grouping
assert(
	Errors.Key("ServerScriptService.Services.ShopService:42: attempt to index nil with 'Hat'")
		== "ShopService:#: attempt to index nil with 'Hat'"
)
assert(Errors.Key('Players.Bob.PlayerScripts.X:7: bad "value 12"') == 'X:#: bad ""')
local seen = {}
assert(
	Errors.Throttle(seen, "a", 0, 60)
		and not Errors.Throttle(seen, "a", 30, 60)
		and Errors.Throttle(seen, "a", 61, 60)
)

-- Formatting and screen fitting
assert(
	Abbreviate(999) == "999"
		and Abbreviate(1000) == "1K"
		and Abbreviate(1550) == "1.5K"
		and Abbreviate(2e6) == "2M"
)
assert(Locale.Fill("Day {1}: {2} coins", { 3, 15 }) == "Day 3: 15 coins")
assert(Locale.Fill("Hi {2}", { "a" }) == "Hi {2}")
assert(DeviceScale.Fit(1920, 1080, nil, nil) == 1.3 and DeviceScale.Fit(480, 270, nil, nil) == 0.5)
assert(math.abs(DeviceScale.Fit(844, 390, 900, 690) - 390 * 0.9 / 690) < 1e-9)
assert(DeviceScale.Fit(10000, 10000, 500, 400) == 1.3)

-- Leaderboard ties and short lists
local tied = Ranking.Merge(
	{ { UserId = 9, Name = "z", Value = 5 } },
	{ { UserId = 3, Name = "c", Value = 5 } },
	10
)
assert(#tied == 2 and tied[1].UserId == 3 and tied[2].UserId == 9)

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
	"PASS player data validation, settings, daily streak, debug commands, shop rules, rate limiting, codes, equipping, leaderboard, coin bonus, starter quests, playtime gifts, moderation and error grouping"
)
-- Motion: the spring settles on its target without overshoot, whatever the frame rate.
for _, dt in { 1 / 240, 1 / 60, 1 / 10, 1 } do
	local position, velocity, peak = 0, 0, 0
	for _ = 1, math.ceil(3 / dt) do
		position, velocity = Motion.Spring(position, velocity, 2, 1.5, dt)
		peak = math.max(peak, position)
	end
	assert(math.abs(position - 2) < 1e-3 and peak <= 2 + 1e-9)
end
assert(math.abs(Motion.Wave(0.25, 1, 3, 0) - 3) < 1e-9 and math.abs(Motion.Wave(0, 1, 3, 0)) < 1e-9)
assert(math.abs(Motion.Stride(0.9, 3, 10) - 0.2) < 1e-9)
assert(require("./purchases"))
assert(require("./sessions"))
assert(require("./lifecycle"))
assert(require("./telemetry"))
