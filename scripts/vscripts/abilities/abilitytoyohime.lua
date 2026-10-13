g_toyohime_players_coord={}--公用坐标表
Toyohime04_particle=nil
ability_thdots_toyohimeEx ={}
function ability_thdots_toyohimeEx:GetManaCost()
	return self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("extra_manacost_pct") / 100
end
function ability_thdots_toyohimeEx:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function ability_thdots_toyohimeEx:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:EmitSound("Hero_ArcWarden.MagneticField.Cast")
	--创建坐标
	CreateModifierThinker(caster, self, "modifier_ability_thdots_toyohimeex_thinker",{ duration = self:GetSpecialValueFor("duration") }, self:GetCursorPosition(), self:GetCaster():GetTeamNumber(),false)
	--创建脚下坐标
	CreateModifierThinker(caster, self, "modifier_ability_thdots_toyohimeex_thinker",{ duration = self:GetSpecialValueFor("duration") }, self:GetCaster():GetAbsOrigin(),self:GetCaster():GetTeamNumber(),false)
end
function ability_thdots_toyohimeEx:GetIntrinsicModifierName()
	return "modifier_ability_thdots_toyohime_exbuff"
end
modifier_ability_thdots_toyohime_exbuff = {}
LinkLuaModifier("modifier_ability_thdots_toyohime_exbuff", "scripts/vscripts/abilities/abilitytoyohime.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_toyohime_exbuff:IsHidden() return true end
function modifier_ability_thdots_toyohime_exbuff:OnCreated()
	self.parent = self:GetParent()
end

function modifier_ability_thdots_toyohime_exbuff:CheckState()
	if self.parent:HasModifier("modifier_ability_thdots_toyohimeex_mark2") then
		return {[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,}
	end
	return nil
end
modifier_ability_thdots_toyohimeex_thinker = {} --坐标
LinkLuaModifier("modifier_ability_thdots_toyohimeex_thinker", "scripts/vscripts/abilities/abilitytoyohime.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_toyohimeex_thinker:RemoveOnDeath() return true end

function modifier_ability_thdots_toyohimeex_thinker:OnCreated()
	if not IsServer() then return end
	self:GetParent():EmitSound("Hero_ArcWarden.MagneticField")
	self.ability  = self:GetAbility()
	self.radius   = 400
	self.interval = self.ability:GetSpecialValueFor("interval")
    self.thinker            = self:GetParent()
    self.caster             = self.thinker:GetOwner()
    local playerid = self.caster:GetPlayerOwnerID()
    g_toyohime_players_coord[playerid] = g_toyohime_players_coord[playerid] or {}
    --创建属于施法者的坐标表

    self.index = self.thinker:GetEntityIndex()
    g_toyohime_players_coord[playerid][self.index] = self.thinker--坐标记录
    --print(g_toyohime_players_coord[playerid][self.index])
	local units = FindUnitsInRadius(self.caster:GetTeam(),self:GetParent():GetAbsOrigin(),nil,400,DOTA_UNIT_TARGET_TEAM_BOTH,DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) --循环查找范围内单位
	for _, unit in pairs(units) do
		unit:AddNewModifier(self.caster, self.ability, "modifier_ability_thdots_toyohimeex_mark",{ duration = self.interval+0.1 }) --添加标记
	end
	self:StartIntervalThink(0.4)
	local new_pos = self:GetParent():GetOrigin()

	local nTeam = self:GetCaster():GetTeamNumber()
	local nEnemyTeam = nil
	if nTeam == DOTA_TEAM_GOODGUYS then
		nEnemyTeam = DOTA_TEAM_BADGUYS
	else
		nEnemyTeam = DOTA_TEAM_GOODGUYS
	end
	local effectIndex1 = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast5.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(effectIndex1, 0, new_pos)
	ParticleManager:SetParticleControl(effectIndex1, 1, Vector(20, 0, 0))
	ParticleManager:ReleaseParticleIndex(effectIndex1)
	local effectIndex2 = ParticleManager:CreateParticleForTeam("models/toyohime/fx/toyohime_cast5_enemy.vpcf", PATTACH_WORLDORIGIN, nil,nEnemyTeam)
	ParticleManager:SetParticleControl(effectIndex2, 0, new_pos)
	ParticleManager:SetParticleControl(effectIndex2, 1, Vector(20, 0, 0))
	ParticleManager:ReleaseParticleIndex(effectIndex2)
end

function modifier_ability_thdots_toyohimeex_thinker:OnIntervalThink() --使用计时器实现类光环
	local units = FindUnitsInRadius(self.caster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, 400,DOTA_UNIT_TARGET_TEAM_BOTH,DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) --循环查找范围内单位
	for _, unit in pairs(units) do
		unit:AddNewModifier(self.caster, self.ability, "modifier_ability_thdots_toyohimeex_mark",{ duration = self.interval }) --添加标记
		unit:AddNewModifier(self.caster, self.ability, "modifier_ability_thdots_toyohimeex_mark2",{ duration = 0.5 }) --添加标记2,保证标记不会消失
	end
end

function modifier_ability_thdots_toyohimeex_thinker:OnRemoved()
    if not IsServer() then return end
    local playerid=self.caster:GetPlayerOwnerID()
	self:GetParent():StopSound("Hero_ArcWarden.MagneticField")
    g_toyohime_players_coord[playerid][self.index]=nil
end

modifier_ability_thdots_toyohimeex_mark2 = {} 
LinkLuaModifier("modifier_ability_thdots_toyohimeex_mark2", "scripts/vscripts/abilities/abilitytoyohime.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_toyohimeex_mark2:IsHidden() return true end
function modifier_ability_thdots_toyohimeex_mark2:IsPurgable() return false end
function modifier_ability_thdots_toyohimeex_mark2:RemoveOnDeath() return true end

modifier_ability_thdots_toyohimeex_mark = {}
LinkLuaModifier("modifier_ability_thdots_toyohimeex_mark", "scripts/vscripts/abilities/abilitytoyohime.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_toyohimeex_mark:IsHidden() return true end
function modifier_ability_thdots_toyohimeex_mark:IsPurgable() return false end
function modifier_ability_thdots_toyohimeex_mark:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	--判断标记所有者的团队，然后上buff
	if self.parent:IsOpposingTeam(self:GetCaster():GetTeam()) then
		self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_ability_thdots_toyohimeex_debuff", {})
	else
		self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_ability_thdots_toyohimeex_buff", {})
	end
	self:StartIntervalThink(1)
end
function modifier_ability_thdots_toyohimeex_mark:OnIntervalThink() --使用计时器实现类光环
	if self.parent:IsOpposingTeam(self:GetCaster():GetTeam()) then
		self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_ability_thdots_toyohimeex_debuff", {})
	else
		self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_ability_thdots_toyohimeex_buff", {})
		if self.caster.toyohime_02_buff ==true then
			self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_ability_thdots_toyohime02_buff", {})
		end
	end
end
function modifier_ability_thdots_toyohimeex_mark:OnRemoved()
	if not IsServer() then return end
	if not self.parent:HasModifier("modifier_ability_thdots_toyohimeex_mark2") then
		self.parent:RemoveModifierByName("modifier_ability_thdots_toyohimeex_buff")
		self.parent:RemoveModifierByName("modifier_ability_thdots_toyohimeex_debuff")
		self.parent:RemoveModifierByName("modifier_ability_thdots_toyohime02_buff")
	end
end

modifier_ability_thdots_toyohimeex_buff = {}
LinkLuaModifier("modifier_ability_thdots_toyohimeex_buff", "scripts/vscripts/abilities/abilitytoyohime.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_toyohimeex_buff:IsHidden() return false end
function modifier_ability_thdots_toyohimeex_buff:IsPurgable()return self:GetCaster():FindAbilityByName("special_bonus_unique_toyohime_5"):GetLevel() ~= 0 end

function modifier_ability_thdots_toyohimeex_buff:CheckState()
	if self:GetCaster():HasScepter() then
		return {[MODIFIER_STATE_FORCED_FLYING_VISION]=true,}
	end
end

function modifier_ability_thdots_toyohimeex_buff:GetEffectName() return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf" end
function modifier_ability_thdots_toyohimeex_buff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
modifier_ability_thdots_toyohimeex_debuff = {}
LinkLuaModifier("modifier_ability_thdots_toyohimeex_debuff", "scripts/vscripts/abilities/abilitytoyohime.lua",
	LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_toyohimeex_debuff:IsHidden() return false end

function modifier_ability_thdots_toyohimeex_debuff:IsPurgable()
	return self:GetCaster():FindAbilityByName("special_bonus_unique_toyohime_5"):GetLevel() == 0
end

function modifier_ability_thdots_toyohimeex_debuff:IsPurgeException() return false end

function modifier_ability_thdots_toyohimeex_debuff:RemoveOnDeath() return true end

function modifier_ability_thdots_toyohimeex_debuff:OnCreated()
	if not IsServer() then return end
	if self:GetCaster():FindAbilityByName("special_bonus_unique_toyohime_1"):GetLevel() ~= 0 then
		self.add_count = 2
	else
		self.add_count = 1
	end
	--self.damage_amplify_pct = self:GetAbility():GetSpecialValueFor("damage_amplify_pct")
	--self.damage_reduce_pct = self:GetAbility():GetSpecialValueFor("damage_reduce_pct")
	self:SetStackCount(self.add_count)
	self:StartIntervalThink(1)
end

function modifier_ability_thdots_toyohimeex_debuff:OnIntervalThink()
	if not IsServer() then return end
	if self:GetParent():HasModifier("modifier_ability_thdots_toyohimeex_mark2") then
		local new_count = self:GetStackCount() + self.add_count
		self:SetStackCount(new_count)
	end
	if self:GetCaster():FindAbilityByName("special_bonus_unique_toyohime_2"):GetLevel() ~= 0 then
		local damage_table = {
			ability = self:GetAbility(),
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = self:GetParent():GetHealthDeficit() * 0.04,
			damage_type = self:GetAbility():GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE
		}
		UnitDamageTarget(damage_table)
	end
end

function modifier_ability_thdots_toyohimeex_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end

function modifier_ability_thdots_toyohimeex_debuff:GetModifierIncomingDamage_Percentage()
	return self:GetStackCount()
end

function modifier_ability_thdots_toyohimeex_debuff:GetModifierDamageOutgoing_Percentage()
	return -self:GetStackCount()
end

function modifier_ability_thdots_toyohimeex_debuff:GetEffectName()
	return "particles/units/heroes/hero_elder_titan/elder_titan_natural_order_physical.vpcf"
end

ability_thdots_toyohime01 = {}

--------------------------------------------------------------------------------
-- Init Abilities
function ability_thdots_toyohime01:Spawn()
	-- register custom indicator
	if not IsServer() then
		CustomIndicator:RegisterAbility( self )
		return
	end
end

--------------------------------------------------------------------------------
-- Ability Custom Indicator (using CustomIndicator library, this section is Client Lua only)
function ability_thdots_toyohime01:CreateCustomIndicator()
	local particle_cast = "particles/thd2/heroes/toyohime/hero_snapfire_shotgun_range_finder_aoe.vpcf"
	self.effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
end

function ability_thdots_toyohime01:UpdateCustomIndicator(loc)
	-- get data
	local origin = self:GetCaster():GetAbsOrigin()

	-- get direction
	local direction = loc - origin
	direction.z = 0
	direction = direction:Normalized()

	ParticleManager:SetParticleControl(self.effect_cast, 0, origin)
	ParticleManager:SetParticleControl(self.effect_cast, 1, origin + direction * (self:GetCastRange(loc, nil) + 100))
	ParticleManager:SetParticleControl(self.effect_cast, 6, origin)
end

function ability_thdots_toyohime01:DestroyCustomIndicator()
	print("destroy")
	ParticleManager:DestroyParticle(self.effect_cast, true)
	ParticleManager:ReleaseParticleIndex(self.effect_cast)
end

--------------------------------------------------------------------------------
function ability_thdots_toyohime01:OnSpellStart()
	local target_point = self:GetCursorPosition()
	local caster = self:GetCaster()
	local o = caster:GetOrigin()
	self.cuttrees = self:GetAutoCastState()
	EmitSoundOn("Hero_DrowRanger.Silence", caster)
	local particle_gust = "models/toyohime/fx/toyohime_cast1.vpcf"
	local gust_projectile = {
		Ability = self,
		EffectName = particle_gust,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = 700,
		fStartRadius = 125,
		fEndRadius = 200,
		fExpireTime = GameRules:GetGameTime() + 10.0,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = false,
		vVelocity = (((target_point - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()) * 2000,
		bProvidesVision = false,
		ExtraData = {
			x = o.x,
			y = o.y,
		}
	}
	ProjectileManager:CreateLinearProjectile(gust_projectile)
end

--------------------------------------------------------------------------------
-- Projectile
function ability_thdots_toyohime01:OnProjectileThink(vLocation)
	if self.cuttrees then
		GridNav:DestroyTreesAroundPoint(vLocation, 200, false)	
	end
end
function ability_thdots_toyohime01:OnProjectileHit_ExtraData(target, location, data)
	if not target then return end

	-- get value
	local silence = self:GetSpecialValueFor("duration")
	local max_duration = self:GetSpecialValueFor("knockback_duration_max")
	local max_dist = self:GetSpecialValueFor("knockback_distance_max")
	local min_duration = self:GetSpecialValueFor("knockback_duration_min")
	local min_dist = self:GetSpecialValueFor("knockback_distance_min")
	local caster = self:GetCaster()
	-- calculate distance & direction
	local vec = Vector(data.x, data.y, 0) - target:GetOrigin()
	vec.z = 0
	local distance = vec:Length2D()
	local proportion = (1 - distance / self:GetSpecialValueFor("point_blank_range"))
	distance = min_dist + proportion * max_dist
	local duration = min_duration + max_duration * proportion
	vec = vec:Normalized()
	local knockback_properties = {
		center_x           = data.x + 1,
		center_y           = data.y + 1,
		center_z           = 0,
		duration           = duration * (1 - target:GetStatusResistance()),
		knockback_duration = duration,
		knockback_distance = distance,
		knockback_height   = 0,
		should_stun        = 0
	}
	--print(distance)
	target:AddNewModifier(caster, self, "modifier_knockback", knockback_properties)
	local damage = self:GetSpecialValueFor("damage") 
	if target:HasModifier("modifier_ability_thdots_toyohimeex_mark") then
		damage = damage + caster:GetMana() * self:GetSpecialValueFor("damage_mana_pct")/100
		target:AddNewModifier(caster, nil, "modifier_muted", {duration= silence})
	end
	local damage_table = {
		ability = self,
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		damage_flags = DOTA_DAMAGE_FLAG_NONE
	}
	UnitDamageTarget(damage_table)
	-- apply silence
	UtilSilence:UnitSilenceTarget(caster, target, silence)
	UnitDisarmedTarget(caster, target, silence)
	-- play effects
	self:PlayEffects(target)
end

--------------------------------------------------------------------------------
function ability_thdots_toyohime01:PlayEffects(target)
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_drow/drow_hero_silence.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(effect_cast)
end

modifier_ability_thdots_toyohime02_buff = {}
LinkLuaModifier("modifier_ability_thdots_toyohime02_buff", "scripts/vscripts/abilities/abilitytoyohime.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_toyohime02_buff:IsHidden() return false end
function modifier_ability_thdots_toyohime02_buff:OnCreated()
	if not IsServer() then return end
end

function modifier_ability_thdots_toyohime02_buff:CheckState()
	return {[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,}
end

ability_thdots_toyohime02 = class({})

function ability_thdots_toyohime02:OnAbilityPhaseStart()
	if not IsServer() then return end
	self.playerid 				= self:GetCaster():GetPlayerOwnerID()
	local target 				= self:GetCursorPosition()
	local distance				= 0
	local maxdistance 			= 800
	self.mincoord				= nil
	for _,coord in pairs(g_toyohime_players_coord[self.playerid]) do
		distance = (coord:GetAbsOrigin() - target):Length2D()
		if distance < maxdistance then
			maxdistance = distance
			self.mincoord = coord
			print(self.mincoord:GetOrigin())
		end
	end--查找最近坐标
	print("self.mincoord")
	print(self.mincoord)
	if self.mincoord ~= nil then 
		return true 
	else
		return UF_FAIL_OTHER
	end
end

function ability_thdots_toyohime02:OnSpellStart()
	if not IsServer() then return end
	local target_point  = self.mincoord:GetOrigin()
	local caster        = self:GetCaster()
	local deal_duration = 2
	local radius        = 400
	self.maxdistance = 0
	self.maxcoord = nil
	self:PlayEffects(target_point, deal_duration)
	caster:EmitSound("Hero_VoidSpirit.Dissimilate.Cast")

	--特效加载
	self.effect_cast1 = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast2_orange.vpcf", PATTACH_WORLDORIGIN, nil) 
	self.effect_cast2 = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast2_anticlockwise.vpcf",PATTACH_WORLDORIGIN, nil)
	self.effect_cast3 = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast2_down.vpcf", PATTACH_WORLDORIGIN,nil)
	ParticleManager:SetParticleControl(self.effect_cast1, 0, target_point)
	ParticleManager:SetParticleControl(self.effect_cast2, 0, target_point)
	ParticleManager:SetParticleControl(self.effect_cast3, 0, target_point)
	for _, coord in pairs(g_toyohime_players_coord[self.playerid]) do
		self.distance = (coord:GetAbsOrigin() - target_point):Length2D()
		if self.distance > self.maxdistance then
			self.maxdistance = self.distance
			self.maxcoord = coord
		end
		print("find")
	end
	local end_point  =self.maxcoord:GetOrigin() --预先锁定最远坐标
	EmitSoundOnLocationWithCaster(target_point, "Hero_VoidSpirit.Dissimilate.Portals", self:GetCaster())
	self.effect_cast1n = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast2.vpcf", PATTACH_WORLDORIGIN, nil)
	self.effect_cast2n = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast2_clockwise.vpcf",PATTACH_WORLDORIGIN, nil)
	self.effect_cast3n = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast2_up.vpcf", PATTACH_WORLDORIGIN,nil)
	ParticleManager:SetParticleControl(self.effect_cast1n, 0, end_point)
	ParticleManager:SetParticleControl(self.effect_cast2n, 0, end_point)
	ParticleManager:SetParticleControl(self.effect_cast3n, 0, end_point)
	local nTeam = caster:GetTeamNumber()
	caster.toyohime_02_buff = true
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("toyohime02_buff_delay"),
		function()
		caster.toyohime_02_buff = false
		end,5)
	local nEnemyTeam = nil
	if nTeam == DOTA_TEAM_GOODGUYS then
		nEnemyTeam = DOTA_TEAM_BADGUYS
	else
		nEnemyTeam = DOTA_TEAM_GOODGUYS
	end
	MinimapEvent(nTeam, caster, end_point.x, end_point.y, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING,2)
	MinimapEvent(nEnemyTeam, caster, end_point.x, end_point.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING,2)
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("toyohime02_tele_delay"),
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			local playerid = caster:GetPlayerOwnerID()
			local maxcoord = nil
			self.maxdistance = 0
			for _, coord in pairs(g_toyohime_players_coord[playerid]) do
				self.distance = (coord:GetAbsOrigin() - target_point):Length2D()
				--print(self.distance)
				if self.distance > self.maxdistance then
					self.maxdistance = self.distance
					maxcoord = coord
					--print(coord)
				end
			end --查找最远坐标
			ParticleManager:DestroyParticle(self.effect_cast1, false)
			ParticleManager:ReleaseParticleIndex(self.effect_cast1)
			ParticleManager:DestroyParticle(self.effect_cast2, false)
			ParticleManager:ReleaseParticleIndex(self.effect_cast2)
			ParticleManager:DestroyParticle(self.effect_cast3, false)
			ParticleManager:ReleaseParticleIndex(self.effect_cast3)
			ParticleManager:DestroyParticle(self.effect_cast1n, false)
			ParticleManager:ReleaseParticleIndex(self.effect_cast1n)
			ParticleManager:DestroyParticle(self.effect_cast2n, false)
			ParticleManager:ReleaseParticleIndex(self.effect_cast2n)
			ParticleManager:DestroyParticle(self.effect_cast3n, false)
			ParticleManager:ReleaseParticleIndex(self.effect_cast3n)
			if maxcoord ~= nil then
				--print("self.maxcoord")
				--print(maxcoord)
				local Vector = maxcoord:GetAbsOrigin()
				local friends = FindUnitsInRadius(caster:GetTeam(), target_point, nil, radius,DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,false)
				for _, hero in pairs(friends) do
					FindClearSpaceForUnit(hero,hero:GetOrigin() + Vector - target_point, false)
				end
				EmitSoundOn("Hero_VoidSpirit.Dissimilate.TeleportIn",caster)
				local damage = self:GetSpecialValueFor("AbilityDamage")
				local enemies1 = FindUnitsInRadius(caster:GetTeam(), target_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				local enemies2 = FindUnitsInRadius(caster:GetTeam(), Vector, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				for _, unit in pairs(enemies1) do
					UtilStun:UnitStunTarget(caster, unit, deal_duration, (UtilStun.TraceSource and UtilStun:TraceSource(function() return self end) or nil), "script:scripts/vscripts/abilities/abilitytoyohime.lua:OnSpellStart:473")
					local damage_table = {
						ability = self,
						victim = unit,
						attacker = caster,
						damage = damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						damage_flags = DOTA_DAMAGE_FLAG_NONE
					}
					--print("toyohime02damage"..damage)
					UnitDamageTarget(damage_table)
				end
				for _, unit in pairs(enemies2) do
					UtilStun:UnitStunTarget(caster, unit, deal_duration, (UtilStun.TraceSource and UtilStun:TraceSource(function() return self end) or nil), "script:scripts/vscripts/abilities/abilitytoyohime.lua:OnSpellStart:486")
				end
				EmitSoundOn("Hero_VoidSpirit.Dissimilate.Stun",caster)
			else
				--print("nill--") --这里应该有施法失败的提示
			end
			return nil
		end,
		2)
end

function ability_thdots_toyohime02:PlayEffects(center_pos, duration)
	-- generate data
	local caster = self:GetCaster()
	local angle = math.pi / 20
	for i = 1, 40 do
		local position = Vector(center_pos.x + 400 * math.sin(angle), center_pos.y + 400 * math.cos(angle), center_pos.z)
		angle = angle + math.pi / 20
		local blocker = CreateModifierThinker(
			caster,                            -- player source
			self,                              -- ability source
			"modifier_earthshaker_fissure_lua_thinker", -- modifier name
			{ duration =  2 },                  -- kv
			position,
			caster:GetTeamNumber(),
			true
		)
		blocker:SetHullRadius(48)
	end
end

--直接使用imba的沟壑代码（失效）
LinkLuaModifier("modifier_earthshaker_fissure_lua_thinker", "scripts/vscripts/abilities/abilitytoyohime.lua",LUA_MODIFIER_MOTION_NONE)

modifier_earthshaker_fissure_lua_thinker = {}
function modifier_earthshaker_fissure_lua_thinker:IsHidden()
	return true
end

function modifier_earthshaker_fissure_lua_thinker:IsPurgable()
	return false
end

ability_thdots_toyohime03 = {}

function ability_thdots_toyohime03:GetCooldown(level)
	local cd = self.BaseClass.GetCooldown(self, level)
	local telent = self:GetCaster():FindAbilityByName("special_bonus_unique_toyohime_4")
	if telent then
		cd = cd + telent:GetSpecialValueFor("value")
	end
	return cd
end

function ability_thdots_toyohime03:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("ability_thdots_toyohimeEx")
	local duration = self:GetSpecialValueFor("aura_duration")
	local playerid = caster:GetPlayerOwnerID()
	if ability then
	--创建坐标
	self.thinker1=CreateModifierThinker(caster,ability, "modifier_ability_thdots_toyohimeex_thinker",{ duration = duration }, self:GetCursorPosition(), self:GetCaster():GetTeamNumber(),false)
	--创建脚下坐标
	CreateModifierThinker(caster,ability, "modifier_ability_thdots_toyohimeex_thinker",{ duration = duration }, self:GetCaster():GetAbsOrigin(),self:GetCaster():GetTeamNumber(),false)
	end
	local maxdistance = 0
	local maxcoord = nil
	FindClearSpaceForUnit(caster, self:GetCursorPosition(), true) --传送
	EmitSoundOn( "Hero_ArcWarden.TempestDouble", self:GetCaster())
	for _, coord in pairs(g_toyohime_players_coord[playerid]) do
		self.distance = CalcDistanceBetweenEntityOBB(caster, coord)
		if self.distance > maxdistance then
			maxdistance = self.distance
			maxcoord = coord
		end
		print("find")
	end --查找最远坐标
	local nTeam = caster:GetTeamNumber()
	local nEnemyTeam = nil
	if nTeam == DOTA_TEAM_GOODGUYS then
		nEnemyTeam = DOTA_TEAM_BADGUYS
	else
		nEnemyTeam = DOTA_TEAM_GOODGUYS
	end
	local end_point = maxcoord:GetAbsOrigin()
	MinimapEvent(nTeam, caster, end_point.x, end_point.y, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING,1)
	MinimapEvent(nEnemyTeam, caster, end_point.x, end_point.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING,1)
	--local effectIndex = ParticleManager:CreateParticle("particles/econ/items/tinker/boots_of_travel/teleport_end_bots.vpcf", PATTACH_ABSORIGIN, caster)
	--ParticleManager:SetParticleControl(effectIndex, 0, maxcoord:GetAbsOrigin())
	--ParticleManager:DestroyParticleSystemTime(effectIndex, 10)
	caster:SwapAbilities(self:GetAbilityName(), "ability_thdots_toyohime03_back", false, true)
	caster:FindAbilityByName("ability_thdots_toyohime03_back"):StartCooldown(0.5)
	caster.has_ended03 = false
	--local effectIndex = ParticleManager:CreateParticle("particles/econ/items/tinker/boots_of_travel/teleport_start_bots.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.thinker1)
	--ParticleManager:DestroyParticleSystemTime(effectIndex, 10)
	caster:SetContextThink(DoUniqueString("toyohime03_reverse"),
		function()
			if caster.has_ended03 then return end
			caster:SwapAbilities(self:GetAbilityName(), "ability_thdots_toyohime03_back", true, false)
			return nil
		end, self:GetSpecialValueFor("duration"))
end

ability_thdots_toyohime03_back = {}

function ability_thdots_toyohime03_back:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local playerid = caster:GetPlayerOwnerID()
	local maxdistance = 0
	local maxcoord = nil
	for _, coord in pairs(g_toyohime_players_coord[playerid]) do
		self.distance = CalcDistanceBetweenEntityOBB(caster, coord)
		if self.distance > maxdistance then
			maxdistance = self.distance
			maxcoord = coord
		end
		print("find")
	end --查找最远坐标
	if maxcoord ~= nil then
		caster:SetOrigin(maxcoord:GetOrigin())
		EmitSoundOn( "Hero_ArcWarden.TempestDouble", self:GetCaster() )
	else
		print("nill")
	end
	caster:SwapAbilities( "ability_thdots_toyohime03", "ability_thdots_toyohime03_back", true, false)
	caster.has_ended03 = true
end

function OnToyohime04SpellStart(keys)
	GameRules:BeginNightstalkerNight(keys.Duration)
	keys.caster.has_ended04 = false
	keys.ability:ApplyDataDrivenModifier(keys.caster,keys.caster, "modifier_thdots_toyohime04_think_interval",{ duration = keys.duration })
	EmitGlobalSound("Hero_Silencer.GlobalSilence.Cast")
	keys.caster:SwapAbilities(keys.ability:GetAbilityName(), "ability_thdots_toyohime04_end", false,true)
	keys.caster:FindAbilityByName("ability_thdots_toyohime04_end"):StartCooldown(keys.ability:GetSpecialValueFor("stop_time"))
	keys.caster:SetContextThink(DoUniqueString("toyohime04_reverse"),
	function()
		if keys.caster.has_ended04 then return nil end
		keys.caster:SwapAbilities(keys.ability:GetAbilityName(), "ability_thdots_toyohime04_end", true, false)
		return nil end
	, keys.ability:GetSpecialValueFor("duration"))
end
function OnToyohime04SpellThink(keys)
	local heros = FindUnitsInRadius(
		keys.caster:GetTeamNumber(),
		keys.caster:GetOrigin(),
		nil,
		99999,
		keys.ability:GetAbilityTargetTeam(),
		keys.ability:GetAbilityTargetType(),
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 
		FIND_ANY_ORDER,
		false)
	for _, hero in pairs(heros) do
		if not hero:HasModifier("modifier_ability_thdots_toyohimeex_mark") then
			keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_ability_thdots_toyohime04_debuff", { duration = keys.duration })
			if keys.caster:FindAbilityByName("special_bonus_unique_toyohime_8"):GetLevel() ~= 0 then
				if not hero:IsOpposingTeam(keys.caster:GetTeam()) then
					keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_ability_thdots_toyohime04_buff",{ duration = keys.duration })
				end
			else
				keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_ability_thdots_toyohime04_buff",{ duration = keys.duration })
			end
		end
	end
	keys.caster:SpendMana(keys.caster:GetMana()*keys.manacost/100,keys.ability)
end
function OnToyohime04AddParticle(keys)
	Toyohime04_particle = ParticleManager:CreateParticle("models/toyohime/fx/toyohime_cast6.vpcf",PATTACH_CUSTOMORIGIN_FOLLOW, keys.caster)
	ParticleManager:SetParticleControl(Toyohime04_particle, 1,Vector(keys.duration, 0, 0))
end
function OnToyohime04RemoveParticle(keys)
	ParticleManager:DestroyParticle(Toyohime04_particle,false)
	print("destroy")
	ParticleManager:ReleaseParticleIndex(Toyohime04_particle)
	Toyohime04_particle=nil
end

function OnToyohime04SpellEnd(keys)
	keys.caster.has_ended04 = true
	keys.caster:RemoveModifierByName("modifier_thdots_toyohime04_think_interval")
	keys.caster:SwapAbilities("ability_thdots_toyohime04", "ability_thdots_toyohime04_end", true, false)
end
ability_thdots_toyohime_wanbaochui = {}
function ability_thdots_toyohime_wanbaochui:GetManaCost()
	return self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("extra_manacost_pct") / 100
end
function ability_thdots_toyohime_wanbaochui:OnSpellStart()
	self.caster = self:GetCaster()
	local stack = nil
	local caster = self:GetCaster()
	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.caster:GetOrigin(),
		nil,
		99999,
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	for _, enemy in ipairs(enemies) do
		if enemy:FindModifierByName("modifier_ability_thdots_toyohimeex_mark") then
			stack = enemy:FindModifierByName("modifier_ability_thdots_toyohimeex_debuff"):GetStackCount()
			enemy:FindModifierByName("modifier_ability_thdots_toyohimeex_debuff"):SetStackCount(stack+20)
			local damage_table = {
				ability = self,
				victim = enemy,
				attacker = caster,
				damage = caster:GetMaxMana() * self:GetSpecialValueFor("damage_mana_pct") / 100,
				damage_type = self:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NONE
			}
			UnitDamageTarget(damage_table)
		end
	end
end
