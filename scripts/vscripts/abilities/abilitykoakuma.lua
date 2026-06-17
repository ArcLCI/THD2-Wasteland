LinkLuaModifier("modifier_koakuma02_debuff", "scripts/vscripts/abilities/abilitykoakuma.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_koakuma02_aoe_debuff", "scripts/vscripts/abilities/abilitykoakuma.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_thdots_koakuma03_passive", "scripts/vscripts/abilities/abilitykoakuma.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_thdots_koakuma03", "scripts/vscripts/abilities/abilitykoakuma.lua", LUA_MODIFIER_MOTION_NONE)

KOAKUMA_BOUNCE_STATES = KOAKUMA_BOUNCE_STATES or {}
KOAKUMA_BOUNCE_NEXT_ID = KOAKUMA_BOUNCE_NEXT_ID or 0
KOAKUMA_BOUNCE_CLEANUP_RUNNING = KOAKUMA_BOUNCE_CLEANUP_RUNNING or false

local function StartKoakumaBounceCleanup()
	if KOAKUMA_BOUNCE_CLEANUP_RUNNING then return end
	KOAKUMA_BOUNCE_CLEANUP_RUNNING = true

	-- 所有 Koakuma 弹射共用一个低频 thinker 清理异常残留状态。
	GameRules:GetGameModeEntity():SetContextThink("koakuma_bounce_state_cleanup", function()
		local now = GameRules:GetGameTime()
		local hasState = false
		for castId, state in pairs(KOAKUMA_BOUNCE_STATES) do
			local caster = state.caster
			local ability = state.ability
			if state.expireTime <= now or caster == nil or caster:IsNull() or ability == nil or ability:IsNull() then
				KOAKUMA_BOUNCE_STATES[castId] = nil
			else
				hasState = true
			end
		end

		if not hasState then
			KOAKUMA_BOUNCE_CLEANUP_RUNNING = false
			return nil
		end
		return 2
	end, 2)
end

local function RegisterKoakumaBounceState(state)
	KOAKUMA_BOUNCE_NEXT_ID = KOAKUMA_BOUNCE_NEXT_ID + 1
	state.castId = KOAKUMA_BOUNCE_NEXT_ID
	state.expireTime = GameRules:GetGameTime() + 15
	KOAKUMA_BOUNCE_STATES[state.castId] = state
	StartKoakumaBounceCleanup()
	return state.castId
end

local function RemoveKoakumaBounceState(castId)
	KOAKUMA_BOUNCE_STATES[castId] = nil
end

