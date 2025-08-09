local ui = require('openmw.ui')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local I = require('openmw.interfaces')
local templates = require('openmw.interfaces').MWUI.templates
local async = require('openmw.async')

local realTimer = require("scripts.quest_guider_lite.realTimer")

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

    fl.props.position = util.vector2(0, math.min(self.params.maxNegativeShift or (config.data.ui.scrollArrowSize * 2) or 32, pos.y + val))
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
---@field maxNegativeShift integer?
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

    meta.innnerSize = util.vector2(params.size.x - 4, params.size.y - 4)

    meta.params = params

    local lockEvent = false
    local timer
    local function stopScrollTimer()
        if timer then
            timer()
            timer = nil
        end
    end

    local function startScrollTimer(type, value)
        stopScrollTimer()

        local func
        func = function ()
            if type == 0 then
                meta:scrollUp(value)
            else
                meta:scrollDown(value)
            end
            lockEvent = true
            timer = realTimer.newTimer(0.2, func)
        end
        timer = realTimer.newTimer(1, func)
    end

    local contentData
    contentData = {
        template = templates.box,
        props = {
            autoSize = false,
            size = params.size,
        },
        name = params.name,
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.lastMousePos = util.vector2(coord.position.x, coord.position.y)
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
            end),

            focusLoss = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.lastMousePos then return end

                local posDIff = coord.position - layout.userData.lastMousePos

                if posDIff.y > 0 then
                    meta:scrollUp(posDIff.y)
                elseif posDIff.y < 0 then
                    meta:scrollDown(-posDIff.y)
                end

                layout.userData.lastMousePos = coord.position
            end),
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
                    lockEvent = false
                    startScrollTimer(0, meta.params.scrollAmount / 5 or 12)
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
                    lockEvent = false
                    startScrollTimer(1, meta.params.scrollAmount / 5 or 12)
                end,
                mouseRelease = function (layout)
                    stopScrollTimer()
                end
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    autoSize = false,
                    size = util.vector2(1, 1),
                    anchor = util.vector2(1, 1),
                    position = util.vector2(params.size.x, params.size.y),
                    visible = false,
                },
                content = ui.content{},
            }
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