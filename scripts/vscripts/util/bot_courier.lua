LinkLuaModifier("modifier_bot_courier_shield", "util/bot_courier.lua", LUA_MODIFIER_MOTION_NONE)

local BOT_COURIER_OWNER_RETRY_INTERVAL = 0.1
local BOT_COURIER_OWNER_RETRY_COUNT = 100

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
	if unit == nil or unit:IsNull() or unit.IsCourier == nil or not unit:IsCourier() then return true end

	local playerID = BotCourier_GetOwnerPlayerID(unit)
	if playerID < 0 then return false end
	if not BotCourier_IsBotPlayerID(playerID) then return true end

	if not unit:HasModifier("modifier_bot_courier_shield") then
		unit:AddNewModifier(unit, nil, "modifier_bot_courier_shield", {})
	end
	return unit:HasModifier("modifier_bot_courier_shield")
end

function THD2_ScheduleBotCourierShield(unit)
	if unit == nil or unit:IsNull() or unit.IsCourier == nil or not unit:IsCourier() then return end

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
	local couriers = Entities:FindAllByClassname("npc_dota_courier") or {}
	for _, courier in pairs(couriers) do
		THD2_ScheduleBotCourierShield(courier)
	end
end

modifier_bot_courier_shield = class({})

function modifier_bot_courier_shield:IsHidden() return true end
function modifier_bot_courier_shield:IsDebuff() return false end
function modifier_bot_courier_shield:IsPurgable() return false end
function modifier_bot_courier_shield:RemoveOnDeath() return false end

function modifier_bot_courier_shield:CheckState()
	-- 信使无敌使用明确状态实现，三类绝对无伤属性继续作为伤害事件兜底。
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
end

function modifier_bot_courier_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_bot_courier_shield:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_bot_courier_shield:GetAbsoluteNoDamageMagical() return 1 end
function modifier_bot_courier_shield:GetAbsoluteNoDamagePure() return 1 end
