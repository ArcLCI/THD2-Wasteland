-------------------------------------------------------------------------------------------
-- new 天生技能（可以使用魔晶升级）
-------------------------------------------------------------------------------------------
ability_thdots_shizuhaEXNew = {}

function ability_thdots_shizuhaEXNew:GetIntrinsicModifierName()
    return "modifier_thdots_shizuhaEX_check_levelup_new"
end
function ability_thdots_shizuhaEXNew:GetBehavior()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_POINT
    else
        return self.BaseClass.GetBehavior(self)
    end
end

function ability_thdots_shizuhaEXNew:OnSpellStart()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local ability = self
    local pOrg = caster:GetAbsOrigin()
    local pTgt = ability:GetCursorPosition()
    local tree_duration = self:GetSpecialValueFor("tree_duration")
    local modifier_duration = self:GetSpecialValueFor("modifier_duration")

    local p = pTgt - pOrg
    local vn = Vector(p.x, p.y, 0)
    local f = vn:Normalized()
    if f:Length2D() <= 0.1 then
        f = caster:GetForwardVector():Normalized()
        caster:SetForwardVector(f)
    end

    local angle = self:GetSpecialValueFor("trees_circle_angel")
    local radius = self:GetSpecialValueFor("trees_circle_radius")
    local speace = self:GetSpecialValueFor("trees_circle_speace")
    local trees_num = self:GetSpecialValueFor("trees_num")
    local angle_per_tree = angle * 2 / trees_num
    local pSt = pTgt - (radius - speace) * f -- （半径 - 间隔）取圆心
    for i = -angle, angle, angle_per_tree do
        local ff = RotatePosition(Vector(0, 0, 0), QAngle(0, i, 0), f) -- 旋转方向
        local pTemp = pSt + radius * ff
        CreateTempTree(pTemp, tree_duration)
    end

    EmitSoundOnLocationWithCaster(pSt, "Hero_Furion.Sprout", caster)

    -- 防止单位卡住
    local units = FindUnitsInRadius(caster:GetTeam(), pSt, nil, 550, DOTA_UNIT_TARGET_TEAM_BOTH,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for i, unit in pairs(units) do
        unit:SetUnitOnClearGround()
    end

    local trees_vision_radius = self:GetSpecialValueFor("trees_vision_radius")
    -- 视野
    AddFOWViewer(caster:GetTeamNumber(), pSt, trees_vision_radius, tree_duration, false)
    caster:AddNewModifier(caster, ability, "modifier_thdots_shizuhaEX_speed_up_buff", {
        duration = modifier_duration
    })
end

LinkLuaModifier("modifier_thdots_shizuhaEX_check_levelup_new", "scripts/vscripts/abilities/abilityshizuha.lua",
    LUA_MODIFIER_MOTION_NONE)

modifier_thdots_shizuhaEX_check_levelup_new = {}
function modifier_thdots_shizuhaEX_check_levelup_new:IsHidden()
    return false
end
function modifier_thdots_shizuhaEX_check_levelup_new:IsPurgable()
    return false
end
function modifier_thdots_shizuhaEX_check_levelup_new:RemoveOnDeath()
    return false
end
function modifier_thdots_shizuhaEX_check_levelup_new:IsDebuff()
    return false
end
function modifier_thdots_shizuhaEX_check_levelup_new:AllowIllusionDuplicate()
    return false
end

function modifier_thdots_shizuhaEX_check_levelup_new:OnCreated()
    if not IsServer() then
        return
    end
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.lastLevel = self.caster:GetLevel()
    self:SetStackCount(self.lastLevel)
    -- 升级是离散事件，低频检查并仅在等级变化时继续处理。
    self:StartIntervalThink(0.5)
end
function modifier_thdots_shizuhaEX_check_levelup_new:OnIntervalThink()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local currentLevel = caster:GetLevel()
    if currentLevel == self.lastLevel then
        return
    end

    local ability = self:GetAbility()
    local baseDamage = ability:GetSpecialValueFor("base_damage")
    local levelMultiple = ability:GetSpecialValueFor("level_multiple")

    if caster:IsRealHero() then

        -- 伤害值计算
        local dealdamages = ((currentLevel * levelMultiple) + baseDamage)
        -- 升级伤害只需要检查英雄列表，避免执行全图空间扫描。
        for _, vic in ipairs(HeroList:GetAllHeroes()) do
            if vic:IsAlive() and UnitFilter(vic, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(),
                ability:GetAbilityTargetFlags(), caster:GetTeamNumber()) == UF_SUCCESS then
                local damage_table = {
                    ability = ability,
                    victim = vic,
                    attacker = caster,
                    damage = dealdamages,
                    damage_type = ability:GetAbilityDamageType(),
                    damage_flags = 0
                }
                UnitDamageTarget(damage_table) -- 公用伤害方法
            end
        end

        -- 所有人说话广播
        -- GameRules:SendCustomMessage("#ShizuhaEXMessage", 0, 0)

        -- 显示左侧广播
        local gameEvent = {}
        gameEvent["player_id"] = caster:GetPlayerID()
        gameEvent["teamnumber"] = -1
        gameEvent["value"] = dealdamages
        gameEvent["message"] = "#ShizuhaEXMessage"
        FireGameEvent("dota_combat_event_message", gameEvent)

        -- 生产特效 在自己脚下
        local nEffectIndex = ParticleManager:CreateParticle(
            "particles/econ/items/windrunner/windranger_arcana/windranger_arcana_item_cyclone_v2_leaf.vpcf",
            PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(nEffectIndex, 0, caster:GetOrigin())
        ParticleManager:ReleaseParticleIndex(nEffectIndex)

    end

    self.lastLevel = currentLevel
    self:SetStackCount(currentLevel)
end

modifier_thdots_shizuhaEX_speed_up_buff = {}
LinkLuaModifier("modifier_thdots_shizuhaEX_speed_up_buff", "scripts/vscripts/abilities/abilityshizuha.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_shizuhaEX_speed_up_buff:IsPurgable()
    return true
end
function modifier_thdots_shizuhaEX_speed_up_buff:RemoveOnDeath()
    return true
end
function modifier_thdots_shizuhaEX_speed_up_buff:IsDebuff()
    return false
end

function modifier_thdots_shizuhaEX_speed_up_buff:GetEffectName()
    return "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_slow_debuff.vpcf"
end
function modifier_thdots_shizuhaEX_speed_up_buff:GetEffectAttachType()
    return "follow_origin"
end

function modifier_thdots_shizuhaEX_speed_up_buff:DeclareFunctions()
    return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_thdots_shizuhaEX_speed_up_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("active_bonus_attack_speed")
end

function modifier_thdots_shizuhaEX_speed_up_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("active_bonus_movespeed_pct")
end

-------------------------------------------------------------------------------------------
-- 一技能音效调用
-------------------------------------------------------------------------------------------
function shizuha01soundeffect(keys)
    local caster = keys.caster
    local ability = keys.ability
    local target = keys.ability:GetCursorPosition()
    local duration = keys.duration
    local radius = keys.radius
    local root_duration = keys.root_duration

    -- 施法圈命中单位
    local targets = FindUnitsInRadius(caster:GetTeam(), target, nil, radius, ability:GetAbilityTargetTeam(),
        ability:GetAbilityTargetType(), 0, 0, false)

    -- 给命中添加modifier
    for _, vic in ipairs(targets) do
        ability:ApplyDataDrivenModifier(caster, vic, "modifier_shizuha01", {
            duration = root_duration
        })
    end

    -- 释放技能特效
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf",
        PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, target)
    ParticleManager:SetParticleControl(particle, 1, target)
    ParticleManager:SetParticleControl(particle, 2, target)
    ParticleManager:DestroyParticleSystem(particle, false)

    local particle2 = ParticleManager:CreateParticle(
        "particles/econ/items/pugna/pugna_ti9_immortal/pugna_ti9_immortal_netherblast.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle2, 5, target)
    ParticleManager:DestroyParticleSystem(particle2, false)

    -- 台词语音
    caster:EmitSound("Voice_Thdots_Shizuha.AbilityShizuha01")
end

function OnShizuha01SpellStart(keys)
    local caster = keys.caster

    local target = keys.target
    local ability = keys.ability

    local intscale = keys.intscale
    local shizuha01dealdamage = keys.damage

    -- UnitDamageTarget(damage_table)	 

    local damage_table = {
        ability = keys.ability,
        victim = target,
        attacker = caster,
        damage = shizuha01dealdamage,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }
    UnitDamageTarget(damage_table)
    caster:EmitSound("suwako01effect")
end

function OnShizuha01SpellEnd(keys)

end

-------------------------------------------------------------------------------------------
-- 二技能
-------------------------------------------------------------------------------------------
function OnCreatedShizuha02Time(keys)
    local count = 0
    local times1 = keys.ability:GetChannelTime() - 1

    -- 每次回复血量和蓝量
    keys.caster:Heal(keys.heal_amount / times1, keys.caster)
    keys.caster:SetMana(keys.mana_regen_amount / times1 + keys.target:GetMana())

    -- 显示回复血量的特效
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, keys.caster, keys.heal_amount / times1, nil)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, keys.caster, keys.mana_regen_amount / times1, nil)

end

function OnCreatedShizuha02End(keys)
    -- print("施法完成成功，获得攻击力buff")
end

function OnShizuha02Interrupted(keys)
    -- print("施法被中断")
end

-------------------------------------------------------------------------------------------
-- 三技能
-------------------------------------------------------------------------------------------
ability_thdots_shizuha03 = {}
LinkLuaModifier("modifier_generic_orb_effect_lua", "components/modifiers/generic/modifier_generic_orb_effect_lua",
    LUA_MODIFIER_MOTION_NONE)

function ability_thdots_shizuha03:GetIntrinsicModifierName()
    return "aura_thdots_shizuha03_buff"
end

function ability_thdots_shizuha03:GetCastRange(vLocation, hTarget)
    -- GetOrbCastRange
    local caster = self:GetCaster()

    local tData = DOTAGameManager:GetHeroDataByName_Script(caster:GetUnitName())
    local BaseAttackRange = tonumber(tData["AttackRange"])
    local BaseCastRange = self.BaseClass.GetCastRange(self, vLocation, hTarget)

    local castrange = caster:Script_GetAttackRange()

    if IsServer() then
        -- Server-side
        -- Note: DOTA_ABILITY_BEHAVIOR_ATTACK会计算dota的攻击距离加成，但不会计算lua的
        local BonusAttackRange = GetSumModifierValues(caster, "GetModifierAttackRangeBonus")

        castrange = BaseCastRange + BonusAttackRange
    else
        -- Client-side
        castrange = BaseCastRange + (caster:Script_GetAttackRange() - BaseAttackRange)
        -- 移除施法距离加成
        castrange = castrange - caster:GetCastRangeBonus()
    end

    return castrange
end

function ability_thdots_shizuha03:GetProjectileName()
    return "particles/heros/shizuha/shizuha_attack_modifier_activation.vpcf"
end

function ability_thdots_shizuha03:OnOrbImpact(keys)
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local target = keys.target
    local duration = self:GetSpecialValueFor("disable_healing_times")

    if not target:IsMagicImmune() then
        target:AddNewModifier(caster, self, "shizuha03_disable_healing_debuff", {
            duration = duration * (1 - target:GetStatusResistance())
        })
    end

    -- 命中特效
    local particle = ParticleManager:CreateParticle("particles/heros/shizuha/shizuha_attack_modifier_endboom.vpcf",
        PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)

    local splash_damage = self:GetSpecialValueFor("range_damage") +
                              FindTelentValue(caster, "special_bonus_unique_shizuha_5")
    -- 当前主动法球仅对主目标造成额外物理伤害，不再扫描或伤害周围单位。
    local damage_table = {
        ability = self,
        victim = target,
        attacker = caster,
        damage = splash_damage,
        damage_type = self:GetAbilityDamageType(),
        damage_flags = 0
    }
    UnitDamageTarget(damage_table)
end

shizuha03_disable_healing_debuff = {}
LinkLuaModifier("shizuha03_disable_healing_debuff", "scripts/vscripts/abilities/abilityshizuha.lua",
    LUA_MODIFIER_MOTION_NONE)
function shizuha03_disable_healing_debuff:IsHidden()
    return false
end
function shizuha03_disable_healing_debuff:IsPurgable()
    return true
end
function shizuha03_disable_healing_debuff:RemoveOnDeath()
    return true
end
function shizuha03_disable_healing_debuff:IsDebuff()
    return true
end

function shizuha03_disable_healing_debuff:GetEffectName()
    return "particles/units/heroes/hero_spectre/spectre_desolate_debuff.vpcf"
end
function shizuha03_disable_healing_debuff:GetEffectAttachType()
    return "follow_origin"
end

function shizuha03_disable_healing_debuff:DeclareFunctions()
    return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP}
