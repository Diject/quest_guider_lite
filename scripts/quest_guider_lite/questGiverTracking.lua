local types = require('openmw.types')
local world = require('openmw.world')
local util = require("openmw.util")

local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")

local commonInfo = require("scripts.quest_guider_lite.common")

local questLib = require("scripts.quest_guider_lite.quest")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local cellLib = require("scripts.quest_guider_lite.cell")

local config = require("scripts.quest_guider_lite.config")

local l10n = require('openmw.core').l10n(commonInfo.l10nKey)


local this = {}


---@type table<string, {markerId : string?, hudMarkerId : string?}>
this.trackedQuestGivers = {}



function this.registerTrackedQuestGiver(objectRecordId, markerRecordId, hudMarkerId)
    this.trackedQuestGivers[objectRecordId] = {markerId = markerRecordId, hudMarkerId = hudMarkerId}
end


function this.createQuestGiverMarker(ref)
    local recordId = ref.recordId

    if this.trackedQuestGivers[recordId] then return end

    local objectData = questLib.getObjectData(recordId)
    if not objectData or not objectData.starts then return end

    local questNames = {}

    for _, questId in pairs(objectData.starts) do
        local questIdLower = questId:lower()
        if (playerQuests.getCurrentIndex(questIdLower) or 0) > 0 then goto continue end

        local questData = questLib.getQuestData(questIdLower)
        if not questData or not questData.name then goto continue end

        local firstIndexStr = questLib.getFirstIndex(questData)
        if not firstIndexStr then goto continue end
        if not questLib.checkConditionsForQuest(questIdLower, firstIndexStr) then
            goto continue
        end

        questNames[questData.name] = questData.name

        ::continue::
    end

    questNames = tableLib.values(questNames, true)

    if #questNames <= 0 then return end

    ---@type proximityTool.record
    local recordData = {
        icon = commonInfo.exclamationMarkPath,
        iconRatio = 2,
        iconColor = commonInfo.defaultColorData,
        nameColor = commonInfo.defaultColorData,
        description = stringLib.getValueEnumString(questNames, config.data.journal.objectNames, l10n("starts").." %s"),
        proximity = config.data.tracking.questGiverProximity * 69.99,
        priority = -100,
        temporary = true,
    }

    ---@type proximityTool.hudm?
    local hudMarkerParams
    if config.data.tracking.hudMarkers.enabled then
        hudMarkerParams = {
            modName = commonInfo.modName,
            version = 5,
            params = {
                icon = commonInfo.hudExclamationMarkPath,
                screenOffset = util.vector2(10, 0),
                scale = 1,
                raytracing = config.data.tracking.hudMarkers.rayTracing,
                range = config.data.tracking.hudMarkers.range * 3.2808,
                opacity = config.data.tracking.hudMarkers.opacity * 0.01,
                offsetMult = 1.0,
                offset = util.vector3(0, 0, 15),
                -- boundingBoxCenter = true,
                bonusSize = 10,
                color = commonInfo.colorToArray(config.data.ui.defaultColor),
            },
            objectIds = {recordId},
            temporary = true,
        }
    end


    ---@type proximityTool.marker
    ---@diagnostic disable-next-line: missing-fields
    local markerData = {
        objectId = recordId,
        temporary = true,
    }

    world.players[1]:sendEvent("QGL:addMarkerForQuestGivers", {
        questNames = questNames,
        recordData = recordData,
        markerData = markerData,
        objectRecordId = recordId,
        hudMarkerData = hudMarkerParams
    })
end


function this.updateQuestGiverMarkers()
    for objId, markerData in pairs(this.trackedQuestGivers) do
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
            world.players[1]:sendEvent("QGL:removeProximityRecord", {recordId = markerData.markerId})
            world.players[1]:sendEvent("QGL:removeHUDMarker", {id = markerData.hudMarkerId})
            this.trackedQuestGivers[objId] = nil
        end
    end
end


function this.createQuestGiverMarkerForDoor(ref)
    if not types.Door.isTeleport(ref) then return end

    local destCell = types.Door.destCell(ref)

    local cellsData = cellLib.findReachableCellsByNode({cell = destCell}) ---@diagnostic disable-line: missing-fields

    ---@type table<string, questDataGenerator.objectInfo>
    local giverIdsWithData = {}

    local function checkObj(ref)
        local recordId = ref.recordId
        if giverIdsWithData[recordId] then return end

        local objectData = questLib.getObjectData(recordId)
        if not objectData or not objectData.starts then return end

        giverIdsWithData[recordId] = objectData
    end

    for _, cellData in pairs(cellsData or {}) do
        local cell = cellData.cell
        for _, obj in pairs(cell:getAll(types.NPC)) do
            checkObj(obj)
        end
        for _, obj in pairs(cell:getAll(types.Creature)) do
            checkObj(obj)
        end
    end

    local questNames = {}

    for objId, objectData in pairs(giverIdsWithData) do
        for _, questId in pairs(objectData.starts) do
            local questIdLower = questId:lower()
            if (playerQuests.getCurrentIndex(questIdLower) or 0) > 0 then goto continue end

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

            questNames[questData.name] = questData.name

            ::continue::
        end
    end

    questNames = tableLib.values(questNames, true)

    if #questNames <= 0 then return end

    ---@type proximityTool.record
    local recordData = {
        name = destCell.name or "???",
        icon = commonInfo.doorExclMarkPath,
        iconColor = commonInfo.defaultColorData,
        nameColor = commonInfo.defaultColorData,
        description = stringLib.getValueEnumString(questNames, config.data.journal.objectNames, "%s can be started here or in surrounding locations."),
        proximity = 400,
        priority = 0,
        shortTerm = true,
    }


    ---@type proximityTool.marker
    ---@diagnostic disable-next-line: missing-fields
    local markerData = {
        object = ref,
        shortTerm = true,
    }

    world.players[1]:sendEvent("QGL:addMarkerForQuestGivers", {
        questNames = questNames,
        recordData = recordData,
        markerData = markerData,
    })
end


return this