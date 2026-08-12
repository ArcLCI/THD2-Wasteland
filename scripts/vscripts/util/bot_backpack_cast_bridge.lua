-- Experimental bridge for replaying a Bot consumable order after promoting the
-- item from the backpack.  This module is deliberately disabled by default.

local BotBackpackCastBridge = {}

local enabled = false
local activeOperations = {}
local lastLogTimes = {}

local BACKPACK_FIRST_SLOT = 6
local BACKPACK_LAST_SLOT = 8
local MAIN_FIRST_SLOT = 0
local MAIN_LAST_SLOT = 5
local BACKPACK_LOCK_MAX = 6.5
local RESULT_TIMEOUT = 0.8
local RESULT_POLL_INTERVAL = 0.03
local RESTORE_TIMEOUT = 1.5
local RESTORE_POLL_INTERVAL = 0.05

local registry = {
	item_clarity = "unit_target",
	item_flask = "unit_target",
	item_smoke_of_deceit = "no_target",
	item_dust = "no_target",
	item_ward_observer = "location",
	item_ward_sentry = "location",
	item_ward_dispenser = "location",
	item_cheese = "no_target",
	item_jinkela = "no_target",
	item_magic_mushroom = "no_target",
	item_card_bad_man = "no_target",
	item_card_eat_man = "unit_target",
	item_card_good_man = "unit_target",
	item_card_kid_man = "no_target",
	item_card_love_man = "unit_target",
	item_card_moon_man = "no_target",
	item_card_super_man = "no_target",
	item_card_worse_man = "unit_target",
}

local protectedItems = {
	item_aegis = true,
	item_gem = true,
	item_kusanagi = true,
	item_tpscroll = true,
}

for itemName, _ in pairs(registry) do
	protectedItems[itemName] = true
end

local function IsValidHandle(handle)
	return handle ~= nil and (handle.IsNull == nil or not handle:IsNull())
end

local function GetTime()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	if Time ~= nil then
		return Time()
	end
	return os.clock()
end

local function GetEntityIndex(entity)
	if not IsValidHandle(entity) or entity.entindex == nil then return -1 end
	return entity:entindex()
end

local function Log(unit, itemName, reason)
	local unitIndex = GetEntityIndex(unit)
	local key = tostring(unitIndex) .. ":" .. tostring(itemName) .. ":" .. tostring(reason)
	local now = GetTime()
	if lastLogTimes[key] ~= nil and now - lastLogTimes[key] < 1 then return end
	lastLogTimes[key] = now
	print(string.format(
		"[THD][BotBackpackBridge] unit=%s item=%s reason=%s",
		tostring(unitIndex),
		tostring(itemName or "unknown"),
		tostring(reason)
	))
end

local function GetItemName(item)
	if not IsValidHandle(item) or item.GetAbilityName == nil then return nil end
	return item:GetAbilityName()
end

local function FindItemSlot(unit, item, firstSlot, lastSlot)
	if not IsValidHandle(unit) or not IsValidHandle(item) then return nil end
	for slot = firstSlot, lastSlot do
		if unit:GetItemInSlot(slot) == item then
			return slot
		end
	end
	return nil
end

local function IsProtectedItem(item)
	local itemName = GetItemName(item)
	if itemName == nil then return true end
	if protectedItems[itemName] then return true end
	local taskProtected = _G.THD2_BOT_BACKPACK_PROTECTED_ITEMS
	return taskProtected ~= nil and taskProtected[itemName] == true
end

local function SelectMainSlot(unit)
	for slot = MAIN_FIRST_SLOT, MAIN_LAST_SLOT do
		if unit:GetItemInSlot(slot) == nil then
			return slot
		end
	end

	local selectedSlot = nil
	local selectedCost = nil
	for slot = MAIN_FIRST_SLOT, MAIN_LAST_SLOT do
		local item = unit:GetItemInSlot(slot)
		if IsValidHandle(item) and not IsProtectedItem(item) then
			local cost = item.GetCost ~= nil and item:GetCost() or 0
			cost = tonumber(cost) or 0
			if selectedSlot == nil or cost < selectedCost then
				selectedSlot = slot
				selectedCost = cost
			end
		end
	end
	return selectedSlot
end

