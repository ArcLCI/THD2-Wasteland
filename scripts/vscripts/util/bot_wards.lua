if BotObserverWards == nil then
	BotObserverWards = {}
end

local BOT_OBSERVER_WARD_INTERVAL = 120
local BOT_SENTRY_WARD_INTERVAL = 140
local BOT_WARD_INITIAL_DELAY = 10
local BOT_SENTRY_WARD_INITIAL_DELAY = 40
local BOT_OBSERVER_WARD_RADIUS = 1600
local BOT_SENTRY_WARD_RADIUS = 600
local BOT_SENTRY_WARD_VISION_RANGE = 150
local BOT_SENTRY_WARD_TRUE_SIGHT_RANGE = 900
local BOT_OBSERVER_WARD_MAX_PER_ROUND_MIN = 4
local BOT_OBSERVER_WARD_MAX_PER_ROUND_MAX = 5
local BOT_SENTRY_WARD_MAX_PER_ROUND = 2
-- 生命周期略短于刷新间隔，避免下一轮选点时旧眼还未被清理导致跳过生成。
local BOT_OBSERVER_WARD_DURATION = 119
local BOT_SENTRY_WARD_DURATION = 139

local BOT_WARD_TYPE_OBSERVER = "observer"
local BOT_WARD_TYPE_SENTRY = "sentry"

local BOT_WARD_LANE_TOP = "top"
local BOT_WARD_LANE_MID = "mid"
local BOT_WARD_LANE_BOT = "bot"
local BOT_WARD_LANES = {
	BOT_WARD_LANE_TOP,
	BOT_WARD_LANE_MID,
	BOT_WARD_LANE_BOT,
}

local TOWER_TOP_1 = "top_1"
local TOWER_MID_1 = "mid_1"
local TOWER_BOT_1 = "bot_1"
local TOWER_TOP_2 = "top_2"
local TOWER_MID_2 = "mid_2"
local TOWER_BOT_2 = "bot_2"
local TOWER_TOP_3 = "top_3"
local TOWER_MID_3 = "mid_3"
local TOWER_BOT_3 = "bot_3"

local BOT_WARD_TOWER_ORDER = {
	TOWER_TOP_1,
	TOWER_MID_1,
	TOWER_BOT_1,
	TOWER_TOP_2,
	TOWER_MID_2,
	TOWER_BOT_2,
	TOWER_TOP_3,
	TOWER_MID_3,
	TOWER_BOT_3,
}

local BOT_WARD_PREVIOUS_TOWER = {
	[TOWER_TOP_2] = TOWER_TOP_1,
	[TOWER_TOP_3] = TOWER_TOP_2,
	[TOWER_MID_2] = TOWER_MID_1,
	[TOWER_MID_3] = TOWER_MID_2,
	[TOWER_BOT_2] = TOWER_BOT_1,
	[TOWER_BOT_3] = TOWER_BOT_2,
}

local BOT_WARD_TOWER_NAMES = {
	[DOTA_TEAM_GOODGUYS] = {
		[TOWER_TOP_1] = {"npc_dota_goodguys_tower1_top"},
		[TOWER_MID_1] = {"npc_dota_goodguys_tower1_mid"},
		[TOWER_BOT_1] = {"npc_dota_goodguys_tower1_bot"},
		[TOWER_TOP_2] = {"npc_dota_goodguys_tower2_top"},
		[TOWER_MID_2] = {"npc_dota_goodguys_tower2_mid"},
		[TOWER_BOT_2] = {"npc_dota_goodguys_tower2_bot"},
		[TOWER_TOP_3] = {"npc_dota_goodguys_tower3_top"},
		[TOWER_MID_3] = {"npc_dota_goodguys_tower3_mid"},
		[TOWER_BOT_3] = {"npc_dota_goodguys_tower3_bot"},
	},
	[DOTA_TEAM_BADGUYS] = {
		[TOWER_TOP_1] = {"npc_dota_badguys_tower1_top"},
		[TOWER_MID_1] = {"npc_dota_badguys_tower1_mid"},
		[TOWER_BOT_1] = {"npc_dota_badguys_tower1_bot"},
		[TOWER_TOP_2] = {"npc_dota_badguys_tower2_top"},
		[TOWER_MID_2] = {"npc_dota_badguys_tower2_mid"},
		[TOWER_BOT_2] = {"npc_dota_badguys_tower2_bot"},
		[TOWER_TOP_3] = {"npc_dota_badguys_tower3_top"},
		[TOWER_MID_3] = {"npc_dota_badguys_tower3_mid"},
		[TOWER_BOT_3] = {"npc_dota_badguys_tower3_bot"},
	},
}

