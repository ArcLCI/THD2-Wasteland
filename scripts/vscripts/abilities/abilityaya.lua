if AbilityAya == nil then
    AbilityAya = class({})
end

local function AyaDistancePointToSegment2D(point, startPos, endPos)
    local sx = startPos.x
    local sy = startPos.y
    local ex = endPos.x
    local ey = endPos.y
    local px = point.x
    local py = point.y
    local dx = ex - sx
    local dy = ey - sy
    local lenSq = dx * dx + dy * dy

    if lenSq <= 0 then
        local ox = px - sx
        local oy = py - sy
        return math.sqrt(ox * ox + oy * oy)
    end

    local t = ((px - sx) * dx + (py - sy) * dy) / lenSq
    t = math.max(0, math.min(1, t))

    local cx = sx + dx * t
    local cy = sy + dy * t
    local ox = px - cx
    local oy = py - cy
    return math.sqrt(ox * ox + oy * oy)
end

ability_thdots_aya01 = {}

function ability_thdots_aya01:GetCastRange(location, target)
    if IsServer() then
        return 0
    end
end

function ability_thdots_aya01:OnSpellStart()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local FixDis = self:GetSpecialValueFor("fix_distance")

    caster:EmitSound("Ability.SandKing_SandStorm.start")

    -- 计数
    -- if caster:HasModifier("modifier_thdots_aya04_blink") then		
    -- caster.aya04count = caster.aya04count - 1	
    -- print("caster.aya04count",caster.aya04count)
    -- end
    if caster:HasModifier("modifier_item_wanbaochui") and caster:HasModifier("modifier_thdots_aya04_blink") then
        caster:SetMana(caster:GetMana() * 0.94)
    end
    local targetPoint = self:GetCursorPosition()
    local Aya01rad = GetRadBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    local Aya01dis = GetDistanceBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    if (Aya01dis > FixDis) then
        Aya01dis = FixDis
    end
    self:SetContextNum("ability_Aya01_Rad", Aya01rad, 0)
    self:SetContextNum("ability_Aya01_Dis", Aya01dis, 0)

    local move_duration = self:GetSpecialValueFor("move_duration")
    caster:AddNewModifier(caster, self, "modifier_thdots_aya01_think_interval", {
        duration = move_duration
    })
end

