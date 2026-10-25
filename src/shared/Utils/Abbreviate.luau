--!strict

-- Short number for boards and counters: 999 -> "999", 1500 -> "1.5K", 2000000 -> "2M".
local UNITS: { { Size: number, Suffix: string } } = {
	{ Size = 1e12, Suffix = "T" },
	{ Size = 1e9, Suffix = "B" },
	{ Size = 1e6, Suffix = "M" },
	{ Size = 1e3, Suffix = "K" },
}

return function(value: number): string
	for _, unit in UNITS do
		if value >= unit.Size then
			local text = string.format("%.1f", math.floor(value / unit.Size * 10) / 10)
			return (string.gsub(text, "%.0$", "")) .. unit.Suffix
		end
	end
	return tostring(math.floor(value))
end
