----------------------------------------------------------------------------------------------
-- Global
if AbilityReimu == nil then
    AbilityReimu = class({})
end

-- 灵梦技能伤害处理
function AbilityReimu:ReimuSpellDamageTarget(damageTable)
    self:DamageConvertType(damageTable)
    self:ExSpellAppliedTarget(damageTable.attacker)
end

-- 三技能：伤害转纯粹
function AbilityReimu:DamageConvertType(damageTable)
    if damageTable.victim:HasModifier("modifier_ability_dota2x_reimu03_enemy") then
        damageTable.damage_type = DAMAGE_TYPE_PURE
    end
    UnitDamageTarget(damageTable)
end

-- 天生被动：当技能击中目标时触发
function AbilityReimu:ExSpellAppliedTarget(caster)
    local reimuEx = caster:FindAbilityByName("ability_dota2x_reimuEx")
    if caster:HasAbility("ability_dota2x_reimuEx") and not reimuEx:IsHidden() then
        reimuEx:OnSpellAppliedTarget()
    end
end

-- Global End
----------------------------------------------------------------------------------------------
-- Reimu01

function OnReimu01SpellStart(keys)
    local caster = keys.caster
    local ability = keys.ability
    local targetPosition = keys.ability:GetCursorPosition()

    local unit = CreateUnitByName("npc_dota2x_unit_reimu_dummy_unit", targetPosition, false, caster, caster,
        caster:GetTeamNumber())
    unit:FindAbilityByName("ability_dummy_unit"):SetLevel(1)
    ability:ApplyDataDrivenModifier(caster, unit, "modifier_thdots_reimu01_ball", {})
end

