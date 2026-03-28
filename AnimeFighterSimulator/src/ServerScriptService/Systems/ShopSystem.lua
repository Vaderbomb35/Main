-- ShopSystem.lua
-- Handles the Merchant NPC shop, Time Trial shop, boosts, and gamepass checks

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FighterData = require(ReplicatedStorage.Data.FighterData)
local WorldData = require(ReplicatedStorage.Data.WorldData)

local ShopSystem = {}

-- ================================================================
-- GAMEPASS IDS (replace with real IDs before publishing)
-- ================================================================
local GAMEPASS_IDS = {
	autoAttack     = 0,  -- replace with real gamepass IDs
	doubleDrops    = 0,
	magnet         = 0,
	megaBackpack   = 0,
	lucky          = 0,
	superLucky     = 0,
	ultraLucky     = 0,
	teleport       = 0,
	vip            = 0,
	multiOpen      = 0,
	halfCooldown   = 0,
	fastOpen       = 0,
	extraEquip     = 0,
	passive        = 0,
	instantPassive = 0,
}

-- ================================================================
-- BOOST CATALOG
-- ================================================================
local BoostCatalog = {
	yen_boost_small = {
		id = "yen_boost_small",
		name = "Yen Boost (1 hour)",
		type = "yen",
		multiplier = 2.0,
		duration = 3600,
		yenCost = 0,
		robuxCost = 50,
	},
	yen_boost_medium = {
		id = "yen_boost_medium",
		name = "Yen Boost (3 hours)",
		type = "yen",
		multiplier = 2.0,
		duration = 10800,
		yenCost = 0,
		robuxCost = 100,
	},
	xp_boost = {
		id = "xp_boost",
		name = "2x XP Boost (1 hour)",
		type = "xp",
		multiplier = 2.0,
		duration = 3600,
		yenCost = 0,
		robuxCost = 50,
	},
	luck_boost = {
		id = "luck_boost",
		name = "Luck Boost (30 min)",
		type = "luck",
		multiplier = 2.0,  -- 2x luck
		duration = 1800,
		yenCost = 0,
		robuxCost = 75,
	},
	drop_boost = {
		id = "drop_boost",
		name = "2x Drop Boost (1 hour)",
		type = "drop",
		multiplier = 2.0,
		duration = 3600,
		yenCost = 0,
		robuxCost = 50,
	},
}

-- ================================================================
-- MERCHANT NPC
-- ================================================================

-- Merchant inventory rotates daily
local merchantInventory = {}
local merchantLastRotation = 0
local MERCHANT_ROTATION_INTERVAL = 86400  -- 24 hours

