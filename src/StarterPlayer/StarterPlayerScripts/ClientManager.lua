--[[
    ClientManager.lua  (LocalScript)
    Cosmic Pet Simulator — Client-side: receives server data, manages local
    state, handles coin sparkle effects, boost timers, daily reward prompts.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Modules    = ReplicatedStorage:WaitForChild("Modules")
local GameData   = require(Modules:WaitForChild("GameData"))
local PetData    = require(Modules:WaitForChild("PetData"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local UpdatePlayerData = RemoteEvents:WaitForChild("UpdatePlayerData")
local SpawnCoinEffect  = RemoteEvents:WaitForChild("SpawnCoinEffect")
local OpenEggResult    = RemoteEvents:WaitForChild("OpenEggResult")

-- ─── LOCAL STATE ──────────────────────────────────────────────────────────────
local LocalData = {}        -- mirror of server data
local MainGui   = nil       -- reference to MainGui ScreenGui

-- ─── WAIT FOR GUI ─────────────────────────────────────────────────────────────
task.spawn(function()
    MainGui = PlayerGui:WaitForChild("MainGui", 15)
end)

-- ─── UTILITIES ────────────────────────────────────────────────────────────────
local function FormatNumber(n)
    if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
    if n >= 1e9  then return string.format("%.2fB", n / 1e9)  end
    if n >= 1e6  then return string.format("%.2fM", n / 1e6)  end
    if n >= 1e3  then return string.format("%.1fK", n / 1e3)  end
    return tostring(math.floor(n))
end

-- ─── HUD UPDATE ───────────────────────────────────────────────────────────────
local function UpdateHUD(data)
    if not MainGui then return end

    local hud = MainGui:FindFirstChild("HUD")
    if not hud then return end

    local coinsLabel = hud:FindFirstChild("CoinsLabel", true)
    if coinsLabel then
        coinsLabel.Text = "🪙 " .. FormatNumber(data.Coins or 0)
    end

    local gemsLabel = hud:FindFirstChild("GemsLabel", true)
    if gemsLabel then
        gemsLabel.Text = "💎 " .. FormatNumber(data.Gems or 0)
    end

    local rebirthLabel = hud:FindFirstChild("RebirthLabel", true)
    if rebirthLabel then
        rebirthLabel.Text = "🔁 Rebirths: " .. (data.Rebirths or 0)
    end

    local worldLabel = hud:FindFirstChild("WorldLabel", true)
    if worldLabel then
        local world = GameData.WorldById[data.CurrentWorld or 1]
        worldLabel.Text = "🌍 " .. (world and world.Name or "Unknown")
    end

    -- Rebirth button: show required coins
    local rebirthBtn = hud:FindFirstChild("RebirthButton", true)
    if rebirthBtn then
        local req = GameData.GetRebirthRequirement(data.Rebirths or 0)
        local canRebirth = (data.TotalCoins or 0) >= req
        rebirthBtn.BackgroundColor3 = canRebirth
            and Color3.fromRGB(80, 200, 80)
            or  Color3.fromRGB(80, 80, 80)
        local btnLabel = rebirthBtn:FindFirstChild("Label")
        if btnLabel then
            btnLabel.Text = canRebirth
                and "REBIRTH!\n(" .. FormatNumber(req) .. " coins)"
                or  "Rebirth\n" .. FormatNumber(data.TotalCoins or 0) .. "/" .. FormatNumber(req)
        end
    end
end

-- ─── COIN EFFECT ──────────────────────────────────────────────────────────────
-- Floating +N text that rises and fades
local function ShowCoinEffect(worldPos, isGem, value)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
    if not onScreen then return end

    local bill = Instance.new("BillboardGui")
    bill.Size               = UDim2.new(0, 80, 0, 40)
    bill.StudsOffset        = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop        = true
    bill.LightInfluence     = 0
    bill.Adornee            = workspace:FindFirstChildWhichIsA("BasePart") -- fallback

    -- Use a part at worldPos as adornee
    local part = Instance.new("Part")
    part.Size        = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored    = true
    part.CanCollide  = false
    part.Transparency = 1
    part.CFrame      = CFrame.new(worldPos)
    part.Parent      = workspace

    bill.Adornee = part
    bill.Parent  = part

    local label           = Instance.new("TextLabel")
    label.Size            = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font            = Enum.Font.GothamBold
    label.TextScaled      = true
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Text            = (isGem and "💎 +" or "+") .. FormatNumber(value)
    label.TextColor3      = isGem
        and Color3.fromRGB(100, 220, 255)
        or  Color3.fromRGB(255, 220, 50)
    label.Parent          = bill

    -- Tween: float up and fade out
    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(label, tweenInfo, {
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })
    tween:Play()

    task.delay(1.2, function()
        part:Destroy()
    end)
end

SpawnCoinEffect.OnClientEvent:Connect(ShowCoinEffect)

-- ─── EGG RESULT POPUP ─────────────────────────────────────────────────────────
OpenEggResult.OnClientEvent:Connect(function(result)
    if not result or result == "storage_full" then
        -- Show "storage full" notification
        if MainGui then
            local notif = MainGui:FindFirstChild("NotifLabel", true)
            if notif then
                notif.Text    = "⚠ Storage Full! Buy more slots!"
                notif.Visible = true
                task.delay(3, function() notif.Visible = false end)
            end
        end
        return
    end

    -- Find/show the hatch result panel
    if not MainGui then return end
    local panel = MainGui:FindFirstChild("HatchResultPanel", true)
    if not panel then return end

    local rarityData  = PetData.Rarities[result.Rarity]
    local petNameLabel = panel:FindFirstChild("PetNameLabel", true)
    local rarityLabel  = panel:FindFirstChild("RarityLabel", true)

    if petNameLabel then
        petNameLabel.Text      = result.PetName
        petNameLabel.TextColor3 = rarityData and rarityData.Color or Color3.new(1,1,1)
    end
    if rarityLabel then
        rarityLabel.Text       = result.Rarity
        rarityLabel.TextColor3 = rarityData and rarityData.Color or Color3.new(1,1,1)
    end

    panel.Visible = true

    -- Bounce animation
    panel.Size = UDim2.new(0, 10, 0, 10)
    TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 320, 0, 200)
    }):Play()

    -- If Divine or Mythical, show screen shake + confetti effect
    if result.Rarity == "Divine" or result.Rarity == "Mythical" then
        task.spawn(function()
            local camera = workspace.CurrentCamera
            if not camera then return end
            for i = 1, 8 do
                camera.CFrame = camera.CFrame * CFrame.Angles(
                    math.rad(math.random(-2, 2)),
                    math.rad(math.random(-2, 2)),
                    0
                )
                task.wait(0.05)
            end
        end)
    end

    task.delay(4, function()
        TweenService:Create(panel, TweenInfo.new(0.3), { Size = UDim2.new(0, 0, 0, 0) }):Play()
        task.wait(0.3)
        panel.Visible = false
    end)
end)

-- ─── DATA SYNC ────────────────────────────────────────────────────────────────
UpdatePlayerData.OnClientEvent:Connect(function(data)
    LocalData = data
    UpdateHUD(data)

    -- Also refresh pet display (signal PetFollower)
    local rf = ReplicatedStorage:FindFirstChild("_ClientDataSignal")
    if rf then
        rf.Value = game:GetService("HttpService"):JSONEncode(data)
    end
end)

-- ─── INITIAL DATA FETCH ───────────────────────────────────────────────────────
task.spawn(function()
    task.wait(2)  -- wait for server to push first update
    local rf = RemoteFunctions:WaitForChild("GetPlayerData", 10)
    if rf then
        local data = rf:InvokeServer()
        if data then
            LocalData = data
            UpdateHUD(data)
        end
    end
end)

-- ─── PARTICLE SPARKLES ON EQUIPPED PET (ambient effect) ──────────────────────
-- Spawned by PetFollower.lua; this script handles ambient world particles.

-- ─── KEYBOARD SHORTCUTS ───────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.E then
        -- Toggle shop GUI
        if MainGui then
            local shop = MainGui:FindFirstChild("ShopGui")
            if shop then shop.Visible = not shop.Visible end
        end
    elseif input.KeyCode == Enum.KeyCode.Q then
        -- Toggle pets GUI
        if MainGui then
            local pets = MainGui:FindFirstChild("PetsGui")
            if pets then pets.Visible = not pets.Visible end
        end
    end
end)

print("[ClientManager] Initialized.")
