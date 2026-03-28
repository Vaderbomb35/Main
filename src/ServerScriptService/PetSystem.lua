--[[
    PetSystem.lua  (ServerScript)
    Cosmic Pet Simulator — Egg hatching, pet equipping/unequipping.
    All mutations are server-authoritative.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Modules    = ReplicatedStorage:WaitForChild("Modules")
local GameData   = require(Modules:WaitForChild("GameData"))
local PetData    = require(Modules:WaitForChild("PetData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local HatchEgg      = RemoteEvents:WaitForChild("HatchEgg")
local EquipPet      = RemoteEvents:WaitForChild("EquipPet")
local UnequipPet    = RemoteEvents:WaitForChild("UnequipPet")
local UpdatePlayer  = RemoteEvents:WaitForChild("UpdatePlayerData")
local OpenEggResult = RemoteEvents:WaitForChild("OpenEggResult")

-- Wait for DataManager
local DataManager
task.spawn(function()
    while not _G.DataManager do task.wait(0.1) end
    DataManager = _G.DataManager
end)

-- Rate-limit: track last hatch time per player
local LastHatchTime = {}
local HATCH_COOLDOWN = 0.5  -- seconds

-- ─── EGG HATCHING ─────────────────────────────────────────────────────────────
HatchEgg.OnServerEvent:Connect(function(player, eggId)
    if not DataManager then return end

    -- Rate limit check
    local now = os.clock()
    if (now - (LastHatchTime[player.UserId] or 0)) < HATCH_COOLDOWN then return end
    LastHatchTime[player.UserId] = now

    local data = DataManager.GetData(player)
    if not data then return end

    local egg = PetData.EggById[eggId]
    if not egg then return end

    -- World requirement check
    if data.CurrentWorld < (egg.WorldRequired or 1) then return end

    -- Cost check and deduction
    local ok = DataManager.SpendCurrency(player, egg.Currency, egg.Cost)
    if not ok then return end

    -- Determine lucky boost from upgrades + active boosts
    local luckyBoost = GameData.GetUpgradeValue("lucky", data.Upgrades.lucky or 0)
    local nowOs = os.time()
    for _, boost in ipairs(data.ActiveBoosts or {}) do
        if boost.BoostType == "LuckyBoost" and boost.ExpiresAt > nowOs then
            luckyBoost = luckyBoost + boost.BoostValue
        end
    end

    -- Roll the pet
    local petId = PetData.RollPet(eggId, luckyBoost)
    if not petId then
        -- Refund on failure
        DataManager.AddCurrency(player, egg.Currency, egg.Cost)
        return
    end

    local petDef = PetData.PetById[petId]
    if not petDef then
        DataManager.AddCurrency(player, egg.Currency, egg.Cost)
        return
    end

    -- Add pet to inventory
    local instanceId, storageErr = DataManager.AddPet(player, petId)
    if not instanceId then
        if storageErr == "storage_full" then
            -- Refund and notify
            DataManager.AddCurrency(player, egg.Currency, egg.Cost)
            -- Fire a "storage full" notification back
            OpenEggResult:FireClient(player, nil, nil, "storage_full")
            return
        end
        DataManager.AddCurrency(player, egg.Currency, egg.Cost)
        return
    end

    data.EggsHatched = (data.EggsHatched or 0) + 1

    -- Auto-equip if there's room
    if #data.EquippedPets < GameData.MaxEquippedPets + GameData.GetUpgradeValue("pet_capacity", data.Upgrades.pet_capacity or 0) then
        DataManager.EquipPet(player, instanceId)
    end

    -- Notify client with full result for animation
    OpenEggResult:FireClient(player, {
        EggId      = eggId,
        PetId      = petId,
        PetName    = petDef.Name,
        Rarity     = petDef.Rarity,
        InstanceId = instanceId,
    })

    -- Push updated data
    UpdatePlayer:FireClient(player, DataManager.GetData(player))

    print(string.format("[PetSystem] %s hatched %s (%s) from %s",
        player.Name, petDef.Name, petDef.Rarity, egg.Name))
end)

-- ─── EQUIP PET ────────────────────────────────────────────────────────────────
EquipPet.OnServerEvent:Connect(function(player, instanceId)
    if not DataManager then return end
    local ok, err = DataManager.EquipPet(player, instanceId)
    if ok then
        UpdatePlayer:FireClient(player, DataManager.GetData(player))
    else
        -- Optionally send error back: for now just silently fail
        print(string.format("[PetSystem] EquipPet failed for %s: %s", player.Name, tostring(err)))
    end
end)

-- ─── UNEQUIP PET ──────────────────────────────────────────────────────────────
UnequipPet.OnServerEvent:Connect(function(player, instanceId)
    if not DataManager then return end
    DataManager.UnequipPet(player, instanceId)
    UpdatePlayer:FireClient(player, DataManager.GetData(player))
end)

print("[PetSystem] Initialized.")