local function rotateeMerchantInventory()
	merchantInventory = {}

	-- Pick 2 random Mythical fighters from random worlds
	local worldCount = WorldData.GetWorldCount()
	for _ = 1, 2 do
		local worldIdx = math.random(1, worldCount)
		local world = WorldData.GetWorldByIndex(worldIdx)
		if world then
			local fighters = FighterData.GetFightersForWorld(world.id)
			local mythicals = {}
			for _, f in ipairs(fighters) do
				if f.rarity == "Mythical" then table.insert(mythicals, f) end
			end
			if #mythicals > 0 then
				local chosen = mythicals[math.random(1, #mythicals)]
				table.insert(merchantInventory, {
					type = "fighter",
					fighter = chosen,
					cost = math.floor(1e12 * (world.worldIndex * 0.5)),  -- Yen cost
					robuxCost = 299,
				})
			end
		end
	end

	-- Pick 1 Secret fighter (rare find)
	if math.random(1, 3) == 1 then
		local worldIdx = math.random(1, math.min(4, worldCount))
		local world = WorldData.GetWorldByIndex(worldIdx)
		if world then
			local fighters = FighterData.GetFightersForWorld(world.id)
			local secrets = {}
			for _, f in ipairs(fighters) do
				if f.rarity == "Secret" then table.insert(secrets, f) end
			end
			if #secrets > 0 then
				local chosen = secrets[math.random(1, #secrets)]
				table.insert(merchantInventory, {
					type = "fighter",
					fighter = chosen,
					cost = math.floor(1e15 * world.worldIndex),
					robuxCost = 799,
				})
			end
		end
	end

	-- Add some boosts
	table.insert(merchantInventory, {
		type = "boost",
		boost = BoostCatalog.yen_boost_small,
		cost = 0,
		isFreeItem = true,  -- one free boost per merchant visit
	})

	merchantLastRotation = os.time()
end

-- Initialize merchant
rotateeMerchantInventory()

function ShopSystem.GetMerchantInventory()
	if (os.time() - merchantLastRotation) >= MERCHANT_ROTATION_INTERVAL then
		rotateeMerchantInventory()
	end
	return merchantInventory
end

function ShopSystem.BuyFromMerchant(userId, itemIndex)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	if (os.time() - merchantLastRotation) >= MERCHANT_ROTATION_INTERVAL then
		rotateeMerchantInventory()
	end

	local item = merchantInventory[itemIndex]
	if not item then return false, "Item not found" end

	if item.isFreeItem then
		-- Grant free boost once per rotation (tracked in player data)
		local key = "merchant_free_" .. tostring(merchantLastRotation)
		if not data.merchantFreeItemsCollected then data.merchantFreeItemsCollected = {} end
		if data.merchantFreeItemsCollected[key] then
			return false, "Already collected free item this rotation"
		end
		data.merchantFreeItemsCollected[key] = true
		-- Apply boost
		if item.boost then
			ShopSystem._applyBoost(userId, item.boost)
		end
		_G.DataManager.MarkDirty(userId)
		return true, nil
	end

	-- Yen purchase
	if item.cost > 0 then
		local ok, err = _G.CurrencySystem.SpendYen(userId, item.cost)
		if not ok then return false, err end
	end

	-- Grant fighter
	if item.type == "fighter" and item.fighter then
		if not data.fighters then data.fighters = {} end
		local instanceId = tostring(os.time()) .. "_merchant_" .. tostring(math.random(10000, 99999))
		table.insert(data.fighters, {
			id = instanceId,
			fighterId = item.fighter.id,
			name = item.fighter.name,
			rarity = item.fighter.rarity,
			worldId = item.fighter.worldId,
			worldIndex = item.fighter.worldIndex,
			level = 1,
			exp = 0,
			isShiny = false,
			passive = nil,
			passiveSlotUnlocked = false,
		})
		_G.DataManager.MarkDirty(userId)
		return true, { type = "fighter", fighterId = item.fighter.id }
	end

	-- Grant boost
	if item.type == "boost" and item.boost then
		ShopSystem._applyBoost(userId, item.boost)
		return true, { type = "boost", boostId = item.boost.id }
	end

	return false, "Unknown item type"
end

-- ================================================================
-- TIME TRIAL SHOP
-- ================================================================

local TimeTrialShopItems = {
	trading_license = {
		id = "trading_license",
		name = "Trading License",
		ttShardCost = 1000,
		description = "Unlocks the ability to trade with other players",
	},
	defense_token = {
		id = "defense_token",
		name = "Defense Token",
		ttShardCost = 500,
		description = "Enter Defense Mode to earn Max Open Tokens",
	},
	raid_ticket = {
		id = "raid_ticket",
		name = "Raid Ticket",
		ttShardCost = 80,
		description = "Enter the next Raid",
	},
	yen_boost = {
		id = "yen_boost",
		name = "Yen Boost (1hr)",
		ttShardCost = 200,
		description = "2x Yen for 1 hour",
	},
}

function ShopSystem.BuyFromTimeTrialShop(userId, itemId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local item = TimeTrialShopItems[itemId]
	if not item then return false, "Item not found in TT Shop" end

	local ok, err = _G.CurrencySystem.SpendTTShards(userId, item.ttShardCost)
	if not ok then return false, err end

	if itemId == "trading_license" then
		data.hasTradingLicense = true
	elseif itemId == "defense_token" then
		data.defenseTokens = (data.defenseTokens or 0) + 1
	elseif itemId == "raid_ticket" then
		data.raidTickets = (data.raidTickets or 0) + 1
	elseif itemId == "yen_boost" then
		ShopSystem._applyBoost(userId, BoostCatalog.yen_boost_small)
	end

	_G.DataManager.MarkDirty(userId)
	return true, nil
end

function ShopSystem.GetTimeTrialShopItems()
	return TimeTrialShopItems
end

-- ================================================================
-- BOOST APPLICATION
-- ================================================================

function ShopSystem._applyBoost(userId, boostData)
	local data = _G.DataManager.GetData(userId)
	if not data then return end

	if not data.activeBoosts then data.activeBoosts = {} end

	-- Check for existing boost of same type — extend duration
	local now = os.time()
	for _, boost in ipairs(data.activeBoosts) do
		if boost.type == boostData.type then
			-- Boosts don't tick while offline — extend from current expiry
			boost.expiresAt = math.max(boost.expiresAt, now) + boostData.duration
			_G.DataManager.MarkDirty(userId)
			return
		end
	end

	-- New boost
	table.insert(data.activeBoosts, {
		type = boostData.type,
		multiplier = boostData.multiplier,
		expiresAt = now + boostData.duration,
	})
	_G.DataManager.MarkDirty(userId)
end

-- ================================================================
-- GAMEPASS VERIFICATION
-- ================================================================

-- Check if player owns a gamepass (server-authoritative)
function ShopSystem.CheckGamepass(userId, passName)
	local passId = GAMEPASS_IDS[passName]
	if not passId or passId == 0 then return false end  -- ID not set

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
	end)

	return success and owns
end

-- Sync all gamepasses for a player on join
function ShopSystem.SyncGamepasses(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return end
	if not data.gamepasses then data.gamepasses = {} end

	for passName, _ in pairs(GAMEPASS_IDS) do
		data.gamepasses[passName] = ShopSystem.CheckGamepass(userId, passName)
	end

	-- Apply gamepass bonuses (e.g., extra equip slot)
	if data.gamepasses.extraEquip and not data._extraEquipApplied then
		data._extraEquipApplied = true
		-- Handled by reading gamepasses.extraEquip in FighterSystem
	end

	_G.DataManager.MarkDirty(userId)
end

-- Called by MarketplaceService.PromptGamePassPurchaseFinished
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then return end

	local userId = player.UserId
	-- Find which pass was purchased
	for passName, passId in pairs(GAMEPASS_IDS) do
		if passId == gamePassId then
			local data = _G.DataManager.GetData(userId)
			if data and data.gamepasses then
				data.gamepasses[passName] = true
				_G.DataManager.MarkDirty(userId)
			end
			break
		end
	end
end)

-- ================================================================
-- DAILY SPIN
-- ================================================================

local DailySpinRewards = {
	{ weight = 500, type = "yen_boost",      reward = { boostId = "yen_boost_small" } },
	{ weight = 300, type = "xp_boost",       reward = { boostId = "xp_boost" } },
	{ weight = 150, type = "luck_boost",     reward = { boostId = "luck_boost" } },
	{ weight = 100, type = "raid_ticket",    reward = { count = 1 } },
	{ weight = 17,  type = "defense_token",  reward = { count = 1 } },  -- 1.7% chance
	{ weight = 5,   type = "yen",            reward = { amount = 1000000 } },
}

function ShopSystem.ClaimDailySpin(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local now = os.time()
	local cooldown = 86400  -- 24 hours
	if (now - (data.lastDailySpin or 0)) < cooldown then
		local remaining = cooldown - (now - data.lastDailySpin)
		return false, "Daily spin available in " .. math.ceil(remaining / 3600) .. " hours"
	end

	-- Roll
	local totalWeight = 0
	for _, r in ipairs(DailySpinRewards) do totalWeight = totalWeight + r.weight end

	local roll = math.random() * totalWeight
	local cum = 0
	local chosen = DailySpinRewards[1]

	for _, r in ipairs(DailySpinRewards) do
		cum = cum + r.weight
		if roll <= cum then chosen = r; break end
	end

	-- Apply reward
	if chosen.type == "yen_boost" then
		ShopSystem._applyBoost(userId, BoostCatalog.yen_boost_small)
	elseif chosen.type == "xp_boost" then
		ShopSystem._applyBoost(userId, BoostCatalog.xp_boost)
	elseif chosen.type == "luck_boost" then
		ShopSystem._applyBoost(userId, BoostCatalog.luck_boost)
	elseif chosen.type == "raid_ticket" then
		data.raidTickets = (data.raidTickets or 0) + chosen.reward.count
	elseif chosen.type == "defense_token" then
		data.defenseTokens = (data.defenseTokens or 0) + chosen.reward.count
	elseif chosen.type == "yen" then
		_G.CurrencySystem.AddYen(userId, chosen.reward.amount)
	end

	data.lastDailySpin = now
	_G.DataManager.MarkDirty(userId)

	return true, { rewardType = chosen.type, reward = chosen.reward }
end

-- ================================================================
-- CODE REDEMPTION
-- ================================================================

local VALID_CODES = {
	["ANIMEFIGHTERS2025"] = { yen = 500000, raidTickets = 2, alreadyUsed = {} },
	["WELCOME100K"]       = { yen = 1000000, alreadyUsed = {} },
	["FREEBOOST"]         = { boostId = "yen_boost_small", alreadyUsed = {} },
}

function ShopSystem.RedeemCode(userId, code)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local codeData = VALID_CODES[string.upper(code)]
	if not codeData then return false, "Invalid or expired code" end

	-- Check if already redeemed
	if codeData.alreadyUsed[tostring(userId)] then
		return false, "Code already redeemed"
	end

	-- Apply rewards
	if codeData.yen then _G.CurrencySystem.AddYen(userId, codeData.yen) end
	if codeData.raidTickets then
		data.raidTickets = (data.raidTickets or 0) + codeData.raidTickets
	end
	if codeData.boostId then
		ShopSystem._applyBoost(userId, BoostCatalog[codeData.boostId])
	end

	codeData.alreadyUsed[tostring(userId)] = true
	_G.DataManager.MarkDirty(userId)

	return true, { rewards = codeData }
end

return ShopSystem
