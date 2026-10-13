item_yuetufensuijvren={}
function item_yuetufensuijvren:GetIntrinsicModifierName()
	return "modifier_item_yuetufensuijvren"
end

modifier_item_yuetufensuijvren={}
LinkLuaModifier("modifier_item_yuetufensuijvren","items/item_yuetufensuijvren.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_yuetufensuijvren:IsHidden() return true end
function modifier_item_yuetufensuijvren:IsPurgable() return false end
function modifier_item_yuetufensuijvren:IsPurgeException() return false end
function modifier_item_yuetufensuijvren:RemoveOnDeath() return false end
function modifier_item_yuetufensuijvren:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_yuetufensuijvren:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end
function modifier_item_yuetufensuijvren:CheckState()
	if self.pierce == 1 then
		return {
			[MODIFIER_STATE_CANNOT_MISS] 	= true,
		}
	else
		return
	end
end

function modifier_item_yuetufensuijvren:OnAttackStart(keys)
	--print("11111")
	if keys.attacker == self:GetParent() and not keys.attacker:HasModifier("modifier_item_yuetufensuijvren_cooldown") then
		if RollPseudoRandom(self.chance,self)then
			self.pierce = true
		end
	end
end
function modifier_item_yuetufensuijvren:GetModifierHealthBonus() return self:GetAbility():GetSpecialValueFor("bonus_health") end
function modifier_item_yuetufensuijvren:GetModifierConstantHealthRegen() return self:GetAbility():GetSpecialValueFor("bonus_health_regen") end
function modifier_item_yuetufensuijvren:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
function modifier_item_yuetufensuijvren:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_yuetufensuijvren:GetModifierPhysical_ConstantBlock(events)--被攻击时触发
    if IsClient() then return end
	if RollPercentage(self.block_chance) then
        if events.damage * self.block_percent <= self.block_damage_melee then return events.damage * self.block_percent end
		if not self:GetParent():IsRangedAttacker() then
			return self.block_damage_melee
		else
			return self.block_damage_ranged
		end
	end
end
function modifier_item_yuetufensuijvren:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() or keys.target:IsBuilding() or keys.attacker:IsIllusion() then return end
	if 	self.pierce == true then
		ApplyDamage({
			victim 			= keys.target,
			damage 			= self.damage,
			damage_type		= DAMAGE_TYPE_MAGICAL,
			damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
			attacker 		= keys.attacker,
			ability 		= self.ability
		})
        UtilStun:UnitStunTarget(keys.attacker, keys.target, self.duration, self.ability, 'item_attack_proc')
        keys.attacker:AddNewModifier(keys.attacker,self.ability, "modifier_item_yuetufensuijvren_cooldown", {duration=self.cooldown})
		--print("yes")
	end
	self.pierce = false
end
function modifier_item_yuetufensuijvren:OnCreated()
    if not IsServer() then return end
    self.ability = self:GetAbility()

    self.block_chance = self.ability:GetSpecialValueFor("chance")
    self.block_damage_melee = self.ability:GetSpecialValueFor("block")
    self.block_damage_ranged = self.ability:GetSpecialValueFor("block")
    self.block_percent = self.ability:GetSpecialValueFor("percent")/100
    self.duration = self.ability:GetSpecialValueFor("stun_duration")
    self.cooldown = self.ability:GetSpecialValueFor("cooldown")
    self.damage = self.ability:GetSpecialValueFor("stun_damage")
    self.caster = self:GetParent()
    if self.caster:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK then
        self.chance = self.ability:GetSpecialValueFor("stun_chance_ranged")
    elseif self.caster:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK then
        self.chance  = self.ability:GetSpecialValueFor("stun_chance_melee")
    end
    if not self.caster:IsOwnedByAnyPlayer() then
        self.chance = self.chance/5
    end
end
modifier_item_yuetufensuijvren_cooldown={}
LinkLuaModifier("modifier_item_yuetufensuijvren_cooldown","items/item_yuetufensuijvren.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_yuetufensuijvren_cooldown:IsHidden() return false end
function modifier_item_yuetufensuijvren_cooldown:IsPurgable() return false end
function modifier_item_yuetufensuijvren_cooldown:RemoveOnDeath() return true end

function item_yuetufensuijvren:OnSpellStart()
    if not IsServer() then return end
    --基础信息
    local caster=self:GetCaster()
    local target=self:GetCursorTarget()
    if is_spell_blocked(target,caster) then return end
    local buff_duration=self:GetSpecialValueFor("default_buff_duration")
    --对自己使用判定
    self.cast_self=false
    --消除音效保存
    self.owner=caster

    --确保刷新技能不影响特效
    if caster:HasModifier("modifier_item_yuetufensuijvren_buff") then
        caster:RemoveModifierByName("modifier_item_yuetufensuijvren_buff")
    end

    caster:AddNewModifier(caster,self,"modifier_item_yuetufensuijvren_buff",{duration=buff_duration})
    caster:MoveToTargetToAttack(target)
    target:AddNewModifier(caster, self, "modifier_mark_target_yuetufensuijvren", {duration = buff_duration})

    local particle="particles/econ/items/windrunner/windrunner_cape_sparrowhawk/windrunner_windrun_sparrowhawk.vpcf"
    self.particle = ParticleManager:CreateParticle(particle, PATTACH_ROOTBONE_FOLLOW, caster)

    EmitSoundOn("Ability.Windrun",caster)
    
end

--技能1 modifiers

--modifier 名字：标记敌人

modifier_mark_target_yuetufensuijvren=class({})
LinkLuaModifier("modifier_mark_target_yuetufensuijvren","items/item_yuetufensuijvren.lua",LUA_MODIFIER_MOTION_NONE)

--modifier 基础判定
function modifier_mark_target_yuetufensuijvren:IsHidden()        return false end
function modifier_mark_target_yuetufensuijvren:IsPurgable()      return false end
function modifier_mark_target_yuetufensuijvren:RemoveOnDeath()   return true end
function modifier_mark_target_yuetufensuijvren:IsDebuff()        return true end

--modifier 修改列表
function modifier_mark_target_yuetufensuijvren:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end
--modifier 触发事件
function modifier_mark_target_yuetufensuijvren:OnAttackLanded(keys)
    if not IsServer() then return end
    local caster = self:GetCaster()
    local target = keys.target
    --如果攻击者是自己
    if  keys.attacker==caster then
        local hability = self:GetAbility()
        caster:RemoveModifierByName("modifier_item_yuetufensuijvren_buff")
        target:RemoveModifierByName("modifier_mark_target_yuetufensuijvren")
        --伤害
        local damage_table=
        {
            victim=target,
            attacker=caster,
            damage          = hability:GetSpecialValueFor("stun_damage"),
            damage_type     = hability:GetAbilityDamageType(),
            damage_flags    = hability:GetAbilityTargetFlags(),
            ability         = hability
        }
        EmitSoundOn("DOTA_Item.AbyssalBlade.Activate", target)
        UnitDamageTarget(damage_table)
        UtilStun:UnitStunTarget(keys.attacker, target, hability:GetSpecialValueFor("default_stun_duration"), hability, 'item_active_attack_confirm')
        local particle_abyssal_fx = ParticleManager:CreateParticle("particles/items_fx/abyssal_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(particle_abyssal_fx, 0, target:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle_abyssal_fx)
        self:Destroy()
    end
end


--modifier 名字: 英雄buff 加速
modifier_item_yuetufensuijvren_buff=class({})
LinkLuaModifier("modifier_item_yuetufensuijvren_buff","items/item_yuetufensuijvren.lua",LUA_MODIFIER_MOTION_NONE)

--modifier 基础判定
function modifier_item_yuetufensuijvren_buff:IsHidden()         return false end
function modifier_item_yuetufensuijvren_buff:IsPurgable()       return false end
function modifier_item_yuetufensuijvren_buff:RemoveOnDeath()    return true end
function modifier_item_yuetufensuijvren_buff:IsDebuff()     return false end

--modifier 修改列表
function modifier_item_yuetufensuijvren_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
        MODIFIER_EVENT_ON_ORDER,
    }
    return funcs
end

--提供相位
function modifier_item_yuetufensuijvren_buff:CheckState()
    local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
    return state
end
--状态抗性
function modifier_item_yuetufensuijvren_buff:GetModifierStatusResistanceStacking() 
    return self:GetAbility():GetSpecialValueFor("status_resist")
end

--modifier 修改函数
function modifier_item_yuetufensuijvren_buff:GetModifierMoveSpeed_Absolute()
    --if not IsServer() then return end
    return self:GetAbility():GetSpecialValueFor("speed")
end

--modifier 触发事件：任何命令
function modifier_item_yuetufensuijvren_buff:OnOrder(keys)
    if not IsServer() then return end
    local caster=self:GetParent()
    if keys.unit==caster then 
        --消除加速buff
        if caster:HasModifier("modifier_item_yuetufensuijvren_buff") and self:GetAbility().cast_self==false then
            --caster:RemoveModifierByName("modifier_bloodseeker_thirst")
            caster:RemoveModifierByName("modifier_item_yuetufensuijvren_buff")
        end
         self:GetAbility().cast_self=nil
    end
end

--modifier 消失事件
function modifier_item_yuetufensuijvren_buff:OnDestroy()
    if not IsServer() then return end
    local ability=self:GetAbility()

    --删除特效，停止音效
    ParticleManager:DestroyParticleSystem(ability.particle, true)
    StopSoundOn("Ability.Windrun",ability.owner)
end
