-- 模式选择框架

-- 基础模式表
botModeSelect = {
	is_paused = false,
	dota_inter = false,
	is_bot_enabled = true,
	Difficulty = 4,
	MaxPlayer = 5,
	max_bot = 5,
}

-- bot 难度时间成长扩展到 50 分钟后，适配平均 50 分钟左右的对局。
local BOT_DIFFICULTY_TIME_BUCKETS = 11

-- 默认难度数据
botDifficultyDefaultData = {
	[1] = {
		name = "Easy",

		manaRegen = 3, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 0, -- 死亡时获取金币

		selfStunChanceOnAttack = 0.33, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0.3, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0.002, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 3, -- 移动时自我眩晕持续时间

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { -5, -5, -5 },

		-- 三围定时增加
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
		},
	},
	[2] = {
		name = "Normal",

		manaRegen = 5, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 0, -- 死亡时获取金币

		selfStunChanceOnAttack = 0.1, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0.1, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 0, -- 移动时自我眩晕持续时间

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { 0, 0, 0 },

		-- 三围定时增加
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
		},
	},
	[3] = {
		name = "Hard",

		manaRegen = 8, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 300, -- 死亡时获取金币

		selfStunChanceOnAttack = 0, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 0, -- 移动时自我眩晕持续时间

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			15, -- 10-15 min
			22.5, -- 15-20 min
			37.5, -- 20-25 min
			45, -- 25-30 min
			52.5, -- 30-35 min
			60, -- 35-40 min
			75, -- 40-45 min
			82.5, -- 45-50 min
			90, -- 50+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			12, -- 10-15 min
			18, -- 15-20 min
			30, -- 20-25 min
			37.5, -- 25-30 min
			41.25, -- 30-35 min
			45, -- 35-40 min
			50, -- 40-45 min
			55, -- 45-50 min
			60, -- 50+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { 2, 2, 2 },

		-- 三围定时增加（每5分钟到下一等级）
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.03, 0.01, 0.01 }, -- 10-15 min
				{ 0.03, 0.01, 0.01 }, -- 15-20 min
				{ 0.07, 0.02, 0.02 }, -- 20-25 min
				{ 0.075, 0.022, 0.022 }, -- 25-30 min
				{ 0.11, 0.033, 0.033 }, -- 30-35 min
				{ 0.15, 0.05, 0.05 }, -- 35-40 min
				{ 0.19, 0.063, 0.063 }, -- 40-45 min
				{ 0.21, 0.07, 0.07 }, -- 45-50 min
				{ 0.23, 0.077, 0.077 }, -- 50+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.015, 0.03, 0.01 }, -- 10-15 min
				{ 0.015, 0.03, 0.01 }, -- 15-20 min
				{ 0.03, 0.07, 0.02 }, -- 20-25 min
				{ 0.033, 0.077, 0.022  }, -- 25-30 min
				{ 0.05, 0.11, 0.033 }, -- 30-35 min
				{ 0.07, 0.15, 0.05 }, -- 35-40 min
				{ 0.09, 0.19, 0.063 }, -- 40-45 min
				{ 0.10, 0.21, 0.07 }, -- 45-50 min
				{ 0.11, 0.23, 0.077 }, -- 50+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.015, 0.01, 0.03 }, -- 10-15 min
				{ 0.015, 0.01, 0.03 }, -- 15-20 min
				{ 0.03, 0.02, 0.07 }, -- 20-25 min
				{ 0.033, 0.022, 0.077 }, -- 25-30 min
				{ 0.05, 0.033, 0.11 }, -- 30-35 min
				{ 0.07, 0.05, 0.15 }, -- 35-40 min
				{ 0.09, 0.063, 0.19 }, -- 40-45 min
				{ 0.10, 0.07, 0.21 }, -- 45-50 min
				{ 0.11, 0.077, 0.23 }, -- 50+ min
			},
		},
	},
	[4] = {
		name = "Lunatic",

		manaRegen = 20, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 600, -- 死亡时获取金币

		selfStunChanceOnAttack = 0, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 0, -- 移动时自我眩晕持续时间

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			25, -- 10-15 min
			35, -- 15-20 min
			55, -- 20-25 min
			65, -- 25-30 min
			80, -- 30-35 min
			100, -- 35-40 min
			125, -- 40-45 min
			145, -- 45-50 min
			165, -- 50+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			16, -- 10-15 min
			24, -- 15-20 min
			40, -- 20-25 min
			50, -- 25-30 min
			55, -- 30-35 min
			60, -- 35-40 min
			70, -- 40-45 min
			80, -- 45-50 min
			90, -- 50+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { 4, 4, 4 },

		-- 三围定时增加
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.06, 0.02, 0.02 }, -- 10-15 min
				{ 0.06, 0.02, 0.02 }, -- 15-20 min
				{ 0.12, 0.04, 0.04 }, -- 20-25 min
				{ 0.13, 0.045, 0.045 }, -- 25-30 min
				{ 0.22, 0.072, 0.072 }, -- 30-35 min
				{ 0.30, 0.10, 0.10 }, -- 35-40 min
				{ 0.36, 0.115, 0.115 }, -- 40-45 min
				{ 0.40, 0.13, 0.13 }, -- 45-50 min
				{ 0.44, 0.145, 0.145 }, -- 50+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.03, 0.06, 0.02 }, -- 10-15 min
				{ 0.03, 0.06, 0.02 }, -- 15-20 min
				{ 0.06, 0.12, 0.04 }, -- 20-25 min
				{ 0.065, 0.13, 0.045  }, -- 25-30 min
				{ 0.10, 0.22, 0.072 }, -- 30-35 min
				{ 0.14, 0.30, 0.10 }, -- 35-40 min
				{ 0.16, 0.36, 0.115 }, -- 40-45 min
				{ 0.18, 0.40, 0.13 }, -- 45-50 min
				{ 0.20, 0.44, 0.145 }, -- 50+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.03, 0.02, 0.06 }, -- 10-15 min
				{ 0.03, 0.02, 0.06 }, -- 15-20 min
				{ 0.06, 0.04, 0.12 }, -- 20-25 min
				{ 0.065, 0.045, 0.13 }, -- 25-30 min
				{ 0.10, 0.072, 0.22 }, -- 30-35 min
				{ 0.14, 0.10, 0.30 }, -- 35-40 min
				{ 0.16, 0.115, 0.36 }, -- 40-45 min
				{ 0.18, 0.13, 0.40 }, -- 45-50 min
				{ 0.20, 0.145, 0.44 }, -- 50+ min
			},
		},
	},
}

