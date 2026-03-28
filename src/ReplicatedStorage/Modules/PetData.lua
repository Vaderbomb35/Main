--[[
    PetData.lua
    Cosmic Pet Simulator — All pet definitions, egg pools, and rarity config.
    Designed for maximum engagement: flashy rarities, escalating rewards,
    and hundreds of pets to collect.
--]]

local PetData = {}

-- ─── RARITIES ────────────────────────────────────────────────────────────────
-- Chance is a weight (not %). Higher = more common.
PetData.Rarities = {
    Common    = { DisplayName = "Common",    Color = Color3.fromRGB(180,180,180), Multiplier = 1,    Weight = 600, Glow = false },
    Uncommon  = { DisplayName = "Uncommon",  Color = Color3.fromRGB( 80,200, 80), Multiplier = 2,    Weight = 250, Glow = false },
    Rare      = { DisplayName = "Rare",      Color = Color3.fromRGB( 60,130,220), Multiplier = 6,    Weight =  90, Glow = false },
    Epic      = { DisplayName = "Epic",      Color = Color3.fromRGB(170, 60,230), Multiplier = 18,   Weight =  40, Glow = true  },
    Legendary = { DisplayName = "Legendary", Color = Color3.fromRGB(255,200,  0), Multiplier = 60,   Weight =  15, Glow = true  },
    Mythical  = { DisplayName = "Mythical",  Color = Color3.fromRGB(255, 60, 60), Multiplier = 200,  Weight =   4, Glow = true  },
    Divine    = { DisplayName = "Divine",    Color = Color3.fromRGB(150,255,255), Multiplier = 1000, Weight =   1, Glow = true  },
}

-- Ordered for iteration/display
PetData.RarityOrder = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine"
}

