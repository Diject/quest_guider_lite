local util = require("openmw.util")
local ui = require("openmw.ui")
local vfs = require("openmw.vfs")
local core = require("openmw.core")

local commonData = require("scripts.quest_guider_lite.common")
local config = require("scripts.quest_guider_lite.config")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local keyModule = require("scripts.quest_guider_lite.input.keys")
local realTimer = require("scripts.quest_guider_lite.realTimer")

local interval = require('scripts.quest_guider_lite.ui.interval')

local l10n = core.l10n(commonData.l10nKey)

local fontSize = 18
local imageSize = 24

local this = {}

this.menus = {}
this.currentType = nil

local function addPlus(tb)
    table.insert(tb, {
        type = ui.TYPE.Text,
        props = {
            text = l10n("+"),
            autoSize = true,
            textSize = 16,
            textColor = config.data.ui.defaultColor,
            anchor = util.vector2(0.5, 0.5),
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
    })
end

local function addBtnInfoLay(tb, keyCombs, str, withoutPlus)
    local isValid = false
    for _, keyComb in pairs(keyCombs) do
        if keyModule.isKeyValidToShow(keyComb) then
            isValid = true
            break
        end
    end
    if not isValid then return end

    local btnsContent = {}

    for i, keyComb in ipairs(keyCombs) do
        local keys = keyModule.splitKeyCombinationSorted(keyComb)
        if keys then
            if next(btnsContent) then
                table.insert(btnsContent, interval(4, 0))
            end

            for j, key in ipairs(keys) do
                local image = keyModule.keyImage[key]
                local imOffest = keyModule.keyTextureOffset[key]
                local imSize = keyModule.keyTextureSize[key]

                if image and vfs.fileExists(image) then
                    if j > 1 then addPlus(btnsContent) end

                    table.insert(btnsContent, {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture{ path = image, offset = imOffest, size = imSize },
                            color = config.data.ui.defaultColor,
                            size = (imSize and (imSize / math.max(imSize.x, imSize.y)) or util.vector2(1, 1)) * imageSize,
                            anchor = util.vector2(0.5, 0.5),
                        },
                    })

                else
                    local name = keyModule.keyCombinationToString(key)
                    if j > 1 then addPlus(btnsContent) end

                    table.insert(btnsContent, {
                        type = ui.TYPE.Text,
                        props = {
                            text = "["..name.."]",
                            autoSize = true,
                            textSize = 16,
                            textColor = config.data.ui.defaultColor,
                            anchor = util.vector2(0.5, 0.5),
                        },
                    })
                end
            end
        end
    end

    if #btnsContent == 0 then return end

    local lay = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content{
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    anchor = util.vector2(0.5, 0.5),
                },
                content = ui.content(btnsContent)
            },
            interval(4, 0),
            {
                type = ui.TYPE.Text,
                props = {
                    text = str,
                    autoSize = true,
                    textSize = fontSize,
                    textColor = config.data.ui.defaultColor,
                    multiline = true,
                    wordWrap = false,
                    textAlignH = ui.ALIGNMENT.Start,
                    textAlignV = ui.ALIGNMENT.Center,
                    anchor = util.vector2(0.5, 0.5),
                },
            }
        }
    }

    if next(tb) then table.insert(tb, interval(10, 0)) end
    table.insert(tb, lay)
end


function this.create(contentTable, group)
    this.destroy(group)

    local layout = {
        layer = ui.layers.indexOf("ControllerButtons") and "ControllerButtons" or commonData.messageLayer,
        name = commonData.gamepadInfoMenuId,
        props = {
            anchor = util.vector2(0.5, 1),
            relativePosition = util.vector2(0.5, 1),
            relativeSize = util.vector2(1, 0),
            size = util.vector2(0, math.max(48, config.data.ui.fontSize * 2)),
            alpha = 0,
        },
        content = ui.content{
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                    anchor = util.vector2(0.5, 0.5),
                    relativePosition = util.vector2(0.5, 0.5),
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(contentTable),
            }
        }
    }

    local menu = ui.create(layout)
    this.menus[group] = menu

    local function alphaTimer()
        if not menu.layout then return end

        layout.props.alpha = math.min(1, layout.props.alpha + core.getRealFrameDuration() * 3)
        menu:update()
        if layout.props.alpha ~= 1 then
            realTimer.newTimer(0, alphaTimer)
        end
    end
    realTimer.newTimer(0, alphaTimer)
