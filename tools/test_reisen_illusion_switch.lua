local function Assert(condition, message)
    if not condition then
        error(message, 2)
    end
end

function class(value)
    return value
end

PATTACH_CUSTOMORIGIN = 0

local caster = {
    origin = {x = 100, y = 200, z = 0},
}

function caster:GetOrigin()
    return {x = self.origin.x, y = self.origin.y, z = self.origin.z}
end

function caster:GetHullRadius()
    return 24
end

function caster:GetEntityIndex()
    return 42
end

function caster:HasModifier()
    return false
end

function caster:FindModifierByName()
    return nil
end

local entities = {[1] = caster}
function EntIndexToHScript(index)
    return entities[index]
end

function RandomFloat()
    return 0
end

local clearSpaceCalls = 0
local lastClearSpacePosition = nil
function FindClearSpaceForUnit(unit, position, findClearSpace)
    Assert(unit == caster and findClearSpace == true, "Reisen02 displacement arguments changed")
    clearSpaceCalls = clearSpaceCalls + 1
    lastClearSpacePosition = position
end

local createCalls = 0
local createdCounts = {}
local createdIllusions = {}
function CreateIllusions(owner, copiedHero, modifierKeys, count, padding, scramblePosition, findClearSpace)
    Assert(owner == caster and copiedHero == caster, "Reisen02 illusion source changed")
    Assert(modifierKeys.outgoing_damage == -80 and modifierKeys.incoming_damage == 250,
        "Reisen02 illusion damage values changed")
    Assert(modifierKeys.duration == 10, "Reisen02 illusion duration changed")
    Assert(padding == 24 and scramblePosition == true and findClearSpace == true,
        "Reisen02 illusion placement arguments changed")

    createCalls = createCalls + 1
    table.insert(createdCounts, count)
    local result = {}
    for _ = 1, count do
        local illusion = {context = nil}
        function illusion:GetOrigin()
            return {x = 120, y = 220, z = 0}
        end
        function illusion:SetContextNum(name, value)
            Assert(name == "ReisenOld02IllusionCaster", "Reisen02 illusion context name changed")
            self.context = value
        end
        table.insert(result, illusion)
        table.insert(createdIllusions, illusion)
    end
    return result
end

ParticleManager = {}
function ParticleManager:CreateParticle()
    return 1
end

function ParticleManager:SetParticleControl()
end

THD2_REISEN_ILLUSIONS_ENABLED = nil
dofile("scripts/vscripts/abilities/abilityreisen.lua")

local keys = {
    caster_entindex = 1,
    Max_illusions = 9,
    Illusion_duration = 10,
    Illusion_damage_out_pct = -80,
    Illusion_damage_in_pct = 250,
    Chance = 10,
    illusionChance = 1.5,
}

Assert(THD2_REISEN_ILLUSIONS_ENABLED == false, "Reisen illusion debug switch must default to disabled")

OnReisenOld02SpellStart(keys)
Assert(clearSpaceCalls == 1, "Reisen02 active displacement must remain enabled while illusions are disabled")
Assert(math.abs(lastClearSpacePosition.x - 150) < 0.001 and lastClearSpacePosition.y == 200,
    "Reisen02 active displacement distance changed")
Assert(createCalls == 0, "Reisen02 active created illusions while the master switch was disabled")
Assert(caster.ability_reisen02_illusion_max == nil,
    "Reisen02 active changed the illusion counter while the master switch was disabled")

OnReisenOld02SpellSuccess(keys)
Assert(createCalls == 0, "Reisen02 passive created illusions while the master switch was disabled")

THD2_REISEN_ILLUSIONS_ENABLED = true
OnReisenOld02SpellStart(keys)
OnReisenOld02SpellSuccess(keys)
Assert(createCalls == 2 and createdCounts[1] == 2 and createdCounts[2] == 1,
    "Reisen02 master switch did not restore both illusion creation paths")
Assert(caster.ability_reisen02_illusion_max == 3, "Reisen02 illusion counter changed")
for _, illusion in ipairs(createdIllusions) do
    Assert(illusion.context == 42, "Reisen02 illusion owner context changed")
end

print("test_reisen_illusion_switch: PASS")
