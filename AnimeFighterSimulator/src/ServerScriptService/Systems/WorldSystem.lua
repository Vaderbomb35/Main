-- WorldSystem.lua
-- Handles world unlocking, player area tracking, and world teleportation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldData = require(ReplicatedStorage.Data.WorldData)

local WorldSystem = {}

-- ================================================================
-- WORLD UNLOCKING
-- ================================================================

function WorldSystem.UnlockWorld(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local world = WorldData.GetWorldById(worldId)
	if not world then return false, "Invalid world" end

	-- Check if already unlocked
	for _, w in ipairs(data.unlockedWorlds or {}) do
		if w == worldId then return false, "World already unlocked" end
	end

	-- Check cost
	local cost = world.unlockCost
	local ok, err = _G.CurrencySystem.SpendYen(userId, cost)
	if not ok then return false, err end

	-- Unlock
	if not data.unlockedWorlds then data.unlockedWorlds = {} end
	table.insert(data.unlockedWorlds, worldId)
	_G.DataManager.MarkDirty(userId)

	return true, world
end

function WorldSystem.IsWorldUnlocked(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false end
	for _, w in ipairs(data.unlockedWorlds or {}) do
		if w == worldId then return true end
	end
	return false
end

function WorldSystem.GetUnlockedWorlds(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return {} end
	return data.unlockedWorlds or {}
end

-- ================================================================
-- TELEPORTATION
-- ================================================================

-- Returns the spawn CFrame for a world (looks up map model in Workspace)
local function getWorldSpawnCFrame(worldId)
	local mapsFolder = Workspace:FindFirstChild("Maps")
	if not mapsFolder then
		-- Default: stagger worlds in a line
		local world = WorldData.GetWorldById(worldId)
		if world then
			return CFrame.new((world.worldIndex - 1) * 2000, 10, 0)
		end
		return CFrame.new(0, 10, 0)
	end

	local mapModel = mapsFolder:FindFirstChild(worldId)
	if mapModel then
		local spawnPart = mapModel:FindFirstChild("SpawnPoint")
		if spawnPart then
			return spawnPart.CFrame + Vector3.new(0, 5, 0)
		end
		if mapModel.PrimaryPart then
			return mapModel.PrimaryPart.CFrame + Vector3.new(0, 10, 0)
		end
	end

	return CFrame.new(0, 10, 0)
end

function WorldSystem.TeleportPlayerToWorld(player, worldId)
	local userId = player.UserId
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	if not WorldSystem.IsWorldUnlocked(userId, worldId) then
		return false, "World not unlocked"
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false, "Character not ready"
	end

	local spawnCFrame = getWorldSpawnCFrame(worldId)
	character:SetPrimaryPartCFrame(spawnCFrame)

	-- Update current world index
	local world = WorldData.GetWorldById(worldId)
	if world then
		data.currentWorldIndex = world.worldIndex
		_G.DataManager.MarkDirty(userId)
	end

	-- Notify combat system of new area
	if _G.CombatSystem then
		_G.CombatSystem.SetPlayerArea(userId, worldId)
	end

	-- Fire world change event to client
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remotes then
		local worldChangedEvent = remotes:FindFirstChild("WorldChanged")
		if worldChangedEvent then
			worldChangedEvent:FireClient(player, { worldId = worldId, worldData = world })
		end
	end

	return true, nil
end

-- ================================================================
-- NEXT WORLD INFO (for unlock button in UI)
-- ================================================================

function WorldSystem.GetNextWorldToUnlock(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return nil end

	local worldCount = WorldData.GetWorldCount()
	for i = 1, worldCount do
		local world = WorldData.GetWorldByIndex(i)
		if world then
			local unlocked = false
			for _, w in ipairs(data.unlockedWorlds or {}) do
				if w == world.id then unlocked = true; break end
			end
			if not unlocked then
				return world
			end
		end
	end
	return nil  -- all worlds unlocked
end

return WorldSystem
