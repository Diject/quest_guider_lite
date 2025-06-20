local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates

local button = require("scripts.quest_guider_lite.ui.button")


---@class questGuider.ui.scrollBox.params
---@field size any -- util.vector2
---@field content any
---@field updateFunc fun()
---@field thisElementInContent fun() : any


---@param params questGuider.ui.scrollBox.params
return function(params)
    if not params then return end

    local flex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = params.size,
        },
        content = ui.content {
            {
                type = ui.TYPE.Container,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = false,
                            position = util.vector2(0, 0),
                        },
                        content = params.content,
                    }
                },
            }
        }
    }

    local function getFlex()
        return params.thisElementInContent().content[1].content[1].content[1]
    end

    local contentData
    contentData = {
        template = templates.boxTransparent,
        props = {
            size = params.size,
        },
        events = {

        },
        userData = {

        },
        content = ui.content {
            flex,
            button{
                position = util.vector2(params.size.x - 4, 4),
                anchor = util.vector2(1, 0),
                text = "<",
                updateFunc = params.updateFunc,
                event = function (layout)
                    local fl = getFlex()
                    local pos = fl.props.position
                    if not pos then return end

                    fl.props.position = util.vector2(0, math.min(0, pos.y + 24))
                    params.updateFunc()
                end,
            },
            button{
                position = util.vector2(params.size.x - 4, params.size.y - 4),
                anchor = util.vector2(1, 1),
                text = ">",
                updateFunc = params.updateFunc,
                event = function (layout)
                    local fl = getFlex()
                    local pos = fl.props.position
                    if not pos then return end

                    fl.props.position = util.vector2(0, pos.y - 24)
                    params.updateFunc()
                end
            },
        },
    }

    return contentData
end