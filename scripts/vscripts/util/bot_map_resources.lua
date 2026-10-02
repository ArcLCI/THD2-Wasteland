-- 只读地图资源观察桥。原生thinker负责刷新/奖励；本模块不发奖、不控制英雄动作。
local B={}
local RUN='MAP-RESOURCES-20261002-R2'
local INTERVAL=0.5
local nodes,heroes={},{}
local nextDiscovery,nextHeroes=-90,-90
local started=false
local markers=setmetatable({}, {__mode='k'})
local definitions={
	{kind='wisdom',class='npc_dota_xp_fountain',ability='ability_xp_fountain',modifier='modifier_xp_fountain_aura',timeKey='countdown_time',first=1},
	{kind='lotus',class='npc_dota_lotus_pool',ability='ability_lotus_pool',modifier='modifier_passive_lotus_pool',timeKey='first_lotus_pickup_time',first=3},
}

-- 协议1：四个固定槽，每槽location/meta/state三个无属性标记；禁止复制到幻象。
for slot=1,4 do
	for _,field in ipairs({'location','meta','state'}) do
		local name='modifier_thd2_map_resource_'..field..'_'..slot
		LinkLuaModifier(name,'util/bot_map_resources',LUA_MODIFIER_MOTION_NONE)
		local marker=class({});_G[name]=marker
		-- 7.38的Bot枚举会跳过服务端IsHidden=true；客户端仍隐藏纯数据标记。
		function marker:IsHidden() return not IsServer() end
		function marker:IsPurgable() return false end
		function marker:IsDebuff() return false end
		function marker:RemoveOnDeath() return false end
		function marker:AllowIllusionDuplicate() return false end
	end
end

local function Valid(h) return h~=nil and not h:IsNull() end
-- 只在自身真正激活普通符时发布收据；与地图资源观察分开，不共享敌方信息。
for _,field in ipairs({'sequence','time','location','type'}) do
	local name='modifier_thd2_rune_receipt_'..field
	LinkLuaModifier(name,'util/bot_map_resources',LUA_MODIFIER_MOTION_NONE)
	local marker=class({});_G[name]=marker
	function marker:IsHidden() return not IsServer() end
	function marker:IsPurgable() return false end
	function marker:RemoveOnDeath() return false end
	function marker:AllowIllusionDuplicate() return false end
end
local function Clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function Now() return GameRules:GetDOTATime(false,false) end
local function IsBotHero(hero)
	if not Valid(hero) or not hero:IsRealHero() or hero:IsIllusion() then return false end
	local id=hero:GetPlayerOwnerID()
	if id<0 or PlayerResource:GetSelectedHeroEntity(id)~=hero then return false end
	if PlayerResource.IsFakeClient and PlayerResource:IsFakeClient(id) then return true end
	return _G.THD2_IsBotHero and _G.THD2_IsBotHero(hero)==true
