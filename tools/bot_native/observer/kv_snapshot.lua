-- 手动调用的游戏侧只读快照。不得从addon启动入口自动require，也不注册Think。
local O = {}
local RUN = "THD-BOT-KV-OBSERVE-20261010-R1"
local sequence = 0
local bits = {
    DOTA_BOT_TANK = 1, DOTA_BOT_STUN_SUPPORT = 2, DOTA_BOT_PURE_SUPPORT = 4,
    DOTA_BOT_PUSH_SUPPORT = 8, DOTA_BOT_HARD_CARRY = 16,
    DOTA_BOT_SEMI_CARRY = 32, DOTA_BOT_GANKER = 64,
}
local function Escape(s)
    return '"' .. tostring(s):gsub('[%z\1-\31\\"]', function(c)
        if c == '"' or c == '\\' then return '\\' .. c end
        return string.format('\\u%04x', string.byte(c))
    end) .. '"'
end
local function Json(value)
    if value == nil then return 'null' end
    if type(value) == 'boolean' then return value and 'true' or 'false' end
    if type(value) == 'number' then
        if value ~= value or value == math.huge or value == -math.huge then return 'null' end
        return string.format('%.9g', value)
    end
    if type(value) == 'string' then return Escape(value) end
    local keys, fields = {}, {}
    for k, _ in pairs(value) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do fields[#fields + 1] = Escape(k) .. ':' .. Json(value[k]) end
    return '{' .. table.concat(fields, ',') .. '}'
end
local function Safe(fn)
    local ok, value = pcall(fn)
    if ok then return value end
    return nil
end
local function Emit(record)
    sequence = sequence + 1
    record.run = RUN
    record.sequence = sequence
    record.map_name = Safe(function() return GetMapName() end)
    record.game_time = Safe(function() return GameRules:GetGameTime() end)
    record.dota_time = Safe(function() return GameRules:GetDOTATime(false, false) end)
    print('[THDNativeKV] ' .. Json(record))
end
local function Summary(kv)
    local bot = type(kv) == 'table' and kv.Bot or nil
    local present = type(bot) == 'table'
    local result = {kv_available = type(kv) == 'table', bot_present = present}
    if not present then return result end
    result.aggression_raw = bot.AggressionFactor ~= nil and tostring(bot.AggressionFactor) or nil
    result.aggression_declared = tonumber(bot.AggressionFactor)
    result.hero_type = bot.HeroType ~= nil and tostring(bot.HeroType) or nil
    local mask, seen = 0, {}
    for tag in string.gmatch(result.hero_type or '', 'DOTA_BOT_[A-Z_]+') do
        if not seen[tag] then
            seen[tag] = true
            if bits[tag] then mask = mask + bits[tag] else result.unrecognized_tag = true end
        end
    end
    result.recognized_mask = mask
    result.build_present = type(bot.Build) == 'table'
    result.loadout_present = type(bot.Loadout) == 'table'
    result.laning_info_present = type(bot.LaningInfo) == 'table'
    -- 这是KV声明读数，绝不在Lua中把缺省值当成实际Bot字段读数。
    return result
end

function O.Dump(label)
    if not IsServer() then return end
    label = tostring(label or 'manual'):sub(1, 64)
    local snapshot = tostring(Safe(function() return GameRules:GetGameTime() end)) .. ':' .. tostring(sequence + 1)
    local source = Safe(function() return LoadKeyValues('scripts/npc/bot_heroes_custom.txt') end)
    if type(source) == 'table' and type(source.DOTAHeroes) == 'table' then source = source.DOTAHeroes end
    Emit({event = 'kv_begin', snapshot = snapshot, label = label,
        engine_query_available = type(GetUnitKeyValuesByName) == 'function', source_available = type(source) == 'table'})
    local names, included = {}, {}
    local function Add(name)
        if type(name) == 'string' and name ~= '' and not included[name] then
            included[name] = true; names[#names + 1] = name
        end
    end
    if type(source) == 'table' then
        for name, data in pairs(source) do if type(data) == 'table' and name:find('npc_dota_hero_', 1, true) == 1 then Add(name) end end
    end
    -- 在加载源配置缺失时仍可检查实际存在的英雄，不将缺失解释为零。
    local heroes = Safe(function() return HeroList:GetAllHeroes() end) or {}
    local heroCount = 0
    for _, hero in ipairs(heroes) do
        if Safe(function() return hero ~= nil and not hero:IsNull() and hero:IsRealHero() and not hero:IsIllusion() end) then
            local name = Safe(function() return hero:GetUnitName() end)
            local class = Safe(function() return hero:GetClassname() end)
            local player = Safe(function() return hero:GetPlayerOwnerID() end)
            local selected = player ~= nil and player >= 0 and Safe(function() return PlayerResource:GetSelectedHeroEntity(player) == hero end)
            if selected then
                local marker = Safe(function() return hero:FindAbilityByName('ability_thd2_bot_profile') end)
                Emit({event = 'hero_identity', snapshot = snapshot, label = label,
                    unit_kv_name = name, classname = class,
                    entity_index = Safe(function() return hero:entindex() end), player_id = player,
                    team = Safe(function() return hero:GetTeamNumber() end),
                    is_bot = Safe(function() return PlayerResource:IsFakeClient(player) end),
                    profile_marker_level = marker and Safe(function() return marker:GetLevel() end) or nil,
                    alive = Safe(function() return hero:IsAlive() end)})
                Add(name); Add(class); heroCount = heroCount + 1
            end
        end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local ok, loaded = pcall(function() return GetUnitKeyValuesByName(name) end)
        Emit({event = 'kv_record', snapshot = snapshot, label = label, slot = name,
            addon_source = Summary(type(source) == 'table' and source[name] or nil),
            engine_unit_kv = Summary(ok and loaded or nil),
            engine_query_status = not ok and 'error' or type(loaded) == 'table' and 'table' or 'no_table',
            engine_query_error = not ok and tostring(loaded):sub(1, 192) or nil})
    end
    Emit({event = 'kv_end', snapshot = snapshot, label = label, hero_count = heroCount, slot_count = #names})
end

return O