local function GetKoakumaNearbyEnemies(state, center, hasKoakuma04)
	local scanRadius = state.bounceRange
	if hasKoakuma04 then
		scanRadius = math.max(scanRadius, state.koakuma04Radius)
	end

	-- 弹射选敌与 4 技能范围伤害共用一次扫描。
	return FindUnitsInRadius(
		state.caster:GetTeamNumber(),
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

local function GetKoakumaNextTarget(state, currentTarget, center, nearbyEnemies)
	for _, unit in pairs(nearbyEnemies) do
		if unit ~= currentTarget and (unit:GetAbsOrigin() - center):Length2D() <= state.bounceRange then
			return unit
		end
	end

	-- 没有其他敌人时直接判断是否能回弹至施法者，无需额外扫描友方单位。
	local caster = state.caster
	if caster:IsAlive() and not caster:IsInvulnerable() and caster ~= currentTarget
		and (caster:GetAbsOrigin() - center):Length2D() <= state.bounceRange then
		return caster
	end
end

local function LaunchKoakumaBounceProjectile(state, source, target)
	state.expireTime = GameRules:GetGameTime() + 15
	ProjectileManager:CreateTrackingProjectile({
		Target = target,
		Source = source,
		EffectName = state.particleName,
		Ability = state.ability,
		bDodgeable = false,
		bProvidesVision = false,
		iMoveSpeed = state.projectileSpeed,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		ExtraData = { cast_id = state.castId }
	})
end

local function ConsumeKoakuma03Ready(caster, castAbility, koakuma03)
	if koakuma03 == nil or not caster:HasModifier("modifier_thdots_koakuma03") then return 0 end

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

local function CreateKoakumaBounceState(ability, target, kind)
	local caster = ability:GetCaster()
	local level = ability:GetLevel() - 1
	local koakuma03 = caster:FindAbilityByName("ability_thdots_koakuma03")
	local koakuma04 = caster:FindAbilityByName("ability_thdots_koakuma04")
	local isKoakuma = caster:GetClassname() == "npc_dota_hero_lich"
	local bonusProjectileSpeed = ConsumeKoakuma03Ready(caster, ability, koakuma03)
	local hasKoakuma04 = caster:HasModifier("modifier_koakuma04")
	local koakuma04Level = koakuma04 ~= nil and koakuma04:GetLevel() - 1 or -1
	local koakuma04BonusDamage = 0
	if hasKoakuma04 and koakuma04Level >= 0 then
		koakuma04BonusDamage = koakuma04:GetLevelSpecialValueFor("bonus_damage", koakuma04Level) / 100
	end

	local damageBonusPercent = ability:GetLevelSpecialValueFor("damage_bonus_percent", level)
	if kind == 2 then
		damageBonusPercent = damageBonusPercent + FindTelentValue(caster, "special_bonus_unique_koakuma_5") * 0.25
	end

	local state = {
		ability = ability,
		caster = caster,
		kind = kind,
		bounceCount = 0,
		damage = (1 + koakuma04BonusDamage) * (ability:GetLevelSpecialValueFor("damage", level) + caster:GetIntellect(false) * damageBonusPercent),
		bounceRange = ability:GetLevelSpecialValueFor("range", level),
		projectileSpeed = ability:GetLevelSpecialValueFor("projectile_speed", level) + bonusProjectileSpeed + FindTelentValue(caster, "special_bonus_unique_koakuma_1"),
		particleName = kind == 1 and "particles/heroes/koakuma/koakuma01.vpcf" or "particles/heroes/koakuma/koakuma02.vpcf",
		maxBounces = 0,
		damageReductionPercent = 0,
		koakuma04DamagePercentage = 0,
		koakuma04Radius = 0,
		duration = kind == 2 and ability:GetSpecialValueFor("duration") or 0
	}

	if kind == 1 then
		state.damage = state.damage + FindTelentValue(caster, "special_bonus_unique_koakuma_4")
	end
	if isKoakuma and koakuma03 ~= nil and koakuma04 ~= nil then
		local koakuma03Level = koakuma03:GetLevel() - 1
		state.maxBounces = koakuma03:GetLevelSpecialValueFor("bounces", koakuma03Level) + FindTelentValue(caster, "special_bonus_unique_koakuma_3")
		state.damageReductionPercent = (koakuma03:GetLevelSpecialValueFor("damage_reduction_percent", koakuma03Level) + FindTelentValue(caster, "special_bonus_unique_koakuma_2")) / 100
		state.koakuma04DamagePercentage = koakuma04:GetLevelSpecialValueFor("damage_percentage", koakuma04Level)
		state.koakuma04Radius = koakuma04:GetLevelSpecialValueFor("radius", koakuma04Level)
	end

	RegisterKoakumaBounceState(state)
	LaunchKoakumaBounceProjectile(state, caster, target)
end

local function RefreshKoakuma02Modifier(target, modifierName, duration)
	local modifier = target:FindModifierByName(modifierName)
	if modifier ~= nil then
		modifier:SetDuration(duration, true)
	end
end

local function AddKoakuma02ModifierStack(caster, target, ability, modifierName, duration)
	local modifier = target:FindModifierByName(modifierName)
	if modifier == nil then
		modifier = target:AddNewModifier(caster, ability, modifierName, { duration = duration })
		modifier:SetStackCount(1)
	else
		modifier:SetDuration(duration, true)
		modifier:IncrementStackCount()
	end
end

local function ApplyKoakuma02DirectDebuff(state, target)
	RefreshKoakuma02Modifier(target, "modifier_koakuma02_aoe_debuff", state.duration)
	AddKoakuma02ModifierStack(state.caster, target, state.ability, "modifier_koakuma02_debuff", state.duration)
end

local function ApplyKoakuma02AreaDebuff(state, target)
	RefreshKoakuma02Modifier(target, "modifier_koakuma02_debuff", state.duration)
	AddKoakuma02ModifierStack(state.caster, target, state.ability, "modifier_koakuma02_aoe_debuff", state.duration)
end

local function DealKoakuma04AreaDamage(state, target, center, nearbyEnemies)
	for _, unit in pairs(nearbyEnemies) do
		if unit ~= target and (unit:GetAbsOrigin() - center):Length2D() <= state.koakuma04Radius then
			if state.kind == 2 then
				ApplyKoakuma02AreaDebuff(state, unit)
			end
			UnitDamageTarget({
				ability = state.ability,
				victim = unit,
				attacker = state.caster,
				damage = state.damage * state.koakuma04DamagePercentage / 100,
				damage_type = DAMAGE_TYPE_MAGICAL,
				damage_flags = 0
			})
		end
	end
end

local function HandleKoakumaBounceHit(castId, target)
	local state = KOAKUMA_BOUNCE_STATES[castId]
	if state == nil then return true end
	if target == nil or target:IsNull() or state.caster == nil or state.caster:IsNull() then
		RemoveKoakumaBounceState(castId)
		return true
	end

	target:EmitSound("Hero_OgreMagi.Fireblast.Target")
	if state.bounceCount ~= 0 then
		state.damage = state.damage * (1 - state.damageReductionPercent)
	end

	local center = target:GetAbsOrigin()
	if target:GetTeam() ~= state.caster:GetTeam() then
		if state.kind == 2 then
			ApplyKoakuma02DirectDebuff(state, target)
		end
		UnitDamageTarget({
			ability = state.ability,
			victim = target,
			attacker = state.caster,
			damage = state.damage,
			damage_type = DAMAGE_TYPE_MAGICAL
		})
	end

	local hasKoakuma04 = state.caster:HasModifier("modifier_koakuma04")
	local nearbyEnemies = nil
	if hasKoakuma04 or state.bounceCount < state.maxBounces then
		nearbyEnemies = GetKoakumaNearbyEnemies(state, center, hasKoakuma04)
	end
	if hasKoakuma04 then
		DealKoakuma04AreaDamage(state, target, center, nearbyEnemies)
	end

	if state.bounceCount >= state.maxBounces then
		RemoveKoakumaBounceState(castId)
		return true
	end

	local nextTarget = GetKoakumaNextTarget(state, target, center, nearbyEnemies)
	if nextTarget == nil then
		RemoveKoakumaBounceState(castId)
		return true
	end

	state.bounceCount = state.bounceCount + 1
	LaunchKoakumaBounceProjectile(state, target, nextTarget)
	return true
end

ability_thdots_koakuma01 = class({})

function ability_thdots_koakuma01:OnSpellStart()
	local target = self:GetCursorTarget()
	self:GetCaster():EmitSound("Hero_OgreMagi.Fireblast.Cast")
	if is_spell_blocked(target) then return end
	CreateKoakumaBounceState(self, target, 1)
end

function ability_thdots_koakuma01:OnProjectileHit_ExtraData(target, location, extraData)
	return HandleKoakumaBounceHit(tonumber(extraData.cast_id), target)
end

ability_thdots_koakuma02 = class({})

function ability_thdots_koakuma02:OnSpellStart()
	local target = self:GetCursorTarget()
	self:GetCaster():EmitSound("Hero_OgreMagi.Fireblast.Cast")
	if is_spell_blocked(target) then return end
	CreateKoakumaBounceState(self, target, 2)
end

function ability_thdots_koakuma02:OnProjectileHit_ExtraData(target, location, extraData)
	return HandleKoakumaBounceHit(tonumber(extraData.cast_id), target)
end

modifier_koakuma02_debuff = class({})

function modifier_koakuma02_debuff:IsDebuff() return true end
function modifier_koakuma02_debuff:IsPurgable() return true end

function modifier_koakuma02_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_koakuma02_debuff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_speed_reduction") * self:GetStackCount()
end

function modifier_koakuma02_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_speed_reduction") * self:GetStackCount()
end

modifier_koakuma02_aoe_debuff = class({})

function modifier_koakuma02_aoe_debuff:IsDebuff() return true end
function modifier_koakuma02_aoe_debuff:IsPurgable() return true end

function modifier_koakuma02_aoe_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_koakuma02_aoe_debuff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("aoe_attack_speed_reduction") * self:GetStackCount()
end

function modifier_koakuma02_aoe_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("aoe_movement_speed_reduction") * self:GetStackCount()
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
