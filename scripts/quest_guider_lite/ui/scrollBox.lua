local ui = require('openmw.ui')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local templates = require('openmw.interfaces').MWUI.templates

local button = require("scripts.quest_guider_lite.ui.button")

local iconUp = "textures/omw_menu_scroll_up.dds"
local iconDown = "textures/omw_menu_scroll_down.dds"


---@class questGuider.ui.scrollBox
local scrollBoxMeta = {}
scrollBoxMeta.__index = scrollBoxMeta

scrollBoxMeta.getMainFlex = function (self)
    return self:thisElementInContent().content[1].content[1].content[1]
end

scrollBoxMeta.scrollUp = function(self, val)
    local fl = self:getMainFlex()
    local pos = fl.props.position
    if not pos then return end

    fl.props.position = util.vector2(0, math.min(32, pos.y + val))
    self:update()
end

scrollBoxMeta.scrollDown = function(self, val)
    local fl = self:getMainFlex()
    local pos = fl.props.position
    if not pos then return end

    fl.props.position = util.vector2(0, pos.y - val)
    self:update()
end


---@class questGuider.ui.scrollBox.params
---@field size any -- util.vector2
---@field content any
---@field updateFunc fun()
---@field thisElementInContent fun() : any
---@field arrange any?


---@param params questGuider.ui.scrollBox.params
return function(params)
    if not params then return end

    ---@class questGuider.ui.scrollBox
    local meta = setmetatable({}, scrollBoxMeta)

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
                            arrange = params.arrange,
                        },
                        content = params.content,
                    }
                },
            }
        }
    }

    meta.update = function (self)
        params.updateFunc()
    end

    meta.thisElementInContent = function (self)
        return params.thisElementInContent()
    end

    local lockEvent = false
    local timer
    local function stopScrollTimer()
        if timer then
            timer()
            timer = nil
            lockEvent = false
        end
    end

    local function startScrollTimer(type, value)
        stopScrollTimer()
        -- TODO implement real timer
        -- timer = time.runRepeatedly(function ()
        --     if type == 0 then
        --         scrollUp(value)
        --     else
        --         scrollDown(value)
        --     end
        --     lockEvent = true
        -- end, time.second * 0.5, { initialDelay = 1 * time.second })
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
            meta = meta,
        },
        content = ui.content {
            flex,
            button{
                position = util.vector2(params.size.x - 4, 4),
                anchor = util.vector2(1, 0),
                icon = iconUp,
                iconSize = util.vector2(16, 16),
                updateFunc = params.updateFunc,
                event = function (layout)
                    if not lockEvent then
                        meta:scrollUp(24)
                    end
                end,
                mousePress = function (layout)
                    startScrollTimer(0, 12)
                end,
                mouseRelease = function (layout)
                    stopScrollTimer()
                end
            },
            button{
                position = util.vector2(params.size.x - 4, params.size.y - 4),
                anchor = util.vector2(1, 1),
                icon = iconDown,
                iconSize = util.vector2(16, 16),
                updateFunc = params.updateFunc,
                event = function (layout)
                    if not lockEvent then
                        meta:scrollDown(24)
                    end
                end,
                mousePress = function (layout)
                    startScrollTimer(1, 12)
                end,
                mouseRelease = function (layout)
                    stopScrollTimer()
                end
            },
        },
    }

    return contentData
end