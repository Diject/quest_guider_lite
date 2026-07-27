local playerRef = require("openmw.self")

local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local dataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
local questBase = require("scripts.quest_guider_lite.questBase")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local cellData = require("scripts.quest_guider_lite.core.cellData")
local realTimer = require("scripts.quest_guider_lite.realTimer")
local tags = require("scripts.quest_guider_lite.types.tag")
local playerInventory = require("scripts.quest_guider_lite.helpers.playerInventory")


local this = {}

---@type table<string, table<questGuider.playerQuest.storageQuestData, any>>
this.trackedObjects = {}
---@type table<string, questGuider.playerQuest.storageQuestData>
this.trackedQuestDiaData = {}
---@type table<string, {tm: integer, diaId: string, index: integer, dias: table<string, {actor: any, dia: any, info: any}>}> by quest diaId
this.questDialogueTimestamps = {}

this.eventType = {
    died = 1,
    dialogue = 2,
    item = 3,
    itemObtained = 4,
    itemGiven = 5,
    finished = 99,
}

local forbiddenForTracking = {
    [this.eventType.finished] = true,
    [this.eventType.itemObtained] = true,
    [this.eventType.itemGiven] = true,
}

this.itemTypes = {
    [this.eventType.item] = true,
    [this.eventType.itemObtained] = true,
    [this.eventType.itemGiven] = true,
}


function this.getHashVal(type, val1, val2)
    return string.format("%d_%s_%s", type or -1, val1 or "", val2 or "")
end


function this.init()
    local storageData = playerQuests.getStorageData()
    if not storageData then return end

    for qName, qStorageData in pairs(storageData.questData) do
        if qStorageData.finished then goto continue end

        for _, rec in pairs(qStorageData.list) do
            if not rec.type or forbiddenForTracking[rec.type] then goto continue end

            if rec.dId then
                this.trackedObjects[rec.dId] = this.trackedObjects[rec.dId] or {}
                this.trackedObjects[rec.dId][qStorageData] = true
            end

            if rec.obj then
                this.trackedObjects[rec.obj] = this.trackedObjects[rec.obj] or {}
                this.trackedObjects[rec.obj][qStorageData] = true
            end
            ::continue::
        end

        local qData = playerQuests.getQuestDataByName(qName)
        if qData then
            for diaId, rec in pairs(qData.records) do
                this.trackedQuestDiaData[diaId] = qStorageData
                for objId, _ in pairs(questBase.getQuestDiaVarValues(diaId, function (d) return d.type ~= 3 end) or {}) do
                    this.trackedObjects[objId] = this.trackedObjects[objId] or {}
                    this.trackedObjects[objId][qStorageData] = true
                end
            end
        end

        ::continue::
    end
end


function this.registerQuestDialogue(diaId, stage)
    this.questDialogueTimestamps[diaId] = {tm = realTimer.frameCounter, diaId = diaId, index = stage, dias = {}}
end


