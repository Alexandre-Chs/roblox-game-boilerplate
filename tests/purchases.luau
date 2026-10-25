--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local data = { Cash = 0, Receipts = {} }
local player = {}
local market = {}
local grants = 0
local savesSucceed = true
local connected = true
local services = {
	DataService = {
		GetData = function()
			return if connected then data else nil
		end,
		WaitForSave = function(_self, _player, predicate)
			return savesSucceed and predicate(data)
		end,
	},
}
local products = {
	[1] = function()
		grants += 1
		data.Cash += 10
		return true
	end,
}
local purchaseService = luau.load(fs.readFile("src/server/Services/PurchaseService/init.luau"), {
	environment = {
		game = {
			GetService = function(_self, name)
				if name == "MarketplaceService" then
					return market
				end
				return {
					GetPlayerByUserId = function()
						return if connected then player else nil
					end,
				}
			end,
		},
		script = { Products = products },
		require = function(value)
			return value
		end,
		Enum = { ProductPurchaseDecision = { NotProcessedYet = "pending", PurchaseGranted = "granted" } },
		warn = function() end,
	},
})()
purchaseService:Init(services)
purchaseService:Start()
local function receipt(id, productId)
	return market.ProcessReceipt({ PurchaseId = id, PlayerId = 1, ProductId = productId or 1 })
end
assert(receipt("first") == "granted")
assert(receipt("first") == "granted" and grants == 1)
for index = 1, 110 do
	assert(receipt(tostring(index)) == "granted")
end
assert(receipt("first") == "granted" and grants == 111, "Old receipts must not be granted again")
savesSucceed = false
assert(receipt("save-failure") == "pending")
assert(receipt("save-failure") == "pending" and grants == 112)
savesSucceed = true
assert(receipt("save-failure") == "granted" and grants == 112)
assert(receipt("unknown", 999) == "pending")
connected = false
assert(receipt("offline") == "pending")
purchaseService:Destroy()
assert(market.ProcessReceipt == nil)
print("PASS receipt replay, save retry, unknown products and disconnected player")
return true
