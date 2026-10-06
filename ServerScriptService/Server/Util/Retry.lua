local Retry = {}

local DEFAULT_ATTEMPTS = 3

-- Runs `callback` until it succeeds or the attempts run out.
-- Returns whether it succeeded and, if so, what the callback returned.
function Retry.Run<T>(callback: () -> T, maxAttempts: number?, label: string?): (boolean, T?)
	local attempts = maxAttempts or DEFAULT_ATTEMPTS
	local logLabel = label or "Retry"

	for attempt = 1, attempts do
		local success, result = pcall(callback)
		if success then
			return true, result
		end

		warn(string.format("[%s] Attempt %d/%d failed: %s", logLabel, attempt, attempts, tostring(result)))

		if attempt < attempts then
			task.wait(attempt) -- linear backoff
		end
	end

	return false, nil
end

return Retry
