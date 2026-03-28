-- FighterSystem.lua
-- Manages fighter equip/unequip, fusion (leveling), crafting, incubator, shiny conversion

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FighterData = require(ReplicatedStorage.Data.FighterData)
local WorldData = require(ReplicatedStorage.Data.WorldData)
local PassiveData = require(ReplicatedStorage.Data.PassiveData)

local FighterSystem = {}

local MAX_FIGHTER_LEVEL = 440

-- ================================================================
-- EQUIP / UNEQUIP
-- ================================================================

function FighterSystem.EquipFighter(userId, instanceId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	-- Verify fighter exists in collection
	local found = false
	for _, f in ipairs(data.fighters or {}) do
		if f.id == instanceId then found = true; break end
	end
	if not found then return false, "Fighter not in collection" end

	-- Check if already equipped
	for _, eid in ipairs(data.equippedFighters or {}) do
		if eid == instanceId then return false, "Already equipped" end
	end

	-- Check max equip slots
	local maxSlots = 3
	maxSlots = maxSlots + (data.upgrades and data.upgrades.extraEquipSlots or 0)
	if data.gamepasses and data.gamepasses.extraEquip then
		maxSlots = maxSlots + 1
	end

	if #(data.equippedFighters or {}) >= maxSlots then
		return false, "Max equip slots filled (" .. maxSlots .. ")"
	end

	table.insert(data.equippedFighters, instanceId)
	_G.DataManager.MarkDirty(userId)
	return true, nil
end

function FighterSystem.UnequipFighter(userId, instanceId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	for i, eid in ipairs(data.equippedFighters or {}) do
		if eid == instanceId then
			table.remove(data.equippedFighters, i)
			_G.DataManager.MarkDirty(userId)
			return true, nil
		end
	end

	return false, "Fighter not equipped"
end

-- ================================================================
-- FUSION (LEVELING)
-- ================================================================

-- Fuse sacrificed fighters into target to gain EXP
-- sacrificeIds: array of fighter instance IDs to consume
function FighterSystem.FuseFighters(userId, targetId, sacrificeIds)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	-- Find target
	local target = nil
	for _, f in ipairs(data.fighters or {}) do
		if f.id == targetId then target = f; break end
	end
	if not target then return false, "Target fighter not found" end
	if target.level >= MAX_FIGHTER_LEVEL then return false, "Fighter is already max level" end

	-- Cannot sacrifice equipped fighters
	local equippedSet = {}
	for _, eid in ipairs(data.equippedFighters or {}) do equippedSet[eid] = true end
	if equippedSet[targetId] then return false, "Cannot fuse an equipped fighter" end

	-- Collect sacrifice EXP
	local totalEXP = 0
	local toRemove = {}

	for _, sacId in ipairs(sacrificeIds) do
		if sacId == targetId then
			return false, "Cannot sacrifice the target fighter"
		end
		if equippedSet[sacId] then
			return false, "Cannot sacrifice an equipped fighter"
		end

		local sacFighter = nil
		local sacIndex = nil
		for i, f in ipairs(data.fighters) do
			if f.id == sacId then sacFighter = f; sacIndex = i; break end
		end
		if not sacFighter then return false, "Sacrifice fighter not found: " .. sacId end

		-- EXP value based on rarity and level of sacrifice
		local rarityData = FighterData.Rarities[sacFighter.rarity]
		local rarityBonus = rarityData and rarityData.tier or 1
		local sacEXP = math.floor((sacFighter.level * 50 + sacFighter.exp) * rarityBonus)
		totalEXP = totalEXP + sacEXP

		table.insert(toRemove, sacIndex)
	end

	-- Remove sacrificed fighters (reverse order to preserve indices)
	table.sort(toRemove, function(a, b) return a > b end)
	for _, idx in ipairs(toRemove) do
		table.remove(data.fighters, idx)
	end

	-- Apply EXP to target
	target.exp = target.exp + totalEXP

	-- Level up loop
	local levelsGained = 0
	while target.level < MAX_FIGHTER_LEVEL do
		local expNeeded = FighterData.GetExpForLevel(target.level)
		if target.exp >= expNeeded then
			target.exp = target.exp - expNeeded
			target.level = target.level + 1
			levelsGained = levelsGained + 1
		else
			break
		end
	end

	-- Cap EXP at max level
	if target.level >= MAX_FIGHTER_LEVEL then
		target.exp = 0
	end

	_G.DataManager.MarkDirty(userId)
	return true, { levelsGained = levelsGained, newLevel = target.level, expRemaining = target.exp }
end

-- ================================================================
-- CRAFTING
-- ================================================================

-- Craft a world's unique Crafted fighter from 3 Mythicals + 5 Shards
function FighterSystem.CraftFighter(userId, worldId, mythicalInstanceIds, useShiny)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local world = WorldData.GetWorldById(worldId)
	if not world then return false, "Invalid world" end
	if not world.craftedFighter then return false, "This world has no craftable fighter" end

	local craftedTemplate = FighterData.Fighters[world.craftedFighter]
	if not craftedTemplate then return false, "Crafted fighter data not found" end

	-- Validate 3 mythicals from this world
	if #mythicalInstanceIds ~= 3 then
		return false, "Crafting requires exactly 3 Mythical fighters from this world"
	end

	local equippedSet = {}
	for _, eid in ipairs(data.equippedFighters or {}) do equippedSet[eid] = true end

	local requiredRarity = useShiny and "Mythical" or "Mythical"
	local mythicalIndices = {}

	for _, mid in ipairs(mythicalInstanceIds) do
		if equippedSet[mid] then
			return false, "Cannot use equipped fighters for crafting"
		end
		local found = false
		for i, f in ipairs(data.fighters) do
			if f.id == mid then
				if f.rarity ~= "Mythical" then
					return false, "All fighters must be Mythical rarity"
				end
				if f.worldId ~= worldId then
					return false, "All fighters must be from " .. world.name
				end
				if useShiny and not f.isShiny then
					return false, "Shiny crafting requires Shiny Mythical fighters"
				end
				found = true
				table.insert(mythicalIndices, i)
				break
			end
		end
		if not found then return false, "Fighter not found: " .. mid end
	end

	-- Check shards
	local shardsRequired = useShiny and 20 or 5
	local CurrencySystem = _G.CurrencySystem
	local hasShards, shardErr = CurrencySystem.SpendShards(userId, worldId, shardsRequired)
	if not hasShards then return false, shardErr end

	-- Remove mythicals (reverse order)
	table.sort(mythicalIndices, function(a, b) return a > b end)
	for _, idx in ipairs(mythicalIndices) do
		table.remove(data.fighters, idx)
	end

	-- Create crafted fighter instance
	local instance = {
		id = tostring(os.time()) .. "_craft_" .. tostring(math.random(10000, 99999)),
		fighterId = craftedTemplate.id,
		name = craftedTemplate.name,
		rarity = "Crafted",
		worldId = worldId,
		worldIndex = world.worldIndex,
		level = 1,
		exp = 0,
		isShiny = useShiny or false,
		passive = nil,
		passiveSlotUnlocked = false,
	}

	table.insert(data.fighters, instance)
	_G.DataManager.MarkDirty(userId)

	return true, instance
end

-- ================================================================
-- SELL FIGHTER (convert to PXP / Yen)
-- ================================================================

function FighterSystem.SellFighter(userId, instanceId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	-- Can't sell equipped fighters
	local equippedSet = {}
	for _, eid in ipairs(data.equippedFighters or {}) do equippedSet[eid] = true end
	if equippedSet[instanceId] then return false, "Cannot sell an equipped fighter" end

	local found = false
	local yenValue = 0
	for i, f in ipairs(data.fighters) do
		if f.id == instanceId then
			-- Sell value: rarity tier * level * 100 Yen
			local rarityData = FighterData.Rarities[f.rarity]
			yenValue = math.floor((rarityData and rarityData.tier or 1) * f.level * 100)
			if f.isShiny then yenValue = yenValue * 2 end
			table.remove(data.fighters, i)
			found = true
			break
		end
	end

	if not found then return false, "Fighter not found" end

	_G.CurrencySystem.AddYen(userId, yenValue)
	_G.DataManager.MarkDirty(userId)

	return true, yenValue
end

-- ================================================================
-- INCUBATOR
-- ================================================================

-- Place a fighter in the incubator (gains +1 level per day)
function FighterSystem.PlaceInIncubator(userId, worldId, instanceId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local world = WorldData.GetWorldById(worldId)
	if not world or not world.hasIncubator then
		return false, "This world has no incubator"
	end

	if not data.incubatorSlots then data.incubatorSlots = {} end
	if data.incubatorSlots[worldId] then
		return false, "Incubator slot is occupied in " .. world.name
	end

	-- Verify fighter in collection
	local found = false
	for _, f in ipairs(data.fighters or {}) do
		if f.id == instanceId then
			if f.level >= MAX_FIGHTER_LEVEL then
				return false, "Fighter is already max level"
			end
			found = true; break
		end
	end
	if not found then return false, "Fighter not found" end

	data.incubatorSlots[worldId] = {
		fighterId = instanceId,
		placedAt = os.time(),
		lastCollectedAt = os.time(),
	}
	_G.DataManager.MarkDirty(userId)
	return true, nil
end

-- Collect incubator levels (called on login / manual collect)
function FighterSystem.CollectIncubator(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data or not data.incubatorSlots then return false, "No incubator data" end

	local slot = data.incubatorSlots[worldId]
	if not slot then return false, "No fighter in incubator" end

	local now = os.time()
	local secondsSinceCollect = now - slot.lastCollectedAt
	local daysElapsed = math.floor(secondsSinceCollect / 86400)

	if daysElapsed < 1 then
		return false, "Incubator not ready yet"
	end

	-- Find the fighter and add levels
	local levelsToGive = math.min(daysElapsed, MAX_FIGHTER_LEVEL)
	local fighter = nil
	for _, f in ipairs(data.fighters or {}) do
		if f.id == slot.fighterId then fighter = f; break end
	end

	if not fighter then
		data.incubatorSlots[worldId] = nil
		_G.DataManager.MarkDirty(userId)
		return false, "Fighter no longer in collection"
	end

	local levelsGained = 0
	for _ = 1, levelsToGive do
		if fighter.level >= MAX_FIGHTER_LEVEL then break end
		fighter.level = fighter.level + 1
		levelsGained = levelsGained + 1
	end

	slot.lastCollectedAt = now

	if fighter.level >= MAX_FIGHTER_LEVEL then
		-- Remove from incubator automatically
		data.incubatorSlots[worldId] = nil
	end

	_G.DataManager.MarkDirty(userId)
	return true, { levelsGained = levelsGained, newLevel = fighter.level }
end

-- ================================================================
-- SHINY CONVERSION (Shiny Machine)
-- ================================================================

-- Convert a normal fighter to Shiny using Fruits
-- Cost: 10 Fruits per conversion (tracked via a Fruits count in data)
function FighterSystem.MakeShiny(userId, instanceId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local FRUIT_COST = 10
	local fruits = data.fruits or 0
	if fruits < FRUIT_COST then
		return false, "Not enough Fruits (need " .. FRUIT_COST .. ", have " .. fruits .. ")"
	end

	local fighter = nil
	for _, f in ipairs(data.fighters or {}) do
		if f.id == instanceId then fighter = f; break end
	end
	if not fighter then return false, "Fighter not found" end
	if fighter.isShiny then return false, "Fighter is already Shiny" end

	data.fruits = fruits - FRUIT_COST
	fighter.isShiny = true
	_G.DataManager.MarkDirty(userId)

	return true, nil
end

-- ================================================================
-- PASSIVE REROLL
-- ================================================================

function FighterSystem.RerollPassive(userId, instanceId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local fighter = nil
	for _, f in ipairs(data.fighters or {}) do
		if f.id == instanceId then fighter = f; break end
	end
	if not fighter then return false, "Fighter not found" end

	-- Check passive slot unlocked
	if not fighter.passiveSlotUnlocked then
		if not (data.gamepasses and data.gamepasses.passive) then
			return false, "Passive slot not unlocked (requires Passive gamepass)"
		end
		fighter.passiveSlotUnlocked = true
	end

	-- Determine shard cost
	local costKey = fighter.rarity
	if fighter.isShiny then
		costKey = "Shiny" .. fighter.rarity
	end
	local shardCost = PassiveData.RerollCosts[costKey] or PassiveData.RerollCosts[fighter.rarity] or 1

	local ok, err = _G.CurrencySystem.SpendShards(userId, fighter.worldId, shardCost)
	if not ok then return false, err end

	local newPassive = PassiveData.RollPassive()
	fighter.passive = newPassive
	_G.DataManager.MarkDirty(userId)

	return true, newPassive
end

-- Transfer a passive from one fighter to another
function FighterSystem.TransferPassive(userId, sourceId, targetId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local source, target = nil, nil
	for _, f in ipairs(data.fighters or {}) do
		if f.id == sourceId then source = f end
		if f.id == targetId then target = f end
	end
	if not source then return false, "Source fighter not found" end
	if not target then return false, "Target fighter not found" end
	if not source.passive then return false, "Source has no passive" end

	-- Transfer passive machine costs: 1 shard from each world
	local ok1, e1 = _G.CurrencySystem.SpendShards(userId, source.worldId, 1)
	if not ok1 then return false, e1 end

	target.passive = source.passive
	target.passiveSlotUnlocked = true
	source.passive = nil
	_G.DataManager.MarkDirty(userId)

	return true, nil
end

return FighterSystem
