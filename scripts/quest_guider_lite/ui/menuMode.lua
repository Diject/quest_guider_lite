local UI = require("openmw.interfaces").UI
local core = require("openmw.core")

local this = {}

this.essentialModes = {
    ["Interface"] = true,
    ["Dialogue"] = true,
    ["LevelUp"] = true,
    ["ChargenName"] = true,
    ["ChargenRace"] = true,
    ["ChargenBirth"] = true,
    ["ChargenClass"] = true,
    ["ChargenClassGenerate"] = true,
    ["ChargenClassReview"] = true,
    ["ChargenClassPick"] = true,
    ["ChargenClassCreate"] = true,
    ["MainMenu"] = true,
    ["Barter"] = true,
    ["SpellBuying"] = true,
    ["Travel"] = true,
}


local modeId = "Journal"
this.modeId = modeId

local activated = false


function this.activate()
    activated = true
    UI.addMode(modeId, {windows = {}})
end


function this.deactivate()
    if not activated then return end
    UI.removeMode(modeId)
    activated = false
end


function this.setActiveFlag(active)
    activated = active and true or false
end


function this.isActivated()
    return activated
end


function this.setActivatedFlag(val)
    activated = val and true or false
end


---@return boolean
function this.isActive()
    if not activated then return false end
    for _, m in pairs(UI.modes) do
        if m == modeId then
            return true
        end
    end
    return false
end


---@return boolean
function this.isModeActive(mode)
    for _, m in pairs(UI.modes) do
        if m == mode then
            return true
        end
    end
    return false
end


---@return boolean
function this.isMenuInteractive()
    return UI.getMode() and true or false
end


return this