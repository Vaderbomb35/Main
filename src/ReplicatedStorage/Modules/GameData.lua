--[[
    GameData.lua
    Cosmic Pet Simulator — World definitions, upgrades, shop items, balancing.
--]]

local GameData = {}

-- ─── WORLDS ───────────────────────────────────────────────────────────────────
GameData.Worlds = {
    {
        Id = 1,
        Name = "Starter Meadow",
        Description = "A peaceful green meadow filled with shiny coins.",
        RequiredRebirths = 0,
        CoinMultiplier = 1,
        GemChance = 0.03,       -- 3% of coin spawns are gems
        CoinSpawnRate = 0.5,    -- seconds between coin batch spawns
        CoinsPerBatch = 8,
        SkyColor = Color3.fromRGB(135,206,235),
        GroundColor = Color3.fromRGB(100,200,80),
        AmbientColor = Color3.fromRGB(180,220,160),
        FogEnabled = false,
        UnlockMessage = "Welcome, Trainer! Begin your adventure!",
    },
    {
        Id = 2,
        Name = "Crystal Caves",
        Description = "Glittering caves full of rare crystals and riches.",
        RequiredRebirths = 1,
        CoinMultiplier = 5,
        GemChance = 0.07,
        CoinSpawnRate = 0.4,
        CoinsPerBatch = 12,
        SkyColor = Color3.fromRGB(50,40,80),
        GroundColor = Color3.fromRGB(60,50,100),
        AmbientColor = Color3.fromRGB(120,100,200),
        FogEnabled = true,
        FogColor = Color3.fromRGB(80,60,120),
        FogEnd = 200,
        UnlockMessage = "You've entered the Crystal Caves! New pets await!",
    },
    {
        Id = 3,
        Name = "Neon City",
        Description = "A futuristic city where coins glow in neon colors.",
        RequiredRebirths = 3,
        CoinMultiplier = 20,
        GemChance = 0.10,
        CoinSpawnRate = 0.35,
        CoinsPerBatch = 16,
        SkyColor = Color3.fromRGB(10,10,30),
        GroundColor = Color3.fromRGB(20,20,50),
        AmbientColor = Color3.fromRGB(50,50,150),
        FogEnabled = true,
        FogColor = Color3.fromRGB(30,20,60),
        FogEnd = 180,
        UnlockMessage = "Neon City unlocked! The coins are electric here!",
    },
    {
        Id = 4,
        Name = "Galactic Void",
        Description = "Float through space collecting cosmic currencies.",
        RequiredRebirths = 7,
        CoinMultiplier = 100,
        GemChance = 0.15,
        CoinSpawnRate = 0.3,
        CoinsPerBatch = 20,
        SkyColor = Color3.fromRGB(5,5,20),
        GroundColor = Color3.fromRGB(10,5,30),
        AmbientColor = Color3.fromRGB(20,10,60),
        FogEnabled = true,
        FogColor = Color3.fromRGB(10,5,30),
        FogEnd = 150,
        UnlockMessage = "You've reached the Galactic Void! Incredible rewards!",
    },
    {
        Id = 5,
        Name = "Divine Realm",
        Description = "The realm of the gods. Unimaginable wealth flows here.",
        RequiredRebirths = 15,
        CoinMultiplier = 1000,
        GemChance = 0.25,
        CoinSpawnRate = 0.25,
        CoinsPerBatch = 25,
        SkyColor = Color3.fromRGB(150,255,255),
        GroundColor = Color3.fromRGB(200,255,240),
        AmbientColor = Color3.fromRGB(255,255,220),
        FogEnabled = false,
        UnlockMessage = "You have ascended to the Divine Realm! Legends live here!",
    },
}

GameData.WorldById = {}
for _, world in ipairs(GameData.Worlds) do
    GameData.WorldById[world.Id] = world
end

-- ─── UPGRADES ─────────────────────────────────────────────────────────────────
GameData.Upgrades = {
    {
        Id = "coin_magnet",
        Name = "Coin Magnet",
        Description = "Increases the radius coins are attracted to you.",
        Icon = "rbxassetid://6401805476",
        MaxLevel = 20,
        BaseCost = 200,
        CostMultiplier = 1.8,   -- each level costs CostMultiplier * previous
        Currency = "Coins",
        EffectPerLevel = 2,     -- +2 studs magnet radius per level
        BaseValue = 8,          -- starting radius
    },
    {
        Id = "coin_value",
        Name = "Coin Value",
        Description = "Each coin you collect is worth more.",
        Icon = "rbxassetid://6401805476",
        MaxLevel = 30,
        BaseCost = 500,
        CostMultiplier = 2.0,
        Currency = "Coins",
        EffectPerLevel = 0.1,   -- +10% coin value per level (multiplicative)
        BaseValue = 1.0,
    },
    {
        Id = "lucky",
        Name = "Lucky Charm",
        Description = "Boosts your chances of hatching rare pets.",
        Icon = "rbxassetid://6401805476",
        MaxLevel = 10,
        BaseCost = 1000,
        CostMultiplier = 3.0,
        Currency = "Coins",
        EffectPerLevel = 0.5,   -- +0.5 lucky points per level
        BaseValue = 0,
    },
    {
        Id = "pet_capacity",
        Name = "Pet Capacity",
        Description = "Equip more pets at once!",
        Icon = "rbxassetid://6401805476",
        MaxLevel = 6,           -- cap at 9 pets (3 base + 6 upgrades)
        BaseCost = 10000,
        CostMultiplier = 5.0,
        Currency = "Gems",
        EffectPerLevel = 1,     -- +1 pet slot per level
        BaseValue = 3,
    },
    {
        Id = "auto_hatch",
        Name = "Auto Hatch",
        Description = "Automatically hatches eggs in your queue.",
        Icon = "rbxassetid://6401805476",
        MaxLevel = 5,
        BaseCost = 2000,
        CostMultiplier = 3.5,
        Currency = "Gems",
        EffectPerLevel = 1,     -- +1 egg hatched per cycle
        BaseValue = 0,
    },
    {
        Id = "gem_luck",
        Name = "Gem Radar",
        Description = "Increases gem drop chance from coins.",
        Icon = "rbxassetid://6401805476",
        MaxLevel = 10,
        BaseCost = 500,
        CostMultiplier = 2.5,
        Currency = "Gems",
        EffectPerLevel = 0.01,  -- +1% gem chance per level
        BaseValue = 0,
    },
}

