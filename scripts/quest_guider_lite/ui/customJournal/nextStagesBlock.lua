local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local playerRef = require('openmw.self')
local templates = require('openmw.interfaces').MWUI.templates

local config = require("scripts.quest_guider_lite.configLib")
local commonUtils = require("scripts.quest_guider_lite.utils.common")
local consts = require("scripts.quest_guider_lite.common")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local tableLib = require("scripts.quest_guider_lite.utils.table")

local playerQuests = require('scripts.quest_guider_lite.playerQuests')
local tracking = require("scripts.quest_guider_lite.trackingLocal")

local log = require("scripts.quest_guider_lite.utils.log")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local button = require("scripts.quest_guider_lite.ui.button")


local this = {}


---@class questGuider.ui.nextStagesMeta
local nextStagesMeta = {}
nextStagesMeta.__index = nextStagesMeta

nextStagesMeta.type = consts.elementMetatableTypes.nextStages


function nextStagesMeta.getRequirementsFlex(self)
    return self:getLayout().content[2].content[3]
end

function nextStagesMeta.getRequirementsHeader(self)
    return self:getLayout().content[2].content[1]
end

function nextStagesMeta.getObjectsFlex(self)
    return self:getLayout().content[2].content[2]
end

function nextStagesMeta.getHeaderNextBtnsFlex(self)
    return self:getRequirementsHeader().content[1].content[2]
end

function nextStagesMeta.getHeaderVariantBtnsFlex(self)
    return self:getRequirementsHeader().content[3]
end