-- ─── PETS ─────────────────────────────────────────────────────────────────────
-- MeshId / TextureId reference asset IDs that exist in Roblox's catalog.
-- Using placeholder IDs — swap with your published asset IDs.
PetData.Pets = {
    -- ── COMMON ──
    {
        Id = "cat_basic",       Name = "Tabby Cat",
        Rarity = "Common",      Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.6,            Color = Color3.fromRGB(210,160,90),
        Description = "A friendly tabby cat. It loves coins!",
    },
    {
        Id = "dog_basic",       Name = "Golden Puppy",
        Rarity = "Common",      Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.65,           Color = Color3.fromRGB(230,180,80),
        Description = "Loyal and energetic. Will fetch coins for you.",
    },
    {
        Id = "bunny_basic",     Name = "Cotton Bunny",
        Rarity = "Common",      Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.5,            Color = Color3.fromRGB(255,230,230),
        Description = "Hops around collecting coins.",
    },
    {
        Id = "chick_basic",     Name = "Fluffy Chick",
        Rarity = "Common",      Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.4,            Color = Color3.fromRGB(255,235,100),
        Description = "Tiny but determined coin collector.",
    },
    {
        Id = "turtle_basic",    Name = "Sunny Turtle",
        Rarity = "Common",      Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.55,           Color = Color3.fromRGB(100,180,100),
        Description = "Slow and steady earns the coins.",
    },

    -- ── UNCOMMON ──
    {
        Id = "fox_uncommon",    Name = "Sly Fox",
        Rarity = "Uncommon",    Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.7,            Color = Color3.fromRGB(230,120,40),
        Description = "Cunning and quick. Sniffs out extra coins.",
    },
    {
        Id = "panda_uncommon",  Name = "Panda Cub",
        Rarity = "Uncommon",    Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.75,           Color = Color3.fromRGB(255,255,255),
        Description = "Black and white and coins all over.",
    },
    {
        Id = "penguin_uncommon", Name = "Ice Penguin",
        Rarity = "Uncommon",    Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.65,           Color = Color3.fromRGB(200,230,255),
        Description = "Slides in and grabs coins like ice!",
    },
    {
        Id = "koala_uncommon",  Name = "Koala",
        Rarity = "Uncommon",    Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.6,            Color = Color3.fromRGB(190,180,170),
        Description = "Chill but surprisingly good at collecting.",
    },

    -- ── RARE ──
    {
        Id = "wolf_rare",       Name = "Shadow Wolf",
        Rarity = "Rare",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.85,           Color = Color3.fromRGB(60,60,80),
        Description = "Lurks in shadows, emerges for coins.",
    },
    {
        Id = "phoenix_rare",    Name = "Baby Phoenix",
        Rarity = "Rare",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.7,            Color = Color3.fromRGB(255,130,30),
        Description = "A newborn phoenix. Burns with coin-lust.",
    },
    {
        Id = "unicorn_rare",    Name = "Starlight Unicorn",
        Rarity = "Rare",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.9,            Color = Color3.fromRGB(210,160,255),
        Description = "Leaves a sparkling trail everywhere.",
    },
    {
        Id = "dragon_rare",     Name = "Crystal Dragon",
        Rarity = "Rare",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.8,            Color = Color3.fromRGB(100,220,220),
        Description = "A young dragon with crystalline scales.",
    },

    -- ── EPIC ──
    {
        Id = "neon_cat_epic",   Name = "Neon Cat",
        Rarity = "Epic",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.7,            Color = Color3.fromRGB(255,0,200),
        Description = "Glows with neon energy. Multiplies coin drops!",
    },
    {
        Id = "galaxy_dog_epic", Name = "Galaxy Dog",
        Rarity = "Epic",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.8,            Color = Color3.fromRGB(80,40,160),
        Description = "Coated in stardust. Pulls coins from the cosmos.",
    },
    {
        Id = "titan_bear_epic", Name = "Titan Bear",
        Rarity = "Epic",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 1.1,            Color = Color3.fromRGB(120,80,40),
        Description = "Massive and powerful. Collects coins in bulk.",
    },
    {
        Id = "electric_rabbit_epic", Name = "Electric Rabbit",
        Rarity = "Epic",        Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 0.65,           Color = Color3.fromRGB(255,240,0),
        Description = "Zaps around collecting coins at lightning speed.",
    },

    -- ── LEGENDARY ──
    {
        Id = "rainbow_dragon_legendary",    Name = "Rainbow Dragon",
        Rarity = "Legendary",   Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 1.2,            Color = Color3.fromRGB(255,80,80),
        Description = "A legendary beast. Trails a rainbow of riches.",
    },
    {
        Id = "golden_phoenix_legendary",    Name = "Golden Phoenix",
        Rarity = "Legendary",   Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 1.0,            Color = Color3.fromRGB(255,220,0),
        Description = "Rises from ashes and rains golden coins.",
    },
    {
        Id = "cosmic_wolf_legendary",       Name = "Cosmic Wolf",
        Rarity = "Legendary",   Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 1.1,            Color = Color3.fromRGB(100,60,220),
        Description = "Howls at the moon. Each howl drops a coin shower.",
    },

    -- ── MYTHICAL ──
    {
        Id = "void_serpent_mythical",       Name = "Void Serpent",
        Rarity = "Mythical",    Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 1.3,            Color = Color3.fromRGB(30,0,40),
        Description = "Slithers through dimensions. Devours coins.",
    },
    {
        Id = "star_emperor_mythical",       Name = "Star Emperor",
        Rarity = "Mythical",    Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 1.4,            Color = Color3.fromRGB(255,255,200),
        Description = "Commands the stars themselves to collect for you.",
    },

    -- ── DIVINE ──
    {
        Id = "celestial_titan_divine",      Name = "Celestial Titan",
        Rarity = "Divine",      Icon = "rbxassetid://6401805476",
        MeshId = "rbxassetid://1370473653", TextureId = "rbxassetid://1370473735",
        Scale = 1.6,            Color = Color3.fromRGB(150,255,255),
        Description = "The rarest being in the cosmos. Unimaginable power.",
    },
}

