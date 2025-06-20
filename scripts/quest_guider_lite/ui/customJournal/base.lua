local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates

local commonData = require("scripts.quest_guider_lite.common")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local log = require("scripts.quest_guider_lite.utils.log")

local button = require("scripts.quest_guider_lite.ui.button")
local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")

local questBox = require("scripts.quest_guider_lite.ui.customJournal.questBox")


---@class questGuider.ui.customJournal
local journalMeta = {}
journalMeta.__index = journalMeta

journalMeta.menu = nil


journalMeta.getQuestList = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[2]
end

journalMeta.getQuestMain = function (self)
    return self.menu.layout.content[2].content[1].content[2]
end

journalMeta.update = function(self)
    self.menu:update()
end


---@param params questGuider.ui.customJournal.params
function journalMeta.__fillQuestsContent(self, content, params)
    ---@type questGuider.playerQuest.storageData
    local playerData = playerQuests.getStorageData()

    for qName, dt in pairs(playerData.questData) do
        content:add{
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = true,
            },
            name = qName,
            userData = {
                questName = qName,
                playerQuestData = dt,
            },
            events = {
                mouseRelease = async:callback(function(e, layout)
                    if e.button ~= 1 then return end

                    local lay = self:getQuestMain()
                    lay.content = ui.content{
                        questBox.create{
                            fontSize = 18,
                            playerQuestData = layout.userData.playerQuestData,
                            questName = layout.userData.questName,
                            size = lay.userData.size,
                            updateFunc = function ()
                                self:update()
                            end,
                            thisElementInContent = function ()
                                return lay.content[1]
                            end
                        }
                    }
                    self:update()
                end),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = true,
                    },
                    content = ui.content {

                    }
                },
                {
                    template = templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        text = qName,
                        textSize = params.fontSize or 18,
                        multiline = false,
                        wordWrap = false,
                        textAlignH = ui.ALIGNMENT.Start,
                    },
                }
            }
        }
    end
end


---@class questGuider.ui.customJournal.params
---@field size any
---@field fontSize integer
---@field relativePosition any?

---@param params questGuider.ui.customJournal.params
local function create(params)

    ---@class questGuider.ui.customJournal
    local meta = setmetatable({}, journalMeta)

    local function updateFunc()
        if not meta.menu then return end
        meta:update()
    end

    local mainHeader = {
        template = templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = "Journal",
            textSize = 30,
            autoSize = true,
            textAlignH = ui.ALIGNMENT.Center,
        },
        userData = {},
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.doDrag = true
                local screenSize = ui.screenSize()
                layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.lastMousePos then return end

                local screenSize = ui.screenSize()
                local props = meta.menu.layout.props
                local relativePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)

                props.relativePosition = props.relativePosition - (layout.userData.lastMousePos - relativePos)
                meta:update()

                layout.userData.lastMousePos = relativePos
            end),
        }
    }

    local questListSize = util.vector2(params.size.x * 0.3, params.size.y)
    local searchBar = {
        type = ui.TYPE.Container,
        props = {
            autoSize = false,
            size = util.vector2(questListSize.x, params.fontSize)
        },
        content = ui.content {
            {
                template = templates.boxTransparent,
                props = {
                    position = util.vector2(2, 2),
                    anchor = util.vector2(0, 0),
                },
                content = ui.content {
                    {
                        template = templates.textEditLine,
                        props = {
                            autoSize = false,
                            textSize = params.fontSize,
                            size = util.vector2(params.size.x * 0.2, params.fontSize),
                        },
                    },
                }
            },
            button{
                updateFunc = updateFunc,
                text = "Search",
                position = util.vector2(questListSize.x - 2, 3),
                anchor = util.vector2(1, 0),
            },
        }
    }

    local questsContent = ui.content{}
    meta:__fillQuestsContent(questsContent, params)

    local questListBox = scrollBox{
        updateFunc = updateFunc,
        thisElementInContent = function ()
            return meta.menu.layout.content[2].content[1].content[1].content[2]
        end,
        size = util.vector2(questListSize.x - 4, questListSize.y - params.fontSize - 10),
        content = questsContent
    }

    local questList = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = questListSize
        },
        content = ui.content {
            searchBar,
            questListBox,
        }
    }


    local questInfoSize = util.vector2(params.size.x * 0.7, params.size.y)
    local questInfo = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = questInfoSize,
        },
        userData = {
            size = questInfoSize,
        },
        content = ui.content {

        }
    }

    local mainWindow = {
        template = templates.boxSolidThick,
        props = {

        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content {
                    questList,
                    questInfo
                }
            }
        }
    }

    local mainFlex = {
        type = ui.TYPE.Flex,
        layer = "Windows",
        props = {
            autoSize = true,
            horizontal = false,
            align = ui.ALIGNMENT.Center,
            relativePosition = params.relativePosition,
        },
        userData = {

        },
        content = ui.content {
            mainHeader,
            mainWindow,
        }
    }

    meta.menu = ui.create(mainFlex)

    return meta
end


return create