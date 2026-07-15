--[[
04技能buff持续时间不能固定,只能重新设定SetDuration;不能禁止使用物品。
]]

local MODIFIER_NAME_ACCUSATION_TIMER="modifier_thdots_shikieiki01_accusation_timer"
local MODIFIER_NAME_ACCUSATION="modifier_thdots_shikieiki1_accusation"

local function ApplyShikieiki01Accusation(Caster, Target, Duration)
	local AbilityShikieiki01=Caster:FindAbilityByName("ability_thdots_shikieiki01")
	if not AbilityShikieiki01 then return nil end
	local ability_level=AbilityShikieiki01:GetLevel()
	if ability_level<=0 then
		AbilityShikieiki01:SetLevel(1)
	end
	AbilityShikieiki01:ApplyDataDrivenModifier(Caster,Target,MODIFIER_NAME_ACCUSATION_TIMER,{Duration=Duration})
	if ability_level<=0 then
		AbilityShikieiki01:SetLevel(ability_level)
	end
	return AbilityShikieiki01
end

local function DestroyShikieiki04Effect(Caster, Target)
	if not Caster or not Target then return end
	if Caster:IsNull() or Target:IsNull() then return end
	if not Target.ability_shikieiki_04_effectIndex then return end
	local caster_index=Caster:entindex()
	local effectIndex=Target.ability_shikieiki_04_effectIndex[caster_index]
	if effectIndex then
		ParticleManager:DestroyParticleSystem(effectIndex,true)
		Target.ability_shikieiki_04_effectIndex[caster_index]=nil
	end
end

function GetAccusationCount(Caster,Target)
	local modifiers=Target:FindAllModifiersByName(MODIFIER_NAME_ACCUSATION_TIMER)
	local ModifierCount=0
	if modifiers then
		for _,modifier in pairs(modifiers) do
			if modifier and modifier:GetCaster()==Caster then
				ModifierCount=ModifierCount+1
			end
		end
	end
	--print("GetAccusationCount:"..tostring(ModifierCount))
	return ModifierCount
end

 --clear Accusation and return how many Accusation cleared
function DelAccusation(Caster,Target,DelNum)
	DelNum=DelNum or 99
	local ModifierCount=0
	local modifiers=Target:FindAllModifiersByName(MODIFIER_NAME_ACCUSATION_TIMER)
	local DelCount=0
	if modifiers then
		table.sort(modifiers,function(a,b)
			if a and b and a:GetRemainingTime()<b:GetRemainingTime() then return true end
		end)
		
		for _,modifier in pairs(modifiers) do
			if modifier and modifier:GetCaster()==Caster then
				if DelNum>DelCount then
					modifier:Destroy()
					DelCount=DelCount+1
				end
			end 
		end
	end
	--print("DelAccusation:"..tostring(DelCount))
	return DelCount
end
-------------------------------------------------------------------
function Shikieiki01_OnSpellStart(keys)	
	
	local Ability=keys.ability
	local Caster=keys.caster
	local point = keys.ability:GetCursorPosition()
	local search_radius = keys.ability:GetSpecialValueFor("AOE")
	local Target = FindUnitsInRadius(
				   Caster:GetTeam(),						--caster team
				   point,							--find position
				   nil,										--find entity
				   search_radius,						--find radius
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
				   0, --flag
				   FIND_ANY_ORDER,
				   false
			    )
	for i,v in pairs(Target) do
	-- if (Target:IsBuilding() == true ) then return end
	Ability:ApplyDataDrivenModifier(Caster,v,"modifier_thdots_shikieiki01_mark",{Duration=keys.Duration})
	Ability:ApplyDataDrivenModifier(Caster,v,keys.ModifierName,{Duration=keys.Duration})
	end
