
STARTING_GOLD = 500--650
DEBUG = true
GameMode = nil

THD_FOW_VIEWER_ENABLED = true
THD_FOW_VIEWER_STATS = THD_FOW_VIEWER_STATS or {
	calls = 0,
	blocked = 0,
	maxRadius = 0,
	maxDuration = 0,
	byTag = {},
}

THD_CONTEXT_THINK_ENABLED = true
THD_CONTEXT_THINK_STATS = THD_CONTEXT_THINK_STATS or {
	calls = 0,
	blocked = 0,
	uniqueNameCalls = 0,
	byTag = {},
}

function THD_SetContextThinkEnabled(enabled)
	THD_CONTEXT_THINK_ENABLED = enabled == true
	print("[THD][ContextThink] " .. (THD_CONTEXT_THINK_ENABLED and "ENABLED" or "DISABLED"))
end

function THD_GetContextThinkStats()
	return THD_CONTEXT_THINK_STATS
end

function THD_SetContextThink(entity, name, callback, delay, tag)
	local stats = THD_CONTEXT_THINK_STATS
	stats.calls = (stats.calls or 0) + 1
	local key = tag or name or "unknown"
	stats.byTag[key] = (stats.byTag[key] or 0) + 1
	if type(name) == "string" and string.find(name, "__") ~= nil then
		stats.uniqueNameCalls = (stats.uniqueNameCalls or 0) + 1
	end

	if THD_CONTEXT_THINK_ENABLED ~= true then
		stats.blocked = (stats.blocked or 0) + 1
		return
	end

	if entity ~= nil and entity.SetContextThink ~= nil then
		return entity:SetContextThink(name, callback, delay)
	end
end

function THD_SetGlobalContextThink(name, callback, delay, tag)
	return THD_SetContextThink(GameRules:GetGameModeEntity(), name, callback, delay, tag)
end

function THD_SetFOWViewerEnabled(enabled)
	THD_FOW_VIEWER_ENABLED = enabled == true
	print("[THD][FOW] AddFOWViewer " .. (THD_FOW_VIEWER_ENABLED and "ENABLED" or "DISABLED"))
end

function THD_GetFOWViewerStats()
	return THD_FOW_VIEWER_STATS
end

function THD_AddFOWViewer(team, location, radius, duration, unobstructed, tag)
	local stats = THD_FOW_VIEWER_STATS
	stats.calls = (stats.calls or 0) + 1
	stats.maxRadius = math.max(stats.maxRadius or 0, radius or 0)
	stats.maxDuration = math.max(stats.maxDuration or 0, duration or 0)
	local key = tag or "unknown"
	stats.byTag[key] = (stats.byTag[key] or 0) + 1

	if THD_FOW_VIEWER_ENABLED ~= true then
		stats.blocked = (stats.blocked or 0) + 1
		return
	end

	AddFOWViewer(team, location, radius, duration, unobstructed)
end

THD_NEUTRAL_ABILITY_SANITIZER_ENABLED = true
THD_NEUTRAL_ABILITY_SANITIZER_STATS = THD_NEUTRAL_ABILITY_SANITIZER_STATS or {
	scans = 0,
	neutralUnits = 0,
	removed = 0,
	byAbility = {},
}

local THD_NEUTRAL_ABILITIES_TO_SANITIZE = {
	neutral_upgrade = true,
	creep_irresolute = true,
	frogmen_riverborn_aura = true,
	frogmen_arm_of_the_deep = true,
	twin_gate_portal_warp = true,
}

local function THD_FindAllByClassname(classname)
	if Entities == nil then return {} end
	if Entities.FindAllByClassname ~= nil then
		return Entities:FindAllByClassname(classname) or {}
	end

	local result = {}
	local entity = nil
	repeat
		entity = Entities:FindByClassname(entity, classname)
		if entity ~= nil then
			table.insert(result, entity)
		end
	until entity == nil
	return result
end

local function THD_SanitizeNeutralAbilityOnUnit(unit)
	if unit == nil or unit.IsNull == nil then return 0 end
	local okUnit, isNull = pcall(function() return unit:IsNull() end)
	if not okUnit or isNull then return 0 end
	if unit.FindAbilityByName == nil or unit.RemoveAbility == nil then return 0 end
	local classname = ""
	if unit.GetClassname ~= nil then
		local okClassname, unitClassname = pcall(function() return unit:GetClassname() end)
		if okClassname and unitClassname ~= nil then
			classname = unitClassname
		end
	end
	if unit.IsNeutralUnitType ~= nil then
		local okNeutral, isNeutral = pcall(function() return unit:IsNeutralUnitType() end)
		if okNeutral and isNeutral ~= true and classname ~= "npc_dota_creep_lane" then return 0 end
	end

	local removed = 0
	local stats = THD_NEUTRAL_ABILITY_SANITIZER_STATS
	for abilityName, _ in pairs(THD_NEUTRAL_ABILITIES_TO_SANITIZE) do
		local okFind, ability = pcall(function() return unit:FindAbilityByName(abilityName) end)
		if okFind and ability ~= nil then
			local okRemove = pcall(function() unit:RemoveAbility(abilityName) end)
			if okRemove then
				removed = removed + 1
				stats.removed = (stats.removed or 0) + 1
				stats.byAbility[abilityName] = (stats.byAbility[abilityName] or 0) + 1
			end
		end
	end
	return removed
end

function THD_SetNeutralAbilitySanitizerEnabled(enabled)
	THD_NEUTRAL_ABILITY_SANITIZER_ENABLED = enabled == true
	print("[THD][NeutralSanitizer] " .. (THD_NEUTRAL_ABILITY_SANITIZER_ENABLED and "ENABLED" or "DISABLED"))
end

function THD_GetNeutralAbilitySanitizerStats()
	return THD_NEUTRAL_ABILITY_SANITIZER_STATS
end

function THD_SanitizeNeutralNativeAbilities(tag)
	if THD_NEUTRAL_ABILITY_SANITIZER_ENABLED ~= true then return end

	local stats = THD_NEUTRAL_ABILITY_SANITIZER_STATS
	stats.scans = (stats.scans or 0) + 1
	stats.lastTag = tag or "unknown"

	local units = THD_FindAllByClassname("npc_dota_creep_neutral")
	local laneCreeps = THD_FindAllByClassname("npc_dota_creep_lane")
	for _, unit in pairs(laneCreeps) do
		table.insert(units, unit)
	end
	stats.neutralUnits = (stats.neutralUnits or 0) + #units
	for _, unit in pairs(units) do
		THD_SanitizeNeutralAbilityOnUnit(unit)
	end
end

-- Backward-compatible names kept for older test hooks.
THD_NATIVE_NEUTRAL_ABILITY_STRIP_ENABLED = THD_NEUTRAL_ABILITY_SANITIZER_ENABLED
THD_NATIVE_NEUTRAL_ABILITY_STRIP_STATS = THD_NEUTRAL_ABILITY_SANITIZER_STATS

function THD_SetNativeNeutralAbilityStripEnabled(enabled)
	THD_SetNeutralAbilitySanitizerEnabled(enabled)
	THD_NATIVE_NEUTRAL_ABILITY_STRIP_ENABLED = THD_NEUTRAL_ABILITY_SANITIZER_ENABLED
end

THD_HIDDEN_NEUTRAL_CLEANUP_ENABLED = THD_HIDDEN_NEUTRAL_CLEANUP_ENABLED or false
THD_HIDDEN_NEUTRAL_CLEANUP_GRACE_SECONDS = THD_HIDDEN_NEUTRAL_CLEANUP_GRACE_SECONDS or 180
THD_HIDDEN_NEUTRAL_CLEANUP_SEEN_AT = THD_HIDDEN_NEUTRAL_CLEANUP_SEEN_AT or {}
THD_HIDDEN_NEUTRAL_CLEANUP_STATS = THD_HIDDEN_NEUTRAL_CLEANUP_STATS or {
	scans = 0,
	candidates = 0,
	deferred = 0,
	removed = 0,
	byName = {},
}

