item_yuemianjidongzhuangzhi = class({})

function item_yuemianjidongzhuangzhi:Precache(ctx)
	PrecacheResource( "soundfile", "soundevents/game_sounds_items.vsndevts", ctx )
	PrecacheResource( "particle", "particles/items_fx/force_staff.vpcf", ctx )
end

function item_yuemianjidongzhuangzhi:GetIntrinsicModifierName()
	return "modifier_item_yuemianjidongzhuangzhi_basic"
end

function item_yuemianjidongzhuangzhi:OnSpellStart()
	if IsClient() then return end
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	if target:TriggerSpellAbsorb(self) then return end

	target:EmitSound("DOTA_Item.HurricanePike.Activate")
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		target:AddNewModifier(caster,self,"modifier_item_yuemianjidongzhuangzhi_target",{duration=-1,dis = self:GetSpecialValueFor('distance')}).v = (target:GetAbsOrigin() -caster:GetAbsOrigin()):Normalized()
		caster:AddNewModifier(caster,self,"modifier_item_yuemianjidongzhuangzhi_target",{duration=-1,dis = self:GetSpecialValueFor('distance')}).v = (caster:GetAbsOrigin() -target:GetAbsOrigin()):Normalized()
		caster:AddNewModifier(caster,self,"modifier_item_yuemianjidongzhuangzhi_caster",{duration=self:GetSpecialValueFor("buff_duration")}).t = target
	end
	if target:GetTeamNumber() == caster:GetTeamNumber() then
		target:AddNewModifier(caster,self,"modifier_item_yuemianjidongzhuangzhi_target",{duration=-1,dis = self:GetSpecialValueFor('ttui_distance')}).v = (target:GetForwardVector()):Normalized()
	end

	if caster:IsRangedAttacker() and target:GetTeam() ~= caster:GetTeam() then		--攻击指令
		local startAttack = {
			UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),}
		ExecuteOrderFromTable(startAttack)
	end
end

modifier_item_yuemianjidongzhuangzhi_caster = class({})
LinkLuaModifier("modifier_item_yuemianjidongzhuangzhi_caster","items/item_yuemianjidongzhuangzhi.lua",0)

function modifier_item_yuemianjidongzhuangzhi_caster:IsHidden() return false end
function modifier_item_yuemianjidongzhuangzhi_caster:IsPurgable() return false end
function modifier_item_yuemianjidongzhuangzhi_caster:IsDebuff() return false end
function modifier_item_yuemianjidongzhuangzhi_caster:RemoveOnDeath() return true end
	
function modifier_item_yuemianjidongzhuangzhi_caster:OnCreated(e)
	self:SetHasCustomTransmitterData(true)
	if IsClient() then return end
	self:SetStackCount(self:GetAbility():GetSpecialValueFor("buff_attack_limit"))
end

function modifier_item_yuemianjidongzhuangzhi_caster:OnStackCountChanged(e)
	if e == 1 then self:Destroy() end
end

function modifier_item_yuemianjidongzhuangzhi_caster:AddCustomTransmitterData()
	return {
		as = self.as,
		ar = self.ar
	}
end	

function modifier_item_yuemianjidongzhuangzhi_caster:HandleCustomTransmitterData(e)
	self.as = e.as
	self.ar = e.ar
end

function modifier_item_yuemianjidongzhuangzhi_caster:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK_CANCELLED,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ORDER
	}
end

function modifier_item_yuemianjidongzhuangzhi_caster:OnOrder(e)
	if IsClient() then return end
	if e.unit ~= self:GetParent() then return end
	self.ar = 0
	self.as = 0
	if e.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
		if e.target == self.t then
			self.ar = 100000
			self.as = self:GetAbility():GetSpecialValueFor("buff_attack_speed")
		end
	end
end

function modifier_item_yuemianjidongzhuangzhi_caster:OnAttackCancelled(e)
	if IsClient() then return end
	if e.attacker ~= self:GetParent() then return end
	self.ar = 0
	self.as = 0
end

function modifier_item_yuemianjidongzhuangzhi_caster:OnAttack(e)
	if IsClient() then return end
	if e.attacker ~= self:GetParent() then return end
	if self:GetParent():GetAttackTarget() ~= self.t then
		self.as = 0
		self.ar = 0
	end
	if e.target ~= self.t then return end
	self:DecrementStackCount()
end

function modifier_item_yuemianjidongzhuangzhi_caster:GetModifierAttackSpeedBonus_Constant ()
	return self.as
end

function modifier_item_yuemianjidongzhuangzhi_caster:GetModifierAttackRangeBonus()
	if not IsServer() then return end
	return self:GetParent():IsRangedAttacker() and self.ar or 0
end

modifier_item_yuemianjidongzhuangzhi_target = class({})
LinkLuaModifier("modifier_item_yuemianjidongzhuangzhi_target","items/item_yuemianjidongzhuangzhi.lua",LUA_MODIFIER_MOTION_HORIZONTAL )

