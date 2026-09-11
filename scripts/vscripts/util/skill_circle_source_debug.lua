-- S3只保留已验证的additive来源标记，不增加伤害、范围或视野。
-- Bot仅读取正常单位接口；没有共享危险表或网络广播。
local Source = {ENABLED = true, OUTCOME_DETAILS = false, BATCH = '20260908-RF1-S3AV'}
local MODIFIER = 'modifier_thd_sanae01_observation'
LinkLuaModifier(MODIFIER, 'scripts/vscripts/util/skill_circle_source_debug.lua', LUA_MODIFIER_MOTION_NONE)
modifier_thd_sanae01_observation = class({})
local function Trace(data, event, tick)
	print(string.format('[GAME][SkillCircleTruth] batch=%s event=%s dota_time=%.3f sim_time=%.3f cast=%s carrier=%s instance=%s unit=%s creation_invisible=%s team=%s player=%s ability=ability_thdots_sanae01 x=%.1f y=%.1f radius=%.1f nominal_duration=%.3f interval=%.3f tick=%s',
		Source.BATCH, event, GameRules:GetDOTATime(false, false), GameRules:GetGameTime(), data.cast, data.carrier,
		tostring(data.id), data.unitName, tostring(data.creationInvisible), tostring(data.team), tostring(data.player),
		data.x, data.y, data.radius, data.duration, data.interval, tostring(tick or -1)))
end
local function CreateCarrier(carrier, caster, ability, center, radius, duration, modifierName)
	-- 使用已存在的零视野additive定义，不修改共享KV；只移除本标记实例继承的隐身/通用dummy能力。
	local marker = CreateUnitByName('npc_no_vision_dummy_unit', center, false, caster, caster, caster:GetTeamNumber())
	if marker == nil or not IsValidEntity(marker) then return nil end
	for _, name in ipairs({'ability_dummy_unit', 'ability_invisible_dummy_unit'}) do
		if marker:FindAbilityByName(name) ~= nil then marker:RemoveAbility(name) end
	end
	marker:RemoveModifierByName('dummy_unit')
	marker:AddNewModifier(caster, ability, modifierName or MODIFIER, {duration = duration, radius = radius})
	return marker
end
function Source.Begin(caster, ability, center, radius, ticks, interval)
	if not Source.ENABLED or not IsServer() or caster == nil or not IsValidEntity(caster)
	or ability == nil or not IsValidEntity(ability) then return nil end
	radius, ticks, interval = tonumber(radius), tonumber(ticks), tonumber(interval)
	if radius == nil or ticks == nil or interval == nil or radius <= 0 or ticks <= 0 or interval <= 0 then return nil end
	local group = {cast = DoUniqueString('sanae_source'), markers = {}}
	for _, carrier in ipairs({'additive'}) do
		local marker = CreateCarrier(carrier, caster, ability, center, radius, ticks * interval)
		if marker ~= nil and IsValidEntity(marker) then
			local modifier = marker:FindModifierByName(MODIFIER)
			if modifier ~= nil then
				local data = {marker = marker, cast = group.cast, carrier = carrier, id = marker:entindex(),
					unitName = marker:GetUnitName(), creationInvisible = marker:IsInvisible(),
					team = caster:GetTeamNumber(), player = caster:GetPlayerOwnerID(), x = center.x, y = center.y,
					radius = radius, ticks = ticks, duration = ticks * interval, interval = interval}
				modifier.THD_SourceData = data
				table.insert(group.markers, data)
				Trace(data, 'created')
			else
				UTIL_Remove(marker)
				print('[GAME][SkillCircleTruth] batch='..Source.BATCH..' event=create_failed carrier='..carrier..' reason=modifier_missing')
			end
		else
			print('[GAME][SkillCircleTruth] batch='..Source.BATCH..' event=create_failed carrier='..carrier..' reason=unit_missing')
		end
	end
	return group
end
function Source.Tick(group, tick)
	if group == nil then return end
	for _, data in ipairs(group.markers) do
		if data.marker ~= nil and IsValidEntity(data.marker) then
			local modifier = data.marker:FindModifierByName(MODIFIER)
			if modifier ~= nil then modifier:SetDuration(math.max(0.05, (data.ticks - tick) * data.interval), true) end
		end
		Trace(data, tick == 0 and 'active' or 'tick', tick)
	end
end
function Source.Finish(group)
	if group == nil then return end
	for _, data in ipairs(group.markers) do
		Trace(data, 'timer_finished')
		if data.marker ~= nil and IsValidEntity(data.marker) then
			local modifier = data.marker:FindModifierByName(MODIFIER)
			if modifier ~= nil then modifier:Destroy() else UTIL_Remove(data.marker) end
		end
	end