local function THD_GetVisibleObserverForTeam(team)
	for _, hero in pairs(THD_FindAllByClassname("npc_dota_hero*")) do
		if hero ~= nil and hero.IsNull ~= nil then
			local okValid, valid = pcall(function()
				return not hero:IsNull() and hero.GetTeamNumber ~= nil and hero:GetTeamNumber() == team
			end)
			if okValid and valid == true and hero.CanEntityBeSeenByMyTeam ~= nil then
				return hero
			end
		end
	end
	return nil
end

local function THD_IsEntityVisibleToTeam(unit, team)
	local observer = THD_GetVisibleObserverForTeam(team)
	if observer == nil or observer.CanEntityBeSeenByMyTeam == nil then return false end
	local ok, visible = pcall(function() return observer:CanEntityBeSeenByMyTeam(unit) end)
	return ok and visible == true
end

local function THD_IsHiddenInvulnerableNeutral(unit)
	if unit == nil or unit.IsNull == nil then return false end
	local okNull, isNull = pcall(function() return unit:IsNull() end)
	if not okNull or isNull then return false end
	local okAlive, alive = pcall(function() return unit.IsAlive ~= nil and unit:IsAlive() end)
	if not okAlive or alive ~= true then return false end
	local okNeutral, isNeutral = pcall(function() return unit.IsNeutralUnitType ~= nil and unit:IsNeutralUnitType() end)
	if not okNeutral or isNeutral ~= true then return false end
	local visibleRadiant = THD_IsEntityVisibleToTeam(unit, DOTA_TEAM_GOODGUYS)
	local visibleDire = THD_IsEntityVisibleToTeam(unit, DOTA_TEAM_BADGUYS)
	if visibleRadiant or visibleDire then return false end
	local okInvulnerable, invulnerable = pcall(function()
		return unit.IsInvulnerable ~= nil and unit:IsInvulnerable()
	end)
	return okInvulnerable and invulnerable == true
end

function THD_SetHiddenNeutralCleanupEnabled(enabled, source)
	THD_HIDDEN_NEUTRAL_CLEANUP_ENABLED = enabled == true
	THD_HIDDEN_NEUTRAL_CLEANUP_SEEN_AT = THD_HIDDEN_NEUTRAL_CLEANUP_SEEN_AT or {}
	local message = string.format(
		"[THD][HiddenNeutralCleanup] enabled=%s source=%s",
		tostring(THD_HIDDEN_NEUTRAL_CLEANUP_ENABLED),
		tostring(source or "unknown")
	)
	print(message)
	if THD_HIDDEN_NEUTRAL_CLEANUP_ENABLED and THD_CleanupHiddenInvulnerableNeutrals ~= nil then
		THD_CleanupHiddenInvulnerableNeutrals("enabled_immediate_scan", false)
	end
end

function THD_SetHiddenNeutralCleanupGraceSeconds(seconds)
	local value = tonumber(seconds)
	if value == nil or value < 0 then return false end
	THD_HIDDEN_NEUTRAL_CLEANUP_GRACE_SECONDS = value
	local message = string.format("[THD][HiddenNeutralCleanup] graceSeconds=%.1f", value)
	print(message)
	return true
end

function THD_GetHiddenNeutralCleanupStats()
	return THD_HIDDEN_NEUTRAL_CLEANUP_STATS
end

function THD_CleanupHiddenInvulnerableNeutrals(tag, force)
	if THD_HIDDEN_NEUTRAL_CLEANUP_ENABLED ~= true and force ~= true then return end
	local stats = THD_HIDDEN_NEUTRAL_CLEANUP_STATS
	stats.scans = (stats.scans or 0) + 1
	stats.lastTag = tag or "unknown"
	local neutrals = THD_FindAllByClassname("npc_dota_creep_neutral")
	local now = GameRules ~= nil and GameRules:GetGameTime() or 0
	local seenAt = THD_HIDDEN_NEUTRAL_CLEANUP_SEEN_AT or {}
	local currentSeen = {}
	for _, unit in pairs(neutrals) do
		if unit ~= nil and unit.IsNull ~= nil then
			local okEnt, entindex = pcall(function() return unit:entindex() end)
			if okEnt and entindex ~= nil then
				currentSeen[entindex] = true
			end
		end
		if THD_IsHiddenInvulnerableNeutral(unit) then
			stats.candidates = (stats.candidates or 0) + 1
			local entindex = -1
			local okEnt, unitEntindex = pcall(function() return unit:entindex() end)
			if okEnt and unitEntindex ~= nil then entindex = unitEntindex end
			if seenAt[entindex] == nil then
				seenAt[entindex] = now
			end
			local hiddenDuration = now - (seenAt[entindex] or now)
			if not force and hiddenDuration < (THD_HIDDEN_NEUTRAL_CLEANUP_GRACE_SECONDS or 180) then
				stats.deferred = (stats.deferred or 0) + 1
			else
				local name = "<unknown>"
				local okName, unitName = pcall(function()
					if unit.GetUnitName == nil then return "<unknown>" end
					return unit:GetUnitName()
				end)
				if okName and unitName ~= nil and unitName ~= "" then name = unitName end
				stats.byName[name] = (stats.byName[name] or 0) + 1
				local okRemove = pcall(function() UTIL_Remove(unit) end)
				if okRemove then
					stats.removed = (stats.removed or 0) + 1
					seenAt[entindex] = nil
				end
			end
		end
	end
	for entindex, _ in pairs(seenAt) do
		if currentSeen[entindex] ~= true then
			seenAt[entindex] = nil
		end
	end
	THD_HIDDEN_NEUTRAL_CLEANUP_SEEN_AT = seenAt
end

function THD_ForceCleanupHiddenInvulnerableNeutrals(source)
	if THD_CleanupHiddenInvulnerableNeutrals ~= nil then
		THD_CleanupHiddenInvulnerableNeutrals(source or "manual_force", true)
	end
	local stats = THD_HIDDEN_NEUTRAL_CLEANUP_STATS or {}
	local message = string.format(
		"[THD][HiddenNeutralCleanup] forceCleanup scans=%d candidates=%d deferred=%d removed=%d",
		stats.scans or 0,
		stats.candidates or 0,
		stats.deferred or 0,
		stats.removed or 0
	)
	print(message)
end

THD_ALL_NEUTRAL_CLEANUP_ENABLED = THD_ALL_NEUTRAL_CLEANUP_ENABLED or false
THD_ALL_NEUTRAL_CLEANUP_STATS = THD_ALL_NEUTRAL_CLEANUP_STATS or {
	scans = 0,
	removed = 0,
	byName = {},
}

local function THD_IsCleanupNeutralUnit(unit)
	if unit == nil or unit.IsNull == nil then return false end
	local okNull, isNull = pcall(function() return unit:IsNull() end)
	if not okNull or isNull then return false end
	local okNeutral, isNeutral = pcall(function()
		return unit.IsNeutralUnitType ~= nil and unit:IsNeutralUnitType()
	end)
	return okNeutral and isNeutral == true
end

function THD_SetAllNeutralCleanupEnabled(enabled, source)
	THD_ALL_NEUTRAL_CLEANUP_ENABLED = enabled == true
	local message = string.format("[THD][AllNeutralCleanup] enabled=%s source=%s", tostring(THD_ALL_NEUTRAL_CLEANUP_ENABLED), tostring(source or "unknown"))
	print(message)
	if THD_ALL_NEUTRAL_CLEANUP_ENABLED then
		THD_CleanupAllNeutralUnits("enabled_immediate")
	end
end

function THD_GetAllNeutralCleanupStats()
	return THD_ALL_NEUTRAL_CLEANUP_STATS
end

