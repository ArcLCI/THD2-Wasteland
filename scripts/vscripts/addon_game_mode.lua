-- 这个文件是RPG载入的时候，游戏的主程序最先载入的文件
-- 一般在这里载入各种我们所需要的各种lua文件
-- 除了addon_game_mode以外，其他的部分都需要去掉


GameRules:EnableCustomGameSetupAutoLaunch(true)

EnableMegaCreeps = true
SendToServerConsole("dota_daynightcycle_pause 0")

G_Rune_Bounty_List = {1,1,1,1,1,1}
G_Rune_PowerUp_List = {1,1,1,1,1,1}
G_Rune_Bounty_Spwner_List = {}
G_Rune_PowerUp_Spwner_List = {}
-- 在线测试白名单
G_OnlineDebugWhiteList = {
	[259798081] = 1, -- QKzero
};
DOTA_BAN_LIST={
	"npc_dota_hero_morphling",--水人
	"npc_dota_hero_shredder",--伐木机-
	"npc_dota_hero_magnataur",--猛犸
	"npc_dota_hero_abaddon",--亚巴顿
	"npc_dota_hero_jakiro",--双头龙-
	"npc_dota_hero_phoenix",--凤凰-
	"npc_dota_hero_sand_king",--沙王-
	"npc_dota_hero_hoodwink",--松鼠-
	"npc_dota_hero_primal_beast",--兽-
	"npc_dota_hero_spirit_breaker",--白牛
	"npc_dota_hero_muerta",--奶绿-
	"npc_dota_hero_ancient_apparition",--冰魂
	"npc_dota_hero_shadow_shaman",--小Y
	"npc_dota_hero_shadow_demon",--毒狗
	"npc_dota_hero_enigma",--谜团
	"npc_dota_hero_keeper_of_the_light",--光之守卫
	"npc_dota_hero_tiny",--小小
	"npc_dota_hero_brewmaster",--酒仙
	"npc_dota_hero_beastmaster",--兽王
	"npc_dota_hero_windrunner",--风行者
	"npc_dota_hero_snapfire",--电炎绝手
	"npc_dota_hero_treant",--树人
	"npc_dota_hero_tusk",--巨牙海民
	"npc_dota_hero_medusa",--美杜莎
	"npc_dota_hero_techies",--工程师
	"npc_dota_hero_troll_warlord",--巨魔
	"npc_dota_hero_faceless_void",--虚空
	"npc_dota_hero_pudge",--帕吉
	"npc_dota_hero_antimage",--敌法
	"npc_dota_hero_slardar",--大鱼
	"npc_dota_hero_ringmaster",--百戏大王
	"npc_dota_hero_kez",--凯
	"npc_dota_hero_skeleton_king",--冥魂大帝
	"npc_dota_hero_alchemist",--炼金术士
	"npc_dota_hero_wisp",--艾欧
	"npc_dota_hero_pangolier",--石鳞剑士
	"npc_dota_hero_marci",--玛西
	"npc_dota_hero_nevermore",--影魔
	"npc_dota_hero_bloodseeker",--血魔
	"npc_dota_hero_ember_spirit",--灰烬之灵
}--dota乱入名单，请在activelist中同步修改
THD2_BAN_LIST ={
	
	--"npc_dota_hero_queenofpain",
	--"npc_dota_hero_arc_warden",
	-- "npc_dota_hero_ember_spirit",
	--"npc_dota_hero_dark_willow",
	--"npc_dota_hero_death_prophet",
	--"npc_dota_hero_winter_wyvern",
	--"npc_dota_hero_oracle",
}
-- 载入项目所有文件
require	("timers")
dofile  ( "util/neutral_items" )
require ( "util/constants" )
require ( "util/container" )
require ( "util/damage" )
require ( "util/stun" )
require ( "util/pauseunit" )
require ( "util/silence" )
require ( "util/magic_immune" )
local BotBackpackCastBridge = require ( "util/bot_backpack_cast_bridge" )
local SetupSurrenderGuard = require ( "util/setup_surrender_guard" )
require ( "util/timers" )
require ( "util/util" )
require ( "util/mode_select" )
require ( "util/disarmed" )
require ( "util/invulnerable" )
require ( "util/graveunit" )
require ( "util/collision" )
require ( "util/nodamage" )
require ( "util/CheckItemModifies")
require ( "util/performattack")
require ( "util/bot_courier")
require ( "util/lane_creep_protection")
require ( "util/create_illusion")
require ( "lib/selection")
require ( "components/modifiers/init" )
require ( "lib/libraries_init" )



--clothes
require ( "util/specialmode")
require ( "util/clothes")
require ( "util/eventregister")
require ( "util/observe")
require ( "util/rune_fixer")
require ( "util/neutral_spawner_fixer")
require ( "util/charge_manager")
require ( "util/webapi")
require ( "util/shuffle")
require ( "util/urd")
require ( "util/super_siege")
require ( "util/thd_wheel")
require ( "util/thd_secondary_ability")
require ( "util/camerayaw")
require ( "util/skill_change")
require ( "util/mushroom")
require ( "util/bot_wards")
require ( "util/heroselectoverlay")
require ( "util/innate_ability")
require ( "util/occult_ball" )
require ( "util/notifications" )
local perfDiagnosticsLoaded, perfDiagnosticsError = pcall(require, "util/perf_diagnostics")
if not perfDiagnosticsLoaded then
	print("[PERF] Failed to load perf diagnostics: " .. tostring(perfDiagnosticsError))
end

local function SetNativeBotThinkingForTest(enable, source)
	local ok, err = pcall(function()
		THD2_SetBotThinking(enable)
	end)
	local msg
	if ok then
		msg = string.format("[BOT] native BotThinking %s by %s", enable and "ENABLED" or "DISABLED", tostring(source or "manual"))
	else
		msg = "[BOT] failed to set native BotThinking: " .. tostring(err)
	end
	print(msg)
	GameRules:SendCustomMessage(msg, 0, 0)
end

