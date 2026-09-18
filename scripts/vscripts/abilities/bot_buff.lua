require("util/mode_select")

local BOT_DYNAMIC_STAGE_MAX = 5
local BOT_OBJECTIVE_CACHE_INTERVAL = 5.0
local BOT_DYNAMIC_BONUS_REFRESH_INTERVAL = 1.0
local BOT_GEM_SELL_GOLD = 2000
local BOT_KUSANAGI_SELL_GOLD = 30000
local BOT_GEM_LAST_ITEM_SLOT = 14

-- 动态阶段奖励：阶段3/5才给移速、施法距离、攻击距离、冷却减少、技能强度和法术抗性。
local BOT_DYNAMIC_STAGE_BONUS = {
    [0] = { attr = {0, 0, 0}, hpRegen = 0, gold = 0, exp = 0, moveSpeed = 0, castRange = 0, meleeAttackRange = 0, rangedAttackRange = 0, cooldown = 0, spellAmp = 0, magicResist = 0 },
    [1] = { attr = {2, 2, 2}, hpRegen = 1, gold = 5, exp = 5, moveSpeed = 0, castRange = 0, meleeAttackRange = 0, rangedAttackRange = 0, cooldown = 0, spellAmp = 0, magicResist = 0 },
    [2] = { attr = {5, 5, 5}, hpRegen = 3, gold = 12, exp = 10, moveSpeed = 0, castRange = 0, meleeAttackRange = 0, rangedAttackRange = 0, cooldown = 0, spellAmp = 0, magicResist = 0 },
    [3] = { attr = {8, 8, 8}, hpRegen = 6, gold = 22, exp = 18, moveSpeed = 40, castRange = 150, meleeAttackRange = 50, rangedAttackRange = 75, cooldown = 10, spellAmp = 15, magicResist = 10 },
    [4] = { attr = {10, 10, 10}, hpRegen = 8, gold = 28, exp = 22, moveSpeed = 40, castRange = 150, meleeAttackRange = 50, rangedAttackRange = 75, cooldown = 10, spellAmp = 15, magicResist = 10 },
    [5] = { attr = {12, 12, 12}, hpRegen = 10, gold = 35, exp = 28, moveSpeed = 60, castRange = 250, meleeAttackRange = 75, rangedAttackRange = 150, cooldown = 20, spellAmp = 30, magicResist = 20 },
}

-- 统计 bot 方自己损失的塔，作为建筑损失阶段来源。
local BOT_OBJECTIVE_TOWERS = {
    [DOTA_TEAM_GOODGUYS] = {
        { tier = 1, weight = 1, names = {"npc_dota_goodguys_tower1_top"} },
        { tier = 1, weight = 1, names = {"npc_dota_goodguys_tower1_mid"} },
        { tier = 1, weight = 1, names = {"npc_dota_goodguys_tower1_bot"} },
        { tier = 2, weight = 3, names = {"npc_dota_goodguys_tower2_top"} },
        { tier = 2, weight = 3, names = {"npc_dota_goodguys_tower2_mid"} },
        { tier = 2, weight = 3, names = {"npc_dota_goodguys_tower2_bot"} },
        { tier = 3, weight = 8, names = {"npc_dota_goodguys_tower3_top"} },
        { tier = 3, weight = 8, names = {"npc_dota_goodguys_tower3_mid"} },
        { tier = 3, weight = 8, names = {"npc_dota_goodguys_tower3_bot"} },
        { tier = 4, weight = 0, names = {"npc_dota_goodguys_tower4"} },
    },
    [DOTA_TEAM_BADGUYS] = {
        { tier = 1, weight = 1, names = {"npc_dota_badguys_tower1_top"} },
        { tier = 1, weight = 1, names = {"npc_dota_badguys_tower1_mid"} },
        { tier = 1, weight = 1, names = {"npc_dota_badguys_tower1_bot"} },
        { tier = 2, weight = 3, names = {"npc_dota_badguys_tower2_top"} },
        { tier = 2, weight = 3, names = {"npc_dota_badguys_tower2_mid"} },
        { tier = 2, weight = 3, names = {"npc_dota_badguys_tower2_bot"} },
        { tier = 3, weight = 8, names = {"npc_dota_badguys_tower3_top"} },
        { tier = 3, weight = 8, names = {"npc_dota_badguys_tower3_mid"} },
        { tier = 3, weight = 8, names = {"npc_dota_badguys_tower3_bot"} },
        { tier = 4, weight = 0, names = {"npc_dota_badguys_tower4"} },
    },
}

