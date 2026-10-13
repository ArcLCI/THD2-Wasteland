if AbilityYuyuko == nil then
	AbilityYuyuko = class({})
end

ability_thdots_yuyuko01 = {}

function ability_thdots_yuyuko01:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local start_position = caster:GetOrigin()
	local end_position = self:GetCursorPosition()
	local direct = ((end_position - start_position) * Vector(1, 1, 0)):Normalized()
	local particle = "particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm.vpcf"

	caster:EmitSound("Hero_DeathProphet.CarrionSwarm")

	local speed = self:GetSpecialValueFor("speed")
	local start_radius = self:GetSpecialValueFor("start_radius")
	local end_radius = self:GetSpecialValueFor("end_radius")
	local bo = ProjectileManager:CreateLinearProjectile({
				Source = caster,
				Ability = self,
				vSpawnOrigin = caster:GetOrigin(),
				bDeleteOnHit = true,
			    iUnitTargetTeam	 	= self:GetAbilityTargetTeam(),
	   			iUnitTargetType 	= self:GetAbilityTargetType(),
				EffectName = "particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm_core01.vpcf",
				fDistance = self:GetSpecialValueFor("range"),
				fStartRadius = start_radius,
				fEndRadius = end_radius,
				fExpireTime = GameRules:GetGameTime() + 10.0,
				vVelocity = direct * speed,
				bReplaceExisting = false,
				bProvidesVision = false,	
				bHasFrontalCone = false,
			})
	Timer.Wait "DestroyFanProjectile" (1,
		function ()
			ProjectileManager:DestroyLinearProjectile(bo)
		end
	)
	self.particle = ParticleManager:CreateParticle(particle,PATTACH_WORLDORIGIN,nil)
	ParticleManager:SetParticleControl(self.particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.particle, 1, Vector(direct.x*speed,direct.y*speed,0))
	ParticleManager:SetParticleControl(self.particle, 2, Vector(200,200,100))
	ParticleManager:DestroyParticleSystemTime(self.particle,1)
end

function ability_thdots_yuyuko01:OnProjectileHit(hTarget, vLocation)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = hTarget
	local damage = self:GetAbilityDamage()
	if hTarget then
		local damageTable = {victim = target,
							damage = damage,
							damage_type = self:GetAbilityDamageType(),
							attacker = caster,
							ability = self
							}
		UnitDamageTarget(damageTable)

		local hitParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm_impact.vpcf",PATTACH_WORLDORIGIN,nil)
		ParticleManager:SetParticleControl(hitParticle, 0, hTarget:GetAttachmentOrigin(hTarget:ScriptLookupAttachment("attach_hitloc")))
		ParticleManager:DestroyParticle(hitParticle, false)
		ParticleManager:ReleaseParticleIndex(hitParticle)
	end
end

ability_thdots_yuyuko02 = {}

function ability_thdots_yuyuko02:GetAssociatedSecondaryAbilities()
	return "ability_thdots_yuyuko02_end"
end

function ability_thdots_yuyuko02:OnUpgrade()
	local caster  =	self:GetCaster()

	-- When you level up nightmare while it is active, don't level up nightmare end (cuz that's a bad idea)
	if caster:HasAbility("ability_thdots_yuyuko02_end") and caster:FindAbilityByName("ability_thdots_yuyuko02_end"):GetLevel() ~= 1 then
		caster:FindAbilityByName("ability_thdots_yuyuko02_end"):SetLevel(1)
	end
end

function ability_thdots_yuyuko02:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")
	if target:TriggerSpellAbsorb(self) then return end

	-- 防止施法者混乱导致不能正常切换技能
	if target:HasModifier("modifier_thdots_yuyuko02_buff") then
		target:RemoveModifierByName("modifier_thdots_yuyuko02_buff")
	end

	target:AddNewModifier(caster, self, "modifier_thdots_yuyuko02_buff", {Duration = duration * (1 - target:GetStatusResistance())})

	--替换技能
	local secAbility = caster:FindAbilityByName("ability_thdots_yuyuko02_end")

	if secAbility then
		caster:SwapAbilities(self:GetName(), secAbility:GetName(), false, true)
	end
end

