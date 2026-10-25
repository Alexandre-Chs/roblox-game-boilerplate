--!strict

-- Translates keyed, dynamic text with the LocalizationTable in assets/localization/Strings.csv.
-- Static UI text needs nothing: Roblox auto-translates any GUI text that matches a Source.
-- Format never yields: until the player's translator has loaded (Prepare) it returns the
-- English fallback with {1}, {2}... filled in. Works on the server (pass the player) and client.
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local Locale = {}
local translators: { [Player]: Translator } = setmetatable({}, { __mode = "k" }) :: any

local function fill(text: string, args: { any }): string
	return (
		string.gsub(text, "{(%d+)}", function(index: string)
			local value = args[tonumber(index) :: number]
			return if value ~= nil then tostring(value) else `\{{index}\}`
		end)
	)
end

-- Loads the player's translator in the background. Call once per player.
function Locale.Prepare(player: Player)
	task.spawn(function()
		local ok, translator =
			pcall(LocalizationService.GetTranslatorForPlayerAsync, LocalizationService, player)
		if ok then
			translators[player] = translator
		end
	end)
end

function Locale.Format(player: Player?, key: string, args: { any }, fallback: string): string
	local translator = translators[player or Players.LocalPlayer]
	if translator then
		local ok, text = pcall(translator.FormatByKey, translator, key, args)
		if ok then
			return text
		end
	end
	return fill(fallback, args)
end

return Locale
