local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Enums = require(ReplicatedStorage.Shared.Enums)

local TileState = Enums.TileState
local TILE_STATE_ATTRIBUTE = Enums.Attribute.TileState

local WARNING_TWEEN_SECONDS = 0.3
local DANGER_TWEEN_SECONDS = 0.15

export type Tile = {
	Part: Part,
	State: Enums.TileState,
	-- Incremented whenever the tile is triggered or reset, so that delayed
	-- steps from an older lifecycle can detect they are outdated.
	LifecycleToken: number,
	ActiveTween: Tween?,
	HomeCFrame: CFrame,
}

local TileService = {}

local tiles: { Tile } = {}
local tileByPart: { [Instance]: Tile } = {}
local random = Random.new()

local function setTileState(tile: Tile, newState: Enums.TileState)
	tile.State = newState
	tile.Part:SetAttribute(TILE_STATE_ATTRIBUTE, newState)
end

local function playTween(tile: Tile, durationSeconds: number, goal: { [string]: any })
	if tile.ActiveTween then
		tile.ActiveTween:Cancel()
	end

	local tween = TweenService:Create(
		tile.Part,
		TweenInfo.new(durationSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		goal
	)
	tile.ActiveTween = tween
	tween:Play()
end

function TileService.Clear()
	tiles = {}
	tileByPart = {}
end

function TileService.Register(part: Part)
	local tile: Tile = {
		Part = part,
		State = TileState.SAFE,
		LifecycleToken = 0,
		ActiveTween = nil,
		HomeCFrame = part.CFrame,
	}

	table.insert(tiles, tile)
	tileByPart[part] = tile
	part:SetAttribute(TILE_STATE_ATTRIBUTE, TileState.SAFE)
end

function TileService.GetState(part: Instance): Enums.TileState?
	local tile = tileByPart[part]
	return if tile then tile.State else nil
end

function TileService.PickRandomSafe(count: number): { Tile }
	local safeTiles: { Tile } = {}
	for _, tile in tiles do
		if tile.State == TileState.SAFE then
			table.insert(safeTiles, tile)
		end
	end

	local pickedTiles: { Tile } = {}
	for _ = 1, math.min(count, #safeTiles) do
		local index = random:NextInteger(1, #safeTiles)
		table.insert(pickedTiles, table.remove(safeTiles, index) :: Tile)
	end
	return pickedTiles
end

-- SAFE -> WARNING -> DANGER -> HOLE
function TileService.Trigger(tile: Tile)
	if tile.State ~= TileState.SAFE then
		return
	end

	tile.LifecycleToken += 1
	local expectedToken = tile.LifecycleToken
	local settings = Config.Tiles

	setTileState(tile, TileState.WARNING)
	playTween(tile, WARNING_TWEEN_SECONDS, { Color = settings.Colors.WARNING })

	task.spawn(function()
		task.wait(settings.WarningTime)
		if tile.LifecycleToken ~= expectedToken then
			return
		end

		setTileState(tile, TileState.DANGER)
		tile.Part.Material = Enum.Material.Neon
		playTween(tile, DANGER_TWEEN_SECONDS, { Color = settings.Colors.DANGER })

		task.wait(settings.DangerTime)
		if tile.LifecycleToken ~= expectedToken then
			return
		end

		setTileState(tile, TileState.HOLE)
		tile.Part.CanCollide = false
		playTween(tile, settings.HoleFadeTime, {
			Transparency = 1,
			Position = tile.Part.Position - Vector3.yAxis * settings.HoleSinkDistance,
		})
	end)
end

function TileService.ResetAll()
	for _, tile in tiles do
		tile.LifecycleToken += 1 -- invalidates pending lifecycle steps

		if tile.ActiveTween then
			tile.ActiveTween:Cancel()
			tile.ActiveTween = nil
		end

		local part = tile.Part
		part.CFrame = tile.HomeCFrame
		part.Transparency = 0
		part.CanCollide = true
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Config.Tiles.Colors.SAFE
		setTileState(tile, TileState.SAFE)
	end
end

return TileService