end
function Shikieiki01_Modifier_Accusation_OnKill(keys)
	local Ability=keys.ability
	local Caster=Ability:GetCaster()
	local Attacker=keys.attacker
	local Target=keys.unit
	local DamageHPPct = 0
	local DamageHPPctelse = 0
	if (Attacker:GetClassname()=="npc_dota_roshan" ) then return end
	if (Attacker:IsBuilding() == true ) then return end
	if Target:IsRealHero() then
		DamageHPPct=keys.DamageHpPctOnkillHero*0.01
	else
		DamageHPPctelse=keys.DamageHpPctOnkillCreep
	end

	local TriggerNum=DelAccusation(Caster,Attacker,keys.AccusationTriggerNum)
	local Damage=Attacker:GetMaxHealth()*DamageHPPct*TriggerNum+DamageHPPctelse*TriggerNum+keys.DamageHpPctOnkillBase*TriggerNum
	if Attacker:IsRealHero() == true then
		UnitDamageTarget{
		ability = keys.ability,
		victim = Attacker,
		attacker = Caster,
		damage = Damage,
		damage_type = Ability:GetAbilityDamageType()
	}
	end
	--print("Shikieiki01_Modifier_Accusation_OnKill| Damage:"..tostring(Damage))
end

function Shikieiki01_Modifier_AccusationTimer_OnCreated(keys)
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	local MaxAccusationNum=keys.MaxAccusationNum
	if Caster:HasModifier("modifier_item_wanbaochui") then
		MaxAccusationNum=999
	end
	local ModifierAccusation=Target:FindModifierByNameAndCaster(MODIFIER_NAME_ACCUSATION,Caster)
	local ModifierCount=GetAccusationCount(Caster,Target)
	--[[local effectIndex = ParticleManager:CreateParticle("particles/heroes/shikieiki/ability_shikieiki_01_guilty.vpcf", PATTACH_CUSTOMORIGIN, Caster)
	ParticleManager:SetParticleControlEnt(effectIndex , 0, Target, 5, "follow_origin", Vector(0,0,0), true)
	ParticleManager:DestroyParticleSystemTime(effectIndex,keys.Duration)
	local effectIndex = ParticleManager:CreateParticle("particles/heroes/shikieiki/ability_shikieiki_01_guilty_b.vpcf", PATTACH_CUSTOMORIGIN, Caster)
	ParticleManager:SetParticleControlEnt(effectIndex , 0, Target, 5, "follow_origin", Vector(0,0,0), true)
	ParticleManager:SetParticleControl(effectIndex, 1, Vector(0,ModifierCount,0))]]--
	--ParticleManager:SetParticleControl(effectIndex, 1, Target:GetOrigin())
	--ParticleManager:SetParticleControl(effectIndex, 2, Target:GetOrigin())
	--ParticleManager:SetParticleControl(effectIndex, 3, Target:GetOrigin())
	if not Target:FindModifierByName("modifier_thdots_shikieiki1_accusation_slow") then
		Target:AddNewModifier(Caster,Ability,"modifier_thdots_shikieiki1_accusation_slow",{})
	end

	Ability:ApplyDataDrivenModifier(Caster,Target,MODIFIER_NAME_ACCUSATION,{})
	ModifierAccusation=Target:FindModifierByNameAndCaster(MODIFIER_NAME_ACCUSATION,Caster)
	if ModifierAccusation then
		ModifierAccusation:SetStackCount(ModifierCount)

		--ParticleManager:SetParticleControlEnt(effectIndex , 3, Target, 5, "follow_origin", Vector(0,0,0), true)

	end
	if ModifierCount>MaxAccusationNum then
		DelAccusation(Caster,Target,ModifierCount-MaxAccusationNum)
	end
end

function Shikieiki01_Modifier_AccusationTimer_OnDestroy(keys)
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	local MaxAccusationNum=keys.MaxAccusationNum
	local ModifierAccusation=Target:FindModifierByNameAndCaster(MODIFIER_NAME_ACCUSATION,Caster)
	
	if ModifierAccusation then
		if ModifierAccusation:GetStackCount()>1 then
			ModifierAccusation:DecrementStackCount()
		else
			ModifierAccusation:Destroy()
		end
	end
