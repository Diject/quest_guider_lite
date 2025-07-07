local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local templates = require('openmw.interfaces').MWUI.templates
local customTemplates = require("scripts.quest_guider_lite.ui.templates")

local config = require("scripts.quest_guider_lite.configLib")
local commonData = require("scripts.quest_guider_lite.common")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local tracking = require("scripts.quest_guider_lite.trackingLocal")

local timeLib = require("scripts.quest_guider_lite.timeLocal")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local log = require("scripts.quest_guider_lite.utils.log")

local button = require("scripts.quest_guider_lite.ui.button")
local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")

local questBox = require("scripts.quest_guider_lite.ui.customJournal.questBox")


---@class questGuider.ui.customJournal
local journalMeta = {}
journalMeta.__index = journalMeta

journalMeta.menu = nil


journalMeta.getQuestList = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[3]
end

journalMeta.getQuestMain = function (self)
    return self.menu.layout.content[2].content[1].content[2]
end

journalMeta.getQuestScrollBox = function (self)
    return self:getQuestMain().content[1]
end

journalMeta.getQuestListCheckBoxFlex = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[2]
end

journalMeta.getQuestListFinishedCheckBox = function (self)
    return self:getQuestListCheckBoxFlex().content[1]
end

journalMeta.getQuestListHiddenCheckBox = function (self)
    return self:getQuestListCheckBoxFlex().content[3]
end

journalMeta.resetQuestListColors = function (self)
    local questList = self:getQuestList()

    ---@type questGuider.ui.scrollBox
    local questBoxMeta = questList.userData.scrollBoxMeta
    local layout = questBoxMeta:getMainFlex()

    for _, elem in ipairs(layout.content) do
        elem.content[3].props.textShadow = false
    end
end

journalMeta.updateQuestListTrackedColors = function (self)
    local questList = self:getQuestList()

    ---@type questGuider.ui.scrollBox
    local questBoxMeta = questList.userData.scrollBoxMeta
    local layout = questBoxMeta:getMainFlex()

    for _, elem in ipairs(layout.content) do
        if elem.userData and elem.userData.playerQuestData then
            elem.content[1].content = ui.content{}
            self:_addFlags(elem.content[1].content, elem.userData.playerQuestData)
        end
    end
end

journalMeta.setQuestListSelectedFlad = function (self, value)
    self:getQuestList().userData.selected = value
end

journalMeta.getQuestListSelectedFladValue = function (self)
    return self:getQuestList().userData.selected
end

journalMeta.resetQuestListSelection = function (self)
    self:resetQuestListColors()
    self:setQuestListSelectedFlad(nil)
end

journalMeta.clearQuestInfo = function (self)
    local qInfoScrollBox = self:getQuestScrollBox()
    if not qInfoScrollBox then return end

    qInfoScrollBox.name = nil

    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qInfoScrollBox.userData.scrollBoxMeta
    sBoxMeta:clearContent()
end

journalMeta.selectQuest = function (self, qName)
    if qName == nil then
        self:resetQuestListSelection()
        self:clearQuestInfo()
        return
    end

    ---@type questGuider.ui.scrollBox
    local scrollBoxMeta = self:getQuestList().userData.scrollBoxMeta
    local qListLayout = scrollBoxMeta:getMainFlex()

    local qMainLay = self:getQuestMain()

    local succ, selectedLayout = pcall(function() return qListLayout.content[qName] end)
    if not succ or not selectedLayout then
        self:clearQuestInfo()
        self:setQuestListSelectedFlad(nil)
        return
    end

    local function applyTextShadow()
        selectedLayout.content[3].props.textShadow = true
        selectedLayout.content[3].props.textShadowColor = config.data.ui.shadowColor
    end

    if self:getQuestScrollBox() and self:getQuestScrollBox().name == qName then
        applyTextShadow()
        return
    end

    qMainLay.content = ui.content{
        questBox.create{
            parent = self,
            fontSize = self.params.fontSize or 18,
            playerQuestData = selectedLayout.userData.playerQuestData,
            questName = selectedLayout.userData.questName,
            size = qMainLay.userData.size,
            updateFunc = function ()
                self:update()
            end,
        }
    }

    self:resetQuestListSelection()
    self:setQuestListSelectedFlad(qName)
    applyTextShadow()

    self:update()

    ---@type questGuider.ui.questBoxMeta
    local questBoxMeta = self:getQuestScrollBox().userData.questBoxMeta
    core.sendGlobalEvent("QGL:fillQuestBoxQuestInfo", questBoxMeta.dialogueInfo)
