local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

local CANVAS_SIZE = Vector2.new(1040, 560)
local BACKGROUND_COLOR = Color3.fromRGB(20, 22, 30)
local TITLE_COLOR = Color3.fromRGB(255, 215, 0)
local TITLE_HEIGHT = 70
local LIST_TOP_OFFSET = 80
local LIST_LEFT_PADDING = 40
local ROW_HEIGHT = 46

-- Gold, silver and bronze for the first three places.
local RANK_COLORS: { Color3 } = {
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(200, 200, 210),
	Color3.fromRGB(205, 127, 50),
}

local rowLabels: { TextLabel } = {}
local userNameCache: { [number]: string } = {}
local isRefreshing = false

local function getUserName(userId: number): string
	local cachedName = userNameCache[userId]
	if cachedName then
		return cachedName
	end

	local success, userName = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if success then
		userNameCache[userId] = userName
		return userName
	end
	return "Unknown"
end

local function buildGui(board: BasePart)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.CanvasSize = CANVAS_SIZE
	surfaceGui.LightInfluence = 0

	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = BACKGROUND_COLOR
	background.BorderSizePixel = 0
	background.Parent = surfaceGui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 52
	titleLabel.TextColor3 = TITLE_COLOR
	titleLabel.Text = "🏆 TOP WINS"
	titleLabel.Parent = background

	local listFrame = Instance.new("Frame")
	listFrame.Position = UDim2.new(0, 0, 0, LIST_TOP_OFFSET)
	listFrame.Size = UDim2.new(1, 0, 1, -LIST_TOP_OFFSET)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = background

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingLeft = UDim.new(0, LIST_LEFT_PADDING)
	listPadding.Parent = listFrame

	for rank = 1, Config.Leaderboard.Size do
		local rowLabel = Instance.new("TextLabel")
		rowLabel.LayoutOrder = rank
		rowLabel.Size = UDim2.new(1, -LIST_LEFT_PADDING, 0, ROW_HEIGHT)
		rowLabel.BackgroundTransparency = 1
		rowLabel.Font = Enum.Font.GothamBold
		rowLabel.TextSize = 32
		rowLabel.TextXAlignment = Enum.TextXAlignment.Left
		rowLabel.TextColor3 = RANK_COLORS[rank] or Color3.new(1, 1, 1)
		rowLabel.Text = ""
		rowLabel.Parent = listFrame
		rowLabels[rank] = rowLabel
	end

	surfaceGui.Parent = board
end

local function renderRows(topWins: { DataService.WinsEntry })
	for rank, rowLabel in rowLabels do
		local entry = topWins[rank]
		if entry then
			rowLabel.Text = string.format("%d.  %s  —  %d Wins", rank, getUserName(entry.UserId), entry.Wins)
		elseif rank == 1 then
			rowLabel.Text = "No wins yet"
		else
			rowLabel.Text = ""
		end
	end
end

function LeaderboardService.Refresh()
	if isRefreshing then
		return
	end
	isRefreshing = true

	local success, errorMessage = pcall(function()
		local topWins = DataService.GetTopWins(Config.Leaderboard.Size)
		if topWins then
			renderRows(topWins)
		end
	end)

	isRefreshing = false
	if not success then
		warn(`[LeaderboardService] Refresh failed: {errorMessage}`)
	end
end

function LeaderboardService.Init(board: BasePart?)
	if not board then
		warn("[LeaderboardService] No board found, the leaderboard will be skipped.")
		return
	end

	buildGui(board)

	task.spawn(function()
		while true do
			LeaderboardService.Refresh()
			task.wait(Config.Leaderboard.RefreshSeconds)
		end
	end)
end

return LeaderboardService
