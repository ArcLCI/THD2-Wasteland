ability_thdots_sagume_1 = {}

function ability_thdots_sagume_1:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local damage = self:GetSpecialValueFor("damage") + FindTelentValue(caster,"special_bonus_unique_sagume_6")
	ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_loadout.vpcf", PATTACH_ABSORIGIN,target)
	target:EmitSound("sagume01")
	UtilSilence:UnitSilenceTarget( caster,target,self:GetSpecialValueFor("stuntime")+FindTelentValue(self:GetCaster(),"special_bonus_unique_sagume_3"))
	local damage_table = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	UnitDamageTarget(damage_table)
	--UtilStun:UnitStunTarget(caster,target,self:GetSpecialValueFor("stuntime"))
end




ability_thdots_sagume_2 = {}

function ability_thdots_sagume_2:GetCastRange(location, target)
	if IsServer() then return 0 end
end

function ability_thdots_sagume_2:GetBehavior()
	if self:GetCaster():HasModifier("modifier_ability_sagume_telent7_check") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	else
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	end
end

function ability_thdots_sagume_2:GetManaCost(level)
	if self:GetCaster():HasModifier("modifier_ability_sagume_telent7_check") then
		return 0
	else
		return self.BaseClass.GetManaCost(self,level)
	end
end

function ability_thdots_sagume_2:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local cast_range = self:GetSpecialValueFor("cast_range") -- FindTelentValue(caster,"special_bonus_unique_sagume_6")
    if not caster:HasModifier("modifier_ability_sagume_telent7_check") then 
    local point = self:GetCursorPosition()
    self.point = caster:GetAbsOrigin()
    if caster:HasModifier("modifier_item_wanbaochui") then
	    local victims = FindUnitsInRadius(caster:GetTeam(),caster:GetAbsOrigin(),nil,self:GetSpecialValueFor("radius"),DOTA_UNIT_TARGET_TEAM_ENEMY + DOTA_UNIT_TARGET_TEAM_CUSTOM --对范围内的敌人造成效果
	 	    ,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,0,0,false)
	    for hh,sb in pairs(victims) do
        	caster:PerformAttack(sb, true, true, true, true, true, false, false)		--起点万宝槌即时攻击
        end
    end
    caster:EmitSound("sagumeblink")
	ParticleManager:CreateParticle("particles/econ/events/spring_2021/blink_dagger_spring_2021_end.vpcf", PATTACH_ABSORIGIN,caster)
	if (point - self.point):Length2D() > cast_range then point = self.point + (point-self.point):Normalized()*cast_range end
    FindClearSpaceForUnit(caster,point,true)
		caster:AddNewModifier(caster, self, "modifier_ability_sagume_2_bounce", {duration = self:GetSpecialValueFor("bounce_duration")})
    if caster:HasModifier("modifier_item_wanbaochui") then
	    local victims = FindUnitsInRadius(caster:GetTeam(),caster:GetAbsOrigin(),nil,self:GetSpecialValueFor("radius"),DOTA_UNIT_TARGET_TEAM_ENEMY + DOTA_UNIT_TARGET_TEAM_CUSTOM --对范围内的敌人造成效果
	 	    ,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,0,0,false)
	    for hh,sb in pairs(victims) do
        	caster:PerformAttack(sb, true, true, true, true, true, false, false)		--终点万宝槌即时攻击
        end
    end
    if FindTelentValue(caster,"special_bonus_unique_sagume_7") ~= 0 then
    	caster:AddNewModifier(caster,self,"modifier_ability_sagume_telent7_check",{duration = self:GetEffectiveCooldown(self:GetLevel())})
    	self:EndCooldown()
    end
    else																				--返回起点天赋
    if caster:HasModifier("modifier_item_wanbaochui") then
	    local victims = FindUnitsInRadius(caster:GetTeam(),caster:GetAbsOrigin(),nil,self:GetSpecialValueFor("radius"),DOTA_UNIT_TARGET_TEAM_ENEMY + DOTA_UNIT_TARGET_TEAM_CUSTOM --对范围内的敌人造成效果
	 	    ,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,0,0,false)
	    for hh,sb in pairs(victims) do
        	caster:PerformAttack(sb, true, true, true, true, true, false, false)		--起点万宝槌即时攻击
        end
    end
    caster:EmitSound("sagumeblink")
	ParticleManager:CreateParticle("particles/econ/events/spring_2021/blink_dagger_spring_2021_end.vpcf", PATTACH_ABSORIGIN,caster)
    FindClearSpaceForUnit(caster,self.point,true)
    if caster:HasModifier("modifier_item_wanbaochui") then
	    local victims = FindUnitsInRadius(caster:GetTeam(),caster:GetAbsOrigin(),nil,self:GetSpecialValueFor("radius"),DOTA_UNIT_TARGET_TEAM_ENEMY + DOTA_UNIT_TARGET_TEAM_CUSTOM --对范围内的敌人造成效果
	 	    ,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,0,0,false)
	    for hh,sb in pairs(victims) do
        	caster:PerformAttack(sb, true, true, true, true, true, false, false)		--终点万宝槌即时攻击
        end
    end
    caster:RemoveModifierByName("modifier_ability_sagume_telent7_check")
    end
