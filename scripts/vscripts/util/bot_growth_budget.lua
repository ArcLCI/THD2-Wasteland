-- 仅记录Bot补强的时间/购买增量，不把英雄原生、升级、装备或固定难度属性纳入额度。
local G={CAP=300,RESERVE_GOLD=9000}
local methods={'ModifyStrength','ModifyAgility','ModifyIntellect'}
local function State(hero)
    hero.THD_BotGrowthBudget=hero.THD_BotGrowthBudget or {time={0,0,0},bought={0,0,0}}
    return hero.THD_BotGrowthBudget
end
local function Room(s,i) return math.max(0,G.CAP-s.time[i]-s.bought[i]) end
function G.AddTime(hero,values)
    local s=State(hero)
    for i=1,3 do
        local add=math.min(Room(s,i),math.max(0,tonumber(values[i]) or 0))
        if add>0 then hero[methods[i]](hero,add);s.time[i]=s.time[i]+add end
    end
end
local function Log(hero,s,event,amount)
    print(string.format('[GAME][BotGrowth] run=BOT-GROWTH-20261006-R38 time=%.3f pid=%d event=%s amount=%.2f strength=%.2f agility=%.2f intellect=%.2f',
        GameRules:GetDOTATime(false,false),hero:GetPlayerOwnerID(),event,amount,
        s.time[1]+s.bought[1],s.time[2]+s.bought[2],s.time[3]+s.bought[3]))
end
function G.SpendExcess(hero,playerID)
    local s=State(hero)
    local reliable,unreliable=PlayerResource:GetReliableGold(playerID),PlayerResource:GetUnreliableGold(playerID)
    local full=Room(s,1)+Room(s,2)+Room(s,3)<0.000001
    if full then
        -- 等额转换：先扣后存，再按实际入账退款，避免引擎金币上限导致丢钱或凭空增金。
        if unreliable>0 then
            PlayerResource:SetGold(playerID,0,false)
            PlayerResource:SetGold(playerID,reliable+unreliable,true)
            local credited=math.max(0,math.min(unreliable,PlayerResource:GetReliableGold(playerID)-reliable))
            PlayerResource:SetGold(playerID,unreliable-credited,false)
            s.converted=(s.converted or 0)+credited
            local now=GameRules:GetDOTATime(false,false)
            if now-(s.goldLogAt or -90)>=60 then
                s.goldLogAt=now
                print(string.format('[GAME][BotGrowthGold] run=BOT-GROWTH-20261006-R38 time=%.3f pid=%d credited=%d reliable_before=%d reliable_after=%d unreliable_before=%d unreliable_after=%d total_before=%d total_after=%d',
                    now,playerID,credited,reliable,PlayerResource:GetReliableGold(playerID),unreliable,PlayerResource:GetUnreliableGold(playerID),
                    reliable+unreliable,PlayerResource:GetReliableGold(playerID)+PlayerResource:GetUnreliableGold(playerID)))
            end
        end
    else
        local packets=math.floor(math.max(0,reliable+unreliable-G.RESERVE_GOLD)/800)
        local primary=hero:GetPrimaryAttribute()+1
        local packetPoints=(primary>=1 and primary<=3) and 5 or 3
        local cost=0
        local purchased={0,0,0}
        local function Available(i) return math.max(0,Room(s,i)-purchased[i]) end
        -- 每包原为主属性3、副属性各1；某项满额后将剩余点数转给未满项，最多900点总额度。
        for _=1,math.min(packets,180) do
            local adds={0,0,0}
            local left=packetPoints
            for i=1,3 do
                adds[i]=math.min(Available(i),i==primary and 3 or 1);left=left-adds[i]
            end
            for _=1,3 do
                local best,room=nil,0
                for i=1,3 do if Available(i)-adds[i]>room then best,room=i,Available(i)-adds[i] end end
                if not best or left<=0 then break end
                local extra=math.min(room,left);adds[best]=adds[best]+extra;left=left-extra
            end
            local granted=adds[1]+adds[2]+adds[3]
            if granted<0.000001 then break end
            local price=math.ceil(granted*800/packetPoints-0.000001)
            if cost+price>reliable+unreliable-G.RESERVE_GOLD then break end
            for i=1,3 do purchased[i]=purchased[i]+adds[i] end
            cost=cost+price
        end
        if cost>0 then
            local debit=math.min(unreliable,cost)
            PlayerResource:SetGold(playerID,unreliable-debit,false)
            if cost>debit then PlayerResource:SetGold(playerID,reliable-(cost-debit),true) end
            -- 批量结算，每轮最多三次原生属性写入，避免余额大时反复刷新英雄属性。
            for i=1,3 do if purchased[i]>0 then hero[methods[i]](hero,purchased[i]);s.bought[i]=s.bought[i]+purchased[i] end end
            Log(hero,s,'attributes_purchased',cost)
        end
    end
    local now=GameRules:GetDOTATime(false,false)
    if now-(s.loggedAt or -90)>=60 or full~=s.loggedFull then
        s.loggedAt,s.loggedFull=now,full
        Log(hero,s,full and 'all_attributes_capped' or 'budget',s.converted or 0)
    end
end
return G
