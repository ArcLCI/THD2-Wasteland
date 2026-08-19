item_feixiangjian = {}

function item_feixiangjian:GetIntrinsicModifierName()
	return "modifier_item_feixiangjian_passive"
end

modifier_item_feixiangjian_passive = {}
LinkLuaModifier("modifier_item_feixiangjian_passive","items/item_feixiangjian.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_feixiangjian_passive:IsHidden() return true end
function modifier_item_feixiangjian_passive:IsPurgable() return false end
function modifier_item_feixiangjian_passive:IsPurgeException() return false end
function modifier_item_feixiangjian_passive:RemoveOnDeath() return false end
function modifier_item_feixiangjian_passive:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_feixiangjian_passive:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_item_feixiangjian_passive:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_feixiangjian_passive:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")	
end

function modifier_item_feixiangjian_passive:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_feixiangjian_passive:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	if not self.caster:HasModifier("modifier_item_feixiangjian_lightning") then
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_item_feixiangjian_lightning", {})
	end
end

function modifier_item_feixiangjian_passive:OnDestroy()
	if not IsServer() then return end

	if self.caster == nil or self.caster:IsNull() then return end
	if self.caster:HasModifier("modifier_item_feixiangjian_lightning") then
		self.caster:RemoveModifierByName("modifier_item_feixiangjian_lightning")
	end
end

modifier_item_feixiangjian_lightning = {}
LinkLuaModifier("modifier_item_feixiangjian_lightning","items/item_feixiangjian.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_feixiangjian_lightning:IsHidden() return false end
function modifier_item_feixiangjian_lightning:IsPurgable() return false end
function modifier_item_feixiangjian_lightning:IsPurgeException() return false end
function modifier_item_feixiangjian_lightning:RemoveOnDeath() return false end

function modifier_item_feixiangjian_lightning:Init()
	if self.inited ~= nil and self.inited == true then return end
	self.inited = true

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.chance = self.ability:GetSpecialValueFor("chance")
	self.lockRange = self.ability:GetSpecialValueFor("lock_range")
	self.maxTarget = self.ability:GetSpecialValueFor("max_target")
	self.lightningDamage = self.ability:GetSpecialValueFor("lightning_damage")
	self.debuffDuration = self.ability:GetSpecialValueFor("debuff_duration")
end

function modifier_item_feixiangjian_lightning:OnCreated()
	if not IsServer() then return end

	self:Init()
end

function modifier_item_feixiangjian_lightning:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_item_feixiangjian_lightning:OnAttackLanded(event)
	if not IsServer() then return end

	if self:GetCaster() ~= event.attacker then return end
	if self:GetCaster():IsNull() or not self:GetCaster():IsRealHero() then return end

	self:Init()

	if RandomInt(1, 100) > self.chance then return end

	-- 闪电索敌的上一个实体
	local preTarget = self.caster
	local target = event.target
	local damagedTarget = {}
	for i = 1, self.maxTarget do
		-- 结算当前目标
		if target == nil then break end
		table.insert(damagedTarget, target)

		-- 计算当前目标伤害
		local damage = self.lightningDamage
		local damageTable = {
			ability = self.ability,
			victim = target,
			attacker = self.caster,
			damage = damage,
			damage_type = self.ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		UnitDamageTarget(damageTable)

        target:AddNewModifier(
            self.caster,
            self.ability,
            "modifier_item_feixiangjian_disable",
            {duration = self.debuffDuration}
        )

		--创建音效
		EmitSoundOn("Hero_Zuus.ArcLightning.Cast", self.caster)
		--创建特效
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning_head.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, preTarget)
		if preTarget == self.caster then
			ParticleManager:SetParticleControlEnt(particle, 0, self.caster, 5, "attach_attack1", Vector(0, 0, 0), true)
		else
			ParticleManager:SetParticleControlEnt(particle, 0, preTarget, 5, "attach_hitloc", Vector(0, 0, 0), true)
		end
		ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() + Vector(0, 0, 150))
		ParticleManager:ReleaseParticleIndex(particle)
		ParticleManager:DestroyParticleSystemTime(particle, 2)

		-- 搜索下一个目标
		if i + 1 > self.maxTarget then break end
		local function FindNextTarget()
			local targets = FindUnitsInRadius(
				self.caster:GetTeamNumber(),
				target:GetOrigin(),
				nil,
				self.lockRange,
				self.ability:GetAbilityTargetTeam(),
				self.ability:GetAbilityTargetType(),
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_ANY_ORDER,
				false
			)
			for i = 1, #targets do
				local damaged = false
				for j = 1, #damagedTarget do
					if damagedTarget[j] ~= nil and not damagedTarget[j]:IsNull() and targets[i] == damagedTarget[j] then
						damaged = true
						break
					end
				end
				if damaged == false then
					return targets[i]
				end
			end
			return nil
		end
		preTarget = target
		target = FindNextTarget()
	end
end

modifier_item_feixiangjian_disable = {}
LinkLuaModifier("modifier_item_feixiangjian_disable", "items/item_feixiangjian.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_feixiangjian_disable:IsDebuff() return true end
function modifier_item_feixiangjian_disable:IsPurgable() return true end

function modifier_item_feixiangjian_disable:OnCreated()
    self.ability = self:GetAbility()
    if not IsServer() then return end
    
    -- 创建残废特效
    self.particle = ParticleManager:CreateParticle(
        "particles/items2_fx/sange_maim.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        self:GetParent()
    )
    ParticleManager:SetParticleControlEnt(self.particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
end

function modifier_item_feixiangjian_disable:OnDestroy()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
end

function modifier_item_feixiangjian_disable:DeclareFunctions()
    return {
        -- MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

-- function modifier_item_feixiangjian_disable:GetModifierAttackSpeedBonus_Constant()
--     return self.ability:GetSpecialValueFor("maim_attack_speed")
-- end

function modifier_item_feixiangjian_disable:GetModifierMoveSpeedBonus_Percentage()
    local ability = self.ability or self:GetAbility()
    if ability == nil then return 0 end
    return ability:GetSpecialValueFor("maim_movement_speed")
end