end
function modifier_thd_sanae01_observation:IsHidden() return false end
function modifier_thd_sanae01_observation:IsPurgable() return false end
function modifier_thd_sanae01_observation:RemoveOnDeath() return false end
function modifier_thd_sanae01_observation:OnCreated(keys)
	if not IsServer() then return end
	-- 公开可见modifier的层数仅编码范围，客户端仍受团队视野限制。
	self:SetStackCount(math.max(1, math.ceil(tonumber(keys.radius) or 0)))
end
function modifier_thd_sanae01_observation:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end
function modifier_thd_sanae01_observation:DeclareFunctions()
	return {MODIFIER_PROPERTY_FIXED_DAY_VISION, MODIFIER_PROPERTY_FIXED_NIGHT_VISION}
end
function modifier_thd_sanae01_observation:GetFixedDayVision() return 0 end
function modifier_thd_sanae01_observation:GetFixedNightVision() return 0 end
function modifier_thd_sanae01_observation:OnDestroy()
	if not IsServer() then return end
	if self.THD_SourceData ~= nil then Trace(self.THD_SourceData, 'marker_destroyed') end
	local parent = self:GetParent()
	if parent ~= nil and IsValidEntity(parent) then UTIL_Remove(parent) end
end
-- 延时预警沿用已验证的零视野载体；marker剩余时间只公开预警倒计时，不编码隐藏等级。
local DELAY_MODIFIER='modifier_thd_tojiko04_observation'
LinkLuaModifier(DELAY_MODIFIER,'scripts/vscripts/util/skill_circle_source_debug.lua',LUA_MODIFIER_MOTION_NONE)
modifier_thd_tojiko04_observation=class({})
for _,name in ipairs({'IsHidden','IsPurgable','RemoveOnDeath','OnCreated','CheckState','DeclareFunctions','GetFixedDayVision','GetFixedNightVision'}) do
	modifier_thd_tojiko04_observation[name]=modifier_thd_sanae01_observation[name]
end
local function DelayedTrace(data,event)
	print(string.format('[GAME][SkillDelayedTruth] batch=20260910-RF1-S15VC event=%s dota_time=%.3f cast=%s instance=%s team=%s player=%s ability=ability_thdots_tojiko04 x=%.1f y=%.1f radius=%.1f delay=%.3f impact_at=%.3f role=%s pair=%s',
		event,GameRules:GetDOTATime(false,false),data.cast,tostring(data.id),tostring(data.team),tostring(data.player),data.x,data.y,data.radius,data.delay,data.impactAt,data.role,data.pair))
end
function Source.BeginDelayed(caster,ability,center,radius,delay,metadata)
	if not Source.ENABLED or not IsServer() or caster==nil or not IsValidEntity(caster) or ability==nil or not IsValidEntity(ability) then return nil end
	if radius<=0 or radius>2000 or delay<=0 or delay>9 then return nil end
	local marker=CreateCarrier('additive',caster,ability,center,radius,delay+0.35,DELAY_MODIFIER)
	if not marker then
		print('[GAME][SkillDelayedTruth] batch=20260910-RF1-S15VC event=create_failed reason=marker_missing')
		return nil
	end
	local modifier=marker:FindModifierByName(DELAY_MODIFIER)
	if not modifier then
		UTIL_Remove(marker)
		print('[GAME][SkillDelayedTruth] batch=20260910-RF1-S15VC event=create_failed reason=modifier_missing')
		return nil
	end
	metadata=metadata or {}
	local data={role=metadata.role or 'primary',pair=metadata.pair or 'none',marker=marker,id=marker:entindex(),cast=DoUniqueString('tojiko04_warning'),team=caster:GetTeamNumber(),player=caster:GetPlayerOwnerID(),
		x=center.x,y=center.y,radius=radius,delay=delay,impactAt=GameRules:GetDOTATime(false,false)+delay}
	modifier.THD_DelayedData=data
	DelayedTrace(data,'created')
	return data
end
function Source.DelayedImpact(data)
	if not data then return end
	DelayedTrace(data,'impact')
	if data.marker and IsValidEntity(data.marker) then
		local modifier=data.marker:FindModifierByName(DELAY_MODIFIER)
		if modifier then modifier:Destroy() else UTIL_Remove(data.marker) end
	end
end
function modifier_thd_tojiko04_observation:OnDestroy()
	if not IsServer() then return end
	if self.THD_DelayedData then DelayedTrace(self.THD_DelayedData,'marker_destroyed') end
	modifier_thd_sanae01_observation.OnDestroy(self)
end
-- 归因仅写Game日志。诊断异常不得中断原伤害流程，不对Bot共享全图状态。
local function OutcomeValue(default,fn)
	local ok,value=pcall(fn);if ok and value~=nil then return value end;return default
