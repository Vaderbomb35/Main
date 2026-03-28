--[[
    MainHUD.lua  (LocalScript inside MainGui ScreenGui)
    Cosmic Pet Simulator — Builds and manages the entire UI:
      • HUD bar (coins, gems, rebirths, world)
      • Hatch panel (egg selection + hatching animation)
      • Pets panel (inventory + equip/unequip)
      • Shop panel (upgrades + boost items)
      • Daily reward popup
      • Settings / world select
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local ScreenGui   = script.Parent  -- the ScreenGui this script lives inside

local Modules  = ReplicatedStorage:WaitForChild("Modules")
local GameData = require(Modules:WaitForChild("GameData"))
local PetData  = require(Modules:WaitForChild("PetData"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local HatchEgg      = RemoteEvents:WaitForChild("HatchEgg")
local EquipPet      = RemoteEvents:WaitForChild("EquipPet")
local UnequipPet    = RemoteEvents:WaitForChild("UnequipPet")
local BuyUpgrade    = RemoteEvents:WaitForChild("BuyUpgrade")
local BuyShopItem   = RemoteEvents:WaitForChild("BuyShopItem")
local RebirthEvent  = RemoteEvents:WaitForChild("Rebirth")
local TeleportWorld = RemoteEvents:WaitForChild("TeleportWorld")

-- ─── HELPERS ──────────────────────────────────────────────────────────────────
local function FormatNumber(n)
    if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
    if n >= 1e9  then return string.format("%.2fB", n / 1e9)  end
    if n >= 1e6  then return string.format("%.2fM", n / 1e6)  end
    if n >= 1e3  then return string.format("%.1fK", n / 1e3)  end
    return tostring(math.floor(n))
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
end

local function MakePadding(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.Parent = parent
end

local function MakeLabel(parent, text, size, pos, color, font, textColor)
    local l = Instance.new("TextLabel")
    l.Size   = size or UDim2.fromScale(1, 1)
    l.Position = pos or UDim2.new()
    l.BackgroundTransparency = 1
    l.Font   = font or Enum.Font.GothamBold
    l.TextScaled = true
    l.TextColor3 = textColor or Color3.new(1, 1, 1)
    l.TextStrokeTransparency = 0.6
    l.Text   = text
    l.Parent = parent
    return l
end

local function MakeButton(parent, text, size, pos, bgColor, textColor)
    local btn = Instance.new("TextButton")
    btn.Size  = size or UDim2.new(0, 150, 0, 45)
    btn.Position = pos or UDim2.new()
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(60, 120, 220)
    btn.BorderSizePixel  = 0
    btn.Font  = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.TextColor3 = textColor or Color3.new(1, 1, 1)
    btn.Text  = text
    MakeCorner(btn, 8)
    btn.Parent = parent

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = bgColor
                and Color3.new(
                    math.min(1, bgColor.R + 0.15),
                    math.min(1, bgColor.G + 0.15),
                    math.min(1, bgColor.B + 0.15)
                )
                or Color3.fromRGB(90, 150, 255)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = bgColor or Color3.fromRGB(60, 120, 220)
        }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.05), { Size = UDim2.new(
            btn.Size.X.Scale * 0.95, btn.Size.X.Offset * 0.95,
            btn.Size.Y.Scale * 0.95, btn.Size.Y.Offset * 0.95
        )}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), { Size = size or UDim2.new(0, 150, 0, 45) }):Play()
    end)

    return btn
end

local function Panel(parent, name, size, pos, color, alpha)
    local f = Instance.new("Frame")
    f.Name  = name
    f.Size  = size
    f.Position = pos or UDim2.new()
    f.BackgroundColor3 = color or Color3.fromRGB(20, 20, 40)
    f.BackgroundTransparency = alpha or 0.1
    f.BorderSizePixel = 0
    MakeCorner(f, 14)
    f.Parent = parent
    return f
end

-- ─── LOCAL DATA ───────────────────────────────────────────────────────────────
local LocalData = {}

-- ─── ① HUD BAR (top) ──────────────────────────────────────────────────────────
local HUD = Panel(ScreenGui, "HUD",
    UDim2.new(1, -20, 0, 70),
    UDim2.new(0, 10, 0, 10),
    Color3.fromRGB(15, 15, 30), 0.05
)

