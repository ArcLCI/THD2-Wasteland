LinkLuaModifier("modifier_thdots_lane_creep_march_protection", "util/lane_creep_protection.lua", LUA_MODIFIER_MOTION_NONE)

local LANE_CREEP_PROTECTION_END_TIME = 30 * 60
local LANE_CREEP_PROTECTION_THINK_INTERVAL = 0.2
local LANE_CREEP_PROTECTION_ACQUISITION_RANGE = 300
local LANE_CREEP_PROTECTION_CREEP_RELEASE_RADIUS = 700
local LANE_CREEP_PROTECTION_BUILDING_RELEASE_RADIUS = 900
local LANE_CREEP_PROTECTION_PLAYER_DAMAGE_REDUCTION = -90
local LANE_CREEP_PROTECTION_STATUS_RESISTANCE = 70
local LANE_CREEP_PROTECTION_SPEED_DELAY = 30
local LANE_CREEP_PROTECTION_SPEED_BONUS = 25

THD_LANE_CREEP_PROTECTION = THD_LANE_CREEP_PROTECTION or {
	creeps = {},
	buildings = nil,
	thinkerRunning = false,
}

local function LaneCreepProtection_IsValid(unit)
	return unit ~= nil and unit.IsNull ~= nil and not unit:IsNull() and unit:IsAlive()
end

local function LaneCreepProtection_IsBeforeEndTime()
	return GameRules:GetDOTATime(false, false) < LANE_CREEP_PROTECTION_END_TIME
end

local function LaneCreepProtection_IsLaneCreep(unit)
	if unit == nil or unit.GetClassname == nil then return false end
	local classname = unit:GetClassname()
	return classname == "npc_dota_creep_lane" or classname == "npc_dota_creep_siege"
end

local function LaneCreepProtection_IsPlayerControlledUnit(unit, visited, depth)
	if unit == nil or unit.IsNull == nil or unit:IsNull() then return false end
	visited = visited or {}
	depth = depth or 0
	if depth > 6 then return false end

	local entindex = unit.entindex ~= nil and unit:entindex() or nil
	if entindex ~= nil then
		if visited[entindex] then return false end
		visited[entindex] = true
	end

	-- 覆盖英雄、幻象、召唤物及玩家接管的其他单位。
	if unit.IsHero ~= nil and unit:IsHero() then return true end
	if unit.IsControllableByAnyPlayer ~= nil and unit:IsControllableByAnyPlayer() then return true end
	local playerID = unit.GetPlayerOwnerID ~= nil and unit:GetPlayerOwnerID() or -1
	if playerID ~= nil and playerID >= 0 then return true end
	local controllingPlayerID = unit.GetMainControllingPlayer ~= nil and unit:GetMainControllingPlayer() or -1
	if controllingPlayerID ~= nil and controllingPlayerID >= 0 then return true end

	-- 部分技能通过 dummy 或多层召唤关系创建单位，需要沿 owner 链追溯英雄。
	for _, owner in pairs({
		unit.GetOwner ~= nil and unit:GetOwner() or nil,
		unit.GetOwnerEntity ~= nil and unit:GetOwnerEntity() or nil,
	}) do
		if owner ~= nil and owner ~= unit
			and LaneCreepProtection_IsPlayerControlledUnit(owner, visited, depth + 1) then
			return true
		end
	end
	return false
end

local function LaneCreepProtection_DistanceSquared(first, second)
	local delta = first:GetAbsOrigin() - second:GetAbsOrigin()
	return delta.x * delta.x + delta.y * delta.y
end

local function LaneCreepProtection_FindAllByClassname(classname)
	if Entities.FindAllByClassname ~= nil then
		return Entities:FindAllByClassname(classname) or {}
	end

	local result = {}
	local entity = nil
	repeat
		entity = Entities:FindByClassname(entity, classname)
		if entity ~= nil then table.insert(result, entity) end
	until entity == nil
	return result
end

local function LaneCreepProtection_CollectReleaseTargets()
	local targets = {}
	for _, classname in ipairs({"npc_dota_creep_lane", "npc_dota_creep_siege"}) do
		for _, unit in pairs(LaneCreepProtection_FindAllByClassname(classname)) do
			if LaneCreepProtection_IsValid(unit) then
				table.insert(targets, unit)
			end
		end
	end

	-- 建筑位置固定，仅缓存一次句柄，避免集中 thinker 高频重复扫描。
	local manager = THD_LANE_CREEP_PROTECTION
	if manager.buildings == nil then
		manager.buildings = {}
		for _, classname in ipairs({"npc_dota_tower", "npc_dota_barracks", "npc_dota_fort"}) do
			for _, building in pairs(LaneCreepProtection_FindAllByClassname(classname)) do
				table.insert(manager.buildings, building)
			end
		end
	end
	for _, building in pairs(manager.buildings) do
		if LaneCreepProtection_IsValid(building) then
			table.insert(targets, building)
		end
	end
	return targets
end

local function LaneCreepProtection_ShouldRelease(creep, targets)
	local team = creep:GetTeamNumber()
	for _, target in pairs(targets) do
		if target ~= creep and target:GetTeamNumber() ~= team then
			local releaseRadius = LaneCreepProtection_IsLaneCreep(target)
				and LANE_CREEP_PROTECTION_CREEP_RELEASE_RADIUS
				or LANE_CREEP_PROTECTION_BUILDING_RELEASE_RADIUS
			if LaneCreepProtection_DistanceSquared(creep, target) <= releaseRadius * releaseRadius then
				return true
			end
		end
	end
	return false
end

