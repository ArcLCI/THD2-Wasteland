-- 本轮已授权启用；仅诊断通用眩晕，不向 Bot 回传游戏侧信息。
local Trace = { ENABLED = true }
local second, count, dropped = -1, 0, 0

local function Remaining(target)
    local remaining = 0
    for _, modifier in pairs(target:FindAllModifiersByName('modifier_stunned')) do
        remaining = math.max(remaining, modifier:GetRemainingTime())
    end
    return remaining
end

function Trace.Before(caster, target)
    if not Trace.ENABLED or caster == nil or target == nil or caster == target
        or not target:IsRealHero() then return nil end
    local now = GameRules:GetDOTATime(false, false)
    if math.floor(now) ~= second then second, count = math.floor(now), 0 end
    if count >= 20 then dropped = dropped + 1; return nil end
    count = count + 1
    return { time = now, remaining = Remaining(target), stunned = target:IsStunned() }
end

function Trace.After(before, caster, target, modifier, duration, ability, sourceKind)
    if before == nil then return end
    local name = 'unknown'
    if ability ~= nil then
        local ok, value = pcall(function() return ability:GetAbilityName() end)
        if ok and type(value) == 'string' then name = value end
    end
    local valid = modifier ~= nil and not modifier:IsNull()
    print(string.format('[GAME][ControlEffect] revision=CONTROL-TRACE-R3 event=stun_apply_result clock=dota time=%.3f caster_pid=%s target_pid=%s caster_unit=%s target_unit=%s ability=%s source_kind=%s coverage=modifier_stunned_only self_cast=false before_remaining=%.3f before_stunned=%s requested_duration=%.3f modifier_returned=%s after_remaining=%.3f after_stunned=%s dropped=%d',
        before.time, tostring(caster:GetPlayerOwnerID()), tostring(target:GetPlayerOwnerID()), caster:GetUnitName(), target:GetUnitName(), name, sourceKind or 'unspecified',
        before.remaining, tostring(before.stunned), duration, tostring(valid), Remaining(target),
        tostring(target:IsStunned()), dropped))
    dropped = 0
end

if Trace.ENABLED then
    print('[GAME][ControlTraceReady] revision=CONTROL-TRACE-R3 scope=all_casters_to_real_heroes coverage=modifier_stunned_only effect_limit=20')
end
return Trace
