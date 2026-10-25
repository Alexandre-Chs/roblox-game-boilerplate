--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local PlayerData = require("../src/server/Data/PlayerData")

local function signal()
	local callbacks = {}
	return {
		Connect = function(_self, callback)
			table.insert(callbacks, callback)
		end,
		Fire = function()
			for _, callback in callbacks do
				callback()
			end
		end,
	}
end

local function profile(data)
	local p = { Data = data, LastSavedData = {}, active = true, ended = 0, saves = 0, userIds = {} }
	p.OnSave = signal()
	p.OnSessionEnd = signal()
	function p.IsActive(self)
		return self.active
	end
	function p.AddUserId(self, id)
		table.insert(self.userIds, id)
	end
	function p.Reconcile(self)
		for key, value in PlayerData.Template do
			if self.Data[key] == nil then
				self.Data[key] = if type(value) == "table" then {} else value
			end
		end
	end
	function p.EndSession(self)
		self.ended += 1
		self.active = false
	end
	function p.Save(self)
		self.saves += 1
		self.OnSave:Fire()
		self.LastSavedData = table.clone(self.Data)
	end
	return p
end

local DataSessions = luau.load(fs.readFile("src/server/Data/DataSessions.luau"), {
	environment = {
		script = { Parent = { PlayerData = PlayerData } },
		require = function(value)
			return value
		end,
		warn = function() end,
		task = { wait = function() end },
	},
})()

local function player(id)
	local p = { UserId = id, present = true, kicked = nil }
	function p.Kick(self, message)
		self.kicked = message
	end
	return p
end

local function sessions(next)
	return DataSessions.new({
		StartSessionAsync = function()
			return next()
		end,
	}, function(p)
		return p.present
	end)
end

-- Successful load reconciles, tags the user id and stamps LastSeenAt on save.
local good = profile({ Cash = 5 })
local s = sessions(function()
	return good
end)
local alice = player(1)
s:Load(alice)
local data = s:GetData(alice)
assert(data and data.Cash == 5 and data.SchemaVersion == 1, "loaded and reconciled")
assert(good.userIds[1] == 1 and alice.kicked == nil)
assert(s:RequestSave(alice) and good.saves == 1 and data.LastSeenAt > 0)
assert(s:WaitForSave(alice, function(saved)
	return saved.Cash == 5
end))

-- Invalid data is never reset: the session ends and the player is kicked.
local bad = profile({ Cash = -3 })
local bob = player(2)
sessions(function()
	return bad
end):Load(bob)
assert(bob.kicked and bad.ended == 1 and bad.Data.Cash == -3, "invalid data kept intact")

-- Store failures kick instead of playing without data.
local carol = player(3)
sessions(function()
	return nil
end):Load(carol)
assert(carol.kicked)
local dave = player(4)
sessions(function()
	error("DataStore down")
end):Load(dave)
assert(dave.kicked)

-- A player who leaves mid-load is released without a kick.
local late = profile({})
local erin = player(5)
sessions(function()
	erin.present = false
	return late
end):Load(erin)
assert(late.ended == 1 and erin.kicked == nil)

-- Another server stealing the session kicks and hides the data.
good.OnSessionEnd:Fire()
assert(s:GetData(alice) == nil and alice.kicked)

-- Release and Destroy end sessions; nothing loads after Destroy.
local frank = player(6)
local fp = profile({})
local s2 = sessions(function()
	return fp
end)
s2:Load(frank)
s2:Release(frank)
assert(fp.ended == 1 and s2:GetData(frank) == nil and not s2:RequestSave(frank))
s2:Destroy()
s2:Load(frank)
assert(s2:GetData(frank) == nil)

print("PASS data sessions: load, invalid data, store failure, early leave, stolen session, release")
return true
