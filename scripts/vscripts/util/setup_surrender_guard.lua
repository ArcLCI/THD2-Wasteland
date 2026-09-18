local SetupSurrenderGuard = {}

local TIMEOUT_CVAR = "dota_auto_surrender_all_disconnected_timeout"
local SAVED_CVAR = "thd_setup_surrender_saved_timeout"
-- 原生逻辑直接比较 elapsed > timeout，0 不是禁用；开局前使用足够大的门槛。
local WAIT_TIMEOUT = 1000000000
local state = _G.THD_SETUP_SURRENDER_GUARD or { protected = false }
_G.THD_SETUP_SURRENDER_GUARD = state

local function Log(action, gameState, value)
	print(string.format(
		"[THD][SetupSurrenderGuard] version=SG1 action=%s state=%s original=%s value=%s",
		action, tostring(gameState), tostring(state.original), tostring(value)
	))
end

local function ReadTimeout()
	local value = Convars:GetFloat(TIMEOUT_CVAR)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		error("cannot read " .. TIMEOUT_CVAR)
	end
	return value
end

local function Update(gameState)
	local current = ReadTimeout()
	if gameState < DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if state.protected and current == WAIT_TIMEOUT then
			Log("protect", gameState, current)
			return
		end

		-- changelevel 可能重建 Lua VM，但引擎 cvar 仍保留；不要把上一局的保护值当成原值。
		local savedText = Convars:GetStr(SAVED_CVAR)
		if savedText == nil or savedText == "" then
			Convars:RegisterConvar(SAVED_CVAR, "unset", "THD pregame surrender timeout restore value", 0)
		end
		local saved = tonumber(savedText)
		if current == WAIT_TIMEOUT and saved ~= nil then
			state.original = saved
		else
			state.original = current
		end
		Convars:SetStr(SAVED_CVAR, string.format("%.17g", state.original))
		if tonumber(Convars:GetStr(SAVED_CVAR)) ~= state.original then
			error("cannot preserve original surrender timeout")
		end
		Convars:SetFloat(TIMEOUT_CVAR, WAIT_TIMEOUT)
		if ReadTimeout() ~= WAIT_TIMEOUT then
			error("cannot protect pregame surrender timeout")
		end
		state.protected = true
		Log("protect", gameState, WAIT_TIMEOUT)
	elseif state.protected or current == WAIT_TIMEOUT then
		local original = state.original or tonumber(Convars:GetStr(SAVED_CVAR))
		if original == nil then error("missing original surrender timeout") end
		state.original = original
		-- 只恢复本模块设置的值；管理员已经主动改动时保留其新设置。
		if current == WAIT_TIMEOUT then
			Convars:SetFloat(TIMEOUT_CVAR, original)
			if ReadTimeout() ~= original then error("cannot restore surrender timeout") end
			Log("restore", gameState, original)
		else
			Log("external_override", gameState, current)
		end
		state.protected = false
	end
end

function SetupSurrenderGuard:OnStateChange(gameState)
	-- 仅保护 dedicated 的开局流程；原有本地主机与已开始的比赛不改变规则。
	if not IsServer() or not IsDedicatedServer() then return end
	local ok, err = pcall(Update, gameState)
	if not ok then
		print("[THD][SetupSurrenderGuard] version=SG1 action=error message=" .. tostring(err))
	end
end

return SetupSurrenderGuard
