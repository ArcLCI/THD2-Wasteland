-- 原生前摇保护只限制主动替换订单，不授予眩晕免疫，也不延长施法阶段。
local CastPhaseOrders = {}
local protectedAbilities = {
    ability_thdots_nitori02 = true,
    ability_thdots_shou04 = true,
    ability_thdots_yumemi04 = true,
}

local replacementOrders = {}
for _, name in ipairs({
    'DOTA_UNIT_ORDER_MOVE_TO_POSITION', 'DOTA_UNIT_ORDER_MOVE_TO_TARGET',
    'DOTA_UNIT_ORDER_ATTACK_MOVE', 'DOTA_UNIT_ORDER_ATTACK_TARGET',
    'DOTA_UNIT_ORDER_CAST_POSITION', 'DOTA_UNIT_ORDER_CAST_TARGET',
    'DOTA_UNIT_ORDER_CAST_TARGET_TREE', 'DOTA_UNIT_ORDER_CAST_NO_TARGET',
    'DOTA_UNIT_ORDER_CAST_TOGGLE', 'DOTA_UNIT_ORDER_STOP', 'DOTA_UNIT_ORDER_HOLD_POSITION',
    'DOTA_UNIT_ORDER_PATROL', 'DOTA_UNIT_ORDER_PICKUP_ITEM', 'DOTA_UNIT_ORDER_PICKUP_RUNE',
    'DOTA_UNIT_ORDER_DROP_ITEM', 'DOTA_UNIT_ORDER_GIVE_ITEM',
    'DOTA_UNIT_ORDER_MOVE_TO_DIRECTION', 'DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION',
}) do
    local value = _G[name]
    if value ~= nil then replacementOrders[value] = true end
end

function CastPhaseOrders.Filter(keys)
    if not replacementOrders[keys.order_type] or keys.units == nil then return true end
    local kept, removed = {}, false
    for _, index in pairs(keys.units) do
        local unit = EntIndexToHScript(index)
        local ability = unit ~= nil and not unit:IsNull() and unit:IsAlive()
            and unit:GetCurrentActiveAbility() or nil
        if ability ~= nil and not ability:IsNull()
            and protectedAbilities[ability:GetAbilityName()] and ability:IsInAbilityPhase() then
            removed = true
        else
            kept[#kept + 1] = index
        end
    end
    if not removed then return true end
    if #kept == 0 then return false end
    -- 多选订单仅剔除正在保护的单位，其他单位仍交给已有过滤链。
    keys.units = {}
    for i, index in ipairs(kept) do keys.units[tostring(i - 1)] = index end
    return true
end

return CastPhaseOrders