-- 统计 bot 方自己损失的兵营，双兵营全掉时额外加分。
local BOT_OBJECTIVE_BARRACKS = {
    [DOTA_TEAM_GOODGUYS] = {
        { lane = "top", kind = "melee", weight = 5, names = {"npc_dota_goodguys_melee_rax_top"} },
        { lane = "mid", kind = "melee", weight = 5, names = {"npc_dota_goodguys_melee_rax_mid"} },
        { lane = "bot", kind = "melee", weight = 5, names = {"npc_dota_goodguys_melee_rax_bot"} },
        { lane = "top", kind = "ranged", weight = 5, names = {"npc_dota_goodguys_range_rax_top"} },
        { lane = "mid", kind = "ranged", weight = 5, names = {"npc_dota_goodguys_range_rax_mid"} },
        { lane = "bot", kind = "ranged", weight = 5, names = {"npc_dota_goodguys_range_rax_bot"} },
    },
    [DOTA_TEAM_BADGUYS] = {
        { lane = "top", kind = "melee", weight = 5, names = {"npc_dota_badguys_melee_rax_top"} },
        { lane = "mid", kind = "melee", weight = 5, names = {"npc_dota_badguys_melee_rax_mid"} },
        { lane = "bot", kind = "melee", weight = 5, names = {"npc_dota_badguys_melee_rax_bot"} },
        { lane = "top", kind = "ranged", weight = 5, names = {"npc_dota_badguys_range_rax_top"} },
        { lane = "mid", kind = "ranged", weight = 5, names = {"npc_dota_badguys_range_rax_mid"} },
        { lane = "bot", kind = "ranged", weight = 5, names = {"npc_dota_badguys_range_rax_bot"} },
    },
}

local botObjectiveCache = {}
local botKnownBuildings = {}
local botStallPenaltyCache = {}

-- Hard 使用较慢的建筑阶段阈值；Lunatic 单独使用更早的建筑分数和拖延时间。
local BOT_DIFFICULTY_HARD = 3
local BOT_DIFFICULTY_LUNATIC = 4

local BOT_STALL_PENALTY_TIMINGS = {
    [BOT_DIFFICULTY_HARD] = {900, 1500, 2100, 2700, 3300},
    [BOT_DIFFICULTY_LUNATIC] = {900, 1200, 1800, 2400, 3000},
}

local function BotBuff_GetDifficultyLevel()
    if botModeSelect ~= nil and botModeSelect.Difficulty ~= nil then
        return botModeSelect.Difficulty
    end

    local data = GetBotDifficultyData and GetBotDifficultyData() or {}
    if data.name == "Lunatic" then return BOT_DIFFICULTY_LUNATIC end
    if data.name == "Hard" then return BOT_DIFFICULTY_HARD end

    return BOT_DIFFICULTY_HARD
end

local function BotBuff_GetCacheKey(team, difficultyLevel)
    return tostring(team) .. ":" .. tostring(difficultyLevel)
end

local function BotBuff_GetBuildingKey(className, names)
    return className .. ":" .. table.concat(names, "|")
end

local function BotBuff_IsTargetBuilding(building, names)
    local unitName = building.GetUnitName and building:GetUnitName() or nil
    local entityName = building.GetName and building:GetName() or nil
    for _, name in pairs(names) do
        if unitName == name or entityName == name then
            return true
        end
    end

    return false
end

local function BotBuff_FindBuildings(className, names)
    local result = {}
    local buildings = Entities:FindAllByClassname(className)
    for _, building in pairs(buildings) do
        if building ~= nil and not building:IsNull() then
            if BotBuff_IsTargetBuilding(building, names) then
                table.insert(result, building)
            end
        end
    end

    for _, name in pairs(names) do
        local building = Entities:FindByName(nil, name)
        if building ~= nil and not building:IsNull() then
            local duplicated = false
            for _, existBuilding in pairs(result) do
                if existBuilding == building then
                    duplicated = true
                    break
                end
            end
            if not duplicated then
                table.insert(result, building)
            end
        end
    end

    return result
end

