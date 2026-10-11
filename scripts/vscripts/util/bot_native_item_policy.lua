local M = {}
M.TEETH_STATE = 8

-- 装备规则独立于英雄。乳牙附带多个modifier，但一次主动只贡献一个状态位。
-- 只认已经生效的攻速/移速buff，不把持有装备、沉默或吸血子modifier重复计数。
function M.GetState(hero)
	if hero:HasModifier("modifier_item_teeth_berserk_buff") then return M.TEETH_STATE end
	return 0
end

return M
