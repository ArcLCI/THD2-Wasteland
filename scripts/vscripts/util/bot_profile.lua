local BotProfile = {}

BotProfile.DAMAGE = "damage"
BotProfile.FRONTLINE = "frontline"
BotProfile.SUPPORT = "support"

local validProfiles = {
	[BotProfile.DAMAGE] = true,
	[BotProfile.FRONTLINE] = true,
	[BotProfile.SUPPORT] = true,
}

local PROFILE_MARKER_ABILITY = "ability_thd2_bot_profile"
local profileLevels = {
	[BotProfile.DAMAGE] = 1,
	[BotProfile.FRONTLINE] = 2,
	[BotProfile.SUPPORT] = 3,
}

local heroConfigs = {}
local selectedProfiles = {}

--[[
	注册表是英雄接入定位系统的唯一入口。rolePools 控制地图选人候选池，
	abilityPlans 按定位覆盖默认加点；未注册英雄仍会收到通用定位标记并沿用原加点。
]]
function BotProfile.RegisterHero(heroName, config)
	if type(heroName) ~= "string" or type(config) ~= "table" then return false end
	local defaultProfile = config.defaultProfile
	if not validProfiles[defaultProfile] then defaultProfile = BotProfile.DAMAGE end
	heroConfigs[heroName] = {
		defaultProfile = defaultProfile,
		rolePools = config.rolePools,
		abilityPlans = config.abilityPlans,
	}
	return true
end

function BotProfile.RegisterHeroes(configs)
	if type(configs) ~= "table" then return end
	for heroName, config in pairs(configs) do
		BotProfile.RegisterHero(heroName, config)
	end
end

function BotProfile.GetRolePools(heroName)
	local config = heroConfigs[heroName]
	return config ~= nil and config.rolePools or nil
end

function BotProfile.HasHeroConfig(heroName)
	return heroConfigs[heroName] ~= nil
end

function BotProfile.IsValidProfile(profile)
	return validProfiles[profile] == true
end

local function IsProfileAllowed(config, profile)
	if config == nil or type(config.rolePools) ~= "table" then return true end
	for _, allowedProfile in ipairs(config.rolePools) do
		if allowedProfile == profile then return true end
	end
	return false
end

function BotProfile.ValidateProfile(heroName, profile)
	if not validProfiles[profile] then
		return false, "unknown_profile"
	end
	if not IsProfileAllowed(heroConfigs[heroName], profile) then
		return false, "profile_not_allowed"
	end
	return true
end

function BotProfile.RecordProfile(heroName, requestedProfile)
	if type(heroName) ~= "string" then return nil end
	local config = heroConfigs[heroName]
	local profile = validProfiles[requestedProfile] and IsProfileAllowed(config, requestedProfile) and requestedProfile
		or (config ~= nil and config.defaultProfile)
		or BotProfile.DAMAGE
	selectedProfiles[heroName] = profile
	print("[BOT][Profile] selected hero=" .. heroName .. " profile=" .. profile
		.. " requested=" .. tostring(requestedProfile))
	return profile
end

function BotProfile.GetSelectedProfile(heroOrName)
	local heroName = type(heroOrName) == "string" and heroOrName or heroOrName:GetClassname()
	local config = heroConfigs[heroName]
	return selectedProfiles[heroName]
		or (config ~= nil and config.defaultProfile)
		or BotProfile.DAMAGE
end

function BotProfile.ApplyProfile(hero)
	if hero == nil or hero:IsNull() then return nil end
	local profile = BotProfile.GetSelectedProfile(hero)
	local desiredLevel = profileLevels[profile] or profileLevels[BotProfile.DAMAGE]
	local marker = hero:FindAbilityByName(PROFILE_MARKER_ABILITY)
	if marker == nil then
		marker = hero:AddAbility(PROFILE_MARKER_ABILITY)
	end
	if marker == nil then
		if hero.__thd2_bot_profile_add_failed ~= true then
			hero.__thd2_bot_profile_add_failed = true
			print("[BOT][Profile] failed player=" .. tostring(hero:GetPlayerOwnerID())
				.. " hero=" .. hero:GetClassname() .. " profile=" .. profile)
		end
		return profile
	end

	hero.__thd2_bot_profile_add_failed = nil
	marker:SetHidden(true)
	if marker:GetLevel() ~= desiredLevel then
		marker:SetLevel(desiredLevel)
		print("[BOT][Profile] applied player=" .. tostring(hero:GetPlayerOwnerID())
			.. " hero=" .. hero:GetClassname() .. " profile=" .. profile
			.. " markerLevel=" .. tostring(desiredLevel))
	end
	return profile
end

function BotProfile.GetAbilityPlan(hero, defaultPlan)
	local config = heroConfigs[hero:GetClassname()]
	if config == nil or type(config.abilityPlans) ~= "table" then return defaultPlan end
	return config.abilityPlans[BotProfile.GetSelectedProfile(hero)] or defaultPlan
end

return BotProfile
