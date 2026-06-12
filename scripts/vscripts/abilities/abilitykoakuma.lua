LinkLuaModifier("modifier_thdots_koakuma03_passive", "scripts/vscripts/abilities/abilitykoakuma.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_thdots_koakuma03", "scripts/vscripts/abilities/abilitykoakuma.lua", LUA_MODIFIER_MOTION_NONE)

local function CreateKoakumaBounceDummy(caster, dummyAbilityName, dummyModifierName)
	local dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	dummy:FindAbilityByName("ability_dummy_unit"):SetLevel(1)
	dummy:AddAbility(dummyAbilityName)
	local dummyAbility = dummy:FindAbilityByName(dummyAbilityName)
	dummyAbility:ApplyDataDrivenModifier(caster, dummy, dummyModifierName, {})

	-- 弹道回调异常时强制清理 dummy，避免实体永久残留。
	dummy:SetContextThink("koakuma_bounce_dummy_cleanup", function()
		if dummy ~= nil and not dummy:IsNull() then
			dummy:RemoveSelf()
		end
		return nil
	end, 15)

	return dummyAbility
end

local function GetKoakumaNearbyEnemies(caster, center, ability)
	local scanRadius = ability.bounceRange
	if caster:GetOwner():HasModifier("modifier_koakuma04") then
		scanRadius = math.max(scanRadius, ability.koakuma04_radius)
	end

	-- 弹射选敌与 4 技能范围伤害共用一次扫描。
	return FindUnitsInRadius(
		caster:GetTeamNumber(),
		center,
		nil,
		scanRadius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
end

local function GetKoakumaNextTarget(caster, currentTarget, center, ability, nearbyEnemies)
	for _, unit in pairs(nearbyEnemies) do
		if unit ~= currentTarget and (unit:GetAbsOrigin() - center):Length2D() <= ability.bounceRange then
			return unit
		end
	end

	-- 没有其他敌人时直接判断是否能回弹至施法者，无需额外扫描友方单位。
	local owner = caster:GetOwner()
	if owner ~= nil and not owner:IsNull() and owner:IsAlive() and not owner:IsInvulnerable() and owner ~= currentTarget
		and (owner:GetAbsOrigin() - center):Length2D() <= ability.bounceRange then
		return owner
	end
end

local function ConsumeKoakuma03Ready(caster, castAbility, koakuma03)
	if not caster:HasModifier("modifier_thdots_koakuma03") then return 0 end

	local level = koakuma03:GetLevel() - 1
	local bonusProjectileSpeed = koakuma03:GetLevelSpecialValueFor("bonus_projectile_speed", level)
	local reductionCooldown = -koakuma03:GetLevelSpecialValueFor("reduction_cooldown", level)
	THDReduceCooldown(castAbility, reductionCooldown)

	local cooldown = koakuma03:GetCooldown(level)
	if caster:HasModifier("modifier_item_nuclear_stick_cooldown_reduction") then
		cooldown = cooldown * 0.75
	end
	koakuma03:StartCooldown(cooldown)
	caster:RemoveModifierByName("modifier_thdots_koakuma03")

	local passive = caster:FindModifierByName("modifier_thdots_koakuma03_passive")
	if passive ~= nil then
		passive:StartCooldownWatch()
	end
	return bonusProjectileSpeed
end

function OnKoakuma01SpellStart( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if is_spell_blocked(keys.target) then return end
	local ability_level = ability:GetLevel() - 1
	local koakuma03
	local koakuma03_level
	local koakuma04
	local koakuma04_level
	local dummy_ability = CreateKoakumaBounceDummy(caster, "ability_thdots_koakuma01_dummy", "modifier_koakuma01_dummy_unit")
	local Int = caster:GetIntellect(false)
	if caster:GetClassname()=="npc_dota_hero_lich" then		
		koakuma03 = caster:FindAbilityByName("ability_thdots_koakuma03")
		koakuma03_level = koakuma03:GetLevel() - 1
		koakuma04 = caster:FindAbilityByName("ability_thdots_koakuma04")
		koakuma04_level = koakuma04:GetLevel() - 1
	end
	local bonus_projectile_speed = 0
	if caster:HasModifier("modifier_thdots_koakuma03") then
		bonus_projectile_speed = ConsumeKoakuma03Ready(caster, ability, koakuma03)
	end	

	local koakuma04_bonus_damage = 0
	if caster:HasModifier("modifier_koakuma04") then 
		koakuma04_bonus_damage = koakuma04:GetLevelSpecialValueFor("bonus_damage", koakuma04_level)/100	
	end
	-- Ability variables

	dummy_ability.bounceCount = 0
	dummy_ability.damage = (1 + koakuma04_bonus_damage) * (ability:GetLevelSpecialValueFor("damage", ability_level) + Int * ability:GetLevelSpecialValueFor("damage_bonus_percent", ability_level)) + FindTelentValue(caster,"special_bonus_unique_koakuma_4")
	dummy_ability.bounceRange = ability:GetLevelSpecialValueFor("range", ability_level) 	
	dummy_ability.original_ability = ability
	dummy_ability.particle_name = "particles/heroes/koakuma/koakuma01.vpcf"
	dummy_ability.projectile_speed = ability:GetLevelSpecialValueFor("projectile_speed", ability_level) + bonus_projectile_speed + FindTelentValue(caster,"special_bonus_unique_koakuma_1")
	dummy_ability.projectileFrom = caster
	dummy_ability.projectileTo = nil
	if caster:GetClassname()=="npc_dota_hero_lich" then	
		dummy_ability.maxBounces = koakuma03:GetLevelSpecialValueFor("bounces", koakuma03_level)  + FindTelentValue(caster,"special_bonus_unique_koakuma_3")
		dummy_ability.damage_reduction_percent = (koakuma03:GetLevelSpecialValueFor("damage_reduction_percent", koakuma03_level) + FindTelentValue(caster,"special_bonus_unique_koakuma_2"))/100	
		dummy_ability.koakuma04_damage_percentage = koakuma04:GetLevelSpecialValueFor("damage_percentage", koakuma04_level)
		dummy_ability.koakuma04_radius = koakuma04:GetLevelSpecialValueFor("radius", koakuma04_level)
	else
		dummy_ability.maxBounces = 0
		dummy_ability.damage_reduction_percent = 0
		dummy_ability.koakuma04_damage_percentage = 0
		dummy_ability.koakuma04_radius = 0
	end

	dummy_ability.projectileTo = target
			

	local info = {
    Target = dummy_ability.projectileTo,
    Source = dummy_ability.projectileFrom,
    EffectName = dummy_ability.particle_name,
    Ability = dummy_ability,
    bDodgeable = false,
    bProvidesVision = false,
    iMoveSpeed = dummy_ability.projectile_speed,
    iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
	}
	ProjectileManager:CreateTrackingProjectile( info )   
end

--[[Author: Pizzalol
	Date: 29.09.2015.
	Creates bounce projectiles to the nearest target if there is any]]
function OnKoakuma01SpellJump( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	-- Initialize the damage table
	local damage_table = {}
	damage_table.attacker = caster:GetOwner()
	damage_table.victim = target
	damage_table.ability = ability.original_ability
	damage_table.damage_type = DAMAGE_TYPE_MAGICAL
	if ability.bounceCount ~= 0 then
		damage_table.damage = ability.damage * (1-ability.damage_reduction_percent)
	else
		damage_table.damage = ability.damage
	end
	local center = target:GetAbsOrigin()
	if target:GetTeam() ~= caster:GetTeam() then
		UnitDamageTarget(damage_table)
	end
	-- Save the new damage for future bounces
	ability.damage = damage_table.damage
	local hasKoakuma04 = caster:GetOwner():HasModifier("modifier_koakuma04")
	local nearbyEnemies = nil
	if hasKoakuma04 or ability.bounceCount < ability.maxBounces then
		nearbyEnemies = GetKoakumaNearbyEnemies(caster, center, ability)
	end
	if hasKoakuma04 then
		for _,v in pairs(nearbyEnemies) do
			if v ~= target and (v:GetAbsOrigin() - center):Length2D() <= ability.koakuma04_radius then
				local deal_damage = ability.damage * ability.koakuma04_damage_percentage / 100
				local damage_table = {
						ability = ability.original_ability,
					    victim = v,
					    attacker = caster:GetOwner(),
					    damage = deal_damage,
					    damage_type = DAMAGE_TYPE_MAGICAL, 
			    	    damage_flags = 0
				}
				UnitDamageTarget(damage_table)
			end
		end
	end

	-- If we exceeded the bounce limit then remove the dummy and stop the function
	if ability.bounceCount >= ability.maxBounces then
		killDummy(caster,caster)
		return
	end

	-- Reset target data and find new targets
	ability.projectileFrom = ability.projectileTo
	ability.projectileTo = nil

	ability.projectileTo = GetKoakumaNextTarget(caster, target, center, ability, nearbyEnemies)

	-- If we didnt find a new target then kill the dummy
	if ability.projectileTo == nil then
		killDummy(caster, caster)
	else
	-- Otherwise increase the bounce count and create a new bounce projectile
		ability.bounceCount = ability.bounceCount + 1
		local info = {
        Target = ability.projectileTo,
        Source = ability.projectileFrom,
        EffectName = ability.particle_name,
        Ability = ability,
        bDodgeable = false,
        bProvidesVision = false,
        iMoveSpeed = ability.projectile_speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
    	}
    	ProjectileManager:CreateTrackingProjectile( info )
    end
end

function killDummy(caster, target)
	if caster:GetUnitName() == "npc_dummy_unit" then
		caster:RemoveSelf()
	elseif target:GetUnitName() == "npc_dummy_unit" then
		target:RemoveSelf()
	end
end

function OnKoakuma02SpellStart( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if is_spell_blocked(keys.target) then return end
	local ability_level = ability:GetLevel() - 1
	local koakuma03
	local koakuma03_level
	local koakuma04
	local koakuma04_level
	local dummy_ability = CreateKoakumaBounceDummy(caster, "ability_thdots_koakuma02_dummy", "modifier_koakuma02_dummy_unit")
	local Int = caster:GetIntellect(false)

	if caster:GetClassname()=="npc_dota_hero_lich" then	
		koakuma03 = caster:FindAbilityByName("ability_thdots_koakuma03")
		koakuma03_level = koakuma03:GetLevel() - 1
		koakuma04 = caster:FindAbilityByName("ability_thdots_koakuma04")
		koakuma04_level = koakuma04:GetLevel() - 1
	end
	local bonus_projectile_speed = 0
	if caster:HasModifier("modifier_thdots_koakuma03") then
		bonus_projectile_speed = ConsumeKoakuma03Ready(caster, ability, koakuma03)
	end
	
	local koakuma04_bonus_damage = 0
	if caster:HasModifier("modifier_koakuma04") then 
		koakuma04_bonus_damage = koakuma04:GetLevelSpecialValueFor("bonus_damage", koakuma04_level)/100	
	end
	-- Ability variables
	
	dummy_ability.damage = (1 + koakuma04_bonus_damage) * (ability:GetLevelSpecialValueFor("damage", ability_level) + Int * (FindTelentValue(caster,"special_bonus_unique_koakuma_5") * 0.25 + ability:GetLevelSpecialValueFor("damage_bonus_percent", ability_level))) 

	dummy_ability.bounceCount = 0
	dummy_ability.bounceRange = ability:GetLevelSpecialValueFor("range", ability_level) 	
	dummy_ability.original_ability = ability
	dummy_ability.particle_name = "particles/heroes/koakuma/koakuma02.vpcf"
	dummy_ability.projectile_speed = ability:GetLevelSpecialValueFor("projectile_speed", ability_level) + bonus_projectile_speed + FindTelentValue(caster,"special_bonus_unique_koakuma_1")
	dummy_ability.projectileFrom = caster
	dummy_ability.projectileTo = nil
	dummy_ability.duration = keys.Duration
	if caster:GetClassname()=="npc_dota_hero_lich" then	
		dummy_ability.maxBounces = koakuma03:GetLevelSpecialValueFor("bounces", koakuma03_level) + FindTelentValue(caster,"special_bonus_unique_koakuma_3")
		dummy_ability.damage_reduction_percent = (koakuma03:GetLevelSpecialValueFor("damage_reduction_percent", koakuma03_level) + FindTelentValue(caster,"special_bonus_unique_koakuma_2"))/100	
		dummy_ability.koakuma04_damage_percentage = koakuma04:GetLevelSpecialValueFor("damage_percentage", koakuma04_level)
		dummy_ability.koakuma04_radius = koakuma04:GetLevelSpecialValueFor("radius", koakuma04_level)
	else
		dummy_ability.maxBounces = 0
		dummy_ability.damage_reduction_percent = 0
		dummy_ability.koakuma04_damage_percentage = 0
		dummy_ability.koakuma04_radius = 0
	end

	dummy_ability.projectileTo = target
	
	local info = {
    Target = dummy_ability.projectileTo,
    Source = dummy_ability.projectileFrom,
    EffectName = dummy_ability.particle_name,
    Ability = dummy_ability,
    bDodgeable = false,
    bProvidesVision = false,
    iMoveSpeed = dummy_ability.projectile_speed,
    iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
	}
	ProjectileManager:CreateTrackingProjectile( info )   
end

--[[Author: Pizzalol
	Date: 29.09.2015.
	Creates bounce projectiles to the nearest target if there is any]]
function OnKoakuma02SpellJump( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local targetLoc = target:GetAbsOrigin()

	-- Initialize the damage table
	local damage_table = {}
	damage_table.attacker = caster:GetOwner()
	damage_table.victim = target
	damage_table.ability = ability.original_ability
	damage_table.damage_type = DAMAGE_TYPE_MAGICAL
	if ability.bounceCount ~= 0 then
		damage_table.damage = ability.damage * (1-ability.damage_reduction_percent)
	else
		damage_table.damage = ability.damage
	end
	if target:GetTeam() ~= caster:GetTeam() then
		if target:HasModifier("modifier_koakuma02_debuff") == false and target:HasModifier("modifier_koakuma02_aoe_debuff") == false then			
			target.koakuma02count = 0			
			target.koakuma02countaoe = 0			
		end
		if target:HasModifier("modifier_koakuma02_debuff") == false then			
			target.koakuma02count = 0			
		end
		ability.original_ability:ApplyDataDrivenModifier(caster:GetOwner(), target, "modifier_koakuma02_debuff", {duration = ability.duration})
		if target:HasModifier("modifier_koakuma02_aoe_debuff") then
			ability.original_ability:ApplyDataDrivenModifier(caster:GetOwner(), target, "modifier_koakuma02_aoe_debuff", {duration = ability.duration})
			target:SetModifierStackCount("modifier_koakuma02_aoe_debuff", ability.original_ability, target.koakuma02countaoe)
		end
		target.koakuma02count = target.koakuma02count + 1
		target:SetModifierStackCount("modifier_koakuma02_debuff", ability.original_ability, target.koakuma02count)
		UnitDamageTarget(damage_table)	
	end
	-- Save the new damage for future bounces
	ability.damage = damage_table.damage
	local hasKoakuma04 = caster:GetOwner():HasModifier("modifier_koakuma04")
	local nearbyEnemies = nil
	if hasKoakuma04 or ability.bounceCount < ability.maxBounces then
		nearbyEnemies = GetKoakumaNearbyEnemies(caster, targetLoc, ability)
	end
	if hasKoakuma04 then
		for _,v in pairs(nearbyEnemies) do
			if v ~= target and (v:GetAbsOrigin() - targetLoc):Length2D() <= ability.koakuma04_radius then
				if v:HasModifier("modifier_koakuma02_debuff") == false and v:HasModifier("modifier_koakuma02_aoe_debuff") == false then			
					v.koakuma02count = 0			
					v.koakuma02countaoe = 0			
				end
				if v:HasModifier("modifier_koakuma02_aoe_debuff") == false then			
					v.koakuma02countaoe = 0			
				end
				ability.original_ability:ApplyDataDrivenModifier(caster:GetOwner(), v, "modifier_koakuma02_aoe_debuff", {duration = ability.duration})
				if v:HasModifier("modifier_koakuma02_debuff") then
					ability.original_ability:ApplyDataDrivenModifier(caster:GetOwner(), v, "modifier_koakuma02_debuff", {duration = ability.duration})
					v:SetModifierStackCount("modifier_koakuma02_debuff", ability.original_ability, v.koakuma02count)
				end
				v.koakuma02countaoe = v.koakuma02countaoe + 1
				v:SetModifierStackCount("modifier_koakuma02_aoe_debuff", ability.original_ability, v.koakuma02countaoe)
				local deal_damage = ability.damage * ability.koakuma04_damage_percentage / 100
				local damage_table = {
						ability = ability.original_ability,
					    victim = v,
					    attacker = caster:GetOwner(),
					    damage = deal_damage,
					    damage_type = DAMAGE_TYPE_MAGICAL, 
			    	    damage_flags = 0
				}
				UnitDamageTarget(damage_table)				
			end
		end
	end

	-- If we exceeded the bounce limit then remove the dummy and stop the function
	if ability.bounceCount >= ability.maxBounces then
		killDummy(caster,caster)
		return
	end

	-- Reset target data and find new targets
	ability.projectileFrom = ability.projectileTo
	ability.projectileTo = nil

	ability.projectileTo = GetKoakumaNextTarget(caster, target, targetLoc, ability, nearbyEnemies)

	-- If we didnt find a new target then kill the dummy
	if ability.projectileTo == nil then
		killDummy(caster, caster)
	else
	-- Otherwise increase the bounce count and create a new bounce projectile
		ability.bounceCount = ability.bounceCount + 1
		local info = {
        Target = ability.projectileTo,
        Source = ability.projectileFrom,
        EffectName = ability.particle_name,
        Ability = ability,
        bDodgeable = false,
        bProvidesVision = false,
        iMoveSpeed = ability.projectile_speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
    	}
    	ProjectileManager:CreateTrackingProjectile( info )
    end
end

ability_thdots_koakuma03 = class({})

function ability_thdots_koakuma03:GetIntrinsicModifierName()
	return "modifier_thdots_koakuma03_passive"
end

modifier_thdots_koakuma03_passive = class({})

function modifier_thdots_koakuma03_passive:IsHidden() return true end
function modifier_thdots_koakuma03_passive:IsPurgable() return false end
function modifier_thdots_koakuma03_passive:RemoveOnDeath() return false end

function modifier_thdots_koakuma03_passive:OnCreated()
	if not IsServer() then return end
	self:RefreshReadyState()
end

function modifier_thdots_koakuma03_passive:OnRefresh()
	if not IsServer() then return end
	self:RefreshReadyState()
end

function modifier_thdots_koakuma03_passive:RefreshReadyState()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	if ability:IsCooldownReady() then
		if not parent:HasModifier("modifier_thdots_koakuma03") then
			parent:AddNewModifier(parent, ability, "modifier_thdots_koakuma03", {})
		end
		self:StartIntervalThink(-1)
	else
		self:StartCooldownWatch()
	end
end

function modifier_thdots_koakuma03_passive:StartCooldownWatch()
	-- ready 存在时完全停止 thinker，仅在冷却期间检查恢复状态。
	self:StartIntervalThink(0.1)
end

function modifier_thdots_koakuma03_passive:OnIntervalThink()
	if self:GetAbility():IsCooldownReady() then
		self:RefreshReadyState()
	end
end

modifier_thdots_koakuma03 = class({})

function modifier_thdots_koakuma03:IsHidden() return false end
function modifier_thdots_koakuma03:IsPurgable() return false end
function modifier_thdots_koakuma03:RemoveOnDeath() return false end

function OnKoakumaExThink(keys)
	local caster = keys.caster
	local ability = keys.ability	
	local mana = caster:GetMana()
	local max_mana = caster:GetMaxMana()
	if max_mana <= 0 then return end
	local stack_count = math.floor( 100 - ( mana / max_mana ) * 100 )
	local modifier_created = false
	if caster:HasModifier("modifier_thdots_koakumaex") == false then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_koakumaex", {})	
		modifier_created = true
	end
	-- 缺失魔法百分比变化时才同步层数，减少无效 modifier 更新。
	if modifier_created or ability.koakuma_ex_last_stack ~= stack_count then
		caster:SetModifierStackCount("modifier_thdots_koakumaex", ability, stack_count)
		ability.koakuma_ex_last_stack = stack_count
	end
end

function OnKoakuma04Death(keys)
	local caster = keys.caster or EntIndexToHScript(keys.caster_entindex)
	if caster == nil or caster:IsNull() then return end
	if keys.unit ~= caster or not caster:IsRealHero() or not caster:HasModifier("modifier_item_wanbaochui") then return end

	local wanbaochui_damage_percent = keys.ability:GetSpecialValueFor("wanbaochui_damage_percent") / 100
	local wanbaochui_damage_radius = keys.ability:GetSpecialValueFor("wanbaochui_damage_radius")
	local wanbaochui_stun_time = keys.ability:GetSpecialValueFor("wanbaochui_stun_time")
	local vec_caster = caster:GetOrigin()

	local effectIndex1 = ParticleManager:CreateParticle("particles/econ/items/monkey_king/arcana/fire/mk_arcana_fire_spring_ring_radial.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(effectIndex1, 0, caster, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:DestroyParticleSystem(effectIndex1, false)
	local effectIndex2 = ParticleManager:CreateParticle("particles/heroes/yumemi/ability_yumemi_04_exolosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(effectIndex2, 0, caster, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:DestroyParticleSystem(effectIndex2, false)
	caster:EmitSound("Hero_Huskar.Inner_Fire.Cast")

	local targets = FindUnitsInRadius(
		caster:GetTeam(),
		vec_caster,
		nil,
		wanbaochui_damage_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	for _,v in pairs(targets) do
		UtilStun:UnitStunTarget(caster, v, wanbaochui_stun_time)

		local effectIndex = ParticleManager:CreateParticle("particles/econ/items/invoker/invoker_apex/invoker_sun_strike_beam_immortal1.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, v:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex, false)
		v:EmitSound("Hero_Huskar.Inner_Fire.Cast")

		UnitDamageTarget({
			ability = keys.ability,
			victim = v,
			attacker = caster,
			damage = v:GetMaxHealth() * wanbaochui_damage_percent,
			damage_type = DAMAGE_TYPE_MAGICAL,
			damage_flags = 0
		})
	end
end
