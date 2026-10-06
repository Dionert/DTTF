local Debris = game:GetService("Debris")

local Effects = {}

local DEFAULT_BURST_COLOR = Color3.fromRGB(255, 60, 60)
local PARTICLE_COUNT = 40
local CLEANUP_DELAY_SECONDS = 2

function Effects.Burst(position: Vector3, color: Color3?)
	local anchorPart = Instance.new("Part")
	anchorPart.Anchored = true
	anchorPart.CanCollide = false
	anchorPart.CanQuery = false
	anchorPart.CanTouch = false
	anchorPart.Transparency = 1
	anchorPart.Size = Vector3.one
	anchorPart.Position = position
	anchorPart.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color or DEFAULT_BURST_COLOR)
	emitter.Speed = NumberRange.new(20, 35)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Size = NumberSequence.new(1.2, 0)
	emitter.Rate = 0
	emitter.Parent = anchorPart
	emitter:Emit(PARTICLE_COUNT)

	Debris:AddItem(anchorPart, CLEANUP_DELAY_SECONDS)
end

return Effects
