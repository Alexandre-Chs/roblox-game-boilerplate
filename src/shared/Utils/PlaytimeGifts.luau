--!strict

-- Pure playtime gift rule shared by PlaytimeService (authority) and the Hud gift button.
-- claimed holds the gift indexes already taken this session.
local PlaytimeGifts = {}

export type Gift = { Minutes: number, Coins: number }

-- The next unclaimed gift and the seconds until it can be claimed (0 = ready),
-- or nil when every gift of the session is taken. Gifts unlock in list order.
function PlaytimeGifts.Next(
	elapsed: number,
	gifts: { Gift },
	claimed: { [number]: boolean }
): (number?, number)
	for index, gift in gifts do
		if not claimed[index] then
			return index, math.max(0, gift.Minutes * 60 - elapsed)
		end
	end
	return nil, 0
end

return PlaytimeGifts
