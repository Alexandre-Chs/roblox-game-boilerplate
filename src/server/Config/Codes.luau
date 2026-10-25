--!strict

-- Promo codes. Server-only so players cannot read unreleased codes from the client.
-- Keys are upper case; players may type any case. Expires is a Unix time (0 = never).
export type Code = { Coins: number, Expires: number }

return table.freeze({
	WELCOME = table.freeze({ Coins = 50, Expires = 0 }),
	RELEASE = table.freeze({ Coins = 100, Expires = 0 }),
}) :: { [string]: Code }