modifier_thdots_yuyuko02_buff = {}
LinkLuaModifier("modifier_thdots_yuyuko02_buff","scripts/vscripts/abilities/abilityyuyuko.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuyuko02_buff:IsPurgable() 		 return true end
function modifier_thdots_yuyuko02_buff:RemoveOnDeath()		 return true end
function modifier_thdots_yuyuko02_buff:IsHidden()			 return false end
function modifier_thdots_yuyuko02_buff:IsDebuff()			 return true end
function modifier_thdots_yuyuko02_buff:CanParentBeAutoAttacked() return false end

function modifier_thdots_yuyuko02_buff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
function modifier_thdots_yuyuko02_buff:GetEffectName()
    return "particles/units/heroes/hero_bane/bane_nightmare.vpcf"
end

function modifier_thdots_yuyuko02_buff:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:StartIntervalThink(1)
	self.invulnerable = true
	self.damaged = 0

	EmitSoundOn("Hero_Bane.Nightmare", self.parent)
	EmitSoundOn("Hero_Bane.Nightmare.Loop", self.parent)
end

function modifier_thdots_yuyuko02_buff:OnDestroy()
	if not IsServer() then return end

	StopSoundOn("Hero_Bane.Nightmare.Loop", self.parent)
	EmitSoundOn("Hero_Bane.Nightmare.End", self.parent)

	-- Emit nightmare end sound effect
	EmitSoundOn("Hero_Bane.Nightmare.End", self.parent)

	local swap = true

	local units = FindUnitsInRadius(self.caster:GetTeamNumber(),
		self.caster:GetAbsOrigin(),
		nil,
		FIND_UNITS_EVERYWHERE, -- Global
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		FIND_ANY_ORDER,
	false)

	-- 检测场上是否有modifier
	for i,unit in pairs(units) do
		if unit:FindModifierByNameAndCaster("modifier_thdots_yuyuko02_buff", self.caster) then
			swap = false
		end
	end

	if swap then
		--替换技能
		local secAbility = self.caster:FindAbilityByName("ability_thdots_yuyuko02_end")

		if secAbility then
			self.caster:SwapAbilities(self.ability:GetName(), secAbility:GetName(), true, false)
		end
	end
end

function modifier_thdots_yuyuko02_buff:CheckState()
	return
	{
		[MODIFIER_STATE_NIGHTMARED] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVULNERABLE] = self.invulnerable,
		[MODIFIER_STATE_NO_HEALTH_BAR] = self.invulnerable,
	}
end
function modifier_thdots_yuyuko02_buff:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_ALLIED,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_thdots_yuyuko02_buff:OnIntervalThink()
	if not IsServer() then return end

	local damage_tabel = {
				victim 			= self:GetParent(),
				damage          = self.ability:GetSpecialValueFor("damage"),
				damage_type		= self.ability:GetAbilityDamageType(),
				damage_flags 	= self.ability:GetAbilityTargetFlags(),
				attacker 		= self.caster,
				ability 		= self.ability
			}
	self.invulnerable = false
	if self.parent:GetTeamNumber() == self.caster:GetTeamNumber() then return end
	ApplyDamage(damage_tabel)
end
function modifier_thdots_yuyuko02_buff:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_thdots_yuyuko02_buff:GetOverrideAnimationRate()
	return 0.5
end

function modifier_thdots_yuyuko02_buff:OnTakeDamage(keys)
	if not IsServer() then return end

	self.damaged = self.damaged + keys.damage
	if keys.unit == self:GetParent() and keys.attacker~=self:GetParent() and keys.attacker:IsHero() then
		if keys.attacker~=self.caster or (self.damaged >= self.ability:GetSpecialValueFor("wakeup_damage")) then
			self:Destroy()
		end
	end
end
function modifier_thdots_yuyuko02_buff:OnAttackStart( keys )
	if not IsServer() then return end

	local duration = self.ability:GetSpecialValueFor("duration")
	local duration_remaining = self:GetRemainingTime()
	if keys.target == self:GetParent() and keys.attacker~=self:GetParent() and keys.attacker:IsHero() then
		if keys.attacker~=self.caster then
			keys.attacker:AddNewModifier(self.caster, self.ability, "modifier_thdots_yuyuko02_buff", {Duration = (duration + duration_remaining) * (1 - keys.attacker:GetStatusResistance())})
			self:Destroy()
		end
	end
