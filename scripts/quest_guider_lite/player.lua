local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local util = require('openmw.util')

local log = require("scripts.quest_guider_lite.utils.log")

local commonData = require("scripts.quest_guider_lite.common")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local config = require("scripts.quest_guider_lite.configLib")

local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local configLib = require("scripts.quest_guider_lite.configLib")
local killCounter = require("scripts.quest_guider_lite.killCounter")

local timeLib = require("scripts.quest_guider_lite.timeLocal")

local createQuestMenu = require("scripts.quest_guider_lite.ui.customJournal.base")
local nextStagesBlock = require("scripts.quest_guider_lite.ui.customJournal.nextStagesBlock")

---@type questGuider.ui.customJournal?
local questMenu



local function onInit()
    if not localStorage.isPlayerStorageReady() then
        localStorage.initPlayerStorage()
    end
    killCounter.initByStorageData(localStorage.data)
    tracking.init()
end


local function onLoad(data)
    localStorage.initPlayerStorage(data)
    killCounter.initByStorageData(localStorage.data)
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

input.registerTriggerHandler("QGL:journal.menuKey", async:callback(function()
    if questMenu then
        questMenu.menu:destroy()
        questMenu = nil
        I.UI.removeMode("Journal")
    else
        I.UI.setMode("Journal", { windows = {} })
        questMenu = createQuestMenu{
            fontSize = config.data.ui.fontSize,
            size = util.vector2(config.data.journal.width, config.data.journal.height),
            relativePosition = util.vector2(config.data.journal.position.x, config.data.journal.position.y),
            onClose = function ()
                questMenu = nil
                I.UI.removeMode("Journal")
            end
        }
    end
end))

local function onKeyRelease(key)
    if questMenu and not core.isWorldPaused() then
        questMenu.menu:destroy()
        questMenu = nil
    end
end


time.runRepeatedly(function()
    if tracking.handlePlayerInventory() then
        tracking.updateMarkers()
    end
end, 5 * time.second + math.random())


return {
    engineHandlers = {
        onQuestUpdate = function(questId, stage)
            playerQuests.update(questId, stage)
            if config.data.tracking.autoTrack then
                tracking.trackQuest(questId, stage)
            end
            if tracking.handleTrackingRequirements() then
                tracking.updateMarkers()
            end
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
        onKeyRelease = onKeyRelease,
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

        ---@param data questGuider.main.fillQuestBoxQuestInfo.return
        ["QGL:fillQuestBoxQuestInfo"] = function (data)
            if not questMenu then return end
            ---@class questGuider.ui.questBoxMeta
            local questBox = questMenu:getQuestScrollBox().userData.questBoxMeta

            questBox.questInfo = data
            questBox:addTrackButtons()

            ---@type questGuider.ui.scrollBox
            local scrollBox = questBox:getScrollBox().userData.scrollBoxMeta

            local scrollBoxContent = scrollBox:getMainFlex()

            for contentIndex, dt in pairs(data) do
                local element = scrollBoxContent.content[contentIndex]
                if not element then goto continue end

                element.content:add(
                    nextStagesBlock.create{
                        data = dt,
                        size = scrollBox.innnerSize,
                        fontSize = config.data.ui.fontSize,
                        updateFunc = function ()
                            questMenu:update()
                        end,
                        thisElementInContent = function ()
                            return scrollBox:getMainFlex().content[contentIndex].content[#element.content]
                        end
                    }
                )

                ::continue::
            end
            questMenu:update()
        end,

        ["QGL:updateQuestMenu"] = function (data)
            if not questMenu then return end

            questMenu:updateNextStageBlocks()
            questMenu:updateQuestListTrackedColors()
            questMenu:update()
        end,

        ["QGL:registerActorDeath"] = function (data)
            killCounter.registerKill(data.object)
            tracking.handleDeath(data.object.recordId)
        end
    },
}