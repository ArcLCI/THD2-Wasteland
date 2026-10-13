local MIKO03_COMBO_INTERVAL = 0.2
local MIKO03_COMBO_PENDING_TIMEOUT = 1.5

ability_thdots_mikoEx = {}

function ability_thdots_mikoEx:GetIntrinsicModifierName()
	return "modifier_miko_telent"
end

-- modifier_ability_mikoEx_vision = {}
-- LinkLuaModifier("modifier_ability_mikoEx_vision", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
-- function modifier_ability_mikoEx_vision:IsHidden() return true end
-- function modifier_ability_mikoEx_vision:IsDebuff() return false end
-- function modifier_ability_mikoEx_vision:IsPurgable() return false end
-- function modifier_ability_mikoEx_vision:RemoveOnDeath() return false end

-- function modifier_ability_mikoEx_vision:OnCreated()
-- 	if not IsServer() then return end
-- 	self:StartIntervalThink(0.3)
-- 	self:OnIntervalThink()
-- end

-- function modifier_ability_mikoEx_vision:OnIntervalThink()        -- 每0.3秒添加一次0.31秒的高空视野
-- 	if not IsServer() then return end
-- 	if not self:GetCaster():IsAlive() then return end
-- 	local caster = self:GetCaster()
-- 	local radius = self:GetAbility():GetSpecialValueFor("radius") + FindTelentValue(self:GetCaster(),"special_bonus_unique_miko03")
-- 	local heros = FindUnitsInRadius(
-- 				   caster:GetTeam(),						--caster team
-- 				   caster:GetAbsOrigin(),							--find position
-- 				   nil,										--find entity
-- 				   radius,						--find radius
-- 				   DOTA_UNIT_TARGET_TEAM_ENEMY,
-- 				   DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
-- 				   0, 0,
-- 				   false
-- 			    )
-- 	for hh,sb in pairs(heros) do
-- 		if not sb:IsInvisible() then
-- 			AddFOWViewer( caster:GetTeam(), sb:GetAbsOrigin(), 100, 0.31, false)
-- 		end
-- 	end
-- 	if not (self:GetCaster():FindAbilityByName("ability_thdots_miko04"):GetLevel() == 3) then return end
-- 	self.castrange = self:GetCaster():FindAbilityByName("ability_thdots_miko04"):GetSpecialValueFor("max_level_cast_range")
-- end

-- function modifier_ability_mikoEx_vision:DeclareFunctions()
-- 	return {
-- 		MODIFIER_PROPERTY_CAST_RANGE_BONUS,
-- 		MODIFIER_EVENT_ON_TAKEDAMAGE,
-- 	}
-- end

-- function modifier_ability_mikoEx_vision:GetModifierCastRangeBonus()
-- 	return self.castrange
-- end

-- function modifier_ability_mikoEx_vision:OnTakeDamage(keys)
-- 	if not IsServer() then return end
-- 	local caster = self:GetCaster()
--     if self:GetCaster():FindAbilityByName("ability_thdots_miko03"):GetLevel() ~= 4 then return end  --这一段是全能吸血 根据造成的伤害进行一个heal
--     if keys.attacker == caster then
--     	if caster:GetHealth() == 0 then return end
-- 		local heal_ratio = 0.01 * self:GetCaster():FindAbilityByName("ability_thdots_miko03"):GetSpecialValueFor("max_level_heal_ratio")
--         caster:Heal(keys.damage*heal_ratio,caster)
--         SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,caster,keys.damage*heal_ratio,nil) 
--     end
-- end

----------------------------------------------------------------------------------------------------

ability_thdots_miko03 = {}

function ability_thdots_miko03:GetIntrinsicModifierName()
	return "modifier_ability_miko03_passive"
end

