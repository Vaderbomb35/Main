-- Main.server.lua
-- Entry point: loads all systems and sets up remote event handlers

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ================================================================
-- SETUP REMOTE EVENTS (create before systems load)
-- ================================================================

local remoteEventsFolder = Instance.new("Folder")
remoteEventsFolder.Name = "RemoteEvents"
remoteEventsFolder.Parent = ReplicatedStorage

local function makeRemote(name, isFunction)
	if isFunction then
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = remoteEventsFolder
		return rf
	else
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = remoteEventsFolder
		return re
	end
end

-- Events (server → client notifications)
makeRemote("PlayerDataLoaded")
makeRemote("SyncCurrency")
makeRemote("EnemyKilled")
makeRemote("DamageDealt")
makeRemote("UltimateActivated")
makeRemote("WorldChanged")
makeRemote("QuestCompleted")
makeRemote("SyncQuestProgress")
makeRemote("WorldBadgeEarned")
makeRemote("RaidAnnounced")
makeRemote("RaidJoined")
makeRemote("RaidBossHealth")
makeRemote("RaidShieldActivated")
makeRemote("RaidShieldRemoved")
makeRemote("RaidCompleted")
makeRemote("RaidFailed")
makeRemote("DefenseModeStarted")
makeRemote("DefenseModeWaveStarted")
makeRemote("DefenseModeWaveCleared")
makeRemote("DefenseModeCompleted")
makeRemote("DefenseModeFailed")
makeRemote("TradeOfferReceived")
makeRemote("TradeCompleted")
makeRemote("TradeDeclined")
makeRemote("DailyLoginReward")
makeRemote("UpgradeChallengeCompleted")

-- Remote Functions (client → server requests)
makeRemote("RequestAction", true)  -- single multiplex RF for client requests

-- ================================================================
-- LOAD SYSTEMS (order matters for dependencies)
-- ================================================================

print("[Main] Loading AnimeFighterSimulator systems...")

-- 1. DataManager loads first (handles player join/leave)
local DataManager = require(ServerScriptService.DataManagers.DataManager)

-- 2. Systems that depend on DataManager
local CurrencySystem  = require(ServerScriptService.Systems.CurrencySystem)
local FighterSystem   = require(ServerScriptService.Systems.FighterSystem)
local WorldSystem     = require(ServerScriptService.Systems.WorldSystem)
local GachaSystem     = require(ServerScriptService.Systems.GachaSystem)
local CombatSystem    = require(ServerScriptService.Systems.CombatSystem)
local QuestSystem     = require(ServerScriptService.Systems.QuestSystem)
local ClassSystem     = require(ServerScriptService.Systems.ClassSystem)
local RaidSystem      = require(ServerScriptService.Systems.RaidSystem)
local ShopSystem      = require(ServerScriptService.Systems.ShopSystem)
local DailySystem     = require(ServerScriptService.Systems.DailySystem)
local DefenseModeSystem = require(ServerScriptService.Systems.DefenseModeSystem)
local TradeSystem     = require(ServerScriptService.Systems.TradeSystem)

-- Register systems in global table for cross-system access
_G.DataManager      = DataManager
_G.CurrencySystem   = CurrencySystem
_G.FighterSystem    = FighterSystem
_G.WorldSystem      = WorldSystem
_G.GachaSystem      = GachaSystem
_G.CombatSystem     = CombatSystem
_G.QuestSystem      = QuestSystem
_G.ClassSystem      = ClassSystem
_G.RaidSystem       = RaidSystem
_G.ShopSystem       = ShopSystem
_G.DailySystem      = DailySystem
_G.DefenseModeSystem = DefenseModeSystem
_G.TradeSystem      = TradeSystem

print("[Main] All systems loaded.")

-- ================================================================
-- SYNC GAMEPASSES ON JOIN
-- ================================================================

