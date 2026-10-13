ability_thdots_byakuren01 = class ({})  

function ability_thdots_byakuren01:OnSpellStart()
	if not IsServer() then return end
	self.caster				= self:GetCaster()
	self.ability          = self
	self.target           = self:GetCursorTarget()
	self.cast_range 	= self:GetSpecialValueFor("cast_range") + self.caster:GetCastRangeBonus()
	self.point = self:GetCursorPosition()
	self.caster:RemoveModifierByName("modifier_byakuren03_byakuren01_cast_range_bonus")
	if is_spell_blocked(self.target) then return end
	if self.cast_range_bonus == nil then self.cast_range_bonus = false end

	if self.cast_range_bonus == true then
		local vector_distance = self.caster:GetAbsOrigin() - self.target:GetAbsOrigin()
		local direction = (vector_distance):Normalized()
		local distance = (vector_distance):Length2D()
		if distance > 190 then 
			local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_void_hit.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
			ParticleManager:SetParticleControl(effectIndex, 0, self.caster:GetAbsOrigin())
			--ParticleManager:DestroyParticleSystem(effectIndex,false)
			FindClearSpaceForUnit(self.caster, self.target:GetAbsOrigin() + direction * 190, true)
			ResolveNPCPositions(self.caster:GetAbsOrigin(), 128)
		end
		self.cast_range_bonus = false
	end	
	OnByakuren01SpellStart(self)
end