-- Coins
local coinFrame = Panel(HUD, "CoinFrame", UDim2.new(0, 160, 0, 44), UDim2.new(0, 10, 0.5, -22), Color3.fromRGB(40,30,10), 0.1)
MakeLabel(coinFrame, "🪙 0", nil, nil, nil, nil, Color3.fromRGB(255,220,50)).Name = "CoinsLabel"

-- Gems
local gemFrame = Panel(HUD, "GemFrame", UDim2.new(0, 140, 0, 44), UDim2.new(0, 180, 0.5, -22), Color3.fromRGB(10,30,40), 0.1)
MakeLabel(gemFrame, "💎 0", nil, nil, nil, nil, Color3.fromRGB(100,220,255)).Name = "GemsLabel"

-- Rebirth counter
local rebirthFrame = Panel(HUD, "RebirthFrame", UDim2.new(0, 140, 0, 44), UDim2.new(0, 330, 0.5, -22), Color3.fromRGB(30,10,40), 0.1)
MakeLabel(rebirthFrame, "🔁 0", nil, nil, nil, nil, Color3.fromRGB(180,100,255)).Name = "RebirthLabel"

-- World label
local worldFrame = Panel(HUD, "WorldFrame", UDim2.new(0, 180, 0, 44), UDim2.new(0, 480, 0.5, -22), Color3.fromRGB(10,30,10), 0.1)
MakeLabel(worldFrame, "🌍 Starter Meadow", nil, nil, nil, nil, Color3.fromRGB(100,255,100)).Name = "WorldLabel"

-- Nav buttons (right side)
local navButtons = {
    { name = "Hatch",    label = "🥚 Hatch",   color = Color3.fromRGB(200,120,30)  },
    { name = "Pets",     label = "🐾 Pets",    color = Color3.fromRGB(80,160,80)   },
    { name = "Shop",     label = "🛒 Shop",    color = Color3.fromRGB(60,120,220)  },
    { name = "Worlds",   label = "🌍 Worlds",  color = Color3.fromRGB(40,140,140)  },
    { name = "Rebirth",  label = "🔁 Rebirth", color = Color3.fromRGB(180,60,200)  },
}
for i, nb in ipairs(navButtons) do
    local btn = MakeButton(HUD, nb.label,
        UDim2.new(0, 100, 0, 44),
        UDim2.new(1, -530 + (i-1)*108, 0.5, -22),
        nb.color
    )
    btn.Name = nb.name .. "Button"
end

-- ─── NOTIFICATION LABEL ───────────────────────────────────────────────────────
local notif = MakeLabel(ScreenGui, "", UDim2.new(0, 400, 0, 50),
    UDim2.new(0.5, -200, 0, 90),
    Color3.fromRGB(30,10,10),
    Enum.Font.GothamBold,
    Color3.fromRGB(255,100,100)
)
notif.Name    = "NotifLabel"
notif.Visible = false
notif.BackgroundColor3 = Color3.fromRGB(60,20,20)
notif.BackgroundTransparency = 0.2

-- ─── ② HATCH PANEL ────────────────────────────────────────────────────────────
local HatchPanel = Panel(ScreenGui, "HatchPanel",
    UDim2.new(0, 620, 0, 460),
    UDim2.new(0.5, -310, 0.5, -230),
    Color3.fromRGB(20, 15, 35), 0.05
)
HatchPanel.Visible = false
MakePadding(HatchPanel, 14)

MakeLabel(HatchPanel, "🥚 Egg Hatcher", UDim2.new(1, 0, 0, 40), UDim2.new(), nil, nil, Color3.fromRGB(255,200,50))

-- Close button
local hatchClose = MakeButton(HatchPanel, "✕",
    UDim2.new(0, 36, 0, 36), UDim2.new(1, -46, 0, 4),
    Color3.fromRGB(180,40,40)
)
hatchClose.MouseButton1Click:Connect(function() HatchPanel.Visible = false end)

