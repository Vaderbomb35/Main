-- CurrencySystem.lua
-- Handles passive Yen income, Yen transactions, and class-based income rates

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassData = require(ReplicatedStorage.Data.ClassData)
local PassiveData = require(ReplicatedStorage.Data.PassiveData)

local CurrencySystem = {}

-- How often we tick passive income (every N seconds)
local INCOME_TICK_RATE = 5  -- tick every 5 seconds, give 5 seconds worth of income

-- Multipliers from Roblox Group membership, weekend events, etc.
-- These would be set dynamically by event systems
local globalYenMultiplier = 1.0
local isWeekend = false

-- ================================================================
-- INCOME CALCULATION
-- ================================================================

-- Returns Yen per second for this player
function CurrencySystem.GetYenPerSecond(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return 0 end

	local classData = ClassData.GetClass(data.classIndex or 1)
	if not classData then return 0 end

	local baseYen = classData.yenPerMinute / 60  -- convert to per second

	-- Upgrades tab world badge multiplier (each badge = +10%)
	local badgeMultiplier = data.upgrades and data.upgrades.yenMultiplier or 1.0

	-- Check for Solid Gold passive on equipped fighters
	local passiveEffects = PassiveData.AggregatePassiveEffects(
		CurrencySystem._getEquippedFighterData(data)
	)
	local passiveYenMult = passiveEffects.yenMultiplier or 1.0

	-- Active Yen boost
	local boostMult = CurrencySystem._getActiveBoostMultiplier(data, "yen")

	-- Global server multiplier
	local globalMult = globalYenMultiplier
	if isWeekend then globalMult = globalMult * 2 end

	-- Roblox Group bonus (1.5x) — verified server-side via GroupService
	-- Handled separately; assumed 1.0 here unless group check passes

	return baseYen * badgeMultiplier * passiveYenMult * boostMult * globalMult
end

function CurrencySystem._getEquippedFighterData(data)
	local fighters = {}
	if not data.fighters or not data.equippedFighters then return fighters end
	local fighterMap = {}
	for _, f in ipairs(data.fighters) do
		fighterMap[f.id] = f
	end
	for _, eid in ipairs(data.equippedFighters) do
		if fighterMap[eid] then
			table.insert(fighters, fighterMap[eid])
		end
	end
	return fighters
end

function CurrencySystem._getActiveBoostMultiplier(data, boostType)
	local mult = 1.0
	local now = os.time()
	if not data.activeBoosts then return mult end
	for _, boost in ipairs(data.activeBoosts) do
		if boost.type == boostType and boost.expiresAt > now then
			mult = mult * (boost.multiplier or 1.0)
		end
	end
	return mult
end

-- ================================================================
-- YEN TRANSACTIONS
-- ================================================================

function CurrencySystem.AddYen(userId, amount)
	if amount <= 0 then return false end
	local success = _G.DataManager.IncrementValue(userId, "yen", amount)
	if success then
		CurrencySystem._syncYenToClient(userId)
	end
	return success
end

function CurrencySystem.SpendYen(userId, amount)
	if amount <= 0 then return false, "Invalid amount" end
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end
	if data.yen < amount then
		return false, "Not enough Yen (have " .. tostring(data.yen) .. ", need " .. tostring(amount) .. ")"
	end
	_G.DataManager.IncrementValue(userId, "yen", -amount)
	CurrencySystem._syncYenToClient(userId)
	return true, nil
end

function CurrencySystem.GetYen(userId)
	return _G.DataManager.GetValue(userId, "yen") or 0
end

-- Shard transactions
function CurrencySystem.AddShards(userId, worldId, amount)
	local data = _G.DataManager.GetData(userId)
	if not data then return false end
	if not data.shards then data.shards = {} end
	data.shards[worldId] = (data.shards[worldId] or 0) + amount
	_G.DataManager.MarkDirty(userId)
	return true
end

function CurrencySystem.SpendShards(userId, worldId, amount)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end
	local current = (data.shards and data.shards[worldId]) or 0
	if current < amount then
		return false, "Not enough shards (have " .. current .. ", need " .. amount .. ")"
	end
	data.shards[worldId] = current - amount
	_G.DataManager.MarkDirty(userId)
	return true
end

function CurrencySystem.GetShards(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data or not data.shards then return 0 end
	return data.shards[worldId] or 0
end

-- TT Shard transactions
function CurrencySystem.AddTTShards(userId, amount)
	return _G.DataManager.IncrementValue(userId, "ttShards", amount)
end

function CurrencySystem.SpendTTShards(userId, amount)
	local current = _G.DataManager.GetValue(userId, "ttShards") or 0
	if current < amount then return false, "Not enough TT Shards" end
	_G.DataManager.IncrementValue(userId, "ttShards", -amount)
	return true
end

-- ================================================================
-- CLIENT SYNC
-- ================================================================

function CurrencySystem._syncYenToClient(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end
	local yen = CurrencySystem.GetYen(userId)
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remotes then
		local syncEvent = remotes:FindFirstChild("SyncCurrency")
		if syncEvent then
			syncEvent:FireClient(player, { yen = yen })
		end
	end
end

-- ================================================================
-- PASSIVE INCOME LOOP
-- ================================================================

local lastTick = os.clock()

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local elapsed = now - lastTick

	if elapsed < INCOME_TICK_RATE then return end
	lastTick = now

	for _, player in ipairs(Players:GetPlayers()) do
		local userId = player.UserId
		local yenPerSecond = CurrencySystem.GetYenPerSecond(userId)
		local earned = math.floor(yenPerSecond * elapsed)
		if earned > 0 then
			CurrencySystem.AddYen(userId, earned)
		end
	end
end)

-- ================================================================
-- GLOBAL MULTIPLIER CONTROLS (called by event systems)
-- ================================================================

function CurrencySystem.SetGlobalYenMultiplier(mult)
	globalYenMultiplier = mult
end

function CurrencySystem.SetWeekendBonus(active)
	isWeekend = active
end

return CurrencySystem
