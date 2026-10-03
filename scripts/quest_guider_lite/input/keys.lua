local input = require("openmw.input")
local core = require("openmw.core")
local util = require("openmw.util")

local common = require("scripts.quest_guider_lite.common")
local config = require("scripts.quest_guider_lite.config")

local l10n = core.l10n(common.l10nKey)


local this = {}


this.isGamepad = true


this.keyName = {
    ["LMB"] = l10n("leftMouseButton"),
    ["MMB"] = l10n("middleMouseButton"),
    ["RMB"] = l10n("rightMouseButton"),
    ["MB4"] = l10n("mouseButton4"),
    ["MB5"] = l10n("mouseButton5"),
    ["C_A"] = "A",
    ["C_B"] = "B",
    ["C_X"] = "X",
    ["C_Y"] = "Y",
    ["C_Back"] = "Back",
    ["C_Guide"] = "Guide",
    ["C_Start"] = "Start",
    ["C_LeftStick"] = "L-Stick Btn",
    ["C_RightStick"] = "R-Stick Btn",
    ["C_LeftShoulder"] = "LB",
    ["C_RightShoulder"] = "RB",
    ["C_DPadUp"] = "D-pad Up",
    ["C_DPadDown"] = "D-pad Down",
    ["C_DPadLeft"] = "D-pad Left",
    ["C_DPadRight"] = "D-pad Right",
    ["C_DPAD"] = "D-pad",
    ["C_RT"] = "RT",
    ["C_LT"] = "LT",
    ["C_LSTICK"] = "L-Stick",
    ["C_RSTICK"] = "R-Stick",
}

this.keyImage = {
    ["C_A"] = "textures/omw_steam_button_a.dds",
    ["C_B"] = "textures/omw_steam_button_b.dds",
    ["C_X"] = "textures/omw_steam_button_x.dds",
    ["C_Y"] = "textures/omw_steam_button_y.dds",
    ["C_Back"] = "textures/omw_steam_button_view.dds",
    ["C_Start"] = "textures/omw_steam_button_menu.dds",
    ["C_LeftStick"] = "textures/omw_steam_button_l3.dds",
    ["C_RightStick"] = "textures/omw_steam_button_r3.dds",
    ["C_LeftShoulder"] = "textures/omw_xbox_button_lb.dds",
    ["C_RightShoulder"] = "textures/omw_xbox_button_rb.dds",
    ["C_DPadUp"] = "textures/omw_steam_button_dpad.dds",
    ["C_DPadDown"] = "textures/omw_steam_button_dpad.dds",
    ["C_DPadLeft"] = "textures/omw_steam_button_dpad.dds",
    ["C_DPadRight"] = "textures/omw_steam_button_dpad.dds",

    ["C_DPAD"] = "textures/omw_steam_button_dpad.dds",
    ["C_DPAD_UPDOWN"] = "textures/omw_steam_button_dpad.dds",
    ["C_DPAD_LEFTRIGHT"] = "textures/omw_steam_button_dpad.dds",
    ["C_RT"] = "textures/omw_xbox_button_rt.dds",
    ["C_LT"] = "textures/omw_xbox_button_lt.dds",
    ["C_LSTICK"] = "textures/omw_steam_button_lstick.dds",
    ["C_RSTICK"] = "textures/omw_steam_button_rstick.dds",
}

this.keyTextureOffset = {
    ["C_DPadUp"] = util.vector2(0, 0),
    ["C_DPadDown"] = util.vector2(0, 64),
    ["C_DPadLeft"] = util.vector2(0, 0),
    ["C_DPadRight"] = util.vector2(64, 0),
    ["C_DPAD_UPDOWN"] = util.vector2(32, 0),
    ["C_DPAD_LEFTRIGHT"] = util.vector2(0, 32),
}
this.keyTextureSize = {
    ["C_DPadUp"] = util.vector2(128, 64),
    ["C_DPadDown"] = util.vector2(128, 64),
    ["C_DPadLeft"] = util.vector2(64, 128),
    ["C_DPadRight"] = util.vector2(64, 128),
    ["C_DPAD_UPDOWN"] = util.vector2(64, 128),
    ["C_DPAD_LEFTRIGHT"] = util.vector2(128, 64),
}


local dpadBtns = {
    ["C_DPadUp"] = "C_DPAD_UPDOWN",
    ["C_DPadDown"] = "C_DPAD_UPDOWN",
    ["C_DPadLeft"] = "C_DPAD_LEFTRIGHT",
    ["C_DPadRight"] = "C_DPAD_LEFTRIGHT",
}

---@return string[]
function this.getDpadBtnCombo(btn1, btn2)
    local r1 = dpadBtns[btn1]
    local r2 = dpadBtns[btn2]

    if r1 and r1 == r2 then
        return {r1}
    else
        return {btn1, btn2}
    end
end


function this.splitKeyCombination(comb)
    local keys = {}
    for key in string.gmatch(comb, "[^%s%+]+") do
        table.insert(keys, key)
    end
    return keys
end


local function removeCPrefix(key)
    if key:sub(1, 2) == "C_" then
        return key:sub(3)
    end
    return key
end


function this.splitKeyCombinationSorted(comb)
    if not comb then return end

    local keys = this.splitKeyCombination(comb)
    local keyNameData = {}
    for _, key in ipairs(keys) do
        local id = -1
        local isKey, keyId = pcall(function ()
            return input.KEY[key]
        end)
        if isKey and keyId then
            id = type(keyId) =="number" and keyId or -1
        else
            local nm = removeCPrefix(key)
            local isBtn, cid = pcall(function ()
                return input.CONTROLLER_BUTTON[nm]
            end)
            id = isBtn and type(cid) == "number" and 1000 - cid or -1
        end

        table.insert(keyNameData, {id, key})
    end

    local keyIds = {}
    table.sort(keyNameData, function (a, b)
        return a[1] > b[1]
    end)
    for _, dt in ipairs(keyNameData) do
        table.insert(keyIds, dt[2])
    end

    return keyIds
