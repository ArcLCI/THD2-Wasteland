-- 临时手动实机模式：真人英雄升至12级，每5秒施加2秒破坏，保留3秒恢复窗口。
local Mode = {ENABLED = true, LEVEL = 12, INTERVAL = 5, DURATION = 2}
local MODIFIER = "modifier_thd_reisen_test_break"
local THINK = "THD_ReisenBreakTest"
local heroes = {}

LinkLuaModifier(MODIFIER, "util/reisen_break_test", LUA_MODIFIER_MOTION_NONE)
modifier_thd_reisen_test_break = class({})
function modifier_thd_reisen_test_break:IsHidden() return false end
function modifier_thd_reisen_test_break:IsDebuff() return true end
function modifier_thd_reisen_test_break:IsPurgable() return false end
function modifier_thd_reisen_test_break:GetTexture() return "item_silver_edge" end
function modifier_thd_reisen_test_break:CheckState()
    return {[MODIFIER_STATE_PASSIVES_DISABLED] = true}
end

local function Attach(hero)
    if not Mode.ENABLED or not hero or hero:IsNull() or not hero:IsRealHero() or hero:IsIllusion() then return end
    local player = hero:GetPlayerOwnerID()
    if player < 0 or PlayerResource:IsFakeClient(player) then return end
    if heroes[hero] then return end
    heroes[hero] = true
    local prepared = false
    hero:SetContextThink(THINK, function()
        if hero:IsNull() then heroes[hero] = nil; return nil end
        if not Mode.ENABLED then
            hero:RemoveModifierByName(MODIFIER)
            heroes[hero] = nil
            return nil
        end
        if GameRules:IsGamePaused() then return 0.2 end
        -- 只作用于真人当前选中的本体，不处理分身、召唤物和Bot。
        if PlayerResource:GetSelectedHeroEntity(player) ~= hero then
            hero:RemoveModifierByName(MODIFIER)
            heroes[hero] = nil
            return nil
        end
        if not prepared then
            for level = hero:GetLevel(), Mode.LEVEL - 1 do hero:HeroLevelUp(false) end
            prepared = true
            print(string.format("[REISEN_BREAK_TEST] player=%d level=%d interval=%d duration=%d", player, hero:GetLevel(), Mode.INTERVAL, Mode.DURATION))
            return Mode.INTERVAL
        end
        if hero:IsAlive() then
            hero:AddNewModifier(hero, nil, MODIFIER, {duration = Mode.DURATION})
        end
        return Mode.INTERVAL
    end, 1)
end

function Mode:Start()
    if self.started then return end
    self.started = true
    ListenToGameEvent("npc_spawned", function(event)
        Attach(EntIndexToHScript(event.entindex))
    end, nil)
    -- 关闭时立即停止循环并清除测试破坏；重新开启可作用于已出生的玩家。
    Convars:RegisterCommand("thd_reisen_break_test", function(_, enabled)
        if enabled ~= "0" and enabled ~= "1" then
            print("Usage: thd_reisen_break_test 0|1")
            return
        end
        Mode.ENABLED = enabled == "1"
        if not Mode.ENABLED then
            for hero in pairs(heroes) do
                if not hero:IsNull() then
                    hero:SetContextThink(THINK, nil, 0)
                    hero:RemoveModifierByName(MODIFIER)
                end
            end
            heroes = {}
        else
            for player = 0, 63 do
                if PlayerResource:IsValidPlayerID(player) then
                    Attach(PlayerResource:GetSelectedHeroEntity(player))
                end
            end
        end
        print("[REISEN_BREAK_TEST] enabled=" .. tostring(Mode.ENABLED))
    end, "Temporary human hero level 12 and periodic break: 0 off, 1 on.", 0)
end

return Mode
