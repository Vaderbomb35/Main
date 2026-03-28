--[[
    DataManager.lua  (ServerScript)
    Cosmic Pet Simulator — Handles all DataStore operations.
    Saves and loads player data with retry logic and session locking.
--]]

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local GameData = require(Modules:WaitForChild("GameData"))

local PlayerDataStore = DataStoreService:GetDataStore("CosmicPetSimulator_v1")
local DATA_SAVE_INTERVAL = 60  -- auto-save every 60 seconds

-- ─── DEFAULT PLAYER DATA ─────────────────────────────────────────────────────
local function GetDefaultData()
    return {
        -- Currency
        Coins        = 0,
        Gems         = 0,
        TotalCoins   = 0,   -- lifetime coins earned

        -- Progression
        Rebirths       = 0,
        CurrentWorld   = 1,

        -- Pets: list of { id, petId, equipped, index }
        Pets           = {},
        EquippedPets   = {},  -- list of pet instance ids currently equipped
        PetStorageMax  = GameData.MaxStoredPets,

        -- Upgrades: { upgradeId = level }
        Upgrades = {
            coin_magnet   = 0,
            coin_value    = 0,
            lucky         = 0,
            pet_capacity  = 0,
            auto_hatch    = 0,
            gem_luck      = 0,
        },

        -- Active boosts: list of { BoostType, BoostValue, ExpiresAt }
        ActiveBoosts   = {},

        -- Daily reward tracking
        LastDailyReward  = 0,    -- os.time() of last claim
        DailyRewardStreak = 0,

        -- Stats
        EggsHatched    = 0,
        TotalPetsOwned = 0,

        -- Meta
        Version        = 1,
        CreatedAt      = os.time(),
        LastSeen       = os.time(),
    }
end

-- ─── IN-MEMORY CACHE ─────────────────────────────────────────────────────────
local PlayerData = {}    -- [userId] = data table
local SaveTimers = {}    -- [userId] = last save time

-- ─── DATASTORE HELPERS ───────────────────────────────────────────────────────
local function RetryLoad(userId, retries)
    retries = retries or 3
    local data, err
    for attempt = 1, retries do
        local success
        success, data = pcall(function()
            return PlayerDataStore:GetAsync("Player_" .. userId)
        end)
        if success then return data end
        err = data
        warn(string.format("[DataManager] Load attempt %d failed for %d: %s", attempt, userId, tostring(err)))
        task.wait(2 ^ attempt)  -- exponential back-off: 2, 4, 8 seconds
    end
    return nil
end

local function RetrySave(userId, data, retries)
    retries = retries or 3
    for attempt = 1, retries do
        local success, err = pcall(function()
            PlayerDataStore:SetAsync("Player_" .. userId, data)
        end)
        if success then return true end
        warn(string.format("[DataManager] Save attempt %d failed for %d: %s", attempt, userId, tostring(err)))
        task.wait(2 ^ attempt)
    end
    return false
end

-- ─── MIGRATION ───────────────────────────────────────────────────────────────
local function MigrateData(data)
    -- Future: handle version bumps
    -- e.g., if data.Version == nil then ... end
    local defaults = GetDefaultData()

    -- Ensure all upgrade keys exist
    for upgradeId, _ in pairs(defaults.Upgrades) do
        if data.Upgrades[upgradeId] == nil then
            data.Upgrades[upgradeId] = 0
        end
    end

    -- Clamp world to valid range
    if not GameData.WorldById[data.CurrentWorld] then
        data.CurrentWorld = 1
    end

    data.Version = defaults.Version
    return data
end

-- ─── PUBLIC API ──────────────────────────────────────────────────────────────
local DataManager = {}

function DataManager.LoadPlayer(player)
    local userId = player.UserId
    local raw    = RetryLoad(userId)
    local data

    if raw then
        data = MigrateData(raw)
    else
        data = GetDefaultData()
        print(string.format("[DataManager] New player data created for %s (%d)", player.Name, userId))
    end

    data.LastSeen = os.time()
    PlayerData[userId] = data
    SaveTimers[userId] = os.time()
    return data
end

function DataManager.SavePlayer(player)
    local userId = player.UserId
    local data   = PlayerData[userId]
    if not data then return end

    data.LastSeen = os.time()
    local ok = RetrySave(userId, data)
    if ok then
        SaveTimers[userId] = os.time()
    end
