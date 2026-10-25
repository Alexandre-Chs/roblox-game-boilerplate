--!strict

-- Pure coin payout rule shared by the Coin component and tests.
-- roll (0 <= roll < 1) turns the fractional part into a chance of one more coin,
-- so a +10% bonus on a 1-coin pickup still pays out 10% more on average.
local CoinReward = {}

export type Community = { FriendBonus: number, MaxFriends: number }

-- Extra share from friends in the server (capped) plus the Premium bonus when it applies.
function CoinReward.Bonus(
	friends: number,
	community: Community,
	premium: boolean,
	premiumBonus: number
): number
	local fromFriends = math.min(math.max(friends, 0), community.MaxFriends) * community.FriendBonus
	return fromFriends + if premium then premiumBonus else 0
end

function CoinReward.Amount(base: number, multiplier: number, bonus: number, roll: number): number
	local exact = base * multiplier * (1 + bonus)
	local whole = math.floor(exact)
	return if roll < exact - whole then whole + 1 else whole
end

return CoinReward
