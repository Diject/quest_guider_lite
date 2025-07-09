---@diagnostic disable: duplicate-doc-field
local core = require('openmw.core')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local playerRef = require('openmw.self')

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local itemLib = require("scripts.quest_guider_lite.types.item")
local colors = require("scripts.quest_guider_lite.types.gradient")
local common = require("scripts.quest_guider_lite.common")

local storage = require("scripts.quest_guider_lite.storage.localStorage")

local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local killCounter = require("scripts.quest_guider_lite.killCounter")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")

local config = require("scripts.quest_guider_lite.config")

local l10n = core.l10n(common.l10nKey)

---@type proximityTool
local proximityTool = I.proximityTool

local storageLabel = "tracking"


local this = {}


---@type table<string, {id : string, groupId : string}>
local lastInteriorMarkers = {}

---@class questGuider.tracking.markerRecord
---@field localMarkerId string|nil
---@field localDoorMarkerId string|nil
---@field disabled boolean?
---@field userDisabled boolean?

---@alias questGuider.tracking.markerData {id : string, index : integer, groupName : string, data : questGuider.tracking.markerRecord, parentObject: string?, itemCount : integer?, actorCount : integer?, handledRequirements : table<string, questDataGenerator.requirementBlock>?}

---@class questGuider.tracking.objectRecord
---@field color number[]?
---@field markers table<string, questGuider.tracking.markerData> by quest id
---@field targetCells table<string, string>? parent cell editor name by editor name of cell that have access to the parent

---@type table<string, questGuider.tracking.objectRecord>
this.markerByObjectId = {}

---@type table<string, {objects : table<string, string[]>}>
this.trackedObjectsByDiaId = {}

---@type table<string, boolean>
this.disabledQuests = {}

this.initialized = false

---@return boolean isSuccessful
function this.init()
    this.initialized = false
    proximityTool = I.proximityTool
    if not proximityTool then return false end

    if not storage.isPlayerStorageReady() then
        return false
    end

    if not storage.data then return false end
    if not storage.data[storageLabel] then
        storage.data[storageLabel] = {colorId = 1}
    end
    this.storageData = storage.data[storageLabel]
    this.storageData.markerByObjectId = this.storageData.markerByObjectId or {}
    this.storageData.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId or {}

    this.markerByObjectId = this.storageData.markerByObjectId
    this.trackedObjectsByDiaId = this.storageData.trackedObjectsByQuestId

    this.scannedCellsForTemporaryMarkers = {}

    this.initialized = true
    return this.initialized
end


---@class questGuider.tracking.addMarker
---@field questId string should be lower
---@field questStage integer
---@field objectId string should be lower
---@field objectName string?
---@field questData questDataGenerator.questData
---@field reqData questGuider.quest.getDescriptionDataFromBlock.returnArr?
---@field positionData questGuider.quest.getRequirementPositionData.returnData
---@field color number[]|nil

