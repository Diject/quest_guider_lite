local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local input = require('openmw.input')
local templates = require('openmw.interfaces').MWUI.templates

local consts = require("scripts.quest_guider_lite.common")
local tableLib = require("scripts.quest_guider_lite.utils.table")

local tooltip = require("scripts.proximityTool.ui.tooltip")
local interval = require("scripts.quest_guider_lite.ui.interval")


---@class questGuider.ui.buttonMeta
local buttonMeta = {}
buttonMeta.__index = buttonMeta

function buttonMeta.getButtonTextElement(self)
    if not self.params.text then return end
    if self.params.icon then
        return self.layout.content[1].content[3]
    else
        return self.layout.content[1].content[1]
    end
end


function buttonMeta.getButtonIconElement(self)
    if not self.params.icon then return end
    return self.layout.content[1].content[1]
end


local mousePress = async:callback(function(e, layout)
    if e.button ~= 1 then return end

    local uData = layout.userData
    local params = uData.params

    layout.template = templates.boxSolid

    uData.pressed = true
    if params.mousePress then
        params.mousePress(layout)
    end

    layout.userData.params.updateFunc()
end)

local mouseRelease = async:callback(function(e, layout)
    if e.button ~= 1 then return end

    layout.template = templates.boxSolidThick

    if layout.userData.params.mouseRelease then
        layout.userData.params.mouseRelease(layout)
    end

    if layout.userData.pressed and layout.userData.params.event then
        layout.userData.params.event(layout)
    end

    layout.userData.pressed = false
    layout.userData.params.updateFunc()
end)

local focusLoss = async:callback(function(e, layout)
    if layout.userData.pressed and layout.userData.params.mouseRelease then
        layout.userData.params.mouseRelease(layout)
    end
    layout.userData.pressed = false
    tooltip.destroy(layout)
end)

local mouseMove = async:callback(function(coord, layout)
    if not layout.userData.params.tooltipContent then return end
    tooltip.createOrMove(coord, layout, layout.userData.params.tooltipContent)
end)



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
---@field userData table?
---@field updateFunc fun()
---@field thisElementInContent any

---@param params questGuider.ui.button.params
return function (params)
    if not params then return end

    ---@class questGuider.ui.buttonMeta
    local meta = setmetatable({}, buttonMeta)

    meta.params = params

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

    local layout
    layout = {
        template = templates.boxSolidThick,
        props = {
            propagateEvents = false,
            relativePosition = params.relativePosition,
            position = params.position,
            anchor = params.anchor,
        },
        events = {
            mousePress = mousePress,
            mouseRelease = mouseRelease,
            focusLoss = focusLoss,
            mouseMove = mouseMove,
        },
        userData = {
            params = params,
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

    meta.layout = layout

    if params.userData then
        tableLib.copy(params.userData, layout.userData)
    end

    return layout
end