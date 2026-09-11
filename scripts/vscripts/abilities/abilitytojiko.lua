local CircleSource = require('util/skill_circle_source_debug')
--------------------------------------------------------
--雷矢「元兴寺的电磁炮」
--------------------------------------------------------
ability_thdots_tojikoEx = {}

local TOJIKO_EX_RESIDUAL_HEIGHT = 32

local function TojikoGetResidualPoint(point)
	return GetGroundPosition(point, nil) + Vector(0, 0, TOJIKO_EX_RESIDUAL_HEIGHT)
end

local function TojikoUpdateExResidualPoints(ability, caster, table_name, points, use_set_origin)
	if not caster or caster:IsNull() or not caster:IsHero() or not caster:HasModifier("modifier_ability_thdots_tojikoEx") then return end
	ability[table_name] = ability[table_name] or {}
	for i, point in ipairs(points) do
		point = TojikoGetResidualPoint(point)
		if ability[table_name][i] == nil then
			ability[table_name][i] = {
				think_modifier = nil,
			}
		end
		local thinker = ability[table_name][i].think_modifier
		if thinker == nil or thinker:IsNull() then
			ability[table_name][i].think_modifier = CreateModifierThinker(caster, ability, "modifier_ability_thdots_tojikoEx_passive_dummy", {}, point, caster:GetTeamNumber(), false)
		elseif use_set_origin then
			thinker:SetOrigin(point)
		else
			thinker:SetAbsOrigin(point)
		end
	end
end

function ability_thdots_tojikoEx:GetIntrinsicModifierName()
	return "modifier_ability_thdots_tojikoEx"
end

