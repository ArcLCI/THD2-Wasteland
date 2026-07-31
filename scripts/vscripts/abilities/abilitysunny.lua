--------------------------------------------------------
--光精「交叉反射」
--------------------------------------------------------
ability_thdots_sunnyEx = {}

function ability_thdots_sunnyEx:GetIntrinsicModifierName()
	return "modifier_ability_thdots_sunnyEx_passive"
end

modifier_ability_thdots_sunnyEx_passive = {}
LinkLuaModifier("modifier_ability_thdots_sunnyEx_passive","scripts/vscripts/abilities/abilitysunny.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sunnyEx_passive:IsHidden() 		return false end
function modifier_ability_thdots_sunnyEx_passive:IsPurgable()		return false end
function modifier_ability_thdots_sunnyEx_passive:RemoveOnDeath() 	return false end
function modifier_ability_thdots_sunnyEx_passive:IsDebuff()		return false end

function modifier_ability_thdots_sunnyEx_passive:OnCreated()
	self.caster 						= self:GetParent()
	self.int 							= self:GetAbility():GetSpecialValueFor("int")
	self.resistance 					= self:GetAbility():GetSpecialValueFor("resistance")
	self.regen_bonus 					= self:GetAbility():GetSpecialValueFor("regen_bonus")
	if IsServer() then
		self.is_daytime = nil
		-- EX被动只缓存昼夜状态，魔抗在属性查询时按当前智力计算。
		self:StartIntervalThink(0.5)
		self:OnIntervalThink()
	end
end

function modifier_ability_thdots_sunnyEx_passive:OnIntervalThink()
	if IsServer() then
		local is_daytime = GameRules:IsDaytime()
		if self.is_daytime == is_daytime then return end
		self.is_daytime = is_daytime
		self:SetStackCount(is_daytime and 1 or 0)
	end
end

function modifier_ability_thdots_sunnyEx_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_ability_thdots_sunnyEx_passive:GetModifierConstantHealthRegen()
	if self:GetStackCount() ~= 0 then
		return self:GetParent():GetLevel() * (self.regen_bonus or 0)
	else
		return 0
	end
end
function modifier_ability_thdots_sunnyEx_passive:GetModifierMagicalResistanceBonus()
	local int = self.int or 1
	if int == 0 then return 0 end
	-- 智力变化会在modifier属性查询时即时反映。
	return (self:GetParent():GetIntellect(false) / int) * (self.resistance or 0)
end

--------------------------------------------------------
--光符「黄光偏斜」
--------------------------------------------------------
ability_thdots_sunny01 = {}

function ability_thdots_sunny01:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local duration  			= self:GetSpecialValueFor("duration")
	-- 1技能隐身和移速合并到同一个modifier，移除0.03秒轮询。
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_sunny01", {duration = duration})

	EmitSoundOn("DOTA_Item.InvisibilitySword.Activate", caster)
end

modifier_ability_thdots_sunny01 = {}
LinkLuaModifier("modifier_ability_thdots_sunny01","scripts/vscripts/abilities/abilitysunny.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sunny01:IsHidden() 		return false end
function modifier_ability_thdots_sunny01:IsPurgable()		return false end
function modifier_ability_thdots_sunny01:RemoveOnDeath() 	return true end
function modifier_ability_thdots_sunny01:IsDebuff()		return false end

function modifier_ability_thdots_sunny01:OnCreated()
	if not IsServer() then return end
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_sunny_1") ~= 0 then
		self:SetStackCount(FindTelentValue(self:GetCaster(),"special_bonus_unique_sunny_1"))
	end
end

function modifier_ability_thdots_sunny01:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
	}
end

function modifier_ability_thdots_sunny01:OnAttackStart(keys)
	if not IsServer() then return end
	if keys.attacker == self:GetParent() then
		self:Destroy()
	end
end

function modifier_ability_thdots_sunny01:OnAbilityExecuted(keys)
	if not IsServer() then return end
	if keys.unit ~= self:GetParent() then return end
	if keys.ability == self:GetAbility() then return end
	self:Destroy()
end

function modifier_ability_thdots_sunny01:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
	}
