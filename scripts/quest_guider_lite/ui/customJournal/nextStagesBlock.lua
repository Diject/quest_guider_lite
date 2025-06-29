local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local playerRef = require('openmw.self')
local templates = require('openmw.interfaces').MWUI.templates

local commonUtils = require("scripts.quest_guider_lite.utils.common")
local consts = require("scripts.quest_guider_lite.common")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local tableLib = require("scripts.quest_guider_lite.utils.table")

local playerQuests = require('scripts.quest_guider_lite.playerQuests')

local log = require("scripts.quest_guider_lite.utils.log")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local button = require("scripts.quest_guider_lite.ui.button")


local this = {}


---@class questGuider.ui.nextStagesMeta
local nextStagesMeta = {}
nextStagesMeta.__index = nextStagesMeta


function nextStagesMeta.getRequirementsFlex(self)
    return self:thisElementInContent().content[2].content[2]
end

function nextStagesMeta.getRequirementsHeader(self)
    return self:thisElementInContent().content[2].content[1]
end

function nextStagesMeta.getHeaderNextBtnsFlex(self)
    return self:getRequirementsHeader().content[1].content[2]
end

function nextStagesMeta.getHeaderVariantBtnsFlex(self)
    return self:getRequirementsHeader().content[3]
end


function nextStagesMeta._fill(self, nextBtnsFlexContent)
    local params = self.params

    local nextStageData = self.data

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local objectPositions = nextStageData.objectPositions

    ---@param data  questGuider.quest.getRequirementPositionData.positionData
    ---@return string?
    ---@return string?
    local function getDescription(data)
        local descr
        local descrBack
        if not data.description then
            for i = #data.cellPath, 1, -1 do
                descr = descr and string.format("%s => \"%s\"", descr, data.cellPath[i].name) or
                    string.format("\"%s\"", data.cellPath[i].name)
                descrBack = descrBack and string.format("\"%s\" <= %s", data.cellPath[i].name, descrBack) or
                    string.format("\"%s\"", data.cellPath[i].name)
            end
        else
            descr = data.description
        end

        return descr, descrBack
    end

    ---@param requirements questGuider.quest.getDescriptionDataFromBlock.returnArr[]
    local function addObjectPositionInfo(content, requirements)
        ---@type table<string, {name : string, descr : string, descrBackward : string, positions : questGuider.quest.getRequirementPositionData.positionData[]}>
        local objectPosInfo = {}
        for _, req in pairs(requirements) do
            for objId, objName in pairs(req.objects or {}) do
                if objectPosInfo[objId] then goto continue end

                local positionData = objectPositions[objId]
                if not positionData then goto continue end

                ---@param pos questGuider.quest.getRequirementPositionData.positionData
                for _, pos in pairs(tableLib.getFirst(positionData.positions, 1)) do
                    local descr, descrBck = getDescription(pos)

                    objectPosInfo[objId] = {
                        descr = descr or "",
                        descrBackward = descrBck or descr or "",
                        name = positionData.name or "???",
                        positions = positionData.positions,
                    }
                end

                ::continue::
            end
        end

        for objId, objData in pairs(objectPosInfo) do

            local header = {
                type = ui.TYPE.Container,
                props = {
                    autoSize = false,
                    size = util.vector2(self.params.size.x, params.fontSize)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(0, 0),
                        },
                        content = ui.content {
                            {
                                template = templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                    text = objData.name,
                                    autoSize = true,
                                    textSize = (self.params.fontSize or 18) * 1.1,
                                    multiline = false,
                                    wordWrap = false,
                                },
                            },
                        }
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(1, 0),
                            position = util.vector2(self.params.size.x, 0)
                        },
                        content = ui.content {
                            {
                                template = templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                    text = "Closest position:",
                                    autoSize = true,
                                    textSize = (self.params.fontSize or 18) * 0.9,
                                    textAlignH = ui.ALIGNMENT.End,
                                    multiline = false,
                                    wordWrap = false,
                                },
                            },
                        }
                    },
                }
            }

            local posTextShift = self.params.fontSize / 2
            local posHeight = uiUtils.getTextHeight(objData.descr, self.params.fontSize, self.params.size.x - posTextShift, 0.5)
            local position = {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    size = util.vector2(
                        self.params.size.x,
                        math.min(self.params.fontSize * 2, posHeight)
                    ),
                    horizontal = true,
                },
                content = ui.content {
                    interval(posTextShift, 0),
                    {
                        template = templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = objData.descr,
                            autoSize = false,
                            textSize = self.params.fontSize or 18,
                            size = util.vector2(
                                self.params.size.x,
                                posHeight
                            ),
                            multiline = true,
                            wordWrap = true,
                        },
                    }
                }
            }

            content:add{
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = false,
                },
                userData = {
                    positions = objData.positions,
                },
                content = ui.content {
                    header,
                    position,
                }
            }
            content:add(interval(0, math.floor(self.params.fontSize / 2)))
        end
    end

    ---@param requirements questGuider.quest.getDescriptionDataFromBlock.returnArr[]
    local function addRequirements(content, requirements)
        for _, req in ipairs(requirements) do
            content:add{
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = false,
                },
                userData = {
                    requirement = req,
                },
                content = ui.content {
                    {
                        template = templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = req.str,
                            autoSize = true,
                            textSize = params.fontSize or 18,
                        },
                    }
                }
            }
        end
    end

    local function resetColorOfButtons(flex)
        for _, elem in pairs(flex.content) do
            ---@type questGuider.ui.buttonMeta
            local meta = elem.userData and elem.userData.meta
            if meta then
                local textElem = meta:getButtonTextElement(elem)
                if textElem then
                    textElem.props.textColor = consts.defaultColor
                end
            end
        end
    end

    local function addNextStageButtons(dt, format)
        for diaId, diaData in pairs(dt or {}) do

            local curentIndex = playerQuests.getCurrentIndex(diaId) or 0
            for _, nextData in ipairs(diaData) do
                if curentIndex >= nextData.index then goto continue end

                nextBtnsFlexContent:add(interval(12, 0))
                nextBtnsFlexContent:add(
                    button{
                        text = string.format(format, tostring(nextData.index)),
                        updateFunc = params.updateFunc,
                        event = function (layout)
                            local variantBtnFlex = self:getHeaderVariantBtnsFlex()
                            variantBtnFlex.content = ui.content{
                                {
                                    template = templates.textNormal,
                                    type = ui.TYPE.Text,
                                    props = {
                                        text = "Variants:",
                                        autoSize = true,
                                        textSize = params.fontSize or 18,
                                        multiline = false,
                                        wordWrap = false,
                                    },
                                },
                            }
                            local reqFlex = self:getRequirementsFlex()
                            reqFlex.content = ui.content{}

                            ---@type questGuider.ui.buttonMeta
                            local btnMeta = layout.userData.meta
                            local btn = btnMeta:getButtonTextElement(layout)
                            if btn then
                                resetColorOfButtons(self:getHeaderNextBtnsFlex())
                                btn.props.textColor = consts.selectedColor
                            end

                            for i, reqs in ipairs(nextData.requirements) do
                                variantBtnFlex.content:add(interval(12, 0))
                                variantBtnFlex.content:add(
                                    button{
                                        text = string.format("-%d-", i),
                                        updateFunc = params.updateFunc,
                                        event = function (layout)
                                            local reqFlex = self:getRequirementsFlex()
                                            reqFlex.content = ui.content{
                                                interval(0, self.params.fontSize)
                                            }

                                            ---@type questGuider.ui.buttonMeta
                                            local btnMeta = layout.userData.meta
                                            local btn = btnMeta:getButtonTextElement(layout)
                                            if btn then
                                                resetColorOfButtons(self:getHeaderVariantBtnsFlex())
                                                btn.props.textColor = consts.selectedColor
                                            end

                                            addObjectPositionInfo(reqFlex.content, reqs)
                                            reqFlex.content:add(interval(0, self.params.fontSize))
                                            addRequirements(reqFlex.content, reqs)
                                        end,
                                    }
                                )
                            end

                            self:update()
                        end,
                    }
                )

                ::continue::
            end
        end
    end

    addNextStageButtons(nextStageData.next, "-%d-")
    addNextStageButtons(nextStageData.linked, "(%d)")