local function BotBuff_IsBuildingDead(className, names)
    local key = BotBuff_GetBuildingKey(className, names)
    local known = botKnownBuildings[key] or {seen = false, maxCount = 0, lost = false}
    if known.lost then
        return true
    end

    local buildings = BotBuff_FindBuildings(className, names)
    if #buildings > 0 then
        known.seen = true
        known.maxCount = math.max(known.maxCount or 0, #buildings)
        botKnownBuildings[key] = known

        for _, building in pairs(buildings) do
            if not building:IsAlive() then
                -- 建筑损失一旦确认就固定记录，避免死亡实体移除后阶段回落。
                known.lost = true
                return true
            end
        end

        -- 同名建筑如果当前数量少于历史最高数量，说明其中一座已死亡并被移除。
        if #buildings < (known.maxCount or 0) then
            known.lost = true
            return true
        end

        return false
    end

    -- 曾经找到过的建筑如果之后找不到，说明死亡后实体已被移除，也计为损失。
    if known.seen == true then
        known.lost = true
        botKnownBuildings[key] = known
        return true
    end

    botKnownBuildings[key] = known
    return false
end

local function BotBuff_GetObjectiveStage(score, difficultyLevel)
    if difficultyLevel == BOT_DIFFICULTY_LUNATIC then
        -- Lunatic：分数包含同路前置塔，1 座三塔至少12分，同路三塔+双兵营至少25分。
        if score >= 25 then return 5 end
        if score >= 12 then return 4 end
        if score >= 8 then return 3 end
        if score >= 4 then return 2 end
        if score >= 1 then return 1 end
        return 0
    end

    if difficultyLevel == BOT_DIFFICULTY_HARD then
        -- Hard：按新建筑权重重新映射，阶段4约等于打穿一路高地。
        if score >= 25 then return 4 end
        if score >= 12 then return 3 end
        if score >= 8 then return 2 end
        if score >= 3 then return 1 end
    end

    return 0
end

local function BotBuff_GetStallPenalty(team, state, difficultyLevel)
    local nowTime = GameRules:GetDOTATime(false, false)
    local penalty = 0
    local timings = BOT_STALL_PENALTY_TIMINGS[difficultyLevel]
    if timings == nil then return 0 end

    -- 玩家错过推进时间节点后，拖延惩罚永久累计，不因之后补拆建筑而回退。
    if nowTime >= timings[1] and state.towerLostByTier[1] < 1 then penalty = penalty + 1 end
    if nowTime >= timings[2] and state.towerLostByTier[1] < 2 and state.towerLostByTier[2] < 1 then penalty = penalty + 1 end
    if nowTime >= timings[3] and state.towerLostByTier[2] < 1 then penalty = penalty + 1 end
    if nowTime >= timings[4] and state.towerLostByTier[3] < 1 then penalty = penalty + 1 end
    if nowTime >= timings[5] and state.barracksLost < 1 then penalty = penalty + 1 end

    local cacheKey = BotBuff_GetCacheKey(team, difficultyLevel)
    botStallPenaltyCache[cacheKey] = math.max(botStallPenaltyCache[cacheKey] or 0, penalty)
    return botStallPenaltyCache[cacheKey]
end

local function BotBuff_BuildObjectiveState(team)
    local difficultyLevel = BotBuff_GetDifficultyLevel()
    local state = {
        difficultyLevel = difficultyLevel,
        score = 0,
        towerLostByTier = {[1] = 0, [2] = 0, [3] = 0, [4] = 0},
        barracksLost = 0,
        fullLaneBarracksLost = 0,
        laneBarracks = {},
    }

    for _, towerData in pairs(BOT_OBJECTIVE_TOWERS[team] or {}) do
        if BotBuff_IsBuildingDead("npc_dota_tower", towerData.names) then
            state.score = state.score + towerData.weight
            state.towerLostByTier[towerData.tier] = state.towerLostByTier[towerData.tier] + 1
        end
    end

    for _, barracksData in pairs(BOT_OBJECTIVE_BARRACKS[team] or {}) do
        if BotBuff_IsBuildingDead("npc_dota_barracks", barracksData.names) then
            state.score = state.score + barracksData.weight
            state.barracksLost = state.barracksLost + 1
            state.laneBarracks[barracksData.lane] = state.laneBarracks[barracksData.lane] or {}
            state.laneBarracks[barracksData.lane][barracksData.kind] = true
        end
    end

    for _, laneState in pairs(state.laneBarracks) do
        if laneState.melee and laneState.ranged then
            state.fullLaneBarracksLost = state.fullLaneBarracksLost + 1
            state.score = state.score + 3
        end
    end

    state.objectiveStage = BotBuff_GetObjectiveStage(state.score, difficultyLevel)
    -- Hard/Lunatic 下，两路兵营全掉或任意4塔被摧毁时，bot 直接进入阶段5。
    if (difficultyLevel == BOT_DIFFICULTY_HARD or difficultyLevel == BOT_DIFFICULTY_LUNATIC)
        and (state.fullLaneBarracksLost >= 2 or state.towerLostByTier[4] >= 1) then
        state.objectiveStage = BOT_DYNAMIC_STAGE_MAX
    end
    state.stallPenalty = BotBuff_GetStallPenalty(team, state, difficultyLevel)
    state.dynamicStage = math.min(state.objectiveStage + state.stallPenalty, BOT_DYNAMIC_STAGE_MAX)
    return state
end

local function BotBuff_GetObjectiveState(team)
    local now = GameRules:GetGameTime()
    local difficultyLevel = BotBuff_GetDifficultyLevel()
    local cacheKey = BotBuff_GetCacheKey(team, difficultyLevel)
    local cached = botObjectiveCache[cacheKey]
    if cached ~= nil and cached.nextRefreshTime ~= nil and cached.nextRefreshTime > now then
        return cached.state
    end

    local state = BotBuff_BuildObjectiveState(team)
    botObjectiveCache[cacheKey] = {
        nextRefreshTime = now + BOT_OBJECTIVE_CACHE_INTERVAL,
        state = state,
    }

    return state
end

-- Bot 基础管理器
ability_common_bot_buff = class({})

function ability_common_bot_buff:GetIntrinsicModifierName()
    local caster = self:GetCaster()
    if caster ~= nil then
        local team = caster:GetTeamNumber()
        if team == DOTA_TEAM_GOODGUYS then
            return "modifier_bot_buff_radiant"
        elseif team == DOTA_TEAM_BADGUYS then
            return "modifier_bot_buff_dire"
        end
    end

	return "modifier_bot_buff"
end

function ability_common_bot_buff:OnOwnerDied()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local data = GetBotDifficultyData() or {}

	if caster:IsIllusion() then return end

    caster:ModifyGold(data.goldGainOnDeath or 0, false, DOTA_ModifyGold_AbilityGold)
end

modifier_bot_buff = class({})
LinkLuaModifier("modifier_bot_buff", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_bot_buff:IsHidden() return false end
--function modifier_bot_buff:IsDebuff() return false end
function modifier_bot_buff:IsPurgable() return false end
function modifier_bot_buff:RemoveOnDeath() return false end

function modifier_bot_buff:DeclareFunctions()
	-- 难度只调整数值增益，不再订阅攻击/移动事件施加自晕惩罚。
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_TOOLTIP,
	}
end

function modifier_bot_buff:RefreshDynamicBonus()
    if not IsServer() then return end

    local now = GameRules:GetGameTime()
    if self.nextDynamicBonusRefresh ~= nil and self.nextDynamicBonusRefresh > now then return end

    -- 建筑损失和拖延惩罚只低频刷新，避免属性查询时频繁扫描建筑。
    local state = BotBuff_GetObjectiveState(self.caster:GetTeamNumber())
    local oldStage = self.dynamicStage or 0
    self.objectiveScore = state.score or 0
    self.objectiveStage = state.objectiveStage or 0
    self.stallPenalty = state.stallPenalty or 0
    self.fullLaneBarracksLost = state.fullLaneBarracksLost or 0
    self.tier4TowerLost = state.towerLostByTier[4] or 0
    self.dynamicStage = state.dynamicStage or 0
    self.dynamicBonus = BOT_DYNAMIC_STAGE_BONUS[self.dynamicStage] or BOT_DYNAMIC_STAGE_BONUS[0]
    -- stack count 直接显示当前 bot 补强阶段，便于游戏内测试观察。
    self:SetStackCount(self.dynamicStage)
    if oldStage ~= self.dynamicStage and self.caster.CalculateStatBonus ~= nil then
        self.caster:CalculateStatBonus(true)
    end
    self.nextDynamicBonusRefresh = now + BOT_DYNAMIC_BONUS_REFRESH_INTERVAL
end

function modifier_bot_buff:GetDynamicBonus()
    if IsServer() then
        self:RefreshDynamicBonus()
        return self.dynamicBonus or BOT_DYNAMIC_STAGE_BONUS[self:GetStackCount()] or BOT_DYNAMIC_STAGE_BONUS[0]
    end

    -- 客户端无法扫描建筑，使用同步的 stack count 还原当前阶段奖励。
    return BOT_DYNAMIC_STAGE_BONUS[self:GetStackCount()] or BOT_DYNAMIC_STAGE_BONUS[0]
end

function modifier_bot_buff:GetModifierConstantManaRegen()
    local data = GetBotDifficultyData() or {}
	return data.manaRegen or 0
end

function modifier_bot_buff:GetModifierConstantHealthRegen()
    local data = GetBotDifficultyData() or {}
    local bonus = self:GetDynamicBonus()

	return (data.hpRegen or 0) + (bonus.hpRegen or 0)
end

 function modifier_bot_buff:GetModifierBonusStats_Strength()
    local data = GetBotDifficultyData() or {}
    local attrBase = data.giveAttrBase or {0, 0, 0}
    local bonus = self:GetDynamicBonus()

	return (attrBase[1] or 0) + (bonus.attr[1] or 0)
end

function modifier_bot_buff:GetModifierBonusStats_Agility()
    local data = GetBotDifficultyData() or {}
    local attrBase = data.giveAttrBase or {0, 0, 0}
    local bonus = self:GetDynamicBonus()

	return (attrBase[2] or 0) + (bonus.attr[2] or 0)
end

 function modifier_bot_buff:GetModifierBonusStats_Intellect()
    local data = GetBotDifficultyData() or {}
    local attrBase = data.giveAttrBase or {0, 0, 0}
    local bonus = self:GetDynamicBonus()

    return (attrBase[3] or 0) + (bonus.attr[3] or 0)
end

function modifier_bot_buff:GetModifierMoveSpeedBonus_Constant()
    local bonus = self:GetDynamicBonus()
    return bonus.moveSpeed or 0
end

function modifier_bot_buff:GetModifierCastRangeBonusStacking()
    local bonus = self:GetDynamicBonus()
    return bonus.castRange or 0
end

function modifier_bot_buff:GetModifierAttackRangeBonus()
    local bonus = self:GetDynamicBonus()
    if self:GetParent():IsRangedAttacker() then
        return bonus.rangedAttackRange or 0
    end

    return bonus.meleeAttackRange or 0
end

function modifier_bot_buff:GetModifierPercentageCooldown()
    local bonus = self:GetDynamicBonus()
    return bonus.cooldown or 0
end

function modifier_bot_buff:GetModifierSpellAmplify_Percentage()
    local bonus = self:GetDynamicBonus()
    return bonus.spellAmp or 0
end

function modifier_bot_buff:GetModifierMagicalResistanceBonus()
    local bonus = self:GetDynamicBonus()
    return bonus.magicResist or 0
end

function modifier_bot_buff:OnTooltip()
    -- tooltip 显示 stage/score/penalty，便于测试建筑统计是否漏计。
    return (self.dynamicStage or 0) * 10000 + (self.objectiveScore or 0) * 10 + (self.stallPenalty or 0)
end

function modifier_bot_buff:OnCreated(params)
    if not IsServer() then return end
    
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    local botDifficultyData = GetBotDifficultyData() or {}
    
    self.giveGoldAmount = botDifficultyData.giveGoldAmount or {0}
    self.giveExpAmount = botDifficultyData.giveExpAmount or {0}
    self.giveAttrBonus = botDifficultyData.giveAttrBonus or {{{0, 0, 0}}, {{0, 0, 0}}, {{0, 0, 0}}}
    self.dynamicStage = 0
    self.objectiveScore = 0
    self.objectiveStage = 0
    self.stallPenalty = 0
    self.fullLaneBarracksLost = 0
    self.tier4TowerLost = 0
    self.dynamicBonus = BOT_DYNAMIC_STAGE_BONUS[0]
    self:SetStackCount(self.dynamicStage)
    
    
    self.interval = self.ability:GetSpecialValueFor("interval")
    self:StartIntervalThink(self.interval)

    -- 难度削弱不再通过攻击/移动自晕实现；仅保留诊断版本标识。
    GameRules.THDMovementSubscriptionRun = "20260912-SELF-STUN-REMOVED-R1"
    GameRules.THDBotSelfStunRemoved = true
end

function modifier_bot_buff:ConvertExcessGoldToAttributes()
    if self.caster == nil or self.caster:IsNull() then return end

    local playerID = self.caster:GetPlayerOwnerID()
    if (playerID == nil or playerID < 0) and self.caster.GetPlayerID ~= nil then
        playerID = self.caster:GetPlayerID()
    end
    if playerID == nil or playerID < 0 then return end

    local reliableGold = PlayerResource:GetReliableGold(playerID)
    local unreliableGold = PlayerResource:GetUnreliableGold(playerID)
    local totalGold = reliableGold + unreliableGold
    if totalGold <= 9000 then return end

    local convertCount = math.floor((totalGold - 9000) / 800)
    if convertCount <= 0 then return end

    local convertGold = convertCount * 800
    local addAllAttr = convertCount
    local addPrimaryAttr = convertCount * 2

    -- 总金币超过9000时，每800金币转换为1点全属性和2点主属性，优先消耗不可靠金币。
    local reduceUnreliableGold = math.min(unreliableGold, convertGold)
    local reduceReliableGold = convertGold - reduceUnreliableGold
    PlayerResource:SetGold(playerID, unreliableGold - reduceUnreliableGold, false)
    if reduceReliableGold > 0 then
        PlayerResource:SetGold(playerID, reliableGold - reduceReliableGold, true)
    end

    self.caster:ModifyStrength(addAllAttr)
    self.caster:ModifyAgility(addAllAttr)
    self.caster:ModifyIntellect(addAllAttr)

    if self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        self.caster:ModifyStrength(addPrimaryAttr)
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
        self.caster:ModifyAgility(addPrimaryAttr)
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        self.caster:ModifyIntellect(addPrimaryAttr)
    end
end

function modifier_bot_buff:SellGemItems()
    if self.caster == nil or self.caster:IsNull() then return end

    local gemCount = 0
    --[[ Bot 无法合理处理真视宝石，每次低频检查时强制卖出主物品栏、背包和储藏栏中的宝石。 ]]
    for slot = 0, BOT_GEM_LAST_ITEM_SLOT do
        local item = self.caster:GetItemInSlot(slot)
        if item ~= nil and not item:IsNull() and item:GetAbilityName() == "item_gem" then
            self.caster:RemoveItem(item)
            UTIL_Remove(item)
            gemCount = gemCount + 1
        end
    end

    if gemCount > 0 then
        self.caster:ModifyGold(gemCount * BOT_GEM_SELL_GOLD, true, DOTA_ModifyGold_Unspecified)
    end
end

function modifier_bot_buff:SellKusanagiItems()
    if self.caster == nil or self.caster:IsNull() then return end

    local kusanagiCount = 0
    -- Bot 拾取天丛云剑后按鸦天狗的处理方式直接移除，并兑换为固定金币。
    for slot = 0, BOT_GEM_LAST_ITEM_SLOT do
        local item = self.caster:GetItemInSlot(slot)
        if item ~= nil and not item:IsNull() and item:GetAbilityName() == "item_kusanagi" then
            self.caster:RemoveItem(item)
            UTIL_Remove(item)
            kusanagiCount = kusanagiCount + 1
        end
    end

    if kusanagiCount > 0 then
        self.caster:ModifyGold(kusanagiCount * BOT_KUSANAGI_SELL_GOLD, true, DOTA_ModifyGold_Unspecified)
    end
end

function modifier_bot_buff:OnIntervalThink()
    if not IsServer() then return end


    if self.caster:IsIllusion() then return end

    -- 游戏还未开始，不生效
    local nowTime = GameRules:GetDOTATime(false, false)
    if (nowTime < 1.0) then return end

    self:SellGemItems()
    self:SellKusanagiItems()

    -- 按照5分钟分批的索引
    local timeIndex5 = math.ceil(nowTime / 300.0)
    local botDifficultyData = GetBotDifficultyData() or {}
    local dynamicBonus = self:GetDynamicBonus()
    local dynamicStage = self.dynamicStage or 0
    local giveGoldAmount = botDifficultyData.giveGoldAmount or self.giveGoldAmount or {0}
    local giveExpAmount = botDifficultyData.giveExpAmount or self.giveExpAmount or {0}
    local giveAttrBonus = botDifficultyData.giveAttrBonus or self.giveAttrBonus or {{{0, 0, 0}}, {{0, 0, 0}}, {{0, 0, 0}}}

    -- 时间成长保留，动态阶段额外补经济，避免前期直接压线过强。
    local addGold = (giveGoldAmount[math.min(timeIndex5, #giveGoldAmount)] or 0) + (dynamicBonus.gold or 0)
    self.caster:ModifyGold(addGold, false, DOTA_ModifyGold_AbilityGold)
    self:ConvertExcessGoldToAttributes()

    -- 经验补偿同样绑定动态阶段，用于惩罚长期不推进或追赶建筑劣势。
    local addExp = (giveExpAmount[math.min(timeIndex5, #giveExpAmount)] or 0) + (dynamicBonus.exp or 0)
    self.caster:AddExperience(addExp, DOTA_ModifyXP_HeroAbility, false, true)

    -- 永久属性仍随时间增加，动态阶段只提供倍率，避免阶段切换造成永久属性跳变。
    local addStrength = 0
    local addAgility = 0
    local addIntelligence = 0
    local attrGrowthMultiplier = 1 + dynamicStage * 0.08
    if self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        local attrBonusTable = (giveAttrBonus[1] or {})[math.min(timeIndex5, #(giveAttrBonus[1] or {}))] or {0, 0, 0}

        addStrength = (attrBonusTable[1] or 0) * attrGrowthMultiplier
        addAgility = (attrBonusTable[2] or 0) * attrGrowthMultiplier
        addIntelligence = (attrBonusTable[3] or 0) * attrGrowthMultiplier
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
        local attrBonusTable = (giveAttrBonus[2] or {})[math.min(timeIndex5, #(giveAttrBonus[2] or {}))] or {0, 0, 0}

        addStrength = (attrBonusTable[1] or 0) * attrGrowthMultiplier
        addAgility = (attrBonusTable[2] or 0) * attrGrowthMultiplier
        addIntelligence = (attrBonusTable[3] or 0) * attrGrowthMultiplier
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        local attrBonusTable = (giveAttrBonus[3] or {})[math.min(timeIndex5, #(giveAttrBonus[3] or {}))] or {0, 0, 0}

        addStrength = (attrBonusTable[1] or 0) * attrGrowthMultiplier
        addAgility = (attrBonusTable[2] or 0) * attrGrowthMultiplier
        addIntelligence = (attrBonusTable[3] or 0) * attrGrowthMultiplier
    end
    self.caster:ModifyStrength(addStrength)
    self.caster:ModifyAgility(addAgility)
    self.caster:ModifyIntellect(addIntelligence)

end

-- 按队伍拆分 modifier 名称，bot 对 bot 测试时可分别观察双方 buff。
modifier_bot_buff_radiant = class(modifier_bot_buff)
LinkLuaModifier("modifier_bot_buff_radiant", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

modifier_bot_buff_dire = class(modifier_bot_buff)
LinkLuaModifier("modifier_bot_buff_dire", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

-- Bot 收集器
ability_common_bot_corrector = class({})

function ability_common_bot_corrector:GetIntrinsicModifierName()
    return "modifier_bot_corrector"
end

modifier_bot_corrector = class({})
LinkLuaModifier("modifier_bot_corrector", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

local BOT_CORRECTOR_THINK_INTERVAL = 0.75
local BOT_CORRECTOR_PICKUP_RADIUS = 300

function modifier_bot_corrector:IsHidden() return true end
--function modifier_bot_corrector:IsDebuff() return false end
function modifier_bot_corrector:IsPurgable() return false end
function modifier_bot_corrector:RemoveOnDeath() return false end

function modifier_bot_corrector:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self:StartIntervalThink(BOT_CORRECTOR_THINK_INTERVAL)
end

function modifier_bot_corrector:OnIntervalThink()
    if not IsServer() then return end

	if self.caster:IsIllusion() then return end

	-- from rune_fixer.lua
	local vec = Vector(0.0,0.0,-512.0)
	local checklen = BOT_CORRECTOR_PICKUP_RADIUS

	local Caster = self.caster
	local Bounty_Spwner_List = Entities:FindAllByClassnameWithin("dota_item_rune_spawner_bounty", Caster:GetOrigin() + vec, checklen)
	
	if #Bounty_Spwner_List > 0 then
		local Rune_Bounty_List = Entities:FindAllByClassnameWithin("dota_item_rune", Caster:GetOrigin(), checklen)
		for _,v in pairs(Rune_Bounty_List) do
			if v ~= nil then
				--UTIL_Remove(v)
				Caster:PickupRune(v)
				break
			end
		end
	end
end
