--!strict

-- Pure error grouping for ErrorReportService, tested in tests/run.luau.
local Errors = {}

-- Turns one error message into a short, stable key: script paths kept to their last part,
-- numbers and quoted values removed, so the same bug groups under one analytics label.
function Errors.Key(message: string): string
	local text = string.gsub(message, "[%w_]+%.[%w_%.]+%.([%w_]+):", "%1:")
	text = string.gsub(text, '"[^"]*"', '""')
	text = string.gsub(text, "%d+", "#")
	text = string.gsub(text, "%s+", " ")
	text = string.gsub(text, "^%s*(.-)%s*$", "%1")
	-- Short keys: the dashboard groups many distinct custom field values into "Other".
	return string.sub(text, 1, 60)
end

-- Allows each key at most once per window seconds. Returns whether to report it now.
function Errors.Throttle(seen: { [string]: number }, key: string, now: number, window: number): boolean
	local last = seen[key]
	if last and now - last < window then
		return false
	end
	seen[key] = now
	return true
end

return Errors