end

journalMeta.update = function(self)
    self.menu:update()
end


function journalMeta.updateNextStageBlocks(self)
    ---@type questGuider.ui.questBoxMeta
    local qBox = self:getQuestScrollBox().userData.questBoxMeta
    ---@type questGuider.ui.scrollBox
    local scrlBox = qBox:getScrollBox().userData.scrollBoxMeta

    for _, scrollContentElement in pairs(scrlBox:getMainFlex().content) do
        for _, nextStagesBlock in pairs(scrollContentElement.content or {}) do
            if not nextStagesBlock.userData or not nextStagesBlock.userData or not nextStagesBlock.userData.meta
                    or nextStagesBlock.userData.meta.type ~= commonData.elementMetatableTypes.nextStages then
                goto continue
            end

            nextStagesBlock.userData.meta:updateObjectElements()

            ::continue::
        end
    end
end


---@param questData questGuider.playerQuest.storageQuestData
---@param text string
---@return boolean
local function hasText(questData, text)
    text = text:lower()
    if questData.name:lower():find(text) then
        return true
    end

    for _, dt in pairs(questData.list) do
        if dt.diaId:find(text) then return true end

        local journalText = playerQuests.getJournalText(dt.diaId, dt.index)
        if journalText and journalText:lower():find(text) then
            return true
        end

        local dateStr = timeLib.getDateByTime(dt.timestamp or 0)
        if dateStr:lower():find(text) then
            return true
        end
    end

    return false
end


---@param storageData questGuider.playerQuest.storageQuestData
function journalMeta._addFlags(self, content, storageData)
    if not commonData.whiteTexture then return end

    ---@type table<string, string[]>
    local objects = {}
    for diaId, diaRecord in pairs((playerQuests.getQuestDataByName(storageData.name) or {}).records or {}) do
        tableLib.copy(tracking.getDiaTrackedObjects(diaId) or {}, objects)
    end

    if not config.data.journal.trackedColorMarks and next(objects) then
        content:add{
            type = ui.TYPE.Image,
            props = {
                resource = commonData.whiteTexture,
                size = util.vector2(self.params.fontSize / 3, self.params.fontSize),
                color = commonData.defaultColor,
            },
        }
    else
        local maxMarks = config.data.journal.maxColorMarks
        for objectId, _ in pairs(objects) do
            local objData = tracking.getTrackedObjectData(objectId)
            if objData and objData.color then
                if maxMarks > 0 then
                    maxMarks = maxMarks - 1
                else
                    break
                end
                content:add{
                    type = ui.TYPE.Image,
                    props = {
                        resource = commonData.whiteTexture,
                        size = util.vector2(self.params.fontSize / 4, self.params.fontSize),
                        color = util.color.rgb(objData.color[1], objData.color[2], objData.color[3]),
                    },
                }
            end
        end
    end
end


function journalMeta.fillQuestsContent(self, content)
    local params = self.params

    if not content then
        local qList = self:getQuestList()
        ---@type questGuider.ui.scrollBox
        local sBoxMeta = qList.userData.scrollBoxMeta
        sBoxMeta:clearContent()

        content = sBoxMeta:getMainFlex().content
    end

    ---@type questGuider.playerQuest.storageData
    local playerData = playerQuests.getStorageData()

    ---@type questGuider.playerQuest.storageQuestData[]
    local sortedData = tableLib.values(playerData.questData, function (a, b)
        return (a.finished and -2 or a.disabled and -1 or a.timestamp or 0) > (b.finished and -2 or b.disabled and -1 or b.timestamp or 0)
    end)

    local showFinished = self:getQuestListFinishedCheckBox().userData.checked
    local showHidden = self:getQuestListHiddenCheckBox().userData.checked

    local disabledColor = config.data.ui.disabledColor
    local finishedColor = config.data.ui.disabledColor

    for _, dt in pairs(sortedData) do
        if dt.disabled and not showHidden
                or dt.finished and not showFinished then
            goto continue
        end

        if self.textFilter ~= "" and not hasText(dt, self.textFilter) then
            goto continue
        end

        local qName = dt.name or ""

        local qNameText = qName == "" and "Other" or qName or "???"

        if dt.finished then
            qNameText = string.format("(F) %s", qNameText)
        end

        local flagsContent = ui.content{}
        self:_addFlags(flagsContent, dt)

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

                    self:selectQuest(qName)
                end),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = true,
                    },
                    content = flagsContent,
                },
                interval(0, params.fontSize / 4),
                {
                    template = templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        text = qNameText,
                        textSize = params.fontSize or 18,
                        textColor = dt.disabled and disabledColor or dt.finished and finishedColor or config.data.ui.defaultColor,
                        multiline = false,
                        wordWrap = false,
                        textAlignH = ui.ALIGNMENT.Start,
                    },
                }
            }
        }

        ::continue::
    end
