local include = require("scripts.quest_guider_lite.utils.include")

local playerFunc = require('openmw.types').Player
local core = require('openmw.core')

local playerRef = include('openmw.self')
if not playerRef then
    local world = include('openmw.world')
    if world then
        playerRef = world.players[1]
    end
end

local this = {}

---@class questGuider.playerQuest.data
---@field records table<string, any>

---@type table<string, questGuider.playerQuest.data>
this.questData = {}

---@type table<string, boolean>
this.finished = {}

local initialized = false

function this.init()
    if initialized then return end

    this.finished = {}

    for _, dia in pairs(core.dialogue.journal.records) do
        local qName = dia.questName
        if qName then
            if not this.questData[qName] then this.questData[qName] = {records = {}} end
            this.questData[qName].records[dia.id] = dia
        end
    end

    for qId, q in pairs(playerFunc.quests(playerRef)) do
        if not q.finished then goto continue end

        this.finished[q.id] = true

        local dia = core.dialogue.journal.records[q.id]
        if not dia or not dia.questName then goto continue end

        local qData = this.questData[dia.questName]
        if not qData then goto continue end

        for id, rec in pairs(qData.records) do
            this.finished[id] = true
        end

        ::continue::
    end

    initialized = true
end

function this.reset()
    initialized = false
    this.finished = {}
end

function this.isInitialized()
    return initialized
end


---@param diaId string
function this.getQuestDialogue(diaId)
    local quest = playerFunc.quests(playerRef)[diaId]
    return quest
end


---@param qName string
---@return questGuider.playerQuest.data?
function this.getQuestDataByName(qName)
    return this.questData[qName]
end


---@param diaId string
---@return questGuider.playerQuest.data?
function this.getQuestDataByDiaId(diaId)
    local dia = core.dialogue.journal.records[diaId]
    if not dia then return end

    return this.questData[dia.name]
end


---@param diaId string
---@param index integer
---@return string?
function this.getJournalText(diaId, index)
    local diaData = this.getQuestDialogue(diaId)
    if not diaData then return end

    local dia = core.dialogue.journal.records[diaId]
    if not dia then return end

    local info = dia.infos[index]
    if not info then return end

    return info.text
end


function this.addFinished(diaId)
    local qDia = this.getQuestDialogue(diaId)
    if not qDia or not qDia.finished then return end

    this.finished[diaId] = true

    local dia = core.dialogue.journal.records[qDia.id]
    if not dia then return end

    local data = this.getQuestDataByName(dia.name or "")
    if not data then return end

    for id, _ in pairs(data.records) do
        this.finished[id] = true
    end
end

---@param dialogueId string lowercase
---@return boolean?
function this.isFinished(dialogueId)
    return this.finished[dialogueId]
end

---@param diaId string
---@return integer|nil
function this.getCurrentIndex(diaId)
    local qData = playerFunc.quests(playerRef)[diaId]
    if not qData then return end
    return qData.stage
end


return this