function THD_CleanupAllNeutralUnits(tag)
	local stats = THD_ALL_NEUTRAL_CLEANUP_STATS or { scans = 0, removed = 0, byName = {} }
	stats.scans = (stats.scans or 0) + 1
	stats.lastTag = tag or "unknown"
	stats.byName = stats.byName or {}
	local removedThisScan = 0
	for _, unit in pairs(THD_FindAllByClassname("npc_dota_creep_neutral")) do
		if THD_IsCleanupNeutralUnit(unit) then
			local name = "<unknown>"
			local okName, unitName = pcall(function()
				if unit.GetUnitName == nil then return "<unknown>" end
				return unit:GetUnitName()
			end)
			if okName and unitName ~= nil and unitName ~= "" then name = unitName end
			local okRemove = pcall(function() UTIL_Remove(unit) end)
			if okRemove then
				removedThisScan = removedThisScan + 1
				stats.removed = (stats.removed or 0) + 1
				stats.byName[name] = (stats.byName[name] or 0) + 1
			end
		end
	end
	THD_ALL_NEUTRAL_CLEANUP_STATS = stats
	local message = string.format("[THD][AllNeutralCleanup] tag=%s removedThisScan=%d totalRemoved=%d", tostring(tag or "manual"), removedThisScan, stats.removed or 0)
	print(message)
	return removedThisScan
end

function THD_ForceCleanupAllNeutralUnits(source)
	return THD_CleanupAllNeutralUnits(source or "manual_force")
end

function THD_EnableLateGameNeutralShutdown(source)
	local oldGrace = THD_HIDDEN_NEUTRAL_CLEANUP_GRACE_SECONDS or 180
	if THD_SetHiddenNeutralCleanupGraceSeconds ~= nil then
		THD_SetHiddenNeutralCleanupGraceSeconds(0)
	else
		THD_HIDDEN_NEUTRAL_CLEANUP_GRACE_SECONDS = 0
	end
	if THD_SetHiddenNeutralCleanupEnabled ~= nil then
		THD_SetHiddenNeutralCleanupEnabled(true, source or "late_game_neutral_shutdown")
	end
	if THD_SetAllNeutralCleanupEnabled ~= nil then
		THD_SetAllNeutralCleanupEnabled(true, source or "late_game_neutral_shutdown")
	else
		THD_ALL_NEUTRAL_CLEANUP_ENABLED = true
	end
	if THD_CleanupAllNeutralUnits ~= nil then
		THD_CleanupAllNeutralUnits(source or "late_game_neutral_shutdown")
	end
	if THD_ForceCleanupHiddenInvulnerableNeutrals ~= nil then
		THD_ForceCleanupHiddenInvulnerableNeutrals(source or "late_game_neutral_shutdown")
	end
	local message = string.format(
		"[THD][LateGameNeutralShutdown] enabled=true oldHiddenGrace=%.1f newHiddenGrace=0 allNeutralCleanup=true hiddenCleanup=true",
		oldGrace
	)
	print(message)
end
function THD_DisableNeutralsForLateGame(source)
	return THD_EnableLateGameNeutralShutdown(source)
end



function THD_GetNativeNeutralAbilityStripStats()
	return THD_GetNeutralAbilitySanitizerStats()
end

function THD_StripNativeNeutralAbilities(unit)
	if THD_NEUTRAL_ABILITY_SANITIZER_ENABLED ~= true then return end
	THD_SanitizeNeutralAbilityOnUnit(unit)
end

THD_COMBAT_EXPERIMENT_FLAGS = THD_COMBAT_EXPERIMENT_FLAGS or {
	hiddenNoAttack = false,
	hiddenNoAcquire = false,
	hiddenStripAbilities = false,
	neutralStripAbilities = false,
	neutralRemoveSelectedModifiers = false,
	laneLowAcquire = false,
	laneStripAbilities = false,
	laneRemoveSelectedModifiers = false,
}
THD_COMBAT_EXPERIMENT_STATE = THD_COMBAT_EXPERIMENT_STATE or {}
THD_COMBAT_EXPERIMENT_STATS = THD_COMBAT_EXPERIMENT_STATS or {
	scans = 0,
	hidden = 0,
	hiddenNoAttack = 0,
	hiddenNoAcquire = 0,
	hiddenStripped = 0,
	neutral = 0,
	neutralStripped = 0,
	neutralModifiersRemoved = 0,
	lane = 0,
	laneLowAcquire = 0,
	laneStripped = 0,
	laneModifiersRemoved = 0,
	restored = 0,
}

local function THD_GetEntityIndex(unit)
	if unit == nil or unit.entindex == nil then return nil end
	local ok, entindex = pcall(function() return unit:entindex() end)
	if ok then return entindex end
	return nil
end

local function THD_IsHiddenNeutralForExperiment(unit)
	if unit == nil or unit.IsNull == nil then return false end
	local okNull, isNull = pcall(function() return unit:IsNull() end)
	if not okNull or isNull then return false end
	local okAlive, alive = pcall(function() return unit.IsAlive ~= nil and unit:IsAlive() end)
	if not okAlive or alive ~= true then return false end
	local okNeutral, isNeutral = pcall(function() return unit.IsNeutralUnitType ~= nil and unit:IsNeutralUnitType() end)
	if not okNeutral or isNeutral ~= true then return false end
	return not THD_IsEntityVisibleToTeam(unit, DOTA_TEAM_GOODGUYS) and not THD_IsEntityVisibleToTeam(unit, DOTA_TEAM_BADGUYS)
end

local function THD_CombatExperimentSafeCall(defaultValue, fn)
	local ok, result = pcall(fn)
	if ok and result ~= nil then return result end
	return defaultValue
end

local function THD_RememberCombatState(unit)
	local entindex = THD_GetEntityIndex(unit)
	if entindex == nil then return nil end
	local state = THD_COMBAT_EXPERIMENT_STATE[entindex]
	if state == nil then
		state = {}
		state.attackCapability = THD_CombatExperimentSafeCall(nil, function()
			if unit.GetAttackCapability == nil then return nil end
			return unit:GetAttackCapability()
		end)
		state.acquisitionRange = THD_CombatExperimentSafeCall(nil, function()
			if unit.GetAcquisitionRange == nil then return nil end
			return unit:GetAcquisitionRange()
		end)
		THD_COMBAT_EXPERIMENT_STATE[entindex] = state
	end
	state.lastSeen = GameRules ~= nil and GameRules:GetGameTime() or 0
	return state
end

local function THD_RestoreCombatState(unit, entindex)
	local index = entindex or THD_GetEntityIndex(unit)
	if index == nil then return false end
	local state = THD_COMBAT_EXPERIMENT_STATE[index]
	if state == nil then return false end
	if unit ~= nil and unit.IsNull ~= nil then
		local okNull, isNull = pcall(function() return unit:IsNull() end)
		if okNull and not isNull then
			if state.attackCapability ~= nil and unit.SetAttackCapability ~= nil then
				pcall(function() unit:SetAttackCapability(state.attackCapability) end)
			end
			if state.acquisitionRange ~= nil and unit.SetAcquisitionRange ~= nil then
				pcall(function() unit:SetAcquisitionRange(state.acquisitionRange) end)
			end
			if unit.SetIdleAcquire ~= nil then
				pcall(function() unit:SetIdleAcquire(true) end)
			end
		end
	end
	THD_COMBAT_EXPERIMENT_STATE[index] = nil
	THD_COMBAT_EXPERIMENT_STATS.restored = (THD_COMBAT_EXPERIMENT_STATS.restored or 0) + 1
	return true
end