end

function modifier_ability_thdots_sunny01:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_speed") + self:GetStackCount()
end

function modifier_ability_thdots_sunny01:GetModifierInvisibilityLevel()
	return 1
end

--------------------------------------------------------
--日热「冰质分解」
--------------------------------------------------------
ability_thdots_sunny02 = {}

function ability_thdots_sunny02:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_sunny02:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local radius  				= self:GetSpecialValueFor("radius")
	local damage  				= self:GetSpecialValueFor("damage")
	local stun_time  			= self:GetSpecialValueFor("stun_time")
	local int_bonus  			= self:GetSpecialValueFor("int_bonus")
	damage = damage + caster:GetIntellect(false) * int_bonus

	--特效音效
	sunny02_effect(caster,radius)
	caster:EmitSound("Hero_Tinker.LaserImpact")
	--伤害
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, self:GetAbilityTargetTeam(),
									self:GetAbilityTargetType(),0,0,false)
	for _,v in pairs(targets) do
		local damage_table = {
				ability = self,
				victim = v,
				attacker = caster,
				damage = damage,
				damage_type = self:GetAbilityDamageType(), 
				damage_flags = 0
		}
		UtilStun:UnitStunTarget(caster,v,stun_time)
		UnitDamageTarget(damage_table)
	end
end

function sunny02_effect(caster,radius)
	local origin = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector()
	local direct = math.atan2(forward.y, forward.x)
	local start_pos = origin + Vector(0, 0, 500)

	for k=0,4 do
		-- 2技能直接用SetParticleControl给坐标，替代dummy单位和0.03秒thinker。
		local rad = Vector(math.cos(direct+math.pi/2.5*k),math.sin(direct+math.pi/2.5*k),0) --五个方向
		local end_pos = origin + rad * radius + Vector(0, 0, 96)
		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControl(effectIndex, 0, start_pos)
		ParticleManager:SetParticleControl(effectIndex, 1, end_pos)
		ParticleManager:SetParticleControl(effectIndex, 9, start_pos)
		ParticleManager:DestroyParticleSystemTime(effectIndex,2)
	end
end

--------------------------------------------------------
--光符「蓝光反射」
--------------------------------------------------------
ability_thdots_sunny03 = {}

function ability_thdots_sunny03:ApplyBounceDamage(caster, target, damage, duration)
	target:EmitSound("Hero_Tinker.LaserImpact")
	target:AddNewModifier(caster,self, "modifier_ability_thdots_sunny03_debuff", {duration = duration * (1 - target:GetStatusResistance())})
	local damage_table = {
				ability = self,
				victim = target,
				attacker = caster,
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				damage_flags = 0
		}
	UnitDamageTarget(damage_table)
end