end
local function OutcomeLog(data,event,extra)
	print(string.format('[GAME][SkillOutcome] batch=20260910-RF1-S15VC event=%s dota_time=%.3f cast=%s instance=%s pair=%s role=%s caster_team=%s caster_player=%s x=%.1f y=%.1f radius=%.1f %s',
		event,GameRules:GetDOTATime(false,false),data.cast,tostring(data.id),data.pair,data.role,tostring(data.team),tostring(data.player),data.x,data.y,data.radius,extra))
end
function Source.CaptureImpact(data,targets)
	if not Source.OUTCOME_DETAILS or not data then return end
	local ok=pcall(function()
		local selected={}
		for _,target in pairs(targets) do selected[target:entindex()]=true end
		local count=0
		for _,hero in ipairs(HeroList:GetAllHeroes()) do
			if hero and IsValidEntity(hero) and hero:IsRealHero() and hero:GetTeamNumber()~=data.team then
				local point=hero:GetAbsOrigin();local distance=(point-Vector(data.x,data.y,point.z)):Length2D()
				OutcomeLog(data,'impact_subject',string.format('target_entity=%d target_team=%d target_player=%d selected=%d inside_geometry=%d distance=%.1f target_x=%.1f target_y=%.1f alive=%d invulnerable=%d magic_immune=%d fountain=%d health=%.1f armor=%.3f',
					hero:entindex(),hero:GetTeamNumber(),hero:GetPlayerOwnerID(),selected[hero:entindex()] and 1 or 0,distance<=data.radius and 1 or 0,distance,point.x,point.y,
					hero:IsAlive() and 1 or 0,hero:IsInvulnerable() and 1 or 0,hero:IsMagicImmune() and 1 or 0,hero:HasModifier('modifier_fountain_aura_buff') and 1 or 0,hero:GetHealth(),hero:GetPhysicalArmorValue(false)))
				count=count+1
			end
		end
		OutcomeLog(data,'impact_subjects_complete','subjects='..count)
	end)
	if not ok then OutcomeLog(data,'diagnostic_error','site=impact_subjects') end
end
function Source.OutcomeHealth(victim)
	if not Source.OUTCOME_DETAILS then return -1 end
	return OutcomeValue(-1,function() return victim:GetHealth() end)
end
function Source.DamageFactors(caster,victim,ability)
	if not Source.OUTCOME_DETAILS then return nil end
	local factors={}
	local function Read(name,fn)
		local ok,value=pcall(fn)
		local known=ok and type(value)=='number' and value==value and math.abs(value)<math.huge
		factors[name]=known and value or 0;factors[name..'Known']=known and 1 or 0
	end
	Read('magicResist',function() return victim:Script_GetMagicalArmorValue(false,nil) end)
	Read('spellAmp',function() return caster:GetSpellAmplification(false) end)
	Read('armor',function() return victim:GetPhysicalArmorValue(false) end)
	Read('level',function() return ability:GetLevel() end)
	Read('stacks',function()
		local modifier=victim:FindModifierByName('modifier_ability_thdots_tojikoEx_debuff')
		return modifier and modifier:GetStackCount() or 0
	end)
	return factors
end
function Source.RecordDamage(data,victim,requested,result,before,skipped,factors)
	if not Source.OUTCOME_DETAILS or not data then return end
	local ok=pcall(function()
		if not victim:IsRealHero() then return end
		if factors then
			OutcomeLog(data,'damage_factors',string.format('target_entity=%d target_team=%d target_player=%d phase=before_call mr_method=Script_GetMagicalArmorValue game_magic_resist=%.4f caster_spell_amp=%.4f game_armor=%.3f ability_level=%d game_tojiko_stacks=%d mr_known=%d amp_known=%d armor_known=%d level_known=%d stacks_known=%d',
				victim:entindex(),victim:GetTeamNumber(),victim:GetPlayerOwnerID(),factors.magicResist,factors.spellAmp,factors.armor,factors.level,factors.stacks,factors.magicResistKnown,factors.spellAmpKnown,factors.armorKnown,factors.levelKnown,factors.stacksKnown))
		end
		local after=Source.OutcomeHealth(victim)
		local known=type(result)=='number' and result==result and math.abs(result)<math.huge
		OutcomeLog(data,'damage_call',string.format('target_entity=%d target_team=%d target_player=%d outcome=%s requested=%.3f result_known=%d engine_return=%.3f hp_before=%.1f hp_after=%.1f hp_delta=%.1f',
			victim:entindex(),victim:GetTeamNumber(),victim:GetPlayerOwnerID(),skipped and 'skipped_fountain' or 'damage_requested',requested,known and 1 or 0,known and result or -1,
			before,after,before>=0 and after>=0 and before-after or -1))
	end)
	if not ok then OutcomeLog(data,'diagnostic_error','site=damage_call') end
end
return Source