local function IsBotPlayer(playerID)
	if playerID == nil or playerID < 0 or PlayerResource == nil then return false end
	if PlayerResource.IsValidPlayerID ~= nil and not PlayerResource:IsValidPlayerID(playerID) then
		return false
	end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then
		return true
	end
	return PlayerIsBot ~= nil and PlayerIsBot(playerID) == true
end

local function IsRealBotHero(unit)
	if not IsValidHandle(unit) or unit.IsRealHero == nil or not unit:IsRealHero() then return false end
	if unit.IsIllusion ~= nil and unit:IsIllusion() then return false end
	if unit.GetPlayerOwnerID == nil then return false end
	return IsBotPlayer(unit:GetPlayerOwnerID())
end

local function GetOrderMode(orderType)
	if orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET then return "no_target" end
	if orderType == DOTA_UNIT_ORDER_CAST_TARGET then return "unit_target" end
	if orderType == DOTA_UNIT_ORDER_CAST_POSITION then return "location" end
	return nil
end

local function ResolveOrderUnit(keys)
	if keys == nil or keys.units == nil then return nil end
	local unitIndex = keys.units["0"] or keys.units[0]
	if unitIndex == nil or EntIndexToHScript == nil then return nil end
	return EntIndexToHScript(unitIndex)
end

local function ResolveOrderAbility(keys)
	if keys == nil or keys.entindex_ability == nil or keys.entindex_ability == 0 then return nil end
	if EntIndexToHScript == nil then return nil end
	return EntIndexToHScript(keys.entindex_ability)
end

local function IsValidOrderPayload(keys, mode)
	if mode == "unit_target" then
		if keys.entindex_target == nil or keys.entindex_target == 0 then return false end
		return EntIndexToHScript ~= nil and IsValidHandle(EntIndexToHScript(keys.entindex_target))
	end
	if mode == "location" then
		return tonumber(keys.position_x) ~= nil
			and tonumber(keys.position_y) ~= nil
			and tonumber(keys.position_z) ~= nil
	end
	return mode == "no_target"
end

local function GetCooldown(item)
	if not IsValidHandle(item) or item.GetCooldownTimeRemaining == nil then return 0 end
	return tonumber(item:GetCooldownTimeRemaining()) or 0
end

local function GetCharges(item)
	if not IsValidHandle(item) or item.GetCurrentCharges == nil then return nil end
	return tonumber(item:GetCurrentCharges())
end

local function RestoreInventory(operation)
	local unit = operation.unit
	if not IsValidHandle(unit) then return false end

	local displacedItem = operation.displacedItem
	local displacedSlot = FindItemSlot(unit, displacedItem, MAIN_FIRST_SLOT, BACKPACK_LAST_SLOT)
	local bridgeItemSlot = FindItemSlot(unit, operation.item, MAIN_FIRST_SLOT, BACKPACK_LAST_SLOT)

	if IsValidHandle(displacedItem) then
		if displacedSlot ~= operation.backpackSlot then
			Log(unit, operation.itemName, "restore_displaced_item_moved")
			return false
		end
		local mainItem = unit:GetItemInSlot(operation.mainSlot)
		if mainItem ~= nil and mainItem ~= operation.item then
			Log(unit, operation.itemName, "restore_main_slot_occupied")
			return false
		end
		unit:SwapItems(operation.backpackSlot, operation.mainSlot)
		return unit:GetItemInSlot(operation.mainSlot) == displacedItem
	end

	-- 主槽原本为空时，未消耗完的堆叠物品仍需返回原副包槽。
	if bridgeItemSlot == operation.mainSlot and unit:GetItemInSlot(operation.backpackSlot) == nil then
		unit:SwapItems(operation.mainSlot, operation.backpackSlot)
		return unit:GetItemInSlot(operation.backpackSlot) == operation.item
	end
	return bridgeItemSlot == nil or bridgeItemSlot == operation.backpackSlot
end

local function CompleteOperation(operation, restoreState)
	local unitIndex = operation.unitIndex
	if activeOperations[unitIndex] ~= operation then return nil end
	operation.finished = true
	operation.allowRecursive = false
	activeOperations[unitIndex] = nil
	Log(operation.unit, operation.itemName,
		(operation.finishSucceeded and "success_" or "failure_") .. tostring(operation.finishReason)
			.. "_" .. tostring(restoreState))
	return nil
