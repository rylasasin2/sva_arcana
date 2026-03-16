require "/scripts/util.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"

function build(directory, config, parameters, level, seed)
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  -- select, load and merge abilities
  setupAbility(config, parameters, "alt")
  setupAbility(config, parameters, "primary")

  -- elemental type
  local elementalType = parameters.elementalType or config.elementalType or "physical"
  replacePatternInData(config, nil, "<elementalType>", elementalType)

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  config.tooltipFields = {}
  
  local critRate = configParameter("critRate", 0)
  local critBonus = configParameter("powerCritBoost", {0, 0})
  if critRate == 0 then
	config.tooltipFields.critRateLabel = "^shadow;^#8c8c8c;n/a^reset;"
	config.tooltipFields.critDamageLabel = "^shadow;^#8c8c8c;n/a^reset;"
  else
	config.tooltipFields.critRateLabel = "^shadow;^orange;"..math.floor(critRate*100).."%^reset;"
	config.tooltipFields.critDamageLabel = "^shadow;^orange;+"..math.max(math.floor(configParameter("critDamage", 0)*100 - 100), 0).."%^reset;"
	config.tooltipFields.critRateBoostLabel = "^shadow;^#8c8c8c;+"..math.max(math.floor(critBonus[1]*100), 0).."%^reset;"
	config.tooltipFields.critDamageBoostLabel = "^shadow;^#8c8c8c;+"..math.max(math.floor(critBonus[2]*100), 0).."%^reset;"
  end
  
  config.tooltipFields.subtitle = parameters.category
  config.tooltipFields.energyPerShotLabel = config.primaryAbility.energyPerShot or 0
  local bestDrawTime = (config.primaryAbility.powerProjectileTime[1] + config.primaryAbility.powerProjectileTime[2]) / 2
  local bestDrawMultiplier = root.evalFunction(config.primaryAbility.drawPowerMultiplier, bestDrawTime)
  config.tooltipFields.maxDamageLabel = util.round(config.primaryAbility.projectileParameters.power * config.damageLevelMultiplier * bestDrawMultiplier, 1)
  if elementalType ~= "physical" then
    config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
  end

  -- set price
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end
