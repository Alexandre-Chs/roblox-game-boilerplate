--!strict

local Packet = require(script.Parent.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
	BuyItem = Packet("BuyItem", Packet.String):Response(Packet.Boolean8, Packet.String):RateLimit(5, 1),
}

return Packets