end

function DataManager.GetData(player)
    return PlayerData[player.UserId]
end

function DataManager.SetData(player, key, value)
    local data = PlayerData[player.UserId]
    if data then
        data[key] = value
    end
end

-- Give coins/gems safely (checks for overflow/cheating)
function DataManager.AddCurrency(player, currencyType, amount)
    local data = PlayerData[player.UserId]
    if not data then return end
    amount = math.floor(math.abs(amount))  -- no negatives or decimals

    if currencyType == "Coins" then
        data.Coins      = data.Coins + amount
        data.TotalCoins = data.TotalCoins + amount
    elseif currencyType == "Gems" then
        data.Gems = data.Gems + amount
    end
end

function DataManager.SpendCurrency(player, currencyType, amount)
    local data = PlayerData[player.UserId]
    if not data then return false end
    amount = math.floor(math.abs(amount))

    if currencyType == "Coins" then
        if data.Coins < amount then return false end
        data.Coins = data.Coins - amount
        return true
    elseif currencyType == "Gems" then
        if data.Gems < amount then return false end
        data.Gems = data.Gems - amount
        return true
    end
    return false
end

-- Add a pet to inventory, returns instance id (index into Pets array)
function DataManager.AddPet(player, petId)
    local data = PlayerData[player.UserId]
    if not data then return nil end
    if #data.Pets >= data.PetStorageMax then return nil, "storage_full" end

    local instanceId = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    table.insert(data.Pets, {
        InstanceId = instanceId,
        PetId      = petId,
        Equipped   = false,
    })
    data.TotalPetsOwned = data.TotalPetsOwned + 1
    return instanceId
end

function DataManager.EquipPet(player, instanceId)
    local data = PlayerData[player.UserId]
    if not data then return false, "no_data" end

    -- Determine max equipped slots
    local maxSlots = GameData.MaxEquippedPets
                   + GameData.GetUpgradeValue("pet_capacity", data.Upgrades.pet_capacity or 0)
    maxSlots = math.floor(maxSlots)

    if #data.EquippedPets >= maxSlots then
        return false, "slots_full"
    end

    -- Find the pet
    for _, pet in ipairs(data.Pets) do
        if pet.InstanceId == instanceId then
            if pet.Equipped then return false, "already_equipped" end
            pet.Equipped = true
            table.insert(data.EquippedPets, instanceId)
            return true
        end
    end
    return false, "not_found"
end

function DataManager.UnequipPet(player, instanceId)
    local data = PlayerData[player.UserId]
    if not data then return false end

    for i, id in ipairs(data.EquippedPets) do
        if id == instanceId then
            table.remove(data.EquippedPets, i)
            break
        end
    end
    for _, pet in ipairs(data.Pets) do
        if pet.InstanceId == instanceId then
            pet.Equipped = false
            return true
        end
    end
    return false
end

function DataManager.ComputePetMultiplier(player)
    local data = PlayerData[player.UserId]
    if not data then return 1 end

    local PetData = require(Modules:WaitForChild("PetData"))
    local total = 1
    for _, id in ipairs(data.EquippedPets) do
        for _, pet in ipairs(data.Pets) do
            if pet.InstanceId == id then
                local petDef = PetData.PetById[pet.PetId]
                if petDef then
                    local rarityDef = PetData.Rarities[petDef.Rarity]
                    if rarityDef then
                        total = total + rarityDef.Multiplier
                    end
                end
                break
            end
        end
    end
    return total
end

-- ─── PLAYER EVENTS ───────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    DataManager.LoadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    DataManager.SavePlayer(player)
    PlayerData[player.UserId] = nil
    SaveTimers[player.UserId] = nil
end)

-- Auto-save loop
task.spawn(function()
    while true do
        task.wait(DATA_SAVE_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            if (os.time() - (SaveTimers[player.UserId] or 0)) >= DATA_SAVE_INTERVAL then
                task.spawn(DataManager.SavePlayer, player)
            end
        end
    end
end)

-- Bind to close for server shutdown
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.SavePlayer(player)
    end
end)

-- Expose module globally so other scripts can require it
_G.DataManager = DataManager
return DataManager
