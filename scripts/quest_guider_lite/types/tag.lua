local core = require("openmw.core")
local playerRef = require("openmw.self")
local types = require("openmw.types")
local calendar = require("openmw_aux.calendar")

local NPC = types.NPC
local Creature = types.Creature

local common = require("scripts.quest_guider_lite.common")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local getObject = require("scripts.quest_guider_lite.core.getObject")
local timeLib = require("scripts.quest_guider_lite.timeLocal")

local l10n = core.l10n(common.l10nKey)


local factions = {}
for _, f in pairs(core.factions.records) do
    factions[f.id] = f
end


local function getClassName(classId)
    local class = NPC.classes.record(classId)
    if class then
        return class.name
    end
    return nil
end

local function getRaceName(raceId)
    local race = NPC.races.record(raceId)
    if race then
        return race.name
    end
    return nil
end

local function getFactionName(factionId)
    local faction = factions[factionId]
    return faction and faction.name or nil
end

local function getRankName(factionId, rankId)
    local faction = factions[factionId]
    if faction then
        local rank = faction.ranks[rankId]
        if rank then
            return rank.name
        end
    end
    return nil
end





local playerName = "PCName"
local playerRace = "PCRace"
local playerClass = "PCClass"
pcall(function ()
    local obj = getObject("player")
    playerName = obj.name
    playerRace = getRaceName(obj.race)
    playerClass = getClassName(obj.class)
end)



local this = {}


---@return boolean
function this.isRefRequired(text)
    if not text then return false end
    if text:find("%Faction", 1, true) or text:find("%Rank", 1, true) or
            text:find("%Cell", 1, true) or text:find("%Gamehour", 1, true) or
            text:find("%PCRank", 1, true) or text:find("%NextPCRank", 1, true) then
        return true
    end
    return false
end


---@return string
function this.replaceInText(text, ref)
    local tb = {
        ["PCName"] = playerName,
        ["PCRace"] = playerRace,
        ["PCClass"] = playerClass,
        ["Cell"] = playerRef.cell.displayName or playerRef.cell.name,
        ["Gamehour"] = calendar.formatGameTime("%H", timeLib.getGlobalTimestamp())
    }

    local actor
    if ref then
        actor = NPC.objectIsInstance(ref) and NPC.record(ref.recordId) or Creature.objectIsInstance(ref) and Creature.record(ref.recordId)
    end

    if actor then
        tb.Name = actor.name

        local race = actor.race and getRaceName(actor.race) or nil
        if race then
            tb.Race = race
        end

        local class = actor.class and getClassName(actor.class) or nil
        if class then
            tb.Class = class
        end

        if ref and NPC.objectIsInstance(ref) then
            local actorFactions = NPC.getFactions(ref)
            local factionId
            if actorFactions then
                local _, fId = next(actorFactions)
                if fId then
                    tb.Faction = getFactionName(fId)
                    factionId = fId
                end
            end

            if factionId then
                local rankId = NPC.getFactionRank(ref, factionId)

                if rankId and rankId > 0 then
                    tb.Rank = getRankName(factionId, rankId)
                end

                local plRank = NPC.getFactionRank(playerRef, factionId)
                if rankId and rankId > 0 then
                    tb.PCRank = getRankName(factionId, plRank)
                    tb.NextPCRank = getRankName(factionId, plRank + 1)
                end
            end
        end
    end

    text = stringLib.replaceGameTags(text, tb)
    text = stringLib.removeSpecialCharactersFromJournalText(text)

    return text ---@diagnostic disable-line: return-type-mismatch
end


---@return string
function this.replaceInTextSimple(text, record)
    local tb = {
        ["PCName"] = playerName,
        ["PCRace"] = playerRace,
        ["PCClass"] = playerClass,
    }

    if record then
        tb.Name = record.name

        local race = record.race and getRaceName(record.race) or nil
        if race then
            tb.Race = race
        end

        local class = record.class and getClassName(record.class) or nil
        if class then
            tb.Class = class
        end
    end

    text = stringLib.replaceGameTags(text, tb)
    text = stringLib.removeSpecialCharactersFromJournalText(text)

    return text ---@diagnostic disable-line: return-type-mismatch
end


return this