Convars:RegisterCommand("thd_botthink", function(_, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	if arg == "on" or arg == "1" or arg == "true" then
		SetNativeBotThinkingForTest(true, "console")
	elseif arg == "off" or arg == "0" or arg == "false" then
		SetNativeBotThinkingForTest(false, "console")
	else
		print("[BOT] usage: thd_botthink 1/0 or on/off")
	end
end, "Toggle native Dota BotThinking for performance tests", 0)

Convars:RegisterCommand("thd_botthink_on", function()
	SetNativeBotThinkingForTest(true, "console")
end, "Enable native Dota BotThinking", 0)

Convars:RegisterCommand("thd_botthink_off", function()
	SetNativeBotThinkingForTest(false, "console")
end, "Disable native Dota BotThinking", 0)

local function SetFOWViewerForTest(enable, source)
	local ok, err = pcall(function()
		THD_SetFOWViewerEnabled(enable)
	end)
	local msg
	if ok then
		msg = string.format("[THD][FOW] AddFOWViewer %s by %s", enable and "ENABLED" or "DISABLED", tostring(source or "manual"))
	else
		msg = "[THD][FOW] failed to toggle AddFOWViewer: " .. tostring(err)
	end
	print(msg)
	GameRules:SendCustomMessage(msg, 0, 0)
end

local function SetContextThinkForTest(enable, source)
	local ok, err = pcall(function()
		THD_SetContextThinkEnabled(enable)
	end)
	local status = enable and "ENABLED" or "DISABLED"
	local message
	if ok then
		message = "[THD][ContextThink] " .. status .. " by " .. tostring(source or "unknown")
	else
		message = "[THD][ContextThink] failed: " .. tostring(err)
	end
	print(message)
	GameRules:SendCustomMessage(message, 0, 0)
end

local function SetNeutralSanitizerForTest(enable, source)
	local ok, err = pcall(function()
		THD_SetNeutralAbilitySanitizerEnabled(enable)
	end)
	local status = enable and "ENABLED" or "DISABLED"
	local message
	if ok then
		message = "[THD][NeutralSanitizer] " .. status .. " by " .. tostring(source or "unknown")
	else
		message = "[THD][NeutralSanitizer] failed: " .. tostring(err)
	end
	print(message)
	GameRules:SendCustomMessage(message, 0, 0)
end

Convars:RegisterCommand("thd_contextthink", function(_, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	local enable = arg == "1" or arg == "true" or arg == "on"
	if not enable and not (arg == "0" or arg == "false" or arg == "off") then
		print("[THD][ContextThink] usage: thd_contextthink 0/1")
		return
	end
	SetContextThinkForTest(enable, "console")
end, "Enable or disable THI wrapped SetContextThink calls", 0)

Convars:RegisterCommand("thd_contextthink_off", function()
	SetContextThinkForTest(false, "console")
end, "Disable THI wrapped SetContextThink calls", 0)

Convars:RegisterCommand("thd_contextthink_on", function()
	SetContextThinkForTest(true, "console")
end, "Enable THI wrapped SetContextThink calls", 0)

Convars:RegisterCommand("thd_sanitize_neutrals", function(_, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	local enable = arg == "1" or arg == "true" or arg == "on"
	if not enable and not (arg == "0" or arg == "false" or arg == "off") then
		print("[THD][NeutralSanitizer] usage: thd_sanitize_neutrals 0/1")
		return
	end
	SetNeutralSanitizerForTest(enable, "console")
end, "Enable or disable THI neutral native ability sanitizer", 0)

Convars:RegisterCommand("thd_sanitize_neutrals_off", function()
	SetNeutralSanitizerForTest(false, "console")
end, "Disable THI neutral native ability sanitizer", 0)

Convars:RegisterCommand("thd_sanitize_neutrals_on", function()
	SetNeutralSanitizerForTest(true, "console")
end, "Enable THI neutral native ability sanitizer", 0)

Convars:RegisterCommand("thd_neutral_spawner_fixer", function(_, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	local enable = arg == "1" or arg == "true" or arg == "on"
	if not enable and not (arg == "0" or arg == "false" or arg == "off") then
		print("[THD][NeutralSpawnerFixer] usage: thd_neutral_spawner_fixer 0/1")
		return
	end
	if THD_SetNeutralSpawnerFixerEnabled ~= nil then
		THD_SetNeutralSpawnerFixerEnabled(enable, "console")
	end
end, "Enable or disable THI neutral spawner fixer", 0)

Convars:RegisterCommand("thd_neutral_spawner_fixer_off", function()
	if THD_SetNeutralSpawnerFixerEnabled ~= nil then
		THD_SetNeutralSpawnerFixerEnabled(false, "console")
	end
end, "Disable THI neutral spawner fixer", 0)

Convars:RegisterCommand("thd_neutral_spawner_fixer_on", function()
	if THD_SetNeutralSpawnerFixerEnabled ~= nil then
		THD_SetNeutralSpawnerFixerEnabled(true, "console")
	end
end, "Enable THI neutral spawner fixer", 0)

Convars:RegisterCommand("thd_hidden_neutral_cleanup", function(_, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	local enable = arg == "1" or arg == "true" or arg == "on"
	if not enable and not (arg == "0" or arg == "false" or arg == "off") then
		print("[THD][HiddenNeutralCleanup] usage: thd_hidden_neutral_cleanup 0/1")
		return
	end
	if THD_SetHiddenNeutralCleanupEnabled ~= nil then
		THD_SetHiddenNeutralCleanupEnabled(enable, "console")
	end
end, "Enable or disable hidden invulnerable neutral cleanup", 0)

Convars:RegisterCommand("thd_hidden_neutral_cleanup_off", function()
	if THD_SetHiddenNeutralCleanupEnabled ~= nil then
		THD_SetHiddenNeutralCleanupEnabled(false, "console")
	end
end, "Disable hidden invulnerable neutral cleanup", 0)

Convars:RegisterCommand("thd_hidden_neutral_cleanup_on", function()
	if THD_SetHiddenNeutralCleanupEnabled ~= nil then
		THD_SetHiddenNeutralCleanupEnabled(true, "console")
	end
end, "Enable hidden invulnerable neutral cleanup", 0)

Convars:RegisterCommand("thd_hidden_neutral_cleanup_now", function()
	if THD_ForceCleanupHiddenInvulnerableNeutrals ~= nil then
		THD_ForceCleanupHiddenInvulnerableNeutrals("console")
	end
end, "Immediately cleanup hidden invulnerable neutrals ignoring grace", 0)

Convars:RegisterCommand("thd_hidden_neutral_cleanup_grace", function(_, value)
	if THD_SetHiddenNeutralCleanupGraceSeconds == nil or not THD_SetHiddenNeutralCleanupGraceSeconds(value) then
		print("[THD][HiddenNeutralCleanup] usage: thd_hidden_neutral_cleanup_grace seconds")
	end
end, "Set hidden neutral cleanup grace seconds", 0)

Convars:RegisterCommand("thd_neutral_cleanup_all", function()
	if THD_ForceCleanupAllNeutralUnits ~= nil then
		THD_ForceCleanupAllNeutralUnits("console")
	end
end, "Immediately remove all neutral creep units", 0)

Convars:RegisterCommand("thd_disable_neutrals_late", function()
	if THD_DisableNeutralsForLateGame ~= nil then
		THD_DisableNeutralsForLateGame("console")
	end
end, "Late-game emergency: remove all neutral creeps and enable hidden neutral cleanup with grace=0", 0)

Convars:RegisterCommand("thd_neutral_cleanup_all_on", function()
	if THD_SetAllNeutralCleanupEnabled ~= nil then
		THD_SetAllNeutralCleanupEnabled(true, "console")
	end
end, "Enable periodic all neutral creep cleanup", 0)

Convars:RegisterCommand("thd_neutral_cleanup_all_off", function()
	if THD_SetAllNeutralCleanupEnabled ~= nil then
		THD_SetAllNeutralCleanupEnabled(false, "console")
	end
end, "Disable periodic all neutral creep cleanup", 0)

Convars:RegisterCommand("thd_neutral_cleanup_all_toggle", function(_, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	local enable = arg == "1" or arg == "true" or arg == "on"
	if not enable and not (arg == "0" or arg == "false" or arg == "off") then
		print("[THD][AllNeutralCleanup] usage: thd_neutral_cleanup_all_toggle 0/1")
		return
	end
	if THD_SetAllNeutralCleanupEnabled ~= nil then
		THD_SetAllNeutralCleanupEnabled(enable, "console")
	end
end, "Enable or disable periodic all neutral creep cleanup", 0)

local function SetCombatExperimentFromConsole(flag, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	local enable = arg == "1" or arg == "true" or arg == "on"
	if not enable and not (arg == "0" or arg == "false" or arg == "off") then
		print("[THD][CombatExperiment] usage: 0/1 or on/off")
		return
	end
	if THD_SetCombatExperimentFlag ~= nil then
		THD_SetCombatExperimentFlag(flag, enable, "console")
	end
end

Convars:RegisterCommand("thd_hidden_neutral_no_attack", function(_, value)
	SetCombatExperimentFromConsole("hiddenNoAttack", value)
end, "Toggle hidden neutral no attack experiment", 0)

Convars:RegisterCommand("thd_hidden_neutral_no_acquire", function(_, value)
	SetCombatExperimentFromConsole("hiddenNoAcquire", value)
end, "Toggle hidden neutral no acquire experiment", 0)

Convars:RegisterCommand("thd_hidden_neutral_strip_abilities", function(_, value)
	SetCombatExperimentFromConsole("hiddenStripAbilities", value)
end, "Toggle hidden neutral strip all abilities experiment", 0)

Convars:RegisterCommand("thd_neutral_strip_abilities", function(_, value)
	SetCombatExperimentFromConsole("neutralStripAbilities", value)
end, "Toggle all neutral strip all abilities experiment", 0)

Convars:RegisterCommand("thd_neutral_remove_modifiers", function(_, value)
	SetCombatExperimentFromConsole("neutralRemoveSelectedModifiers", value)
end, "Toggle selected neutral modifier removal experiment", 0)

Convars:RegisterCommand("thd_lane_creep_low_acquire", function(_, value)
	SetCombatExperimentFromConsole("laneLowAcquire", value)
end, "Toggle lane creep low acquire experiment", 0)

Convars:RegisterCommand("thd_lane_creep_strip_abilities", function(_, value)
	SetCombatExperimentFromConsole("laneStripAbilities", value)
end, "Toggle lane creep strip all abilities experiment", 0)

Convars:RegisterCommand("thd_lane_creep_remove_modifiers", function(_, value)
	SetCombatExperimentFromConsole("laneRemoveSelectedModifiers", value)
end, "Toggle selected lane creep modifier removal experiment", 0)

Convars:RegisterCommand("thd_hero_attrs", function(_, value)
	if THD_SetAllHeroBaseAttributes == nil or not THD_SetAllHeroBaseAttributes(value, "console") then
		print("[THD][HeroExperiment] usage: thd_hero_attrs value")
	end
end, "Set all real heroes base str/agi/int", 0)

Convars:RegisterCommand("thd_hero_attrs_1", function()
	if THD_SetAllHeroBaseAttributes ~= nil then THD_SetAllHeroBaseAttributes(1, "console") end
end, "Set all real heroes base str/agi/int to 1", 0)

Convars:RegisterCommand("thd_hero_attrs_1000", function()
	if THD_SetAllHeroBaseAttributes ~= nil then THD_SetAllHeroBaseAttributes(1000, "console") end
end, "Set all real heroes base str/agi/int to 1000", 0)

Convars:RegisterCommand("thd_hero_vision", function(_, value)
	if THD_SetAllHeroVision == nil or not THD_SetAllHeroVision(value, "console") then
		print("[THD][HeroExperiment] usage: thd_hero_vision value")
	end
end, "Set all real heroes day/night vision", 0)

Convars:RegisterCommand("thd_hero_vision_100", function()
	if THD_SetAllHeroVision ~= nil then THD_SetAllHeroVision(100, "console") end
end, "Set all real heroes day/night vision to 100", 0)

Convars:RegisterCommand("thd_hero_restore", function()
	if THD_RestoreHeroExperiment ~= nil then THD_RestoreHeroExperiment("console") end
end, "Restore hero experiment attrs and vision", 0)

Convars:RegisterCommand("thd_fowviewer", function(_, value)
	local arg = value ~= nil and string.lower(tostring(value)) or ""
	if arg == "on" or arg == "1" or arg == "true" then
		SetFOWViewerForTest(true, "console")
	elseif arg == "off" or arg == "0" or arg == "false" then
		SetFOWViewerForTest(false, "console")
	else
		print("[THD][FOW] usage: thd_fowviewer 1/0 or on/off")
	end
end, "Toggle THI AddFOWViewer wrapper for accumulation tests", 0)

Convars:RegisterCommand("thd_fowviewer_on", function()
	SetFOWViewerForTest(true, "console")
end, "Enable THI AddFOWViewer wrapper", 0)

Convars:RegisterCommand("thd_fowviewer_off", function()
	SetFOWViewerForTest(false, "console")
end, "Disable THI AddFOWViewer wrapper", 0)

local botTable = {
    [DOTA_TEAM_GOODGUYS]    = {},
    [DOTA_TEAM_BADGUYS]     = {}
}

function _G.THD2_IsBotHero(unit)
	if unit == nil or unit:IsNull() then return false end
	if AddBotsToTable ~= nil then
		AddBotsToTable()
	end

	for _, teamBots in pairs(botTable) do
		for _, botHero in pairs(teamBots) do
			if botHero ~= nil and not botHero:IsNull() and botHero == unit then
				return true
			end
		end
	end

	return false
end

function _G.THD2_TeamHasBot(team)
	if AddBotsToTable ~= nil then
		AddBotsToTable()
	end

	local bots = botTable[team]
	if bots == nil then return false end
	for _, hero in pairs(bots) do
		if hero ~= nil and not hero:IsNull() then
			return true
		end
	end

	return false
end

local function THD2_IsBotPlayerID(playerID)
	if playerID == nil or playerID < 0 then return false end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then return true end
	if PlayerIsBot ~= nil and PlayerIsBot(playerID) then return true end
	return PlayerResource:GetSteamID(playerID) == PlayerResource:GetSteamID(100)
end

function _G.THD2_TeamIsPureBot(team)
	local playerCount = PlayerResource:GetPlayerCountForTeam(team)
	local validHeroCount = 0

	for index = 0, playerCount - 1 do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(team, index)
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local hero = player:GetAssignedHero()
			if hero ~= nil and not hero:IsNull() then
				validHeroCount = validHeroCount + 1
				if not THD2_IsBotPlayerID(playerID) then
					return false
				end
			end
		end
	end

	return validHeroCount > 0
end

if THDOTSGameMode == nil then
	THDOTSGameMode = {}
end

function Precache( context )

	if GetMapName() == "dota" then 
		--bot enable for default at dota map
		THD2_SetBotMode(true)
	end
	
	--clothes add(extra clothes,default should add first)
	add_cloth(
			"npc_dota_hero_templar_assassin",
			"models/thd2/sakuya_cloth01/sakuya_mmd_cloth01.vmdl",
			1.0, --not necessary
			3    --not necessary, minimal id usable for default
	)

	LinkLuaModifier("modifier_imba_roshan_ai", "components/modifiers/modifier_imba_roshan_ai.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("aura_ability_collection_find_master_lua", "scripts/vscripts/abilities/abilityCollection.lua", LUA_MODIFIER_MOTION_NONE)

	PrecacheResource( "model", "models/thd2/point.vmdl", context )--真の点数
	PrecacheResource( "model", "models/thd2/power.vmdl", context )--真のP点
	PrecacheResource( "model", "models/development/invisiblebox.vmdl", context )
	PrecacheResource( "model", "models/thd2/iku/iku_lightning_drill.vmdl", context )
	PrecacheResource( "particle", "particles/items_fx/aegis_respawn_spotlight.vpcf",context )--真のP点
	PrecacheResource( "particle", "particles/units/heroes/hero_mirana/mirana_base_attack.vpcf",context )--永琳弹道
	PrecacheResource( "particle", "particles/items2_fx/hand_of_midas.vpcf",context )--真の点数
	PrecacheResource( "particle_folder", "particles/thd2/heroes/reimu", context )--灵梦and跳台
	PrecacheResource( "particle", "particles/thd2/environment/death/act_hero_die.vpcf",context )--死亡
	PrecacheResource( "particle", "particles/environment/thd_rain.vpcf",context )--雨
	PrecacheResource( "particle", "particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf",context )--雨
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_visage.vsndevts", context )--灵梦and跳台
	PrecacheResource( "soundfile", "soundevents/game_sounds_custom.vsndevts", context )--背景音乐，BIU
	--PrecacheResource( "particle", "particles/thd2/chen_cast_4.vpcf", context )--激光

	-- 轮盘
	PrecacheResource( "soundfile", "soundevents/chat_wheel_sounds.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/thdots_yugi_sounds.vsndevts", context ) --星熊勇仪

	-- 语音
	local hReAssocVO = 	{
		npc_dota_hero_drow_ranger		 = "npc_dota_hero_drowranger",
		npc_dota_hero_sand_king			 = "npc_dota_hero_sandking",
		npc_dota_hero_obsidian_destroyer = "npc_dota_hero_outworld_destroyer",
		npc_dota_hero_shadow_shaman		 = "npc_dota_hero_shadowshaman",
		npc_dota_hero_witch_doctor		 = "npc_dota_hero_witchdoctor",
		npc_dota_hero_pangolier			 = "npc_dota_hero_pangolin",
		npc_dota_hero_crystal_maiden	 = "npc_dota_hero_crystalmaiden",
		npc_dota_hero_storm_spirit		 = "npc_dota_hero_stormspirit",
	}

	local hHeroList = LoadKeyValues("scripts/npc/activelist.txt")
	for sHero, sActive in pairs(hHeroList) do
		local sHeroVO = hReAssocVO[sHero] 
						and hReAssocVO[sHero] 
						or sHero
		
		PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_"..string.sub(sHeroVO, 15)..".vsndevts", context )
	end

	-- 单位模型
	local precachedModels = {}
	local hUnitList = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for sUnit, tKV in pairs(hUnitList) do
		if type(tKV) == "table" then
			local model = tKV["model"] or tKV["Model"] or nil
			if model ~= nil and not precachedModels[model] then
				precachedModels[model] = true

				PrecacheResource( "model", model, context )
			end
		end
	end

	PrecacheResource( "model", "models/props_gameplay/donkey.vmdl", context )--信使
	PrecacheResource( "model", "models/props_gameplay/donkey_wings.vmdl", context )--飞行信使

	PrecacheResource( "model", "models/thd2/yyy.vmdl", context )--灵梦D
	PrecacheResource( "model", "models/thd2/fantasy_seal.vmdl", context )--灵梦F

	PrecacheResource( "model", "models/thd2/youmu/youmu.vmdl", context )--妖梦R

	PrecacheResource( "model", "models/heroes/lycan/lycan_wolf.vmdl", context )--狗花D

	PrecacheResource( "particle", "particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_fallback_low_egset.vpcf", 
	context )--天子F
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context )--天子W
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_zuus", context )--天子W

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_tinker", context )--秋静叶大招

	PrecacheResource( "model", "models/props_gameplay/rune_haste01.vmdl", context )--魔理沙R
	PrecacheResource( "model", "models/thd2/masterspark.vmdl", context )--魔理沙 魔炮
	
	PrecacheResource( "particle", "particles/dire_fx/tower_bad_face_end_shatter.vpcf", context )--幽幽子F
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_death_prophet", context )--幽幽子D
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_bane", context )--幽幽子F
	PrecacheResource( "model", "models/thd2/yuyuko_fan.vmdl", context )--幽幽子W

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_phoenix", context )--妹红R	
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_phoenix.vsndevts", context )--妹红R
	PrecacheResource( "model", "models/thd2/firewing.vmdl", context )--妹红W	

	PrecacheResource( "particle", "particles/thd2/heroes/flandre/ability_flandre_04_buff.vpcf", context )--芙兰朵露	
	PrecacheResource( "particle", "particles/thd2/heroes/flandre/ability_flandre_04_effect.vpcf", context )--芙兰朵露

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_brewmaster", context )--红三
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts", context )--红三

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_tiny", context )--西瓜
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_tiny.vsndevts", context )--西瓜

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_night_stalker", context )--露米娅
	
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_disruptor", context )--永琳
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_disruptor.vsndevts", context )--永琳

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_night_stalker", context )--NEET

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_doom_bringer", context )--flandre04
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_phantom_assassin", context )--flandre04

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_tiny", context )--suika01
	-- PrecacheResource( "particle_folder", "particles/units/heroes/hero_dark_seer/dark_seer_surge_start_fallback_low.vpcf", context )-- 提琴

	PrecacheResource( "particle", "particles/econ/courier/courier_trail_orbit/courier_trail_orbit.vpcf", context )--超级兵特效
	PrecacheResource( "particle", "particles/units/heroes/hero_spectre/spectre_desolate_debuff.vpcf", context )--超级兵特效

	PrecacheResource( "model", "models/mushroom/mushroom.vmdl",context ) -- 蘑菇
	PrecacheResource( "particle", "particles/econ/items/phantom_assassin/phantom_assassin_weapon_hells_usher/phantom_assassin_hells_usher_ambient.vpcf", context )--超人卡
	PrecacheResource( "particle", "particles/econ/events/ti7/blink_dagger_end_ti7.vpcf", context )--9球
	PrecacheResource( "particle", "particles/econ/events/fall_2021/blink_dagger_fall_2021_start_lvl2.vpcf", context )--nb9球
	PrecacheResource( "particle", "particles/econ/events/fall_2021/blink_dagger_fall_2021_end_lvl2.vpcf", context )--nb9球
	PrecacheResource( "particle", "particles/units/heroes/hero_skeletonking/skeleton_king_weapon_blur_critical.vpcf", context )--楼观剑暴击
	PrecacheResource( "particle", "particles/units/heroes/hero_monkey_king/monkey_king_attack_01_blur_cud.vpcf", context )--二天一流连击
	PrecacheResource( "particle", "particles/econ/items/monkey_king/ti7_weapon/mk_ti7_crimson_strike_cast_motion_dark.vpcf", context )--二天一流暴击
	PrecacheResource( "particle", "particles/thd2/items/item_dragon_star.vpcf", context )--龙星
	PrecacheResource( "particle", "particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm.vpcf", context )--扇子
	PrecacheResource( "particle", "particles/items2_fx/sange_maim.vpcf", context )--诅咒木剑
	PrecacheResource( "particle", "particles/items4_fx/nullifier_mute_debuff.vpcf", context )--绯想剑
	PrecacheResource( "particle", "particles/items2_fx/heavens_halberd.vpcf", context )--庭师遗册
	PrecacheResource( "particle", "particles/thd2/items/item_frock.vpcf", context )--毒裙
	PrecacheResource( "particle", "particles/thd2/items/item_grudge_bow_grudge.vpcf", context )--恨弓
	PrecacheResource( "particle", "particles/econ/events/fall_major_2016/radiant_fountain_regen_fm06_lvl3.vpcf", context )--果篮
	PrecacheResource( "particle", "particles/items_fx/force_staff.vpcf", context )--推推
	PrecacheResource( "particle", "particles/status_fx/status_effect_forcestaff.vpcf", context )--推推
	PrecacheResource( "particle", "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf", context )--近战兔炮
	PrecacheResource( "particle", "particles/generic_gameplay/generic_lifesteal.vpcf", context )--吸血
	PrecacheResource( "particle", "particles/items3_fx/octarine_core_lifesteal.vpcf", context )--法术吸血
	PrecacheResource( "particle", "particles/items2_fx/veil_of_discord.vpcf", context )--流雏人形
	PrecacheResource( "particle", "particles/econ/items/necrolyte/necrophos_sullen/necro_sullen_pulse_friend.vpcf", context )--嫉妒之心眼
	PrecacheResource( "particle", "particles/econ/items/undying/undying_pale_augur/undying_pale_augur_decay_strength_xfer.vpcf", context )--嫉妒之心眼
	PrecacheResource( "particle", "particles/thd2/items/item_kafziel.vpcf", context )--死神镰刀
	PrecacheResource( "particle", "particles/items4_fx/spirit_vessel_damage.vpcf", context )--死神镰刀
	PrecacheResource( "particle", "particles/thd2/heroes/iku/iku_02.vpcf", context )--羽川
	PrecacheResource( "particle", "particles/items2_fx/magic_stick.vpcf", context )--便当
	PrecacheResource( "particle", "particles/thd2/items/item_morenjingjuan.vpcf", context )--魔人
	PrecacheResource( "particle", "particles/units/heroes/hero_enigma/enigma_ambient_body.vpcf", context )--魔人
	PrecacheResource( "particle", "particles/econ/items/silencer/silencer_ti6/silencer_last_word_status_ti6_ring_mist.vpcf", context )--破魔
	PrecacheResource( "particle", "particles/econ/items/storm_spirit/storm_spirit_orchid_hat/storm_spirit_orchid.vpcf", context )--破魔
	PrecacheResource( "particle", "particles/thd2/items/item_qijizhixing.vpcf", context )--奇迹之星
	PrecacheResource( "particle", "particles/items3_fx/glimmer_cape_initial.vpcf", context )--闪避布
	PrecacheResource( "particle", "particles/items2_fx/mask_of_madness.vpcf", context )--乳牙
	PrecacheResource( "particle", "particles/items2_fx/gleipnir_root.vpcf", context )--触手
	PrecacheResource( "particle", "particles/units/heroes/hero_bane/bane_sap.vpcf", context )--心眼
	PrecacheResource( "particle", "particles/items4_fx/combo_breaker_buff.vpcf", context )--替身
	PrecacheResource( "particle", "particles/thd2/items/item_umbrella_attach.vpcf", context )--舌头伞
	PrecacheResource( "particle", "particles/econ/items/windrunner/windrunner_cape_sparrowhawk/windrunner_windrun_sparrowhawk.vpcf", context )--大晕冲锋
	PrecacheResource( "particle", "particles/items_fx/abyssal_blade.vpcf", context )--大晕主动
	PrecacheResource( "particle", "particles/units/heroes/hero_lion/lion_spell_voodoo.vpcf", context )--hex
	PrecacheResource( "particle", "particles/thd2/items/item_lily.vpcf", context )--百合
	PrecacheResource( "particle", "particles/items2_fx/pipe_of_insight.vpcf", context )--笛子
	PrecacheResource( "particle", "particles/thd2/items/item_ballon.vpcf", context )--幽灵气球
	PrecacheResource( "particle", "particles/status_fx/status_effect_frost.vpcf", context )--围巾
	PrecacheResource( "particle", "particles/thd2/items/item_bad_man_card.vpcf", context )--坏人卡
	PrecacheResource( "particle", "particles/thd2/items/item_good_man_card.vpcf", context )--好人卡
	PrecacheResource( "particle", "particles/thd2/items/item_love_man_card.vpcf", context )--爱人卡
	PrecacheResource( "particle", "particles/thd2/items/item_unlucky_man_card.vpcf", context )--衰人卡
	PrecacheResource( "particle", "particles/units/heroes/hero_lich/lich_ambient_frost_legs.vpcf", context )--冰青蛙减速
	PrecacheResource( "particle", "particles/thd2/items/item_kafziel.vpcf", context )--镰刀
	PrecacheResource( "particle", "particles/base_attacks/ranged_tower_good_launch.vpcf", context )--绿刀
	PrecacheResource( "particle", "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf", context )--绿坝
	PrecacheResource( "particle", "particles/units/heroes/hero_brewmaster/brewmaster_windwalk.vpcf", context )--碎骨笛
	PrecacheResource( "particle", "particles/units/heroes/hero_medusa/medusa_mana_shield_shell_mod.vpcf", context )--碎骨笛
	PrecacheResource( "particle", "particles/thd2/items/item_camera.vpcf", context )--相机
	PrecacheResource( "particle", "particles/thd2/items/item_tsundere.vpcf", context )--无敌
	PrecacheResource( "particle", "particles/thd2/items/item_rocket.vpcf",context )--火箭
	PrecacheResource( "particle", "particles/thd2/items/item_mr_yang.vpcf",context )--电钻
	PrecacheResource( "particle", "particles/thd2/items/item_donation_gem.vpcf",context )--钱玉
	PrecacheResource( "particle", "particles/thd2/items/item_donation_box.vpcf",context )--钱箱
	--PrecacheResource( "particle", "particles/thd2/items/item_phoenix_wing.vpcf",context )--火凤凰之翼
	PrecacheResource( "particle", "particles/econ/events/ti10/radiance_owner_ti10.vpcf",context )--火凤凰之翼
	PrecacheResource( "particle", "particles/econ/events/ti10/radiance_ti10.vpcf",context )--火凤凰之翼
	PrecacheResource( "particle", "particles/thd2/items/item_darkred_umbrella_fog_attach.vpcf",context )--深红的雨伞 单位依附
	PrecacheResource( "particle", "particles/econ/items/sniper/sniper_charlie/sniper_base_attack_explosion_charlie.vpcf",context )--风枪
	PrecacheResource( "particle", "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf",context )--马王
	PrecacheResource( "particle", "particles/thd2/items/item_yatagarasu.vpcf",context )--八尺乌
	PrecacheResource( "particle", "particles/items2_fx/phase_boots.vpcf",context )--狐狸面具
	PrecacheResource( "particle", "particles/econ/items/windrunner/windranger_arcana/windranger_arcana_ambient.vpcf",context )--风神羽翼
	PrecacheResource( "particle", "particles/thd2/items/item_pocket_watch.vpcf",context )--秒表
	PrecacheResource( "particle", "particles/thd2/items/item_moon_bow.vpcf",context )--月弓
	PrecacheResource( "particle", "particles/items_fx/ethereal_blade.vpcf",context )--三次元
	PrecacheResource( "particle", "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf",context )--三次元
	PrecacheResource( "particle", "particles/items2_fx/mekanism.vpcf",context )--梅肯
	PrecacheResource( "particle", "particles/items3_fx/warmage_mana.vpcf",context )--秘法
	PrecacheResource( "particle", "particles/thd2/items/item_flower_umbrella_shield.vpcf", context )--花伞特效
	PrecacheResource( "particle", "particles/thd2/items/item_flower_umbrella_attach.vpcf", context )--花伞特效
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_templar_assassin.vsndevts", context )--花伞音效
	
	PrecacheResource( "model", "models/thd2/kaguya/kaguya.vmdl",context )

	--MMD

	PrecacheResource( "model", "models/thd2/reisen/reisen.vmdl",context )
	--PrecacheResource( "model", "models/thd2/reisen/reisenUnit.vmdl",context )

	PrecacheResource( "model", "models/thd2/marisa/marisa_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/tenshi/tenshi_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/flandre/flandre_mmd.vmdl",context )

	PrecacheResource( "model", "models/thd2/hiziri_byakuren/hiziri_byakuren_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/mokou/mokou_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/yuugi/yuugi_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/suika/suika_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/rumia/rumia_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/iku/iku_mmd.vmdl",context )

	PrecacheResource( "model", "models/thd2/youmu/youmu_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/eirin/eirin_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/yuyuko/yuyuko_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/utsuho/utsuho_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/sakuya/sakuya_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/remilia/remilia_mmd.vmdl", context)

	PrecacheResource( "model", "models/heroes/death_prophet/death_prophet_ghost.vmdl",context )

	PrecacheResource( "model", "models/thd2/yukkuri/yukkuri.vmdl",context )
	PrecacheResource( "model", "models/thd2/koishi/koishi_transform_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/koishi/koishi_w_mmd.vmdl",context )
	PrecacheResource( "model", "models/thd2/yumemi/yumemi_idousen.vmdl",context )

	PrecacheResource( "model", "models/thd2/kanako/kanako_mmd_transform.vmdl",context )
	PrecacheResource( "model", "models/thd2/kanako/kanako_mmd_transforming.vmdl",context )
	PrecacheResource( "model", "models/satori/satori.vmdl",context )
	PrecacheResource( "model", "models/new_touhou_model/satori/satori.vmdl",context )
	PrecacheResource( "model", "models/thd_hero/lunasa_prismriver/lunasa.vmdl",context )
	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/thdots_larva_sounds.vsndevts", context ) --爱塔妮缇·拉尔瓦
	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/thdots_exrumia_sounds.vsndevts", context)  --EX露米娅
	PrecacheResource( "model", "models/exrumia/exrumia.vmdl",context )
	PrecacheResource( "model", "models/flandrev2/flandrev2.vmdl",context )--flandrev2
	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/thdots_flandrev2_sounds.vsndevts", context) 
	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/thdots_miko_sounds.vsndevts", context) 
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/miko2.vsndevts", context) 
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_shadowshaman.vsndevts", context) 
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_void_spirit.vsndevts", context)  --神子V2

	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/kasen2.vsndevts", context)  --kasen2
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_enigma.vsndevts", context)  --kasen
	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/sagume.vsndevts", context)  --sagume
	PrecacheResource( "soundfile", "soundevents/thdots_hero_sounds/samurai.vsndevts", context)  --sagume

	PrecacheResource( "model", "models/new_touhou_model/aya/aya_with_wing.vmdl", context)
	PrecacheResource( "model", "models/exrumia/exrumia2.vmdl", context)
	PrecacheResource( "model", "models/exrumia/exrumia3.vmdl", context)
	PrecacheResource( "model", "models/ibaraki_kasen/ibaraki_kasen_2.vmdl", context)
	PrecacheResource( "model", "models/ibaraki_kasen/ibaraki_kasen_3.vmdl", context)
	PrecacheResource( "model", "models/keine2/keine2.vmdl", context)
	PrecacheResource( "model", "models/miko/miko_b.vmdl", context)
	PrecacheResource( "model", "models/nitori_cast1/nitori.vmdl", context)
	PrecacheResource( "model", "models/tei_pistol/tei2_pistol.vmdl", context)
	PrecacheResource( "model", "models/miko/miko_b.vmdl", context)

	-- clothes
	PrecacheResource( "model", "models/alice_cloth01/alice_cloth01.vmdl", context)
	PrecacheResource( "model", "models/thd2/yukari/yukari_mmd.vmdl", context)
	PrecacheResource( "model", "models/heroes/troll_warlord/troll_warlord.vmdl", context)
	PrecacheResource( "model", "models/flandre_scarlet_skin4/flandre_scarlet_skin4.vmdl", context)
	PrecacheResource( "model", "models/cirno2/cirno2.vmdl", context)
	PrecacheResource( "model", "models/hoshiguma/hoshiguma.vmdl", context)
	PrecacheResource( "model", "models/reisen/reisen_new.vmdl", context)

	--轮换的模型等
	PrecacheResource( "model", "models/heroes/warlock/warlock_demon.vmdl", context)  --地狱火
end

-- Create the game mode when we activate
function Activate()
	GameRules.THDOTSGameMode = THDOTSGameMode
	GameRules.THDOTSGameMode:InitGameMode()
	_G["AddonTemplate"] = THDOTSGameMode
end

-- 这个函数是addon_game_mode里面所写的，会在vlua.cpp执行的时候所执行的内容
function THDOTSGameMode:InitGameMode()
	print('[THDOTS] Starting to load THDots gamemode...')
	-- 在等待玩家之前保护未选队阶段，避免原生 60 秒全员断线判负。
	SetupSurrenderGuard:OnStateChange(GameRules:State_Get())
	-- 临时铃仙破坏实机模式，可用 thd_reisen_break_test 0 关闭。
	require("util/reisen_break_test"):Start()

	if PerfDiagnostics ~= nil then
		local ok, err = pcall(function()
			PerfDiagnostics:Start()
		end)
		if not ok then
			local message = "[PERF] failed to start diagnostics: " .. tostring(err)
			print(message)
			GameRules:SendCustomMessage(message, 0, 0)
		end
	else
		print("[PERF] diagnostics module is not loaded")
	end

	InitLogFile( "log/dota2x.txt","")
	-- 初始化记录文件
	-- 这个记录文件的路径是 dota 2 beta/dota/log/dota2x.txt
	-- 在有必要的时候，你可以使用  AppendToLogFile("log/dota2x.txt","记录内容")
	-- 来记录一些数据，避免游戏的崩溃了，却无法看到控制台的报错，无法判断是哪里出了问题

	-- 游戏事件监听
	-- 监听的API规则是
	-- ListenToGameEvent(API定义的事件名称或者我们自己程序发出的事件名称,事件触发之后执行的函数,LUA所有者)
	-- 这里所使用的 Dynamic_Wrap(THDOTSGameMode, 'OnEntityKilled') 其实就相当于self:OnEntityKilled
	-- 使用Dynamic_Wrap的好处是可以在控制台输入 developer 1之后，控制台显示一些额外的信息
	if self.__thd_event_listeners_registered == true then
		print("[THD][Event] main listeners already registered, skip")
	else
		self.__thd_event_listeners_registered = true

	ListenToGameEvent('entity_killed', Dynamic_Wrap(THDOTSGameMode, 'OnEntityKilled'), self)
	-- 监听单位被击杀的事件

	ListenToGameEvent('player_connect_full', Dynamic_Wrap(THDOTSGameMode, 'AutoAssignPlayer'), self)
	-- 监听玩家连接完成的事件，这里的函数 AutoAssignPlayer 是自动分配玩家英雄

	ListenToGameEvent('player_disconnect', Dynamic_Wrap(THDOTSGameMode, 'CleanupPlayer'), self)
	-- 监听玩家断开连接的事件，有时候当玩家断开连接，我们可能要为其清理英雄，储存相关数据，等他重连之后再重新赋给他

	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(THDOTSGameMode, 'AbilityUsed'), self)

	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(THDOTSGameMode, 'AbilityLearn'), self)

	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(THDOTSGameMode, 'Levelup'), self)

	ListenToGameEvent('npc_spawned', Dynamic_Wrap( THDOTSGameMode, 'OnHeroSpawned' ), self )

	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(THDOTSGameMode, 'OnGameRulesStateChange'), self)

	ListenToGameEvent('player_chat', Dynamic_Wrap(THDOTSGameMode, 'OnPlayerSay'), self)

	--ListenToGameEvent('dota_hero_random', Dynamic_Wrap(THDOTSGameMode, 'OnPlayerRandomChoose'), self) -- not working

	--ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(THDOTSGameMode, 'OnPlayerRandomChoose'), self)

	ListenToGameEvent("dota_item_picked_up", Dynamic_Wrap(THDOTSGameMode, 'OnItemPickedUp'), self)

	-- ListenToGameEvent("dota_item_purchase", Dynamic_Wrap(THDOTSGameMode, 'OnItemPurchase'), self)
	ListenToGameEvent("dota_item_purchase", Dynamic_Wrap(THDOTSGameMode, 'On_dota_item_purchase'), self)

	ListenToGameEvent("dota_item_purchased", Dynamic_Wrap(THDOTSGameMode, 'On_dota_item_purchased'), self)

	ListenToGameEvent("dota_pause_event", Dynamic_Wrap(THDOTSGameMode, 'On_dota_pause_event'), self)

	ListenToGameEvent("dota_inventory_item_added", Dynamic_Wrap(THDOTSGameMode, 'On_dota_inventory_item_added'), self)
	end

end

function Split(szFullString, szSeparator)  
	local nFindStartIndex = 1  
	local nSplitIndex = 1  
	local nSplitArray = {}  
	while true do  
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
		if not nFindLastIndex then  
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
			break  
		end  
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
		nSplitIndex = nSplitIndex + 1  
	end  
	return nSplitArray  
end

function GetCurrentTime()
	-- hour, minute, second
	return string.match(GetSystemTime(), '(%d+)[:](%d+)[:](%d+)')
end

function GetHostPlayer()  --获取当前主机(房主)玩家的句柄
	for i=0,63 do
		local plyhd = PlayerResource:GetPlayer(i)
		-- 验证玩家是否为主机
		local is_host = GameRules:PlayerHasCustomGameHostPrivileges(plyhd)
		if is_host then return plyhd end
	end
	return nil
end

-- 验证玩家是否为主机
function IsHost( key )
	local i = tonumber(key)
	if i ~= nil then -- number
		local plyhd = PlayerResource:GetPlayer(i)
		return GameRules:PlayerHasCustomGameHostPrivileges(plyhd)
	else 
		return GameRules:PlayerHasCustomGameHostPrivileges(key)
	end
end

function HostSay( text )  --由主机发送某条消息(当做日志, 提示等, 发送给所有人)
	--Say(GetHostPlayer(),text,false)
	GameRules:SendCustomMessage("<font color='#00FFFF'>" .. text .. "</font>", 0, 0)
end

boolstr = {
	[true] = "Yes",
	[false] = "No"
}

G_Player_Pause_Count = {0,0,0,0,0,0,0,0,0,0,0,0,0,0}
G_Player_Cloth = {1,1,1,1,1,1,1,1,1,1,1,1,1,1}
G_Player_IsCoach = {0,0,0,0,0,0,0,0,0,0,0,0,0,0}
MAX_Pause_Count = 6

function DisplayChampion( caster )
	local unit = CreateUnitByName(
		"npc_vision_dummy_unit"
		,caster:GetOrigin()
		,false
		,caster
		,caster
		,caster:GetTeam()
	)
	unit:FindAbilityByName("ability_invisible_dummy_unit"):SetLevel(1)

	local effectIndex = ParticleManager:CreateParticle("particles/champion/champion.vpcf", PATTACH_CUSTOMORIGIN, caster) 
	ParticleManager:SetParticleControlEnt(effectIndex , 0, caster, 5, "attach_hitloc", Vector(0,0,0), true)

	Timer.Loop 'DisplayChampion' ( 0.1, 5 * 10,
			function(i)
				unit:SetOrigin(caster:GetOrigin())
				if i == 5 * 10 then
					unit:RemoveSelf()
					ParticleManager:DestroyParticleSystem(effectIndex,true)
					return true
				end
			end
	)
end

ThdotsLab = false
TestMode = false
RDC_MODE = false
fakerank={}
BP_MODE = false
function THDOTSGameMode:OnPlayerSay( keys )
	local text = keys.text
	-- 获取玩家的id与handle
	local plyid = keys.playerid
	if plyid < 0 then return end --console
	local plyhd = PlayerResource:GetPlayer(plyid)
	-- 验证玩家是否为主机(影响接下来某些选项的设置权)
	local is_host = GameRules:PlayerHasCustomGameHostPrivileges(plyhd)
	-- is_host 的值就是发言的玩家是否为主机
	local tmp = "false"
	if is_host then tmp = "true" end
	print("player " .. plyid .. " says " .. text )
	print("player is host: " .. tmp )
	
	local ss = Split( text, " " )
	local command = ss[1]
	if command ~= nil then
		command = string.lower(command)
	end

	if command == "-botthinkoff" or command == "-botthinkon" or command == "-botthink" then
		local enable = command == "-botthinkon"
		if command == "-botthink" then
			local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
			enable = arg == "on" or arg == "1" or arg == "true"
			if not enable and not (arg == "off" or arg == "0" or arg == "false") then
				GameRules:SendCustomMessage("[BOT] usage: -botthink on/off, -botthinkon, -botthinkoff", 0, 0)
				return
			end
		end

		SetNativeBotThinkingForTest(enable, "chat")
		return
	end

	if command == "-contextthinkoff" or command == "-contextthinkon" or command == "-contextthink" then
		local enable = command == "-contextthinkon"
		if command == "-contextthink" then
			local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
			enable = arg == "on" or arg == "1" or arg == "true"
			if not enable and not (arg == "off" or arg == "0" or arg == "false") then
				GameRules:SendCustomMessage("[THD][ContextThink] usage: -contextthink on/off, -contextthinkon, -contextthinkoff", 0, 0)
				return
			end
		end

		SetContextThinkForTest(enable, "chat")
		return
	end

	if command == "-sanitize_neutrals_off" or command == "-sanitize_neutrals_on" or command == "-sanitize_neutrals" then
		local enable = command == "-sanitize_neutrals_on"
		if command == "-sanitize_neutrals" then
			local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
			enable = arg == "on" or arg == "1" or arg == "true"
			if not enable and not (arg == "off" or arg == "0" or arg == "false") then
				GameRules:SendCustomMessage("[THD][NeutralSanitizer] usage: -sanitize_neutrals on/off", 0, 0)
				return
			end
		end

		SetNeutralSanitizerForTest(enable, "chat")
		return
	end

	if command == "-neutral_spawner_fixer_off" or command == "-neutral_spawner_fixer_on" or command == "-neutral_spawner_fixer" then
		local enable = command == "-neutral_spawner_fixer_on"
		if command == "-neutral_spawner_fixer" then
			local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
			enable = arg == "on" or arg == "1" or arg == "true"
			if not enable and not (arg == "off" or arg == "0" or arg == "false") then
				GameRules:SendCustomMessage("[THD][NeutralSpawnerFixer] usage: -neutral_spawner_fixer on/off", 0, 0)
				return
			end
		end

		if THD_SetNeutralSpawnerFixerEnabled ~= nil then
			THD_SetNeutralSpawnerFixerEnabled(enable, "chat")
		else
			GameRules:SendCustomMessage("[THD][NeutralSpawnerFixer] setter is not loaded", 0, 0)
		end
		return
	end

	if command == "-hidden_neutral_cleanup_off" or command == "-hidden_neutral_cleanup_on" or command == "-hidden_neutral_cleanup" then
		local enable = command == "-hidden_neutral_cleanup_on"
		if command == "-hidden_neutral_cleanup" then
			local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
			enable = arg == "on" or arg == "1" or arg == "true"
			if not enable and not (arg == "off" or arg == "0" or arg == "false") then
				GameRules:SendCustomMessage("[THD][HiddenNeutralCleanup] usage: -hidden_neutral_cleanup on/off", 0, 0)
				return
			end
		end

		if THD_SetHiddenNeutralCleanupEnabled ~= nil then
			THD_SetHiddenNeutralCleanupEnabled(enable, "chat")
		else
			GameRules:SendCustomMessage("[THD][HiddenNeutralCleanup] setter is not loaded", 0, 0)
		end
		return
	end

	if command == "-hidden_neutral_cleanup_now" then
		if THD_ForceCleanupHiddenInvulnerableNeutrals ~= nil then
			THD_ForceCleanupHiddenInvulnerableNeutrals("chat")
		else
			GameRules:SendCustomMessage("[THD][HiddenNeutralCleanup] force cleanup is not loaded", 0, 0)
		end
		return
	end

	if command == "-neutral_cleanup_all" then
		if THD_ForceCleanupAllNeutralUnits ~= nil then
			THD_ForceCleanupAllNeutralUnits("chat")
		else
			GameRules:SendCustomMessage("[THD][AllNeutralCleanup] cleanup is not loaded", 0, 0)
		end
		return
	end

	if command == "-disable_neutrals_late" then
		if THD_DisableNeutralsForLateGame ~= nil then
			THD_DisableNeutralsForLateGame("chat")
		else
			GameRules:SendCustomMessage("[THD][DisableNeutralsLate] function is not loaded", 0, 0)
		end
		return
	end

	if command == "-neutral_cleanup_all_on" or command == "-neutral_cleanup_all_off" or command == "-neutral_cleanup_all_toggle" then
		local enable = command == "-neutral_cleanup_all_on"
		if command == "-neutral_cleanup_all_toggle" then
			local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
			enable = arg == "on" or arg == "1" or arg == "true"
			if not enable and not (arg == "off" or arg == "0" or arg == "false") then
				GameRules:SendCustomMessage("[THD][AllNeutralCleanup] usage: -neutral_cleanup_all_toggle on/off", 0, 0)
				return
			end
		end
		if THD_SetAllNeutralCleanupEnabled ~= nil then
			THD_SetAllNeutralCleanupEnabled(enable, "chat")
		end
		return
	end

	if command == "-hidden_no_attack" or command == "-hidden_no_acquire" or command == "-hidden_strip_abilities" or command == "-neutral_strip_abilities" or command == "-neutral_remove_modifiers" or command == "-lane_low_acquire" or command == "-lane_strip_abilities" or command == "-lane_remove_modifiers" then
		local flagByCommand = {
			["-hidden_no_attack"] = "hiddenNoAttack",
			["-hidden_no_acquire"] = "hiddenNoAcquire",
			["-hidden_strip_abilities"] = "hiddenStripAbilities",
			["-neutral_strip_abilities"] = "neutralStripAbilities",
			["-neutral_remove_modifiers"] = "neutralRemoveSelectedModifiers",
			["-lane_low_acquire"] = "laneLowAcquire",
			["-lane_strip_abilities"] = "laneStripAbilities",
			["-lane_remove_modifiers"] = "laneRemoveSelectedModifiers",
		}
		local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
		local enable = arg == "on" or arg == "1" or arg == "true"
		if not enable and not (arg == "off" or arg == "0" or arg == "false") then
			GameRules:SendCustomMessage("[THD][CombatExperiment] usage: " .. command .. " on/off", 0, 0)
			return
		end
		if THD_SetCombatExperimentFlag ~= nil then
			THD_SetCombatExperimentFlag(flagByCommand[command], enable, "chat")
		else
			GameRules:SendCustomMessage("[THD][CombatExperiment] setter is not loaded", 0, 0)
		end
		return
	end

	if command == "-hero_attrs" or command == "-hero_vision" or command == "-hero_restore" then
		if command == "-hero_restore" then
			if THD_RestoreHeroExperiment ~= nil then THD_RestoreHeroExperiment("chat") end
			return
		end
		local value = ss[2]
		if command == "-hero_attrs" then
			if THD_SetAllHeroBaseAttributes == nil or not THD_SetAllHeroBaseAttributes(value, "chat") then
				GameRules:SendCustomMessage("[THD][HeroExperiment] usage: -hero_attrs value", 0, 0)
			end
		else
			if THD_SetAllHeroVision == nil or not THD_SetAllHeroVision(value, "chat") then
				GameRules:SendCustomMessage("[THD][HeroExperiment] usage: -hero_vision value", 0, 0)
			end
		end
		return
	end

	if command == "-fowvieweroff" or command == "-fowvieweron" or command == "-fowviewer" then
		local enable = command == "-fowvieweron"
		if command == "-fowviewer" then
			local arg = ss[2] ~= nil and string.lower(ss[2]) or ""
			enable = arg == "on" or arg == "1" or arg == "true"
			if not enable and not (arg == "off" or arg == "0" or arg == "false") then
				GameRules:SendCustomMessage("[THD][FOW] usage: -fowviewer on/off, -fowvieweron, -fowvieweroff", 0, 0)
				return
			end
		end

		SetFOWViewerForTest(enable, "chat")
		return
	end

	if command == "-perfdiag" or command == "-perfdump" or command == "-perfdetail" or command == "-perfdumpdetail" then
		if PerfDiagnostics == nil then
			GameRules:SendCustomMessage("[PERF] PerfDiagnostics is not loaded", 0, 0)
		else
			local ok, err = pcall(function()
				if command == "-perfdump" then
					PerfDiagnostics:DumpHistory(false)
				elseif command == "-perfdumpdetail" then
					PerfDiagnostics:DumpHistory(true)
				elseif command == "-perfdetail" then
					PerfDiagnostics:PrintSnapshot("manual_detail")
				else
					PerfDiagnostics:PrintSnapshot("manual")
				end
			end)
			if not ok then
				local msg = "[PERF] " .. tostring(command) .. " failed: " .. tostring(err)
				print(msg)
				GameRules:SendCustomMessage(msg, 0, 0)
			end
		end
		return
	end

	-- 白名单用户可用
	if G_OnlineDebugWhiteList[PlayerResource:GetSteamAccountID(plyid)] ~= nil then
		if (ss[1] == "-k" or ss[1] == "-kill") then
            local hero = PlayerResource:GetSelectedHeroEntity(plyid)
            hero:Kill(nil, hero)
        elseif (ss[1] == "-rh" or ss[1] == "-replacehero") then
            local hero = PlayerResource:GetSelectedHeroEntity(plyid)
            local newHeroName = ss[2]
            local properties = {}
            for i = 3, #ss do
                properties[ss[i]] = 1
            end
            if (hero ~= nil and newHeroName ~= nil) then
                if string.sub(newHeroName, 1, string.len("npc_dota_hero_")) ~= "npc_dota_hero_" then
                    newHeroName = "npc_dota_hero_" .. newHeroName
                end
                local gold = hero:GetGold()
                local xp = hero:GetCurrentXP()
                if properties["-ug"] == 1 then
                    gold = 0
                end
                if properties["-ux"] == 1 then
                    xp = 0
                end
                PlayerResource:ReplaceHeroWith(plyid, newHeroName, gold, xp)
            end
        elseif (ss[1] == "-pi" or ss[1] == "-printitem") then
            local hero = PlayerResource:GetSelectedHeroEntity(plyid)
            if hero ~= nil then
                local items = {}
                for i = 0, 11 do
                    local item = hero:GetItemInSlot(i)
                    if item ~= nil then
                        items[i] = item:GetName()
                    end
                end
                print_r(items)
            end
        elseif (ss[1] == "-pm" or ss[1] == "-printmodifier") then
            local hero = PlayerResource:GetSelectedHeroEntity(plyid)
            if hero ~= nil then
                local modifiers = hero:FindAllModifiers()
				for i = 1, #modifiers do
					modifiers[i] = modifiers[i]:GetName()
				end
				print_r(modifiers)
            end
        elseif (ss[1] == "-am" or ss[1] == "-addmodifier") then
            local hero = PlayerResource:GetSelectedHeroEntity(plyid)
            if hero ~= nil then
                local modifier_name = ss[2]
                if modifier_name ~= nil then
                    hero:AddNewModifier(hero, nil, modifier_name, {})
                end
            end
        elseif (ss[1] == "-rm" or ss[1] == "-removemodifier") then
            local hero = PlayerResource:GetSelectedHeroEntity(plyid)
            if hero ~= nil then
                local modifier_name = ss[2]
                if modifier_name ~= nil then
                    hero:RemoveModifierByName(modifier_name)
                end
            end
        elseif (ss[1] == "-pp" or ss[1] == "-printPosition") then
            local hero = PlayerResource:GetSelectedHeroEntity(plyid)
            if hero ~= nil then
				print(hero:GetOrigin())
            end
        end
	end

	if is_host then  --主机限定的指令(所有图通用)
		if command == "-testbot" then
			local hero_name = ss[2]
			if hero_name == nil then
				--hero_name = "npc_dota_hero_mirana"
				hero_name = "npc_dota_hero_chaos_knight"
			end
			THD2_SetJustForFunMode(plyhd,2)
			THD2_SetTeamHero(2,hero_name)
			THD2_SetTeamHero(3,hero_name)
			THD2_SetFRSMode(true)
			THD2_SetPlayerPerTeam(12)
			THD2_ChangeBotDifficulty(plyhd,4)
		end
		
		if ss[1] == "-clear_item" then
			--clear_item item_yuetufensuijvren
			for i = 0,63 do
				if PlayerResource:GetPlayer(i) ~= nil then
					print(i)
					local playerhero = PlayerResource:GetPlayer(i):GetAssignedHero()
					if playerhero ~= nil then
						for j=0,11 do
							local it=playerhero:GetItemInSlot(j)
							if it~=nil and (ss[2]==nil or ss[2]==it:GetName()) then
								UTIL_Remove(it)
							end
						end
					end
				end
			end
		end
		
		
		if ss[1] == "-perf_test1" and IsInToolsMode() then
			local x = tonumber(ss[2])
			if x == nil then x=1 end
			THD_SetContextThink(plyhd:GetAssignedHero(), DoUniqueString("perf_test1"),
				function()
					local c_dummy = 0
					local targets = {}
					for i=1,x do
						targets = FindUnitsInRadius(
							plyhd:GetTeamNumber(),
							Vector(RandomInt(1,1999), RandomInt(1,1999), 256),
							nil,
							RandomInt(9999,99999),
							DOTA_UNIT_TARGET_TEAM_BOTH,
							DOTA_UNIT_TARGET_ALL,
							DOTA_UNIT_TARGET_FLAG_NONE,
							FIND_ANY_ORDER,
							false
						)
						for i,v in pairs(targets) do
							if v:FindAbilityByName("ability_dummy_unit") ~=nil then
								c_dummy = c_dummy + 1
							end
						end
					end
					HostSay( "一共有" .. #targets .. "个单位" )

					HostSay( "一共有" .. c_dummy .. "个dummy" )
				end,
			0.03, "perf_test1")
		end
		
		if text == "-CountUnits" then
			local targets = FindUnitsInRadius(
				plyhd:GetTeamNumber(),
				Vector(0, 0, 256),
				nil,
				99999,
				DOTA_UNIT_TARGET_TEAM_BOTH,
				DOTA_UNIT_TARGET_ALL,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_ANY_ORDER,
				false
			)
			HostSay( "一共有" .. #targets .. "个单位" )
			local c_dummy = 0
			for i,v in pairs(targets) do
				if v:FindAbilityByName("ability_dummy_unit") ~=nil then
					c_dummy = c_dummy + 1
				end
			end
			
			HostSay( "一共有" .. c_dummy .. "个dummy" )
		end

		if text == "-labmode" then
			ThdotsLab = true
		end

		if text == "-quitlab" then
			ThdotsLab = false
		end

		if text == "-testmode" then
			EnableMegaCreeps = false
			TestMode = true
			GameRules:SetCreepSpawningEnabled(false)
			GameRules:ForceGameStart()
			SendToServerConsole("dota_easybuy 1")
			SendToServerConsole("dota_kill_buildings")
			SendToServerConsole("dota_daynightcycle_pause 1")
			HostSay("昼夜循环已关闭")
			HostSay("控制台输入dota_daynightcycle_toggle切换昼夜")
			SendToServerConsole("dota_daynightcycle_toggle")
		end

		if ss[1] == "-test.respawn" and (TestMode == true or IsInToolsMode()) then	--设定重生时间
			local x = tonumber(ss[2])
			GameMode:SetFixedRespawnTime( x )
			HostSay("RespawnTime Set to "..x)
		end

		if ss[1] == "-test.createunits" and (TestMode == true or IsInToolsMode()) then
			-- -test.createunits 10 npc_dota_neutral_kobold enemy
			local num = ss[2]
			local name = ss[3]
			local team
			local location = plyhd:GetAssignedHero():GetCursorPosition()	-- 不知道为什么是地图原点，能用就行

			if ss[4] ~= nil then
				if ss[4] == "enemy" then
					if plyhd:GetTeam() == 3 then
						team = 2
					else
						team = 3	-- 队伍不是夜魇就召唤夜魇的
					end
				else
					team = plyhd:GetTeam()
				end
			else
				team = plyhd:GetTeam()
			end

			for i=1, num do
				CreateUnitByName(name, location, true, nil, nil, team)
			end
		end

		if GameRules:State_Get() == 2 and text == "-rankdc" and not THD2_GetBotMode() and not RDC_MODE and not BP_MODE then
			RDC_MODE = true
			GameRules:SendCustomMessage("#RANKDC_Explain2",0,0)
			GameRules:SendCustomMessage("#RANKDC_Explain3",0,0)
			GameRules:SendCustomMessage("#RANKDC_Explain4",0,0)
		end
		if GameRules:State_Get() == 2 and text == "-bp" and not THD2_GetBotMode() and not BP_MODE and not RDC_MODE then
			BP_MODE = true
			--注意这里选人界面还没载入, 所以不会禁用随机按钮, 但是lua禁用了随机所以按了也没用
			THD_Set_Random_Usable(false)
			GameRules:SetHeroSelectionTime(20);
			GameRules:SetHeroSelectPenaltyTime(0);
			GameRules:SendCustomMessage("#BP_Explain2",0,0)
			GameRules:SendCustomMessage("#BP_Explain3",0,0)
			GameRules:SendCustomMessage("#BP_Explain4",0,0)
			--GameRules:SendCustomMessage("#BP_New_Explain1",0,0)
		end
		if text == "-reset_hero" then 
			GameRules:ResetToHeroSelection()
			return
		end
		if text == "-find_thinker" then
			local tmp = Entities:FindAllInSphere(Vector(0,0,0),300)
			print("#tmp is :")
			print(#tmp)
			for _,v in pairs(tmp) do
				-- print('==================================')
				-- print(v:GetOrigin())
				-- print(v:GetName())
				-- print('+++++++++++++++++++++++++++++++++++')
			end
			return
		end

		if text == "-checkfort" then
			local zzz=Entities:FindAllByClassname("npc_dota_fort")
			for _,v in pairs(zzz) do
				print('---------------')
				print(v:GetOrigin())
				print(v:GetClassname()..":")
				print(v:GetTeam())
				print(v:GetHealth())
				print('---------------')
			end
		elseif text == "-print_nearby_abilities" then
			local tmp = Entities:FindAllInSphere(PlayerResource:GetPlayer(plyid):GetAssignedHero():GetOrigin(),300)
			for _,v in pairs(tmp) do
				print('==================================')
				print(v:GetOrigin())
				if v:IsBaseNPC() then
					print("Name: "..v:GetUnitName())
				end
				print("BaseClass: "..v:GetClassname())
				if not v:IsBaseNPC() then return end
				print("Abilities: ")
				local cnt = v:GetAbilityCount()
				-- 按实际技能槽数量扫描，避免越界触发控制台警告。
				for i=0,cnt - 1 do
					local ability = v:GetAbilityByIndex(i)
					if ability ~= nil then
						print(ability:GetAbilityName())
					end
				end
				print('+++++++++++++++++++++++++++++++++++')
			end
			return
		end
	
		if text == "-print_nearby_modifiers" then
			local tmp = Entities:FindAllInSphere(PlayerResource:GetPlayer(plyid):GetAssignedHero():GetOrigin(),300)
			for _,v in pairs(tmp) do
				print('---------------')
				print(v:GetOrigin())
				print(v:GetClassname()..":")
				if not v:IsBaseNPC() then return end
				print("Modifiers: ")
				local cnt = v:GetModifierCount()
				for i=0,cnt do
					print(v:GetModifierNameByIndex(i))
				end
				print('---------------')
			end
			return
		end

		if text == "-print_nearby_entities" then
			local tmp = Entities:FindAllInSphere(PlayerResource:GetPlayer(plyid):GetAssignedHero():GetOrigin(),300)
			for k,v in pairs(tmp) do
				print('---------------')
				print(v:GetOrigin())
				if v:IsBaseNPC() then
					print("Name: "..v:GetUnitName())
				end
				print("BaseClass: "..v:GetClassname())
				if not v:IsBaseNPC() then return end
				print("Modifiers: ")
				local cnt = v:GetModifierCount()
				for i=0,cnt do
					print(v:GetModifierNameByIndex(i))
				end
				print('---------------')
			end
			return
		end

		if text == "-print_nearby_models" then
			local tmp = Entities:FindAllInSphere(PlayerResource:GetPlayer(plyid):GetAssignedHero():GetOrigin(),300)
			for k,v in pairs(tmp) do
				print('---------------')
				print(v:GetOrigin())
				if v:IsBaseNPC() then
					print("Name: "..v:GetUnitName())
					print("Modle: "..v:GetModelName())
				end
				print("BaseClass: "..v:GetClassname())
				print('---------------')
			end
			return
		end
		
		if text == "-print_nearby_item" then
			local tmp = Entities:FindAllInSphere(PlayerResource:GetPlayer(plyid):GetAssignedHero():GetOrigin(),300)
			for _,v in pairs(tmp) do
				print('---------------')
				print(v:GetOrigin())
				print(v:GetClassname())
				print('---------------')
				--HostSay(v:GetClassname())
			end
			return
		elseif text == "-print_position" then
			local tmp = PlayerResource:GetPlayer(plyid):GetAssignedHero():GetOrigin()
			print(tmp)
			return
		elseif ss[1] == "-observeinit" then  --仅预处理观战模式
			if GameRules:State_Get() <= 2 then --只允许洗牌阶段用
				enable_observe( ss[2] ~= "0" )
				observerhd = PlayerResource:GetPlayer(plyid)
			end
		elseif ss[1] == "-observe" then  --make host observing
			if GameRules:State_Get() <= 2 then 
				enable_observe( ss[2] ~= "0" )
				enable_coach( plyid, true )
				observerhd = PlayerResource:GetPlayer(plyid)
			end
		elseif ss[1] == "-setmaxplayer" then --设置最大玩家数
			if GameRules:State_Get() <= 2 then 
				local res = THD2_SetPlayerPerTeam(tonumber(ss[2]))
				Say(plyhd,"Max player(per team) set to "..tostring(res),false)
			end
		elseif ss[1] == "-setmaxbot" then --设置最大bot数
			if GameRules:State_Get() <= 2 then 
				local res = THD2_SetPlayerBadTeam(tonumber(ss[2]))
				Say(plyhd,"Max Bot set to "..tostring(res),false)
			end
		elseif ss[1] == "-setteamhero" then --设置队伍英雄(仅限强制复选)
			if GameRules:State_Get() <= 2 and THD2_GetJFFMode()==2 then 
				THD2_SetTeamHero(tonumber(ss[2]),ss[3])
				Say(plyhd,"Team " .. ss[2] .. " set to " .. ss[3],false)
			end
		elseif text == "-allowsame" then  --允许选择相同少女
			THD2_SetCloneMode(true)
			Say(plyhd, "Allowsame Mode ON...",false)
		elseif text == "-unallowsame" then  --不再允许选择相同少女
			THD2_SetCloneMode(false)
			Say(plyhd, "Allowsame Mode OFF...",false)
		elseif text == "-ordinary" then  --通常模式
			THD2_SetJustForFunMode(plyhd,1)
			--Say(plyhd, "Ordinary Mode...",false)
		elseif text == "-allsame" then  --(同队)全部选择相同少女
			THD2_SetJustForFunMode(plyhd,2)
			--Say(plyhd, "Allsame Mode...",false)
		--[[elseif text == "-dota" then  --开启dota乱入
			for _, Hero in pairs(DOTA_BAN_LIST) do
				for i=#THD2_BAN_LIST,1,-1 do
					if THD2_BAN_LIST[i] == Hero then
						table.remove(THD2_BAN_LIST, i)--将乱入英雄从黑名单中移除
					end
				end
			end
			for i,v in ipairs(THD2_BAN_LIST) do
				print(i,v)
			end
			Say(plyhd,"已开启乱入",false)--]]
		end
		if GameRules:State_Get() < DOTA_GAMERULES_STATE_HERO_SELECTION then --只能在英雄选择阶段(请选择你的英雄)前使用
			if GetMapName() == "dota" then		-- dota地图指令
				if text == "-dota" then
					THD2_SetDotaMixedMode(true)
					Say(plyhd, "Dota Mixed ON",false)
				elseif text == "-undota" then
					THD2_SetDotaMixedMode(false)
					Say(plyhd, "Dota Mixed OFF",false)
				end
			end
		else
			if text == "-strawberry" or text == "-unstrawberry" then
				HostSay("Can't Change it now, please do this earlier at hero selection state.")
			elseif GetMapName() == "dota" then
				if text == "-dota" or text == "-undota" then
					HostSay("Can't Change it now, please do this earlier at hero selection state.")
				end
			end
		end
		if GameRules:State_Get() < DOTA_GAMERULES_STATE_STRATEGY_TIME then --只能在决策阶段(所有人选完人)前使用,主要是为了防止恶意使用
			if ss[1] == "-fastrespawn" then  --快速复活
				local value = tonumber(ss[2])
				THD2_SetFRSMode(true)
				Say(plyhd, "Fast Respawn Mode ON",false)
				if value ~= nil then
					THD2_SetFRSValue(value)
					Say(plyhd, "Fast Respawn Value Set to "..tostring(value).."%",false)
				end
			elseif text == "-unfastrespawn" then
				THD2_SetFRSMode(false)
				Say(plyhd, "Fast Respawn Mode OFF",false)
			elseif text == "-fastcd" then  --快速CD(-80%冷却时间,类似wtf但蓝量非无限)
				THD2_SetFCDMode(true)
				Say(plyhd, "Fast CoolDown Mode ON",false)
			elseif text == "-unfastcd" then
				THD2_SetFCDMode(false)
				Say(plyhd, "Fast CoolDown Mode OFF",false)
			elseif text == "-allpick" then
				THD2_SetAPMode(true)
				Say(plyhd, "All Pick Mode ON", false)
			elseif text == "-unallpick" then
				THD2_SetAPMode(false)
				Say(plyhd, "All Pick Mode OFF", false)
			elseif ss[1] == "-banbot" or ss[1] == "-banbothero" then
				THD2_BanBotHero(plyhd, ss[2])
			elseif ss[1] == "-banbots" or ss[1] == "-banbotheroes" then
				for i = 2, #ss do
					THD2_BanBotHero(plyhd, ss[i])
				end
			elseif ss[1] == "-banallbot" or ss[1] == "-banallbothero" then
				THD2_BanAllBotHero(plyhd)
			elseif ss[1] == "-unbanbot" or ss[1] == "-unbanbothero" then
				THD2_UnbanBotHero(plyhd, ss[2])
			elseif ss[1] == "-unbanbots" or ss[1] == "-unbanbotheroes" then
				for i = 2, #ss do
					THD2_UnbanBotHero(plyhd, ss[i])
				end
			elseif ss[1] == "-pickbot" then
				if #ss >= 2 then
					THD2_BanAllBotHero(plyhd)
					THD2_UnbanBotHero(plyhd, ss[2])
				end
			elseif ss[1] == "-pickbots" then
				THD2_BanAllBotHero(plyhd)
				for i = 2, #ss do
					THD2_UnbanBotHero(plyhd, ss[i])
				end
			elseif ss[1] == "-banhero" then
				THD2_BanHero(plyhd, ss[2])
			elseif ss[1] == "-banheros" or ss[1] == "-banheroes" then
            	for i = 2, #ss do
					THD2_BanHero(plyhd, ss[i])
				end
		    end
		else
			if text == "-fastrespawn" or text == "-unfastrespawn" or text == "-fastcd" or text == "-unfastcd" then
				HostSay("Can't Change it now, please do this earlier at shuffle state.")
			end
		end
	end
	
	--完全通用的公共指令
	if text=="-checktime" then
		HostSay("GetGameTime(): "..GameRules:GetGameTime())
		HostSay("GetDOTATime(0, 0)"..GameRules:GetDOTATime(false, false))
	elseif text=="-checkmap" then
		HostSay("mapname is: "..GetMapName())
		HostSay("FastCoolDown: "..boolstr[THD2_GetFCDMode()])
		HostSay("FastRespawn: "..boolstr[THD2_GetFRSMode()])
		if THD2_GetFRSMode() then
			HostSay("FastRespawnValue: "..THD2_GetFRSValue().."%")
		end
		HostSay("JustForFun: "..THD2_GetJFFModeName())
		if THD2_GetBotMode() then
			HostSay("BotDiff: ".. THD2_GetBotDiffName() )
		end
		if THD2_GetDotaMixedMode() then
			HostSay("DotaMixed: ".. boolstr[THD2_GetDotaMixedMode()] )
		end
		HostSay("MaxPlayer: " .. THD2_GetPlayerPerTeam())
	elseif ss[1] == "-debugtext" then
		DisplayChampion( PlayerResource:GetPlayer(plyid):GetAssignedHero() )
	elseif ss[1] == "-coach" then
		if GetMapName() == "4_thdots_with_coach" and GameRules:State_Get() <= 2 then
			enable_coach( plyid, ss[2] == "1" )
		end
	elseif ss[1] == "-keybind" then
		if PlayerResource:GetSelectedHeroName(plyid) == "npc_dota_hero_invoker" then
			CustomGameEventManager:Send_ServerToPlayer(plyhd, "custom_key_bind", {key_val = ss[2], event = "xianzhezhishi"} )
		end
	elseif text == "-yaw0" then
		CustomGameEventManager:Send_ServerToPlayer(plyhd, "set_camera_yaw", {key_val = 0} )
		print(GameRules:GetDOTATime(false, false))
	elseif text == "-081way" then
		CustomGameEventManager:Send_ServerToPlayer(plyhd, "set_camera_yaw", {key_val = 180} )
		print(GameRules:GetDOTATime(false, false))
	elseif ss[1] == "-yaw" then
		CustomGameEventManager:Send_ServerToPlayer(plyhd, "set_camera_yaw", {key_val = tonumber(ss[2])} )
		print(GameRules:GetDOTATime(false, false))
	elseif text == "-pause" then
		if is_host or G_Player_Pause_Count[plyid+1] < MAX_Pause_Count then --host可以无限暂停
			G_Player_Pause_Count[plyid+1] = G_Player_Pause_Count[plyid+1] + 1
			PauseGame(not GameRules:IsGamePaused()) -- set as not
		else
			HostSay( string.format( "Player %d has Paused %d times!You can pause any more now.", plyid, MAX_Pause_Count ) )
		end
	elseif ss[1] == "-cloth" then
		update_cloth( G_Player_Cloth, plyid, tonumber(ss[2]) )
	-- do not need this anymore from now on
	-- just click button to random pick

	--[[
	elseif text == "-random" then
		if GameRules:State_Get() > 2 then -- after shuffle
			if PlayerResource:HasSelectedHero(plyid) == false then
				PlayerResource:GetPlayer(plyid):MakeRandomHeroSelection()
				--PlayerResource:ModifyGold(plyid,200,true,0); --200 extra gold
			end
		end
	--]]

	elseif ss[1] == "-repick" then
		-- THD2_MakePlayerRepick(plyid, ss[2])
	elseif ss[1] == "-urd" and not RDC_MODE then
		THD_URD(plyid,plyhd)
	elseif ss[1] == "-urd" and RDC_MODE then
		if fakerank[plyhd] then
			Say(plyhd,".你先别急", true) --新模式彩蛋
		else
			GameRules:SendCustomMessage("#RANKDC_Explain5",0,0)
		end
	elseif ss[1] == "-rank" and not RDC_MODE then
		THD_RANK(plyid,plyhd)
	elseif ss[1] == "-rank" and RDC_MODE then --新模式彩蛋
		if fakerank[plyhd] then
			Say(plyhd,tostring(fakerank[plyhd]), true)
		elseif RollPercentage(95) then
			GameRules:SendCustomMessage("#RANKDC_Explain6",0,0)
		elseif RollPercentage(80) then
			Say(plyhd,"600", true)
		else
			if RollPercentage(95) then
				fakerank[plyhd]=RandomInt(450,999)
			elseif RollPercentage(80) then
				fakerank[plyhd]=RandomInt(1000,1799)
			elseif RollPercentage(95) then
				fakerank[plyhd]=RandomInt(1,449)
			else
				fakerank[plyhd]=RandomInt(1800,9001)
			end
			Say(plyhd,tostring(fakerank[plyhd]), true)
		end
	elseif text == "ruozhitaidao" then --gtmdtd(这里是大鸽加的, 而且本来是空的)
		HostSay("gtmdtd")  --这个是我加的 XD
		GameRules:SendCustomMessage("<font color='#00FFFF'>teamnumber is:</font>"..plyhd:GetTeamNumber(), 0, 0)
		if GetMapName() ~= "1_thdots_map" then
			AddFOWViewer(plyhd:GetTeamNumber(),Vector(0,0,0),4000,5,false)
		end
	elseif text == "-refresh" then
		if GameRules:IsCheatMode() then
			local hero = plyhd:GetAssignedHero()
			hero:SetContextNum("item_card_cooldown", 0, 0)
			hero:SetContextThink("item_card_cooldown_think", nil, 0)
		end
	elseif text == "-zisha" then --影狼BUG自杀指令
		local hero = plyhd:GetAssignedHero()
		local time = RandomInt(20, 40)
		print(hero:GetName())
		if hero:GetName() == "npc_dota_hero_lycan" then
			Say(plyhd, "30秒后重置", true)
			hero:SetContextThink("kagerou_kill", 
				function()
				hero:ForceKill(true)
			end,
			time)
		end
	elseif text == "-reisen2w" then --
		local hero = plyhd:GetAssignedHero()
		if hero:GetName() == "npc_dota_hero_phantom_lancer" then
			hero:SetMaterialGroup("1")
			hero.Reisen2_IsBlack = false
		end
	elseif text == "-reisen2b" then --
		local hero = plyhd:GetAssignedHero()
		if hero:GetName() == "npc_dota_hero_phantom_lancer" then
			hero:SetMaterialGroup("0")
			hero.Reisen2_IsBlack = true
		end
	elseif text == "-daiyousei01" then --
		local hero = plyhd:GetAssignedHero()
		if hero:GetName() == "npc_dota_hero_nyx_assassin" then
			hero:SetMaterialGroup("0")
		end
	elseif text == "-daiyousei02" then --
		local hero = plyhd:GetAssignedHero()
		if hero:GetName() == "npc_dota_hero_nyx_assassin" then
			hero:SetMaterialGroup("1")
		end
	elseif text == "-youmu2" then --
		local hero = plyhd:GetAssignedHero()
		if hero:GetName() == "npc_dota_hero_juggernaut" then
			print(hero:GetName())
			THD_Change_skill_youmu2(hero,plyhd)
		elseif hero:GetName() == "npc_dota_hero_enchantress" then
			GameRules:SendCustomMessage("#Youmu2SkillChangeFail", 0, 0)
		end
	end
	
	if text == "getnum" then
		local ability = hero:FindAbilityByName("ability_common_power_buff")
		hero:SetModifierStackCount("common_thdots_power_str_buff",ability,RandomInt(1,30))
		-- local num = GetNum()
		-- HostSay("num is " .. tostring(num))
	end
	-- if text == "1" then
	-- 	HostSay("-createhero leg")
	-- end
	-- if text == "2" then
	-- 	HostSay("-createhero leg enemy")
	-- end
	--以上为所有玩家和地图可用的通用指令
	
	if GetMapName() ~= "dota" then return end
	-- 下面的指令就只能在dota(bot)地图中使用了
	
	if is_host then  --这些指令仍然是主机限定的
		if text == "-addbot" then --启用bot
			THD2_SetBotMode(true)
			HostSay("Bot Mode ON...")
			--具体改动到了state变动
			--必须在选人完成前使用才有效
		elseif text == "-removebot" then --取消bot
			THD2_SetBotMode(false)
			HostSay("Bot Mode OFF...")
			--必须在选人完成前使用才有效
		elseif text == "-startbot" then --运行bot脚本
			--开启sv_cheats (现在不需要了)
			--SendToServerConsole('sv_cheats 1')
			THD2_SetBotThinking(true)
			HostSay("Bot Start to Think...")
		elseif text == "-stopbot" then --停止bot脚本
			THD2_SetBotThinking(false)
			HostSay("Bot Stop to Think...")
		elseif text == "-easy" then --选择难度, 以下共4种
			THD2_ChangeBotDifficulty(plyhd,1)
			--Say(nil, "Bot Difficulty set to easy",false)
		elseif text == "-normal" then
			THD2_ChangeBotDifficulty(plyhd,2)
			--Say(nil, "Bot Difficulty set to normal",false)
		elseif text == "-hard" then 
			THD2_ChangeBotDifficulty(plyhd,3)
			--Say(nil, "Bot Difficulty set to hrad",false)
		elseif text == "-lunatic" then 
			THD2_ChangeBotDifficulty(plyhd,4)
		elseif text == "-extra" then 
			THD2_ChangeBotDifficulty(plyhd,5)
			--Say(nil, "Bot Difficulty set to lunatic",false)
		elseif text == "-ayayayaya" then --怂那岛
			THD2_SetJustForFunMode(plyhd,3)
			--Say(plyhd, "Ayayayaya Mode...",false)
		elseif text == "-gaishi" then --盖世XC
			THD2_SetJustForFunMode(plyhd,4)	
		elseif text == "-naotan" then
			THD2_SetNaotanMode(true)
		end
	end
	
end

function THDOTSGameMode:CheckChoose( keys )
	--有玩家未选择少女则随机选择
	for i=0,63 do
		if PlayerResource:GetPlayer(i) ~= nil then
			if PlayerResource:HasSelectedHero(i) == false then
				PlayerResource:GetPlayer(i):MakeRandomHeroSelection()
				print(i)
			end
		end
	end
end


-- 这个函数是在有玩家连接到游戏之后，调用的，请查看 THDOTSGameMode:AutoAssignPlayer里面调用这个函数的部分
-- 主要是设置属于游戏模式的相关规则，并且开启循环计时器
function THDOTSGameMode:CaptureGameMode()
	if self.__thd_capture_game_mode_done == true then
		print("THDOTSGameMode:CaptureGameMode already captured, skip")
		return
	end
	self.__thd_capture_game_mode_done = true

	print("THDOTSGameMode:CaptureGameMode")
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue( DOTA_ATTRIBUTE_STRENGTH_HP, 20 )
	GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath(false) --死亡不掉钱
	GameRules:SetStartingGold(850)                   		-- 设置起始金钱
	GameRules:SetHideBlacklistedHeroes(true)				-- 隐藏黑名单英雄

	GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(THDOTSGameMode, 'OnTHDOTSOrderFilter'), self)
	GameRules:GetGameModeEntity():SetDamageFilter(Dynamic_Wrap(THDOTSGameMode, 'OnTHDOTSDamageFilter'), self)

	-- 补dota地图的thd_blue_entity
	local thd_blue_entity = Entities:FindByName(nil, "thd_blue_entity")
	if thd_blue_entity == nil then
		local dummy = CreateUnitByName("npc_dummy_unit", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
		dummy:SetEntityName("thd_blue_entity")
		thd_blue_entity = dummy
	end
	if thd_blue_entity:FindModifierByName("modifier_event_proxy") == nil then
		thd_blue_entity:AddNewModifier(nil, nil, "modifier_event_proxy", {duration = -1})
	end

	if GetMapName() == "dota" then
		-- 人机地图
		GameRules:GetGameModeEntity():SetAllowNeutralItemDrops(true)
		GameRules:GetGameModeEntity():SetUseDefaultDOTARuneSpawnLogic(true)
		GameRules:GetGameModeEntity():SetRuneEnabled(DOTA_RUNE_ILLUSION,false)
	else
		-- 人人地图
		-- GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockAmount(0)--近战初始格挡值
		-- GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPerLevelAmount(0)--近战每级获得格挡	
		-- GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPercent(0)--近战格挡概率
		GameRules:GetGameModeEntity():SetAllowNeutralItemDrops(false)
		GameRules:GetGameModeEntity():SetUseDefaultDOTARuneSpawnLogic(true)
		GameRules:GetGameModeEntity():SetRuneEnabled(DOTA_RUNE_ARCANE,false)
		_G.ROSHAN_SPAWN_LOC = Entities:FindByClassname(nil, "npc_dota_roshan_spawner"):GetAbsOrigin()
		for _, Hero in pairs(DOTA_BAN_LIST) do
			table.insert(THD2_BAN_LIST, Hero)--将乱入英雄加入黑名单
		end
	end--dota地图掉落中立物品 
	if GameMode == nil then
	  GameMode = GameRules:GetGameModeEntity()		

	  -- 设定镜头距离的大小，默认为1134
	  GameMode:SetCameraDistanceOverride( 1134.0 )
	 end
end

-- 以下的这些函数，大多都是把传递的数值Print出来
-- PrintTable和print的东西，都会显示在控制台上
-- PrintTable会显示例如
-- caster:
--        table:0x00ff000
-- caster_entindex:195
-- target:
--        table:0x00ff000
-- 这样的内容，那么我们就可以通过keys.caster_entindex来获取这个caster的Entity序号
-- 再通过
-- EntIndexToHScript(keys.caster_entindex)
-- 就可以获取这个施法者相对应的hScript了

function THDOTSGameMode:AbilityUsed(keys)
	print("THDOTSGameMode:AbilityUsed")
	-- local caster = EntIndexToHScript(keys.caster_entindex)
	--  -- print_r(keys)
	-- 	for i=0,15 do 
	-- 		if caster:GetAbilityByIndex(i) ~= nil then
	-- 			print(caster:GetAbilityByIndex(i):GetName())
	-- 		end
	-- 	end
	-- 	print("------------------------------------")
	-- 	for i=0,8 do 
	-- 		if caster:GetModifierNameByIndex(i) ~= nil then
	-- 			-- print(caster:GetModifierNameByIndex(i))
	-- 		end
	-- 	end
		
	-- 	print("------------------------------------")
	local ply = EntIndexToHScript(keys.PlayerID+1)
	if(ply==nil)then
	  return
	end
	local caster = ply:GetAssignedHero()
	if(caster==nil)then
	  return
	end
	if(keys.abilityname == "item_ultimate_scepter_roshan")then
		caster:AddItemByName("item_wanbaochui2")
	end
end

function THDOTSGameMode:AbilityLearn(keys)
	print("THDOTSGameMode:AbilityLearn")
	local ply = EntIndexToHScript(keys.player)
	  if(ply==nil)then
	    return
	  end
	local caster = ply:GetAssignedHero()
	if caster ~= nil and keys.abilityname ~= nil then
		THD2_OnAbilityLearned(caster, keys.abilityname)
	end
end

G_Bot_Level = {0,0,0,0,0,0,0,0,0,0,0}

function THDOTSGameMode:BotUpGradeAbility(hero)
	-- print("THDOTSGameMode:BotUpGradeAbility")
	
	local hName = hero:GetClassname()
	local hIndex = -1
	for i=0,233 do
		if G_Bot_Random_Hero[i] == hName then
			hIndex = i
			break
		end
	end
	
	if hIndex < 0 then
		print('THDOTSGameMode:BotUpGradeAbility: Error: invalid hero name: ' .. hName )
	else
		local v = hero:GetPlayerOwnerID()
		local lvl = hero:GetLevel()
		--print(lvl)
		if lvl == nil then
			lvl = 1
		end
		--print(lvl)
		for i=G_Bot_Level[v]+1,lvl do
			local abilitySlot = G_Bots_Ability_Add[hIndex][i]
			-- 0 表示该等级不点技能，不能传给 GetAbilityByIndex。
			if abilitySlot ~= nil and abilitySlot > 0 and abilitySlot <= hero:GetAbilityCount() then
				local j = abilitySlot - 1 --abilitys is 0~n-1, but vals set as 1~n
				local ability = hero:GetAbilityByIndex(j)
				if ability~=nil then
					local oldLevel = ability:GetLevel()
					local level = math.min((ability:GetLevel() + 1),ability:GetMaxLevel())
					ability:SetLevel(level)
					if level > oldLevel then
						THD2_OnAbilityLearned(hero, ability)
					end
				end
			end
		end
		
		G_Bot_Level[v] = lvl
		
	end
	
	hero:SetAbilityPoints(0)
	
end

function THDOTSGameMode:Levelup(keys)
	print("THDOTSGameMode:Levelup")	

	if PlayerResource:GetSelectedHeroName(keys.player_id) == "npc_dota_hero_lone_druid" then
		--  秋姐升级监听 （暂时弃用）
	end
	THD2_Special_OnLevelUp()
end

function THDOTSGameMode:BotUpGradeAbilityCommon(caster)
	print("THDOTSGameMode:BotUpGradeAbilityCommon")
	 
	
	-- local unitNameSlot = G_BOT_Ability_list[caster:GetUnitName()]
	-- local abilitySlot = nil
	-- if unitNameSlot~=nil then
	-- 	abilitySlot = unitNameSlot[caster:GetLevel()]
	-- end
	-- if abilitySlot ~= nil then
	-- 	local ability = caster:GetAbilityByIndex(abilitySlot)
	-- 	ability:UpgradeAbility(true)
	-- else
	-- 	for i=0,16 do
	-- 	 	local ability = caster:GetAbilityByIndex(i)
	-- 	 	if ability:CanAbilityBeUpgraded() then
	-- 			ability:UpgradeAbility(true)
	-- 			break
	-- 		end
	-- 	end 
	-- end
	--caster:SetAbilityPoints(0)
end

function THDOTSGameMode:AutoAssignPlayer(keys)
	--print("THDOTSGameMode:BotUpGradeAbilityCommon")
	 
	
	-- 这里调用CaptureGameMode这个函数，执行游戏模式初始化
	THDOTSGameMode:CaptureGameMode()
end


function THDOTSGameMode:getItemByName( hero, name )
	for i=0,11 do
	  local item = hero:GetItemInSlot( i )
	  if item ~= nil then
	    local lname = item:GetAbilityName()
	    if lname == name then
	      return item
	    end
	  end
	end

	return nil
end

function THDOTSGameMode:OnEntityKilled( keys )
	-- 储存被击杀的单位
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- 储存杀手单位
	local killerEntity = nil
	if keys.entindex_attacker then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	-- 已经被v社修复了
	-- if killerEntity and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then--修复夜魇人头数量显示-1BUG
    --     CustomGameEventManager:Send_ServerToAllClients('SetTopBarDireScore',{value = PlayerResource:GetTeamKills(DOTA_TEAM_BADGUYS)})
    -- end

	if killedUnit:IsHero() and not killedUnit.HasAegis and not killedUnit:IsIllusion() then --判断有无不朽盾，并BIU
 		killedUnit:EmitSound("THD_BIU")
	end

	for i=0,10 do --因幡帝，资本家
		if PlayerResource:GetPlayer(i) == nil then break end
		if killedUnit:FindAbilityByName("ability_dummy_unit") or killedUnit:FindAbilityByName("ability_invisible_dummy_unit") then return end
		local ply = PlayerResource:GetPlayer(i)
		local hero = ply:GetAssignedHero()
		if hero == nil then break end
		if hero:GetName() == "npc_dota_hero_gyrocopter" and FindTelentValue(hero,"special_bonus_unique_tei_4") == 1 then
			local gold = RandomInt(2, 6)
			hero:ModifyGold(gold, false, DOTA_ModifyGold_Unspecified)
		end
	end

	if(killedUnit:IsHero()==false and killedUnit:GetUnitName()~= "ability_yuuka_flower") then
		if killedUnit:FindAbilityByName("ability_dummy_unit") or killedUnit:FindAbilityByName("ability_invisible_dummy_unit") then return end --若被击杀的单位是马甲，则return
		local i = RandomInt(0,100)
		if(i<5)then
			--print("CreateModifierThinker: coin")
			local unit = CreateModifierThinker(
				nil,
				nil,
				"aura_ability_collection_find_master_lua",
				{model = "models/thd2/point.vmdl", name = "npc_coin_up_unit"},
				killedUnit:GetOrigin(),
				DOTA_TEAM_NEUTRALS,
				false
			)
			unit.IsGet = false
			local time = 0
			unit:SetThink(
				function()
					if GameRules:IsGamePaused() then return 0.03 end
					if time >= 30.0 then
						unit:RemoveSelf()
						return nil
					end
					time = time + 0.2
					return 0.2
				end, 
				"ability_collection_power_remove",
			0)
		end
		i = RandomInt(0,100)
		if(i<5)then
			--print("CreateModifierThinker: power")
			local unit = CreateModifierThinker(
				nil,
				nil,
				"aura_ability_collection_find_master_lua",
				{model = "models/thd2/power.vmdl", name = "npc_power_up_unit"},
				killedUnit:GetOrigin(),
				DOTA_TEAM_NEUTRALS,
				false
			)
			unit.IsGet = false
			local time = 0
			unit:SetThink(
				function()
					if GameRules:IsGamePaused() then return 0.03 end
					if time >= 30.0 then
						unit:RemoveSelf()
						return nil
					end
					time = time + 0.2
					return 0.2
				end, 
				"ability_collection_power_remove",
			0)
		end
	end
	
	if(killedUnit:IsHero()==true)then
		if killedUnit:GetClassname() == "npc_dota_hero_kunkka" and killedUnit.IsDriving == true then
			--print('test_ship')
			--local murasaship = killedUnit.ability_minamitsu_ship
			--murasaship:CastAbilityOnPosition(murasaship:GetAbsOrigin(),murasaship:FindAbilityByName("ability_thdots_minamitsu04_unit_download"),-1)
			self:OnMinamitsu04ShipDownload(killedUnit)
		end
	end
	
		if(killedUnit:IsHero()==true and not killedUnit:IsReincarnating())then
			local effectIndex = ParticleManager:CreateParticle("particles/thd2/environment/death/act_hero_die.vpcf", PATTACH_CUSTOMORIGIN, killedUnit)
			ParticleManager:SetParticleControl(effectIndex, 0, killedUnit:GetOrigin())
			ParticleManager:SetParticleControl(effectIndex, 1, killedUnit:GetOrigin())
			ParticleManager:DestroyParticleSystem(effectIndex,false)
			local powerStatValue = killedUnit:GetContext("hero_bouns_stat_power_count")
			if(powerStatValue==nil)then
				return
			end
			local powerDecrease = (powerStatValue - powerStatValue%2)/2
			killedUnit:SetContextNum("hero_bouns_stat_power_count",powerStatValue-powerDecrease,0)
			local ability = killedUnit:FindAbilityByName("ability_common_power_buff")
			if(killedUnit:GetPrimaryAttribute()==0)then
				killedUnit:SetModifierStackCount("common_thdots_power_str_buff",ability,powerStatValue-powerDecrease)
			elseif(killedUnit:GetPrimaryAttribute()==1)then
				killedUnit:SetModifierStackCount("common_thdots_power_agi_buff",ability,powerStatValue-powerDecrease)
			elseif(killedUnit:GetPrimaryAttribute()==2)then
				killedUnit:SetModifierStackCount("common_thdots_power_int_buff",ability,powerStatValue-powerDecrease)
			end
			OnCollectionDrop(killedUnit,powerDecrease)
		end

	if killerEntity and killerEntity:IsHero() then
		local abilityNecAura = killerEntity:FindAbilityByName("yuyuko_heartstopper_aura")
		if(abilityNecAura~=nil)then
	  	local abilityLevel = abilityNecAura:GetLevel()
	    	if(abilityLevel~=nil)then
	    		killerEntity:SetMana(killerEntity:GetMana()+(abilityLevel*5+5))
	    	end
		end
	end
	--[[if killedUnit:GetClassname() == "npc_dota_roshan"  then
		local item = CreateItem("item_wanbaochui2", nil, nil)
                local pos = killedUnit:GetAbsOrigin()
                local drop = CreateItemOnPositionSync( pos, item )
                local pos_launch = pos+ RandomVector(RandomFloat(150,200))
                item:LaunchLoot(false, 200, 0.75, pos_launch)
	end--]]
	if killedUnit:GetClassname()== "npc_dota_fort" and not RDC_MODE then WebApi:AfterMatch() end
end



function THDOTSGameMode:OnHeroSpawned( keys )
	--print("THDOTSGameMode:OnHeroSpawned")
	--if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then return end
	 
	
	local hero = EntIndexToHScript(keys.entindex)
	if(hero==nil)then
	  return
	end
	-- 30 分钟前为新生成的线上小兵注册防断线护送状态。
	THD2_RegisterLaneCreepMarchProtection(hero)
	-- 信使生成或重生时，为 Bot 控制的信使补充永久护盾。
	THD2_ScheduleBotCourierShield(hero)

	--[[if hero:GetUnitName() =="npc_dota_roshan" then
		print("roshan")
		hero:AddItemByName("item_aegis")
	end--]]
	if hero:GetClassname() == "npc_dota_lone_druid_bear" then
		local ability1 = hero:FindAbilityByName("ability_kasenbear_01")
		local ability2 = hero:FindAbilityByName("ability_kasenbear_02")
		local ability3 = hero:FindAbilityByName("lone_druid_spirit_bear_return")
		ability2:SetLevel(ability1:GetLevel())
		ability3:SetLevel(1)
		--print(hero:IsRealHero())
		local owner = hero:GetPlayerOwner():GetAssignedHero()
		--print(owner)
		--print(owner:GetClassname())
		hero.owner = owner
	end
	if hero:IsHero() and not hero:IsIllusion() then

		--print('THDOTSGameMode:OnHeroSpawned:')
		--print(hero:GetClassname())
		--print('strated')
		
	 	if hero.isFirstSpawn == nil or hero.isFirstSpawn == true then
		    self:PrecacheHeroResource(hero)
			
			THD2_FirstAddBuff(hero)

		    local ability = hero:AddAbility("ability_common_power_buff")
			if ability ~= nil then
				ability:SetLevel(1)
				if(hero:GetPrimaryAttribute()==0)then
					ability:ApplyDataDrivenModifier(hero,hero,"common_thdots_power_str_buff",{})
				elseif(hero:GetPrimaryAttribute()==1)then
					ability:ApplyDataDrivenModifier(hero,hero,"common_thdots_power_agi_buff",{})
				elseif(hero:GetPrimaryAttribute()==2)then
					ability:ApplyDataDrivenModifier(hero,hero,"common_thdots_power_int_buff",{})
				else
					ability:ApplyDataDrivenModifier(hero,hero,"common_thdots_power_all_buff",{})
				end
			end
			-- not working
			--[[
			if PlayerResource:HasRandomed(hero:GetPlayerOwnerID()) then --this player random picked
				print('Player' .. hero:GetPlayerOwnerID() .. 'gain 200 gold' )
				hero:ModifyGold( 200, true, 0 )
			end
			--]]
			if hero:GetUsedAbilitySlotCount() >= 35 then
				hero:RemoveAbility("ability_pluck_famango")
			end

			local highfive = hero:AddAbility("plus_high_five")
			highfive:SetLevel(highfive:GetMaxLevel())
			highfive:SetHidden(true)
			
		    hero.isFirstSpawn = false
			
	  	end

		if hero:GetClassname() == "npc_dota_hero_drow_ranger" then
		    hero:SetModel("models/thd2/koishi/koishi_mmd.vmdl")
		    hero:SetOriginalModel("models/thd2/koishi/koishi_mmd.vmdl")
		    PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
		    hero:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
		end
		
		local plyid = hero:GetPlayerOwnerID() + 1
		if plyid > 0 then
			local cloth_id = G_Player_Cloth[plyid]
			local classname = hero:GetClassname()
			--print(plyid)
			--print(cloth_id)
			if Hero_Cloth[classname] ~= nil then
				local cloth = Hero_Cloth[classname][cloth_id]
				if cloth ~= nil then
					hero:SetModel(cloth)
					hero:SetOriginalModel(cloth)

					if Hero_Cloth[classname..'_size'] ~= nil
						and Hero_Cloth[classname..'_size'][cloth_id] ~= nil then
						local cloth_size = Hero_Cloth[classname..'_size'][cloth_id]
						hero:SetModelScale(cloth_size)
					end

					if Hero_Cloth[classname..'_material'] ~= nil
						and Hero_Cloth[classname..'_material'][cloth_id] ~= nil then

						hero:SetMaterialGroup(Hero_Cloth[classname..'_material'][cloth_id])
					end
				end
			end
		end
		--print('THDOTSGameMode:OnHeroSpawned:')
		--print(hero:GetClassname())
		--print('ended')
	end
end

function THDOTSGameMode:PrecacheHeroResource(hero)
	local heroName = hero:GetClassname()
	local context

	local abilityEx
	local modifierRemove

	--DeepPrintTable()
	--motion:
	--motion:EnableMotion()
	print('THDOTSGameMode:PrecacheHeroResource:')
	print(heroName)

	InitInnateAbilityForHero(hero)

	-- 数据驱动用
	local selfCastAbilities = {
		"ability_thdots_yukari04",
	}

	for i, sAbility in pairs(selfCastAbilities) do
		local hAbility = hero:FindAbilityByName(sAbility)
		if hAbility ~= nil then
			hAbility.selfCastToFountain = true
		end
	end

	if(heroName == "npc_dota_hero_zuus")then
		require( 'abilities/abilityYasaka' )
		local ability = hero:FindAbilityByName("ability_thdots_yasakaEx")
		ability:SetLevel(1)
		ability = hero:FindAbilityByName("ability_thdots_yasaka43")
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_yasaka42")
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_yasaka41")
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_yasaka04_quit")
		ability:SetHidden(true)
		ability:SetLevel(1)
	elseif(heroName == "npc_dota_hero_slark")then
		require( 'abilities/abilityAya' )
	elseif(heroName == "npc_dota_hero_lina")then
		require( 'abilities/abilityReimu' )
		require( 'abilities/abilityReisen' )
		abilityEx = hero:FindAbilityByName("ability_dota2x_reimuEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_juggernaut")then
		require( 'abilities/abilityYoumu' )
		abilityEx = hero:FindAbilityByName("ability_thdots_youmuEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_drow_ranger")then
		require( 'abilities/abilityKoishi' )
	elseif(heroName == "npc_dota_hero_earthshaker")then
		require( 'abilities/abilityTensi' )
	elseif(heroName == "npc_dota_hero_crystal_maiden")then
		require( 'abilities/abilityMarisa' )
		abilityEx = hero:FindAbilityByName("ability_thdots_marisaEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_furion")then
		require( 'abilities/abilityKaguya' )	
		abilityEx = hero:FindAbilityByName("ability_thdots_kaguyaEx")
		abilityEx:SetLevel(1)		
	elseif(heroName == "npc_dota_hero_necrolyte")then
		require( 'abilities/abilityYuyuko' )
		hero:SetContextNum("ability_yuyuko_Ex_deadflag",FALSE,0)
		-- Damage filter is registered once in CaptureGameMode.
		abilityEx = hero:FindAbilityByName("ability_thdots_yuyukoEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_templar_assassin")then
		require( 'abilities/abilitySakuya' )
		abilityEx = hero:FindAbilityByName("ability_thdots_sakuyaEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_razor")then
		require( 'abilities/abilityIku' )
		abilityEx = hero:FindAbilityByName("ability_thdots_ikuEx")
		abilityEx:SetLevel(1)	
		abilityEx_2 = hero:FindAbilityByName("ability_thdots_iku_pose")
		abilityEx_2:SetLevel(1)
	elseif(heroName == "npc_dota_hero_naga_siren")then
		require( 'abilities/abilityFlandre' )
		abilityEx = hero:FindAbilityByName("ability_thdots_flandreEx")
		hero.mirror = false;
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_chaos_knight")then
		require( 'abilities/abilityMokou' )
		abilityEx = hero:FindAbilityByName("ability_thdots_mokouEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_sniper")then
		--hero:EnableMotion()
	elseif(heroName == "npc_dota_hero_mirana")then
		-- 与恢复后的 Old 技能组保持一致，出生时点亮天生技能。
		abilityEx = hero:FindAbilityByName("ability_thdots_reisenOldex")
		abilityEx:SetLevel(1)
		--hero:EnableMotion()
	elseif(heroName == "npc_dota_hero_silencer")then
		abilityEx = hero:FindAbilityByName("ability_thdots_eirinex")
		abilityEx:SetLevel(1)
		hero.ability_eirinEx_count = 0
		hero:SetContextThink(DoUniqueString("Thdots_eirinEx_passive"),
		  function()
		  	if GameRules:IsGamePaused() then return 0.03 end
		    hero.ability_eirinEx_count = hero.ability_eirinEx_count + 1
		    if(hero.ability_eirinEx_count >= 81)then
		      hero.ability_eirinEx_count = 0
		      hero:SetBaseIntellect(hero:GetBaseIntellect()+1)
		    end
		    if(hero:FindModifierByName("modifier_silencer_int_steal")~=nil)then
		      hero:RemoveModifierByName("modifier_silencer_int_steal")
		    end
		    return 1.0
		  end
		,1.0)
	elseif(heroName == "npc_dota_hero_tinker")then
		abilityEx = hero:FindAbilityByName("ability_thdots_yumemiEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_axe")then
		hero:SetContextThink("ability_cirno_ex", 
		    function()
		    	if GameRules:IsGamePaused() then return 0.03 end
				local cirnosmanaperc = hero:GetManaPercent()
		      	if hero:GetIntellect(false)~=9 then
		        	hero:ModifyIntellect(9-hero:GetIntellect(false))
					hero:SetMana(cirnosmanaperc*hero:GetMaxMana())
		      	end
		      return 0.1
		    end, 
		0.1)
	elseif(heroName == "npc_dota_hero_kunkka")then
		--GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(THDOTSGameMode, 'OnMinamitsu04Order'), self)
	elseif(heroName == "npc_dota_hero_puck")then
		abilityEx = hero:FindAbilityByName("ability_thdots_RanEx")
		abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_venomancer")then
		-- Damage filter is registered once in CaptureGameMode.
		abilityEx = hero:FindAbilityByName("ability_thdots_YuukaEx")
		abilityEx:SetLevel(1)
		abilityEx2 = hero:FindAbilityByName("ability_thdots_YuukaEx2")
		abilityEx2:SetLevel(1)
	elseif(heroName == "npc_dota_hero_visage")then
	   	abilityEx = hero:FindAbilityByName("ability_thdots_MargatroidEx")
	    abilityEx:SetLevel(1)

	    local doll=CreateUnitByName(
					"ability_margatroidex_doll",
					hero:GetOrigin(),
					false,
					hero,
					hero,
					hero:GetTeam())
		doll:SetModel("models/alice/penglai.vmdl")
		doll:SetOriginalModel("models/alice/penglai.vmdl")
		doll:RemoveSelf()
	elseif(heroName == "npc_dota_hero_phantom_assassin")then
	   	abilityEx = hero:FindAbilityByName("ability_thdots_nueEx")
	    abilityEx:SetLevel(1)
	elseif(heroName == "npc_dota_hero_rubick")then
		abilityEx = hero:FindAbilityByName("ability_thdots_satori01")
		hero:AddNewModifier(hero, abilityEx, "modifier_ability_thdots_satori01_target", {})
		--hero:FindAbilityByName("rubick_empty2"):SetHidden(true)
	elseif(heroName == "npc_dota_hero_invoker")then		
		local ability = hero:FindAbilityByName("ability_thdots_patchouli_xianzhezhishi")
		ability:SetLevel(1)	
		ability = hero:FindAbilityByName("ability_thdots_patchouli_fire_fire")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_fire_water")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_fire_wood")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_fire_metal")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_fire_earth")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_water_water")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_water_wood")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_water_metal")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_water_earth")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_wood_wood")
		ability:SetLevel(1)
		ability:SetHidden(true)		
		ability = hero:FindAbilityByName("ability_thdots_patchouli_wood_metal")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_wood_earth")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_metal_metal")
		ability:SetLevel(1)
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_patchouli_metal_earth")
		ability:SetLevel(1)
		ability:SetHidden(true)		
		ability = hero:FindAbilityByName("ability_thdots_patchouli_earth_earth")
		ability:SetLevel(1)
		ability:SetHidden(true)
	elseif (heroName == "npc_dota_hero_lich") then
	   	abilityEx = hero:FindAbilityByName("ability_thdots_koakumaex")
	    abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_dazzle") then
		-- Damage filter is registered once in CaptureGameMode.
		abilityEx = hero:FindAbilityByName("ability_thdots_lunasaEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_lunasa_wanbaochui")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_dragon_knight") then
		abilityEx = hero:FindAbilityByName("ability_thdots_meirinex")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_weaver") then
		abilityEx = hero:FindAbilityByName("ability_thdots_lyricaEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_mars") then
		abilityEx = hero:FindAbilityByName("ability_thdots_shouEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_night_stalker") then
		abilityEx = hero:FindAbilityByName("ability_thdots_mystiaex")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_earth_spirit") then
		abilityEx = hero:FindAbilityByName("ability_thdots_MerlinEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_vengefulspirit") then
		abilityEx = hero:FindAbilityByName("ability_thdots_hatateEx")
		abilityEx:SetLevel(1)	
	elseif (heroName == "npc_dota_hero_riki") then
		abilityEx = hero:FindAbilityByName("ability_thdots_kogasaex")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_gyrocopter") then
		abilityEx = hero:FindAbilityByName("ability_thdots_teiex")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_spectre") then
		abilityEx = hero:FindAbilityByName("ability_thdots_nitoriEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_legion_commander") then
		abilityEx = hero:FindAbilityByName("ability_thdots_kokoroEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_kokoroEx_2")
		abilityEx:SetLevel(1)
		-- abilityEx = hero:FindAbilityByName("ability_thdots_kokoro03_release")
		-- abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_luna") then
		abilityEx = hero:FindAbilityByName("ability_thdots_childEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_phantom_lancer") then
		abilityEx = hero:FindAbilityByName("ability_thdots_reisen_2_04")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_witch_doctor") then
		abilityEx = hero:FindAbilityByName("ability_thdots_hinaEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_hina05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_lycan") then
		abilityEx = hero:FindAbilityByName("ability_thdots_kagerouEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_batrider") then
		abilityEx = hero:FindAbilityByName("ability_thdots_seijaEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_leshrac") then
		abilityEx = hero:FindAbilityByName("ability_thdots_lily05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_ursa") then
		abilityEx = hero:FindAbilityByName("ability_thdotsr_NazrinEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_chen") then
		abilityEx = hero:FindAbilityByName("ability_thdotsr_star05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_sven") then
		abilityEx = hero:FindAbilityByName("ability_thdots_yorihime_Ex")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_yorihime_ultimateEX")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_rattletrap") then
		abilityEx = hero:FindAbilityByName("ability_thdots_sunnyEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_sunny05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_terrorblade") then
		abilityEx = hero:FindAbilityByName("ability_thdots_chenEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_chen04")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_ogre_magi") then
		abilityEx = hero:FindAbilityByName("ability_thdots_suwako05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_skywrath_mage") then
		abilityEx = hero:FindAbilityByName("ability_thdots_sumirekoEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_marci") then
		abilityEx = hero:FindAbilityByName("ability_thdots_renkoEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_broodmother") then
		abilityEx = hero:FindAbilityByName("ability_thdots_yamameEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_nyx_assassin") then
		abilityEx = hero:FindAbilityByName("ability_thdots_daiyouseiEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_void_spirit") then
		abilityEx = hero:FindAbilityByName("ability_thdots_keineEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_winter_wyvern") then
		abilityEx = hero:FindAbilityByName("ability_thdots_lettyEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_pugna") then
		abilityEx = hero:FindAbilityByName("ability_thdots_parseeEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_disruptor") then
		abilityEx = hero:FindAbilityByName("ability_thdots_tojikoEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_tojiko05")
		abilityEx:SetLevel(1)
		if hero:GetModelName() == "models/tojiko/tojiko.vmdl" then
			local tojikoEx_particle = ParticleManager:CreateParticle("models/tojiko/tojiko/lightning.vpcf", PATTACH_CUSTOMORIGIN, hero)
			ParticleManager:SetParticleControlEnt(tojikoEx_particle , 0, hero, 5, "attach_wq_fx", Vector(0,0,0), true)
			ParticleManager:CreateParticle("models/tojiko/tojiko/cloud.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
		end
	elseif (heroName == "npc_dota_hero_omniknight") then
		abilityEx = hero:FindAbilityByName("ability_thdots_kisumeEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_kisume05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_arc_warden") then
		abilityEx = hero:FindAbilityByName("void_spirit_aether_remnant")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_grimstroke") then
		abilityEx = hero:FindAbilityByName("ability_thdots_seigaEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_seiga05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_undying") then
		abilityEx = hero:FindAbilityByName("ability_thdots_miyakoEx")
		abilityEx:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_miyako05")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_bristleback") then
		local ability = hero:FindAbilityByName("ability_thdots_kasen04_ex")
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_kasen04_ex_WBC")
		ability:SetHidden(true)
		ability:SetLevel(1)
		abilityEx = hero:FindAbilityByName("ability_thdots_kasenEx")
		abilityEx:SetLevel(1)	
		abilityEx = hero:FindAbilityByName("ability_thdots_kasenEx_WBC")
		abilityEx:SetHidden(true)
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_dark_willow") then
		abilityEx = hero:FindAbilityByName("ability_thdots_larvaEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_viper") then
		abilityEx = hero:FindAbilityByName("ability_thdots_medicineEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_dawnbreaker") then
		abilityEx = hero:FindAbilityByName("ability_thdots_mikoWanbao")
		abilityEx:SetLevel(1)
		abilityEx:SetHidden(true)
		abilityEx = hero:FindAbilityByName("ability_thdots_mikoEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_obsidian_destroyer") then
		abilityEx = hero:FindAbilityByName("ability_thdots_yukariEx")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_abyssal_underlord") then
		abilityEx = hero:FindAbilityByName("ability_thdots_rinEx")
		abilityEx:SetLevel(1)
		hero:AddNewModifier(hero, abilityEx, "modifier_ability_thdots_rinEx_buff", {})
		hero.limit = abilityEx:GetSpecialValueFor("limit")
		print(hero.limit)
		abilityEx = hero:FindAbilityByName("ability_thdots_rin_wbc")
		abilityEx:SetLevel(1)
		abilityEx:SetHidden(true)
	elseif (heroName == "npc_dota_hero_death_prophet") then
		local ability = hero:FindAbilityByName("ability_thdots_shion_05")
		ability:SetHidden(true)
		abilityEx = hero:FindAbilityByName("ability_thdots_shion_ex")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_queenofpain") then
		abilityEx = hero:FindAbilityByName("ability_thdots_sagume_Ex")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_meepo") then
		abilityEx = hero:FindAbilityByName("ability_thdots_Jyoon_passive")
		abilityEx:SetLevel(1)
	elseif (heroName == "npc_dota_hero_lone_druid") then
		abilityEx = hero:FindAbilityByName("ability_thdots_shizuhaEXNew")
		abilityEx:SetLevel(1) --开局设置天生技能一级
	elseif (heroName == "npc_dota_hero_oracle") then
		abilityEx = hero:FindAbilityByName("ability_thdots_toyohimeEx")
		abilityEx:SetLevel(1) --开局设置天生技能一级
		local ability = hero:FindAbilityByName("ability_thdots_toyohime03_back")
		ability:SetHidden(true)
		ability:SetLevel(1)
		ability = hero:FindAbilityByName("ability_thdots_toyohime04_end")
		ability:SetHidden(true)
		ability:SetLevel(1)
	end
