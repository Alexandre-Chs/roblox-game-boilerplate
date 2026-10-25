--!strict
local PlayerData = require("../src/server/Data/PlayerData")
local RateLimit = require("../src/shared/Utils/RateLimit")
local Purchasing = require("../src/server/Services/ShopService/Purchasing")

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
print("PASS player data validation, shop rules and per-player rate limiting")
assert(require("./purchases"))
assert(require("./sessions"))
