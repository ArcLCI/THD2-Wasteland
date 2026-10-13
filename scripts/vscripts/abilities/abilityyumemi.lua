function YumemiCreateCross(caster, vector)
    local count = 1 + FindTelentValue(caster, "special_bonus_unique_yumemi_1")
    for i = 1, count do
        local cross = CreateUnitByName("npc_ability_yumemi_01_cross", vector, false, caster, caster, caster:GetTeam())
        local ability_dummy_unit = cross:FindAbilityByName("ability_dummy_unit")
        ability_dummy_unit:SetLevel(1)

        local effectIndex = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_nevermore/nevermore_shadowraze_ember.vpcf", PATTACH_ABSORIGIN, cross)
        ParticleManager:ReleaseParticleIndex(effectIndex)

        cross:SetForwardVector(caster:GetForwardVector())
        cross:SetContextThink(DoUniqueString("ability_yumemi_01_spell_cross"), function()
            if GameRules:IsGamePaused() then
                return 0.03
            end
            -- cross:ForceKill(true)
            cross:RemoveSelf()
            return
        end, 12.0)
        local owner = caster:GetOwner()
        if owner ~= nil then
            cross:SetOwner(owner)
        end
        cross.ability_yumemi_01_spell_dealdamage = 1
    end
end

function OnYumemi01SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local targetPoint = keys.ability:GetCursorPosition()

    local rad = GetRadBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    local forwardVector = caster:GetOrigin() +
                              Vector(math.cos(rad) * keys.FixedDistance, math.sin(rad) * keys.FixedDistance, 0)

    if caster.ability_yumemi_01_spell_dealdamage ~= 0 then
        caster.ability_yumemi_01_spell_dealdamage = 0
    end

    caster:SetContextThink(DoUniqueString("ability_yumemi_01_spell_start"), function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        YumemiCreateCross(caster, forwardVector)
        return nil
    end, 1.0)
end

