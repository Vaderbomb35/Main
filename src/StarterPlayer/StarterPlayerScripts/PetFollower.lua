--[[
    PetFollower.lua  (LocalScript)
    Cosmic Pet Simulator — Renders equipped pet models on the client,
    makes them orbit/follow the player with smooth animations and
    particle glow effects based on rarity.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Modules  = ReplicatedStorage:WaitForChild("Modules")
local PetData  = require(Modules:WaitForChild("PetData"))
local GameData = require(Modules:WaitForChild("GameData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateData   = RemoteEvents:WaitForChild("UpdatePlayerData")

-- ─── PET MODEL FOLDER ────────────────────────────────────────────────────────
local PetModels = workspace:FindFirstChild("PetModels")
    or Instance.new("Folder", workspace)
PetModels.Name = "PetModels"

-- Track currently displayed pets: [instanceId] = { model, orbitAngle }
local DisplayedPets = {}

-- ─── RARITY → PARTICLE EFFECT ────────────────────────────────────────────────
local RarityEmitterColors = {
    Common    = ColorSequence.new(Color3.fromRGB(200,200,200)),
    Uncommon  = ColorSequence.new(Color3.fromRGB(80,200,80)),
    Rare      = ColorSequence.new(Color3.fromRGB(60,130,220)),
    Epic      = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200,60,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100,0,200)),
    },
    Legendary = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,220,0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,150,0)),
    },
    Mythical  = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,60,60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,100)),
    },
    Divine    = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150,255,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,255)),
    },
}

local function AddGlowParticles(part, rarity)
    local rarityData = PetData.Rarities[rarity]
    if not rarityData or not rarityData.Glow then return end

    -- Sparkle emitter
    local emitter            = Instance.new("ParticleEmitter")
    emitter.Texture          = "rbxassetid://6401805476"  -- star texture
    emitter.Color            = RarityEmitterColors[rarity] or ColorSequence.new(Color3.new(1,1,1))
    emitter.LightEmission    = 0.9
    emitter.LightInfluence   = 0.1
    emitter.Rate             = rarity == "Divine" and 30 or rarity == "Mythical" and 20 or 12
    emitter.Size             = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.15),
        NumberSequenceKeypoint.new(1, 0),
    }
    emitter.Lifetime         = NumberRange.new(0.5, 1.5)
    emitter.Speed            = NumberRange.new(1, 3)
    emitter.SpreadAngle      = Vector2.new(180, 180)
    emitter.RotSpeed         = NumberRange.new(-180, 180)
    emitter.Rotation         = NumberRange.new(0, 360)
    emitter.Parent           = part

    -- Point light for glow effect
    local light            = Instance.new("PointLight")
    light.Brightness       = rarity == "Divine" and 5 or rarity == "Mythical" and 4 or 2.5
    light.Range            = rarity == "Divine" and 16 or rarity == "Mythical" and 12 or 8
    light.Color            = rarityData.Color
    light.Shadows          = false
    light.Parent           = part
end

