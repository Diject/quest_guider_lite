local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local input = require('openmw.input')
local templates = require('openmw.interfaces').MWUI.templates
local tooltip = require("scripts.proximityTool.ui.tooltip")

---@class questGuider.ui.button.params
---@field menu any
---@field text string?
---@field textSize integer?
---@field textColor any?
---@field size any? -- util.vector2
---@field event function?
---@field tooltipContent any?

---@param params questGuider.ui.button.params
return function (params)
    if not params or not params.menu then return end
    local content
    content = {
        template = templates.boxSolidThick,
        props = {
            propagateEvents = false,
        },
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                content.template = templates.boxSolid
                layout.userData.pressed = true
                params.menu.element:update()
            end),

            mouseRelease = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                content.template = templates.boxSolidThick
                if layout.userData.pressed and params.event then
                    params.event(layout)
                end
                layout.userData.pressed = false
                params.menu.element:update()
            end),

            focusLoss = async:callback(function(e, layout)
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
                content = ui.content {
                    {
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
                }
            }
        },
    }

    return content
end