modifier_ability_thdots_tojikoEx = {}
LinkLuaModifier("modifier_ability_thdots_tojikoEx","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojikoEx:IsHidden() 		return false end
function modifier_ability_thdots_tojikoEx:IsPurgable()		return false end
function modifier_ability_thdots_tojikoEx:RemoveOnDeath() 	return false end
function modifier_ability_thdots_tojikoEx:IsDebuff()		return false end


function modifier_ability_thdots_tojikoEx:DeclareFunctions()
	return
	{
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_ability_thdots_tojikoEx:CastCopiedAbility(cast_ability, point, origin)
	cast_ability.tojiko_is_ex_copy = true
	cast_ability.tojiko_ex_point = point
	cast_ability.tojiko_ex_origin = origin
	cast_ability:OnSpellStart()
	cast_ability.tojiko_is_ex_copy = nil
	cast_ability.tojiko_ex_point = nil
	cast_ability.tojiko_ex_origin = nil
end

function modifier_ability_thdots_tojikoEx:RefreshCurrentResidual(ability_name, cast_ability, point, origin)
	local caster = self:GetParent()
	if ability_name == "ability_thdots_tojiko01" then
		local cast_range = cast_ability:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus()
		local width = cast_ability:GetSpecialValueFor("width")
		local length = cast_ability:GetSpecialValueFor("length")
		if (point - origin):Length2D() + length > cast_range then
			point = origin + (point - origin):Normalized() * (cast_range - length)
		end
		local ap1 = point
		local ap2 = ap1 + (ap1 - origin):Normalized() * length / 3
		local ap3 = ap1 + (ap1 - origin):Normalized() * length / 3 * 2
		local ap4 = ap1 + (ap1 - origin):Normalized() * length
		local position_1 = ap1 + (ap1 - origin):Normalized() * width
		local position_2 = ap2 + (ap2 - origin):Normalized() * width
		local position_3 = ap3 + (ap3 - origin):Normalized() * width
		local position_4 = ap4 + (ap4 - origin):Normalized() * width
		TojikoUpdateExResidualPoints(cast_ability, caster, "tojiko01_table", {
			RotatePosition(ap1, QAngle(0, 90, 0), position_1),
			RotatePosition(ap1, QAngle(0, -90, 0), position_1),
			RotatePosition(ap2, QAngle(0, 90, 0), position_2),
			RotatePosition(ap2, QAngle(0, -90, 0), position_2),
			RotatePosition(ap3, QAngle(0, 90, 0), position_3),
			RotatePosition(ap3, QAngle(0, -90, 0), position_3),
			RotatePosition(ap4, QAngle(0, 90, 0), position_4),
			RotatePosition(ap4, QAngle(0, -90, 0), position_4),
		}, false)
	elseif ability_name == "ability_thdots_tojiko02" then
		local delay = cast_ability:GetSpecialValueFor("delay")
		caster:SetContextThink(DoUniqueString("tojiko02_ex_residual_refresh"), function()
			if GameRules:IsGamePaused() then return FrameTime() end
			local radius = cast_ability:GetSpecialValueFor("radius")
			local cp = Vector(origin.x, origin.y, origin.z)
			cp.x = cp.x + 0.01
			local position = point + (point - cp):Normalized() * radius
			local points = {}
			for i = 1, 8 do
				points[i] = position
				position = RotatePosition(point, QAngle(0, 44, 0), position)
			end
			TojikoUpdateExResidualPoints(cast_ability, caster, "tojiko02_table", points, false)
			return nil
		end, delay)
	elseif ability_name == "ability_thdots_tojiko03" then
		TojikoUpdateExResidualPoints(cast_ability, caster, "tojiko03_table", {point}, false)
	elseif ability_name == "ability_thdots_tojiko04" then
		local delay = cast_ability:GetSpecialValueFor("delay")
		caster:SetContextThink(DoUniqueString("tojiko04_ex_residual_refresh"), function()
			if GameRules:IsGamePaused() then return FrameTime() end
			local radius = cast_ability:GetSpecialValueFor("radius")
			local num_2 = 10
			local num = 20
			local cp = Vector(origin.x, origin.y, origin.z)
			cp.x = cp.x + 0.01
			local position = point + (point - cp):Normalized() * radius
			local position_2 = point + (point - cp):Normalized() * (radius - 150)
			local points = {}
			for i = 1, num do
				points[i] = position
				if i ~= num_2 then
					position = RotatePosition(point, QAngle(0, 360 / 10, 0), position)
				else
					position = position_2
				end
			end
			TojikoUpdateExResidualPoints(cast_ability, caster, "tojiko04_table", points, true)
			return nil
		end, delay)
	end
end

function modifier_ability_thdots_tojikoEx:OnAbilityFullyCast(keys)
	if not IsServer() then return end
	local caster = self:GetParent()
	if keys.unit ~= caster then return end

	local cast_ability = keys.ability
	if not cast_ability then return end
	local ability_name = cast_ability:GetName()
	if ability_name ~= "ability_thdots_tojiko01" and ability_name ~= "ability_thdots_tojiko02"
		and ability_name ~= "ability_thdots_tojiko03" and ability_name ~= "ability_thdots_tojiko04" then
		return
	end
	local cast_ability_point = cast_ability:GetCursorPosition()

	if ability_name == "ability_thdots_tojiko01" then
		if self.ability_1 and caster.tojiko01_ex_origin and caster.tojiko01_ex_direction then
			self:CastCopiedAbility(cast_ability, caster.tojiko01_ex_origin + caster.tojiko01_ex_direction, caster.tojiko01_ex_origin)
		else
			self.ability_1 = true
		end
		caster.tojiko01_ex_origin = caster:GetOrigin()
		caster.tojiko01_ex_direction = caster:GetForwardVector()
	elseif ability_name == "ability_thdots_tojiko02" then
		if self.ability_2 and caster.tojiko02_ex_point then
			self:CastCopiedAbility(cast_ability, caster.tojiko02_ex_point, caster.tojiko02_ex_point)
		else
			self.ability_2 = true
		end
		caster.tojiko02_ex_point = cast_ability_point
	elseif ability_name == "ability_thdots_tojiko03" then
		if self.ability_3 and caster.tojiko03_ex_point then
			self:CastCopiedAbility(cast_ability, caster.tojiko03_ex_point, caster.tojiko03_ex_point)
		else
			self.ability_3 = true
		end
		caster.tojiko03_ex_point = cast_ability_point
	elseif ability_name == "ability_thdots_tojiko04" then
		if self.ability_4 and caster.tojiko04_ex_point then
			self:CastCopiedAbility(cast_ability, caster.tojiko04_ex_point, caster.tojiko04_ex_point)
		else
			self.ability_4 = true
		end
		caster.tojiko04_ex_point = cast_ability_point
	end

	self:RefreshCurrentResidual(ability_name, cast_ability, cast_ability_point, caster:GetOrigin())
end

function modifier_ability_thdots_tojikoEx:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.ability_thdots_tojiko01 = nil
	self.ability_1 = false
	self.ability_2 = false
	self.ability_3 = false
	self.ability_4 = false
	-- 天赋由统一刷新函数处理，不再启动空的 OnIntervalThink。
	THD2_RefreshTalentModifiers(self.caster, "ability_thdots_tojikoEx")
end

function modifier_ability_thdots_tojikoEx:OnTakeDamage(keys)
	if not IsServer() then return end
	if keys.attacker:GetTeam() == keys.unit:GetTeam() then return end
	if keys.inflictor == nil then return end
	local caster = keys.attacker
	local target = keys.unit
	if keys.attacker == self:GetParent() and keys.damage_type == 2 and not keys.inflictor:IsItem() then
		--天赋易伤
		if FindTelentValue(self:GetParent(),"special_bonus_unique_tojiko_2") ~= 0 and target:IsAlive() then
			local duration = self:GetAbility():GetSpecialValueFor("debuff_duration")
			if target:FindModifierByName("modifier_ability_thdots_tojikoEx_debuff") == nil then
				target:AddNewModifier(self:GetCaster(), self:GetAbility(),"modifier_ability_thdots_tojikoEx_debuff", {duration = duration * (1 - target:GetStatusResistance())}):SetStackCount(1)
			else
				local modifier = target:FindModifierByName("modifier_ability_thdots_tojikoEx_debuff")
				modifier:IncrementStackCount()
				modifier:SetDuration(duration, true)
			end
		end
		--天赋刷新大招冷却
		if FindTelentValue(self:GetParent(),"special_bonus_unique_tojiko_3") ~= 0 and target:IsHero() then
			local reduce_time = self:GetAbility():GetSpecialValueFor("reduce_time")
			local tojiko04 = caster:FindAbilityByName("ability_thdots_tojiko04")
			local cooldown = tojiko04:GetCooldownTimeRemaining() - reduce_time
			tojiko04:EndCooldown()
			tojiko04:StartCooldown(cooldown)
		end
	end
end


modifier_ability_thdots_tojikoEx_telent_1 = modifier_ability_thdots_tojikoEx_telent_1 or {}  --天赋监听
LinkLuaModifier("modifier_ability_thdots_tojikoEx_telent_1","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojikoEx_telent_1:IsHidden() 		return true end
function modifier_ability_thdots_tojikoEx_telent_1:IsPurgable()		return false end
function modifier_ability_thdots_tojikoEx_telent_1:RemoveOnDeath() 	return false end
function modifier_ability_thdots_tojikoEx_telent_1:IsDebuff()		return false end

modifier_ability_thdots_tojikoEx_telent_4 = modifier_ability_thdots_tojikoEx_telent_4 or {}  --天赋监听
LinkLuaModifier("modifier_ability_thdots_tojikoEx_telent_4","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojikoEx_telent_4:IsHidden() 		return true end
function modifier_ability_thdots_tojikoEx_telent_4:IsPurgable()		return false end
function modifier_ability_thdots_tojikoEx_telent_4:RemoveOnDeath() 	return false end
function modifier_ability_thdots_tojikoEx_telent_4:IsDebuff()		return false end
function modifier_ability_thdots_tojikoEx_telent_4:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end
function modifier_ability_thdots_tojikoEx_telent_4:GetModifierConstantManaRegen()
	return 8
end


--天赋易伤debuff
modifier_ability_thdots_tojikoEx_debuff = {}
LinkLuaModifier("modifier_ability_thdots_tojikoEx_debuff","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojikoEx_debuff:IsHidden() 		return false end
function modifier_ability_thdots_tojikoEx_debuff:IsPurgable()		return true end
function modifier_ability_thdots_tojikoEx_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_tojikoEx_debuff:IsDebuff()		return true end

function modifier_ability_thdots_tojikoEx_debuff:GetEffectName() return "particles/generic_gameplay/generic_slowed_cold.vpcf" end
function modifier_ability_thdots_tojikoEx_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_ability_thdots_tojikoEx_debuff:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_ability_thdots_tojikoEx_debuff:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("debuff_bonus_damage") * self:GetStackCount()
end

--特效modifier
modifier_ability_thdots_tojikoEx_passive_dummy = {}
LinkLuaModifier("modifier_ability_thdots_tojikoEx_passive_dummy","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojikoEx_passive_dummy:IsHidden() 		return false end
function modifier_ability_thdots_tojikoEx_passive_dummy:IsPurgable()		return false end
function modifier_ability_thdots_tojikoEx_passive_dummy:RemoveOnDeath() 	return false end
function modifier_ability_thdots_tojikoEx_passive_dummy:IsDebuff()		return false end

function modifier_ability_thdots_tojikoEx_passive_dummy:OnCreated()
	if not IsServer() then return end
	local point = self:GetParent():GetOrigin()
	-- 残留点只保留电特效，跟随 thinker 位置；不写 CP1，避免额外光晕固定在首次施法点。

	self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_lightning_slow.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.particle, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_origin", point, true)
end

function modifier_ability_thdots_tojikoEx_passive_dummy:OnDestroy()
	if not IsServer() then return end
	-- 优化：修复粒子注释问题，防止长期粒子泄漏。
	if self.particle ~= nil then
		ParticleManager:DestroyParticle(self.particle, true)
		ParticleManager:ReleaseParticleIndex(self.particle)
		self.particle = nil
	end
end
--------------------------------------------------------
--神明「稻目之怨」
--------------------------------------------------------

ability_thdots_tojiko01 = {}

function ability_thdots_tojiko01:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function ability_thdots_tojiko01:GetCastPoint()
	if self:GetCaster():IsRealHero() then
		return self.BaseClass.GetCastPoint(self)
	else
		return 0
	end
end


function ability_thdots_tojiko01:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local point 				= self.tojiko_ex_point or self:GetCursorPosition()
	local cast_origin 			= self.tojiko_ex_origin or caster:GetOrigin()
	local is_ex_copy 			= self.tojiko_is_ex_copy
	local cast_range  			= self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus()
	local width  				= self:GetSpecialValueFor("width")
	local length  				= self:GetSpecialValueFor("length")
	local damage  				= self:GetSpecialValueFor("damage")
	local armor_damage_bonus  	= self:GetSpecialValueFor("armor_damage_bonus")
	local stun_duration  		= self:GetSpecialValueFor("stun_duration") + FindTelentValue(caster,"special_bonus_unique_tojiko_1")
	local HitHero = false



	local distance = (point - cast_origin):Length2D() + length
	if distance > cast_range then
		point = cast_origin + (point - cast_origin):Normalized() * ( cast_range - length )
	end
	local end_position = point + ( point - cast_origin):Normalized() * length
	caster.tojiko01_end_position = end_position
	
	--设置8个点
	local num = 8
	local cp = cast_origin
	local ap1 = point
	local ap2 = ap1 + (ap1 - cp):Normalized() * length / 3
	local ap3 = ap1 + (ap1 - cp):Normalized() * length / 3 * 2
	local ap4 = ap1 + (ap1 - cp):Normalized() * length
	local position_1 = ap1 + (ap1 - cp):Normalized() * width
	local position_2 = ap2 + (ap2 - cp):Normalized() * width
	local position_3 = ap3 + (ap3 - cp):Normalized() * width
	local position_4 = ap4 + (ap4 - cp):Normalized() * width
	local pt = {}
	pt[1] = RotatePosition(ap1, QAngle(0, 90, 0), position_1)
	pt[2] = RotatePosition(ap1, QAngle(0, -90, 0), position_1)
	pt[3] = RotatePosition(ap2, QAngle(0, 90, 0), position_2)
	pt[4] = RotatePosition(ap2, QAngle(0, -90, 0), position_2)
	pt[5] = RotatePosition(ap3, QAngle(0, 90, 0), position_3)
	pt[6] = RotatePosition(ap3, QAngle(0, -90, 0), position_3)
	pt[7] = RotatePosition(ap4, QAngle(0, 90, 0), position_4)
	pt[8] = RotatePosition(ap4, QAngle(0, -90, 0), position_4)
	--特效音效
	if not is_ex_copy then
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko01",point)
	else
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko01_dummy",point)
	end
	local tojiko01_particle_name = "particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf"
	local tojiko01_particle_name_2 = "particles/econ/items/arc_warden/arc_warden_ti9_immortal/arc_warden_ti9_wraith_cast.vpcf"
	for i=1,num do
		local particle_point = pt[i]
		local tojiko01_particle_1 = ParticleManager:CreateParticle(tojiko01_particle_name, PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControl(tojiko01_particle_1, 0, particle_point)
		ParticleManager:SetParticleControl(tojiko01_particle_1, 1, Vector(particle_point.x,particle_point.y,particle_point.z+1500))
		ParticleManager:DestroyParticleSystem(tojiko01_particle_1,false)

		local tojiko01_particle_2 = ParticleManager:CreateParticle(tojiko01_particle_name_2, PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControl(tojiko01_particle_2, 0, particle_point)
		ParticleManager:SetParticleControl(tojiko01_particle_2, 1, particle_point)
		ParticleManager:DestroyParticleSystem(tojiko01_particle_2,false)
	end


	--只有英雄触发table操作，马甲不触发
	if not is_ex_copy and caster:IsHero() and caster:HasModifier("modifier_ability_thdots_tojikoEx") then
		self.tojiko01_table = self.tojiko01_table or {}
		for i=1,num do
			local point = TojikoGetResidualPoint(pt[i])
			if self.tojiko01_table[i] == nil then
					self.tojiko01_table[i] = {
					think_modifier = nil,
				}
				self.tojiko01_table[i].think_modifier = CreateModifierThinker(caster, self, "modifier_ability_thdots_tojikoEx_passive_dummy", {}, point, caster:GetTeamNumber(), false)
			else
				self.tojiko01_table[i].think_modifier:SetAbsOrigin(point)
			end
		end
	end

	--判断是否击中英雄单位并造成伤害
	local targets = FindUnitsInLine(caster:GetTeam(), point, end_position, nil,width,self:GetAbilityTargetTeam(),self:GetAbilityTargetType(),0)
	for _,vic in ipairs(targets) do
		if vic:IsHero() then
			HitHero = true
			break
		end
	end
	for _,vic in pairs (targets) do
		local vic_damage = damage + vic:GetPhysicalArmorValue(false) * armor_damage_bonus
		local damage_tabel = {
				victim 			= vic,
				damage 			= vic_damage,
				damage_type		= self:GetAbilityDamageType(),
				attacker 		= caster,
				ability 		= self
			}
		if HitHero then
			UtilStun:UnitStunTarget(caster,vic,stun_duration)
		end
		UnitDamageTarget(damage_tabel)
	end
end

--------------------------------------------------------
--雷击「镰足之死」
--------------------------------------------------------

ability_thdots_tojiko02 = {}

function ability_thdots_tojiko02:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function ability_thdots_tojiko02:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_tojiko02:GetCastPoint()
	if self:GetCaster():IsRealHero() then
		return self.BaseClass.GetCastPoint(self)
	else
		return 0
	end
end

function ability_thdots_tojiko02:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local point 				= self.tojiko_ex_point or self:GetCursorPosition()
	local cast_origin 			= self.tojiko_ex_origin or caster:GetOrigin()
	local is_ex_copy 			= self.tojiko_is_ex_copy
	local radius  				= self:GetSpecialValueFor("radius")
	local damage  				= self:GetSpecialValueFor("damage")
	local armor_damage_bonus  	= self:GetSpecialValueFor("armor_damage_bonus")
	local delay  				= self:GetSpecialValueFor("delay")
	local damage_bonus  		= self:GetSpecialValueFor("damage_bonus") / 100
	AddFOWViewer(caster:GetTeamNumber(), point,radius,delay+0.5, false)
	if not is_ex_copy then
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko02_1",point)
	else
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko02_1_dummy",point)
	end
	local tojiko_explosion_particle = ParticleManager:CreateParticle("particles/econ/items/zeus/lightning_weapon_fx/zuus_lb_cfx_il.vpcf", PATTACH_CUSTOMORIGIN,nil)
	ParticleManager:SetParticleControl(tojiko_explosion_particle, 0, point)
	ParticleManager:SetParticleControl(tojiko_explosion_particle, 1, Vector(radius,0,0))
	ParticleManager:DestroyParticleSystem(tojiko_explosion_particle,false)

	local tojiko_explosion_particle_2 = ParticleManager:CreateParticle("particles/econ/items/arc_warden/arc_warden_ti9_immortal/arc_warden_ti9_wraith_spawn_portal.vpcf", PATTACH_CUSTOMORIGIN,nil)
	ParticleManager:SetParticleControl(tojiko_explosion_particle_2, 0, point)
	ParticleManager:DestroyParticleSystem(tojiko_explosion_particle_2,false)

	local strike_particle = "particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf"
	local strike_particle_fx = ParticleManager:CreateParticle(strike_particle, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(strike_particle_fx, 0, point)
	ParticleManager:SetParticleControl(strike_particle_fx, 1, point)
	ParticleManager:SetParticleControl(strike_particle_fx, 2, point)
	ParticleManager:SetParticleControl(strike_particle_fx, 7, Vector(radius,0,0))
	ParticleManager:DestroyParticleSystem(strike_particle_fx,false)


	caster:SetContextThink(DoUniqueString("tojiko02_delay"), function ()
		if GameRules:IsGamePaused() then return FrameTime() end
		--设置8个点
		local num = 8
		local qangle = QAngle(0, 44, 0)
		local cp = Vector(cast_origin.x, cast_origin.y, cast_origin.z)
		cp.x = cp.x + 0.01 --设置技能点偏移，不然特效会出BUG
		local position = point + (point - cp):Normalized() * radius
		local pt = {}
		for i=1,num do
			pt[i] = position
			position = RotatePosition(point, qangle, position)
		end

		--特效音效
		if not is_ex_copy then
			StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko02_2",point)
		else
			StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko02_2_dummy",point)
		end
		local tojiko02_particle_name = "particles/units/heroes/hero_arc_warden/arc_warden_flux_cast.vpcf"
		local tojiko02_particle_name_2 = "particles/econ/items/arc_warden/arc_warden_ti9_immortal/arc_warden_ti9_wraith_cast.vpcf"
		for i=1,num do
			local particle_point = pt[i]
			local tojiko02_particle_1 = ParticleManager:CreateParticle(tojiko02_particle_name, PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(tojiko02_particle_1, 0, Vector(particle_point.x,particle_point.y,particle_point.z+1500))
			ParticleManager:SetParticleControl(tojiko02_particle_1, 1, particle_point)
			ParticleManager:SetParticleControl(tojiko02_particle_1, 2, particle_point)
			ParticleManager:SetParticleControl(tojiko02_particle_1, 3, particle_point)
			ParticleManager:SetParticleControl(tojiko02_particle_1, 9, particle_point)
			ParticleManager:DestroyParticleSystem(tojiko02_particle_1,false)

			local tojiko02_particle_2 = ParticleManager:CreateParticle(tojiko02_particle_name_2, PATTACH_CUSTOMORIGIN,nil)
			ParticleManager:SetParticleControl(tojiko02_particle_2, 0, particle_point)
			ParticleManager:SetParticleControl(tojiko02_particle_2, 1, particle_point)
			ParticleManager:DestroyParticleSystem(tojiko02_particle_2,false)
		end
		--只有英雄触发table操作，马甲不触发
		if not is_ex_copy and caster:IsHero() and caster:HasModifier("modifier_ability_thdots_tojikoEx") then
			self.tojiko02_table = self.tojiko02_table or {}
			for i=1,num do
				local point = TojikoGetResidualPoint(pt[i])
				if self.tojiko02_table[i] == nil then
						self.tojiko02_table[i] = {
						think_modifier = nil,
					}
					self.tojiko02_table[i].think_modifier = CreateModifierThinker(caster, self, "modifier_ability_thdots_tojikoEx_passive_dummy", {}, point, caster:GetTeamNumber(), false)
				else
					self.tojiko02_table[i].think_modifier:SetAbsOrigin(point)
				end
			end
		end
		
		
		local targets = FindUnitsInRadius(caster:GetTeam(), point,nil,radius,self:GetAbilityTargetTeam()
			,self:GetAbilityTargetType(),0,0,false)

		for _,vic in ipairs(targets) do
			if vic:IsHero() then
				damage = damage * (1 + damage_bonus)
				break
			end
		end
		for _,vic in pairs (targets) do
			local vic_damage = damage + vic:GetPhysicalArmorValue(false) * armor_damage_bonus
			local damage_tabel = {
					victim 			= vic,
					damage 			= vic_damage,
					damage_type		= self:GetAbilityDamageType(),
					attacker 		= caster,
					ability 		= self
				}
			UnitDamageTarget(damage_tabel)
		end
	end, delay)
end

--------------------------------------------------------
--雷矢「元兴寺的雷矢」
--------------------------------------------------------

ability_thdots_tojiko03 = {}

function ability_thdots_tojiko03:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function ability_thdots_tojiko03:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_tojiko03:GetCastPoint()
	if self:GetCaster():IsRealHero() then
		return self.BaseClass.GetCastPoint(self)
	else
		return 0
	end
end

function ability_thdots_tojiko03:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local point 				= self.tojiko_ex_point or self:GetCursorPosition()
	local is_ex_copy 			= self.tojiko_is_ex_copy
	local radius  				= self:GetSpecialValueFor("radius")
	local damage  				= self:GetSpecialValueFor("damage")
	local armor_damage_bonus  	= self:GetSpecialValueFor("armor_damage_bonus")
	local duration  			= self:GetSpecialValueFor("duration")
	local vision_time  			= self:GetSpecialValueFor("vision_time") --视野持续时间
	local vision_radius  		= self:GetSpecialValueFor("vision_radius")

	AddFOWViewer(caster:GetTeamNumber(), point,vision_radius,vision_time, false)
	--设置1个点
	local num = 1

	local pt = {}
	for i=1,num do
		pt[i] = point
	end

	--特效音效
	if not is_ex_copy then
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko03",point)
	else
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko03_dummy",point)
	end
	local tojiko03_particle_name = "particles/econ/items/zeus/lightning_weapon_fx/zuus_lightning_bolt_immortal_lightning.vpcf"
	for i=1,num do
		local particle_point = pt[i]
		local tojiko03_particle_1 = ParticleManager:CreateParticle(tojiko03_particle_name, PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControl(tojiko03_particle_1, 0, Vector(particle_point.x,particle_point.y,particle_point.z+5000))
		ParticleManager:SetParticleControl(tojiko03_particle_1, 1, particle_point)
		ParticleManager:DestroyParticleSystem(tojiko03_particle_1,false)

		local strike_particle = "particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf"
		local strike_particle_fx = ParticleManager:CreateParticle(strike_particle, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(strike_particle_fx, 0, particle_point)
		ParticleManager:SetParticleControl(strike_particle_fx, 1, particle_point)
		ParticleManager:SetParticleControl(strike_particle_fx, 2, particle_point)
		ParticleManager:SetParticleControl(strike_particle_fx, 7, Vector(radius,0,0))
		ParticleManager:DestroyParticleSystem(strike_particle_fx,false)
	end

	
	--只有英雄触发table操作，马甲不触发
	if not is_ex_copy and caster:IsHero() and caster:HasModifier("modifier_ability_thdots_tojikoEx") then
		self.tojiko03_table = self.tojiko03_table or {}
		for i=1,num do
			local point = TojikoGetResidualPoint(pt[i])
			if self.tojiko03_table[i] == nil then
					self.tojiko03_table[i] = {
					think_modifier = nil,
				}
				self.tojiko03_table[i].think_modifier = CreateModifierThinker(caster, self, "modifier_ability_thdots_tojikoEx_passive_dummy", {}, point, caster:GetTeamNumber(), false)
			else
				self.tojiko03_table[i].think_modifier:SetAbsOrigin(point)
			end
		end
	end


	local targets = FindUnitsInRadius(caster:GetTeam(), point,nil,radius,self:GetAbilityTargetTeam()
		,self:GetAbilityTargetType(),0,0,false)

	for _,vic in ipairs(targets) do
		if vic:IsHero() then
			caster:AddNewModifier(caster, self, "modifier_ability_thdots_tojiko03", {duration = duration})
			break
		end
	end
	for _,vic in pairs (targets) do
		local vic_damage = damage + vic:GetPhysicalArmorValue(false) * armor_damage_bonus
		local damage_tabel = {
				victim 			= vic,
				damage 			= vic_damage,
				damage_type		= self:GetAbilityDamageType(),
				attacker 		= caster,
				ability 		= self
			}
		UnitDamageTarget(damage_tabel)
	end

end


modifier_ability_thdots_tojiko03 = {}
LinkLuaModifier("modifier_ability_thdots_tojiko03","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojiko03:IsHidden() 		return false end
function modifier_ability_thdots_tojiko03:IsPurgable()		return true end
function modifier_ability_thdots_tojiko03:RemoveOnDeath() 	return true end
function modifier_ability_thdots_tojiko03:IsDebuff()		return false end


function modifier_ability_thdots_tojiko03:OnCreated()
	if not IsServer() then return end
	if self:GetParent():IsHero() then
		self.effect = ParticleManager:CreateParticle("particles/econ/events/ti8/mjollnir_shield_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	end
end

function modifier_ability_thdots_tojiko03:OnDestroy()
	if not IsServer() then return end
	if self:GetParent():IsHero() then
		ParticleManager:DestroyParticle(self.effect,true)
	end
end

function modifier_ability_thdots_tojiko03:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
	}
end

function modifier_ability_thdots_tojiko03:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage_percentage")
end

function modifier_ability_thdots_tojiko03:GetModifierTotal_ConstantBlock(kv)
	if not IsServer() then return end
	if bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return 0 end
	if kv.target == self:GetParent() and kv.damage_type == 1 then
		return kv.damage * self:GetAbility():GetSpecialValueFor("physical_reduce") / 100
	else
		return 0
	end
end

--------------------------------------------------------
--怨灵「入鹿之雷」
--------------------------------------------------------

ability_thdots_tojiko04 = {}

function ability_thdots_tojiko04:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function ability_thdots_tojiko04:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_tojiko04:GetCastPoint()
	if self:GetCaster():IsRealHero() then
		return self.BaseClass.GetCastPoint(self)
	else
		return 0
	end
end

function ability_thdots_tojiko04:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local point 				= self.tojiko_ex_point or self:GetCursorPosition()
	local cast_origin 			= self.tojiko_ex_origin or caster:GetOrigin()
	local is_ex_copy 			= self.tojiko_is_ex_copy
	local radius  				= self:GetSpecialValueFor("radius")
	local damage  				= self:GetSpecialValueFor("damage")
	local delay  				= self:GetSpecialValueFor("delay")
	local armor_damage_bonus  	= self:GetSpecialValueFor("armor_damage_bonus")
	local regen_mana  			= self:GetSpecialValueFor("regen_mana")
	-- 与现有固定地点预警同步；复用原结算计时器收尾，不新增定时器。
	-- 当前施法与旧位置复制共享诊断pair；复制仍走相同伤害和预警入口。
	if not is_ex_copy then self.thd_warning_sequence=(self.thd_warning_sequence or 0)+1 end
	local warningSource=CircleSource.BeginDelayed(caster,self,point,radius,delay,{
		role=is_ex_copy and 'echo' or 'primary',pair=tostring(caster:entindex())..':'..tostring(self.thd_warning_sequence or 0)})


	if not is_ex_copy then
		caster:EmitSound("Voice_Thdots_Tojiko.AbilityTojiko04_1")
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko04_3",point)
	else
		StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko04_3_dummy",point)
	end
	AddFOWViewer(caster:GetTeamNumber(), point,radius,delay+1, false)
	local tojiko04_cast_particle = ParticleManager:CreateParticle("particles/econ/items/razor/razor_ti6/razor_plasmafield_ti6.vpcf", PATTACH_CUSTOMORIGIN,nil)
	ParticleManager:SetParticleControl(tojiko04_cast_particle, 0, point)
	ParticleManager:SetParticleControl(tojiko04_cast_particle, 1, Vector(radius,radius,1))
	ParticleManager:DestroyParticleSystemTime(tojiko04_cast_particle,delay)

	if not is_ex_copy then
		local tojiko04_cast_particle_2 = ParticleManager:CreateParticle("particles/econ/items/zeus/arcana_chariot/zeus_arcana_thundergods_wrath_start.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(tojiko04_cast_particle_2, 0, caster:GetOrigin())
		ParticleManager:SetParticleControl(tojiko04_cast_particle_2, 1, caster:GetOrigin())
		ParticleManager:SetParticleControl(tojiko04_cast_particle_2, 2, Vector(0,0,0))
		ParticleManager:SetParticleControl(tojiko04_cast_particle_2, 3, caster:GetOrigin())
		ParticleManager:SetParticleControl(tojiko04_cast_particle_2, 6, caster:GetOrigin())
		ParticleManager:DestroyParticleSystemTime(tojiko04_cast_particle_2,delay)
	end


	caster:SetContextThink(DoUniqueString("tojiko04_delay"), function ()
		if GameRules:IsGamePaused() then return FrameTime() end

		--设置20个点,10个大圈，10个小圈
		local num = 10
		local num_2 = 10
		local qangle = QAngle(0, 360/num, 0)
		num = num + num_2
		local cp = Vector(cast_origin.x, cast_origin.y, cast_origin.z)
		cp.x = cp.x + 0.01 --设置技能点偏移，不然特效会出BUG
		local position = point + (point - cp):Normalized() * radius
		local position_2 = point + (point - cp):Normalized() * ( radius - 150 )
		local pt = {}
		for i=1,num do
			pt[i] = position
			if i ~= num_2 then
				position = RotatePosition(point, qangle, position)
			else
				position = position_2
			end
		end

		--特效音效
		if not is_ex_copy then
			StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko04_2",point)
		else
			StartSoundEventFromPosition("Voice_Thdots_Tojiko.AbilityTojiko04_2_dummy",point)
		end

		local tojiko04_particle_name = "particles/units/heroes/hero_arc_warden/arc_warden_flux_cast.vpcf"
		local tojiko04_particle_name_2 = "particles/econ/items/zeus/arcana_chariot/zeus_arcana_thundergods_wrath.vpcf"
		for i=1,num do
			local particle_point = pt[i]
			local tojiko04_particle_1 = ParticleManager:CreateParticle(tojiko04_particle_name, PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(tojiko04_particle_1, 0, Vector(particle_point.x,particle_point.y,particle_point.z+1500))
			ParticleManager:SetParticleControl(tojiko04_particle_1, 1, particle_point)
			ParticleManager:SetParticleControl(tojiko04_particle_1, 2, particle_point)
			ParticleManager:DestroyParticleSystem(tojiko04_particle_1,false)

			local tojiko04_particle_2 = ParticleManager:CreateParticle(tojiko04_particle_name_2, PATTACH_CUSTOMORIGIN,nil)
			ParticleManager:SetParticleControl(tojiko04_particle_2, 0, Vector(particle_point.x,particle_point.y,particle_point.z+1500))
			ParticleManager:SetParticleControl(tojiko04_particle_2, 1, particle_point)
			ParticleManager:SetParticleControl(tojiko04_particle_2, 2, particle_point)
			ParticleManager:DestroyParticleSystem(tojiko04_particle_2,false)
		end
		local tojiko04_cast_particle_end = ParticleManager:CreateParticle("particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(tojiko04_cast_particle_end, 0, point)
		ParticleManager:SetParticleControl(tojiko04_cast_particle_end, 1, Vector(radius,radius,radius))
		ParticleManager:DestroyParticleSystem(tojiko04_cast_particle_end,false)
		--只有英雄触发table操作，马甲不触发
		if not is_ex_copy and caster:IsHero() and caster:HasModifier("modifier_ability_thdots_tojikoEx") then
			self.tojiko04_table = self.tojiko04_table or {}
			for i=1,num do
				local point = TojikoGetResidualPoint(pt[i])
				if self.tojiko04_table[i] == nil then
						self.tojiko04_table[i] = {
						think_modifier = nil,
					}
					self.tojiko04_table[i].think_modifier = CreateModifierThinker(caster, self, "modifier_ability_thdots_tojikoEx_passive_dummy", {}, point, caster:GetTeamNumber(), false)
				else
					self.tojiko04_table[i].think_modifier:SetOrigin(point)
				end
			end
		end


		CircleSource.DelayedImpact(warningSource)
		local targets = FindUnitsInRadius(caster:GetTeam(), point,nil,radius,self:GetAbilityTargetTeam()
			,self:GetAbilityTargetType(),0,0,false)
		CircleSource.CaptureImpact(warningSource,targets)

		for _,vic in ipairs(targets) do
			if vic:IsHero() then
				caster:SetMana(caster:GetMana() + regen_mana)
				SendOverheadEventMessage(nil,OVERHEAD_ALERT_MANA_ADD,caster,regen_mana,nil)
				break
			end
		end
		for _,vic in pairs (targets) do
			local vic_damage = damage + vic:GetPhysicalArmorValue(false) * armor_damage_bonus
			local damage_tabel = {
					victim 			= vic,
					damage 			= vic_damage,
					damage_type		= self:GetAbilityDamageType(),
					attacker 		= caster,
					ability 		= self
				}
			local healthBefore=CircleSource.OutcomeHealth(vic)
			local factors=CircleSource.DamageFactors(caster,vic,self)
			if not vic:HasModifier("modifier_fountain_aura_buff") then
				local applied=UnitDamageTarget(damage_tabel)
				CircleSource.RecordDamage(warningSource,vic,vic_damage,applied,healthBefore,false,factors)
			else
				CircleSource.RecordDamage(warningSource,vic,vic_damage,nil,healthBefore,true,factors)
			end
		end
	end, delay)
end



--------------------------------------------------------
--「元兴寺的龙卷」：万宝槌技能
--------------------------------------------------------

ability_thdots_tojiko05 = {}

function ability_thdots_tojiko05:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_tojiko05:OnInventoryContentsChanged()
	if IsServer() then
		if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
			self:SetHidden(false)
		else
			if self:GetCaster():HasModifier("modifier_ability_thdots_tojiko05") then
				self:GetCaster():RemoveModifierByName("modifier_ability_thdots_tojiko05")
			end
			self:SetHidden(true)
		end
	end
end

function ability_thdots_tojiko05:OnHeroCalculateStatBonus()
	self:OnInventoryContentsChanged()
end

function ability_thdots_tojiko05:GetCastPoint()
	if self:GetCaster():IsRealHero() then
		return self.BaseClass.GetCastPoint(self)
	else
		return 0
	end
end

function ability_thdots_tojiko05:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local duration  			= self:GetSpecialValueFor("duration")
	caster:EmitSound("Voice_Thdots_Tojiko.AbilityTojiko05_Cast")
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_tojiko05",{duration = duration})
end

modifier_ability_thdots_tojiko05 = {}
LinkLuaModifier("modifier_ability_thdots_tojiko05","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojiko05:IsHidden() 		return false end
function modifier_ability_thdots_tojiko05:IsPurgable()		return false end
function modifier_ability_thdots_tojiko05:RemoveOnDeath() 	return true end
function modifier_ability_thdots_tojiko05:IsDebuff()		return false end
function modifier_ability_thdots_tojiko05:IsAura() 			return true end

function modifier_ability_thdots_tojiko05:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_ability_thdots_tojiko05:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_ability_thdots_tojiko05:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_ability_thdots_tojiko05:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_ability_thdots_tojiko05:GetModifierAura() return "modifier_ability_thdots_tojiko05_debuff" end

function modifier_ability_thdots_tojiko05:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_ability_thdots_tojiko05:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end

function modifier_ability_thdots_tojiko05:CheckState() --无法攻击被攻击
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end


function modifier_ability_thdots_tojiko05:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
end

function modifier_ability_thdots_tojiko05:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("reduce_mgical_resistance")
end


function modifier_ability_thdots_tojiko05:OnCreated()
	if not IsServer() then return end
	local caster = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	local tojiko05_particle_name = "particles/units/heroes/hero_razor/razor_plasmafield.vpcf"
	self.tojiko05_particle = ParticleManager:CreateParticle(tojiko05_particle_name, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.tojiko05_particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.tojiko05_particle, 1, Vector(radius,radius,1))
end

function modifier_ability_thdots_tojiko05:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticleSystem(self.tojiko05_particle,true)
end


modifier_ability_thdots_tojiko05_debuff = {}
LinkLuaModifier("modifier_ability_thdots_tojiko05_debuff","scripts/vscripts/abilities/abilitytojiko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_tojiko05_debuff:IsHidden() 		return false end
function modifier_ability_thdots_tojiko05_debuff:IsPurgable()		return false end
function modifier_ability_thdots_tojiko05_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_tojiko05_debuff:IsDebuff()		return true end

function modifier_ability_thdots_tojiko05_debuff:CheckState()
	if not IsServer() then return end
	if IsTHDImmune(self:GetParent()) then
		return {[MODIFIER_STATE_SILENCED] = false}
	else
		return {[MODIFIER_STATE_SILENCED] = true}
	end
end
function modifier_ability_thdots_tojiko05_debuff:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.target = self:GetParent()
	self.target:EmitSound("Voice_Thdots_Tojiko.AbilityTojiko05_Target_1")
	self.target:EmitSound("Voice_Thdots_Tojiko.AbilityTojiko05_Target_2")
	local tojiko05_particle_debuff_name = "particles/units/heroes/hero_razor_reduced_flash/razor_static_link_beam_reduced_flash.vpcf"
	self.tojiko05_particle_debuff = ParticleManager:CreateParticle(tojiko05_particle_debuff_name, PATTACH_ABSORIGIN_FOLLOW,self.target)
	ParticleManager:SetParticleControlEnt(self.tojiko05_particle_debuff , 0, self.target, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(self.tojiko05_particle_debuff , 1, self.caster, 5, "attach_hitloc", Vector(0,0,0), true)
end

function modifier_ability_thdots_tojiko05_debuff:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticleSystem(self.tojiko05_particle_debuff,true)
	self.target:StopSound("Voice_Thdots_Tojiko.AbilityTojiko05_Target_2")
	self.target:EmitSound("Voice_Thdots_Tojiko.AbilityTojiko05_Target_3")
end