function OnReimu01BollCreated(keys)
    local caster = keys.caster
    local ability = keys.ability
    local unit = keys.target

    unit.targetPosition = unit:GetOrigin()
    unit.radius = keys.radius
    unit.bounce_time = keys.bounce_time
    unit.first_damage = keys.first_damage
    unit.stun_duration = keys.stun_duration
    unit.damage_follow_pct = keys.damage_follow_pct * 0.01

    -- Ball parameters
    unit.ballParam = {
        gravity = 150, -- 重力加速度
        interval = 0.04, -- 时基
        startHeight = 680, -- 初始高度
        bounceHeight = 80, -- 弹跳平面高度
        bounceFactor = 0.8, -- 初次触底回弹速度系数
        bounceFactorFollow = 0.9 -- 后续触底回弹速度系数
    }

    -- Ball object
    unit.ballObj = {
        position = unit.targetPosition + Vector(0, 0, unit.ballParam.startHeight), -- 当前位置
        gravity = unit.ballParam.gravity * unit.ballParam.interval, -- 重力加速度
        time = 0, -- 碰撞次数
        velocity = 0 -- 垂直速度
    }

    -- Ball particle
    unit.fireIndex = ParticleManager:CreateParticle("particles/heroes/reimu/reimu_01_effect_fire.vpcf",
        PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(unit.fireIndex, 0, unit.ballObj.position)
    unit.ballIndex = ParticleManager:CreateParticle("particles/thd2/heroes/reimu/reimu_01_effect_b.vpcf",
        PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(unit.ballIndex, 0, unit.ballObj.position)
    ParticleManager:SetParticleControl(unit.ballIndex, 1, Vector(unit.radius * 0.035, 0, 0))
    ParticleManager:SetParticleControl(unit.ballIndex, 3, unit.ballObj.position)
end

function OnReimu01BollIntervalThink(keys)
    local caster = keys.caster
    local ability = keys.ability
    local unit = keys.target

    -- Fall
    unit.ballObj.velocity = unit.ballObj.velocity + unit.ballObj.gravity
    unit.ballObj.position.z = unit.ballObj.position.z - unit.ballObj.velocity
    ParticleManager:SetParticleControl(unit.fireIndex, 0, unit.ballObj.position)
    ParticleManager:SetParticleControl(unit.ballIndex, 0, unit.ballObj.position)
    ParticleManager:SetParticleControl(unit.ballIndex, 3, unit.ballObj.position)

    -- Collision detection
    if unit.ballObj.position.z <= unit.targetPosition.z + unit.ballParam.bounceHeight then
        -- Collision object
        if unit.ballObj.time == 0 then
            unit.ballObj.velocity = -unit.ballObj.velocity * unit.ballParam.bounceFactor
        else
            unit.ballObj.velocity = -unit.ballObj.velocity * unit.ballParam.bounceFactorFollow
        end
        unit.ballObj.position.z = unit.targetPosition.z + unit.ballParam.bounceHeight + 0.1

        -- Caculate effect
        local damage = unit.first_damage * (1 - unit.damage_follow_pct * unit.ballObj.time)

        -- Find target
        local targets = FindUnitsInRadius(caster:GetTeamNumber(), unit.ballObj.position, nil, unit.radius,
            ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,
            false)

        -- Apply target effect
        for _, target in pairs(targets) do
            -- Apply damage
            local damageTable = {
                ability = ability,
                victim = target,
                attacker = caster,
                damage = damage,
                damage_type = ability:GetAbilityDamageType()
            }
            AbilityReimu:ReimuSpellDamageTarget(damageTable)
            -- Apply stun
            UtilStun:UnitStunTarget(caster, target, unit.stun_duration)
        end

        -- Collision sound
        StartSoundEventFromPosition("Visage_Familar.StoneForm.Cast", unit.ballObj.position)

        -- Collision particle
        local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/reimu/reimu_01_effect.vpcf",
            PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(effectIndex, 0, unit.ballObj.position)
        ParticleManager:SetParticleControl(effectIndex, 2, unit.ballObj.position)
        ParticleManager:SetParticleControl(effectIndex, 5, Vector(unit.radius - 25, 0, 0))
        ParticleManager:DestroyParticle(effectIndex, false)

        -- Collision time
        unit.ballObj.time = unit.ballObj.time + 1
        if unit.ballObj.time >= unit.bounce_time then
            unit:RemoveModifierByName("modifier_thdots_reimu01_ball")
        end
    end
end

function OnReimu01BollDestroy(keys)
    if keys.target and not keys.target:IsNull() then
        local unit = keys.target

        if unit.fireIndex then
            ParticleManager:DestroyParticle(unit.fireIndex, true)
        end
        if unit.ballIndex then
            ParticleManager:DestroyParticle(unit.ballIndex, true)
        end

        keys.target:Destroy()
    end
end

-- Reimu01 End
----------------------------------------------------------------------------------------------
-- Reimu02

-- Ability Initialization
ability_dota2x_reimu02 = class({})

-- Modifiers
modifier_thdots_reimu02_shot = class({})
LinkLuaModifier("modifier_thdots_reimu02_shot", "scripts/vscripts/abilities/abilityreimu.lua", LUA_MODIFIER_MOTION_NONE)

-- Ability Basic Parameter
function ability_dota2x_reimu02:GetCastRange()
    return self:GetSpecialValueFor("follow_radius")
end

-- Ability Script
function ability_dota2x_reimu02:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()

    local num = self:GetLevelSpecialValueFor("number", self:GetLevel() - 1)

    local position = caster:GetOrigin()
    local rad = RandomFloat(-math.pi, math.pi)
    local direction = Vector(math.cos(rad), math.sin(rad), 0)

    -- Generate position offset Angle
    local qangle = QAngle(0, 360 / num, 0)

    for i = 1, num do
        -- Generate unit
        local dummy = CreateUnitByName("npc_dota2x_unit_reimu02_light", position, false, caster, caster,
            caster:GetTeamNumber())
        dummy:SetForwardVector(direction)
        dummy:FindAbilityByName("ability_reimu02_dummy_unit"):SetLevel(1)
        dummy:AddNewModifier(caster, self, "modifier_thdots_reimu02_shot", {
            duration = self:GetSpecialValueFor("duration"),
            direction_x = direction.x,
            direction_y = direction.y
        })

        -- Offset position
        direction = RotatePosition(Vector(0, 0, 0), qangle, direction)
    end
end

-- Modifier Basic Parameter
function modifier_thdots_reimu02_shot:IsHidden()
    return true
end
function modifier_thdots_reimu02_shot:IsDebuff()
    return false
end
function modifier_thdots_reimu02_shot:IsPurgable()
    return false
end
function modifier_thdots_reimu02_shot:RemoveOnDeath()
    return true
end

function modifier_thdots_reimu02_shot:OnCreated(params)
    if not IsServer() then
        return
    end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()

    self.damage = self.ability:GetSpecialValueFor("damage")
    self.damageRadius = self.ability:GetSpecialValueFor("damage_radius")
    self.followRadius = self.ability:GetSpecialValueFor("follow_radius")

    self.initSpeed = self.ability:GetSpecialValueFor("init_speed")
    self.lockInitSpeedAcc = self.ability:GetSpecialValueFor("lock_init_speed_acc")
    self.unlockInitSpeedAcc = self.ability:GetSpecialValueFor("unlock_init_speed_acc")
    self.centriSpeedAcc = self.ability:GetSpecialValueFor("centri_speed_acc")

    -- self.followRadius = 650
    -- self.initSpeed = 1600
    -- self.lockInitSpeedAcc = 3200
    -- self.unlockInitSpeedAcc = 3000
    -- self.centriSpeedAcc = 3000

    self.centriSpeed = 0

    self.locked = false
    self.position = self.parent:GetOrigin() + Vector(0, 0, self.ability:GetSpecialValueFor("height"))
    self.startPosition = self.parent:GetOrigin()
    self.targetPosition = self.parent:GetOrigin()
    self.lockedTarget = nil
    self.initialDiretion = Vector(params.direction_x, params.direction_y, 0)
    self.centriDirection = Vector(params.direction_x, params.direction_y, 0)

    self.damaged = false
    self.interval = FrameTime()
    self:StartIntervalThink(self.interval)
end

function modifier_thdots_reimu02_shot:OnIntervalThink()
    if not IsServer() then
        return
    end

    -- 弹体/施法来源可能已被清理，停止thinker而不是继续调用失效实体。
    if self.parent == nil or not IsValidEntity(self.parent)
        or self.caster == nil or not IsValidEntity(self.caster)
        or self.ability == nil or not IsValidEntity(self.ability) then
        self:StartIntervalThink(-1)
        self:Destroy()
        return
    end
    if self.damaged == true then
        return
    end

    -- Damage target detection
    local targets = FindUnitsInRadius(self.caster:GetTeamNumber(), self.position, nil, self.damageRadius,
        self.ability:GetAbilityTargetTeam(), self.ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER, false)
    -- Apply damage
    for _, target in pairs(targets) do
        local damageTable = {
            ability = self.ability,
            victim = target,
            attacker = self.caster,
            damage = self.damage,
            damage_type = self.ability:GetAbilityDamageType()
        }
        AbilityReimu:ReimuSpellDamageTarget(damageTable)

        target:EmitSound("Hero_Wisp.Spirits.Target")

        self.damaged = true
        self:StartIntervalThink(-1)
        self:Destroy()
        return
    end

    -- Seek and mobile
    targets = FindUnitsInRadius(self.caster:GetTeamNumber(), self.position, nil, self.followRadius,
        self.ability:GetAbilityTargetTeam(), self.ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #targets > 0 then
        local target = targets[1]
        self.locked = true
        self.lockedTaget = target
        self.targetPosition = target:GetOrigin()
    end

    -- Determine the centripetal direction
    if self.locked then
        -- Track the target if it exists
        if self.lockedTaget ~= nil and not self.lockedTaget:IsNull() then
            self.targetPosition = self.lockedTaget:GetOrigin()
        end
        self.centriDirection = (self.targetPosition - self.position):Normalized()
    end

    -- Calculate the velocity vector
    if self.initSpeed > 0 then
        if self.locked then
            self.initSpeed = self.initSpeed - self.lockInitSpeedAcc * self.interval
        else
            self.initSpeed = self.initSpeed - self.unlockInitSpeedAcc * self.interval
        end
    else
        self.initSpeed = 0
        -- Reduce initial speed to zero and destroy before the enemy is captured
        if not self.locked then
            self:Destroy()
            return
        end
    end
    if self.locked then
        self.centriSpeed = self.centriSpeed + self.centriSpeedAcc * self.interval
    end
    local velocity = (self.initSpeed * self.initialDiretion + self.centriSpeed * self.centriDirection)

    -- Change the position
    self.position = self.position + velocity * self.interval
    -- self.parent:SetForwardVector(velocity:Normalized())
    self.parent:SetOrigin(self.position)

    -- Destroy when you reach the enemy position
    if self.locked and GetDistanceBetweenTwoVec2D(self.targetPosition, self.position) <= self.damageRadius / 2 then
        self:Destroy()
    end
end

function modifier_thdots_reimu02_shot:OnDestroy()
    if not IsServer() then
        return
    end

    local parent = self.parent
    self.parent = nil
    if parent ~= nil and IsValidEntity(parent) then
        parent:Destroy()
    end
end

-- Reimu02 End
----------------------------------------------------------------------------------------------
-- Reimu03

ability_dota2x_reimu03 = {}

function ability_dota2x_reimu03:GetBehavior()
    if self:GetCaster():HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
    else
        return self.BaseClass.GetBehavior(self)
    end
end

function ability_dota2x_reimu03:GetAOERadius()
    if not self:GetCaster():HasScepter() then
        return 0
    else
        return self:GetSpecialValueFor("scepter_radius")
    end
end

function ability_dota2x_reimu03:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local scepter_radius = self:GetSpecialValueFor("scepter_radius")
    local duration = self:GetSpecialValueFor("duration")
    if not caster:HasScepter() then
        local target = self:GetCursorTarget()

        if is_spell_blocked(target, caster) then
            return
        end

        if caster:GetTeamNumber() == target:GetTeamNumber() then
            target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_ally", {
                duration = duration
            })
            -- target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_immue", {duration = duration})

            -- if caster:HasScepter() then
            --     target:Purge(false,true,false,true,false)
            -- end
        else
            target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_enemy", {
                duration = duration
            })
            -- target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_silence", {duration = duration})
            -- if caster:HasScepter() then
            --     ability:ApplyDataDrivenModifier(caster, target, "modifier_ability_dota2x_reimu03_passives_disabled", {})
            --     ability:ApplyDataDrivenModifier(caster, target, "modifier_ability_dota2x_reimu03_slowdown", {})
            -- end
        end

        target:EmitSound("Hero_WitchDoctor.Voodoo_Restoration")

    else
        -- 万宝槌
        local target_point = self:GetCursorPosition()
        local targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, scepter_radius,
            self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), 0, 0, false)

        for i, target in pairs(targets) do
            if caster:GetTeamNumber() == target:GetTeamNumber() then
                target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_ally", {
                    duration = duration
                })
                -- target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_immue", {duration = duration})

                -- if caster:HasScepter() then
                --     target:Purge(false,true,false,true,false)
                -- end
            else
                target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_enemy", {
                    duration = duration
                })
                -- target:AddNewModifier(caster, self, "modifier_ability_dota2x_reimu03_silence", {duration = duration})
                -- if caster:HasScepter() then
                --     ability:ApplyDataDrivenModifier(caster, target, "modifier_ability_dota2x_reimu03_passives_disabled", {})
                --     ability:ApplyDataDrivenModifier(caster, target, "modifier_ability_dota2x_reimu03_slowdown", {})
                -- end
            end

            target:EmitSound("Hero_WitchDoctor.Voodoo_Restoration")

        end
    end
