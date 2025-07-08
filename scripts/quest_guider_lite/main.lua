local async = require('openmw.async')
local world = require('openmw.world')
local types = require('openmw.types')
local time = require('openmw_aux.time')

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local log = require("scripts.quest_guider_lite.utils.log")
local dataHandler = require("scripts.quest_guider_lite.dataHandler")
local questLib = require("scripts.quest_guider_lite.quest")
local testing = require("scripts.quest_guider_lite.testing.tests")
local questGivers = require("scripts.quest_guider_lite.questGiverTracking")
local trackingGlobal = require("scripts.quest_guider_lite.trackingGlobal")
local cellLib = require("scripts.quest_guider_lite.cell")
local common = require("scripts.quest_guider_lite.common")
local killCounter = require("scripts.quest_guider_lite.killCounter")

local l10n = require('openmw.core').l10n(common.l10nKey)


---@class questGuider.main.fillQuestBoxQuestInfo.returnFieldDt
---@field requirements questGuider.quest.getDescriptionDataFromBlock.return[]
---@field index integer

---@alias questGuider.main.fillQuestBoxQuestInfo.returnDt table<string, questGuider.main.fillQuestBoxQuestInfo.returnFieldDt[]> by dia id, sorted by index
---@alias questGuider.main.fillQuestBoxQuestInfo.returnBlock {next : questGuider.main.fillQuestBoxQuestInfo.returnDt?, linked : questGuider.main.fillQuestBoxQuestInfo.returnDt?, objectPositions : table<string, questGuider.quest.getRequirementPositionData.returnData>, diaId : string, diaIndex : integer}

---@alias questGuider.main.fillQuestBoxQuestInfo.return table<integer, questGuider.main.fillQuestBoxQuestInfo.returnBlock> by content id


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


---@param params {diaId : string, diaIndex : number|string, objectId : string?}
local function addMarkersForQuest(params)

    local questData = questLib.getQuestData(params.diaId)
    if not questData then return end

    local indexStr = tostring(params.diaIndex)
    local indexData = questData[indexStr]
    if not indexData then return end

    local objects = {}

    for i, reqDataBlock in pairs(indexData.requirements or {}) do

        local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
        if not requirementData then goto continue end

        for _, requirement in ipairs(requirementData) do
            for objId, posData in pairs(requirement.positionData or {}) do
                if params.objectId and params.objectId ~= objId then goto continue end

                if posData then
                    ---@type questGuider.tracking.addMarker
                    local eventParams = {
                        questId = params.diaId,
                        objectId = objId,
                        objectName = posData.name,
                        positionData = posData,
                        questData = questData,
                        questStage = params.diaIndex,
                        reqData = requirement,
                    }
                    world.players[1]:sendEvent("QGL:addMarker", eventParams)

                    objects[objId] = posData.name
                end

                ::continue::
            end
        end

        ::continue::
    end

    return objects
end


