local BOT_COURIER_OWNER_RETRY_INTERVAL = 0.1
local BOT_COURIER_OWNER_RETRY_COUNT = 100
local BOT_COURIER_SHIELD_CONTEXT = "thd2_bot_courier_shield"

THD_BOT_COURIER_SHIELD_ENABLED = false

local function BotCourier_IsValidCourier(unit)
	return unit ~= nil and unit.IsNull ~= nil and not unit:IsNull()
		and unit.IsCourier ~= nil and unit:IsCourier()
end

function THD_GetBotCourierShieldEnabled()
	return THD_BOT_COURIER_SHIELD_ENABLED == true
end

local function BotCourier_IsBotPlayerID(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then return false end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then return true end
	if PlayerIsBot ~= nil and PlayerIsBot(playerID) then return true end

	local player = PlayerResource:GetPlayer(playerID)
	if player ~= nil and player:GetContext("PlayerIsBot") == 1 then return true end
	return PlayerResource:GetSteamID(playerID) == PlayerResource:GetSteamID(100)
end

local function BotCourier_GetOwnerPlayerID(courier)
	local playerID = courier:GetPlayerOwnerID()
	if playerID ~= nil and playerID >= 0 then
		return playerID
	end

	if courier.GetMainControllingPlayer ~= nil then
		playerID = courier:GetMainControllingPlayer()
		if playerID ~= nil and playerID >= 0 then
			return playerID
		end
	end

	-- 部分信使生成时尚未直接绑定 owner，通过玩家首选信使反查实际控制者。
	for id = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(id) and PlayerResource:GetPreferredCourierForPlayer(id) == courier then
			return id
		end
	end
	return -1
end

function THD2_ApplyBotCourierShield(unit)
	if not THD_GetBotCourierShieldEnabled() then return true end
	if not BotCourier_IsValidCourier(unit) then return true end

	local playerID = BotCourier_GetOwnerPlayerID(unit)
	if playerID < 0 then return false end
	if not BotCourier_IsBotPlayerID(playerID) then return true end

	unit:SetContextNum(BOT_COURIER_SHIELD_CONTEXT, 1, 0)
	if not unit:HasModifier("modifier_invulnerable") then
		-- 使用引擎内建无敌 modifier，避免自定义 Lua modifier 注册失败。
		unit:AddNewModifier(unit, nil, "modifier_invulnerable", {duration = -1})
	end
	return unit:HasModifier("modifier_invulnerable")
end

function THD2_IsBotCourierShielded(unit)
	return BotCourier_IsValidCourier(unit) and unit:GetContext(BOT_COURIER_SHIELD_CONTEXT) == 1
end

function THD2_ApplyBotCourierShieldDamage(keys)
	if keys == nil or keys.entindex_victim_const == nil then return end
	if not THD_GetBotCourierShieldEnabled() then return end

	local target = EntIndexToHScript(keys.entindex_victim_const)
	if THD2_IsBotCourierShielded(target) then
		keys.damage = 0
	end
end

function THD2_ScheduleBotCourierShield(unit)
	if not THD_GetBotCourierShieldEnabled() then return end
	if not BotCourier_IsValidCourier(unit) then return end

	-- npc_spawned 触发时信使可能尚未绑定控制者，短时间重试后再结束检查。
	local retryCount = 0
	unit:SetContextThink("thd2_bot_courier_shield", function()
		if unit == nil or unit:IsNull() then return nil end
		if THD2_ApplyBotCourierShield(unit) then return nil end

		retryCount = retryCount + 1
		if retryCount >= BOT_COURIER_OWNER_RETRY_COUNT then return nil end
		return BOT_COURIER_OWNER_RETRY_INTERVAL
	end, 0)
end

function THD2_RefreshBotCourierShields()
	if not THD_GetBotCourierShieldEnabled() then return end
	local couriers = Entities:FindAllByClassname("npc_dota_courier") or {}
	for _, courier in pairs(couriers) do
		THD2_ScheduleBotCourierShield(courier)
	end
end

local function BotCourier_ClearShield(unit)
	if not THD2_IsBotCourierShielded(unit) then return end
	unit:SetContextNum(BOT_COURIER_SHIELD_CONTEXT, 0, 0)
	if unit:HasModifier("modifier_invulnerable") then
		unit:RemoveModifierByName("modifier_invulnerable")
	end
end

local function BotCourier_ClearAllShields()
	local couriers = Entities:FindAllByClassname("npc_dota_courier") or {}
	for _, courier in pairs(couriers) do
		BotCourier_ClearShield(courier)
	end
end

function THD_SetBotCourierShieldEnabled(enabled, source)
	THD_BOT_COURIER_SHIELD_ENABLED = enabled == true
	local message = string.format(
		"[THD][BotCourierShield] enabled=%s source=%s",
		tostring(THD_BOT_COURIER_SHIELD_ENABLED),
		tostring(source or "unknown")
	)
	print(message)
	if not THD_BOT_COURIER_SHIELD_ENABLED then
		BotCourier_ClearAllShields()
	else
		THD2_RefreshBotCourierShields()
	end
	return THD_BOT_COURIER_SHIELD_ENABLED
end

local function BotCourier_ParseEnabled(value)
	local arg = string.lower(tostring(value or ""))
	local enable = arg == "1" or arg == "true" or arg == "on"
	if not enable and not (arg == "0" or arg == "false" or arg == "off") then
		print("[THD][BotCourierShield] usage: thd_bot_courier_shield on|off")
		return nil
	end
	return enable
end

Convars:RegisterCommand("thd_bot_courier_shield", function(_, value)
	local enable = BotCourier_ParseEnabled(value)
	if enable == nil then return end
	THD_SetBotCourierShieldEnabled(enable, "console")
end, "Enable or disable bot courier invulnerable shield", 0)

Convars:RegisterCommand("thd_bot_courier_shield_on", function()
	THD_SetBotCourierShieldEnabled(true, "console")
end, "Enable bot courier invulnerable shield", 0)

Convars:RegisterCommand("thd_bot_courier_shield_off", function()
	THD_SetBotCourierShieldEnabled(false, "console")
end, "Disable bot courier invulnerable shield", 0)

BotCourier_ClearAllShields()
