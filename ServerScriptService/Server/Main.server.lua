--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script.Parent.Services

-- Requiring Network creates the RemoteEvents before any service needs them.
require(ReplicatedStorage.Shared.Network)

local LobbyService = require(Services.LobbyService)
local ArenaService = require(Services.ArenaService)

LobbyService.Build()
ArenaService.Build()

local DataService = require(Services.DataService)
local PlayerService = require(Services.PlayerService)
local HitService = require(Services.HitService)
local LeaderboardService = require(Services.LeaderboardService)
local RoundService = require(Services.RoundService)

DataService.Init()
PlayerService.Init()
HitService.Init()
LeaderboardService.Init(LobbyService.GetLeaderboardBoard())
RoundService.Init()

RoundService.Run()