end
--Modifiers
modifier_thdots_shikieiki1_accusation_slow = class({})
LinkLuaModifier("modifier_thdots_shikieiki1_accusation_slow","scripts/vscripts/abilities/abilityshikieiki.lua",LUA_MODIFIER_MOTION_NONE)

--modifier 基础判定
function modifier_thdots_shikieiki1_accusation_slow:IsHidden()      return true end
function modifier_thdots_shikieiki1_accusation_slow:IsPurgable()        return false end
function modifier_thdots_shikieiki1_accusation_slow:RemoveOnDeath()     return false end
function modifier_thdots_shikieiki1_accusation_slow:IsDebuff()      return true end

--modifier 修改列表
function modifier_thdots_shikieiki1_accusation_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
    return funcs
end
function modifier_thdots_shikieiki1_accusation_slow:GetModifierMoveSpeedBonus_Percentage()
	local caster = self:GetCaster()
	if caster == nil or caster.FindAbilityByName == nil then
		return 0
	end
	local ability = caster:FindAbilityByName("ability_thdots_shikieiki01")
	if not ability or ability:GetLevel()== 0 then
		return 0
	else
		return self:GetStackCount()*ability:GetSpecialValueFor("move_speed");
	end
end
function modifier_thdots_shikieiki1_accusation_slow:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end
function modifier_thdots_shikieiki1_accusation_slow:OnIntervalThink(keys)
	if not IsServer() then return end
	local Caster=self:GetCaster()
	local Target=self:GetParent()
	if Caster == nil or Target == nil or Caster.FindAbilityByName == nil or Target.FindModifierByNameAndCaster == nil then
		self:SetStackCount(0)
		self:StartIntervalThink(-1)
		return
	end
	local ability = Caster:FindAbilityByName("ability_thdots_shikieiki01")
	local ModifierAccusation=Target:FindModifierByNameAndCaster(MODIFIER_NAME_ACCUSATION,Caster)
	local level = ability and ability:GetLevel() or 0
	if not ModifierAccusation or level == 0 then 
		self:SetStackCount(0)
	else
		self:SetStackCount(ModifierAccusation:GetStackCount())
	end
end


function Shikieiki02_OnSpellStart(keys)
	if is_spell_blocked(keys.target) then return end
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	local AccusationNum=DelAccusation(Caster,Target)
	local StunDuration= math.min(keys.StunDurationBase+keys.StunDurationAccusation*AccusationNum,3)
	local Damage=keys.DamageBase+keys.DamageAccusation*AccusationNum
	
	UtilStun:UnitStunTarget(Caster,Target,StunDuration)
	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_CUSTOMORIGIN, Target)
	ParticleManager:SetParticleControl(effectIndex, 0, Target:GetOrigin())
	ParticleManager:SetParticleControl(effectIndex, 1, Vector(1,1,1))
	ParticleManager:SetParticleControl(effectIndex, 2, Vector(0,0,0))
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	UnitDamageTarget{
		ability = keys.ability,
		victim = Target,
		attacker = Caster,
		damage = Damage,
		damage_type = Ability:GetAbilityDamageType()
	}
	--print("Shikieiki02_OnSpellStart| damage:"..tostring(Damage).." stun:"..tostring(StunDuration))
end

