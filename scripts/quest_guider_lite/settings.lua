local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local storage = require('openmw.storage')

local config = require("scripts.quest_guider_lite.config")
local commonData = require("scripts.quest_guider_lite.common")

I.Settings.registerPage{
  key = commonData.settingPage,
  l10n = commonData.l10nKey,
  name = "modName",
  description = "modDescription",
}

---@class questGuider.settings.boolSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field trueLabel string|nil
---@field falseLabel string|nil
---@field disabled boolean|nil

---@class questGuider.settings.numberSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default number|nil
---@field min number|nil
---@field max number|nil
---@field integer boolean|nil
---@field disabled boolean|nil

---@class questGuider.settings.label
---@field description string|nil l10n
---@field disabled boolean|nil

---@class questGuider.settings.text
---@field text string|nil
---@field disabled boolean|nil


---@param args questGuider.settings.boolSetting
local function boolSetting(args)
    return {
        key = args.key,
        renderer = "checkbox",
        name = args.name,
        description = args.description,
        default = args.default or false,
        argument = {
            trueLabel = args.trueLabel,
            falseLabel = args.falseLabel,
            disabled = args.disabled,
        }
    }
end

---@param args questGuider.settings.numberSetting
local function numberSetting(args)
    local data = {
        key = args.key,
        renderer = "number",
        name = args.name,
        description = args.description,
        default = args.default or 0,
        argument = {
            min = args.min,
            max = args.max,
            integer = args.integer,
            disabled = args.disabled,
        }
    }
    return data
end

local lableId = 0
---@param args questGuider.settings.label
local function textLabel(args)
    local data = {
        renderer = "QGL:Renderer:label",
        key = "__dummy__"..tostring(lableId),
        name = "empty",
        description = args.description,
        disabled = args.disabled,
    }
    lableId = lableId + 1
    return data
end

local function text(args)
    local data = {
        renderer = "QGL:Renderer:text",
        key = "__dummy__"..tostring(lableId),
        name = "empty",
        description = args.description,
        disabled = args.disabled,
        text = args.text,
    }
    lableId = lableId + 1
    return data
end

local function inputKey(args)
    local data = {
        renderer = "inputBinding",
        key = args.key,
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            key = args.argKey,
            type = args.argType
        }
    }
    return data
end

input.registerTrigger {
    key = "QGL:ui.menuKey",
    l10n = commonData.l10nKey,
}

-- f this
local bindingSection = storage.playerSection('OMWInputBindings')
if bindingSection:get(config.default.ui.menuKey) == nil then
    bindingSection:set(config.default.ui.menuKey, {
        device = "keyboard",
        button = input.KEY[config.default.ui.menuKey],
        type = "trigger",
        key = "QGL:ui.menuKey",
    })
end


I.Settings.registerGroup{
    key = commonData.storageSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "journal",
    permanentStorage = true,
    order = 0,
    settings = {
        inputKey{key = "ui.menuKey", name = "customJournalKeyName", description = "customJournalKeyDescription", argType = "trigger", argKey = "QGL:ui.menuKey", default = config.default.ui.menuKey},
        numberSetting{key = "ui.fontSize", name = "fontSize", integer = true, min = 12, max = 72, default = config.default.ui.fontSize},
    },
}