
    local ControlTrace = require('util/control_trace')
    if UtilStun == nil then
	    UtilStun = class({})
    end

    function UtilStun:TraceSource(readSource)
        if not ControlTrace.ENABLED then return nil end
        -- 来源查询属于诊断，失败不能阻止原眩晕或改变 nil ability 的添加规则。
        local ok, value = pcall(readSource)
        if ok then return value end
        return nil
    end

	function UtilStun:UnitStunTarget( caster,target,stuntime,sourceAbility,sourceKind)
		-- 可选来源仅用于诊断，保留实际 AddNewModifier 的 nil ability 和原时长规则。
		local before = nil
		if ControlTrace.ENABLED then
			local ok, value = pcall(ControlTrace.Before, caster, target)
			if ok then before = value end
		end
		local duration = stuntime * (1 - target:GetStatusResistance())
		local modifier = target:AddNewModifier(caster, nil, "modifier_stunned", {duration=duration})
		if before ~= nil then pcall(ControlTrace.After, before, caster, target, modifier, duration, sourceAbility, sourceKind) end
    end

    function UnitPauseTargetSakuya( caster,target,pausetime,ability)
    	ability:ApplyDataDrivenModifier( caster, target, "modifier_sakuya_pause_unit", {Duration=pausetime} )
    end
