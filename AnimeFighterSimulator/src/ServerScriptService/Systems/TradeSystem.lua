-- TradeSystem.lua
-- Handles Shard and Boost trading between players (fighters NOT tradeable)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TradeSystem = {}

-- Pending trade offers: [tradeId] = tradeData
local pendingTrades = {}
local tradeCounter = 0

local TRADE_TIMEOUT = 120  -- 2 minutes to accept

-- ================================================================
-- TRADE REQUEST
-- ================================================================

function TradeSystem.SendTradeOffer(senderUserId, targetUserId, offerShards, offerWorldId, requestShards, requestWorldId)
	local senderData = _G.DataManager.GetData(senderUserId)
	local targetData = _G.DataManager.GetData(targetUserId)

	if not senderData then return false, "Your data not loaded" end
	if not targetData then return false, "Target player not found or not in server" end

	-- License check
	if not senderData.hasTradingLicense then
		return false, "You need a Trading License (1,000 TT Shards from Time Trial Shop)"
	end
	if not targetData.hasTradingLicense then
		return false, "Target player does not have a Trading License"
	end

	-- Validate sender has the offered shards
	local senderShards = (senderData.shards and senderData.shards[offerWorldId]) or 0
	if senderShards < offerShards then
		return false, "Not enough shards to offer (have " .. senderShards .. " " .. offerWorldId .. " shards)"
	end

	tradeCounter = tradeCounter + 1
	local tradeId = "trade_" .. tostring(tradeCounter)

	pendingTrades[tradeId] = {
		tradeId = tradeId,
		senderUserId = senderUserId,
		targetUserId = targetUserId,
		offerShards = offerShards,
		offerWorldId = offerWorldId,
		requestShards = requestShards,
		requestWorldId = requestWorldId,
		createdAt = os.time(),
		status = "pending",
	}

	-- Notify target
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local tradeEvent = remotes:FindFirstChild("TradeOfferReceived")
			if tradeEvent then
				local senderPlayer = Players:GetPlayerByUserId(senderUserId)
				tradeEvent:FireClient(targetPlayer, {
					tradeId = tradeId,
					senderName = senderPlayer and senderPlayer.Name or "Unknown",
					offerShards = offerShards,
					offerWorldId = offerWorldId,
					requestShards = requestShards,
					requestWorldId = requestWorldId,
				})
			end
		end
	end

	-- Auto-expire after timeout
	task.delay(TRADE_TIMEOUT, function()
		if pendingTrades[tradeId] and pendingTrades[tradeId].status == "pending" then
			pendingTrades[tradeId] = nil
		end
	end)

	return true, tradeId
end

-- ================================================================
-- ACCEPT TRADE
-- ================================================================

function TradeSystem.AcceptTrade(acceptingUserId, tradeId)
	local trade = pendingTrades[tradeId]
	if not trade then return false, "Trade offer expired or not found" end
	if trade.targetUserId ~= acceptingUserId then return false, "Not your trade offer" end
	if trade.status ~= "pending" then return false, "Trade already resolved" end

	local senderData = _G.DataManager.GetData(trade.senderUserId)
	local targetData = _G.DataManager.GetData(trade.targetUserId)

	if not senderData or not targetData then return false, "Player data unavailable" end

	-- Validate both sides still have what they offered
	local senderShards = (senderData.shards and senderData.shards[trade.offerWorldId]) or 0
	if senderShards < trade.offerShards then
		pendingTrades[tradeId] = nil
		return false, "Sender no longer has the offered shards"
	end

	local targetShards = (targetData.shards and targetData.shards[trade.requestWorldId]) or 0
	if targetShards < trade.requestShards then
		return false, "You no longer have " .. trade.requestShards .. " " .. trade.requestWorldId .. " shards"
	end

	-- Execute trade
	-- Sender gives offerShards (offerWorldId) → Target
	senderData.shards[trade.offerWorldId] = senderShards - trade.offerShards
	if not targetData.shards then targetData.shards = {} end
	targetData.shards[trade.offerWorldId] = (targetData.shards[trade.offerWorldId] or 0) + trade.offerShards

	-- Target gives requestShards (requestWorldId) → Sender
	targetData.shards[trade.requestWorldId] = targetShards - trade.requestShards
	if not senderData.shards then senderData.shards = {} end
	senderData.shards[trade.requestWorldId] = (senderData.shards[trade.requestWorldId] or 0) + trade.requestShards

	_G.DataManager.MarkDirty(trade.senderUserId)
	_G.DataManager.MarkDirty(trade.targetUserId)

	trade.status = "completed"
	pendingTrades[tradeId] = nil

	-- Notify both players
	local senderPlayer = Players:GetPlayerByUserId(trade.senderUserId)
	local targetPlayer = Players:GetPlayerByUserId(trade.targetUserId)
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remotes then
		local completeEvent = remotes:FindFirstChild("TradeCompleted")
		if completeEvent then
			if senderPlayer then
				completeEvent:FireClient(senderPlayer, {
					received = { shards = trade.requestShards, worldId = trade.requestWorldId },
					gave = { shards = trade.offerShards, worldId = trade.offerWorldId },
				})
			end
			if targetPlayer then
				completeEvent:FireClient(targetPlayer, {
					received = { shards = trade.offerShards, worldId = trade.offerWorldId },
					gave = { shards = trade.requestShards, worldId = trade.requestWorldId },
				})
			end
		end
	end

	return true, nil
end

-- ================================================================
-- DECLINE TRADE
-- ================================================================

function TradeSystem.DeclineTrade(userId, tradeId)
	local trade = pendingTrades[tradeId]
	if not trade then return false, "Trade not found" end
	if trade.targetUserId ~= userId and trade.senderUserId ~= userId then
		return false, "Not your trade"
	end

	trade.status = "declined"
	pendingTrades[tradeId] = nil

	-- Notify sender
	local senderPlayer = Players:GetPlayerByUserId(trade.senderUserId)
	if senderPlayer then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local declineEvent = remotes:FindFirstChild("TradeDeclined")
			if declineEvent then declineEvent:FireClient(senderPlayer, { tradeId = tradeId }) end
		end
	end

	return true, nil
end

return TradeSystem
