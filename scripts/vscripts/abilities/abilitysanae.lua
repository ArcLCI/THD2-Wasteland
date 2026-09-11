local CircleSource = require('util/skill_circle_source_debug')
----------------------------------------------------------------------------------------------
-- Sanae01
function OnSanae01SpellStart(keys)
    local caster = keys.caster
    local ability = keys.ability
    local targetPosition = keys.ability:GetCursorPosition()

    local damage = keys.damage
    local duration = keys.duration
    local radius = keys.radius
    local scepter_bouns = keys.scepter_bouns
    local interval = keys.interval

    local time = 0
    -- 标记只提供受视野限制的技能来源，不改变下面的伤害/减速逻辑。
    local circleObservation = CircleSource.Begin(caster, ability, targetPosition, radius, duration, interval)

    caster:SetContextThink(DoUniqueString("sanae_01_particle"), function()
        if GameRules:IsGamePaused() then
            return 0.03
        end

        if time >= duration then
            CircleSource.Finish(circleObservation)
            return nil
        end

        CircleSource.Tick(circleObservation, time)
        local targets = FindUnitsInRadius(caster:GetTeamNumber(), targetPosition, nil, radius,
            ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(),
            FIND_ANY_ORDER, false)

        for _, target in ipairs(targets) do
            local damageTable = {
                ability = ability,
                victim = target,
                attacker = caster,
                damage = damage,
                damage_type = ability:GetAbilityDamageType(),
                damage_flags = DOTA_DAMAGE_FLAG_NONE
            }
            if target:IsHero() and caster:HasModifier("modifier_item_wanbaochui") then
                damageTable.damage = damageTable.damage * (1 + scepter_bouns * 0.01)
            end
            UnitDamageTarget(damageTable)

            ability:ApplyDataDrivenModifier(caster, target, "modifier_thdots_sanae01_slow", {})
        end

        time = time + 1
        return interval
    end, 0)

    EmitSoundOnLocationWithCaster(targetPosition, "Hero_Invoker.Tornado.Cast", caster)

    local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_cyclone.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, targetPosition)
    ParticleManager:DestroyParticleSystem(effectIndex, false)
    Timer.Wait 'sanae_01_particle'(1.5, function()
        if GameRules:IsGamePaused() then
            return 0.04
        end

        effectIndex = ParticleManager:CreateParticle("particles/items_fx/cyclone.vpcf", PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(effectIndex, 0, targetPosition)
        ParticleManager:SetParticleControl(effectIndex, 1, targetPosition)
        ParticleManager:DestroyParticleSystem(effectIndex, false)
    end)
end

-- Sanae01 End
----------------------------------------------------------------------------------------------
-- Sanae02

-- Ability Initialization
ability_thdots_sanae02 = class({})

-- Ability Basic Parameter
function ability_thdots_sanae02:GetAbilityDamage()
    local damage = self:GetSpecialValueFor("damage")
    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_sanae_4")
    if talent ~= nil and talent:GetLevel() ~= 0 then
        damage = damage + talent:GetSpecialValueFor("value")
    end
    return damage
end

function ability_thdots_sanae02:GetCastRange()
    return self:GetSpecialValueFor("cast_range")
end

function ability_thdots_sanae02:GetAOERadius()
    return self:GetSpecialValueFor("damage_radius")
end

-- Ability Script
function ability_thdots_sanae02:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()

    local delayTime = self:GetSpecialValueFor("delay_time")
    local stunDuration = self:GetSpecialValueFor("stun_duration")
    local scepterBouns = 1 + self:GetSpecialValueFor("scepter_bouns") * 0.01

    local creationTime = GameRules:GetGameTime()
    local targetPosition = self:GetCursorPosition()

    caster:SetContextThink('sanae02_delay', function()
        if GameRules:IsGamePaused() or GameRules:GetGameTime() - creationTime < delayTime then
            return 0.04
        end

        local targets = FindUnitsInRadius(caster:GetTeamNumber(), targetPosition, nil, self:GetAOERadius(),
            self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
        for _, target in pairs(targets) do
            local damageTable = {
                ability = self,
                victim = target,
                attacker = caster,
                damage = self:GetAbilityDamage(),
                damage_type = self:GetAbilityDamageType(),
                damage_flags = DOTA_DAMAGE_FLAG_NONE
            }
            if target:IsHero() and caster:HasScepter() then
                damageTable.damage = damageTable.damage * scepterBouns
            end
            UnitDamageTarget(damageTable)

            local talent = caster:FindAbilityByName("special_bonus_unique_sanae_3")
            if talent == nil or talent:GetLevel() == 0 then
                UtilStun:UnitStunTarget(caster, target, stunDuration)
            else
                UtilStun:UnitStunTarget(caster, target, stunDuration + talent:GetSpecialValueFor("value"))
            end
        end

        EmitSoundOnLocationWithCaster(targetPosition, "Hero_Zuus.GodsWrath.PreCast", caster)
        EmitSoundOnLocationWithCaster(targetPosition, "Ability.Torrent", caster)

        local effectIndex = ParticleManager:CreateParticle("particles/heroes/sanae/ability_sanea_02_effect.vpcf",
            PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(effectIndex, 0, targetPosition)
        ParticleManager:SetParticleControl(effectIndex, 1, targetPosition)
        ParticleManager:DestroyParticleSystem(effectIndex, false)

        return nil
    end, delayTime)
end

-- Sanae02 End
----------------------------------------------------------------------------------------------
-- Sanae lyz

ability_thdots_sanae_lyz = {}

function ability_thdots_sanae_lyz:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function ability_thdots_sanae_lyz:OnAbilityPhaseStart()
    if not IsServer() then
        return
    end
    self.charges = self:GetCurrentAbilityCharges() -- 获取消耗充能前的充能数
end

function ability_thdots_sanae_lyz:GetChannelTime()
    if not IsServer() then
        return
    end
    if not self:GetAutoCastState() then
        return 0
    else
        local channelTime = self:GetSpecialValueFor("channel_interval") * self.charges -- 持续施法时间为施放所有充能所需时间
        return channelTime
    end
end

function ability_thdots_sanae_lyz:OnSpellStart()
    if not IsServer() then
        return
    end
    if self:GetAutoCastState() then -- 自动施法
        self.frametime = self:GetSpecialValueFor("channel_interval")
        self.spendCheck = 0
        self.channel_radius = self:GetSpecialValueFor("channel_radius")
        self.channel_interval = self:GetSpecialValueFor("channel_interval")
        return
    end
    local caster = self:GetCaster()

    -- 随机御神签
    local RandomOmikuzi = RandomInt(1, 100)
    if RandomOmikuzi >= 1 and RandomOmikuzi <= 25 then
        self.OmikuziType = 1
    elseif RandomOmikuzi >= 26 and RandomOmikuzi <= 50 then
        self.OmikuziType = 2
    elseif RandomOmikuzi >= 51 and RandomOmikuzi <= 75 then
        self.OmikuziType = 3
    elseif RandomOmikuzi >= 76 and RandomOmikuzi <= 100 then
        self.OmikuziType = 4
    end

    -- 投射物信息
    local target_location = self:GetCursorPosition()
    local caster_location = caster:GetAbsOrigin()
    local direction = caster:GetForwardVector()
    local speed = GetDistanceBetweenTwoVec2D(target_location, caster_location) /
                      self:GetSpecialValueFor("projectile_duration")

    -- 抛物线特效
    local projectile_particle = ParticleManager:CreateParticle(
        "particles/heroes/sanae/ability_sanae_omikuzi_projectile.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(projectile_particle, 0,
        caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))) -- 起点
    ParticleManager:SetParticleControl(projectile_particle, 1, target_location) -- 终点
    ParticleManager:SetParticleControl(projectile_particle, 2, Vector(speed, 0, 0)) -- 速度

    local projectile_table = {
        Source = caster,
        Ability = self,
        bProvidesVision = true,
        iVisionRadius = 200,
        iVisionTeamNumber = caster:GetTeamNumber(),
        vSpawnOrigin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")),
        vVelocity = direction * speed,
        fDistance = GetDistanceBetweenTwoVec2D(target_location, caster_location),
        fStartRadius = self:GetSpecialValueFor("collision_radius"),
        fEndRadius = self:GetSpecialValueFor("collision_radius"),
        fExpireTime = GameRules:GetGameTime() + 10.0,
        -- iUnitTargetTeam	 	= self:GetAbilityTargetTeam(),
        -- iUnitTargetType 	= self:GetAbilityTargetType(),
        -- iUnitTargetFlags = self:GetAbilityTargetFlags(),
        bIgnoreSource = true,
        bHasFrontalCone = false,
        bDrawsOnMinimap = false,
        bVisibleToEnemies = true,
        ExtraData = {
            OmikuziType = self.OmikuziType,
            projectile_particle = projectile_particle
        }
    }
    ProjectileManager:CreateLinearProjectile(projectile_table)
end

function ability_thdots_sanae_lyz:OnChannelThink()
    if not IsServer() then
        return
    end
    if not self:GetAutoCastState() then
        return
    end
    local caster = self:GetCaster()
    if self.frametime == nil then
        self.frametime = self:GetSpecialValueFor("channel_interval")
    end
    self.frametime = self.frametime + FrameTime()

    if self.frametime >= self.channel_interval then
        self.frametime = 0

        if self.spendCheck == 0 then
            self.spendCheck = 1
        else
            if caster:GetMana() >= self:GetManaCost(self:GetLevel() - 1) then -- 魔法消耗，没蓝终止持续施法
                self:PayManaCost()
            else
                caster:InterruptChannel()
                return
            end
            if self:GetCurrentAbilityCharges() > 0 then
                self:SetCurrentAbilityCharges(self:GetCurrentAbilityCharges() - 1) -- 消耗充能
            end
        end

        -- 随机御神签
        local RandomOmikuzi = RandomInt(1, 100)
        if RandomOmikuzi >= 1 and RandomOmikuzi <= 25 then
            self.OmikuziType = 1
        elseif RandomOmikuzi >= 26 and RandomOmikuzi <= 50 then
            self.OmikuziType = 2
        elseif RandomOmikuzi >= 51 and RandomOmikuzi <= 75 then
            self.OmikuziType = 3
        elseif RandomOmikuzi >= 76 and RandomOmikuzi <= 100 then
            self.OmikuziType = 4
        end

        -- 投射物信息
        local target_location = self:GetCursorPosition() + RandomVector(RandomInt(0, self.channel_radius))
        local caster_location = caster:GetAbsOrigin()
        local direction = ((target_location - caster_location) * Vector(1, 1, 0)):Normalized()
        local speed = GetDistanceBetweenTwoVec2D(target_location, caster_location) /
                          self:GetSpecialValueFor("projectile_duration")

        -- 抛物线特效
        local projectile_particle = ParticleManager:CreateParticle(
            "particles/heroes/sanae/ability_sanae_omikuzi_projectile.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(projectile_particle, 0,
            caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))) -- 起点
        ParticleManager:SetParticleControl(projectile_particle, 1, target_location) -- 终点
        ParticleManager:SetParticleControl(projectile_particle, 2, Vector(speed, 0, 0)) -- 速度

        local projectile_table = {
            Source = caster,
            Ability = self,
            bProvidesVision = true,
            iVisionRadius = 200,
            iVisionTeamNumber = caster:GetTeamNumber(),
            vSpawnOrigin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")),
            vVelocity = direction * speed,
            fDistance = GetDistanceBetweenTwoVec2D(target_location, caster_location),
            fStartRadius = self:GetSpecialValueFor("collision_radius"),
            fEndRadius = self:GetSpecialValueFor("collision_radius"),
            fExpireTime = GameRules:GetGameTime() + 10.0,
            -- iUnitTargetTeam	 	= self:GetAbilityTargetTeam(),
            -- iUnitTargetType 	= self:GetAbilityTargetType(),
            -- iUnitTargetFlags = self:GetAbilityTargetFlags(),
            bIgnoreSource = true,
            bHasFrontalCone = false,
            bDrawsOnMinimap = false,
            bVisibleToEnemies = true,
            ExtraData = {
                OmikuziType = self.OmikuziType,
                projectile_particle = projectile_particle
            }
        }
        ProjectileManager:CreateLinearProjectile(projectile_table)
    end
