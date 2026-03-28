-- DataManager.server.lua
-- Handles all player data loading, saving, and in-memory caching
-- Uses ProfileService pattern for safe DataStore operations

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataTemplate = require(ReplicatedStorage.Modules.PlayerDataTemplate)

local DataManager = {}
DataManager.__index = DataManager

-- DataStore key prefix
local DATASTORE_NAME = "AnimeFighterSim_v1"
local AUTOSAVE_INTERVAL = 60  -- seconds
local SESSION_LOCK_EXPIRY = 300  -- 5 minutes before another server can claim data

local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local sessionLockStore = DataStoreService:GetDataStore(DATASTORE_NAME .. "_Locks")

-- In-memory cache: [userId] = data
local playerCache = {}
local saveCooldowns = {}
local dirtyFlags = {}  -- [userId] = true when data needs saving

-- ================================================================
-- INTERNAL HELPERS
-- ================================================================

local function getKey(userId)
	return "Player_" .. tostring(userId)
end

local function getSessionKey(userId)
	return "Lock_" .. tostring(userId)
end

local function safeGet(store, key, retries)
	retries = retries or 3
	local data, err
	for i = 1, retries do
		local success
		success, data = pcall(function()
			return store:GetAsync(key)
		end)
		if success then return data, nil end
		err = data
		task.wait(2 ^ i)
	end
	return nil, err
end

local function safeSet(store, key, value, retries)
	retries = retries or 3
	for i = 1, retries do
		local success, err = pcall(function()
			store:SetAsync(key, value)
		end)
		if success then return true end
		warn("[DataManager] SetAsync failed for " .. key .. ": " .. tostring(err))
		task.wait(2 ^ i)
	end
	return false
end

local function safeUpdate(store, key, transform, retries)
	retries = retries or 3
	for i = 1, retries do
		local success, result = pcall(function()
			return store:UpdateAsync(key, transform)
		end)
		if success then return result end
		warn("[DataManager] UpdateAsync failed for " .. key)
		task.wait(2 ^ i)
	end
	return nil
end

-- ================================================================
-- SESSION LOCK
-- ================================================================

local function acquireSessionLock(userId)
	local sessionKey = getSessionKey(userId)
	local serverId = game.JobId ~= "" and game.JobId or "Studio"
	local now = os.time()

	local acquired = safeUpdate(sessionLockStore, sessionKey, function(existing)
		if existing then
			-- Check if lock is expired
			if (now - existing.timestamp) < SESSION_LOCK_EXPIRY and existing.serverId ~= serverId then
				return nil  -- don't update; lock is held by another server
			end
		end
		return { serverId = serverId, timestamp = now }
	end)

	return acquired ~= nil
end

local function releaseSessionLock(userId)
	local sessionKey = getSessionKey(userId)
	safeSet(sessionLockStore, sessionKey, nil)
end

-- ================================================================
-- LOAD & SAVE
-- ================================================================

local function loadPlayerData(userId)
	local key = getKey(userId)
	local raw, err = safeGet(dataStore, key)

	if err then
		warn("[DataManager] Load error for " .. userId .. ": " .. tostring(err))
		return PlayerDataTemplate.New(), false
	end

	if raw == nil then
		-- New player
		local newData = PlayerDataTemplate.New()
		newData.firstJoinDate = os.date("%Y-%m-%d")
		return newData, true
	end

	-- Migrate existing data to latest template
	local migrated = PlayerDataTemplate.Migrate(raw)
	return migrated, true
end

local function savePlayerData(userId)
	local data = playerCache[userId]
	if not data then return end

	local key = getKey(userId)
	local success = safeSet(dataStore, key, data)

	if success then
		dirtyFlags[userId] = false
	end

	return success
end

-- ================================================================
-- PUBLIC API
-- ================================================================

function DataManager.GetData(userId)
	return playerCache[userId]
end

function DataManager.SetValue(userId, path, value)
	local data = playerCache[userId]
	if not data then return false end

	-- Support dot-separated paths like "stats.strength"
	local keys = string.split(path, ".")
	local current = data
	for i = 1, #keys - 1 do
		if type(current[keys[i]]) ~= "table" then return false end
		current = current[keys[i]]
	end
	current[keys[#keys]] = value
	dirtyFlags[userId] = true
	return true
end

function DataManager.IncrementValue(userId, path, amount)
	local data = playerCache[userId]
	if not data then return false end

	local keys = string.split(path, ".")
	local current = data
	for i = 1, #keys - 1 do
		if type(current[keys[i]]) ~= "table" then return false end
		current = current[keys[i]]
	end
	local key = keys[#keys]
	if type(current[key]) ~= "number" then return false end
	current[key] = current[key] + amount
	dirtyFlags[userId] = true
	return true
end

function DataManager.GetValue(userId, path)
	local data = playerCache[userId]
	if not data then return nil end

	local keys = string.split(path, ".")
	local current = data
	for _, k in ipairs(keys) do
		if type(current) ~= "table" then return nil end
		current = current[k]
	end
	return current
end

function DataManager.MarkDirty(userId)
	dirtyFlags[userId] = true
end

-- ================================================================
-- PLAYER JOIN / LEAVE
-- ================================================================

local function onPlayerAdded(player)
	local userId = player.UserId

	-- Try to acquire session lock
	local lockAcquired = acquireSessionLock(userId)
	if not lockAcquired then
		warn("[DataManager] Could not acquire session lock for " .. player.Name .. ". Kicking.")
		player:Kick("Your data is currently in use by another server. Please try again in a moment.")
		return
	end

	local data, success = loadPlayerData(userId)
	playerCache[userId] = data

	-- Update playtime tracking
	data.lastLoginDate = os.date("%Y-%m-%d")
	dirtyFlags[userId] = false

	-- Fire event so other systems know data is ready
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local dataLoaded = remoteEvents:FindFirstChild("PlayerDataLoaded")
		if dataLoaded then
			dataLoaded:FireClient(player, data)
		end
	end

	print("[DataManager] Loaded data for " .. player.Name .. (success and "" or " (error fallback)"))
end

local function onPlayerRemoving(player)
	local userId = player.UserId

	-- Final save
	savePlayerData(userId)
	releaseSessionLock(userId)

	playerCache[userId] = nil
	dirtyFlags[userId] = nil
	saveCooldowns[userId] = nil

	print("[DataManager] Saved and cleaned up data for " .. player.Name)
end

-- ================================================================
-- AUTOSAVE LOOP
-- ================================================================

local lastAutosave = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if (now - lastAutosave) < AUTOSAVE_INTERVAL then return end
	lastAutosave = now

	for userId, dirty in pairs(dirtyFlags) do
		if dirty then
			task.spawn(savePlayerData, userId)
		end
	end
end)

-- ================================================================
-- BIND SHUTDOWN SAVE
-- ================================================================

game:BindToClose(function()
	print("[DataManager] Server closing — saving all player data...")
	for userId in pairs(playerCache) do
		savePlayerData(userId)
		releaseSessionLock(userId)
	end
	print("[DataManager] All data saved.")
end)

-- ================================================================
-- CONNECTIONS
-- ================================================================

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Export to global for other server scripts
_G.DataManager = DataManager

return DataManager
