local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates

local log = require("scripts.quest_guider_lite.utils.log")

local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")


local this = {}


---@param params questGuider.ui.questBox.params
local function fillJournal(content, params)

    for i = #params.playerQuestData.list, 1, -1 do
        local qInfo = params.playerQuestData.list[i]
        if not qInfo then goto continue end

        local text = playerQuests.getJournalText(qInfo.diaId, qInfo.index)
        if not text then goto continue end

        local height = uiUtils.getTextHeight(text, params.fontSize, params.size.x - 12)
        local textElemSize = util.vector2(params.size.x - 12, height)

        content:add{
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = false,
                anchor = util.vector2(0.5, 0),
            },
            content = ui.content {
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
        }

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
                    autoSize = true,
                    textSize = params.fontSize or 18,
                    multiline = false,
                    wordWrap = false,
                    textAlignH = ui.ALIGNMENT.Center,
                },
            }
        }
    }

    local journalContentSize = util.vector2(params.size.x, params.size.y - headerSize.y)

    local journalContent = ui.content{}
    fillJournal(journalContent, params)

    local journalEntries = scrollBox{
        updateFunc = params.updateFunc,
        thisElementInContent = function ()
            return params.thisElementInContent().content[1].content[2]
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
        content = ui.content {
            mainFlex,
        }
    }

    return mainPart
end


return this