-- QuestSystem.lua
-- World questlines: track kill counts, reward badges, mounts, Yen multipliers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WorldData = require(ReplicatedStorage.Data.WorldData)

local QuestSystem = {}

-- Quest structure per world: series of quests requiring enemy kills
-- questlines[worldId] = array of { questIndex, description, killTarget, reward }
local questlines = {}

-- Build quest lines dynamically from WorldData
local function buildQuestlines()
	local count = WorldData.GetWorldCount()
	for i = 1, count do
		local world = WorldData.GetWorldByIndex(i)
		if world then
			questlines[world.id] = {}
			local questCount = world.questCount or 5
			local baseKills = 100 * (2 ^ (i - 1))  -- scales per world

			for q = 1, questCount do
				local killTarget = math.floor(baseKills * q)
				local yenReward = math.floor(world.enemyYenReward * 500 * q)
				table.insert(questlines[world.id], {
					questIndex = q,
					description = "Defeat " .. killTarget .. " enemies in " .. world.name,
					killTarget = killTarget,
					yenReward = yenReward,
					isLastQuest = (q == questCount),
				})
			end
		end
	end
end
buildQuestlines()

-- ================================================================
-- QUEST PROGRESS
-- ================================================================

local function getQuestProgress(data, worldId)
	if not data.questProgress then data.questProgress = {} end
	if not data.questProgress[worldId] then
		data.questProgress[worldId] = {
			completedQuests = {},
			currentQuestIndex = 1,
			enemiesKilled = 0,
		}
	end
	return data.questProgress[worldId]
end

-- Called by CombatSystem when an enemy dies
function QuestSystem.OnEnemyKilled(userId, worldId, isBoss, isMiniboss)
	local data = _G.DataManager.GetData(userId)
	if not data then return end

	local progress = getQuestProgress(data, worldId)
	local worldQuests = questlines[worldId]
	if not worldQuests then return end

	local currentQuestIdx = progress.currentQuestIndex
	if currentQuestIdx > #worldQuests then return  -- all quests done end

	local currentQuest = worldQuests[currentQuestIdx]

	-- Increment kill count
	progress.enemiesKilled = progress.enemiesKilled + 1

	-- Check completion
	if progress.enemiesKilled >= currentQuest.killTarget then
		QuestSystem.CompleteQuest(userId, worldId, currentQuestIdx)
	else
		_G.DataManager.MarkDirty(userId)
		-- Sync progress to client
		QuestSystem._syncQuestProgress(userId, worldId, progress, currentQuest)
	end
end

function QuestSystem.CompleteQuest(userId, worldId, questIndex)
	local data = _G.DataManager.GetData(userId)
	if not data then return end

	local progress = getQuestProgress(data, worldId)
	local worldQuests = questlines[worldId]
	if not worldQuests then return end

	local quest = worldQuests[questIndex]
	if not quest then return end

	-- Mark completed
	table.insert(progress.completedQuests, questIndex)
	progress.currentQuestIndex = questIndex + 1
	progress.enemiesKilled = 0  -- reset for next quest

	-- Give Yen reward
	_G.CurrencySystem.AddYen(userId, quest.yenReward)

	-- If this was the final quest in the world, grant badge + Yen multiplier
	if quest.isLastQuest then
		QuestSystem.GrantWorldBadge(userId, worldId)
	end

	_G.DataManager.MarkDirty(userId)

	-- Notify client
	local player = game:GetService("Players"):GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local questComplete = remotes:FindFirstChild("QuestCompleted")
			if questComplete then
				questComplete:FireClient(player, {
					worldId = worldId,
					questIndex = questIndex,
					yenReward = quest.yenReward,
					isLastQuest = quest.isLastQuest,
				})
			end
		end
	end
end

-- ================================================================
-- WORLD BADGE (completing all quests in a world)
-- ================================================================

function QuestSystem.GrantWorldBadge(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data then return end

	-- Check not already earned
	if not data.worldBadgesEarned then data.worldBadgesEarned = {} end
	for _, earned in ipairs(data.worldBadgesEarned) do
		if earned == worldId then return end
	end

	table.insert(data.worldBadgesEarned, worldId)

	-- Grant permanent +10% Yen multiplier in upgrades tab
	if not data.upgrades then data.upgrades = {} end
	data.upgrades.yenMultiplier = (data.upgrades.yenMultiplier or 1.0) * 1.10

	_G.DataManager.MarkDirty(userId)

	-- Grant Roblox Badge if configured (uses BadgeService)
	-- local BadgeService = game:GetService("BadgeService")
	-- local badgeId = BADGE_IDS[worldId]
	-- if badgeId then
	--     pcall(function() BadgeService:AwardBadge(userId, badgeId) end)
	-- end

	-- Notify client to show badge unlock + mount reward
	local player = game:GetService("Players"):GetPlayerByUserId(userId)
	if player then
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local badgeEvent = remotes:FindFirstChild("WorldBadgeEarned")
			if badgeEvent then
				badgeEvent:FireClient(player, { worldId = worldId })
			end
		end
	end
end

-- ================================================================
-- QUERY METHODS (for UI)
-- ================================================================

function QuestSystem.GetQuestInfo(userId, worldId)
	local data = _G.DataManager.GetData(userId)
	if not data then return nil end

	local progress = getQuestProgress(data, worldId)
	local worldQuests = questlines[worldId]
	if not worldQuests then return nil end

	local currentQuest = worldQuests[progress.currentQuestIndex]
	return {
		currentQuestIndex = progress.currentQuestIndex,
		totalQuests = #worldQuests,
		currentQuest = currentQuest,
		enemiesKilled = progress.enemiesKilled,
		completedQuests = progress.completedQuests,
		isComplete = progress.currentQuestIndex > #worldQuests,
	}
end

function QuestSystem._syncQuestProgress(userId, worldId, progress, currentQuest)
	local player = game:GetService("Players"):GetPlayerByUserId(userId)
	if not player then return end
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remotes then return end
	local syncEvent = remotes:FindFirstChild("SyncQuestProgress")
	if syncEvent then
		syncEvent:FireClient(player, {
			worldId = worldId,
			enemiesKilled = progress.enemiesKilled,
			killTarget = currentQuest and currentQuest.killTarget or 0,
			questIndex = progress.currentQuestIndex,
		})
	end
end

return QuestSystem
