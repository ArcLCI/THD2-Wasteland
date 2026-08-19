if AbilitySuika == nil then
	AbilitySuika = class({})
end
function OnSuika02Switch(keys)
	local caster=keys.caster
	if caster:HasModifier("passive_suika02_attack") then
		caster:RemoveModifierByName("passive_suika02_attack")
	else 
		keys.ability:ApplyDataDrivenModifier(caster,caster,"passive_suika02_attack",{duration = -1})
	end
end

function OnSuika02Start(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
	local targets = keys.target_entities
	for _,v in pairs(targets) do
		local deal_damage = keys.ability:GetAbilityDamage()
		local damage_table = {
			    victim = v,
			    attacker = caster,
			    damage = deal_damage,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end
	caster:AddNewModifier(caster, keys.ability, "modifier_suika_sound", {})
end

modifier_suika_sound = {}
LinkLuaModifier("modifier_suika_sound","scripts/vscripts/abilities/abilitySuika.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_suika_sound:IsHidden() return true end
function modifier_suika_sound:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
	}
end

function modifier_suika_sound:OnAbilityExecuted(keys)
	if not IsServer() then return end
	local caster = self:GetParent()
	if caster ~= keys.unit then return end
	local ability = keys.ability
	if ability:GetName() == "tiny_toss" then
		caster:StopSound("Voice_Thdots_Suika.AbilitySuika01_1")
		caster:StopSound("Voice_Thdots_Suika.AbilitySuika01_2")
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil,1500,DOTA_UNIT_TARGET_TEAM_ENEMY,
								DOTA_UNIT_TARGET_HERO,0,0,false)
		if #targets ~= 0 then
			if RollPercentage(20) then
				caster:EmitSound("Voice_Thdots_Suika.AbilitySuika01_1")
			elseif RollPercentage(20) then
				caster:EmitSound("Voice_Thdots_Suika.AbilitySuika01_2")
			end
		end
	end
end
function OnSuika02ULTStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
	local targets = keys.target_entities
	local abilityLevel = caster:GetContext("ability_thdots_suika02_level") 
	for _,v in pairs(targets) do
		local deal_damage = 60 + (abilityLevel - 1) * 30
		local damage_table = {
				ability = keys.ability,
			    victim = v,
			    attacker = caster,
			    damage = deal_damage,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end
end

function OnSuika03Start(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_duration = ability:GetSpecialValueFor("ability_duration")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_suika03_states", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_suika03_think_interval", {})
	if caster:GetUnitName() == "npc_dota_hero_tidehunter" then
		caster:EmitSound("Voice_Thdots_Suika.AbilitySuika01")
	end
	if caster:HasModifier("modifier_item_wanbaochui") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_suika03_wanbaochui", {})
	end
	local ModifierSuika03=caster:FindModifierByName("modifier_thdots_Suika_04")
	if ModifierSuika03 then
		caster.suika03_time = ModifierSuika03:GetRemainingTime()
		ModifierSuika03:SetDuration(caster.suika03_time + ability_duration, true)
		if caster:FindModifierByName("modifier_thdots_Suika_04_telent") then
			caster:FindModifierByName("modifier_thdots_Suika_04_telent"):SetDuration(caster.suika03_time + ability_duration, true)
		end
	end
end

function OnSuika03End(keys)
	local caster = keys.caster
	local ability = keys.ability
	print("caster.suika03_time is:")
	print(caster.suika03_time)
end

local SUIKA03_AUTO_ATTACK_RADIUS = 500
local SUIKA03_AUTO_ATTACK_INTERVAL = 0.3
local SUIKA03_AUTO_ATTACK_FLAGS = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE +
	DOTA_UNIT_TARGET_FLAG_NO_INVIS +
	DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE +
	DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
-- 测试开关："auto_attack" 使用自动索敌，"hero_control" 交给施法者所属玩家控制。
SUIKA03_SUMMON_TEST_MODE = SUIKA03_SUMMON_TEST_MODE or "hero_control"

local function Suika03SetSummonTestMode(value)
	local mode = value ~= nil and string.lower(tostring(value)) or ""
	if mode == "auto" or mode == "auto_attack" then
		SUIKA03_SUMMON_TEST_MODE = "auto_attack"
	elseif mode == "control" or mode == "hero_control" then
		SUIKA03_SUMMON_TEST_MODE = "hero_control"
	else
		print("[Suika03] usage: thd_suika03_summon_mode auto/control")
		return
	end
	print("[Suika03] summon mode: " .. SUIKA03_SUMMON_TEST_MODE)
end

if IsServer() then
	Convars:RegisterCommand("thd_suika03_summon_mode", function(_, value)
		Suika03SetSummonTestMode(value)
	end, "Switch Suika03 summons between automatic attack and player control", 0)
end

local function Suika03IsValidAttackTarget(unit, target)
	return target ~= nil and not target:IsNull() and target:IsAlive() and
		(target:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() <= SUIKA03_AUTO_ATTACK_RADIUS
end

local function Suika03FindNearestTarget(unit, targetType)
	local targets = FindUnitsInRadius(
		unit:GetTeamNumber(),
		unit:GetAbsOrigin(),
		nil,
		SUIKA03_AUTO_ATTACK_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		targetType,
		SUIKA03_AUTO_ATTACK_FLAGS,
		FIND_CLOSEST,
		false
	)
	return targets[1]
end

local function Suika03StartAutoAttack(unit)
	unit:SetIdleAcquire(true)
	unit:SetContextThink(DoUniqueString("ability_thdots_suika03_summon_auto_attack"), function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then
			return nil
		end
		if GameRules:IsGamePaused() then
			return 0.03
		end

		local currentTarget = unit:GetAttackTarget()
		-- 三技能召唤物优先保持或寻找英雄目标，附近没有英雄时才攻击普通单位。
		if Suika03IsValidAttackTarget(unit, currentTarget) and currentTarget:IsHero() then
			return SUIKA03_AUTO_ATTACK_INTERVAL
		end

		local target = Suika03FindNearestTarget(unit, DOTA_UNIT_TARGET_HERO)
		if target == nil and not Suika03IsValidAttackTarget(unit, currentTarget) then
			target = Suika03FindNearestTarget(unit, DOTA_UNIT_TARGET_BASIC)
		end
		if target ~= nil and target ~= currentTarget then
			unit:MoveToTargetToAttack(target)
		elseif target == nil and not Suika03IsValidAttackTarget(unit, currentTarget) then
			unit:Stop()
		end
		return SUIKA03_AUTO_ATTACK_INTERVAL
	end, 0)
end

local function Suika03SetupSummonControl(unit, caster)
	if SUIKA03_SUMMON_TEST_MODE == "hero_control" then
		local playerID = caster:GetPlayerOwnerID()
		if playerID ~= nil and playerID >= 0 then
			unit:SetOwner(caster)
			unit:SetIdleAcquire(false)
			unit:SetControllableByPlayer(playerID, true)
			return
		end
	end
	Suika03StartAutoAttack(unit)
end

function OnSuika03Spawn(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local Caster = keys.caster
	local CasterName = Caster:GetClassname()
	local bonusAttack = 0 
	local attack = 0
	local health = Caster:GetMaxHealth()*0.4
    for i=0,5 do
        item = Caster:GetItemInSlot(i)
        if(item~=nil)then
            bonusAttack = item:GetSpecialValueFor("bonus_damage")
            if(bonusAttack~=nil)then
                attack = bonusAttack + attack
            end
        end
	end 
	local Damage = (Caster:GetAttackDamage()+attack)*0.4
	if CasterName == "npc_dota_hero_tidehunter" then
		local unit = CreateUnitByName(
			"npc_dota_suika_03_smallsuika"
			,caster:GetOrigin() - caster:GetForwardVector() * 100
			,false
			,caster
			,caster
			,caster:GetTeam()
			)
		keys.ability:ApplyDataDrivenModifier(Caster, unit, "modifier_thdots_suika03_unit", {})
		unit:SetBaseMaxHealth(health)
		unit:SetBaseDamageMax(Damage)
		unit:SetBaseDamageMin(Damage)
		Suika03SetupSummonControl(unit, Caster)
		unit:SetContextThink("npc_dota_suika_03_smallsuika_timer",
		function ()
			if GameRules:IsGamePaused() then return 0.03 end
			unit:ForceKill(true)
			unit:RemoveAllModifiers(0,true,true,true)
			unit:RemoveSelf() 
			return nil
		end, 5.0+FindTelentValue(Caster,"special_bonus_unique_suika_4")) 
	else
		local unit = CreateUnitByName(
			"npc_dota_satori_03_smallsatori"
			,caster:GetOrigin() - caster:GetForwardVector() * 100
			,false
			,caster
			,caster
			,caster:GetTeam()
			)
		keys.ability:ApplyDataDrivenModifier(Caster, unit, "modifier_thdots_suika03_unit", {})
		unit:SetBaseMaxHealth(health)
		unit:SetBaseDamageMax(Damage)
		unit:SetBaseDamageMin(Damage)
		Suika03SetupSummonControl(unit, Caster)
		unit:SetContextThink("npc_dota_suika_03_smallsuika_timer",
		function ()
			if GameRules:IsGamePaused() then return 0.03 end
			unit:ForceKill(true)
			unit:RemoveAllModifiers(0,true,true,true)
			unit:RemoveSelf() 
			return nil
		end, 5.0) 
	end	
end

function OnSuika04SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local Caster = keys.caster
	local CasterName = Caster:GetClassname()
	local ability = keys.ability
	-- duration 已由 KV 的 LinkedSpecialBonus 结算，避免再次手工叠加天赋。
	local duration = ability:GetSpecialValueFor("duration")
	if FindTelentValue(caster,"special_bonus_unique_suika_1")~=0 then --无视眩晕
		keys.ability:ApplyDataDrivenModifier( caster, caster, "modifier_thdots_Suika_04_telent", {duration = duration} )
	end
	if caster:HasModifier("modifier_item_wanbaochui") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_Suika_04_wanbaochui", {})
	end
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_Suika_04", {duration = duration})
	if CasterName == "npc_dota_hero_tidehunter" then
		caster:EmitSound("Voice_Thdots_Suika.AbilitySuika04")
		caster:SetModelScale(2.0)
		local ability = caster:FindAbilityByName("ability_thdots_suika02") 
		caster:SetContextNum("ability_thdots_suika02_level", ability:GetLevel(), 0) 
		caster:RemoveAbility("ability_thdots_suika02") 
		caster:RemoveModifierByName("passive_suika02_attack") 
		caster:AddAbility("ability_thdots_suika02_ult")
		local abilityUlt = caster:FindAbilityByName("ability_thdots_suika02_ult")
		abilityUlt:SetLevel(keys.ability:GetLevel())
	else
		caster:SetModelScale(2.0)
	end
	ability:SetActivated(false)
	-- caster:SetContextThink("ability_thdots_suika04_duration", 
	-- 	function ()
	-- 		if GameRules:IsGamePaused() then return 0.03 end
	-- 		if CasterName == "npc_dota_hero_tidehunter" then
	-- 			caster:RemoveAbility("ability_thdots_suika02_ult") 
	-- 			caster:AddAbility("ability_thdots_suika02")
	-- 			caster:RemoveModifierByName("passive_suika02_ult_attack") 
	-- 			local ability02 = caster:FindAbilityByName("ability_thdots_suika02")
	-- 			ability02:SetLevel(caster:GetContext("ability_thdots_suika02_level"))
	-- 			caster:SetModelScale(1.0)
	-- 		else
	-- 			caster:SetModelScale(1.0)
	-- 		end
			
	-- 		caster:RemoveModifierByName("modifier_thdots_Suika_04")
	-- 		caster:RemoveModifierByName("modifier_thdots_Suika_04_telent") 
	-- 		ability:SetActivated(true)
	-- 	end
	-- ,duration) 
end

function OnSuika04End( keys )
	local caster = EntIndexToHScript(keys.caster_entindex)
	local Caster = keys.caster
	local CasterName = Caster:GetClassname()
	local ability = keys.ability
	if CasterName == "npc_dota_hero_tidehunter" then
		caster:RemoveAbility("ability_thdots_suika02_ult") 
		caster:AddAbility("ability_thdots_suika02")
		caster:RemoveModifierByName("passive_suika02_ult_attack") 
		local ability02 = caster:FindAbilityByName("ability_thdots_suika02")
		ability02:SetLevel(caster:GetContext("ability_thdots_suika02_level"))
		caster:SetModelScale(1.0)
	else
		caster:SetModelScale(1.0)
	end	
	caster:RemoveModifierByName("modifier_thdots_Suika_04")
	caster:RemoveModifierByName("modifier_thdots_Suika_04_telent") 
	ability:SetActivated(true)
end

function Suika_04_wanbaochui_check(keys)
	local caster = keys.caster
	local casterName = caster:GetClassname()
	local abilityEx = nil
	if casterName == "npc_dota_hero_tidehunter" and caster:HasModifier("modifier_item_wanbaochui") then
		abilityEx = caster:FindAbilityByName("ability_thdots_suikaex")
		abilityEx:SetLevel(1)
	else
		abilityEx = caster:FindAbilityByName("ability_thdots_suikaex")
		if abilityEx == nil then return end
		abilityEx:SetLevel(0)
	end
end



