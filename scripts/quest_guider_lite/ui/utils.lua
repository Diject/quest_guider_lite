local ui = require('openmw.ui')
local util = require('openmw.util')

local config = require("scripts.quest_guider_lite.config")

local this = {}


function this.getTextHeight(text, fontSize, width, mul)
    if not mul then mul = 0.7 end
    if #text == 0 then return 0 end
    local words = {}
    local charWidth = fontSize * mul
    local rowMaxSize = math.floor(width / charWidth)
    local rowCount = 1
    for line in text:gmatch("[^\n]+") do
        local currentRowSize = 0
        for word in line:gmatch("%S+") do
            local wordSize = utf8.len(word) or string.len(word)
            if currentRowSize + wordSize <= rowMaxSize then
                currentRowSize = currentRowSize + wordSize + 1
            else
                rowCount = rowCount + 1
                currentRowSize = wordSize
            end
            table.insert(words, word)
        end
        rowCount = rowCount + 1
    end
    rowCount = rowCount - 1
    return rowCount * fontSize, rowCount
end


function this.getUIScale()
	local width = ui.layers[ui.layers.indexOf("HUD")].size.x
	local screenSize = ui.screenSize()
	return screenSize.x / width
end


function this.getScaledScreenSize()
    return ui.layers[ui.layers.indexOf("HUD")].size
end


local specialCharacters = {
    ["("] = "(",
    [")"] = ")",
    ["."] = ".",
    ["%"] = "%",
    ["+"] = "+",
    ["-"] = "-",
    ["*"] = "*",
    ["?"] = "?",
    ["["] = "[",
    ["]"] = "]",
    ["^"] = "^",
    ["$"] = "$"
}

function this.colorize(text, search, color, defaultColor)
    local strLen = utf8.len(search) or string.len(search)
    if strLen == 0 then return text end

    color = color or "#000000"
    defaultColor = defaultColor or ("#"..config.data.ui.defaultColor:asHex())

    local pattern = ""
    for i = 1, #search do
        local c = search:sub(i, i)
        if c:match("%a") then
            pattern = pattern .. "[" .. c:lower() .. c:upper() .. "]"
        elseif specialCharacters[c] then
            pattern = pattern .. "%" .. c
        else
            pattern = pattern .. c
        end
    end

    return text:gsub(pattern, function(found)
        return color..found..defaultColor
    end)
end


function this.colorizeNested(text, search, color, defaultColor)
    if not search or #search == 0 then return text end

    color = color or "#000000"
    defaultColor = defaultColor or ("#"..config.data.ui.defaultColor:asHex())

    local pattern = ""
    for i = 1, #search do
        local c = search:sub(i, i)
        if c:match("%a") then
            pattern = pattern .. "[" .. c:lower() .. c:upper() .. "]"
        elseif specialCharacters[c] then
            pattern = pattern .. "%" .. c
        else
            pattern = pattern .. c
        end
    end

    local result = ""
    local lastIndex = 1
    local currentColor = defaultColor

    for i, c in text:gmatch("()(#%x%x%x%x%x%x)") do
        local segment = text:sub(lastIndex, i - 1)
        if #segment > 0 then
            local replacedSegment = segment:gsub(pattern, function(found)
                return color .. found .. currentColor
            end)
            result = result .. replacedSegment
        end
        result = result .. c
        currentColor = c
        lastIndex = i + #c
    end

    local finalSegment = text:sub(lastIndex)
    if #finalSegment > 0 then
        local replacedSegment = finalSegment:gsub(pattern, function(found)
            return color .. found .. currentColor
        end)
        result = result .. replacedSegment
    end

    return result
end


function this.removeColorMarkers(text)
    return text:gsub("#%x%x%x%x%x%x", "")
end


return this