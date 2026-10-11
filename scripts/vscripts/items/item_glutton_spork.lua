item_glutton_spork = {}

function item_glutton_spork:GetIntrinsicModifierName()
    return "modifier_item_glutton_spork_passive"
end

modifier_item_glutton_spork_passive = {}
LinkLuaModifier("modifier_item_glutton_spork_passive","items/item_glutton_spork.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_glutton_spork_passive:IsHidden() return true end
function modifier_item_glutton_spork_passive:IsDebuff() return false end
function modifier_item_glutton_spork_passive:IsPurgable() return false end
function modifier_item_glutton_spork_passive:IsPurgeException() return false end
function modifier_item_glutton_spork_passive:RemoveOnDeath() return false end

function modifier_item_glutton_spork_passive:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS_UNIQUE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_glutton_spork_passive:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE -- 允许多个相同修饰器共存
end

function modifier_item_glutton_spork_passive:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_glutton_spork_passive:GetModifierBonusStats_Agility() return self:GetAbility():GetSpecialValueFor("bonus_agility") end
function modifier_item_glutton_spork_passive:GetModifierAttackRangeBonusUnique()
    local ability = self:GetAbility()
    if ability == nil or ability:IsNull() then return 0 end
    -- 装备被动射程只取最大值；不再用其他物品的存在与否决定优先级。
    return ability:GetSpecialValueFor("bonus_attack_range")
end
function modifier_item_glutton_spork_passive:GetModifierHPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_hp_regen_amplify_percentage") end
function modifier_item_glutton_spork_passive:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
function modifier_item_glutton_spork_passive:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_move_speed") end
function modifier_item_glutton_spork_passive:OnCreated()
    if not IsServer() then return end
end

-- 新增吸血效果实现 --
function modifier_item_glutton_spork_passive:OnAttackLanded(params)
    if not IsServer() then return end
    
    local attacker = params.attacker
    local target = params.target
    
    -- 确保是装备持有者发起的攻击
    if attacker ~= self:GetParent() then return end
    
    -- 获取装备和配置值
    local ability = self:GetAbility()
    local lifesteal_percent = ability:GetSpecialValueFor("lifesteal_percent")
    local exclude_buildings = ability:GetSpecialValueFor("lifesteal_exclude_building") == 1
    
    -- 排除无效目标
    if not target or target:IsNull() then return end
    if exclude_buildings and target:IsBuilding() then return end
    
    -- 计算基础吸血量
    local lifesteal_amount = target:GetMaxHealth() * lifesteal_percent / 100
    
    -- 应用吸血效果
    attacker:Heal(lifesteal_amount, ability)
    
    -- 显示吸血特效
    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end
