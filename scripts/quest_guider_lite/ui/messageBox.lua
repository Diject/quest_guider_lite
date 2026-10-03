local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local I = require("openmw.interfaces")

local customTemplates = require("scripts.quest_guider_lite.ui.templates")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local commonData = require("scripts.quest_guider_lite.common")

local menuHandler = require("scripts.quest_guider_lite.menuHandler")
local menuMode = require("scripts.quest_guider_lite.ui.menuMode")
local keyModule = require("scripts.quest_guider_lite.input.keys")
local realTimer = require("scripts.quest_guider_lite.realTimer")

local config = require("scripts.quest_guider_lite.configLib")

local borders = require("scripts.quest_guider_lite.ui.borders").thick
local button = require("scripts.quest_guider_lite.ui.button")
local interval = require("scripts.quest_guider_lite.ui.interval")

local l10n = core.l10n(commonData.l10nKey)



local this = {}


---@class UI.messageBox.newSimple.params
---@field menuId string?
---@field fontSize number?
---@field relativeSize {x : number, y : number}?
---@field size {x : number, y : number}?
---@field relativePosition {x : number, y : number}?
---@field message string?
---@field yesCallback function?
---@field noCallback function?
---@field btn3Name string?
---@field btn3Callback function?
---@field onClose function?



---@param params UI.messageBox.newSimple.params
function this.newSimple(params)
    if not params then params = {} end

    local screenSize = uiUtils.getScaledScreenSize()

    params.fontSize = params.fontSize or 18

    if params.relativeSize then
        params.size = params.size or util.vector2(screenSize.x * params.relativeSize.x, screenSize.y * params.relativeSize.y)
    end
    params.size = params.size or util.vector2(300, 200)
    if params.size.x < 400 or params.size.x < 250 then
        params.size = util.vector2(math.max(300, params.size.x), math.max(200, params.size.y))
    end

    if not params.relativePosition then
        params.relativePosition = util.vector2((screenSize.x - params.size.x) / 2 / screenSize.x, (screenSize.y - params.size.y) / 2 / screenSize.y)
    end
    params.message = params.message or ""

    params.menuId = params.menuId or commonData.messageBoxMenuId

    ---@class UI.messageBox.simple.meta
    local meta = setmetatable({}, {})

    meta.params = params
    meta.update = function ()
        meta.menu:update()
    end

    local function yesCallback()
        meta:close()
        if params.yesCallback then params.yesCallback() end
    end
    local function noCallback()
        meta:close()
        if params.noCallback then params.noCallback() end
    end
    local function btn3Callback()
        meta:close()
        if params.btn3Callback then params.btn3Callback() end
    end

    function meta:close()
        I.DijectKeyBindings.keybind.unregister("C_Y", yesCallback, -100)
        I.DijectKeyBindings.keybind.unregister("C_X", noCallback, -100)
        I.DijectKeyBindings.keybind.unregister("C_A", btn3Callback, -100)
        if params.onClose then params.onClose() end
        if not self.menu or not self.menu.layout then return end
        self.menu:destroy()
        menuHandler.unregisterMenu(params.menuId)
    end

    local headerSize = util.vector2(params.size.x, params.fontSize)


    local mainSize = util.vector2(params.size.x, params.size.y - headerSize.y)

    local buttons = {}
    table.insert(buttons, button{
        updateFunc = meta.update,
        textSize = params.fontSize,
        text = keyModule.isGamepad and l10n("YesY") or core.getGMST("sYes"),
        event = yesCallback,
    })
    table.insert(buttons, interval(params.fontSize * 2, 0))
    table.insert(buttons, button{
        updateFunc = meta.update,
        textSize = params.fontSize,
        text = keyModule.isGamepad and l10n("NoX") or core.getGMST("sNo"),
        event = noCallback
    })
    if params.btn3Name then
        table.insert(buttons, interval(params.fontSize * 2, 0))
        table.insert(buttons, button{
            updateFunc = meta.update,
            textSize = params.fontSize,
            text = params.btn3Name,
            event = btn3Callback,
        })
    end

    local mainLayout
    mainLayout = {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.TextEdit,
                props = {
                    text = params.message,
                    textSize = params.fontSize,
                    multiline = true,
                    wordWrap = true,
                    readOnly = true,
                    autoSize = true,
                    size = util.vector2(mainSize.x, 0),
                    anchor = util.vector2(0.5, 0),
                    textColor = config.data.ui.defaultColor,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    horizontal = true,
                    anchor = util.vector2(0.5, 0),
                    position = util.vector2(mainSize.x / 2, mainSize.y - params.fontSize * 0.5),
                    size = util.vector2(mainSize.x, params.fontSize * 2),
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(buttons)
            },
        },
    }


    local layout = {
        template = customTemplates.boxSolidThick,
        layer = commonData.messageLayer,
        props = {
            size = params.size,
            relativePosition = params.relativePosition,
        },
        userData = {
            meta = meta,
        },
        content = ui.content {
            mainLayout,
        }
    }


    meta.menu = ui.create(layout)

    I.DijectKeyBindings.keybind.register("C_Y", yesCallback, -100)
    I.DijectKeyBindings.keybind.register("C_X", noCallback, -100)
    I.DijectKeyBindings.keybind.register("C_A", btn3Callback, -100)

    local function autoClose()
        if not meta.menu or not meta.menu.layout then return end

        if not menuMode.isMenuInteractive() then
            meta:close()
        else
            realTimer.newTimer(0.2, autoClose)
        end
    end
    realTimer.newTimer(0.2, autoClose)

    return meta
end


return this