end

G_Player_randomed = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

local HIGH_GROUND_TOWER_ABILITIES = {
	"tower_ursa_fury_swipes",
	"tower_shredder_reactive_armor",
}

-- 双方 T3/T4 只保留三级叠伤与活性护甲；重复初始化也清除旧的热血战魂。
function THDOTSGameMode:AddHighGroundTowerAbilities()
	local towers = Entities:FindAllByClassname("npc_dota_tower") or {}
	for _, tower in pairs(towers) do
		local unitName = tower:GetUnitName()
		if string.find(unitName, "tower3", 1, true) or string.find(unitName, "tower4", 1, true) then
			if tower:FindAbilityByName("tower_troll_warlord_fervor") ~= nil then
				tower:RemoveAbility("tower_troll_warlord_fervor")
			end
			for _, abilityName in ipairs(HIGH_GROUND_TOWER_ABILITIES) do
				local ability = tower:FindAbilityByName(abilityName)
				if ability == nil then
					ability = tower:AddAbility(abilityName)
				end
				if ability ~= nil and ability:GetLevel() ~= 3 then
					ability:SetLevel(3)
				end
			end
		end
	end
end

function THDOTSGameMode:OnGameRulesStateChange(keys)
	local newState = GameRules:State_Get()
	SetupSurrenderGuard:OnStateChange(newState)
	if newState == 2 then -- CUSTOM_GAME_SETUP / shuffle
		-- WebApi:SetTesting(true)
		WebApi:BeforeMatch(THD2_Rating_Catcher)
		ModeSelect()
		if THD2_GetBotMode() then
			BotModSelect()
			OpenBotDifficultyEditorOnGameRulesStateChange()
			GameRules:SendCustomMessage("#BotMode_Explain1",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain2",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain3",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain4",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain5",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain6",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain7",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain8",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain9",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain10",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain11",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain12",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain13",0,0)
			GameRules:SendCustomMessage("#BotMode_Explain14",0,0)
		else
			GameRules:SendCustomMessage("#BP_Explain1",0,0)
			GameRules:SendCustomMessage("#RANKDC_Explain1",0,0)
			for _,banName in pairs(THD2_BAN_LIST) do
				GameRules:AddHeroToBlacklist(banName)
			end
		end
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then -- HERO_SELECTION
        --关闭模式选择窗口
        CloseGameMod()

		if not THD2_GetDotaMixedMode() then
			for i, enableName in pairs(DOTA_BAN_LIST) do
				GameRules:AddHeroToBlacklist(enableName)
			end
		end

		-- 需要addoninfo.txt中EnablePickRules = true来启用DotaBP
		if not BP_MODE then
			-- 取消（跳过）DotaBP
			--GameRules:GetGameModeEntity():SetDraftingHeroPickSelectTimeOverride(60)
			--GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(0)
		else
			-- BP Mode
			--local banningTime = 15
			--GameRules:GetGameModeEntity():SetDraftingHeroPickSelectTimeOverride(60)
			--GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(banningTime)
			--GameRules:SetCustomGameBansPerTeam(5)

			GameRules:GetGameModeEntity():SetContextThink(
			"msg delay",
			function()
				GameRules:SendCustomMessage("#BP_Explain5",0,0)
				--GameRules:SendCustomMessage("#BP_New_Explain2",0,0)
				--GameRules:SendCustomMessage("#BP_New_Explain3",0,0)

				--更新ui, 取消随机按钮
				THD_Set_Random_Usable(false)

				-- 禁用阶段结束后恢复随机按钮
				--Timers:CreateTimer(banningTime, function()
				--	THD_Set_Random_Usable(true)
				--end)

				return nil
			end,
			0.2
		)
		end
		
		--[[
		GameRules:GetGameModeEntity():SetContextThink(
			"msg delay",
			function()
				HostSay("Please input -random to pick randomly.")
				HostSay("input -random will get 200 extra gold.")
				HostSay("click random button won't get anything.")
				return nil
			end,
			0.2
		)
		]]--
		-- local num = GetNum()
		-- HostSay("num is " .. tostring(num))
		
		--原加钱弃用, 现在随机时直接加
		--[[
		GameRules:GetGameModeEntity():SetContextThink(
			"random checker",
			function()
				for i=0,20 do
					if G_Player_randomed[i+1] == 0 and PlayerResource:HasRandomed(i) then
						G_Player_randomed[i+1] = 1
						PlayerResource:ModifyGold(i,200,true,0);
					end
				end
				if GameRules:State_Get() >= 4 then return nil end
				return 0.2
			end,
			0.2
		)
		]]--
	elseif newState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		
		if BP_MODE then 
			print("startBp")
			THDOTSGameMode:CheckChoose()
			for i=0,63 do
				if PlayerResource:GetPlayer(i) ~= nil then
					if PlayerResource:HasSelectedHero(i) ~= false then
						local name = PlayerResource:GetSelectedHeroName(i)
						local id = PlayerResource:GetSelectedHeroID(i)
						THD2_BPBanHero(name, id)
					end
				end
			end
			BP_MODE = false
			GameRules:SendCustomMessage("#BP_Explain6",0,0)
			GameRules:GetGameModeEntity():SetContextThink(
						"Return to Selection",
						function()
							GameRules:SetHeroSelectionTime(60);
							GameRules:SetHeroSelectPenaltyTime(30);
							GameRules:ResetToHeroSelection()
							--启用随机
							THD_Set_Random_Usable(true)
							return nil
						end,
						5.0
					)
			return
		end
		--如果有人没选英雄则自动暂停游戏
		local has_patchouli = false
		local has_youmu = false
		for i =0,63 do
			if PlayerResource:GetPlayer(i) ~= nil then
				if PlayerResource:HasSelectedHero(i) == false then
					
					THDOTSGameMode:CheckChoose()
				end
				--对帕秋莉玩家的提醒
				if PlayerResource:GetSelectedHeroName(i) == "npc_dota_hero_invoker" and not has_patchouli then
					has_patchouli = true
				elseif PlayerResource:GetSelectedHeroName(i) == "npc_dota_hero_juggernaut" and not has_youmu then
					GameRules:SendCustomMessage("#Youmu2Explain1", 0, 0)
					GameRules:SendCustomMessage("#Youmu2Explain2", 0, 0)
					has_youmu = true
				end
			end
		end
		
		THD2_ForceClone(); --will check at inside
		
		if THD2_GetBotMode() == true then
		
			HostSay("You're in bot mode.")
			HostSay("Bot Difficulty: " .. THD2_GetBotDiffName())
			
			THD2_AddBot()
			
		end
		
		THD2_ForceClone(); --will check at inside
		
		
    elseif newState == DOTA_GAMERULES_STATE_TEAM_SHOWCASE then  --显示人物的阶段(过场)
		--random hero for anyone which not choosed
		THDOTSGameMode:CheckChoose()
    elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then -- 地图加载好了, 所有人准备出门
		self:AddHighGroundTowerAbilities()
		if GetMapName() ~= "dota" then
			-- thdots地图
			GameRules:GetGameModeEntity():SetContextThink("roshanRemove_delay",
			function()
				-- 移除原roshan
				local roshan = Entities:FindByClassname(nil, "npc_dota_roshan")
				if roshan ~= nil then roshan:RemoveSelf() else print("roshan is nil") end

				-- 自己生成肉山
				local ROSHAN_ENT = CreateUnitByName("npc_dota_roshan", _G.ROSHAN_SPAWN_LOC, true, nil, nil, DOTA_TEAM_NEUTRALS)
				ROSHAN_ENT:AddNewModifier(ROSHAN_ENT, nil, "modifier_imba_roshan_ai", {})
				ROSHAN_ENT:SetOriginalModel("models/alice/golyat.vmdl")
				return nil
			end,
			0.2
			)
		end

		if THD2_GetBotMode() == true then
			HostSay("Bot Difficulty: " .. THD2_GetBotDiffName())
			-- 启用人机
			Convars:SetBool("dota_bot_mode", true)
			Convars:SetBool("dota_bot_disable", false)
		end
		--[[if THD2_GetFRSMode() then -- fast respawn mode
			GameMode:SetFixedRespawnTime( THD2_GetFRSTime() )
			HostSay("Fast Respawn Mode ON")
		end--]]
		if THD2_GetFRSMode() then
			HostSay("Fast Respawn Mode ON")
			HostSay("Fast Respawn Value: "..THD2_GetFRSValue().."%")
		end
		if THD2_GetFCDMode() then
			HostSay("Fast CoolDown Mode ON")
		end
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then  --游戏到达 00:00(第一次刷符)
	
		--开启神符修正机制
		rune_fixer_init()
		THD2_neutral_spawner_fixer()	-- 刷野修正
		THD2_BotPushAllWithDelay()
		THD2_StartBotObserverWardThinker()
		GameRules:SetTimeOfDay(0.25)
		MushRoomStart() 		--刷蘑菇系统
		AddBotsToTable()
		-- Bot 身份与信使 owner 均已稳定后，补扫并添加永久无敌。
		THD2_RefreshBotCourierShields()
		local TeamRadiant = botTable[DOTA_TEAM_GOODGUYS]
    	local TeamDire = botTable[DOTA_TEAM_BADGUYS]
		Timers:CreateTimer(function()
        NeutralItems.GiveNeutralItems(TeamRadiant, TeamDire)
		return 1
		end)
		if EnableMegaCreeps then
			siege_start_interval()	--超级兵系统
		end
    end
  
	print(newState)
	
	if newState == 7 then
		AddObViews() --添加未分配玩家的观战视野
		G_Player_sighted = {}
		
		THD_SetGlobalContextThink( "observe sight", function ( ... )
			for i = 0,63 do
				if G_Player_sighted[i] == nil and PlayerResource:GetPlayer(i) ~= nil then
					print(i)
					local playerhero = PlayerResource:GetPlayer(i):GetAssignedHero()
					if PlayerResource:GetSelectedHeroName(i) ~= "npc_dota_hero_monkey_king"
					and playerhero ~= nil then
						if PlayerResource:GetPlayerCountForTeam(6) > 0 then
							CreateObserveSightUnit(playerhero)
						end
						G_Player_sighted[i] = true
						
					end
				end
			end
			if GameRules:State_Get() == 7 then
				return 5.0
			else
				return nil
			end
		end , 5.0)
		URD_initialize()		--投降系统初始化
	end
	if newState == 9 then

	end
	
	if newState == DOTA_GAMERULES_STATE_POST_GAME and not RDC_MODE then
		-- WebApi:SetTesting(true)
		print("do it")
		WebApi:AfterMatch()
	end
	--之前的信使加载
	--[[
	if newState == 7 then
		GameRules:GetGameModeEntity():SetContextThink( "thetime", function ( ... )
			for i = 0,63 do
				if G_Player_courier[i] == nil and PlayerResource:GetPlayer(i) ~= nil then
					print(i)
					local playerhero = PlayerResource:GetPlayer(i):GetAssignedHero()
					if PlayerResource:GetSelectedHeroName(i) ~= "npc_dota_hero_monkey_king"
					and playerhero ~= nil then
						local xinshi = CreateUnitByName(
						"npc_dota_courier", 
						playerhero:GetOrigin() + ( playerhero:GetForwardVector() * 100), 
						false, 
						playerhero, 
						playerhero, 
						playerhero:GetTeam()
						)
						xinshi:SetControllableByPlayer(i, true)
						xinshi:SetOriginalModel("models/items/courier/shibe_dog_cat/shibe_dog_cat_flying.vmdl")
						--local ID = Caster:GetPlayerOwnerID()
						--xinshi:SetControllableByPlayer(ID,true)	
						local ability = xinshi:AddAbility("ability_system_fly")
						ability:SetLevel(1)	
						ability = xinshi:FindAbilityByName("courier_burst")
						ability:SetLevel(1)	
						if PlayerResource:GetPlayerCountForTeam(6) > 0 then
							CreateObserveSightUnit(playerhero)
						end
						G_Player_courier[i] = xinshi
					end
				end
			end
			if GameRules:State_Get() == 7 then
				return 5.0
			end
		end , 5.0)
	end
	]]--
  
