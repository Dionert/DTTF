local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Enums = require(ReplicatedStorage.Shared.Enums)
local Network = require(ReplicatedStorage.Shared.Network)

local Difficulty = require(script.Parent.Parent.Util.Difficulty)

local ArenaService = require(script.Parent.ArenaService)
local TileService = require(script.Parent.TileService)
local PlayerService = require(script.Parent.PlayerService)
local HitService = require(script.Parent.HitService)
local DataService = require(script.Parent.DataService)
local LeaderboardService = require(script.Parent.LeaderboardService)

local RoundState = Enums.RoundState
local Sound = Enums.Sound

local WAITING_POLL_SECONDS = 1
local PLAYING_TICK_SECONDS = 0.1
local ERROR_RECOVERY_SECONDS = 2

local RoundService = {}

local currentState: Enums.RoundState = RoundState.WAITING
local currentStateValue: number? = nil
local roundStartClock = 0
local lastSyncClockByPlayer: { [Player]: number } = {}

local function setRoundState(state: Enums.RoundState, value: number?)
	currentState = state
	currentStateValue = value
	Network.FireAllClients("StateChanged", state, value)
end

local function hasEnoughPlayers(): boolean
	return #Players:GetPlayers() >= Config.Round.MinPlayers
end

local function playSoundForAll(soundName: Enums.SoundName)
	Network.FireAllClients("PlaySound", soundName)
end

local function runWaitingPhase()
	setRoundState(RoundState.WAITING)
	while not hasEnoughPlayers() do
		task.wait(WAITING_POLL_SECONDS)
	end
end

-- Returns false when too many players left and the round has to be cancelled.
local function runIntermissionPhase(): boolean
	for secondsRemaining = Config.Round.IntermissionTime, 1, -1 do
		if not hasEnoughPlayers() then
			return false
		end
		setRoundState(RoundState.INTERMISSION, secondsRemaining)
		task.wait(1)
	end
	return hasEnoughPlayers()
end

-- Returns the number of players that start the round, or nil when it was cancelled.
local function runStartingPhase(): number?
	local participants = PlayerService.GetEligiblePlayers()
	if #participants < Config.Round.MinPlayers then
		task.wait(1)
		return nil
	end

	ArenaService.Reset()
	PlayerService.StartRound(participants, ArenaService.GetSpawnPositions(#participants))

	for secondsRemaining = Config.Round.CountdownTime, 1, -1 do
		setRoundState(RoundState.STARTING, secondsRemaining)
		playSoundForAll(Sound.Countdown)
		task.wait(1)
	end

	-- Players may have left or died during the countdown.
	if PlayerService.GetAliveCount() < Config.Round.MinPlayers then
		PlayerService.EndRound()
		ArenaService.Reset()
		return nil
	end

	return #participants
end

-- Runs until the round is decided. Returns the winner, or nil for a draw.
local function runPlayingPhase(startingPlayerCount: number): Player?
	PlayerService.Unfreeze()
	HitService.SetEnabled(true)
	setRoundState(RoundState.PLAYING, 0)
	playSoundForAll(Sound.Go)

	roundStartClock = os.clock()
	local nextPickClock = roundStartClock + Config.Difficulty.FirstPickDelay
	local nextUpdateClock = 0

	-- A solo round only ends when the player is eliminated.
	local aliveCountThatEndsRound = if startingPlayerCount > 1 then 1 else 0

	while PlayerService.GetAliveCount() > aliveCountThatEndsRound do
		local nowClock = os.clock()
		local elapsedSeconds = nowClock - roundStartClock

		if nowClock >= nextUpdateClock then
			nextUpdateClock = nowClock + Config.Round.UpdateInterval
			Network.FireAllClients("RoundUpdate", PlayerService.GetAliveCount(), elapsedSeconds)
		end

		if nowClock >= nextPickClock then
			local pickIntervalSeconds, tileCount = Difficulty.Get(elapsedSeconds)

			local pickedTiles = TileService.PickRandomSafe(tileCount)
			if #pickedTiles > 0 then
				for _, tile in pickedTiles do
					TileService.Trigger(tile)
				end
				playSoundForAll(Sound.Warning)
				task.delay(Config.Tiles.WarningTime, playSoundForAll, Sound.Danger)
			end

			nextPickClock = os.clock() + pickIntervalSeconds
		end

		task.wait(PLAYING_TICK_SECONDS)
	end

	HitService.SetEnabled(false)

	if startingPlayerCount > 1 and PlayerService.GetAliveCount() == 1 then
		return PlayerService.GetAlivePlayers()[1]
	end
	return nil
end

local function runWinnerPhase(winner: Player?)
	setRoundState(RoundState.WINNER)

	if winner then
		DataService.AddWin(winner)
		Network.FireAllClients("RoundWinner", winner.DisplayName, winner.UserId)
		playSoundForAll(Sound.Winner)
	else
		Network.FireAllClients("RoundDraw")
	end

	task.wait(Config.Round.WinnerDisplayTime)
end

local function runResetPhase()
	setRoundState(RoundState.RESET)
	PlayerService.EndRound()
	ArenaService.Reset()
	task.delay(Config.Round.LeaderboardRefreshDelay, LeaderboardService.Refresh)
end

local function runRound()
	runWaitingPhase()

	if not runIntermissionPhase() then
		return
	end

	local startingPlayerCount = runStartingPhase()
	if not startingPlayerCount then
		return
	end

	local winner = runPlayingPhase(startingPlayerCount)
	runWinnerPhase(winner)
	runResetPhase()
end

-- Brings late joiners up to date with the current round state.
local function onClientReady(player: Player)
	local nowClock = os.clock()
	local lastSyncClock = lastSyncClockByPlayer[player]
	if lastSyncClock and nowClock - lastSyncClock < Config.Round.SyncCooldown then
		return
	end
	lastSyncClockByPlayer[player] = nowClock

	Network.FireClient("StateChanged", player, currentState, currentStateValue)
	if currentState == RoundState.PLAYING then
		Network.FireClient("RoundUpdate", player, PlayerService.GetAliveCount(), os.clock() - roundStartClock)
	end
end

function RoundService.Init()
	Network.Connect("ClientReady", onClientReady)
	Players.PlayerRemoving:Connect(function(player)
		lastSyncClockByPlayer[player] = nil
	end)
end

function RoundService.Run()
	while true do
		local success, errorMessage = pcall(runRound :: () -> any)
		if not success then
			warn(`[RoundService] Error: {errorMessage}`)
			HitService.SetEnabled(false)
			pcall(PlayerService.EndRound)
			pcall(ArenaService.Reset)
			task.wait(ERROR_RECOVERY_SECONDS)
		end
	end
end

return RoundService
