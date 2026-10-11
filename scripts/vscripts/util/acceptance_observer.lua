-- 离线验收证据：只读自身/事件对象，不给Bot传递隐藏状态。
local O = { ENABLED = true }
local Build = require('util/acceptance_build')
local started=false
local serial=0
local function Token(value) return tostring(value):gsub('%s','_') end
local function Emit(tag,fields)
	if not O.ENABLED then return end
	serial=serial+1
	print(string.format('[THD][%s] schema=2 producer=thd_acceptance_v2 run_id=%s build_id=%s time=%.3f sequence=%d %s',
		tag,Build.RUN_ID,Build.BUILD_ID,GameRules:GetDOTATime(false,false),serial,fields))
end
local function Safe(fn)
	return function(...)
		if not O.ENABLED then return end
		local ok,err=pcall(fn,...)
		if not ok then O.ENABLED=false;print('[THD][AcceptanceError] producer=thd_acceptance_v2 error='..Token(err));return nil end
		return err -- 定时观察需传回下次间隔；事件监听忽略此返回值。
	end
end
local function Valid(entity) return entity and not entity:IsNull() end
local resources={item_famango=true,item_great_famango=true,item_greater_famango=true,item_magic_mushroom=true,item_roshans_banner=true}
function O.ResourceUse(caster,target,itemName,itemIndex,before,after,removed,manaBefore,manaAfter)
	Safe(function()
		local present=false
		for slot=0,8 do local item=caster:GetItemInSlot(slot)
			if Valid(item) and item:entindex()==itemIndex then present=true end
		end
		Emit('ResourceReceipt',string.format('event=effect_applied operation=consume pid=%d target_pid=%d item=%s item_entity=%d charges_before=%d charges_after=%s removal_requested=%s inventory_contains_entity=%s mana_before=%.1f mana_after=%.1f evidence=direct_callback_reread',
			caster:GetPlayerOwnerID(),target:GetPlayerOwnerID(),itemName,itemIndex,before,Token(after),tostring(removed),tostring(present),manaBefore,manaAfter))
	end)()
end
-- 7.38未公开莲花池专用领取事件：保存库存差量及现场线索，不推断奖励来源。
local lotusNames={'item_famango','item_great_famango','item_greater_famango'}
local inventoryStates={}
local observedHeroes,lotusPools={},{}
local nextHeroes,nextPools=-1000,-1000
local function LotusInventory(hero)
	local counts={0,0,0}
	for slot=0,8 do
		local item=hero:GetItemInSlot(slot)
		if Valid(item) then
			for i,name in ipairs(lotusNames) do
				if item:GetAbilityName()==name then counts[i]=counts[i]+math.max(0,item:GetCurrentCharges()) end
			end
		end
	end
	return counts