function ability_thdots_sunny03:CreateBounceParticle(source, target)
	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_CUSTOMORIGIN,source)
	ParticleManager:SetParticleControlEnt(effectIndex , 0, source, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(effectIndex , 1, target, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(effectIndex , 9, source, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:DestroyParticleSystemTime(effectIndex,2)
end

function ability_thdots_sunny03:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local damage = self:GetSpecialValueFor("damage")
	local damage_bonus = self:GetSpecialValueFor("damage_bonus") / 100
	local duration = self:GetSpecialValueFor("duration")
	local int_bonus = self:GetSpecialValueFor("int_bonus")
	local radius = self:GetSpecialValueFor("radius")
	local bounce_count = self:GetSpecialValueFor("num") + FindTelentValue(caster,"special_bonus_unique_sunny_2")
	damage = damage + caster:GetIntellect(false) * int_bonus

	-- 初始命中保留从施法者到目标的激光表现，并释放粒子。
	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_CUSTOMORIGIN,caster)
	ParticleManager:SetParticleControlEnt(effectIndex , 0, caster, 5, "attach_attack2", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(effectIndex , 1, target, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(effectIndex , 9, caster, 5, "attach_attack2", Vector(0,0,0), true)
	ParticleManager:DestroyParticleSystemTime(effectIndex,2)

	self:ApplyBounceDamage(caster, target, damage, duration)
	local hit_targets = {}
	hit_targets[target:entindex()] = true
	local current_target = target
	damage = damage * damage_bonus

	for i=1,bounce_count do
		local targets = FindUnitsInRadius(caster:GetTeam(), current_target:GetAbsOrigin(), nil, radius, self:GetAbilityTargetTeam(),
										self:GetAbilityTargetType(),0,0,false)
		DeleteDummy(targets)
		local candidates = {}
		for _,unit in pairs(targets) do
			-- 每次弹射在当前目标范围内随机选一个未命中过的其他敌方单位。
			if unit ~= current_target and not hit_targets[unit:entindex()] then
				table.insert(candidates, unit)
			end
		end
		if #candidates == 0 then break end

		local next_target = candidates[RandomInt(1, #candidates)]
		self:CreateBounceParticle(current_target, next_target)
		self:ApplyBounceDamage(caster, next_target, damage, duration)
		hit_targets[next_target:entindex()] = true
		current_target = next_target
		damage = damage * damage_bonus
	end
end

modifier_ability_thdots_sunny03_debuff = {}
LinkLuaModifier("modifier_ability_thdots_sunny03_debuff","scripts/vscripts/abilities/abilitysunny.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sunny03_debuff:IsHidden() 		return false end
function modifier_ability_thdots_sunny03_debuff:IsPurgable()		return true end
function modifier_ability_thdots_sunny03_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_sunny03_debuff:IsDebuff()		return true end

function modifier_ability_thdots_sunny03_debuff:DeclareFunctions()	
	return {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP
	}
end

function modifier_ability_thdots_sunny03_debuff:GetModifierHealAmplify_PercentageTarget()
	return self:GetAbility():GetSpecialValueFor("regen_reduce")
end

function modifier_ability_thdots_sunny03_debuff:GetModifierHPRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("regen_reduce")
end

function modifier_ability_thdots_sunny03_debuff:OnTooltip()
	return self:GetAbility():GetSpecialValueFor("regen_reduce")
end

--------------------------------------------------------
--激光「太阳爆发」
--------------------------------------------------------
ability_thdots_sunny04 = {}

function ability_thdots_sunny04:OnSpellStart()
	if not IsServer() then return end
	self.caster 						= self:GetCaster()
	self.damage 						= self:GetSpecialValueFor("damage")
	self.int_bonus 						= self:GetSpecialValueFor("int_bonus")
	self.damage = self.damage + self.caster:GetIntellect(false) * self.int_bonus
	self.caster:AddNewModifier(self.caster, self,"modifier_ability_thdots_sunny04", {})
	--设置白天
end

modifier_ability_thdots_sunny04 = {}
LinkLuaModifier("modifier_ability_thdots_sunny04","scripts/vscripts/abilities/abilitysunny.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sunny04:IsHidden() 		return false end
function modifier_ability_thdots_sunny04:IsPurgable()		return false end
function modifier_ability_thdots_sunny04:RemoveOnDeath() 	return true end
function modifier_ability_thdots_sunny04:IsDebuff()		return false end

function modifier_ability_thdots_sunny04:OnCreated()
	if not IsServer() then return end
	self.caster 						= self:GetParent()
	self.radius 						= self:GetAbility():GetSpecialValueFor("radius")
	self.constant 						= self:GetAbility():GetSpecialValueFor("constant")
	self.base_count 					= self:GetAbility():GetSpecialValueFor("base_count")
	self.length 						= self:GetAbility():GetSpecialValueFor("length")
	self.interval = 0.3
	self.count = self.base_count + math.floor(self.caster:GetMaxHealth()/self.constant)
	self.duration = self.count * self.interval
	if not self.orbs then
		self.orbs = {}
	end
	self:StartIntervalThink(self.interval)
	--特效音效
	self.sun = CreateUnitByName("npc_dummy_unit", 
    	                        Vector(99999,-99999,0), 
								false, 
							    self.caster, 
								self.caster, 
								self.caster:GetTeamNumber()
								)
								local ability_dummy_unit = self.sun:FindAbilityByName("ability_dummy_unit")
								ability_dummy_unit:SetLevel(1)
	self.sun:SetOrigin(Vector(99999,-99999,0))
	self.sun:AddAbility("phoenix_supernova")
	local sunness = self.sun:FindAbilityByName("phoenix_supernova")
	sunness:SetLevel(4)
	self.sun:CastAbilityImmediately(sunness, self.caster:GetPlayerOwnerID())
	self.sun_supernova_hidden = nil
	self.sun_check_interval = 0.2
	self.sun:SetContextThink("sunny04_kill", 
		function ()
			if GameRules:IsGamePaused() then return self.sun_check_interval end
			if self.caster:HasModifier("modifier_ability_thdots_sunny04") then
				local is_hidden = self.sun:HasModifier("modifier_phoenix_supernova_hiding")
				-- 只在modifier变化为hidden时重放。
				if self.sun_supernova_hidden ~= is_hidden and not is_hidden then
					self.sun:CastAbilityImmediately(sunness, self.caster:GetPlayerOwnerID())
				end
				self.sun_supernova_hidden = is_hidden
				return self.sun_check_interval
			else
				self.sun:ForceKill(true)
				return nil
			end
		end,
	self.sun_check_interval)
end

function modifier_ability_thdots_sunny04:OnIntervalThink()
	if not IsServer() then return end
	local caster = self.caster
	local ability = self:GetAbility()
	local width = self.radius
	local length = self.length

	local orb_thinker = CreateModifierThinker(
		self:GetCaster(),
		self,
		nil, -- 暂无额外modifier参数。
		{},
		self:GetCaster():GetOrigin(),
		self:GetCaster():GetTeamNumber(),
		false		
	)
	
	orb_thinker:EmitSound("Voice_Thdots_Seija.AbilitySeija01_1")
	ProjectileManager:CreateLinearProjectile({
				Ability = ability,
				EffectName = "particles/econ/items/puck/puck_alliance_set/puck_illusory_orb_aproset_linear_projectile.vpcf",
				vSpawnOrigin = caster:GetAbsOrigin(),
				fDistance = length,
				fStartRadius = width,
				fEndRadius = width,
				Source = caster,
				bHasFrontalCone = false,
				bReplaceExisting = false,
				iUnitTargetTeam = ability:GetAbilityTargetTeam(),							
				iUnitTargetType = ability:GetAbilityTargetType(),
				fExpireTime = GameRules:GetGameTime() + 3.0,
				bDeleteOnHit = false,
				vVelocity = (caster:GetForwardVector() * Vector(1, 1, 0)):Normalized() * 1200,
				bProvidesVision = true,	
				iVisionRadius 		= 250,
				iVisionTeamNumber 	= caster:GetTeamNumber(),
				ExtraData = {
					orb_thinker		= orb_thinker:entindex(),
				}
			})
	table.insert(self.orbs, orb_thinker:entindex())
	self.count = self.count - 1
	if self.count <= 0 then
		self:Destroy()
	end
end

function ability_thdots_sunny04:OnProjectileHit_ExtraData(target, location, data)
	if not IsServer() then return end
	if data ~= nil and data.orb_thinker ~= nil then
		local orb = EntIndexToHScript(data.orb_thinker)
		if orb ~= nil and not orb:IsNull() then
			orb:RemoveSelf()
		end
	end
	if target then
		target:EmitSound("Hero_Puck.IIllusory_Orb_Damage")
		local damage_table = {
					ability = self,
					victim = target,
					attacker = self.caster,
					damage = self.damage,
					damage_type = self:GetAbilityDamageType(), 
					damage_flags = 0
			}
		UnitDamageTarget(damage_table)
	end
end

function modifier_ability_thdots_sunny04:OnDestroy()
	if not IsServer() then return end
	if self.orbs ~= nil then
		for _, entIndex in pairs(self.orbs) do
			local orb = EntIndexToHScript(entIndex)
			if orb ~= nil and not orb:IsNull() then
				orb:RemoveSelf()
			end
		end
		self.orbs = nil
	end
	if self.sun ~= nil and not self.sun:IsNull() then
		self.sun:ForceKill(true)
	end
end

--------------------------------------------------------
--虹光「棱镜闪光」
--------------------------------------------------------
ability_thdots_sunny05 = {}

local function IsValidSunny05Caster(caster)
	return caster ~= nil
		and not caster:IsNull()
		and caster:IsRealHero()
		and not caster:IsIllusion()
end

function ability_thdots_sunny05:ClearSunnyIllusion(delay)
	if not IsServer() then return end
	if not self.illusion or self.illusion:IsNull() then
		self.illusion = nil
		return
	end

	local illusion = self.illusion
	local kill_func = function()
		if illusion and not illusion:IsNull() then
			illusion:ForceKill(true)
		end
		if self.illusion == illusion then
			self.illusion = nil
		end
	end

	if delay and delay > 0 then
		self:GetCaster():SetContextThink("sunny05_delay", kill_func, delay)
	else
		kill_func()
	end
end

function ability_thdots_sunny05:OnInventoryContentsChanged()
	if IsServer() then
		local caster = self:GetCaster()
		-- Bot 英雄不属于 IsOwnedByAnyPlayer 的范围，但仍应正常解锁万宝槌技能。
		if not IsValidSunny05Caster(caster) then return end
		if caster:HasModifier("modifier_item_wanbaochui") then
			self:SetHidden(false)
		else
			-- 5技能只清理当前缓存的镜像句柄，不再全图99999扫描友方单位。
			self:ClearSunnyIllusion(0.03)
			self:SetHidden(true)
		end
	end
end

function ability_thdots_sunny05:OnHeroCalculateStatBonus()
	self:OnInventoryContentsChanged()
end

function ability_thdots_sunny05:OnSpellStart()
	if not IsServer() then return end
	self.caster 						= self:GetCaster()
	-- 只排除幻象和非真实英雄，允许真实 Bot 英雄施放并创建镜像。
	if not IsValidSunny05Caster(self.caster) then return end
	self.target 						= self:GetCursorTarget()
	if not self.target or self.target:IsNull() then return end
	local duration  					= self:GetSpecialValueFor("duration")
	self:ClearSunnyIllusion()
	self.caster:SetContextThink("sunny05",
		function()
			self.illusion = CreateIllusionTHD(self,self.target,nil,0,0,duration,true)
			if self.illusion and not self.illusion:IsNull() then
				self.illusion:AddNewModifier(self.caster, self, "modifier_ability_thdots_sunny05", {})
			else
				print("[Sunny05] CreateIllusionTHD failed")
			end
		end,
	0.03)
end

modifier_ability_thdots_sunny05 = {}
LinkLuaModifier("modifier_ability_thdots_sunny05","scripts/vscripts/abilities/abilitysunny.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sunny05:IsHidden() 		return false end
function modifier_ability_thdots_sunny05:IsPurgable()		return false end
function modifier_ability_thdots_sunny05:RemoveOnDeath() 	return true end
function modifier_ability_thdots_sunny05:IsDebuff()			return false end

function modifier_ability_thdots_sunny05:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE]			= true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] 		= true,
		[MODIFIER_STATE_DISARMED]				= true
	}
end

function modifier_ability_thdots_sunny05:OnCreated()
	if not IsServer() then return end
	self.illusion = self:GetParent()
	self.target = self:GetAbility().target
	-- 镜像血量同步从0.03秒降到0.1秒。
	self:StartIntervalThink(0.1)
end

function modifier_ability_thdots_sunny05:OnIntervalThink()
	if not IsServer() then return end
	if not self.target or self.target:IsNull() or not self.target:IsAlive() then
		self:GetParent():ForceKill(true)
		self:Destroy()
		return
	end

	self.health = self.target:GetHealth()
	local percent = self.health/self.target:GetMaxHealth()
	if self.target:IsAlive() then
		self.illusion:SetHealth(self.illusion:GetMaxHealth()*percent)
	else
		self:GetParent():ForceKill(true)
		self:Destroy()
	end
end

function modifier_ability_thdots_sunny05:OnDestroy()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if ability and ability.illusion == self:GetParent() then
		ability.illusion = nil
	end
end
