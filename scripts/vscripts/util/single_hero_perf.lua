-- 仅在单英雄性能局加载；只在外部请求时枚举，采样窗口内不运行诊断 thinker。
local Perf = {}
local config = nil
local sequence = 0

local function Token(value)
	return tostring(value):gsub("[^%w_%.%-]", "_")
end

function Perf.Configure(settings, hero, profile, radiant, dire)
	config = {run = Token(settings.run) .. "-" .. Token(Time()), hero = hero,
		profile = profile, radiant = radiant, dire = dire}
	print("[PERF][Configured] schema=1 run=" .. config.run .. " hero=" .. hero
		.. " profile=" .. profile .. " radiant_capacity=" .. radiant .. " dire_capacity=" .. dire)
end

local function Snapshot(detail)
	if config == nil then return end
	sequence = sequence + 1
	local started = Time()
	local errors, bots, mismatch, alive = 0, 0, 0, 0
	local counts = {[DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0}
	local levels = {damage = 1, damage_spell = 2, frontline = 2, support = 3}
	local function Read(fn, fallback)
		local ok, value = pcall(fn)
		if not ok or value == nil then errors = errors + 1; return fallback end
		return value
	end
	print(string.format("[PERF][Begin] schema=1 run=%s seq=%d hero=%s profile=%s time=%.3f phase=%d detail=%s difficulty=%s",
		config.run, sequence, config.hero, config.profile, GameRules:GetDOTATime(false, false),
		GameRules:State_Get(), tostring(detail), Token(cur_bot_dif)))
	for player = 0, 63 do
		if PlayerResource:IsValidTeamPlayerID(player) then
			local team = PlayerResource:GetTeam(player)
			if counts[team] ~= nil then
				counts[team] = counts[team] + 1
				local isBot = PlayerResource:IsFakeClient(player)
				local selected = PlayerResource:GetSelectedHeroName(player)
				local hero = PlayerResource:GetSelectedHeroEntity(player)
				local name, level, living, markerLevel, ent = "none", -1, false, -1, -1
				if hero ~= nil and not hero:IsNull() then
					name = hero:GetUnitName()
					level, living, ent = hero:GetLevel(), hero:IsAlive(), hero:entindex()
					local marker = hero:FindAbilityByName("ability_thd2_bot_profile")
					if marker ~= nil then markerLevel = marker:GetLevel() end
				end
				if isBot then
					bots = bots + 1
					if living then alive = alive + 1 end
					if selected ~= config.hero or name ~= config.hero or markerLevel ~= levels[config.profile] then
						mismatch = mismatch + 1
					end
				end
				print(string.format("[PERF][Roster] seq=%d player=%d team=%d bot=%s selected=%s hero=%s ent=%d level=%d alive=%s profile_level=%d",
					sequence, player, team, tostring(isBot), Token(selected), name, ent, level, tostring(living), markerLevel))
			end
		end
	end
	local units, modifiers, illusions, thinkers = 0, 0, 0, 0
	if detail then
		local byName, byModifier = {}, {}
		local entities = Read(function() return Entities:FindAllByClassname("npc_dota_*") end, {})
		for _, unit in ipairs(entities) do
			if unit ~= nil and not unit:IsNull() then
				local class = unit:GetClassname()
				if class == "npc_dota_thinker" then thinkers = thinkers + 1 end
				if unit.GetUnitName ~= nil and unit.FindAllModifiers ~= nil then
					units = units + 1
					local name = Read(function() return unit:GetUnitName() end, "unknown")
					byName[name] = (byName[name] or 0) + 1
					if Read(function() return unit:IsIllusion() end, false) then illusions = illusions + 1 end
					for _, modifier in ipairs(Read(function() return unit:FindAllModifiers() end, {})) do
						local name = Read(function() return modifier:GetName() end, "unknown")
						modifiers = modifiers + 1
						byModifier[name] = (byModifier[name] or 0) + 1
					end
				end
			end
		end
		-- 只记录实例分布，不主动执行 DeclareFunctions/GetPriority 等英雄回调。
		for name, count in pairs(byName) do
			print(string.format("[PERF][Unit] seq=%d name=%s count=%d", sequence, Token(name), count))
		end
		for name, count in pairs(byModifier) do
			print(string.format("[PERF][Modifier] seq=%d name=%s count=%d", sequence, Token(name), count))
		end
	end
	local valid = bots > 0 and mismatch == 0 and errors == 0
		and counts[DOTA_TEAM_GOODGUYS] == config.radiant and counts[DOTA_TEAM_BADGUYS] == config.dire
	print(string.format("[PERF][End] run=%s seq=%d time=%.3f valid=%s bots=%d alive=%d mismatch=%d radiant=%d dire=%d radiant_capacity=%d dire_capacity=%d units=%s modifiers=%s illusions=%s thinkers=%s errors=%d scan_ms=%.3f",
		config.run, sequence, GameRules:GetDOTATime(false, false), tostring(valid), bots, alive, mismatch,
		counts[DOTA_TEAM_GOODGUYS], counts[DOTA_TEAM_BADGUYS], config.radiant, config.dire,
		detail and tostring(units) or "unknown", detail and tostring(modifiers) or "unknown",
		detail and tostring(illusions) or "unknown", detail and tostring(thinkers) or "unknown", errors, (Time() - started) * 1000))
end

Convars:RegisterCommand("thd_single_hero_snapshot", function(_, detail)
	local ok, err = pcall(Snapshot, detail == "1")
	if not ok then print("[PERF][Error] " .. Token(err)) end
end, "Single hero roster (0) or unit/modifier snapshot (1); read only.", 0)

return Perf
