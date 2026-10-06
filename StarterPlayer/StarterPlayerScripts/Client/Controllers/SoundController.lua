local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

ReplicatedStorage:WaitForChild("Shared") -- wait until the shared modules have replicated
local Config = require(ReplicatedStorage.Shared.Config)
local Network = require(ReplicatedStorage.Shared.Network)

local SoundController = {}

local soundsByName: { [string]: Sound } = {}

function SoundController.Play(soundName: string)
	local sound = soundsByName[soundName]
	if sound then
		sound:Play()
	end
end

function SoundController.Init()
	local soundFolder = Instance.new("Folder")
	soundFolder.Name = "GameSounds"
	soundFolder.Parent = SoundService

	-- Sounds without an id are skipped, so the game also works without audio.
	for soundName, soundId in pairs(Config.Sounds.Ids) do
		if soundId ~= "" then
			local sound = Instance.new("Sound")
			sound.Name = soundName
			sound.SoundId = soundId
			sound.Volume = Config.Sounds.Volume
			sound.Parent = soundFolder
			soundsByName[soundName] = sound
		end
	end

	Network.Connect("PlaySound", function(soundName: unknown)
		if typeof(soundName) == "string" then
			SoundController.Play(soundName)
		end
	end)
end

return SoundController
