local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates
local playerRef = require('openmw.self')

local log = require("scripts.quest_guider_lite.utils.log")

local config = require("scripts.quest_guider_lite.configLib")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local common = require('scripts.quest_guider_lite.common')
local tracking = require("scripts.quest_guider_lite.trackingLocal")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")
local button = require("scripts.quest_guider_lite.ui.button")
local tooltip = require("scripts.quest_guider_lite.ui.tooltip")

local dialogueIDTooltipLib = require("scripts.quest_guider_lite.ui.dialogueIdTooltip")

local l10n = core.l10n(common.l10nKey)


local this = {}


---@class questGuider.ui.questBoxMeta
local questBoxMeta = {}
questBoxMeta.__index = questBoxMeta

---@type table<string, {diaId : string, index : integer, contentIndex : integer}>
questBoxMeta.dialogueInfo = {}

function questBoxMeta.getScrollBox(self)
    return self:getLayout()
end

function questBoxMeta.getButtonWidget(self)
    return self:getScrollBox().userData.scrollBoxMeta:getMainFlex().content[1].content[3]
end

function questBoxMeta.getButtonFlex(self)
    return self:getButtonWidget().content[3]
end

function questBoxMeta.addTrackButtons(self, showRemoveBtn)
    self:getButtonFlex().content = ui.content{}
    self:getButtonFlex().content:add(button{
        text = l10n("trackObjects"),
        textSize = self.params.fontSize * 0.8,
        event = function (layout)
            self:addTrackButtons(true)

            for _, info in pairs(self.questInfo) do
                tracking.trackQuest(info.diaId, info.diaIndex)
                break
            end
        end,
        updateFunc = function ()
            self.params.updateFunc()
        end
    })

    local hasTracked = showRemoveBtn
    for _, info in pairs(self.dialogueInfo) do
        hasTracked = hasTracked or tracking.isDialogueHasTracked{diaId = info.diaId}
        if hasTracked then break end
    end

    if hasTracked then
        self:getButtonFlex().content:add(interval(self.params.fontSize, 0))
        self:getButtonFlex().content:add(button{
            text = l10n("removeTracking"),
            textSize = self.params.fontSize * 0.8,
            event = function (layout)
                for _, info in pairs(self.questInfo) do
                    tracking.removeMarker{
                        questId = info.diaId,
                        removeLinked = true
                    }
                    break
                end

                self:addTrackButtons()
                playerRef:sendEvent("QGL:updateQuestMenu", {})
            end,
            updateFunc = function ()
                self.params.updateFunc()
            end
        })
    end
end


---@param params questGuider.ui.questBox.params
function questBoxMeta._fillJournal(self, content, params)

    self.dialogueInfo = {}

    local contentIndex = 2
    for i = #params.playerQuestData.list, 1, -1 do
        local qInfo = params.playerQuestData.list[i]
        if not qInfo then goto continue end

        local text = playerQuests.getJournalText(qInfo.diaId, qInfo.index)
        if not text then goto continue end

        if not self.dialogueInfo[qInfo.diaId] or self.dialogueInfo[qInfo.diaId].index < qInfo.index then
            self.dialogueInfo[qInfo.diaId] = {
                diaId = qInfo.diaId,
                index = qInfo.index,
                contentIndex = contentIndex,
            }
        end

        local dateStr = timeLib.getDateByTime(qInfo.timestamp or 0)

        local height = uiUtils.getTextHeight(text, params.fontSize, params.size.x - 12)
        local textElemSize = util.vector2(params.size.x - 12, height)

        local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{recordInfo = qInfo, fontSize = params.fontSize}

        content:add{
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = false,
            },
            userData = {
                contentIndex = contentIndex,
                info = qInfo,
            },
            content = ui.content {
                interval(0, params.fontSize),
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = true,
                    },
                    content = ui.content {
                        interval(4, 1),
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = dateStr,
                                autoSize = true,
                                textSize = (params.fontSize or 18) * 1.15,
                                textColor = config.data.ui.dateColor,
                            },
                            userData = {},
                            events = {
                                mouseMove = async:callback(function(coord, layout)
                                    tooltip.createOrMove(coord, layout, tooltipContent)
                                end),

                                focusLoss = async:callback(function(e, layout)
                                    tooltip.destroy(layout)
                                end),
                            },
                        }
                    }
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = true,
                    },
                    content = ui.content {
                        interval(4, 1),
                        {
                            template = templates.textNormal,
                            type = ui.TYPE.Text,
                            props = {
                                text = text,
                                textColor = config.data.ui.defaultColor,
                                autoSize = false,
                                size = textElemSize,
                                textSize = params.fontSize or 18,
                                multiline = true,
                                wordWrap = true,
                                textAlignH = ui.ALIGNMENT.Center,
                            },
                        }
                    }
                },
            }
        }

        contentIndex = contentIndex + 1

        ::continue::
    end
