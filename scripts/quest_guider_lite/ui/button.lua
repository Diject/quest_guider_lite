local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local input = require('openmw.input')
local templates = require('openmw.interfaces').MWUI.templates
local tooltip = require("scripts.proximityTool.ui.tooltip")

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

---@param params questGuider.ui.button.params
return function (params)
    if not params then return end

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
    end
    buttonContent:add{
        template = templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = params.text or "Ok",
            textSize = params.textSize or 18,
            multiline = false,
            wordWrap = false,
            textAlignH = ui.ALIGNMENT.Start,
        },
    }

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