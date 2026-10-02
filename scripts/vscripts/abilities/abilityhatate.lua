abilityhatate = class({})

ability_thdots_hatate01 = {}

function ability_thdots_hatate01:GetIntrinsicModifierName()
    return "modifier_ability_thdots_hatate01"
end

function ability_thdots_hatate01:GetCastRange(location, target)
    if IsServer() then
        return 0
    end
end

function ability_thdots_hatate01:OnSpellStart()
    local caster = self:GetCaster()
    -- THDReduceCooldown(keys.ability,FindTelentValue(caster,"special_bonus_unique_hatate_2"))
    local targetPoint = self:GetCursorPosition()
    local range = self:GetSpecialValueFor("range")
    local illusions_duration = self:GetSpecialValueFor("illusions_duration")
    local illusion_damage_percent_incoming_melee = self:GetSpecialValueFor("illusion_damage_percent_incoming_melee")

    caster:EmitSound("Hero_Antimage.Blink_out")

    self.caster = caster
    self.ability = self

    local vecCaster = caster:GetOrigin()
    local maxRange = range + FindTelentValue(caster, "special_bonus_unique_hatate_1") + caster:GetCastRangeBonus()
    local pointRad = GetRadBetweenTwoVec2D(vecCaster, targetPoint)
    local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti9/blink_dagger_ti9_start_sparkles.vpcf",
        PATTACH_POINT, caster)
    ParticleManager:SetParticleControl(effectIndex, 0, caster:GetAbsOrigin())
    ParticleManager:DestroyParticleSystem(effectIndex, false)
    if FindTelentValue(caster, "special_bonus_unique_hatate_3") == 1 then
        local illusion = CreateIllusionTHD(self, caster, caster:GetAbsOrigin(), 400, 1, illusions_duration, false)
        illusion:AddNewModifier(caster, self, "modifier_ability_thdots_hatate01_illusion", {
            Duration = illusions_duration
        })
    end
    if (GetDistanceBetweenTwoVec2D(vecCaster, targetPoint) <= maxRange) then
        FindClearSpaceForUnit(caster, targetPoint, true)
    else
        local blinkVector = Vector(math.cos(pointRad) * maxRange, math.sin(pointRad) * maxRange, 0) + vecCaster
        FindClearSpaceForUnit(caster, blinkVector, true)
    end
end

modifier_ability_thdots_hatate01 = {}
LinkLuaModifier("modifier_ability_thdots_hatate01", "scripts/vscripts/abilities/abilityhatate.lua",
    LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_hatate01:IsHidden()
    return true
end
function modifier_ability_thdots_hatate01:IsPurgable()
    return false
end
function modifier_ability_thdots_hatate01:RemoveOnDeath()
    return false
end
function modifier_ability_thdots_hatate01:IsDebuff()
    return false
end

function modifier_ability_thdots_hatate01:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE}
end

function modifier_ability_thdots_hatate01:GetModifierMoveSpeedBonus_Special_Boots()
    return self:GetAbility():GetSpecialValueFor("movespeed_bonus")
end