-- Egg scroll frame
local eggScroll = Instance.new("ScrollingFrame")
eggScroll.Name             = "EggScroll"
eggScroll.Size             = UDim2.new(1, 0, 1, -50)
eggScroll.Position         = UDim2.new(0, 0, 0, 50)
eggScroll.BackgroundTransparency = 1
eggScroll.BorderSizePixel  = 0
eggScroll.ScrollBarThickness = 6
eggScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
eggScroll.CanvasSize       = UDim2.new()
eggScroll.Parent           = HatchPanel

local eggGrid = Instance.new("UIGridLayout")
eggGrid.CellSize    = UDim2.new(0, 160, 0, 200)
eggGrid.CellPadding = UDim2.new(0, 12, 0, 12)
eggGrid.Parent      = eggScroll

-- Populate eggs
for _, egg in ipairs(PetData.Eggs) do
    local card = Panel(eggScroll, egg.Id, UDim2.new(), UDim2.new(), egg.Color, 0.2)

    local nameL = MakeLabel(card, egg.Name,
        UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 4),
        nil, nil, egg.Color
    )

    local costCurrency = egg.Currency == "Gems" and "💎" or "🪙"
    MakeLabel(card, costCurrency .. " " .. FormatNumber(egg.Cost),
        UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 34),
        nil, Enum.Font.Gotham, Color3.fromRGB(200,200,200)
    )

    local hatchBtn = MakeButton(card, "Hatch!",
        UDim2.new(0.85, 0, 0, 36), UDim2.new(0.075, 0, 1, -46),
        Color3.fromRGB(80,200,80)
    )
    hatchBtn.MouseButton1Click:Connect(function()
        HatchEgg:FireServer(egg.Id)
    end)

    -- x5 hatch button
    local hatch5Btn = MakeButton(card, "x5",
        UDim2.new(0.85, 0, 0, 28), UDim2.new(0.075, 0, 1, -14),
        Color3.fromRGB(60,160,60)
    )
    hatch5Btn.MouseButton1Click:Connect(function()
        for _ = 1, 5 do
            task.wait(0.1)
            HatchEgg:FireServer(egg.Id)
        end
    end)
end

-- ─── HATCH RESULT PANEL ───────────────────────────────────────────────────────
local HatchResultPanel = Panel(ScreenGui, "HatchResultPanel",
    UDim2.new(0, 320, 0, 200),
    UDim2.new(0.5, -160, 0.3, -100),
    Color3.fromRGB(20, 20, 40), 0.05
)
HatchResultPanel.Visible = false
HatchResultPanel.ZIndex  = 20

MakeLabel(HatchResultPanel, "NEW PET!",
    UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 10),
    nil, nil, Color3.fromRGB(255,255,100)
).ZIndex = 21

local petNameLabel = MakeLabel(HatchResultPanel, "",
    UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 54),
    nil, Enum.Font.GothamBold, Color3.new(1,1,1)
)
petNameLabel.Name   = "PetNameLabel"
petNameLabel.ZIndex = 21

local rarityLabel = MakeLabel(HatchResultPanel, "",
    UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 100),
    nil, Enum.Font.GothamBold, Color3.new(1,1,1)
)
rarityLabel.Name   = "RarityLabel"
rarityLabel.ZIndex = 21

-- ─── ③ PETS PANEL ─────────────────────────────────────────────────────────────
local PetsPanel = Panel(ScreenGui, "PetsGui",
    UDim2.new(0, 660, 0, 500),
    UDim2.new(0.5, -330, 0.5, -250),
    Color3.fromRGB(15, 25, 15), 0.05
)
PetsPanel.Visible = false
MakePadding(PetsPanel, 12)

MakeLabel(PetsPanel, "🐾 My Pets", UDim2.new(1, 0, 0, 36), UDim2.new(), nil, nil, Color3.fromRGB(100,255,100))

local petsClose = MakeButton(PetsPanel, "✕",
    UDim2.new(0, 36, 0, 36), UDim2.new(1, -46, 0, 2),
    Color3.fromRGB(180,40,40)
)
petsClose.MouseButton1Click:Connect(function() PetsPanel.Visible = false end)