---@param params questGuider.tracking.addMarker
---@return questGuider.tracking.objectRecord|nil
function this.addMarker(params)
    if not this.initialized then return end

    local objectId = params.objectId

    local positionData = params.positionData

    local questData = params.questData

    if not questData or not positionData then return end

    if params.reqData and params.reqData.data.type == "DIAO" then return end

    local playerQuestData = playerQuests.getQuestStorageData(questData.name)

    if playerQuestData then
        if not config.data.tracking.trackDisabled and playerQuestData.disabled then
            return
        end
    end

    local qTrackingInfo
    if this.trackedObjectsByDiaId[params.questId] then
        qTrackingInfo = this.trackedObjectsByDiaId[params.questId]
    else
        qTrackingInfo = {objects = {}}
    end

    local objectTrackingData = this.markerByObjectId[objectId]
    if not objectTrackingData then
        local colorId = math.min(this.storageData.colorId, #colors)

        objectTrackingData = { markers = {}, color = config.data.tracking.colored and colors[colorId] } ---@diagnostic disable-line: missing-fields

        this.storageData.colorId = colorId < #colors and colorId + 1 or 1
    end

    if objectTrackingData.markers[params.questId] then
        local oldData = objectTrackingData.markers[params.questId]
        if oldData.actorCount or positionData.actorCount then
            oldData.actorCount = math.max(oldData.actorCount or 0, positionData.actorCount or 0)
        end
        if oldData.itemCount or positionData.itemCount then
            oldData.itemCount = math.max(oldData.itemCount or 0, positionData.itemCount or 0)
        end
        if positionData.parentObject then
            oldData.parentObject = positionData.parentObject
        end
        if params.reqData and params.reqData.reqDataForHandling then
            local hash = ""
            for _, r in pairs(params.reqData.reqDataForHandling) do
                hash = hash..r.type..tostring(r.operator)..tostring(r.value)..tostring(r.variable)..tostring(r.object)
            end
            if not oldData.handledRequirements then oldData.handledRequirements = {} end
            oldData.handledRequirements[hash] = params.reqData.reqDataForHandling
        end
        return
    end

    ---@type questGuider.tracking.markerRecord
    local objectMarkerData = {}

    ---@type proximityTool.record
    local markerRecordParams = {
        name = positionData.name,
        description = {string.format("%s: \"%s\"", l10n("quest"), questData.name or ""), ""},
        nameColor = config.data.tracking.colored and objectTrackingData.color,
        proximity = config.data.tracking.proximity,
        priority = 10,
    }

    ---@type proximityTool.record
    local doorMarkerRecordParams = {
        name = string.format("%s", positionData.name),
        description = {string.format("%s: \"%s\"", l10n("quest"), questData.name or ""), ""},
        icon = "textures/icons/quest_guider/toDoorIcon.dds",
        iconRatio = 1.6,
        iconColor = common.defaultColorData,
        nameColor = config.data.tracking.colored and objectTrackingData.color,
        proximity = config.data.tracking.proximity,
        priority = 0,
    }

    objectMarkerData.localMarkerId = proximityTool.addRecord(markerRecordParams)

    objectMarkerData.localDoorMarkerId = proximityTool.addRecord(doorMarkerRecordParams)

    if not objectMarkerData.localMarkerId then return end

    if not objectTrackingData.markers then objectTrackingData.markers = {} end
    local handledReqs = params.reqData and params.reqData.reqDataForHandling
    if handledReqs then
        local hash = ""
        for _, r in pairs(handledReqs) do
            hash = hash..r.type..tostring(r.operator)..tostring(r.value)..tostring(r.variable)..tostring(r.object)
        end
        handledReqs = {[hash] = handledReqs}
    end
    objectTrackingData.markers[params.questId] = {
        id = params.questId,
        index = params.questStage,
        groupName = questData.name,
        data = objectMarkerData,
        itemCount = positionData.itemCount,
        actorCount = positionData.actorCount,
        parentObject = positionData.parentObject,
        handledRequirements = handledReqs,
    }

    local objects = {}
    objects[objectId] = true

    local isItem = itemLib.isItem(objectId)

    local markEntrances = #positionData.positions < config.data.tracking.maxPos

    local positionalMarkers = { record = objectMarkerData.localMarkerId, groupName = questData.name, positions = {} }
    local doorMarkers = { record = objectMarkerData.localDoorMarkerId, groupName = questData.name, positions = {} }

    for _, data in pairs(positionData.positions or {}) do

        if objectMarkerData.localMarkerId then

            local rawData = data.rawData

            if rawData then
                if rawData.id then
                    objects[rawData.id] = true
                end
            else
                table.insert(positionalMarkers.positions, {
                    cell = {
                        isExterior = data.id and false or true,
                        id = data.id,
                    },
                    position = data.position,
                })
            end
        end

        if data.id ~= nil then

            local cell = data.cellPath and data.cellPath[1] or nil
            if cell then

                if markEntrances then
                    local exitPositions = data.entrances

                    if exitPositions and objectMarkerData.localDoorMarkerId then

                        for _, posData in pairs(exitPositions) do
                            ---@type proximityTool.positionData
                            local pos = {position = posData, cell = {isExterior = true}}
                            table.insert(doorMarkers.positions, pos)
                        end
                    end
                end

                if not objectTrackingData.targetCells then
                    objectTrackingData.targetCells = {}
                end

                objectTrackingData.targetCells[cell.id] = cell.id
            end
        end
    end

    if #positionalMarkers.positions > 0 then
        proximityTool.addMarker(positionalMarkers)
    end

    if #doorMarkers.positions > 0 then
        proximityTool.addMarker(doorMarkers)
    end

    local listOfObjects = tableLib.keys(objects)
    if #listOfObjects > 0 then

        proximityTool.addMarker{
            record = objectMarkerData.localMarkerId,
            objects = listOfObjects,
            groupName = questData.name,
            itemId = isItem and objectId or nil,
        }

    end

    this.markerByObjectId[objectId] = objectTrackingData

    qTrackingInfo.objects[objectId] = listOfObjects

    this.trackedObjectsByDiaId[params.questId] = qTrackingInfo

    local updateMarkers = false
    if positionData.itemCount then
        updateMarkers = updateMarkers or this.handlePlayerInventory()
    end
    if positionData.actorCount then
        updateMarkers = updateMarkers or this.handleDeath(objectId)
    end

    -- if this.disabledQuests[params.questId] then
    --     this.setDisableMarkerState{ questId = params.questId, value = true }
    -- end

    if updateMarkers then
        this.updateMarkers()
    end

    return objectTrackingData
end


---@class questGuider.tracking.disableMarker
---@field questId string? should be lowercase
---@field objectId string? should be lowercase
---@field toggle boolean?
---@field value boolean?
---@field isUserDisabled boolean?
---@field temporary boolean?

---@param params questGuider.tracking.disableMarker
function this.setDisableMarkerState(params)
    if not (params.isUserDisabled or params.temporary) and
        params.questId and this.disabledQuests[params.questId] then
            return
    end

    local markerDataHashTable = {}

    for objId, objData in pairs(this.markerByObjectId) do
        if params.objectId and objId ~= params.objectId then goto continue end

        for qId, markerData in pairs(objData.markers) do
            if params.questId and qId ~= params.questId then goto continue end

            markerDataHashTable[markerData.data] = true

            ::continue::
        end

        ::continue::
    end

    ---@param markerData questGuider.tracking.markerRecord
    local function setDisabledState(markerData)
        local disabledState = params.toggle == true and not markerData.disabled or params.value

        if params.temporary then
            markerData.disabled = disabledState
        elseif params.isUserDisabled then
            markerData.disabled = disabledState
            if markerData.disabled == nil then markerData.disabled = false end
            markerData.userDisabled = markerData.disabled

        elseif markerData.userDisabled ~= nil then
            local userDisabled = markerData.userDisabled
            if userDisabled == disabledState then
                markerData.userDisabled = nil
            end
            markerData.disabled = userDisabled

        else
            markerData.disabled = disabledState
        end

        proximityTool.setVisibility(markerData.localDoorMarkerId, nil, not markerData.disabled)
        proximityTool.setVisibility(markerData.localMarkerId, nil, not markerData.disabled)
    end

    for markerData, _ in pairs(markerDataHashTable) do
        setDisabledState(markerData)
    end
end


---@class questGuider.tracking.getDisabledState
---@field questId string should be lowercase
---@field objectId string should be lowercase

---@param params questGuider.tracking.getDisabledState
---@return boolean?
function this.getDisabledState(params)
    if not params or not params.objectId or not params.questId then return end

    local objData = this.markerByObjectId[params.objectId]
    local objQuestTrackingData = objData and objData.markers[params.questId]
    local disabledState = objQuestTrackingData and objQuestTrackingData.data.disabled

    return disabledState or false
end


---@param markerData questGuider.tracking.markerData
local function checkHandledRequirements(objectId, markerData, protectedState)
    if not protectedState then protectedState = false end
    local changed = false
    if not markerData.handledRequirements then return end

    local res = false

    for _, reqBlock in pairs(markerData.handledRequirements) do
        local reqRes = requirementChecker.checkBlock(reqBlock, {threatErrorsAs = true})
        res = res or reqRes
    end

    if res == false then
        if markerData.data.disabled ~= true and not protectedState then
            this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = true }
            changed = true
        end
    elseif res == true then
        protectedState = true
        if markerData.data.disabled ~= false then
            this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = false }
            changed = true
        end
    end

    return changed, protectedState