end
function modifier_thdots_yuyuko02_buff:OnAttackAllied(keys)
	if not IsServer() then return end

	self:OnAttackStart(keys)
end

ability_thdots_yuyuko02_end = {}

function ability_thdots_yuyuko02_end:ProcsMagicStick() return false end

function ability_thdots_yuyuko02_end:GetAssociatedPrimaryAbilities()
	return "ability_thdots_yuyuko02"
end

function ability_thdots_yuyuko02_end:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()

	-- Find ALL heroes nightmared
	local units = FindUnitsInRadius(caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		FIND_UNITS_EVERYWHERE, -- Global
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		FIND_ANY_ORDER,
		false)

	-- Stop all of the Nightmare modifiers
	for i,unit in pairs(units) do
		if unit:HasModifier("modifier_thdots_yuyuko02_buff") then
			unit:RemoveModifierByName("modifier_thdots_yuyuko02_buff")
		end
	end
end

ability_thdots_yuyuko03 = {}

function ability_thdots_yuyuko03:GetIntrinsicModifierName()
	return "modifier_thdots_yuyuko03_aura"
end

function ability_thdots_yuyuko03:GetCastRange( location , target)
	return self:GetSpecialValueFor("aura_radius")
end

function ability_thdots_yuyuko03:GetBehavior()
	if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AURA
	else
		return self.BaseClass.GetBehavior(self)
	end
end

function ability_thdots_yuyuko03:GetCooldown(level)
	if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
		return self.BaseClass.GetCooldown(self, level)
	else
		return 0
	end
end

function ability_thdots_yuyuko03:GetManaCost(level)
	if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
		return self.BaseClass.GetManaCost(self, level)
	else
		return 0
	end
end

function ability_thdots_yuyuko03:OnSpellStart()
	local caster = self:GetCaster()
	local heal_duration = self:GetSpecialValueFor("lyz_heal_duration")

	caster:EmitSound("Hero_Necrolyte.SpiritForm.Cast")

	caster:AddNewModifier(caster, self, "modifier_thdots_yuyuko03_aura_lyz", {duration = heal_duration})
end