-- Equipped count label
local equippedLabel = MakeLabel(PetsPanel, "Equipped: 0/3",
    UDim2.new(0, 200, 0, 24), UDim2.new(0, 0, 0, 40),
    nil, Enum.Font.Gotham, Color3.fromRGB(180,180,180)
)
equippedLabel.Name = "EquippedLabel"

local petsScroll = Instance.new("ScrollingFrame")
petsScroll.Size             = UDim2.new(1, 0, 1, -70)
petsScroll.Position         = UDim2.new(0, 0, 0, 70)
petsScroll.BackgroundTransparency = 1
petsScroll.BorderSizePixel  = 0
petsScroll.ScrollBarThickness = 6
petsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
petsScroll.CanvasSize       = UDim2.new()
petsScroll.Parent           = PetsPanel

local petsGrid = Instance.new("UIGridLayout")
petsGrid.CellSize    = UDim2.new(0, 130, 0, 150)
petsGrid.CellPadding = UDim2.new(0, 8, 0, 8)
petsGrid.Parent      = petsScroll

-- Refresh pets panel from data
local function RefreshPetsPanel(data)
    -- Clear existing cards
    for _, child in ipairs(petsScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if not data then return end

    local maxSlots = GameData.MaxEquippedPets + GameData.GetUpgradeValue("pet_capacity", data.Upgrades and data.Upgrades.pet_capacity or 0)
    equippedLabel.Text = "Equipped: " .. #data.EquippedPets .. "/" .. math.floor(maxSlots)

    for _, petEntry in ipairs(data.Pets or {}) do
        local petDef    = PetData.PetById[petEntry.PetId]
        if not petDef then continue end
        local rarityDef = PetData.Rarities[petDef.Rarity]

        local card = Panel(petsScroll, petEntry.InstanceId, UDim2.new(), UDim2.new(),
            rarityDef and Color3.new(
                rarityDef.Color.R * 0.2,
                rarityDef.Color.G * 0.2,
                rarityDef.Color.B * 0.2
            ) or Color3.fromRGB(30,30,40),
            0.1
        )

        MakeLabel(card, petDef.Name,
            UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 4),
            nil, nil, rarityDef and rarityDef.Color or Color3.new(1,1,1)
        )

        MakeLabel(card, petDef.Rarity,
            UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 36),
            nil, Enum.Font.Gotham, rarityDef and rarityDef.Color or Color3.new(1,1,1)
        )

        local mult = rarityDef and rarityDef.Multiplier or 1
        MakeLabel(card, "x" .. mult .. " coins",
            UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 60),
            nil, Enum.Font.Gotham, Color3.fromRGB(255,220,100)
        )

        local btnColor = petEntry.Equipped
            and Color3.fromRGB(180,40,40)
            or  Color3.fromRGB(60,160,60)
        local equipBtn = MakeButton(card,
            petEntry.Equipped and "Unequip" or "Equip",
            UDim2.new(0.85, 0, 0, 30),
            UDim2.new(0.075, 0, 1, -38),
            btnColor
        )
        equipBtn.MouseButton1Click:Connect(function()
            if petEntry.Equipped then
                UnequipPet:FireServer(petEntry.InstanceId)
            else
                EquipPet:FireServer(petEntry.InstanceId)
            end
        end)
    end
end

-- ─── ④ SHOP PANEL ─────────────────────────────────────────────────────────────
local ShopPanel = Panel(ScreenGui, "ShopGui",
    UDim2.new(0, 660, 0, 500),
    UDim2.new(0.5, -330, 0.5, -250),
    Color3.fromRGB(10, 15, 30), 0.05
)
ShopPanel.Visible = false
MakePadding(ShopPanel, 12)

MakeLabel(ShopPanel, "🛒 Shop & Upgrades", UDim2.new(1, 0, 0, 36), UDim2.new(), nil, nil, Color3.fromRGB(100,180,255))

local shopClose = MakeButton(ShopPanel, "✕",
    UDim2.new(0, 36, 0, 36), UDim2.new(1, -46, 0, 2),
    Color3.fromRGB(180,40,40)
)
shopClose.MouseButton1Click:Connect(function() ShopPanel.Visible = false end)

