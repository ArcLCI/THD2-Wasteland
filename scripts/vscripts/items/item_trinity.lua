item_trinity = {}

function item_trinity:GetIntrinsicModifierName()
    return "modifier_item_trinity_passive"
end

modifier_item_trinity_passive = {}
LinkLuaModifier("modifier_item_trinity_passive","items/item_trinity.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_trinity_passive:IsHidden() return true end
function modifier_item_trinity_passive:IsDebuff() return false end
function modifier_item_trinity_passive:IsPurgable() return false end
function modifier_item_trinity_passive:IsPurgeException() return false end
function modifier_item_trinity_passive:RemoveOnDeath() return false end

function modifier_item_trinity_passive:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_trinity_passive:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE -- 允许多个相同修饰器共存
end

function modifier_item_trinity_passive:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_trinity_passive:GetModifierBonusStats_Agility() return self:GetAbility():GetSpecialValueFor("bonus_agility") end
function modifier_item_trinity_passive:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_trinity_passive:GetModifierAttackRangeBonus() 
    local ability = self:GetAbility()
    if ability == nil or ability:IsNull() then
        return 0
    end

    -- 按来源物品实体判定首件，避免将查询返回的 modifier 句柄与 Lua self 直接比较。
    -- 多件仍只提供一次射程；首件移除后，由查询返回的剩余被动接替。
    local firstModifier = self:GetParent():FindModifierByName("modifier_item_trinity_passive")
    if firstModifier == nil or firstModifier:IsNull() then
        return 0
    end
    local firstAbility = firstModifier:GetAbility()
    if firstAbility == nil or firstAbility:IsNull() or firstAbility:entindex() ~= ability:entindex() then
        return 0
    end

    local caster = self:GetCaster()
    local bonus_range = ability:GetSpecialValueFor("bonus_attack_range")
    
    -- 检查道具互斥
    local hasModifier1 = caster:HasModifier("modifier_item_yuemianjidongzhuangzhi_range")
    local hasModifier2 = caster:HasModifier("modifier_item_yuemianzhinu_range")
    local hasModifier3 = caster:HasModifier("modifier_item_kafziel_attack_range_bonus")
    
    -- 无冲突道具时生效
    if not (hasModifier1 or hasModifier2 or hasModifier3) then
        return bonus_range
    end
    return 0
end
function modifier_item_trinity_passive:GetModifierHPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_hp_regen_amplify_percentage") end
function modifier_item_trinity_passive:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
function modifier_item_trinity_passive:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_move_speed") end
function modifier_item_trinity_passive:GetModifierSpellAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_spell_amplify_percentage") end
function modifier_item_trinity_passive:GetModifierMPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_mp_regen_amplify_percentage") end
function modifier_item_trinity_passive:GetModifierPercentageCasttime() return self:GetAbility():GetSpecialValueFor("bonus_cast_speed") end

function modifier_item_trinity_passive:OnCreated()
    if not IsServer() then return end
end

-- 新增吸血效果实现 --
function modifier_item_trinity_passive:OnAttackLanded(params)
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

function item_trinity:OnSpellStart()
    local caster = self:GetCaster()
    local shield_value = self:GetSpecialValueFor("active_shield_value")
    local shield_duration = self:GetSpecialValueFor("active_shield_duration")
    
    -- 创建护盾效果
    caster:AddNewModifier(
        caster,
        self,
        "modifier_item_trinity_active_shield",
        {
            duration = shield_duration,
            shield_amount = shield_value
        }
    )
    
    -- 视觉特效
    ParticleManager:CreateParticle(
        "particles/items/trinity_shield.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )
    EmitSoundOn("DOTA_Item.Pipe.Activate", caster)
end

-- 修复后的护盾效果修饰器
modifier_item_trinity_active_shield = {}
LinkLuaModifier("modifier_item_trinity_active_shield", "items/item_trinity.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_trinity_active_shield:IsHidden() return false end
function modifier_item_trinity_active_shield:IsDebuff() return false end
function modifier_item_trinity_active_shield:IsPurgable() return true end
function modifier_item_trinity_active_shield:RemoveOnDeath() return true end

function modifier_item_trinity_active_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,  -- 关键：客户端护盾显示
        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,      -- 关键：服务器端伤害吸收
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING -- 防止控制穿透
    }
end

function modifier_item_trinity_active_shield:OnCreated(params)
    if IsServer() then
        self.shield_remaining = params.shield_amount
        self:SetStackCount(self.shield_remaining)
        
        -- 创建护盾特效（使用Dota标准护盾特效）
        self.particle = ParticleManager:CreateParticle(
            "particles/items3_fx/lotus_orb_shield.vpcf", -- 标准莲花护盾特效
            PATTACH_POINT_FOLLOW,
            self:GetParent()
        )
        ParticleManager:SetParticleControlEnt(
            self.particle, 
            0, 
            self:GetParent(), 
            PATTACH_POINT_FOLLOW, 
            "attach_hitloc", 
            self:GetParent():GetAbsOrigin(), 
            true
        )
        self:AddParticle(self.particle, false, false, -1, false, false)
    end
end

-- 关键：客户端护盾显示函数
function modifier_item_trinity_active_shield:GetModifierIncomingDamageConstant()
    if IsClient() then
        return self:GetStackCount() -- 客户端直接返回堆栈值用于UI显示
    end
    return 0
end

-- 关键：服务器端伤害吸收逻辑
function modifier_item_trinity_active_shield:GetModifierTotal_ConstantBlock(params)
    if not IsServer() then return 0 end
    
    -- 排除生命损失类伤害
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
        return 0
    end
    
    local damage = params.damage
    local absorb_amount = math.min(self.shield_remaining, damage)
    
    -- 更新护盾值
    self.shield_remaining = self.shield_remaining - absorb_amount
    self:SetStackCount(self.shield_remaining)
    
    -- 伤害吸收特效
    if absorb_amount > 0 then
        ParticleManager:CreateParticle(
            "particles/items3_fx/lotus_orb_shield_hit.vpcf", -- 标准护盾击中特效
            PATTACH_ABSORIGIN,
            self:GetParent()
        )
        
        -- 显示吸收数值
        SendOverheadEventMessage(
            nil,
            OVERHEAD_ALERT_BLOCK,
            self:GetParent(),
            absorb_amount,
            nil
        )
    end
    
    -- 护盾耗尽时移除
    if self.shield_remaining <= 0 then
        self:Destroy()
    end
    
    return absorb_amount
end

function modifier_item_trinity_active_shield:GetModifierStatusResistanceStacking()
    return self:GetAbility():GetSpecialValueFor("bonus_status_resistance_stacking") -- 100%状态抗性
end

function modifier_item_trinity_active_shield:OnDestroy()
    if IsServer() then
        -- 播放护盾破碎特效
        ParticleManager:CreateParticle(
            "particles/items3_fx/lotus_orb_destroy.vpcf", -- 标准护盾破碎特效
            PATTACH_ABSORIGIN,
            self:GetParent()
        )
        EmitSoundOn("DOTA_Item.LotusOrb.Target", self:GetParent())
    end
end
