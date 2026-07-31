local function Assert(condition, message)
    if not condition then error(message, 2) end
end

local VecMeta = {}
VecMeta.__index = VecMeta
function VecMeta:Length2D()
    return math.sqrt(self.x * self.x + self.y * self.y)
end
function VecMeta.__sub(a, b)
    return setmetatable({x = a.x - b.x, y = a.y - b.y, z = 0}, VecMeta)
end

local function Vec(x, y)
    return setmetatable({x = x, y = y or 0, z = 0}, VecMeta)
end

DOTA_UNIT_TARGET_TEAM_FRIENDLY = 1
DOTA_UNIT_TARGET_BASIC = 2
DOTA_UNIT_TARGET_OTHER = 4
DOTA_UNIT_TARGET_FLAG_INVULNERABLE = 8
FIND_CLOSEST = 0

function IsValidEntity(unit) return unit ~= nil and not unit.removed end

local worldUnits = {}
function FindUnitsInRadius()
    return worldUnits
end

local clearedPosition = nil
function FindClearSpaceForUnit(_, position)
    clearedPosition = position
end

dofile("scripts/vscripts/abilities/abilityyuuka.lua")

local caster = {origin = Vec(0), ownerIndex = 17, wanbao = false}
function caster:entindex() return self.ownerIndex end
function caster:GetOrigin() return self.origin end
function caster:GetTeamNumber() return 1 end
function caster:GetCastRangeBonus() return 0 end
function caster:GetPlayerOwnerID() return 5 end
function caster:HasModifier(name) return name == "modifier_item_wanbaochui" and self.wanbao end
function caster:EmitSound() end
function caster:FindAbilityByName() return nil end

local ability = {cooldownEnded = false, manaRefunded = false}
function ability:GetSpecialValueFor(name)
    Assert(name == "AbilityCastRange", "unexpected Yuuka special value")
    return 700
end
function ability:EndCooldown() self.cooldownEnded = true end
function ability:RefundManaCost() self.manaRefunded = true end

local function NewFlower(x, ownerIndex)
    local flower = {
        origin = Vec(x),
        alive = true,
        thdots_yuuka_owner_entindex = ownerIndex,
    }
    function flower:IsAlive() return self.alive end
    function flower:GetUnitName() return "ability_yuuka_flower" end
    function flower:GetOrigin() return self.origin end
    function flower:SetOwner(owner) self.owner = owner end
    function flower:SetControllableByPlayer(playerID, enabled)
        self.controllerID = playerID
        self.controlEnabled = enabled
    end
    function flower:AddNoDraw() self.hidden = true end
    function flower:ForceKill() self.alive = false end
    return flower
end

local foreignFlower = NewFlower(90, 99)
local ownedFlower = NewFlower(120, caster.ownerIndex)
YuukaRegisterFlowerControl(caster, ownedFlower)
Assert(ownedFlower.owner == caster and ownedFlower.controllerID == 5 and ownedFlower.controlEnabled,
    "flower must be registered as the Bot player's controllable minion")
worldUnits = {foreignFlower, ownedFlower}
Assert(YuukaFindOwnedFlower(caster, ability, Vec(100), 250) == ownedFlower,
    "point resolver must reject a closer foreign flower")

local farFlower = NewFlower(800, caster.ownerIndex)
worldUnits = {farFlower}
Assert(YuukaFindOwnedFlower(caster, ability, Vec(800), 250) == nil,
    "point resolver must reject an owned flower outside cast range")

worldUnits = {foreignFlower, ownedFlower}
clearedPosition = nil
YuukaEx2_OnSpellStart({caster = caster, ability = ability, target_points = {Vec(100)}})
Assert(clearedPosition == ownedFlower.origin, "Ex2 must jump to the resolved owned flower")

worldUnits = {}
ability.cooldownEnded = false
ability.manaRefunded = false
clearedPosition = nil
YuukaEx2_OnSpellStart({caster = caster, ability = ability, target_points = {Vec(300)}})
Assert(clearedPosition == nil and ability.cooldownEnded and ability.manaRefunded,
    "unupgraded Ex2 must reject a point without an owned flower")

caster.wanbao = true
ability.cooldownEnded = false
ability.manaRefunded = false
local wanbaoPoint = Vec(300)
YuukaEx2_OnSpellStart({caster = caster, ability = ability, target_points = {wanbaoPoint}})
Assert(clearedPosition == wanbaoPoint and not ability.cooldownEnded and not ability.manaRefunded,
    "Wanbaochui Ex2 must jump directly to a point when no flower exists")

caster.wanbao = false
ownedFlower = NewFlower(120, caster.ownerIndex)
worldUnits = {foreignFlower, ownedFlower}
local createdAt = nil
local illusion = {}
function Yuuka04_CreateIllusion(_, position)
    createdAt = position
    return illusion
end
Yuuka04_OnSpellStart({
    caster = caster,
    ability = ability,
    target_points = {Vec(100)},
    Duration = 20,
    IllusionDamageInPct = 50,
    IllusionDamageOutPct = -50,
})
Assert(ownedFlower.hidden and not ownedFlower.alive, "Yuuka04 must consume the resolved owned flower")
Assert(createdAt == ownedFlower.origin and caster.ability_yuuka04_illusion == illusion,
    "Yuuka04 must create and record its illusion at the resolved flower")

print("test_yuuka_point_cast: OK")