modifier_ability_thdots_hatate01_illusion = {}
LinkLuaModifier("modifier_ability_thdots_hatate01_illusion", "scripts/vscripts/abilities/abilityhatate.lua",
    LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_hatate01_illusion:IsHidden()
    return true
end
function modifier_ability_thdots_hatate01_illusion:IsPurgable()
    return false
end
function modifier_ability_thdots_hatate01_illusion:RemoveOnDeath()
    return true
end
function modifier_ability_thdots_hatate01_illusion:IsDebuff()
    return false
end
function modifier_ability_thdots_hatate01_illusion:CheckState()
    return {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true
    }
end

--[[function Hatate01OnSpellStart( keys )
	local caster = keys.caster
	-- THDReduceCooldown(keys.ability,FindTelentValue(caster,"special_bonus_unique_hatate_2"))
	local targetPoint = keys.ability:GetCursorPosition()
	local vecCaster = caster:GetOrigin()
	local maxRange = keys.range + FindTelentValue(caster,"special_bonus_unique_hatate_1") + caster:GetCastRangeBonus()
	local pointRad = GetRadBetweenTwoVec2D(vecCaster,targetPoint)
	local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti9/blink_dagger_ti9_start_sparkles.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(effectIndex, 0, caster:GetAbsOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex, false)
	if FindTelentValue(caster,"special_bonus_unique_hatate_3") == 1 then
		local illusion = create_illusion(keys,caster:GetAbsOrigin(),400,1,keys.illusions_duration)
		if (illusion ~= nil) then
			local casterAngles = caster:GetAnglesAsVector()
			illusion:SetAngles(casterAngles.x,casterAngles.y,casterAngles.z)
			
			illusion:SetHealth(illusion:GetMaxHealth()*caster:GetHealthPercent()*0.01)
			illusion:SetMana(illusion:GetMaxMana()*caster:GetManaPercent()*0.01)
		end
		keys.ability:ApplyDataDrivenModifier(caster, illusion, "modifier_ability_thdots_hatate01_illusion", {Duration = keys.illusions_duration})
	end
	if(GetDistanceBetweenTwoVec2D(vecCaster,targetPoint)<=maxRange)then
		FindClearSpaceForUnit(caster,targetPoint,true)
	else
		local blinkVector = Vector(math.cos(pointRad)*maxRange,math.sin(pointRad)*maxRange,0) + vecCaster
		FindClearSpaceForUnit(caster,blinkVector,true)
	end
end

function create_illusion(keys, illusion_origin, illusion_incoming_damage, illusion_outgoing_damage, illusion_duration)	
	local player_id = keys.caster:GetPlayerID()
	local caster_team = keys.caster:GetTeam()
	local tmp = keys.caster
	if keys.caster:GetPlayerOwner():GetContext("PlayerIsBot") == 1 then
		tmp = nil
	end
	
	local illusion = CreateUnitByName(keys.caster:GetUnitName(), illusion_origin, true, keys.caster, tmp, caster_team)  --handle_UnitOwner needs to be nil, or else it will crash the game.
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

function Hatate02OnSpellStart(keys)
    local caster = keys.caster
    local targetPoint = keys.target_points[1]
    if targetPoint == nil then
        targetPoint = keys.ability:GetCursorPosition()
    end
    -- ɵ����Ч��������,�����Ŵ��ܷ�Χ�ķ���
    --[[
	local radius = keys.radius
	if caster:GetContext("radius_bonus") ~= nil then
		radius = radius + caster:GetContext("radius_bonus")
	end
	]]
    local max_stack = keys.max_stack
    if caster:GetContext("stack_bonus") ~= nil then
        max_stack = max_stack + caster:GetContext("stack_bonus")
    end
    caster:EmitSound("Voice_Thdots_Hatate.AbilityHatate02")
    local dummy = CreateUnitByName("npc_dummy_unit", targetPoint, false, caster, caster, caster:GetTeam())
    local ability_dummy_unit = dummy:FindAbilityByName("ability_dummy_unit")
    ability_dummy_unit:SetLevel(1)
    local effectIndex = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_dmg_shock.vpcf",
        PATTACH_CUSTOMORIGIN_FOLLOW, dummy)
    ParticleManager:DestroyParticleSystem(effectIndex, false)
    local effectIndex2 = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_dmg_shock.vpcf",
        PATTACH_CUSTOMORIGIN_FOLLOW, dummy)
    ParticleManager:DestroyParticleSystem(effectIndex2, false)
    -- local effectIndex3 = ParticleManager:CreateParticle("particles/items_fx/ethereal_blade.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    -- ParticleManager:DestroyParticleSystem(effectIndex3, false)
    dummy:ForceKill(true)
    local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, keys.radius,
        keys.ability:GetAbilityTargetTeam(), keys.ability:GetAbilityTargetType(), 0, 0, false)
    local buff_count = 0
    for _, v in pairs(targets) do
        if v:IsRealHero() then
            buff_count = buff_count + 1
        end
    end
    if caster:HasModifier("modifier_ability_thdots_hatate02_buff") then
        local stack = caster:GetModifierStackCount("modifier_ability_thdots_hatate02_buff", caster)
        caster:SetModifierStackCount("modifier_ability_thdots_hatate02_buff", caster, stack + buff_count)
    end
    keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_ability_thdots_hatate02_buff", {
        Duration = keys.duration
    })
    if caster:GetModifierStackCount("modifier_ability_thdots_hatate02_buff", caster) == 0 then
        caster:SetModifierStackCount("modifier_ability_thdots_hatate02_buff", caster, buff_count)
    elseif caster:GetModifierStackCount("modifier_ability_thdots_hatate02_buff", caster) > max_stack then
        caster:SetModifierStackCount("modifier_ability_thdots_hatate02_buff", caster, max_stack)
    end
    for _, v in pairs(targets) do
        local attack = 0
        keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_ability_thdots_hatate02_debuff", {
            Duration = keys.duration
        })
        local effectIndex = ParticleManager:CreateParticle(
            "particles/econ/items/invoker/invoker_ti6/invoker_deafening_blast_ti6_knockback_debuff.vpcf",
            PATTACH_ABSORIGIN_FOLLOW, v)
        ParticleManager:DestroyParticleSystemTime(effectIndex, keys.duration)
        for i = 0, 5 do
            local item = caster:GetItemInSlot(i)
            if (item ~= nil) then
                local bonusAttack = item:GetSpecialValueFor("bonus_damage")
                if (bonusAttack ~= nil) then
                    attack = bonusAttack + attack
                end
            end
        end
        local damage_table = {
            ability = keys.ability,
            victim = v,
            attacker = caster,
            damage = keys.damage * (1 + caster:GetModifierStackCount("modifier_ability_thdots_hatate02_buff", caster)),
            damage_type = keys.ability:GetAbilityDamageType(),
            damage_flags = 0
        }
        UnitDamageTarget(damage_table)
        -- SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,v,keys.damage*3,nil)
    end
