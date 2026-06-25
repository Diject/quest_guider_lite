local world = require('openmw.world')
local core = require("openmw.core")
local types = require("openmw.types")
local commonData = require("scripts.quest_guider_lite.common")
local cellData = require("scripts.quest_guider_lite.core.cellData")

local l10n = core.l10n(commonData.l10nKey)

local this = {}

this.skillName = {
	[0] = l10n("Block"),
	[1] = l10n("Armorer"),
	[2] = l10n("Medium Armor"),
	[3] = l10n("Heavy Armor"),
	[4] = l10n("Blunt Weapon"),
	[5] = l10n("Long Blade"),
	[6] = l10n("Axe"),
	[7] = l10n("Spear"),
	[8] = l10n("Athletics"),
	[9] = l10n("Enchant"),
	[10] = l10n("Destruction"),
	[11] = l10n("Alteration"),
	[12] = l10n("Illusion"),
	[13] = l10n("Conjuration"),
	[14] = l10n("Mysticism"),
	[15] = l10n("Restoration"),
	[16] = l10n("Alchemy"),
	[17] = l10n("Unarmored"),
	[18] = l10n("Security"),
	[19] = l10n("Sneak"),
	[20] = l10n("Acrobatics"),
	[21] = l10n("Light Armor"),
	[22] = l10n("Short Blade"),
	[23] = l10n("Marksman"),
	[24] = l10n("Mercantile"),
	[25] = l10n("Speechcraft"),
	[26] = l10n("Hand to Hand")
}

this.attributeName = {
	[0] = l10n("Strength"),
	[1] = l10n("Intelligence"),
	[2] = l10n("Willpower"),
	[3] = l10n("Agility"),
	[4] = l10n("Speed"),
	[5] = l10n("Endurance"),
	[6] = l10n("Personality"),
	[7] = l10n("Luck"),
}

this.weather = {
	["clear"] = 0,
	["cloudy"] = 1,
	["foggy"] = 2,
	["overcast"] = 3,
	["rain"] = 4,
	["thunder"] = 5,
	["ash"] = 6,
	["blight"] = 7,
	["snow"] = 8,
	["blizzard"] = 9,
}


this.getObject = require("scripts.quest_guider_lite.core.getObject")


---@param id integer
---@return {name : string}
function this.getMagicEffect(id)
	local effect = core.magic.effects.records[id]
	local effectName

	if not effect then
		effectName = string.format(l10n("magicEffectFormat"), id)
	else
		effectName = effect.name
	end

	return {name = effectName or ""}
end


---@param id string
---@return {name : string}
function this.findClass(id)
	local class = types.NPC.classes.record(id)
	local className

	if not class then
		className = string.format(l10n("classFormat"), id)
	else
		className = class.name
	end

    return {name = className or ""}
end


---@param params {topic : string}
---@return nil
function this.findDialogue(params)
	return nil
end


---@param id string
---@return nil
function this.getScript(id)
	return nil
end


---@param params {id : string?, name : string?, position : tes3vector3?, x : integer?, y : integer?}
function this.getCell(params)
	local func = function ()
		local cell
		if params.id then
			cell = world.getCellById(params.id)
		elseif params.name then
			cell = world.getCellByName(params.name)
		elseif params.position then
			local x = math.floor(params.position.x / 8192)
			local y = math.floor(params.position.y / 8192)
			cell = world.getExteriorCell(x, y)
		elseif params.x and params.y then
			cell = world.getExteriorCell(params.x, params.y)
		end

		return cell
	end

	local success, res = pcall(func)

	return success and res or nil
end


this.getCellData = cellData.getCellData


return this