local function THD_StripAllAbilities(unit)
	if unit == nil or unit.GetAbilityCount == nil then return 0 end
	local names = {}
	local okCount, count = pcall(function() return unit:GetAbilityCount() end)
	if not okCount or count == nil then return 0 end
	for i = 0, count - 1 do
		local okAbility, ability = pcall(function() return unit:GetAbilityByIndex(i) end)
		if okAbility and ability ~= nil and ability.GetAbilityName ~= nil then
			local okName, name = pcall(function() return ability:GetAbilityName() end)
			if okName and name ~= nil and name ~= "" then table.insert(names, name) end
		end
	end
	local removed = 0
	for _, name in ipairs(names) do
		if unit.RemoveAbility ~= nil then
			local okRemove = pcall(function() unit:RemoveAbility(name) end)
			if okRemove then removed = removed + 1 end
		end
	end
	return removed
end

local function THD_RemoveSelectedCombatModifiers(unit)
	if unit == nil or unit.RemoveModifierByName == nil then return 0 end
	local modifierNames = {
		"modifier_neutral_sleep_ai",
		"modifier_neutral_upgrade",
		"modifier_creep_irresolute",
		"modifier_frogmen_riverborn_aura",
		"modifier_frogmen_arm_of_the_deep",
	}
	local removed = 0
	for _, name in ipairs(modifierNames) do
		local hasModifier = false
		if unit.HasModifier ~= nil then
			local okHas, result = pcall(function() return unit:HasModifier(name) end)
			hasModifier = okHas and result == true
		end
		if hasModifier then
			local okRemove = pcall(function() unit:RemoveModifierByName(name) end)
			if okRemove then removed = removed + 1 end
		end
	end
	return removed
end

local function THD_ApplyHiddenNeutralExperiment(unit)
	local flags = THD_COMBAT_EXPERIMENT_FLAGS
	if not THD_IsHiddenNeutralForExperiment(unit) then
		local entindex = THD_GetEntityIndex(unit)
		if entindex ~= nil and THD_COMBAT_EXPERIMENT_STATE[entindex] ~= nil then
			THD_RestoreCombatState(unit, entindex)
		end
		return
	end
	local stats = THD_COMBAT_EXPERIMENT_STATS
	stats.hidden = (stats.hidden or 0) + 1
	if flags.hiddenNoAttack or flags.hiddenNoAcquire or flags.hiddenStripAbilities then
		THD_RememberCombatState(unit)
	end
	if flags.hiddenNoAttack and unit.SetAttackCapability ~= nil then
		pcall(function() unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK) end)
		stats.hiddenNoAttack = (stats.hiddenNoAttack or 0) + 1
	end
	if flags.hiddenNoAcquire then
		if unit.SetAcquisitionRange ~= nil then pcall(function() unit:SetAcquisitionRange(0) end) end
		if unit.SetIdleAcquire ~= nil then pcall(function() unit:SetIdleAcquire(false) end) end
		if unit.Stop ~= nil then pcall(function() unit:Stop() end) end
		stats.hiddenNoAcquire = (stats.hiddenNoAcquire or 0) + 1
	end
	if flags.hiddenStripAbilities then
		local removed = THD_StripAllAbilities(unit)
		if removed > 0 then stats.hiddenStripped = (stats.hiddenStripped or 0) + removed end
	end
	if flags.neutralStripAbilities then
		local removed = THD_StripAllAbilities(unit)
		if removed > 0 then stats.neutralStripped = (stats.neutralStripped or 0) + removed end
	end
	if flags.neutralRemoveSelectedModifiers then
		local removed = THD_RemoveSelectedCombatModifiers(unit)
		if removed > 0 then stats.neutralModifiersRemoved = (stats.neutralModifiersRemoved or 0) + removed end
	end
end

local function THD_ApplyLaneCreepExperiment(unit)
	if unit == nil or unit.IsNull == nil then return end
	local okNull, isNull = pcall(function() return unit:IsNull() end)
	if not okNull or isNull then return end
	local okAlive, alive = pcall(function() return unit.IsAlive ~= nil and unit:IsAlive() end)
	if not okAlive or alive ~= true then return end
	local stats = THD_COMBAT_EXPERIMENT_STATS
	stats.lane = (stats.lane or 0) + 1
	local flags = THD_COMBAT_EXPERIMENT_FLAGS
	if flags.laneLowAcquire then
		THD_RememberCombatState(unit)
		if unit.SetAcquisitionRange ~= nil then pcall(function() unit:SetAcquisitionRange(300) end) end
		if unit.SetIdleAcquire ~= nil then pcall(function() unit:SetIdleAcquire(false) end) end
		stats.laneLowAcquire = (stats.laneLowAcquire or 0) + 1
	else
		local entindex = THD_GetEntityIndex(unit)
		if entindex ~= nil and THD_COMBAT_EXPERIMENT_STATE[entindex] ~= nil then
			THD_RestoreCombatState(unit, entindex)
		end
	end
	if flags.laneStripAbilities then
		local removed = THD_StripAllAbilities(unit)
		if removed > 0 then stats.laneStripped = (stats.laneStripped or 0) + removed end
	end
	if flags.laneRemoveSelectedModifiers then
		local removed = THD_RemoveSelectedCombatModifiers(unit)
		if removed > 0 then stats.laneModifiersRemoved = (stats.laneModifiersRemoved or 0) + removed end
	end
end

function THD_SetCombatExperimentFlag(flag, enabled, source)
	if THD_COMBAT_EXPERIMENT_FLAGS[flag] == nil then return false end
	THD_COMBAT_EXPERIMENT_FLAGS[flag] = enabled == true
	local message = string.format("[THD][CombatExperiment] %s=%s source=%s", flag, tostring(enabled == true), tostring(source or "unknown"))
	print(message)
	return true
end

function THD_GetCombatExperimentStats()
	return THD_COMBAT_EXPERIMENT_STATS
end

function THD_ApplyCombatExperiments(tag)
	local stats = THD_COMBAT_EXPERIMENT_STATS
	stats.scans = (stats.scans or 0) + 1
	stats.lastTag = tag or "unknown"
	stats.hidden = 0
	stats.hiddenNoAttack = 0
	stats.hiddenNoAcquire = 0
	stats.neutral = 0
	stats.neutralStripped = 0
	stats.neutralModifiersRemoved = 0
	stats.lane = 0
	stats.laneLowAcquire = 0
	stats.laneStripped = 0
	stats.laneModifiersRemoved = 0
	for _, unit in pairs(THD_FindAllByClassname("npc_dota_creep_neutral")) do
		stats.neutral = (stats.neutral or 0) + 1
		THD_ApplyHiddenNeutralExperiment(unit)
	end
	for _, unit in pairs(THD_FindAllByClassname("npc_dota_creep_lane")) do
		THD_ApplyLaneCreepExperiment(unit)
	end
end

THD_HERO_EXPERIMENT_STATE = THD_HERO_EXPERIMENT_STATE or {}
THD_HERO_EXPERIMENT_STATS = THD_HERO_EXPERIMENT_STATS or {
	attrValue = nil,
	visionValue = nil,
	attrApplied = 0,
	visionApplied = 0,
	restored = 0,
}

local function THD_ForEachHero(fn)
	local heroes = THD_FindAllByClassname("npc_dota_hero*")
	for _, hero in pairs(heroes) do
		if hero ~= nil and hero.IsRealHero ~= nil then
			local okReal, isReal = pcall(function() return hero:IsRealHero() end)
			if okReal and isReal == true then
				fn(hero)
			end
		end
	end
end

local function THD_RememberHeroExperimentState(hero)
	local entindex = THD_GetEntityIndex(hero)
	if entindex == nil then return nil end
	local state = THD_HERO_EXPERIMENT_STATE[entindex]
	if state == nil then
		state = {}
		state.strength = THD_CombatExperimentSafeCall(nil, function() return hero:GetBaseStrength() end)
		state.agility = THD_CombatExperimentSafeCall(nil, function() return hero:GetBaseAgility() end)
		state.intellect = THD_CombatExperimentSafeCall(nil, function() return hero:GetBaseIntellect() end)
		state.dayVision = THD_CombatExperimentSafeCall(nil, function()
			if hero.GetDayTimeVisionRange == nil then return nil end
			return hero:GetDayTimeVisionRange()
		end)
		state.nightVision = THD_CombatExperimentSafeCall(nil, function()
			if hero.GetNightTimeVisionRange == nil then return nil end
			return hero:GetNightTimeVisionRange()
		end)
		THD_HERO_EXPERIMENT_STATE[entindex] = state
	end
	return state