end

modifier_ability_dota2x_reimu03_ally = {}
LinkLuaModifier("modifier_ability_dota2x_reimu03_ally", "scripts/vscripts/abilities/abilityreimu.lua",
    LUA_MODIFIER_MOTION_NONE)

function modifier_ability_dota2x_reimu03_ally:IsHidden()
    return false
end
function modifier_ability_dota2x_reimu03_ally:IsPurgable()
    return true
end
function modifier_ability_dota2x_reimu03_ally:RemoveOnDeath()
    return true
end
function modifier_ability_dota2x_reimu03_ally:IsDebuff()
    return false
end
function modifier_ability_dota2x_reimu03_ally:GetEffectName()
    return "particles/thd2/heroes/reimu/reimu_03_effect.vpcf"
end
function modifier_ability_dota2x_reimu03_ally:GetEffectAttachType()
    return PATTACH_POINT_FOLLOW
end

function modifier_ability_dota2x_reimu03_ally:DeclareFunctions()
    return {MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL}
end

function modifier_ability_dota2x_reimu03_ally:GetAbsoluteNoDamagePhysical()
    return 1
end

modifier_ability_dota2x_reimu03_enemy = {}
LinkLuaModifier("modifier_ability_dota2x_reimu03_enemy", "scripts/vscripts/abilities/abilityreimu.lua",
    LUA_MODIFIER_MOTION_NONE)