function OnYumemi01SpellHit(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local loseMana = caster:GetMaxMana() - caster:GetMana()
    local mult_per_mana = keys.ability:GetSpecialValueFor("damage_mult_per_mana")
    local mult = (loseMana - loseMana % mult_per_mana) / mult_per_mana
    local dealdamage = keys.ability:GetAbilityDamage() *
                           (1 + mult * keys.ability:GetSpecialValueFor("damage_mana_mult") / 100)

    local damage_table = {
        ability = keys.ability,
        victim = keys.target,
        attacker = caster,
        damage = dealdamage,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = keys.ability:GetAbilityTargetFlags()
    }
    UnitDamageTarget(damage_table)
end

function OnYumemi02SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local targetPoint = keys.ability:GetCursorPosition()
    local Yumemi02rad = GetRadBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    local Yumemi02dis = GetDistanceBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    keys.ability:SetContextNum("ability_Yumemi02_Rad", Yumemi02rad, 0) -- 面向
    keys.ability:SetContextNum("ability_Yumemi02_Dis", Yumemi02dis, 0) -- 总距离
    keys.ability:SetContextNum("ability_Yumemi02_CurDis", 0, 0) -- 当前已行进距离
    -- caster:SetModel("models/thd2/yumemi/yumemi_idousen.vmdl")
    local Caster = keys.caster
    local CasterName = Caster:GetClassname()
    if CasterName ~= "npc_dota_hero_tinker" then
        caster:SetOriginalModel("models/new_touhou_model/satori/satori.vmdl")
    else
        caster:SetOriginalModel("models/thd2/yumemi/yumemi_idousen.vmdl")
    end

    --[[if caster:HasModifier("modifier_item_aghanims_shard") then
		ProjectileManager:ProjectileDodge(caster)
	end--]]
end

function OnYumemi02SpellMove(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local vecCaster = caster:GetOrigin()

    local Yumemi02rad = keys.ability:GetContext("ability_Yumemi02_Rad")
    local vec = Vector(vecCaster.x + math.cos(Yumemi02rad) * keys.MoveSpeed / 50,
        vecCaster.y + math.sin(Yumemi02rad) * keys.MoveSpeed / 50, GetGroundPosition(caster:GetOrigin(), caster).z + 100)
    caster:SetOrigin(vec)

    local Yumemi02dis = keys.ability:GetContext("ability_Yumemi02_Dis")
    local manacostpercent = keys.ManaCostPercent

    if (Yumemi02dis < 0 or caster:GetMana() <= 0) then
        caster:SetUnitOnClearGround()
        keys.ability:SetContextNum("ability_Yumemi02_Dis", 0, 0)
        caster:RemoveModifierByName("modifier_thdots_yumemi02_think_interval")
        caster:SetOrigin(Vector(vec.x, vec.y, GetGroundPosition(caster:GetOrigin(), caster).z))
        local Caster = keys.caster
        local CasterName = Caster:GetClassname()
        if CasterName ~= "npc_dota_hero_tinker" then
            caster:SetModel("models/new_touhou_model/satori/satori.vmdl")
            caster:SetOriginalModel("models/new_touhou_model/satori/satori.vmdl")
        else
            caster:SetModel("models/thd2/yumemi/yumemi_mmd.vmdl")
            caster:SetOriginalModel("models/thd2/yumemi/yumemi_mmd.vmdl")
        end
        local effectIndex = ParticleManager:CreateParticle(
            "particles/econ/items/storm_spirit/storm_spirit_orchid_hat/stormspirit_orchid_ball_end.vpcf",
            PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(effectIndex, 0, caster:GetOrigin())
        ParticleManager:SetParticleControl(effectIndex, 1, caster:GetOrigin())
        OnYumemi02CastEnd(keys, keys.ability:GetContext("ability_Yumemi02_CurDis"))
    else
        Yumemi02dis = Yumemi02dis - keys.MoveSpeed / 50
        Yumemi02curdis = keys.ability:GetContext("ability_Yumemi02_CurDis") + keys.MoveSpeed / 50
        keys.ability:SetContextNum("ability_Yumemi02_CurDis", Yumemi02curdis, 0)
        keys.ability:SetContextNum("ability_Yumemi02_Dis", Yumemi02dis, 0)
        caster:SetMana(caster:GetMana() - caster:GetMaxMana() * manacostpercent / 5000 - keys.ManaCost / 50)
    end
end
function OnYumemi02CastEnd(keys, distance)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local interval_dis = keys.ability:GetSpecialValueFor("scepter_interval_dis")
    local start_dis = keys.ability:GetSpecialValueFor("scepter_start_dis")
    caster:SetUnitOnClearGround()
    if caster:HasModifier("modifier_item_wanbaochui") and keys.caster:GetClassname() == "npc_dota_hero_tinker" and
        distance > start_dis then
        local multi = (distance - distance % interval_dis) / interval_dis
        local ability03 = caster:FindAbilityByName("ability_thdots_yumemi03")
        if ability03 == nil or ability03:GetLevel() <= 0 then
            return
        end
        keys.ability = ability03
        keys.Duration = keys.ability:GetSpecialValueFor("move_slow_duration")
        keys.Radius = keys.ability:GetSpecialValueFor("radius") * (1 + multi * 0.1)
        keys.Damage = keys.ability:GetAbilityDamage() * (1 + multi * 0.2)
        keys.RadiusMulti = 1 + multi * 0.1
        OnYumemi03SpellStart(keys, 0.1)
    end
end
function OnYumemi03SpellStart(keys, delay)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local vecCaster = caster:GetOrigin()
    local effectIndex = ParticleManager:CreateParticle("particles/heroes/yumemi/ability_yumemi_03_unit.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, caster:GetOrigin())
    ParticleManager:SetParticleControl(effectIndex, 1, caster:GetOrigin())
    if keys.RadiusMulti == nil then
        keys.RadiusMulti = 1
    end
    ParticleManager:SetParticleControl(effectIndex, 3, Vector(keys.RadiusMulti, keys.RadiusMulti, 0)) -- 特效范围缩放
    if delay == nil then
        delay = 1
    end
    local hasWanBaoChui = caster:HasModifier("modifier_item_wanbaochui")
    ParticleManager:SetParticleControl(effectIndex, 4, Vector(delay, 0, 0)) -- 特效延迟设定
    caster:SetContextThink(DoUniqueString("ability_yumemi_03_spell_start"), function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        local targets = FindUnitsInRadius(caster:GetTeam(), vecCaster, nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
            keys.ability:GetAbilityTargetType(), 0, FIND_CLOSEST, false)

        for _, v in pairs(targets) do
            local deal_damage
            if keys.Damage ~= nil then
                deal_damage = keys.Damage
            else
                deal_damage = keys.ability:GetAbilityDamage()
            end
            local damage_table = {
                ability = keys.ability,
                victim = v,
                attacker = caster,
                damage = deal_damage,
                damage_type = keys.ability:GetAbilityDamageType(),
                damage_flags = keys.ability:GetAbilityTargetFlags()
            }
            keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_yumemi_03_slow", {
                duration = keys.Duration
            })
            UnitDamageTarget(damage_table)
        end
        caster:EmitSound("Hero_StormSpirit.StaticRemnantExplode")
        if not hasWanBaoChui then
            YumemiCreateCross(caster, vecCaster)
        end
        return nil
    end, delay)
end

ability_thdots_yumemi04 = class({})

function ability_thdots_yumemi04:OnAbilityPhaseStart()
    if not IsServer() then return true end
    -- 原 0.1 秒前摇 + 4 秒自晕统一为原生前摇；取消只清理表现。
    local caster = self:GetCaster()
    caster:EmitSound("Voice_Thdots_Yumemi.AbilityYumemi04")
    caster:EmitSound("Hero_Enigma.BlackHole.Cast.Chasm")
    self.phaseParticle = ParticleManager:CreateParticle("particles/heroes/yumemi/ability_yumemi_04.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    return true
end

function ability_thdots_yumemi04:OnAbilityPhaseInterrupted()
    if not IsServer() then return end
    self:GetCaster():StopSound("Hero_Enigma.BlackHole.Cast.Chasm")
    self:GetCaster():StopSound("Voice_Thdots_Yumemi.AbilityYumemi04")
    if self.phaseParticle ~= nil then
        ParticleManager:DestroyParticle(self.phaseParticle, false)
        ParticleManager:ReleaseParticleIndex(self.phaseParticle)
        self.phaseParticle = nil
    end
end

function ability_thdots_yumemi04:OnSpellStart()
    if not IsServer() then return end
    self:OnAbilityPhaseInterrupted()
    local keys = { caster_entindex = self:GetCaster():entindex(), ability = self,
        Radius = self:GetSpecialValueFor("radius"), StunDuration = self:GetSpecialValueFor("stun_duration") }
    -- 天赋十字在成功施法时生成，避免真实中断后留下免费效果。
    OnYumemi04PhaseStart(keys)
    local passive = self:GetCaster():FindModifierByName("modifier_thdots_yumemiEx_passive")
    -- 十字现在同帧生成，先刷新原计数再读取大招伤害，避免等待 0.1 秒被动轮询。
    if passive ~= nil then passive:OnIntervalThink() end
    local effect = ParticleManager:CreateParticle("particles/heroes/yumemi/ability_yumemi_04_exolosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:ReleaseParticleIndex(effect)
    OnYumemi04Destroy(keys)
end

function ability_thdots_yumemi04:OnOwnerDied()
    self:OnAbilityPhaseInterrupted()
end

-- 保留旧公开标记供外部兼容，不再附加自晕或在销毁回调结算。
LinkLuaModifier("modifier_yumemi04_action", "scripts/vscripts/abilities/abilityyumemi.lua", LUA_MODIFIER_MOTION_NONE)
modifier_yumemi04_action = class({})
function modifier_yumemi04_action:IsHidden() return true end
function modifier_yumemi04_action:IsPurgable() return false end

function OnYumemi04PhaseStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)

    if FindTelentValue(caster, "special_bonus_unique_yumemi_3") ~= 0 then
        local vecCaster = caster:GetOrigin()
        local leftVector = caster:GetLeftVector()
        local count = keys.ability:GetSpecialValueFor("cross_count")

        for i = 1, count do
            local rollRad = i * math.pi * 2 / 6
            local leftCos = leftVector.x
            local leftSin = leftVector.y
            local crossVector = Vector(math.cos(rollRad) * leftCos - math.sin(rollRad) * leftSin,
                leftSin * math.cos(rollRad) + leftCos * math.sin(rollRad), 0) * 300 + vecCaster

            YumemiCreateCross(caster, crossVector)
        end
    end
end

function OnYumemi04Destroy(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local vecCaster = caster:GetOrigin()
    local targets = FindUnitsInRadius(caster:GetTeam(), vecCaster, nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
        keys.ability:GetAbilityTargetType(), 0, FIND_CLOSEST, false)
    for _, v in pairs(targets) do
        local deal_damage = keys.ability:GetAbilityDamage()
        local cross_bonus_damage = keys.ability:GetSpecialValueFor("damage_per_cross") *
                                       caster:FindModifierByName("modifier_thdots_yumemiEx_passive"):GetStackCount()
        if FindTelentValue(caster, "special_bonus_unique_yumemi_3") ~= 0 then
            deal_damage = deal_damage + cross_bonus_damage
        end
        local damage_table = {
            ability = keys.ability,
            victim = v,
            attacker = caster,
            damage = deal_damage,
            damage_type = keys.ability:GetAbilityDamageType(),
            damage_flags = keys.ability:GetAbilityTargetFlags()
        }
        UtilStun:UnitStunTarget(caster, v, keys.StunDuration, (UtilStun.TraceSource and UtilStun:TraceSource(function() return keys.ability end) or nil), "script:scripts/vscripts/abilities/abilityyumemi.lua:OnYumemi04Destroy:290")
        UnitDamageTarget(damage_table)
    end
    caster:EmitSound("Hero_Phoenix.SuperNova.Explode")
end

ability_thdots_yumemiEx = {}

function ability_thdots_yumemiEx:GetIntrinsicModifierName()
    return "modifier_thdots_yumemiEx_passive"
end

function ability_thdots_yumemiEx:GetBehavior()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    else
        return self.BaseClass.GetBehavior(self)
    end
end

function ability_thdots_yumemiEx:GetCooldown(level)
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return self.BaseClass.GetCooldown(self, level)
    else
        return 0
    end
end

function ability_thdots_yumemiEx:OnSpellStart() -- My very own soulring!
    local caster = self:GetCaster()
    local cross = Entities:FindAllByModel("models/thd2/yumemi/yumemi_q_mmd.vmdl")
    local cross_count = caster:FindModifierByName("modifier_thdots_yumemiEx_passive"):GetStackCount()
    local cross_cost = self:GetSpecialValueFor("cross_cost")
    local cross_remaining = cross_count - cross_cost
    local mana_restore_pct = self:GetSpecialValueFor("mana_restore_pct")

    if cross_count < cross_cost then
        self:EndCooldown()
        return
    end

    for i = 1, cross_cost do -- 消耗次数
        for k, v in pairs(cross) do
            if v ~= nil and v:IsNull() == false then
                local owner = v:GetOwner()
                local casterOwner = caster:GetOwner()
                if owner ~= nil and casterOwner ~= nil and owner == casterOwner then
                    v:RemoveSelf()
                    cross_count = cross_count - 1
                    if cross_count == cross_remaining then
                        caster:GiveMana(caster:GetMaxMana() * mana_restore_pct * 0.01)
                        caster:EmitSound("Hero_Tinker.RearmStart")
                    end
                    break -- 消耗一次返回
                end
            end
        end
    end

    ProjectileManager:ProjectileDodge(caster)
end

modifier_thdots_yumemiEx_passive = {}
LinkLuaModifier("modifier_thdots_yumemiEx_passive", "scripts/vscripts/abilities/abilityyumemi.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_yumemiEx_passive:IsHidden()
    return false
end
function modifier_thdots_yumemiEx_passive:IsPurgable()
    return false
end
function modifier_thdots_yumemiEx_passive:RemoveOnDeath()
    return false
end
function modifier_thdots_yumemiEx_passive:IsDebuff()
    return false
end

function modifier_thdots_yumemiEx_passive:DeclareFunctions()
    return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE}
end

function modifier_thdots_yumemiEx_passive:OnCreated()
    if not IsServer() then
        return
    end
    self:StartIntervalThink(0.1)
end

function modifier_thdots_yumemiEx_passive:OnIntervalThink()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local cross = Entities:FindAllByModel("models/thd2/yumemi/yumemi_q_mmd.vmdl")
    caster:SetModifierStackCount("modifier_thdots_yumemiEx_passive", ability, #cross)
end

function modifier_thdots_yumemiEx_passive:OnTakeDamage(event)
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local cross = Entities:FindAllByModel("models/thd2/yumemi/yumemi_q_mmd.vmdl")
    local telentblock = 0
    if event.unit ~= caster or
        (not event.attacker:IsHero() and FindTelentValue(caster, "special_bonus_unique_yumemi_2") ~= 0) then
        return
    end
    if event.inflictor and
        (event.inflictor:GetName() == "ability_thdots_yugi04" or event.inflictor:GetName() == "ability_thdots_komachi04") then
        return
    end
    for k, v in pairs(cross) do
        if v ~= nil and v:IsNull() == false then
            local owner = v:GetOwner()
            local casterOwner = caster:GetOwner()
            if owner ~= nil and casterOwner ~= nil and owner == casterOwner then
                if event.damage > telentblock then
                    if not caster:HasModifier("modifier_ability_thdots_yumemiEx_cross") then
                        caster:SetHealth(caster:GetHealth() + event.damage)
                        caster:AddNewModifier(caster, ability, "modifier_ability_thdots_yumemiEx_cross", {
                            duration = 0.05
                        })
                        v:RemoveSelf()
                    else
                        return
                    end
                end
            end
        end
    end
end

function modifier_thdots_yumemiEx_passive:GetModifierBaseAttack_BonusDamage()
    local ability = self:GetAbility()
    return ability:GetSpecialValueFor("attack_bonus") * self:GetStackCount()
end

modifier_ability_thdots_yumemiEx_cross = {}
LinkLuaModifier("modifier_ability_thdots_yumemiEx_cross", "scripts/vscripts/abilities/abilityyumemi.lua",
    LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_yumemiEx_cross:IsHidden()
    return false
end
function modifier_ability_thdots_yumemiEx_cross:IsPurgable()
    return false
end
function modifier_ability_thdots_yumemiEx_cross:RemoveOnDeath()
    return false
end
function modifier_ability_thdots_yumemiEx_cross:IsDebuff()
    return false
end

function modifier_ability_thdots_yumemiEx_cross:OnCreated()
    if not IsServer() then
        return
    end
    self.particle = "particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf"
    self.duration = 0.3
    local caster = self:GetCaster()
    self.refraction_particle = ParticleManager:CreateParticle(self.particle, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(self.refraction_particle, 1, caster, PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:DestroyParticleSystemTime(self.refraction_particle, self.duration)
end

function modifier_ability_thdots_yumemiEx_cross:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK}
end

function modifier_ability_thdots_yumemiEx_cross:GetModifierTotal_ConstantBlock(kv)
    if not IsServer() then
        return
    end
    if bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
        return 0
    end
    return kv.damage
end
