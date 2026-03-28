-- GameController.client.lua
-- Main client controller: handles local player data, UI updates, server requests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local RequestAction = RemoteEvents:WaitForChild("RequestAction", 10)

-- ================================================================
-- LOCAL STATE
-- ================================================================

local GameController = {}
local playerData = nil

-- ================================================================
-- HELPER: Send action to server
-- ================================================================

function GameController.SendAction(action, payload)
	if not RequestAction then
		warn("[Client] RequestAction RemoteFunction not found")
		return { success = false, error = "Not connected" }
	end
	local result = RequestAction:InvokeServer(action, payload)
	return result
end

-- ================================================================
-- DATA SYNC
-- ================================================================

RemoteEvents:WaitForChild("PlayerDataLoaded").OnClientEvent:Connect(function(data)
	playerData = data
	print("[Client] Player data loaded:", LocalPlayer.Name)
	GameController.OnDataLoaded(data)
end)

RemoteEvents:WaitForChild("SyncCurrency").OnClientEvent:Connect(function(currencies)
	if playerData then
		if currencies.yen then playerData.yen = currencies.yen end
		GameController.UpdateCurrencyUI()
	end
end)

-- ================================================================
-- UI UPDATES
-- ================================================================

function GameController.OnDataLoaded(data)
	GameController.UpdateCurrencyUI()
	GameController.UpdateWorldUI()
	GameController.UpdateFighterUI()
	GameController.UpdateClassUI()
end

function GameController.UpdateCurrencyUI()
	if not playerData then return end
	-- Update Yen display
	local gui = LocalPlayer.PlayerGui
	local mainHud = gui:FindFirstChild("MainHUD")
	if mainHud then
		local yenLabel = mainHud:FindFirstChild("YenLabel", true)
		if yenLabel then
			yenLabel.Text = "💰 " .. GameController.FormatNumber(playerData.yen)
		end
		local classLabel = mainHud:FindFirstChild("ClassLabel", true)
		if classLabel then
			classLabel.Text = "Class: " .. tostring(playerData.classIndex or 1)
		end
		local rankLabel = mainHud:FindFirstChild("RankLabel", true)
		if rankLabel then
			rankLabel.Text = "Rank " .. tostring(playerData.rank or 1)
		end
	end
end

function GameController.UpdateWorldUI()
	-- Update world indicator and next world unlock button cost
end

function GameController.UpdateFighterUI()
	-- Refresh fighter inventory display
end

function GameController.UpdateClassUI()
	-- Refresh class and stat UI
end

-- ================================================================
-- NUMBER FORMATTING (1000 → 1K, 1000000 → 1M, etc.)
-- ================================================================

function GameController.FormatNumber(n)
	n = math.floor(n or 0)
	if n >= 1e24 then
		return string.format("%.2fSp", n / 1e24)
	elseif n >= 1e21 then
		return string.format("%.2fSx", n / 1e21)
	elseif n >= 1e18 then
		return string.format("%.2fQt", n / 1e18)
	elseif n >= 1e15 then
		return string.format("%.2fQd", n / 1e15)
	elseif n >= 1e12 then
		return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.2fK", n / 1e3)
	else
		return tostring(n)
	end
end

-- ================================================================
-- EVENT HANDLERS (from server → client)
-- ================================================================

RemoteEvents:WaitForChild("EnemyKilled").OnClientEvent:Connect(function(info)
	-- Show floating Yen text
	if info.position and info.yenEarned then
		GameController.ShowFloatingText(
			"+" .. GameController.FormatNumber(info.yenEarned),
			info.position,
			Color3.fromRGB(255, 215, 0)
		)
	end
	if info.isBoss then
		-- Play boss kill VFX / sound
	end
end)

RemoteEvents:WaitForChild("UltimateActivated").OnClientEvent:Connect(function(info)
	-- Play ultimate VFX
	if info.userId == LocalPlayer.UserId then
		GameController.ShowFloatingText(
			info.ultimateName .. "!",
			LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and
			LocalPlayer.Character.PrimaryPart.Position or Vector3.new(0,10,0),
			Color3.fromRGB(255, 100, 255)
		)
	end
end)