function modifier_ability_dota2x_reimu03_enemy:IsHidden()
    return false
end
function modifier_ability_dota2x_reimu03_enemy:IsPurgable()
    return true
end
function modifier_ability_dota2x_reimu03_enemy:RemoveOnDeath()
    return true
end
function modifier_ability_dota2x_reimu03_enemy:IsDebuff()
    return true
end
function modifier_ability_dota2x_reimu03_enemy:GetEffectName()
    return "particles/thd2/heroes/reimu/reimu_03_effect.vpcf"
end
function modifier_ability_dota2x_reimu03_enemy:GetEffectAttachType()
    return PATTACH_POINT_FOLLOW
end

function modifier_ability_dota2x_reimu03_enemy:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

-- Reimu03 End
----------------------------------------------------------------------------------------------
-- Reimu04

function OnReimu04SpellStart(keys)
    local caster = keys.caster
    local ability = keys.ability

    local unit = CreateUnitByName("npc_dota2x_unit_reimu_dummy_unit", caster:GetOrigin(), false, caster, caster,
        caster:GetTeamNumber())
    unit:FindAbilityByName("ability_dummy_unit"):SetLevel(1)
    ability:ApplyDataDrivenModifier(caster, unit, "modifier_ability_dota2x_reimu04_circle", {})