end

function Hatate02OnAttackLanded(keys)
    local target = keys.target
    if keys.target:HasModifier("modifier_ability_thdots_hatate02_debuff") then
        local damage_table = {
            ability = keys.ability,
            victim = target,
            attacker = keys.attacker,
            damage = keys.damage,
            damage_type = keys.ability:GetAbilityDamageType(),
            damage_flags = 1
        }
        UnitDamageTarget(damage_table)
        -- local mana_regen = keys.ability:GetSpecialValueFor("mana_regen")
        -- SendOverheadEventMessage(nil,OVERHEAD_ALERT_MANA_ADD,keys.attacker,mana_regen,nil)
        -- keys.attacker:SetMana(keys.attacker:GetMana() + mana_regen)
    end
end

function Hatate03OnIntervalThink(keys)
    local caster = keys.caster
    local duration = keys.duration
    local ability = keys.ability
    local count
    if (keys.ability:GetContext("ability_Hatate03_Count") == nil) then
        keys.ability:SetContextNum("ability_Hatate03_Count", 1000, 0)
    end
    count = keys.ability:GetContext("ability_Hatate03_Count")
    if FindTelentValue(caster, "special_bonus_unique_hatate_5") == 1 then
        count = 1000
    else
        count = count - 100 / duration
    end
    caster:SetModifierStackCount("modifier_ability_thdots_hatate03", caster, count)
    keys.ability:SetContextNum("ability_Hatate03_Count", count, 0)
end

function Hatate03ResetContext(keys)
    if (keys.ability:GetContext("ability_Hatate03_Count") == nil) then
        keys.ability:SetContextNum("ability_Hatate03_Count", 1000, 0)
    end
    keys.ability:SetContextNum("ability_Hatate03_Count", 1000, 0)
end

function Hatate04OnSpellStart(keys)
    if not IsServer() then return end
    local caster = keys.caster
    local ability = keys.ability
    -- local duration = keys.duration
    local ability02 = keys.caster:FindAbilityByName("ability_thdots_hatate02")
    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000,
        keys.ability:GetAbilityTargetTeam(), keys.ability:GetAbilityTargetType(), 0, 0, false)
    for _, v in pairs(targets) do
        if not v:HasModifier("modifier_illusion") and v:IsAlive() then
            local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/aya/ability_aya_02_mark.vpcf",
                PATTACH_CUSTOMORIGIN_FOLLOW, v)
            ParticleManager:DestroyParticleSystemTime(effectIndex, keys.duration)
            v:EmitSound("Hero_Tinker.GridEffect")
            local dummy
            if ability:GetLevel() == 1 then
                dummy = CreateUnitByName("npc_vision_dummy_unit", v:GetAbsOrigin(), false, caster, caster,
                    caster:GetTeam())
            else
                dummy = CreateUnitByName("npc_vision_hatate_dummy_unit", v:GetAbsOrigin(), false, caster, caster,
                    caster:GetTeam())
            end
            -- modifier可能立即进入回调，先绑定跟随目标再应用，避免读取未初始化target。
            if dummy == nil or dummy:IsNull() then return end
            dummy.target = v
            dummy:SetNightTimeVisionRange(keys.radius)
            dummy:SetDayTimeVisionRange(keys.radius)
            -- 在可能销毁dummy的modifier回调之前完成基础技能初始化。
            local ability_dummy_unit = dummy:FindAbilityByName("ability_dummy_unit")
            if ability_dummy_unit ~= nil and not ability_dummy_unit:IsNull() then
                ability_dummy_unit:SetLevel(1)
            end
            if dummy:IsNull() or dummy.hatateRemoving then return end
            ability:ApplyDataDrivenModifier(caster, dummy, "modifier_ability_thdots_hatate04_dummy", {
                Duration = keys.duration
            })
            ability:ApplyDataDrivenModifier(caster, v, "modifier_ability_thdots_hatate04", {
                Duration = keys.duration
            })
            if ability:GetLevel() == 3 and not dummy:IsNull() and not dummy.hatateRemoving then
                local abilityGEM = dummy:FindAbilityByName("ability_thdots_hatate04_unit")
                if abilityGEM ~= nil and not abilityGEM:IsNull() then
                    abilityGEM:SetLevel(1)
                    dummy:CastAbilityImmediately(abilityGEM, 0)
                end
            end
        end
    end
