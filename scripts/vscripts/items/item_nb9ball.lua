item_nb9ball = {}

function item_nb9ball:GetCastRange()
    -- 服务端保留原有任意点施法，再由 OnSpellStart 截断距离；UI 查询须独立取得施法者。
    if not IsClient() then return 99999 end
    local base_range = self:GetSpecialValueFor("AbilityCastRange")
    local caster = self:GetCaster()
    if caster == nil or caster:IsNull() then
        return base_range
    end
    return base_range + caster:GetCastRangeBonus()
end

function item_nb9ball:GetIntrinsicModifierName()
    return "modifier_item_nb9ball_basic"
end

function item_nb9ball:OnSpellStart()
    local caster = self:GetCaster()
    local caster_absorigin = caster:GetAbsOrigin()
    local base_range = self:GetSpecialValueFor("AbilityCastRange")
    local bonus_range = caster:GetCastRangeBonus()  -- 获取英雄的施法距离加成

    local particle = ParticleManager:CreateParticle(
        "particles/econ/events/fall_2021/blink_dagger_fall_2021_start_lvl2.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, caster_absorigin)
    ParticleManager:ReleaseParticleIndex(particle)

    if IsClient() then return end
    EmitSoundOnLocationWithCaster(caster_absorigin, "Hero_Antimage.Blink_out", caster)
    local point = self:GetCursorPosition()
    local cast_range = base_range + bonus_range

    local distance = (caster_absorigin - point):Length2D()

    local final_point

    if distance < cast_range then
        final_point = point
    else
        final_point = caster_absorigin + (point - caster_absorigin):Normalized() * cast_range
    end

    local modifier_duration = self:GetSpecialValueFor("modifier_duration")
    FindClearSpaceForUnit(caster, final_point, true)
    ProjectileManager:ProjectileDodge(caster)
    caster:AddNewModifier(caster, self, "modifier_item_nb9ball", { duration = modifier_duration })
end

modifier_item_nb9ball = {}
LinkLuaModifier("modifier_item_nb9ball", "items/item_nb9ball.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_nb9ball:IsHidden()
    return false
end

function modifier_item_nb9ball:RemoveOnDeath()
    return true
end

function modifier_item_nb9ball:IsPurgable()
    return true
end

function modifier_item_nb9ball:IsDebuff()
    return false
end

function modifier_item_nb9ball:OnCreated()
    local caster = self:GetCaster()
    local caster_absorigin = caster:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle(
        "particles/econ/events/fall_2021/blink_dagger_fall_2021_end_lvl2.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, caster_absorigin)
    ParticleManager:ReleaseParticleIndex(particle)
    if IsClient() then return end
    EmitSoundOnLocationWithCaster(caster_absorigin, "Hero_Antimage.Blink_in", caster)
end

function modifier_item_nb9ball:OnRefresh()
    local caster = self:GetCaster()
    local caster_absorigin = caster:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle(
        "particles/econ/events/fall_2021/blink_dagger_fall_2021_end_lvl2.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, caster_absorigin)
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_item_nb9ball:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_item_nb9ball:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("modifier_attack_speed")
end

function modifier_item_nb9ball:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("modifier_movespeed_percent")
end

modifier_item_nb9ball_basic = {}
LinkLuaModifier("modifier_item_nb9ball_basic", "items/item_nb9ball.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_nb9ball_basic:IsHidden()
    return true
end

function modifier_item_nb9ball_basic:RemoveOnDeath()
    return false
end

function modifier_item_nb9ball_basic:IsPurgable()
    return false
end

function modifier_item_nb9ball_basic:IsDebuff()
    return false
end

function modifier_item_nb9ball_basic:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_nb9ball_basic:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
    }
end

function modifier_item_nb9ball_basic:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage")
end

function modifier_item_nb9ball_basic:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_item_nb9ball_basic:GetModifierMoveSpeedBonus_Constant_Unique()
    return self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_item_nb9ball_basic:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("all_stats")
end

function modifier_item_nb9ball_basic:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("all_stats")
end

function modifier_item_nb9ball_basic:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("all_stats")
end

function modifier_item_nb9ball_basic:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("health")
end

function modifier_item_nb9ball_basic:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("mana")
end
