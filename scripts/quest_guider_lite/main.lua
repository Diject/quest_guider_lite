local async = require('openmw.async')
local world = require('openmw.world')
local types = require('openmw.types')

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local log = require("scripts.quest_guider_lite.utils.log")
local dataHandler = require("scripts.quest_guider_lite.dataHandler")
local questLib = require("scripts.quest_guider_lite.quest")
local testing = require("scripts.quest_guider_lite.testing.tests")
local questGivers = require("scripts.quest_guider_lite.questGiverTracking")
local trackingGlobal = require("scripts.quest_guider_lite.trackingGlobal")


local function onInit()
    dataHandler.init()
    -- testing.descriptionLines()
end

local function onLoad()
    dataHandler.init()
end


local function onObjectActive(ref)
    if ref.type ~= types.NPC and ref.type ~= types.Creature then return end

    questGivers.createQuestGiverMarker(ref)
end


local function addMarkersForQuest(qId, qIndex)

    local questData = questLib.getQuestData(qId)
    if not questData then return end

    local indexStr = tostring(qIndex)
    local indexData = questData[indexStr]
    if not indexData then return end

    local objects = {}

    for i, reqDataBlock in pairs(indexData.requirements or {}) do

        local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
        if not requirementData then goto continue end

        for _, requirement in ipairs(requirementData) do
            for objId, objName in pairs(requirement.objects or {}) do
                local posData = requirement.positionData and requirement.positionData[objId]
                if posData then
                    ---@type questGuider.tracking.addMarker
                    local params = {
                        questId = qId,
                        objectId = objId,
                        objectName = objName,
                        positionData = posData,
                        questData = questData,
                        questStage = qIndex,
                        reqData = requirement,
                    }
                    world.players[1]:sendEvent("QGL:addMarker", params)

                    objects[objId] = objName
                end
            end
        end

        ::continue::
    end

    return objects
end


return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onObjectActive = onObjectActive,
    },
    eventHandlers = {
        ["QGL:trackQuest"] = function (data)
            local questNextIndexes, linkedIndexData = questLib.getNextIndexes(data.questId, data.questId, data.index, data.params)

            local objects = {}

            if questNextIndexes and not data.finished then
                for _, indexStr in pairs(questNextIndexes) do
                    local objs = addMarkersForQuest(data.questId, indexStr)
                    tableLib.copy(objs, objects)
                end
                data.shouldUpdate = true
            end

            if linkedIndexData then
                for qId, dt in pairs(linkedIndexData) do
                    local objs = addMarkersForQuest(qId, dt.index)
                    tableLib.copy(objs, objects)
                end
                data.shouldUpdate = true
            end

            if tableLib.size(objects) > 0 then
                local names = {}
                for id, name in pairs(objects) do
                    if name and name ~= "" then
                        table.insert(names, name)
                    end
                end

                if #names > 0 then
                     world.players[1]:sendEvent("QGL:showTrackingMessage", {message = stringLib.getValueEnumString(names, 3, "Started tracking %s.")})
                end

                world.players[1]:sendEvent("QGL:updateMarkers", {})
            end
        end,

        ["QGL:drawQuestBlockInJournalMenu"] = function (data)
            local questId = data.questId

            local out = {}

            out.questId = data.questId
            out.questData = questLib.getQuestData(questId)
            if not out.questData then return end

            world.players[1]:sendEvent("QGL:drawQuestBlockInJournalMenu", out)
        end,

        ["QGL:questGiverMarkerCallback"] = function (data)
            local recordId = data.recordId
            local objectId = data.inputData.objectRecordId
        end,

        ["QGL:updateQuestGiverMarkers"] = function ()
            questGivers.updateQuestGiverMarkers()
        end,

        ["QGL:addMarkersForInteriorCell"] = function (data)
            trackingGlobal.addMarkersForInteriorCell(data.cellId, data.markerByObjectId)
        end
    },
}