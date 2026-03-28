-- FighterData.lua
-- Defines all fighters: rarities, base damage, world origin, ultimate ability

local FighterData = {}

-- Rarity tiers with base damage multipliers and drop weights
FighterData.Rarities = {
	Common    = { tier = 1, damageMultiplier = 1.0,    weight = 500,  color = Color3.fromRGB(180, 180, 180), glowColor = Color3.fromRGB(200,200,200) },
	Rare      = { tier = 2, damageMultiplier = 2.5,    weight = 300,  color = Color3.fromRGB(0, 120, 255),   glowColor = Color3.fromRGB(50,150,255) },
	Epic      = { tier = 3, damageMultiplier = 6.0,    weight = 150,  color = Color3.fromRGB(120, 0, 200),   glowColor = Color3.fromRGB(160,50,255) },
	Legendary = { tier = 4, damageMultiplier = 15.0,   weight = 40,   color = Color3.fromRGB(255, 165, 0),   glowColor = Color3.fromRGB(255,200,50) },
	Mythical  = { tier = 5, damageMultiplier = 40.0,   weight = 9,    color = Color3.fromRGB(255, 50, 50),   glowColor = Color3.fromRGB(255,100,100) },
	Crafted   = { tier = 6, damageMultiplier = 100.0,  weight = 0,    color = Color3.fromRGB(0, 255, 200),   glowColor = Color3.fromRGB(50,255,220) },
	Secret    = { tier = 7, damageMultiplier = 300.0,  weight = 1,    color = Color3.fromRGB(255, 215, 0),   glowColor = Color3.fromRGB(255,240,100) },
	Divine    = { tier = 8, damageMultiplier = 1000.0, weight = 0.01, color = Color3.fromRGB(255, 255, 255), glowColor = Color3.fromRGB(180,255,255) },
}

-- Pity system constants
FighterData.Pity = {
	LegendaryPity = 80,    -- guaranteed Legendary after N pulls without one
	MythicalPity  = 4000,  -- guaranteed Mythical after N pulls in Mythical pity cycle
	-- Secret and Divine: NO pity
}

-- Base EXP required per level (scales quadratically)
-- Total EXP to reach level N = sum of EXP(1..N-1)
function FighterData.GetExpForLevel(level)
	-- Base: 100 EXP for level 1, scales by 1.05 per level
	return math.floor(100 * (1.05 ^ (level - 1)))
end

-- Base damage formula: rarity multiplier * worldMultiplier * (1 + level * 0.02)
function FighterData.CalculateDamage(fighter, level)
	local rarityData = FighterData.Rarities[fighter.rarity]
	if not rarityData then return 0 end
	local worldMult = fighter.worldIndex * 1.5
	local levelMult = 1 + (level * 0.02)
	return math.floor(rarityData.damageMultiplier * worldMult * levelMult * 10)
end