-- Build a lookup table by Id for O(1) access
PetData.PetById = {}
for _, pet in ipairs(PetData.Pets) do
    PetData.PetById[pet.Id] = pet
end

-- ─── EGGS ─────────────────────────────────────────────────────────────────────
-- Each egg has a weighted pet pool derived from rarities.
-- PetIds listed here are what can hatch from that egg.
PetData.Eggs = {
    {
        Id = "basic_egg",           Name = "Basic Egg",
        Cost = 100,                 Currency = "Coins",
        Icon = "rbxassetid://6401805476",
        Color = Color3.fromRGB(200,180,140),
        PetPool = {
            "cat_basic", "dog_basic", "bunny_basic", "chick_basic", "turtle_basic",
            "fox_uncommon", "panda_uncommon",
        },
        WorldRequired = 1,
    },
    {
        Id = "forest_egg",          Name = "Forest Egg",
        Cost = 1000,                Currency = "Coins",
        Icon = "rbxassetid://6401805476",
        Color = Color3.fromRGB(80,160,80),
        PetPool = {
            "fox_uncommon", "panda_uncommon", "penguin_uncommon", "koala_uncommon",
            "wolf_rare", "phoenix_rare", "unicorn_rare",
        },
        WorldRequired = 2,
    },
    {
        Id = "mystic_egg",          Name = "Mystic Egg",
        Cost = 10000,               Currency = "Coins",
        Icon = "rbxassetid://6401805476",
        Color = Color3.fromRGB(120,60,220),
        PetPool = {
            "wolf_rare", "phoenix_rare", "unicorn_rare", "dragon_rare",
            "neon_cat_epic", "galaxy_dog_epic", "titan_bear_epic",
        },
        WorldRequired = 3,
    },
    {
        Id = "cosmic_egg",          Name = "Cosmic Egg",
        Cost = 500,                 Currency = "Gems",
        Icon = "rbxassetid://6401805476",
        Color = Color3.fromRGB(30,30,100),
        PetPool = {
            "neon_cat_epic", "galaxy_dog_epic", "electric_rabbit_epic",
            "rainbow_dragon_legendary", "golden_phoenix_legendary", "cosmic_wolf_legendary",
        },
        WorldRequired = 4,
    },
    {
        Id = "divine_egg",          Name = "Divine Egg",
        Cost = 5000,                Currency = "Gems",
        Icon = "rbxassetid://6401805476",
        Color = Color3.fromRGB(150,255,255),
        PetPool = {
            "rainbow_dragon_legendary", "golden_phoenix_legendary",
            "void_serpent_mythical", "star_emperor_mythical",
            "celestial_titan_divine",
        },
        WorldRequired = 5,
    },
}

PetData.EggById = {}
for _, egg in ipairs(PetData.Eggs) do
    PetData.EggById[egg.Id] = egg
end

-- ─── HELPER: weighted random roll ────────────────────────────────────────────
function PetData.RollPet(eggId, luckyBoost)
    luckyBoost = luckyBoost or 0
    local egg = PetData.EggById[eggId]
    if not egg then return nil end

    -- Build weighted list from the egg's pet pool
    local pool = {}
    local totalWeight = 0
    for _, petId in ipairs(egg.PetPool) do
        local pet = PetData.PetById[petId]
        if pet then
            local rarityData = PetData.Rarities[pet.Rarity]
            if rarityData then
                -- Lucky boost increases mythical/divine weight slightly
                local weight = rarityData.Weight
                if pet.Rarity == "Mythical" or pet.Rarity == "Divine" then
                    weight = weight + luckyBoost
                end
                totalWeight = totalWeight + weight
                table.insert(pool, { petId = petId, weight = totalWeight })
            end
        end
    end

    local roll = math.random() * totalWeight
    for _, entry in ipairs(pool) do
        if roll <= entry.weight then
            return entry.petId
        end
    end
    -- Fallback: return last in pool
    return pool[#pool] and pool[#pool].petId
end

return PetData