end

local function FinishOperation(operation, succeeded, reason)
	local unitIndex = operation.unitIndex
	if activeOperations[unitIndex] ~= operation then return nil end
	operation.allowRecursive = false
	operation.finishSucceeded = succeeded == true
	operation.finishReason = reason
	if RestoreInventory(operation) then return CompleteOperation(operation, "restored") end
	operation.phase = "restore"
	operation.restoreDeadline = operation.restoreDeadline or (GetTime() + RESTORE_TIMEOUT)
	Log(operation.unit, operation.itemName,
		(operation.finishSucceeded and "success_" or "failure_") .. tostring(reason) .. "_restore_deferred")
	return RESTORE_POLL_INTERVAL
end

local function HasNativeCastSucceeded(operation)
	if not IsValidHandle(operation.item) then return true end
	local charges = GetCharges(operation.item)
	if operation.charges ~= nil and charges ~= nil and charges < operation.charges then return true end
	return GetCooldown(operation.item) > 0
end

local function BuildNativeOrder(operation)
	local keys = operation.keys
	local order = {
		UnitIndex = operation.unitIndex,
		OrderType = keys.order_type,
		AbilityIndex = GetEntityIndex(operation.item),
		Queue = false,
	}
	if operation.mode == "unit_target" then
		order.TargetIndex = keys.entindex_target
	elseif operation.mode == "location" then
		if Vector ~= nil then
			order.Position = Vector(keys.position_x, keys.position_y, keys.position_z)
		else
			order.Position = {x = keys.position_x, y = keys.position_y, z = keys.position_z}
		end
	end
	return order
end

local function StepOperation(operation)
	if activeOperations[operation.unitIndex] ~= operation or operation.finished then return nil end
	if operation.phase == "restore" then
		if not IsValidHandle(operation.unit) then return CompleteOperation(operation, "restore_unit_lost") end
		if RestoreInventory(operation) then return CompleteOperation(operation, "restored_after_retry") end
		if GetTime() >= (operation.restoreDeadline or GetTime()) then
			return CompleteOperation(operation, "restore_timeout")
		end
		return RESTORE_POLL_INTERVAL
	end
	if not enabled then
		return FinishOperation(operation, false, "disabled")
	end
	if not IsValidHandle(operation.unit) then
		return FinishOperation(operation, false, "unit_lost")
	end

	if operation.phase == "reissue" then
		if not IsValidHandle(operation.item) then
			return FinishOperation(operation, false, "item_lost_before_cast")
		end
		if FindItemSlot(operation.unit, operation.item, MAIN_FIRST_SLOT, MAIN_LAST_SLOT) ~= operation.mainSlot then
			return FinishOperation(operation, false, "item_not_in_main_slot")
		end
		if ExecuteOrderFromTable == nil then
			return FinishOperation(operation, false, "execute_order_unavailable")
		end

		operation.allowRecursive = true
		local ok = pcall(ExecuteOrderFromTable, BuildNativeOrder(operation))
		operation.allowRecursive = false
		if not ok then
			return FinishOperation(operation, false, "execute_order_error")
		end
		operation.phase = "await_result"
		operation.resultDeadline = GetTime() + RESULT_TIMEOUT
		return RESULT_POLL_INTERVAL
	end

	-- 消耗完毕的物品句柄会先失效，这本身就是原生施法成功证据。
	if HasNativeCastSucceeded(operation) then
		return FinishOperation(operation, true, "native_cast_confirmed")
	end
	if GetTime() >= operation.resultDeadline then
		return FinishOperation(operation, false, "native_cast_unconfirmed")
	end
	return RESULT_POLL_INTERVAL
end

local function ScheduleOperation(operation)
	if operation.unit.SetContextThink == nil then return false end
	local contextName = "thd_bot_backpack_bridge_" .. tostring(operation.unitIndex)
	operation.unit:SetContextThink(contextName, function()
		return StepOperation(operation)
	end, 0)
	return true
end

