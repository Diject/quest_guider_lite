local this = {}

this.time = 0


---@param time number
---@return string
function this.getDateByTime(time)
    local start_hour = 6
    local start_day = 1
    local start_month = 8
    local start_year = 427

    local month_days = 30
    local months_in_year = 12

    local morrowind_months = {
        "Morning Star", "Sun's Dawn", "First Seed", "Rain's Hand",
        "Second Seed", "Mid Year", "Sun's Height", "Last Seed",
        "Hearthfire", "Frostfall", "Sun's Dusk", "Evening Star"
    }

    local total_seconds = time + (start_hour * 3600)

    local total_days = math.floor(total_seconds / 86400)
    local remaining_seconds = total_seconds % 86400

    local hour = math.floor(remaining_seconds / 3600)
    local minute = math.floor((remaining_seconds % 3600) / 60)
    local second = remaining_seconds % 60

    local day = start_day + total_days
    local month = start_month
    local year = start_year

    while day > month_days do
        day = day - month_days
        month = month + 1
        if month > months_in_year then
            month = 1
            year = year + 1
        end
    end

    local function day_suffix(d)
        if d >= 11 and d <= 13 then return "th" end
        local last = d % 10
        if last == 1 then return "st"
        elseif last == 2 then return "nd"
        elseif last == 3 then return "rd"
        else return "th" end
    end

    local suffix = day_suffix(day)
    local month_name = morrowind_months[month]

    local result = string.format("%d%s %s, 3E %d %02d:%02d",
        day, suffix, month_name, year, hour, minute)

    return result
end

return this