end

--[[
-- 与OnTHDOTSOrderFilter合并
function THDOTSGameMode:OnMinamitsu04Order(keys)
  if keys.units["0"] ~= nil then
    local orderUnit = EntIndexToHScript(keys.units["0"])
    if orderUnit ~= nil then
      if keys.order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
        if orderUnit:GetClassname() == "npc_dota_hero_kunkka" then
          if keys.entindex_target == orderUnit.ability_minamitsu_ship_index then
            local ship = EntIndexToHScript(orderUnit.ability_minamitsu_ship_index)
            self:OnMinamitsuMoveToShip(orderUnit,ship)
          end
        elseif orderUnit:GetUnitName() == "ability_minamitsu_04_ship"  then
          if keys.entindex_target == orderUnit.ability_minamitsu_hero_index then
            local hero = EntIndexToHScript(orderUnit.ability_minamitsu_hero_index)
            self:OnMinamitsuMoveToShip(hero,orderUnit)
            return false
          end
        end
      elseif keys.order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
        if orderUnit:GetClassname() == "npc_dota_hero_kunkka" then
          if orderUnit.IsDriving then
            local ship = orderUnit.ability_minamitsu_ship
            if ship ~= nil and ship:IsNull() == false then
              ship:MoveToPosition(Vector(keys.position_x,keys.position_y,keys.position_z))
            end
          end
        end
      end
    end
  end
  return true
end
--]]


