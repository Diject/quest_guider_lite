local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local input = require('openmw.input')
local templates = require('openmw.interfaces').MWUI.templates

local consts = require("scripts.quest_guider_lite.common")

local tooltip = require("scripts.proximityTool.ui.tooltip")
local interval = require("scripts.quest_guider_lite.ui.interval")


---@class questGuider.ui.buttonMeta
local buttonMeta = {}
buttonMeta.__index = buttonMeta

function buttonMeta.getButtonTextElement(self, thisElementInContent)
    if not self.params.text then return end
    local thisElem = thisElementInContent or (self.thisElementInContent and self.thisElementInContent())
    if not thisElem then return end
    if self.params.icon then
        return thisElem.content[1].content[3]
    else
        return thisElem.content[1].content[1]
    end
end


function buttonMeta.getButtonIconElement(self, thisElementInContent)
    if not self.params.icon then return end
    local thisElem = thisElementInContent or (self.thisElementInContent and self.thisElementInContent())
    if not thisElem then return end
    return thisElem.content[1].content[1]
end


---@class questGuider.ui.button.params
---@field text string?
---@field textSize integer?
---@field textColor any?
---@field size any? util.vector2
---@field icon string?
---@field iconSize any? util.vector2
---@field iconColor any?
---@field event fun(layout : any)?
---@field mousePress fun(layout : any)?
---@field mouseRelease fun(layout : any)?
---@field tooltipContent any?
---@field relativePosition any? util.vector2
---@field position any? util.vector2
---@field anchor any? util.vector2
---@field updateFunc fun()
---@field thisElementInContent any

---@param params questGuider.ui.button.params
return function (params)
    if not params then return end

    ---@class questGuider.ui.buttonMeta
    local meta = setmetatable({}, buttonMeta)

    meta.params = params

    meta.thisElementInContent = params.thisElementInContent

    local buttonContent = ui.content {}
    if params.icon then
        local texture = ui.texture{ path = params.icon }
        buttonContent:add{
            type = ui.TYPE.Image,
            props = {
                resource = texture,
                size = params.iconSize,
                color = params.iconColor,
            },
        }
        if params.text then
            buttonContent:add(interval(4, 0))
        end
    end

    if params.text then
        buttonContent:add{
            type = ui.TYPE.Text,
            props = {
                text = params.text or "Ok",
                textSize = params.textSize or 18,
                multiline = false,
                wordWrap = false,
                textAlignH = ui.ALIGNMENT.Start,
                textColor = params.textColor or consts.defaultColor
            },
        }
    end

    local content
    content = {
        template = templates.boxSolidThick,
        props = {
            propagateEvents = false,
            relativePosition = params.relativePosition,
            position = params.position,
            anchor = params.anchor,
        },
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                content.template = templates.boxSolid
                layout.userData.pressed = true
                if params.mousePress then
                    params.mousePress(layout)
                end
                params.updateFunc()
            end),

            mouseRelease = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                content.template = templates.boxSolidThick
                if params.mouseRelease then
                    params.mouseRelease(layout)
                end
                if layout.userData.pressed and params.event then
                    params.event(layout)
                end
                layout.userData.pressed = false
                params.updateFunc()
            end),

            focusLoss = async:callback(function(e, layout)
                if layout.userData.pressed and params.mouseRelease then
                    params.mouseRelease(layout)
                end
                layout.userData.pressed = false
                tooltip.destroy(layout)
            end),

            mouseMove = async:callback(function(coord, layout)
                if not params.tooltipContent then return end
                tooltip.createOrMove(coord, layout, params.tooltipContent)
            end),
        },
        userData = {
            pressed = false,
            meta = meta,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = params.size and false or true,
                    size = params.size,
                    horizontal = true,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content(buttonContent)
            }
        },
    }

    return content
end