-- RaidSystem.lua
-- Raid boss every 30 mins: ticket-gated, adaptive HP, shard rewards, shield phases

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WorldData = require(ReplicatedStorage.Data.WorldData)

local RaidSystem = {}

local RAID_INTERVAL = 30 * 60       -- 30 minutes between raids
local RAID_DURATION = 10 * 60       -- 10 minutes to defeat boss
local SHARD_REWARD_NORMAL = {3, 5}  -- min, max
local SHARD_REWARD_MASSIVE = {13, 20}
local RAID_TICKET_COST = 1          -- tickets per raid entry

-- Current active raid data (server-wide; only one raid at a time per server)
local activeRaid = nil
local nextRaidTime = os.time() + RAID_INTERVAL

-- Players who joined current raid
local raidParticipants = {}  -- [userId] = true

-- ================================================================
-- RAID SCHEDULING
-- ================================================================

local function selectRandomWorld()
	local count = WorldData.GetWorldCount()
	local idx = math.random(1, count)
	return WorldData.GetWorldByIndex(idx)
end

local function calculateBossHealth(worldIndex, participantCount)
	-- Adaptive health: scales with world and player count
	local baseHealth = 10 ^ worldIndex * 100
	local playerScale = 1 + (participantCount - 1) * 0.5
	return math.floor(baseHealth * playerScale)
end

local function startRaid(isMassive)
	local world = selectRandomWorld()
	local participantCount = 0
	for _ in pairs(raidParticipants) do participantCount = participantCount + 1 end
	participantCount = math.max(1, participantCount)

	local bossHealth = calculateBossHealth(world.worldIndex, participantCount)

	activeRaid = {
		worldId = world.id,
		worldIndex = world.worldIndex,
		worldName = world.name,
		isMassive = isMassive or false,
		bossHealth = bossHealth,
		maxBossHealth = bossHealth,
		startTime = os.time(),
		endsAt = os.time() + RAID_DURATION,
		shieldPhases = { 0.75, 0.50, 0.25 },  -- HP thresholds for shields
		activeShield = false,
		currentShieldPhase = 1,
		waveEnemiesAlive = 0,
		completed = false,
		failed = false,
	}

	raidParticipants = {}

	-- Announce raid to all players
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remotes then
		local raidAnnounce = remotes:FindFirstChild("RaidAnnounced")
		if raidAnnounce then
			raidAnnounce:FireAllClients({
				worldId = activeRaid.worldId,
				worldName = activeRaid.worldName,
				isMassive = activeRaid.isMassive,
				endsAt = activeRaid.endsAt,
			})
		end
	end

	print("[RaidSystem] Raid started in " .. world.name)
end

-- ================================================================
-- RAID ENTRY
-- ================================================================

