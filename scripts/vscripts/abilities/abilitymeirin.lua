-- MEIRIN04_CONTEXT = 0
-- SATORI_CONTEXT = 0
function OnMeirinexSpellThink(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local modifier = caster:FindModifierByName("modifier_thdots_meirinex_attack")
    local stackcount = keys.stackCount
    if modifier:GetStackCount() < stackcount then
        modifier:IncrementStackCount()
    end
end

function OnMeirinexDamage(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local modifier = caster:FindModifierByName("modifier_thdots_meirinex_attack")
    local stackcount = keys.stackCount

    local damagePct = ability:GetSpecialValueFor("damage_pct")
    local damagePctBonus = ability:GetSpecialValueFor("damage_pct_bonus")

    if target:GetTeam() ~= caster:GetTeam() then
        if caster:IsRealHero() and target:IsBuilding() == false and modifier:GetStackCount() > 0 and
            caster:HasModifier("modifier_meirinex") then
            -- local bonusAttack = 0 
            -- local attack = 0
            -- for i=0,5 do
            -- 	item = caster:GetItemInSlot(i)
            -- 	if(item~=nil)then
            -- 		bonusAttack = item:GetSpecialValueFor("bonus_damage")
            -- 		if(bonusAttack~=nil)then
            -- 			attack = bonusAttack + attack
            -- 		end
            -- 	end
            -- end 
            local Damage = caster:GetAverageTrueAttackDamage(caster) *
                               damagePct * 0.01
            local damage_table = {
                ability = keys.ability,
                victim = target,
                attacker = caster,
                damage = Damage,
                damage_type = DAMAGE_TYPE_PURE,
                damage_flags = 1
            }
            StartSoundEventFromPosition("Hero_Ancient_Apparition.ChillingTouch.Target", target:GetOrigin())
            UtilStun:UnitStunTarget(caster, target, 0.1, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilitymeirin.lua:OnMeirinexDamage:47")

            local effectIndex = ParticleManager:CreateParticle(
                "particles/units/heroes/hero_lich/lich_frost_nova_flash_b.vpcf", PATTACH_CUSTOMORIGIN, caster)
            ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
            ParticleManager:DestroyParticleSystem(effectIndex, false)
            -- SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,target,Damage,nil)
            modifier:DecrementStackCount()

            UnitDamageTarget(damage_table)
        end
    end
end

ability_thdots_meirin01 = {}
local MEIRIN01_INTERVAL = 0.03

function ability_thdots_meirin01:GetCastRange(location, target)
    if IsServer() then
        return 0
    end
end

function ability_thdots_meirin01:OnSpellStart()
    local caster = self:GetCaster()
    local range = self:GetLevelSpecialValueFor("range", self:GetLevel() - 1)
    local skewer_speed = self:GetLevelSpecialValueFor("skewer_speed", self:GetLevel() - 1)
    local targetPoint = self:GetCursorPosition()

    caster:EmitSound("Hero_Magnataur.Skewer.Cast")

    -- Distance and direction variables
    self.direction = (targetPoint - caster:GetAbsOrigin()):Normalized()
    local Meirin01dis = GetDistanceBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    -- If the caster targets over the max range, sets the distance to the max
    if Meirin01dis > range then
        Meirin01dis = range
    end

    -- Applies the disable modifier
    local move_duration = Meirin01dis / skewer_speed
    caster:AddNewModifier(caster, self, "modifier_thdots_meirin01_think_interval", {
        Duration = move_duration
    })
    caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1, 1.5)
end

modifier_thdots_meirin01_think_interval = {}
LinkLuaModifier("modifier_thdots_meirin01_think_interval", "scripts/vscripts/abilities/abilitymeirin.lua",
    LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meirin01_think_interval:IsHidden()
    return false
end
function modifier_thdots_meirin01_think_interval:IsPurgable()
    if self:GetParent() == self:GetCaster() then
        return false
    end
    if self:GetParent() ~= self:GetCaster() then
        return true
    end
end
function modifier_thdots_meirin01_think_interval:RemoveOnDeath()
    return true
end
function modifier_thdots_meirin01_think_interval:IsDebuff()
    if self:GetParent() == self:GetCaster() then
        return false
    end
    if self:GetParent() ~= self:GetCaster() then
        return true
    end
end
function modifier_thdots_meirin01_think_interval:GetEffectName()
    return "particles/units/heroes/hero_magnataur/magnataur_skewer.vpcf"
end
function modifier_thdots_meirin01_think_interval:GetEffectAttachType()
    return "follow_origin"
end
function modifier_thdots_meirin01_think_interval:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_thdots_meirin01_think_interval:OnCreated()
    if not IsServer() then
        return
    end
    self.meirin01time = self:GetDuration()
    self.interval = MEIRIN01_INTERVAL
    self.skewer_speed = self:GetAbility():GetLevelSpecialValueFor("skewer_speed", self:GetAbility():GetLevel() - 1)
    self.remaining_distance = self.skewer_speed * self.meirin01time
    self:StartIntervalThink(self.interval)
end

function modifier_thdots_meirin01_think_interval:OnDestroy()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local target = self:GetParent()
    local ability = self:GetAbility()
    target:SetUnitOnClearGround()
    if target ~= caster then
        local damage_table = {
            ability = ability,
            victim = target,
            attacker = caster,
            damage = ability:GetSpecialValueFor("skewer_damage"),
            damage_type = ability:GetAbilityDamageType(),
            damage_flags = 0
        }
        UnitDamageTarget(damage_table)
    end
end

function modifier_thdots_meirin01_think_interval:OnIntervalThink()
    local caster = self:GetCaster()
    local target = self:GetParent()
    local ability = self:GetAbility()
    self.meirin01time = self.meirin01time - self.interval
    local skewer_radius = ability:GetLevelSpecialValueFor("skewer_radius", ability:GetLevel() - 1)
    local hero_offset = ability:GetLevelSpecialValueFor("hero_offset", ability:GetLevel() - 1)
    local move_distance = math.min(self.skewer_speed * self.interval, self.remaining_distance)

    if target:HasModifier("modifier_ability_thdots_hina04") then -- 踢转转大招BUG
        target:RemoveModifierByName("modifier_thdots_meirin01_think_interval")
        return
    end

    if target == caster and self.meirin01time > 0 and move_distance > 0 then
        -- Units to be caught in the skewer
        -- local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, skewer_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
        -- local units = FindUnitsInLine(caster:GetTeamNumber(), caster:GetOrigin(), caster:GetAbsOrigin() + 10*ability.direction, nil, 125 , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, false)
        local scan_distance = move_distance + 10
        local units = FindUnitsInLine(caster:GetTeam(), caster:GetAbsOrigin(),
            caster:GetAbsOrigin() + scan_distance * ability.direction, nil, 75, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0)
        -- Loops through target
        for i, unit in ipairs(units) do
            -- Checks if the target is already affected by skewer
            if not unit:HasModifier("modifier_thdots_meirin01_think_interval") and
                not unit:HasModifier("modifier_item_dragon_star_buff") then
                -- If not, move it offset in front of the caster
                -- if (unit:GetOrigin() - caster:GetOrigin()):Length2D() < 200 then
                -- 	break
                -- end
                local new_position = caster:GetAbsOrigin() + hero_offset * ability.direction
                unit:SetAbsOrigin(new_position)
                -- Apply the motion controller to the target
                unit:AddNewModifier(caster, ability, "modifier_thdots_meirin01_think_interval", {
                    Duration = self.meirin01time
                })
            end
        end
    end

    local next_position = target:GetAbsOrigin() + ability.direction * move_distance
    local vec = Vector(next_position.x, next_position.y, GetGroundPosition(next_position, target).z)
    target:SetOrigin(vec)
    self.remaining_distance = self.remaining_distance - move_distance
    if (self.remaining_distance <= 0) then
        target:RemoveModifierByName("modifier_thdots_meirin01_think_interval")
    end
end

--[[function Skewer(keys)
	local caster = keys.caster
	local ability = keys.ability
	local skewer_speed =  ability:GetLevelSpecialValueFor("skewer_speed", ability:GetLevel() - 1)
	local range = ability:GetLevelSpecialValueFor("range", ability:GetLevel() - 1)
	local point = ability:GetCursorPosition()
	targetPoint = point
	-- Distance and direction variables
	local vector_distance = point - caster:GetAbsOrigin()
	local distance = (vector_distance):Length2D()
	local direction = (vector_distance):Normalized()
	-- If the caster targets over the max range, sets the distance to the max
	if distance > range then
		point = caster:GetAbsOrigin() + range * direction
		distance = range
	end
	
	-- Total distance to travel
	ability.distance = distance
	
	-- Distance traveled per interval
	ability.speed = skewer_speed/30
	
	-- The direction to travel
	ability.direction = direction
	
	-- Distance traveled so far
	ability.traveled_distance = 0
	
	-- Applies the disable modifier
	meirin01time = distance/900
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_skewer_disable_caster", {Duration = meirin01time})
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1,1.5)
end]]

function CheckTargets(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    meirin01time = meirin01time - 0.01
    local skewer_radius = ability:GetLevelSpecialValueFor("skewer_radius", ability:GetLevel() - 1)
    local hero_offset = ability:GetLevelSpecialValueFor("hero_offset", ability:GetLevel() - 1)

    -- Units to be caught in the skewer
    -- local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, skewer_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
    -- local units = FindUnitsInLine(caster:GetTeamNumber(), caster:GetOrigin(), caster:GetAbsOrigin() + 10*ability.direction, nil, 125 , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, false)
    local units = FindUnitsInLine(caster:GetTeam(), caster:GetAbsOrigin(),
        caster:GetAbsOrigin() + 10 * ability.direction, nil, 75, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0)
    -- Loops through target
    for i, unit in ipairs(units) do
        -- Checks if the target is already affected by skewer
        if not unit:HasModifier("modifier_skewer_disable_target") and
            not unit:HasModifier("modifier_item_dragon_star_buff") then
            -- If not, move it offset in front of the caster
            -- if (unit:GetOrigin() - caster:GetOrigin()):Length2D() < 200 then
            -- 	break 
            -- end
            local new_position = caster:GetAbsOrigin() + hero_offset * ability.direction
            unit:SetAbsOrigin(new_position)
            -- Apply the motion controller to the target
            ability:ApplyDataDrivenModifier(caster, unit, "modifier_skewer_disable_target", {
                Duration = meirin01time
            })
        end
    end
end

function SkewerMotion(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    -- Move the target while the distance traveled is less than the original distance upon cast
    if target:HasModifier("modifier_ability_thdots_hina04") then -- 踢转转大招BUG
        target:InterruptMotionControllers(true)
        target:RemoveModifierByName("modifier_skewer_disable_target")
    end
    if not caster:HasModifier("modifier_skewer_disable_caster") then
        target:InterruptMotionControllers(true)
        target:RemoveModifierByName("modifier_skewer_disable_target")
    end
    if ability.traveled_distance < ability.distance then
        target:SetAbsOrigin(target:GetAbsOrigin() + ability.direction * ability.speed)
        -- If the target is the caster, calculate the new travel distance
        if target == caster then
            ability.traveled_distance = ability.traveled_distance + ability.speed
        end
    else
        -- Remove the motion controller once the distance has been traveled
        target:InterruptMotionControllers(true)
        -- Remove the appropriate disable modifier from the target
        if target == caster then
            target:RemoveModifierByName("modifier_skewer_disable_caster")
        else
            target:RemoveModifierByName("modifier_skewer_disable_target")
        end
    end
end

function OnMeirin02Purge(keys)
    local ability = keys.ability
    local caster = keys.caster

    -- Purge(bool RemovePositiveBuffs, bool RemoveDebuffs, bool BuffsCreatedThisFrameOnly, bool RemoveStuns, bool RemoveExceptions) 
    caster:Purge(false, true, false, true, false)

end

function OnMeirin02Talent(keys)
    local ability = keys.ability
    local caster = keys.caster

    if FindTelentValue(caster, "special_bonus_unique_meirin_4") == 1 then
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_meirin02_buff_ex", {})
    end
    if caster:HasModifier("modifier_item_wanbaochui") then
        caster:RemoveModifierByName("modifier_meirin03_damage")
    end
end

function OnMeirin03PassiveIntervalThink(keys)
    keys.caster:AddNewModifier(keys.caster, keys.ability, "modifier_meirin03_block", {})
end

modifier_meirin03_block = {}
LinkLuaModifier("modifier_meirin03_block", "scripts/vscripts/abilities/abilitymeirin.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_meirin03_block:IsHidden()
    return true
end
function modifier_meirin03_block:IsPurgable()
    return false
end
function modifier_meirin03_block:RemoveOnDeath()
    return false
end
function modifier_meirin03_block:IsDebuff()
    return false
end

function modifier_meirin03_block:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK}
end

function modifier_meirin03_block:GetModifierTotal_ConstantBlock(kv)
    if not IsServer() then
        return
    end
    if bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
        return 0
    end
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_meirin03_damage") then
        return
    end
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local helixcd = ability:GetSpecialValueFor("cooldown")
    local helixcd_wbc = ability:GetSpecialValueFor("cooldown_wbc")
    local damage = ability:GetSpecialValueFor("damage") + FindTelentValue(caster, "special_bonus_unique_meirin_3")
    local block_damage = ability:GetSpecialValueFor("block_damage") +
                             FindTelentValue(caster, "special_bonus_unique_meirin_2")
    local rate = kv.damage / kv.original_damage
    if RollPercentage(ability:GetSpecialValueFor("chance")) then
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius,
            ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), 0, 0, false)
        for _, v in pairs(targets) do
            local damage_table = {
                ability = ability,
                victim = v,
                attacker = caster,
                damage = damage,
                damage_type = ability:GetAbilityDamageType()
            }
            UnitDamageTarget(damage_table)
        end
        if caster:HasModifier("modifier_item_wanbaochui") and caster:HasModifier("modifier_meirin02_buff") then
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_meirin03_damage", {
                Duration = helixcd_wbc
            })
        else
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_meirin03_damage", {
                Duration = helixcd
            })
        end
        return block_damage * rate
    else
        return
    end