GameData.UpgradeById = {}
for _, upg in ipairs(GameData.Upgrades) do
    GameData.UpgradeById[upg.Id] = upg
end

-- ─── REBIRTH ──────────────────────────────────────────────────────────────────
GameData.Rebirth = {
    BaseRequirement = 100000,    -- coins needed for first rebirth
    RequirementMultiplier = 3,   -- each rebirth costs 3x more coins
    RebirthMultiplier = 1.5,     -- each rebirth gives 1.5x global multiplier
    RewardGems = 10,             -- gems awarded on rebirth
    RewardGemsPerRebirth = 5,    -- extra gems per rebirth count
    MaxRebirths = 50,
}

-- ─── SHOP (BOOSTS) ────────────────────────────────────────────────────────────
GameData.ShopItems = {
    {
        Id = "2x_coins_30",
        Name = "2x Coins (30 min)",
        Description = "Double your coin income for 30 minutes!",
        Cost = 50,
        Currency = "Gems",
        Icon = "rbxassetid://6401805476",
        BoostType = "CoinMultiplier",
        BoostValue = 2,
        BoostDuration = 1800,   -- seconds
    },
    {
        Id = "3x_coins_60",
        Name = "3x Coins (1 hr)",
        Description = "Triple coin income for an hour!",
        Cost = 90,
        Currency = "Gems",
        Icon = "rbxassetid://6401805476",
        BoostType = "CoinMultiplier",
        BoostValue = 3,
        BoostDuration = 3600,
    },
    {
        Id = "lucky_30",
        Name = "Lucky Aura (30 min)",
        Description = "Dramatically increase rare pet hatch rates!",
        Cost = 100,
        Currency = "Gems",
        Icon = "rbxassetid://6401805476",
        BoostType = "LuckyBoost",
        BoostValue = 10,
        BoostDuration = 1800,
    },
    {
        Id = "hatch_speed_60",
        Name = "Speed Hatch (1 hr)",
        Description = "Hatch 2 eggs at once for an hour!",
        Cost = 75,
        Currency = "Gems",
        Icon = "rbxassetid://6401805476",
        BoostType = "HatchSpeed",
        BoostValue = 2,
        BoostDuration = 3600,
    },
    {
        Id = "pet_storage_50",
        Name = "Expand Storage (+50)",
        Description = "Permanently add 50 more pet storage slots.",
        Cost = 200,
        Currency = "Gems",
        Icon = "rbxassetid://6401805476",
        BoostType = "PetStorage",
        BoostValue = 50,
        BoostDuration = -1,     -- permanent
    },
}

GameData.ShopById = {}
for _, item in ipairs(GameData.ShopItems) do
    GameData.ShopById[item.Id] = item
end

-- ─── DAILY REWARDS ────────────────────────────────────────────────────────────
GameData.DailyRewards = {
    { Day = 1,  Type = "Coins", Amount = 500 },
    { Day = 2,  Type = "Gems",  Amount = 10 },
    { Day = 3,  Type = "Coins", Amount = 2000 },
    { Day = 4,  Type = "Gems",  Amount = 25 },
    { Day = 5,  Type = "EggId", Amount = "forest_egg" },
    { Day = 6,  Type = "Gems",  Amount = 50 },
    { Day = 7,  Type = "EggId", Amount = "mystic_egg" },
}

-- ─── MISC CONSTANTS ───────────────────────────────────────────────────────────
GameData.MaxEquippedPets  = 3       -- base max equipped (upgradeable)
GameData.MaxStoredPets    = 100     -- base storage
GameData.HatchAnimSeconds = 3       -- how long the hatch animation plays
GameData.CoinPickupRadius = 8       -- base stud radius for coin magnetism
GameData.GemValue         = 100     -- 1 gem = 100 coins worth (display only)

-- Utility: compute upgrade cost at a given level
function GameData.GetUpgradeCost(upgradeId, currentLevel)
    local upg = GameData.UpgradeById[upgradeId]
    if not upg then return 0 end
    local cost = upg.BaseCost
    for _ = 1, currentLevel do
        cost = math.floor(cost * upg.CostMultiplier)
    end
    return cost
end

-- Utility: compute current upgrade value
function GameData.GetUpgradeValue(upgradeId, currentLevel)
    local upg = GameData.UpgradeById[upgradeId]
    if not upg then return 0 end
    return upg.BaseValue + (upg.EffectPerLevel * currentLevel)
end

-- Utility: compute rebirth requirement
function GameData.GetRebirthRequirement(rebirthCount)
    local req = GameData.Rebirth.BaseRequirement
    for _ = 1, rebirthCount do
        req = math.floor(req * GameData.Rebirth.RequirementMultiplier)
    end
    return req
end

return GameData
