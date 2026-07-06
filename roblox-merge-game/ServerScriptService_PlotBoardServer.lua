-- Script: ServerScriptService.PlotBoardServer
--
-- Replaces the ScreenGui upgrade/rebirth menu with a physical board that
-- gets built next to each player's plot. Everything a player used to click
-- on a 2D screen (Spawn Speed, Plot Capacity, Starting Tier, Rebirth) is now
-- a real part in the world with a ClickDetector, and its price/level is
-- shown on a SurfaceGui anyone walking past can also read -- so a plot with
-- maxed-out upgrades and 2 rebirths is visible bragging rights, the same
-- way the leaderboards are.
--
-- ClickDetector.MouseClick fires on the SERVER with the clicking player
-- already identified, so purchases here don't need a RemoteEvent round
-- trip or server-side re-validation of "who clicked" -- Roblox guarantees
-- that part.
--
-- This script owns: leaderstats (Cash/Gems), per-player upgrade levels,
-- rebirth count, and a small placeholder income tick so the board is
-- testable on its own. The real per-second income should eventually come
-- from the merge/tier system instead of the placeholder tick below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local plotSpawns = Workspace:WaitForChild("PlotSpawns")

-- [Player] = plot marker Part assigned to them
local assignedPlot = {}
-- [Player] = { Levels = { [upgradeId] = level }, RebirthCount = n }
local playerData = {}
-- [Player] = { board = Model, altarMessage = string?, altarMessageUntil = number? }
local playerBoards = {}

local FREE_PLOTS = plotSpawns:GetChildren()

-- ===================== Helpers =====================

local function getLevel(player, upgradeId)
	return playerData[player].Levels[upgradeId] or 0
end

local function assignPlot(player)
	local marker = table.remove(FREE_PLOTS)
	if not marker then
		warn("No free plots left in PlotSpawns for " .. player.Name)
		return nil
	end
	assignedPlot[player] = marker
	return marker
end

local function releasePlot(player)
	local marker = assignedPlot[player]
	if marker then
		table.insert(FREE_PLOTS, marker)
		assignedPlot[player] = nil
	end
end

-- Builds one physical button: a pillar with a SurfaceGui title/body and a
-- ClickDetector. Returns the labels so the caller can update them later.
local function createButtonPart(parent, name, cframe, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(4, 6, 2)
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Parent = parent

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.LayoutOrder = 1
	title.Parent = gui

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, 0, 0, 90)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextScaled = true
	body.TextWrapped = true
	body.TextColor3 = Color3.new(1, 1, 1)
	body.LayoutOrder = 2
	body.Parent = gui

	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 14
	detector.Parent = part

	return part, title, body, detector
end

