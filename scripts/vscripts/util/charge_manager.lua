
ChargeManager = {
	["abilities"] = {},
}

AbilitiesSharedCharge = {
	["lunchbox"] = 0
}

local function GetPlayerChargeState(hUnit)
	if hUnit == nil or hUnit:IsNull() then return nil end
	local nPlayerID = hUnit:GetPlayerOwnerID()
	if nPlayerID == nil or nPlayerID < 0 then return nil end
	local charges = ChargeManager["abilities"][nPlayerID]
	if charges == nil and hUnit:IsRealHero() and not hUnit:IsClone() and not hUnit:IsTempestDouble() then
		charges = {}
		for key, value in pairs(AbilitiesSharedCharge) do charges[key] = value end
		ChargeManager["abilities"][nPlayerID] = charges
	end
	return charges
end

local function NoteMissingChargeState(hUnit, sKey)
	if hUnit == nil or hUnit:IsNull() then return end
	-- 每单位/共享键只记一次；缺表单位不创建或清零玩家英雄的共享充能。
	hUnit.THD_MissingChargeStateLogged = hUnit.THD_MissingChargeStateLogged or {}
	if hUnit.THD_MissingChargeStateLogged[sKey] then return end
	hUnit.THD_MissingChargeStateLogged[sKey] = true
	print(string.format('[THD][ChargeManager] result=missing_player_state player=%s unit=%s key=%s real_hero=%s clone=%s tempest=%s illusion=%s',
		tostring(hUnit:GetPlayerOwnerID()), tostring(hUnit:GetUnitName()), tostring(sKey),
		tostring(hUnit:IsRealHero()), tostring(hUnit:IsClone()), tostring(hUnit:IsTempestDouble()), tostring(hUnit:IsIllusion())))
end

function ChargeManager:InitCharges(hAbility, hUnit, sKey)
	if hAbility == nil or hAbility:IsNull() then return end
	local charges = GetPlayerChargeState(hUnit)
	if charges == nil then
		-- 不标记InitedCharge，真实英雄状态建立后仍可正确初始化。
		NoteMissingChargeState(hUnit, sKey)
		return
	end
	if hAbility.InitedCharge then
		ChargeManager:SetCharges(hUnit, sKey, hAbility:GetCurrentCharges())
		return
	end
	hAbility:SetCurrentCharges(charges[sKey] or 0)
	hAbility.InitedCharge = true
end

function ChargeManager:SetCharges(hUnit, sKey, nCharge)
	local charges = GetPlayerChargeState(hUnit)
	if charges == nil then
		NoteMissingChargeState(hUnit, sKey)
		return false
	end
	charges[sKey] = nCharge
	return true
end

function ChargeManager:GetCharges(hUnit, sKey, hAbility)
	local charges = GetPlayerChargeState(hUnit)
	if charges == nil then
		NoteMissingChargeState(hUnit, sKey)
		return 0
	end
	if hAbility ~= nil and not hAbility:IsNull() and hAbility.InitedCharge == nil then
		hAbility.InitedCharge = true
	end
	return charges[sKey] or 0
end

function ChargeManager:RemoveCharges(hUnit, sKey, tModifiers)
	if hUnit == nil or hUnit:IsNull() then return end

	-- 没有modifier时重置Charges
	if tModifiers ~= nil then
		for i, modifier in pairs(tModifiers) do
			if hUnit:HasModifier(modifier) then return end
		end
	end

	ChargeManager:SetCharges(hUnit, sKey, 0)
end
