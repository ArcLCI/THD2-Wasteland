item_third_eyes = {}

function item_third_eyes:GetIntrinsicModifierName()
	return "modifier_item_third_eyes_passive"
end

modifier_item_third_eyes_passive = {}
LinkLuaModifier("modifier_item_third_eyes_passive","items/item_third_eyes.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_third_eyes_passive:IsHidden() return true end
function modifier_item_third_eyes_passive:IsPurgable() return false end
function modifier_item_third_eyes_passive:IsPurgeException() return false end
function modifier_item_third_eyes_passive:RemoveOnDeath() return false end
function modifier_item_third_eyes_passive:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_third_eyes_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_item_third_eyes_passive:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mgical_resistance")	
end

function modifier_item_third_eyes_passive:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end
function modifier_item_third_eyes_passive:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end
function modifier_item_third_eyes_passive:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end
function modifier_item_third_eyes_passive:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function item_third_eyes:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function item_third_eyes:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if is_spell_blocked(target,caster) then return end
	-- print("args")
	local duration = self:GetSpecialValueFor("duration")
	target:EmitSound("Item.GlimmerCape.Activate")
	-- caster:EmitSound("Hero_Bane.BrainSap")
	-- target:EmitSound("Hero_Bane.BrainSap.Target")
	target:AddNewModifier(caster,self,"modifier_item_third_eyes_debuff",{duration = duration})
	local sap_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bane/bane_sap.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(sap_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(sap_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(sap_particle)
	ParticleManager:DestroyParticleSystemTime(sap_particle,duration)
end

modifier_item_third_eyes_debuff = {}
LinkLuaModifier("modifier_item_third_eyes_debuff","items/item_third_eyes.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_third_eyes_debuff:IsHidden() 		return false end
function modifier_item_third_eyes_debuff:IsPurgable()		return true end
function modifier_item_third_eyes_debuff:RemoveOnDeath() 	return true end
function modifier_item_third_eyes_debuff:IsDebuff()		return true end

function modifier_item_third_eyes_debuff:GetEffectName()
	return "particles/econ/items/bane/bane_fall20_immortal/bane_fall20_immortal_grip_brain.vpcf"
	-- return "particles/econ/items/storm_spirit/storm_spirit_orchid_hat/stormspirit_orchid_head_ambient.vpcf"
end

function modifier_item_third_eyes_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_third_eyes_debuff:OnCreated()
	local ability = self:GetAbility()
	-- 物品可能在减益结束前被出售/移除，先缓存所有后续仍需使用的数值。
	if ability ~= nil and IsValidEntity(ability) then
		self.regen_reduce = ability:GetSpecialValueFor("regen_reduce")
	else
		self.regen_reduce = 0
	end
	if not IsServer() then return end
	if ability == nil or not IsValidEntity(ability) then
		self:Destroy()
		return
	end
	self.caster 						= self:GetCaster()
	self.ability						= ability
	self.damage							= ability:GetSpecialValueFor("damage")
	self.damage_flags					= ability:GetAbilityTargetFlags()
	self.duration						= ability:GetSpecialValueFor("duration")
	self.max_duration					= ability:GetSpecialValueFor("max_duration") - self.duration
	self:StartIntervalThink(1)
end

function modifier_item_third_eyes_debuff:OnIntervalThink()
	if not IsServer() then return end
	local damage = self.damage
	local ability = nil
	if self.ability ~= nil and IsValidEntity(self.ability) then
		ability = self.ability
	end
	local damage_tabel = {
				victim 			= self:GetParent(),
				damage 			= damage,
				damage_type		= DAMAGE_TYPE_PURE,
				damage_flags 	= self.damage_flags or 0,
				attacker 		= self.caster,
				ability 		= ability
			}
	-- print("damage count")
	local effectIndex = ParticleManager:CreateParticle("particles/econ/items/dazzle/dazzle_ti9/dazzle_shadow_wave_ti9_impact_damage.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	-- ParticleManager:SetParticleControl(effectIndex, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(effectIndex, 1, self:GetParent():GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(effectIndex)
	ParticleManager:DestroyParticleSystemTime(effectIndex,1)
	UnitDamageTarget(damage_tabel)
end


function modifier_item_third_eyes_debuff:DeclareFunctions()	
	return {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_item_third_eyes_debuff:OnTakeDamage(keys)
	if not IsServer() then return end
	if self:GetParent():IsNull() or keys.unit ~= self:GetParent() then return end
	if keys.attacker:GetTeam() == keys.unit:GetTeam() then return end
	if self.max_duration > 0 and keys.damage_type == 2 then
		-- print("keys.damage_type")
		-- print(keys.damage_type)
		-- print("self.max_duration")
		-- print(self.max_duration)
		self:SetDuration(self:GetRemainingTime() + 1, true)
		self.max_duration = self.max_duration - 1
	end
end

function modifier_item_third_eyes_debuff:GetModifierHealAmplify_PercentageTarget()
	return self.regen_reduce or 0
end

function modifier_item_third_eyes_debuff:GetModifierHPRegenAmplify_Percentage()
	return self.regen_reduce or 0
end

function modifier_item_third_eyes_debuff:OnTooltip()
	return self.regen_reduce or 0
end
