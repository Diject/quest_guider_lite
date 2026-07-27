local async = require("openmw.async")
local core = require("openmw.core")

local config = require("scripts.quest_guider_lite.configLib")
local menuHandler = require("scripts.quest_guider_lite.menuHandler")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local menuBuilders = require("scripts.quest_guider_lite.ui.menuBuilders")
local common = require("scripts.quest_guider_lite.common")
local contextMenu = require("scripts.quest_guider_lite.ui.contextMenu")

local l10n = core.l10n(common.l10nKey)


local this = {}


---@param dialogueNameMap table<string, any>
---@param topicIdByName table<string, string>
---@return questGuider.ui.contextMenu.create.params.element[] contextMenuData must be placed in userData.contextMenuData to be used in contextMenuEvents
function this.getDialogueTextData(dialogueNameMap, topicIdByName)
    ---@return questGuider.ui.contextMenu.create.params.element[]
    local contextMenuData = {}
    for _, name in ipairs(tableLib.keys(dialogueNameMap, true)) do
        if next(contextMenuData) then
            table.insert(contextMenuData, {type = 0})
        end
        table.insert(contextMenuData, {
            text = name,
            callback = function ()
                local menu = menuHandler.getMenu(common.topicsMenuId)
                if not menu then
                    menu = menuBuilders.topicMenu()
                    menuHandler.registerMenu(common.topicsMenuId, menu)
                end

                local id = topicIdByName[name] or name
                menu:selectTopic(id)
                contextMenu.destroy()
            end
        })
    end

    return contextMenuData
end


---@return table contextMenuEvents
function this.getDialogueTextEvents(scrollBoxMeta)
    local contextMenuEvents = {
        mousePress = async:callback(function(e, layout)
            layout.userData.clickTimestamp = core.getRealTime()
            scrollBoxMeta:mousePress(e)
        end),

        mouseRelease = async:callback(function(e, layout)
            if contextMenu.getActiveMenuId() and layout.userData.contextMenuId == contextMenu.getActiveMenuId() then
                contextMenu.destroy()
            elseif e.button == 1 and layout.userData.contextMenuData and (scrollBoxMeta.lastMovedDistance < 30) and
                    core.getRealTime() - layout.userData.clickTimestamp < 0.4 then
                layout.userData.contextMenuId = contextMenu.create{
                    position = e.position,
                    fontSize = config.data.ui.fontSize,
                    elements = layout.userData.contextMenuData,
                }
            end

            scrollBoxMeta:mouseRelease(e)
        end),
    }

    return contextMenuEvents
end


---@param updateFunc fun()?
---@return questGuider.ui.contextMenu.create.params.element[] contextMenuData
function this.getOptionsData(updateFunc)
    ---@type questGuider.ui.contextMenu.create.params.element[]
    local out = {
        {type = 1, text = l10n("questLogContextLabel"), fontSize = config.data.ui.fontSize * 1.1},
        {type = 0},
        {type = 3, text = l10n("questLogContextDialogueInfo"), data = config.data.journal.questLog.dialogueInfo, callback = function (checked, layout)
            config.setValue("journal.questLog.dialogueInfo", checked)
            if updateFunc then updateFunc() end
        end},
        {type = 3, text = l10n("questLogContextObjectInfo"), data = config.data.journal.questLog.objectInfo, callback = function (checked, layout)
            config.setValue("journal.questLog.objectInfo", checked)
            if updateFunc then updateFunc() end
        end},
    }

    return out
end



return this