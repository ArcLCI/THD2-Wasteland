function LinkLuaModifier() end
function IsServer() return true end

dofile("scripts/vscripts/abilities/abilitysunny.lua")

local function Assert(condition, message)
	if not condition then error(message, 2) end
end

local function NewCaster(isRealHero, isIllusion)
	local caster = {
		isRealHero = isRealHero,
		isIllusion = isIllusion,
		hasWanbaochui = true,
		contextThinkCount = 0,
	}
	function caster:IsNull() return false end
	function caster:IsRealHero() return self.isRealHero end
	function caster:IsIllusion() return self.isIllusion end
	function caster:IsOwnedByAnyPlayer()
		error("Sunny05 must not reject a Bot through IsOwnedByAnyPlayer")
	end
	function caster:HasModifier(name)
		return name == "modifier_item_wanbaochui" and self.hasWanbaochui
	end
	function caster:SetContextThink(_, callback)
		self.contextThinkCount = self.contextThinkCount + 1
		callback()
	end
	return caster
end

local function NewAbility(caster, target)
	local ability = setmetatable({ caster = caster, target = target }, { __index = ability_thdots_sunny05 })
	function ability:GetCaster() return self.caster end
	function ability:GetCursorTarget() return self.target end
	function ability:GetSpecialValueFor(name)
		Assert(name == "duration", "unexpected Sunny05 special value")
		return 40
	end
	function ability:SetHidden(hidden) self.hidden = hidden end
	return ability
end

local target = {}
function target:IsNull() return false end

local createdCount = 0
local modifierCount = 0
function CreateIllusionTHD(_, copiedTarget, _, incomingDamage, outgoingDamage, duration, findClearSpace)
	Assert(copiedTarget == target, "Sunny05 must copy the selected target")
	Assert(incomingDamage == 0 and outgoingDamage == 0, "Sunny05 illusion damage values changed")
	Assert(duration == 40 and findClearSpace == true, "Sunny05 illusion duration or placement changed")
	createdCount = createdCount + 1
	local illusion = {}
	function illusion:IsNull() return false end
	function illusion:AddNewModifier(_, _, name)
		Assert(name == "modifier_ability_thdots_sunny05", "Sunny05 marker modifier missing")
		modifierCount = modifierCount + 1
	end
	return illusion
end

local botCaster = NewCaster(true, false)
local botAbility = NewAbility(botCaster, target)
botAbility:OnInventoryContentsChanged()
Assert(botAbility.hidden == false, "Bot Sunny05 must be visible with Wanbaochui")
botAbility:OnSpellStart()
Assert(createdCount == 1, "Bot Sunny05 must create one illusion")
Assert(modifierCount == 1, "Bot Sunny05 illusion must receive its marker modifier")

local illusionCaster = NewCaster(false, true)
local illusionAbility = NewAbility(illusionCaster, target)
illusionAbility:OnInventoryContentsChanged()
illusionAbility:OnSpellStart()
Assert(illusionAbility.hidden == nil, "Sunny illusion must not refresh Wanbaochui visibility")
Assert(illusionCaster.contextThinkCount == 0, "Sunny illusion must not recursively create another illusion")
Assert(createdCount == 1, "invalid Sunny05 caster created an illusion")

local helperIllusion = {}
local ownerPassedToCreateIllusions = "unset"
function CreateIllusions(owner, copiedTarget)
	Assert(owner ~= nil, "CreateIllusions requires a valid owner")
	ownerPassedToCreateIllusions = owner
	Assert(copiedTarget == target, "CreateIllusionTHD must preserve the copied target")
	return { helperIllusion }
end

dofile("scripts/vscripts/util/create_illusion.lua")

local ownerlessCaster = {}
function ownerlessCaster:IsNull() return false end
function ownerlessCaster:GetPlayerOwner() return nil end
local ownerlessAbility = {}
function ownerlessAbility:GetCaster() return ownerlessCaster end

local result = CreateIllusionTHD(ownerlessAbility, target, nil, 0, 0, 40, true)
Assert(result == helperIllusion, "ownerless caster must still create an illusion")
Assert(ownerPassedToCreateIllusions == ownerlessCaster, "ownerless caster must remain the illusion owner")

local botOwner = {}
function botOwner:GetContext(name)
	Assert(name == "PlayerIsBot", "unexpected player context lookup")
	return 1
end
function botCaster:GetPlayerOwner() return botOwner end

result = CreateIllusionTHD(botAbility, target, nil, 0, 0, 40, true)
Assert(result == helperIllusion, "Bot caster helper path must return its illusion")
Assert(ownerPassedToCreateIllusions == botCaster, "Bot caster must be the valid illusion owner")

print("[PASS] Sunny05 game-side Bot casting mock")
