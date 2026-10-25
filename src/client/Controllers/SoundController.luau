--!strict

-- Plays music and sound effects through two SoundGroups whose volumes follow the
-- player's saved Settings. Ids come from Config/Sounds; empty ids stay silent.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Sounds = require(ReplicatedStorage.Config.Sounds)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SoundController = { Name = "SoundController", Dependencies = { "DataController" } }
local registry: { [string]: any } = {}
local trove = Trove.new()
local sfxGroup: SoundGroup? = nil

function SoundController.Init(_self: any, controllers: { [string]: any })
	registry = controllers
end

function SoundController.Start(_self: any)
	local musicGroup = trove:Add(Instance.new("SoundGroup"))
	musicGroup.Name = "Music"
	musicGroup.Parent = SoundService
	local effects = trove:Add(Instance.new("SoundGroup"))
	effects.Name = "Sfx"
	effects.Parent = SoundService
	sfxGroup = effects

	local data = registry.DataController
	trove:Add(data:Observe({ "Settings", "MusicVolume" }, function(volume: any)
		musicGroup.Volume = if type(volume) == "number" then volume else 0.5
	end))
	trove:Add(data:Observe({ "Settings", "SfxVolume" }, function(volume: any)
		effects.Volume = if type(volume) == "number" then volume else 0.8
	end))

	if Sounds.Music ~= "" then
		local music = trove:Add(Instance.new("Sound"))
		music.Name = "Music"
		music.SoundId = Sounds.Music
		music.Looped = true
		music.SoundGroup = musicGroup
		music.Parent = musicGroup
		music:Play()
	end
end

-- Plays a named effect from Config/Sounds.Sfx once. Unknown or empty names do nothing.
function SoundController.PlaySfx(_self: any, name: string)
	local id = (Sounds.Sfx :: { [string]: string })[name]
	local group = sfxGroup
	if not id or id == "" or not group then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.SoundGroup = group
	sound.Parent = group
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

function SoundController.Destroy(_self: any)
	sfxGroup = nil
	trove:Clean()
end

return SoundController
