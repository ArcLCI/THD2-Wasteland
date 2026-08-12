--[[

首先, 由于有performattack, 要保证每次land后仍作一次暴击判定并在成功时添加修饰器
对于船勾, 在暴击概率变化时要重判一次
attackstart也要做暴击判定, 用来当做一般情况下攻击的标准判定
不过有个问题是有抬手的话可以s掉, 这样下次performattack可以100%暴击
不过仅在无敌斩之类技能时会这样触发(连击刀/虫子被动不会,因为第一次攻击会触发抬手清buff)
其它技能附加攻击特效的角色(文?)也可以这样卡
一个思路是start附加的暴击修饰器只给1帧(0.1秒之类?)的持续时间, land附加的暴击修饰器则不限时
这样, land附加的暴击修饰器无法被检测(因为start一抬手就清掉并变成start附加的有持续时间限制的修饰器了)
无法检测=有实际意义的随机

其它暴击装备的叠加: 如果有多个楼观, 那么每次判定暴击时移除之前存在的修饰器前先检测其是否为长时间有效, 不是的话直接跳过本次判定(其它抬手判定生效), 否则正常移除即可
另一个思路是同一个装备的data里额外记录一个LastConsiderCritTime, 如果本次判定时间没变说明目前如果存在暴击修饰器那一定是刚加上的(至少之前的已经被上次consider移除)

]]

local function GetCritData(keys)
	local data = keys.caster["Data_Item_"..keys.ability:GetName()]
	if not data then
		ItemAbility_Crit_Refresh(keys)
		data = keys.caster["Data_Item_"..keys.ability:GetName()]
	end
	return data
end

local function GetCritChance(keys)
	local data = GetCritData(keys)
	local CritChance = data.CritChanceConst + (data.TakeDamageTrigger and math.floor(data.DamageCount/data.TakeDamageTrigger)*data.BuffCritChance or 0)
	return math.min(data.BuffMaxStack or 100, CritChance)
end

local function ReconsiderCriticalStrike(keys, duration)
	if duration == nil then duration = -1 end
	local caster = keys.caster
	local data = GetCritData(keys)
	local NowTime = GameRules:GetGameTime()
	if NowTime-data.LastTriggerTime >= data.CritBuffDuration then
		data.DamageCount=0
	end
	if caster:HasModifier(data.CritModifierName) then
		if data.LastConsiderCritTime ~= NowTime then
			caster:RemoveModifierByName(data.CritModifierName)
		else
			--other same equipment crit happend
			return
		end
	end
	if GetCritChance(keys)>=RandomInt(1,100) then
		keys.ability:ApplyDataDrivenModifier(caster,caster,data.CritModifierName,{duration=duration})
	end
	data.LastConsiderCritTime = NowTime
end

--Calls when Created
function ItemAbility_Crit_Refresh(keys)
	keys.caster["Data_Item_"..keys.ability:GetName()] = {
		LastTriggerTime=0,
		DamageCount=0,
		
		BuffMaxStack=keys.BuffMaxStack,
		BuffCritChance=keys.BuffCritChance,
		CritBuffDuration=keys.CritBuffDuration or 0,
		CritChanceConst=keys.CritChanceConst,
		CritModifierName=keys.CritModifierName,
		IconModifierName=keys.IconModifierName or "",
		TakeDamageTrigger=keys.TakeDamageTrigger,
	}
	-- for immediate perform attack after bought crit
	ReconsiderCriticalStrike(keys)
end

--Calls when Destroy
function ItemAbility_Crit_Recycle(keys)
	local caster = keys.caster
	-- OnDestroy 不携带创建事件的暴击参数，缺少缓存时不能反向执行 Refresh。
	local data = caster["Data_Item_"..keys.ability:GetName()]
	if not data then return end
	data.LastTriggerTime = 0
	data.DamageCount = 0
	-- recycle for crit modifier
	if caster:HasModifier(data.CritModifierName) then
		caster:RemoveModifierByName(data.CritModifierName)
	end
	if caster:HasModifier(data.IconModifierName) then
		caster:RemoveModifierByName(data.IconModifierName)
	end
end

function ItemAbility_Crit_OnAttackStart(keys)
	ReconsiderCriticalStrike(keys,0.1)
end

function ItemAbility_Crit_OnAttackLanded(keys)
	ReconsiderCriticalStrike(keys)
end

function ItemAbility_Anchor_ReculcCritChance(keys)
	local ability = keys.ability
	local caster = keys.caster
	local data = GetCritData(keys)
	local DamageTaken = keys.DamageTaken or 0
	
	local NowTime = GameRules:GetGameTime()
	
	if NowTime-data.LastTriggerTime >= data.CritBuffDuration then
		data.LastTriggerTime = NowTime
		data.DamageCount = 0
	end
	
	local OChance = GetCritChance(keys)
	data.DamageCount = data.DamageCount + DamageTaken
	local NChance = GetCritChance(keys)
	
	if NChance > OChance or OChance == data.BuffMaxStack then
		data.LastTriggerTime = NowTime
		
		if caster:HasModifier(data.IconModifierName) then
			caster:RemoveModifierByName(data.IconModifierName)
		end
		ability:ApplyDataDrivenModifier(caster, caster, data.IconModifierName, {duration = data.CritBuffDuration})
		caster:SetModifierStackCount(data.IconModifierName, ability, NChance)
		
		ReconsiderCriticalStrike(keys)
	end
	
end

function ItemAbility_Sampan_Crit_Effect(keys)
	local caster = keys.caster
	local data = GetCritData(keys)
	local duration = caster:FindModifierByName(data.CritModifierName):GetDuration()
	if keys.Flag == 0 and duration > 0 or keys.Flag == 1 and duration < 0 then
		local particle_impact = "particles/units/heroes/hero_skeletonking/skeleton_king_weapon_blur_critical.vpcf"
		local effect_impact = ParticleManager:CreateParticle( particle_impact, PATTACH_ABSORIGIN_FOLLOW, keys.target )
		ParticleManager:ReleaseParticleIndex( effect_impact )
		caster:EmitSound("Hero_SkeletonKing.CriticalStrike")
	end
end
