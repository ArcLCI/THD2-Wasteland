LinkLuaModifier("modifier_bot_courier_shield", "scripts/vscripts/util/bot_courier.lua", LUA_MODIFIER_MOTION_NONE)

local function BotCourier_IsBotPlayerID(playerID)
	if playerID == nil or playerID < 0 then return false end
	-- 优先兼容全局 Bot 判断，未提供时使用项目现有的 fallback。
	if THD2_IsBotPlayerID ~= nil then
		return THD2_IsBotPlayerID(playerID)
	end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then return true end
	if PlayerIsBot ~= nil and PlayerIsBot(playerID) then return true end
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

	-- 部分信使没有直接 owner，通过玩家首选信使反查实际控制者。
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
	return true
end

function THD2_ScheduleBotCourierShield(unit)
	if unit == nil or unit:IsNull() or unit.IsCourier == nil or not unit:IsCourier() then return end

	-- npc_spawned 触发时信使可能尚未绑定控制者，短时间重试后再结束检查。
	local retryCount = 0
	unit:SetContextThink("thd2_bot_courier_shield", function()
		if unit == nil or unit:IsNull() then return nil end
		if THD2_ApplyBotCourierShield(unit) then return nil end

		retryCount = retryCount + 1
		if retryCount >= 20 then return nil end
		return 0.1
	end, 0)
end

modifier_bot_courier_shield = class({})

function modifier_bot_courier_shield:IsHidden() return true end
function modifier_bot_courier_shield:IsDebuff() return false end
function modifier_bot_courier_shield:IsPurgable() return false end
function modifier_bot_courier_shield:RemoveOnDeath() return false end

function modifier_bot_courier_shield:DeclareFunctions()
	-- 不使用 INVULNERABLE 状态，避免改变信使的选取和交互规则。
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_bot_courier_shield:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_bot_courier_shield:GetAbsoluteNoDamageMagical() return 1 end
function modifier_bot_courier_shield:GetAbsoluteNoDamagePure() return 1 end
