--------------------------------------------------------
-- Usami Renko
--------------------------------------------------------

ability_thdots_renko01 = {}
ability_thdots_renko02 = {}
ability_thdots_renko03 = {}
ability_thdots_renkoEx = {}
ability_thdots_renko04 = {}

AbilityRenko = AbilityRenko or {}

local RENKO_EX_ABILITY = "ability_thdots_renkoEx"
local RENKO_EX_HANDLER = "modifier_ability_thdots_renkoEx_handler"
local RENKO_EX_STACK = "modifier_ability_thdots_renkoEx_stack"
local RENKO_EX_BONUS_DAMAGE = "modifier_ability_thdots_renkoEx_bonus_damage"
local RENKO_EX_SHARED_BONUS_DAMAGE = "modifier_ability_thdots_renkoEx_shared_bonus_damage"
-- 4技能预留独立光晕效果，当前不使用卡尔环绕球。
local RENKO_EX_RECORD_PARTICLES = {
	[1] = "particles/units/heroes/hero_invoker/invoker_exort_orb.vpcf",
	[2] = "particles/units/heroes/hero_invoker/invoker_wex_orb.vpcf",
	[3] = "particles/units/heroes/hero_invoker/invoker_quas_orb.vpcf",
}
local RENKO_EX_ORB_HEIGHT = 112
local RENKO_EX_ORB_UPDATE_INTERVAL = 0.03
local RENKO_EX_ORB_TRACKS = {
	[1] = { radius = 96, speed = 2.40, tilt = 0, phase = 0 },
	[2] = { radius = 112, speed = 2.75, tilt = math.rad(35), phase = math.pi * 2 / 3 },
	[3] = { radius = 84, speed = 2.05, tilt = -math.rad(35), phase = math.pi * 4 / 3 },
}
local RENKO_01_MANAVOID_PARTICLE = "particles/units/heroes/hero_antimage/antimage_manavoid.vpcf"
local RENKO_01_MANAVOID_SOUND = "Hero_Antimage.ManaVoid"
local RENKO_02_PROJECTILE_PARTICLE = "models/toyohime/fx/toyohime_cast1.vpcf"
local RENKO_02_PROJECTILE_SOUND = "Hero_DrowRanger.Silence"
local RENKO_02_WEAKEN = "modifier_ability_thdots_renko02_weaken"
local RENKO_02_ARMOR_REDUCTION = "modifier_ability_thdots_renko02_armor_reduction"
local RENKO_02_STRONG_SLOW = "modifier_ability_thdots_renko02_strong_slow"
local RENKO_03_STOMP_PARTICLE = "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf"
local RENKO_03_STOMP_SOUND = "Hero_Centaur.HoofStomp"
local RENKO_03_ATTACK_BUFF = "modifier_ability_thdots_renko03_attack_buff"
local RENKO_03_DEFENSE_BUFF = "modifier_ability_thdots_renko03_defense_buff"
local RENKO_03_OMNIVAMP_BUFF = "modifier_ability_thdots_renko03_omnivamp_buff"
local RENKO_04_CAST_PARTICLE = "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf"
local RENKO_04_STATUS_EFFECT = "particles/status_fx/status_effect_gods_strength.vpcf"
local RENKO_04_HERO_EFFECT = "particles/units/heroes/hero_sven/sven_gods_strength_hero_effect.vpcf"
local RENKO_04_AMBIENT_EFFECT = "particles/units/heroes/hero_sven/sven_spell_gods_strength_ambient.vpcf"
local RENKO_04_SOUND = "Hero_Sven.GodsStrength"
local RENKO_04_PHYSICAL_DAMAGE = "modifier_ability_thdots_renko04_physical_damage"
local RENKO_04_CRIT = "modifier_ability_thdots_renko04_crit"
local RENKO_TALENT_03 = "special_bonus_unique_renko_3"
local RENKO_TALENT_04 = "special_bonus_unique_renko_4"
local RENKO_TALENT_05 = "special_bonus_unique_renko_5"

