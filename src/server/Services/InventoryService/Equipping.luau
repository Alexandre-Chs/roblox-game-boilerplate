--!strict

-- Pure equip rule for InventoryService, tested in tests/run.luau. "" unequips.
local Equipping = {}

export type Result = "Ok" | "UnknownItem" | "NotOwned"

function Equipping.Check(
	data: { Inventory: { [string]: boolean } },
	catalog: { [string]: any },
	itemId: any
): Result
	if itemId == "" then
		return "Ok"
	elseif type(itemId) ~= "string" or catalog[itemId] == nil then
		return "UnknownItem"
	elseif data.Inventory[itemId] ~= true then
		return "NotOwned"
	end
	return "Ok"
end

return Equipping