local BOT_WARD_LANING_POINTS = {
	[DOTA_TEAM_GOODGUYS] = {
		Vector(-3971, 1595, 256),
		Vector(-7804, 3814, 128),
		Vector(-1937, 214, 128),
		Vector(-135, 1380, 128),
		Vector(3106, -4055, 256),
		Vector(7939, -5568, 128),
	},
	[DOTA_TEAM_BADGUYS] = {
		Vector(-4275, 3520, 128),
		Vector(-7047, 5091, 128),
		Vector(-1542, 2036, 256),
		Vector(1386, -506, 128),
		Vector(4196, -4765, 128),
		Vector(8390, -4272, 128),
	},
}

local BOT_WARD_START_POINTS = {
	[DOTA_TEAM_GOODGUYS] = {
		Vector(-247, -1091, 128),
		Vector(-1939, 223, 128),
		Vector(193, -1240, 128),
		Vector(1570, -4625, 256),
	},
	[DOTA_TEAM_BADGUYS] = {
		Vector(-489, 300, 128),
		Vector(1384, -498, 128),
		Vector(-1121, 1443, 128),
		Vector(-1751, 3570, 256),
	},
}

local BOT_WARD_LANING_POINT_LANES = {
	[DOTA_TEAM_GOODGUYS] = {
		BOT_WARD_LANE_TOP,
		BOT_WARD_LANE_TOP,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_BOT,
		BOT_WARD_LANE_BOT,
	},
	[DOTA_TEAM_BADGUYS] = {
		BOT_WARD_LANE_TOP,
		BOT_WARD_LANE_TOP,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_BOT,
		BOT_WARD_LANE_BOT,
	},
}

local BOT_WARD_START_POINT_LANES = {
	[DOTA_TEAM_GOODGUYS] = {
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_BOT,
	},
	[DOTA_TEAM_BADGUYS] = {
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_MID,
		BOT_WARD_LANE_TOP,
	},
}

local BOT_WARD_ALIVE_OWN_TOWER_POINTS = {
	[DOTA_TEAM_GOODGUYS] = {
		[TOWER_TOP_1] = {Vector(-5922, 5928, 128), Vector(-6834, 3247, 128), Vector(-3654, 3793, 128)},
		[TOWER_MID_1] = {Vector(2452, -2576, 0), Vector(-108, -13, 128), Vector(-2406, 2231, 0)},
		[TOWER_BOT_1] = {Vector(5467, -4894, 128), Vector(5875, -7195, 256), Vector(3109, -4063, 256)},
		[TOWER_TOP_2] = {Vector(-7931, 1819, 536), Vector(-3973, 1598, 256), Vector(-4342, -1032, 536)},
		[TOWER_MID_2] = {Vector(-1285, -4335, 403), Vector(-4344, -1024, 536), Vector(-860, -2106, 128)},
		[TOWER_BOT_2] = {Vector(2551, -7068, 128), Vector(1576, -4627, 256), Vector(-210, -8172, 134)},
		[TOWER_TOP_3] = {Vector(-6553, -3060, 256), Vector(-7507, -958, 256), Vector(-4841, -2106, 256)},
		[TOWER_MID_3] = {Vector(-4344, -3908, 256), Vector(-1290, -4338, 403), Vector(-4339, -1026, 536)},
		[TOWER_BOT_3] = {Vector(-1797, -5896, 128), Vector(-3619, -6092, 256), Vector(-1691, -7687, 134)},
	},
	[DOTA_TEAM_BADGUYS] = {
		[TOWER_TOP_1] = {Vector(-8032, 6462, 256), Vector(-3874, 5246, 128), Vector(-4529, 2137, 128)},
		[TOWER_MID_1] = {Vector(-1119, 1438, 128), Vector(2816, -1451, 256), Vector(-1634, 3504, 256)},
		[TOWER_BOT_1] = {Vector(4328, -3322, 128), Vector(4883, -1857, 128), Vector(7697, -1581, 528)},
		[TOWER_TOP_2] = {Vector(-1638, 3507, 256), Vector(-1611, 7647, 124), Vector(-4167, 6423, 128)},
		[TOWER_MID_2] = {Vector(3114, -272, 256), Vector(1032, 3569, 400), Vector(-1641, 3508, 256)},
		[TOWER_BOT_2] = {Vector(7702, -1582, 528), Vector(4608, 769, 528), Vector(2822, -1457, 256)},
		[TOWER_TOP_3] = {Vector(3119, 5729, 256), Vector(1029, 3567, 400), Vector(941, 5142, 128), Vector(1269, 7236, 134)},
		[TOWER_MID_3] = {Vector(4010, 3487, 256), Vector(4607, 770, 528), Vector(1732, 2450, 128)},
		[TOWER_BOT_3] = {Vector(6346, 2655, 256), Vector(4611, 764, 528), Vector(8034, 761, 256)},
	},
}

