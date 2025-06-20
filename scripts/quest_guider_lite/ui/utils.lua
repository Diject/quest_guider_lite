local this = {}


function this.getTextHeight(text, fontSize, width)
    if #text == 0 then return 0 end
    local words = {}
    local rowMaxSize = math.floor(width / fontSize)
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