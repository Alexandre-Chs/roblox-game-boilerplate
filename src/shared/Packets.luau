--!strict

local Packet = require(script.Parent.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
	BuyItem = Packet("BuyItem", Packet.String):Response(Packet.Boolean8, Packet.String):RateLimit(5, 1),
	ClaimDaily = Packet("ClaimDaily"):Response(Packet.Boolean8, Packet.NumberU16):RateLimit(2, 1),
	SetSetting = Packet("SetSetting", Packet.String, Packet.NumberF32):RateLimit(10, 1),
	-- Server to client only; the limit only bounds clients that fire it anyway.
	Notify = Packet("Notify", Packet.String):RateLimit(1, 1),
}

return Packets