modifier_thdots_aya01_think_interval = {}
LinkLuaModifier("modifier_thdots_aya01_think_interval", "scripts/vscripts/abilities/abilityaya.lua",
    LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_aya01_think_interval:IsHidden()
    return false
end
function modifier_thdots_aya01_think_interval:IsPurgable()
    return false
end
function modifier_thdots_aya01_think_interval:RemoveOnDeath()
    return false
end
function modifier_thdots_aya01_think_interval:IsDebuff()
    return false
end
function modifier_thdots_aya01_think_interval:GetEffectName()
    return "particles/heroes/aya/ability_aya_01.vpcf"
end
function modifier_thdots_aya01_think_interval:GetEffectAttachType()
    return "follow_origin"
end
function modifier_thdots_aya01_think_interval:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_thdots_aya01_think_interval:DeclareFunctions()
    return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_thdots_aya01_think_interval:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_1
end

function modifier_thdots_aya01_think_interval:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end

function modifier_thdots_aya01_think_interval:OnCreated()
    if not IsServer() then
        return
    end
    self.move_interval = 0.02
    self.search_interval = 0.04
    self.search_elapsed = self.search_interval
    self.aya01_next_damage_time = {}
    self.aya01_last_search_origin = self:GetCaster():GetAbsOrigin()
    self:StartIntervalThink(self.move_interval)
end

function modifier_thdots_aya01_think_interval:OnDestroy()
    if not IsServer() then
        return
    end
    self.aya01_next_damage_time = nil
    self.aya01_last_search_origin = nil
end

function modifier_thdots_aya01_think_interval:OnIntervalThink()
    local caster = self:GetCaster()
    local vecCaster = caster:GetOrigin()
    local ability = self:GetAbility()
    local MoveSpeed = ability:GetSpecialValueFor("move_speed")
    local damage_radius = ability:GetSpecialValueFor("damage_radius")
    local flyspeed = MoveSpeed
    if caster:HasModifier("modifier_item_wanbaochui") then
        flyspeed = MoveSpeed * 2
    end
    if caster:HasModifier("modifier_item_wanbaochui") and caster:HasModifier("modifier_thdots_aya04_blink") then
        local abilitycd = caster:FindAbilityByName("ability_thdots_aya01")
        if abilitycd then
            abilitycd:EndCooldown()
        end
    end

    -- 降低搜敌频率，用上一段位移路径补偿命中范围，避免高速穿越漏判。
    self.search_elapsed = (self.search_elapsed or 0) + (self.move_interval or 0.02)
    if self.search_elapsed >= (self.search_interval or 0.04) then
        local search_start = self.aya01_last_search_origin or vecCaster
        local search_end = caster:GetAbsOrigin()
        local search_distance = GetDistanceBetweenTwoVec2D(search_start, search_end)
        local targets = FindUnitsInRadius(caster:GetTeam(), search_end, nil, damage_radius + search_distance,
            ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), 0, false)
        local now = GameRules:GetGameTime()

        for _, v in pairs(targets) do
            if v and not v:IsNull() and AyaDistancePointToSegment2D(v:GetAbsOrigin(), search_start, search_end) <=
                damage_radius then
                local index = v:GetEntityIndex()
                local next_damage_time = self.aya01_next_damage_time[index] or 0
                if now >= next_damage_time then
                    local damage_table = {
                        ability = ability,
                        victim = v,
                        attacker = caster,
                        damage = ability:GetAbilityDamage() + FindTelentValue(caster, "special_bonus_unique_aya_5"),
                        damage_type = ability:GetAbilityDamageType(),
                        damage_flags = 0
                    }
                    UnitDamageTarget(damage_table)

                    if caster:HasModifier("modifier_item_wanbaochui") then
                        v:AddNewModifier(caster, ability, "modifier_aya01_slow", {
                            Duration = 3
                        })
                    end

                    if v:IsHero() and caster:HasModifier("modifier_thdots_aya04_blink") and caster:GetClassname() ==
                        "npc_dota_hero_slark" then
                        local abilitycd = caster:FindAbilityByName("ability_thdots_aya01")
                        if abilitycd then
                            abilitycd:EndCooldown()
                        end
                    end

                    self.aya01_next_damage_time[index] = now + 0.4
                end
            end
        end
        self.aya01_last_search_origin = search_end
        self.search_elapsed = 0
    end

    local Aya01rad = ability:GetContext("ability_Aya01_Rad")
    local vec = Vector(vecCaster.x + math.cos(Aya01rad) * flyspeed / 50,
        vecCaster.y + math.sin(Aya01rad) * flyspeed / 50, vecCaster.z)
    caster:SetOrigin(vec)
    local aya01dis = ability:GetContext("ability_Aya01_Dis")
    if (aya01dis < 0) then
        caster:SetUnitOnClearGround()
        ability:SetContextNum("ability_Aya01_Dis", 0, 0)
        caster:RemoveModifierByName("modifier_thdots_aya01_think_interval")
    else
        aya01dis = aya01dis - flyspeed / 50
        ability:SetContextNum("ability_Aya01_Dis", aya01dis, 0)
    end
end

modifier_aya01_slow = {}
LinkLuaModifier("modifier_aya01_slow", "scripts/vscripts/abilities/abilityaya.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_aya01_slow:IsHidden()
    return false
end
function modifier_aya01_slow:IsPurgable()
    return true
end
function modifier_aya01_slow:RemoveOnDeath()
    return true
end
function modifier_aya01_slow:IsDebuff()
    return true
end

function modifier_aya01_slow:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_aya01_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("wanbaochui_slow")
end

function OnAya02SpellStart(keys)
    if is_spell_blocked(keys.target) then
        return
    end
    keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, keys.EffectName, {})
    if FindTelentValue(keys.caster, "special_bonus_unique_aya_1") ~= 0 then
        keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, "modifier_thdots_aya02_buff_talent", {})
    else
        keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, keys.BuffName, {})
    end
