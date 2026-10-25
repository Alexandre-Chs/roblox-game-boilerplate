--!strict

-- Pure daily streak rules shared by DailyRewardService (authority) and the DailyReward screen (display).
export type State = { LastClaimDay: number, Streak: number }

local DailyReward = {}

-- UTC day number; the server passes os.time(), the client workspace:GetServerTimeNow().
function DailyReward.Today(unixSeconds: number): number
	return unixSeconds // 86400
end

-- Returns whether a claim is possible today, the streak it would reach and its reward.
function DailyReward.Evaluate(state: State, today: number, rewards: { number }): (boolean, number, number)
	if state.LastClaimDay >= today then
		return false, state.Streak, 0
	end
	local streak = if state.LastClaimDay == today - 1 then state.Streak + 1 else 1
	return true, streak, rewards[(streak - 1) % #rewards + 1]
end

return DailyReward