modifier_ability_miko03_passive = {}
LinkLuaModifier("modifier_ability_miko03_passive", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko03_passive:IsHidden()
	if not IsServer() then return end
	if self:GetAbility():IsCooldownReady() then 
		return false
	else
		return true
	end 
end
function modifier_ability_miko03_passive:IsDebuff() return false end
function modifier_ability_miko03_passive:IsPurgable() return false end
function modifier_ability_miko03_passive:RemoveOnDeath() return false end

function modifier_ability_miko03_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_ability_miko03_passive:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetCaster() then return end
	if not self:GetAbility():IsCooldownReady() then return end --检测是否是CD中 CD中无法触发效果
	if not keys.target or keys.target:IsNull() then return end
	if not keys.target:IsAlive() then return end
	if not keys.attacker:HasModifier("modifier_ability_miko03_next") then
		keys.attacker:AddNewModifier(keys.attacker,self:GetAbility(),"modifier_ability_miko03_next",{target_entindex = keys.target:entindex()})
	end
end

modifier_ability_miko03_stun = {}
LinkLuaModifier("modifier_ability_miko03_stun", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko03_stun:IsHidden() return true end
function modifier_ability_miko03_stun:IsDebuff() return true end
function modifier_ability_miko03_stun:IsPurgable() return true end
function modifier_ability_miko03_stun:RemoveOnDeath() return true end

function modifier_ability_miko03_stun:OnCreated()
	self:StartIntervalThink(0.1)
end

function modifier_ability_miko03_stun:OnIntervalThink()
	if not IsServer() then return end
	local count = self:GetParent():GetModifierStackCount("modifier_ability_miko03_stun", nil)
	self:GetParent():SetModifierStackCount("modifier_ability_miko03_stun", self, count - 1 )
end

function modifier_ability_miko03_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

modifier_ability_miko03_next = {}
LinkLuaModifier("modifier_ability_miko03_next", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko03_next:IsHidden() return true end
function modifier_ability_miko03_next:IsDebuff() return false end
function modifier_ability_miko03_next:IsPurgable() return false end
function modifier_ability_miko03_next:RemoveOnDeath() return true end

function modifier_ability_miko03_next:OnCreated(params)
	if not IsServer() then return end
	self.attacktimes = self:GetAbility():GetSpecialValueFor("fast_attack_times")
	self.target_entindex = params and tonumber(params.target_entindex) or nil
	self.combo_pending = false
	self.combo_started = false
	self.pending_expire_time = 0
	self:StartIntervalThink(MIKO03_COMBO_INTERVAL)
end

function modifier_ability_miko03_next:OnRefresh(params)
	if not IsServer() then return end
	if params and params.target_entindex then
		self.target_entindex = tonumber(params.target_entindex)
	end
end

function modifier_ability_miko03_next:OnRemoved()
	if not IsServer() then return end
	self:StartIntervalThink(-1)
	if self.combo_started then
		self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(self:GetAbility():GetLevel() - 1))
	end
end

function modifier_ability_miko03_next:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_ability_miko03_next:PlayComboGesture()
	local caster = self:GetParent()
	if caster:HasModifier("modifier_miko_immortal") then return end
	-- PerformAttack 会启动普通攻击动作，这里主动覆盖回原 3 技能连击动作。
	caster:RemoveGesture(ACT_DOTA_ATTACK)
	caster:RemoveGesture(ACT_DOTA_ATTACK2)
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3, 1.8)
end

function modifier_ability_miko03_next:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetParent()
	if not caster or caster:IsNull() or not caster:IsAlive() then
		if caster and not caster:IsNull() then
			caster:RemoveModifierByName("modifier_ability_miko03_next")
		end
		return
	end

	if self.combo_pending then
		if GameRules:GetGameTime() >= self.pending_expire_time then
			self.combo_pending = false
			if self.attacktimes <= 0 then
				caster:RemoveModifierByName("modifier_ability_miko03_next")
			end
		end
		return
	end

	if self.attacktimes <= 0 then
		caster:RemoveModifierByName("modifier_ability_miko03_next")
		return
	end

	local target = nil
	if self.target_entindex then
		target = EntIndexToHScript(self.target_entindex)
	end
	if not target or target:IsNull() or not target:IsAlive() then
		caster:RemoveModifierByName("modifier_ability_miko03_next")
		return
	end

	self.combo_pending = true
	self.combo_started = true
	self.pending_expire_time = GameRules:GetGameTime() + MIKO03_COMBO_PENDING_TIMEOUT
	self.attacktimes = self.attacktimes - 1
	caster:PerformAttack(target, false, true, true, true, true, false, false)
	self:PlayComboGesture()
end

function modifier_ability_miko03_next:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetCaster() then return end
	if not self.combo_pending then return end

	local damage = self:GetAbility():GetSpecialValueFor("damage") 
	local dmg_type = DAMAGE_TYPE_MAGICAL
	if keys.attacker:HasModifier("modifier_miko_immortal") then dmg_type = DAMAGE_TYPE_PURE end
	if not keys.target or keys.target:IsNull() then return end
	if self.target_entindex and keys.target:entindex() ~= self.target_entindex then return end
	self.combo_pending = false
	self.pending_expire_time = 0
	if keys.target:IsBuilding() then damage = damage * 0.2 end
	if keys.target:GetTeam() == keys.attacker:GetTeam() then damage = 0 end
	local damage_table = {
		victim = keys.target,
		attacker = keys.attacker,
		damage = damage,
		damage_type = dmg_type,
	}
	local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/miko/miko04p.vpcf", PATTACH_ABSORIGIN,keys.target)
	ParticleManager:ReleaseParticleIndex(effectIndex)
	UnitDamageTarget(damage_table)

	if keys.target and not keys.target:IsNull() and FindTelentValue(self:GetCaster(),"special_bonus_unique_miko04") ~= 0 then
		local duration = keys.target:GetModifierStackCount("modifier_ability_miko03_stun", nil) * 0.1
		if keys.attacker:IsRealHero() then duration = duration + 0.5 end --眩晕叠加机制类似拉尔瓦02 duration为剩余眩晕时间
		keys.target:AddNewModifier(keys.attacker,self:GetAbility(),"modifier_ability_miko03_stun",{duration = duration})
		keys.target:SetModifierStackCount("modifier_ability_miko03_stun", self, duration * 10 )
	end
	if self.attacktimes <= 0 then
		keys.attacker:RemoveModifierByName("modifier_ability_miko03_next")
	end
end

function modifier_ability_miko03_next:GetModifierAttackRangeBonus()
	return self:GetAbility():GetSpecialValueFor("attack_range")
end

function modifier_ability_miko03_next:GetAttackSound()
	return "exrumiaattack"
end

---------------------------------------------------------------------------------------------------------------------------------

ability_thdots_miko04 = {}

function ability_thdots_miko04:GetChannelTime()
	return 2
end

function ability_thdots_miko04:GetChannelAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

function ability_thdots_miko04:OnSpellStart()
	if not IsServer() then return end
    self.caster = self:GetCaster()
    self.target = self:GetCursorTarget()
    self.caster:AddNewModifier(self.caster,self,"modifier_ability_miko04_cready",{})
	self.target:AddNewModifier(self.caster,self,"modifier_ability_miko04_tready",{})
	self.ceff = ParticleManager:CreateParticle("particles/thd2/heroes/miko/miko05p.vpcf", PATTACH_ABSORIGIN_FOLLOW,self.caster)
	self.teff = ParticleManager:CreateParticle("particles/thd2/heroes/miko/miko05p.vpcf", PATTACH_ABSORIGIN_FOLLOW,self.target)
	self.teff2 = ParticleManager:CreateParticle("particles/units/heroes/hero_dawnbreaker/dawnbreaker_solar_guardian_aoe.vpcf", PATTACH_ABSORIGIN_FOLLOW,self.target)
	ParticleManager:SetParticleControlEnt(self.teff2, 1, self.target, PATTACH_ABSORIGIN_FOLLOW, nil, self.target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(self.teff2,2,Vector(500,500,0))
    self.caster:EmitSound("miko04cc")
    self.target:EmitSound("miko04tc")
end

function ability_thdots_miko04:OnChannelFinish(bInterrupted)
	if not IsServer() then return end
	if self.caster:IsAlive() and ( self.caster:GetModifierStackCount("modifier_ability_miko04_cready",nil) >= 100 ) then  --检测是否满足各项条件
		if self.target:IsAlive() then
			self.tp = self.target:GetAbsOrigin()
			local invul_duration = self:GetSpecialValueFor("invul_duration")
			self.caster:AddNewModifier(self.caster,self,"modifier_ability_miko04_speed",{duration = invul_duration})
			self.target:AddNewModifier(self.caster,self,"modifier_ability_miko04_speed",{duration = invul_duration})
			FindClearSpaceForUnit(self.caster,self.tp,true)
			ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_divine_favor.vpcf", PATTACH_ABSORIGIN,self.target)
		end
		self.caster:EmitSound("miko04layer")
    end
	ParticleManager:DestroyParticle(self.ceff,true)
	ParticleManager:DestroyParticle(self.teff,true)
	ParticleManager:DestroyParticle(self.teff2,true)
	self.caster:RemoveModifierByName("modifier_ability_miko04_cready")
	self.target:RemoveModifierByName("modifier_ability_miko04_tready")
end

modifier_ability_miko04_speed = {}
LinkLuaModifier("modifier_ability_miko04_speed", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko04_speed:IsHidden() return false end
function modifier_ability_miko04_speed:IsPurgable() return true end
function modifier_ability_miko04_speed:IsDebuff() return false end
function modifier_ability_miko04_speed:RemoveOnDeath() return true end

function modifier_ability_miko04_speed:OnCreated()
	self.eff = ParticleManager:CreateParticle("particles/thd2/items/item_tsundere.vpcf", PATTACH_ABSORIGIN_FOLLOW,self:GetParent())
end

function modifier_ability_miko04_speed:OnRemoved()
   ParticleManager:DestroyParticle(self.eff,true)
end

function modifier_ability_miko04_speed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
end

function modifier_ability_miko04_speed:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_ability_miko04_speed:GetAbsoluteNoDamageMagical() return 1 end
function modifier_ability_miko04_speed:GetAbsoluteNoDamagePure() return 1 end

function modifier_ability_miko04_speed:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_STUNNED] = false,
	}
end

modifier_ability_miko04_cready = {}
LinkLuaModifier("modifier_ability_miko04_cready", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko04_cready:IsHidden() return false end
function modifier_ability_miko04_cready:IsPurgable() return false end
function modifier_ability_miko04_cready:IsDebuff() return false end
function modifier_ability_miko04_cready:RemoveOnDeath() return true end

function modifier_ability_miko04_cready:OnCreated()
	self:StartIntervalThink(0.04)
	self:OnIntervalThink()
end

function modifier_ability_miko04_cready:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local count = caster:GetModifierStackCount("modifier_ability_miko04_cready",nil) + 2
	if count >= 100 then count = 100 end
	caster:SetModifierStackCount("modifier_ability_miko04_cready", self:GetAbility(),count)
	local heal = self:GetAbility():GetSpecialValueFor("heal")
	caster:Heal(heal,caster)
	SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,caster,heal,nil)
end

modifier_ability_miko04_tready = {}
LinkLuaModifier("modifier_ability_miko04_tready", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko04_tready:IsHidden() return false end
function modifier_ability_miko04_tready:IsPurgable() return false end
function modifier_ability_miko04_tready:IsDebuff() return false end
function modifier_ability_miko04_tready:RemoveOnDeath() return true end

function modifier_ability_miko04_tready:OnCreated()
	self:StartIntervalThink(0.05)
	self:OnIntervalThink()
end

function modifier_ability_miko04_tready:OnIntervalThink()
	if not IsServer() then return end
	local count = self:GetCaster():GetModifierStackCount("modifier_ability_miko04_cready",nil) + 2
	if count >= 100 then count = 100 end
	self:GetParent():SetModifierStackCount("modifier_ability_miko04_tready", self:GetAbility(),count)
	if not self:GetCaster():IsAlive() then 
		self:GetParent():RemoveModifierByName("modifier_ability_miko04_tready")
	end
	local heal = self:GetAbility():GetSpecialValueFor("heal")
	if self:GetCaster():HasModifier("modifier_miko_immortal") then
		local heros = FindUnitsInRadius(
				   self:GetCaster():GetTeam(),						--caster team
				   self:GetParent():GetAbsOrigin(),							--find position
				   nil,										--find entity
				   self:GetAbility():GetSpecialValueFor("immortal_radius"),						--find radius
				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				   DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
				   0, 0,
				   false
			    ) 
		   for hh,sb in pairs(heros) do
			 sb:Heal(heal,self:GetCaster())
	SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,sb,heal,nil)
		   end
		else
	       self:GetParent():Heal(heal,self:GetCaster())
	SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,self:GetParent(),heal,nil)
    end