end

function THD_SetAllHeroBaseAttributes(value, source)
	local attr = tonumber(value)
	if attr == nil or attr < 0 then return false end
	local applied = 0
	THD_ForEachHero(function(hero)
		THD_RememberHeroExperimentState(hero)
		if hero.SetBaseStrength ~= nil then pcall(function() hero:SetBaseStrength(attr) end) end
		if hero.SetBaseAgility ~= nil then pcall(function() hero:SetBaseAgility(attr) end) end
		if hero.SetBaseIntellect ~= nil then pcall(function() hero:SetBaseIntellect(attr) end) end
		if hero.CalculateStatBonus ~= nil then pcall(function() hero:CalculateStatBonus(true) end) end
		applied = applied + 1
	end)
	THD_HERO_EXPERIMENT_STATS.attrValue = attr
	THD_HERO_EXPERIMENT_STATS.attrApplied = applied
	local message = string.format("[THD][HeroExperiment] attrs=%.1f applied=%d source=%s", attr, applied, tostring(source or "unknown"))
	print(message)
	return true
end

function THD_SetAllHeroVision(value, source)
	local vision = tonumber(value)
	if vision == nil or vision < 0 then return false end
	local applied = 0
	THD_ForEachHero(function(hero)
		THD_RememberHeroExperimentState(hero)
		if hero.SetDayTimeVisionRange ~= nil then pcall(function() hero:SetDayTimeVisionRange(vision) end) end
		if hero.SetNightTimeVisionRange ~= nil then pcall(function() hero:SetNightTimeVisionRange(vision) end) end
		applied = applied + 1
	end)
	THD_HERO_EXPERIMENT_STATS.visionValue = vision
	THD_HERO_EXPERIMENT_STATS.visionApplied = applied
	local message = string.format("[THD][HeroExperiment] vision=%.1f applied=%d source=%s", vision, applied, tostring(source or "unknown"))
	print(message)
	return true
end

function THD_RestoreHeroExperiment(source)
	local restored = 0
	THD_ForEachHero(function(hero)
		local entindex = THD_GetEntityIndex(hero)
		local state = entindex ~= nil and THD_HERO_EXPERIMENT_STATE[entindex] or nil
		if state ~= nil then
			if state.strength ~= nil and hero.SetBaseStrength ~= nil then pcall(function() hero:SetBaseStrength(state.strength) end) end
			if state.agility ~= nil and hero.SetBaseAgility ~= nil then pcall(function() hero:SetBaseAgility(state.agility) end) end
			if state.intellect ~= nil and hero.SetBaseIntellect ~= nil then pcall(function() hero:SetBaseIntellect(state.intellect) end) end
			if state.dayVision ~= nil and hero.SetDayTimeVisionRange ~= nil then pcall(function() hero:SetDayTimeVisionRange(state.dayVision) end) end
			if state.nightVision ~= nil and hero.SetNightTimeVisionRange ~= nil then pcall(function() hero:SetNightTimeVisionRange(state.nightVision) end) end
			if hero.CalculateStatBonus ~= nil then pcall(function() hero:CalculateStatBonus(true) end) end
			restored = restored + 1
		end
	end)
	THD_HERO_EXPERIMENT_STATE = {}
	THD_HERO_EXPERIMENT_STATS.attrValue = nil
	THD_HERO_EXPERIMENT_STATS.visionValue = nil
	THD_HERO_EXPERIMENT_STATS.restored = (THD_HERO_EXPERIMENT_STATS.restored or 0) + restored
	local message = string.format("[THD][HeroExperiment] restored=%d source=%s", restored, tostring(source or "unknown"))
	print(message)
	return true
end

function THD_GetHeroExperimentStats()
	return THD_HERO_EXPERIMENT_STATS
end

TRUE = 1
FALSE = 0

function Toolsprint(string)
	if IsInToolsMode() then
		print(string)
	end
end

function GetDistanceBetweenTwoVec2D(a, b)
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)
    return math.sqrt(xx*xx + yy*yy)
end

function GetRadBetweenTwoVec2D(a,b)
	local y = b.y - a.y
	local x = b.x - a.x
	return math.atan2(y,x)
end
--aVec:原点向量
--rectOrigin：单位原点向量
--rectWidth：矩形宽度
--rectLenth：矩形长度
--rectRad：矩形相对Y轴旋转角度
function IsRadInRect(aVec,rectOrigin,rectWidth,rectLenth,rectRad)
	local aRad = GetRadBetweenTwoVec2D(rectOrigin,aVec)
	local turnRad = aRad + (math.pi/2 - rectRad)
	local aRadius = GetDistanceBetweenTwoVec2D(rectOrigin,aVec)
	local turnX = aRadius*math.cos(turnRad)
	local turnY = aRadius*math.sin(turnRad)
	local maxX = rectWidth/2
	local minX = -rectWidth/2
	local maxY = rectLenth
	local minY = 0
	if(turnX<maxX and turnX>minX and turnY>minY and turnY<maxY)then
		return true
	else
	    return false
	end
	return false
end

function IsRadBetweenTwoRad2D(a,rada,radb)
    local maxrad = math.max(rada,radb)
    local minrad = math.min(rada,radb)
    
    if rada >= 0 and radb >= 0 then
        if(a<=maxrad and a>=minrad)then
            print("true")
            return true
        end
    elseif rada >=0 and radb < 0 then

    elseif rada < 0 and radb >= 0 then
        if(a<maxrad and a>minrad)then
            print("true")
            return true
        end
    elseif rada < 0 and radb < 0 then
        if(a<maxrad and a>minrad)then
            print("true")
            return true
        end
    end

	return false
end


-- cx = 目标的x
-- cy = 目标的y
-- ux = math.cos(theta)   (rad是caster和target的夹角的弧度制表示)
-- uy = math.sin(theta)
-- r = 目标和原点之间的距离
-- theta = 夹角的弧度制
-- px = 原点的x
-- py = 原点的y
-- 返回 true or false(目标是否在扇形内，在的话=true，不在=false)

function IsPointInCircularSector(cx,cy,ux,uy,r,theta,px,py)
    local dx = px - cx
    local dy = py - cy

    local length = math.sqrt(dx * dx + dy * dy)

    if (length > r) then
        return false
    end

    local vec = Vector(dx,dy,0):Normalized()
    return math.acos(vec.x * ux + vec.y * uy) < theta
 end 


function SetTargetToTraversable(target)
    local vecTarget = target:GetOrigin() 
    local vecGround = GetGroundPosition(vecTarget, nil)

    UnitNoCollision(target,vecTarget)
end

function CDOTA_BaseNPC:GetFountainHandle()
	local handle
	for i, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
		if fountain:GetTeamNumber() == self:GetTeamNumber() then
			handle = fountain
			break
		end
	end

    return handle
end

function CDOTA_BaseNPC:GetFountainAbsOrigin()
	local absorigin
	for i, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
		if fountain:GetTeamNumber() == self:GetTeamNumber() then
			absorigin = fountain:GetAbsOrigin()
			break
		end
	end

    return absorigin
end

function CDOTA_BaseNPC:SetUnitOnClearGround()       --学习imba的方法，延迟 1 FrameTime
	Timer.Wait 'SetOnClearGround' (FrameTime(), function()
		self:SetAbsOrigin(Vector(self:GetAbsOrigin().x, self:GetAbsOrigin().y, GetGroundPosition(self:GetAbsOrigin(), self).z))		
		FindClearSpaceForUnit(self, self:GetAbsOrigin(), true)
		ResolveNPCPositions(self:GetAbsOrigin(), 64)
	end)
end