end
local function ObserveLotusInventory()
	local now=GameRules:GetDOTATime(false,false)
	if now>=nextHeroes then
		nextHeroes=now+2;observedHeroes={}
		for _,hero in ipairs(HeroList:GetAllHeroes()) do
			if Valid(hero) and hero:IsRealHero() and not hero:IsIllusion() then
				local pid=hero:GetPlayerOwnerID()
				if pid>=0 and PlayerResource:GetSelectedHeroEntity(pid)==hero then observedHeroes[#observedHeroes+1]=hero end
			end
		end
	end
	if now>=nextPools then nextPools=now+5;lotusPools=Entities:FindAllByClassname('npc_dota_lotus_pool') end
	for _,hero in ipairs(observedHeroes) do
		if Valid(hero) then
			local pid,index=hero:GetPlayerOwnerID(),hero:entindex()
			local counts=LotusInventory(hero)
			local pickup=hero:HasModifier('modifier_lotus_pool_pickup')
			local previous=inventoryStates[pid]
			if previous and previous.entity~=index then previous=nil end
			if not previous or counts[1]~=previous.counts[1] or counts[2]~=previous.counts[2] or counts[3]~=previous.counts[3] then
				local poolIndex,distance=-1,-1
				local point=hero:GetAbsOrigin()
				for _,pool in ipairs(lotusPools) do
					if Valid(pool) then
						local d=(pool:GetAbsOrigin()-point):Length2D()
						if distance<0 or d<distance then distance=d;poolIndex=pool:entindex() end
					end
				end
				local before=previous and table.concat(previous.counts,',') or 'unknown'
				Emit('ResourceReceipt',string.format('event=%s operation=observe pid=%d item=lotus_family hero_entity=%d counts_before=%s counts_after=%s sample_gap=%.3f pickup_modifier_before=%s pickup_modifier_after=%s nearest_pool_entity=%d nearest_pool_distance=%.1f evidence=inventory_snapshot_delta origin=unknown attribution=observed_delta_only',
					previous and 'lotus_inventory_delta' or 'lotus_inventory_baseline',pid,index,before,table.concat(counts,','),previous and now-previous.at or 0,
					tostring(previous and previous.pickup or false),tostring(pickup),poolIndex,distance))
			end
			inventoryStates[pid]={entity=index,counts=counts,pickup=pickup,at=now}
		end
	end
end
function O.Start()
	if started or not O.ENABLED then return end
	started=true
	Safe(function()
		Emit('RunStart','event=begin prepared_run=true')
		Emit('BuildLoaded','component=game scope=observer_and_manifest')
		ListenToGameEvent('game_rules_state_change',Safe(function()
			local state=GameRules:State_Get()
			local winner='unknown'
			if state==DOTA_GAMERULES_STATE_POST_GAME and GameRules.GetGameWinner then
				local ok,value=pcall(function() return GameRules:GetGameWinner() end)
				if ok and (value==DOTA_TEAM_GOODGUYS or value==DOTA_TEAM_BADGUYS) then winner=tostring(value) end
			end
			Emit('RunState','event=state state='..tostring(state)..' postgame='..tostring(state==DOTA_GAMERULES_STATE_POST_GAME)..' winner='..winner)
		end),nil)
		ListenToGameEvent('dota_rune_activated_server',Safe(function(event)
			local pid=tonumber(event.PlayerID)
			if not pid or pid<0 then return end
			local hero=PlayerResource:GetSelectedHeroEntity(pid)
			if not Valid(hero) then return end
			local point=hero:GetAbsOrigin()
			Emit('ResourceReceipt',string.format('event=rune_activated operation=pickup pid=%d rune_type=%s x=%.1f y=%.1f gold_after=%d evidence=engine_event reward_delta=unknown resource_instance=unknown',
				pid,Token(event.rune),point.x,point.y,PlayerResource:GetGold(pid)))
		end),nil)
		ListenToGameEvent('dota_item_picked_up',Safe(function(event)
			if not resources[event.itemname] then return end
			local index=tonumber(event.HeroEntityIndex or event.UnitEntityIndex)
			local hero=index and EntIndexToHScript(index) or nil
			if not Valid(hero) then
				Emit('ResourceReceipt','event=item_pickup_unresolved item='..Token(event.itemname)..' evidence=missing_actor');return
			end
			local count=0
			for slot=0,8 do local item=hero:GetItemInSlot(slot)
				if Valid(item) and item:GetAbilityName()==event.itemname then count=count+math.max(1,item:GetCurrentCharges()) end
			end
			Emit('ResourceReceipt',string.format('event=item_picked_up operation=pickup pid=%d item=%s item_entity=%s inventory_after=%d evidence=engine_event_and_inventory origin=unknown',
				hero:GetPlayerOwnerID(),Token(event.itemname),Token(event.ItemEntityIndex),count))
		end),nil)
		-- 事件字段来自本机7.38 game.gameevents；库存添加不等于莲花池领取。
		ListenToGameEvent('dota_inventory_item_added',Safe(function(event)
			if not resources[event.itemname] then return end
			Emit('ResourceReceipt','event=inventory_item_added operation=observe pid='..Token(event.inventory_player_id)
				..' item='..Token(event.itemname)..' item_entity='..Token(event.item_entindex)
				..' parent_entity='..Token(event.inventory_parent_entindex)..' slot='..Token(event.item_slot)
				..' is_courier='..Token(event.is_courier)..' evidence=engine_inventory_event origin=unknown')
		end),nil)
		Timers:CreateTimer(1,Safe(function()
			if GameRules:State_Get()>=DOTA_GAMERULES_STATE_POST_GAME then return nil end
			ObserveLotusInventory()
			return 0.5
		end))
		Emit('ObserverReady','event=ready lotus_inventory_interval=0.5 origin_attribution=unknown')
		ListenToGameEvent('dota_player_used_ability',Safe(function(event)
			if not resources[event.abilityname] then return end
			-- 原生恢复品只报告引擎事件；没有直接回调重读时不宣称最终效果。
			Emit('ResourceReceipt','event=ability_used operation=consume pid='..Token(event.PlayerID)..' item='..Token(event.abilityname)..' evidence=engine_event effect=unknown')
		end),nil)
	end)()
end
return O
