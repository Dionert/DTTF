local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PartFactory = require(script.Parent.Parent.Util.PartFactory)
local TileService = require(script.Parent.TileService)

local ArenaService = {}

local tilesFolder: Folder? = nil
local spawnPositions: { Vector3 } = {}
local spectatorSpot = Vector3.zero
local random = Random.new()

local function buildSpectatorWalls(parent: Instance, platformCenter: Vector3)
	local settings = Config.Spectator
	local halfPlatformSize = settings.PlatformSize / 2
	local wallCenterY = settings.PlatformThickness / 2 + settings.WallHeight / 2

	local frontBackSize = Vector3.new(settings.PlatformSize, settings.WallHeight, 1)
	local leftRightSize = Vector3.new(1, settings.WallHeight, settings.PlatformSize)

	local walls: { { Size: Vector3, Offset: Vector3 } } = {
		{ Size = frontBackSize, Offset = Vector3.new(0, wallCenterY, halfPlatformSize) },
		{ Size = frontBackSize, Offset = Vector3.new(0, wallCenterY, -halfPlatformSize) },
		{ Size = leftRightSize, Offset = Vector3.new(halfPlatformSize, wallCenterY, 0) },
		{ Size = leftRightSize, Offset = Vector3.new(-halfPlatformSize, wallCenterY, 0) },
	}

	for index, wallData in walls do
		local wall = PartFactory.Solid(
			`SpectatorWall{index}`,
			wallData.Size,
			CFrame.new(platformCenter + wallData.Offset),
			settings.Color,
			parent
		)
		wall.Transparency = 1
	end
end

local function buildSpectatorPlatform(parent: Instance)
	local settings = Config.Spectator
	local arenaSettings = Config.Arena

	local halfArenaSize = (arenaSettings.GridSize * arenaSettings.TileSize) / 2
	local platformCenter = arenaSettings.Origin
		+ Vector3.new(0, settings.HeightAboveArena, -(halfArenaSize + settings.DistanceBehindArena))

	PartFactory.Solid(
		"SpectatorPlatform",
		Vector3.new(settings.PlatformSize, settings.PlatformThickness, settings.PlatformSize),
		CFrame.new(platformCenter),
		settings.Color,
		parent
	)
	buildSpectatorWalls(parent, platformCenter)

	spectatorSpot = platformCenter + Vector3.yAxis * (settings.PlatformThickness / 2)
end

function ArenaService.Build(): Folder
	local previousArena = workspace:FindFirstChild("Arena")
	if previousArena then
		previousArena:Destroy()
	end
	TileService.Clear()
	spawnPositions = {}

	local settings = Config.Arena

	local arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "Arena"

	local newTilesFolder = Instance.new("Folder")
	newTilesFolder.Name = "Tiles"
	newTilesFolder.Parent = arenaFolder
	tilesFolder = newTilesFolder

	local gridSize = settings.GridSize
	local tileSize = settings.TileSize
	local halfGridSize = (gridSize * tileSize) / 2

	for gridX = 1, gridSize do
		for gridZ = 1, gridSize do
			local tileCenter = settings.Origin
				+ Vector3.new((gridX - 0.5) * tileSize - halfGridSize, 0, (gridZ - 0.5) * tileSize - halfGridSize)

			local tilePart = PartFactory.Solid(
				`Tile_{gridX}_{gridZ}`,
				Vector3.new(tileSize - settings.TileGap, settings.TileHeight, tileSize - settings.TileGap),
				CFrame.new(tileCenter),
				Config.Tiles.Colors.SAFE,
				newTilesFolder
			)
			TileService.Register(tilePart)

			-- Only every other tile (checkerboard) is a spawn point, so players start spread out.
			if (gridX + gridZ) % 2 == 0 then
				table.insert(spawnPositions, tileCenter + Vector3.yAxis * (settings.TileHeight / 2))
			end
		end
	end

	buildSpectatorPlatform(arenaFolder)

	arenaFolder.Parent = workspace
	return arenaFolder
end

function ArenaService.Reset()
	TileService.ResetAll()
end

-- Returns `count` spawn positions in random order. Positions are reused when
-- there are more players than spawn points.
function ArenaService.GetSpawnPositions(count: number): { Vector3 }
	local shuffled = table.clone(spawnPositions)
	for index = #shuffled, 2, -1 do
		local swapIndex = random:NextInteger(1, index)
		shuffled[index], shuffled[swapIndex] = shuffled[swapIndex], shuffled[index]
	end

	local positions: { Vector3 } = {}
	for index = 1, count do
		positions[index] = shuffled[((index - 1) % #shuffled) + 1]
	end
	return positions
end

function ArenaService.GetSpectatorSpot(): Vector3
	local spread = Config.Spectator.SpotSpread
	return spectatorSpot + Vector3.new(random:NextNumber(-spread, spread), 0, random:NextNumber(-spread, spread))
end

function ArenaService.GetTilesFolder(): Folder
	assert(tilesFolder, "[ArenaService] The arena has not been built yet")
	return tilesFolder
end

return ArenaService