Players.PlayerAdded:Connect(function(player)
	-- Wait for data to be loaded
	task.wait(1)
	local userId = player.UserId

	-- Sync gamepasses (non-blocking)
	task.spawn(function()
		ShopSystem.SyncGamepasses(userId)
	end)

	-- Attempt daily login reward
	task.spawn(function()
		DailySystem.ClaimDailyLogin(userId)
	end)

	-- Set initial world area
	local data = DataManager.GetData(userId)
	if data then
		local worldId = "super_island"
		if data.unlockedWorlds and #data.unlockedWorlds > 0 then
			worldId = data.unlockedWorlds[#data.unlockedWorlds]  -- most recent world
		end
		CombatSystem.SetPlayerArea(userId, worldId)
	end

	-- Check upgrade challenges (they might have been earned offline)
	task.spawn(function()
		task.wait(2)
		DailySystem.CheckUpgradeChallenges(userId)
	end)
end)

-- ================================================================
-- MULTIPLEX REMOTE FUNCTION HANDLER
-- ================================================================

-- All client → server requests come through one RemoteFunction
-- Action: string identifying what the client wants to do
-- Payload: table of arguments
local actionHandlers = {}

-- Register handlers
actionHandlers["OpenStar"] = function(player, payload)
	local result, rarity, isShiny, err = GachaSystem.Pull(player.UserId, payload.worldId)
	if err then return { success = false, error = err } end
	return { success = true, fighter = result, rarity = rarity, isShiny = isShiny }
end

actionHandlers["OpenStarMulti"] = function(player, payload)
	local results, err = GachaSystem.MultiPull(player.UserId, payload.worldId, payload.count)
	if err then return { success = false, error = err } end
	return { success = true, results = results }
end

actionHandlers["UnlockWorld"] = function(player, payload)
	local ok, result = WorldSystem.UnlockWorld(player.UserId, payload.worldId)
	if not ok then return { success = false, error = result } end
	return { success = true, world = result }
end

actionHandlers["TravelToWorld"] = function(player, payload)
	local ok, err = WorldSystem.TeleportPlayerToWorld(player, payload.worldId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["EquipFighter"] = function(player, payload)
	local ok, err = FighterSystem.EquipFighter(player.UserId, payload.instanceId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["UnequipFighter"] = function(player, payload)
	local ok, err = FighterSystem.UnequipFighter(player.UserId, payload.instanceId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["FuseFighters"] = function(player, payload)
	local ok, result = FighterSystem.FuseFighters(player.UserId, payload.targetId, payload.sacrificeIds)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["CraftFighter"] = function(player, payload)
	local ok, result = FighterSystem.CraftFighter(player.UserId, payload.worldId, payload.mythicalIds, payload.useShiny)
	if not ok then return { success = false, error = result } end
	return { success = true, fighter = result }
end

actionHandlers["SellFighter"] = function(player, payload)
	local ok, yen = FighterSystem.SellFighter(player.UserId, payload.instanceId)
	if not ok then return { success = false, error = yen } end
	return { success = true, yenEarned = yen }
end

actionHandlers["PlaceIncubator"] = function(player, payload)
	local ok, err = FighterSystem.PlaceInIncubator(player.UserId, payload.worldId, payload.instanceId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["CollectIncubator"] = function(player, payload)
	local ok, result = FighterSystem.CollectIncubator(player.UserId, payload.worldId)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["MakeShiny"] = function(player, payload)
	local ok, err = FighterSystem.MakeShiny(player.UserId, payload.instanceId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["RerollPassive"] = function(player, payload)
	local ok, result = FighterSystem.RerollPassive(player.UserId, payload.instanceId)
	if not ok then return { success = false, error = result } end
	return { success = true, passive = result }
end

actionHandlers["TransferPassive"] = function(player, payload)
	local ok, err = FighterSystem.TransferPassive(player.UserId, payload.sourceId, payload.targetId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["TrainStat"] = function(player, payload)
	local ok, result = ClassSystem.TrainStat(player.UserId, payload.stat)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["TrainStatBulk"] = function(player, payload)
	local ok, result = ClassSystem.TrainStatBulk(player.UserId, payload.stat, payload.count)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["UpgradeClass"] = function(player, payload)
	local ok, result = ClassSystem.UpgradeClass(player.UserId)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["JoinRaid"] = function(player, payload)
	local ok, err = RaidSystem.JoinRaid(player.UserId)
	if not ok then return { success = false, error = err } end
	return { success = true, raid = RaidSystem.GetActiveRaidInfo() }
end

actionHandlers["DamageRaidBoss"] = function(player, payload)
	RaidSystem.DamageBoss(player.UserId, payload.damage or 0)
	return { success = true }
end

actionHandlers["GetMerchantInventory"] = function(player, payload)
	return { success = true, inventory = ShopSystem.GetMerchantInventory() }
end

actionHandlers["BuyFromMerchant"] = function(player, payload)
	local ok, result = ShopSystem.BuyFromMerchant(player.UserId, payload.itemIndex)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["BuyFromTTShop"] = function(player, payload)
	local ok, err = ShopSystem.BuyFromTimeTrialShop(player.UserId, payload.itemId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["ClaimDailySpin"] = function(player, payload)
	local ok, result = ShopSystem.ClaimDailySpin(player.UserId)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["RedeemCode"] = function(player, payload)
	local ok, result = ShopSystem.RedeemCode(player.UserId, payload.code)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["StartDefenseMode"] = function(player, payload)
	local ok, err = DefenseModeSystem.StartDefenseMode(player.UserId, payload.worldId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["SendTradeOffer"] = function(player, payload)
	local targetPlayer = Players:GetPlayerByUserId(payload.targetUserId)
	if not targetPlayer then return { success = false, error = "Target player not in server" } end

	local ok, tradeId = TradeSystem.SendTradeOffer(
		player.UserId, payload.targetUserId,
		payload.offerShards, payload.offerWorldId,
		payload.requestShards, payload.requestWorldId
	)
	if not ok then return { success = false, error = tradeId } end
	return { success = true, tradeId = tradeId }
end

actionHandlers["AcceptTrade"] = function(player, payload)
	local ok, err = TradeSystem.AcceptTrade(player.UserId, payload.tradeId)
	if not ok then return { success = false, error = err } end
	return { success = true }
end

actionHandlers["DeclineTrade"] = function(player, payload)
	TradeSystem.DeclineTrade(player.UserId, payload.tradeId)
	return { success = true }
end

actionHandlers["SacrificeFighterForPXP"] = function(player, payload)
	local ok, result = DailySystem.SacrificeFighterForPXP(player.UserId, payload.instanceId)
	if not ok then return { success = false, error = result } end
	return { success = true, result = result }
end

actionHandlers["GetPlayerData"] = function(player, payload)
	local data = DataManager.GetData(player.UserId)
	return { success = true, data = data }
end

-- Bind the remote function
local requestActionRF = remoteEventsFolder:WaitForChild("RequestAction")
requestActionRF.OnServerInvoke = function(player, action, payload)
	if type(action) ~= "string" then
		return { success = false, error = "Invalid action" }
	end

	local handler = actionHandlers[action]
	if not handler then
		return { success = false, error = "Unknown action: " .. action }
	end

	-- Rate limit: basic cooldown per player per action (prevent spam)
	local cooldownKey = tostring(player.UserId) .. "_" .. action
	local lastCall = _G._actionCooldowns and _G._actionCooldowns[cooldownKey] or 0
	local now = os.clock()
	if (now - lastCall) < 0.1 then  -- 100ms minimum between same action calls
		return { success = false, error = "Please slow down" }
	end
	if not _G._actionCooldowns then _G._actionCooldowns = {} end
	_G._actionCooldowns[cooldownKey] = now

	-- Call handler safely
	local ok, result = pcall(handler, player, payload or {})
	if not ok then
		warn("[Main] Error in action '" .. action .. "' for " .. player.Name .. ": " .. tostring(result))
		return { success = false, error = "Server error" }
	end

	return result
end

print("[Main] AnimeFighterSimulator server initialized successfully!")