-- Builds the full board model for one player's plot and wires up clicks.
local function buildBoard(player, marker)
	local board = Instance.new("Model")
	board.Name = player.Name .. "_Board"
	board.Parent = Workspace

	local base = marker.CFrame * CFrame.new(0, 0, -14)

	-- Stats sign: shows live Cash/Gems, visible to anyone walking by.
	local statsPart, statsTitle, statsBody = createButtonPart(
		board, "StatsSign", base * CFrame.new(0, 6, 0) * CFrame.Angles(0, math.pi, 0),
		Color3.fromRGB(40, 40, 40)
	)
	statsPart.Size = Vector3.new(8, 5, 1)
	statsTitle.Text = player.Name
	statsBody.Text = "Cash: 0\nGems: 0"

	-- Upgrade pillars, laid out left to right.
	local upgradeParts = {}
	local spacing = 5
	local startX = -((#GameConfig.UpgradeOrder - 1) * spacing) / 2
	for i, upgradeId in ipairs(GameConfig.UpgradeOrder) do
		local def = GameConfig.Upgrades[upgradeId]
		local x = startX + (i - 1) * spacing
		local part, title, body, detector = createButtonPart(
			board, upgradeId,
			base * CFrame.new(x, 3, 6) * CFrame.Angles(0, math.pi, 0),
			Color3.fromRGB(60, 140, 220)
		)
		upgradeParts[upgradeId] = { part = part, title = title, body = body }

		detector.MouseClick:Connect(function(clickingPlayer)
			if assignedPlot[clickingPlayer] ~= marker then
				return
			end
			local data = playerData[clickingPlayer]
			local level = getLevel(clickingPlayer, upgradeId)
			local cost = GameConfig.GetUpgradeCost(upgradeId, level)
			if not cost then
				return -- maxed out
			end
			local leaderstats = clickingPlayer:FindFirstChild("leaderstats")
			local cashStat = leaderstats and leaderstats:FindFirstChild("Cash")
			if not cashStat or cashStat.Value < cost then
				return
			end
			cashStat.Value -= cost
			data.Levels[upgradeId] = level + 1
		end)
	end

	-- Rebirth altar: bigger, gold, sits behind the upgrade pillars.
	local altarPart, altarTitle, altarBody, altarDetector = createButtonPart(
		board, "RebirthAltar", base * CFrame.new(0, 4, 12) * CFrame.Angles(0, math.pi, 0),
		Color3.fromRGB(230, 190, 60)
	)
	altarPart.Size = Vector3.new(6, 8, 3)
	altarTitle.Text = "Rebirth"

	altarDetector.MouseClick:Connect(function(clickingPlayer)
		if assignedPlot[clickingPlayer] ~= marker then
			return
		end
		local data = playerData[clickingPlayer]
		local leaderstats = clickingPlayer:FindFirstChild("leaderstats")
		local cashStat = leaderstats and leaderstats:FindFirstChild("Cash")
		local gemsStat = leaderstats and leaderstats:FindFirstChild("Gems")
		if not cashStat or not gemsStat then
			return
		end

		if data.RebirthCount >= GameConfig.MaxRebirths then
			playerBoards[clickingPlayer].altarMessage = "All rebirths complete!"
			playerBoards[clickingPlayer].altarMessageUntil = os.clock() + 3
			return
		end

		local requirement = GameConfig.GetRebirthRequirement(data.RebirthCount)
		if cashStat.Value < requirement then
			playerBoards[clickingPlayer].altarMessage = "Need "
				.. GameConfig.FormatNumber(requirement - cashStat.Value) .. " more cash"
			playerBoards[clickingPlayer].altarMessageUntil = os.clock() + 3
			return
		end

		local gemsEarned = GameConfig.GetGemsForRebirth(cashStat.Value)
		gemsStat.Value += gemsEarned
		cashStat.Value = 0
		data.RebirthCount += 1
		table.clear(data.Levels)

		playerBoards[clickingPlayer].altarMessage = "Rebirthed! +"
			.. GameConfig.FormatNumber(gemsEarned) .. " gems"
		playerBoards[clickingPlayer].altarMessageUntil = os.clock() + 3
	end)

	return {
		model = board,
		statsBody = statsBody,
		altarTitle = altarTitle,
		altarBody = altarBody,
		upgradeParts = upgradeParts,
	}
end

-- ===================== Live display refresh =====================

local function refreshBoard(player)
	local record = playerBoards[player]
	local data = playerData[player]
	if not record or not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cashStat = leaderstats and leaderstats:FindFirstChild("Cash")
	local gemsStat = leaderstats and leaderstats:FindFirstChild("Gems")
	local cash = cashStat and cashStat.Value or 0
	local gems = gemsStat and gemsStat.Value or 0

	record.statsBody.Text = string.format(
		"Cash: %s\nGems: %s",
		GameConfig.FormatNumber(cash), GameConfig.FormatNumber(gems)
	)

	for upgradeId, ui in pairs(record.upgradeParts) do
		local def = GameConfig.Upgrades[upgradeId]
		local level = getLevel(player, upgradeId)
		local cost = GameConfig.GetUpgradeCost(upgradeId, level)
		ui.title.Text = def.Name
		if cost then
			ui.body.Text = string.format("Lv %d\n%s cash", level, GameConfig.FormatNumber(cost))
		else
			ui.body.Text = string.format("Lv %d\nMAXED", level)
		end
	end

	if record.altarMessage and os.clock() < (record.altarMessageUntil or 0) then
		record.altarBody.Text = record.altarMessage
	elseif data.RebirthCount >= GameConfig.MaxRebirths then
		record.altarBody.Text = "All rebirths complete!"
	else
		local requirement = GameConfig.GetRebirthRequirement(data.RebirthCount)
		record.altarBody.Text = string.format(
			"%s / %s cash\nRebirth %d of %d",
			GameConfig.FormatNumber(cash), GameConfig.FormatNumber(requirement),
			data.RebirthCount + 1, GameConfig.MaxRebirths
		)
	end
end

-- ===================== Player lifecycle =====================

local function onPlayerAdded(player)
	local marker = assignPlot(player)
	if not marker then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats

	local gems = Instance.new("NumberValue")
	gems.Name = "Gems"
	gems.Value = 0
	gems.Parent = leaderstats

	playerData[player] = { Levels = {}, RebirthCount = 0 }
	playerBoards[player] = buildBoard(player, marker)

	-- Placeholder income so the board is testable without the merge loop
	-- wired up yet. Swap this for the real per-second tier income later.
	task.spawn(function()
		while player.Parent do
			task.wait(1)
			if cash.Parent then
				cash.Value += 10 * (1 + getLevel(player, "StartingTier") * 0.1)
			end
		end
	end)
end

local function onPlayerRemoving(player)
	local record = playerBoards[player]
	if record then
		record.model:Destroy()
	end
	playerBoards[player] = nil
	playerData[player] = nil
	releasePlot(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ===================== Refresh loop =====================

task.spawn(function()
	while true do
		task.wait(0.5)
		for player in pairs(playerBoards) do
			refreshBoard(player)
		end
	end
end)