local BOT_WARD_DEAD_ENEMY_TOWER_POINTS = {
	[DOTA_TEAM_GOODGUYS] = {
		[TOWER_TOP_1] = {Vector(-5870, 8023, 256), Vector(-1611, 7652, 124), Vector(-2238, 4264, 256), Vector(1026, 3572, 400)},
		[TOWER_MID_1] = {Vector(1031, 3569, 400), Vector(829, 1583, 128), Vector(4610, 764, 528), Vector(3443, -700, 256)},
		[TOWER_BOT_1] = {Vector(4644, -1800, 128), Vector(7682, -2583, 256), Vector(7695, -1577, 528), Vector(5095, -242, 256)},
		[TOWER_TOP_2] = {Vector(1030, 3568, 400), Vector(-1616, 7654, 124), Vector(3168, 6605, 256), Vector(2339, 4270, 128)},
		[TOWER_MID_2] = {Vector(4607, 770, 528), Vector(3403, 983, 256), Vector(1028, 3571, 400), Vector(4550, 2872, 256), Vector(3383, 4062, 256)},
		[TOWER_BOT_2] = {Vector(8125, 704, 256), Vector(4610, 764, 528), Vector(5497, 2661, 256)},
		[TOWER_TOP_3] = {Vector(2331, 4272, 128), Vector(4446, 5554, 256)},
		[TOWER_MID_3] = {Vector(4470, 3880, 256), Vector(5749, 5296, 256)},
		[TOWER_BOT_3] = {Vector(5998, 3888, 256), Vector(5127, 2752, 256)},
	},
	[DOTA_TEAM_BADGUYS] = {
		[TOWER_TOP_1] = {Vector(-3856, 495, 256), Vector(-7904, 1791, 535), Vector(-7559, 370, 256)},
		[TOWER_MID_1] = {Vector(-4342, -1024, 536), Vector(-3404, -344, 256), Vector(-813, -2435, 128), Vector(-1287, -4357, 403)},
		[TOWER_BOT_1] = {Vector(3806, -4584, 128), Vector(3937, -7217, 128), Vector(2558, -7080, 128), Vector(1743, -5084, 256), Vector(2033, -8356, 250)},
		[TOWER_TOP_2] = {Vector(-5282, -1584, 256), Vector(-7489, -1117, 256), Vector(-5680, -3137, 256)},
		[TOWER_MID_2] = {Vector(-1290, -4332, 403), Vector(-4340, -1031, 536), Vector(-3271, -1423, 256), Vector(-3788, -4521, 256), Vector(-5172, -3414, 256), Vector(-4903, -2862, 128), Vector(-3086, -4270, 128)},
		[TOWER_BOT_2] = {Vector(-1289, -4338, 403), Vector(-1890, -7873, 134), Vector(-3526, -6962, 256), Vector(-3611, -5316, 256), Vector(-2750, -5278, 128)},
		[TOWER_TOP_3] = {Vector(-6401, -4283, 256)},
		[TOWER_MID_3] = {Vector(-4915, -4405, 256), Vector(-4908, -4402, 256), Vector(-6172, 5639, 256)},
		[TOWER_BOT_3] = {Vector(-4850, -5935, 256)},
	},
}

local function BotWard_GetOpposingTeam(team)
	if team == DOTA_TEAM_GOODGUYS then return DOTA_TEAM_BADGUYS end
	if team == DOTA_TEAM_BADGUYS then return DOTA_TEAM_GOODGUYS end
	return nil
end

