if AbilityYugi == nil then
	AbilityYugi = class({})
end

local function Yugi04_IsBotUnit(unit)
	if not unit or unit:IsNull() then return false end
	if THD2_IsBotHero ~= nil and THD2_IsBotHero(unit) then return true end

	local playerID = unit:GetPlayerOwnerID()
	if (not playerID or playerID < 0) and unit.GetPlayerID then
		playerID = unit:GetPlayerID()
	end
	if playerID and playerID >= 0 then
		if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:IsFakeClient(playerID) then
			return true
		end

		local player = PlayerResource:GetPlayer(playerID)
		if player and player:GetContext("PlayerIsBot") == 1 then
			return true
		end
	end

	local owner = unit:GetPlayerOwner()
	return owner and owner:GetContext("PlayerIsBot") == 1
end

local function Yugi04_ApplyBotCircle(caster, ability, target, duration)
	if Yugi04_IsBotUnit(target) then
		local center = target:GetAbsOrigin()
		target:AddNewModifier(caster, ability, "modifier_thdots_yugi04_bot_circle", {
			duration = duration,
			center_x = center.x,
			center_y = center.y,
			center_z = center.z,
		})
	end
end

function OnYugi03Damage(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	local Attacker = keys.attacker
	if(target:IsBuilding())then
		return
	end
	if not caster:HasModifier("ability_yugi03_animation") then return end
	caster:RemoveModifierByName("ability_yugi03_animation")

	local telentDamage = FindTelentValue(caster,"special_bonus_unique_yugi_1") * caster:GetStrength()

	local dealdamage = keys.BounsDamage + telentDamage

	if Attacker:IsRealHero() then
		dealdamage = dealdamage
	else dealdamage = dealdamage* 0.35
	end

	local damage_table = {
			ability = keys.ability,
			victim = target,
			attacker = caster,
			damage = dealdamage,
			damage_type = keys.ability:GetAbilityDamageType(),
	    	damage_flags = 0
	}
	local knockback_properties = {
			 center_x 			= caster:GetOrigin().x,
			 center_y 			= caster:GetOrigin().y,
			 center_z 			= caster:GetOrigin().z,
			 duration 			= 1 ,
			 knockback_duration = 1,
			 knockback_distance = keys.Distance,
			 knockback_height 	= 200,
		}
	UtilStun:UnitStunTarget( caster,target,1.0)
	target:AddNewModifier(caster, keys.ability, "modifier_thdots_yugi03_mark", {duration = 1})
	target:AddNewModifier(caster, self, "modifier_knockback", knockback_properties)
	target:EmitSound("Hero_Spirit_Breaker.GreaterBash")
	UnitDamageTarget(damage_table)
end

modifier_thdots_yugi03_mark = {}
LinkLuaModifier("modifier_thdots_yugi03_mark", "scripts/vscripts/abilities/abilityYugi.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_yugi03_mark:IsHidden()			return true end
function modifier_thdots_yugi03_mark:IsPurgable()		return true end
function modifier_thdots_yugi03_mark:RemoveOnDeath()	return true end
function modifier_thdots_yugi03_mark:IsDebuff()			return true end

function OnYugi03Refresh(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("ability_yugi03_animation")
end

function OnYugi03Fail(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	if not caster:HasModifier("ability_yugi03_animation") then return end
	caster:RemoveModifierByName("ability_yugi03_animation")
end

function OnYugiKill(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local ability = caster:FindAbilityByName("ability_thdots_yugi04")
	if FindTelentValue(caster,"special_bonus_unique_yugi_2") ~= 0 and keys.unit:IsHero()==true and keys.unit:HasModifier("modifier_illusion")==false then
		ability:EndCooldown()
	end
end

--[[
function OnYugi04SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	local vecTarget = target:GetOrigin()
	local ability_radius = keys.ability:GetSpecialValueFor("ability_radius")
	local ability_duration = keys.ability:GetSpecialValueFor("ability_duration")
	target:SetContextNum("ability_yugi04_point_x",vecTarget.x,0)
	target:SetContextNum("ability_yugi04_point_y",vecTarget.y,0)
	keys.ability.Iscandan = false
	if target:IsHero() and caster:GetName() == "npc_dota_hero_centaur" then
		if RollPercentage(2) then
			caster:EmitSound("Voice_Thdots_Yugi.AbilityYugi04_1")
			keys.ability.Iscandan = true
		else
			caster:EmitSound("Voice_Thdots_Yugi.AbilityYugi04")
		end
	end
	--以下是特效
	local coil_thinker = CreateModifierThinker(
		caster,
		keys.ability,
		"modifier_yugi04_effect",
		{duration = ability_duration},
		vecTarget,
		caster:GetTeamNumber(),
		false
	)

	local coil_modifier = target:AddNewModifier(caster, keys.ability, "modifier_imba_puck_dream_coil", 
		{
			duration		= ability_duration,
			coil_thinker	= coil_thinker:entindex()
		})

	local coil_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf", PATTACH_ABSORIGIN, coil_thinker)
	ParticleManager:SetParticleControlEnt(coil_particle, 0, coil_thinker, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", coil_thinker:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(coil_particle, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	local count = ability_duration

	target:SetContextThink("yugi04", 
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			local particle = ParticleManager:CreateParticle("particles/heroes/seija/seija04.vpcf", PATTACH_ABSORIGIN_FOLLOW, coil_thinker)
		    ParticleManager:SetParticleControl(particle, 2, Vector(ability_radius, ability_radius, ability_radius))
		    ParticleManager:ReleaseParticleIndex(particle)
		    count = count - 0.5
		    if count <= 0 then
		    	return nil
		    else
		    	return 0.5
		    end
		end,
		0)
end
--]]

modifier_yugi04_effect = {}
LinkLuaModifier("modifier_yugi04_effect", "scripts/vscripts/abilities/abilityYugi.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_yugi04_effect:GetEffectName()
	return "particles/units/heroes/hero_puck/puck_dreamcoil.vpcf"
end

--[[
function OnYugi04SpellThink(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	if(target:GetClassname()=="npc_dota_roshan")then
		return
	end
	if target:HasModifier("modifier_void_spirit_aether_remnant_pull") then
		target:RemoveModifierByName("modifier_void_spirit_aether_remnant_pull")
	end
	local vecPoint = Vector(target:GetContext("ability_yugi04_point_x"),target:GetContext("ability_yugi04_point_y"),0)
	local dis = GetDistanceBetweenTwoVec2D(target:GetOrigin(),vecPoint)




	if(dis>keys.AbilityRadius)then
		target:EmitSound("Ability.SandKing_CausticFinale")
		if target:IsRealHero() and keys.ability.Iscandan == true then
			target:EmitSound("Voice_Thdots_Yugi.AbilityYugi04_2")
			keys.ability.Iscandan = false
		end
		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex,false)

		-- local damage_table = {
		-- 	ability = keys.ability,
		-- 	victim = target,
		-- 	attacker = caster,
		-- 	damage = 99999,
		-- 	damage_type = DAMAGE_TYPE_HP_REMOVAL,
		-- 	damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_REFLECTION
		-- }
		-- UnitDamageTarget(damage_table)
		if(caster~=nil)then
			target:Kill(keys.ability, caster)
		else
			target:Kill(keys.ability, nil)
		end
	end
end

function OnYugi04SpellEnd(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	if not target or target:IsNull() then return end

	local dealdamage = target:GetMaxHealth() * (keys.DamagePercent+FindTelentValue(caster,"special_bonus_unique_yugi_3")) / 100
	local damage_table = {
		ability = keys.ability,
		victim = target,
		attacker = caster,
		damage = dealdamage,
		damage_type = keys.ability:GetAbilityDamageType(),
	    damage_flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	}
	target:EmitSound("Ability.SandKing_CausticFinale")
	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	UnitDamageTarget(damage_table)
end

function OnYugi04wanbaochui(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	-- if is_spell_blocked(target) then return end
	target:EmitSound("Hero_Axe.JungleWeapon.Dunk")
	local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yugi/yugi_slam.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	local effectIndex1 = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex1, 0, target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex1,false)
	keys.ability:ApplyDataDrivenModifier( caster, target, "modifier_thdots_yugi04_think_interval", {duration=keys.ability_duration} )
	if caster:HasModifier("modifier_item_wanbaochui") then
		local targets = FindUnitsInRadius(
			caster:GetTeam(),		
			target:GetOrigin(),	
			nil,					
			350,		
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			0,
			FIND_CLOSEST,
			false
		)
		for k,v in pairs(targets) do
			keys.ability:ApplyDataDrivenModifier( caster, v, "modifier_thdots_yugi04_think_interval", {duration=keys.ability_duration} )
			
			if v~=target then
				local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yugi/yugi_slam.vpcf", PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(effectIndex, 0, v:GetOrigin())
				ParticleManager:DestroyParticleSystem(effectIndex,false)
			end
		end
	end
end
--]]

ability_thdots_yugi04 = {}

function ability_thdots_yugi04:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	Timer.Wait 'yugi04_delay' (0.5,
	function ()
		local duration = self:GetSpecialValueFor("ability_duration")

		-- if is_spell_blocked(target) then return end
		target:EmitSound("Hero_Axe.JungleWeapon.Dunk")

		local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yugi/yugi_slam.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex,false)
		local effectIndex1 = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex1, 0, target:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex1,false)

		target:AddNewModifier( caster, self, "modifier_thdots_yugi04_think_interval", {duration = duration} )
		-- 仅对 bot 目标额外附加不可驱散减速。
		Yugi04_ApplyBotCircle(caster, self, target, duration)

		if caster:HasModifier("modifier_item_wanbaochui") then
			local targets = FindUnitsInRadius(
				caster:GetTeam(),		
				target:GetOrigin(),	
				nil,					
				350,		
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO,
				0,
				FIND_CLOSEST,
				false
			)
			for k,v in pairs(targets) do
				v:AddNewModifier( caster, self, "modifier_thdots_yugi04_think_interval", {duration = duration} )
				Yugi04_ApplyBotCircle(caster, self, v, duration)

				if v~=target then
					local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yugi/yugi_slam.vpcf", PATTACH_CUSTOMORIGIN, caster)
					ParticleManager:SetParticleControl(effectIndex, 0, v:GetOrigin())
					ParticleManager:DestroyParticleSystem(effectIndex,false)
				end
			end
		end
	end
	)

end

modifier_thdots_yugi04_think_interval = {}
LinkLuaModifier("modifier_thdots_yugi04_think_interval", "scripts/vscripts/abilities/abilityYugi.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_yugi04_think_interval:IsHidden()			return false end
function modifier_thdots_yugi04_think_interval:IsPurgable()			return false end
function modifier_thdots_yugi04_think_interval:RemoveOnDeath()		return true end
function modifier_thdots_yugi04_think_interval:IsDebuff()			return true end
function modifier_thdots_yugi04_think_interval:GetAttributes()		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_thdots_yugi04_bot_circle = {}
LinkLuaModifier("modifier_thdots_yugi04_bot_circle", "scripts/vscripts/abilities/abilityYugi.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_yugi04_bot_circle:IsHidden()		return true end
function modifier_thdots_yugi04_bot_circle:IsPurgable()		return false end
function modifier_thdots_yugi04_bot_circle:RemoveOnDeath()	return true end
function modifier_thdots_yugi04_bot_circle:IsDebuff()		return true end

function modifier_thdots_yugi04_bot_circle:OnCreated(params)
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.radius = 270
	self.displacement_threshold = 70
	if params and params.center_x and params.center_y then
		self.center_position = Vector(params.center_x, params.center_y, params.center_z or self.parent:GetAbsOrigin().z)
	else
		self.center_position = self.parent:GetAbsOrigin()
	end
	self.last_position = self.parent:GetAbsOrigin()
	self:StartIntervalThink(0.03)
end

function modifier_thdots_yugi04_bot_circle:OnIntervalThink()
	if not IsServer() then return end
	if not self.parent or self.parent:IsNull() then return end

	local current_position = self.parent:GetAbsOrigin()
	if self.parent:HasModifier("modifier_thdots_yugi03_mark") then
		-- Yugi 3 技能击退期间不限制移动，避免圆形边界抵消击退效果。
		self.last_position = current_position
		return
	end

	local step_distance = (current_position - self.last_position):Length2D()
	if step_distance > self.displacement_threshold then
		-- 大位移视为位移/瞬移技能，不阻止技能效果，但圆心仍保持 4 技能施放时的位置。
		self.last_position = current_position
		return
	end

	local offset = current_position - self.center_position
	local distance_from_center = offset:Length2D()
	if distance_from_center > self.radius then
		-- 普通移动越界时夹回圆形边缘，圆内移动不受影响。
		local direction = offset:Normalized()
		local clamped_position = self.center_position + direction * self.radius
		clamped_position.z = GetGroundHeight(clamped_position, self.parent)
		self.parent:SetAbsOrigin(clamped_position)
		current_position = clamped_position
	end

	self.last_position = current_position
end

function modifier_thdots_yugi04_bot_circle:OnDestroy()
	if not IsServer() then return end
	if self.parent and not self.parent:IsNull() then
		self.parent:SetUnitOnClearGround()
	end
end

function modifier_thdots_yugi04_think_interval:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.target = self:GetParent()
	self.ability = self:GetAbility()

	local vecTarget = self.target:GetOrigin()
	self.AbilityRadius = self.ability:GetSpecialValueFor("ability_radius")
	local ability_duration = self.ability:GetSpecialValueFor("ability_duration")
	self.target:SetContextNum("ability_yugi04_point_x",vecTarget.x,0)
	self.target:SetContextNum("ability_yugi04_point_y",vecTarget.y,0)
	self.ability.Iscandan = false
	if self.target:IsHero() and self.caster:GetName() == "npc_dota_hero_centaur" then
		if RollPercentage(2) then
			self.caster:EmitSound("Voice_Thdots_Yugi.AbilityYugi04_1")
			self.ability.Iscandan = true
		else
			self.caster:EmitSound("Voice_Thdots_Yugi.AbilityYugi04")
		end
	end
	--以下是特效
	local coil_thinker = CreateModifierThinker(
		self.caster,
		self.ability,
		"modifier_yugi04_effect",
		{duration = ability_duration},
		vecTarget,
		self.caster:GetTeamNumber(),
		false
	)

	local coil_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf", PATTACH_ABSORIGIN, coil_thinker)
	ParticleManager:SetParticleControlEnt(coil_particle, 0, coil_thinker, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", coil_thinker:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(coil_particle, 1, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), true)
	local count = ability_duration

	self.target:SetContextThink("yugi04", 
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			local particle = ParticleManager:CreateParticle("particles/heroes/seija/seija04.vpcf", PATTACH_ABSORIGIN_FOLLOW, coil_thinker)
		    ParticleManager:SetParticleControl(particle, 2, Vector(self.AbilityRadius, self.AbilityRadius, self.AbilityRadius))
		    ParticleManager:ReleaseParticleIndex(particle)
		    count = count - 0.5
		    if count <= 0 then
		    	return nil
		    else
		    	return 0.5
		    end
		end,
		0)

	self:StartIntervalThink(0.1)
end

function modifier_thdots_yugi04_think_interval:OnIntervalThink()
	if not IsServer() then return end

	if(self.target:GetClassname()=="npc_dota_roshan")then
		return
	end
	if self.target:HasModifier("modifier_void_spirit_aether_remnant_pull") then
		self.target:RemoveModifierByName("modifier_void_spirit_aether_remnant_pull")
	end

	if not self.target:HasModifier("modifier_thdots_yugi04_motion_control_mark") then
		self.target:AddNewModifier(self.caster, self.ability, "modifier_thdots_yugi04_motion_control_mark", {duration = self:GetRemainingTime()})
	end

	local vecPoint = Vector(self.target:GetContext("ability_yugi04_point_x"),self.target:GetContext("ability_yugi04_point_y"),0)
	local dis = GetDistanceBetweenTwoVec2D(self.target:GetOrigin(),vecPoint)


	if(dis>self.AbilityRadius)then
		self.target:EmitSound("Ability.SandKing_CausticFinale")
		if self.target:IsRealHero() and self.ability.Iscandan == true then
			self.target:EmitSound("Voice_Thdots_Yugi.AbilityYugi04_2")
			self.ability.Iscandan = false
		end
		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
		ParticleManager:SetParticleControl(effectIndex, 0, self.target:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex,false)

		-- local damage_table = {
		-- 	ability = keys.ability,
		-- 	victim = target,
		-- 	attacker = caster,
		-- 	damage = 99999,
		-- 	damage_type = DAMAGE_TYPE_HP_REMOVAL,
		-- 	damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_REFLECTION
		-- }
		-- UnitDamageTarget(damage_table)
		if(self.caster~=nil)then
			self.target:Kill(self.ability, self.caster)
		else
			self.target:Kill(self.ability, nil)
		end
	end
end

function modifier_thdots_yugi04_think_interval:OnDestroy()
	if not IsServer() then return end

	if not self.target or self.target:IsNull() then return end

	self.target:EmitSound("Hero_Axe.JungleWeapon.Dunk")

	local dealdamage = self.target:GetMaxHealth() * (self.ability:GetSpecialValueFor("damage_percent")) / 100
	local damage_table = {
		ability = self.ability,
		victim = self.target,
		attacker = self.caster,
		damage = dealdamage,
		damage_type = self.ability:GetAbilityDamageType(),
		damage_flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	}
	self.target:EmitSound("Ability.SandKing_CausticFinale")
	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
	ParticleManager:SetParticleControl(effectIndex, 0, self.target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	UnitDamageTarget(damage_table)
end

modifier_thdots_yugi04_motion_control_mark = {}
LinkLuaModifier("modifier_thdots_yugi04_motion_control_mark", "scripts/vscripts/abilities/abilityYugi.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yugi04_motion_control_mark:IsHidden()			return true end
function modifier_thdots_yugi04_motion_control_mark:IsPurgable()		return true end
function modifier_thdots_yugi04_motion_control_mark:RemoveOnDeath()		return true end
function modifier_thdots_yugi04_motion_control_mark:IsDebuff()			return true end
function modifier_thdots_yugi04_motion_control_mark:GetAttributes()		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_thdots_yugi04_motion_control_mark:CheckState()
	local state = {
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
	}

	if not self:GetParent():HasModifier("modifier_thdots_yugi03_mark") then
		return state
	else
		return
	end
end
