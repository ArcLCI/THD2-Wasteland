function ItemAbility_yuemianzhinu_range(keys)
	local caster = keys.caster
	local ability = keys.ability
    caster:AddNewModifier(caster, ability, "modifier_item_yuemianzhinu_range",{ })
end
function ItemAbility_yuemianzhinu_range_destory(keys)
	local caster = keys.caster
	if caster == nil or caster:IsNull() then return end
	-- 各件物品独立持有射程来源，移除一件不会影响剩余物品。
	for _, modifier in ipairs(caster:FindAllModifiersByName("modifier_item_yuemianzhinu_range")) do
		if modifier:GetAbility() == keys.ability then modifier:Destroy() end
	end
end
modifier_item_yuemianzhinu_range = modifier_item_yuemianzhinu_range or class({})
LinkLuaModifier("modifier_item_yuemianzhinu_range", "items/item_yuemianzhinu.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_yuemianzhinu_range:IsDebuff() return false end

function modifier_item_yuemianzhinu_range:IsHidden() return true end

function modifier_item_yuemianzhinu_range:IsPurgable() return false end

function modifier_item_yuemianzhinu_range:RemoveOnDeath() return false end
function modifier_item_yuemianzhinu_range:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_yuemianzhinu_range:OnCreated(params)
    if not IsServer() then return end
end
function modifier_item_yuemianzhinu_range:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS_UNIQUE
	}
end
function modifier_item_yuemianzhinu_range:GetModifierAttackRangeBonusUnique()
	local ability = self:GetAbility()
	if ability == nil or ability:IsNull() or not self:GetParent():IsRangedAttacker() then return 0 end
	-- 只给远程单位提供射程，和其他装备通过 UNIQUE 取最大值。
	return ability:GetSpecialValueFor("bonus_attack_range")
end
