-- 按需读取移动事件相关实例；不修改 Modifier、属性、优先级或事件订阅。
THDMovementSnapshot = THDMovementSnapshot or {}

local function ReadValue(fallback, fn)
    local ok, value = pcall(fn)
    if ok and value ~= nil then return value end
    return fallback
end

local function Token(value)
    return tostring(value):gsub("%s", "_")
end

function THDMovementSnapshot:Print()
    if not IsServer() then return end
    local gameTime = GameRules:GetDOTATime(false, false)
    local scan = string.format("%.3f", GameRules:GetGameTime())
    local units = Entities:FindAllByClassname("npc_dota_*") or {}
    print(string.format("[MOVE][Begin] schema=1 scan=%s dota_time=%.3f game_time=%.3f enum=%s entity_candidates=%d candidate=%s",
        scan, gameTime, GameRules:GetGameTime(), tostring(MODIFIER_EVENT_ON_UNIT_MOVED), #units,
        Token(GameRules.THDMovementSubscriptionRun or "baseline")))
    print(string.format("[MOVE][Difficulty] scan=%s self_stun_removed=%s",
        scan, tostring(GameRules.THDBotSelfStunRemoved == true)))
    local byName = {}
    local unitCount, modifierCount, declaredCount, methodCount, declarationErrors = 0, 0, 0, 0, 0
    for _, unit in ipairs(units) do
        if unit ~= nil and not unit:IsNull() and unit.FindAllModifiers ~= nil then
            local modifiers = ReadValue({}, function() return unit:FindAllModifiers() end)
            local names, declaresMove, moveMethods = {}, {}, {}
            for _, modifier in ipairs(modifiers) do
                if modifier ~= nil and not modifier:IsNull() then
                    local name = ReadValue("unknown", function() return modifier:GetName() end)
                    names[#names + 1] = name
                    modifierCount = modifierCount + 1
                    byName[name] = (byName[name] or 0) + 1
                    local moveMethod = ReadValue(nil, function() return modifier.OnUnitMoved end)
                    local declareMethod = ReadValue(nil, function() return modifier.DeclareFunctions end)
                    do
                        if type(moveMethod) == "function" then
                            moveMethods[#moveMethods + 1] = name
                            methodCount = methodCount + 1
                        end
                        -- 读取当前 Lua 声明，不将其冒充为引擎已注册事件表。
                        if type(declareMethod) == "function" then
                            local ok, declared = pcall(declareMethod, modifier)
                            if ok and type(declared) == "table" then
                                for _, event in pairs(declared) do
                                    if event == MODIFIER_EVENT_ON_UNIT_MOVED then
                                        declaresMove[#declaresMove + 1] = name
                                        declaredCount = declaredCount + 1
                                        break
                                    end
                                end
                            elseif not ok then
                                declarationErrors = declarationErrors + 1
                            end
                        end
                    end
                end
            end
            table.sort(names)
            table.sort(declaresMove)
            table.sort(moveMethods)
            unitCount = unitCount + 1
            print(string.format("[MOVE][Unit] scan=%s ent=%s name=%s class=%s team=%s player=%s alive=%s hero=%s illusion=%s owner=%s modifiers=%d declared_move=%s move_method=%s names=%s",
                scan,
                Token(ReadValue(-1, function() return unit:entindex() end)),
                Token(ReadValue("unknown", function() return unit:GetUnitName() end)),
                Token(ReadValue("unknown", function() return unit:GetClassname() end)),
                Token(ReadValue(-1, function() return unit:GetTeamNumber() end)),
                Token(ReadValue(-1, function() return unit:GetPlayerOwnerID() end)),
                Token(ReadValue(false, function() return unit:IsAlive() end)),
                Token(ReadValue(false, function() return unit:IsRealHero() end)),
                Token(ReadValue(false, function() return unit:IsIllusion() end)),
                Token(ReadValue(-1, function() local owner = unit:GetOwner(); return owner and owner:entindex() or -1 end)),
                #names, #declaresMove > 0 and table.concat(declaresMove, ",") or "none",
                #moveMethods > 0 and table.concat(moveMethods, ",") or "none",
                #names > 0 and table.concat(names, ",") or "none"))
        end
    end
    local sorted = {}
    for name, count in pairs(byName) do sorted[#sorted + 1] = {name = name, count = count} end
    table.sort(sorted, function(a, b) if a.count == b.count then return a.name < b.name end return a.count > b.count end)
    for _, entry in ipairs(sorted) do
        print(string.format("[MOVE][Modifier] scan=%s name=%s count=%d", scan, entry.name, entry.count))
    end
    print(string.format("[MOVE][End] scan=%s units=%d modifiers=%d lua_declared_move=%d lua_move_method=%d declaration_errors=%d dota_time=%.3f",
        scan, unitCount, modifierCount, declaredCount, methodCount, declarationErrors, GameRules:GetDOTATime(false, false)))
end

if not THDMovementSnapshot.registered then
    Convars:RegisterCommand("thd_move_snapshot", function()
        local ok, err = pcall(function() THDMovementSnapshot:Print() end)
        if not ok then print("[MOVE][Error] " .. tostring(err)) end
    end, "Read current units, modifier lists and Lua movement declarations.", 0)
    THDMovementSnapshot.registered = true
end
print("[MOVE][Loaded] schema=1 command=thd_move_snapshot")