end


---@class questGuider.ui.nextStages.params
---@field size any util.vector2
---@field fontSize integer
---@field data questGuider.main.fillQuestBoxQuestInfo.returnBlock
---@field updateFunc function
---@field thisElementInContent any


---@param params questGuider.ui.nextStages.params
function this.create(params)

    ---@class questGuider.ui.nextStagesMeta
    local meta = setmetatable({}, nextStagesMeta)

    meta.thisElementInContent = function (self)
        return params.thisElementInContent()
    end

    meta.update = function (self)
        params.updateFunc()
    end

    meta.data = params.data
    meta.params = params

    local nextBtnsFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
        content = ui.content{}
    }
    meta:_fill(nextBtnsFlex.content)

    local header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content {
                    {
                        template = templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = "Next:",
                            autoSize = true,
                            textSize = params.fontSize or 18,
                            multiline = false,
                            wordWrap = false,
                        },
                    },
                    nextBtnsFlex,
                }
            },
            interval(0, 4),
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content{}
            }
        }
    }

    local requirementFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
        },
        content = ui.content {

        }
    }

    local mainFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
        userData = {
            meta = meta,
        },
        content = ui.content {
            interval(4, 0),
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = false,
                },
                content = ui.content {
                    header,
                    requirementFlex,
                }
            }
        }
    }

    return mainFlex
end


return this