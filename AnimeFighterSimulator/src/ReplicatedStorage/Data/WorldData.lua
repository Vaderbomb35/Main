-- WorldData.lua
-- Defines all worlds, their unlock costs, enemies, and boss data

local WorldData = {}

-- World template structure:
-- id, name, unlockCost (Yen), minDamage (to farm), bossHealth, bossYen, enemyYen, shardType, worldIndex
WorldData.Worlds = {
	[1] = {
		id = "super_island",
		name = "Super Island",
		unlockCost = 0,
		minDamageRecommended = 0,
		bossHealth = 500,
		bossYenReward = 1000,
		enemyYenReward = 10,
		shardType = "SuperShard",
		fighterPool = {
			"Goku_SSJ", "Naruto_Base", "Ichigo_Base", "Luffy_Base",
			"Vegeta_Base", "Sasuke_Base", "Zoro_Base", "Saitama_Casual"
		},
		craftedFighter = "Goku_UI",
		questCount = 5,
		worldIndex = 1,
		theme = "Dragon Ball / Naruto / One Piece crossover",
		spawnPositions = {
			CFrame = {0, 10, 0},
		},
	},
	[2] = {
		id = "ninja_village",
		name = "Ninja Village",
		unlockCost = 50000,
		minDamageRecommended = 500,
		bossHealth = 5000,
		bossYenReward = 10000,
		enemyYenReward = 100,
		shardType = "NinjaShard",
		fighterPool = {
			"Naruto_KCM", "Sasuke_CS2", "Kakashi_Mangekyo", "Itachi_Akatsuki",
			"Pain_Deva", "Jiraiya_Sage", "Minato_Teleport", "Madara_Rinnegan"
		},
		craftedFighter = "Naruto_Baryon",
		questCount = 5,
		worldIndex = 2,
		theme = "Naruto",
	},
	[3] = {
		id = "crazy_town",
		name = "Crazy Town",
		unlockCost = 500000,
		minDamageRecommended = 5000,
		bossHealth = 50000,
		bossYenReward = 100000,
		enemyYenReward = 1000,
		shardType = "CrazyShard",
		fighterPool = {
			"Luffy_Gear2", "Zoro_3Sword", "Sanji_Diable", "Nami_Climatact",
			"Usopp_Sniper", "Chopper_Monster", "Robin_Clutch", "Franky_Radical"
		},
		craftedFighter = "Luffy_Gear5",
		questCount = 5,
		worldIndex = 3,
		theme = "One Piece",
		hasDefenseMode = true,
	},
	[4] = {
		id = "fruit_island",
		name = "Fruit Island",
		unlockCost = 5000000,
		minDamageRecommended = 50000,
		bossHealth = 500000,
		bossYenReward = 1000000,
		enemyYenReward = 10000,
		shardType = "FruitShard",
		fighterPool = {
			"Blackbeard_Dark", "Whitebeard_Quake", "Roger_Gold", "Shanks_Haki",
			"Ace_Mera", "Sabo_Mera2", "Law_Ope", "Hancock_Love"
		},
		craftedFighter = "Joyboy_Drums",
		questCount = 5,
		worldIndex = 4,
		theme = "One Piece - Paramecia",
	},
	[5] = {
		id = "hero_university",
		name = "Hero University",
		unlockCost = 50000000,
		minDamageRecommended = 500000,
		bossHealth = 5000000,
		bossYenReward = 10000000,
		enemyYenReward = 100000,
		shardType = "HeroShard",
		fighterPool = {
			"Deku_FullCowl", "Bakugo_Explosion", "Todoroki_HalfCold", "AllMight_Prime",
			"Endeavor_Flame", "Hawks_Feather", "Mirio_Permeation", "Aizawa_Erasure"
		},
		craftedFighter = "Deku_OneForAll100",
		questCount = 5,
		worldIndex = 5,
		theme = "My Hero Academia",
		hasPassiveRerollMachine = true,
	},
	[6] = {
		id = "wall_city",
		name = "Wall City",
		unlockCost = 500000000,
		minDamageRecommended = 5000000,
		bossHealth = 50000000,
		bossYenReward = 100000000,
		enemyYenReward = 1000000,
		shardType = "WallShard",
		fighterPool = {
			"Eren_Attack", "Mikasa_Blades", "Levi_Blades", "Armin_Commander",
			"Annie_FemaleT", "Reiner_ArmoredT", "Bertholdt_ColossalT", "Zeke_BeastT"
		},
		craftedFighter = "Eren_Founding",
		questCount = 5,
		worldIndex = 6,
		theme = "Attack on Titan",
		hasDefenseMode = true,
	},
	[7] = {
		id = "slayer_army",
		name = "Slayer Army",
		unlockCost = 5000000000,
		minDamageRecommended = 50000000,
		bossHealth = 500000000,
		bossYenReward = 1000000000,
		enemyYenReward = 10000000,
		shardType = "SlayerShard",
		fighterPool = {
			"Tanjiro_Water", "Zenitsu_Thunder", "Inosuke_Beast", "Rengoku_Flame",
			"Giyu_Water", "Shinobu_Insect", "Tengen_Sound", "Muichiro_Mist"
		},
		craftedFighter = "Tanjiro_SunBreath",
		questCount = 5,
		worldIndex = 7,
		theme = "Demon Slayer",
		hasIncubator = true,
	},
	[8] = {
		id = "ghoul_town",
		name = "Ghoul Town",
		unlockCost = 50000000000,
		minDamageRecommended = 500000000,
		bossHealth = 5000000000,
		bossYenReward = 10000000000,
		enemyYenReward = 100000000,
		shardType = "GhoulShard",
		fighterPool = {
			"Kaneki_EyePatch", "Touka_Rabbit", "Amon_Dove", "Hinami_Flower",
			"Juuzou_Juuzou", "Arima_CCG", "Eto_OneEyed", "Yoshimura_Owl"
		},
		craftedFighter = "Kaneki_Dragon",
		questCount = 5,
		worldIndex = 8,
		theme = "Tokyo Ghoul",
	},
}

-- Helper: get world by id string
function WorldData.GetWorldById(id)
	for _, world in ipairs(WorldData.Worlds) do
		if world.id == id then
			return world
		end
	end
	return nil
end

-- Helper: get world by index
function WorldData.GetWorldByIndex(index)
	return WorldData.Worlds[index]
end

-- Total world count
function WorldData.GetWorldCount()
	local count = 0
	for _ in pairs(WorldData.Worlds) do count = count + 1 end
	return count
end

return WorldData