local function IsRecursiveOrderMatch(operation, item, keys)
	if operation == nil or operation.allowRecursive ~= true
		or operation.item ~= item or operation.keys.order_type ~= keys.order_type
	then
		return false
	end
	if operation.mode == "unit_target" then
		return operation.keys.entindex_target == keys.entindex_target
	end
	if operation.mode == "location" then
		return operation.keys.position_x == keys.position_x
			and operation.keys.position_y == keys.position_y
			and operation.keys.position_z == keys.position_z
	end
	return operation.mode == "no_target"
end

function BotBackpackCastBridge.FilterOrder(keys)
	if not enabled then return nil end

	local orderMode = keys ~= nil and GetOrderMode(keys.order_type) or nil
	if orderMode == nil then return nil end

	local unit = ResolveOrderUnit(keys)
	local item = ResolveOrderAbility(keys)
	if not IsValidHandle(unit) or not IsValidHandle(item) then return nil end

	local unitIndex = GetEntityIndex(unit)
	local operation = activeOperations[unitIndex]
	if IsRecursiveOrderMatch(operation, item, keys) then
		operation.allowRecursive = false
		return true
	end

	if not IsRealBotHero(unit) then return nil end
	if item.IsItem == nil or not item:IsItem() then return nil end

	local itemName = GetItemName(item)
	local registeredMode = registry[itemName]
	local backpackSlot = FindItemSlot(unit, item, BACKPACK_FIRST_SLOT, BACKPACK_LAST_SLOT)
	if registeredMode == nil or backpackSlot == nil then return nil end

	if operation ~= nil then
		Log(unit, itemName, "operation_already_active")
		return false
	end
	if registeredMode ~= orderMode or not IsValidOrderPayload(keys, orderMode) then
		Log(unit, itemName, "invalid_cast_type_or_payload")
		return false
	end

	local cooldownBefore = GetCooldown(item)
	if cooldownBefore > 0 then
		Log(unit, itemName, "item_already_on_cooldown")
		return false
	end

	local mainSlot = SelectMainSlot(unit)
	if mainSlot == nil then
		Log(unit, itemName, "no_safe_main_slot")
		return false
	end

	local displacedItem = unit:GetItemInSlot(mainSlot)
	local newOperation = {
		unit = unit,
		unitIndex = unitIndex,
		item = item,
		itemName = itemName,
		mode = orderMode,
		keys = {
			order_type = keys.order_type,
			entindex_target = keys.entindex_target,
			position_x = keys.position_x,
			position_y = keys.position_y,
			position_z = keys.position_z,
		},
		backpackSlot = backpackSlot,
		mainSlot = mainSlot,
		displacedItem = displacedItem,
		cooldownBefore = cooldownBefore,
		charges = GetCharges(item),
		phase = "reissue",
	}

	-- 先同步完成换位并拦截原订单，下一帧只重发引擎原生物品订单。
	unit:SwapItems(backpackSlot, mainSlot)
	if unit:GetItemInSlot(mainSlot) ~= item then
		Log(unit, itemName, "swap_to_main_failed")
		return false
	end

	local cooldownAfter = GetCooldown(item)
	newOperation.cooldownAfterSwap = cooldownAfter
	if cooldownAfter > BACKPACK_LOCK_MAX then
		RestoreInventory(newOperation)
		Log(unit, itemName, "unexpected_cooldown_after_swap")
		return false
	end
	if cooldownAfter > 0 then
		if item.EndCooldown == nil then
			RestoreInventory(newOperation)
			Log(unit, itemName, "cannot_clear_backpack_lock")
			return false
		end
		item:EndCooldown()
	end

	activeOperations[unitIndex] = newOperation
	if not ScheduleOperation(newOperation) then
		FinishOperation(newOperation, false, "scheduler_unavailable")
	end
	return false
end

function BotBackpackCastBridge.SetEnabled(value)
	enabled = value == true
	if not enabled then
		local pending = {}
		for _, operation in pairs(activeOperations) do
			table.insert(pending, operation)
		end
		for _, operation in pairs(pending) do
			FinishOperation(operation, false, "disabled")
		end
	end
	print("[THD][BotBackpackBridge] enabled=" .. tostring(enabled))
	return enabled
end

function BotBackpackCastBridge.IsEnabled()
	return enabled
end

function BotBackpackCastBridge.GetRegistry()
	return registry
end

_G.THD2_BotBackpackCastBridge = BotBackpackCastBridge

return BotBackpackCastBridge
