-- CombatSystem.lua
-- Manages auto-combat: enemies spawn, fighters attack, damage dealt, Yen drops

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FighterData = require(ReplicatedStorage.Data.FighterData)
local PassiveData = require(ReplicatedStorage.Data.PassiveData)

local CombatSystem = {}

-- Active enemy tables per world area
-- Structure: enemyData[areaId] = { { model, health, maxHealth, yenReward, isBoss } }
local activeEnemies = {}

-- Combat states per player
-- playerCombat[userId] = { attacking = bool, attackCooldown = number, ultimateCooldowns = {} }
local playerCombat = {}

-- Attack radius for auto-targeting
local ATTACK_RADIUS = 20
local BASE_ATTACK_INTERVAL = 1.0  -- seconds between auto-attacks

-- ================================================================
-- ENEMY SPAWNING
-- ================================================================

local EnemyTemplates = {
	super_island = {
		normal = { name = "Minion", health = 100,  yenReward = 10,   spawnWeight = 10 },
		miniboss = { name = "Elite", health = 1000, yenReward = 200,  spawnWeight = 2  },
		boss     = { name = "Boss",  health = 5000, yenReward = 1000, spawnWeight = 0  },
	},
	ninja_village = {
		normal = { name = "Rogue Ninja",   health = 1000,  yenReward = 100,   spawnWeight = 10 },
		miniboss = { name = "Jonin",        health = 10000, yenReward = 2000,  spawnWeight = 2  },
		boss     = { name = "Kage",         health = 50000, yenReward = 10000, spawnWeight = 0  },
	},
	crazy_town = {
		normal = { name = "Pirate Grunt", health = 10000,  yenReward = 1000,   spawnWeight = 10 },
		miniboss = { name = "Pirate Captain", health = 100000, yenReward = 20000, spawnWeight = 2 },
		boss     = { name = "Pirate Warlord", health = 500000, yenReward = 100000, spawnWeight = 0 },
	},
	-- Additional worlds use this scaling formula
}

local function getEnemyTemplate(worldId, enemyType)
	if EnemyTemplates[worldId] then
		return EnemyTemplates[worldId][enemyType]
	end
	-- Fallback: generate scaled template from world index
	local world = require(ReplicatedStorage.Data.WorldData).GetWorldById(worldId)
	if not world then return nil end
	local scale = 10 ^ (world.worldIndex - 1)
	return {
		name = enemyType == "boss" and "World Boss" or (enemyType == "miniboss" and "Elite Enemy" or "Enemy"),
		health = scale * (enemyType == "boss" and 5000 or (enemyType == "miniboss" and 1000 or 100)),
		yenReward = scale * (enemyType == "boss" and 1000 or (enemyType == "miniboss" and 200 or 10)),
		spawnWeight = enemyType == "normal" and 10 or (enemyType == "miniboss" and 2 or 0),
	}
end

-- Register an enemy in the active list
function CombatSystem.RegisterEnemy(areaId, model, enemyType, worldId)
	if not activeEnemies[areaId] then
		activeEnemies[areaId] = {}
	end
	local template = getEnemyTemplate(worldId, enemyType)
	if not template then return end

	local instance = {
		model = model,
		health = template.health,
		maxHealth = template.health,
		yenReward = template.yenReward,
		isBoss = (enemyType == "boss"),
		isMiniboss = (enemyType == "miniboss"),
		areaId = areaId,
		worldId = worldId,
		alive = true,
	}
	table.insert(activeEnemies[areaId], instance)
	return instance
end

function CombatSystem.UnregisterEnemy(areaId, model)
	if not activeEnemies[areaId] then return end
	for i, enemy in ipairs(activeEnemies[areaId]) do
		if enemy.model == model then
			table.remove(activeEnemies[areaId], i)
			return
		end
	end
end

-- ================================================================
-- DAMAGE CALCULATION
-- ================================================================