end

function OnReimu04CircleThinkInterval(keys)
    local caster = keys.caster
    local ability = keys.ability
    local unit = keys.target

    local targets = keys.target_entities
    local telent01 = keys.telent01
    local remain_time = unit:FindModifierByName("modifier_ability_dota2x_reimu04_circle"):GetRemainingTime()

    -- 防止在持续时间结束后仍被执行
    local duration = remain_time + 0.5

    for _, target in ipairs(targets) do
        if not target:HasModifier("modifier_ability_dota2x_reimu04_damage") then
            ability:ApplyDataDrivenModifier(caster, target, "modifier_ability_dota2x_reimu04_damage", {
                duration = duration
            })
        end
        if telent01 > 0 and not target:HasModifier("modifier_ability_dota2x_reimu04_root") then
            ability:ApplyDataDrivenModifier(caster, target, "modifier_ability_dota2x_reimu04_root", {
                duration = duration
            })
        end
    end
end

function OnReimu04CircleDestroy(keys)
    if keys.target and not keys.target:IsNull() then
        keys.target:Destroy()
    end
end

function OnReimu04Damage(keys)
    local caster = keys.caster
    local ability = keys.ability
    local target = keys.target

    local stun_duration = keys.stun_duration
    local damage = keys.damage
    local damage_count = keys.damage_count

    local modifier = target:FindModifierByName("modifier_ability_dota2x_reimu04_damage")
    if modifier:GetStackCount() == nil then
        modifier:SetStackCount(0)
    end
    if modifier:GetStackCount() < damage_count then
        local damageTable = {
            ability = ability,
            victim = target,
            attacker = caster,
            damage = damage,
            damage_type = ability:GetAbilityDamageType()
        }
        AbilityReimu:ReimuSpellDamageTarget(damageTable)
        UtilStun:UnitStunTarget(caster, target, stun_duration)
        modifier:IncrementStackCount()
    end
end

-- Reimu04 End
----------------------------------------------------------------------------------------------
-- ReimuEx

-- Ability Initialization
ability_dota2x_reimuEx = {}

-- Ability Basic Parameter
-- function ability_dota2x_reimuEx:GetIntrinsicModifierName()
--     return "modifier_ability_dota2x_reimuEx_buff"
-- end

-- 自定义接口：当技能命中目标时层数增加
-- function ability_dota2x_reimuEx:InnateAbilityType() return 2 end
function ability_dota2x_reimuEx:OnSpellAppliedTarget()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    if caster:IsNull() or not caster:IsAlive() or not caster:IsRealHero() then
        return
    end

    local stack_count = caster:GetModifierStackCount("modifier_ability_dota2x_reimuEx_buff", caster)
    local modifier
    if caster:HasModifier("modifier_ability_dota2x_reimuEx_buff") then
        modifier = caster:FindModifierByName("modifier_ability_dota2x_reimuEx_buff")
        if stack_count < 20 then
            modifier:IncrementStackCount()
        end
        modifier:SetDuration(self:GetSpecialValueFor("duration"), true)
    else
        modifier = caster:AddNewModifier(caster, self, "modifier_ability_dota2x_reimuEx_buff", {
            duration = self:GetSpecialValueFor("duration")
        })
        modifier:SetStackCount(1)
    end
end
--[[
function ability_dota2x_reimuEx:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE
	else
		return self.BaseClass.GetBehavior(self)
	end
end
--]]

