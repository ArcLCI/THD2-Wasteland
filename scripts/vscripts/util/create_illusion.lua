--[[
function create_illusion(keys, illusion_origin, illusion_incoming_damage, illusion_outgoing_damage, illusion_duration)	
	local player_id = keys.caster:GetPlayerID()
	local caster_team = keys.caster:GetTeam()
	local tmp = keys.caster
	if keys.caster:GetPlayerOwner():GetContext("PlayerIsBot") == 1 then
		tmp = nil
	end
	
	local illusion = CreateUnitByName(keys.caster:GetUnitName(), illusion_origin, true, keys.caster, tmp, caster_team)  --handle_UnitOwner needs to be nil, or else it will crash the game.  --seriously?
	illusion:SetPlayerID(player_id)
	illusion:SetControllableByPlayer(player_id, true)

	--Level up the illusion to the caster's level.
	local caster_level = keys.caster:GetLevel()
	for i = 1, caster_level - 1 do
		illusion:HeroLevelUp(false)
	end

	--Set the illusion's available skill points to 0 and teach it the abilities the caster has.
	illusion:SetAbilityPoints(0)
	for ability_slot = 0, 15 do
		local individual_ability = keys.caster:GetAbilityByIndex(ability_slot)
		if individual_ability ~= nil then 
			local illusion_ability = illusion:FindAbilityByName(individual_ability:GetAbilityName())
			if illusion_ability ~= nil then
				illusion_ability:SetLevel(individual_ability:GetLevel())
			end
		end
	end

	--Recreate the caster's items for the illusion.
	for item_slot = 0, 5 do
		local individual_item = keys.caster:GetItemInSlot(item_slot)
		if individual_item ~= nil then
			local illusion_duplicate_item = CreateItem(individual_item:GetName(), illusion, illusion)
			illusion:AddItem(illusion_duplicate_item)
			illusion_duplicate_item:SetPurchaser(nil)
		end
	end
	
	-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle 
	illusion:AddNewModifier(keys.caster, keys.ability, "modifier_illusion", {duration = illusion_duration, outgoing_damage = illusion_outgoing_damage, incoming_damage = illusion_incoming_damage})
	
	illusion:MakeIllusion()  --Without MakeIllusion(), the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.  Without it, IsIllusion() returns false and IsRealHero() returns true.

	return illusion
end
--]]

function CreateIllusionTHD(keys, target, illusion_origin, illusion_incoming_damage, illusion_outgoing_damage, illusion_duration, bfindClearSpace)
	local caster
	if keys.caster ~= nil then
		caster = keys.caster
	else
		caster = keys:GetCaster()
	end
	if caster == nil or caster:IsNull() or target == nil or target:IsNull() then
		return nil
	end

	-- 7.38 的 CreateIllusions 要求有效实体 owner；Bot 同样使用真实施法者，不能再传 nil。
	local illusions = CreateIllusions(caster, target, {	-- (owner: CBaseEntity, heroToCopy: CDOTA_BaseNPC_Hero, modifierKeys: CreateIllusionsModifierKeys,
		outgoing_damage = illusion_outgoing_damage,
		incoming_damage	= illusion_incoming_damage,
		bounty_base		= 0,		-- 基础金钱
		bounty_growth	= 2,		-- 每级金钱成长
		outgoing_damage_structure	= nil,
		outgoing_damage_roshan		= nil,
		duration		= illusion_duration
	}
	, 1, 72, false, bfindClearSpace)		--  numIllusions: int, padding: int, scramblePosition: bool, findClearSpace: bool): [CDOTA_BaseNPC_Hero]
	if illusions == nil then
		return nil
	end

	for i, illusion in pairs(illusions) do

		if illusion_origin then
			FindClearSpaceForUnit(illusion,illusion_origin,true)	-- 没有设定地点，幻象将产生在target位置(padding)
		end

		return illusion		-- 返回 CDOTA_BaseNPC_Hero
	end
end