end

function OnAya02Attack(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    if (keys.attacker ~= caster) then
        return
    end
    local target = keys.target
    local damage = keys.BounsDamage * (1 + FindTelentValue(keys.caster, "special_bonus_unique_aya_1"))
    -- print(damage)
    local damage_table = {
        ability = keys.ability,
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }
    UnitDamageTarget(damage_table)
end

function OnAya03SpellStart(keys)
    AbilityAya:OnAya03Start(keys)
end

function OnAya04SpellOrderMoved(keys)
    AbilityAya:OnAya04OrderMoved(keys)
end

function OnAya04SpellOrderAttack(keys)
    AbilityAya:OnAya04OrderAttack(keys)
end

function OnAya04SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local ability = caster:FindAbilityByName("ability_thdots_aya01")
    ability:EndCooldown()
    -- 还原
    UnitNoPathingfix(caster, caster, keys.ability:GetSpecialValueFor("ability_duration"))

    -- caster.aya04count = keys.Count
    -- print("caster.aya04count",caster.aya04count)
end

function OnAya04SpellRefresh(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    -- 判断
    -- if caster.aya04count <= 0 then return end
    local ability = caster:FindAbilityByName("ability_thdots_aya01")
    -- if(ability~=nil)then
    ability:EndCooldown()
    -- end
end

function AbilityAya:OnAya03Start(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local vecCaster = caster:GetOrigin()
    local targets = keys.target_entities
    local Attacker = keys.attacker
    for _, v in pairs(targets) do
        local deal_damage = keys.AbilityMulti * caster:GetPrimaryStatValue() + FindValueTHD("base_damage", keys.ability)

        if Attacker:IsRealHero() then
            deal_damage = deal_damage
        else
            deal_damage = deal_damage * 0.35
        end

        local damage_table = {
            ability = keys.ability,
            victim = v,
            attacker = caster,
            damage = deal_damage,
            damage_type = keys.ability:GetAbilityDamageType(),
            damage_flags = 0
        }
        UnitDamageTarget(damage_table)
    end
    local effectIndex = ParticleManager:CreateParticle(
        "particles/econ/items/windrunner/windrunner_cape_cascade/windrunner_windrun_cascade.vpcf", PATTACH_CUSTOMORIGIN,
        caster)
    ParticleManager:SetParticleControl(effectIndex, 0, caster:GetOrigin() + caster:GetForwardVector() * 100)
    ParticleManager:SetParticleControl(effectIndex, 1, caster:GetOrigin() + caster:GetForwardVector() * 100)
    ParticleManager:SetParticleControl(effectIndex, 3, caster:GetOrigin() + caster:GetForwardVector() * 100)
    ParticleManager:DestroyParticleSystemTime(effectIndex, 2)
end

function AbilityAya:OnAya04OrderMoved(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    if caster:IsStunned() == false and caster:HasModifier("modifier_item_yukkuri_stick_debuff") == false then
        if (keys.ability:GetContext("ability_Aya04_blink_lock") == FALSE) then
            return
        end

        keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_aya04_animation", {
            Duration = 0.3
        })

        local targetPoint = keys.ability:GetCursorPosition()
        local Aya04dis = GetDistanceBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
        local BlinkRange = math.min(keys.BlinkRange, Aya04dis)
        local vecMove = caster:GetOrigin() + BlinkRange * caster:GetForwardVector()
        caster:SetOrigin(vecMove)
        ResolveNPCPositions(vecMove, 500)
        local effectIndex = ParticleManager:CreateParticle("particles/heroes/aya/ability_aya_04.vpcf",
            PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(effectIndex, 0, vecMove)
        ParticleManager:SetParticleControl(effectIndex, 3, vecMove)
        ParticleManager:DestroyParticleSystem(effectIndex, false)

        if (keys.ability:GetContext("ability_Aya04_blink_lock") == TRUE or
            keys.ability:GetContext("ability_Aya04_blink_lock") == nil) then
            keys.ability:SetContextNum("ability_Aya04_blink_lock", FALSE, 0)
            Timer.Wait 'ability_Aya04_blink_lock'(0.1, function()
                keys.ability:SetContextNum("ability_Aya04_blink_lock", TRUE, 0)

            end)
        end
    end
end

function AbilityAya:OnAya04OrderAttack(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    if caster:IsStunned() == false and caster:HasModifier("modifier_item_yukkuri_stick_debuff") == false then
        if (keys.ability:GetContext("ability_Aya04_blink_lock") == FALSE) then
            return
        end
        local vectarget = keys.target:GetOrigin()
        caster:SetOrigin(vectarget)
        ResolveNPCPositions(vectarget, 300)
        local effectIndex = ParticleManager:CreateParticle("particles/heroes/aya/ability_aya_04.vpcf",
            PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(effectIndex, 0, vectarget)
        ParticleManager:SetParticleControl(effectIndex, 3, vectarget)
        ParticleManager:DestroyParticleSystem(effectIndex, false)

        if (keys.ability:GetContext("ability_Aya04_blink_lock") == TRUE or
            keys.ability:GetContext("ability_Aya04_blink_lock") == nil) then
            keys.ability:SetContextNum("ability_Aya04_blink_lock", FALSE, 0)
            Timer.Wait 'ability_Aya04_blink_lock'(0.1, function()
                keys.ability:SetContextNum("ability_Aya04_blink_lock", TRUE, 0)
            end)
        end
    end
end

function OnAya04Created(keys)
    local caster = keys.caster
    if caster:GetClassname() == "npc_dota_hero_slark" then
        caster:SetOriginalModel("models/new_touhou_model/aya/aya_with_wing.vmdl")
    end
end

function AyaFantasy(keys)
    local caster = keys.caster
    local ability = keys.ability
    local level = ability:GetLevel() - 1
    local pOrg = caster:GetAbsOrigin()
    local distance = ability:GetLevelSpecialValueFor("range", level)
    local count = ability:GetLevelSpecialValueFor("count", level)
    local pTgt = ability:GetCursorPosition()
    local f = (pTgt - pOrg):Normalized()
    local pct = ParticleManager:CreateParticle("particles/units/heroes/hero_aya/aya_fantasy.vpcf", PATTACH_POINT_FOLLOW,
        caster)
    local dist = 0
    local v = 75
    local length = distance / v * 0.05
    caster.hitTable = {}
    ability:SetContextNum("ability_aya_fantasy_speed", v, 0)
    ParticleManager:SetParticleControlEnt(pct, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(),
        true)
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_aya_fantasy_find", nil)
    caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
    Timers:CreateTimer(function()
        if not caster:IsAlive() then
            caster:RemoveModifierByName("modifier_aya_fantasy_find")
            ParticleManager:DestroyParticleSystem(pct, true)
            return nil
        elseif dist > distance then
            if count > 1 then
                count = count - 1
                dist = 0
                v = math.min(v + 25, 200)
                ability:SetContextNum("ability_aya_fantasy_speed", v, 0)
                length = distance / v * 0.05
                caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
                f = AyaFantasyGetAngle(keys, (-1) * f)
                caster:EmitSound("Hero_FacelessVoid.TimeWalk")
                return 0.05
            else
                caster:RemoveModifierByName("modifier_aya_fantasy_find")
                FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
                ParticleManager:DestroyParticleSystem(pct, true)
                caster:SetForwardVector(f)
                caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_1)

                -- --刷新疾走风靡
                -- if caster:IsRealHero() and caster:GetUnitName()=="npc_dota_hero_faceless_void" then
                --     local ab = caster:FindAbilityByName("aya_charge")
                --     if ab and ab:GetLevel()>0 then
                --         ab:EndCooldown()
                --     end
                -- end
                return nil
            end
        else
            local speed = math.min(distance - dist + 1, v)
            dist = dist + speed
            caster:SetAbsOrigin(caster:GetAbsOrigin() + speed * f)
            caster:SetForwardVector(f)
            return 0.05
        end
    end)
end
function AyaFantasyGetAngle(keys, f)
    local caster = keys.caster
    local ability = keys.ability
    local level = ability:GetLevel() - 1
    local range = ability:GetLevelSpecialValueFor("range", level)
    local pOrg = caster:GetAbsOrigin()
    local up = nil
    local maxcos = 0
    local units = FindUnitsInRadius(caster:GetTeam(), pOrg, nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER,
        false)
    if #units > 0 then
        for i, enemy in pairs(units) do
            if enemy ~= nil and IsValidUnit(enemy) and enemy:IsAlive() then
                local f1 = enemy:GetAbsOrigin() - pOrg
                local dif = GetVectorsCos(f, f1)
                if dif > 0.5 and dif > maxcos then
                    maxcos = dif
                    up = enemy
                    if enemy:IsHero() then
                        break
                    end
                end
            end
        end
    end
    if up == nil then
        f = RotatePosition(Vector(0, 0, 0), QAngle(0, RandomFloat(-20, 20), 0), f)
    else
        f = up:GetAbsOrigin() - pOrg
    end
    return Vector2D(f):Normalized()
end
function AyaFantasyHit(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local level = ability:GetLevel() - 1
    -- 幻想风靡命中伤害读取当前冲刺速度档位，不使用末帧被距离截断的位移值。
    local speed = ability:GetContext("ability_aya_fantasy_speed") or 0
    local dam = ability:GetLevelSpecialValueFor("damage", level) +
        speed * ability:GetLevelSpecialValueFor("speed_damage_factor", level)
    if IsValidUnit(target) then
        if target:IsAlive() then
            local damage_table = {
                ability = keys.ability,
                victim = target,
                attacker = caster,
                damage = dam,
                damage_type = keys.ability:GetAbilityDamageType(),
                damage_flags = 0
            }
            UnitDamageTarget(damage_table) -- 公用伤害方法

            local index = target:GetEntityIndex()
            local tbl = caster.hitTable
            tbl[index] = tbl[index] or 0
            tbl[index] = tbl[index] + 1
            if not target:IsMagicImmune() and not target:IsInvulnerable() then
                if tbl[index] == 3 then
                    ability:ApplyDataDrivenModifier(caster, target, "modifier_aya_fantasy_stun", {
                        duration = GetStunDur(caster, target, 1)
                    })
                end
                -- ability:ApplyDataDrivenModifier(caster,target,"modifier_aya_fantasy_shako",nil)
            end
            -- 去除next delay
            Timers:CreateTimer(0.2, function()
                if target and IsValidEntity(target) then
                    target:RemoveModifierByName("modifier_aya_fantasy_dam")
                end
                return nil
            end)
        end
    end
end

function Vector2D(v)
    local x = v.x
    local y = v.y
    local vn = Vector(x, y, 0)
    -- print(v)
    -- print(vn)
    return vn
end
function GetVectorsCos(v1, v2)
    return v1:Dot(v2) / (v1:Length() * v2:Length())
end
function IsValidUnit(u)
    if not IsValidEntity(u) or u:HasAbility("dummy_barrage") or u:HasAbility("dummy_passive") or
        u:HasAbility("dummy_passive_vulnerable") then
        return false
    else
        return true
    end
end
function GetStunDur(caster, target, dur) -- 包括眩晕、冻结、缠绕、麻痹，不包括网
    local resist = GetStunResist(target, caster)
    return dur * (1 - resist)
end
function GetStunResist(uu, us)
    local noResist = 1
    if uu:HasModifier("modifier_item_waterwalk") then
        noResist = noResist * 0.8
    end
    if uu:HasModifier("modifier_item_medusa_stone") then
        noResist = noResist * 0.5
    end

    noResist = math.max(0.35, noResist)
    noResist = math.min(1, noResist)
    return 1 - noResist
end
