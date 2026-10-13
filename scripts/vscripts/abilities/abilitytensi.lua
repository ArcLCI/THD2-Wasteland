if AbilityTensi == nil then
	AbilityTensi = class({})
end

ability_thdots_tensi02 = {}

function ability_thdots_tensi02:GetCooldown(level)
	local cooldown_reduction = self:GetCaster():GetCooldownReduction()
	local cooldown = self:GetSpecialValueFor("ability_multi") / self:GetCaster():GetStrength()
	return cooldown / cooldown_reduction
end

function ability_thdots_tensi02:GetIntrinsicModifierName() return "passive_tensi02_attack" end

passive_tensi02_attack = {}
LinkLuaModifier("passive_tensi02_attack","scripts/vscripts/abilities/abilityTensi.lua",LUA_MODIFIER_MOTION_NONE)
function passive_tensi02_attack:IsHidden() 			return true end
function passive_tensi02_attack:IsPurgable()		return false end
function passive_tensi02_attack:RemoveOnDeath() 	return false end
function passive_tensi02_attack:IsDebuff()			return false end

function passive_tensi02_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
function passive_tensi02_attack:OnAttackLanded(keys)
	local caster = self:GetCaster()
	local target = keys.target
	if caster ~= keys.attacker then return end

	local ability = self:GetAbility()
	local telent_chance = ability:GetSpecialValueFor("telent_chance")
	local should_attack = false
	local should_recool = false
	if telent_chance ~= 0 and RollPercentage(telent_chance) then
		should_attack = true
	elseif ability:IsCooldownReady() then
		should_attack = true
		should_recool = true
	end

	if should_attack == true then
		local telentdamage = FindTelentValue(caster,"special_bonus_unique_tensi_1") * caster:GetStrength()
		local damage = ability:GetSpecialValueFor("bouns_damage") + telentdamage
		local duration = ability:GetSpecialValueFor("stun_duration")
		local targets = FindUnitsInRadius(
			caster:GetTeam(),
			target:GetOrigin(),
			nil,
			ability:GetSpecialValueFor("stun_radius"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_OTHER,
			0,
			FIND_CLOSEST,
			false
		)
		if (#targets > 0) then
			for _,v in pairs(targets) do
				local damage_table = {
					ability = ability,
					victim = v,
					attacker = caster,
					damage = damage,
					damage_type = ability:GetAbilityDamageType(),
					damage_flags = 0
				}
				UtilStun:UnitStunTarget(caster,v,duration, ability, "tensi_attack_proc")
				UnitDamageTarget(damage_table)
			end

			if should_recool == true then
				ability:StartCooldown(ability:GetEffectiveCooldown(ability:GetLevel() - 1))
			end

			target:EmitSound("Hero_EarthShaker.Totem.Attack")

			local effectIndex = ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_fallback_low_egset.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
			ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
			ParticleManager:DestroyParticleSystem(effectIndex,false)
		end
	end
end

ability_thdots_tensi03 = ability_thdots_tensi03 or class({})

function ability_thdots_tensi03:GetIntrinsicModifierName()
	-- 3技能被动改为Lua实现，统一处理命中回复和万宝槌EX状态。
	return "passive_tensi03_attacked"
end

function ability_thdots_tensi03:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	-- 主动期间通过Lua modifier监听受伤叠加攻速。
	caster:AddNewModifier(caster, self, "active_tensi03_attacked", {duration = self:GetSpecialValueFor("duration")})
end

LinkLuaModifier("passive_tensi03_attacked","scripts/vscripts/abilities/abilityTensi.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("active_tensi03_attacked","scripts/vscripts/abilities/abilityTensi.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tensi03_bonus_attackspeed","scripts/vscripts/abilities/abilityTensi.lua",LUA_MODIFIER_MOTION_NONE)

passive_tensi03_attacked = passive_tensi03_attacked or class({})
function passive_tensi03_attacked:IsHidden() return true end
function passive_tensi03_attacked:IsPurgable() return false end
function passive_tensi03_attacked:IsDebuff() return false end
function passive_tensi03_attacked:RemoveOnDeath() return false end

function passive_tensi03_attacked:OnCreated()
	if not IsServer() then return end
	self.has_wanbaochui_ex = nil
	-- 保留1秒检查，但只在万宝槌状态变化时写EX技能等级。
	self:StartIntervalThink(1)
	self:OnIntervalThink()
end

function passive_tensi03_attacked:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function passive_tensi03_attacked:OnAttackLanded(keys)
	if not IsServer() then return end
	local caster = self:GetParent()
	-- 被动回复从被攻击改为攻击实际命中后触发。
	if keys.target ~= caster then return end
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 or caster:PassivesDisabled() then return end

	local bonus_health = ability:GetSpecialValueFor("bonus_health")
	caster:Heal(bonus_health, caster)
	caster:GiveMana(ability:GetSpecialValueFor("bonus_mana"))
	if caster:HasModifier("active_tensi03_attacked") then
		caster:Heal(bonus_health, caster)
	end
end

function passive_tensi03_attacked:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetParent()
	local abilityEx = caster:FindAbilityByName("ability_thdots_tensiex")
	if not abilityEx then return end

	local has_wanbaochui = caster:GetClassname() == "npc_dota_hero_earthshaker" and caster:HasModifier("modifier_item_wanbaochui")
	if self.has_wanbaochui_ex == has_wanbaochui then return end
	self.has_wanbaochui_ex = has_wanbaochui
	-- 只有状态切换时才SetLevel，避免每秒重复写技能等级。
	abilityEx:SetLevel(has_wanbaochui and 1 or 0)
end

active_tensi03_attacked = active_tensi03_attacked or class({})
function active_tensi03_attacked:IsPurgable() return true end
function active_tensi03_attacked:IsDebuff() return false end
function active_tensi03_attacked:GetEffectName() return "particles/units/heroes/hero_demonartist/demonartist_spiritwalk_buff_start_rope.vpcf" end
function active_tensi03_attacked:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function active_tensi03_attacked:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function active_tensi03_attacked:OnTakeDamage(keys)
	if not IsServer() then return end
	local caster = self:GetParent()
	if keys.unit ~= caster then return end

	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local max_stack_count = ability:GetSpecialValueFor("max_stack_count")
	local duration = ability:GetSpecialValueFor("duration")
	local modifier = caster:FindModifierByName("modifier_tensi03_bonus_attackspeed")
	local stack_count = 0
	if modifier then
		stack_count = modifier:GetStackCount()
	else
		modifier = caster:AddNewModifier(caster, ability, "modifier_tensi03_bonus_attackspeed", {duration = duration})
	end

	if not modifier then return end

	if stack_count < max_stack_count then
		stack_count = stack_count + 1
		modifier:SetStackCount(stack_count)
	end
	-- 受伤时仍刷新攻速buff持续时间，满层后不再重复写层数。
	modifier:SetDuration(duration, true)
end

modifier_tensi03_bonus_attackspeed = modifier_tensi03_bonus_attackspeed or class({})
function modifier_tensi03_bonus_attackspeed:IsHidden() return false end
function modifier_tensi03_bonus_attackspeed:IsPurgable() return true end
function modifier_tensi03_bonus_attackspeed:IsDebuff() return false end

function modifier_tensi03_bonus_attackspeed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_tensi03_bonus_attackspeed:GetModifierAttackSpeedBonus_Constant()
	local ability = self:GetAbility()
	if not ability then return 0 end
	return ability:GetSpecialValueFor("bonus_attackspeed") * self:GetStackCount()
end


function Tensiwanbaochuibuff(keys)
	local ability=keys.ability
	local caster=keys.caster
	local target=keys.target
	if is_spell_blocked(target,caster) then return end
	target:EmitSound("DOTA_Item.HeavensHalberd.Activate")
	if(caster:GetTeam() == keys.target:GetTeam())then
		keys.ability:ApplyDataDrivenModifier(caster, keys.target, "modifier_tensi_wanbaochui_buff", {})
		keys.ability:ApplyDataDrivenModifier(caster, keys.target, "modifier_tensi_wanbaochui_buff_2", {})
	else
		if is_spell_blocked(keys.target) then return end
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_tensi_wanbaochui_buff", {}) 
	end
end