function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function THDOTSGameMode:OnTHDOTSDamageFilter(keys)
	if keys.entindex_attacker_const == nil or keys.entindex_victim_const == nil then
		return true
	end
	local unit = EntIndexToHScript(keys.entindex_attacker_const) --施加伤害者
	local target = EntIndexToHScript(keys.entindex_victim_const) --受伤害者
	if THD2_ApplyLaneCreepMarchProtectionDamage ~= nil then
		THD2_ApplyLaneCreepMarchProtectionDamage(keys)
	end
	if THD2_ApplyBotCourierShieldDamage ~= nil then
		THD2_ApplyBotCourierShieldDamage(keys)
	end
	target.damage = keys.damage
	if target:IsHero() and not target:IsIllusion() then
		if target:HasModifier("modifier_item_aegis") then
			target.HasAegis = true
			-- print(target.HasAegis)
		else
			target.HasAegis = false
			-- print(target.HasAegis)
		end
	end
	if keys.damagetype_const == 2 and keys.damage >= 50 then
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,target,keys.damage,nil)
	end
	if unit ~= nil and unit:IsNull() == false and target ~= nil and target:IsNull() == false then
		--莲子4技能物理伤害增幅监听
		if (keys.damagetype_const == DAMAGE_TYPE_PHYSICAL or keys.damagetype_const == 1) and unit:HasModifier("modifier_ability_thdots_renko04_physical_damage") then
			local renko04PhysicalDamageBonusPct = unit:GetModifierStackCount("modifier_ability_thdots_renko04_physical_damage", nil)
			if renko04PhysicalDamageBonusPct > 0 then
				keys.damage = keys.damage * (1 + renko04PhysicalDamageBonusPct / 100)
			end
		end
		--提琴伤害监听
		if unit:IsHero() and unit:GetName() == "npc_dota_hero_dazzle" and keys.entindex_inflictor_const ~= nil then --entindex_inflictor_const是伤害来源,普攻为nil
			local LUNASA_DAMAGE_BONUS_PERCENT = unit:GetModifierStackCount("modifier_lunasa03", unit)/100 --法术暴击几率
			local percent = RandomFloat(0, 1.00) --随机数, 若几率大于随机数则暴击
			if LUNASA_DAMAGE_BONUS_PERCENT >= percent then
			local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_surge_start_fallback_low.vpcf", PATTACH_POINT, unit)
			ParticleManager:DestroyParticleSystem(effectIndex,false)
				keys.damage = keys.damage * 2
			end
		end
		--因幡帝3技能伤害监听
		if target:GetName() == "npc_dota_hero_gyrocopter" and keys.entindex_inflictor_const == nil and target:HasModifier("modifier_ability_thdots_tei03") 
			and unit:IsRangedAttacker() then
			local damage_reduce = 1 -FindValueTHD("beattacked_reduce",target:FindAbilityByName("ability_thdots_tei03")) / 100
			keys.damage = keys.damage * damage_reduce
		end
		--幽香花伤害对塔伤害监听
		if unit:GetUnitName()=="ability_yuuka_flower" and target:IsBuilding() then
			keys.damage = keys.damage * 0.15
		end
		if unit:IsHero()==false then
			local owner = unit:GetOwner()
			if owner ~= nil then
				unit = owner
			end
		end
		--幽幽子死亡BUFF伤害监听
		if target:GetClassname()=="npc_dota_hero_necrolyte" and target:GetContext("ability_yuyuko_Ex_deadflag") == FALSE  and target:IsRealHero() then
			if keys.damage >= target:GetHealth() then
				local vecCaster = target:GetOrigin()
				local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yuyuko/ability_yuyuko_04_effect.vpcf", PATTACH_CUSTOMORIGIN, target)
				ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
				ParticleManager:DestroyParticleSystem(effectIndex,false)

				effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/yuyuko/ability_yuyuko_04_effect_a.vpcf", PATTACH_CUSTOMORIGIN, target)
				ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
				ParticleManager:SetParticleControl(effectIndex, 5, target:GetOrigin())
				ParticleManager:DestroyParticleSystem(effectIndex,false)
				local ability = target:FindAbilityByName("ability_thdots_yuyukoEx")
				ability:ApplyDataDrivenModifier(target, target, "modifier_thdots_yuyukoEx", {})
				target:SetHealth(target:GetMaxHealth())
				UnitNoDamageTarget(target,target,10)
				if FindTelentValue(target,"special_bonus_unique_yuyuko_4") == 0 then
					UnitDisarmedTarget(target,target,10)					
				end
				target:SetContextNum("ability_yuyuko_Ex_deadflag",TRUE,0)
				local gameTime = GameRules:GetGameTime()
				target:SetContextThink(DoUniqueString("abilityyuyuko_Ex_undead_timer"), 
					function()
						if GameRules:IsGamePaused() then return 0.03 end
						if GameRules:GetGameTime() - gameTime <= 10.1 then
							if target:IsAlive() == false then
								target:SetContextNum("ability_yuyuko_Ex_deadflag",FALSE,0)
								return nil
							end
							local Distance = GetDistanceBetweenTwoVec2D(target:GetOrigin(),vecCaster)						--百合的束缚
							local FirstDistance = 300
							if Distance > FirstDistance and FindTelentValue(target,"special_bonus_unique_yuyuko_4") == 0 then
								local CasterPos = target:GetAbsOrigin()
								local vec = vecCaster - CasterPos
								local MaxSpeed = 800
								local MoveDistance = (Distance-FirstDistance)
								MoveDistance=(MoveDistance*MoveDistance)/(200*200)*MaxSpeed*0.05
								if MoveDistance>1.0 then
									target:SetAbsOrigin(CasterPos + vec:Normalized()*MoveDistance)
								end
							end
							return 0.05
						else
							if(unit~=nil)then
								target:SetHealth(1)
								target:Kill(keys.ability, unit)
						    else
						    	target:Kill(keys.ability, target)
						    end
						    target:SetContextNum("ability_yuyuko_Ex_deadflag",FALSE,0)
						    return nil
						end
					end, 
				0.05)
				return false
			end
		end
	end
	return true
