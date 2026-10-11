local M = {}
local Items = require("util/bot_native_item_policy")
local CONTEXT = "thd_native_policy_r2"
local MOKOU, TEI = "npc_dota_hero_chaos_knight", "npc_dota_hero_gyrocopter"

local function HealthExemption(hero, slot, state)
	-- 只豁免血量比例门槛，不增加倍率，也不越过死亡、失能或动作生命周期保护。
	if state >= Items.TEETH_STATE then return "teeth_lifesteal" end
	if hero:IsInvulnerable() then return "invulnerable" end
	-- 已核对的主动生存窗口：妹红大招持续回血，蕾米莉亚开启大招按实际伤害吸血。
	if slot == MOKOU and hero:HasModifier("modifier_thdots_Mokou_04") then return "mokou_regeneration" end
	if slot == "npc_dota_hero_warlock" and hero:HasModifier("modifier_thdots_Remilia04_think_interval") then
		return "remilia_active_lifesteal"
	end
	return nil
end

local function CanBenefit(hero, slot, state)
	-- 普通爆发保留20%门槛；有效吸血/无敌等生存窗口不限瞬时血量比例。
	if not hero:IsAlive() or hero:GetMaxHealth() <= 0 then
		return false, "dead_or_invalid_health"
	end
	local exemption = HealthExemption(hero, slot, state)
	if exemption == nil and hero:GetHealth() / hero:GetMaxHealth() < 0.2 then
		return false, "below_20pct"
	end
	if hero:IsChanneling() or hero:IsDisarmed() or hero:IsStunned() or hero:IsHexed()
		or hero:HasModifier("modifier_phenx_egg_caster")
		or hero:HasModifier("modifier_item_yuetufensuijvren_buff")
		or hero:HasModifier("modifier_thdots_Mokou01_think_interval") then return false, "disabled_or_protected" end
	for i = 0, hero:GetAbilityCount() - 1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability ~= nil and (ability:IsInAbilityPhase() or ability:IsChanneling()) then return false, "ability_cast" end
	end
	-- 主动装备的前摇/持续施法同样保留保护，覆盖背包、TP及中立物品槽位。
	for i = 0, 16 do
		local item = hero:GetItemInSlot(i)
		if item ~= nil and (item:IsInAbilityPhase() or item:IsChanneling()) then return false, "item_cast" end
	end
	return true, exemption ~= nil and ("eligible_no_health_floor_" .. exemption) or "eligible_20pct"
end

-- 各英雄发布同一版本的自身状态；倍率只在原生统一入口计算一次。
function M.Attach(hero)
	if hero == nil or hero:IsNull() or not hero:IsRealHero() or hero:IsIllusion() then return end
	local slot = hero:GetUnitName()
	hero:SetContextNum(CONTEXT, 0, 0)
	local sequence, lastState = 0, nil
	local lastObserved, lastReason = nil, nil
	hero:SetContextThink("THDNativePolicyR2", function()
		if hero:IsNull() then return nil end
		if GameRules:IsGamePaused() then return 0.2 end
		local player = hero:GetPlayerOwnerID()
		if player < 0 or not PlayerResource:IsFakeClient(player)
			or PlayerResource:GetSelectedHeroEntity(player) ~= hero then
			hero:SetContextNum(CONTEXT, 0, 0)
			return nil
		end
		local marker = hero:FindAbilityByName("ability_thd2_bot_profile")
		local damageProfile = marker ~= nil and marker:GetLevel() == 1
		local state = Items.GetState(hero)
		if damageProfile then
			if slot == MOKOU and hero:HasModifier("modifier_thdots_Mokou_04") then state = state + 1 end
			if slot == TEI then
				if hero:HasModifier("modifier_ability_thdots_tei03") then state = state + 2 end
				if hero:HasModifier("modifier_ability_thdots_tei04") then state = state + 4 end
			end
		end
		local observed = state
		local reason = "no_active_state"
		if state ~= 0 then
			local eligible
			eligible, reason = CanBenefit(hero, slot, state)
			if not eligible then state = 0 end
		end
		-- 最大16000015，小于2^24；数字context即使经float传递也不会丢失状态位。
		sequence = sequence % 1000000 + 1
		hero:SetContextNum(CONTEXT, sequence * 16 + state, 0)
		if lastState ~= state or lastObserved ~= observed or lastReason ~= reason then
			print(string.format("[THDNativePolicy] version=2 hero=%s entity=%d state=%d observed_state=%d reason=%s profile_damage=%s time=%.3f",
				slot, hero:entindex(), state, observed, reason, tostring(damageProfile), GameRules:GetGameTime()))
			lastState, lastObserved, lastReason = state, observed, reason
		end
		return 0.2
	end, 0.2)
end

return M
