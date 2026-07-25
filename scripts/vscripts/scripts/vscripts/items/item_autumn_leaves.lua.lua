LinkLuaModifier( "modifier_item_autumn_leaves", "scripts/vscripts/items/item_autumn_leaves.lua.lua", LUA_MODIFIER_MOTION_NONE )
--Abilities
if item_autumn_leaves == nil then
	item_autumn_leaves = class({})
end
function item_autumn_leaves:GetIntrinsicModifierName()
	return "modifier_item_autumn_leaves"
end
---------------------------------------------------------------------
--Modifiers
if modifier_item_autumn_leaves == nil then
	modifier_item_autumn_leaves = class({})
end
function modifier_item_autumn_leaves:OnCreated(params)
	if IsServer() then
	end
end
function modifier_item_autumn_leaves:OnRefresh(params)
	if IsServer() then
	end
end
function modifier_item_autumn_leaves:OnDestroy()
	if IsServer() then
	end
end
function modifier_item_autumn_leaves:DeclareFunctions()
	return {
	}
end