end

------------------------------------------------------------------------------------------------------------------------------------------

ability_thdots_mikoWanbao = {}

function ability_thdots_mikoWanbao:OnInventoryContentsChanged() --无万宝槌时隐藏
	if not IsServer() then return end
		if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
			self:SetHidden(false)
		else
			self:SetHidden(true)
		end
end

function ability_thdots_mikoWanbao:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster,self,"modifier_ability_mikoWanbao_disable",{duration = duration})
	target:AddNewModifier(caster,self,"modifier_ability_mikoWanbao_disable",{duration = duration})
end

modifier_ability_mikoWanbao_disable = {}
LinkLuaModifier("modifier_ability_mikoWanbao_disable", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_mikoWanbao_disable:IsHidden() return false end
function modifier_ability_mikoWanbao_disable:IsPurgable() return false end
function modifier_ability_mikoWanbao_disable:RemoveOnDeath() return true end
function modifier_ability_mikoWanbao_disable:IsDebuff()
	if not IsServer() then return end
	if self:GetParent():GetTeam() == self:GetCaster():GetTeam() then return false end
	return true
end

function modifier_ability_mikoWanbao_disable:CheckState()
	if not IsServer() then return end
	if self:GetCaster():HasModifier("modifier_miko_immortal") then
	    self.tableskill = {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
	   }
    else
	   self.tableskill = {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
	   }
    end
	return self.tableskill
end

function modifier_ability_mikoWanbao_disable:OnCreated()
	self.eff = ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_blade_fury_disk.vpcf", PATTACH_ABSORIGIN_FOLLOW,self:GetParent())
	self:GetParent():EmitSound("mikowanbao")
end

function modifier_ability_mikoWanbao_disable:OnRemoved()
	ParticleManager:DestroyParticle(self.eff,true)
end

----------------------------------------------------------------------------------------------------------------------------------

modifier_miko_telent = {}
LinkLuaModifier("modifier_miko_telent", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_miko_telent:IsHidden() return true end
function modifier_miko_telent:IsPurgable() return false end
function modifier_miko_telent:RemoveOnDeath() return false end
function modifier_miko_telent:IsDebuff() return false end

function modifier_miko_telent:OnCreated()
	self:StartIntervalThink(0.3)
	self:OnIntervalThink()
end

function modifier_miko_telent:OnIntervalThink() -- 天赋监听
	if not IsServer() then return end
	local ability = self:GetAbility()
	if ability ~= nil then
		if ability:GetSpecialValueFor("have_immortal") ~= 0 and self:GetCaster():HasModifier("modifier_miko_immortal") == false then
			self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_miko_immortal",{})
		end
	end
end

modifier_miko_immortal = {}
LinkLuaModifier("modifier_miko_immortal", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_miko_immortal:IsHidden() return false end
function modifier_miko_immortal:IsPurgable() return false end
function modifier_miko_immortal:RemoveOnDeath() return false end
function modifier_miko_immortal:IsDebuff() return false end

function modifier_miko_immortal:OnCreated()
	if not IsServer() then return end
	self:GetCaster():SetOriginalModel("models/miko/miko_b.vmdl")
end

function modifier_miko_immortal:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
end

function modifier_miko_immortal:GetAttackSound()
	return "exrumiaattack"
end

function modifier_miko_immortal:GetModifierHealthRegenPercentage()
	if self:GetCaster():FindAbilityByName("ability_thdots_miko01"):GetLevel() == 0 then return end
	return self:GetCaster():FindAbilityByName("ability_thdots_miko01"):GetSpecialValueFor("immortal_health_regen")
end

function modifier_miko_immortal:GetModifierAttackRangeBonus()
	if self:GetCaster():FindAbilityByName("ability_thdots_miko03"):GetLevel() == 0 then return end
	return self:GetCaster():FindAbilityByName("ability_thdots_miko03"):GetSpecialValueFor("immortal_attack_range")
end

ability_thdots_miko01 = {}

function ability_thdots_miko01:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_miko01:OnSpellStart() --施法时就转移到目的地了
	self.tpoint = self:GetCursorPosition()
	self.caster = self:GetCaster()
	local vision = self.caster:GetCurrentVisionRange()
	local duration = self:GetSpecialValueFor("disappear_duration")
	self.caster:AddNewModifier(self.caster,self,"modifier_ability_miko01_disappearing",{duration = duration})
	SetTHD2BlockingNeutrals(self.caster, false)
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_miko07") ~= 0 then
		self.Particle = "particles/thd2/heroes/miko/miko1_600/miko1_600.vpcf"
	else
		self.Particle = "particles/thd2/heroes/miko/miko1_300/miko1_300.vpcf"
	end
    local thinker = CreateModifierThinker(self.caster,self,"modifier_ability_miko01_effect",{duration = duration},self.tpoint,self.caster:GetTeamNumber(),false)
    ParticleManager:CreateParticle(self.Particle, PATTACH_ABSORIGIN,thinker)
	self.caster:AddNoDraw()
	FindClearSpaceForUnit(self.caster,self.tpoint,true)
	AddFOWViewer(self:GetCaster():GetTeamNumber(), self.tpoint, vision, duration, false)
	self.caster:EmitSound("miko01c")
end

modifier_ability_miko01_disappearing = {}
LinkLuaModifier("modifier_ability_miko01_disappearing", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko01_disappearing:IsHidden() return false end
function modifier_ability_miko01_disappearing:IsDebuff() return false end
function modifier_ability_miko01_disappearing:IsPurgable() return false end
function modifier_ability_miko01_disappearing:RemoveOnDeath() return false end

function modifier_ability_miko01_disappearing:CheckState()
	return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = false,
	}
end

function modifier_ability_miko01_disappearing:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BONUS_DAY_VISION,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
	}
end

function modifier_ability_miko01_disappearing:GetBonusNightVision()
	return -99999
end

function modifier_ability_miko01_disappearing:GetBonusDayVision()
	return -99999
end

function modifier_ability_miko01_disappearing:OnDestroy() --状态移除时造成各项效果
	if not IsServer() then return end
	self:GetCaster():RemoveNoDraw()
	SetTHD2BlockingNeutrals(self:GetCaster(), nil)
	self.eff = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf", PATTACH_ABSORIGIN,self:GetParent())
	if not self:GetCaster():IsAlive() then return end
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	local damage = self:GetAbility():GetSpecialValueFor("damage")
	if self:GetParent():FindAbilityByName("ability_thdots_miko01"):GetLevel() == 4 then
		damage = damage + self:GetAbility():GetSpecialValueFor("max_level_damage")
	end
	local stuntime = self:GetAbility():GetSpecialValueFor("stuntime")
	local heroes = FindUnitsInRadius(
				   self:GetCaster():GetTeam(),						--caster team
				   self:GetCaster():GetAbsOrigin(),							--find position
				   nil,										--find entity
				   radius,						--find radius
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
				   DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0,
				   false
			    )
	for hh,sb in pairs(heroes) do
		UtilStun:UnitStunTarget(self:GetCaster(),sb,stuntime, (UtilStun.TraceSource and UtilStun:TraceSource(function() return self:GetAbility() end) or nil), "script:scripts/vscripts/abilities/abilitymiko.lua:OnDestroy:612")
		local damage_table = {
			victim = sb,
			attacker = self:GetCaster(),
			damage = damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
		}
		UnitDamageTarget(damage_table)
	end
	self:GetCaster():EmitSound("miko01i")
end

modifier_ability_miko01_effect = {}
LinkLuaModifier("modifier_ability_miko01_effect", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)

ability_thdots_miko02 = {}

function ability_thdots_miko02:OnToggle()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster,self,"modifier_ability_miko02_check",{})
	else
		caster:RemoveModifierByName("modifier_ability_miko02_check")
	end
end

modifier_ability_miko02_check = {}
LinkLuaModifier("modifier_ability_miko02_check", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko02_check:IsHidden() 		return true end
function modifier_ability_miko02_check:IsPurgable()		return false end
function modifier_ability_miko02_check:RemoveOnDeath() 	return true end
function modifier_ability_miko02_check:IsDebuff()		return false end

function modifier_ability_miko02_check:OnCreated()
	self:StartIntervalThink(1)
	self:OnIntervalThink()
end

function modifier_ability_miko02_check:OnIntervalThink() --判断蓝量是否满足添加BUFF的要求
	if not IsServer() then return end
	local caster = self:GetCaster()
	local mana = caster:GetMana()
	local spend = self:GetAbility():GetSpecialValueFor("mana_cost")
	if self:GetCaster():HasModifier("modifier_miko_immortal") then
		spend = self:GetAbility():GetSpecialValueFor("immortal_mana_cost")
	end
	if not (mana >= spend) then
		caster:RemoveModifierByName("modifier_ability_miko02_aura")
	return end
    caster:SpendMana(spend,self:GetAbility())
    if not caster:HasModifier("modifier_ability_miko02_aura") then
    	if not caster:HasModifier("modifier_miko_immortal") then
    		caster:AddNewModifier(caster,self:GetAbility(),"modifier_ability_miko02_aura",{})
		end
	end
    caster:AddNewModifier(caster,self:GetAbility(),"modifier_ability_miko02_bonus",{duration = 1.1})
end

function modifier_ability_miko02_check:OnRemoved()
	if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_ability_miko02_aura")
end


modifier_ability_miko02_aura = {}
LinkLuaModifier("modifier_ability_miko02_aura", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko02_aura:IsHidden() 		return false end
function modifier_ability_miko02_aura:IsPurgable()		return false end
function modifier_ability_miko02_aura:RemoveOnDeath() 	return true end
function modifier_ability_miko02_aura:IsDebuff()		return false end

function modifier_ability_miko02_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end -- global
function modifier_ability_miko02_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_ability_miko02_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_ability_miko02_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_ability_miko02_aura:GetModifierAura() return "modifier_ability_miko02_bonus" end
function modifier_ability_miko02_aura:IsAura() return true end

modifier_ability_miko02_bonus = {}
LinkLuaModifier("modifier_ability_miko02_bonus", "scripts/vscripts/abilities/abilitymiko.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_miko02_bonus:IsHidden() 		return true end
function modifier_ability_miko02_bonus:IsPurgable()		return false end
function modifier_ability_miko02_bonus:RemoveOnDeath() 	return true end
function modifier_ability_miko02_bonus:IsDebuff()		return false end

function modifier_ability_miko02_bonus:DeclareFunctions()
	return {
		--MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	}
end
--[[
function modifier_ability_miko02_bonus:GetModifierMoveSpeedBonus_Percentage()
    local bonus = self:GetStackCount() / 10	
	return bonus
end

function modifier_ability_miko02_bonus:GetModifierSpellAmplify_Percentage()
	local bonus = self:GetStackCount() / 10	
	return bonus
end
]]
function modifier_ability_miko02_bonus:GetModifierMoveSpeedBonus_Constant()
	local speed_bonus = self:GetStackCount() / 10 * self:GetAbility():GetSpecialValueFor("speed_bonus")
	return speed_bonus
end

function modifier_ability_miko02_bonus:GetModifierSpellAmplify_Percentage()
	local bonus = self:GetStackCount() / 10	* self:GetAbility():GetSpecialValueFor("bonus")
	return bonus
end 

function modifier_ability_miko02_bonus:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end

function modifier_ability_miko02_bonus:OnIntervalThink() --将数值存在count中 否则client读取不到
	--换成用层数代表是否半数效果(5)、全效果(10)、1.5倍效果(15)，再直接乘以提升属性
	if not IsServer() then return end
	local bonus = self:GetAbility():GetSpecialValueFor("bonus")
	local speed_bonus = self:GetAbility():GetSpecialValueFor("speed_bonus")
	local count = 10--层数
	if self:GetParent() ~= self:GetCaster() then 
		count = count * ( 0.5 )
	else
		if self:GetParent():FindAbilityByName("ability_thdots_miko02"):GetLevel() == 4 then 
			count = count * self:GetAbility():GetSpecialValueFor("max_level_bonus")
		end
    end
    self:SetStackCount(count)
end
