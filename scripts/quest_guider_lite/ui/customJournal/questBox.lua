local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates

local log = require("scripts.quest_guider_lite.utils.log")

local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local common = require('scripts.quest_guider_lite.common')

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")


local this = {}


---@class questGuider.ui.questBoxMeta
local questBoxMeta = {}
questBoxMeta.__index = questBoxMeta

---@type table<string, {diaId : string, index : integer, contentIndex : integer}>
questBoxMeta.dialogueInfo = {}

function questBoxMeta.getScrollBox(self)
    return self:thisElementInContent().content[1].content[2]
end


---@param params questGuider.ui.questBox.params
function questBoxMeta._fillJournal(self, content, params)

    self.dialogueInfo = {}

    local contentIndex = 1
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
                                textSize = (params.fontSize or 18) + 2,
                                textColor = common.journalDateColorData,
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
---@field thisElementInContent any


---@param params questGuider.ui.questBox.params
function this.create(params)

    ---@class questGuider.ui.questBoxMeta
    local meta = setmetatable({}, questBoxMeta)

    meta.thisElementInContent = function (self)
        return params.thisElementInContent()
    end

    local headerSize = util.vector2(params.size.x, params.fontSize * 3)
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
                    autoSize = false,
                    size = util.vector2(params.size.x, params.fontSize),
                    textSize = params.fontSize or 18,
                    multiline = false,
                    wordWrap = false,
                    textAlignH = ui.ALIGNMENT.Center,
                },
            }
        }
    }

    local journalContentSize = util.vector2(params.size.x - 6, params.size.y - headerSize.y - 6)

    local journalContent = ui.content{}
    meta:_fillJournal(journalContent, params)

    local journalEntries = scrollBox{
        updateFunc = params.updateFunc,
        thisElementInContent = function ()
            return meta:thisElementInContent().content[1].content[2]
        end,
        size = journalContentSize,
        content = journalContent
    }

    local mainFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = params.size
        },
        content = ui.content {
            header,
            journalEntries,
        }
    }

    local mainPart = {
        template = templates.boxTransparent,
        props = {
            autoSize = false,
            size = params.size,
        },
        userData = {
            meta = meta,
        },
        content = ui.content {
            mainFlex,
        }
    }

    return mainPart
end


return this