function OnsuwakoexSpellStart(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local suwakointscale = keys.intscale
    local dealdamagesuwako = ((caster:GetIntellect(false) * suwakointscale) + ability:GetAbilityDamage())
    local damage_table = {
        ability = keys.ability,
        victim = target,
        attacker = caster,
        damage = dealdamagesuwako,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }

    local effectIndex = ParticleManager:CreateParticle(
        "particles/econ/items/storm_spirit/strom_spirit_ti8/gold_storm_sprit_ti8_overload_discharge.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 2, target:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 5, target:GetOrigin())
    caster:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")
    ParticleManager:DestroyParticleSystem(effectIndex, false)
    local suwakoexdamage = UnitDamageTarget(damage_table)
end

function OnsuwakoexSpellStart2(keys)
    local caster = keys.caster
    local target = keys.ability:GetCursorPosition()
    local ability = keys.ability
    local damageradius = ability:GetLevelSpecialValueFor("suwakoex_radius", ability:GetLevel() - 1)

    local suwakointscale = ability:GetLevelSpecialValueFor("int_multi", ability:GetLevel() - 1)
    local dealdamagesuwako = ((caster:GetIntellect(false) * suwakointscale) + ability:GetAbilityDamage()) *
                                 (1 + FindTelentValue(caster, "special_bonus_unique_suwako_8"))

    local suwakomaxtarget = FindValueTHD("max_target", ability)

    -- ability:EndCooldown()
    -- ability:StartCooldown(2.2)

    local suwakotarget = 0
    local targets = FindUnitsInRadius(caster:GetTeam(), -- caster team
    target, -- find position
    nil, -- find entity
    damageradius, -- find radius
    DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, 0, FIND_CLOSEST, false)
    caster.suwakoexeffect = 0
    for _, v in pairs(targets) do
        suwakotarget = suwakotarget + 1
        if suwakotarget > suwakomaxtarget then
            dealdamagesuwako = 0
        end
        local damage_table = {
            ability = keys.ability,
            victim = v,
            attacker = caster,
            damage = dealdamagesuwako,
            damage_type = keys.ability:GetAbilityDamageType(),
            damage_flags = 0
        }
        if caster.suwakoexeffect == 0 then
            local effectIndex = ParticleManager:CreateParticle(
                "particles/econ/items/storm_spirit/strom_spirit_ti8/gold_storm_sprit_ti8_overload_discharge.vpcf",
                PATTACH_CUSTOMORIGIN, caster)
            ParticleManager:SetParticleControl(effectIndex, 0, target)
            ParticleManager:SetParticleControl(effectIndex, 1, target)
            ParticleManager:SetParticleControl(effectIndex, 2, target)
            ParticleManager:SetParticleControl(effectIndex, 5, target)
            v:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")
            caster.suwakoexeffect = 1
            ParticleManager:DestroyParticleSystem(effectIndex, false)
        end
        UnitDamageTarget(damage_table)
    end
    caster.suwakoexeffect = 0
end

function suwako01soundeffect(keys)
    local caster = keys.caster
    local ability = keys.ability
    local radius = ability:GetCastRange()
    local root_duration = ability:GetSpecialValueFor("root_duration")
    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, ability:GetAbilityTargetTeam(),
        ability:GetAbilityTargetType(), 0, 0, false)
    for _, vic in ipairs(targets) do
        ability:ApplyDataDrivenModifier(caster, vic, "modifier_suwako01", {
            duration = root_duration
        })
    end

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf",
        PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
    ParticleManager:DestroyParticleSystem(particle, false)

    local particle_demo = ParticleManager:CreateParticle("particles/heroes/seija/seija04.vpcf",
        PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle_demo, 2, Vector(radius, radius, radius))
    caster:EmitSound("suwako01effectvoice_" .. math.random(1, 3))
    ParticleManager:DestroyParticleSystem(particle_demo, false)
end

function suwakoexvoice(keys)
    local caster = keys.caster
    caster:EmitSound("suwako_innate_" .. math.random(1, 3))
end
function OnSuwako01SpellStart(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    -- ApplyDamage({victim = target, attacker = caster, damage = (caster:GetIntellect(false)*1.4) +  ability:GetAbilityDamage(), damage_type = keys.ability:GetAbilityDamageType()})
    local intscale = keys.intscale
    local suwako01dealdamage = (caster:GetIntellect(false) * intscale) + ability:GetAbilityDamage() +
                                   FindTelentValue(caster, "special_bonus_unique_suwako_1")
    local damage_table = {
        ability = keys.ability,
        victim = target,
        attacker = caster,
        damage = suwako01dealdamage,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }
    UnitDamageTarget(damage_table)
    caster:EmitSound("suwako01effect")
end

function OnSuwako01SpellEnd(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
end

function Suwako02cooldown(keys)
    local caster = keys.caster
end

function OnSuwako02SpellStart(keys)
    local caster = keys.caster
    local model = keys.model

    if caster:GetModelName() ~= model then
        caster.pre_model = caster:GetModelName()
    end
    if caster:GetModelScale() ~= model then
        caster.pre_model_scale = caster:GetModelScale()
    end

    caster:SetOriginalModel(model)
    caster:SetModelScale(4)
    -- caster:SetModel(model)	
    caster:EmitSound("suwako02_1")
    local ability_duration = keys.ability:GetSpecialValueFor("ability_duration")
    local suwako02_modifier = caster:AddNewModifier(caster, keys.ability, "modifier_ability_thdots_suwako02_telent", {
        duration = ability_duration
    })
    if FindTelentValue(caster, "special_bonus_unique_suwako_7") ~= 0 then
        suwako02_modifier:SetStackCount(1)
    end
end

modifier_ability_thdots_suwako02_telent = {}
LinkLuaModifier("modifier_ability_thdots_suwako02_telent", "scripts/vscripts/abilities/abilitysuwako.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_suwako02_telent:IsHidden()
    return true
end
function modifier_ability_thdots_suwako02_telent:IsPurgable()
    return false
end
function modifier_ability_thdots_suwako02_telent:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_suwako02_telent:IsDebuff()
    return false
end

function modifier_ability_thdots_suwako02_telent:CheckState()
    if self:GetStackCount() == 1 then
        return {
            [MODIFIER_STATE_SILENCED] = false,
            [MODIFIER_STATE_MUTED] = false
        }
    else
        return {
            [MODIFIER_STATE_SILENCED] = true,
            [MODIFIER_STATE_MUTED] = true
        }
    end
end

function modifier_ability_thdots_suwako02_telent:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_ability_thdots_suwako02_telent:GetModifierMoveSpeedBonus_Percentage()
    if self:GetStackCount() == 1 then
        return self:GetAbility():GetSpecialValueFor("movement_speed_percent_bonus_suwako")
    else
        return 0
    end
end

function suwako02modelcheck(keys)
    local caster = keys.caster
    local model = keys.model
    caster.pre_model = caster:GetModelName()
    caster.pre_model_scale = caster:GetModelScale()
    caster:SetModel(model)
end

function suwako02effectcheck(keys)
    local caster = keys.caster
    local radius = keys.radius
    local effectIndex4 = ParticleManager:CreateParticle("particles/econ/events/ti7/shivas_guard_active_ti7.vpcf",
        PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(effectIndex4, 0, caster:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex4, 1, Vector(radius - 300, 0, radius - 300))
    caster:EmitSound("suwako_02")
    ParticleManager:DestroyParticleSystemTime(effectIndex4, 1)
end

function OnSuwako02SpellEnd(keys)
    local caster = keys.caster
    caster:SetOriginalModel(caster.pre_model)
    caster:SetModelScale(caster.pre_model_scale)
end

function suwako02damage(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local intervals = FindValueTHD("intervals", ability)
    local intscale = FindValueTHD("int_scale", ability)
    local suwako02dealdamage = ((caster:GetIntellect(false) * intscale) + ability:GetAbilityDamage()) * intervals
    -- ApplyDamage({victim = target, attacker = caster, damage = ((caster:GetIntellect(false)*0.5) +  ability:GetAbilityDamage())*0.5, damage_type = keys.ability:GetAbilityDamageType()})

    if target:IsHero() then
        caster:EmitSound("suwako_02")
        local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti7/shivas_guard_impact_ti7.vpcf",
            PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
        ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
        ParticleManager:DestroyParticleSystemTime(effectIndex, 1)
    end

    local suwakoslowduration = 0
    if caster:HasModifier("modifier_suwako02_change") then
        local suwako2duration = caster:FindModifierByName("modifier_suwako02_change"):GetRemainingTime()
        suwakoslowduration = keys.SlowDuration + suwako2duration
    else
        suwakoslowduration = keys.SlowDuration
    end

    keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_suwako02_slow", {
        duration = suwakoslowduration
    })
    local damage_table = {
        ability = keys.ability,
        victim = target,
        attacker = caster,
        damage = suwako02dealdamage,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }
    UnitDamageTarget(damage_table)
    -- keys.ability:ApplyDataDrivenModifier(caster,target,"modifier_suwako02_ministun",{})
end

function suwako03manacost(keys)
    local caster = keys.caster
    local manacost = keys.manacost
    local manatospend = ((caster:GetMaxMana() * manacost) / 100)
    local ability = keys.ability
    caster:Script_ReduceMana(manatospend, ability)
end

function suwako03check(keys)
    local caster = keys.caster
    local manacost = keys.manacost

    local ability = keys.ability

    if caster:GetMana() < ((caster:GetMaxMana() * manacost) / 100) then

        ability:SetActivated(false)
    else
        ability:SetActivated(true)
    end
end

function OnSuwako04SpellStartNew(keys)

    local caster = keys.caster
    local ability = keys.ability

    THDReduceCooldown(ability, -FindTelentValue(caster, "special_bonus_unique_suwako_3"))
    -- caster:EmitSound("suwako_04_"..math.random(1,3))	
    EmitGlobalSound("suwako_04_" .. math.random(1, 3))
    -- caster:GiveMana(((caster:GetIntellect(false)*0.6)+120)*0.12)	
    local targets = FindUnitsInRadius(caster:GetTeam(), -- caster team
    caster:GetAbsOrigin(), -- find position
    nil, -- find entity
    99999, -- find radius
    DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
    for _, v in pairs(targets) do
        ability:ApplyDataDrivenModifier(caster, v, "modifier_suwako04", {})
    end

end

function OnSuwako04ModifierCheckDestroyedNew(keys)
    local caster = keys.caster

    local target = keys.target
    local ability = keys.ability
    -- ApplyDamage({victim = target, attacker = caster, damage = (caster:GetIntellect(false)*0.6) +  ability:GetAbilityDamage(), damage_type = keys.ability:GetAbilityDamageType()})
    ability:ApplyDataDrivenModifier(caster, target, "modifier_suwako04_stun", {
        duration = keys.Duration
    })
    local suwako04dealdamage = (caster:GetIntellect(false) * 0.6) + ability:GetAbilityDamage() +
                                   FindTelentValue(caster, "special_bonus_unique_suwako_4")

    local damage_table = {
        ability = keys.ability,
        victim = target,
        attacker = caster,
        damage = suwako04dealdamage,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }
    local targetLoc = target:GetAbsOrigin()
    UnitDamageTarget(damage_table)
    caster:EmitSound("suwako_04")

    local effectIndex = ParticleManager:CreateParticle(
        "particles/econ/items/kunkka/kunkka_weapon_whaleblade_retro/kunkka_spell_torrent_retro_whaleblade_b.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, targetLoc)
    ParticleManager:SetParticleControl(effectIndex, 1, targetLoc)
    ParticleManager:SetParticleControl(effectIndex, 2, targetLoc)
    ParticleManager:SetParticleControl(effectIndex, 5, targetLoc)
    ParticleManager:DestroyParticleSystem(effectIndex, false)

    local effectIndex4 = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_earthshaker/earthshaker_fissure.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex4, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(effectIndex4, 1, caster:GetAbsOrigin())
    ParticleManager:DestroyParticleSystem(effectIndex4, false)

    local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti7/shivas_guard_impact_ti7.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, targetLoc)
    ParticleManager:SetParticleControl(effectIndex, 1, targetLoc)
    ParticleManager:DestroyParticleSystem(effectIndex, false)

end

function Onsuwako04check(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    ability:ApplyDataDrivenModifier(caster, target, "modifier_suwako04", {})
    ability:ApplyDataDrivenModifier(caster, target, "modifier_suwako04_stun", {})
end

function Onsuwako04start(keys)
    local caster = keys.caster

    local target = keys.target
    local ability = keys.ability
    -- ApplyDamage({victim = target, attacker = caster, damage = (caster:GetIntellect(false)*0.6) +  ability:GetAbilityDamage(), damage_type = keys.ability:GetAbilityDamageType()})

    local suwako04dealdamage = (caster:GetIntellect(false) * 0.6) + ability:GetAbilityDamage() +
                                   FindTelentValue(caster, "special_bonus_unique_suwako_4")

    local damage_table = {
        ability = keys.ability,
        victim = target,
        attacker = caster,
        damage = suwako04dealdamage,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }

    caster:EmitSound("suwako_04")

    local effectIndex = ParticleManager:CreateParticle(
        "particles/econ/items/kunkka/kunkka_weapon_whaleblade_retro/kunkka_spell_torrent_retro_whaleblade_b.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 2, target:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 5, target:GetOrigin())
    ParticleManager:DestroyParticleSystem(effectIndex, false)

    local effectIndex4 = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_earthshaker/earthshaker_fissure.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex4, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(effectIndex4, 1, caster:GetAbsOrigin())
    ParticleManager:DestroyParticleSystem(effectIndex4, false)

    local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti7/shivas_guard_impact_ti7.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
    ParticleManager:DestroyParticleSystem(effectIndex, false)

    UnitDamageTarget(damage_table)
end

function Suwako04voice(event)
    local caster = event.caster
    -- local ability = event.ability	
    THDReduceCooldown(event.ability, -FindTelentValue(caster, "special_bonus_unique_suwako_3"))
    -- caster:EmitSound("suwako_04_"..math.random(1,3))	
    EmitGlobalSound("suwako_04_" .. math.random(1, 3))
    -- caster:GiveMana(((caster:GetIntellect(false)*0.6)+120)*0.12)	
end

function HideWearables(event)
    local hero = event.caster
    local ability = event.ability

    hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
    local model = hero:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW) -- Set model hidden
            table.insert(hero.hiddenWearables, model)
        end
        model = model:NextMovePeer()
    end
end

function ShowWearables(event)
    local hero = event.caster

    for i, v in pairs(hero.hiddenWearables) do
        v:RemoveEffects(EF_NODRAW)
    end
end

function OnSuwako03DealDamage(keys)
    local caster = keys.caster
    local dmg = keys.DealDamage
    local returnmana = keys.Manareturn
    local getmana = dmg * returnmana * 0.01
    caster:GiveMana(getmana)
end

function OnSuwako03TakeDamage(keys)

    local caster = keys.caster
    local ability = keys.ability
    local attacker = keys.attacker
    local damagetaken = keys.DamageTaken
    local reduction = ability:GetLevelSpecialValueFor("damage_reduction", ability:GetLevel() - 1)
    local positivereduction = reduction * (-1)
    local rawdamage = (damagetaken * 100) / positivereduction
    local reducedamage = rawdamage * positivereduction * 0.01
    local manaabsorb = keys.Manaabsorb
    local manatospend = reducedamage / manaabsorb
    if caster:GetHealth() == 0 then
        return
    end
    if manatospend > caster:GetMana() then
        local mananeeded = manatospend - caster:GetMana()
        local hpneeded = mananeeded * manaabsorb
        if hpneeded > caster:GetHealth() then
            if attacker == nil then
                caster:SetHealth(1)
            else
                caster:Kill(ability, attacker)
            end
        else
            caster:SetHealth(caster:GetHealth() - hpneeded)
        end
        caster:SetMana(0)
        if caster:GetMana() == 0 and ability:GetToggleState() then
            ability:ToggleAbility()
        end
    else
        caster:SetMana(caster:GetMana() - manatospend)
    end
    if caster:GetMana() == 0 and ability:GetToggleState() then
        ability:ToggleAbility()
    end
end

function suwako03toggleoff(keys)
    local caster = keys.caster
    local ability = keys.ability
    ability:StartCooldown(5)
end


-- 5技能永久被动：用 Lua modifier 监听攻击，避免 KV 定时轮询
modifier_suwako05_passive = class({})
LinkLuaModifier("modifier_suwako05_passive", "scripts/vscripts/abilities/abilitysuwako.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_suwako05_passive:IsHidden() return true end
function modifier_suwako05_passive:IsPurgable() return false end
function modifier_suwako05_passive:IsDebuff() return false end
function modifier_suwako05_passive:RemoveOnDeath() return false end

function modifier_suwako05_passive:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_suwako05_passive:OnAttackLanded(keys)
    if not IsServer() then return end
    local caster = self:GetParent()
    if keys.attacker ~= caster then return end

    local target = keys.target
    local ability = self:GetAbility()
    if not target or not ability or ability:IsNull() then return end
    -- 命中时再检查自动施法和冷却，保持原自动触发条件
    if not ability:GetAutoCastState() or not ability:IsCooldownReady() then return end

    local manaCost = ability:GetManaCost(ability:GetLevel() - 1)
    if caster:GetMana() < manaCost then return end
    local cooldown = ability:GetSpecialValueFor("cooldown")

    caster:SpendMana(manaCost, ability)
    CastSuwako05AtLocation(caster, ability, target:GetOrigin())

    -- 冷却统一读取 KV，避免魔晶分支绕过自动触发冷却。
    ability:StartCooldown(cooldown)
end

function ApplySuwako05Passive(keys)
    local caster = keys.caster
    local ability = keys.ability
    if not caster:HasModifier("modifier_suwako05_passive") then
        caster:AddNewModifier(caster, ability, "modifier_suwako05_passive", {})
    end
end

-- 公共伤害函数（在目标位置施放技能效果）
function CastSuwako05AtLocation(caster, ability, targetLoc)
    if not ability or ability:IsNull() then return end

    local damageradius = ability:GetLevelSpecialValueFor("suwakoex_radius", ability:GetLevel() - 1)
    local suwakointscale = ability:GetLevelSpecialValueFor("int_multi", ability:GetLevel() - 1)
    local baseDamage = ability:GetAbilityDamage()
    local damage = ((caster:GetIntellect(false) * suwakointscale) + baseDamage) *
                       (1 + FindTelentValue(caster, "special_bonus_unique_suwako_8"))
    local maxTarget = FindValueTHD("max_target", ability)

    local targets = FindUnitsInRadius(caster:GetTeam(), targetLoc, nil, damageradius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, 0, FIND_CLOSEST, false)

    local targetCount = 0
    local playedEffect = false
    for _, v in pairs(targets) do
        targetCount = targetCount + 1
        if targetCount > maxTarget then break end
        local damage_table = {
            ability = ability,
            victim = v,
            attacker = caster,
            damage = damage,
            damage_type = ability:GetAbilityDamageType(),
            damage_flags = 0
        }
        if not playedEffect then
            local effectIndex = ParticleManager:CreateParticle(
                "particles/econ/items/storm_spirit/strom_spirit_ti8/gold_storm_sprit_ti8_overload_discharge.vpcf",
                PATTACH_CUSTOMORIGIN, caster)
            ParticleManager:SetParticleControl(effectIndex, 0, targetLoc)
            ParticleManager:SetParticleControl(effectIndex, 1, targetLoc)
            ParticleManager:SetParticleControl(effectIndex, 2, targetLoc)
            ParticleManager:SetParticleControl(effectIndex, 5, targetLoc)
            v:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")
            playedEffect = true
            ParticleManager:DestroyParticleSystem(effectIndex, false)
        end
        UnitDamageTarget(damage_table)
    end
end

-- 主动施法（手动施放）
function OnsuwakoexSpellStart2(keys)
    local caster = keys.caster
    local ability = keys.ability
    local targetUnit = keys.target
    if not targetUnit then return end

    local cooldown = keys.cooldown

    -- 检查手动冷却修饰器（魔晶后专用）
    if caster:HasModifier("modifier_suwako05_manual_cooldown") then
        -- 仍在冷却中，拒绝施放
        return
    end

    -- 播放语音
    caster:EmitSound("suwako_innate_" .. math.random(1, 3))

    -- 施放技能效果
    CastSuwako05AtLocation(caster, ability, targetUnit:GetOrigin())

    -- 冷却统一读取 KV，魔晶不再绕过手动施法冷却。
    ability:StartCooldown(cooldown)
end

-- 攻击命中回调（自动施法触发）
--[[
-- 旧版5技能被动：已由 modifier_suwako05_passive 接管，保留注释仅作对照
function Suwako05OnAttackLanded_Deprecated(keys)
    local caster = keys.attacker
    local target = keys.target
    if not caster or not target then return end

    local ability = caster:FindAbilityByName("ability_thdots_suwako05")
    if not ability then return end

    if ability:GetAutoCastState() and ability:IsCooldownReady() then
        local manaCost = ability:GetManaCost(ability:GetLevel() - 1)
        if caster:GetMana() >= manaCost then
            caster:SpendMana(manaCost, ability)
            -- 施放技能
            CastSuwako05AtLocation(caster, ability, target:GetOrigin())
            -- 处理冷却
            if not caster:HasModifier("modifier_item_aghanims_shard") then
                -- 无魔晶时，启动2.2秒冷却
                ability:StartCooldown(2.2)
            end
            -- 有魔晶时，不启动冷却（技能保持0冷却，自动施法无限制）
        end
    end
end

-- 定时检查自动施法状态和技能冷却，动态控制攻击距离加成
function Suwako05PassiveThink_Deprecated(keys)
    local caster = keys.caster
    local ability = keys.ability
    if not caster or not ability then return end

    local autoCast = ability:GetAutoCastState()
    local cooldownReady = ability:IsCooldownReady()   -- 技能冷却是否就绪（魔晶后始终为真）
    local rangeMod = caster:FindModifierByName("modifier_suwako05_attack_range_deprecated")

    if autoCast and cooldownReady then
        if not rangeMod then
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_suwako05_attack_range_deprecated", {})
        end
    else
        if rangeMod then
            rangeMod:Destroy()
        end
    end
end
]]




-- Aghanim技能：护盾（基于yorihime_03重构）
ability_thdots_suwako_aghs = class({})

LinkLuaModifier("modifier_suwako_aghs_shield", "scripts/vscripts/abilities/abilitysuwako.lua", LUA_MODIFIER_MOTION_NONE)

-- 动态魔法消耗（UI显示）
function ability_thdots_suwako_aghs:GetManaCost(level)
    local caster = self:GetCaster()
    if caster then
        return caster:GetMana() * self:GetSpecialValueFor("mana_cost") * 0.01
    end
    return 0
end

function ability_thdots_suwako_aghs:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if not target then return end

    -- 消耗当前50%魔法值
    local mana_cost = caster:GetMana() * 0.5
    --[[caster:SpendMana(mana_cost, self)--]]
	
	-- ========== 音效 ==========
    -- 施法者（suwako）播放音效（需替换为实际事件名）
	caster:EmitSound("suwako_innate_" .. math.random(1, 3))
    -- 施法目标播放美杜莎音效
    target:EmitSound("Hero_Medusa.ManaShield.On") 

    -- 计算护盾值
    local shield_base = self:GetSpecialValueFor("shield_base")
    local shield_factor = self:GetSpecialValueFor("shield_factor")
    local shield_value = shield_base + mana_cost * shield_factor
    local duration = self:GetSpecialValueFor("duration")

    -- 移除旧护盾（防止叠加）
    if target:HasModifier("modifier_suwako_aghs_shield") then
        target:RemoveModifierByName("modifier_suwako_aghs_shield")
    end

    -- 施加护盾修饰器
    target:AddNewModifier(caster, self, "modifier_suwako_aghs_shield", {
        duration = duration,
        shield = shield_value
    })

	-- -- 对目标造成1点纯粹伤害（触发效果但不致死）
    -- local damageTable = {
    --     victim = target,
    --     attacker = caster,
    --     damage = 1,
    --     damage_type = DAMAGE_TYPE_PURE,
    --     ability = self,
    --     damage_flags = DOTA_DAMAGE_FLAG_NONE
    -- }
    -- ApplyDamage(damageTable)
end

-- 护盾修饰器（完全基于yorihime_03的实现重构）
modifier_suwako_aghs_shield = {}

function modifier_suwako_aghs_shield:IsHidden() return false end
function modifier_suwako_aghs_shield:IsDebuff() return false end
function modifier_suwako_aghs_shield:IsPurgable() return false end
function modifier_suwako_aghs_shield:RemoveOnDeath() return true end

function modifier_suwako_aghs_shield:OnCreated(keys)
    if not IsServer() then return end
    local parent = self:GetParent()
    local caster = self:GetCaster()

    self.shieldRemaining = keys.shield

    -- 施加强驱散（移除负面状态、眩晕）
	parent:Purge(false, true, false, true, false)

	-- 护盾持续特效（美杜莎女儿珍藏版）—— 完全仿照 yorihime_03 的写法
    self.particle = ParticleManager:CreateParticle(
        "particles/econ/items/medusa/medusa_daughters/medusa_daughters_mana_shield.vpcf",
        PATTACH_ROOTBONE_FOLLOW,
        parent
    )
    -- 设置垂直偏移（负值向下，例如 -80 使特效围绕腰部）
    local offset = Vector(0, 0, -80)   -- 可根据实际效果调整数值
    -- 控制点0：特效主位置
    ParticleManager:SetParticleControlEnt(self.particle, 0, parent,
        PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin() + offset, true)
    -- 控制点1：通常用于特效朝向或次要位置，同样添加偏移
    ParticleManager:SetParticleControlEnt(self.particle, 1, parent,
        PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin() + offset, true)

    -- 在状态栏显示剩余护盾值（堆叠计数）
    self:SetStackCount(self.shieldRemaining)
end

function ApplyHealWithAmplification(target, healer, base_heal, ability)
    if not IsServer() then return end
    
    -- 获取目标身上的治疗增强修正值
    local heal_amp = 0
    
    -- 方法1：通过修饰器属性获取（如果使用标准修饰器属性）
    if target.GetHealAmplification then
        heal_amp = target:GetHealAmplification()
    end
    
    -- 方法2：手动检查常见治疗增强来源
    -- 核棒（nuclear_stick）
	if target:HasModifier("modifier_item_nuclear_stick_basic") then
		local modifiers = target:FindAllModifiersByName("modifier_item_nuclear_stick_basic")
		for _, mod in ipairs(modifiers) do
			-- 调用修饰器实现的函数获取治疗增强值
			local amp = mod:GetModifierHealAmplify_PercentageTarget() * 0.01 or 0
			heal_amp = heal_amp + amp
		end
	end
    
    -- 计算最终治疗量
    local final_heal = base_heal * (1 + heal_amp)
    
    -- 应用治疗
    target:Heal(final_heal, healer)
    
    -- 显示治疗数值
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, final_heal, nil)
    
    return final_heal
end


function modifier_suwako_aghs_shield:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    -- 护盾摧毁时播放音效（美杜莎音效）
    parent:EmitSound("Hero_Medusa.ManaShield.Off") 
	
    -- 再次强驱散
	parent:Purge(false, true, false, true, false)

	-- 添加驱散特效
	local dispelParticle = ParticleManager:CreateParticle(
		"particles/thd2/items/item_qijizhixing.vpcf", 
		PATTACH_ABSORIGIN_FOLLOW, 
		parent
	)
	-- 立即释放，让特效播放完自动销毁	
	ParticleManager:ReleaseParticleIndex(dispelParticle)

    -- 美杜莎护盾结束特效（一次性）
    local endParticle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_medusa/medusa_mana_shield_end.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )
    ParticleManager:ReleaseParticleIndex(endParticle)
	
    -- 手动销毁护盾持续特效
    if self.particle then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
	
    -- 剩余护盾转化为生命
    if self.shieldRemaining and self.shieldRemaining > 0 then
        local heal_percent = ability:GetSpecialValueFor("heal_percent") * 0.01
        local base_heal = self.shieldRemaining * heal_percent
        ApplyHealWithAmplification(parent, caster, base_heal, ability)
    end
	
end


function modifier_suwako_aghs_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,   -- 常量格挡（核心护盾机制）
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT, -- 客户端显示剩余值
	}
end

-- 护盾格挡逻辑（完全照搬yorihime_03的实现）
function modifier_suwako_aghs_shield:GetModifierTotal_ConstantBlock(keys)
	if not IsServer() then return 0 end
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then 
		return 0 
	end

	local damage = keys.damage
	if damage < self.shieldRemaining then
		-- 完全格挡本次伤害，剩余护盾减少
		self.shieldRemaining = self.shieldRemaining - damage
		self:SetStackCount(self.shieldRemaining)
		return damage

	else
		-- 护盾耗尽，格挡剩余部分并销毁
		local absorb = self.shieldRemaining
		self:Destroy()   -- 会触发OnDestroy
		return absorb
	end
end

-- 客户端显示剩余护盾值（与堆叠计数一致）
function modifier_suwako_aghs_shield:GetModifierIncomingDamageConstant(keys)
	if IsClient() then
		return self:GetStackCount()
	end
end