function CDOTA_BaseNPC:EmitCasterSound(sCasterName, tSoundNames, fChancePct, flags, fCooldown, sCooldownindex)  -- from imba
	flags = flags or 0
	if self:GetName() ~= sCasterName then
		return true
	end

	if fCooldown then
		if self["VoiceCooldown"..sCooldownindex] then
			return true
		else
			self["VoiceCooldown"..sCooldownindex] = true
			Timers:CreateTimer(fCooldown, function()
				self["VoiceCooldown"..sCooldownindex] = nil
			end)
		end
	end

	if fChancePct then
		if fChancePct <= math.random(1,100) then
			return false -- Only return false if chance was missed
		end
	end
	if (bit.band(flags, DOTA_CAST_SOUND_FLAG_WHILE_DEAD) > 0) or self:IsAlive() then
		local sound = tSoundNames[math.random(1,#tSoundNames)]
		if bit.band(flags, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS) > 0 then
			self:EmitSound(sound)
		--elseif bit.band(flags, DOTA_CAST_SOUND_FLAG_GLOBAL) > 0 then
			-- Iterate through players, added later
		else
			StartSoundEventReliable(sound, self)
		end
	end
	return true
end

function CDOTA_BaseNPC:CasterSoundCooldown(sCasterName, fCooldown, sCooldownindex)  -- 使语音冷却进入cd
	if self:GetName() ~= sCasterName then
		return true
	end

	if fCooldown then
		if self["VoiceCooldown"..sCooldownindex] then
			return true
		else
			self["VoiceCooldown"..sCooldownindex] = true
			Timers:CreateTimer(fCooldown, function()
				self["VoiceCooldown"..sCooldownindex] = nil
			end)
		end
	end

	return true
end

function CDOTA_BaseNPC:GetUsedAbilitySlotCount()
	local count = 0
	for i = 0, self:GetAbilityCount() - 1 do
		if self:GetAbilityByIndex(i) then
			count = count + 1
		end
	end

	return count
end

function ParticleManager:DestroyParticleSystem(effectIndex,bool)
    if(bool)then
        if effectIndex ~= nil then
            ParticleManager:DestroyParticle(effectIndex,true)
            ParticleManager:ReleaseParticleIndex(effectIndex) 
        end
    else
        Timer.Wait 'Effect_Destroy_Particle' (4,
            function()
                if effectIndex ~= nil then
                    ParticleManager:DestroyParticle(effectIndex,true)
                    ParticleManager:ReleaseParticleIndex(effectIndex) 
                end
            end
        )
    end
end

function ParticleManager:DestroyParticleSystemTime(effectIndex,time)
    Timer.Wait 'Effect_Destroy_Particle_Time' (time,
        function()
            ParticleManager:DestroyParticle(effectIndex,true)
            ParticleManager:ReleaseParticleIndex(effectIndex) 
        end
    )
end

function is_spell_blocked(target,caster)
    if caster ~= nil then 
        if caster:GetTeam() == target:GetTeam() then
            return false
        end
    end
	if target:HasModifier("modifier_item_sphere_target") then
		target:RemoveModifierByName("modifier_item_sphere_target")  --The particle effect is played automatically when this modifier is removed (but the sound isn't).
		target:EmitSound("DOTA_Item.LinkensSphere.Activate")
		return true
	end
	return false
end

function THDReduceCooldown(ability,value)
    if value == 0 then return end
    local cooldown=(ability:GetCooldown(ability:GetLevel() - 1)+value)*(ability:GetCooldownTimeRemaining()/ability:GetCooldown(ability:GetLevel() - 1))
    ability:EndCooldown()
    ability:StartCooldown(cooldown)
end

function FindTelentValue(caster,name)
    local ability = caster:FindAbilityByName(name)
    if ability~=nil then
        return ability:GetSpecialValueFor("value")
    else
        return 0
    end
end




THD2_TALENT_MODIFIER_REGISTRY = THD2_TALENT_MODIFIER_REGISTRY or {
    special_bonus_unique_cheng_1 = {{ ability = "ability_thdots_chenEx", modifier = "modifier_ability_thdots_chenEx_telent_1" }},
    special_bonus_unique_cheng_2 = {{ ability = "ability_thdots_chenEx", modifier = "modifier_ability_thdots_chenEx_telent_2" }},
    special_bonus_unique_cheng_4 = {{ ability = "ability_thdots_chenEx", modifier = "modifier_ability_thdots_chenEx_telent_4" }},
    special_bonus_unique_daiyousei_1 = {{ ability = "ability_thdots_daiyouseiEx", modifier = "modifier_ability_thdots_daiyouseiEx_talent1" }},
    special_bonus_unique_daiyousei_4 = {{ ability = "ability_thdots_daiyouseiEx", modifier = "modifier_ability_thdots_daiyouseiEx_talent4" }},
    special_bonus_unique_daiyousei_5 = {{ ability = "ability_thdots_daiyouseiEx", modifier = "modifier_ability_thdots_daiyouseiEx_talent5" }},
    special_bonus_unique_daiyousei_6 = {{ ability = "ability_thdots_daiyouseiEx", modifier = "modifier_ability_thdots_daiyouseiEx_talent6" }},
    special_bonus_unique_eirin_1 = {{ ability = "ability_thdots_eirinex", modifier = "modifier_special_bonus_unique_eirin_1" }},
    special_bonus_unique_eirin_4 = {{ ability = "ability_thdots_eirinex", modifier = "modifier_special_bonus_unique_eirin_4" }},
    special_bonus_unique_eirin_5 = {{ ability = "ability_thdots_eirinex", modifier = "modifier_special_bonus_unique_eirin_5", stack = true }},
    special_bonus_unique_hina_6 = {{ ability = "ability_thdots_hinaEx", modifier = "modifier_ability_thdots_hinaEx_talent6" }},
    special_bonus_unique_kagerou_1 = {{ ability = "ability_thdots_kagerouEx", modifier = "modifier_ability_thdots_kagerouEx_talent1" }},
    special_bonus_unique_keine_2 = {{ ability = "ability_thdots_keineEx", modifier = "modifier_ability_thdots_keineEx_talent2" }},
    special_bonus_unique_keine_3 = {{ ability = "ability_thdots_keineEx", modifier = "modifier_ability_thdots_keineEx_talent3" }},
    special_bonus_unique_kisume_1 = {{ ability = "ability_thdots_kisumeEx", modifier = "modifier_ability_thdots_kisumeEx_telent_1", stack = true }},
    special_bonus_unique_kokoro_1 = {{ ability = "ability_thdots_kokoroEx_2", modifier = "modifier_ability_thdots_kokoroEx_2_talent1" }},
    special_bonus_unique_kokoro_2 = {{ ability = "ability_thdots_kokoroEx_2", modifier = "modifier_ability_thdots_kokoroEx_2_talent2" }},
    special_bonus_unique_kokoro_3 = {{ ability = "ability_thdots_kokoroEx_2", modifier = "modifier_ability_thdots_kokoroEx_2_talent3" }},
    special_bonus_unique_kokoro_4 = {{ ability = "ability_thdots_kokoroEx_2", modifier = "modifier_ability_thdots_kokoroEx_2_talent4" }},
    special_bonus_unique_larva_6 = {{ ability = "ability_thdots_larvaEx", modifier = "modifier_ability_thdots_larva_telent_2" }},
    special_bonus_unique_medicine_0 = {{ ability = "ability_thdots_medicineEx", modifier = "modifier_ability_thdots_medicine0_talent" }},
    special_bonus_unique_medicine_2 = {{ ability = "ability_thdots_medicineEx", modifier = "modifier_ability_thdots_medicine2_talent" }},
    special_bonus_unique_miyako_2 = {{ ability = "ability_thdots_miyakoEx", modifier = "modifier_ability_thdots_miyakoEx_telent_2", stack = true }},
    special_bonus_unique_miyako_3 = {{ ability = "ability_thdots_miyakoEx", modifier = "modifier_ability_thdots_miyakoEx_telent_3", stack = true }},
    special_bonus_unique_miyako_6 = {{ ability = "ability_thdots_miyakoEx", modifier = "modifier_ability_thdots_miyakoEx_telent_6", stack = true }},
    special_bonus_unique_nitori_1 = {{ ability = "ability_thdots_nitoriEx", modifier = "modifier_ability_thdots_nitoriEx_talent1" }},
    special_bonus_unique_nitori_6 = {{ ability = "ability_thdots_nitoriEx", modifier = "modifier_ability_thdots_nitoriEx_talent6" }},
    special_bonus_unique_parsee_4 = {{ ability = "ability_thdots_parseeEx", modifier = "modifier_ability_thdots_parseeEx_talent1" }},
    special_bonus_unique_parsee_5 = {{ ability = "ability_thdots_parseeEx", modifier = "modifier_ability_thdots_parseeEx_talent2" }},
    special_bonus_unique_Reisen_2_ability2_add_const = {{ ability = "ability_thdots_reisen_2_04", modifier = "modifier_ability_thdots_reisen2_04_telent_1" }},
    special_bonus_unique_remilia_1 = {{ ability = "ability_thdots_remilia01", modifier = "modifier_ability_thdots_remilia_talent_1" }},
    special_bonus_unique_sagume_5 = {{ ability = "ability_thdots_sagume_Ex", modifier = "modifier_ability_sagume_telent5" }},
    special_bonus_unique_sagume_6 = {{ ability = "ability_thdots_sagume_Ex", modifier = "modifier_ability_sagume_telent6" }},
    special_bonus_unique_seiga_2 = {{ ability = "ability_thdots_seigaEx", modifier = "modifier_ability_thdots_seigaEx_telent_2", stack = true }},
    special_bonus_unique_seiga_3 = {{ ability = "ability_thdots_seigaEx", modifier = "modifier_ability_thdots_seigaEx_telent_3", stack = true }},
    special_bonus_unique_seiga_6 = {{ ability = "ability_thdots_seigaEx", modifier = "modifier_ability_thdots_seigaEx_telent_6", stack = true }},
    special_bonus_unique_sumireko_1 = {{ ability = "ability_thdots_sumirekoEx", modifier = "modifier_ability_thdots_sumirekoEx_talent_1" }},
    special_bonus_unique_sumireko_4 = {{ ability = "ability_thdots_sumirekoEx", modifier = "modifier_ability_thdots_sumirekoEx_talent_2" }},
    special_bonus_unique_tojiko_1 = {{ ability = "ability_thdots_tojikoEx", modifier = "modifier_ability_thdots_tojikoEx_telent_1", stack = true }},
    special_bonus_unique_tojiko_4 = {{ ability = "ability_thdots_tojikoEx", modifier = "modifier_ability_thdots_tojikoEx_telent_4", stack = true }},
    special_bonus_unique_yorihime_1 = {{ ability = "ability_thdots_yorihime_Ex", modifier = "ability_thdots_yorihime_talent_1" }},
}

function THD2_ApplyTalentModifier(hero, talentName, entry)
    if not hero or hero:IsNull() or not talentName or not entry then return false end
    local talentValue = FindTelentValue(hero, talentName)
    if talentValue == 0 then return false end
    if hero:HasModifier(entry.modifier) then return true end

    local sourceAbility = hero:FindAbilityByName(entry.ability)
    if not sourceAbility then return false end

    local modifier = hero:AddNewModifier(hero, sourceAbility, entry.modifier, {})
    if modifier and entry.stack then
        modifier:SetStackCount(FindTelentValue(hero, entry.stackTalent or talentName))
    end
    return modifier ~= nil
end

function THD2_OnAbilityLearned(hero, ability)
    if not hero or hero:IsNull() or not ability then return end
    local abilityName = ability
    if type(ability) ~= "string" then
        if ability:IsNull() then return end
        abilityName = ability:GetAbilityName()
    end

    local entries = THD2_TALENT_MODIFIER_REGISTRY[abilityName]
    if not entries then return end
    for _, entry in pairs(entries) do
        THD2_ApplyTalentModifier(hero, abilityName, entry)
    end
end

function THD2_RefreshTalentModifiers(hero, sourceAbilityName)
    if not hero or hero:IsNull() then return true end
    local allApplied = true
    for talentName, entries in pairs(THD2_TALENT_MODIFIER_REGISTRY) do
        for _, entry in pairs(entries) do
            if not sourceAbilityName or entry.ability == sourceAbilityName then
                if FindTelentValue(hero, talentName) ~= 0 and not THD2_ApplyTalentModifier(hero, talentName, entry) then
                    allApplied = false
                end
            end
        end
    end
    return allApplied
end

function FindValueTHD(name,ability)

    if ability == nil then
        return 0
    end
    local thdvalue = ability:GetLevelSpecialValueFor(name, ability:GetLevel() - 1 )
--  print(thdvalue)
    return thdvalue

end

function GetSumModifierValues(hUnit, sMethod)
	local sum = 0
	for i, modifier in ipairs(hUnit:FindAllModifiers()) do
		if modifier[sMethod] then
			local bonus = modifier[sMethod](modifier) or 0
			sum = sum + bonus
		end
	end

	return sum
end

function print_r ( t )   --这个t是table，可以查看并打印keys里的所有table子类，一般给t传个keys
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function IsNotLunchbox_ability(ability)  --御币不能充能的技能
    if ability ~= nil then
        if ability:GetName() == "ability_thdots_patchouli_fire"
        or ability:GetName() == "ability_thdots_patchouli_water"
        or ability:GetName() == "ability_thdots_patchouli_wood"
        or ability:GetName() == "ability_thdots_patchouli_metal"
        or ability:GetName() == "ability_thdots_patchouli_earth"
		or ability:GetName() == "ability_thdots_kaguya02"
		or ability:GetName() == "twin_gate_portal_warp" -- 中立建筑传送门交互不应触发施法类被动
		or ability:GetName() == "ability_capture" -- 前哨占领交互不应触发施法类被动
		or ability:GetName() == "ability_lamp_use" -- 中立岗哨交互不应触发施法类被动
        then return true end
        if ability:IsToggle() or ability:GetAbilityType() == 3 then  --GetAbilityType() == 3 是HIDDEN技能，一般是天生，不触发
            return true
        end
    end
	if ability:ProcsMagicStick() then	-- 不知道为什么不能用否定
		return false
	end
end

function CastRang_Calculate(caster,point,range)
    local distance = (point - caster:GetOrigin()):Length2D()
    if distance >= range then
        distance = range
    end
    return distance
end

-- function DeleteDummy(targets)
--     for i=#targets,1,-1 do
--         if targets[i]:HasModifier("dummy_unit") then
--             table.remove(targets, i)
--         end
--     end
-- end

function DeleteDummy(targets)
    local slow = 1
    for fast = 1, #targets, 1 do
        if not targets[fast]:HasModifier("dummy_unit") then
            targets[slow] = targets[fast]
            slow = slow + 1
        end
    end
    while #targets >= slow do
        table.remove(targets)
    end
end

function DecideMaxRange(caster,point,max_range)
    local targetPoint = point
    local vecCaster = caster:GetOrigin()
    local maxRange = max_range
    local pointRad = GetRadBetweenTwoVec2D(vecCaster,targetPoint)
    if(GetDistanceBetweenTwoVec2D(vecCaster,targetPoint)<=maxRange)then
        return targetPoint
    else
        local blinkVector = Vector(math.cos(pointRad)*maxRange,math.sin(pointRad)*maxRange,0) + vecCaster
        return blinkVector
    end
end

DragonImmuneModifiers = {
	"modifier_item_dragon_star_buff",
	"modifier_meirin02_buff",
}

function CDOTA_BaseNPC:IsDragonImmune()
	for i, modifier in ipairs(DragonImmuneModifiers) do
		if self:HasModifier(modifier) then return true end
	end

	return false
end

function CDOTA_BaseNPC:IsTHDImmune()
	if self:IsDragonImmune() or self:HasModifier("modifier_item_tsundere_invulnerable") then return true end

	return false
end

function IsTHDImmune(target) --THD的魔免BUFF，如龙星，彩光风铃等
    if target:HasModifier("modifier_item_dragon_star_buff") --道具:龙星
        or target:HasModifier("modifier_meirin02_buff") --红美铃：彩光风铃
        or target:HasModifier("modifier_item_tsundere_invulnerable") --亡灵送行提灯
        then 
        return true
    else
        return false
    end
end

function GetAllModifierName(caster)
    print("--------------",caster:GetName(),"modifier list :--------------")
    for i=0,8 do
         if caster:GetModifierNameByIndex(i) ~= "" then
             print(caster:GetModifierNameByIndex(i))
         end
    end
    print("---------------end------------")
end

function GetAllAbilityName(caster)
    print("--------------",caster:GetName(),"ability list :--------------")
     -- 按实际技能槽数量扫描，避免越界触发控制台警告。
     for i=0,caster:GetAbilityCount() - 1 do
         local ability = caster:GetAbilityByIndex(i)
         if ability and ability ~= "" then
             print(ability:GetName())
         end
     end
    print("---------------end------------")
end

function IsTHDReflect(target) --THD的反弹伤害BUG
    if target:HasModifier("modifier_thdots_medicine03_OnTakeDamage") --毒人偶毒
        or target:HasModifier("modifier_item_frock_OnTakeDamage") --毒裙
        or target:HasModifier("OnMerlin04TakeDamage") --小号大
        then 
        return true
    else
        return false
    end
end

function IsNoBugModifier(modifier)
    if modifier ~= nil and modifier:GetName() ~= "" then
        if modifier:GetName() == "modifier_scripted_motion_controller" then
            return false
        end
        if modifier:GetName() == "modifier_skewer_disable_target" 
            or modifier:GetName() == "modifier_skewer_datadriven"
            or modifier:GetName() == "modifier_skewer_disable_caster"
            or modifier:GetName() == "modifier_scripted_motion_controlleris"
            then 
                -- print("-----------------------------------")
                -- print(modifier:GetName().." ：is Bug Modifier")
                -- print(modifier.parsee01)
                -- print("is Bug Modifier")
                return false
        else
            print(modifier:GetName()..":is NO Modifier")
                -- print(modifier.parsee01)
            return true
        end
    end
end

--P点掉落
function OnCollectionDrop(killedUnit,num)
    -- 优化：移除调试 print，避免后期大量掉落日志干扰性能。
    local point = killedUnit:GetOrigin()
    local radius = 250
    local time = 0
    for i=1,num do
        local random_point = Vector(point.x + RandomInt(-radius, radius),point.y + RandomInt(-radius/2, radius),point.z)
        local unit = CreateModifierThinker(
			nil,
			nil,
			"aura_ability_collection_find_master_lua",
			{model = "models/thd2/power.vmdl", name = "npc_power_up_unit"},
			killedUnit:GetOrigin(),
			DOTA_TEAM_NEUTRALS,
			false
		)
        unit.IsGet = false
        pcall(function()
            if unit.SetHullRadius ~= nil then unit:SetHullRadius(0) end
            if unit.SetNeverMoveToClearSpace ~= nil then unit:SetNeverMoveToClearSpace(true) end
        end)
        unit:SetThink(
				function()
					if GameRules:IsGamePaused() then return 0.03 end
					if time >= 30.0 then
						unit:RemoveSelf()
						return nil
					end
					time = time + 0.2
					return 0.2
				end, 
				"ability_collection_power_remove",
			0)
    end
end

function IsKilledByYugi04(target,damage)
    if target:HasModifier("modifier_thdots_yugi04_think_interval") and damage>=target:GetMaxHealth() then
        return true
    else 
        return false
    end
end

function IsStealableTHD(ability)
    if ability.stealable == true then return true
    else return false
    end
end

-- 表深拷贝
function DepthCloneTable(table)
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        else
            local newTable = {}
            for key, value in pairs(object) do
                newTable[_copy(key)] = _copy(value)
            end
            return newTable
        end
    end
    return _copy(table)
end
-- 伪随机
-- Rolls a Psuedo Random chance. If failed, chances increases, otherwise chances are reset
-- Numbers taken from https://gaming.stackexchange.com/a/290788
function RollPseudoRandom(base_chance, entity)
	local chances_table = {
		{1, 0.015604},
		{2, 0.062009},
		{3, 0.138618},
		{4, 0.244856},
		{5, 0.380166},
		{6, 0.544011},
		{7, 0.735871},
		{8, 0.955242},
		{9, 1.201637},
		{10, 1.474584},
		{11, 1.773627},
		{12, 2.098323},
		{13, 2.448241},
		{14, 2.822965},
		{15, 3.222091},
		{16, 3.645227},
		{17, 4.091991},
		{18, 4.562014},
		{19, 5.054934},
		{20, 5.570404},
		{21, 6.108083},
		{22, 6.667640},
		{23, 7.248754},
		{24, 7.851112},
		{25, 8.474409},
		{26, 9.118346},
		{27, 9.782638},
		{28, 10.467023},
		{29, 11.171176},
		{30, 11.894919},
		{31, 12.637932},
		{32, 13.400086},
		{33, 14.180520},
		{34, 14.981009},
		{35, 15.798310},
		{36, 16.632878},
		{37, 17.490924},
		{38, 18.362465},
		{39, 19.248596},
		{40, 20.154741},
		{41, 21.092003},
		{42, 22.036458},
		{43, 22.989868},
		{44, 23.954015},
		{45, 24.930700},
		{46, 25.987235},
		{47, 27.045294},
		{48, 28.100764},
		{49, 29.155227},
		{50, 30.210303},
		{51, 31.267664},
		{52, 32.329055},
		{53, 33.411996},
		{54, 34.736999},
		{55, 36.039785},
		{56, 37.321683},
		{57, 38.583961},
		{58, 39.827833},
		{59, 41.054464},
		{60, 42.264973},
		{61, 43.460445},
		{62, 44.641928},
		{63, 45.810444},
		{64, 46.966991},
		{65, 48.112548},
		{66, 49.248078},
		{67, 50.746269},
		{68, 52.941176},
		{69, 55.072464},
		{70, 57.142857},
		{71, 59.154930},
		{72, 61.111111},
		{73, 63.013699},
		{74, 64.864865},
		{75, 66.666667},
		{76, 68.421053},
		{77, 70.129870},
		{78, 71.794872},
		{79, 73.417722},
		{80, 75.000000},
		{81, 76.543210},
		{82, 78.048780},
		{83, 79.518072},
		{84, 80.952381},
		{85, 82.352941},
		{86, 83.720930},
		{87, 85.057471},
		{88, 86.363636},
		{89, 87.640449},
		{90, 88.888889},
		{91, 90.109890},
		{92, 91.304348},
		{93, 92.473118},
		{94, 93.617021},
		{95, 94.736842},
		{96, 95.833333},
		{97, 96.907216},
		{98, 97.959184},
		{99, 98.989899},	
		{100, 100}
	}

	entity.pseudoRandomModifier = entity.pseudoRandomModifier or 0
	local prngBase
	for i = 1, #chances_table do
		if base_chance == chances_table[i][1] then		  
			prngBase = chances_table[i][2]
		end
	end

	if not prngBase then
--		print("The chance was not found! Make sure to add it to the table or change the value.")
		return false
	end
	
	if RollPercentage( prngBase + entity.pseudoRandomModifier ) then
		entity.pseudoRandomModifier = 0
		return true
	else
		entity.pseudoRandomModifier = entity.pseudoRandomModifier + prngBase		
		return false
	end
end
