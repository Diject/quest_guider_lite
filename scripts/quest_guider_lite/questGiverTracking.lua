local types = require('openmw.types')
local world = require('openmw.world')

local stringLib = require("scripts.quest_guider_lite.utils.string")

local commonInfo = require("scripts.quest_guider_lite.common")

local questLib = require("scripts.quest_guider_lite.quest")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local config = require("scripts.quest_guider_lite.config")

local this = {}

this.trackedQuestGivers = {}



function this.registerTrackedQuestGiver(objectRecordId, markerRecordId)
    this.trackedQuestGivers[objectRecordId] = markerRecordId
end


function this.createQuestGiverMarker(ref)
    local recordId = ref.recordId

    if this.trackedQuestGivers[recordId] then return end

    local objectData = questLib.getObjectData(recordId)
    if not objectData or not objectData.starts then return end

    local questNames = {}

    for _, questId in pairs(objectData.starts) do
        local questIdLower = questId:lower()
        local questData = questLib.getQuestData(questIdLower)
        if not questData or not questData.name then goto continue end

        local firstIndexStr = questLib.getFirstIndex(questData)
        if not firstIndexStr then goto continue end
        if not questLib.checkConditionsForQuest(questIdLower, firstIndexStr) then
            goto continue
        end

        local currentIndex = playerQuests.getCurrentIndex(questId)
        if not currentIndex or currentIndex > 0 then
            goto continue
        end

        table.insert(questNames, questData.name)

        ::continue::
    end

    if #questNames <= 0 then return end

    ---@type proximityTool.record
    local recordData = {
        icon = "textures/icons/quest_guider/exclamationMark.dds",
        iconRatio = 2,
        iconColor = commonInfo.defaultColorData,
        description = stringLib.getValueEnumString(questNames, config.data.journal.objectNames, "Starts %s"),
        proximity = config.data.tracking.questGiverProximity,
        priority = -100,
        temporary = true,
    }

    ---@type proximityTool.marker
    ---@diagnostic disable-next-line: missing-fields
    local markerData = {
        objectId = recordId,
        temporary = true,
    }

    world.players[1]:sendEvent("QGL:addMarkerForQuestGivers", {recordData = recordData, markerData = markerData, objectRecordId = recordId})
end


function this.updateQuestGiverMarkers()
    for objId, recordId in pairs(this.trackedQuestGivers) do
        local objectData = questLib.getObjectData(objId)

        local valid = false

        for _, questId in pairs((objectData or {}).starts or {}) do
            local questData = questLib.getQuestData(questId)
            if not questData or not questData.name then goto continue end

            local firstIndexStr = questLib.getFirstIndex(questData)
            if not firstIndexStr then goto continue end
            if not questLib.checkConditionsForQuest(questId, firstIndexStr) then
                goto continue
            end

            local currentIndex = playerQuests.getCurrentIndex(questId)
            if not currentIndex or currentIndex > 0 then
                goto continue
            end

            valid = true
            if valid then
                break;
            end

            ::continue::
        end

        if not valid then
            world.players[1]:sendEvent("QGL:removeProximityRecord", {recordId = recordId})
            this.trackedQuestGivers[objId] = nil
        end
    end
end


return this