local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")

local config = require("scripts.quest_guider_lite.config")
local commonData = require("scripts.quest_guider_lite.common")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local menuMode = require("scripts.quest_guider_lite.ui.menuMode")
local menuHandler = require("scripts.quest_guider_lite.menuHandler")
local templates = require("scripts.quest_guider_lite.ui.templates")
local realTimer = require("scripts.quest_guider_lite.realTimer")

local checkBox = require("scripts.quest_guider_lite.ui.checkBox")

local this = {}

this.menu = nil
this.inFocus = nil
this.timer = nil

---@class questGuider.ui.contextMenu.create.params.element
---@field type integer? -- 0: separator, 1: text, 2: button, 3: checkbox
---@field text string?
---@field data any?
---@field fontSize number?
---@field callback fun(data: any, layout: any)?

---@class questGuider.ui.contextMenu.create.params
---@field position any
---@field fontSize number
---@field elements questGuider.ui.contextMenu.create.params.element[]


---@param params questGuider.ui.contextMenu.create.params
---@return number
function this.create(params)
    this.destroy()

    local id = core.getRealTime()

    local screenSize = uiUtils.getScaledScreenSize()
    local anchor = (screenSize.x - params.position.x) < screenSize.x * 0.75 and util.vector2(1, 0) or nil

    local layout = {
        layer = commonData.messageLayer,
        template = templates.boxSolid,
        props = {
            alpha = 1,
            anchor = anchor,
        },
        userData = {
            id = id,
        },
        events = {
            mouseMove = async:callback(function(coord, layout)
                this.inFocus = true
            end),

            focusLoss = async:callback(function(e, layout)
                this.inFocus = false
            end),
        },
        content = ui.content{
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content{}
            }
        }
    }


    local containerLayout = {
        type = ui.TYPE.Container,
        content = ui.content{
            {
                external = { slot = true },
                props = {
                    relativeSize = util.vector2(1, 1),
                    size = util.vector2(4, 4),
                },
            }
        },
    }

    local height = 4

    for _, data in ipairs(params.elements) do

        if data.type == 0 then
            layout.content[1].content:add{
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture{ path = "textures/menu_thin_border_top.dds" },
                    tileH = true,
                    tileV = false,
                    anchor = util.vector2(0.5, 0.5),
                    size = util.vector2(50, 2),
                },
            }
            goto continue
        end

        local template = {
            type = ui.TYPE.Container,
            content = ui.content{
                {
                    external = { slot = true },
                    props = {
                        relativeSize = util.vector2(1, 1),
                        size = util.vector2(4, 4),
                    },
                    content = ui.content{
                        {
                            type = ui.TYPE.Image,
                            props = {
                                resource = uiUtils.whiteTexture,
                                color = config.data.ui.defaultColor,
                                relativeSize = util.vector2(1, 1),
                                alpha = 0,
                            }
                        },
                    }
                },
            },
        }

        local element
        element = {
            template = template,
            props = {

            },
            events = {
                mouseMove = async:callback(function(coord, layout)
                    template.content[1].content[1].props.alpha = 0.2
                    this.inFocus = true
                    this.menu:update()
                end),

                focusLoss = async:callback(function(e, layout)
                    template.content[1].content[1].props.alpha = 0
                    this.inFocus = false
                    this.menu:update()
                end),
            },
            content = ui.content{}
        }

        if not data.type or data.type == 2 then
            element.content:add{
                type = ui.TYPE.Text,
                props = {
                    text = data.text or "",
                    textSize = data.fontSize or params.fontSize or config.data.ui.fontSize,
                    textColor = config.data.ui.defaultColor,
                    position = util.vector2(4, 4)
                }
            }
            element.events.mousePress = async:callback(function(e, layout)
                if data.callback then
                    data.callback(nil, element)
                end
            end)

        elseif data.type == 1 then
            element.content:add{
                type = ui.TYPE.Text,
                props = {
                    text = data.text or "",
                    textSize = data.fontSize or params.fontSize or config.data.ui.fontSize,
                    textColor = config.data.ui.defaultColor,
                    position = util.vector2(4, 4)
                }
            }
            element.events = nil

        elseif data.type == 3 then
            local cb = checkBox{
                updateFunc = function ()
                    this.menu:update()
                end,
                checked = data.data,
                text = data.text or "",
                textSize = data.fontSize or params.fontSize or config.data.ui.fontSize,
                visible = true,
                position = util.vector2(4, 4),
                event = data.callback,
            }
            cb.events.focusLoss = element.events.focusLoss
            cb.events.mouseMove = element.events.mouseMove
            element.content:add(cb)
        end

        layout.content[1].content:add(element)
        height = height + 8

        ::continue::
    end

    height = height + uiUtils.getContentHeight(layout.content[1].content)

    layout.props.position = (params.position.y + height > screenSize.y) and util.vector2(params.position.x, screenSize.y - height) or
        params.position

    this.inFocus = nil
    local closeTimestamp = core.getRealTime() + 3

    local func
    func = function ()
        this.timer = realTimer.newTimer(0, function ()
            if not this.menu then return end

            local lastAlpha = layout.props.alpha

            if this.inFocus == nil then
                if core.getRealTime() > closeTimestamp then
                    this.destroy()
                    return
                end
            elseif this.inFocus == false then
                layout.props.alpha = math.max(0, layout.props.alpha - core.getRealFrameDuration())
            else
                layout.props.alpha = math.min(1, layout.props.alpha + core.getRealFrameDuration() * 3)
            end

            if layout.props.alpha <= 0 or not menuMode.isMenuInteractive() or not menuHandler.hasActiveMenus() then
                this.destroy()
                return
            end

            if lastAlpha ~= layout.props.alpha then
                this.menu:update()
            end

            func()
        end)
    end
    func()

    this.menu = ui.create(layout)

    return id
end


function this.destroy()
    if not this.menu then return end

    pcall(function ()
        this.menu:destroy()
    end)
    this.menu = nil

    if this.timer then
        this.timer()
        this.timer = nil
    end
end


---@return number?
function this.getActiveMenuId()
    return this.menu and this.menu.layout and this.menu.layout.userData.id or nil
end


return this