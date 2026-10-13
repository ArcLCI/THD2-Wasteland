abilityshou = class({})
SHOU01INTERVAL = 0
count01 = 0
ZDCS = 1
ZDCS_FLAG = true
SHOUEX_COUNT = 0

function Shou01AddParticle( keys )
	-- body
	local caster = keys.caster
	local effectIndex = ParticleManager:CreateParticle(
		"particles/econ/items/dazzle/dazzle_dark_light_weapon/dazzle_dark_shallow_grave_playerglow.vpcf", 
		PATTACH_CUSTOMORIGIN, 
		caster)
	SHOU01_EFFECT_INDEX = effectIndex
	ParticleManager:SetParticleControlEnt(effectIndex , 0, caster, 5, "attach_attack2", Vector(0,0,0), true)
end

function OnShou01SpellStart( keys )
	-- body
	local caster = keys.caster
	SHOU01INTERVAL = SHOU01INTERVAL + 0.1
end

function OnShou01AttackLanded( keys )
	-- body
	local caster = keys.caster
	local target = keys.target
	if is_spell_blocked(target) then return end
	local duration = keys.duration
	local damage = keys.damage
	local stun_bonus = keys.stun_bonus
	if not target:IsBuilding() then
		local damage_table = {
			ability = keys.ability,
			victim = target,
			attacker = caster,
			damage = damage + caster:GetIntellect(false) * keys.intellect_bonus,
			damage_type = keys.ability:GetAbilityDamageType(), 
			damage_flags = 0
		}
		UtilStun:UnitStunTarget(caster,target,(duration - SHOU01INTERVAL) * stun_bonus, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilityshou.lua:OnShou01AttackLanded:42")
		SHOU01INTERVAL = 0
		ParticleManager:DestroyParticleSystem(SHOU01_EFFECT_INDEX, true)
		UnitDamageTarget(damage_table)
	--特效
	--音效
	end
end

function OnShou01OnDestroy( keys )
	-- body
	SHOU01INTERVAL = 0
	ParticleManager:DestroyParticleSystem(SHOU01_EFFECT_INDEX, true)
end

ability_thdots_shou02 = {}

function ability_thdots_shou02:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()

	local light = CreateUnitByName(
			"npc_ability_shou_02_light"
			,targetPoint
			,false
			,caster
			,caster
			,caster:GetTeam()
	)
	local ability_dummy_unit = light:FindAbilityByName("ability_dummy_unit")
	light:AddNewModifier(caster, self, "modifier_ability_thdots_shou02_light", {duration = self:GetSpecialValueFor("duration")})
	ability_dummy_unit:SetLevel(1)
end

modifier_ability_thdots_shou02_light = {}
LinkLuaModifier("modifier_ability_thdots_shou02_light", "scripts/vscripts/abilities/abilityshou.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_shou02_light:IsHidden() 		return true end
function modifier_ability_thdots_shou02_light:IsPurgable()		return false end
function modifier_ability_thdots_shou02_light:RemoveOnDeath() 	return false end
function modifier_ability_thdots_shou02_light:IsDebuff()		return false end

function modifier_ability_thdots_shou02_light:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.03)
	self:OnIntervalThink()
end

function modifier_ability_thdots_shou02_light:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local unit = self:GetParent()
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local intellect_bonus = ability:GetSpecialValueFor("intellect_bonus")
	local effectIndex = ParticleManager:CreateParticle("particles/econ/items/rubick/rubick_arcana/rbck_arc_skywrath_mage_mystic_flare_beam.vpcf", PATTACH_POINT, unit)
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_ancient_seal_debuff_f.vpcf", PATTACH_POINT, unit)
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	targets = FindUnitsInRadius(caster:GetTeam(), unit:GetOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), 0, 0, false)
	if targets then 
		for _,v in pairs (targets) do
			local damage_table = {
				ability = ability,
				victim = v,
				attacker = caster,
				damage = damage + caster:GetIntellect(false) * intellect_bonus,
				damage_type = ability:GetAbilityDamageType(), 
				damage_flags = 0
			}
			UnitDamageTarget(damage_table)
			unit:EmitSound("Hero_StormSpirit.StaticRemnantExplode")
			unit:EmitSound("Hero_Earthshaker.Enchant")
			unit:RemoveModifierByName("modifier_ability_thdots_shou02_light")
			unit:ForceKill(true)
			effectIndex = ParticleManager:CreateParticle("particles/econ/items/storm_spirit/strom_spirit_ti8/storm_sprit_ti8_overload_discharge.vpcf", PATTACH_POINT, unit)
			ParticleManager:DestroyParticleSystem(effectIndex,false)
		end
	end
