local ui = require('openmw.ui')
local util = require('openmw.util')

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
            local wordSize = utf8.len(word)
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


return this