end

function ability_thdots_sagume_2:OnBouncing(source, times)
	if not IsServer() then return end
	local bounce_target = nil
	local targets = FindUnitsInRadius(
		self:GetCaster():GetTeam(),
		source:GetAbsOrigin(),
		nil,
		self:GetSpecialValueFor("bounce_range"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE,
		FIND_ANY_ORDER,
		false
	)
	for _, t in pairs(targets) do
		if t ~= source then
			bounce_target = t
			break
		end
	end
	if bounce_target == nil then return end
	local sagume03 = self:GetCaster():FindAbilityByName("ability_thdots_sagume_3")
	ProjectileManager:CreateTrackingProjectile({
		Ability = self,
		Target = bounce_target,
		Source = source,
		EffectName = sagume03:GetAutoCastState() and "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf" or "particles/units/heroes/hero_queenofpain/queen_base_attack.vpcf",
		iMoveSpeed = self:GetCaster():IsRangedAttacker() and self:GetCaster():GetProjectileSpeed() or 900,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		bDrawsOnMinimap = false,
		bDodgeable = true,
		bIsAttack = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = GameRules:GetGameTime() + 10,
		bProvidesVision = false,
		ExtraData = { bounce_times = times }
	})
end

function ability_thdots_sagume_2:OnProjectileHit_ExtraData(target, loc, data)
	if not IsServer() then return end

	if target and not target:IsNull() then
		local rate = 1 - self:GetSpecialValueFor("bounce_decay") / 100
		local damage = self:GetCaster():GetAttackDamage() * rate ^ data.bounce_times
		UnitDamageTarget({
			victim = target,
			attacker = self:GetCaster(),
			damage = damage,
			damage_type = DAMAGE_TYPE_PHYSICAL
		})

		if target and not target:IsNull() then
			local sagume03 = self:GetCaster():FindAbilityByName("ability_thdots_sagume_3")
			if sagume03:GetAutoCastState() then
				local extra_damage = self:GetCaster():GetIntellect(false) * (sagume03:GetSpecialValueFor("intellect_bonus") + FindTelentValue(self:GetCaster(), "special_bonus_unique_sagume_4"))
				local damage_type = sagume03:GetAbilityDamageType() 
				UnitDamageTarget({
					victim = target,
					attacker = self:GetCaster(),
					damage = extra_damage,
					damage_type = damage_type
				})
			end
			local max_bounce_times = self:GetSpecialValueFor("max_bounce_times")+FindTelentValue(self:GetCaster(),"special_bonus_unique_sagume_5")
			if data.bounce_times >= max_bounce_times then return end
			self:OnBouncing(target, data.bounce_times + 1)
		end
	end
end

modifier_ability_sagume_2_bounce = {}
LinkLuaModifier("modifier_ability_sagume_2_bounce", "scripts/vscripts/abilities/abilitysagume.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_sagume_2_bounce:IsHidden() return false end
function modifier_ability_sagume_2_bounce:IsDebuff() return false end
function modifier_ability_sagume_2_bounce:IsPurgable() return true end
function modifier_ability_sagume_2_bounce:RemoveOnDeath() return true end

function modifier_ability_sagume_2_bounce:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_ability_sagume_2_bounce:OnAttackLanded(event)
	if not IsServer() then return end
	local max_bounce_times = self:GetAbility():GetSpecialValueFor("max_bounce_times")+FindTelentValue(self:GetCaster(),"special_bonus_unique_sagume_5")
	if event.attacker ~= self:GetParent() or event.target:IsOther() then return end
	if max_bounce_times ~= 0 then
	self:GetAbility():OnBouncing(event.target, 1)
	end
end

modifier_ability_sagume_telent7_check = {}
LinkLuaModifier("modifier_ability_sagume_telent7_check","scripts/vscripts/abilities/abilitysagume.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_sagume_telent7_check:IsHidden() return false end
function modifier_ability_sagume_telent7_check:IsDebuff() return false end
function modifier_ability_sagume_telent7_check:IsPurgable() return false end
function modifier_ability_sagume_telent7_check:RemoveOnDeath() return false end

function modifier_ability_sagume_telent7_check:OnRemoved()
	if not IsServer() then return end
	self:GetAbility():StartCooldown(self:GetRemainingTime())
end

ability_thdots_sagume_3 = {}
LinkLuaModifier("modifier_generic_orb_effect_lua", "components/modifiers/generic/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE)

--法球
function ability_thdots_sagume_3:GetIntrinsicModifierName()
	return "modifier_generic_orb_effect_lua"
end

function ability_thdots_sagume_3:GetCastRange(vLocation, hTarget)
	-- GetOrbCastRange
	local caster = self:GetCaster()

	local tData = DOTAGameManager:GetHeroDataByName_Script(caster:GetUnitName())
	local BaseAttackRange = tonumber(tData["AttackRange"])
	local BaseCastRange = self.BaseClass.GetCastRange(self, vLocation, hTarget)

	local castrange = caster:Script_GetAttackRange()

	if IsServer() then
		-- Server-side
		-- Note: DOTA_ABILITY_BEHAVIOR_ATTACK会计算dota的攻击距离加成，但不会计算lua的
		local BonusAttackRange = GetSumModifierValues(caster, "GetModifierAttackRangeBonus")

		castrange = BaseCastRange + BonusAttackRange
	else
		-- Client-side
		castrange = BaseCastRange + (caster:Script_GetAttackRange() - BaseAttackRange)
		-- 移除施法距离加成
		castrange = castrange - caster:GetCastRangeBonus()
	end

	return castrange
end

function ability_thdots_sagume_3:GetProjectileName()
	return "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf"
end

function ability_thdots_sagume_3:OnOrbImpact(keys)
	if not IsServer() then return end
	local caster = self:GetCaster()

	local damage = caster:GetIntellect(false) * (self:GetSpecialValueFor("intellect_bonus") + FindTelentValue(self:GetCaster(),"special_bonus_unique_sagume_4"))
	local damage_type = self:GetAbilityDamageType() 
	local damage_table = {
		victim = keys.target,
		attacker = caster,
		damage = damage,
		damage_type = damage_type,
	}
 	SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,keys.target,damage,nil)
	UnitDamageTarget(damage_table)
end

ability_thdots_sagume_4 = {}

function ability_thdots_sagume_4:GetCooldown(level)
	return self.BaseClass.GetCooldown(self, level)
end

function ability_thdots_sagume_4:OnAbilityUpgrade(ability)
	if not IsServer() then return end
	if ability:GetAbilityName() == "special_bonus_unique_sagume_8" then
		self:SetCurrentAbilityCharges(self:GetMaxAbilityCharges(self:GetLevel()) - 1)
		if not self:IsCooldownReady() then
			self:EndCooldown()
			self:StartCooldown(self:GetCooldownTime())
		end
	end
end

function ability_thdots_sagume_4:OnSpellStart()
	if not IsServer() then return end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
	ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_holy_persuasion.vpcf", PATTACH_ABSORIGIN,target)
    target:EmitSound("sagume04")
	print(target:GetAbilityCount())
    for spell_id = 0,target:GetAbilityCount()-1 do
    	local ability = target:GetAbilityByIndex(spell_id)
    	if ability ~= nil then
    	    if ability:GetCooldownTimeRemaining() ~= 0 then
				if ability ~= self then							--不刷新大招冷却
    		    ability:EndCooldown()
				end
        	else
        		if ability:GetCooldownTime() ~= nil then 
    		        ability:StartCooldown(ability:GetEffectiveCooldown(self:GetLevel()))
    		    end
    	    end
			if ability:GetCurrentAbilityCharges() ~= ability:GetMaxAbilityCharges(ability:GetLevel()) then
				if ability ~= self then							--不刷新大招充能
				ability:RefreshCharges()
				end
			else
				ability:SetCurrentAbilityCharges(0)
			end
    	end
    end

    for item_id = 0, 20 do
		local item_in_target = target:GetItemInSlot(item_id)	
		if item_in_target ~= nil then
		    if item_in_target:GetCooldownTimeRemaining() ~= 0 then
		    	item_in_target:EndCooldown()
		    else
		    	if item_in_target:GetCooldownTime() ~= nil then
		    	    item_in_target:StartCooldown(item_in_target:GetEffectiveCooldown(self:GetLevel()))
		    	end
		    end
		end
	end

	if caster:HasModifier("modifier_ability_sagume_telent7_check") then
		caster:RemoveModifierByName("modifier_ability_sagume_telent7_check")
		caster:GetAbilityByIndex(1):EndCooldown()
	end
end

ability_thdots_sagume_Ex = {}

function ability_thdots_sagume_Ex:GetIntrinsicModifierName()
	return "modifier_sagumeEx_basic"
end

modifier_sagumeEx_basic = {}
LinkLuaModifier("modifier_sagumeEx_basic","scripts/vscripts/abilities/abilitysagume.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_sagumeEx_basic:IsHidden() return false end
function modifier_sagumeEx_basic:IsDebuff() return false end
function modifier_sagumeEx_basic:IsPurgable() return false end
function modifier_sagumeEx_basic:RemoveOnDeath() return false end

function modifier_sagumeEx_basic:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_sagumeEx_basic:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end

function modifier_sagumeEx_basic:OnCreated()
	if not IsServer() then return end
	THD2_RefreshTalentModifiers(self:GetParent(), "ability_thdots_sagume_Ex")
	self:SetStackCount(0)
end

function modifier_sagumeEx_basic:OnDeath(keys)
	if not IsServer() then return end

	if not self:GetCaster():IsAlive() then return end

    local caster = self:GetParent()
	if keys.unit:GetTeam() == caster:GetTeam() then return end
	if not keys.unit:IsRealHero() then return end
	if keys.attacker == caster then self:SetStackCount(self:GetStackCount()+2) return end
	if (keys.unit:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > self:GetAbility():GetSpecialValueFor("limit") then return end
	self:SetStackCount(self:GetStackCount()+2)
end

function modifier_sagumeEx_basic:OnIntervalThink()
	if not IsServer() then return end
end

modifier_ability_sagume_telent5 = {}
LinkLuaModifier("modifier_ability_sagume_telent5","scripts/vscripts/abilities/abilitysagume.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_sagume_telent5:IsHidden() return true end
function modifier_ability_sagume_telent5:IsPurgable() return false end
function modifier_ability_sagume_telent5:IsDebuff() return false end
function modifier_ability_sagume_telent5:RemoveOnDeath() return false end

modifier_ability_sagume_telent6 = {}
LinkLuaModifier("modifier_ability_sagume_telent6","scripts/vscripts/abilities/abilitysagume.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_sagume_telent6:IsHidden() return true end
function modifier_ability_sagume_telent6:IsPurgable() return false end
function modifier_ability_sagume_telent6:IsDebuff() return false end
function modifier_ability_sagume_telent6:RemoveOnDeath() return false end