end


function this.destroy(tp)
    if tp and not this.menus[tp] then return end

    if tp then
        local menu = this.menus[tp]
        if menu and menu.layout then
            menu:destroy()
            this.menus[tp] = nil
        end
    else
        for t, menu in pairs(this.menus) do
            if menu.layout then
                menu:destroy()
            end
            this.menus[t] = nil
        end
    end
end


function this.createJournalMenuHotkeyInfo(allQuestsMode)
    if allQuestsMode then
        this.destroyAllQuestsInfo()
    else
        this.destroyJournalInfo()
    end
    if not keyModule.isGamepad then return end

    local keyConfig = config.data.input.keys

    local contentTable = {}
    local count = 0

    if keyModule.isKeyValidToShow(keyConfig.nextQuest) and keyModule.isKeyValidToShow(keyConfig.previousQuest) then
        addBtnInfoLay(contentTable, keyModule.getDpadBtnCombo(keyConfig.previousQuest, keyConfig.nextQuest), l10n("GamepadActionSelect"))
        count = count + 1
    end

    if keyModule.isGamepad and config.data.input.gamepadJournalScroll then
        addBtnInfoLay(contentTable, {"C_LT", "C_RT"}, l10n("Scroll"))
        count = count + 1
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_RSTICK"}, l10n("GamepadActionCursorScroll"))
        count = count + 1
    end

    if keyModule.isKeyValidToShow(keyConfig.toggleTrackObjects) then
        addBtnInfoLay(contentTable, {keyConfig.toggleTrackObjects}, l10n("GamepadActionTrackObjects"))
        count = count + 1
    end

    if keyModule.isKeyValidToShow(keyConfig.toggleTopTopics) then
        addBtnInfoLay(contentTable, {keyConfig.toggleTopTopics}, l10n("GamepadActionEntryTopics"))
        count = count + 1
    end

    if keyModule.isKeyValidToShow(keyConfig.toggleTracking) then
        addBtnInfoLay(contentTable, {keyConfig.toggleTracking}, l10n("GamepadActionTrackingInfo"))
        count = count + 1
    end

    if keyModule.isKeyValidToShow(keyConfig.toggleQuestHidden) then
        addBtnInfoLay(contentTable, {keyConfig.toggleQuestHidden}, l10n("GamepadActionHideShow"))
        count = count + 1
    end

    if not allQuestsMode then
        if keyModule.isKeyValidToShow(keyConfig.toggleQuestPinned) then
            addBtnInfoLay(contentTable, {keyConfig.toggleQuestPinned}, l10n("GamepadActionPinUnpin"))
            count = count + 1
        end
    end

    if allQuestsMode then
        if keyModule.isKeyValidToShow(keyConfig.toggleStartedHidden) then
            addBtnInfoLay(contentTable, {keyConfig.toggleStartedHidden}, l10n("GamepadActionStartedHidden"))
            count = count + 1
        end
    else
        if keyModule.isKeyValidToShow(keyConfig.toggleFinishedHidden) then
            addBtnInfoLay(contentTable, {keyConfig.toggleFinishedHidden}, l10n("GamepadActionFinishedHidden"))
            count = count + 1
        end
    end

    if allQuestsMode then
        if keyModule.isKeyValidToShow(keyConfig.toggleNearby) then
            addBtnInfoLay(contentTable, {keyConfig.toggleNearby}, l10n("GamepadActionNearbyCheckbox"))
            count = count + 1
        end
        if keyModule.isKeyValidToShow(keyConfig.toggleAllEntries) then
            addBtnInfoLay(contentTable, {keyConfig.toggleAllEntries}, l10n("GamepadActionAllEntriesCheckbox"))
            count = count + 1
        end
    end

    if allQuestsMode then
        if keyModule.isKeyValidToShow(keyConfig.nearbyMenuLocal) then
            addBtnInfoLay(contentTable, {keyConfig.nearbyMenuLocal}, l10n("GamepadActionJournalMenu"))
            count = count + 1
        end
    else
        if keyModule.isKeyValidToShow(keyConfig.nearbyMenuLocal) then
            addBtnInfoLay(contentTable, {keyConfig.nearbyMenuLocal}, l10n("GamepadActionNearbyMenu"))
            count = count + 1
        end
    end

    if keyModule.isKeyValidToShow(keyConfig.topicMenuLocal) then
        addBtnInfoLay(contentTable, {keyConfig.topicMenuLocal}, l10n("GamepadActionTopicsMenu"))
        count = count + 1
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_B"}, l10n("GamepadActionClose"))
    end

    if count <= 2 then return end

    this.create(contentTable, allQuestsMode and "allQuests" or "main")
