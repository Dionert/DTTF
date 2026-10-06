local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Shared") -- wait until the shared modules have replicated
local Network = require(ReplicatedStorage.Shared.Network)

local Controllers = script.Parent.Controllers
local SoundController = require(Controllers.SoundController)
local UIController = require(Controllers.UIController)

SoundController.Init()
UIController.Init()

-- Tell the server the client is ready, so it can send the current round state.
Network.FireServer("ClientReady")
