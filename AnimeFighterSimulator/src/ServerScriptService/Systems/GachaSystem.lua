-- GachaSystem.lua
-- Handles Star opening (gacha pulls), pity tracking, luck, and shiny rolls

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FighterData = require(ReplicatedStorage.Data.FighterData)
local WorldData = require(ReplicatedStorage.Data.WorldData)

local GachaSystem = {}

-- Shiny chance (base 1 in 100 pull gives shiny version)
local SHINY_CHANCE = 0.01

-- Star costs per world (scales with world index)
-- Base cost = 1000 * (1.8 ^ (worldIndex - 1))
local function getStarCost(worldIndex, hasVIP)
	local cost = math.floor(1000 * (1.8 ^ (worldIndex - 1)))
	if hasVIP then
		cost = math.floor(cost * 0.75)  -- 25% discount
	end
	return cost
end

-- ================================================================
-- PITY MANAGEMENT
-- ================================================================

local function getPityData(data, worldId)
	if not data.worldPity then data.worldPity = {} end
	if not data.worldPity[worldId] then
		data.worldPity[worldId] = {
			pullsSinceLastLegendary = 0,
			pullsSinceLastMythical = 0,
			isInMythicalCycle = false,
		}
	end
	return data.worldPity[worldId]
end

local function checkPity(pityData, rolledRarity)
	local pity = FighterData.Pity

	-- Count the pull
	pityData.pullsSinceLastLegendary = pityData.pullsSinceLastLegendary + 1
	if pityData.isInMythicalCycle then
		pityData.pullsSinceLastMythical = pityData.pullsSinceLastMythical + 1
	end

	local finalRarity = rolledRarity

	-- Legendary pity: guarantee Legendary if exceeded threshold
	if pityData.pullsSinceLastLegendary >= pity.LegendaryPity then
		if finalRarity == "Common" or finalRarity == "Rare" or finalRarity == "Epic" then
			finalRarity = "Legendary"
		end
	end

	-- Mythical pity cycle
	if pityData.isInMythicalCycle and pityData.pullsSinceLastMythical >= pity.MythicalPity then
		finalRarity = "Mythical"
	end

	-- Reset counters based on what dropped
	if finalRarity == "Mythical" or finalRarity == "Crafted" or finalRarity == "Secret" or finalRarity == "Divine" then
		pityData.pullsSinceLastLegendary = 0
		pityData.pullsSinceLastMythical = 0
		pityData.isInMythicalCycle = false
	elseif finalRarity == "Legendary" then
		pityData.pullsSinceLastLegendary = 0
		-- Alternate into Mythical pity cycle
		pityData.isInMythicalCycle = not pityData.isInMythicalCycle
		if pityData.isInMythicalCycle then
			pityData.pullsSinceLastMythical = 0
		end
	end

	return finalRarity
end

-- ================================================================
-- SHINY ROLL
-- ================================================================

local function rollShiny(luck)
	local chance = SHINY_CHANCE * (1 + luck * 0.1)
	return math.random() < chance
end

-- ================================================================
-- FIGHTER INSTANCE CREATION
-- ================================================================

local instanceCounter = 0
local function createFighterInstance(fighterTemplate, isShiny)
	instanceCounter = instanceCounter + 1
	return {
		id = tostring(os.time()) .. "_" .. tostring(instanceCounter),  -- unique instance ID
		fighterId = fighterTemplate.id,
		name = fighterTemplate.name,
		rarity = fighterTemplate.rarity,
		worldId = fighterTemplate.worldId,
		worldIndex = fighterTemplate.worldIndex,
		level = 1,
		exp = 0,
		isShiny = isShiny or false,
		passive = nil,                 -- assigned later via Passive Machine
		passiveSlotUnlocked = false,   -- requires Passive gamepass
	}
end

-- ================================================================
-- SINGLE PULL
-- ================================================================