end

function Hatate04OnAttackLanded(keys)
    local stack = keys.caster:GetModifierStackCount("modifier_ability_thdots_hatate04_bonus", caster)
    local ability02 = keys.caster:FindAbilityByName("ability_thdots_hatate02")
    local actual_radius = ability02:GetSpecialValueFor("radius")
    local actual_duration = ability02:GetSpecialValueFor("duration")
    local actual_damage = ability02:GetSpecialValueFor("damage")
    local actual_max_stack = ability02:GetSpecialValueFor("max_stack")
    local actual_target_points = {}
    actual_target_points[1] = keys.target:GetOrigin()
    local attack_time = keys.ability:GetSpecialValueFor("attack_time")
    if stack >= attack_time then
        Hatate02OnSpellStart({
            caster = keys.caster,
            ability = ability02,
            radius = actual_radius,
            duration = actual_duration,
            target_points = actual_target_points,
            damage = actual_damage,
            max_stack = actual_max_stack
        })
        if stack > attack_time then
            keys.caster:SetModifierStackCount("modifier_ability_thdots_hatate04_bonus", caster, stack - attack_time + 1)
        else
            keys.caster:SetModifierStackCount("modifier_ability_thdots_hatate04_bonus", caster, 1)
        end
    else
        keys.caster:SetModifierStackCount("modifier_ability_thdots_hatate04_bonus", caster, stack + 1)
    end
end

function Hatate04DummyIntervalThink(keys)
    if not IsServer() then return end
    local dummy = keys.target
    if dummy == nil or dummy:IsNull() or dummy.hatateRemoving then return end
    local target = dummy.target
    -- 目标/施法者失效立即结束本dummy；不能让0.03秒回调持续报错。
    local caster = keys.caster
    if target == nil or target:IsNull() or not target:IsAlive() or caster == nil or caster:IsNull() then
        Hatate04DummyDestroy(keys)
        return
    end
    caster:SetContextNum("stack_bonus", keys.stack_bonus or 0, 0)
    dummy:SetOrigin(target:GetOrigin())
end

function Hatate04DummyDestroy(keys)
    if not IsServer() then return end
    local dummy = keys.target
    if dummy == nil or dummy:IsNull() or dummy.hatateRemoving then return end
    -- 先置幂等标记，避免ForceKill触发OnDestroy后再次删除同一实体。
    dummy.hatateRemoving = true
    if keys.caster ~= nil and not keys.caster:IsNull() then keys.caster:SetContextNum("stack_bonus", 0, 0) end
    dummy:ForceKill(false)
    if not dummy:IsNull() then dummy:RemoveSelf() end
end

function HatateExOnSpellStart(keys)
    local caster = keys.caster
    local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti9/teleport_start_ti9_lvl2.vpcf",
        PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:DestroyParticleSystemTime(effectIndex, keys.duration)
end

function HatateExOnDestroy(keys)
    local caster = keys.caster
    for i, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
        if fountain:GetTeamNumber() == caster:GetTeamNumber() then
            FindClearSpaceForUnit(caster, fountain:GetAbsOrigin(), true)
            break
        end
    end
end