end

function THDOTSGameMode:OnTHDOTSOrderFilter(keys)

	if keys.units["0"] == nil then return true end

	------------------------------------------------------------------------------------
	-- SelfCast
	------------------------------------------------------------------------------------
	local orderUnit = EntIndexToHScript(keys.units["0"])

	local target = keys.entindex_target ~= 0 and EntIndexToHScript(keys.entindex_target) or nil
	local ability = keys.entindex_ability ~= 0 and EntIndexToHScript(keys.entindex_ability) or nil

	-- 实验性 Bot 副包施法桥接默认关闭；启用时由模块接管白名单消耗品并重发原生订单。
	local bridgeResult = BotBackpackCastBridge.FilterOrder(keys)
	if bridgeResult ~= nil then return bridgeResult end

	if ability ~= nil then
		if ability.selfCastToFountain == true then
			if keys.order_type == DOTA_UNIT_ORDER_CAST_TARGET then
				if target == orderUnit then
					keys.order_type = DOTA_UNIT_ORDER_CAST_POSITION
					local absOrigin = orderUnit:GetFountainAbsOrigin()
					keys.position_x = absOrigin.x
					keys.position_y = absOrigin.y
					keys.position_z = absOrigin.z
					return true
				else
					-- 防止点头像（对目标）没反应
					keys.order_type = DOTA_UNIT_ORDER_CAST_POSITION
					local absOrigin = target:GetAbsOrigin()
					keys.position_x = absOrigin.x
					keys.position_y = absOrigin.y
					keys.position_z = absOrigin.z
					return true
				end
			end
		end
	end

	------------------------------------------------------------------------------------
		-- OnMinamitsu04Order
	------------------------------------------------------------------------------------
	if keys.units["0"] ~= nil
	and (keys.order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET or keys.order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION)
	then
		--local orderUnit = EntIndexToHScript(keys.units["0"])
		if orderUnit ~= nil then
		  if keys.order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
			if orderUnit:GetClassname() == "npc_dota_hero_kunkka" then
			  if keys.entindex_target == orderUnit.ability_minamitsu_ship_index then
				local ship = EntIndexToHScript(orderUnit.ability_minamitsu_ship_index)
				self:OnMinamitsuMoveToShip(orderUnit,ship)
			  end
			elseif orderUnit:GetUnitName() == "ability_minamitsu_04_ship"  then
			  if keys.entindex_target == orderUnit.ability_minamitsu_hero_index then
				local hero = EntIndexToHScript(orderUnit.ability_minamitsu_hero_index)
				self:OnMinamitsuMoveToShip(hero,orderUnit)
				return false
			  end
			end
		  elseif keys.order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
			if orderUnit:GetClassname() == "npc_dota_hero_kunkka" then
			  if orderUnit.IsDriving then
				local ship = orderUnit.ability_minamitsu_ship
				if ship ~= nil and ship:IsNull() == false then
				  ship:MoveToPosition(Vector(keys.position_x,keys.position_y,keys.position_z))
				end
			  end
			end
		  end
		end
	  end

	return true