function modifier_item_yuemianjidongzhuangzhi_target:GetEffectName()
	return "particles/items_fx/force_staff.vpcf"
end

function modifier_item_yuemianjidongzhuangzhi_target:GetEffectAttachType()
	return PATTACH_CENTER_FOLLOW
end

function modifier_item_yuemianjidongzhuangzhi_target:IsDebuff()
	return self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
end

function modifier_item_yuemianjidongzhuangzhi_target:IsHidden()
	return false
end

function modifier_item_yuemianjidongzhuangzhi_target:IsPurgable()
	return false
end

function modifier_item_yuemianjidongzhuangzhi_target:IsPurgeException()
	return false
end

function modifier_item_yuemianjidongzhuangzhi_target:RemoveOnDeath()
	return true
end

function modifier_item_yuemianjidongzhuangzhi_target:OnCreated(e)
	self:SetHasCustomTransmitterData(true)
	self.dis = e.dis
	if IsClient() then return end
	self.movement = 0
	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end
end
function modifier_item_yuemianjidongzhuangzhi_target:OnHorizontalMotionInterrupted()
    self:Destroy()
  end	

function modifier_item_yuemianjidongzhuangzhi_target:GetMotionControllerPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_item_yuemianjidongzhuangzhi_target:OnRemoved()
	if IsClient() then return end
	FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(),true)
	self:GetParent():RemoveHorizontalMotionController(self)
end

function modifier_item_yuemianjidongzhuangzhi_target:UpdateHorizontalMotion(u,dt)
	if IsClient() then return end
	if self.v == nil then return end
	local speed = self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() and self:GetAbility():GetSpecialValueFor("friend_speed") or self:GetAbility():GetSpecialValueFor("enemy_speed")
	local distance = dt*speed
	if (self.movement + distance) > self.dis then
		distance = self.dis - self.movement
		u:SetAbsOrigin(u:GetAbsOrigin()+ self.v * distance)
		self:Destroy()
	else
		self.movement = self.movement + distance
		u:SetAbsOrigin(u:GetAbsOrigin()+ self.v * distance)
	end	
end

modifier_item_yuemianjidongzhuangzhi_basic = class({})
LinkLuaModifier("modifier_item_yuemianjidongzhuangzhi_basic","items/item_yuemianjidongzhuangzhi.lua",0)

function modifier_item_yuemianjidongzhuangzhi_basic:IsHidden() return true end
function modifier_item_yuemianjidongzhuangzhi_basic:IsPurgable() return false end
function modifier_item_yuemianjidongzhuangzhi_basic:IsDebuff() return false end
function modifier_item_yuemianjidongzhuangzhi_basic:IsPurgeException() return false end
function modifier_item_yuemianjidongzhuangzhi_basic:RemoveOnDeath() return false end
function modifier_item_yuemianjidongzhuangzhi_basic:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_yuemianjidongzhuangzhi_basic:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}
end

function modifier_item_yuemianjidongzhuangzhi_basic:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("intellect_bonus")
end

function modifier_item_yuemianjidongzhuangzhi_basic:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("health_regen_constant")
end

function modifier_item_yuemianjidongzhuangzhi_basic:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agility_bonus")
end

function modifier_item_yuemianjidongzhuangzhi_basic:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("health_bonus")
end

function modifier_item_yuemianjidongzhuangzhi_basic:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	local ability = self:GetAbility()

	-- 每件物品保留自己的射程句柄，多件之间仅数值取最大，不共享来源生命周期。
	self.rangeModifier = parent:AddNewModifier(parent, ability, "modifier_item_yuemianjidongzhuangzhi_range", {duration = -1})
end

function modifier_item_yuemianjidongzhuangzhi_basic:OnDestroy()
	if not IsServer() then return end
	if self.rangeModifier ~= nil and not self.rangeModifier:IsNull() then self.rangeModifier:Destroy() end
	self.rangeModifier = nil
end

modifier_item_yuemianjidongzhuangzhi_range = class({})
LinkLuaModifier("modifier_item_yuemianjidongzhuangzhi_range","items/item_yuemianjidongzhuangzhi.lua",0)

function modifier_item_yuemianjidongzhuangzhi_range:IsHidden() return true end
function modifier_item_yuemianjidongzhuangzhi_range:IsPurgable() return false end
function modifier_item_yuemianjidongzhuangzhi_range:IsDebuff() return false end
function modifier_item_yuemianjidongzhuangzhi_range:RemoveOnDeath() return false end
function modifier_item_yuemianjidongzhuangzhi_range:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_yuemianjidongzhuangzhi_range:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS_UNIQUE,
	}
end

function modifier_item_yuemianjidongzhuangzhi_range:GetModifierAttackRangeBonusUnique()
	local ability = self:GetAbility()
	if ability == nil or ability:IsNull() or not self:GetParent():IsRangedAttacker() then return 0 end
	-- 仅被动射程参与装备最大值；主动对指定目标的临时射程仍走独立回调。
	return ability:GetSpecialValueFor("attack_range_bonus")
end
