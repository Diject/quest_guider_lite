local ui = require('openmw.ui')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local templates = require('openmw.interfaces').MWUI.templates

local config = require("scripts.quest_guider_lite.config")

local tableLib = require("scripts.quest_guider_lite.utils.table")

local button = require("scripts.quest_guider_lite.ui.button")

local iconUp = "textures/omw_menu_scroll_up.dds"
local iconDown = "textures/omw_menu_scroll_down.dds"


---@class questGuider.ui.scrollBox
local scrollBoxMeta = {}
scrollBoxMeta.__index = scrollBoxMeta

scrollBoxMeta.getMainFlex = function (self)
    return self:getLayout().content[1]
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

scrollBoxMeta.clearContent = function (self)
    local mainFlex = self:getMainFlex()
    mainFlex.content = ui.content{}
end


---@class questGuider.ui.scrollBox.params
---@field name string?
---@field size any -- util.vector2
---@field scrollAmount integer?
---@field content any
---@field updateFunc fun()
---@field arrange any?
---@field userData table?


---@param params questGuider.ui.scrollBox.params
return function(params)
    if not params then return end

    ---@class questGuider.ui.scrollBox
    local meta = setmetatable({}, scrollBoxMeta)

    local flex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
            size = params.size,
            position = util.vector2(0, 0),
            arrange = params.arrange,
        },
        content = params.content,
    }

    meta.update = function (self)
        params.updateFunc()
    end

    meta.innnerSize = util.vector2(params.size.x - 8, params.size.y - 8)

    meta.params = params

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
        template = templates.box,
        props = {
            size = params.size,
        },
        name = params.name,
        events = {

        },
        userData = {
            scrollBoxMeta = meta,
        },
        content = ui.content {
            flex,
            button{
                position = util.vector2(params.size.x - 4, 4),
                anchor = util.vector2(1, 0),
                icon = iconUp,
                iconSize = util.vector2(config.data.ui.scrollArrowSize, config.data.ui.scrollArrowSize),
                updateFunc = params.updateFunc,
                event = function (layout)
                    if not lockEvent then
                        meta:scrollUp(meta.params.scrollAmount or 24)
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
                iconSize = util.vector2(config.data.ui.scrollArrowSize, config.data.ui.scrollArrowSize),
                updateFunc = params.updateFunc,
                event = function (layout)
                    if not lockEvent then
                        meta:scrollDown(meta.params.scrollAmount or 24)
                    end
                end,
                mousePress = function (layout)
                    startScrollTimer(1, meta.params.scrollAmount / 2 or 12)
                end,
                mouseRelease = function (layout)
                    stopScrollTimer()
                end
            },
        },
    }

    if params.userData then
        tableLib.copy(params.userData, contentData.userData)
    end

    meta.getLayout = function (self)
        return contentData
    end

    return contentData
end