-- ─── BUILD PET MODEL ─────────────────────────────────────────────────────────
local function BuildPetModel(petDef)
    -- Simple sphere pet (replace with actual Roblox model via InsertService
    -- when you have real assets — this is the fallback shape)
    local model  = Instance.new("Model")
    model.Name   = petDef.Id

    local body   = Instance.new("Part")
    body.Name    = "HumanoidRootPart"
    body.Size    = Vector3.new(1.5, 1.5, 1.5) * petDef.Scale
    body.Shape   = Enum.PartType.Ball
    body.Material = Enum.Material.SmoothPlastic
    body.Color   = petDef.Color
    body.Anchored = true
    body.CanCollide = false
    body.CastShadow = true
    body.Parent  = model
    model.PrimaryPart = body

    -- Head with eyes (cute factor)
    local eyeOffsets = { Vector3.new(-0.25, 0.2, -0.65), Vector3.new(0.25, 0.2, -0.65) }
    for _, offset in ipairs(eyeOffsets) do
        local eye        = Instance.new("Part")
        eye.Size         = Vector3.new(0.2, 0.2, 0.1) * petDef.Scale
        eye.Shape        = Enum.PartType.Ball
        eye.Material     = Enum.Material.Neon
        eye.Color        = Color3.new(0, 0, 0)
        eye.Anchored     = true
        eye.CanCollide   = false
        eye.CastShadow   = false
        eye.Position     = body.Position + (offset * petDef.Scale)
        eye.Parent       = model

        -- Weld to body
        local weld       = Instance.new("WeldConstraint")
        weld.Part0       = body
        weld.Part1       = eye
        weld.Parent      = body
    end

    -- Rarity nametag billboard
    local bill            = Instance.new("BillboardGui")
    bill.Size             = UDim2.new(0, 120, 0, 40)
    bill.StudsOffset      = Vector3.new(0, 2.5 * petDef.Scale, 0)
    bill.AlwaysOnTop      = false
    bill.LightInfluence   = 0
    bill.Adornee          = body
    bill.Parent           = model

    local nameLabel       = Instance.new("TextLabel")
    nameLabel.Size        = UDim2.fromScale(1, 1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font        = Enum.Font.GothamBold
    nameLabel.TextScaled  = true
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.Text        = petDef.Name
    local rarityDef       = PetData.Rarities[petDef.Rarity]
    nameLabel.TextColor3  = rarityDef and rarityDef.Color or Color3.new(1,1,1)
    nameLabel.Parent      = bill

    AddGlowParticles(body, petDef.Rarity)

    model.Parent = PetModels
    return model, body
end

-- ─── ORBIT LAYOUT ────────────────────────────────────────────────────────────
local ORBIT_RADIUS  = 5     -- studs from player
local ORBIT_HEIGHT  = 3     -- studs above ground
local ORBIT_SPEED   = 1     -- radians per second

-- Given equipped pet index and total count, return orbit angle offset
local function OrbitAngleOffset(idx, total)
    return (idx - 1) * ((math.pi * 2) / math.max(total, 1))
end

-- ─── SYNC PETS FROM DATA ─────────────────────────────────────────────────────
local function SyncPets(data)
    if not data then return end
    local equipped = data.EquippedPets or {}

    -- Remove models for unequipped pets
    for instanceId, entry in pairs(DisplayedPets) do
        local stillEquipped = false
        for _, eid in ipairs(equipped) do
            if eid == instanceId then stillEquipped = true break end
        end
        if not stillEquipped then
            entry.model:Destroy()
            DisplayedPets[instanceId] = nil
        end
    end

    -- Add models for newly equipped pets
    for idx, instanceId in ipairs(equipped) do
        if not DisplayedPets[instanceId] then
            -- Find pet definition
            local petId
            for _, petEntry in ipairs(data.Pets or {}) do
                if petEntry.InstanceId == instanceId then
                    petId = petEntry.PetId
                    break
                end
            end
            if petId then
                local petDef = PetData.PetById[petId]
                if petDef then
                    local model, body = BuildPetModel(petDef)
                    DisplayedPets[instanceId] = {
                        model       = model,
                        body        = body,
                        orbitOffset = OrbitAngleOffset(idx, #equipped),
                        orbitAngle  = 0,
                    }
                end
            end
        end
    end
end

-- ─── PER-FRAME PET MOVEMENT ──────────────────────────────────────────────────
local function GetPlayerRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

RunService.RenderStepped:Connect(function(dt)
    local root = GetPlayerRoot()
    if not root then return end
    local playerPos = root.Position

    local petList = {}
    for _, entry in pairs(DisplayedPets) do
        table.insert(petList, entry)
    end
    local totalPets = #petList

    for i, entry in ipairs(petList) do
        entry.orbitAngle = entry.orbitAngle + (ORBIT_SPEED * dt)
        local angle = entry.orbitAngle + entry.orbitOffset

        -- Bob up/down
        local bobY = math.sin(entry.orbitAngle * 2 + i) * 0.4

        local targetPos = playerPos + Vector3.new(
            math.cos(angle) * ORBIT_RADIUS,
            ORBIT_HEIGHT + bobY,
            math.sin(angle) * ORBIT_RADIUS
        )

        -- Smooth lerp
        local body = entry.body
        if body and body.Parent then
            body.CFrame = body.CFrame:Lerp(CFrame.new(targetPos), math.min(1, dt * 10))

            -- Eyes: face outward from center
            local faceDir = (targetPos - playerPos).Unit
            body.CFrame = CFrame.new(body.CFrame.Position, body.CFrame.Position + faceDir)

            -- Sync eye welds
            for _, weld in ipairs(body:GetChildren()) do
                if weld:IsA("WeldConstraint") and weld.Part1 then
                    -- welds auto-update
                end
            end
        end
    end
end)

-- ─── LISTEN FOR DATA UPDATES ─────────────────────────────────────────────────
UpdateData.OnClientEvent:Connect(function(data)
    SyncPets(data)
end)

-- Initial sync
task.spawn(function()
    task.wait(2)
    local rf = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetPlayerData", 10)
    if rf then
        local data = rf:InvokeServer()
        if data then SyncPets(data) end
    end
end)

print("[PetFollower] Initialized.")
