-- ModuleScript: ReplicatedStorage.GameConfig
-- Holds the tunable numbers that define how progression feels.
-- Nothing in here is Instance-specific -- it's pure data + math so both
-- server scripts and (later) other systems can read the same source of truth.

local GameConfig = {}

-- ===== Upgrades =====
-- Two-phase cost curve: cheap/fast growth for the first few levels so early
-- game feels generous, then a much steeper climb to create the "wall" that
-- pushes players toward rebirthing, questing, or spending instead of
-- grinding straight through.
GameConfig.Upgrades = {
	SpawnSpeed = {
		Name = "Spawn Speed",
		BaseCost = 100,
		MaxLevel = 20,
		Phase1Levels = 4,
		Phase1Growth = 2.0,
		Phase2Growth = 5.0,
	},
	PlotCapacity = {
		Name = "Plot Capacity",
		BaseCost = 150,
		MaxLevel = 20,
		Phase1Levels = 4,
		Phase1Growth = 2.2,
		Phase2Growth = 5.5,
	},
	StartingTier = {
		Name = "Starting Tier",
		BaseCost = 250,
		MaxLevel = 20,
		Phase1Levels = 4,
		Phase1Growth = 2.5,
		Phase2Growth = 6.0,
	},
}

-- Order controls left-to-right placement on the physical board.
GameConfig.UpgradeOrder = { "SpawnSpeed", "PlotCapacity", "StartingTier" }

function GameConfig.GetUpgradeCost(upgradeId, currentLevel)
	local def = GameConfig.Upgrades[upgradeId]
	if not def or currentLevel >= def.MaxLevel then
		return nil
	end
	local cost = def.BaseCost
	for level = 1, currentLevel do
		local growth = (level < def.Phase1Levels) and def.Phase1Growth or def.Phase2Growth
		cost = cost * growth
	end
	return math.floor(cost)
end

-- ===== Rebirth =====
-- Capped at 3 for now. Each rebirth lines up with finishing a themed
-- 15-tier fruit block (Plain / Frost / Magma). When a new block gets added
-- later, add one more entry here and bump MaxRebirths -- that's the whole
-- update.
GameConfig.MaxRebirths = 3
GameConfig.RebirthRequirements = { 51200, 52428800, 53687091200 }

function GameConfig.GetRebirthRequirement(rebirthCount)
	return GameConfig.RebirthRequirements[rebirthCount + 1]
end

function GameConfig.GetGemsForRebirth(cashAtRebirth)
	-- Diminishing-but-meaningful returns on bigger rebirths. Placeholder
	-- constant (10) -- tune once real playtest cash numbers exist.
	return math.floor(math.sqrt(cashAtRebirth) / 10)
end

-- ===== Formatting =====
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp" }

function GameConfig.FormatNumber(n)
	n = math.floor(n)
	local tier = 1
	local value = n
	while value >= 1000 and tier < #SUFFIXES do
		value = value / 1000
		tier = tier + 1
	end
	if tier == 1 then
		return tostring(value)
	end
	return string.format("%.2f%s", value, SUFFIXES[tier])
end

return GameConfig
