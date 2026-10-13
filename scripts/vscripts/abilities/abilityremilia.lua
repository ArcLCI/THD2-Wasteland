-- 重制神枪
ability_thdots_remilia01 = {}

function ability_thdots_remilia01:GetCooldown(level)
    if self:GetCaster():HasModifier("modifier_ability_thdots_remilia_talent_1") then
        return self.BaseClass.GetCooldown(self, level) - 5
    else
        return self.BaseClass.GetCooldown(self, level)
    end
end

function ability_thdots_remilia01:GetCastRange(location, target)
    if self:GetCaster():HasModifier("modifier_ability_thdots_remilia_talent_1") then
        return self:GetSpecialValueFor("cast_range") * 2
    else
        return self:GetSpecialValueFor("cast_range")
    end
end

function ability_thdots_remilia01:OnSpellStart()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    caster:EmitSound("Sound_Thdots_Remilia.AbilityRemilia01")
    if not caster:HasModifier("modifier_ability_thdots_remilia_talent_Interval") then
        caster:AddNewModifier(caster, self, "modifier_ability_thdots_remilia_talent_Interval", {})
    end
    local ability = self
    local length = ability:GetSpecialValueFor("length")
    local end_position = self:GetCursorPosition()
    local collision_radius = ability:GetSpecialValueFor("collision_radius")
    local start_position = caster:GetOrigin()
    local move_speed = ability:GetSpecialValueFor("move_speed")
    if caster:HasModifier("modifier_ability_thdots_remilia_talent_1") then
        move_speed = move_speed * 2
        length = length * 2
    end
    print(move_speed)
    ProjectileManager:CreateLinearProjectile({
        Source = caster,
        Ability = ability,
        vSpawnOrigin = start_position,
        bDeleteOnHit = true,
        iUnitTargetTeam = ability:GetAbilityTargetTeam(),
        iUnitTargetType = ability:GetAbilityTargetType(),
        EffectName = "particles/heroes/remilia/ability_remilia_01.vpcf",
        fDistance = length,
        fStartRadius = collision_radius,
        fEndRadius = collision_radius,
        fExpireTime = GameRules:GetGameTime() + 10.0,
        vVelocity = (end_position - start_position):Normalized() * move_speed,
        bReplaceExisting = false,
        bProvidesVision = true,
        bHasFrontalCone = false,
        iVisionRadius = 300,
        iVisionTeamNumber = caster:GetTeamNumber()
    })
end

function ability_thdots_remilia01:OnProjectileHitHandle(hTarget, vLocation, iProjectileHandle)
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local target = hTarget
    if not hTarget then
        return
    end
    local vecTarget = target:GetOrigin() + Vector(0, 0, 64)
    local dealdamage = self:GetSpecialValueFor("damage")
    local StunDuration = self:GetSpecialValueFor("stun_duration")
    local damage_table = {
        ability = self,
        victim = target,
        attacker = caster,
        damage = dealdamage,
        damage_type = self:GetAbilityDamageType()
    }
    UtilStun:UnitStunTarget(caster, target, StunDuration, (UtilStun.TraceSource and UtilStun:TraceSource(function() return self end) or nil), "script:scripts/vscripts/abilities/abilityremilia.lua:OnProjectileHitHandle:80")

    local effectIndex = ParticleManager:CreateParticle("particles/heroes/remilia/ability_remilia_01_explosion.vpcf",
        PATTACH_CUSTOMORIGIN, target)
    ParticleManager:SetParticleControl(effectIndex, 0, vecTarget)
    ParticleManager:SetParticleControl(effectIndex, 3, vecTarget)
    ParticleManager:SetParticleControl(effectIndex, 5, vecTarget)
    ParticleManager:DestroyParticleSystem(effectIndex, false)

    StartSoundEventFromPosition("Hero_Lich.ChainFrostImpact.Hero", vLocation)
    ProjectileManager:DestroyLinearProjectile(iProjectileHandle)

    UnitDamageTarget(damage_table)
end