end


function this.handlePlayerInventory()
    local changed = false

    for objId, data in pairs(this.markerByObjectId) do
        local protected = false
        for _, markerData in pairs(data.markers) do

            if markerData.handledRequirements then -- and config.data.tracking.hideFinActors
                local hChanged, hProtected = checkHandledRequirements(objId, markerData, protected)
                changed = changed or hChanged
                protected = protected or hProtected
            end

            if markerData.itemCount then -- and config.data.tracking.hideObtained
                local palyerItemCount = types.Actor.inventory(playerRef):countOf(markerData.parentObject)
                if markerData.itemCount <= palyerItemCount then
                    if markerData.data.disabled ~= true and not protected then
                        this.setDisableMarkerState{ objectId = objId, questId = markerData.id, value = true }
                        changed = true
                    end
                else
                    protected = true
                    if markerData.data.disabled ~= false then
                        this.setDisableMarkerState{ objectId = objId, questId = markerData.id, value = false }
                        changed = true
                    end
                end
            end

        end
    end

    if changed and not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    end

    if changed then
        this.updateMarkers()
    end

    return changed
end


---@return boolean? changed
function this.handleDeath(objectId)
    if not objectId then return end

    local objData = this.markerByObjectId[objectId]
    if not objData then return end

    local changed = false

    local protected = false
    for _, markerData in pairs(objData.markers) do

        if markerData.handledRequirements and config.data.tracking.hideFinActors then
            local hChanged, hProtected = checkHandledRequirements(objectId, markerData, protected)
            changed = changed or hChanged
            protected = protected or hProtected
        end

        if markerData.actorCount then
            local killCount = killCounter.getKillCount(markerData.parentObject or objectId)

            if killCount >= markerData.actorCount then
                if markerData.data.disabled ~= true and not protected then
                    this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = true }
                    changed = true
                end
            else
                protected = true
                if markerData.data.disabled ~= false then
                    this.setDisableMarkerState{ objectId = objectId, questId = markerData.id, value = false }
                    changed = true
                end
            end
        end
    end

    if changed and not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    end

    if changed then
        this.updateMarkers()
    end

    return changed
