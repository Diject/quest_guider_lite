local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates
local consts    = require('scripts.quest_guider_lite.common')

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
    return self:getRequirementsHeader().content[2]
end


function nextStagesMeta._fill(self, nextBtnsFlexContent)
    local params = self.params

    local nextStageData = self.data

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

    for diaId, diaData in pairs(nextStageData.next or {}) do
        local curentIndex = playerQuests.getCurrentIndex(diaId) or 0
        for _, nextData in ipairs(diaData) do
            if curentIndex >= nextData.index then goto continue end

            nextBtnsFlexContent:add(interval(12, 0))
            nextBtnsFlexContent:add(
                button{
                    text = string.format("-%s-", tostring(nextData.index)),
                    updateFunc = params.updateFunc,
                    event = function (layout)
                        local variantBtnFlex = self:getHeaderVariantBtnsFlex()
                        variantBtnFlex.content = ui.content{}
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
                                        reqFlex.content = ui.content{}

                                        ---@type questGuider.ui.buttonMeta
                                        local btnMeta = layout.userData.meta
                                        local btn = btnMeta:getButtonTextElement(layout)
                                        if btn then
                                            resetColorOfButtons(self:getHeaderVariantBtnsFlex())
                                            btn.props.textColor = consts.selectedColor
                                        end

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


---@class questGuider.ui.nextStages.params
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