RemoteEvents:WaitForChild("QuestCompleted").OnClientEvent:Connect(function(info)
	-- Show quest completion notification
	GameController.ShowNotification(
		"Quest Complete!",
		"+" .. GameController.FormatNumber(info.yenReward) .. " Yen" ..
		(info.isLastQuest and "\nWorld questline complete!" or ""),
		Color3.fromRGB(0, 200, 100)
	)
end)

RemoteEvents:WaitForChild("WorldBadgeEarned").OnClientEvent:Connect(function(info)
	GameController.ShowNotification(
		"World Badge Earned!",
		"Permanent +10% Yen income unlocked for " .. info.worldId,
		Color3.fromRGB(255, 215, 0)
	)
end)

RemoteEvents:WaitForChild("RaidAnnounced").OnClientEvent:Connect(function(info)
	GameController.ShowNotification(
		(info.isMassive and "MASSIVE " or "") .. "RAID INCOMING!",
		"Raid in " .. (info.worldName or "Unknown") .. "\nUse /Join Raid to enter!",
		Color3.fromRGB(255, 50, 50)
	)
end)

RemoteEvents:WaitForChild("RaidCompleted").OnClientEvent:Connect(function(info)
	GameController.ShowNotification(
		"Raid Complete!",
		"+" .. info.shardsEarned .. " " .. info.worldId .. " Shards",
		Color3.fromRGB(0, 200, 255)
	)
end)

RemoteEvents:WaitForChild("DailyLoginReward").OnClientEvent:Connect(function(info)
	GameController.ShowNotification(
		"Daily Login Reward!",
		"Day " .. info.streak .. " streak!\nYen: +" .. GameController.FormatNumber(info.rewards.yen),
		Color3.fromRGB(255, 165, 0)
	)
end)

-- ================================================================
-- UI UTILITY FUNCTIONS
-- ================================================================

function GameController.ShowFloatingText(text, position, color)
	-- Create a BillboardGui floating text at world position
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 200, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	-- Attach to a part at position
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(position)
	part.Parent = workspace

	gui.Adornee = part
	gui.Parent = part

	-- Animate upward and fade
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	game:GetService("TweenService"):Create(part, tweenInfo, {
		CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
	}):Play()
	game:GetService("TweenService"):Create(label, tweenInfo, {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	game:GetService("Debris"):AddItem(part, 2)
end

function GameController.ShowNotification(title, message, color)
	local gui = LocalPlayer.PlayerGui
	local notifGui = gui:FindFirstChild("Notifications")
	if not notifGui then
		notifGui = Instance.new("ScreenGui")
		notifGui.Name = "Notifications"
		notifGui.ResetOnSpawn = false
		notifGui.Parent = gui
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 80)
	frame.Position = UDim2.new(1, -340, 0, 20 + (#notifGui:GetChildren() * 90))
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BorderSizePixel = 0
	frame.Parent = notifGui

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 1, 0)
	accent.Position = UDim2.new(0, 0, 0, 0)
	accent.BackgroundColor3 = color or Color3.new(1, 1, 1)
	accent.BorderSizePixel = 0
	accent.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.Position = UDim2.new(0, 15, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = color or Color3.new(1, 1, 1)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.Parent = frame

	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, -20, 0, 40)
	msgLabel.Position = UDim2.new(0, 15, 0, 33)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Text = message
	msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextSize = 13
	msgLabel.TextWrapped = true
	msgLabel.Parent = frame

	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	-- Slide in and auto-dismiss
	frame.Position = UDim2.new(1, 10, 0, 20 + (#notifGui:GetChildren() * 90))
	local ts = game:GetService("TweenService")
	ts:Create(frame, TweenInfo.new(0.3), {
		Position = UDim2.new(1, -340, 0, frame.Position.Y.Offset)
	}):Play()

	task.delay(4, function()
		ts:Create(frame, TweenInfo.new(0.3), {
			Position = UDim2.new(1, 10, 0, frame.Position.Y.Offset)
		}):Play()
		task.delay(0.35, function()
			if frame and frame.Parent then frame:Destroy() end
		end)
	end)
end

-- ================================================================
-- QUICK ACTION INPUT (keyboard shortcuts)
-- ================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Example: Press E near a Star pedestal to open
	if input.KeyCode == Enum.KeyCode.E then
		-- Would check proximity to star pedestal and trigger pull
	end
end)

print("[Client] GameController initialized for " .. LocalPlayer.Name)

return GameController