function CombatSystem.CalculatePlayerDPS(userId)
	local data = _G.DataManager.GetData(userId)
	if not data or not data.fighters then return 0 end

	-- Get equipped fighters
	local equipped = {}
	local fighterMap = {}
	for _, f in ipairs(data.fighters) do
		fighterMap[f.id] = f
	end
	for _, eid in ipairs(data.equippedFighters or {}) do
		if fighterMap[eid] then
			table.insert(equipped, fighterMap[eid])
		end
	end

	if #equipped == 0 then return 0 end

	-- Sum damage from all equipped fighters
	local totalDPS = 0
	for _, fighter in ipairs(equipped) do
		local template = FighterData.Fighters[fighter.fighterId]
		if template then
			local baseDamage = FighterData.CalculateDamage(template, fighter.level)
			-- Shiny bonus: +50% damage
			if fighter.isShiny then
				baseDamage = baseDamage * 1.5
			end
			totalDPS = totalDPS + baseDamage
		end
	end

	-- Apply passive effects
	local passiveEffects = PassiveData.AggregatePassiveEffects(equipped)
	totalDPS = totalDPS * (passiveEffects.damageMultiplier or 1.0)

	-- Crit (always crit passive = 2x)
	if passiveEffects.alwaysCrit then
		totalDPS = totalDPS * 2
	end

	-- 2x Drops gamepass also gives +30% damage (mimicking game behavior)
	if data.gamepasses and data.gamepasses.doubleDrops then
		totalDPS = totalDPS * 1.3
	end

	return math.floor(totalDPS)
end

function CombatSystem.CalculateBossDPS(userId)
	local data = _G.DataManager.GetData(userId)
	if not data or not data.fighters then return 0 end

	local baseDPS = CombatSystem.CalculatePlayerDPS(userId)

	-- Get equipped fighters for boss passive
	local equipped = {}
	local fighterMap = {}
	for _, f in ipairs(data.fighters) do fighterMap[f.id] = f end
	for _, eid in ipairs(data.equippedFighters or {}) do
		if fighterMap[eid] then table.insert(equipped, fighterMap[eid]) end
	end

	local passiveEffects = PassiveData.AggregatePassiveEffects(equipped)
	local bossMult = passiveEffects.bossDamageMultiplier or 1.0

	return math.floor(baseDPS * bossMult)
end

-- ================================================================
-- COMBAT LOOP (server-authoritative damage dealing)
-- ================================================================