local function BotWard_FindTower(team, towerKey)
	local names = BOT_WARD_TOWER_NAMES[team] and BOT_WARD_TOWER_NAMES[team][towerKey]
	if names == nil then return nil end

	local towers = Entities:FindAllByClassname("npc_dota_tower")
	for _, tower in pairs(towers) do
		if tower ~= nil and not tower:IsNull() then
			local unitName = tower:GetUnitName()
			for _, name in pairs(names) do
				if unitName == name then
					return tower
				end
			end
		end
	end

	for _, name in pairs(names) do
		local tower = Entities:FindByName(nil, name)
		if tower ~= nil and not tower:IsNull() then
			return tower
		end
	end

	return nil
end

local function BotWard_IsTowerAlive(team, towerKey)
	local tower = BotWard_FindTower(team, towerKey)
	return tower ~= nil and tower:IsAlive()
end

local function BotWard_GetTowerLane(towerKey)
	if string.find(towerKey, "^top") ~= nil then return BOT_WARD_LANE_TOP end
	if string.find(towerKey, "^mid") ~= nil then return BOT_WARD_LANE_MID end
	if string.find(towerKey, "^bot") ~= nil then return BOT_WARD_LANE_BOT end
	return BOT_WARD_LANE_MID
end

local function BotWard_AddPoint(candidates, point, priority, lane)
	table.insert(candidates, {
		point = point,
		priority = priority,
		lane = lane or BOT_WARD_LANE_MID,
		roll = RandomInt(1, 1000000),
	})
end

local function BotWard_AddPointList(candidates, points, priority, lane)
	if points == nil then return end
	for _, point in pairs(points) do
		BotWard_AddPoint(candidates, point, priority, lane)
	end
end

local function BotWard_AddIndexedPointList(candidates, points, priority, lanes)
	if points == nil then return end
	for index, point in ipairs(points) do
		BotWard_AddPoint(candidates, point, priority, lanes and lanes[index])
	end
end

local function BotWard_HasPreviousTowerAlive(team, towerKey)
	local previousTower = BOT_WARD_PREVIOUS_TOWER[towerKey]
	return previousTower ~= nil and BotWard_IsTowerAlive(team, previousTower)
end

local function BotWard_AddTowerCandidates(candidates, team)
	local enemyTeam = BotWard_GetOpposingTeam(team)

	for _, towerKey in pairs(BOT_WARD_TOWER_ORDER) do
		local lane = BotWard_GetTowerLane(towerKey)

		if BotWard_IsTowerAlive(team, towerKey) and not BotWard_HasPreviousTowerAlive(team, towerKey) then
			BotWard_AddPointList(candidates, BOT_WARD_ALIVE_OWN_TOWER_POINTS[team][towerKey], 2, lane)
		end

		if enemyTeam ~= nil and not BotWard_IsTowerAlive(enemyTeam, towerKey) and not BotWard_HasPreviousTowerAlive(enemyTeam, towerKey) then
			BotWard_AddPointList(candidates, BOT_WARD_DEAD_ENEMY_TOWER_POINTS[team][towerKey], 1, lane)
		end
	end
end

local function BotWard_BuildObserverCandidates(team, firstRound)
	local candidates = {}

	if firstRound then
		BotWard_AddIndexedPointList(candidates, BOT_WARD_START_POINTS[team], 0, BOT_WARD_START_POINT_LANES[team])
	end
	BotWard_AddIndexedPointList(candidates, BOT_WARD_LANING_POINTS[team], 3, BOT_WARD_LANING_POINT_LANES[team])

	BotWard_AddTowerCandidates(candidates, team)

	return candidates
end

local function BotWard_BuildSentryCandidates(team, firstRound)
	local candidates = {}
	if firstRound then
		BotWard_AddIndexedPointList(candidates, BOT_WARD_START_POINTS[team], 0, BOT_WARD_START_POINT_LANES[team])
	end
	-- 首轮以后排除 START_POINTS，只从线上眼位和攻防塔相关眼位中选择。
	BotWard_AddIndexedPointList(candidates, BOT_WARD_LANING_POINTS[team], 2, BOT_WARD_LANING_POINT_LANES[team])
	BotWard_AddTowerCandidates(candidates, team)
	return candidates
end

local function BotWard_IsPointNear(pointA, pointB, distance)
	return (pointA - pointB):Length2D() <= distance
end

