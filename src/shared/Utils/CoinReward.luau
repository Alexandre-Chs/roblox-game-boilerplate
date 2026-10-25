--!strict

-- Pure coin payout rule shared by the Coin component and tests.
-- roll (0 <= roll < 1) turns the fractional part into a chance of one more coin,
-- so a +10% friend bonus on a 1-coin pickup still pays out 10% more on average.
local CoinReward = {}

export type Community = { FriendBonus: number, MaxFriends: number }

function CoinReward.Amount(
	base: number,
	multiplier: number,
	friends: number,
	community: Community,
	roll: number
): number
	local bonus = 1 + math.min(math.max(friends, 0), community.MaxFriends) * community.FriendBonus
	local exact = base * multiplier * bonus
	local whole = math.floor(exact)
	return if roll < exact - whole then whole + 1 else whole
end

return CoinReward
