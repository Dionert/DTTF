local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Enums = require(ReplicatedStorage.Shared.Enums)
local Network = require(ReplicatedStorage.Shared.Network)

local Effects = require(script.Parent.Parent.Util.Effects)
local ArenaService = require(script.Parent.ArenaService)

local IN_ROUND_ATTRIBUTE = Enums.Attribute.InRound

local PlayerService = {}

local roundParticipants: { [Player]: boolean } = {}
local alivePlayers: { [Player]: boolean } = {}
local aliveCount = 0
local deathConnections: { [Player]: RBXScriptConnection } = {}

local function getCharacterParts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return character, humanoid, rootPart
end

local function teleportPlayer(player: Player, position: Vector3)
	local character, _, rootPart = getCharacterParts(player)
	if not character then
		return
	end

	character:PivotTo(CFrame.new(position + Vector3.yAxis * Config.Players.TeleportHeight))
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
	end
end

local function removeFromAlive(player: Player)
	if alivePlayers[player] then
		alivePlayers[player] = nil
		aliveCount -= 1
	end

	local deathConnection = deathConnections[player]
	if deathConnection then
		deathConnection:Disconnect()
		deathConnections[player] = nil
	end
end

function PlayerService.Init()
	Players.PlayerRemoving:Connect(function(player)
		removeFromAlive(player)
		roundParticipants[player] = nil
	end)
end

function PlayerService.GetCharacterParts(player: Player): (Model?, Humanoid?, BasePart?)
	return getCharacterParts(player)
end

-- Players that have a living character and can join the next round.
function PlayerService.GetEligiblePlayers(): { Player }
	local eligiblePlayers: { Player } = {}
	for _, player in Players:GetPlayers() do
		local _, humanoid, rootPart = getCharacterParts(player)
		if humanoid and rootPart and humanoid.Health > 0 then
			table.insert(eligiblePlayers, player)
		end
	end
	return eligiblePlayers
end

function PlayerService.GetAlivePlayers(): { Player }
	local list: { Player } = {}
	for player in alivePlayers do
		table.insert(list, player)
	end
	return list
end

function PlayerService.GetAliveCount(): number
	return aliveCount
end

-- Places the players on their spawn positions and freezes them until `Unfreeze`.
function PlayerService.StartRound(players: { Player }, spawnPositions: { Vector3 })
	for index, player in players do
		roundParticipants[player] = true
		alivePlayers[player] = true
		aliveCount += 1
		player:SetAttribute(IN_ROUND_ATTRIBUTE, true)

		teleportPlayer(player, spawnPositions[index])

		local _, humanoid, rootPart = getCharacterParts(player)
		if rootPart then
			rootPart.Anchored = true
		end
		if humanoid then
			deathConnections[player] = humanoid.Died:Connect(function()
				PlayerService.Eliminate(player)
			end)
		end
	end
end

function PlayerService.Unfreeze()
	for player in alivePlayers do
		local _, _, rootPart = getCharacterParts(player)
		if rootPart then
			rootPart.Anchored = false
		end
	end
end

function PlayerService.Eliminate(player: Player)
	if not alivePlayers[player] then
		return
	end

	removeFromAlive(player)
	player:SetAttribute(IN_ROUND_ATTRIBUTE, false)

	local _, humanoid, rootPart = getCharacterParts(player)

	if rootPart then
		Effects.Burst(rootPart.Position)
		rootPart.Anchored = false
	end

	if humanoid and humanoid.Health > 0 then
		teleportPlayer(player, ArenaService.GetSpectatorSpot())
	end

	Network.FireClient("PlayerEliminated", player)
	Network.FireClient("PlaySound", player, Enums.Sound.Eliminated)
end

-- Clears the round state and respawns every participant in the lobby.
function PlayerService.EndRound()
	for _, deathConnection in deathConnections do
		deathConnection:Disconnect()
	end
	table.clear(deathConnections)

	local playersToRespawn = roundParticipants
	roundParticipants = {}
	alivePlayers = {}
	aliveCount = 0

	for player in playersToRespawn do
		if player.Parent then
			player:SetAttribute(IN_ROUND_ATTRIBUTE, false)
			task.spawn(function()
				-- Can fail when the player leaves during the respawn; that is fine.
				pcall(player.LoadCharacterAsync, player)
			end)
		end
	end
end

return PlayerService
