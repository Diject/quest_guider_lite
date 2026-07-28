local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local I = require("openmw.interfaces")

local customTemplates = require("scripts.quest_guider_lite.ui.templates")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local commonData = require("scripts.quest_guider_lite.common")
local config = require("scripts.quest_guider_lite.configLib")
local tracking = require("scripts.quest_guider_lite.trackingLocal")

local menuHandler = require("scripts.quest_guider_lite.menuHandler")

local templates = require("scripts.quest_guider_lite.ui.templates")
local borders = require("scripts.quest_guider_lite.ui.borders")
local button = require("scripts.quest_guider_lite.ui.button")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")
local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")


local l10n = core.l10n(commonData.l10nKey)


local this = {}

---@class questGuider.ui.firstInitMenu.params
---@field size any?
---@field relativePosition any?
---@field fontSize number?
---@field yesCallback fun()?


---@param params questGuider.ui.firstInitMenu.params
---@return questGuider.ui.firstInitMenu
function this.new(params)
    ---@class questGuider.ui.firstInitMenu.params
    params = params or {}

    params.menuId = params.menuId or commonData.firstInitMenuId

    local screenSize = uiUtils.getScaledScreenSize()

    params.fontSize = params.fontSize or config.data.ui.fontSize

    params.size = params.size or util.vector2(screenSize.x * 0.6, screenSize.y * 0.7)
    params.relativePosition = util.vector2(0.5, 0.5)

    local xLimit = math.floor(screenSize.x * 0.4)
    local imLimit = math.floor(math.min(screenSize.x * 0.2, params.fontSize * 12))

    local previewImageSize = util.vector2(imLimit, imLimit * 0.5)


    ---@class questGuider.ui.firstInitMenu
    local meta = setmetatable({}, {})

    meta.params = params
    meta.update = function ()
        meta.menu:update()
    end

    function meta:close()
        if not self.menu then return end
        I.DijectKeyBindings.keybind.unregister("C_Y", meta.btnFunction)
        I.DijectKeyBindings.keybind.unregister("Enter", meta.btnFunction)
        I.DijectKeyBindings.keybind.unregister("C_X", meta.btnRecreateFunction)
        I.DijectKeyBindings.keybind.unregister("X", meta.btnRecreateFunction)
        self.menu:destroy()
        menuHandler.unregisterMenu(params.menuId)
    end


    local sbSize = util.vector2(params.size.x, params.size.y - params.fontSize * 2)
    ---@type questGuider.ui.scrollBox
    local sBoxMeta

    local function insertLabelToContent(headetText)
        return {
            type = ui.TYPE.Text,
            props = {
                text = headetText,
                textSize = params.fontSize,
                autoSize = false,
                size = util.vector2(xLimit, params.fontSize * 4),
                textColor = config.data.ui.defaultColor,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.End,
            },
        }
    end

    local function insertCBToContent(configTable, configTableName)
        return {
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
            },
            content = ui.content{
                checkBox{
                    updateFunc = meta.update,
                    text = l10n("firstInitGivers"),
                    textSize = params.fontSize,
                    getScrollBoxMeta = function() return sBoxMeta end,
                    checked = configTable.details.givers,
                    event = function (checked, layout)
                        config.setValue(configTableName..".details", {markers = configTable.details.markers, givers = checked})
                        if not checked and not configTable.details.markers then
                            config.setValue(configTableName..".enabled", checked)
                        end
                        if checked and not configTable.enabled then
                            config.setValue(configTableName..".enabled", checked)
                        end
                    end
                },
                interval(0, params.fontSize / 4),
                checkBox{
                    updateFunc = meta.update,
                    text = l10n("firstInitObjects"),
                    textSize = params.fontSize,
                    getScrollBoxMeta = function() return sBoxMeta end,
                    checked = configTable.details.markers,
                    event = function (checked, layout)
                        config.setValue(configTableName..".details", {markers = checked, givers = configTable.details.givers})
                        if not checked and not configTable.details.givers then
                            config.setValue(configTableName..".enabled", checked)
                        end
                        if checked and not configTable.enabled then
                            config.setValue(configTableName..".enabled", checked)
                        end
                    end
                }
            }
        }
    end


    local sbContent
    sbContent = ui.content {
        {
            type = ui.TYPE.Text,
            props = {
                text = l10n("firstInitQuestDataFound"),
                textSize = math.floor(params.fontSize * 1.2),
                autoSize = false,
                size = util.vector2(sbSize.x - params.fontSize, params.fontSize * 4),
                textColor = config.data.ui.defaultColor,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
            },
        },
        interval(0, params.fontSize * 0.25),
        customTemplates.fullHorizontalLineThin,
        interval(0, params.fontSize * 0.25),
        checkBox{
            updateFunc = meta.update,
            text = l10n("firstInitDisableAutoTracking"),
            textSize = params.fontSize,
            textElementSize = util.vector2(sbSize.x - params.fontSize, params.fontSize * 2),
            getScrollBoxMeta = function() return sBoxMeta end,
            checked = not config.data.tracking.autoTrack,
            event = function (checked, layout)
                config.setValue("tracking.autoTrack", not checked)
            end
        },
        interval(0, params.fontSize * 0.25),
        customTemplates.fullHorizontalLineThin,
        interval(0, params.fontSize * 0.25),
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Start,
            },
            content = ui.content{
                {
                    type = ui.TYPE.Flex,
                    content = ui.content{
                        checkBox{
                            updateFunc = meta.update,
                            text = l10n("useColoredMarkersDescriptionInitMenu"),
                            textSize = params.fontSize,
                            textElementSize = util.vector2(xLimit, params.fontSize * 2),
                            getScrollBoxMeta = function() return sBoxMeta end,
                            checked = config.data.tracking.colored,
                            event = function (checked, layout)
                                config.setValue("tracking.colored", checked)
                            end
                        },
                    }
                },
                {
                    props = {
                        size = previewImageSize,
                    },
                    content = ui.content{
                        {
                            type = ui.TYPE.Image,
                            props = {
                                resource = ui.texture{ path = commonData.initMenuColoredMarkersImagePath },
                                size = previewImageSize,
                            },
                        },
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = l10n("On"),
                                textSize = params.fontSize * 1.5,
                                textColor = config.data.ui.defaultColor,
                                textShadow = true,
                                textShadowColor = config.data.ui.shadowColor,
                            }
                        },
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = l10n("Off"),
                                position = util.vector2(previewImageSize.x * 0.5, 0),
                                textSize = params.fontSize * 1.5,
                                textColor = config.data.ui.defaultColor,
                                textShadow = true,
                                textShadowColor = config.data.ui.shadowColor,
                            }
                        }
                    }
                }
            }
        },
        interval(0, params.fontSize * 0.25),
        customTemplates.fullHorizontalLineThin,
        interval(0, params.fontSize * 0.25),
        {
            type = ui.TYPE.Text,
            props = {
                text = l10n("firstInitNote0"),
                textSize = params.fontSize,
                autoSize = false,
                size = util.vector2(sbSize.x - params.fontSize, params.fontSize * 7),
                textColor = config.data.ui.defaultColor,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
            },
        },
        interval(0, params.fontSize * 0.25),
        customTemplates.fullHorizontalLineThin,
        interval(0, params.fontSize * 0.25),
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.End,
            },
            content = ui.content{
                {
                    type = ui.TYPE.Flex,
                    props = {
                        anchor = util.vector2(0, 1),
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content{
                        insertLabelToContent(l10n("firstInitMapMarkersCategory")),
                        interval(0, params.fontSize / 2),
                        insertCBToContent(config.data.tracking.advWMapMarkers, "tracking.advWMapMarkers"),
                    }
                },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture{ path = commonData.initMenuMapMarkersImagePath },
                        size = previewImageSize,
                        anchor = util.vector2(0, 1)
                    },
                }
            }
        },
        interval(0, params.fontSize * 0.5),
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.End,
            },
            content = ui.content{
                {
                    type = ui.TYPE.Flex,
                    props = {
                        anchor = util.vector2(0, 1),
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content{
                        insertLabelToContent(l10n("firstInitProximityMarkersCategory")),
                        interval(0, params.fontSize / 2),
                        insertCBToContent(config.data.tracking.proximityMarkers, "tracking.proximityMarkers"),
                    }
                },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture{ path = commonData.initMenuProximityMarkersImagePath },
                        size = previewImageSize,
                        anchor = util.vector2(0, 1)
                    },
                }
            }
        },
        interval(0, params.fontSize * 0.5),
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.End,
            },
            content = ui.content{
                {
                    type = ui.TYPE.Flex,
                    props = {
                        anchor = util.vector2(0, 1),
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content{
                        insertLabelToContent(l10n("firstInitHUDMarkersCategory")),
                        interval(0, params.fontSize / 2),
                        insertCBToContent(config.data.tracking.hudMarkers, "tracking.hudMarkers"),
                    }
                },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture{ path = commonData.initMenuHudMarkersImagePath },
                        size = previewImageSize,
                        anchor = util.vector2(0, 1)
                    },
                }
            }
        },
        interval(0, params.fontSize * 0.25),
        customTemplates.fullHorizontalLineThin,
        interval(0, params.fontSize * 0.5),
        {
            type = ui.TYPE.Text,
            props = {
                text = l10n("firstInitNote1"),
                textSize = params.fontSize,
                autoSize = false,
                size = util.vector2(sbSize.x - params.fontSize, params.fontSize * 5),
                textColor = config.data.ui.defaultColor,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
            },
        },
        interval(0, params.fontSize * 0.5),
        customTemplates.fullHorizontalLineThin,
    }

    local contentSB = scrollBox{
        updateFunc = meta.update,
        size = sbSize,
        scrollAmount = sbSize.y / 5,
        withoutBorders = true,
        contentHeight = 0,
        autoOptimize = true,
        content = sbContent
    }

    ---@type questGuider.ui.scrollBox
    sBoxMeta = contentSB.userData.scrollBoxMeta ---@diagnostic disable-line: need-check-nil

    local layout = {
        type = ui.TYPE.Widget,
        props = {
            size = params.size,
        },
        userData = {
            meta = meta,
        },
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.lastMousePos then return end

                local props = meta.menu.layout.props
                local relativePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)

                props.relativePosition = props.relativePosition - (layout.userData.lastMousePos - relativePos)
                meta:update()

                layout.userData.lastMousePos = relativePos
            end),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                }
            },
            contentSB,
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    horizontal = true,
                    anchor = util.vector2(0.5, 0.5),
                    size = util.vector2(params.size.x, params.fontSize * 2),
                    position = util.vector2(params.size.x / 2, params.size.y - params.fontSize),
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    button{
                        updateFunc = meta.update,
                        textSize = params.fontSize,
                        text = l10n("firstInitBtn"),
                        event = function ()
                            meta.btnFunction()
                        end
                    },
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = "    "..l10n("or").."    ",
                            textSize = params.fontSize,
                            textColor = config.data.ui.defaultColor,
                        },
                    },
                    button{
                        updateFunc = meta.update,
                        textSize = params.fontSize,
                        text = l10n("firstInitRecreateMarkersBtn"),
                        event = function ()
                            meta.btnRecreateFunction()
                        end
                    },
                }
            },
        }
    }

    local layoutWithBorders = {
        template = templates.boxSolidThick,
        layer = commonData.messageLayer,
        props = {
            size = params.size,
            anchor = util.vector2(0.5, 0.5),
            relativePosition = params.relativePosition,
        },
        content = ui.content {
            layout
        }
    }

    meta.menu = ui.create(layoutWithBorders)
    sBoxMeta:setScrollPosition(0)

    local function onMouseWheelCallback(content, value)
        for _, dt in pairs(content) do
            if not type(dt) == "table" then goto continue end
            if dt.userData and dt.userData.onMouseWheel then
                dt.userData.onMouseWheel(value)
            end

            if dt.content then
                onMouseWheelCallback(dt.content, value)
            end

            ::continue::
        end
    end

    meta.onMouseWheel = function (self, vertical)
        local layout = meta.menu.layout
        onMouseWheelCallback(layout.content, vertical)
    end

    meta.scrollInfo = function (self, value)
        sBoxMeta:setScrollPosition(sBoxMeta:getScrollPosition() + value * (self.params.fontSize or 18) * 3)
    end

    meta.btnFunction = function ()
        if params.yesCallback then params.yesCallback() end
        meta:close()
    end

    meta.btnRecreateFunction = function ()
        tracking:recreateMarkers()
        meta.btnFunction()
    end

    I.DijectKeyBindings.keybind.register("C_Y", meta.btnFunction)
    I.DijectKeyBindings.keybind.register("C_X", meta.btnRecreateFunction)
    I.DijectKeyBindings.keybind.register("X", meta.btnRecreateFunction)
    I.DijectKeyBindings.keybind.register("Enter", meta.btnFunction)

    config.setValue("journal.firstInitMenu", false)

    return meta
end


return this