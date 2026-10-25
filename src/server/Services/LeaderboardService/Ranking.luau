--!strict

-- Pure merge of the stored global top list with live values, tested in tests/run.luau.
local Ranking = {}

export type Entry = { UserId: number, Name: string, Value: number }

-- Live entries replace stored ones for the same user (they are fresher). Highest first,
-- ties by UserId so every server shows the same order; at most size entries.
function Ranking.Merge(stored: { Entry }, live: { Entry }, size: number): { Entry }
	local byUser: { [number]: Entry } = {}
	for _, entry in stored do
		byUser[entry.UserId] = entry
	end
	for _, entry in live do
		byUser[entry.UserId] = entry
	end
	local list: { Entry } = {}
	for _, entry in byUser do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		if a.Value ~= b.Value then
			return a.Value > b.Value
		end
		return a.UserId < b.UserId
	end)
	while #list > size do
		table.remove(list)
	end
	return list
end

return Ranking
