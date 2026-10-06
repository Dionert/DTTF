export type RoundState = "WAITING" | "INTERMISSION" | "STARTING" | "PLAYING" | "WINNER" | "RESET"
export type TileState = "SAFE" | "WARNING" | "DANGER" | "HOLE"
export type SoundName = "Warning" | "Danger" | "Eliminated" | "Winner" | "Countdown" | "Go"
export type AttributeName = "InRound" | "State"

return table.freeze({
	RoundState = table.freeze({
		WAITING = "WAITING" :: "WAITING", -- Not enough players to start a round
		INTERMISSION = "INTERMISSION" :: "INTERMISSION", -- Countdown before the next round
		STARTING = "STARTING" :: "STARTING", -- Players are placed on the arena and frozen
		PLAYING = "PLAYING" :: "PLAYING", -- Tiles are collapsing
		WINNER = "WINNER" :: "WINNER", -- Result is being shown
		RESET = "RESET" :: "RESET", -- Arena and players are being restored
	}),

	TileState = table.freeze({
		SAFE = "SAFE" :: "SAFE",
		WARNING = "WARNING" :: "WARNING",
		DANGER = "DANGER" :: "DANGER",
		HOLE = "HOLE" :: "HOLE",
	}),

	Sound = table.freeze({
		Warning = "Warning" :: "Warning",
		Danger = "Danger" :: "Danger",
		Eliminated = "Eliminated" :: "Eliminated",
		Winner = "Winner" :: "Winner",
		Countdown = "Countdown" :: "Countdown",
		Go = "Go" :: "Go",
	}),

	Attribute = table.freeze({
		InRound = "InRound" :: "InRound", -- Set on players that are still alive in the round
		TileState = "State" :: "State", -- Set on tile parts
	}),
})