end

function modifier_ability_thdots_shou02_light:OnDestroy()
	if not IsServer() then return end
	local unit = self:GetParent()
	unit:ForceKill(true)
end

function Shou03OnKill( keys )
	-- body
	local caster = keys.caster
	local target = keys.unit
	local damage = keys.damage
	local radius = keys.radius
	local count = caster:GetModifierStackCount("modifier_ability_thdots_shouEx", caster)
	local casterPlayerID = caster:GetPlayerOwnerID()
	local GoldBountyAmount=keys.gold_bonus + FindTelentValue(caster,"special_bonus_unique_shou_2")
	target:EmitSound("Hero_Sandking.CausticBodyexplode")
	caster.ItemAbility_DonationGem_TriggerTime=GameRules:GetGameTime()	--加钱
	PlayerResource:SetGold(casterPlayerID,PlayerResource:GetUnreliableGold(casterPlayerID) + GoldBountyAmount,false)
	SendOverheadEventMessage(caster:GetOwner(),OVERHEAD_ALERT_GOLD,caster,GoldBountyAmount,nil)
	if count < 6 then
		caster:SetModifierStackCount("modifier_ability_thdots_shouEx", caster, count + 1)
	end
	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_aphotic_shield_explosion.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(effectIndex , 0, target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	effectIndex = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(),nil,radius,keys.ability:GetAbilityTargetTeam(),keys.ability:GetAbilityTargetType(),0,0,false)
	for _,v in pairs (targets) do
		local damage_table = {
					ability = keys.ability,
					victim = v,
					attacker = caster,
					damage = damage,
					damage_type = keys.ability:GetAbilityDamageType(), 
					damage_flags = 0
				}
		effectIndex = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_smooth_criminal/alchemist_smooth_criminal_unstable_concoction_explosion_streak.vpcf", PATTACH_POINT, v)
		ParticleManager:DestroyParticleSystem(effectIndex,false)
		UtilStun:UnitStunTarget(caster,v,keys.stun_duration, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilityshou.lua:Shou03OnKill:163")
		UnitDamageTarget(damage_table)
		--特效待测
	end
end

function Shou03Think(keys)
	local caster = keys.caster
	local ability = keys.ability
	if caster:HasModifier("modifier_item_wanbaochui") then
		caster:AddNewModifier(caster, ability, "modifier_ability_thdots_shou_wanbaochui",{})
	elseif caster:HasModifier("modifier_ability_thdots_shou_wanbaochui") then
		caster:RemoveModifierByName("modifier_ability_thdots_shou_wanbaochui")
	end
end

modifier_ability_thdots_shou_wanbaochui=class({})
LinkLuaModifier("modifier_ability_thdots_shou_wanbaochui","scripts/vscripts/abilities/abilityshou.lua",LUA_MODIFIER_MOTION_NONE)

--modifier 基础判定
function modifier_ability_thdots_shou_wanbaochui:IsHidden()      return true end
function modifier_ability_thdots_shou_wanbaochui:IsPurgable()        return false end
function modifier_ability_thdots_shou_wanbaochui:RemoveOnDeath()     return false end
function modifier_ability_thdots_shou_wanbaochui:IsDebuff()      return false end

function modifier_ability_thdots_shou_wanbaochui:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_ability_thdots_shou_wanbaochui:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetParent()
	self.amplify_gold = self:GetAbility():GetSpecialValueFor("amplify_gold")
	self.amplify = 0
	self:StartIntervalThink(0.03)
end

function modifier_ability_thdots_shou_wanbaochui:OnIntervalThink()
	if not IsServer() then return end
	self.amplify = math.floor(self.caster:GetGold()/self.amplify_gold)
	self:SetStackCount(self.amplify)
end

function modifier_ability_thdots_shou_wanbaochui:GetModifierSpellAmplify_Percentage()
	return self:GetStackCount()
end

function modifier_ability_thdots_shou_wanbaochui:OnDeath(keys)
	if not IsServer() then return end
	if keys.attacker == self:GetParent() and keys.unit:IsRealHero() then
		print(keys.unit:GetTimeUntilRespawn())
		keys.unit:SetContextThink("HasAegis",
		function()
			if keys.unit:GetTimeUntilRespawn() > 5 then
				print("no aeigs")
				local caster = self:GetParent()
				local casterPlayerID = caster:GetPlayerOwnerID()
				local GoldBountyAmount= self:GetAbility():GetSpecialValueFor("reduce_gold") * caster:GetGold() / 100
				print(GoldBountyAmount)
				PlayerResource:SetGold(casterPlayerID,PlayerResource:GetUnreliableGold(casterPlayerID) + GoldBountyAmount ,false)
				-- SendOverheadEventMessage(caster:GetOwner(),OVERHEAD_ALERT_GOLD,caster,GoldBountyAmount,nil)
			end
		end
		,
		0.03)
	end
end

function ShouExThink( keys )
	-- body
	local caster = keys.caster
	local ability = keys.ability
	local count = caster:GetModifierStackCount("modifier_ability_thdots_shouEx", caster)
	SHOUEX_COUNT = SHOUEX_COUNT + 1
	if SHOUEX_COUNT >= keys.persecond and count < keys.max then
		caster:SetModifierStackCount("modifier_ability_thdots_shouEx", caster, count + 1)
		SHOUEX_COUNT = 0
	end
	if count >= keys.max then
		SHOUEX_COUNT = 0
	end
	--天赋监听
	-- if FindTelentValue(caster,"special_bonus_unique_shou_1") ~= 0 and not caster:HasModifier("modifier_ability_thdots_shouEx_talent1") then
	-- 	print("shou02")
	-- 	caster:AddNewModifier(caster,ability,"modifier_ability_thdots_shouEx_talent1",{})
	-- 	-- caster:FindAbilityByName("ability_thdots_shou02"):SetCurrentAbilityCharges(FindTelentValue(caster,"special_bonus_unique_shou_1"))
	-- 	caster:FindAbilityByName("ability_thdots_shou02"):SetCurrentAbilityCharges(4)
	-- end
end

-- modifier_ability_thdots_shouEx_talent1 = {}  --天赋监听
-- LinkLuaModifier("modifier_ability_thdots_shouEx_talent1","scripts/vscripts/abilities/abilityshou.lua",LUA_MODIFIER_MOTION_NONE)
-- function modifier_ability_thdots_shouEx_talent1:IsHidden() 		return true end
-- function modifier_ability_thdots_shouEx_talent1:IsPurgable()		return false end
-- function modifier_ability_thdots_shouEx_talent1:RemoveOnDeath() 	return false end
-- function modifier_ability_thdots_shouEx_talent1:IsDebuff()		return false end

function ShouExOnSpellStart( keys )
	-- body
	local caster = keys.caster
	local ability = keys.ability
	local regen = keys.regen
	local count = caster:GetModifierStackCount("modifier_ability_thdots_shouEx", caster)
	if count >= 1 and not keys.event_ability:IsItem() and caster:GetHealth() ~= caster:GetMaxHealth() and caster:GetMana() ~= caster:GetMaxMana() then
		-- caster:SetHealth(caster:GetHealth() + (caster:GetMaxHealth()*regen))
		caster:Heal((caster:GetMaxHealth()*regen),caster)
		caster:SetMana(caster:GetMana() + (caster:GetMaxMana()*regen))
		caster:SetModifierStackCount("modifier_ability_thdots_shouEx", caster, count - 1 )
	end
end

ability_thdots_shou04 = {}

function ability_thdots_shou04:GetCooldown(level)
	local cd = self.BaseClass.GetCooldown(self, level)
	local telent = self:GetCaster():FindAbilityByName("special_bonus_unique_shou_3")
	if telent ~= nil then
		cd = cd + telent:GetSpecialValueFor("value")
	end
	return cd
end

function ability_thdots_shou04:OnAbilityPhaseStart()
	if not IsServer() then return true end
	-- 原固定 1.2 秒自晕改由原生前摇承担，订单过滤只保护主动取消。
	self:GetCaster():EmitSound("Hero_ElderTitan.EchoStomp.Channel")
	return true
end

function ability_thdots_shou04:OnAbilityPhaseInterrupted()
	if IsServer() then self:GetCaster():StopSound("Hero_ElderTitan.EchoStomp.Channel") end
end

function ability_thdots_shou04:OnOwnerDied()
	self:OnAbilityPhaseInterrupted()
end

function ability_thdots_shou04:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self
	local length = self:GetSpecialValueFor("length")
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local stun = self:GetSpecialValueFor("stun")
	self:OnAbilityPhaseInterrupted()
	caster.point = self:GetCursorPosition()
	Shou04DelayedAction({ caster = caster, ability = ability, length = length,
		radius = radius, damage = damage, stun = stun })
end

function Shou04OnSpellStart( keys )
	-- body
	local caster = keys.caster
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_6,0.17)
	caster.point = keys.ability:GetCursorPosition()
	caster:SetForwardVector(caster.point-caster:GetOrigin())