end

function ability_thdots_sanae_lyz:OnProjectileHit_ExtraData(hTarget, vLocation, ExtraData)
    if not IsServer() then
        return
    end

    ParticleManager:DestroyParticle(ExtraData.projectile_particle, false)
    ParticleManager:ReleaseParticleIndex(ExtraData.projectile_particle)

    vLocation = Vector(vLocation.x, vLocation.y, GetGroundPosition(vLocation, nil).z)

    -- 基本信息
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")

    -- 寻找附近单位
    local targets = FindUnitsInRadius(caster:GetTeam(), vLocation, nil, radius, self:GetAbilityTargetTeam(),
        self:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

    -- 处理目标
    if ExtraData.OmikuziType == 1 then -- 大凶
        local damage = self:GetSpecialValueFor("daikyou_damage")
        for i, target in pairs(targets) do
            if target:GetTeamNumber() == caster:GetTeamNumber() then
                if target ~= caster then
                    damage = damage * self:GetSpecialValueFor("ally_damage_pct") * 0.01
                end
            else
                target:AddNewModifier(caster, self, "modifier_ability_thdots_sanae_lyz_daikyou", {
                    duration = self:GetSpecialValueFor("daikyou_duration") * (1 - target:GetStatusResistance())
                })
            end

            local damage_table = {
                victim = target,
                attacker = caster,
                damage = damage,
                damage_type = self:GetAbilityDamageType(),
                damage_flags = DOTA_DAMAGE_FLAG_NONE,
                ability = self
            }
            UnitDamageTarget(damage_table)
        end
    elseif ExtraData.OmikuziType == 2 then -- 凶
        local damage = self:GetSpecialValueFor("kyou_damage")
        for i, target in pairs(targets) do
            if target:GetTeamNumber() == caster:GetTeamNumber() then
                if target ~= caster then
                    damage = damage * self:GetSpecialValueFor("ally_damage_pct") * 0.01
                end
            else
                target:AddNewModifier(caster, self, "modifier_ability_thdots_sanae_lyz_kyou", {
                    duration = self:GetSpecialValueFor("kyou_duration") * (1 - target:GetStatusResistance())
                })
            end

            local damage_table = {
                victim = target,
                attacker = caster,
                damage = damage,
                damage_type = self:GetAbilityDamageType(),
                damage_flags = DOTA_DAMAGE_FLAG_NONE,
                ability = self
            }
            UnitDamageTarget(damage_table)
        end
    elseif ExtraData.OmikuziType == 3 then -- 吉
        local damage = self:GetSpecialValueFor("kiti_damage")
        for i, target in pairs(targets) do
            if target:GetTeamNumber() == caster:GetTeamNumber() then
                if target ~= caster then
                    damage = damage * self:GetSpecialValueFor("ally_damage_pct") * 0.01
                end
            else
                target:AddNewModifier(caster, self, "modifier_ability_thdots_sanae_lyz_kiti", {
                    duration = self:GetSpecialValueFor("kiti_duration") * (1 - target:GetStatusResistance())
                })
            end

            local damage_table = {
                victim = target,
                attacker = caster,
                damage = damage,
                damage_type = self:GetAbilityDamageType(),
                damage_flags = DOTA_DAMAGE_FLAG_NONE,
                ability = self
            }
            UnitDamageTarget(damage_table)
        end
    elseif ExtraData.OmikuziType == 4 then -- 大吉
        local damage = self:GetSpecialValueFor("daikiti_damage")
        for i, target in pairs(targets) do
            if target:GetTeamNumber() == caster:GetTeamNumber() then
                if target ~= caster then
                    damage = damage * self:GetSpecialValueFor("ally_damage_pct") * 0.01
                end
            else
                target:AddNewModifier(caster, self, "modifier_ability_thdots_sanae_lyz_daikiti", {
                    duration = self:GetSpecialValueFor("daikiti_duration")
                })
            end

            local damage_table = {
                victim = target,
                attacker = caster,
                damage = damage,
                damage_type = DAMAGE_TYPE_PURE,
                damage_flags = DOTA_DAMAGE_FLAG_NONE,
                ability = self
            }
            UnitDamageTarget(damage_table)
        end
    end

    -- 特效和音效
    if ExtraData.OmikuziType == 1 or ExtraData.OmikuziType == 2 then
        if ExtraData.OmikuziType == 1 then -- 大凶
            -- 字特效
            local particle_icon = ParticleManager:CreateParticle(
                "particles/heroes/sanae/sanae_omikuzi_daikyou_icon.vpcf", PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(particle_icon, 0, vLocation)
            ParticleManager:ReleaseParticleIndex(particle_icon)
            EmitSoundOnLocationWithCaster(vLocation, "Thdots_Sanae.Omikuzi.daikyou", caster)
        elseif ExtraData.OmikuziType == 2 then -- 凶
            -- 字特效
            local particle_icon = ParticleManager:CreateParticle("particles/heroes/sanae/sanae_omikuzi_kyou_icon.vpcf",
                PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(particle_icon, 0, vLocation)
            ParticleManager:ReleaseParticleIndex(particle_icon)
            EmitSoundOnLocationWithCaster(vLocation, "Thdots_Sanae.Omikuzi.kyou", caster)
        end
        -- 爆炸特效
        local particle_effect = ParticleManager:CreateParticle(
            "particles/heroes/sanae/ability_sanea_lyz_kyou_effect.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_effect, 2, vLocation)
        ParticleManager:SetParticleControl(particle_effect, 3, vLocation)
        ParticleManager:ReleaseParticleIndex(particle_effect)
    elseif ExtraData.OmikuziType == 3 or ExtraData.OmikuziType == 4 then
        if ExtraData.OmikuziType == 3 then -- 吉
            -- 字特效
            local particle_icon = ParticleManager:CreateParticle("particles/heroes/sanae/sanae_omikuzi_kiti_icon.vpcf",
                PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(particle_icon, 0, vLocation)
            ParticleManager:ReleaseParticleIndex(particle_icon)
            EmitSoundOnLocationWithCaster(vLocation, "Thdots_Sanae.Omikuzi.kiti", caster)
        elseif ExtraData.OmikuziType == 4 then -- 大吉
            -- 字特效
            local particle_icon = ParticleManager:CreateParticle(
                "particles/heroes/sanae/sanae_omikuzi_daikiti_icon.vpcf", PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(particle_icon, 0, vLocation)
            ParticleManager:ReleaseParticleIndex(particle_icon)
            EmitSoundOnLocationWithCaster(vLocation, "Thdots_Sanae.Omikuzi.daikiti", caster)
        end
        -- 爆炸特效
        local particle_effect = ParticleManager:CreateParticle(
            "particles/heroes/sanae/ability_sanae_lyz_kiti_effect.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_effect, 0, vLocation)
        ParticleManager:ReleaseParticleIndex(particle_effect)
    end

    -- return true 会移除投射物
    return true
end

-- 大凶
modifier_ability_thdots_sanae_lyz_daikyou = {}
LinkLuaModifier("modifier_ability_thdots_sanae_lyz_daikyou", "scripts/vscripts/abilities/abilitysanae.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sanae_lyz_daikyou:IsHidden()
    return false
end
function modifier_ability_thdots_sanae_lyz_daikyou:IsPurgable()
    return true
end
function modifier_ability_thdots_sanae_lyz_daikyou:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_sanae_lyz_daikyou:IsDebuff()
    return true
end

function modifier_ability_thdots_sanae_lyz_daikyou:DeclareFunctions()
    return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_ability_thdots_sanae_lyz_daikyou:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("daikyou_mr_reduce")
end

-- 凶
modifier_ability_thdots_sanae_lyz_kyou = {}
LinkLuaModifier("modifier_ability_thdots_sanae_lyz_kyou", "scripts/vscripts/abilities/abilitysanae.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sanae_lyz_kyou:IsHidden()
    return false
end
function modifier_ability_thdots_sanae_lyz_kyou:IsPurgable()
    return true
end
function modifier_ability_thdots_sanae_lyz_kyou:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_sanae_lyz_kyou:IsDebuff()
    return true
end

function modifier_ability_thdots_sanae_lyz_kyou:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

-- 吉
modifier_ability_thdots_sanae_lyz_kiti = {}
LinkLuaModifier("modifier_ability_thdots_sanae_lyz_kiti", "scripts/vscripts/abilities/abilitysanae.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sanae_lyz_kiti:IsHidden()
    return false
end
function modifier_ability_thdots_sanae_lyz_kiti:IsPurgable()
    return true
end
function modifier_ability_thdots_sanae_lyz_kiti:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_sanae_lyz_kiti:IsDebuff()
    return true
end

function modifier_ability_thdots_sanae_lyz_kiti:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

-- 大吉
modifier_ability_thdots_sanae_lyz_daikiti = {}
LinkLuaModifier("modifier_ability_thdots_sanae_lyz_daikiti", "scripts/vscripts/abilities/abilitysanae.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_sanae_lyz_daikiti:IsHidden()
    return false
end
function modifier_ability_thdots_sanae_lyz_daikiti:IsPurgable()
    return true
end
function modifier_ability_thdots_sanae_lyz_daikiti:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_sanae_lyz_daikiti:IsDebuff()
    return true
end

function modifier_ability_thdots_sanae_lyz_daikiti:DeclareFunctions()
    return {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING}
end

function modifier_ability_thdots_sanae_lyz_daikiti:GetModifierStatusResistanceStacking()
    return self:GetAbility():GetSpecialValueFor("daikiti_sr_reduce")
end

-- Sanae lyz End
----------------------------------------------------------------------------------------------