-- All fighters keyed by id
-- Structure: id, name, rarity, worldId, worldIndex, ultimate, baseImageId, isShiny (runtime)
FighterData.Fighters = {
	-- ============ SUPER ISLAND ============
	Goku_SSJ = {
		id = "Goku_SSJ", name = "Super Saiyan Goku",
		rarity = "Legendary", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Kamehameha", damage = 5.0, cooldown = 12 },
		baseImageId = "rbxassetid://0",
	},
	Naruto_Base = {
		id = "Naruto_Base", name = "Naruto Uzumaki",
		rarity = "Rare", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Rasengan", damage = 2.0, cooldown = 8 },
		baseImageId = "rbxassetid://0",
	},
	Ichigo_Base = {
		id = "Ichigo_Base", name = "Ichigo Kurosaki",
		rarity = "Rare", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Getsuga Tensho", damage = 2.2, cooldown = 9 },
		baseImageId = "rbxassetid://0",
	},
	Luffy_Base = {
		id = "Luffy_Base", name = "Monkey D. Luffy",
		rarity = "Common", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Gum Gum Pistol", damage = 1.5, cooldown = 6 },
		baseImageId = "rbxassetid://0",
	},
	Vegeta_Base = {
		id = "Vegeta_Base", name = "Prince Vegeta",
		rarity = "Epic", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Galick Gun", damage = 3.0, cooldown = 10 },
		baseImageId = "rbxassetid://0",
	},
	Sasuke_Base = {
		id = "Sasuke_Base", name = "Sasuke Uchiha",
		rarity = "Rare", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Chidori", damage = 2.3, cooldown = 8 },
		baseImageId = "rbxassetid://0",
	},
	Zoro_Base = {
		id = "Zoro_Base", name = "Roronoa Zoro",
		rarity = "Epic", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Three Sword Style", damage = 3.2, cooldown = 11 },
		baseImageId = "rbxassetid://0",
	},
	Saitama_Casual = {
		id = "Saitama_Casual", name = "Saitama",
		rarity = "Mythical", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Serious Punch", damage = 20.0, cooldown = 30 },
		baseImageId = "rbxassetid://0",
	},
	Goku_UI = {
		id = "Goku_UI", name = "Ultra Instinct Goku",
		rarity = "Crafted", worldId = "super_island", worldIndex = 1,
		ultimate = { name = "Ultra Instinct Strike", damage = 50.0, cooldown = 25 },
		baseImageId = "rbxassetid://0",
		isCrafted = true,
		craftRequirements = {
			mythicals = 3, worldId = "super_island", shardsRequired = 5
		},
	},

	-- ============ NINJA VILLAGE ============
	Naruto_KCM = {
		id = "Naruto_KCM", name = "Kyuubi Chakra Mode Naruto",
		rarity = "Epic", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Bijuudama", damage = 4.5, cooldown = 12 },
		baseImageId = "rbxassetid://0",
	},
	Sasuke_CS2 = {
		id = "Sasuke_CS2", name = "Cursed Seal Sasuke",
		rarity = "Rare", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Kirin", damage = 3.5, cooldown = 10 },
		baseImageId = "rbxassetid://0",
	},
	Kakashi_Mangekyo = {
		id = "Kakashi_Mangekyo", name = "Kakashi Mangekyo",
		rarity = "Legendary", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Kamui", damage = 8.0, cooldown = 15 },
		baseImageId = "rbxassetid://0",
	},
	Itachi_Akatsuki = {
		id = "Itachi_Akatsuki", name = "Itachi Uchiha",
		rarity = "Legendary", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Amaterasu", damage = 9.0, cooldown = 18 },
		baseImageId = "rbxassetid://0",
	},
	Pain_Deva = {
		id = "Pain_Deva", name = "Pain (Deva Path)",
		rarity = "Mythical", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Shinra Tensei", damage = 25.0, cooldown = 30 },
		baseImageId = "rbxassetid://0",
	},
	Jiraiya_Sage = {
		id = "Jiraiya_Sage", name = "Sage Jiraiya",
		rarity = "Epic", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Sage Mode Rasengan", damage = 5.0, cooldown = 13 },
		baseImageId = "rbxassetid://0",
	},
	Minato_Teleport = {
		id = "Minato_Teleport", name = "Minato Namikaze",
		rarity = "Legendary", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Flying Raijin", damage = 10.0, cooldown = 16 },
		baseImageId = "rbxassetid://0",
	},
	Madara_Rinnegan = {
		id = "Madara_Rinnegan", name = "Madara Rinnegan",
		rarity = "Secret", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Infinite Tsukuyomi", damage = 100.0, cooldown = 60 },
		baseImageId = "rbxassetid://0",
	},
	Naruto_Baryon = {
		id = "Naruto_Baryon", name = "Baryon Mode Naruto",
		rarity = "Crafted", worldId = "ninja_village", worldIndex = 2,
		ultimate = { name = "Baryon Charge", damage = 80.0, cooldown = 25 },
		baseImageId = "rbxassetid://0",
		isCrafted = true,
		craftRequirements = {
			mythicals = 3, worldId = "ninja_village", shardsRequired = 5
		},
	},

	-- ============ CRAZY TOWN ============
	Luffy_Gear2 = {
		id = "Luffy_Gear2", name = "Gear 2nd Luffy",
		rarity = "Rare", worldId = "crazy_town", worldIndex = 3,
		ultimate = { name = "Jet Pistol", damage = 5.0, cooldown = 8 },
		baseImageId = "rbxassetid://0",
	},
	Luffy_Gear5 = {
		id = "Luffy_Gear5", name = "Gear 5th Luffy",
		rarity = "Crafted", worldId = "crazy_town", worldIndex = 3,
		ultimate = { name = "Gomu Gomu no Dawn", damage = 120.0, cooldown = 25 },
		baseImageId = "rbxassetid://0",
		isCrafted = true,
		craftRequirements = {
			mythicals = 3, worldId = "crazy_town", shardsRequired = 5
		},
	},

	-- ============ HERO UNIVERSITY ============
	Deku_FullCowl = {
		id = "Deku_FullCowl", name = "Full Cowl Deku",
		rarity = "Rare", worldId = "hero_university", worldIndex = 5,
		ultimate = { name = "Delaware Smash", damage = 7.0, cooldown = 9 },
		baseImageId = "rbxassetid://0",
	},
	AllMight_Prime = {
		id = "AllMight_Prime", name = "All Might (Prime)",
		rarity = "Mythical", worldId = "hero_university", worldIndex = 5,
		ultimate = { name = "United States of Smash", damage = 40.0, cooldown = 30 },
		baseImageId = "rbxassetid://0",
	},
	Deku_OneForAll100 = {
		id = "Deku_OneForAll100", name = "100% OFA Deku",
		rarity = "Crafted", worldId = "hero_university", worldIndex = 5,
		ultimate = { name = "One For All 100%", damage = 160.0, cooldown = 25 },
		baseImageId = "rbxassetid://0",
		isCrafted = true,
		craftRequirements = {
			mythicals = 3, worldId = "hero_university", shardsRequired = 5
		},
	},

	-- ============ SLAYER ARMY ============
	Tanjiro_Water = {
		id = "Tanjiro_Water", name = "Tanjiro (Water Breath)",
		rarity = "Rare", worldId = "slayer_army", worldIndex = 7,
		ultimate = { name = "Total Concentration", damage = 12.0, cooldown = 10 },
		baseImageId = "rbxassetid://0",
	},
	Rengoku_Flame = {
		id = "Rengoku_Flame", name = "Flame Hashira Rengoku",
		rarity = "Legendary", worldId = "slayer_army", worldIndex = 7,
		ultimate = { name = "Ninth Form: Rengoku", damage = 30.0, cooldown = 20 },
		baseImageId = "rbxassetid://0",
	},
	Tanjiro_SunBreath = {
		id = "Tanjiro_SunBreath", name = "Sun Breath Tanjiro",
		rarity = "Crafted", worldId = "slayer_army", worldIndex = 7,
		ultimate = { name = "Thirteenth Form", damage = 210.0, cooldown = 25 },
		baseImageId = "rbxassetid://0",
		isCrafted = true,
		craftRequirements = {
			mythicals = 3, worldId = "slayer_army", shardsRequired = 5
		},
	},
}

