-- DailySystem.lua
-- Daily login rewards, streak tracking, and PXP / Rank system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DailySystem = {}

-- ================================================================
-- RANK / PXP TABLE
-- ================================================================

-- Rank unlocks better daily login rewards
local RankThresholds = {
	[1]  = 0,
	[2]  = 1000,
	[3]  = 5000,
	[4]  = 15000,
	[5]  = 40000,
	[6]  = 100000,
	[7]  = 250000,
	[8]  = 600000,
	[9]  = 1500000,
	[10] = 5000000,
}

local function getRankFromPXP(pxp)
	local rank = 1
	for r, threshold in pairs(RankThresholds) do
		if pxp >= threshold and r > rank then
			rank = r
		end
	end
	return rank
end

-- PXP value when sacrificing a fighter from backpack
local function getPXPValue(fighter)
	local FighterData = require(ReplicatedStorage.Data.FighterData)
	local rarityData = FighterData.Rarities[fighter.rarity]
	local tier = rarityData and rarityData.tier or 1
	local base = 100 * (10 ^ (tier - 1))
	if fighter.isShiny then base = base * 5 end
	return math.floor(base)
end

-- ================================================================
-- PXP SYSTEM
-- ================================================================

function DailySystem.SacrificeFighterForPXP(userId, instanceId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	-- Confirm fighter exists
	local fighter, fIdx = nil, nil
	for i, f in ipairs(data.fighters or {}) do
		if f.id == instanceId then fighter = f; fIdx = i; break end
	end
	if not fighter then return false, "Fighter not found" end

	-- Can't sacrifice equipped fighter
	for _, eid in ipairs(data.equippedFighters or {}) do
		if eid == instanceId then return false, "Cannot sacrifice equipped fighter" end
	end

	local pxp = getPXPValue(fighter)

	-- Remove fighter
	table.remove(data.fighters, fIdx)

	-- Add PXP
	data.totalPXP = (data.totalPXP or 0) + pxp

	-- Update rank
	local newRank = getRankFromPXP(data.totalPXP)
	data.rank = newRank

	_G.DataManager.MarkDirty(userId)
	return true, { pxpEarned = pxp, totalPXP = data.totalPXP, rank = newRank }
end

-- ================================================================
-- DAILY LOGIN REWARDS
-- ================================================================

-- Rewards scale with rank
local function getDailyRewards(rank, streak)
	local base = {
		yen = 10000 * rank * (1 + streak * 0.05),
		raidTickets = rank >= 5 and 1 or 0,
		boostChance = rank * 0.05,  -- chance to get a boost
	}
	return base
end

function DailySystem.ClaimDailyLogin(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return false, "Data not loaded" end

	local today = os.date("%Y-%m-%d")
	if data.lastLoginDate == today then
		return false, "Already claimed daily login today"
	end

	-- Update streak
	local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
	if data.lastLoginDate == yesterday then
		data.dailyLoginStreak = (data.dailyLoginStreak or 0) + 1
	else
		data.dailyLoginStreak = 1  -- reset streak
	end

	data.lastLoginDate = today

	-- Calculate rewards
	local rank = data.rank or 1
	local streak = data.dailyLoginStreak or 1
	local rewards = getDailyRewards(rank, streak)

	-- Apply Yen
	_G.CurrencySystem.AddYen(userId, math.floor(rewards.yen))

	-- Apply raid ticket
	if rewards.raidTickets > 0 then
		data.raidTickets = (data.raidTickets or 0) + rewards.raidTickets
	end

	-- Roll for boost
	if math.random() < rewards.boostChance then
		-- Give a random boost
		local boostTypes = { "yen_boost_small", "xp_boost", "luck_boost" }
		local chosen = boostTypes[math.random(1, #boostTypes)]
		-- (Apply boost via ShopSystem._applyBoost if ShopSystem is loaded)
		rewards.bonusBoost = chosen
	end

	_G.DataManager.MarkDirty(userId)

	-- Notify client
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local loginRewardEvent = remotes:FindFirstChild("DailyLoginReward")
			if loginRewardEvent then
				loginRewardEvent:FireClient(player, {
					rewards = rewards,
					streak = streak,
					rank = rank,
				})
			end
		end
	end

	return true, { rewards = rewards, streak = streak }
end

-- ================================================================
-- UPGRADES TAB (Permanent Challenges)
-- ================================================================

local UpgradeChallenges = {
	{
		id = "extra_equip_1",
		name = "Extra Equip Slot I",
		description = "Open 100 Stars total",
		difficulty = "Easy",
		requirement = { type = "stars_opened", count = 100 },
		reward = { type = "extraEquipSlot", amount = 1 },
	},
	{
		id = "extra_star_1",
		name = "Extra Star Open I",
		description = "Defeat 1,000 enemies",
		difficulty = "Easy",
		requirement = { type = "enemies_killed", count = 1000 },
		reward = { type = "extraStarOpen", amount = 1 },
	},
	{
		id = "extra_equip_2",
		name = "Extra Equip Slot II",
		description = "Open 1,000 Stars total",
		difficulty = "Medium",
		requirement = { type = "stars_opened", count = 1000 },
		reward = { type = "extraEquipSlot", amount = 1 },
	},
	{
		id = "extra_star_2",
		name = "Extra Star Open II",
		description = "Defeat 10,000 enemies",
		difficulty = "Medium",
		requirement = { type = "enemies_killed", count = 10000 },
		reward = { type = "extraStarOpen", amount = 1 },
	},
	{
		id = "luck_upgrade_1",
		name = "Lucky Challenger I",
		description = "Complete 3 world questlines",
		difficulty = "Hard",
		requirement = { type = "badges_earned", count = 3 },
		reward = { type = "luckBonus", amount = 0.1 },
	},
	{
		id = "extra_equip_3",
		name = "Extra Equip Slot III",
		description = "Reach max level on any fighter",
		difficulty = "Super Hard",
		requirement = { type = "max_level_fighters", count = 1 },
		reward = { type = "extraEquipSlot", amount = 1 },
	},
}

function DailySystem.CheckUpgradeChallenges(userId)
	local data = _G.DataManager.GetData(userId)
	if not data then return end

	for _, challenge in ipairs(UpgradeChallenges) do
		-- Skip already completed
		local already = false
		for _, cid in ipairs(data.upgradesChallengesCompleted or {}) do
			if cid == challenge.id then already = true; break end
		end
		if not already then
			local met = DailySystem._checkRequirement(data, challenge.requirement)
			if met then
				DailySystem._grantUpgradeReward(userId, data, challenge)
			end
		end
	end
end

function DailySystem._checkRequirement(data, req)
	if req.type == "stars_opened" then
		return (data.totalStarsOpened or 0) >= req.count
	elseif req.type == "enemies_killed" then
		return (data.totalEnemiesKilled or 0) >= req.count
	elseif req.type == "badges_earned" then
		return #(data.worldBadgesEarned or {}) >= req.count
	elseif req.type == "max_level_fighters" then
		local count = 0
		for _, f in ipairs(data.fighters or {}) do
			if f.level >= 440 then count = count + 1 end
		end
		return count >= req.count
	end
	return false
end

function DailySystem._grantUpgradeReward(userId, data, challenge)
	if not data.upgradesChallengesCompleted then data.upgradesChallengesCompleted = {} end
	table.insert(data.upgradesChallengesCompleted, challenge.id)

	local reward = challenge.reward
	if not data.upgrades then data.upgrades = {} end

	if reward.type == "extraEquipSlot" then
		data.upgrades.extraEquipSlots = (data.upgrades.extraEquipSlots or 0) + reward.amount
	elseif reward.type == "extraStarOpen" then
		data.upgrades.extraStarOpens = (data.upgrades.extraStarOpens or 0) + reward.amount
	elseif reward.type == "luckBonus" then
		data.upgrades.luckBonus = (data.upgrades.luckBonus or 0) + reward.amount
		data.baseLuck = (data.baseLuck or 0) + reward.amount
	end

	_G.DataManager.MarkDirty(userId)

	-- Notify client
	local player = game:GetService("Players"):GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local upgradeEvent = remotes:FindFirstChild("UpgradeChallengeCompleted")
			if upgradeEvent then
				upgradeEvent:FireClient(player, { challengeId = challenge.id, reward = reward })
			end
		end
	end
end

return DailySystem
