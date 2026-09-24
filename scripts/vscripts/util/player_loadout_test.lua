-- 临时手动测试入口：仅给真人主英雄一次性补齐等级和金币，不修改Bot。
local M = {}
local enabled = false
local granted = {}
local registered = false

local function IsHumanHero(hero)
	if hero == nil or hero:IsNull() or not hero:IsRealHero() or hero:IsIllusion() then return false end
	local playerID = hero:GetPlayerOwnerID()
	if playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) or PlayerResource:IsFakeClient(playerID) then return false end
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil or player:GetContext('PlayerIsBot') == 1 then return false end
	return PlayerResource:GetSelectedHeroEntity(playerID) == hero
end

local function Apply(hero)
	if not enabled or not IsHumanHero(hero) then return end
	local playerID = hero:GetPlayerOwnerID()
	if granted[playerID] == hero then return end
	-- 已经高于12级或50000金时不倒扣；保留升级所得技能点供玩家自行加点。
	for level = hero:GetLevel() + 1, 12 do hero:HeroLevelUp(false) end
	local gold = math.max(0, 50000 - hero:GetGold())
	if gold > 0 then hero:ModifyGold(gold, true, DOTA_ModifyGold_Unspecified) end
	granted[playerID] = hero
	print(string.format('[THD][PlayerLoadoutTest] player=%d level=%d gold=%d', playerID, hero:GetLevel(), hero:GetGold()))
end

function M.Register()
	if registered then return end
	registered = true
	Convars:RegisterCommand('thd_player_test', function(_, value)
		if value ~= '0' and value ~= '1' then
			print('[THD][PlayerLoadoutTest] usage: thd_player_test <0|1>')
			return
		end
		enabled = value == '1'
		print('[THD][PlayerLoadoutTest] enabled=' .. tostring(enabled))
		if not enabled then return end
		-- 支持选人后开启；选人前开启则由出生事件补发。
		for playerID = 0, 63 do
			if PlayerResource:IsValidPlayerID(playerID) then Apply(PlayerResource:GetSelectedHeroEntity(playerID)) end
		end
	end, 'Temporary human player loadout: level 12 and 50000 gold; thd_player_test <0|1>', 0)
	ListenToGameEvent('npc_spawned', function(event)
		if not enabled or event.entindex == nil then return end
		local hero = EntIndexToHScript(event.entindex)
		if hero == nil or hero:IsNull() or not hero:IsRealHero() or hero:IsIllusion() then return end
		local playerID = hero:GetPlayerOwnerID()
		if playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) or PlayerResource:IsFakeClient(playerID)
		or granted[playerID] == hero then return end
		-- 等待普通出生初始化完成；每个英雄只安排一次短回调，无常驻轮询。
		hero:SetContextThink('THD_PlayerLoadoutTest', function()
			Apply(hero)
			return nil
		end, 0.5)
	end, nil)
end

return M