-- Returns: fighterInstance, rarityRolled, wasShiny, error
function GachaSystem.Pull(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data then return nil, nil, false, "Data not loaded" end

	-- Get world
	local world = WorldData.GetWorldById(worldId)
	if not world then return nil, nil, false, "Invalid world" end

	-- Check world unlocked
	local isUnlocked = false
	for _, unlocked in ipairs(data.unlockedWorlds or {}) do
		if unlocked == worldId then isUnlocked = true; break end
	end
	if not isUnlocked then return nil, nil, false, "World not unlocked" end

	-- Calculate star cost
	local hasVIP = data.gamepasses and data.gamepasses.vip
	local cost = getStarCost(world.worldIndex, hasVIP)

	-- Check Yen
	local CurrencySystem = _G.CurrencySystem
	if not CurrencySystem then return nil, nil, false, "CurrencySystem not loaded" end
	local success, err = CurrencySystem.SpendYen(userId, cost)
	if not success then return nil, nil, false, err end

	-- Calculate total luck
	local luck = (data.baseLuck or 0) + (data.upgrades and data.upgrades.luckBonus or 0)
	if data.luckBoostActive and os.time() < data.luckBoostExpiry then
		luck = luck + 0.5
	end
	if data.gamepasses then
		if data.gamepasses.lucky then luck = luck + 0.25 end
		if data.gamepasses.superLucky then luck = luck + 0.5 end
		if data.gamepasses.ultraLucky then luck = luck + 1.0 end
	end

	-- Roll rarity
	local rarity = FighterData.RollRarity(luck)

	-- Pity check
	local pityData = getPityData(data, worldId)
	rarity = checkPity(pityData, rarity)

	-- Pick fighter from world pool with that rarity
	local worldFighters = FighterData.GetFightersForWorld(worldId)
	local fighterTemplate = FighterData.PickFighter(worldFighters, rarity)
	if not fighterTemplate then
		-- Fallback: return a common fighter
		fighterTemplate = FighterData.PickFighter(worldFighters, "Common")
	end
	if not fighterTemplate then
		return nil, rarity, false, "No fighters in pool"
	end

	-- Roll shiny
	local isShiny = rollShiny(luck)

	-- Create instance
	local instance = createFighterInstance(fighterTemplate, isShiny)

	-- Add to player's fighter list
	if not data.fighters then data.fighters = {} end
	table.insert(data.fighters, instance)
	_G.DataManager.MarkDirty(userId)

	return instance, rarity, isShiny, nil
end

-- ================================================================
-- MULTI PULL (up to 8 stars at once)
-- ================================================================

-- Returns: array of { instance, rarity, isShiny }, error
function GachaSystem.MultiPull(userId, worldId, count)
	count = math.clamp(count or 1, 1, 8)

	local data = _G.DataManager.GetData(userId)
	if not data then return nil, "Data not loaded" end

	-- Max opens from upgrades
	local maxOpens = 1 + (data.upgrades and data.upgrades.extraStarOpens or 0)
	if data.gamepasses and data.gamepasses.multiOpen then
		maxOpens = math.max(maxOpens, 5)
	end
	count = math.min(count, maxOpens)

	local results = {}
	for i = 1, count do
		local instance, rarity, isShiny, err = GachaSystem.Pull(userId, worldId)
		if err then
			-- Ran out of Yen mid-multi — stop early
			break
		end
		table.insert(results, { instance = instance, rarity = rarity, isShiny = isShiny })
	end

	return results, nil
end

-- ================================================================
-- STAR COST INFO (for UI)
-- ================================================================

function GachaSystem.GetStarCost(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	local world = WorldData.GetWorldById(worldId)
	if not world then return 0 end
	local hasVIP = data and data.gamepasses and data.gamepasses.vip
	return getStarCost(world.worldIndex, hasVIP)
end

function GachaSystem.GetPityInfo(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data then return nil end
	return getPityData(data, worldId)
end

return GachaSystem
