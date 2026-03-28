-- DefenseModeSystem.lua
-- Defense Mode: wave-based event triggered by Defense Token, rewards Max Open Tokens

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldData = require(ReplicatedStorage.Data.WorldData)

local DefenseModeSystem = {}

-- Worlds that support Defense Mode
local DEFENSE_MODE_WORLDS = {
	"crazy_town", "wall_city", "cursed_high", "lucky_kingdom", "divine_colosseum"
}

-- Active defense sessions: [userId] = sessionData
local activeSessions = {}

local GRACE_PERIOD = 60      -- 1 minute to join after portal opens
local WAVE_COUNT = 20         -- total waves to survive
local BASE_ENEMIES_PER_WAVE = 10

-- Max Open Token rewards scale with world tier
local function getMaxOpenTokenReward(worldIndex, wavesCompleted)
	return math.floor(wavesCompleted * worldIndex * 0.5)
end

-- ================================================================
-- START DEFENSE MODE
-- ================================================================

function DefenseModeSystem.StartDefenseMode(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	-- Check world supports defense mode
	local supported = false
	for _, w in ipairs(DEFENSE_MODE_WORLDS) do
		if w == worldId then supported = true; break end
	end
	if not supported then return false, "This world does not support Defense Mode" end

	-- Check world unlocked
	local unlocked = false
	for _, w in ipairs(data.unlockedWorlds or {}) do
		if w == worldId then unlocked = true; break end
	end
	if not unlocked then return false, "World not unlocked" end

	-- Spend Defense Token
	if (data.defenseTokens or 0) < 1 then
		return false, "No Defense Tokens (earn from Daily Spin or Time Trial Shop)"
	end
	data.defenseTokens = data.defenseTokens - 1

	local world = WorldData.GetWorldById(worldId)

	-- Create session
	activeSessions[userId] = {
		worldId = worldId,
		worldIndex = world and world.worldIndex or 1,
		currentWave = 0,
		totalWaves = WAVE_COUNT,
		enemiesAlive = 0,
		startTime = os.time(),
		active = true,
		completed = false,
	}

	_G.DataManager.MarkDirty(userId)

	-- Start first wave
	task.spawn(function()
		task.wait(3)
		DefenseModeSystem._startNextWave(userId)
	end)

	-- Notify client
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local startEvent = remotes:FindFirstChild("DefenseModeStarted")
			if startEvent then
				startEvent:FireClient(player, {
					worldId = worldId,
					totalWaves = WAVE_COUNT,
				})
			end
		end
	end

	return true, nil
end

-- ================================================================
-- WAVE MANAGEMENT
-- ================================================================

function DefenseModeSystem._startNextWave(userId)
	local session = activeSessions[userId]
	if not session or not session.active then return end

	session.currentWave = session.currentWave + 1

	if session.currentWave > session.totalWaves then
		DefenseModeSystem._completeDefenseMode(userId)
		return
	end

	-- Scale enemies per wave
	local enemyCount = BASE_ENEMIES_PER_WAVE + (session.currentWave * 2)
	session.enemiesAlive = enemyCount

	local player = Players:GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local waveEvent = remotes:FindFirstChild("DefenseModeWaveStarted")
			if waveEvent then
				waveEvent:FireClient(player, {
					wave = session.currentWave,
					totalWaves = session.totalWaves,
					enemyCount = enemyCount,
				})
			end
		end
	end
end

function DefenseModeSystem.OnEnemyKilled(userId)
	local session = activeSessions[userId]
	if not session or not session.active then return end

	session.enemiesAlive = math.max(0, session.enemiesAlive - 1)

	if session.enemiesAlive <= 0 then
		-- Wave cleared
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remotes then
				local clearEvent = remotes:FindFirstChild("DefenseModeWaveCleared")
				if clearEvent then
					clearEvent:FireClient(player, { wave = session.currentWave })
				end
			end
		end

		task.delay(2, function()
			DefenseModeSystem._startNextWave(userId)
		end)
	end
end

function DefenseModeSystem.OnStarHit(userId)
	-- Enemy reached the star — defense failed
	DefenseModeSystem._failDefenseMode(userId)
end

-- ================================================================
-- COMPLETION / FAILURE
-- ================================================================

function DefenseModeSystem._completeDefenseMode(userId)
	local session = activeSessions[userId]
	if not session then return end
	session.active = false
	session.completed = true

	local tokens = getMaxOpenTokenReward(session.worldIndex, session.totalWaves)

	local data = _G.DataManager.GetData(userId)
	if data then
		data.maxOpenTokens = (data.maxOpenTokens or 0) + tokens
		_G.DataManager.MarkDirty(userId)
	end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local completeEvent = remotes:FindFirstChild("DefenseModeCompleted")
			if completeEvent then
				completeEvent:FireClient(player, {
					tokensEarned = tokens,
					wavesCompleted = session.totalWaves,
				})
			end
		end
	end

	activeSessions[userId] = nil
end

function DefenseModeSystem._failDefenseMode(userId)
	local session = activeSessions[userId]
	if not session or not session.active then return end
	session.active = false

	-- Partial reward: tokens based on waves completed
	local tokens = getMaxOpenTokenReward(session.worldIndex, session.currentWave - 1)

	if tokens > 0 then
		local data = _G.DataManager.GetData(userId)
		if data then
			data.maxOpenTokens = (data.maxOpenTokens or 0) + tokens
			_G.DataManager.MarkDirty(userId)
		end
	end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local failEvent = remotes:FindFirstChild("DefenseModeFailed")
			if failEvent then
				failEvent:FireClient(player, {
					wavesCompleted = session.currentWave - 1,
					tokensEarned = tokens,
				})
			end
		end
	end

	activeSessions[userId] = nil
end

function DefenseModeSystem.GetSession(userId)
	return activeSessions[userId]
end

return DefenseModeSystem
