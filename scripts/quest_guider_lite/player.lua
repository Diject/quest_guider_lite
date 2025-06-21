local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")

local timeLib = require("scripts.quest_guider_lite.timeLocal")


local function onInit()
    if not localStorage.isPlayerStorageReady() then
        localStorage.initPlayerStorage()
    end
    tracking.init()
end


local function onLoad(data)
    localStorage.initPlayerStorage(data)
    tracking.init()
    playerQuests.init()
end


local function onSave()
    local data = {}
    localStorage.save(data)
    return data
end


local function teleportedCallback()
    local newCell = self.cell
    if not newCell.isExterior then
        tracking.addMarkersForInteriorCell(newCell)
    end
end


time.runRepeatedly(function()
    if tracking.handlePlayerInventory() then
        tracking.updateMarkers()
    end
end, 5 * time.second)


return {
    engineHandlers = {
        onQuestUpdate = function(questId, stage)
            playerQuests.update(questId, stage)
            tracking.trackQuest(questId, stage)
            core.sendGlobalEvent("QGL:updateQuestGiverMarkers", {})
        end,
        onTeleported = function ()
            async:newUnsavableSimulationTimer(0.1, function () -- delay for the player cell data to be updated
                teleportedCallback()
            end)
        end,
        onSave = onSave,
        onLoad = onLoad,
        onInit = onInit,
    },
    eventHandlers = {
        ["QGL:addMarker"] = function(data)
            tracking.addMarker(data)
        end,

        ["QGL:showTrackingMessage"] = function (data)
            if not data.message then return end
            ui.showMessage(data.message)
        end,

        ["QGL:addMarkerForQuestGivers"] = function (data)
            local recordId, markerId, markerGroupId = tracking.addTrackingMarker(data.recordData, data.markerData)
            tracking.updateMarkers()
            core.sendGlobalEvent("QGL:questGiverMarkerCallback", {
                record = recordId,
                inputData = data,
            })
        end,

        ["QGL:updateMarkers"] = function ()
            tracking.updateMarkers()
        end,

        ["QGL:removeProximityRecord"] = function (data)
            local recordId = data.recordId
            tracking.removeProximityRecord(recordId)
        end,

        ["QGL:removeProximityMarker"] = function (data)
            local id = data.id
            local groupId = data.groupId
            tracking.removeProximityMarker(id, groupId)
        end,

        ["QGL:addMarkerForInteriorCellTracking"] = function (data)
            tracking.addMarkerForInteriorCellFromGlobal(data)
        end,

        ["QGL:updateTime"] = function (data)
            timeLib.time = data.time
        end,
    },
}