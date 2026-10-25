--!strict

-- Badge ids from the Creator Dashboard (Engagement > Badges). 0 = not created; awarding skips it.
return table.freeze({
	Welcome = 0,
	FirstPurchase = 0,
	Streak7 = 0,
}) :: { [string]: number }
