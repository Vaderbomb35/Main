-- ClassSystem.lua
-- Handles class upgrades, stat training, and Yen income tier progression

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassData = require(ReplicatedStorage.Data.ClassData)

local ClassSystem = {}

-- Stat names that can be trained
local STAT_NAMES = { "strength", "durability", "chakra" }

-- Cost per stat point (scales quadratically)
local function getStatUpgradeCost(currentPoints)
	return math.floor(100 * (1.1 ^ currentPoints))
end

-- ================================================================
-- STAT TRAINING
-- ================================================================

function ClassSystem.TrainStat(userId, statName)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	-- Validate stat name
	local valid = false
	for _, s in ipairs(STAT_NAMES) do
		if s == statName then valid = true; break end
	end
	if not valid then return false, "Invalid stat: " .. tostring(statName) end

	if not data.stats then data.stats = { strength = 0, durability = 0, chakra = 0 } end

	local currentPoints = data.stats[statName] or 0
	local cost = getStatUpgradeCost(currentPoints)

	local ok, err = _G.CurrencySystem.SpendYen(userId, cost)
	if not ok then return false, err end

	data.stats[statName] = currentPoints + 1
	_G.DataManager.MarkDirty(userId)

	return true, { stat = statName, newValue = data.stats[statName], nextCost = getStatUpgradeCost(data.stats[statName]) }
end

-- Bulk train: spend Yen for N stat points at once
function ClassSystem.TrainStatBulk(userId, statName, count)
	count = math.clamp(count or 1, 1, 1000)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local valid = false
	for _, s in ipairs(STAT_NAMES) do
		if s == statName then valid = true; break end
	end
	if not valid then return false, "Invalid stat" end

	if not data.stats then data.stats = { strength = 0, durability = 0, chakra = 0 } end

	-- Calculate total cost
	local currentPoints = data.stats[statName] or 0
	local totalCost = 0
	for i = 0, count - 1 do
		totalCost = totalCost + getStatUpgradeCost(currentPoints + i)
	end

	local ok, err = _G.CurrencySystem.SpendYen(userId, totalCost)
	if not ok then return false, err end

	data.stats[statName] = currentPoints + count
	_G.DataManager.MarkDirty(userId)

	return true, { stat = statName, newValue = data.stats[statName], pointsAdded = count }
end

-- ================================================================
-- CLASS UPGRADE
-- ================================================================

function ClassSystem.UpgradeClass(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local currentClass = data.classIndex or 1
	local nextClassIndex = currentClass + 1
	local nextClass = ClassData.GetClass(nextClassIndex)

	if not nextClass then
		return false, "Already max class (" .. ClassData.GetClass(currentClass).name .. ")"
	end

	-- Check stat requirement
	local canUpgrade, statErr = ClassData.CanUpgradeClass(currentClass, data.stats or {})
	if not canUpgrade then return false, statErr end

	-- Check Yen cost
	local ok, err = _G.CurrencySystem.SpendYen(userId, nextClass.upgradeCost)
	if not ok then return false, err end

	data.classIndex = nextClassIndex
	_G.DataManager.MarkDirty(userId)

	return true, {
		newClass = nextClass.name,
		newYenPerMinute = nextClass.yenPerMinute,
		classIndex = nextClassIndex,
	}
end

function ClassSystem.GetClassInfo(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return nil end

	local classIndex = data.classIndex or 1
	local current = ClassData.GetClass(classIndex)
	local next = ClassData.GetClass(classIndex + 1)

	return {
		classIndex = classIndex,
		className = current and current.name or "Unknown",
		yenPerMinute = current and current.yenPerMinute or 0,
		nextClass = next,
		stats = data.stats or {},
	}
end

-- ================================================================
-- STAT COST INFO (for UI)
-- ================================================================

function ClassSystem.GetStatCost(userId, statName)
	local data = _G.DataManager.GetData(userId)
	if not data or not data.stats then return 0 end
	return getStatUpgradeCost(data.stats[statName] or 0)
end

return ClassSystem