end

function Shou04DelayedAction( keys )
	-- body
	local caster = keys.caster
	if not caster:IsAlive() then return end 
	caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_6)
	-- THDReduceCooldown(keys.ability,FindTelentValue(caster,"special_bonus_unique_shou_3"))
	local targetPoint = caster.point
	FindClearSpaceForUnit(caster, targetPoint, false)
	StartSoundEventFromPosition("Hero_EarthShaker.EchoSlam", caster:GetOrigin())
	caster:AddNewModifier(caster, keys.ability, "modifier_ability_thdots_shou04", {Duration = 2})
	SHOU04_POINT = caster:GetAbsOrigin()
	SHOU04_VEC = caster:GetForwardVector()
	for k=0,4 do
		local x = SHOU04_VEC.x*math.cos(math.pi/2.5*k)-SHOU04_VEC.y*math.sin(math.pi/2.5*k)
		local y = SHOU04_VEC.x*math.sin(math.pi/2.5*k)+SHOU04_VEC.y*math.cos(math.pi/2.5*k)
		local rad = Vector(x,y,0) 
		local targets = FindUnitsInLine(caster:GetTeam(), SHOU04_POINT, SHOU04_POINT + rad * keys.length, nil, keys.radius, keys.ability:GetAbilityTargetTeam(), keys.ability:GetAbilityTargetType(), 0)
		for _,v in pairs (targets) do
			v:AddNewModifier(caster, keys.ability, "modifier_ability_thdots_shou04_damage", {duration = 1})
			UtilStun:UnitStunTarget(caster,v,keys.stun, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilityshou.lua:Shou04DelayedAction:344")
		end
	end
end

modifier_ability_thdots_shou04_stun = {}
LinkLuaModifier("modifier_ability_thdots_shou04_stun", "scripts/vscripts/abilities/abilityshou.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_shou04_stun:IsHidden() return true end
function modifier_ability_thdots_shou04_stun:IsPurgable() return false end
function modifier_ability_thdots_shou04_stun:RemoveOnDeath() return true end
function modifier_ability_thdots_shou04_stun:IsDebuff() return false end
function modifier_ability_thdots_shou04_stun:CheckState()
	return {} -- 兼容旧 ID；前摇不再通过自晕实现。
end

modifier_ability_thdots_shou04 = {}
LinkLuaModifier("modifier_ability_thdots_shou04", "scripts/vscripts/abilities/abilityshou.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_shou04:IsHidden() return true end
function modifier_ability_thdots_shou04:IsPurgable() return false end
function modifier_ability_thdots_shou04:RemoveOnDeath() return false end
function modifier_ability_thdots_shou04:IsDebuff() return false end

function modifier_ability_thdots_shou04:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end

function modifier_ability_thdots_shou04:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	for k=0,4 do
		local x = SHOU04_VEC.x*math.cos(math.pi/2.5*k)-SHOU04_VEC.y*math.sin(math.pi/2.5*k)
		local y = SHOU04_VEC.x*math.sin(math.pi/2.5*k)+SHOU04_VEC.y*math.cos(math.pi/2.5*k)
		local rad = Vector(x,y,0) 
		for i=1,10 do
			effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_ancient_seal_debuff_f.vpcf", PATTACH_POINT, caster)
			ParticleManager:SetParticleControl(effectIndex,0, SHOU04_POINT + rad *i* 100)
			ParticleManager:DestroyParticleSystem(effectIndex,false)
		end
	end
end

modifier_ability_thdots_shou04_damage = {}
LinkLuaModifier("modifier_ability_thdots_shou04_damage", "scripts/vscripts/abilities/abilityshou.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_shou04_damage:IsHidden() return true end
function modifier_ability_thdots_shou04_damage:IsPurgable() return false end
function modifier_ability_thdots_shou04_damage:RemoveOnDeath() return true end
function modifier_ability_thdots_shou04_damage:IsDebuff() return true end

function modifier_ability_thdots_shou04_damage:OnCreated()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local damage_table = {
		ability = ability,
		victim = parent,
		attacker = caster,
		damage = ability:GetSpecialValueFor("damage") + caster:GetIntellect(false) * ability:GetSpecialValueFor("intellect_bonus"),
		damage_type = ability:GetAbilityDamageType(), 
		damage_flags = 0
	}
	UnitDamageTarget(damage_table)
end
