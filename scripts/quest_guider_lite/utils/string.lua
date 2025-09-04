---@diagnostic disable: param-type-mismatch

local tableLib = require("scripts.quest_guider_lite.utils.table")

local levenshtein = require("scripts.quest_guider_lite.utils.levenshtein")

local this = {}

--- Returns string like ' "1", "2" and 3 more '
---@param tb table<any, string>
---@param max integer
---@param framePattern string|nil pattern with %s into which result will packed if max more than 0
---@param returnTable boolean? return an array with values
---@param customNumber integer? number of elements in the table
---@return string|string[]|nil
function this.getValueEnumString(tb, max, framePattern, returnTable, customNumber, valueFormat)
    local str = returnTable and {} or ""
    local count = 0
    valueFormat = valueFormat or "\"%s\""

    if max <= 0 then
        return str
    end

    for _, value in pairs(tb) do
        if count >= max then
            if returnTable then
                table.insert(str, string.format("and %d more", (customNumber or tableLib.size(tb)) - count))
            else
                str = string.format("%s and %d more", str, (customNumber or tableLib.size(tb)) - count)
            end
            break
        end

        local valueForm = string.format(valueFormat, value)

        if returnTable then
            table.insert(str, string.format(framePattern or "%s", valueForm))
        else
            str = string.format("%s%s%s", str, str:len() ~= 0 and ", " or "", valueForm)
        end
        count = count + 1

    end

    if framePattern and not returnTable then
        return string.format(framePattern, str)
    end

    return str
end


---@param name string
---@return string
function this.convertDialogueName(name)
    return string.sub(name, 7)
end


---@param text string
---@return string
function this.removeSpecialCharactersFromJournalText(text)
    return text:gsub("@", ""):gsub("#", "") ---@diagnostic disable-line: redundant-return-value
end


---@param text string
---@param phrase string
---@return boolean
function this.hasPhrase(text, phrase)
    local escapedPhrase = phrase:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")

    local pattern = "%f[%w]" .. escapedPhrase .. "%f[^%w]"

    if text:find(pattern) then
        return true
    else
        return false
    end
end


---@param str string
---@return number
function this.length(str)
    return utf8.len(str) or string.len(str) or 0
end


---@return string[]
function this.findTextLinks(text)
    local results = {}
    for match in text:gmatch("@(.-)#") do
        table.insert(results, match)
    end
    return results
end


function this.utf8_splitWords(str)
    local words = {}
    local pattern = "[%wа-яА-ЯёЁąćęłńóśźżĄĆĘŁŃÓŚŹŻčďěňřšťůžČĎĚŇŘŠŤŮŽäöüßÄÖÜéèêëÉÈÊËàâæçîïôœùûüÿÀÂÆÇÎÏÔŒÙÛÜŸ]+"
    for word in str:gmatch(pattern) do
        table.insert(words, word)
    end
    if #words == 0 and str ~= "" then
        table.insert(words, str)
    end
    return words
end


function this.utf8_removeLast(str, n)
    local len = utf8.len(str)
    if not len or n > len then return "" end
    local byte_pos = utf8.offset(str, len - n + 1)
    return str:sub(1, byte_pos - 1)
end


function this.utf8_lower(str)
    return (str:gsub("([%z\1-\127\194-\244][\128-\191]*)", function(c)
        return string.lower(c)
    end))
end


function this.utf8_chars(str)
    local chars = {}
    for _, c in utf8.codes(str) do
        table.insert(chars, utf8.char(c))
    end
    return chars
end


function this.utf8_sub(s, start, len)
    local i = 1
    local byte_start, byte_end
    for p, c in utf8.codes(s) do
        if i == start then
            byte_start = p
        end
        if i == start + len then
            byte_end = p - 1
            break
        end
        i = i + 1
    end
    byte_start = byte_start or 1
    byte_end = byte_end or #s
    return s:sub(byte_start, byte_end)
end


function this.isWordChar(c)
    return c:match("[%wа-яА-ЯёЁąćęłńóśźżĄĆĘŁŃÓŚŹŻčďěňřšťůžČĎĚŇŘŠŤŮŽäöüßÄÖÜéèêëÉÈÊËàâæçîïôœùûüÿÀÂÆÇÎÏÔŒÙÛÜŸ]")
end


---@param pattern string should be lowercase
---@return boolean
function this.fuzzyTopicSearch(text, pattern, threshold)
    if not threshold then
        local len = this.length(pattern)

        threshold = len > 3 and math.max(4, 1 + len / 5) or 0
    end

    local text_lower = this.utf8_lower(text)

    local dist = levenshtein.utf8_levenshtein(text, pattern)
    if dist <= threshold then
        return true
    end

    return false
end


return this