end

function THDOTSGameMode:OnMinamitsuMoveToShip(hero,ship)
  local ability = hero:FindAbilityByName("ability_thdots_minamitsu04")
  if ability ~= nil then
    hero:SetContextThink("ability_thdots_minamitsu_04_move_to_ship",
     	 function ()
     	 	if GameRules:IsGamePaused() then return 0.03 end
	        if hero ~= nil and ship ~= nil and ship:IsNull()==false and hero:IsNull() == false then
	          local shipAbility = ship:FindAbilityByName("ability_thdots_minamitsu04_unit_upload")
	          ship:CastAbilityOnTarget(hero,shipAbility, hero:GetPlayerOwnerID())
	        else
          return nil
        end
      end,
    0.03)
  end
end

function THDOTSGameMode:OnMinamitsu04ShipDownload(caster)
	caster.IsDriving = false
	caster:EmitSound("Voice_Thdots_Minamitsu.AbilityMinamitsu042")
	FindClearSpaceForUnit(caster, caster:GetOrigin(), false)
	caster:MoveToPositionAggressive(caster:GetOrigin())
	caster:RemoveNoDraw()
	caster:RemoveModifierByName("modifier_minamitsu04_Invincible")

	Timer.Wait 'ability_minamitsu_04_remove_speed' (2,
		function()
			if caster.IsDriving == false then
				if caster.ability_minamitsu_ship ~= nil and caster.ability_minamitsu_ship:IsNull() == false then
					caster.ability_minamitsu_ship:RemoveModifierByName("modifier_minamitsu04_speed")
				end
			end
		end
	)
