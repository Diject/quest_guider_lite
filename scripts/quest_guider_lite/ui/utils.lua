local this = {}


function this.getTextHeight(text, fontSize, width, mul)
    if not mul then mul = 0.7 end
    if #text == 0 then return 0 end
    local words = {}
    local charWidth = fontSize * mul
    local rowMaxSize = math.floor(width / charWidth)
    local rowCount = 1
    local currentRowSize = 0
    for word in text:gmatch("%S+") do
        local wordSize = utf8.len(word)
        if currentRowSize + wordSize <= rowMaxSize then
            currentRowSize = currentRowSize + wordSize + 1
        else
            rowCount = rowCount + 1
            currentRowSize = wordSize
        end
        table.insert(words, word)
    end
    return rowCount * fontSize, rowCount
end


return this