end

function shizuha03_disable_healing_debuff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("regen_amplify")
end
function shizuha03_disable_healing_debuff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("regen_amplify")
end
function shizuha03_disable_healing_debuff:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("regen_amplify")
end

aura_thdots_shizuha03_buff = {}
LinkLuaModifier("aura_thdots_shizuha03_buff", "scripts/vscripts/abilities/abilityshizuha.lua", LUA_MODIFIER_MOTION_NONE)
function aura_thdots_shizuha03_buff:IsHidden()
    return true
end
function aura_thdots_shizuha03_buff:IsPurgable()
    return false
end
function aura_thdots_shizuha03_buff:RemoveOnDeath()
    return false
end
function aura_thdots_shizuha03_buff:IsDebuff()
    return false
end

function aura_thdots_shizuha03_buff:IsAura()
    return true
end
function aura_thdots_shizuha03_buff:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end
function aura_thdots_shizuha03_buff:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end
function aura_thdots_shizuha03_buff:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function aura_thdots_shizuha03_buff:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NO_INVIS
end
function aura_thdots_shizuha03_buff:GetModifierAura()
    return "aura_thdots_shizuha03_buff_aura"
end

function aura_thdots_shizuha03_buff:OnCreated()
    if not IsServer() then
        return
    end
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local particle = ParticleManager:CreateParticle("particles/heros/shizuha/sizuha03_buff.vpcf",
        PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:ReleaseParticleIndex(particle)

    parent:AddNewModifier(parent, ability, "modifier_generic_orb_effect_lua", {
        duration = -1
    })
end

function aura_thdots_shizuha03_buff:OnDestroy()
    if not IsServer() then
        return
    end
    local parent = self:GetParent()

    if parent:HasModifier("aura_thdots_shizuha03_buff") then
        return
    end
    parent:RemoveModifierByNameAndCaster("modifier_generic_orb_effect_lua", parent)
end

aura_thdots_shizuha03_buff_aura = {}
LinkLuaModifier("aura_thdots_shizuha03_buff_aura", "scripts/vscripts/abilities/abilityshizuha.lua",
    LUA_MODIFIER_MOTION_NONE)
function aura_thdots_shizuha03_buff_aura:IsHidden()
    return false
end
function aura_thdots_shizuha03_buff_aura:IsPurgable()
    return false
end
function aura_thdots_shizuha03_buff_aura:RemoveOnDeath()
    return false
end
function aura_thdots_shizuha03_buff_aura:IsDebuff()
    return false
end

function aura_thdots_shizuha03_buff_aura:DeclareFunctions()
    return {MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE}
end

function aura_thdots_shizuha03_buff_aura:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("attack_bonus")
end

-------------------------------------------------------------------------------------------
-- A杖  新技能
-------------------------------------------------------------------------------------------

ability_thdots_shizuha05 = {}

function ability_thdots_shizuha05:GetAOERadius()
    return self:GetSpecialValueFor("radius_base")
end

function ability_thdots_shizuha05:CastFilterResultLocation(location)
    if not IsServer() then
        return
    end
    local radius = self:GetSpecialValueFor("radius_base")

    local trees = GridNav:GetAllTreesAroundPoint(location, radius, true)
    if #trees ~= 0 then
        return UF_SUCCESS
    else
        return UF_FAIL_CUSTOM
    end
end

function ability_thdots_shizuha05:GetCustomCastErrorLocation(location)
    return "#thd_hud_error_no_tree_in_radius"
end

function ability_thdots_shizuha05:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local pOrg = caster:GetAbsOrigin()
    local pTgt = self:GetCursorPosition()
    local radius = self:GetSpecialValueFor("radius_base")
    local radius_max = self:GetSpecialValueFor("radius_max")

    local interval = self:GetSpecialValueFor("interval") -- 触发间隔
    local tree_down_countdown = self:GetSpecialValueFor("tree_down_countdown") -- 树木持续时间
    local tree_down_delay = self:GetSpecialValueFor("tree_down_delay")
    local radius_increment = self:GetSpecialValueFor("radius_increment") -- 半径增加速度
    local damage = self:GetSpecialValueFor("damage")

    local debuff_duration = self:GetSpecialValueFor("debuff_duration")

    EmitSoundOnLocationWithCaster(pTgt, "Hero_Batrider.Flamebreak", caster)
    local trees = GridNav:GetAllTreesAroundPoint(pTgt, radius, true)
    -- 初始范围内每多1棵树，增加5%的伤害
    damage = damage * (1 + (#trees - 1) * self:GetSpecialValueFor("dmg_bonus_pct_per_tree") / 100)
    local processedTrees = {}
    -- 特效
    local ptc0 = ParticleManager:CreateParticle("particles/heros/shizuha/sizuha_05_leaf_nosuck.vpcf",
        PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(ptc0, 0, pTgt)
    ParticleManager:SetParticleControl(ptc0, 1, Vector(radius, 1, 1))
    -- ParticleManager:SetParticleControl(ptc0, 2, Vector(radius,0,0))

    caster:EmitSound("Hero_Batrider.Firefly.loop")
    Timers:CreateTimer(interval, function()

        if radius > radius_max then
            ParticleManager:SetParticleControl(ptc0, 1, Vector(radius_max, 1, 1))

            Timers:CreateTimer(tree_down_delay, function()
                ParticleManager:DestroyParticle(ptc0, false)
                ParticleManager:ReleaseParticleIndex(ptc0)
                caster:StopSound("Hero_Batrider.Firefly.loop")
                return nil
            end)
            return nil
        else
            -- 重新找树
            trees = GridNav:GetAllTreesAroundPoint(pTgt, radius, true)
            if #trees <= 0 then
                ParticleManager:SetParticleControl(ptc0, 1, Vector(radius_max, 1, 1))
                Timers:CreateTimer(tree_down_delay, function()
                    ParticleManager:DestroyParticle(ptc0, false)
                    ParticleManager:ReleaseParticleIndex(ptc0)
                    caster:StopSound("Hero_Batrider.Firefly.loop")
                    return nil
                end)
                return nil
            end

            local roundParticles = {}
            for i, tree in pairs(trees) do
                local treeIndex = tree:entindex()
                if not processedTrees[treeIndex] then
                    processedTrees[treeIndex] = true
                    -- 每棵树只创建一次特效，避免扩圈时重复处理内圈树木。
                    local ptc = ParticleManager:CreateParticle(
                        "particles/econ/items/windrunner/windranger_arcana/windranger_arcana_ambient_v2.vpcf",
                        PATTACH_WORLDORIGIN, nil)
                    ParticleManager:SetParticleControl(ptc, 0, tree:GetAbsOrigin())
                    ParticleManager:SetParticleShouldCheckFoW(ptc, false)
                    table.insert(roundParticles, ptc)
                end
            end

            local roundTrees = trees
            local shouldCutTrees = tree_down_countdown - interval <= 0
            -- 每轮共用一个 Timer，统一清理粒子和到期树木。
            Timers:CreateTimer(tree_down_delay, function()
                for _, ptc in pairs(roundParticles) do
                    ParticleManager:DestroyParticle(ptc, false)
                    ParticleManager:ReleaseParticleIndex(ptc)
                end
                if shouldCutTrees then
                    for _, tree in pairs(roundTrees) do
                        if tree ~= nil and not tree:IsNull() then
                            if tree:GetClassname() == "dota_temp_tree" then
                                tree:RemoveSelf()
                            else
                                tree:CutDown(caster:GetTeamNumber())
                            end
                        end
                    end
                end
                return nil
            end)

            ParticleManager:SetParticleControl(ptc0, 1, Vector(radius, 1, 1))
            -- ParticleManager:SetParticleControl(ptc0, 2, Vector(radius,0,0))

            local enemies = FindUnitsInRadius(caster:GetTeam(), pTgt, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
            if #enemies > 0 then
                for i, enemy in pairs(enemies) do
                    if enemy ~= nil and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then
                        -- 1.2秒 降低移速
                        enemy:AddNewModifier(caster, self, "modifier_shizuha05_leaf_wood_debuff", {
                            duration = debuff_duration
                        })
                        local damage_table = {
                            ability = self,
                            victim = enemy,
                            attacker = caster,
                            damage = damage,
                            damage_type = self:GetAbilityDamageType(),
                            damage_flags = 0
                        }
                        UnitDamageTarget(damage_table)

                        local ptc1 = ParticleManager:CreateParticle(
                            "particles/econ/items/windrunner/windranger_arcana/windranger_arcana_monkey_king_bar_tgt_v2.vpcf",
                            PATTACH_POINT_FOLLOW, enemy)
                        ParticleManager:SetParticleControlEnt(ptc1, 0, enemy, PATTACH_POINT_FOLLOW, "follow_hitloc",
                            enemy:GetAbsOrigin(), true)
                        ParticleManager:ReleaseParticleIndex(ptc1)
                    end
                end
            end

            radius = radius + radius_increment
            tree_down_countdown = tree_down_countdown - interval

            -- SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, caster, radius, nil)

            return interval
        end
    end)
end

modifier_shizuha05_leaf_wood_debuff = {}
LinkLuaModifier("modifier_shizuha05_leaf_wood_debuff", "scripts/vscripts/abilities/abilityshizuha.lua",
    LUA_MODIFIER_MOTION_NONE)

function modifier_shizuha05_leaf_wood_debuff:IsHidden()
    return false
end
function modifier_shizuha05_leaf_wood_debuff:IsPurgable()
    return true
end
function modifier_shizuha05_leaf_wood_debuff:RemoveOnDeath()
    return true
end
function modifier_shizuha05_leaf_wood_debuff:IsDebuff()
    return true
end

function modifier_shizuha05_leaf_wood_debuff:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_shizuha05_leaf_wood_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_slow_pct")
end

-------------------------------------------------------------------------------------------
-- 4技能  套用tinker《机械行军》模块
-------------------------------------------------------------------------------------------
ability_thdots_shizuha04 = class({})
LinkLuaModifier("modifier_shizuha04_thinker", "scripts/vscripts/abilities/abilityshizuha.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_shizuha04_damage_control", "scripts/vscripts/abilities/abilityshizuha.lua",
    LUA_MODIFIER_MOTION_NONE) -- 攻击伤害覆盖 modifier_imba_swashbuckle_damage_control

--------------------------------------------------------------------------------
-- Ability Start
function ability_thdots_shizuha04:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- create thinker
    CreateModifierThinker(caster, self, "modifier_shizuha04_thinker", {}, point, caster:GetTeamNumber(), false)

    -- Play effects
    self:PlayEffects()
end
--------------------------------------------------------------------------------
-- 发射物
function ability_thdots_shizuha04:OnProjectileHit_ExtraData(target, location, extraData)
    if not target then
        return true
    end

    -- find units in radius
    local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), -- int, your team number
    location, -- point, center point
    nil, -- handle, cacheUnit. (not known)
    extraData.radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
    self:GetAbilityTargetTeam(), -- int, team filter
    self:GetAbilityTargetType(), -- int, type filter
    0, -- int, flag filter
    0, -- int, order filter
    false -- bool, can grow cache
    )

    local caster = self:GetCaster()
    if #enemies > 0 then
        -- 同一投射物命中范围内共用一次伤害覆盖 modifier，保留每个目标的 PerformAttack。
        caster:AddNewModifier(caster, self, "modifier_shizuha04_damage_control", {})
        for _, enemy in pairs(enemies) do
            caster:PerformAttack(enemy, false, true, true, true, false, false, true)
        end
        caster:RemoveModifierByName("modifier_shizuha04_damage_control")
    end

    return true
end

--------------------------------------------------------------------------------
function ability_thdots_shizuha04:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_tinker/tinker_motm.vpcf"
    local sound_cast = "Voice_Thdots_Shizuha.AbilityShizuha04"

    -- Create Particle 创建手部特效
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(effect_cast, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1",
        Vector(0, 0, 0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound 创建音效
    EmitSoundOnLocationForAllies(self:GetCaster():GetOrigin(), sound_cast, self:GetCaster())
end
--------------------------------------------------------------------------------
-- 覆盖攻击伤害
modifier_shizuha04_damage_control = class({})

function modifier_shizuha04_damage_control:IsHidden()
    return true
end
function modifier_shizuha04_damage_control:IsPurgable()
    return false
end

function modifier_shizuha04_damage_control:OnCreated()
    if not IsServer() then
        return
    end

    if self:GetAbility() then
        local splash_damage = self:GetAbility():GetSpecialValueFor("new_damage")

        self.damage = splash_damage

    else
        self.damage = 0
    end
end

function modifier_shizuha04_damage_control:DeclareFunctions()
    return {MODIFIER_PROPERTY_OVERRIDE_ATTACK_DAMAGE}
end

function modifier_shizuha04_damage_control:GetModifierOverrideAttackDamage()
    return self.damage
end
-----------------------------------------------------------------------------------------------------------------------------------

modifier_shizuha04_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_shizuha04_thinker:IsHidden()
    return true
end

function modifier_shizuha04_thinker:IsDebuff()
    return false
end

function modifier_shizuha04_thinker:IsPurgable()
    return false
end

function modifier_shizuha04_thinker:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_shizuha04_thinker:OnCreated(kv)
    if IsServer() then
        -- 参数
        local duration = self:GetAbility():GetSpecialValueFor("duration") -- special value
        self.radius = self:GetAbility():GetSpecialValueFor("radius") -- special value

        local speed = self:GetAbility():GetSpecialValueFor("speed") -- special value
        local distance = self:GetAbility():GetSpecialValueFor("distance") -- special value
        -- if self:GetCaster():HasScepter() then
        -- 	distance = self:GetAbility():GetSpecialValueFor( "distance_scepter" ) -- special value
        -- end

        local machines_per_sec = self:GetAbility():GetSpecialValueFor("machines_per_sec") -- special value
        local collision_radius = self:GetAbility():GetSpecialValueFor("collision_radius") -- special value
        local splash_radius = self:GetAbility():GetSpecialValueFor("splash_radius") -- special value

        -- generate Data
        local projectile_name = "particles/heros/shizuha/sizuha04_leaf_fall.vpcf"
        local interval = 1 / machines_per_sec
        local center = self:GetParent():GetOrigin()

        local direction = (center - self:GetCaster():GetOrigin())
        direction = Vector(direction.x, direction.y, 0):Normalized()
        self:GetParent():SetForwardVector(direction)

        self.spawn_vector = self:GetParent():GetRightVector()

        self.center_start = center - direction * self.radius

        -- Precache projectile info
        self.projectile_info = {
            Source = self:GetCaster(),
            Ability = self:GetAbility(),
            -- vSpawnOrigin = spawn,

            bDeleteOnHit = true,

            iUnitTargetTeam = self:GetAbility():GetAbilityTargetTeam(),
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = self:GetAbility():GetAbilityTargetType(),

            EffectName = projectile_name,
            fDistance = distance,
            fStartRadius = collision_radius,
            fEndRadius = collision_radius,
            fExpireTime = GameRules:GetGameTime() + 10.0,
            vVelocity = direction * speed,

            ExtraData = {
                radius = splash_radius
            }
        }

        -- 设置持续时间
        self:SetDuration(duration, false)

        -- 每个落叶产生的时间间隔
        self:StartIntervalThink(interval)
        self:OnIntervalThink()

        -- 播放音效
        local sound_cast = "Hero_Windrunner.Projection"
        EmitSoundOn(sound_cast, self:GetParent())
    end
end

function modifier_shizuha04_thinker:OnRefresh(kv)

end

function modifier_shizuha04_thinker:OnDestroy(kv)
    if IsServer() then
        -- effects
        local sound_cast = "Hero_Windrunner.Projection"
        StopSoundOn(sound_cast, self:GetParent())

        UTIL_Remove(self:GetParent())
    end
end

function modifier_shizuha04_thinker:DeclareFunctions()
    local funcs = {MODIFIER_STATE_NO_UNIT_COLLISION}

    return funcs
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_shizuha04_thinker:OnIntervalThink()
    -- generate spawn point
    local spawn = self.center_start + self.spawn_vector * RandomInt(-self.radius, self.radius)

    -- spawn machines
    self.projectile_info.vSpawnOrigin = spawn
    ProjectileManager:CreateLinearProjectile(self.projectile_info)
end

-----------------------------------------------------------------------------------------------------------------------------------