end


Cast_xianzhezhishi = function (keys)
	print(keys.val)
	local val = keys.val
	local plyid = keys.PlayerID
	
	if PlayerResource:GetSelectedHeroName(plyid) == "npc_dota_hero_invoker" then
			
		local hero = PlayerResource:GetPlayer(plyid):GetAssignedHero()
		if hero == nil then return end
		local ability = nil 
		-- 按实际技能槽数量扫描，避免越界触发控制台警告。
		for i=0,hero:GetAbilityCount() - 1 do
			local currentAbility = hero:GetAbilityByIndex(i)
			if currentAbility ~= nil and currentAbility:GetAbilityName() ==
			"ability_thdots_patchouli_xianzhezhishi" then
				ability = currentAbility
			end
		end
			
		if ability ~= nil then
			hero:CastAbilityNoTarget(ability, plyid)
		end
	
	end
	
end

RegisterCustomEventListener("Cast_xianzhezhishi", Cast_xianzhezhishi)

function THDOTSGameMode:On_dota_item_purchase(keys)
	print_r(keys)
	print("dddddddddddddd")
end

function THDOTSGameMode:On_dota_item_purchased(keys)
	--这一段代码表示购卡时将商店显示的卡片删除，然后在购买的单位身上添加相应的使用卡片
	print("[BAREBONES] dota_item_purchased")
	local playerid = keys.PlayerID
	local hero = PlayerResource:GetPlayer(playerid):GetAssignedHero()
	if hero == nil then return end
	local item_name = keys.itemname
	local remove_item_name = nil
	local add_item_name = nil
	if item_name == "item_card_good_man_shop" then
		add_item_name = "item_card_good_man"
		remove_item_name = item_name
	elseif item_name == "item_card_bad_man_shop" then
		add_item_name = "item_card_bad_man" 
		remove_item_name = item_name
	elseif item_name == "item_card_love_man_shop" then
		add_item_name = "item_card_love_man" 
		remove_item_name = item_name
	elseif item_name == "item_card_worse_man_shop" then
		add_item_name = "item_card_worse_man" 
		remove_item_name = item_name
	elseif item_name == "item_card_kid_man_shop" then
		add_item_name = "item_card_kid_man" 
		remove_item_name = item_name
	elseif item_name == "item_card_eat_man_shop" then
		add_item_name = "item_card_eat_man" 
		remove_item_name = item_name
	elseif item_name == "item_card_moon_man_shop" then
		add_item_name = "item_card_moon_man" 
		remove_item_name = item_name
	elseif item_name == "item_card_super_man_shop" then
		add_item_name = "item_card_super_man" 
		remove_item_name = item_name
	else
		return
	end

	-- lock hero items
	local unlocked_indices = {}
	for i=0,30 do
		local old_item = hero:GetItemInSlot(i)
		if old_item and not old_item:IsCombineLocked() then
			table.insert(unlocked_indices, i)
			old_item:SetCombineLocked(true)
		end
	end

	-- lock courier items
	local courier_unlocked_indices = {}
	local courier = PlayerResource:GetPreferredCourierForPlayer(playerid)
	if courier then
		for i=0,20 do
			local courier_item = courier:GetItemInSlot(i)
			if courier_item and not courier_item:IsCombineLocked() then
				table.insert(courier_unlocked_indices, i)
				courier_item:SetCombineLocked(true)
			end
		end
	end

	-- replace cards on hero
	for i=0,30 do
		local old_item = hero:GetItemInSlot(i)
		if old_item then
			if old_item:GetName() == remove_item_name then
				old_item:RemoveSelf()
				hero:AddItemByName(add_item_name)
			end
		end
	end

	-- replace cards on courier
	if courier then
		for i=0,20 do
			local courier_item = courier:GetItemInSlot(i)
			if courier_item then
				if courier_item:GetName() == remove_item_name then
					courier_item:RemoveSelf()
					courier:AddItemByName(add_item_name)
				end
			end
		end
	end

	-- unlock hero items
	for _, i in pairs(unlocked_indices) do
		local old_item = hero:GetItemInSlot(i)
		if old_item then
			old_item:SetCombineLocked(false)
		end
	end

	-- unlock courier items
	if courier then
		for _, i in pairs(courier_unlocked_indices) do
			local courier_item = courier:GetItemInSlot(i)
			if courier_item then
				courier_item:SetCombineLocked(false)
			end
		end
	end
end

RegisterCustomEventListener("Shuffle_Pressed", Shuffle_Pressed)

-- 人机基本模式
RegisterCustomEventListener("ChangeGamePause", ChangeGamePause)
RegisterCustomEventListener("ChangeGameDotaInter", ChangeGameDotaInter)
RegisterCustomEventListener("ChangeGameBotMode", ChangeGameBotMode)
RegisterCustomEventListener("ChangeGameDifficulty", ChangeGameDifficulty)
RegisterCustomEventListener("ChangeGameMaxPlayer", ChangeGameMaxPlayer)
RegisterCustomEventListener("ChangeGameMaxBot", ChangeGameMaxBot)

-- 人机难度模式
RegisterCustomEventListener("OpenBotDifficultyEditor", OpenBotDifficultyEditor)
RegisterCustomEventListener("SaveBotDifficultyData", SaveBotDifficultyData)
RegisterCustomEventListener("ResetBotDifficulty", ResetBotDifficulty)

RegisterCustomEventListener("get_camera_yaw_callback",get_camera_yaw_callback)



function THDOTSGameMode:OnItemPickedUp(keys)
	-- print_r(keys)
	-- print("dddddddddddddddddddddit")
	-- local heroEntity = nil
	-- if keys.HeroEntityIndex ~= nil then
	-- 	heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	-- else
	-- 	heroEntity = EntIndexToHScript(keys.UnitEntityINdex)
	-- end

	-- local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	-- local player = PlayerResource:GetPlayer(keys.PlayerID)
	-- local itemname = keys.itemname
	-- if type(itemEntity) ~= "table" then return false end
	-- if itemEntity:IsNull() then return false end
	-- local box = itemEntity:GetContainer()
	-- if box then box:RemoveSelf() end
	-- if itemEntity:GetCurrentCharges() > 0 then
	-- 	return
	-- end
	-- itemEntity:RemoveSelf()
	-- funitem:CreateItem(itemEntity, "item_card_eat_man",nil)
end

function THDOTSGameMode:On_dota_pause_event(keys)
	print("pause=================================")
	print_r(keys)
end

function THDOTSGameMode:On_dota_inventory_item_added(keys)
	local heroEntity
	local itemEntity
	--print("On_dota_inventory_item_added")
	if keys.inventory_parent_entindex ~= nil and keys.item_entindex ~= nil and EntIndexToHScript(keys.inventory_parent_entindex) ~= nil then
		heroEntity = EntIndexToHScript(keys.inventory_parent_entindex)
		--print("拿起人 "..heroEntity:GetClassname())
		itemEntity = EntIndexToHScript(keys.item_entindex)
		--print("物品 "..itemEntity:GetAbilityName())

		--Rapier
		if itemEntity.IsRapier then
			--print("IsRapier")
			if heroEntity:IsRealHero() or ( heroEntity:GetClassname() == "npc_dota_lone_druid_bear" ) then
				if not itemEntity:GetPurchaser() then
					--print("Not purchaser")
					itemEntity:SetPurchaser(heroEntity)
				end

				if itemEntity:GetPurchaser() and itemEntity:GetPurchaser():GetTeamNumber() ~= heroEntity:GetTeamNumber() then
					itemEntity.free = true
					--print("Free = true")
				end

				if itemEntity.free then
					--print("Free Item")
					itemEntity:SetPurchaser(heroEntity)
					itemEntity:SetPurchaseTime(0)
					itemEntity:SetDroppable(false)
				end
			end
		end

		if heroEntity:IsRealHero()
			and _G.THD2_IsBotHero(heroEntity)
			and itemEntity:GetAbilityName() == "item_kusanagi"
		then
			-- 拾取事件下一帧立即复用 Bot Buff 兑换，缩短临时腾格物品的落地时间。
			local modifierName = "modifier_bot_buff"
			if heroEntity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
				modifierName = "modifier_bot_buff_radiant"
			elseif heroEntity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
				modifierName = "modifier_bot_buff_dire"
			end

			THD_SetContextThink(heroEntity,
				"bot_kusanagi_pickup__" .. tostring(keys.item_entindex),
				function ()
					if heroEntity == nil or heroEntity:IsNull() then return nil end
					local botBuff = heroEntity:FindModifierByName(modifierName)
					if botBuff ~= nil and botBuff.SellKusanagiItems ~= nil then
						botBuff:SellKusanagiItems()
					end
					return nil
				end,
				0,
				"bot_kusanagi_pickup")
		end

		--不知道
		if itemEntity:GetShareability() ~= 2 then return end
		if itemEntity:GetPurchaser() ~= nil then
			--print("购买人 "..itemEntity:GetPurchaser():GetClassname())
			if heroEntity:GetTeam() ~= itemEntity:GetPurchaser():GetTeam() then
				--print("enemy")
				return
			end			
			if itemEntity:GetPurchaser():GetClassname() ~= heroEntity:GetClassname() then 
				--print("not Purchaser")
				THD_SetContextThink(heroEntity,
					"not Purchaser",
					function ()
						if GameRules:IsGamePaused() then return 0.05 end
						if heroEntity == nil or heroEntity:IsNull() then return nil end
						if itemEntity == nil or itemEntity:IsNull() then return nil end
						if heroEntity:IsRealHero() == false then
							--print("not hero")
							return nil
						end
						if heroEntity:HasModifier("modifier_illusion") then
							--print("is illusion")
							return nil
						end
						if heroEntity:IsConsideredHero() == true then
							--print("not hero")
							return nil
						end

						heroEntity:DropItemAtPositionImmediate(itemEntity, heroEntity:GetOrigin())
						return nil
					end,
					0.05,
					"inventory_not_purchaser")
			else
				--print("my item")
				--print("itemEntity: "..itemEntity:GetName())
			end
		end
	end
end

function AddBotsToTable()
    botTable[DOTA_TEAM_GOODGUYS] = {}
    botTable[DOTA_TEAM_BADGUYS] = {}

    for nTeam = 0, 3 do
        local pNum = PlayerResource:GetPlayerCountForTeam(nTeam)
        for i = 0, pNum do
            local playerID = PlayerResource:GetNthPlayerIDOnTeam(nTeam, i)
            local player = PlayerResource:GetPlayer(playerID)
            -- local connectionState = PlayerResource:GetConnectionState(playerID)
            -- print('Setting up Buff for player: '..playerID..', connection state: '..tostring(connectionState))
            if player then
                local hero = player:GetAssignedHero()
                local team = player:GetTeam()
                if hero ~= nil and botTable[team] ~= nil then
                    if PlayerResource:GetSteamID(hero:GetMainControllingPlayer()) == PlayerResource:GetSteamID(100) then
                        -- print('Instering bot player: '..hero:GetUnitName()..', to team: '..team)
                        table.insert(botTable[team], hero)
                    end
                else
                    -- print('[WARN] Failed to add player '.. playerID .. ' to bots list. Spectator?')
                end
            else
                -- print('[WARN] Failed to add player '.. playerID .. ' to bots list. Spectator?')
            end
        end
    end
end

-- local lmmTestCmd = {}
-- ListenToGameEvent('player_chat', lmmTestCmd:playerChat(context), lmmTestCmd)

-- function lmmTestCmd:playerChat(context)
-- 	local player = context.playerid
-- 	local text = context.text
--          -- 在这里判断玩家输入聊天框信息 
-- 	if text == '-windrunner' then
--                     --处理方法
-- 		self:windrunner(player)
-- 	end
-- end

-- -- 处理方法
-- function lmmTestCmd:windrunner(player)
-- 	local hero =  PlayerResource.GetAssignedHero(player)
-- 	-- 逻辑
-- end