modifier_thdots_yuyuko03_aura = {}
LinkLuaModifier("modifier_thdots_yuyuko03_aura", "scripts/vscripts/abilities/abilityyuyuko.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuyuko03_aura:GetAuraEntityReject(target) return false end
function modifier_thdots_yuyuko03_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_thdots_yuyuko03_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function modifier_thdots_yuyuko03_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_thdots_yuyuko03_aura:GetAuraSearchType()  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_thdots_yuyuko03_aura:GetModifierAura()  return "modifier_thdots_yuyuko03_aura_damage" end

function modifier_thdots_yuyuko03_aura:IsAura()
	return true
end

function modifier_thdots_yuyuko03_aura:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_thdots_yuyuko03_aura:IsHidden() return false end
--function modifier_thdots_yuyuko03_aura:GetEffectName() return "particles/auras/aura_heartstopper.vpcf" end
--function modifier_thdots_yuyuko03_aura:GetEffectAttachType() return PATTACH_POINT_FOLLOW end

function modifier_thdots_yuyuko03_aura:OnCreated()
	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.modifier_ghost_lead = "modifier_thdots_yuyuko03_stack"

	-- Ability specials
	self.regen_duration = self.ability:GetSpecialValueFor("regen_duration")
	self.hero_multiplier = self.ability:GetSpecialValueFor("hero_multiplier")
end

function modifier_thdots_yuyuko03_aura:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_thdots_yuyuko03_aura:OnRefresh()
	if IsServer() then
		self:OnCreated()
	end
end

function modifier_thdots_yuyuko03_aura:OnDeath(params)
	if IsServer() then
		local unit = params.unit

		if params.attacker == self:GetParent() then
			-- If this is an illusion, do nothing
			if not params.attacker:IsRealHero() then
				return nil
			end

			-- Initialize stacks
			local stacks = 1

			-- If the target was a real hero, increase stack count
			if unit:IsRealHero() then
				stacks = self.hero_multiplier
			end

			-- If the caster doesn't have the modifier, add it
			if not self.caster:HasModifier(self.modifier_ghost_lead) then
				self.caster:AddNewModifier(self.caster, self.ability, "modifier_thdots_yuyuko03_stack", {duration = self.regen_duration})
			end

			-- Increment stacks
			local modifier_ghost_lead_handler = self.caster:FindModifierByName(self.modifier_ghost_lead)
			if modifier_ghost_lead_handler then
				for i = 1, stacks do
					modifier_ghost_lead_handler:IncrementStackCount()
					modifier_ghost_lead_handler:ForceRefresh()
				end
			end
		end
	end
end

modifier_thdots_yuyuko03_stack = {}
LinkLuaModifier("modifier_thdots_yuyuko03_stack", "scripts/vscripts/abilities/abilityyuyuko.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuyuko03_stack:IsHidden() return false end
function modifier_thdots_yuyuko03_stack:IsPurgable() return false end
function modifier_thdots_yuyuko03_stack:IsDebuff() return false end

function modifier_thdots_yuyuko03_stack:OnCreated()
	if IsServer() then
		-- Ability properties
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.parent = self:GetParent()

		-- Ability specials
		self.regen_duration = self.ability:GetSpecialValueFor("regen_duration")
		self.mana_regen = self.ability:GetSpecialValueFor("mana_regen")					--modifier文本里面的%dMODIFIER_PROPERTY_MANA_REGEN_CONSTANT%貌似是引用客户端的数值
		self.health_regen = self.ability:GetSpecialValueFor("health_regen")				--而这里在服务端定义，客户端里面没有定义，因此这两个放在这没用	= =

		-- Initialize table
		self.stacks_table = {}

		-- Start thinking
		self:StartIntervalThink(0.1)
	end
end

function modifier_thdots_yuyuko03_stack:OnIntervalThink()
	if IsServer() then

		-- Check if there are any stacks left on the table
		if #self.stacks_table > 0 then

			-- For each stack, check if it is past its expiration time. If it is, remove it from the table
			for i = #self.stacks_table, 1, -1 do
				if self.stacks_table[i] + self.regen_duration < GameRules:GetGameTime() then
					table.remove(self.stacks_table, i)
				end
			end

			-- If after removing the stacks, the table is empty, remove the modifier.
			if #self.stacks_table == 0 then
				self:GetParent():RemoveModifierByName("modifier_thdots_yuyuko03_stack")

				-- Otherwise, set its stack count
			else
				self:SetStackCount(#self.stacks_table)
			end

			-- If there are no stacks on the table, just remove the modifier.
		else
			self:GetParent():RemoveModifierByName("modifier_thdots_yuyuko03_stack")
		end
	end
end

function modifier_thdots_yuyuko03_stack:OnRefresh()
	if IsServer() then
		-- Insert new stack values
		table.insert(self.stacks_table, GameRules:GetGameTime())
	end
end

function modifier_thdots_yuyuko03_stack:DeclareFunctions()
	return{
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
	}
end

function modifier_thdots_yuyuko03_stack:GetModifierConstantManaRegen()
	local mana_regen = self:GetAbility():GetSpecialValueFor("mana_regen")
	mana_regen = mana_regen * self:GetStackCount()
	return mana_regen
end

function modifier_thdots_yuyuko03_stack:GetModifierConstantHealthRegen()
	local health_regen = self:GetAbility():GetSpecialValueFor("health_regen")
	health_regen = health_regen * self:GetStackCount()
	return health_regen
end

modifier_thdots_yuyuko03_aura_damage = {}
LinkLuaModifier("modifier_thdots_yuyuko03_aura_damage", "scripts/vscripts/abilities/abilityyuyuko.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuyuko03_aura_damage:IsHidden()
	return false
end

function modifier_thdots_yuyuko03_aura_damage:IsDebuff()
	return true
end

function modifier_thdots_yuyuko03_aura_damage:IsPurgable()
	return false
end

function modifier_thdots_yuyuko03_aura_damage:OnCreated()
	if IsServer() then
		self.parent	= self:GetParent()

		self.radius = self:GetAbility():GetSpecialValueFor("radius")
		self.aura_damage = self:GetAbility():GetSpecialValueFor("aura_damage")
		self.lyz_damage_plus = self:GetAbility():GetSpecialValueFor("lyz_damage_plus")
		self.tick_rate	= self:GetAbility():GetSpecialValueFor("tick_rate")
		self.trance_reduce_pct = self:GetAbility():GetSpecialValueFor("trance_reduce_pct")

		self.lyz_heal_pct = self:GetAbility():GetSpecialValueFor("lyz_heal_pct")

		if not self.timer then
			self:StartIntervalThink(self.tick_rate)
			self.timer = true
		end
	end
end

function modifier_thdots_yuyuko03_aura_damage:OnIntervalThink()
	if IsServer() then
		local caster = self:GetCaster()

		-- Calculates damage
		local damage
		if caster:HasModifier("modifier_thdots_yuyuko03_aura_lyz") then
			damage = self.parent:GetMaxHealth() * ((self.aura_damage + self.lyz_damage_plus) * self.tick_rate) / 100	--lyz
		else
			damage = self.parent:GetMaxHealth() * (self.aura_damage * self.tick_rate) / 100													--normal
		end

		if self.parent:HasModifier("modifier_thdots_yuyuko02_buff") then					--受到恍惚影响时减少伤害
			damage = damage * self.trance_reduce_pct * 0.01
		end

		ApplyDamage({attacker = caster, victim = self.parent, ability = self:GetAbility(), damage = damage, damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})

		--Heal
		if caster:HasModifier("modifier_thdots_yuyuko03_aura_lyz") then
			local heal = damage * self.lyz_heal_pct / 100

			caster:HealWithParams(heal, self:GetAbility(), false, false, caster, false)
		end
	end
end

modifier_thdots_yuyuko03_aura_lyz = {}
LinkLuaModifier("modifier_thdots_yuyuko03_aura_lyz", "scripts/vscripts/abilities/abilityyuyuko.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuyuko03_aura_lyz:IsHidden()			return false end
function modifier_thdots_yuyuko03_aura_lyz:RemoveOnDeath()		return true end
function modifier_thdots_yuyuko03_aura_lyz:IsPurgable()			return true end
function modifier_thdots_yuyuko03_aura_lyz:IsDebuff()			return false end

function modifier_thdots_yuyuko03_aura_lyz:GetEffectName()
	return "particles/heroes/yuyuko/yuyuko_ghost_form_aura.vpcf"
end
function modifier_thdots_yuyuko03_aura_lyz:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW 
end

function modifier_thdots_yuyuko03_aura_lyz:CheckState()
	return{
		[MODIFIER_STATE_ATTACK_IMMUNE]	= true,
		[MODIFIER_STATE_DISARMED]		= true,
	}
end

function modifier_thdots_yuyuko03_aura_lyz:DeclareFunctions()
	return{
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_thdots_yuyuko03_aura_lyz:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_thdots_yuyuko03_aura_lyz:GetModifierMagicalResistanceBonus() return self:GetAbility():GetSpecialValueFor("lyz_magic_reduce_pct") end

ability_thdots_yuyuko04 = {}

function ability_thdots_yuyuko04:GetCooldown(level)
	local cd = self.BaseClass.GetCooldown(self, level)
	local telent = self:GetCaster():FindAbilityByName("special_bonus_unique_yuyuko_1")
	if telent then
		cd = cd + telent:GetSpecialValueFor("value")
	end
	return cd
end

-- function ability_thdots_yuyuko04:OnAbilityPhaseStart()
-- 	if not IsServer() then return end
-- 	OnYuyuko04PhaseStart({
-- 		ability = self,
-- 		caster = self:GetCaster()
-- 	})
-- end

function ability_thdots_yuyuko04:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	self.radius = self:GetSpecialValueFor("effect_radius")
	self.damage_radius = self:GetSpecialValueFor("damage_radius")
	self.damage_multi = self:GetSpecialValueFor("damage_multi")
	caster:EmitSound("Voice_Thdots_Yuyuko.AbilityYuyuko04")
	OnYuyuko04SpellStart({
		ability = self,
		caster = caster,
		DamageCount = self:GetSpecialValueFor("damage_count")
	})
	caster:AddNewModifier(caster, self, "modifier_thdots_yuyuko04_think_interval", {duration = 2.0})
end

function ability_thdots_yuyuko04:OnChannelFinish(interrupted)
	if not IsServer() then return end
	local caster = self:GetCaster()
	if interrupted then
		caster:RemoveModifierByName("modifier_thdots_yuyuko04_think_interval")
	end
	OnYuyuko04SpellRemove({
		ability = self,
		caster = caster
	})
end

modifier_thdots_yuyuko04_think_interval = {}
LinkLuaModifier("modifier_thdots_yuyuko04_think_interval", "scripts/vscripts/abilities/abilityyuyuko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_yuyuko04_think_interval:IsHidden() return false end
function modifier_thdots_yuyuko04_think_interval:IsPurgable() return false end
function modifier_thdots_yuyuko04_think_interval:RemoveOnDeath() return true end
function modifier_thdots_yuyuko04_think_interval:IsDebuff() return false end
function modifier_thdots_yuyuko04_think_interval:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_thdots_yuyuko04_think_interval:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.2)
end

function modifier_thdots_yuyuko04_think_interval:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	OnYuyuko04SpellThink({
		ability = ability,
		caster = caster,
		target_entities = targets,
		DamageRadius = ability.damage_radius,
		DamageMulti = ability.damage_multi
	})
end

function OnYuyuko04PhaseStart(keys)
end

function OnYuyuko04SpellStart(keys)
	local caster = keys.caster
	-- THDReduceCooldown(keys.ability,FindTelentValue(caster,"special_bonus_unique_yuyuko_1"))
	local vecCaster = caster:GetOrigin()
	local vecForward = caster:GetForwardVector() 
	local unit = CreateUnitByName(
		"npc_dota2x_unit_yuyuko_04"
		,caster:GetOrigin() - vecForward * 100
		,false
		,caster
		,caster
		,caster:GetTeam()
	)
	local ability_dummy_unit = unit:FindAbilityByName("ability_dummy_unit")
	ability_dummy_unit:SetLevel(1)
	
	unit:StartGesture(ACT_DOTA_IDLE)
	local forwardRad = GetRadBetweenTwoVec2D(caster:GetOrigin(),unit:GetOrigin())
	unit:SetForwardVector(Vector(math.cos(forwardRad+math.pi/2),math.sin(forwardRad+math.pi/2),0))

	local effectIndex2 = ParticleManager:CreateParticle("particles/heroes/yuyuko/ability_yuyuko_04_effect_d.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex2, 0, caster:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex2,false)

	unit:SetContextThink("ability_yuyuko_04_unit_remove", 
		function () 
			if GameRules:IsGamePaused() then return 0.03 end
			unit:RemoveSelf()
			return nil
		end, 
		2.0)

	keys.ability:SetContextNum("ability_yuyuko_04_time_count", keys.DamageCount, 0) 

	-- local particle_death = "particles/units/heroes/hero_skeletonking/wraith_king_reincarnate.vpcf"
	-- local particle_death_fx = ParticleManager:CreateParticle(particle_death, PATTACH_CUSTOMORIGIN, caster)
	-- ParticleManager:SetParticleAlwaysSimulate(particle_death_fx)
	-- ParticleManager:SetParticleControl(particle_death_fx, 0, caster:GetAbsOrigin())
	-- ParticleManager:SetParticleControl(particle_death_fx, 1, Vector(3, 0, 0))
	-- ParticleManager:SetParticleControl(particle_death_fx, 11, Vector(10, 0, 0))
	-- ParticleManager:ReleaseParticleIndex(particle_death_fx)
	-- local particle_death_2 = "particles/units/heroes/hero_necrolyte/necrolyte_spirit.vpcf"
	-- local particle_death_fx_2 = ParticleManager:CreateParticle(particle_death_2, PATTACH_CUSTOMORIGIN, caster)
	-- ParticleManager:SetParticleAlwaysSimulate(particle_death_fx_2)
	-- ParticleManager:SetParticleControl(particle_death_fx_2, 0, caster:GetAbsOrigin())
	-- ParticleManager:SetParticleControl(particle_death_fx_2, 2, Vector(500, 0, 0))
	-- ParticleManager:ReleaseParticleIndex(particle_death_fx_2)
end

function OnYuyuko04SpellRemove(keys)
	local caster = keys.caster
end

function OnYuyuko04SpellThink(keys)
	local caster = keys.caster
	local targets = keys.target_entities

	local timecount = keys.ability:GetContext("ability_yuyuko_04_time_count")
	if(timecount>=0)then
		timecount = timecount - 1
		keys.ability:SetContextNum("ability_yuyuko_04_time_count", timecount, 0) 
		for _,v in pairs(targets) do    
			if((v:GetTeam()~=caster:GetTeam()) and (v:IsInvulnerable() == false) and (v:IsBuilding() == false) and (v:IsAlive() == true) and (v:GetClassname()~="npc_dota_roshan")) and (v:GetClassname()~="trigger_dota") then
				local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yuyuko/ability_yuyuko_04_effect.vpcf", PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(effectIndex, 0, v:GetOrigin())
				ParticleManager:DestroyParticleSystem(effectIndex,false)

				effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yuyuko/ability_yuyuko_04_effect_a.vpcf", PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(effectIndex, 0, v:GetOrigin())
				ParticleManager:SetParticleControl(effectIndex, 5, v:GetOrigin())
				ParticleManager:DestroyParticleSystem(effectIndex,false)

				local effectIndex2 = ParticleManager:CreateParticle("particles/heroes/yuyuko/ability_yuyuko_04_effect_d.vpcf", PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(effectIndex2, 0, v:GetOrigin())
				ParticleManager:DestroyParticleSystem(effectIndex2,false)


				local vecV = v:GetOrigin()
				local deal_damage = (v:GetMaxHealth() - v:GetHealth())*keys.DamageMulti
				local boolDamage
				if((v:GetHealth()<=deal_damage) or (v:IsHero()==false))then
					boolDamage = true
				else
					boolDamage = false
				end

				if(v:IsHero()==false) then
					v:Kill(keys.ability,caster)
				else
					local damage_table = {
						ability = keys.ability,
						victim = v,
						attacker = caster,
						damage = deal_damage,
						damage_type = keys.ability:GetAbilityDamageType(), 
						damage_flags = 0
					}
					if caster:HasModifier("modifier_item_wanbaochui") then
						UtilStun:UnitStunTarget(caster,v,0.1, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilityyuyuko.lua:OnYuyuko04SpellThink:749")
					end
					UnitDamageTarget(damage_table)
				end

				if(boolDamage)then
					local DamageTargets = FindUnitsInRadius(
					   caster:GetTeam(),		--caster team
					   vecV,					--find position
					   nil,						--find entity
					   keys.DamageRadius,		--find radius
					   DOTA_UNIT_TARGET_TEAM_ENEMY,
					   keys.ability:GetAbilityTargetType(),
					   0, FIND_CLOSEST,
					   false
				    )
					for _,v in pairs(DamageTargets) do
					    local damage_table_death = {
					    	ability = keys.ability,
							victim = v,
							attacker = caster,
							damage = keys.ability:GetAbilityDamage(),
							damage_type = keys.ability:GetAbilityDamageType(), 
							damage_flags = 0
						}
						if caster:HasModifier("modifier_item_wanbaochui") then
							UtilStun:UnitStunTarget(caster,v,0.3, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilityyuyuko.lua:OnYuyuko04SpellThink:775")
						end
						UnitDamageTarget(damage_table_death)
					end
				end		

				return
			end
		end
		
	else
		caster:RemoveModifierByName("modifier_thdots_yuyuko04_think_interval") 
	end
end


--[[
function OnYuyukoKill(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local ability =keys.ability
	
	if caster:HasModifier("modifier_item_wanbaochui") and keys.unit:IsHero()==true and keys.unit:IsIllusion()==false then 
		if(caster:GetContext("Yuyuko_buff")==nil)then
			caster:SetContextNum("Yuyuko_buff",0,0)
			local stack_count = caster:GetContext("Yuyuko_buff")
		end
		if  caster:HasModifier("modifier_yuyuko_wanbaochui_buff")==false then
			stack_count = 2
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_yuyuko_wanbaochui_buff", {})
			caster:SetModifierStackCount("modifier_yuyuko_wanbaochui_buff", ability, stack_count)
		else
			stack_count = stack_count+1
			caster:SetModifierStackCount("modifier_yuyuko_wanbaochui_buff", ability, stack_count)
		end
	end
end
]]--