end
local function Discover(now)
	if now>=nextHeroes then
		nextHeroes=now+2;heroes={}
		for _,hero in ipairs(HeroList:GetAllHeroes()) do if IsBotHero(hero) then heroes[#heroes+1]=hero end end
	end
	if now<nextDiscovery then return end
	nextDiscovery=now+5
	for _,definition in ipairs(definitions) do
		local list=Entities:FindAllByClassname(definition.class) or {}
		table.sort(list,function(a,b)
			local x,y=a:GetAbsOrigin(),b:GetAbsOrigin()
			return x.x<y.x or (x.x==y.x and x.y<y.y)
		end)
		for index=1,2 do
			local slot=definition.first+index-1
			local unit=list[index]
			if not Valid(unit) or not unit:IsAlive() then nodes[slot]=nil
			elseif not nodes[slot] or nodes[slot].unit~=unit then
				nodes[slot]={unit=unit,definition=definition,observed={},nextThinker=-90}
				print(string.format('[GAME][MapResource] run=%s event=discovered slot=%d kind=%s entity=%d',RUN,slot,definition.kind,unit:entindex()))
			end
		end
	end
end
local function ReadNative(node,now)
	if not Valid(node.unit) or not node.unit:IsAlive() then return nil end
	local ability=node.unit:FindAbilityByName(node.definition.ability)
	if not Valid(ability) then return nil end
	if not Valid(node.modifier) or node.modifier:GetAbility()~=ability then
		node.modifier=nil
		if now<node.nextThinker then return nil end
		node.nextThinker=now+5
		-- 只在该建筑附近查找，且核对原生技能归属；不按最近同名modifier猜来源。
		local nearby=Entities:FindAllInSphere(node.unit:GetAbsOrigin(),128) or {}
		nearby[#nearby+1]=node.unit
		for _,unit in ipairs(nearby) do
			if Valid(unit) and unit.FindModifierByName then
				local modifier=unit:FindModifierByName(node.definition.modifier)
				if Valid(modifier) and modifier:GetAbility()==ability then node.modifier=modifier;break end
			end
		end
		if not node.modifier then return nil end
	end
	local radius=ability:GetSpecialValueFor('radius')
	local duration=ability:GetSpecialValueFor(node.definition.timeKey)
	if radius<=0 or radius>1023 or duration<=0 or duration>25.5 then return nil end
	local count=node.modifier:GetStackCount()
	if type(count)~='number' or count<0 then return nil end
	return count,radius,duration
end
local function PackLocation(point)
	if math.abs(point.x)>=16384 or math.abs(point.y)>=16384 then return nil end
	local x=math.floor(point.x+16384+0.5)
	local y=math.floor(point.y+16384+0.5)
	if x>32767 or y>32767 then return nil end
	return 1+x+y*32768
end
local function WriteMarker(hero,slot,field,value)
	local cache=markers[hero]
	if not cache then cache={};markers[hero]=cache end
	local name='modifier_thd2_map_resource_'..field..'_'..slot
	local modifier=cache[name]
	if not Valid(modifier) then
		modifier=hero:FindModifierByName(name) or hero:AddNewModifier(hero,nil,name,{})
		cache[name]=modifier
	end
	if Valid(modifier) and modifier:GetStackCount()~=value then modifier:SetStackCount(value) end
	if Valid(modifier) then return modifier:GetStackCount(),modifier:IsHidden() end
	return nil,nil
end
local function Sample()
	local now=Now()
	Discover(now)
	local observers={}
	for _,hero in ipairs(heroes) do if Valid(hero) then observers[hero:GetTeamNumber()]=hero end end
	for slot=1,4 do
		local node=nodes[slot]
		local location,meta=0,0
		if node and Valid(node.unit) and node.unit:IsAlive() then
			local point=node.unit:GetAbsOrigin()
			location=PackLocation(point) or 0
			local count,radius,duration=ReadNative(node,now)
			if count~=nil and location>0 then
				node.radius,node.duration=radius,duration
			end
			if location>0 and node.radius then
				meta=16777216+Clamp(math.floor((point.z+1024)/32+0.5),0,63)*262144
					+math.floor(node.duration*10+0.5)*1024+math.floor(node.radius+0.5)
			end
			for team,observer in pairs(observers) do
				-- 视野丢失不刷新时间戳，也不将隐藏的实际数量写到Bot标记。
				if count~=nil and observer:CanEntityBeSeenByMyTeam(node.unit) then
					local tick=math.floor((now+120)*2)
					if tick>=0 and tick<30000000 then
						local old=node.observed[team]
						local value=Clamp(math.floor(count),0,31)
						node.observed[team]={packet=(tick+1)*64+value+1,count=value}
						if not old or old.count~=value then
							print(string.format('[GAME][MapResource] run=%s time=%.2f team=%d slot=%d event=observed count=%d radius=%.0f duration=%.1f',RUN,now,team,slot,value,node.radius or 0,node.duration or 0))
						end
					end
				end
			end
			if count==nil and now-(node.missingLogAt or -90)>=15 then
				node.missingLogAt=now
				print(string.format('[GAME][MapResource] run=%s time=%.2f slot=%d event=source_unavailable',RUN,now,slot))
			end
		end
		for _,hero in ipairs(heroes) do
			if Valid(hero) then
				local observation=node and node.observed[hero:GetTeamNumber()]
				local packet=observation and observation.packet or 0
				local actualLocation,hidden=WriteMarker(hero,slot,'location',location)
				local actualMeta=WriteMarker(hero,slot,'meta',meta)
				local actualState=WriteMarker(hero,slot,'state',packet)
				local cache=markers[hero]
				cache.diagnostics=cache.diagnostics or {}
				local diagnostic=cache.diagnostics[slot]
				local matched=actualLocation==location and actualMeta==meta and actualState==packet
				if not diagnostic or now-diagnostic.at>=60 or diagnostic.matched~=matched then
					cache.diagnostics[slot]={at=now,matched=matched}
					print(string.format('[GAME][MapResource] run=%s time=%.2f pid=%d slot=%d event=marker_write matched=%s hidden=%s expected_location=%d actual_location=%s expected_meta=%d actual_meta=%s expected_state=%d actual_state=%s',
						RUN,now,hero:GetPlayerOwnerID(),slot,tostring(matched),tostring(hidden),location,tostring(actualLocation),meta,tostring(actualMeta),packet,tostring(actualState)))
				end
			end
		end
	end
end
function B.Start()
	if started then return end
	started=true
	-- 事件的rune是类型，不是符点编号；只给实际领取者写入自身收据。
	ListenToGameEvent('dota_rune_activated_server',function(event)
		local id=tonumber(event.PlayerID)
		if not id or id<0 then return end
		local hero=PlayerResource:GetSelectedHeroEntity(id)
		if not IsBotHero(hero) then return end
		local point=hero:GetAbsOrigin()
		hero.THD_RuneReceiptSequence=(hero.THD_RuneReceiptSequence or 0)%65535+1
		local values={time=math.floor((Now()+120)*10)+1,location=PackLocation(point),type=(tonumber(event.rune) or -1)+2,sequence=hero.THD_RuneReceiptSequence}
		-- 序号最后写入，读取者用前后序号复核完整性。
		for _,field in ipairs({'time','location','type','sequence'}) do
			local name='modifier_thd2_rune_receipt_'..field
			local modifier=hero:FindModifierByName(name)
			if not Valid(modifier) then modifier=hero:AddNewModifier(hero,nil,name,{}) end
			if not Valid(modifier) then break end
			modifier:SetStackCount(values[field])
			if modifier:GetStackCount()~=values[field] then break end
		end
		print(string.format('[GAME][RunePickup] run=RUNE-PICKUP-20261002-R26 time=%.3f pid=%d event=activated rune_type=%s x=%.1f y=%.1f',
			Now(),id,tostring(event.rune),point.x,point.y))
	end,nil)
	print('[GAME][RunePickup] run=RUNE-PICKUP-20261002-R26 event=observer_ready')
	print('[GAME][MapResource] run='..RUN..' event=ready protocol=1')
	local errors=0
	Timers:CreateTimer(1,function()
		if GameRules:State_Get()>=DOTA_GAMERULES_STATE_POST_GAME then return nil end
		local ok,message=xpcall(Sample,debug.traceback)
		if not ok then
			errors=errors+1;print('[GAME][MapResource] event=error '..tostring(message))
			if errors>=3 then return nil end
			return 5
		end
		errors=0;return INTERVAL
	end)
end
return B
