local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

ReplicatedStorage:WaitForChild("Shared") -- wait until the shared modules have replicated
local Config = require(ReplicatedStorage.Shared.Config)
local Enums = require(ReplicatedStorage.Shared.Enums)
local Network = require(ReplicatedStorage.Shared.Network)

local UIBuilder = require(script.Parent.Parent.UI.UIBuilder)

local RoundState = Enums.RoundState
local Colors = Config.UI.Colors
local localPlayer = Players.LocalPlayer

local BANNER_POP_SECONDS = 0.25
local BANNER_START_SCALE = 0.6
local FLASH_START_TRANSPARENCY = 0.6
local FLASH_FADE_SECONDS = 0.6

local UIController = {}

type ViewModel = {
	State: string,
	Value: number?,
	AliveCount: number,
	ElapsedSeconds: number,
	IsEliminated: boolean,
}

local ui: UIBuilder.GameUI -- assigned in Init
local latestBannerId = 0

local viewModel: ViewModel = {
	State = RoundState.WAITING,
	Value = nil,
	AliveCount = 0,
	ElapsedSeconds = 0,
	IsEliminated = false,
}

local function isInRound(): boolean
	return localPlayer:GetAttribute(Enums.Attribute.InRound) == true
end

local function formatClock(totalSeconds: number): string
	local wholeSeconds = math.floor(totalSeconds)
	return string.format("%02d:%02d", wholeSeconds // 60, wholeSeconds % 60)
end

local function setHeader(title: string?, subtitle: string?)
	ui.TitleLabel.Text = title or ""
	ui.SubtitleLabel.Text = subtitle or ""
end

local function setRoundInfoVisible(isVisible: boolean)
	ui.PlayersLeftLabel.Visible = isVisible
	ui.RoundTimeLabel.Visible = isVisible
end

local function showBanner(text: string, subtitle: string?, color: Color3?, durationSeconds: number)
	latestBannerId += 1
	local bannerId = latestBannerId

	ui.BannerLabel.Text = text
	ui.BannerLabel.TextColor3 = color or Colors.White
	ui.BannerSubtitleLabel.Text = subtitle or ""
	ui.BannerLabel.Visible = true
	ui.BannerSubtitleLabel.Visible = subtitle ~= nil and subtitle ~= ""

	ui.BannerScale.Scale = BANNER_START_SCALE
	TweenService:Create(
		ui.BannerScale,
		TweenInfo.new(BANNER_POP_SECONDS, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()

	task.delay(durationSeconds, function()
		-- Ignore if a newer banner replaced this one.
		if bannerId == latestBannerId then
			ui.BannerLabel.Visible = false
			ui.BannerSubtitleLabel.Visible = false
		end
	end)
end

local function flashScreen()
	ui.FlashFrame.BackgroundTransparency = FLASH_START_TRANSPARENCY
	TweenService:Create(ui.FlashFrame, TweenInfo.new(FLASH_FADE_SECONDS), { BackgroundTransparency = 1 }):Play()
end

local function render()
	local state = viewModel.State
	setRoundInfoVisible(false)

	if state == RoundState.WAITING then
		setHeader("DON'T TOUCH THE FLOOR", "Waiting for more players...")
	elseif state == RoundState.INTERMISSION then
		setHeader("NEXT ROUND", "Starting in: " .. tostring(viewModel.Value))
	elseif state == RoundState.STARTING then
		if isInRound() then
			setHeader("ROUND STARTING", tostring(viewModel.Value))
		else
			setHeader("ROUND STARTING", "Round in progress...")
		end
	elseif state == RoundState.PLAYING then
		setRoundInfoVisible(true)
		ui.PlayersLeftLabel.Text = "PLAYERS LEFT: " .. tostring(viewModel.AliveCount)
		ui.RoundTimeLabel.Text = "ROUND TIME: " .. formatClock(viewModel.ElapsedSeconds)

		if isInRound() then
			setHeader("SURVIVE!", "")
		elseif viewModel.IsEliminated then
			setHeader("YOU ARE SPECTATING", "")
		else
			setHeader("ROUND IN PROGRESS", "You will join the next round")
		end
	elseif state == RoundState.WINNER then
		setHeader("ROUND OVER", "")
	else
		setHeader("", "")
	end
end

local function onStateChanged(state: string, value: number?)
	viewModel.State = state
	viewModel.Value = value

	if state == RoundState.WAITING or state == RoundState.INTERMISSION or state == RoundState.STARTING then
		viewModel.IsEliminated = false
	end

	render()

	if state == RoundState.PLAYING and isInRound() then
		showBanner("GO!", nil, Colors.Green, 1.5)
	end
end

local function onRoundUpdate(aliveCount: unknown, elapsedSeconds: unknown)
	viewModel.AliveCount = tonumber(aliveCount) or 0
	viewModel.ElapsedSeconds = tonumber(elapsedSeconds) or 0
	render()
end

local function onEliminated()
	viewModel.IsEliminated = true
	render()
	showBanner("YOU ARE ELIMINATED", nil, Colors.Red, 3)
	flashScreen()
end

local function onWinner(displayName: unknown, userId: unknown)
	setRoundInfoVisible(false)
	if userId == localPlayer.UserId then
		showBanner("🏆 YOU WIN!", "+1 WIN", Colors.Gold, 3)
	else
		showBanner("🏆 ROUND WINNER", tostring(displayName) .. "  •  +1 WIN", Colors.Gold, 3)
	end
end

local function onDraw()
	setRoundInfoVisible(false)
	showBanner("NO WINNER", "Everyone fell!", Colors.White, 3)
end

function UIController.Init()
	ui = UIBuilder.Build()
	render()

	Network.Connect("StateChanged", onStateChanged)
	Network.Connect("RoundUpdate", onRoundUpdate)
	Network.Connect("PlayerEliminated", onEliminated)
	Network.Connect("RoundWinner", onWinner)
	Network.Connect("RoundDraw", onDraw)

	localPlayer:GetAttributeChangedSignal(Enums.Attribute.InRound):Connect(render)
end

return UIController
