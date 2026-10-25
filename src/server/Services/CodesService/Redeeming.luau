--!strict

-- Pure promo code rules for CodesService, tested in tests/run.luau.
local Redeeming = {}

export type Result = "Ok" | "Invalid" | "Expired" | "AlreadyRedeemed"

-- Trims, upper-cases and rejects anything but 1 to 32 letters, digits, - or _.
function Redeeming.Normalize(text: any): string?
	if type(text) ~= "string" or #text > 64 then
		return nil
	end
	local code = string.upper((string.gsub(text, "^%s*(.-)%s*$", "%1")))
	if #code == 0 or #code > 32 or string.find(code, "[^%w_%-]") then
		return nil
	end
	return code
end

-- redeemed holds "Code_<CODE>" keys (PlayerData.Redeemed).
function Redeeming.Check(
	redeemed: { [string]: boolean },
	codes: { [string]: { Coins: number, Expires: number } },
	code: string?,
	now: number
): Result
	local entry = if code then codes[code] else nil
	if not code or not entry then
		return "Invalid"
	elseif entry.Expires ~= 0 and now >= entry.Expires then
		return "Expired"
	elseif redeemed[Redeeming.Key(code)] then
		return "AlreadyRedeemed"
	end
	return "Ok"
end

function Redeeming.Key(code: string): string
	return `Code_{code}`
end

return Redeeming