end


---@param combination string?
---@return string?
function this.keyCombinationToString(combination)
    if not combination then return end

    local keys = this.splitKeyCombination(combination)
    local keyNameData = {}
    for _, key in ipairs(keys) do
        local name
        local id = -1
        local isKey, keyId = pcall(function ()
            return input.KEY[key]
        end)
        if isKey and keyId then
            name = input.getKeyName(keyId)
            id = type(keyId) =="number" and keyId or -1
        else
            name = this.keyName[key]
            local nm = removeCPrefix(key)
            local isBtn, cid = pcall(function ()
                return input.CONTROLLER_BUTTON[nm]
            end)
            id = isBtn and type(cid) == "number" and 1000 - cid or -1
        end
        name = name or key

        table.insert(keyNameData, {id, name})
    end

    local keyNames = {}
    table.sort(keyNameData, function (a, b)
        return a[1] > b[1]
    end)
    for _, dt in ipairs(keyNameData) do
        table.insert(keyNames, dt[2])
    end

    return table.concat(keyNames, " + ")
end


function this.isKeyValidToShow(comb)
    if not comb then return false end
    local hasGamepadKey = comb:find("C_") and true or false
    return this.isGamepad == hasGamepadKey
end


function this.getJournalMenuHotkeyInfoStr(allQuestsMode)
    local out = {}
    local keyConfig = config.data.input.keys

    if this.isKeyValidToShow(keyConfig.nextQuest) and this.isKeyValidToShow(keyConfig.previousQuest) then
        table.insert(out, l10n("nextPreviousHotkeysStrFormat", {
            next = this.keyCombinationToString(keyConfig.nextQuest),
            previous = this.keyCombinationToString(keyConfig.previousQuest),
        }))
    end

    if this.isGamepad then
        table.insert(out, l10n("scrollQuestGamepadHotkeys"))
    end

    if this.isKeyValidToShow(keyConfig.toggleTrackObjects) then
        table.insert(out, l10n("toggleTrackObjectsHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTrackObjects),
        }))
    end

    if this.isKeyValidToShow(keyConfig.toggleTopTopics) then
        table.insert(out, l10n("toggleTopTopicsHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTopTopics),
        }))
    end

    if this.isKeyValidToShow(keyConfig.toggleTracking) then
        table.insert(out, l10n("toggleTrackingHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTracking),
        }))
    end

    if this.isKeyValidToShow(keyConfig.toggleQuestHidden) then
        table.insert(out, l10n("toggleQuestHiddenHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleQuestHidden),
        }))
    end

    if not allQuestsMode then
        if this.isKeyValidToShow(keyConfig.toggleQuestPinned) then
            table.insert(out, l10n("toggleQuestPinnedHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleQuestPinned),
            }))
        end
    end

    if allQuestsMode then
        if this.isKeyValidToShow(keyConfig.toggleStartedHidden) then
            table.insert(out, l10n("toggleStartedHiddenHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleStartedHidden),
            }))
        end
    else
        if this.isKeyValidToShow(keyConfig.toggleFinishedHidden) then
            table.insert(out, l10n("toggleFinishedHiddenHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleFinishedHidden),
            }))
        end
    end

    if allQuestsMode then
        if this.isKeyValidToShow(keyConfig.toggleNearby) then
            table.insert(out, l10n("toggleNearbyHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleNearby),
            }))
        end
        if this.isKeyValidToShow(keyConfig.toggleAllEntries) then
            table.insert(out, l10n("toggleAllEntriesHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleAllEntries),
            }))
        end
    end

    if allQuestsMode then
        if this.isKeyValidToShow(keyConfig.nearbyMenuLocal) then
            table.insert(out, l10n("journalMenuLocalHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.nearbyMenuLocal),
            }))
        end
    else
        if this.isKeyValidToShow(keyConfig.nearbyMenuLocal) then
            table.insert(out, l10n("nearbyMenuLocalHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.nearbyMenuLocal),
            }))
        end
    end

    if this.isKeyValidToShow(keyConfig.topicMenuLocal) then
        table.insert(out, l10n("topicMenuLocalHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.topicMenuLocal),
        }))
    end

    if this.isGamepad then
        table.insert(out, l10n("closeMenuHotkeyStrFormat", {
            hotkey = "B",
        }))
    end

    if #out <= 2 then return end

    return table.concat(out, l10n("hotkeyInfoSeparator"))
end


function this.getTopicsMenuHotkeyInfoStr()
    local out = {}
    local keyConfig = config.data.input.keys

    if this.isKeyValidToShow(keyConfig.nextQuest) and this.isKeyValidToShow(keyConfig.previousQuest) then
        table.insert(out, l10n("nextPreviousTopicHotkeysStrFormat", {
            next = this.keyCombinationToString(keyConfig.nextQuest),
            previous = this.keyCombinationToString(keyConfig.previousQuest),
        }))
    end

    if this.isKeyValidToShow(keyConfig.toggleTopTopics) then
        table.insert(out, l10n("showMoreTopicsHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTopTopics),
        }))
    end

    if this.isKeyValidToShow(keyConfig.toggleAlphabetical) then
        table.insert(out, l10n("toggleAlphabeticalHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleAlphabetical),
        }))
    end

    if this.isGamepad then
        table.insert(out, l10n("closeMenuHotkeyStrFormat", {
            hotkey = "B",
        }))
    end

    if #out <= 1 then return end

    return table.concat(out, l10n("hotkeyInfoSeparator"))
end


return this