end


---@class questGuider.ui.customJournal.params
---@field size any
---@field fontSize integer
---@field relativePosition any?
---@field onClose function?

---@param params questGuider.ui.customJournal.params
local function create(params)

    ---@class questGuider.ui.customJournal
    local meta = setmetatable({}, journalMeta)

    local function updateFunc()
        if not meta.menu then return end
        meta:update()
    end

    meta.params = params

    meta.textFilter = ""

    local mainHeader = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(params.size.x, params.fontSize * 1.5),
        },
        userData = {},
        content = ui.content{
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = "Journal",
                    textSize = params.fontSize * 1.5,
                    autoSize = true,
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                },
                userData = {},
                events = {
                    mousePress = async:callback(function(coord, layout)
                        meta:getQuestMain().content = ui.content{}
                        meta:resetQuestListColors()

                        layout.userData.doDrag = true
                        local screenSize = ui.screenSize()
                        layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
                    end),

                    mouseRelease = async:callback(function(_, layout)
                        local relativePos = meta.menu.layout.props.relativePosition
                        config.setValue("journal.position.x", relativePos.x)
                        config.setValue("journal.position.y", relativePos.y)
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
            },
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = "Close",
                    textSize = params.fontSize * 1.25,
                    autoSize = true,
                    anchor = util.vector2(1, 1),
                    relativePosition = util.vector2(1, 1),
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                },
                userData = {},
                events = {
                    mouseRelease = async:callback(function(_, layout)
                        if params.onClose then params.onClose() end
                        meta.menu:destroy()
                    end),
                }
            },
        },
    }

    local questListSize = util.vector2(params.size.x * config.data.journal.listRelativeSize, params.size.y)
    local searchBar
    searchBar = {
        type = ui.TYPE.Container,
        props = {
            autoSize = false,
            size = util.vector2(questListSize.x, params.fontSize)
        },
        content = ui.content {
            {
                template = templates.box,
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
                            size = util.vector2(params.size.x * 0.2, params.fontSize + 4),
                        },
                        events = {
                            textChanged = async:callback(function(text, layout)
                                meta.textFilter = text
                            end),
                            focusLoss = async:callback(function(layout)
                                searchBar.content[1].content[1].props.text = meta.textFilter
                            end),
                        },
                    },
                }
            },
            button{
                updateFunc = updateFunc,
                text = "Search",
                textSize = params.fontSize,
                position = util.vector2(questListSize.x - 2, 3),
                anchor = util.vector2(1, 0),
                event = function (layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)
                end
            },
        }
    }

    local checkBoxes = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
        content = ui.content {
            checkBox{
                updateFunc = function ()
                    meta:update()
                end,
                checked = true,
                text = "Finished",
                textSize = params.fontSize or 18,
                event = function (checked, layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)
                end
            },
            interval(params.fontSize / 2, 0),
            checkBox{
                updateFunc = function ()
                    meta:update()
                end,
                checked = true,
                text = "Hidden",
                textSize = params.fontSize or 18,
                event = function (checked, layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillQuestsContent()
                    meta:selectQuest(selectedQuest)
                end
            },
        }
    }

    local questsContent = ui.content{}

    local questListBox = scrollBox{
        updateFunc = updateFunc,
        size = util.vector2(questListSize.x - 4, questListSize.y - params.fontSize * 2 - 14),
        scrollAmount = params.fontSize * 6,
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
            checkBoxes,
            questListBox,
        }
    }


    local questInfoSize = util.vector2(params.size.x * (1 - config.data.journal.listRelativeSize), params.size.y)
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
        template = customTemplates.boxSolidThick,
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

    meta:fillQuestsContent(questsContent)

    return meta
end


return create