function this.handleJournalEvent(diaId, diaIndex)
    local qData, qName = playerQuests.getQuestDataByDiaId(diaId)
    if not qData then return end

    local storageData = this.trackedQuestDiaData[diaId]
    local hasRegisteredData = storageData ~= nil
    storageData = storageData or playerQuests.getQuestStorageData(qName) or playerQuests.initStorageQuestData(qName)
    if not storageData or storageData.finished then return end

    local isFirstEntry = #storageData.list == 0

    local tmData = this.questDialogueTimestamps[diaId]
    if tmData then
        if math.abs(tmData.tm - realTimer.frameCounter) <= 5 then
            for _, dt in pairs(tmData.dias) do
                if not this.trackedObjects[dt.dia.id] or not this.trackedObjects[dt.dia.id][storageData] then
                    this.trackedObjects[dt.dia.id] = this.trackedObjects[dt.dia.id] or {}
                    this.trackedObjects[dt.dia.id][storageData] = true
                    this.handleDialogueEvent(dt.actor, dt.dia.id, dt.info.id)
                end
            end
        end

        this.questDialogueTimestamps[diaId] = nil
    end

    if not hasRegisteredData then
        for objId, _ in pairs(questBase.getQuestDiaVarValues(diaId, function (d) return d.type ~= 3 end) or {}) do
            this.trackedObjects[objId] = this.trackedObjects[objId] or {}
            this.trackedObjects[objId][storageData] = true
        end

        this.trackedQuestDiaData[diaId] = storageData
    end

    if qData.isFinished then
        local dt = {
            type = this.eventType.finished,
            globalTime = timeLib.getGlobalTimestamp(),
            cellData = cellData.getCellData(playerRef.cell)
        }

        if not storageData.logHashes then storageData.logHashes = {} end
        local hash = this.getHashVal(dt.type)
        local pos = storageData.logHashes[hash] or (#storageData.list + 1)
        table.insert(storageData.list, pos, dt)
        storageData.logHashes[hash] = pos

        for key, tb in pairs(this.trackedObjects) do
            if tb[storageData] then
                tb[storageData] = nil
            end
        end
        for dId, val in pairs(this.trackedQuestDiaData) do
            if val == storageData then
                this.trackedQuestDiaData[dId] = nil
            end
        end
    elseif isFirstEntry then
        this.handleInventory(true)
    end
end


function this.handleDialogueEvent(actor, diaId, infoId)
    local info, dia = playerQuests.getDialogueInfo(diaId, infoId)
    if not info or not dia then return end

    local data = this.trackedObjects[diaId]
    if data then

        local hash = this.getHashVal(this.eventType.dialogue, diaId, infoId)

        for storageData, _ in pairs(data) do
            if not storageData.logHashes then storageData.logHashes = {} end
            if storageData.logHashes[hash] then goto continue end

            local dt = {
                type = this.eventType.dialogue,
                globalTime = timeLib.getGlobalTimestamp(),
                cellData = cellData.getCellData(playerRef.cell),
                dId = diaId,
                dInfo = infoId,
                obj = actor.recordId,
                text = tags.isRefRequired(info.text) and tags.replaceInText(info.text, actor) or nil
            }
            table.insert(storageData.list, dt)
            storageData.logHashes[hash] = #storageData.list

            this.trackedObjects[actor.recordId] = this.trackedObjects[actor.recordId] or {}
            this.trackedObjects[actor.recordId][storageData] = true

            this.handleDialogueInventory(storageData, infoId)

            :: continue::
        end

    else
        for qDiaId, dt in pairs(this.questDialogueTimestamps) do
            if math.abs(dt.tm - realTimer.frameCounter) <= 3 then
                if info.text then
                    dt.dias[this.getHashVal(nil, diaId, infoId)] = {actor = actor, info = info, dia = dia}
                end
            end
        end
    end
end


local function insertToData(storageData, objId, hash, dt)
    if not storageData.logHashes[hash] then
        table.insert(storageData.list, dt)
        storageData.logHashes[hash] = #storageData.list

        this.trackedObjects[objId] = this.trackedObjects[objId] or {}
        this.trackedObjects[objId][storageData] = true
    else
        local pos = storageData.logHashes[hash]
        local listCount = #storageData.list
        for i = pos, listCount - 1 do
            storageData.list[i] = storageData.list[i + 1]
        end
        storageData.list[listCount] = dt
        storageData.logHashes[hash] = listCount
    end
end


function this.handleDiedEvent(objId)
    local data = this.trackedObjects[objId]
    if not data then return end

    local hash = this.getHashVal(this.eventType.died, objId)

    for storageData, _ in pairs(data) do
        if not storageData.logHashes then storageData.logHashes = {} end

        local dt = {
            type = this.eventType.died,
            globalTime = timeLib.getGlobalTimestamp(),
            obj = objId,
        }

        insertToData(storageData, objId, hash, dt)

        :: continue::
    end
end


function this.handleDialogueInventory(storageData, infoId)
    for itemId, count in pairs(playerInventory.difference) do
        local dtType = count > 0 and this.eventType.itemObtained or this.eventType.itemGiven

        if not storageData.logHashes then storageData.logHashes = {} end
        local hash = this.getHashVal(dtType, itemId, infoId)
        if storageData.logHashes[hash] then goto continue end

        local dt = {
            type = dtType,
            globalTime = timeLib.getGlobalTimestamp(),
            obj = itemId,
            userData = math.abs(count)
        }

        table.insert(storageData.list, dt)
        storageData.logHashes[hash] = #storageData.list

        ::continue::
    end
end


function this.handleInventory(useCurrentInventory)
    for itemId, count in pairs(useCurrentInventory and playerInventory.items or playerInventory.difference) do
        if count <= 0 then goto continue end

        local data = this.trackedObjects[itemId]
        if not data then goto continue end

        local dtType = this.eventType.item

        local hash = this.getHashVal(dtType, itemId)

        for storageData, _ in pairs(data) do
            if not storageData.logHashes then storageData.logHashes = {} end

            local dt = {
                type = dtType,
                globalTime = timeLib.getGlobalTimestamp(),
                obj = itemId,
                userData = 1
            }

            insertToData(storageData, itemId, hash, dt)
        end

        ::continue::
    end
end


return this