-- Find the nearest alive enemy to a player's character
local function findNearestEnemy(character, areaId)
	if not character or not character.PrimaryPart then return nil end
	if not activeEnemies[areaId] then return nil end

	local playerPos = character.PrimaryPart.Position
	local nearest = nil
	local nearestDist = ATTACK_RADIUS

	for _, enemy in ipairs(activeEnemies[areaId]) do
		if enemy.alive and enemy.model and enemy.model.PrimaryPart then
			local dist = (enemy.model.PrimaryPart.Position - playerPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = enemy
			end
		end
	end

	return nearest
end

local function killEnemy(enemy, killer)
	enemy.alive = false

	-- Grant Yen to killer
	if killer then
		local CurrencySystem = _G.CurrencySystem
		if CurrencySystem then
			-- Apply drop boost
			local data = _G.DataManager.GetData(killer.UserId)
			local boostMult = 1.0
			if data then
				local now = os.time()
				for _, boost in ipairs(data.activeBoosts or {}) do
					if boost.type == "yen" and boost.expiresAt > now then
						boostMult = boostMult * (boost.multiplier or 1.0)
					end
				end
				if data.gamepasses and data.gamepasses.doubleDrops then
					boostMult = boostMult * 2
				end
			end
			local yen = math.floor(enemy.yenReward * boostMult)
			CurrencySystem.AddYen(killer.UserId, yen)

			-- Fire kill event to client for VFX/sound
			local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remotes then
				local killEvent = remotes:FindFirstChild("EnemyKilled")
				if killEvent then
					killEvent:FireClient(killer, {
						yenEarned = yen,
						isBoss = enemy.isBoss,
						position = enemy.model.PrimaryPart and enemy.model.PrimaryPart.Position,
					})
				end
			end
		end
	end

	-- Update quest progress
	if killer and _G.QuestSystem then
		_G.QuestSystem.OnEnemyKilled(killer.UserId, enemy.worldId, enemy.isBoss, enemy.isMiniboss)
	end

	-- Remove enemy model from workspace
	if enemy.model then
		task.delay(0.5, function()
			if enemy.model then
				enemy.model:Destroy()
			end
		end)
	end

	-- Remove from active list
	CombatSystem.UnregisterEnemy(enemy.areaId, enemy.model)
end

-- Per-player combat heartbeat
local playerLastAttack = {}
local playerAreaMap = {}  -- [userId] = areaId

function CombatSystem.SetPlayerArea(userId, areaId)
	playerAreaMap[userId] = areaId
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()

	for _, player in ipairs(Players:GetPlayers()) do
		local userId = player.UserId
		local areaId = playerAreaMap[userId]
		if not areaId then continue end

		local data = _G.DataManager.GetData(userId)
		if not data then continue end

		-- Check attack cooldown
		local lastAttack = playerLastAttack[userId] or 0
		local attackInterval = BASE_ATTACK_INTERVAL
		if data.gamepasses and data.gamepasses.halfCooldown then
			attackInterval = attackInterval * 0.5
		end
		local passiveData = {}
		-- Apply speed from passives via equipped fighters
		-- (abbreviated — full implementation in production)

		if (now - lastAttack) < attackInterval then continue end
		playerLastAttack[userId] = now

		local character = player.Character
		if not character or not character.PrimaryPart then continue end

		local target = findNearestEnemy(character, areaId)
		if not target then continue end

		-- Deal damage
		local damage = target.isBoss
			and CombatSystem.CalculateBossDPS(userId)
			or CombatSystem.CalculatePlayerDPS(userId)

		target.health = target.health - damage

		-- Update health bar via client
		local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remotes then
			local dmgEvent = remotes:FindFirstChild("DamageDealt")
			if dmgEvent then
				dmgEvent:FireAllClients({
					targetId = tostring(target.model),
					damage = damage,
					healthPercent = math.max(0, target.health / target.maxHealth),
				})
			end
		end

		-- Check death
		if target.health <= 0 then
			killEnemy(target, player)
		end
	end
end)

-- ================================================================
-- ULTIMATE ABILITIES
-- ================================================================

-- Returns current ultimate for each equipped fighter with cooldown tracking
local ultimateCooldowns = {}  -- [userId .. "_" .. fighterId] = lastUsedTime

function CombatSystem.TryFireUltimate(userId)
	local data = _G.DataManager.GetData(userId)
	if not data or not data.fighters then return end

	local fighterMap = {}
	for _, f in ipairs(data.fighters) do fighterMap[f.id] = f end

	local now = os.clock()
	for _, eid in ipairs(data.equippedFighters or {}) do
		local instance = fighterMap[eid]
		if not instance then continue end
		local template = FighterData.Fighters[instance.fighterId]
		if not template or not template.ultimate then continue end

		local cooldownKey = tostring(userId) .. "_" .. eid
		local lastUsed = ultimateCooldowns[cooldownKey] or 0
		local cooldown = template.ultimate.cooldown

		if data.gamepasses and data.gamepasses.halfCooldown then
			cooldown = cooldown * 0.5
		end

		if (now - lastUsed) >= cooldown then
			ultimateCooldowns[cooldownKey] = now
			-- Fire ultimate event to clients for VFX
			local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remotes then
				local ultEvent = remotes:FindFirstChild("UltimateActivated")
				if ultEvent then
					ultEvent:FireAllClients({
						userId = userId,
						fighterId = instance.fighterId,
						ultimateName = template.ultimate.name,
						damage = template.ultimate.damage,
					})
				end
			end
		end
	end
end

return CombatSystem