function BotObserverWards:IsWardClose(wardType, team, point, radius)
	self.wards = self.wards or {}
	self.wards[wardType] = self.wards[wardType] or {}
	self.wards[wardType][team] = self.wards[wardType][team] or {}

	for key, ward in pairs(self.wards[wardType][team]) do
		if ward == nil or ward:IsNull() or not ward:IsAlive() then
			self.wards[wardType][team][key] = nil
		elseif BotWard_IsPointNear(ward:GetAbsOrigin(), point, radius) then
			return true
		end
	end

	return false
end

local function BotWard_PointKey(point)
	return string.format("%d_%d", math.floor(point.x + 0.5), math.floor(point.y + 0.5))
end

function BotObserverWards:ApplyWardModifiers(ward, wardType, duration)
	if wardType == BOT_WARD_TYPE_OBSERVER then
		ward:AddNewModifier(ward, nil, "modifier_item_buff_ward", {
			duration = duration,
			vision_range = BOT_OBSERVER_WARD_RADIUS
		})
	elseif wardType == BOT_WARD_TYPE_SENTRY then
		ward:AddNewModifier(ward, nil, "modifier_item_buff_ward", {
			duration = duration,
			vision_range = BOT_SENTRY_WARD_VISION_RANGE
		})
		ward:AddNewModifier(ward, nil, "modifier_item_ward_true_sight", {
			duration = duration,
			true_sight_range = BOT_SENTRY_WARD_TRUE_SIGHT_RANGE
		})
		ward:AddNewModifier(ward, nil, "modifier_truesight", {
			duration = duration
		})
	end
end

function BotObserverWards:SpawnWard(wardType, team, point, unitName, duration)
	self.wards = self.wards or {}
	self.wards[wardType] = self.wards[wardType] or {}
	self.wards[wardType][team] = self.wards[wardType][team] or {}

	local key = BotWard_PointKey(point)
	local oldWard = self.wards[wardType][team][key]
	if oldWard ~= nil and not oldWard:IsNull() and oldWard:IsAlive() then
		return false
	end

	local spawnPoint = GetGroundPosition(point, nil)
	local ward = CreateUnitByName(unitName, spawnPoint, false, nil, nil, team)
	if ward == nil then return false end

	ward:SetTeam(team)
	ward:SetControllableByPlayer(-1, false)
	self:ApplyWardModifiers(ward, wardType, duration)
	self.wards[wardType][team][key] = ward

	ward:SetContextThink("bot_" .. wardType .. "_ward_lifetime", function()
		if ward ~= nil and not ward:IsNull() then
			ward:ForceKill(false)
		end
		return nil
	end, duration)

	return true
end

function BotObserverWards:SpawnObserverWard(team, point)
	return self:SpawnWard(BOT_WARD_TYPE_OBSERVER, team, point, "npc_dota_observer_wards", BOT_OBSERVER_WARD_DURATION)
end

function BotObserverWards:SpawnSentryWard(team, point)
	return self:SpawnWard(BOT_WARD_TYPE_SENTRY, team, point, "npc_dota_sentry_wards", BOT_SENTRY_WARD_DURATION)
end

function BotObserverWards:GetRound(wardType, team)
	self.rounds = self.rounds or {}
	self.rounds[wardType] = self.rounds[wardType] or {}
	return self.rounds[wardType][team] or 0
end

function BotObserverWards:AdvanceRound(wardType, team)
	self.rounds = self.rounds or {}
	self.rounds[wardType] = self.rounds[wardType] or {}
	self.rounds[wardType][team] = (self.rounds[wardType][team] or 0) + 1
end

function BotObserverWards:GetLaneCursor(wardType, team)
	self.laneCursors = self.laneCursors or {}
	self.laneCursors[wardType] = self.laneCursors[wardType] or {}
	self.laneCursors[wardType][team] = self.laneCursors[wardType][team] or 1
	return self.laneCursors[wardType][team]
end

function BotObserverWards:AdvanceLaneCursor(wardType, team, lane)
	self.laneCursors = self.laneCursors or {}
	self.laneCursors[wardType] = self.laneCursors[wardType] or {}

	for index, laneName in ipairs(BOT_WARD_LANES) do
		if laneName == lane then
			self.laneCursors[wardType][team] = index % #BOT_WARD_LANES + 1
			return
		end
	end

	self.laneCursors[wardType][team] = self:GetLaneCursor(wardType, team) % #BOT_WARD_LANES + 1