function Shikieiki03_OnAttackLanded(keys)
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	if keys.target:IsBuilding() then return end
	local MaxAccusationNum=keys.MaxAccusationNum
	--if Target:IsRealHero() then
	-- 三技能借用一技能的叠罪 modifier，避免大小写错误导致万宝槌分支空引用。
	local AbilityShikieiki01=ApplyShikieiki01Accusation(Caster,Target,keys.AccusationDuration)

	if AbilityShikieiki01 and Caster:HasModifier("modifier_item_wanbaochui") then
		local RandomNumber = RandomInt(1,100)
		if RandomNumber<51 then
			ApplyShikieiki01Accusation(Caster,Target,keys.AccusationDuration)
		end
	end
	local Damage= ( keys.DamageOnMaxAccusation + FindTelentValue(Caster,"special_bonus_unique_shikieiki_1") ) * GetAccusationCount(Caster,Target)
	UnitDamageTarget{
		ability = keys.ability,
		victim = Target,
		attacker = Caster,
		damage = Damage,
		damage_type = Ability:GetAbilityDamageType()
		}
end

function Shikieiki04_ModifierDebuff_OnIntervalThink(keys)
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	local Damage=keys.DamagePerSec*0.03
	
	UnitDamageTarget{
		ability = keys.ability,
		victim = Target,
		attacker = Caster,
		damage = Damage,
		damage_type = Ability:GetAbilityDamageType()
	}
end
function Shikieiki04_ModifierKeepDebuffDuration_OnCreated(keys)
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	
	Target.Shikieiki04_Debuff_Duration=keys.DebuffDuration
end
function Shikieiki04_ModifierKeepDebuffDuration_OnDestroy(keys)
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	
	Target.Shikieiki04_Debuff_Duration=nil
	DestroyShikieiki04Effect(Caster,Target)
end
function Shikieiki04_ModifierKeepDebuffDuration_OnIntervalThink(keys)
	local Ability=keys.ability
	local Caster=keys.caster
	local Target=keys.target
	local RadiusKeepDuration=keys.RadiusKeepDuration
	local DebuffName=keys.DebuffName
			
	local Modifier04Debuff=Target:FindModifierByNameAndCaster(DebuffName,Caster)
	if Modifier04Debuff then
		Target.Shikieiki04_Debuff_Duration=Target.Shikieiki04_Debuff_Duration or Modifier04Debuff:GetRemainingTime()
		if CalcDistanceBetweenEntityOBB(Caster,Target)<RadiusKeepDuration and Caster:IsAlive() then
			Modifier04Debuff:SetDuration(Target.Shikieiki04_Debuff_Duration,true)
		else
			Target.Shikieiki04_Debuff_Duration=Modifier04Debuff:GetRemainingTime()
		end
	end
	local MaxHealth = Target:GetMaxHealth()
	local Health = Target:GetHealth()

	if (Health/MaxHealth)<=0.1 then
		Ability:ApplyDataDrivenModifier(Caster, Target, "modifier_thdots_shikieiki04_deny", {})
	end
end

function Shikieiki04_ModifierDebuff_OnCreated(keys)
	local Caster=keys.caster
	local Target=keys.target
	-- 特效索引按目标和施法者保存，避免同一施法者多个审判互相覆盖。
	DestroyShikieiki04Effect(Caster,Target)
	local effectIndex = ParticleManager:CreateParticle(
		"particles/heroes/shikieiki/ability_shikieiki_04.vpcf", 
		PATTACH_CUSTOMORIGIN, 
		Target)
	ParticleManager:SetParticleControlEnt(effectIndex , 0, Target, 5, "follow_origin", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(effectIndex , 1, Target, 5, "follow_origin", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(effectIndex , 4, Target, 5, "follow_origin", Vector(0,0,0), true)
	Target.ability_shikieiki_04_effectIndex=Target.ability_shikieiki_04_effectIndex or {}
	Target.ability_shikieiki_04_effectIndex[Caster:entindex()] = effectIndex
end

function Shikieiki04_OnSpellStart(keys)

	local caster=keys.caster
	local target = keys.target
	if is_spell_blocked(target) then return end
	caster:EmitSound("Hero_Oracle.FatesEdict.Cast")
	caster:EmitSound("Voice_Thdots_Shikieiki.AbilityShikieiki04")
	caster:EmitSound("Hero_Oracle.FatesEdict")
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_thdots_shikieiki04_debuff", {})
end