function ChangeGamePause(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		if GameRules:PlayerHasCustomGameHostPrivileges(plyhd) then
			botModeSelect.is_paused = data.is_paused ~= 0
			PauseGame(botModeSelect.is_paused)
		end
	end
end

function ChangeGameDotaInter(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.dota_inter = data.dota_inter ~= 0
		THD2_SetDotaMixedMode(botModeSelect.dota_inter)
		if botModeSelect.dota_inter then
			Say(plyhd, "Dota Mixed ON", false)
		else
			Say(plyhd, "Dota Mixed OFF", false)
		end
	end
end

function ChangeGameBotMode(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.is_bot_enabled = data.is_bot_enabled ~= 0
		THD2_SetBotMode(botModeSelect.is_bot_enabled)
		if botModeSelect.is_bot_enabled then
			Say(plyhd, "Bot Mode ON...", false)
		else
			Say(plyhd, "Bot Mode OFF...", false)
		end
	end
end

function ChangeGameDifficulty(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		THD2_ChangeBotDifficulty(plyhd, data.difficulty)
		botModeSelect.Difficulty = data.difficulty
	end
end

function ChangeGameMaxPlayer(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.MaxPlayer = tonumber(data.maxPlayer)
		local res = THD2_SetPlayerPerTeam(botModeSelect.MaxPlayer)
		Say(plyhd, "Max player(per team) set to " .. tostring(res), false)
	end
end

function ChangeGameMaxBot(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.max_bot = tonumber(data.max_bot)
		local res = THD2_SetPlayerBadTeam(botModeSelect.max_bot)
		Say(plyhd,"Max Bot set to "..tostring(res),false)
	end
end

function CloseGameMod()
	CustomGameEventManager:Send_ServerToAllClients("CloseGameMod", {})
end

function ModeSelect()
	CustomUI:DynamicHud_Create(-1, "Select", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("ModeSelect", { botModeSelect })  --然后将LUA表里的数据传给重连的玩家
end

function BotModSelect()
	CustomUI:DynamicHud_Create(-1, "BotSelect", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("BotModSelect", { botModeSelect })  --然后将LUA表里的数据传给重连的玩家
end


-- 难度数据
function SetBotDifficultyData(data)
	if not IsServer() then return end

	botDifficultyData = data
	CustomNetTables:SetTableValue(
			"selection",
			"botDifficultyData",
			botDifficultyData
	)
end

function GetBotDifficultyData()
	if IsServer() then
		return botDifficultyData
	else
		return CustomNetTables:GetTableValue("selection", "botDifficultyData")
	end
end

if IsServer() then
	SetBotDifficultyData(botDifficultyDefaultData[1])
end

function OpenBotDifficultyEditorOnGameRulesStateChange()
	CustomGameEventManager:Send_ServerToAllClients("OpenBotDifficultyEditor", { GetBotDifficultyData() })
end

-- 打开难度编辑器
function OpenBotDifficultyEditor(data)
	if data == nil then return end
	local plyhd = PlayerResource:GetPlayer(data.PlayerID)
	if not GameRules:PlayerHasCustomGameHostPrivileges(plyhd) then
		Say(plyhd, "只有主机可以编辑难度数据！", false)
		return
	end

	local difficulty = botModeSelect.Difficulty
	local diffData = botDifficultyData

	if diffData == nil then
		Say(plyhd, "无效的难度等级：" .. tostring(difficulty), false)
		return
	end

	-- 转换Lua表为可以序列化的格式
	local sendData = {
		difficulty = difficulty,
		name = diffData.name,
		manaRegen = diffData.manaRegen,
		hpRegen = diffData.hpRegen,
		goldGainOnDeath = diffData.goldGainOnDeath,
		selfStunChanceOnAttack = diffData.selfStunChanceOnAttack,
		selfStunDurationOnAttack = diffData.selfStunDurationOnAttack,
		selfStunChanceOnMove = diffData.selfStunChanceOnMove,
		selfStunDurationOnMove = diffData.selfStunDurationOnMove,
		giveGoldAmount = diffData.giveGoldAmount,
		giveExpAmount = diffData.giveExpAmount,
		giveAttrBase = diffData.giveAttrBase,
		giveAttrBonus = diffData.giveAttrBonus
	}

	-- 发送当前难度数据给前端
	CustomGameEventManager:Send_ServerToPlayer(plyhd, "OpenDifficultyEditor", sendData)

	Say(plyhd, "正在编辑 " .. diffData.name .. " 难度的数据...", false)
end

-- 保存难度数据
function SaveBotDifficultyData(data)
	if data == nil then return end
	local plyhd = PlayerResource:GetPlayer(data.PlayerID)
	if not GameRules:PlayerHasCustomGameHostPrivileges(plyhd) then
		Say(plyhd, "只有主机可以保存难度数据！", false)
		return
	end

	local difficulty = data.difficulty
	if difficulty == nil or difficulty < 1 or difficulty > 4 then
		Say(plyhd, "无效的难度等级", false)
		return
	end

	-- 构建新的难度数据表
	local newData = {
		name = data.name or botDifficultyDefaultData[difficulty].name,

		manaRegen = tonumber(data.manaRegen) or 0,
		hpRegen = tonumber(data.hpRegen) or 0,
		goldGainOnDeath = tonumber(data.goldGainOnDeath) or 0,

		selfStunChanceOnAttack = tonumber(data.selfStunChanceOnAttack) or 0,
		selfStunDurationOnAttack = tonumber(data.selfStunDurationOnAttack) or 0,
		selfStunChanceOnMove = tonumber(data.selfStunChanceOnMove) or 0,
		selfStunDurationOnMove = tonumber(data.selfStunDurationOnMove) or 0,

		giveGoldAmount = {},
		giveExpAmount = {},
		giveAttrBase = {},
		giveAttrBonus = {{}, {}, {}}
	}

	-- 填充时间相关数据
	for i = 1, BOT_DIFFICULTY_TIME_BUCKETS do
		newData.giveGoldAmount[i] = tonumber(data.giveGoldAmount[tostring(i)]) or data.giveGoldAmount[i] or 0
		newData.giveExpAmount[i] = tonumber(data.giveExpAmount[tostring(i)]) or data.giveExpAmount[i] or 0
	end

	-- 填充固定三围
	for i = 1, 3 do
		newData.giveAttrBase[i] = tonumber(data.giveAttrBase[tostring(i)]) or data.giveAttrBase[i] or 0
	end

	-- 填充定时三围加成
	for attrIdx = 1, 3 do
		for timeIdx = 1, BOT_DIFFICULTY_TIME_BUCKETS do
			local attrData = data.giveAttrBonus[tostring(attrIdx)] or data.giveAttrBonus[attrIdx] or {}
			local timeData = attrData[tostring(timeIdx)] or attrData[timeIdx] or {}

			newData.giveAttrBonus[attrIdx][timeIdx] = {
				tonumber(timeData["1"]) or tonumber(timeData[1]) or 0,
				tonumber(timeData["2"]) or tonumber(timeData[2]) or 0,
				tonumber(timeData["3"]) or tonumber(timeData[3]) or 0
			}
		end
	end

	-- 更新数据
	botDifficultyDefaultData[difficulty] = newData

	-- 如果当前正在使用这个难度，立即更新
	if botModeSelect.Difficulty == difficulty then
		SetBotDifficultyData(newData)
	end

	-- 通知保存成功
	CustomGameEventManager:Send_ServerToPlayer(plyhd, "SaveDifficultySuccess", {success = true})

	Say(plyhd, "难度 " .. newData.name .. " 数据已更新！", false)
	print("[BotDifficulty] 难度 " .. difficulty .. " 数据已更新")
end

-- 重置为默认
function ResetBotDifficulty(data)
	if data == nil then return end
	local plyhd = PlayerResource:GetPlayer(data.PlayerID)
	if not GameRules:PlayerHasCustomGameHostPrivileges(plyhd) then
		return
	end

	local difficulty = data.difficulty or 1

	-- 重新初始化默认数据
	InitDefaultDifficultyData()

	-- 发送更新后的数据给前端
	local diffData = botDifficultyDefaultData[difficulty]
	if diffData then
		local sendData = {
			difficulty = difficulty,
			name = diffData.name,
			manaRegen = diffData.manaRegen,
			hpRegen = diffData.hpRegen,
			goldGainOnDeath = diffData.goldGainOnDeath,
			selfStunChanceOnAttack = diffData.selfStunChanceOnAttack,
			selfStunDurationOnAttack = diffData.selfStunDurationOnAttack,
			selfStunChanceOnMove = diffData.selfStunChanceOnMove,
			selfStunDurationOnMove = diffData.selfStunDurationOnMove,
			giveGoldAmount = diffData.giveGoldAmount,
			giveExpAmount = diffData.giveExpAmount,
			giveAttrBase = diffData.giveAttrBase,
			giveAttrBonus = diffData.giveAttrBonus
		}
		CustomGameEventManager:Send_ServerToPlayer(plyhd, "OpenDifficultyEditor", sendData)
	end

	Say(plyhd, "难度 " .. (diffData and diffData.name or "未知") .. " 已重置为默认！", false)
end

-- 初始化默认难度数据（用于重置）
function InitDefaultDifficultyData()
	-- 这里重新定义默认数据，用于重置功能
	-- 由于原文件已经有定义，这里只是确保引用正确
	print("[BotDifficulty] 重置难度数据为默认值")
end
