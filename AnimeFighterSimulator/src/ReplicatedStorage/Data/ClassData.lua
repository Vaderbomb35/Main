-- ClassData.lua
-- Defines the 24 Class tiers that gate Yen income per minute

local ClassData = {}

-- Each class: name, yenPerMinute, upgradeCost, statRequirements
-- statRequirements: minimum combined stat points (Strength + Durability + Chakra)
ClassData.Classes = {
	[1]  = { name = "Fighter",         yenPerMinute = 5,                    upgradeCost = 0,                     statRequirement = 0 },
	[2]  = { name = "Shinobi",         yenPerMinute = 15,                   upgradeCost = 500,                   statRequirement = 50 },
	[3]  = { name = "Pirate",          yenPerMinute = 50,                   upgradeCost = 5000,                  statRequirement = 150 },
	[4]  = { name = "Ghoul",           yenPerMinute = 200,                  upgradeCost = 50000,                 statRequirement = 400 },
	[5]  = { name = "Hero",            yenPerMinute = 750,                  upgradeCost = 500000,                statRequirement = 1000 },
	[6]  = { name = "Reaper",          yenPerMinute = 2500,                 upgradeCost = 5000000,               statRequirement = 2500 },
	[7]  = { name = "Saiyan",          yenPerMinute = 10000,                upgradeCost = 50000000,              statRequirement = 6000 },
	[8]  = { name = "Titan",           yenPerMinute = 40000,                upgradeCost = 500000000,             statRequirement = 15000 },
	[9]  = { name = "Slayer",          yenPerMinute = 150000,               upgradeCost = 5000000000,            statRequirement = 35000 },
	[10] = { name = "Wizard",          yenPerMinute = 600000,               upgradeCost = 50000000000,           statRequirement = 80000 },
	[11] = { name = "Cursed",          yenPerMinute = 2500000,              upgradeCost = 500000000000,          statRequirement = 175000 },
	[12] = { name = "Alchemist",       yenPerMinute = 10000000,             upgradeCost = 5000000000000,         statRequirement = 375000 },
	[13] = { name = "Exorcist",        yenPerMinute = 40000000,             upgradeCost = 50000000000000,        statRequirement = 800000 },
	[14] = { name = "Soul King",       yenPerMinute = 160000000,            upgradeCost = 500000000000000,       statRequirement = 1700000 },
	[15] = { name = "Demon Lord",      yenPerMinute = 650000000,            upgradeCost = 5e15,                  statRequirement = 3600000 },
	[16] = { name = "Dragon Emperor",  yenPerMinute = 2600000000,           upgradeCost = 5e16,                  statRequirement = 7500000 },
	[17] = { name = "Phantom",         yenPerMinute = 10000000000,          upgradeCost = 5e17,                  statRequirement = 16000000 },
	[18] = { name = "Void Walker",     yenPerMinute = 41000000000,          upgradeCost = 5e18,                  statRequirement = 34000000 },
	[19] = { name = "Celestial",       yenPerMinute = 164000000000,         upgradeCost = 5e19,                  statRequirement = 72000000 },
	[20] = { name = "Godslayer",       yenPerMinute = 660000000000,         upgradeCost = 5e20,                  statRequirement = 150000000 },
	[21] = { name = "Archon",          yenPerMinute = 2630000000000,        upgradeCost = 5e21,                  statRequirement = 320000000 },
	[22] = { name = "Ascendant",       yenPerMinute = 10500000000000,       upgradeCost = 5e22,                  statRequirement = 680000000 },
	[23] = { name = "Kishin",          yenPerMinute = 4050000000000,        upgradeCost = 5e23,                  statRequirement = 1500000000 },
	[24] = { name = "Angel",           yenPerMinute = 12150000000000,       upgradeCost = 5e24,                  statRequirement = 3000000000 },
}

-- Stats required (each stat must individually meet 1/3 of the total requirement)
function ClassData.CanUpgradeClass(currentClass, playerStats)
	local nextClass = ClassData.Classes[currentClass + 1]
	if not nextClass then return false, "Already max class" end

	local totalStats = (playerStats.strength or 0) + (playerStats.durability or 0) + (playerStats.chakra or 0)
	if totalStats < nextClass.statRequirement then
		local needed = nextClass.statRequirement - totalStats
		return false, "Need " .. tostring(needed) .. " more stat points"
	end

	return true, nil
end

function ClassData.GetClass(index)
	return ClassData.Classes[index]
end

function ClassData.GetMaxClass()
	return #ClassData.Classes
end

return ClassData