-- Get all fighters belonging to a world
function FighterData.GetFightersForWorld(worldId)
	local result = {}
	for _, fighter in pairs(FighterData.Fighters) do
		if fighter.worldId == worldId then
			table.insert(result, fighter)
		end
	end
	return result
end

-- Weighted random rarity pick (used by gacha system)
function FighterData.RollRarity(luck)
	luck = luck or 0
	-- luck shifts weight from lower tiers to higher tiers slightly
	local weights = {}
	local totalWeight = 0

	for rarity, data in pairs(FighterData.Rarities) do
		if data.weight > 0 then
			local adjusted = data.weight * (1 + luck * 0.01)
			-- Higher rarities benefit more from luck
			if data.tier >= 5 then
				adjusted = adjusted * (1 + luck * 0.05)
			end
			weights[rarity] = adjusted
			totalWeight = totalWeight + adjusted
		end
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	-- Sort by tier ascending so we check low rarities first
	local sorted = {}
	for rarity, w in pairs(weights) do
		table.insert(sorted, { rarity = rarity, weight = w, tier = FighterData.Rarities[rarity].tier })
	end
	table.sort(sorted, function(a, b) return a.tier < b.tier end)

	for _, entry in ipairs(sorted) do
		cumulative = cumulative + entry.weight
		if roll <= cumulative then
			return entry.rarity
		end
	end

	return "Common"
end

-- Pick a random fighter from a world given a rarity
function FighterData.PickFighter(worldFighters, rarity)
	local pool = {}
	for _, f in ipairs(worldFighters) do
		if f.rarity == rarity and not f.isCrafted then
			table.insert(pool, f)
		end
	end
	if #pool == 0 then
		-- Fallback: pick any non-crafted fighter
		for _, f in ipairs(worldFighters) do
			if not f.isCrafted then
				table.insert(pool, f)
			end
		end
	end
	if #pool == 0 then return nil end
	return pool[math.random(1, #pool)]
end

return FighterData