-- Modifiers
modifier_ability_dota2x_reimuEx_buff = {}
LinkLuaModifier("modifier_ability_dota2x_reimuEx_buff", "scripts/vscripts/abilities/abilityReimu.lua",
    LUA_MODIFIER_MOTION_NONE)

-- Modifier Basic Parameter
function modifier_ability_dota2x_reimuEx_buff:IsHidden()
    return false
end
function modifier_ability_dota2x_reimuEx_buff:IsPurgable()
    return false
end
function modifier_ability_dota2x_reimuEx_buff:RemoveOnDeath()
    return true
end
function modifier_ability_dota2x_reimuEx_buff:IsDebuff()
    return false
end

-- Modifier Script
function modifier_ability_dota2x_reimuEx_buff:OnCreated()
    -- if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
end

-- Modifier Functions
function modifier_ability_dota2x_reimuEx_buff:DeclareFunctions()
    return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT}
end

-- 攻速增益
function modifier_ability_dota2x_reimuEx_buff:GetModifierAttackSpeedBonus_Constant()
    if self.ability == nil then
        self.ability = self:GetAbility()
    end
    local stack_count = self:GetStackCount()
    if stack_count == nil then
        stack_count = 0
    end
    if self.caster:HasModifier("modifier_ability_dota2ex_reimuex_buff_the_most_strong") then
        return 0
    else
        return self.ability:GetSpecialValueFor("attack_speed_bonus") * stack_count
    end
end

-- 移速增益
function modifier_ability_dota2x_reimuEx_buff:GetModifierMoveSpeedBonus_Constant()
    if self.caster == nil then
        self.caster = self:GetCaster()
    end
    if self.ability == nil then
        self.ability = self:GetAbility()
    end
    local stack_count = self:GetStackCount()
    if stack_count == nil then
        stack_count = 0
    end
    if self.caster:HasModifier("modifier_ability_dota2ex_reimuex_buff_the_most_strong") then
        return 0
    else
        return self.ability:GetSpecialValueFor("move_speed_bonus") * stack_count
    end
end

-- 万宝槌效果
function ability_dota2x_reimuEx:OnSpellStart()
    self.caster = self:GetCaster()
    local caster = self.caster
    local a_stack_count = self.caster:GetModifierStackCount("modifier_ability_dota2x_reimuEx_buff", self.caster)
    if a_stack_count ~= 20 then
        self:EndCooldown()
        return
    else
        caster:AddNewModifier(caster, self, "modifier_ability_dota2ex_reimuex_buff_the_most_strong", {
            Duration = self:GetSpecialValueFor("duration")
        })
        caster:RemoveModifierByName("modifier_ability_dota2x_reimuEx_buff")

        caster:EmitSound("Hero_Lina.FlameCloak.Cast")

    end
end

modifier_ability_dota2ex_reimuex_buff_the_most_strong = {}
LinkLuaModifier("modifier_ability_dota2ex_reimuex_buff_the_most_strong", "scripts/vscripts/abilities/abilityReimu.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_dota2ex_reimuex_buff_the_most_strong:IsHidden()
    return false
end
function modifier_ability_dota2ex_reimuex_buff_the_most_strong:IsPurgable()
    return false
end
function modifier_ability_dota2ex_reimuex_buff_the_most_strong:RemoveOnDeath()
    return true
end
function modifier_ability_dota2ex_reimuex_buff_the_most_strong:IsDebuff()
    return false
end
function modifier_ability_dota2ex_reimuex_buff_the_most_strong:CheckState()
    return {
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end

function modifier_ability_dota2ex_reimuex_buff_the_most_strong:OnCreated()
    -- if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
end

-- Modifier Functions
function modifier_ability_dota2ex_reimuex_buff_the_most_strong:DeclareFunctions()
    return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE}
end

function modifier_ability_dota2ex_reimuex_buff_the_most_strong:GetModifierAttackSpeedBonus_Constant()
    return self.ability:GetSpecialValueFor("a_attack_speed_bonus")
end
function modifier_ability_dota2ex_reimuex_buff_the_most_strong:GetModifierMoveSpeedOverride()
    return self.ability:GetSpecialValueFor("a_move_speed_bonus")
end
--[[
----------万宝槌cd
function ability_dota2x_reimuEx:GetCooldown(iLevel)
    if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
        return self:GetSpecialValueFor("scepter_cd")
    end
    return self.BaseClass.GetCooldown(self, iLevel)
end
--]]
-- ReimuEx End
----------------------------------------------------------------------------------------------
