
local function ReconsiderBlock(keys)
	local caster = keys.caster
	local data = caster["Data_Item_"..keys.ability:GetName()]
	local NowTime = GameRules:GetGameTime()
	if caster:HasModifier(data.BlockModifierName) then
		if data.LastConsiderBlockTime ~= NowTime then
			caster:RemoveModifierByName(data.BlockModifierName)
		else
			--other same equipment Block happend
			return
		end
	end
	if RollPseudoRandom(data.BlockChance, keys.ability) then
		keys.ability:ApplyDataDrivenModifier(caster,caster,data.BlockModifierName,{duration=-1})
	end
	data.LastConsiderBlockTime = NowTime
end

--Calls when Created
function ItemAbility_Block_Refresh(keys)
	keys.caster["Data_Item_"..keys.ability:GetName()] = {
		BlockChance=keys.BlockChance,
		BlockModifierName=keys.BlockModifierName,
	}
	ReconsiderBlock(keys)
end

--Calls when Destroy
function ItemAbility_Block_Recycle(keys)
	local caster = keys.caster
	local data = caster["Data_Item_"..keys.ability:GetName()]
	-- OnDestroy 不携带创建事件参数，缓存缺失时不能反向执行 Refresh。
	if not data then return end
	if caster:HasModifier(data.BlockModifierName) then
		caster:RemoveModifierByName(data.BlockModifierName)
	end
end

function ItemAbility_Block_OnAttacked(keys)
	ReconsiderBlock(keys)
end



function ItemBlockXOnSpellStart(keys)
	local caster = keys.caster
	local shivas_guard_particle = ParticleManager:CreateParticle("particles/items2_fx/shivas_guard_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(shivas_guard_particle, 1, Vector(keys.BlastFinalRadius, keys.BlastFinalRadius / keys.BlastSpeedPerSecond, keys.BlastSpeedPerSecond))
	ParticleManager:DestroyParticleSystemTime(shivas_guard_particle,keys.BlastVisionDuration)
	keys.ability:ApplyDataDrivenModifier(caster, caster, keys.ModifierShieldName, {})	
	caster:EmitSound("DOTA_Item.ShivasGuard.Activate")
	caster.xuenvdeweijin_blast_radius=0.0
	local blockThinkInterval = 0.05
	caster:SetThink(function ()
		if (caster.xuenvdeweijin_blast_radius>=keys.BlastFinalRadius) then 
			return nil 
		end
		--
		keys.ability:CreateVisibilityNode(caster:GetAbsOrigin(), keys.BlastVisionRadius, keys.BlastVisionDuration)
		caster.xuenvdeweijin_blast_radius = caster.xuenvdeweijin_blast_radius + (keys.BlastSpeedPerSecond * blockThinkInterval)
		local nearby_enemy_units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, caster.xuenvdeweijin_blast_radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

			for _, individual_unit in ipairs(nearby_enemy_units) do
				if not individual_unit:HasModifier(keys.ModifierBlastDebuffName) then
					--This impact particle effect should radiate away from the caster of Shiva's Guard.
					local shivas_guard_impact_particle = ParticleManager:CreateParticle("particles/items2_fx/shivas_guard_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, individual_unit)
					local target_point = individual_unit:GetAbsOrigin()
					local caster_point = individual_unit:GetAbsOrigin()
					ParticleManager:SetParticleControl(shivas_guard_impact_particle, 1, target_point + (target_point - caster_point) * 30)
					ParticleManager:DestroyParticleSystemTime(shivas_guard_impact_particle,keys.BlastVisionDuration)
                    keys.ability:ApplyDataDrivenModifier(caster, individual_unit, keys.ModifierBlastDebuffName, {duration = keys.BlastDebuffDuration * (1 - individual_unit:GetStatusResistance())})
					local damage_table = {
						ability = keys.ability,
						victim = individual_unit,
						attacker = caster,
						damage = keys.BlastDamage,
						damage_type = DAMAGE_TYPE_MAGICAL,
					}
					UnitDamageTarget(damage_table)					
				end
			end
		return 0.03
	end)
end