modifier_ability_thdots_remilia_talent_Interval = {}
LinkLuaModifier("modifier_ability_thdots_remilia_talent_Interval", "scripts/vscripts/abilities/abilityRemilia.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_remilia_talent_Interval:IsHidden()
    return true
end
function modifier_ability_thdots_remilia_talent_Interval:IsPurgable()
    return false
end
function modifier_ability_thdots_remilia_talent_Interval:RemoveOnDeath()
    return false
end
function modifier_ability_thdots_remilia_talent_Interval:IsDebuff()
    return false
end
function modifier_ability_thdots_remilia_talent_Interval:OnCreated()
    if not IsServer() then
        return
    end
    THD2_RefreshTalentModifiers(self:GetCaster(), "ability_thdots_remilia01")
end

function modifier_ability_thdots_remilia_talent_Interval:OnIntervalThink()
    if not IsServer() then
        return
    end
end

modifier_ability_thdots_remilia_talent_1 = {}
LinkLuaModifier("modifier_ability_thdots_remilia_talent_1", "scripts/vscripts/abilities/abilityRemilia.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_remilia_talent_1:IsHidden()
    return true
end
function modifier_ability_thdots_remilia_talent_1:IsPurgable()
    return false
end
function modifier_ability_thdots_remilia_talent_1:RemoveOnDeath()
    return false
end
function modifier_ability_thdots_remilia_talent_1:IsDebuff()
    return false
end

-- function OnRemilia01SpellStart(keys)
-- 	local caster = EntIndexToHScript(keys.caster_entindex)
-- 	THDReduceCooldown(keys.ability,FindTelentValue(caster,"special_bonus_unique_warlock_1"))
-- 	local vecCaster = caster:GetOrigin()
-- 	keys.ability.ability_remilia01_vecCaster = vecCaster

-- 	print_r(keys)
-- 	local ability = keys.ability
-- 	local length = ability:GetSpecialValueFor("length")
-- 	local end_position = keys.ability:GetCursorPosition()
-- 	local collision_radius = ability:GetSpecialValueFor("collision_radius")
-- 	local start_position = vecCaster
-- 	ProjectileManager:CreateLinearProjectile({
-- 				Source = caster,
-- 				Ability = ability,
-- 				vSpawnOrigin = start_position,
-- 				bDeleteOnHit = true,
-- 			    iUnitTargetTeam	 	= ability:GetAbilityTargetTeam(),
-- 	   			iUnitTargetType 	= ability:GetAbilityTargetType(),
-- 				EffectName = "particles/heroes/remilia/ability_remilia_01.vpcf",
-- 				fDistance = length,
-- 				fStartRadius = collision_radius,
-- 				fEndRadius = collision_radius,
-- 				vVelocity = (end_position - start_position):Normalized() * 1500,
-- 				bReplaceExisting = false,
-- 				bProvidesVision = true,	
-- 				bHasFrontalCone = false,				
-- 			})
-- end

-- function OnRemilia01SpellHit(keys)
-- 	local caster = EntIndexToHScript(keys.caster_entindex)
-- 	local target = keys.target
-- 	local vecTarget = target:GetOrigin() + Vector(0,0,64)
-- 	local dealdamage = keys.ability:GetAbilityDamage()
-- 	local damage_table = {
-- 			ability = keys.ability,
-- 			victim = target,
-- 			attacker = caster,
-- 			damage = dealdamage,
-- 			damage_type = keys.ability:GetAbilityDamageType(), 
-- 	    	amage_flags = 0
-- 	}
-- 	UnitDamageTarget(damage_table)	
-- 	local spellPoint = keys.ability.ability_remilia01_vecCaster
-- 	local dis = GetDistanceBetweenTwoVec2D(spellPoint,target:GetOrigin())

-- 	UtilStun:UnitStunTarget(caster,target,keys.StunDuration)

-- 	local effectIndex = ParticleManager:CreateParticle(
-- 		"particles/heroes/remilia/ability_remilia_01_explosion.vpcf", 
-- 		PATTACH_CUSTOMORIGIN, 
-- 		target)
-- 	ParticleManager:SetParticleControl(effectIndex, 0, vecTarget)
-- 	ParticleManager:SetParticleControl(effectIndex, 3, vecTarget)
-- 	ParticleManager:SetParticleControl(effectIndex, 5, vecTarget)
-- 	ParticleManager:DestroyParticleSystem(effectIndex,false)
-- end

function OnRemilia02SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    caster.ability_remilia_02_time_count = 0
    caster.ability_remilia_02_jump_high = 0
    caster.ability_remilia_02_jump_distance = 0
    caster.ability_remilia_02_forward_vector = caster:GetForwardVector()
    local effectIndex = ParticleManager:CreateParticle("particles/heroes/remilia/ability_remilia_02.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    if caster:HasModifier("modifier_item_wanbaochui") then
        ParticleManager:SetParticleControl(effectIndex, 1, Vector(235, 0, 0))
    else
        ParticleManager:SetParticleControl(effectIndex, 1, Vector(145, 0, 0))
    end
    ParticleManager:SetParticleControl(effectIndex, 0, caster:GetOrigin())
    caster.ability_remilia_02_effectIndex = effectIndex
end

function OnRemilia02SpellThink(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    caster.ability_remilia_02_time_count = caster.ability_remilia_02_time_count + 0.01
    local moveDistance = 3000 * caster.ability_remilia_02_time_count + 60
    local vecForward = caster.ability_remilia_02_forward_vector
    local effectOrigin = caster:GetOrigin() + Vector(vecForward.x * moveDistance, vecForward.y * moveDistance, 0)
    ParticleManager:SetParticleControl(caster.ability_remilia_02_effectIndex, 0, effectOrigin)
end

function OnRemilia02SpellRemove(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local moveDistance = 3000 * caster.ability_remilia_02_time_count
    keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_Remilia02_action", nil)

    caster:SetContextThink("ability_remilia_02_jump_timer", function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        if (caster.ability_remilia_02_jump_distance < moveDistance) then
            if (caster.ability_remilia_02_jump_distance <= moveDistance / 2) then
                caster.ability_remilia_02_jump_high = 30
            else
                caster.ability_remilia_02_jump_high = -30
            end
            caster.ability_remilia_02_jump_distance = caster.ability_remilia_02_jump_distance + keys.MoveSpeed / 20
            local vecCaster = caster:GetOrigin()
            local forwardVec = caster.ability_remilia_02_forward_vector
            local vec = vecCaster + forwardVec * keys.MoveSpeed / 20 + Vector(0, 0, caster.ability_remilia_02_jump_high)
            caster:SetOrigin(vec)
            return 0.05
        else
            caster:SetContextThink("ability_remilia_02_delay", function()
                if GameRules:IsGamePaused() then
                    return 0.03
                end
                caster:RemoveModifierByName("modifier_thdots_Remilia02_action")
                ParticleManager:DestroyParticleSystem(caster.ability_remilia_02_effectIndex, true)
                caster.ability_remilia_02_jump_distance = 0
                caster.ability_remilia_02_jump_high = 0
                local vecCaster = caster:GetOrigin()
                caster:SetOrigin(Vector(vecCaster.x, vecCaster.y, GetGroundPosition(vecCaster, nil).z))
                OnRemilia02SpellRemoveStage2(keys, moveDistance)
                return nil
            end, 0.1)
            return nil
        end
    end, 0.05)
end

function OnRemilia02SpellRemoveStage2(keys, moveDistance)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local radius = 140
    if caster:HasModifier("modifier_item_wanbaochui") then
        radius = 230
    end

    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius,
        keys.ability:GetAbilityTargetTeam(), keys.ability:GetAbilityTargetType(), keys.ability:GetAbilityTargetFlags(),
        FIND_CLOSEST, false)
    local target = nil

    for _, v in pairs(targets) do
        if (v ~= nil) and v:HasModifier("modifier_thdots_yasaka04_buff") == false then
            target = v
        end
    end

    if (target ~= nil) then
        local stuntime = moveDistance / keys.MoveSpeed
        UtilStun:UnitStunTarget(caster, target, stuntime, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilityremilia.lua:OnRemilia02SpellRemoveStage2:284")
        if caster:HasModifier("modifier_item_wanbaochui") then
            local damage_table = {
                ability = keys.ability,
                victim = target,
                attacker = caster,
                damage = 400,
                damage_type = keys.ability:GetAbilityDamageType(),
                damage_flags = keys.ability:GetAbilityTargetFlags()
            }
            UnitDamageTarget(damage_table)
        end

    end

    if (moveDistance > 0) then
        caster:SetContextThink("ability_remilia_02_jump_timer_stage2_action", function()
            if GameRules:IsGamePaused() then
                return 0.03
            end
            if (caster.ability_remilia_02_time_count ~= 0) then
                keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_Remilia02_action_stage2", nil)
            end
        end, 0.2)
    end

    caster:SetContextThink("ability_remilia_02_jump_timer_stage2", function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        if (caster.ability_remilia_02_jump_distance < moveDistance and
            (caster:HasModifier("modifier_thdots_Remilia03_think_interval") == false)) then
            if (caster.ability_remilia_02_jump_distance <= moveDistance / 2) then
                caster.ability_remilia_02_jump_high = 30
            else
                caster.ability_remilia_02_jump_high = -30
            end
            caster.ability_remilia_02_jump_high = caster.ability_remilia_02_jump_high + 10
            caster.ability_remilia_02_jump_distance = caster.ability_remilia_02_jump_distance + keys.MoveSpeed / 20
            local vecCaster = caster:GetOrigin()
            caster:SetForwardVector(caster.ability_remilia_02_forward_vector)
            local forwardVec = caster.ability_remilia_02_forward_vector
            local vec = vecCaster - forwardVec * keys.MoveSpeed / 20 + Vector(0, 0, caster.ability_remilia_02_jump_high)
            caster:SetOrigin(vec)
            if (target ~= nil) then
                target:SetOrigin(vec)
            end
            return 0.05
        else
            SetTargetToTraversable(caster)
            if (target ~= nil) then
                SetTargetToTraversable(target)
            end
            local vecCaster = caster:GetOrigin()
            caster:SetOrigin(Vector(vecCaster.x, vecCaster.y, GetGroundPosition(vecCaster, nil).z))
            caster.ability_remilia_02_time_count = 0
            caster:RemoveModifierByName("modifier_thdots_Remilia02_action_stage2")
            return nil
        end
    end, 0.05)
end

function OnRemilia03Start(keys)
    local Ability = keys.ability
    local Caster = keys.caster

    local effectIndex = ParticleManager:CreateParticle(
        "particles/econ/courier/courier_trail_04/courier_trail_04_bats.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(effectIndex, 0, Caster:GetOrigin() + Vector(0, 0, 64))
    ParticleManager:SetParticleControl(effectIndex, 1, Caster:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 3, Caster:GetOrigin() + Vector(0, 0, 64))
    ParticleManager:DestroyParticleSystemTime(effectIndex, 1)
    Caster:SetContextThink("ability_remilia_03_start_action", function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        Caster:AddNoDraw()
        return nil
    end, 0.3)
end
function OnRemilia03End(keys)
    local Ability = keys.ability
    local Caster = keys.caster
    Caster:RemoveNoDraw()
    local effectIndex = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_batrider/batrider_firefly_startflash.vpcf", PATTACH_CUSTOMORIGIN, Caster)
    ParticleManager:SetParticleControl(effectIndex, 0, Caster:GetOrigin())
    ParticleManager:DestroyParticleSystemTime(effectIndex, 1)
end

function OnRemilia03Think(keys)
    local Ability = keys.ability
    local Caster = keys.caster
    local Targets = keys.target_entities
    local Damage = keys.DamagePerSec * 0.2

    for _, unit in pairs(Targets) do
        if unit and unit:IsAlive() then
            UnitDamageTarget {
                ability = keys.ability,
                victim = unit,
                attacker = Caster,
                damage = Damage,
                damage_type = keys.ability:GetAbilityDamageType()
            }
        end
    end
end

function OnRemilia04Start(keys)
    local Caster = keys.caster
    local effectIndex = ParticleManager:CreateParticle("particles/heroes/remilia/ability_remilia_04_laser.vpcf",
        PATTACH_CUSTOMORIGIN, Caster)
    ParticleManager:SetParticleControl(effectIndex, 0, Caster:GetOrigin() + Vector(0, 0, 32))
    ParticleManager:SetParticleControl(effectIndex, 1, Caster:GetOrigin() + Vector(0, -500, 128))
    ParticleManager:SetParticleControl(effectIndex, 2, Caster:GetOrigin() + Vector(0, 500, 128))
    ParticleManager:SetParticleControl(effectIndex, 3, Caster:GetOrigin() + Vector(-500, 0, 128))
    ParticleManager:SetParticleControl(effectIndex, 4, Caster:GetOrigin() + Vector(500, 0, 128))
    Caster.ability_remilia_04_effectIndex = effectIndex
    local effectIndexSmoke = ParticleManager:CreateParticle(
        "particles/heroes/remilia/ability_remilia_04_laser_rocket.vpcf", PATTACH_CUSTOMORIGIN, Caster)
    ParticleManager:SetParticleControlEnt(effectIndexSmoke, 0, Caster, 5, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControl(effectIndexSmoke, 1, Vector(math.cos(math.pi / 2), math.sin(math.pi / 2), 0))
    ParticleManager:SetParticleControl(effectIndexSmoke, 2, Vector(math.cos(math.pi), math.sin(math.pi), 0))
    ParticleManager:SetParticleControl(effectIndexSmoke, 3,
        Vector(math.cos(math.pi * 3 / 2), math.sin(math.pi * 3 / 2), 0))
    ParticleManager:SetParticleControl(effectIndexSmoke, 4,
        Vector(math.cos(math.pi * 4 / 2), math.sin(math.pi * 4 / 2), 0))
    Caster.ability_remilia_04_effectIndexSmoke = effectIndexSmoke
    Caster:EmitSound("Hero_Phoenix.SunRay.Loop")
    Caster:EmitCasterSound("npc_dota_hero_warlock", {"thdots_remilia_ability04_01"}, 100,
        DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, 3, "remilia04")
end

function OnRemilia04Remove(keys)
    local Caster = keys.caster
    ParticleManager:DestroyParticleSystem(Caster.ability_remilia_04_effectIndex, true)
    ParticleManager:DestroyParticleSystem(Caster.ability_remilia_04_effectIndexSmoke, true)
    Caster:StopSound("Hero_Phoenix.SunRay.Loop")
end

function OnRemilia04Think(keys)
    local Caster = keys.caster
    local Ability = keys.ability
    local CrossRadius = keys.CrossRadius
    local CrossWidth = keys.CrossWidth / 2
    local Damage = keys.DamagePerSec * 0.5 / 10
    local ManaCost = keys.ManaCostPerSec * 0.5 / 10
    local LifestealPercent = keys.LifestealPercent * 0.01

    if Caster:GetMana() < ManaCost then
        if Ability:GetToggleState() then
            Ability:ToggleAbility()
        end
        if Caster:HasModifier("modifier_thdots_Remilia04_think_interval") then
            Caster:RemoveModifierByName("modifier_thdots_Remilia04_think_interval")
            ParticleManager:DestroyParticleSystem(Caster.ability_remilia_04_effectIndex, true)
        end
        return
    end
    Caster:SpendMana(ManaCost, Ability)

    ParticleManager:SetParticleControl(Caster.ability_remilia_04_effectIndex, 0, Caster:GetOrigin() + Vector(0, 0, 32))
    ParticleManager:SetParticleControl(Caster.ability_remilia_04_effectIndex, 1,
        Caster:GetOrigin() + Vector(0, -500, 128))
    ParticleManager:SetParticleControl(Caster.ability_remilia_04_effectIndex, 2,
        Caster:GetOrigin() + Vector(0, 500, 128))
    ParticleManager:SetParticleControl(Caster.ability_remilia_04_effectIndex, 3,
        Caster:GetOrigin() + Vector(-500, 0, 128))
    ParticleManager:SetParticleControl(Caster.ability_remilia_04_effectIndex, 4,
        Caster:GetOrigin() + Vector(500, 0, 128))

    local CasterPos = Caster:GetAbsOrigin()
    local targets = FindUnitsInRadius(Caster:GetTeam(), Caster:GetOrigin(), nil, CrossRadius,
        Ability:GetAbilityTargetTeam(), Ability:GetAbilityTargetType(), Ability:GetAbilityTargetFlags(), FIND_ANY_ORDER,
        false)

    local DamageAmount = 0
    for _, unit in pairs(targets) do
        if unit and not unit:IsNull() and unit:IsAlive() then
            if (math.abs(unit:GetAbsOrigin().x - CasterPos.x) <= CrossWidth) or
                (math.abs(unit:GetAbsOrigin().y - CasterPos.y) <= CrossWidth) then
                local DamageDone = UnitDamageTarget {
                    ability = keys.ability,
                    victim = unit,
                    attacker = Caster,
                    damage = Damage,
                    damage_type = keys.ability:GetAbilityDamageType()
                }
                if DamageDone and DamageDone > 0 then
                    DamageAmount = DamageAmount + DamageDone
                end
            end
        end
    end

    Caster:Heal(DamageAmount * LifestealPercent, Caster)
end

modifier_remiliapraticlechange = {}
LinkLuaModifier("modifier_remiliapraticlechange", "scripts/vscripts/abilities/abilityRemilia.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_remiliapraticlechange:IsHidden()
    return true
end
function modifier_remiliapraticlechange:IsDebuff()
    return false
end
function modifier_remiliapraticlechange:IsPurgable()
    return false
end
function modifier_remiliapraticlechange:RemoveOnDeath()
    return false
end

ability_thdots_remilia_shard = {}
function ability_thdots_remilia_shard:GetCastRange(location, target)
    if IsServer() then
        return 0
    end
    return self.BaseClass.GetCastRange(self, location, target)
end
function ability_thdots_remilia_shard:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function ability_thdots_remilia_shard:OnSpellStart()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local targetPoint = self:GetCursorPosition()
    local radius = self:GetSpecialValueFor("radius")
    local casterpoint = caster:GetOrigin()
    local pointRad = GetRadBetweenTwoVec2D(casterpoint, targetPoint)
    local AbilityCastRange = self:GetSpecialValueFor("AbilityCastRange") + caster:GetCastRangeBonus()
    local knockback_duration = self:GetSpecialValueFor("knockback_duration")
    local knockback_distance = self:GetSpecialValueFor("knockback_distance")
    local knockback_height = self:GetSpecialValueFor("knockback_height")
    if (GetDistanceBetweenTwoVec2D(casterpoint, targetPoint) <= AbilityCastRange) then
        targetPoint = targetPoint
    else
        targetPoint = Vector(math.cos(pointRad) * radius, math.sin(pointRad) * radius, 0) + casterpoint
    end
    local heros = FindUnitsInRadius(caster:GetTeamNumber(), targetPoint, nil, radius, self:GetAbilityTargetTeam(),
        self:GetAbilityTargetType(), 0, 0, false)
    for _, v in pairs(heros) do
        v:AddNewModifier(caster, self, "modifier_ability_thdots_remilia_shard_knockback_both", {
            duration = knockback_duration
        })
        v:EmitSound("Hero_Tusk.WalrusPunch.Target")
        local damage_table = {
            victim = v,
            attacker = self:GetCaster(),
            damage = self:GetSpecialValueFor("bone_damage"),
            damage_type = self:GetAbilityDamageType(),
            damage_flags = self:GetAbilityTargetFlags(),
            ability = self
        }
        ApplyDamage(damage_table)
    end
    caster:EmitSound("Hero_Tusk.WalrusPunch.Damage")
    local particle = ParticleManager:CreateParticle(
        "particles/econ/items/axe/axe_helm_shoutmask/axe_beserkers_call_owner_shoutmask.vpcf", PATTACH_ABSORIGIN_FOLLOW,
        caster)
    ParticleManager:SetParticleControl(particle, 2, Vector(1, 1, 1))
    ParticleManager:ReleaseParticleIndex(particle)
end
LinkLuaModifier("modifier_ability_thdots_remilia_shard_knockback_both", "scripts/vscripts/abilities/abilityRemilia.lua",
    LUA_MODIFIER_MOTION_BOTH)
modifier_ability_thdots_remilia_shard_knockback_both = class({})
function modifier_ability_thdots_remilia_shard_knockback_both:IsHidden()
    return false
end
function modifier_ability_thdots_remilia_shard_knockback_both:IsPurgable()
    return true
end
function modifier_ability_thdots_remilia_shard_knockback_both:IsStunDebuff()
    return true
end
function modifier_ability_thdots_remilia_shard_knockback_both:IsDebuff()
    return true
end
function modifier_ability_thdots_remilia_shard_knockback_both:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_remilia_shard_knockback_both:DeclareFunctions()
    local funcs = {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE}
    return funcs
end
function modifier_ability_thdots_remilia_shard_knockback_both:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end
function modifier_ability_thdots_remilia_shard_knockback_both:GetOverrideAnimation()
    return ACT_DOTA_FLAIL
end
function modifier_ability_thdots_remilia_shard_knockback_both:GetOverrideAnimationRate()
    return 0.1
end

function modifier_ability_thdots_remilia_shard_knockback_both:OnCreated()
    if not IsServer() then
        return
    end
    self.ability = self:GetAbility()
    self.GetCursorPosition = self:GetAbility():GetCursorPosition()
    self.caster = self:GetAbility():GetCaster()
    self.x = self.ability:GetCaster():GetAbsOrigin().x
    self.y = self.ability:GetCaster():GetAbsOrigin().y
    self.z = self.ability:GetCaster():GetAbsOrigin().z
    self.parent = self:GetParent()
    self.stun_duration = self.ability:GetSpecialValueFor("stun_duration")
    self.knockback_distance = self.ability:GetSpecialValueFor("knockback_distance")
    self.knockback_duration = self.ability:GetSpecialValueFor("knockback_duration")
    self.knockback_height = self.ability:GetSpecialValueFor("knockback_height")
    self.knockback_speed = self.knockback_distance / self.knockback_duration
    local half_duration = self.knockback_duration / 2
    self.gravity = 2 * self.knockback_height / (half_duration * half_duration)
    self.vVelocity = self.gravity * half_duration
    self.position = Vector(self.x, self.y, self.z)
    -- apply motion controllers
    if self.knockback_distance > 0 then
        if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
            return
        end
    end
    if self.knockback_height >= 0 then
        if self:ApplyVerticalMotionController() == false then
            self:Destroy()
            return
        end
    end
    -- print(self.knockback_height)
    self:StartIntervalThink(0.2)
end
function modifier_ability_thdots_remilia_shard_knockback_both:OnIntervalThink()
    if not IsServer() then
        return
    end
    GridNav:DestroyTreesAroundPoint(self.parent:GetOrigin(), 100, true)
end
function modifier_ability_thdots_remilia_shard_knockback_both:UpdateHorizontalMotion(me, dt)
    local distance = (self.GetCursorPosition - self.position):Normalized()
    if not me:HasModifier("modifier_thdots_yugi04_think_interval") then
        me:SetOrigin(me:GetOrigin() + distance * self.knockback_speed * dt)
    end
end

function modifier_ability_thdots_remilia_shard_knockback_both:UpdateVerticalMotion(me, dt)
    local time = dt / self.knockback_duration
    self.parent:SetOrigin(self.parent:GetOrigin() + Vector(0, 0, self.vVelocity * dt))
    self.vVelocity = self.vVelocity - self.gravity * dt
end
function modifier_ability_thdots_remilia_shard_knockback_both:OnDestroy()
    if not IsServer() then
        return
    end
    GridNav:DestroyTreesAroundPoint(self.parent:GetOrigin(), 100, true)
    self.parent:FadeGesture(ACT_DOTA_FLAIL)
    self.parent:RemoveHorizontalMotionController(self)
    self.parent:RemoveVerticalMotionController(self)
    FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false)
    self.parent:AddNewModifier(self.caster, self.ability, "modifier_ability_thdots_remilia_shard_knockback_both_speed",
        {
            duration = self.ability:GetSpecialValueFor("speed_duration") * (1 - self.parent:GetStatusResistance())
        })
    self.parent:EmitSound("Hero_EarthSpirit.BoulderSmash.Silence")
end
LinkLuaModifier("modifier_ability_thdots_remilia_shard_knockback_both_speed",
    "scripts/vscripts/abilities/abilityRemilia.lua", LUA_MODIFIER_MOTION_NONE)
modifier_ability_thdots_remilia_shard_knockback_both_speed = class({})
function modifier_ability_thdots_remilia_shard_knockback_both_speed:IsHidden()
    return false
end
function modifier_ability_thdots_remilia_shard_knockback_both_speed:IsPurgable()
    return true
end
function modifier_ability_thdots_remilia_shard_knockback_both_speed:IsDebuff()
    return true
end
function modifier_ability_thdots_remilia_shard_knockback_both_speed:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_remilia_shard_knockback_both_speed:DeclareFunctions()
    local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
    return funcs
end
function modifier_ability_thdots_remilia_shard_knockback_both_speed:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("move_speed")
end
