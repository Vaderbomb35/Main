--[[
    GameManager.lua  (ServerScript)
    Cosmic Pet Simulator — Core game loop: coin/gem spawning, leaderboard,
    world management, rebirth, and player stat broadcasting.
--]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameData = require(Modules:WaitForChild("GameData"))

-- Wait for DataManager to initialize (it runs first)
local DataManager
task.spawn(function()
    while not _G.DataManager do task.wait(0.1) end
    DataManager = _G.DataManager
end)

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local UpdatePlayerData = RemoteEvents:WaitForChild("UpdatePlayerData")
local SpawnCoinEffect  = RemoteEvents:WaitForChild("SpawnCoinEffect")
local TeleportWorld    = RemoteEvents:WaitForChild("TeleportWorld")
local Rebirth          = RemoteEvents:WaitForChild("Rebirth")

-- ─── COIN / GEM SPAWNING ──────────────────────────────────────────────────────
-- Coins are Parts spawned in the world. When a player walks near one,
-- they collect it. The collection is server-authoritative.

local CoinFolder = Workspace:FindFirstChild("Coins") or Instance.new("Folder", Workspace)
CoinFolder.Name = "Coins"

local COIN_COLORS = {
    Color3.fromRGB(255,215,0),    -- gold
    Color3.fromRGB(220,220,220),  -- silver
    Color3.fromRGB(255,140,0),    -- bronze
}
local GEM_COLOR = Color3.fromRGB(100,200,255)

local function SpawnArena()
    -- Simple flat arena (would be replaced by an actual map build)
    local baseplate = Workspace:FindFirstChild("Baseplate") or Instance.new("Part", Workspace)
    baseplate.Name     = "Baseplate"
    baseplate.Anchored = true
    baseplate.Size     = Vector3.new(512, 4, 512)
    baseplate.Position = Vector3.new(0, -2, 0)
    baseplate.Material = Enum.Material.Grass
    baseplate.Color    = Color3.fromRGB(106,127,63)
    baseplate.Locked   = true
end
SpawnArena()

local function MakeCoinPart(position, isGem, worldId)
    local part    = Instance.new("Part")
    part.Size     = isGem and Vector3.new(1.5, 1.5, 1.5) or Vector3.new(1, 1, 1)
    part.Shape    = Enum.PartType.Ball
    part.Material = isGem and Enum.Material.Neon or Enum.Material.SmoothPlastic
    part.Color    = isGem and GEM_COLOR or COIN_COLORS[math.random(#COIN_COLORS)]
    part.CFrame   = CFrame.new(position)
    part.Anchored = false
    part.CanCollide = false
    part:SetAttribute("IsGem",   isGem)
    part:SetAttribute("WorldId", worldId)

    -- Floating animation via BodyPosition
    local bp          = Instance.new("BodyPosition")
    bp.MaxForce       = Vector3.new(0, 4000, 0)
    bp.Position       = position + Vector3.new(0, 1.5, 0)
    bp.D              = 500
    bp.P              = 5000
    bp.Parent         = part

    -- Slow spin
    local bv          = Instance.new("BodyAngularVelocity")
    bv.MaxTorque      = Vector3.new(0, math.huge, 0)
    bv.AngularVelocity = Vector3.new(0, 2, 0)
    bv.Parent         = part

    -- Neon glow for gems
    if isGem then
        local light       = Instance.new("PointLight")
        light.Brightness  = 3
        light.Color       = GEM_COLOR
        light.Range       = 12
        light.Parent      = part
    end

    part.Parent = CoinFolder

    -- Auto-despawn after 30 seconds if uncollected
    game:GetService("Debris"):AddItem(part, 30)
    return part
end

-- Spawn a batch of coins around a random position in the world area
local function SpawnCoinBatch(worldData)
    local count   = worldData.CoinsPerBatch
    local gemChance = worldData.GemChance

    local ARENA_RADIUS = 200
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local dist  = math.random() * ARENA_RADIUS
        local x     = math.cos(angle) * dist
        local z     = math.sin(angle) * dist
        local y     = 3

        local isGem = math.random() < gemChance
        MakeCoinPart(Vector3.new(x, y, z), isGem, worldData.Id)
    end
end

-- ─── COIN COLLECTION ──────────────────────────────────────────────────────────
-- Every heartbeat, check if any player is within pickup radius of coins.
local COLLECT_DISTANCE = GameData.CoinPickupRadius

local function GetPickupRadius(player)
    local data = DataManager and DataManager.GetData(player)
    if not data then return COLLECT_DISTANCE end
    local bonus = GameData.GetUpgradeValue("coin_magnet", data.Upgrades.coin_magnet or 0)
    return COLLECT_DISTANCE + bonus
end

local function GetCoinValue(player, isGem)
    if not DataManager then return 1 end
    local data = DataManager.GetData(player)
    if not data then return 1 end

    local worldData   = GameData.WorldById[data.CurrentWorld] or GameData.Worlds[1]
    local worldMult   = worldData.CoinMultiplier
    local valueMult   = GameData.GetUpgradeValue("coin_value", data.Upgrades.coin_value or 0)
    local rebirthMult = GameData.Rebirth.RebirthMultiplier ^ data.Rebirths
    local petMult     = DataManager.ComputePetMultiplier(player)

    -- Check active boosts
    local boostMult = 1
    local now = os.time()
    for _, boost in ipairs(data.ActiveBoosts or {}) do
        if boost.BoostType == "CoinMultiplier" and boost.ExpiresAt > now then
            boostMult = boostMult * boost.BoostValue
        end
    end

    local baseValue = isGem and GameData.GemValue or 1
    local total = baseValue * worldMult * (1 + valueMult) * rebirthMult * petMult * boostMult
    return math.max(1, math.floor(total))
end

RunService.Heartbeat:Connect(function()
    if not DataManager then return end
    local coins = CoinFolder:GetChildren()
    if #coins == 0 then return end

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local radius = GetPickupRadius(player)
        local pos    = root.Position

        for _, coin in ipairs(coins) do
            if not coin:IsDescendantOf(CoinFolder) then continue end
            if coin:GetAttribute("Collected") then continue end

            local dist = (coin.Position - pos).Magnitude
            if dist <= radius then
                coin:SetAttribute("Collected", true)

                local isGem = coin:GetAttribute("IsGem")
                local value = GetCoinValue(player, isGem)

                if isGem then
                    DataManager.AddCurrency(player, "Gems", math.max(1, math.floor(value / GameData.GemValue)))
                else
                    DataManager.AddCurrency(player, "Coins", value)
                end

                -- Notify client for effect + HUD update
                SpawnCoinEffect:FireClient(player, coin.Position, isGem, value)
                UpdatePlayerData:FireClient(player, DataManager.GetData(player))

                coin:Destroy()
            end
        end
    end
end)

-- ─── WORLD COIN SPAWN LOOP ────────────────────────────────────────────────────
task.spawn(function()
    -- Simple single-world spawner for now; can be per-world later
    local SPAWN_INTERVAL = 0.5
    while true do
        task.wait(SPAWN_INTERVAL)
        if #Players:GetPlayers() == 0 then continue end

        -- Spawn for the "main" world (world 1 data); in a real game
        -- you'd have separate zones and only spawn in active ones.
        local worldData = GameData.Worlds[1]
        if #CoinFolder:GetChildren() < 200 then
            SpawnCoinBatch(worldData)
        end
    end
end)

-- ─── REBIRTH ──────────────────────────────────────────────────────────────────
Rebirth.OnServerEvent:Connect(function(player)
    if not DataManager then return end
    local data = DataManager.GetData(player)
    if not data then return end

    local required = GameData.GetRebirthRequirement(data.Rebirths)
    if data.TotalCoins < required then
        -- Not enough total coins
        return
    end

    -- Perform rebirth
    data.Rebirths      = data.Rebirths + 1
    data.Coins         = 0
    data.TotalCoins    = 0
    data.Pets          = {}
    data.EquippedPets  = {}

    -- Keep upgrades? (design choice — yes for our game)
    -- Award gems
    local gemReward = GameData.Rebirth.RewardGems
                    + (data.Rebirths * GameData.Rebirth.RewardGemsPerRebirth)
    DataManager.AddCurrency(player, "Gems", gemReward)

    -- Unlock next world if eligible
    for _, world in ipairs(GameData.Worlds) do
        if data.Rebirths >= world.RequiredRebirths then
            data.CurrentWorld = math.max(data.CurrentWorld, world.Id)
        end
    end

    UpdatePlayerData:FireClient(player, data)
    print(string.format("[GameManager] %s rebirthed! Now at rebirth %d", player.Name, data.Rebirths))
end)

-- ─── WORLD TELEPORT ───────────────────────────────────────────────────────────
TeleportWorld.OnServerEvent:Connect(function(player, worldId)
    if not DataManager then return end
    local data = DataManager.GetData(player)
    if not data then return end

    local world = GameData.WorldById[worldId]
    if not world then return end

    if data.Rebirths < world.RequiredRebirths then return end  -- gate check

    data.CurrentWorld = worldId
    UpdatePlayerData:FireClient(player, data)
end)

-- ─── DATA ON JOIN ─────────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    -- Wait for data to load then broadcast to client
    task.spawn(function()
        task.wait(1)  -- brief delay for DataManager to finish loading
        local data = DataManager and DataManager.GetData(player)
        if data then
            UpdatePlayerData:FireClient(player, data)
        end
    end)
end)

-- ─── REMOTE FUNCTIONS ─────────────────────────────────────────────────────────
RemoteFunctions:WaitForChild("GetPlayerData").OnServerInvoke = function(player)
    if not DataManager then return nil end
    return DataManager.GetData(player)
end

RemoteFunctions:WaitForChild("GetLeaderboard").OnServerInvoke = function(_player)
    -- Return top 10 by TotalCoins from connected players (real game: use OrderedDataStore)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local d = DataManager and DataManager.GetData(p)
        if d then
            table.insert(list, {
                Name      = p.Name,
                Rebirths  = d.Rebirths,
                TotalCoins = d.TotalCoins,
                Gems      = d.Gems,
            })
        end
    end
    table.sort(list, function(a, b) return a.Rebirths > b.Rebirths end)
    return list
end

-- ─── BUY UPGRADE ──────────────────────────────────────────────────────────────
RemoteEvents:WaitForChild("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeId)
    if not DataManager then return end
    local data = DataManager.GetData(player)
    if not data then return end

    local upg = GameData.UpgradeById[upgradeId]
    if not upg then return end

    local currentLevel = data.Upgrades[upgradeId] or 0
    if currentLevel >= upg.MaxLevel then return end

    local cost = GameData.GetUpgradeCost(upgradeId, currentLevel)
    local ok   = DataManager.SpendCurrency(player, upg.Currency, cost)
    if not ok then return end

    data.Upgrades[upgradeId] = currentLevel + 1
    UpdatePlayerData:FireClient(player, data)
end)

-- ─── BUY SHOP ITEM ────────────────────────────────────────────────────────────
RemoteEvents:WaitForChild("BuyShopItem").OnServerEvent:Connect(function(player, itemId)
    if not DataManager then return end
    local data = DataManager.GetData(player)
    if not data then return end

    local item = GameData.ShopById[itemId]
    if not item then return end

    local ok = DataManager.SpendCurrency(player, item.Currency, item.Cost)
    if not ok then return end

    if item.BoostType == "PetStorage" then
        data.PetStorageMax = (data.PetStorageMax or GameData.MaxStoredPets) + item.BoostValue
    else
        -- Add timed boost
        local now = os.time()
        table.insert(data.ActiveBoosts, {
            BoostType  = item.BoostType,
            BoostValue = item.BoostValue,
            ExpiresAt  = item.BoostDuration > 0 and (now + item.BoostDuration) or math.huge,
        })
    end

    UpdatePlayerData:FireClient(player, data)
end)

print("[GameManager] Initialized — Cosmic Pet Simulator is running!")
