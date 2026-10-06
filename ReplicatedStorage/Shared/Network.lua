local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type EventName =
	"StateChanged"
	| "RoundUpdate"
	| "PlayerEliminated"
	| "RoundWinner"
	| "RoundDraw"
	| "PlaySound"
	| "ClientReady"

local REMOTES_FOLDER_NAME = "Remotes"

local EVENT_NAMES: { EventName } = {
	"StateChanged",
	"RoundUpdate",
	"PlayerEliminated",
	"RoundWinner",
	"RoundDraw",
	"PlaySound",
	"ClientReady",
}

local isServer = RunService:IsServer()
local remoteEvents: { [string]: RemoteEvent } = {}

if isServer then
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = REMOTES_FOLDER_NAME

	for _, eventName in ipairs(EVENT_NAMES) do
		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = remotesFolder
		remoteEvents[eventName] = remoteEvent
	end

	remotesFolder.Parent = ReplicatedStorage
else
	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)

	for _, eventName in ipairs(EVENT_NAMES) do
		remoteEvents[eventName] = remotesFolder:WaitForChild(eventName) :: RemoteEvent
	end
end

local function getRemoteEvent(eventName: EventName): RemoteEvent
	local remoteEvent = remoteEvents[eventName]
	assert(remoteEvent, `[Network] Unknown event: {eventName}`)
	return remoteEvent
end

local Network = {}

function Network.FireClient(eventName: EventName, player: Player, ...: any)
	assert(isServer, "[Network] FireClient is only allowed on the server")
	getRemoteEvent(eventName):FireClient(player, ...)
end

function Network.FireAllClients(eventName: EventName, ...: any)
	assert(isServer, "[Network] FireAllClients is only allowed on the server")
	getRemoteEvent(eventName):FireAllClients(...)
end

function Network.FireServer(eventName: EventName, ...: any)
	assert(not isServer, "[Network] FireServer is only allowed on the client")
	getRemoteEvent(eventName):FireServer(...)
end

-- On the server the handler receives the sending player as its first argument.
function Network.Connect(eventName: EventName, handler: (...any) -> ()): RBXScriptConnection
	local remoteEvent = getRemoteEvent(eventName)
	if isServer then
		return remoteEvent.OnServerEvent:Connect(handler)
	end
	return remoteEvent.OnClientEvent:Connect(handler)
end

return Network
