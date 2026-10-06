local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Shared") -- wait until the shared modules have replicated
local Config = require(ReplicatedStorage.Shared.Config)

local Colors = Config.UI.Colors

export type GameUI = {
	Gui: ScreenGui,
	FlashFrame: Frame,
	TitleLabel: TextLabel,
	SubtitleLabel: TextLabel,
	PlayersLeftLabel: TextLabel,
	RoundTimeLabel: TextLabel,
	BannerLabel: TextLabel,
	BannerSubtitleLabel: TextLabel,
	BannerScale: UIScale,
}

type LabelOptions = {
	Name: string,
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
	MaxTextSize: number,
}

local UIBuilder = {}

local function createLabel(parent: Instance, options: LabelOptions): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = options.Name
	label.AnchorPoint = options.AnchorPoint
	label.Position = options.Position
	label.Size = options.Size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Colors.White
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = parent

	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = options.MaxTextSize
	textSizeConstraint.Parent = label

	return label
end

function UIBuilder.Build(): GameUI
	local localPlayer = Players.LocalPlayer

	local gui = Instance.new("ScreenGui")
	gui.Name = "GameUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local flashFrame = Instance.new("Frame")
	flashFrame.Name = "Flash"
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = Colors.Red
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.ZIndex = 0
	flashFrame.Parent = gui

	local topCenter = Vector2.new(0.5, 0)
	local bottomCenter = Vector2.new(0.5, 1)
	local center = Vector2.new(0.5, 0.5)

	local titleLabel = createLabel(gui, {
		Name = "Title",
		AnchorPoint = topCenter,
		Position = UDim2.fromScale(0.5, 0.03),
		Size = UDim2.fromScale(0.5, 0.07),
		MaxTextSize = 48,
	})
	local subtitleLabel = createLabel(gui, {
		Name = "Subtitle",
		AnchorPoint = topCenter,
		Position = UDim2.fromScale(0.5, 0.10),
		Size = UDim2.fromScale(0.4, 0.06),
		MaxTextSize = 36,
	})
	local playersLeftLabel = createLabel(gui, {
		Name = "PlayersLeft",
		AnchorPoint = bottomCenter,
		Position = UDim2.fromScale(0.5, 0.92),
		Size = UDim2.fromScale(0.35, 0.05),
		MaxTextSize = 30,
	})
	local roundTimeLabel = createLabel(gui, {
		Name = "RoundTime",
		AnchorPoint = bottomCenter,
		Position = UDim2.fromScale(0.5, 0.97),
		Size = UDim2.fromScale(0.3, 0.04),
		MaxTextSize = 24,
	})
	local bannerLabel = createLabel(gui, {
		Name = "Banner",
		AnchorPoint = center,
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromScale(0.7, 0.14),
		MaxTextSize = 90,
	})
	local bannerSubtitleLabel = createLabel(gui, {
		Name = "BannerSubtitle",
		AnchorPoint = center,
		Position = UDim2.fromScale(0.5, 0.50),
		Size = UDim2.fromScale(0.5, 0.08),
		MaxTextSize = 48,
	})

	playersLeftLabel.Visible = false
	roundTimeLabel.Visible = false
	bannerLabel.Visible = false
	bannerSubtitleLabel.Visible = false

	local bannerScale = Instance.new("UIScale")
	bannerScale.Parent = bannerLabel

	gui.Parent = localPlayer:WaitForChild("PlayerGui")

	return {
		Gui = gui,
		FlashFrame = flashFrame,
		TitleLabel = titleLabel,
		SubtitleLabel = subtitleLabel,
		PlayersLeftLabel = playersLeftLabel,
		RoundTimeLabel = roundTimeLabel,
		BannerLabel = bannerLabel,
		BannerSubtitleLabel = bannerSubtitleLabel,
		BannerScale = bannerScale,
	}
end

return UIBuilder