end

function this.destroyJournalInfo()
    this.destroy("main")
end

function this.destroyAllQuestsInfo()
    this.destroy("allQuests")
end


function this.createTopicsMenuHotkeyInfo()
    if not keyModule.isGamepad then return end
    local keyConfig = config.data.input.keys
    local contentTable = {}
    local count = 0

    if keyModule.isKeyValidToShow(keyConfig.nextQuest) and keyModule.isKeyValidToShow(keyConfig.previousQuest) then
        addBtnInfoLay(contentTable, keyModule.getDpadBtnCombo(keyConfig.nextQuest, keyConfig.previousQuest), l10n("GamepadActionSelect"))
        count = count + 1
    end

    if keyModule.isGamepad and config.data.input.gamepadJournalScroll then
        addBtnInfoLay(contentTable, {"C_LT", "C_RT"}, l10n("GamepadActionScroll"))
        count = count + 1
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_RSTICK"}, l10n("GamepadActionCursorScroll"))
        count = count + 1
    end

    if keyModule.isKeyValidToShow(keyConfig.toggleTopTopics) then
        addBtnInfoLay(contentTable, {keyConfig.toggleTopTopics}, l10n("GamepadActionMore"))
        count = count + 1
    end

    if keyModule.isKeyValidToShow(keyConfig.toggleAlphabetical) then
        addBtnInfoLay(contentTable, {keyConfig.toggleAlphabetical}, l10n("GamepadActionAlphabetical"))
        count = count + 1
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_B"}, l10n("GamepadActionClose"))
    end

    if count <= 1 then return end

    this.create(contentTable, "topics")
end

function this.destroyTopicsInfo()
    this.destroy("topics")
end


function this.createFirstInitMenuHotkeyInfo()
    if not keyModule.isGamepad then return end
    local keyConfig = config.data.input.keys
    local contentTable = {}
    local count = 0

    if keyModule.isGamepad and config.data.input.gamepadJournalScroll then
        addBtnInfoLay(contentTable, {"C_LT", "C_RT"}, l10n("GamepadActionScroll"))
        count = count + 1
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_RSTICK"}, l10n("GamepadActionCursorScroll"))
        count = count + 1
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_Y"}, core.getGMST("sOk"))
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_X"}, l10n("GamepadActionRecreateMarkers"))
    end

    if keyModule.isGamepad then
        addBtnInfoLay(contentTable, {"C_B"}, l10n("GamepadActionClose"))
    end

    if count <= 1 then return end

    this.create(contentTable, "fInit")
end

function this.destroyFirstInitInfo()
    this.destroy("fInit")
end


return this