-- Tab buttons
local upgradesTab = MakeButton(ShopPanel, "Upgrades",
    UDim2.new(0, 130, 0, 34), UDim2.new(0, 0, 0, 44),
    Color3.fromRGB(60,120,200)
)
local boostsTab = MakeButton(ShopPanel, "Boosts",
    UDim2.new(0, 130, 0, 34), UDim2.new(0, 140, 0, 44),
    Color3.fromRGB(40,80,140)
)

local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Size             = UDim2.new(1, 0, 1, -88)
shopScroll.Position         = UDim2.new(0, 0, 0, 88)
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel  = 0
shopScroll.ScrollBarThickness = 6
shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopScroll.CanvasSize       = UDim2.new()
shopScroll.Parent           = ShopPanel

local shopList = Instance.new("UIListLayout")
shopList.Padding     = UDim.new(0, 8)
shopList.Parent      = shopScroll

local CurrentShopTab = "Upgrades"

local function RefreshShop(data)
    for _, child in ipairs(shopScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    if not data then return end

    if CurrentShopTab == "Upgrades" then
        for _, upg in ipairs(GameData.Upgrades) do
            local level = data.Upgrades and data.Upgrades[upg.Id] or 0
            local maxed = level >= upg.MaxLevel
            local cost  = maxed and 0 or GameData.GetUpgradeCost(upg.Id, level)

            local row = Panel(shopScroll, upg.Id,
                UDim2.new(1, -8, 0, 70), UDim2.new(),
                Color3.fromRGB(20,20,45), 0.1
            )
            MakePadding(row, 8)

            MakeLabel(row, upg.Name,
                UDim2.new(0.5, 0, 0, 26), UDim2.new(0, 0, 0, 0),
                nil, nil, Color3.fromRGB(200,200,255)
            )
            MakeLabel(row, upg.Description,
                UDim2.new(0.5, 0, 0, 20), UDim2.new(0, 0, 0, 28),
                nil, Enum.Font.Gotham, Color3.fromRGB(160,160,160)
            )
            MakeLabel(row, "Level: " .. level .. "/" .. upg.MaxLevel,
                UDim2.new(0.28, 0, 0, 26), UDim2.new(0.5, 4, 0, 0),
                nil, Enum.Font.Gotham, Color3.fromRGB(200,200,200)
            )

            local currIcon = upg.Currency == "Gems" and "💎" or "🪙"
            local buyBtn = MakeButton(row,
                maxed and "MAXED" or (currIcon .. " " .. FormatNumber(cost)),
                UDim2.new(0.22, 0, 0, 36),
                UDim2.new(0.77, 0, 0.5, -18),
                maxed and Color3.fromRGB(60,60,60) or Color3.fromRGB(60,160,60)
            )
            if not maxed then
                buyBtn.MouseButton1Click:Connect(function()
                    BuyUpgrade:FireServer(upg.Id)
                end)
            end
        end
    else
        -- Boosts tab
        for _, item in ipairs(GameData.ShopItems) do
            local row = Panel(shopScroll, item.Id,
                UDim2.new(1, -8, 0, 70), UDim2.new(),
                Color3.fromRGB(25,15,30), 0.1
            )
            MakePadding(row, 8)

            MakeLabel(row, item.Name,
                UDim2.new(0.55, 0, 0, 26), UDim2.new(0, 0, 0, 0),
                nil, nil, Color3.fromRGB(255,200,100)
            )
            MakeLabel(row, item.Description,
                UDim2.new(0.55, 0, 0, 20), UDim2.new(0, 0, 0, 28),
                nil, Enum.Font.Gotham, Color3.fromRGB(160,160,160)
            )

            local buyBtn = MakeButton(row,
                "💎 " .. item.Cost,
                UDim2.new(0.22, 0, 0, 36),
                UDim2.new(0.77, 0, 0.5, -18),
                Color3.fromRGB(120,60,200)
            )
            buyBtn.MouseButton1Click:Connect(function()
                BuyShopItem:FireServer(item.Id)
            end)
        end
    end
end

upgradesTab.MouseButton1Click:Connect(function()
    CurrentShopTab = "Upgrades"
    upgradesTab.BackgroundColor3 = Color3.fromRGB(60,120,200)
    boostsTab.BackgroundColor3   = Color3.fromRGB(40,80,140)
    RefreshShop(LocalData)
end)
boostsTab.MouseButton1Click:Connect(function()
    CurrentShopTab = "Boosts"
    boostsTab.BackgroundColor3   = Color3.fromRGB(120,60,200)
    upgradesTab.BackgroundColor3 = Color3.fromRGB(40,80,140)
    RefreshShop(LocalData)
end)

-- ─── ⑤ WORLDS PANEL ───────────────────────────────────────────────────────────
local WorldsPanel = Panel(ScreenGui, "WorldsGui",
    UDim2.new(0, 540, 0, 460),
    UDim2.new(0.5, -270, 0.5, -230),
    Color3.fromRGB(10, 20, 20), 0.05
)
WorldsPanel.Visible = false
MakePadding(WorldsPanel, 12)

MakeLabel(WorldsPanel, "🌍 World Select", UDim2.new(1, 0, 0, 36), UDim2.new(), nil, nil, Color3.fromRGB(100,255,160))

local worldsClose = MakeButton(WorldsPanel, "✕",
    UDim2.new(0, 36, 0, 36), UDim2.new(1, -46, 0, 2),
    Color3.fromRGB(180,40,40)
)
worldsClose.MouseButton1Click:Connect(function() WorldsPanel.Visible = false end)

local worldsList = Instance.new("ScrollingFrame")
worldsList.Size             = UDim2.new(1, 0, 1, -50)
worldsList.Position         = UDim2.new(0, 0, 0, 50)
worldsList.BackgroundTransparency = 1
worldsList.BorderSizePixel  = 0
worldsList.ScrollBarThickness = 6
worldsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
worldsList.CanvasSize       = UDim2.new()
worldsList.Parent           = WorldsPanel

local worldListLayout = Instance.new("UIListLayout")
worldListLayout.Padding = UDim.new(0, 8)
worldListLayout.Parent  = worldsList

local function RefreshWorlds(data)
    for _, child in ipairs(worldsList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    if not data then return end

    for _, world in ipairs(GameData.Worlds) do
        local unlocked = (data.Rebirths or 0) >= world.RequiredRebirths
        local current  = data.CurrentWorld == world.Id

        local row = Panel(worldsList, "world_" .. world.Id,
            UDim2.new(1, -8, 0, 80), UDim2.new(),
            current and Color3.fromRGB(20,60,20) or Color3.fromRGB(20,20,40),
            0.1
        )
        MakePadding(row, 8)

        MakeLabel(row, (current and "▶ " or "") .. world.Name,
            UDim2.new(0.55, 0, 0, 28), UDim2.new(0, 0, 0, 0),
            nil, nil, unlocked and Color3.fromRGB(100,255,100) or Color3.fromRGB(140,140,140)
        )
        MakeLabel(row, world.Description,
            UDim2.new(0.55, 0, 0, 22), UDim2.new(0, 0, 0, 30),
            nil, Enum.Font.Gotham, Color3.fromRGB(160,160,160)
        )
        MakeLabel(row, "Requires " .. world.RequiredRebirths .. " rebirths | x" .. world.CoinMultiplier .. " coins",
            UDim2.new(0.55, 0, 0, 18), UDim2.new(0, 0, 0, 56),
            nil, Enum.Font.Gotham,
            unlocked and Color3.fromRGB(255,220,80) or Color3.fromRGB(180,100,100)
        )

        local tpBtn = MakeButton(row,
            current and "Current" or (unlocked and "Travel Here" or "🔒 Locked"),
            UDim2.new(0.22, 0, 0, 40),
            UDim2.new(0.77, 0, 0.5, -20),
            current and Color3.fromRGB(40,100,40)
                or (unlocked and Color3.fromRGB(40,120,180) or Color3.fromRGB(60,60,60))
        )
        if unlocked and not current then
            tpBtn.MouseButton1Click:Connect(function()
                TeleportWorld:FireServer(world.Id)
                WorldsPanel.Visible = false
            end)
        end
    end
end

-- ─── ⑥ NAV BUTTON HANDLERS ────────────────────────────────────────────────────
local function HideAllPanels()
    HatchPanel.Visible  = false
    PetsPanel.Visible   = false
    ShopPanel.Visible   = false
    WorldsPanel.Visible = false
end

local NavPanelMap = {
    HatchButton   = HatchPanel,
    PetsButton    = PetsPanel,
    ShopButton    = ShopPanel,
    WorldsButton  = WorldsPanel,
}

for btnName, panel in pairs(NavPanelMap) do
    local btn = HUD:FindFirstChild(btnName, true)
    if btn then
        btn.MouseButton1Click:Connect(function()
            local wasVisible = panel.Visible
            HideAllPanels()
            panel.Visible = not wasVisible

            -- Refresh content on open
            if panel == ShopPanel then
                RefreshShop(LocalData)
            elseif panel == PetsPanel then
                RefreshPetsPanel(LocalData)
            elseif panel == WorldsPanel then
                RefreshWorlds(LocalData)
            end
        end)
    end
end

-- Rebirth button
local rebirthBtn = HUD:FindFirstChild("RebirthButton", true)
if rebirthBtn then
    rebirthBtn.MouseButton1Click:Connect(function()
        local data = LocalData
        if not data then return end
        local req = GameData.GetRebirthRequirement(data.Rebirths or 0)
        if (data.TotalCoins or 0) >= req then
            RebirthEvent:FireServer()
        end
    end)
end

-- ─── ⑦ DATA UPDATE HANDLER ────────────────────────────────────────────────────
local function OnDataUpdated(data)
    LocalData = data

    -- HUD
    local coinsLabel = HUD:FindFirstChild("CoinsLabel", true)
    if coinsLabel then coinsLabel.Text = "🪙 " .. FormatNumber(data.Coins or 0) end

    local gemsLabel = HUD:FindFirstChild("GemsLabel", true)
    if gemsLabel then gemsLabel.Text = "💎 " .. FormatNumber(data.Gems or 0) end

    local rebirthLabel = HUD:FindFirstChild("RebirthLabel", true)
    if rebirthLabel then rebirthLabel.Text = "🔁 " .. (data.Rebirths or 0) end

    local worldLabel = HUD:FindFirstChild("WorldLabel", true)
    if worldLabel then
        local w = GameData.WorldById[data.CurrentWorld or 1]
        worldLabel.Text = "🌍 " .. (w and w.Name or "?")
    end

    -- Rebirth button color
    if rebirthBtn then
        local req = GameData.GetRebirthRequirement(data.Rebirths or 0)
        local can = (data.TotalCoins or 0) >= req
        TweenService:Create(rebirthBtn, TweenInfo.new(0.3), {
            BackgroundColor3 = can and Color3.fromRGB(80,200,80) or Color3.fromRGB(100,40,140)
        }):Play()
    end

    -- Refresh open panels
    if PetsPanel.Visible   then RefreshPetsPanel(data) end
    if ShopPanel.Visible   then RefreshShop(data)      end
    if WorldsPanel.Visible then RefreshWorlds(data)    end
end

RemoteEvents:WaitForChild("UpdatePlayerData").OnClientEvent:Connect(OnDataUpdated)

-- ─── ⑧ PANEL OPEN ANIMATIONS ─────────────────────────────────────────────────
for _, panel in pairs({HatchPanel, PetsPanel, ShopPanel, WorldsPanel}) do
    panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if panel.Visible then
            panel.Size = UDim2.new(panel.Size.X.Scale * 0.9, panel.Size.X.Offset * 0.9,
                                   panel.Size.Y.Scale * 0.9, panel.Size.Y.Offset * 0.9)
            TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = panel == HatchPanel  and UDim2.new(0, 620, 0, 460)
                    or panel == PetsPanel   and UDim2.new(0, 660, 0, 500)
                    or panel == ShopPanel   and UDim2.new(0, 660, 0, 500)
                    or UDim2.new(0, 540, 0, 460)
            }):Play()
        end
    end)
end

print("[MainHUD] Initialized.")
