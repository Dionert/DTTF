local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PartFactory = require(script.Parent.Parent.Util.PartFactory)

local LobbyService = {}

local lobbyFolder: Folder? = nil
local leaderboardBoard: Part? = nil

function LobbyService.Build(): Folder
	if lobbyFolder then
		return lobbyFolder
	end

	-- Remove default spawns so players always spawn in the lobby.
	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	local settings = Config.Lobby

	local newLobbyFolder = Instance.new("Folder")
	newLobbyFolder.Name = "Lobby"

	PartFactory.Solid("LobbyFloor", settings.FloorSize, CFrame.identity, settings.FloorColor, newLobbyFolder)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = settings.SpawnSize
	spawnLocation.Position = settings.SpawnPosition
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Color = settings.SpawnColor
	spawnLocation.Material = Enum.Material.SmoothPlastic
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.Parent = newLobbyFolder

	leaderboardBoard = PartFactory.Solid(
		"LeaderboardBoard",
		settings.BoardSize,
		CFrame.new(settings.BoardPosition),
		settings.BoardColor,
		newLobbyFolder
	)

	newLobbyFolder.Parent = workspace
	lobbyFolder = newLobbyFolder
	return newLobbyFolder
end

function LobbyService.GetLeaderboardBoard(): Part?
	return leaderboardBoard
end

return LobbyService