end


---@return boolean?
function this.handleTrackingRequirements()
    local changed = false
    local protected = false

    for objectId, data in pairs(this.markerByObjectId) do
        for _, markerData in pairs(data.markers) do

            local hChanged, hProtected = checkHandledRequirements(objectId, markerData, protected)
            changed = changed or hChanged
            protected = protected or hProtected

        end
    end

    if changed and not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    end

    return changed
end


---@param params questGuider.tracking.removeMarker
local function removeMarker(params)
    local recordIdsToRemove = {}

    ---@param rec questGuider.tracking.markerRecord
    local function addToRemove(rec)
        recordIdsToRemove[rec.localDoorMarkerId or ""] = true
        recordIdsToRemove[rec.localMarkerId or ""] = true
    end

    for objId, objData in pairs(this.markerByObjectId) do
        if params.objectId and objId ~= params.objectId then goto continue end

        for qId, markerData in pairs(objData.markers) do
            if params.questId and qId ~= params.questId then goto continue end

            addToRemove(markerData.data)
            objData.markers[qId] = nil

            ::continue::
        end

        if tableLib.size(objData.markers) == 0 then
            this.markerByObjectId[objId] = nil
        end

        ::continue::
    end

    for qId, qData in pairs(this.trackedObjectsByDiaId) do
        if params.questId and params.questId ~= qId then goto continue end

        for objId, _ in pairs(qData.objects) do
            if params.objectId and objId ~= params.objectId then goto continue end

            qData.objects[objId] = nil

            ::continue::
        end

        if tableLib.size(qData.objects) == 0 then
            this.trackedObjectsByDiaId[qId] = nil
        end

        ::continue::
    end

    local removed = false

    recordIdsToRemove[""] = nil
    for id, _ in pairs(recordIdsToRemove) do
        proximityTool.removeRecord(id)
        removed = true
    end

    return removed
end


---@class questGuider.tracking.removeMarker
---@field questId string|nil should be lowercase
---@field objectId string|nil should be lowercase
---@field removeLinked boolean?

