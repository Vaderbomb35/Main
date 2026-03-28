-- PassiveData.lua
-- Defines all fighter passives, their effects, and reroll costs

local PassiveData = {}

-- canRoll: false = only obtainable by special means (not from Reroll Machine)
PassiveData.Passives = {
	-- POSITIVE PASSIVES
	Tactical_I = {
		id = "Tactical_I", name = "Tactical I",
		description = "1.5x damage to bosses and mini-bosses",
		effect = { bossDamageMultiplier = 1.5 },
		canRoll = true, weight = 100,
	},
	Tactical_II = {
		id = "Tactical_II", name = "Tactical II",
		description = "1.75x damage to bosses and mini-bosses",
		effect = { bossDamageMultiplier = 1.75 },
		canRoll = true, weight = 50,
	},
	Tactical_III = {
		id = "Tactical_III", name = "Tactical III",
		description = "2x damage to bosses and mini-bosses",
		effect = { bossDamageMultiplier = 2.0 },
		canRoll = true, weight = 20,
	},
	Blessing = {
		id = "Blessing", name = "Blessing",
		description = "+75% damage, 2.5x movement speed",
		effect = { damageMultiplier = 1.75, speedMultiplier = 2.5 },
		canRoll = true, weight = 15,
	},
	Ghostly = {
		id = "Ghostly", name = "Ghostly",
		description = "+50% damage, 50% faster attack, 10x movement speed",
		effect = { damageMultiplier = 1.5, attackSpeedMultiplier = 1.5, speedMultiplier = 10.0 },
		canRoll = true, weight = 5,
	},
	Ace = {
		id = "Ace", name = "Ace",
		description = "Always critical hit, +25% more damage",
		effect = { alwaysCrit = true, damageMultiplier = 1.25 },
		canRoll = true, weight = 8,
	},
	Solid_Gold = {
		id = "Solid_Gold", name = "Solid Gold",
		description = "+40% Yen income",
		effect = { yenMultiplier = 1.4 },
		canRoll = true, weight = 3,
	},
	Power_I = {
		id = "Power_I", name = "Power I",
		description = "+20% damage",
		effect = { damageMultiplier = 1.2 },
		canRoll = true, weight = 150,
	},
	Power_II = {
		id = "Power_II", name = "Power II",
		description = "+35% damage",
		effect = { damageMultiplier = 1.35 },
		canRoll = true, weight = 80,
	},
	Power_III = {
		id = "Power_III", name = "Power III",
		description = "+50% damage",
		effect = { damageMultiplier = 1.5 },
		canRoll = true, weight = 30,
	},
	Lucky_I = {
		id = "Lucky_I", name = "Lucky I",
		description = "+0.1 luck when equipped",
		effect = { luckBonus = 0.1 },
		canRoll = true, weight = 40,
	},
	Lucky_II = {
		id = "Lucky_II", name = "Lucky II",
		description = "+0.25 luck when equipped",
		effect = { luckBonus = 0.25 },
		canRoll = true, weight = 12,
	},
	Lucky_III = {
		id = "Lucky_III", name = "Lucky III",
		description = "+0.5 luck when equipped",
		effect = { luckBonus = 0.5 },
		canRoll = false, weight = 0,  -- cannot roll, must obtain through special means
	},
	Speed_Boost = {
		id = "Speed_Boost", name = "Speed Boost",
		description = "3x movement speed",
		effect = { speedMultiplier = 3.0 },
		canRoll = true, weight = 60,
	},

	-- NEGATIVE PASSIVES (only obtainable from old/removed methods; block from Reroll Machine)
	Slow = {
		id = "Slow", name = "Slow",
		description = "0.5x movement speed",
		effect = { speedMultiplier = 0.5 },
		canRoll = false, weight = 0,  -- cannot be obtained from machine
	},
	Dumb = {
		id = "Dumb", name = "Dumb",
		description = "-30% damage",
		effect = { damageMultiplier = 0.7 },
		canRoll = false, weight = 0,
	},
	Weak = {
		id = "Weak", name = "Weak",
		description = "-50% damage to bosses",
		effect = { bossDamageMultiplier = 0.5 },
		canRoll = false, weight = 0,
	},
}

-- Reroll costs in Shards based on fighter rarity
PassiveData.RerollCosts = {
	Common   = 1,
	Rare     = 1,
	Epic     = 1,
	Legendary = 1,
	-- Shiny variants cost more
	ShinyCommon    = 2,
	ShinyRare      = 2,
	ShinyEpic      = 2,
	ShinyLegendary = 2,
	ShinyMythical  = 3,
	ShinyCrafted   = 5,
	Mythical  = 2,
	Crafted   = 3,
	Secret    = 5,
	ShinySecret   = 10,
	Divine    = 10,
	ShinyDivine   = 20,
}

-- Roll a random passive from rollable pool
function PassiveData.RollPassive()
	local pool = {}
	local totalWeight = 0
	for _, passive in pairs(PassiveData.Passives) do
		if passive.canRoll and passive.weight > 0 then
			table.insert(pool, passive)
			totalWeight = totalWeight + passive.weight
		end
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, passive in ipairs(pool) do
		cumulative = cumulative + passive.weight
		if roll <= cumulative then
			return passive.id
		end
	end
	return "Power_I"
end

-- Apply all passives from equipped fighters and return aggregate stats
function PassiveData.AggregatePassiveEffects(equippedFighters)
	local result = {
		damageMultiplier = 1.0,
		bossDamageMultiplier = 1.0,
		speedMultiplier = 1.0,
		attackSpeedMultiplier = 1.0,
		yenMultiplier = 1.0,
		luckBonus = 0,
		alwaysCrit = false,
	}
	for _, fighter in ipairs(equippedFighters) do
		if fighter.passive then
			local passiveData = PassiveData.Passives[fighter.passive]
			if passiveData and passiveData.effect then
				local e = passiveData.effect
				if e.damageMultiplier then result.damageMultiplier = result.damageMultiplier * e.damageMultiplier end
				if e.bossDamageMultiplier then result.bossDamageMultiplier = result.bossDamageMultiplier * e.bossDamageMultiplier end
				if e.speedMultiplier then result.speedMultiplier = result.speedMultiplier * e.speedMultiplier end
				if e.attackSpeedMultiplier then result.attackSpeedMultiplier = result.attackSpeedMultiplier * e.attackSpeedMultiplier end
				if e.yenMultiplier then result.yenMultiplier = result.yenMultiplier * e.yenMultiplier end
				if e.luckBonus then result.luckBonus = result.luckBonus + e.luckBonus end
				if e.alwaysCrit then result.alwaysCrit = true end
			end
		end
	end
	return result
end

return PassiveData