function RaidSystem.JoinRaid(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	if not activeRaid or activeRaid.completed or activeRaid.failed then
		return false, "No active raid right now"
	end

	if os.time() > activeRaid.endsAt then
		return false, "Raid has expired"
	end

	if raidParticipants[userId] then
		return false, "Already in raid"
	end

	-- Spend ticket
	if (data.raidTickets or 0) < RAID_TICKET_COST then
		return false, "Not enough Raid Tickets (need " .. RAID_TICKET_COST .. ")"
	end
	data.raidTickets = data.raidTickets - RAID_TICKET_COST
	_G.DataManager.MarkDirty(userId)

	raidParticipants[userId] = true

	local player = Players:GetPlayerByUserId(userId)
	if player then
		-- Teleport player to raid arena
		if _G.WorldSystem then
			_G.WorldSystem.TeleportPlayerToWorld(player, activeRaid.worldId)
		end

		-- Notify player they joined
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local joinEvent = remotes:FindFirstChild("RaidJoined")
			if joinEvent then
				joinEvent:FireClient(player, {
					bossHealth = activeRaid.bossHealth,
					maxBossHealth = activeRaid.maxBossHealth,
					isMassive = activeRaid.isMassive,
					endsAt = activeRaid.endsAt,
				})
			end
		end
	end

	return true, nil
end

-- ================================================================
-- RAID DAMAGE
-- ================================================================

function RaidSystem.DamageBoss(userId, damage)
	if not activeRaid or activeRaid.completed or activeRaid.failed then return end
	if not raidParticipants[userId] then return end
	if activeRaid.activeShield then return end  -- shield blocks damage

	activeRaid.bossHealth = math.max(0, activeRaid.bossHealth - damage)

	-- Check shield phase triggers
	local healthPercent = activeRaid.bossHealth / activeRaid.maxBossHealth
	local nextPhase = activeRaid.shieldPhases[activeRaid.currentShieldPhase]

	if nextPhase and healthPercent <= nextPhase then
		-- Activate shield, spawn wave
		activeRaid.activeShield = true
		activeRaid.waveEnemiesAlive = 10  -- 10 wave enemies to clear
		activeRaid.currentShieldPhase = activeRaid.currentShieldPhase + 1

		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local shieldEvent = remotes:FindFirstChild("RaidShieldActivated")
			if shieldEvent then
				shieldEvent:FireAllClients({ phasePercent = nextPhase, waveCount = 10 })
			end
		end
	end

	-- Check boss death
	if activeRaid.bossHealth <= 0 then
		RaidSystem._completeRaid()
	end

	-- Broadcast updated HP to all participants
	RaidSystem._broadcastBossHealth()
end

function RaidSystem.OnWaveEnemyKilled(userId)
	if not activeRaid or not activeRaid.activeShield then return end
	if not raidParticipants[userId] then return end

	activeRaid.waveEnemiesAlive = math.max(0, activeRaid.waveEnemiesAlive - 1)

	if activeRaid.waveEnemiesAlive <= 0 then
		-- Remove shield
		activeRaid.activeShield = false

		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local shieldEvent = remotes:FindFirstChild("RaidShieldRemoved")
			if shieldEvent then shieldEvent:FireAllClients({}) end
		end
	end
end

-- ================================================================
-- RAID COMPLETION / FAILURE
-- ================================================================

function RaidSystem._completeRaid()
	if not activeRaid or activeRaid.completed then return end
	activeRaid.completed = true

	local rewards = activeRaid.isMassive and SHARD_REWARD_MASSIVE or SHARD_REWARD_NORMAL
	local shardCount = math.random(rewards[1], rewards[2])

	-- Reward all participants
	for userId in pairs(raidParticipants) do
		local data = _G.DataManager.GetData(userId)
		if data and _G.CurrencySystem then
			_G.CurrencySystem.AddShards(userId, activeRaid.worldId, shardCount)
		end

		local player = Players:GetPlayerByUserId(userId)
		if player then
			local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remotes then
				local completeEvent = remotes:FindFirstChild("RaidCompleted")
				if completeEvent then
					completeEvent:FireClient(player, {
						shardsEarned = shardCount,
						worldId = activeRaid.worldId,
						isMassive = activeRaid.isMassive,
					})
				end
			end
		end
	end

	print("[RaidSystem] Raid completed! " .. shardCount .. " shards rewarded.")
	activeRaid = nil
	raidParticipants = {}
	nextRaidTime = os.time() + RAID_INTERVAL
end

function RaidSystem._failRaid()
	if not activeRaid or activeRaid.failed then return end
	activeRaid.failed = true

	-- No shards on fail
	for userId in pairs(raidParticipants) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remotes then
				local failEvent = remotes:FindFirstChild("RaidFailed")
				if failEvent then failEvent:FireClient(player, {}) end
			end
		end
	end

	print("[RaidSystem] Raid failed!")
	activeRaid = nil
	raidParticipants = {}
	nextRaidTime = os.time() + RAID_INTERVAL
end

function RaidSystem._broadcastBossHealth()
	if not activeRaid then return end
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remotes then return end
	local hpEvent = remotes:FindFirstChild("RaidBossHealth")
	if hpEvent then
		for userId in pairs(raidParticipants) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				hpEvent:FireClient(player, {
					health = activeRaid.bossHealth,
					maxHealth = activeRaid.maxBossHealth,
				})
			end
		end
	end
end

-- ================================================================
-- TICKER
-- ================================================================

RunService.Heartbeat:Connect(function()
	local now = os.time()

	-- Start new raid when interval passes
	if not activeRaid and now >= nextRaidTime then
		local isMassive = (math.random(1, 10) == 1)  -- 10% chance massive raid
		startRaid(isMassive)
	end

	-- Check raid timeout
	if activeRaid and not activeRaid.completed and not activeRaid.failed then
		if now > activeRaid.endsAt then
			RaidSystem._failRaid()
		end
	end
end)

-- ================================================================
-- TICKET MANAGEMENT
-- ================================================================

function RaidSystem.AddTickets(userId, count)
	local data = _G.DataManager.GetData(userId)
	if not data then return false end
	data.raidTickets = (data.raidTickets or 0) + count
	_G.DataManager.MarkDirty(userId)
	return true
end

function RaidSystem.GetActiveRaidInfo()
	return activeRaid
end

function RaidSystem.GetNextRaidTime()
	return nextRaidTime
end

return RaidSystem