---@param data table<string, {diaId : string, index : integer, contentIndex : integer}>
local function fillQuestBoxQuestInfo(data)
    ---@type questGuider.main.fillQuestBoxQuestInfo.return
    local out = {}

    local function getDtArr(t, diaId, index)
        if not t[diaId] then t[diaId] = {} end
        local isNew = false
        local indexStr = tostring(index)
        if not t[diaId][indexStr] then
            t[diaId][indexStr] = {
                requirements = {},
            }
            isNew = true
        end
        return t[diaId][indexStr], isNew
    end

    local function removeDtArr(t, diaId, index)
        local indexStr = tostring(index)
        if t[diaId][indexStr] then
            t[diaId][indexStr] = nil
        end
        if not next(t[diaId]) then
            t[diaId] = nil
        end
    end

    for diaId, diaInfo in pairs(data) do
        local qData = questLib.getQuestData(diaId)
        if not qData then goto continue end

        local questNextIndexes, linkedIndexData = questLib.getNextIndexes(qData, diaId, diaInfo.index, {findCompleted = false, findInLinked = true})
        if not questNextIndexes and not linkedIndexData then goto continue end

        local function getData(qData, index, arr)
            local indexStr = tostring(index)
            local indexData = qData[indexStr]
            if not indexData then return end

            arr.index = tonumber(index)

            for i, reqDataBlock in pairs(indexData.requirements or {}) do
                local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
                if not requirementData then goto continue end

                table.insert(arr.requirements, requirementData)

                ::continue::
            end
        end

        ---@type questGuider.main.fillQuestBoxQuestInfo.returnBlock
        local res = out[diaInfo.contentIndex] or {
            diaId = diaId,
            diaIndex = diaInfo.index,
            next = {},
            linked = {},
        }

        local function fillRes(qData, tb, diaId, index)
            local arr, created = getDtArr(tb, diaId, index)
            if created then
                getData(qData, index, arr)

                if not next(arr.requirements) then
                    removeDtArr(tb, diaId, index)
                end
            end
        end

        if questNextIndexes then
            for _, index in pairs(questNextIndexes) do
                fillRes(qData, res.next, diaId, index)
            end

            if not next(res.next) then
                res.next = nil
            else
                for dId, dt in pairs(res.next) do
                    res.next[dId] = tableLib.values(dt, function (a, b)
                        return a.index > b.index
                    end)
                end
            end
        end

        if linkedIndexData then
            for dId, dt in pairs(linkedIndexData) do
                local linkedQuestData = questLib.getQuestData(dId)
                if linkedIndexData then
                    fillRes(linkedQuestData, res.linked, dId, dt.index)
                end
            end

            if not next(res.linked) then
                res.linked = nil
            else
                for dId, dt in pairs(res.linked) do
                    res.linked[dId] = tableLib.values(dt, function (a, b)
                        return a.index > b.index
                    end)
                end
            end
        end

        if next(res) then
            out[diaInfo.contentIndex] = res
        end

        ::continue::
    end

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local objectPositions = {}
    local function processPosData(posData)
        for _, diaDt in pairs(posData or {}) do
            for _, reqsDt in pairs(diaDt) do
                for _, reqs in pairs(reqsDt.requirements or {}) do
                    for _, reqDt in pairs(reqs) do
                        if reqDt.positionData then
                            tableLib.copy(reqDt.positionData, objectPositions)
                        end
                    end
                end
            end
        end
    end

    for id, dt in pairs(out) do
        processPosData(dt.next)
        processPosData(dt.linked)

        out[id].objectPositions = objectPositions
    end

    for _, dt in pairs(objectPositions) do
        cellLib.fillDistanceToPlayer(dt.positions, world.players[1])

        table.sort(dt.positions, function (a, b)
            return a.distanceToPlayer < b.distanceToPlayer
        end)
    end

    if next(out) then
        world.players[1]:sendEvent("QGL:fillQuestBoxQuestInfo", out)
    end
end


local function showTrackingMessage(objects)
    if tableLib.size(objects) > 0 then
        local names = {}
        for id, name in pairs(objects) do
            if name and name ~= "" then
                table.insert(names, name)
            end
        end

        if #names > 0 then
                world.players[1]:sendEvent("QGL:showTrackingMessage", {message = stringLib.getValueEnumString(names, 3, l10n("startedTracking").." %s.")})
        end

        world.players[1]:sendEvent("QGL:updateMarkers", {})
    end
end


local function updateQuestMenu()
    world.players[1]:sendEvent("QGL:updateQuestMenu", {})
end


time.runRepeatedly(function ()
    world.players[1]:sendEvent("QGL:updateTime", {time = world.getGameTime()})
end, time.minute, {type = time.GameTime})
world.players[1]:sendEvent("QGL:updateTime", {time = world.getGameTime()})


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
                    local objs = addMarkersForQuest{diaId = data.questId, diaIndex = indexStr}
                    tableLib.copy(objs, objects)
                end
                data.shouldUpdate = true
            end

            if linkedIndexData then
                for qId, dt in pairs(linkedIndexData) do
                    local objs = addMarkersForQuest{diaId = qId, diaIndex = dt.index}
                    tableLib.copy(objs, objects)
                end
                data.shouldUpdate = true
            end

            showTrackingMessage(objects)
            updateQuestMenu()
        end,

        ["QGL:trackObject"] = function (data)
            local objects = addMarkersForQuest{diaId = data.diaId, diaIndex = data.index, objectId = data.objectId}
            showTrackingMessage(objects)
            updateQuestMenu()
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
        end,

        ["QGL:fillQuestBoxQuestInfo"] = function (data)
            fillQuestBoxQuestInfo(data)
        end,

        ["QGL:registerActorDeath"] = function (data)
            killCounter.registerKill(data.object)
            world.players[1]:sendEvent("QGL:registerActorDeath", data)
        end,

        ["QGL:updateKillCounter"] = function (data)
            killCounter.init(data)
        end,
    },
}