end

----------------------------
function OnMeirin04Point(keys)
    -- body
    MEIRIN04_POINT = keys.ability:GetCursorPosition()
end

function OnMeirin04(keys)
    -- body
    local caster = keys.caster
    local vec = caster:GetForwardVector()
    local range = 150
    local ability = keys.ability
    local targetPoint = ability:GetCursorPosition()
    local radius = keys.radiu
    local targets = nil
    local stunduration = 1.7
    local time01 = 1.15
    local time02 = 2.52
    local time03 = 4.03
    local vector_distance = MEIRIN04_POINT - caster:GetAbsOrigin()
    if (ability:GetContext("ability_Meirin04_Count") == nil) then
        ability:SetContextNum("ability_Meirin04_Count", 0, 0)
    end
    count = ability:GetContext("ability_Meirin04_Count")

    if count == 0 then
        distance = (vector_distance):Length2D()
        caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4, 0.9)
        local effectIndex = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf", PATTACH_POINT, caster)
        ParticleManager:DestroyParticleSystem(effectIndex, false)
        local effectIndex = ParticleManager:CreateParticle(
            "particles/econ/items/sven/sven_warcry_ti5/sven_spell_warcry_ti_5.vpcf", PATTACH_POINT, caster)
        ParticleManager:DestroyParticleSystem(effectIndex, false)
    end
    count = count + 0.01
    ability:SetContextNum("ability_Meirin04_Count", count, 0)
    -- MEIRIN04_CONTEXT = MEIRIN04_CONTEXT + 0.01	
    if math.abs(count - time01) < 0.001 then
        targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, ability:GetAbilityTargetTeam(),
            ability:GetAbilityTargetType(), 0, 0, false)
        for _, v in pairs(targets) do
            if not v:IsBuilding() then
                local damage_table = {
                    ability = keys.ability,
                    victim = v,
                    attacker = caster,
                    damage = keys.damage01,
                    damage_type = keys.ability:GetAbilityDamageType()
                }
                keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_ability_thdots_meirin04_attack01", {
                    Duration = keys.slow_duration
                })
                UnitDamageTarget(damage_table)
            end
        end
        local effectIndex1 = ParticleManager:CreateParticle(
            "particles/econ/items/elder_titan/elder_titan_ti7/elder_titan_echo_stomp_ti7.vpcf", PATTACH_POINT, caster)
        ParticleManager:DestroyParticleSystem(effectIndex1, false)
        effectIndex1 = ParticleManager:CreateParticle(
            "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock_v2.vpcf", PATTACH_POINT,
            caster)
        ParticleManager:DestroyParticleSystem(effectIndex1, false)
        StartSoundEventFromPosition("Hero_ElderTitan.EchoStomp", caster:GetOrigin())
        StartSoundEventFromPosition("Hero_ElderTitan.EchoStomp", caster:GetOrigin())
        StartSoundEventFromPosition("Hero_ElderTitan.EchoStomp", caster:GetOrigin())
    end
    if math.abs(count - time02) < 0.001 then
        targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, ability:GetAbilityTargetTeam(),
            ability:GetAbilityTargetType(), 0, 0, false)
        for _, v in pairs(targets) do
            if not v:IsBuilding() then
                local damage_table = {
                    ability = keys.ability,
                    victim = v,
                    attacker = caster,
                    damage = keys.damage02,
                    damage_type = keys.ability:GetAbilityDamageType()
                }
                keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_ability_thdots_meirin04_attack02", {
                    Duration = keys.root_duration
                })
                UnitDamageTarget(damage_table)
            end
        end

        local effectIndex2 = ParticleManager:CreateParticle(
            "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock_v2.vpcf", PATTACH_POINT,
            caster)
        ParticleManager:DestroyParticleSystem(effectIndex2, false)
        StartSoundEventFromPosition("Hero_Sven.StormBoltImpact", caster:GetOrigin())
    end
    if count >= (time02 + 0.5) and count <= time03 then
        caster:SetOrigin(caster:GetAbsOrigin() + 2 * vec * (distance / (time03 - time02 + 0.5) / 100))
    end
    if math.abs(count - time03) < 0.001 then
        targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius + 500,
            ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), 0, 0, false)
        for _, v in pairs(targets) do
            if not v:IsBuilding() then
                local damage_table = {
                    ability = keys.ability,
                    victim = v,
                    attacker = caster,
                    damage = keys.damage03,
                    damage_type = keys.ability:GetAbilityDamageType()
                }
                keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_ability_thdots_meirin04_attack03", {
                    Duration = keys.stun_duration
                })
                UnitDamageTarget(damage_table)
            end
        end
        local effectIndex3 = ParticleManager:CreateParticle(
            "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_debut_ground.vpcf", PATTACH_POINT,
            caster)
        ParticleManager:DestroyParticleSystem(effectIndex3, false)
        effectIndex3 = ParticleManager:CreateParticle(
            "particles/econ/items/elder_titan/elder_titan_ti7/elder_titan_echo_stomp_ti7.vpcf", PATTACH_POINT, caster)
        ParticleManager:DestroyParticleSystem(effectIndex3, false)
        effectIndex3 = ParticleManager:CreateParticle(
            "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock_v2.vpcf", PATTACH_POINT,
            caster)
        ParticleManager:DestroyParticleSystem(effectIndex3, false)
        StartSoundEventFromPosition("Hero_Sven.StormBoltImpact", caster:GetOrigin())
        StartSoundEventFromPosition("Hero_Sven.StormBoltImpact", caster:GetOrigin())
    end
end

function OnMeirin04Destroy(keys)
    -- body
    local caster = keys.caster
    FindClearSpaceForUnit(caster, caster:GetAbsOrigin() + 1, true)
    -- MEIRIN04_CONTEXT = 0
    count = 0
    keys.ability:SetContextNum("ability_Meirin04_Count", count, 0)

end