function OnByakuren01SpellStart(keys)	
	local ability = keys.ability
	local caster = keys.caster 
	local vecCaster = caster:GetOrigin()
	local target = keys.target
	local dealdamage = keys.ability:GetSpecialValueFor("damage") - ability:GetSpecialValueFor("aoe_damage")

	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_aphotic_shield_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex, 0, keys.target:GetOrigin())
	ParticleManager:SetParticleControl(effectIndex, 5, keys.target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	caster:EmitSound("Hero_Luna.LucentBeam.Target")

	local damage_target = {
		victim = keys.target,
		attacker = caster,
		damage = dealdamage,
		damage_type = keys.ability:GetAbilityDamageType(), 
		damage_flags = 0
	}
	local targets = FindUnitsInRadius(
						caster:GetTeam(),		
						target:GetOrigin(),	
						nil,					
						ability:GetSpecialValueFor("radius"),		
						DOTA_UNIT_TARGET_TEAM_ENEMY,
						keys.ability:GetAbilityTargetType(),
						0,
						FIND_CLOSEST,
						false
					)
	UnitDamageTarget(damage_target)
	for _,v in pairs(targets) do
		if v and not v:IsNull() then
			local damage_table = {
					ability = keys.ability,
						victim = v,
						attacker = caster,
						damage = ability:GetSpecialValueFor("aoe_damage"),
						damage_type = keys.ability:GetAbilityDamageType(), 
						damage_flags = 0
			}
			UtilStun:UnitStunTarget(caster,v,ability:GetSpecialValueFor("stun_duration"), (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilitybyakuren.lua:OnByakuren01SpellStart:72")
			UnitDamageTarget(damage_table)
		end
	end
end

function ability_thdots_byakuren01:GetCastRange()
	if self.cast_range_bonus == true then
		local ByakurenAbility03 = self:GetCaster():FindAbilityByName("ability_thdots_byakuren03")
		local cast_range_bonus = ByakurenAbility03:GetSpecialValueFor("cast_range")		
		return self:GetSpecialValueFor("cast_range") + cast_range_bonus
	else
		return self:GetSpecialValueFor("cast_range")
	end
end

function ability_thdots_byakuren01:GetBehavior()
	self.caster = self:GetCaster()
	if self.cast_range_bonus == true then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	else
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end
end

ability_thdots_byakuren02 = class ({})  

function ability_thdots_byakuren02:GetAOERadius()
	if ( self:GetCaster():HasScepter() ) then
		return self:GetSpecialValueFor( "wanbaochui_radius" )
	end
	return 0
end


--function ability_thdots_youmu04:GetCooldown( nLevel )
--	local ability = self:GetCaster():FindAbilityByName("special_bonus_unique_juggernaut")
--	local telent_val = 0
    --if ability~=nil then
    --    telent_val = ability:GetSpecialValueFor("value")
    --end
--	return self.BaseClass.GetCooldown( self, nLevel ) + telent_val -- + FindTelentValue(self:GetCaster(),"special_bonus_unique_juggernaut")
--end

function ability_thdots_byakuren02:GetManaCost()
	return self:GetCaster():GetMana() * self:GetSpecialValueFor("mana_cost") / 100
end

function ability_thdots_byakuren02:OnSpellStart()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.ability          = self
	self.target           = self:GetCursorTarget()
	self.AbilityMulti     = self:GetSpecialValueFor("ability_multi")
	self.WanbaochuiRadius = self:GetSpecialValueFor("wanbaochui_radius")
	self.caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	OnByakuren02SpellStart(self)
end

function OnByakuren02SpellStart(keys)
	if is_spell_blocked(keys.target) then return end
	local caster = keys.caster
	local vecCaster = caster:GetOrigin()
	local target = keys.target
	local dealdamage = keys.AbilityMulti * caster:GetMaxMana() --伤害为伤害系数*最大法力值

	local effectIndex = ParticleManager:CreateParticle("particles/heroes/byakuren/ability_byakuren_02.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
	ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
	ParticleManager:SetParticleControl(effectIndex, 2, target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	ParticleManager:ReleaseParticleIndex(effectIndex)

	if caster:HasModifier("modifier_item_wanbaochui") then
		local targets = FindUnitsInRadius(
						caster:GetTeam(),		
						target:GetOrigin(),	
						nil,					
						keys.WanbaochuiRadius,		
						DOTA_UNIT_TARGET_TEAM_ENEMY,
						keys.ability:GetAbilityTargetType(),
						0,
						FIND_CLOSEST,
						false
					)
			for k,v in pairs(targets) do
				local damage_table = {
					ability = keys.ability,
					victim = v,
					attacker = caster,
					damage = dealdamage,
					damage_type = keys.ability:GetAbilityDamageType(), 
					damage_flags = keys.ability:GetAbilityTargetFlags()
				}
				UnitDamageTarget(damage_table)
			end
	else

		local damage_target = {
			victim = keys.target,
			attacker = caster,
			damage = dealdamage,
			damage_type = keys.ability:GetAbilityDamageType(), 
			damage_flags = 0
		}
		UnitDamageTarget(damage_target)
	end
end

function OnByakuren03SpellStart(keys)
	if keys.caster:GetTeam()~=keys.target:GetTeam() and is_spell_blocked(keys.target) then return end
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
	local target = keys.target
	local vecTarget = target:GetOrigin()

	
	if(target:GetTeam()==caster:GetTeam())then
		target:Purge(false,true,false,true,false)
		local vecMove = vecCaster + caster:GetForwardVector() * 60
		target:SetOrigin(vecMove)
		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_pulse_nova_h.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, vecTarget)
		ParticleManager:SetParticleControl(effectIndex, 1, vecTarget)
		ParticleManager:SetParticleControl(effectIndex, 2, vecTarget)
		ParticleManager:ReleaseParticleIndex(effectIndex)
		ParticleManager:DestroyParticleSystem(effectIndex,false)
		SetTargetToTraversable(target)
		target:EmitSound("Hero_Weaver.TimeLapse")
	else
		local effectIndex = ParticleManager:CreateParticle("particles/heroes/byakuren/ability_byakuren_03.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, vecTarget)
		local time = 0
		target:SetThink(
				function()
					if GameRules:IsGamePaused() then return 0.03 end
					if time >= 3.0 then
						target:SetOrigin(vecTarget)
						target:EmitSound("Hero_Weaver.TimeLapse")
						SetTargetToTraversable(target)
						ParticleManager:DestroyParticleSystem(effectIndex,true)
						return nil
					end
					time = time + 0.1
					return 0.1
				end, 
		"ability_byakuren_03_return",
		0)
	end
end

ability_thdots_byakuren04 = class({})

modifier_thdots_byakuren04_passive = class({})
LinkLuaModifier("modifier_thdots_byakuren04_passive", "scripts/vscripts/abilities/abilitybyakuren.lua", LUA_MODIFIER_MOTION_NONE)

function ability_thdots_byakuren04:GetIntrinsicModifierName() return "modifier_thdots_byakuren04_passive" end
function ability_thdots_byakuren04:InnateAbilityType() return 2 end

function modifier_thdots_byakuren04_passive:OnCreated()
	if not IsServer() then return end 
	self:StartIntervalThink(0.2)
end

function modifier_thdots_byakuren04_passive:OnIntervalThink()
	if not IsServer() then return end
	local health_increase = self:GetAbility():GetSpecialValueFor("health_increase")
	self:SetStackCount(self:GetParent():GetMaxMana()*health_increase)
	self:GetParent():CalculateStatBonus(true)
end

function modifier_thdots_byakuren04_passive:GetEffectName()
	return "particles/heroes/byakuren/ability_byakuren_04.vpcf"
end

function modifier_thdots_byakuren04_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_HEALTH_BONUS
	}
end

function modifier_thdots_byakuren04_passive:GetModifierHealthBonus()
	return self:GetStackCount()
end

function modifier_thdots_byakuren04_passive:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetCaster() then return end
	if keys.target:IsBuilding() then return end
	local caster = self:GetParent()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("radius")
	local ability_multi = ability:GetSpecialValueFor("ability_multi") / 100
	local targets = FindUnitsInRadius(caster:GetTeam(), keys.target:GetOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_CLOSEST, false)
	local dealdamage = ability:GetAbilityDamage() + ability_multi * ( caster:GetMaxHealth() - caster:GetHealth())
	for _,v in pairs(targets) do
		local damage = dealdamage
		if v ~= keys.target then
			damage = damage / 2
		end
		local damage_table = {
				ability = ability,
			    victim = v,
			    attacker = caster,
			    damage = damage,
			    damage_type = ability:GetAbilityDamageType(), 
		}
		UnitDamageTarget(damage_table)
		local effectIndex = ParticleManager:CreateParticle("particles/heroes/byakuren/ability_byakuren_04_attack.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, v:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex,false)
	end
	caster:Heal(dealdamage,caster)
end

function OnByakuren05SpellStart(keys)
	local ability=keys.ability
	local caster=keys.caster
	local target=keys.target
	caster:EmitSound("Voice_Thdots_Byakuren.AbilityByakuren04")
	if is_spell_blocked(keys.target) then return end
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_thdots_byakuren05_debuff", {Duration = keys.Duration}) 
end

function OnByakuren03Order(keys)
	if keys.target~=nil and keys.event_ability~=nil then
		if keys.target:HasModifier("modifier_byakuren03_effect") and keys.event_ability:GetAbilityName() == "ability_thdots_byakuren01" then
			--print("target="..keys.target:GetClassname())
			--print("keys.event_ability="..keys.event_ability:GetAbilityName())				
			keys.event_ability.cast_range_bonus = true			
		else
			keys.event_ability.cast_range_bonus = false
		end
	end
end