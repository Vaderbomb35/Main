-- PlayerDataTemplate.lua
-- Default data structure saved per player in DataStore

local PlayerDataTemplate = {}

function PlayerDataTemplate.New()
	return {
		-- === CURRENCY ===
		yen = 0,
		robux = 0,  -- tracked for reference only; actual Robux handled by Roblox

		-- === PROGRESSION ===
		currentWorldIndex = 1,
		unlockedWorlds = { "super_island" },
		classIndex = 1,        -- 1 = Fighter
		totalPXP = 0,          -- Player Experience Points for Rank
		rank = 1,

		-- === STATS (for class unlock requirements) ===
		stats = {
			strength  = 0,
			durability = 0,
			chakra    = 0,
		},

		-- === FIGHTERS ===
		-- Each entry: { id, fighterId, rarity, worldId, level, exp, isShiny, passive, passiveSlotUnlocked }
		fighters = {},
		equippedFighters = {},   -- array of fighter instance IDs (max 3–5)
		maxEquipSlots = 3,

		-- === GACHA / PITY ===
		-- Per-world pity counters
		-- worldPity[worldId] = { pullsSinceLastLegendary, pullsSinceLastMythical, isInMythicalCycle }
		worldPity = {},

		-- === LUCK ===
		baseLuck = 0,            -- from Upgrades tab milestones
		luckBoostActive = false,
		luckBoostExpiry = 0,     -- Unix timestamp

		-- === BOOSTS ===
		activeBoosts = {
			-- { type = "yen"|"xp"|"luck"|"drop", multiplier, expiresAt }
		},

		-- === QUESTS ===
		-- Per-world quest progress
		-- questProgress[worldId] = { completedQuests = {}, currentQuestIndex = 1, enemiesKilled = 0 }
		questProgress = {},

		-- === RAIDS ===
		raidTickets = 3,         -- start with 3 tickets
		lastRaidTicketGrant = 0, -- timestamp for daily ticket refresh

		-- === TIME TRIALS ===
		ttShards = 0,
		bestTimeTrialTimes = {}, -- [roomId] = bestTimeSeconds

		-- === DEFENSE MODE ===
		defenseTokens = 0,
		maxOpenTokens = 0,       -- tokens from Defense Mode for better star opens

		-- === TRADING ===
		hasTradingLicense = false,

		-- === INCUBATOR ===
		-- incubatorSlots[worldId] = { fighterId, placedAt } (one fighter per incubator world)
		incubatorSlots = {},

		-- === SHARDS ===
		-- shards[worldId] = count
		shards = {},

		-- === UPGRADES TAB ===
		-- Permanent upgrades unlocked
		upgrades = {
			extraEquipSlots = 0,    -- bonus equip slots beyond base 3
			extraStarOpens  = 0,    -- bonus multi-opens (base 1, max +7)
			yenMultiplier   = 1.0,  -- from world badge completions
			luckMultiplier  = 1.0,
		},
		worldBadgesEarned = {},     -- list of worldIds where full questline completed
		upgradesChallengesCompleted = {},

		-- === DAILY SYSTEMS ===
		lastLoginDate = "",         -- "YYYY-MM-DD" for daily login reward
		dailyLoginStreak = 0,
		lastDailySpin = 0,          -- timestamp

		-- === BATTLE PASS ===
		battlePassTier = 0,
		battlePassXP = 0,
		battlePassOwned = false,    -- paid tier
		battlePassQuestsCompleted = {},

		-- === COSMETICS ===
		equippedMount = nil,
		ownedMounts = {},
		equippedAura = nil,
		ownedAuras = {},

		-- === GAMEPASSES ===
		-- Stored locally for reference; authoritative check done server-side via MarketplaceService
		gamepasses = {
			autoAttack     = false,
			doubleDrops    = false,
			magnet         = false,
			megaBackpack   = false,
			lucky          = false,
			superLucky     = false,
			ultraLucky     = false,
			teleport       = false,
			vip            = false,
			multiOpen      = false,
			halfCooldown   = false,
			fastOpen       = false,
			extraEquip     = false,
			passive        = false,
			instantPassive = false,
		},

		-- === METADATA ===
		totalPlaytime = 0,          -- seconds
		firstJoinDate = "",
		version = 1,
	}
end

-- Migrate old data to new template (add missing keys with defaults)
function PlayerDataTemplate.Migrate(data)
	local template = PlayerDataTemplate.New()
	for key, default in pairs(template) do
		if data[key] == nil then
			data[key] = default
		end
	end
	-- Nested migration
	if data.stats then
		for k, v in pairs(template.stats) do
			if data.stats[k] == nil then data.stats[k] = v end
		end
	end
	if data.upgrades then
		for k, v in pairs(template.upgrades) do
			if data.upgrades[k] == nil then data.upgrades[k] = v end
		end
	end
	if data.gamepasses then
		for k, v in pairs(template.gamepasses) do
			if data.gamepasses[k] == nil then data.gamepasses[k] = v end
		end
	end
	return data
end

return PlayerDataTemplate
