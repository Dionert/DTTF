local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Retry = require(script.Parent.Parent.Util.Retry)

export type WinsEntry = {
	UserId: number,
	Wins: number,
}

local DataService = {}

local winsStore = DataStoreService:GetDataStore(Config.Data.WinsStoreName)
local rankingStore = DataStoreService:GetOrderedDataStore(Config.Data.TopStoreName)

local winsByPlayer: { [Player]: number } = {}
local hasLoadedData: { [Player]: boolean } = {}
local hasUnsavedChanges: { [Player]: boolean } = {}
local pendingSaveCount = 0

local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local winsValue = Instance.new("IntValue")
	winsValue.Name = "Wins"
	winsValue.Value = 0
	winsValue.Parent = leaderstats

	leaderstats.Parent = player
end

local function syncLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local winsValue = leaderstats and leaderstats:FindFirstChild("Wins") :: IntValue?
	if winsValue then
		winsValue.Value = winsByPlayer[player] or 0
	end
end

-- Stores `value` only when it is higher than what is already saved, so a
-- stale session can never lower a player's wins.
local function writeHighestValue(store: GlobalDataStore, key: string, value: number): boolean
	local success = Retry.Run(function()
		return store:UpdateAsync(key, function(storedValue: number?)
			return math.max(storedValue or 0, value)
		end)
	end, Config.Data.Retries, "DataService")

	return success
end

function DataService.Save(player: Player)
	local winCount = winsByPlayer[player]
	if not hasLoadedData[player] or not hasUnsavedChanges[player] or winCount == nil then
		return
	end

	hasUnsavedChanges[player] = nil
	local key = tostring(player.UserId)

	pendingSaveCount += 1
	local didSaveWins = writeHighestValue(winsStore, key, winCount)
	local didSaveRanking = writeHighestValue(rankingStore, key, winCount)
	pendingSaveCount -= 1

	-- Keep the flag so the next save attempt retries.
	if not (didSaveWins and didSaveRanking) and winsByPlayer[player] ~= nil then
		hasUnsavedChanges[player] = true
	end
end

local function onPlayerAdded(player: Player)
	createLeaderstats(player)
	winsByPlayer[player] = 0

	local didLoad, storedWins = Retry.Run(function()
		return winsStore:GetAsync(tostring(player.UserId)) :: number?
	end, Config.Data.Retries, "DataService")

	-- The player may have left while the data was loading.
	local sessionWins = winsByPlayer[player]
	if not player.Parent or sessionWins == nil then
		return
	end

	if didLoad then
		-- Wins earned while loading are added on top of the stored value.
		winsByPlayer[player] = (storedWins or 0) + sessionWins
		hasLoadedData[player] = true
		syncLeaderstats(player)

		if hasUnsavedChanges[player] then
			task.spawn(DataService.Save, player)
		end
	else
		warn(`[DataService] Could not load data for {player.Name}. Wins will not be saved this session.`)
	end
end

local function onPlayerRemoving(player: Player)
	DataService.Save(player)
	winsByPlayer[player] = nil
	hasLoadedData[player] = nil
	hasUnsavedChanges[player] = nil
end

local function onShutdown()
	for _, player in Players:GetPlayers() do
		task.spawn(DataService.Save, player)
	end

	task.wait()
	local startClock = os.clock()
	while pendingSaveCount > 0 and os.clock() - startClock < Config.Data.ShutdownTimeout do
		task.wait(0.1)
	end
end

function DataService.AddWin(player: Player)
	local currentWins = winsByPlayer[player]
	if currentWins == nil then
		return
	end

	winsByPlayer[player] = currentWins + 1
	hasUnsavedChanges[player] = true
	syncLeaderstats(player)

	task.spawn(DataService.Save, player)
end

-- Returns the players with the most wins, or nil when the DataStore request fails.
function DataService.GetTopWins(count: number): { WinsEntry }?
	local success, entries = pcall(function()
		return rankingStore:GetSortedAsync(false, count):GetCurrentPage()
	end)
	if not success then
		return nil
	end

	local topWins: { WinsEntry } = {}
	for _, entry in entries :: { { key: string, value: number } } do
		local userId = tonumber(entry.key)
		if userId and entry.value > 0 then
			table.insert(topWins, { UserId = userId, Wins = entry.value })
		end
	end
	return topWins
end

function DataService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(onShutdown)
end

return DataService
