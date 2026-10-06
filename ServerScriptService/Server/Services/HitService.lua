local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Enums = require(ReplicatedStorage.Shared.Enums)

local ArenaService = require(script.Parent.ArenaService)
local PlayerService = require(script.Parent.PlayerService)
local TileService = require(script.Parent.TileService)

local HitService = {}

local isEnabled = false
local killPlaneY = Config.Arena.Origin.Y - Config.Arena.KillDepth

local floorRaycastParams = RaycastParams.new()
floorRaycastParams.FilterType = Enum.RaycastFilterType.Include

-- Distance from the root part to the player's feet.
local function getFeetOffset(humanoid: Humanoid, rootPart: BasePart): number
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return Config.HitDetection.R6FeetDistance
	end
	return humanoid.HipHeight + rootPart.Size.Y / 2
end

local function checkPlayer(player: Player)
	local _, humanoid, rootPart = PlayerService.GetCharacterParts(player)
	if not (humanoid and rootPart) then
		return
	end

	if rootPart.Position.Y < killPlaneY then
		PlayerService.Eliminate(player)
		return
	end

	local rayLength = getFeetOffset(humanoid, rootPart) + Config.HitDetection.GroundTolerance
	local floorHit = workspace:Raycast(rootPart.Position, Vector3.new(0, -rayLength, 0), floorRaycastParams)
	if floorHit and TileService.GetState(floorHit.Instance) == Enums.TileState.DANGER then
		PlayerService.Eliminate(player)
	end
end

local function onHeartbeat()
	if not isEnabled then
		return
	end

	for _, player in PlayerService.GetAlivePlayers() do
		checkPlayer(player)
	end
end

function HitService.Init()
	floorRaycastParams.FilterDescendantsInstances = { ArenaService.GetTilesFolder() }
	RunService.Heartbeat:Connect(onHeartbeat)
end

function HitService.SetEnabled(enabled: boolean)
	isEnabled = enabled
end

return HitService