end


---@class questGuider.ui.questBox.params
---@field size any
---@field fontSize integer
---@field questName string,
---@field playerQuestData questGuider.playerQuest.storageQuestData
---@field updateFunc function


---@param params questGuider.ui.questBox.params
function this.create(params)

    ---@class questGuider.ui.questBoxMeta
    local meta = setmetatable({}, questBoxMeta)

    meta.params = params

    meta.update = function (self)
        params.updateFunc()
    end


    local tooltipContent = dialogueIDTooltipLib.getContentForTooltip{meta = meta}

    local headerSize = util.vector2(params.size.x, params.fontSize * 3)
    local checkBoxBlockSize = util.vector2(params.size.x, params.fontSize * 2)
    local header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = headerSize
        },
        content = ui.content {
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = params.questName,
                    textColor = config.data.ui.defaultColor,
                    autoSize = false,
                    size = util.vector2(params.size.x, (params.fontSize or 18) * 1.2),
                    textSize = (params.fontSize or 18) * 1.2,
                    multiline = false,
                    wordWrap = false,
                    textAlignH = ui.ALIGNMENT.Center,
                },
                userData = {},
                events = {
                    mouseMove = async:callback(function(coord, layout)
                        tooltip.createOrMove(coord, layout, tooltipContent)
                    end),

                    focusLoss = async:callback(function(e, layout)
                        tooltip.destroy(layout)
                    end),
                },
            },
            interval(0, params.fontSize / 3),
            {
                type = ui.TYPE.Widget,
                props = {
                    autoSize = false,
                    size = checkBoxBlockSize,
                    horizontal = true,
                },
                content = ui.content {
                    checkBox{
                        updateFunc = function ()
                            params.updateFunc()
                        end,
                        checked = params.playerQuestData.finished,
                        text = l10n("finished"),
                        textSize = params.fontSize or 18,
                        relativePosition = util.vector2(0, 0.5),
                        anchor = util.vector2(0, 0.5),
                        event = function (checked, layout)
                            params.playerQuestData.finished = checked
                        end
                    },
                    checkBox{
                        updateFunc = function ()
                            params.updateFunc()
                        end,
                        checked = params.playerQuestData.disabled,
                        text = l10n("hidden"),
                        relativePosition = util.vector2(0.25, 0.5),
                        anchor = util.vector2(0, 0.5),
                        textSize = params.fontSize or 18,
                        event = function (checked, layout)
                            params.playerQuestData.disabled = checked
                        end
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(1, 0.5),
                            position = util.vector2(params.size.x - params.fontSize * 3, checkBoxBlockSize.y / 2),
                        },
                        content = ui.content{}
                    },
                }
            },
        }
    }

    local journalContent = ui.content{
        header,
    }
    meta:_fillJournal(journalContent, params)

    local journalEntries = scrollBox{
        name = params.questName,
        updateFunc = params.updateFunc,
        size = util.vector2(params.size.x - 2, params.size.y - 2),
        scrollAmount = params.fontSize * 6,
        content = journalContent,
        userData = {
            questBoxMeta = meta,
        }
    }

    meta.getLayout = function (self)
        return journalEntries
    end

    return journalEntries
end


return this