LinkLuaModifier(RENKO_EX_HANDLER, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_EX_STACK, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_EX_BONUS_DAMAGE, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_EX_SHARED_BONUS_DAMAGE, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_02_WEAKEN, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_02_ARMOR_REDUCTION, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_02_STRONG_SLOW, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_03_ATTACK_BUFF, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_03_DEFENSE_BUFF, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_03_OMNIVAMP_BUFF, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_04_PHYSICAL_DAMAGE, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(RENKO_04_CRIT, "scripts/vscripts/abilities/abilityrenko.lua", LUA_MODIFIER_MOTION_NONE)

local function RenkoGetExAbility(caster)
	if caster == nil or caster:IsNull() then return nil end
	local ability = caster:FindAbilityByName(RENKO_EX_ABILITY)
	if ability == nil or ability:GetLevel() < 1 then return nil end
	return ability
end

local function RenkoGetTalent(caster, talentName)
	if caster == nil or caster:IsNull() then return nil end
	local talent = caster:FindAbilityByName(talentName)
	if talent == nil or talent:GetLevel() < 1 then return nil end
	return talent
end

local function RenkoHasWanbaochui(caster)
	return caster ~= nil and not caster:IsNull() and caster:HasModifier("modifier_item_wanbaochui")
end

local function RenkoGetDisplayedAbilityTypes(caster, handler)
	local recordedAbilityTypes = handler.last_ability_types or {}
	if #recordedAbilityTypes == 0 and handler.last_ability_type ~= nil then
		recordedAbilityTypes = { handler.last_ability_type }
	end

	local displayCount = RenkoHasWanbaochui(caster) and 2 or 1
	local abilityTypes = {}
	for index = 1, math.min(displayCount, #recordedAbilityTypes) do
		local abilityType = recordedAbilityTypes[index]
		if abilityType >= 1 and abilityType <= 4 then
			table.insert(abilityTypes, abilityType)
		end
	end
	return abilityTypes
end

local function RenkoGetRecordOrbPosition(caster, abilityType, phaseOffset)
	-- 三种记录球使用固定世界坐标轨道，英雄转身不会改变环绕轨迹。
	local track = RENKO_EX_ORB_TRACKS[abilityType] or RENKO_EX_ORB_TRACKS[1]
	local gameTime = GameRules ~= nil and GameRules:GetGameTime() or 0
	local angle = -gameTime * track.speed + track.phase + (phaseOffset or 0)
	local verticalCircleOffset = math.sin(angle) * track.radius
	return caster:GetAbsOrigin() + Vector(
		math.cos(angle) * track.radius,
		verticalCircleOffset * math.cos(track.tilt),
		RENKO_EX_ORB_HEIGHT + verticalCircleOffset * math.sin(track.tilt)
	)
end

local function RenkoCreateRecordEffect(caster, particleName)
	return ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, caster)
end

local function RenkoGetUniqueAbilityTypes(recordedAbilityTypes, maxCount)
	local abilityTypes = {}
	local seenTypes = {}
	for _, abilityType in ipairs(recordedAbilityTypes or {}) do
		if abilityType >= 1 and abilityType <= 4 and not seenTypes[abilityType] then
			table.insert(abilityTypes, abilityType)
			seenTypes[abilityType] = true
			if #abilityTypes >= maxCount then break end
		end
	end
	return abilityTypes
end

local function RenkoHasAbilityType(abilityTypes, abilityType)
	for _, recordedType in ipairs(abilityTypes or {}) do
		if recordedType == abilityType then return true end
	end
	return false
end

local function RenkoGetVisibleStackModifier(caster, ability)
	local modifier = caster:FindModifierByName(RENKO_EX_STACK)
	if modifier == nil then
		modifier = caster:AddNewModifier(caster, ability, RENKO_EX_STACK, {})
	end
	return modifier
end

local function RenkoGetIndependentDamageModifiers(caster, ignoredModifier)
	local modifiers = {}
	for _, modifier in ipairs(caster:FindAllModifiersByName(RENKO_EX_BONUS_DAMAGE)) do
		if modifier ~= ignoredModifier then table.insert(modifiers, modifier) end
	end
	return modifiers
end

local function RenkoRefreshVisibleStackModifier(caster, ability, ignoredModifier)
	if caster == nil or caster:IsNull() then return end

	local sharedModifier = caster:FindModifierByName(RENKO_EX_SHARED_BONUS_DAMAGE)
	if sharedModifier == ignoredModifier then sharedModifier = nil end
	local stackCount = sharedModifier ~= nil and sharedModifier:GetStackCount() or #RenkoGetIndependentDamageModifiers(caster, ignoredModifier)
	local visibleModifier = caster:FindModifierByName(RENKO_EX_STACK)
	if stackCount <= 0 then
		if visibleModifier ~= nil then visibleModifier:Destroy() end
		return
	end

	visibleModifier = visibleModifier or RenkoGetVisibleStackModifier(caster, ability)
	if visibleModifier ~= nil then visibleModifier:SetStackCount(stackCount) end
end

local function RenkoGetExStackLimit(ability)
	return math.max(0, ability:GetSpecialValueFor("max_stack_count"))
end

local function RenkoHasShard(caster)
	return caster ~= nil and not caster:IsNull() and caster:HasModifier("modifier_item_aghanims_shard")
end

local function RenkoAddExDamageStack(caster, ability)
	local stackDuration = ability:GetSpecialValueFor("stack_duration")
	local stackLimit = RenkoGetExStackLimit(ability)
	if stackLimit <= 0 then return end

	local sharedModifier = caster:FindModifierByName(RENKO_EX_SHARED_BONUS_DAMAGE)
	if RenkoHasShard(caster) then
		local independentModifiers = RenkoGetIndependentDamageModifiers(caster)
		local currentCount = sharedModifier ~= nil and sharedModifier:GetStackCount() or #independentModifiers
		if sharedModifier == nil then
			sharedModifier = caster:AddNewModifier(caster, ability, RENKO_EX_SHARED_BONUS_DAMAGE, { duration = stackDuration })
		end
		if sharedModifier == nil then return end

		-- 灵异珠首次施法时合并旧独立层；之后所有层数共享同一计时。
		sharedModifier:SetStackCount(math.min(currentCount + 1, stackLimit))
		for _, modifier in ipairs(independentModifiers) do
			modifier:Destroy()
		end
		sharedModifier:SetDuration(stackDuration, true)
	else
		if sharedModifier ~= nil then
			-- 兼容调试移除灵异珠：按共享层的剩余时间还原为独立层。
			local sharedCount = math.min(sharedModifier:GetStackCount(), stackLimit)
			local remainingTime = math.max(sharedModifier:GetRemainingTime(), 0)
			sharedModifier:Destroy()
			for _ = 1, sharedCount do
				caster:AddNewModifier(caster, ability, RENKO_EX_BONUS_DAMAGE, { duration = remainingTime })
			end
		end

		if #RenkoGetIndependentDamageModifiers(caster) < stackLimit then
			caster:AddNewModifier(caster, ability, RENKO_EX_BONUS_DAMAGE, { duration = stackDuration })
		end
	end

	RenkoRefreshVisibleStackModifier(caster, ability)
end

function AbilityRenko:GetLastAbilityType(caster)
	local handler = caster:FindModifierByName(RENKO_EX_HANDLER)
	if handler == nil then return nil end
	return handler.last_ability_type
end

function AbilityRenko:RefreshRecordEffects(caster)
	if not IsServer() or caster == nil or caster:IsNull() then return end

	local handler = caster:FindModifierByName(RENKO_EX_HANDLER)
	if handler ~= nil then handler:RefreshRecordEffects() end
end

function AbilityRenko:RecordSpell(ability, abilityType)
	if not IsServer() then return end

	local caster = ability:GetCaster()
	if caster == nil then return end

	local exAbility = RenkoGetExAbility(caster)
	if exAbility == nil then return end

	local handler = caster:FindModifierByName(RENKO_EX_HANDLER)
	if handler == nil then
		handler = caster:AddNewModifier(caster, exAbility, RENKO_EX_HANDLER, {})
	end
	if handler == nil then return end

	-- 始终保留最近两次原始记录；只有万宝槌会读取第二格，重复类型只触发一次。
	local recordedAbilityTypes = handler.last_ability_types or {}
	if #recordedAbilityTypes == 0 and handler.last_ability_type ~= nil then
		recordedAbilityTypes = { handler.last_ability_type }
	end
	local maxEffectCount = RenkoHasWanbaochui(caster) and 2 or 1
	local previousAbilityTypes = RenkoGetUniqueAbilityTypes(recordedAbilityTypes, maxEffectCount)
	ability.renko_previous_ability_type = previousAbilityTypes[1]
	ability.renko_previous_ability_types = previousAbilityTypes

	local newRecordedAbilityTypes = { abilityType }
	for _, recordedType in ipairs(recordedAbilityTypes) do
		if #newRecordedAbilityTypes >= 2 then break end
		table.insert(newRecordedAbilityTypes, recordedType)
	end
	handler.last_ability_types = newRecordedAbilityTypes
	handler.last_ability_type = abilityType

	AbilityRenko:RefreshRecordEffects(caster)
	RenkoAddExDamageStack(caster, exAbility)

	return previousAbilityTypes
end

function AbilityRenko:ReduceOtherBasicCooldowns(caster, usedAbilityName)
	if not IsServer() or caster == nil or caster:IsNull() then return end
	if not caster:HasModifier(RENKO_04_PHYSICAL_DAMAGE) then return end

	local talent = RenkoGetTalent(caster, RENKO_TALENT_03)
	if talent == nil then return end

	local cooldownReduction = talent:GetSpecialValueFor("value")
	for _, abilityName in pairs({ "ability_thdots_renko01", "ability_thdots_renko02", "ability_thdots_renko03" }) do
		if abilityName ~= usedAbilityName then
			local ability = caster:FindAbilityByName(abilityName)
			if ability ~= nil and ability:GetLevel() > 0 then
				local remainingCooldown = ability:GetCooldownTimeRemaining()
				if remainingCooldown > 0 then
					ability:EndCooldown()
					remainingCooldown = remainingCooldown - cooldownReduction
					if remainingCooldown > 0 then
						ability:StartCooldown(remainingCooldown)
					end
				end
			end
		end
	end
end

local function Renko01FindUnits(caster, center, targetType, radius)
	return FindUnitsInRadius(
		caster:GetTeam(),
		center,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		targetType,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
end

local function Renko01FindRandomTarget(caster, radius)
	local heroes = Renko01FindUnits(caster, caster:GetAbsOrigin(), DOTA_UNIT_TARGET_HERO, radius)
	if #heroes > 0 then
		return heroes[RandomInt(1, #heroes)]
	end

	local units = Renko01FindUnits(caster, caster:GetAbsOrigin(), DOTA_UNIT_TARGET_BASIC, radius)
	if #units > 0 then
		return units[RandomInt(1, #units)]
	end

	return nil
end

local function Renko01CreateManaVoidParticle(target, radius)
	local effectIndex = ParticleManager:CreateParticle(RENKO_01_MANAVOID_PARTICLE, PATTACH_POINT_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(effectIndex, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin(), true)
	if radius ~= nil and radius > 0 then
		ParticleManager:SetParticleControl(effectIndex, 1, Vector(radius, 0, 0))
	end
	ParticleManager:ReleaseParticleIndex(effectIndex)
end

local function Renko01DealDamage(ability, caster, target, damage)
	local damageTable = {
		ability = ability,
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = ability:GetAbilityDamageType(),
		damage_flags = ability:GetAbilityTargetFlags(),
	}
	UnitDamageTarget(damageTable)
end

local function Renko01BlinkToTarget(caster, target)
	local direction = caster:GetAbsOrigin() - target:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() < 1 then
		direction = caster:GetForwardVector() * -1
	end
	direction = direction:Normalized()

	local landingPoint = target:GetAbsOrigin() + direction * 128
	ProjectileManager:ProjectileDodge(caster)
	FindClearSpaceForUnit(caster, landingPoint, true)
	ResolveNPCPositions(caster:GetAbsOrigin(), 128)
end

local function Renko04IsHeroControlledUnit(caster, unit)
	if unit == nil or unit:IsNull() or unit:IsBuilding() then return false end
	if unit:IsHero() then return true end

	local playerId = unit:GetPlayerOwnerID()
	if playerId == nil or playerId < 0 then return false end

	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	if hero == nil or hero:IsNull() or not hero:IsHero() then return false end
	return hero:GetTeamNumber() == caster:GetTeamNumber()
end

local function Renko04ApplyPhysicalDamageBuff(ability, caster, target, duration, physicalDamageBonusPct)
	local modifier = target:AddNewModifier(caster, ability, RENKO_04_PHYSICAL_DAMAGE, {
		duration = duration,
		physical_damage_bonus_pct = physicalDamageBonusPct,
	})
	if modifier ~= nil then
		modifier:SetStackCount(math.floor(physicalDamageBonusPct + 0.5))
	end
end

function ability_thdots_renko01:OnSpellStart()
	local caster = self:GetCaster()
	local previousAbilityTypes = AbilityRenko:RecordSpell(self, 1) or {}
	AbilityRenko:ReduceOtherBasicCooldowns(caster, self:GetAbilityName())
	local searchRadius = self:GetSpecialValueFor("search_radius")
	local aoeRadius = self:GetSpecialValueFor("aoe_radius")
	local target = Renko01FindRandomTarget(caster, searchRadius)

	if target == nil then
		EmitSoundOn(RENKO_01_MANAVOID_SOUND, caster)
		return
	end

	local damage = self:GetSpecialValueFor("damage") + caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("attack_damage_factor")
	local damageMultiplier = 1
	if RenkoHasAbilityType(previousAbilityTypes, 2) then
		damageMultiplier = damageMultiplier + 1
	end
	if RenkoHasAbilityType(previousAbilityTypes, 4) then
		damageMultiplier = damageMultiplier + 3
	end
	damage = damage * damageMultiplier

	EmitSoundOn(RENKO_01_MANAVOID_SOUND, target)
	local hasAoeEffect = RenkoHasAbilityType(previousAbilityTypes, 3)
	Renko01CreateManaVoidParticle(target, hasAoeEffect and aoeRadius or 0)

	if hasAoeEffect then
		local targets = Renko01FindUnits(caster, target:GetAbsOrigin(), DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, aoeRadius)
		for _, unit in pairs(targets) do
			Renko01DealDamage(self, caster, unit, damage)
		end
	else
		Renko01DealDamage(self, caster, target, damage)
	end

	if RenkoHasAbilityType(previousAbilityTypes, 1) and target ~= nil and not target:IsNull() then
		Renko01BlinkToTarget(caster, target)
	end
end

function ability_thdots_renko02:OnSpellStart()
	local caster = self:GetCaster()
	local previousAbilityTypes = AbilityRenko:RecordSpell(self, 2) or {}
	AbilityRenko:ReduceOtherBasicCooldowns(caster, self:GetAbilityName())
	local origin = caster:GetAbsOrigin()
	local targetPoint = self:GetCursorPosition()
	local direction = (targetPoint - origin) * Vector(1, 1, 0)
	if direction:Length2D() < 1 then
		direction = caster:GetForwardVector()
	end
	direction = direction:Normalized()

	EmitSoundOn(RENKO_02_PROJECTILE_SOUND, caster)

	local damage = self:GetSpecialValueFor("damage") + caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("attack_damage_factor")
	local projectile = {
		Ability = self,
		EffectName = RENKO_02_PROJECTILE_PARTICLE,
		vSpawnOrigin = origin,
		fDistance = self:GetSpecialValueFor("projectile_distance"),
		fStartRadius = self:GetSpecialValueFor("projectile_width"),
		fEndRadius = self:GetSpecialValueFor("projectile_width"),
		fExpireTime = GameRules:GetGameTime() + 10.0,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		bDeleteOnHit = false,
		vVelocity = direction * self:GetSpecialValueFor("projectile_speed"),
		bProvidesVision = false,
		ExtraData = {
			damage = damage,
			previous_ability_type_1 = previousAbilityTypes[1] or 0,
			previous_ability_type_2 = previousAbilityTypes[2] or 0,
		}
	}
	ProjectileManager:CreateLinearProjectile(projectile)
end

function ability_thdots_renko02:OnProjectileHit_ExtraData(target, location, data)
	if target == nil then return end

	local caster = self:GetCaster()
	local damageTable = {
		ability = self,
		victim = target,
		attacker = caster,
		damage = data.damage,
		damage_type = self:GetAbilityDamageType(),
		damage_flags = self:GetAbilityTargetFlags(),
	}
	UnitDamageTarget(damageTable)

	-- 投射物创建时已经快照历史，命中时不能读取可能已变化的当前 EX 记录。
	local previousAbilityTypes = RenkoGetUniqueAbilityTypes({
		data.previous_ability_type_1 or 0,
		data.previous_ability_type_2 or 0,
	}, 2)
	local hasTalent04 = RenkoGetTalent(caster, RENKO_TALENT_04) ~= nil
	if RenkoHasAbilityType(previousAbilityTypes, 1) then
		target:AddNewModifier(caster, self, RENKO_02_WEAKEN, { duration = self:GetSpecialValueFor("debuff_duration") })
	end
	if RenkoHasAbilityType(previousAbilityTypes, 2) then
		target:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
	end
	if RenkoHasAbilityType(previousAbilityTypes, 4) then
		target:AddNewModifier(caster, self, RENKO_02_STRONG_SLOW, { duration = self:GetSpecialValueFor("debuff_duration") })
	end

	-- 天赋4让2技能始终附带3技能的减甲效果；上一技能为3时只施加一次。
	if RenkoHasAbilityType(previousAbilityTypes, 3) or hasTalent04 then
		target:AddNewModifier(caster, self, RENKO_02_ARMOR_REDUCTION, { duration = self:GetSpecialValueFor("debuff_duration") })
	end
end

function ability_thdots_renko03:OnSpellStart()
	local caster = self:GetCaster()
	local previousAbilityTypes = AbilityRenko:RecordSpell(self, 3) or {}
	AbilityRenko:ReduceOtherBasicCooldowns(caster, self:GetAbilityName())
	local radius = self:GetSpecialValueFor("radius")
	if RenkoHasAbilityType(previousAbilityTypes, 3) then
		radius = radius * (1 + self:GetSpecialValueFor("radius_bonus_pct") / 100)
	end

	EmitSoundOn(RENKO_03_STOMP_SOUND, caster)
	local effectIndex = ParticleManager:CreateParticle(RENKO_03_STOMP_PARTICLE, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(effectIndex)

	local damage = self:GetSpecialValueFor("damage") + caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("attack_damage_factor")
	local targets = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local totalDamage = 0
	for _, target in pairs(targets) do
		local damageTable = {
			ability = self,
			victim = target,
			attacker = caster,
			damage = damage,
			damage_type = self:GetAbilityDamageType(),
			damage_flags = self:GetAbilityTargetFlags(),
		}
		totalDamage = totalDamage + (UnitDamageTarget(damageTable) or 0)
	end

	local buffDuration = self:GetSpecialValueFor("buff_duration")
	local hasTalent04 = RenkoGetTalent(caster, RENKO_TALENT_04) ~= nil
	if RenkoHasAbilityType(previousAbilityTypes, 1) then
		caster:AddNewModifier(caster, self, RENKO_03_ATTACK_BUFF, { duration = buffDuration })
	end
	if RenkoHasAbilityType(previousAbilityTypes, 3) then
		caster:GiveMana(totalDamage * self:GetSpecialValueFor("mana_restore_pct") / 100)
	end
	if RenkoHasAbilityType(previousAbilityTypes, 4) then
		caster:AddNewModifier(caster, self, RENKO_03_OMNIVAMP_BUFF, { duration = buffDuration })
	end

	-- 天赋4让3技能始终附带2技能的防御增益；上一技能为2时只施加一次。
	if RenkoHasAbilityType(previousAbilityTypes, 2) or hasTalent04 then
		caster:AddNewModifier(caster, self, RENKO_03_DEFENSE_BUFF, { duration = buffDuration })
	end
end

function ability_thdots_renko04:OnAbilityUpgrade(ability)
	if not IsServer() then return end
	if ability == nil or ability:IsNull() or ability:GetAbilityName() ~= RENKO_TALENT_05 then return end

	-- 学习天赋5时只补发新增充能，不重置已有充能的恢复进度。
	local maxCharges = self:GetMaxAbilityCharges(self:GetLevel())
	local currentCharges = self:GetCurrentAbilityCharges()
	if currentCharges < maxCharges then
		self:SetCurrentAbilityCharges(math.min(currentCharges + 1, maxCharges))
	end
end

function ability_thdots_renko04:OnSpellStart()
	local caster = self:GetCaster()
	local previousAbilityTypes = AbilityRenko:RecordSpell(self, 4) or {}
	local duration = self:GetSpecialValueFor("duration")
	local physicalDamageBonusPct = self:GetSpecialValueFor("physical_damage_bonus_pct")

	if RenkoHasAbilityType(previousAbilityTypes, 1) then
		physicalDamageBonusPct = physicalDamageBonusPct * (1 + self:GetSpecialValueFor("bonus_effect_pct") / 100)
	end
	if RenkoHasAbilityType(previousAbilityTypes, 2) then
		duration = duration * (1 + self:GetSpecialValueFor("duration_bonus_pct") / 100)
	end

	EmitSoundOn(RENKO_04_SOUND, caster)
	local effectIndex = ParticleManager:CreateParticle(RENKO_04_CAST_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(effectIndex)

	if RenkoHasAbilityType(previousAbilityTypes, 3) then
		local targets = FindUnitsInRadius(
			caster:GetTeam(),
			caster:GetAbsOrigin(),
			nil,
			self:GetSpecialValueFor("ally_radius"),
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)
		for _, target in pairs(targets) do
			if Renko04IsHeroControlledUnit(caster, target) then
				Renko04ApplyPhysicalDamageBuff(self, caster, target, duration, physicalDamageBonusPct)
			end
		end
	else
		Renko04ApplyPhysicalDamageBuff(self, caster, caster, duration, physicalDamageBonusPct)
	end

	if RenkoHasAbilityType(previousAbilityTypes, 4) then
		caster:AddNewModifier(caster, self, RENKO_04_CRIT, { duration = duration })
	end
end

function ability_thdots_renkoEx:GetIntrinsicModifierName()
	return RENKO_EX_HANDLER
end

function ability_thdots_renkoEx:OnInventoryContentsChanged()
	if not IsServer() then return end
	AbilityRenko:RefreshRecordEffects(self:GetCaster())
end

modifier_ability_thdots_renko02_weaken = {}
function modifier_ability_thdots_renko02_weaken:IsHidden() return false end
function modifier_ability_thdots_renko02_weaken:IsPurgable() return true end
function modifier_ability_thdots_renko02_weaken:RemoveOnDeath() return true end
function modifier_ability_thdots_renko02_weaken:IsDebuff() return true end

function modifier_ability_thdots_renko02_weaken:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_thdots_renko02_weaken:OnCreated()
	self.damage_reduce_pct = self:GetAbility():GetSpecialValueFor("damage_reduce_pct")
	self.move_slow_pct = self:GetAbility():GetSpecialValueFor("move_slow_pct")
end

function modifier_ability_thdots_renko02_weaken:OnRefresh()
	self:OnCreated()
end

function modifier_ability_thdots_renko02_weaken:GetModifierSpellAmplify_Percentage()
	return -(self.damage_reduce_pct or 0)
end

function modifier_ability_thdots_renko02_weaken:GetModifierMoveSpeedBonus_Percentage()
	return -(self.move_slow_pct or 0)
end

modifier_ability_thdots_renko02_armor_reduction = {}
function modifier_ability_thdots_renko02_armor_reduction:IsHidden() return false end
function modifier_ability_thdots_renko02_armor_reduction:IsPurgable() return true end
function modifier_ability_thdots_renko02_armor_reduction:RemoveOnDeath() return true end
function modifier_ability_thdots_renko02_armor_reduction:IsDebuff() return true end

function modifier_ability_thdots_renko02_armor_reduction:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_ability_thdots_renko02_armor_reduction:OnCreated()
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_ability_thdots_renko02_armor_reduction:OnRefresh()
	self:OnCreated()
end

function modifier_ability_thdots_renko02_armor_reduction:GetModifierPhysicalArmorBonus()
	return -(self.armor_reduction or 0)
end

modifier_ability_thdots_renko02_strong_slow = {}
function modifier_ability_thdots_renko02_strong_slow:IsHidden() return false end
function modifier_ability_thdots_renko02_strong_slow:IsPurgable() return true end
function modifier_ability_thdots_renko02_strong_slow:RemoveOnDeath() return true end
function modifier_ability_thdots_renko02_strong_slow:IsDebuff() return true end

function modifier_ability_thdots_renko02_strong_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_thdots_renko02_strong_slow:OnCreated()
	self.strong_move_slow_pct = self:GetAbility():GetSpecialValueFor("strong_move_slow_pct")
end

function modifier_ability_thdots_renko02_strong_slow:OnRefresh()
	self:OnCreated()
end

function modifier_ability_thdots_renko02_strong_slow:GetModifierMoveSpeedBonus_Percentage()
	return -(self.strong_move_slow_pct or 0)
end

modifier_ability_thdots_renko03_attack_buff = {}
function modifier_ability_thdots_renko03_attack_buff:IsHidden() return false end
function modifier_ability_thdots_renko03_attack_buff:IsPurgable() return true end
function modifier_ability_thdots_renko03_attack_buff:RemoveOnDeath() return true end
function modifier_ability_thdots_renko03_attack_buff:IsDebuff() return false end

function modifier_ability_thdots_renko03_attack_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
	}
end

function modifier_ability_thdots_renko03_attack_buff:OnCreated()
	self.bonus_attack_damage = self:GetAbility():GetSpecialValueFor("bonus_attack_damage")
	self.bonus_attack_speed_pct = self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
end

function modifier_ability_thdots_renko03_attack_buff:OnRefresh()
	self:OnCreated()
end

function modifier_ability_thdots_renko03_attack_buff:GetModifierPreAttack_BonusDamage()
	return self.bonus_attack_damage or 0
end

function modifier_ability_thdots_renko03_attack_buff:GetModifierAttackSpeedPercentage()
	return self.bonus_attack_speed_pct or 0
end

modifier_ability_thdots_renko03_defense_buff = {}
function modifier_ability_thdots_renko03_defense_buff:IsHidden() return false end
function modifier_ability_thdots_renko03_defense_buff:IsPurgable() return true end
function modifier_ability_thdots_renko03_defense_buff:RemoveOnDeath() return true end
function modifier_ability_thdots_renko03_defense_buff:IsDebuff() return false end

function modifier_ability_thdots_renko03_defense_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_ability_thdots_renko03_defense_buff:OnCreated()
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_magic_resistance = self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

function modifier_ability_thdots_renko03_defense_buff:OnRefresh()
	self:OnCreated()
end

function modifier_ability_thdots_renko03_defense_buff:GetModifierPhysicalArmorBonus()
	return self.bonus_armor or 0
end

function modifier_ability_thdots_renko03_defense_buff:GetModifierMagicalResistanceBonus()
	return self.bonus_magic_resistance or 0
end

modifier_ability_thdots_renko03_omnivamp_buff = {}
function modifier_ability_thdots_renko03_omnivamp_buff:IsHidden() return false end
function modifier_ability_thdots_renko03_omnivamp_buff:IsPurgable() return true end
function modifier_ability_thdots_renko03_omnivamp_buff:RemoveOnDeath() return true end
function modifier_ability_thdots_renko03_omnivamp_buff:IsDebuff() return false end

function modifier_ability_thdots_renko03_omnivamp_buff:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_ability_thdots_renko03_omnivamp_buff:OnCreated()
	self.omnivamp_pct = self:GetAbility():GetSpecialValueFor("omnivamp_pct")
end

function modifier_ability_thdots_renko03_omnivamp_buff:OnRefresh()
	self:OnCreated()
end

function modifier_ability_thdots_renko03_omnivamp_buff:OnTakeDamage(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if keys.unit == nil or keys.unit:IsNull() or keys.unit:IsBuilding() then return end
	if keys.damage <= 0 then return end
	local damageFlags = keys.damage_flags or DOTA_DAMAGE_FLAG_NONE
	if bit.band(damageFlags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then return end
	if bit.band(damageFlags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return end

	self:GetParent():Heal(keys.damage * (self.omnivamp_pct or 0) / 100, self:GetAbility())
end

modifier_ability_thdots_renko04_physical_damage = {}
function modifier_ability_thdots_renko04_physical_damage:IsHidden() return false end
function modifier_ability_thdots_renko04_physical_damage:IsPurgable() return false end
function modifier_ability_thdots_renko04_physical_damage:RemoveOnDeath() return true end
function modifier_ability_thdots_renko04_physical_damage:IsDebuff() return false end

function modifier_ability_thdots_renko04_physical_damage:DeclareFunctions()
	return {}
end

function modifier_ability_thdots_renko04_physical_damage:OnCreated(keys)
	keys = keys or {}
	self.physical_damage_bonus_pct = tonumber(keys.physical_damage_bonus_pct) or self:GetAbility():GetSpecialValueFor("physical_damage_bonus_pct")
	self:SetStackCount(math.floor(self.physical_damage_bonus_pct + 0.5))

	if not IsServer() then return end
	local ambientIndex = ParticleManager:CreateParticle(RENKO_04_AMBIENT_EFFECT, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:AddParticle(ambientIndex, false, false, -1, false, false)
end

function modifier_ability_thdots_renko04_physical_damage:OnRefresh(keys)
	keys = keys or {}
	self.physical_damage_bonus_pct = tonumber(keys.physical_damage_bonus_pct) or self:GetAbility():GetSpecialValueFor("physical_damage_bonus_pct")
	self:SetStackCount(math.floor(self.physical_damage_bonus_pct + 0.5))
end

function modifier_ability_thdots_renko04_physical_damage:GetEffectName()
	return RENKO_04_HERO_EFFECT
end

function modifier_ability_thdots_renko04_physical_damage:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ability_thdots_renko04_physical_damage:GetStatusEffectName()
	return RENKO_04_STATUS_EFFECT
end

modifier_ability_thdots_renko04_crit = {}
function modifier_ability_thdots_renko04_crit:IsHidden() return false end
function modifier_ability_thdots_renko04_crit:IsPurgable() return false end
function modifier_ability_thdots_renko04_crit:RemoveOnDeath() return true end
function modifier_ability_thdots_renko04_crit:IsDebuff() return false end

function modifier_ability_thdots_renko04_crit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
	}
end

function modifier_ability_thdots_renko04_crit:OnCreated()
	self.crit_chance = self:GetAbility():GetSpecialValueFor("crit_chance")
	self.crit_damage = self:GetAbility():GetSpecialValueFor("crit_damage")
end

function modifier_ability_thdots_renko04_crit:OnRefresh()
	self:OnCreated()
end

function modifier_ability_thdots_renko04_crit:GetModifierPreAttack_CriticalStrike()
	if RollPercentage(self.crit_chance or 0) then
		return self.crit_damage or 0
	end
	return nil
end

modifier_ability_thdots_renkoEx_handler = {}
function modifier_ability_thdots_renkoEx_handler:IsHidden() return true end
function modifier_ability_thdots_renkoEx_handler:IsPurgable() return false end
function modifier_ability_thdots_renkoEx_handler:RemoveOnDeath() return false end
function modifier_ability_thdots_renkoEx_handler:IsDebuff() return false end

function modifier_ability_thdots_renkoEx_handler:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_ability_thdots_renkoEx_handler:OnCreated()
	if not IsServer() then return end
	self.record_particle_indices = {}
	self:RefreshRecordEffects()
end

function modifier_ability_thdots_renkoEx_handler:OnDestroy()
	if not IsServer() then return end
	self:ClearRecordEffects()
end

function modifier_ability_thdots_renkoEx_handler:OnDeath(keys)
	if keys.unit ~= self:GetParent() then return end
	self:ClearRecordEffects()
end

function modifier_ability_thdots_renkoEx_handler:OnRespawn(keys)
	if keys.unit ~= self:GetParent() then return end
	self:RefreshRecordEffects()
end

function modifier_ability_thdots_renkoEx_handler:ClearRecordEffects()
	for _, recordEffect in ipairs(self.record_particle_indices or {}) do
		local particleIndex = type(recordEffect) == "table" and recordEffect.particleIndex or recordEffect
		if particleIndex ~= nil then
			ParticleManager:DestroyParticleSystem(particleIndex, true)
		end
	end
	self.record_particle_indices = {}
	self:StartIntervalThink(-1)
end

function modifier_ability_thdots_renkoEx_handler:UpdateRecordEffects()
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end

	for _, recordEffect in ipairs(self.record_particle_indices or {}) do
		local position = RenkoGetRecordOrbPosition(parent, recordEffect.abilityType, recordEffect.phaseOffset)
		ParticleManager:SetParticleControl(recordEffect.particleIndex, 1, position)
	end
end

function modifier_ability_thdots_renkoEx_handler:OnIntervalThink()
	self:UpdateRecordEffects()
end

function modifier_ability_thdots_renkoEx_handler:RefreshRecordEffects()
	if not IsServer() then return end

	self:ClearRecordEffects()
	local parent = self:GetParent()
	local typeOccurrences = {}
	for _, abilityType in ipairs(RenkoGetDisplayedAbilityTypes(parent, self)) do
		local particleName = RENKO_EX_RECORD_PARTICLES[abilityType]
		if particleName ~= nil then
			typeOccurrences[abilityType] = (typeOccurrences[abilityType] or 0) + 1
			local phaseOffset = (typeOccurrences[abilityType] - 1) * math.pi
			local particleIndex = RenkoCreateRecordEffect(parent, particleName)
			table.insert(self.record_particle_indices, {
				particleIndex = particleIndex,
				abilityType = abilityType,
				phaseOffset = phaseOffset,
			})
		end
	end
	self:UpdateRecordEffects()
	if #self.record_particle_indices > 0 then
		self:StartIntervalThink(RENKO_EX_ORB_UPDATE_INTERVAL)
	end
end

modifier_ability_thdots_renkoEx_stack = {}
function modifier_ability_thdots_renkoEx_stack:IsHidden() return self:GetStackCount() <= 0 end
function modifier_ability_thdots_renkoEx_stack:IsPurgable() return false end
function modifier_ability_thdots_renkoEx_stack:RemoveOnDeath() return true end
function modifier_ability_thdots_renkoEx_stack:IsDebuff() return false end

modifier_ability_thdots_renkoEx_bonus_damage = {}
function modifier_ability_thdots_renkoEx_bonus_damage:IsHidden() return true end
function modifier_ability_thdots_renkoEx_bonus_damage:IsPurgable() return false end
function modifier_ability_thdots_renkoEx_bonus_damage:RemoveOnDeath() return true end
function modifier_ability_thdots_renkoEx_bonus_damage:IsDebuff() return false end
function modifier_ability_thdots_renkoEx_bonus_damage:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_ability_thdots_renkoEx_bonus_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_ability_thdots_renkoEx_bonus_damage:OnCreated()
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")

	if not IsServer() then return end
	RenkoRefreshVisibleStackModifier(self:GetParent(), self:GetAbility())
end

function modifier_ability_thdots_renkoEx_bonus_damage:OnRefresh()
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_ability_thdots_renkoEx_bonus_damage:OnDestroy()
	if not IsServer() then return end
	RenkoRefreshVisibleStackModifier(self:GetParent(), self:GetAbility(), self)
end

function modifier_ability_thdots_renkoEx_bonus_damage:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage or 0
end

modifier_ability_thdots_renkoEx_shared_bonus_damage = {}
function modifier_ability_thdots_renkoEx_shared_bonus_damage:IsHidden() return true end
function modifier_ability_thdots_renkoEx_shared_bonus_damage:IsPurgable() return false end
function modifier_ability_thdots_renkoEx_shared_bonus_damage:RemoveOnDeath() return true end
function modifier_ability_thdots_renkoEx_shared_bonus_damage:IsDebuff() return false end

function modifier_ability_thdots_renkoEx_shared_bonus_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_ability_thdots_renkoEx_shared_bonus_damage:OnCreated()
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_ability_thdots_renkoEx_shared_bonus_damage:OnRefresh()
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_ability_thdots_renkoEx_shared_bonus_damage:OnDestroy()
	if not IsServer() then return end
	RenkoRefreshVisibleStackModifier(self:GetParent(), self:GetAbility(), self)
end

function modifier_ability_thdots_renkoEx_shared_bonus_damage:GetModifierPreAttack_BonusDamage()
	return (self.bonus_damage or 0) * self:GetStackCount()
end