---@param params questGuider.tracking.removeMarker
---@return boolean?
function this.removeMarker(params)
    if not params.questId and not params.objectId then return end

    local res = false

    if params.removeLinked and params.questId then
        local qData = playerQuests.getQuestDataByDiaId(params.questId)
        if not qData then return end
        for diaId, _ in pairs(qData.records or {}) do
            res = res or removeMarker{ questId = diaId, objectId = params.objectId }
        end
    end
    res = res or removeMarker(params)

    return res
end


---@class questGuider.tracking.addMarkersForQuest
---@field questId string should be lowercase
---@field questIndex integer|string

---@param params questGuider.tracking.addMarkersForQuest
---@return table<string, boolean>? objects object ids
function this.addMarkersForQuest(params)

    core.sendGlobalEvent("QGL:getTrackingData", {questId = params.questId, index = params.questIndex})

    if not playerRef.cell.isExterior then
        this.addMarkersForInteriorCell(playerRef.cell)
    end
end


function this.trackQuest(questId, index)
    local shouldUpdate = false

    if this.removeMarker{ questId = questId } then
        shouldUpdate = true
    end

    local isFinished = playerQuests.isFinished(questId)

    if isFinished then
        this.removeMarker{ questId = questId, removeLinked = true }
        this.updateMarkers()

    else
        core.sendGlobalEvent("QGL:trackQuest", {
            questId = questId,
            index = index,
            finished = isFinished,
            shouldUpdate = shouldUpdate,
            params = {findCompleted = false, findInLinked = true}
        })
    end
end


---@param params {objectId : string, diaId : string, index : integer}
function this.trackObject(params)
    this.removeMarker{ questId = params.diaId, objectId = params.objectId}

    core.sendGlobalEvent("QGL:trackObject", {
        diaId = params.diaId,
        objectId = params.objectId,
        index = params.index,
    })
end


function this.addTrackingMarker(recordData, markerData)
    if not recordData or not markerData then return end

    local recordId = proximityTool.addRecord(recordData)
    markerData.record = recordId

    local markerId, markerGroupId = proximityTool.addMarker(markerData)

    return recordId, markerId, markerGroupId
end


function this.addMarkersForInteriorCell(cell)
    local keys = {}
    for key, markerData in pairs(lastInteriorMarkers) do
        proximityTool.removeMarker(markerData.id, markerData.groupId)
        table.insert(keys, key)
    end
    for _, key in pairs(keys) do
        lastInteriorMarkers[key] = nil
    end

    core.sendGlobalEvent("QGL:addMarkersForInteriorCell", {
        cellId = cell.id,
        markerByObjectId = this.markerByObjectId,
    })
end


function this.addMarkerForInteriorCellFromGlobal(data)
    local markerData = data.markerData
    local description = data.description
    if not markerData or not description then return end

    local recordData = proximityTool.getMarkerData(markerData.record)
    if not recordData then return end

    local newRecordData = tableLib.deepcopy(recordData)
    newRecordData.description = data.description

    markerData.record = newRecordData

    local id, groupId = proximityTool.addMarker(markerData)
    if not id or not groupId then return end

    lastInteriorMarkers[id] = { id = id, groupId = groupId }
end


---@param params {diaId : string, objectId : string}
---@return boolean
function this.isObjectTracked(params)
    local dt = this.trackedObjectsByDiaId[params.diaId]
    if not dt then return false end

    if not dt.objects[params.objectId] then return false end

    return true
end


---@param params {diaId : string}
---@return boolean
function this.isDialogueHasTracked(params)
    local dia = this.trackedObjectsByDiaId[params.diaId]
    if not dia then return false end
    if not next(dia.objects) then return false end

    return true
end


---@return table<string, string[]>?
function this.getDiaTrackedObjects(diaId)
    if this.trackedObjectsByDiaId[diaId] then
        return this.trackedObjectsByDiaId[diaId].objects or {}
    end
    return nil
end


---@param objId string
---@return questGuider.tracking.objectRecord?
function this.getTrackedObjectData(objId)
    return this.markerByObjectId[objId]
end


function this.removeProximityRecord(id)
    proximityTool.removeRecord(id)
end


function this.removeProximityMarker(id, groupId)
    proximityTool.removeMarker(id, groupId)
end


function this.updateMarkers()
    proximityTool.update()
end


return this