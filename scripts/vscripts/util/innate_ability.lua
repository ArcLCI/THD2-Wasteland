-- 天生技能管理

-- type0: 非天生技能
-- type1: 恒定1级
-- type2: 随终极技能成长等级而成长
-- type3: 每5级成长
function CDOTABaseAbility:InnateAbilityType()
    return 0
end

-- 初始化
function InitInnateAbilityForHero(hero)
    -- 按实际技能槽数量扫描，避免越界触发控制台警告。
    for i = 0, hero:GetAbilityCount() - 1 do
        local ability = hero:GetAbilityByIndex(i)
        if ability ~= nil and ability:InnateAbilityType() > 0 then
            local target_ability = ability
            hero:SetContextThink(target_ability:GetAbilityName(), function ()
if GameRules:IsGamePaused() then return 0.1 end
                local new_level = GetInnateAbilityLevel(target_ability,hero)
                if new_level ~= target_ability:GetLevel() then
                    target_ability:SetLevel(new_level)
                end
                return 1
            end
            , 1)
        end
    end
end

-- 获取天生应有等级
function GetInnateAbilityLevel(ability,hero)
    local type = ability:InnateAbilityType()
    local max_level = ability:GetMaxLevel()
    local hero_level = hero:GetLevel()
    
    local new_level = 1

    -- 恒定1级
    if type == 1 then return 1 end

    -- 随终极技能成长等级而成长
    if type == 2 then
        if hero_level >= 1 then new_level = 1 end
        if hero_level >= 6 then new_level = 2 end
        if hero_level >= 12 then new_level = 3 end
        if hero_level >= 18 then new_level = 4 end
    end

    -- 每5级成长
    if type == 3 then
        if hero_level >= 1 then new_level = 1 end
        if hero_level >= 6 then new_level = 2 end
        if hero_level >= 11 then new_level = 3 end
        if hero_level >= 16 then new_level = 4 end
        if hero_level >= 21 then new_level = 5 end
    end

    if new_level > max_level then
        return max_level
    else
        return new_level
    end
end
