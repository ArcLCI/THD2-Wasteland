--[[
	多定位英雄配置集中放在此处。键使用原版英雄槽位名；未列出的英雄自动沿用
	specialmode.lua 中原有加点表，但仍会获得地图选定的通用定位标记。
]]
return {
	["npc_dota_hero_bounty_hunter"] = {
		defaultProfile = "frontline",
		rolePools = {"damage", "frontline"},
		abilityPlans = {
			frontline =
				{3,1,3,2,3,  6,3,1,1,11,  1,6,2,2,12, 2,0,6,0,15,  0,0,0,0,16,  0,10,13,14,17},
			damage =
				-- 物理核心前期保留两级白狼，随后主盾击、副天狗视觉；20级天赋补足视觉覆盖率。
				{1,3,1,3,3,  6,3,2,2,11,  2,6,2,1,13, 1,0,6,0,14,  0,0,0,0,17,  0,10,12,15,16},
		},
	},
	["npc_dota_hero_rattletrap"] = {
		defaultProfile = "frontline",
		rolePools = {"frontline", "support"},
		abilityPlans = {
			frontline =
				{2,1,2,3,2,  6,2,3,3,10,  3,6,1,1,12, 1,0,6,0,14,  0,0,0,0,17,  0,11,13,15,16},
			support =
				{3,2,3,1,3,  6,3,2,2,11,  2,6,1,1,13, 1,0,6,0,15,  0,0,0,0,17,  0,10,12,14,16},
		},
	},
	["npc_dota_hero_venomancer"] = {
		defaultProfile = "frontline",
		rolePools = {"frontline", "damage"},
		abilityPlans = {
			-- 双定位统一主二副一，6级继续补一技能，11-12级连点大招；前排保留原天赋路线。
			frontline =
				{2,1,2,1,2,  1,2,1,3,11,  6,6,3,3,12, 3,0,6,0,15,  0,0,0,0,17,  0,10,13,14,16},
			-- 输出定位采用相同的前期技能节奏，并保留输出路线原有的天赋选择。
			damage =
				{2,1,2,1,2,  1,2,1,3,10,  6,6,3,3,13, 3,0,6,0,15,  0,0,0,0,17,  0,11,12,14,16},
		},
	},
	["npc_dota_hero_spectre"] = {
		defaultProfile = "damage",
		rolePools = {"damage", "damage_spell"},
		abilityPlans = {
			-- 天生技能会自动升至1级；输出主近身反应、副推进器，2级补一级炮击用于对线消耗。
			damage =
				{3,2,3,1,3, 6,3,1,1,10, 1,6,2,2,12, 2,0,6,0,15, 0,0,0,0,16, 0,11,13,14,17},
			-- 第二输出定位主阳电子炮、副近身反应；25级取得额外浮游炮。
			damage_spell =
				{2,3,2,1,2, 6,2,3,3,11, 3,6,1,1,13, 1,0,6,0,14, 0,0,0,0,17, 0,10,12,15,16},
		},
	},
	["npc_dota_hero_terrorblade"] = {
		defaultProfile = "damage",
		rolePools = {"damage"},
		abilityPlans = {
			-- 橙固定物理核心；大招出生时已有一级，只在6/12/18级补满。
			damage =
				{3,1,3,2,3, 6,3,1,1,10, 1,6,2,2,12, 2,0,6,0,14, 0,0,0,0,17, 0,11,13,15,16},
		},
	},
}
