local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local templates = require('openmw.interfaces').MWUI.templates
local commonData = require("scripts.quest_guider_lite.common")

local interval = require("scripts.quest_guider_lite.ui.interval")


---@class questGuider.ui.checkBox.params
---@field text string?
---@field checked boolean?
---@field textSize integer?
---@field event fun(checked : boolean, layout : any)?
---@field updateFunc fun()


---@param params questGuider.ui.checkBox.params
return function(params)
    if not params then return end
    local size = util.vector2(params.textSize or 18, params.textSize or 18)
    local texture = ui.texture { path = "white" }

    local contentData = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
        userData = {
            checked = params.checked or false
        },
        events = {
            mouseRelease = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                if layout.userData then
                    layout.userData.checked = not layout.userData.checked
                else
                    return
                end

                if layout.userData.checked then
                    layout.content[1].content[1].props.alpha = 1
                else
                    layout.content[1].content[1].props.alpha = 0
                end

                if params.event then
                    params.event(layout.userData.checked, layout)
                end

                params.updateFunc()
            end),
        },
        content = ui.content {
            {
                template = templates.box,
                type = ui.TYPE.Container,
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = texture,
                            size = size,
                            inheritAlpha = false,
                            alpha = params.checked and 1 or 0,
                            color = commonData.defaultColor,
                        },
                    }
                },
            },
            interval(4, 4),
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = params.text or "Enable",
                    textSize = params.textSize or 18,
                    multiline = false,
                    wordWrap = false,
                    textAlignH = ui.ALIGNMENT.Start,
                },
            }
        }
    }

    return contentData
end