local function LaneCreepProtection_RestoreCreep(creep, state)
	if not LaneCreepProtection_IsValid(creep) then return end
	if state ~= nil and state.attackCapability ~= nil and creep.SetAttackCapability ~= nil then
		creep:SetAttackCapability(state.attackCapability)
	end
	if state ~= nil and state.acquisitionRange ~= nil and creep.SetAcquisitionRange ~= nil then
		creep:SetAcquisitionRange(state.acquisitionRange)
	end
	if creep.SetIdleAcquire ~= nil then
		creep:SetIdleAcquire(true)
	end
end

local function LaneCreepProtection_Release(creep, state)
	LaneCreepProtection_RestoreCreep(creep, state)
	if creep ~= nil and creep.IsNull ~= nil and not creep:IsNull() then
		creep:RemoveModifierByName("modifier_thdots_lane_creep_march_protection")
	end
end

local function LaneCreepProtection_Think()
	local manager = THD_LANE_CREEP_PROTECTION
	if not LaneCreepProtection_IsBeforeEndTime() then
		for _, state in pairs(manager.creeps) do
			LaneCreepProtection_Release(state.creep, state)
		end
		manager.creeps = {}
		manager.thinkerRunning = false
		return nil
	end

	local targets = LaneCreepProtection_CollectReleaseTargets()
	for entindex, state in pairs(manager.creeps) do
		local creep = state.creep
		if not LaneCreepProtection_IsValid(creep) then
			manager.creeps[entindex] = nil
		elseif LaneCreepProtection_ShouldRelease(creep, targets) then
			LaneCreepProtection_Release(creep, state)
			manager.creeps[entindex] = nil
		else
			-- 护送期间移除攻击能力，避免原生小兵 AI 在清除目标后立刻重新仇恨英雄。
			if creep.SetAttackCapability ~= nil then
				creep:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
			end
			if creep.SetAcquisitionRange ~= nil then
				creep:SetAcquisitionRange(LANE_CREEP_PROTECTION_ACQUISITION_RANGE)
			end
			if creep.SetIdleAcquire ~= nil then
				creep:SetIdleAcquire(false)
			end
			local attackTarget = creep.GetAttackTarget ~= nil and creep:GetAttackTarget() or nil
			if LaneCreepProtection_IsPlayerControlledUnit(attackTarget) then
				if creep.SetForceAttackTarget ~= nil then creep:SetForceAttackTarget(nil) end
				if creep.SetAggroTarget ~= nil then
					creep:SetAggroTarget(nil)
				elseif creep.Stop ~= nil then
					creep:Stop()
				end
			end
		end
	end

	if next(manager.creeps) == nil then
		manager.thinkerRunning = false
		return nil
	end
	return LANE_CREEP_PROTECTION_THINK_INTERVAL
end

local function LaneCreepProtection_StartThinker()
	local manager = THD_LANE_CREEP_PROTECTION
	if manager.thinkerRunning then return end
	manager.thinkerRunning = true
	GameRules:GetGameModeEntity():SetContextThink("thd_lane_creep_protection", LaneCreepProtection_Think, 0)
end

function THD2_RegisterLaneCreepMarchProtection(unit)
	if not LaneCreepProtection_IsBeforeEndTime() or not LaneCreepProtection_IsLaneCreep(unit) then return end
	if not LaneCreepProtection_IsValid(unit) then return end

	local entindex = unit:entindex()
	if THD_LANE_CREEP_PROTECTION.creeps[entindex] ~= nil then return end

	-- 保存原始索敌距离，护送结束后恢复兵线的正常战斗行为。
	THD_LANE_CREEP_PROTECTION.creeps[entindex] = {
		creep = unit,
		attackCapability = unit.GetAttackCapability ~= nil and unit:GetAttackCapability() or nil,
		acquisitionRange = unit.GetAcquisitionRange ~= nil and unit:GetAcquisitionRange() or nil,
	}
	if unit.SetAttackCapability ~= nil then
		unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
	end
	if unit.SetAcquisitionRange ~= nil then
		unit:SetAcquisitionRange(LANE_CREEP_PROTECTION_ACQUISITION_RANGE)
	end
	if unit.SetIdleAcquire ~= nil then
		unit:SetIdleAcquire(false)
	end
	unit:AddNewModifier(unit, nil, "modifier_thdots_lane_creep_march_protection", {})
	LaneCreepProtection_StartThinker()
end

modifier_thdots_lane_creep_march_protection = class({})

function modifier_thdots_lane_creep_march_protection:IsHidden() return true end
function modifier_thdots_lane_creep_march_protection:IsDebuff() return false end
function modifier_thdots_lane_creep_march_protection:IsPurgable() return false end

function modifier_thdots_lane_creep_march_protection:OnCreated()
	if not IsServer() then return end
	self.createdAt = GameRules:GetGameTime()
end

function modifier_thdots_lane_creep_march_protection:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_thdots_lane_creep_march_protection:GetModifierIncomingDamage_Percentage(params)
	local attacker = params ~= nil and params.attacker or nil
	if LaneCreepProtection_IsBeforeEndTime() and LaneCreepProtection_IsPlayerControlledUnit(attacker) then
		return LANE_CREEP_PROTECTION_PLAYER_DAMAGE_REDUCTION
	end
	return 0
end

function modifier_thdots_lane_creep_march_protection:GetModifierStatusResistanceStacking()
	return LaneCreepProtection_IsBeforeEndTime() and LANE_CREEP_PROTECTION_STATUS_RESISTANCE or 0
end

function modifier_thdots_lane_creep_march_protection:GetModifierMoveSpeedBonus_Percentage()
	if not IsServer() or self.createdAt == nil then return 0 end
	if GameRules:GetGameTime() - self.createdAt >= LANE_CREEP_PROTECTION_SPEED_DELAY then
		return LANE_CREEP_PROTECTION_SPEED_BONUS
	end
	return 0
end