function nextStagesMeta.updateObjectElements(self)
    local flex = self:getObjectsFlex()

    for _, elem in pairs(flex.content) do
        if not elem.userData or not elem.userData.diaId or not elem.userData.objectId then goto continue end

        local disabledState = tracking.getDisabledState{objectId = elem.userData.objectId, questId = elem.userData.diaId}
        local trackedState = tracking.isObjectTracked{diaId = elem.userData.diaId, objectId = elem.userData.objectId}
        local trackingData = tracking.markerByObjectId[elem.userData.objectId]

        local textElem = elem.content[1].content[1].content[1]
        if not trackedState or not trackingData then
            textElem.props.textColor = config.data.ui.defaultColor
        elseif not disabledState then
            textElem.props.textColor = trackingData.color and util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                or config.data.ui.defaultColor
        elseif disabledState then
            textElem.props.textColor = consts.disabledColor
        end

        ::continue::
    end
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
    local function addObjectPositionInfo(content, requirements, diaId, diaIndex)
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
            local trackingData = tracking.markerByObjectId[objId]

            local objectColor = config.data.ui.defaultColor
            if trackingData then
                if trackingData.color then
                    objectColor = util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                end
            end

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
                                    textSize = (self.params.fontSize or 18) * 1.2,
                                    multiline = false,
                                    wordWrap = false,
                                    textColor = tracking.getDisabledState{objectId = objId, questId = diaId} and consts.disabledColor or objectColor,
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
                            button{
                                updateFunc = self.update,
                                text = tracking.isObjectTracked{diaId = diaId, objectId = objId} and "Untrack" or "Track",
                                textSize = (self.params.fontSize or 18) * 0.9,
                                event = function (layout)
                                    local trackedState = tracking.isObjectTracked{diaId = diaId, objectId = objId}
                                    if trackedState then
                                        tracking.removeMarker{objectId = objId, questId = diaId}
                                    else
                                        tracking.trackObject{diaId = diaId, objectId = objId, index = diaIndex}
                                    end

                                    ---@type questGuider.ui.buttonMeta
                                    local btnMeta = layout.userData.meta
                                    local btn = btnMeta:getButtonTextElement()
                                    if btn then
                                        btn.props.text = not trackedState and "Untrack" or "Track"
                                    end
                                    self:updateObjectElements()
                                end
                            },
                            interval((self.params.fontSize or 18) * 2, 0),
                            button{
                                updateFunc = self.update,
                                text = tracking.getDisabledState{objectId = objId, questId = diaId} and "Show" or "Hide",
                                textSize = (self.params.fontSize or 18) * 0.9,
                                event = function (layout)
                                    tracking.setDisableMarkerState{
                                        objectId = objId,
                                        questId = diaId,
                                        toggle = true,
                                        isUserDisabled = true,
                                    }

                                    local disabledState = tracking.getDisabledState{objectId = objId, questId = diaId}

                                    ---@type questGuider.ui.buttonMeta
                                    local btnMeta = layout.userData.meta
                                    local btn = btnMeta:getButtonTextElement()
                                    if btn then
                                        btn.props.text = disabledState and "Show" or "Hide"
                                    end

                                    self:updateObjectElements()
                                end
                            },
                            interval((self.params.fontSize or 18) * 2, 0),
                            {
                                template = templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                    text = "Closest:",
                                    textColor = config.data.ui.defaultColor,
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
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = objData.descr,
                    textColor = config.data.ui.defaultColor,
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

            content:add{
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = false,
                },
                userData = {
                    objectId = objId,
                    diaId = diaId,
                    -- positions = objData.positions,
                },
                content = ui.content {
                    header,
                    interval(self.params.fontSize / 2),
                    position,
                }
            }
            content:add(interval(0, math.floor(self.params.fontSize / 2)))
        end
    end

    ---@param requirements questGuider.quest.getDescriptionDataFromBlock.returnArr[]
    local function addRequirements(content, requirements)
        local text = ""
        for _, req in ipairs(requirements) do
            text = string.format("%s  %s\n", text, req.str)
        end
        content:add{
            template = templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = text,
                textColor = config.data.ui.defaultColor,
                autoSize = true,
                textSize = params.fontSize or 18,
                multiline = true,
                wordWrap = true,
            },
        }
    end

    local function resetColorOfButtons(flex)
        for _, elem in pairs(flex.content) do
            ---@type questGuider.ui.buttonMeta
            local meta = elem.userData and elem.userData.meta
            if meta then
                local textElem = meta:getButtonTextElement()
                if textElem then
                    textElem.props.textColor = config.data.ui.defaultColor
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
                        textSize = params.fontSize,
                        updateFunc = params.updateFunc,
                        event = function (layout)
                            local variantBtnFlex = self:getHeaderVariantBtnsFlex()
                            variantBtnFlex.content = ui.content{
                                {
                                    template = templates.textNormal,
                                    type = ui.TYPE.Text,
                                    props = {
                                        text = "Variants:",
                                        textColor = config.data.ui.defaultColor,
                                        autoSize = true,
                                        textSize = params.fontSize or 18,
                                        multiline = false,
                                        wordWrap = false,
                                    },
                                },
                            }
                            local reqFlex = self:getRequirementsFlex()
                            reqFlex.content = ui.content{}
                            local posFlex = self:getObjectsFlex()
                            posFlex.content = ui.content{}

                            ---@type questGuider.ui.buttonMeta
                            local btnMeta = layout.userData.meta
                            local btn = btnMeta:getButtonTextElement()
                            if btn then
                                resetColorOfButtons(self:getHeaderNextBtnsFlex())
                                btn.props.textColor = consts.selectedColor
                            end

                            for i, reqs in ipairs(nextData.requirements) do
                                variantBtnFlex.content:add(interval(12, 0))
                                variantBtnFlex.content:add(
                                    button{
                                        text = string.format("-%d-", i),
                                        textSize = params.fontSize,
                                        updateFunc = params.updateFunc,
                                        event = function (layout)
                                            local reqFlex = self:getRequirementsFlex()
                                            reqFlex.content = ui.content{
                                                interval(0, self.params.fontSize / 2)
                                            }
                                            local posFlex = self:getObjectsFlex()
                                            posFlex.content = ui.content{
                                                interval(0, self.params.fontSize / 2)
                                            }

                                            ---@type questGuider.ui.buttonMeta
                                            local btnMeta = layout.userData.meta
                                            local btn = btnMeta:getButtonTextElement()
                                            if btn then
                                                resetColorOfButtons(self:getHeaderVariantBtnsFlex())
                                                btn.props.textColor = consts.selectedColor
                                            end

                                            addObjectPositionInfo(posFlex.content, reqs, diaId, nextData.index)
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


---@param params questGuider.ui.nextStages.params
function this.create(params)

    ---@class questGuider.ui.nextStagesMeta
    local meta = setmetatable({}, nextStagesMeta)

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
                            textColor = config.data.ui.defaultColor,
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

    local objectsFlex = {
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
                    objectsFlex,
                    requirementFlex,
                }
            }
        }
    }

    meta.getLayout = function (self)
        return mainFlex
    end

    meta.data = nil

    return mainFlex
end


return this