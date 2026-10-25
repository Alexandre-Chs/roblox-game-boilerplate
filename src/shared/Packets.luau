--!strict

local Packet = require(script.Parent.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
	BuyItem = Packet("BuyItem", Packet.String):Response(Packet.Boolean8, Packet.String):RateLimit(5, 1),
	ClaimDaily = Packet("ClaimDaily"):Response(Packet.Boolean8, Packet.NumberU16):RateLimit(2, 1),
	SetSetting = Packet("SetSetting", Packet.String, Packet.NumberF32):RateLimit(10, 1),
	-- "" unequips. Replies (ok, reason).
	Equip = Packet("Equip", Packet.String):Response(Packet.Boolean8, Packet.String):RateLimit(5, 1),
	-- Replies (ok, message to show). Tight limit: codes must not be brute-forced.
	RedeemCode = Packet("RedeemCode", Packet.String)
		:Response(Packet.Boolean8, Packet.String)
		:RateLimit(3, 10),
	ClaimGroupReward = Packet("ClaimGroupReward"):Response(Packet.Boolean8, Packet.String):RateLimit(2, 5),
	-- Claims the next playtime gift; replies (ok, coins).
	ClaimPlaytimeGift = Packet("ClaimPlaytimeGift")
		:Response(Packet.Boolean8, Packet.NumberU16)
		:RateLimit(2, 2),
	-- Client script errors for ErrorReportService; the limit keeps a looping error from flooding.
	ReportError = Packet("ReportError", Packet.String):RateLimit(3, 10),
	-- Analytics only: tells the server the shop screen opened.
	ShopOpened = Packet("ShopOpened"):RateLimit(2, 1),
	-- Server to client only; the limit only bounds clients that fire it anyway.
	Notify = Packet("Notify", Packet.String):RateLimit(1, 1),
}

return Packets
