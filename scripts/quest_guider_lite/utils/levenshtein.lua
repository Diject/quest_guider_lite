local this = {}

local function utf8_chars(str)
    local chars = {}
    for _, c in utf8.codes(str) do
        table.insert(chars, utf8.char(c))
    end
    return chars
end

local function utf8_levenshtein(s, t)
    local s_chars = utf8_chars(s)
    local t_chars = utf8_chars(t)
    local m, n = #s_chars, #t_chars
    local d = {}

    for i = 0, m do
        d[i] = {}
        d[i][0] = i
    end
    for j = 0, n do
        d[0][j] = j
    end

    for i = 1, m do
        for j = 1, n do
            local cost = (s_chars[i] == t_chars[j]) and 0 or 1
            d[i][j] = math.min(
                d[i-1][j] + 1,
                d[i][j-1] + 1,
                d[i-1][j-1] + cost
            )
        end
    end
    return d[m][n]
end

-- Bounded Levenshtein: returns distance or math.huge if > maxDist
local function utf8_levenshtein_bounded(s, t, maxDist)
    local s_chars = utf8_chars(s)
    local t_chars = utf8_chars(t)
    local m, n = #s_chars, #t_chars

    -- Quick length check
    if math.abs(m - n) > maxDist then
        return math.huge
    end

    -- Use two rows instead of full matrix for memory efficiency
    local prev = {}
    local curr = {}

    for j = 0, n do
        prev[j] = j
    end

    for i = 1, m do
        curr[0] = i
        local rowMin = curr[0]

        for j = 1, n do
            local cost = (s_chars[i] == t_chars[j]) and 0 or 1
            curr[j] = math.min(
                prev[j] + 1,
                curr[j-1] + 1,
                prev[j-1] + cost
            )
            if curr[j] < rowMin then
                rowMin = curr[j]
            end
        end

        -- Early termination: if minimum in row > maxDist, no solution possible
        if rowMin > maxDist then
            return math.huge
        end

        -- Swap rows
        prev, curr = curr, prev
    end

    return prev[n]
end


this.utf8_levenshtein = utf8_levenshtein
this.utf8_levenshtein_bounded = utf8_levenshtein_bounded


return this