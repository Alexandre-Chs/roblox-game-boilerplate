--!strict

export type System = {
	Name: string,
	-- Names of systems this one calls ({} if none). Each must be registered earlier in the registry.
	Dependencies: { string },
	-- All three hooks are required, empty when unused, so cleanup is never forgotten by omission.
	Init: (self: any, systems: { [string]: any }) -> (),
	Start: (self: any) -> (),
	Destroy: (self: any) -> (),
}

local Lifecycle = {}
Lifecycle.__index = Lifecycle

function Lifecycle.new(systems: { System })
	local byName: { [string]: any } = {}
	for _, system in systems do
		assert(type(system.Name) == "string" and #system.Name > 0, "System needs a Name")
		assert(byName[system.Name] == nil, `Duplicate system: {system.Name}`)
		for _, hook in { "Init", "Start", "Destroy" } do
			-- Required even when empty, so cleanup is never forgotten by omission.
			assert(
				type((system :: any)[hook]) == "function",
				`{system.Name} must declare {hook} (empty if unused)`
			)
		end
		assert(
			type(system.Dependencies) == "table",
			`{system.Name} must declare Dependencies (an empty table if none)`
		)
		for _, dependency in system.Dependencies do
			assert(
				byName[dependency] ~= nil,
				`{system.Name} depends on {dependency}, which must be registered before it`
			)
		end
		byName[system.Name] = system
	end

	return setmetatable({
		_systems = table.clone(systems),
		_byName = table.freeze(byName),
		_initialized = {} :: { System },
		_state = "Created",
	}, Lifecycle)
end

function Lifecycle.Destroy(self: Lifecycle)
	if self._state == "Destroyed" then
		return
	end
	self._state = "Destroyed"
	for index = #self._initialized, 1, -1 do
		local system = self._initialized[index]
		local destroy = system.Destroy
		if destroy then
			local ok, message = xpcall(function()
				destroy(system)
			end, debug.traceback)
			if not ok then
				warn(`[{system.Name}.Destroy] {message}`)
			end
		end
	end
	table.clear(self._initialized)
end

function Lifecycle.Start(self: Lifecycle)
	assert(self._state == "Created", `Cannot start lifecycle in state {self._state}`)
	self._state = "Starting"
	local phase = "Init"
	local activeName = "unknown"
	local ok, message = xpcall(function()
		for _, system in self._systems do
			activeName = system.Name
			table.insert(self._initialized, system)
			local init = system.Init
			if init then
				init(system, self._byName)
			end
		end
		phase = "Start"
		for _, system in self._systems do
			activeName = system.Name
			local start = system.Start
			if start then
				start(system)
			end
		end
	end, debug.traceback)
	if not ok then
		self:Destroy()
		error(`[{activeName}.{phase}] {message}`, 0)
	end
	self._state = "Started"
end

export type Lifecycle = typeof(setmetatable({
	_systems = {} :: { System },
	_byName = {} :: { [string]: any },
	_initialized = {} :: { System },
	_state = "Created",
}, Lifecycle))

return Lifecycle
