--!strict

-- Pure chat command parsing shared by DebugService and AdminService, tested in tests/run.luau.
local Commands = {}

-- "/cash 100" -> "cash", { "100" }. Returns nil for text that is not a command.
function Commands.Parse(text: string): (string?, { string })
	local words = string.split(string.gsub(text, "^%s+", ""), " ")
	local first = table.remove(words, 1)
	if not first or string.sub(first, 1, 1) ~= "/" or #first < 2 then
		return nil, {}
	end
	local args = {}
	for _, word in words do
		if word ~= "" then
			table.insert(args, word)
		end
	end
	return string.lower(string.sub(first, 2)), args
end

-- Whole numbers only, within a sane testing range.
function Commands.Amount(text: string?): number?
	local value = if text then tonumber(text) else nil
	if value and value % 1 == 0 and math.abs(value) <= 1e9 then
		return value
	end
	return nil
end

return Commands
