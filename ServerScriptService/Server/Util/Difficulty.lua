local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Difficulty = {}

local random = Random.new()

-- Returns how many seconds to wait until the next pick and how many tiles to pick.
function Difficulty.Get(elapsedSeconds: number): (number, number)
	local settings = Config.Difficulty

	local rampProgress = math.clamp(elapsedSeconds / settings.RampTime, 0, 1)
	local pickInterval = math.lerp(settings.StartInterval, settings.EndInterval, rampProgress)
	local tileCount = math.round(math.lerp(settings.MinTilesPerPick, settings.MaxTilesPerPick, rampProgress))

	if elapsedSeconds > settings.OvertimeAfter then
		pickInterval = settings.OvertimeInterval
		tileCount += settings.OvertimeExtraTiles
	end

	pickInterval *= random:NextNumber(settings.IntervalJitter.Min, settings.IntervalJitter.Max)

	return pickInterval, tileCount
end

return Difficulty