end

local function BotWard_IsSelectedDuplicate(selected, point, closeRadius)
	for _, selectedPoint in pairs(selected) do
		if BotWard_IsPointNear(selectedPoint, point, closeRadius) then
			return true
		end
	end

	return false
end

local function BotWard_SelectCandidates(wardType, team, candidates, maxCount, closeRadius)
	table.sort(candidates, function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		return a.roll < b.roll
	end)

	local selected = {}
	local used = {}

	local function canSelect(index)
		local candidate = candidates[index]
		return not used[index]
			and not BotObserverWards:IsWardClose(wardType, team, candidate.point, closeRadius)
			and not BotWard_IsSelectedDuplicate(selected, candidate.point, closeRadius)
	end

	while #selected < maxCount do
		local pickedIndex = nil
		local cursor = BotObserverWards:GetLaneCursor(wardType, team)

		for offset = 0, #BOT_WARD_LANES - 1 do
			local lane = BOT_WARD_LANES[(cursor + offset - 1) % #BOT_WARD_LANES + 1]
			for index, candidate in ipairs(candidates) do
				if candidate.lane == lane and canSelect(index) then
					pickedIndex = index
					break
				end
			end

			if pickedIndex ~= nil then
				break
			end
		end

		if pickedIndex == nil then
			for index, _ in ipairs(candidates) do
				if canSelect(index) then
					pickedIndex = index
					break
				end
			end
		end

		if pickedIndex == nil then
			break
		end

		local candidate = candidates[pickedIndex]
		used[pickedIndex] = true
		table.insert(selected, candidate.point)
		BotObserverWards:AdvanceLaneCursor(wardType, team, candidate.lane)
	end

	return selected
end

function BotObserverWards:SpawnObserverForTeam(team)
	if not THD2_TeamIsPureBot(team) then return end

	local firstRound = self:GetRound(BOT_WARD_TYPE_OBSERVER, team) == 0
	local candidates = BotWard_BuildObserverCandidates(team, firstRound)
	local maxCount = RandomInt(BOT_OBSERVER_WARD_MAX_PER_ROUND_MIN, BOT_OBSERVER_WARD_MAX_PER_ROUND_MAX)
	local selected = BotWard_SelectCandidates(BOT_WARD_TYPE_OBSERVER, team, candidates, maxCount, BOT_OBSERVER_WARD_RADIUS)
	for _, point in pairs(selected) do
		self:SpawnObserverWard(team, point)
	end
	self:AdvanceRound(BOT_WARD_TYPE_OBSERVER, team)
end

function BotObserverWards:SpawnSentryForTeam(team)
	if not THD2_TeamIsPureBot(team) then return end

	local firstRound = self:GetRound(BOT_WARD_TYPE_SENTRY, team) == 0
	local candidates = BotWard_BuildSentryCandidates(team, firstRound)
	local selected = BotWard_SelectCandidates(BOT_WARD_TYPE_SENTRY, team, candidates, BOT_SENTRY_WARD_MAX_PER_ROUND, BOT_SENTRY_WARD_RADIUS)
	for _, point in pairs(selected) do
		self:SpawnSentryWard(team, point)
	end
	self:AdvanceRound(BOT_WARD_TYPE_SENTRY, team)
end

function BotObserverWards:UpdateObserver()
	self:SpawnObserverForTeam(DOTA_TEAM_GOODGUYS)
	self:SpawnObserverForTeam(DOTA_TEAM_BADGUYS)
end

function BotObserverWards:UpdateSentry()
	self:SpawnSentryForTeam(DOTA_TEAM_GOODGUYS)
	self:SpawnSentryForTeam(DOTA_TEAM_BADGUYS)
end

function THD2_StartBotObserverWardThinker()
	if BotObserverWards.started then return end
	BotObserverWards.started = true

	GameRules:GetGameModeEntity():SetContextThink("bot_observer_ward_thinker", function()
		BotObserverWards:UpdateObserver()
		return BOT_OBSERVER_WARD_INTERVAL
	end, BOT_WARD_INITIAL_DELAY)

	GameRules:GetGameModeEntity():SetContextThink("bot_sentry_ward_thinker", function()
		BotObserverWards:UpdateSentry()
		return BOT_SENTRY_WARD_INTERVAL
	end, BOT_SENTRY_WARD_INITIAL_DELAY)
end
