export type GameConfig = {
	Round: {
		MinPlayers: number,
		IntermissionTime: number, -- seconds
		CountdownTime: number, -- seconds
		WinnerDisplayTime: number, -- seconds
		LeaderboardRefreshDelay: number, -- seconds
		UpdateInterval: number, -- seconds between client updates
		SyncCooldown: number, -- seconds between client state syncs
	},

	Players: {
		TeleportHeight: number, -- studs above the target position
	},

	Lobby: {
		FloorSize: Vector3,
		FloorColor: Color3,
		SpawnSize: Vector3,
		SpawnPosition: Vector3,
		SpawnColor: Color3,
		BoardSize: Vector3,
		BoardPosition: Vector3,
		BoardColor: Color3,
	},

	Arena: {
		GridSize: number, -- tiles per side
		TileSize: number, -- studs
		TileHeight: number, -- studs
		TileGap: number, -- studs
		Origin: Vector3,
		KillDepth: number, -- studs below the origin
	},

	Spectator: {
		PlatformSize: number,
		PlatformThickness: number,
		HeightAboveArena: number,
		DistanceBehindArena: number,
		WallHeight: number,
		SpotSpread: number, -- random spawn offset in studs
		Color: Color3,
	},

	Tiles: {
		WarningTime: number, -- seconds
		DangerTime: number, -- seconds
		HoleFadeTime: number, -- seconds
		HoleSinkDistance: number, -- studs
		Colors: {
			SAFE: Color3,
			WARNING: Color3,
			DANGER: Color3,
		},
	},

	Difficulty: {
		FirstPickDelay: number, -- seconds
		StartInterval: number, -- seconds between picks at the start
		EndInterval: number, -- seconds between picks at full ramp
		RampTime: number, -- seconds until full ramp
		MinTilesPerPick: number,
		MaxTilesPerPick: number,
		IntervalJitter: { Min: number, Max: number },
		OvertimeAfter: number, -- seconds
		OvertimeInterval: number, -- seconds
		OvertimeExtraTiles: number,
	},

	HitDetection: {
		R6FeetDistance: number, -- studs from the root part to the feet
		GroundTolerance: number, -- studs
	},

	Sounds: {
		Volume: number,
		Ids: { [string]: string }, -- keyed by sound name, empty string = disabled
	},

	Data: {
		WinsStoreName: string,
		TopStoreName: string,
		Retries: number,
		ShutdownTimeout: number, -- seconds
	},

	Leaderboard: {
		Size: number,
		RefreshSeconds: number,
	},

	UI: {
		Colors: {
			White: Color3,
			Red: Color3,
			Gold: Color3,
			Green: Color3,
		},
	},
}

local function deepFreeze<T>(value: T): T
	if type(value) == "table" then
		for _, child in pairs(value :: any) do
			deepFreeze(child)
		end
		table.freeze(value :: any)
	end
	return value
end

local config: GameConfig = {
	Round = {
		MinPlayers = 1,
		IntermissionTime = 10,
		CountdownTime = 5,
		WinnerDisplayTime = 3,
		LeaderboardRefreshDelay = 3,
		UpdateInterval = 0.5,
		SyncCooldown = 1,
	},

	Players = {
		TeleportHeight = 3.5,
	},

	Lobby = {
		FloorSize = Vector3.new(80, 2, 80),
		FloorColor = Color3.fromRGB(60, 63, 75),
		SpawnSize = Vector3.new(12, 1, 12),
		SpawnPosition = Vector3.new(0, 1.5, 0),
		SpawnColor = Color3.fromRGB(90, 95, 115),
		BoardSize = Vector3.new(26, 14, 1),
		BoardPosition = Vector3.new(0, 9, 36),
		BoardColor = Color3.fromRGB(20, 22, 30),
	},

	Arena = {
		GridSize = 10,
		TileSize = 8,
		TileHeight = 1,
		TileGap = 0.3,
		Origin = Vector3.new(0, 60, 250),
		KillDepth = 25,
	},

	Spectator = {
		PlatformSize = 30,
		PlatformThickness = 2,
		HeightAboveArena = 25,
		DistanceBehindArena = 30,
		WallHeight = 40,
		SpotSpread = 10,
		Color = Color3.fromRGB(60, 63, 75),
	},

	Tiles = {
		WarningTime = 1.5,
		DangerTime = 2,
		HoleFadeTime = 0.8,
		HoleSinkDistance = 8,
		Colors = {
			SAFE = Color3.fromRGB(67, 200, 90),
			WARNING = Color3.fromRGB(255, 214, 51),
			DANGER = Color3.fromRGB(235, 40, 40),
		},
	},

	Difficulty = {
		FirstPickDelay = 2,
		StartInterval = 3,
		EndInterval = 1,
		RampTime = 120,
		MinTilesPerPick = 1,
		MaxTilesPerPick = 3,
		IntervalJitter = { Min = 0.85, Max = 1.15 },
		OvertimeAfter = 240,
		OvertimeInterval = 0.5,
		OvertimeExtraTiles = 3,
	},

	HitDetection = {
		R6FeetDistance = 3,
		GroundTolerance = 0.75,
	},

	Sounds = {
		Volume = 0.5,
		Ids = {
			Warning = "",
			Danger = "",
			Eliminated = "",
			Winner = "",
			Countdown = "",
			Go = "",
		},
	},

	Data = {
		WinsStoreName = "PlayerWins_v1",
		TopStoreName = "TopWins_v1",
		Retries = 3,
		ShutdownTimeout = 25,
	},

	Leaderboard = {
		Size = 10,
		RefreshSeconds = 60,
	},

	UI = {
		Colors = {
			White = Color3.new(1, 1, 1),
			Red = Color3.fromRGB(235, 60, 60),
			Gold = Color3.fromRGB(255, 215, 0),
			Green = Color3.fromRGB(80, 220, 110),
		},
	},
}

return deepFreeze(config)
