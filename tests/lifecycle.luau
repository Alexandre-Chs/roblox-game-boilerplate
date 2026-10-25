--!strict
local Lifecycle = require("../src/shared/Lifecycle")

local log = {}
local function system(name: string, dependencies: { string }, failStart: boolean?): any
	return {
		Name = name,
		Dependencies = dependencies,
		Init = function()
			table.insert(log, `{name}.Init`)
		end,
		Start = function()
			if failStart then
				error("boom")
			end
			table.insert(log, `{name}.Start`)
		end,
		Destroy = function()
			table.insert(log, `{name}.Destroy`)
		end,
	}
end

-- Hooks run Init for all, then Start for all; Destroy runs in reverse.
local runtime = Lifecycle.new({ system("A", {}), system("B", { "A" }) })
runtime:Start()
runtime:Destroy()
assert(table.concat(log, ",") == "A.Init,B.Init,A.Start,B.Start,B.Destroy,A.Destroy", table.concat(log, ","))

-- A failing Start destroys everything already initialised and names the culprit.
table.clear(log)
local ok, message = pcall(function()
	Lifecycle.new({ system("A", {}), system("B", { "A" }, true) }):Start()
end)
assert(not ok and string.find(tostring(message), "[B.Start]", 1, true))
assert(table.concat(log, ",") == "A.Init,B.Init,A.Start,B.Destroy,A.Destroy", table.concat(log, ","))

-- Missing hooks, missing Dependencies, unknown or misordered dependencies and duplicates fail at boot.
local incomplete = system("C", {})
incomplete.Destroy = nil
assert(not pcall(Lifecycle.new, { incomplete }))
local undeclared = system("D", {})
undeclared.Dependencies = nil
assert(not pcall(Lifecycle.new, { undeclared }))
assert(not pcall(Lifecycle.new, { system("B", { "A" }), system("A", {}) }))
assert(not pcall(Lifecycle.new, { system("A", {}), system("A", {}) }))

print("PASS lifecycle: order, rollback, required hooks and dependency order")
return true
