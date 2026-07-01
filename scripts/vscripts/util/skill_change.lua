--更换英雄技能天赋

function THD_Change_skill(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "游戏开始后无法更换技能", true)
		return 
	end
	if hero.HasSkillChange ~= true then
		Say(plyhd, "该少女没有技能卡", true)
		return
	elseif hero.HasSkillChange == false then
		Say(plyhd, "该少女已经更换技能，无法再更换", true)
		return
	end
	--删除技能天赋
	-- 按实际技能槽数量扫描，避免越界触发控制台警告。
	for i=0,hero:GetAbilityCount() - 1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability and ability ~= "" then
			print(ability:GetName())
			hero:RemoveAbilityByHandle(ability)
		end
	end
	if hero:GetName() == "npc_dota_hero_juggernaut" then
		THD_Change_skill_youmu2(hero,plyhd)
	elseif hero:GetName() == "" then

	end
end

function THD_Change_skill_youmu2(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "*游戏开始后无法更换技能", true)
		return
	end

	local gold = hero:GetGold()
	local exp = hero:GetCurrentXP()
	PrecacheUnitByNameAsync("npc_dota_hero_enchantress", function ()
		local hero = PlayerResource:ReplaceHeroWith(plyhd:GetPlayerID(), "npc_dota_hero_enchantress", gold, exp)

		local ability = hero:FindAbilityByName("ability_thdots_youmu2_Ex")
		ability:SetLevel(1)
		ability = hero:FindAbilityByName("ability_thdots_youmu2_05")
		ability:SetLevel(1)

		GameRules:SendCustomMessage("#Youmu2SkillChange", 0, 0)
	end, plyhd:GetPlayerID())
end
