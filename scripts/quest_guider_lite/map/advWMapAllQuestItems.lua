local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local vfs = require("openmw.vfs")
local Container = types.Container

local config = require("scripts.quest_guider_lite.config")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local dataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
local commonInfo = require("scripts.quest_guider_lite.common")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local getObject = require("scripts.quest_guider_lite.core.getObject")

local l10n = core.l10n(commonInfo.l10nKey)


local itemTypePriority = {
    ["Miscellaneous"] = 10,
    ["Weapon"] = 9,
    ["Book"] = 8,
    ["Armor"] = 7,
    ["Clothing"] = 6,
    ["Apparatus"] = 0,
    ["Ingredient"] = 0,
    ["Light"] = 0,
    ["Lockpick"] = 0,
    ["Potion"] = 0,
    ["Probe"] = 0,
    ["Repair"] = 0,
}

local markerTemplate = {
    type = ui.TYPE.Container,
    content = ui.content{
        {
            external = { slot = true },
            props = {
                relativeSize = util.vector2(1, 1),
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture{ path = commonInfo.mapQuestItemBacgroundPath },
                color = config.data.ui.defaultColor,
                relativeSize = util.vector2(1, 1),
                alpha = 0.75,
            }
        },
    }
}


local methods = {}


---@return questDataGenerator.objectInfo?
local function getValidQuestItemData(recordId)
    local threshold = config.data.tracking.advWMapMarkers.questItemLimit
    if threshold == 0 then return end

    local itData = dataHandler.getObjectData(recordId)
    if itData and itData.stages and (itData.norm or itData.total or itData.inWorld or 0) <= threshold then
        for _, dt in pairs(itData.stages) do
            local q = playerQuests.getQuestDataByDiaId(dt.id)
            local qName = playerQuests.getQuestNameByDiaId(dt.id)

            if not playerQuests.isFinished(dt.id) and not playerQuests.isHidden(qName or "") then

                local currentIndex = playerQuests.getCurrentIndex(dt.id)
                if currentIndex and currentIndex ~= 0 then
                    if currentIndex < dt.index then
                        return itData
                    end
                else
                    return itData
                end

            end
        end
    end
end


---@param this any
---@param trackingInt AdvWMap_tracking.Interface
---@param interface AdvancedWorldMap.Interface?
function methods.updateAllQuestItemsMarker(this, trackingInt, interface)
    ---@module "scripts.quest_guider_lite.map.advWMapIntegration"
    this = this
    if not trackingInt then return end

    if this.allQuestItemsContainerTemplate then
        trackingInt.removeTemplate(this.allQuestItemsContainerTemplate)
        this.allQuestItemsContainerTemplate = nil
    end
    if this.allQuestItemsTemplate then
        trackingInt.removeTemplate(this.allQuestItemsTemplate)
        this.allQuestItemsTemplate = nil
    end

    ---@type table<string, any> by markerId
    this.allItemsMarkers = this.allItemsMarkers or {}
    for _, mId in pairs(this.allItemsMarkers) do
        trackingInt.removeMarker(mId)
    end
    this.allItemsMarkers = {}

    if not config.data.tracking.advWMapMarkers.enabled or not config.data.tracking.advWMapMarkers.details.questItems then
        return
    end


    ---@param itemData questDataGenerator.objectInfo
    local function createItemMarker(parentObject, recId, itemData, onUpdate)
        local objRec, objType = getObject(recId)
        if objRec and objRec.icon and vfs.fileExists(objRec.icon) then

            local stagesList = itemData.stages

            local qNames = {}
            local stages = {}
            for _, dt in pairs(stagesList) do
                stages[dt.id] = true
            end
            for diaId, _ in pairs(stages) do
                local qName = playerQuests.getQuestNameByDiaId(diaId)
                if qName then
                    qNames[qName] = true
                end
            end

            local objName = objRec.name and objRec.name ~= "" and objRec.name or nil
            local tooltipText = objName
            if  tooltipText then
                local defaultColor = interface and interface.getConfig().ui.defaultColor or config.data.ui.defaultColor
                tooltipText = l10n("questItemNameTooltip", {
                    item = string.format("#%s%s#%s", config.data.ui.defaultAltColor:asHex(), tooltipText, defaultColor:asHex())}
                )

                if next(qNames) then
                    qNames = tableLib.keys(qNames)
                    tooltipText = l10n("questItemFullTooltip", {
                        name = tooltipText,
                        list = stringLib.getValueEnumString(qNames, config.data.journal.objectNames)
                    })
                end
            end

            local hashId = recId.."_"..parentObject.id
            if this.allItemsMarkers[hashId] then
                trackingInt.removeMarker(this.allItemsMarkers[hashId])
            end

            local mId = trackingInt.addMarker{
                template = {
                    path = objRec.icon,
                    uiTemplate = markerTemplate,
                    size = util.vector2(1, 1) * config.data.tracking.advWMapMarkers.size * 0.6,
                    anchor = util.vector2(0.5, 0.5),
                    visible = this.allItemsMarkersVisible and this.storageData.allItemsVisibility or false,
                    tText = tooltipText,
                    onClick = commonInfo.advWMapQuestItemsCallback,
                    userData = {
                        type = "regularQuestItem",
                        itemData = itemData,
                        objectName = objName,
                    },
                },
                objects = {parentObject},
                active = true,
                priority = -200 + (itemTypePriority[tostring(objType)] or 0),
                onUpdate = onUpdate,
            }

            if mId then
                this.allItemsMarkers[hashId] = mId
            end

            return mId
        end
    end


    this.allQuestItemsContainerTemplate = this.allQuestItemsContainerTemplate or trackingInt.addTemplate{
        path = "white",
        size = util.vector2(1, 1),
        visible = false,
        userData = {
            type = "regularQuestItemPreset",
        },
    }

    this.allQuestItemsTemplate = this.allQuestItemsTemplate or trackingInt.addTemplate{
        path = "white",
        size = util.vector2(1, 1),
        visible = false,
        userData = {
            type = "regularQuestItemPreset",
        },
    }

    this.allQuestItemsContainerMarker = trackingInt.addMarker{
        template = this.allQuestItemsContainerTemplate,
        types = {"Container"},
        active = true,
        objValidateFn = function (marker, template, object)
            if not config.data.tracking.advWMapMarkers.enabled or
                not config.data.tracking.advWMapMarkers.details.questItems then return false end

            local threshold = config.data.tracking.advWMapMarkers.questItemLimit
            if threshold == 0 then return false end

            local hasQuestItem = false
            ---@type table<string, questDataGenerator.objectInfo>
            local itemData = {}

            local inventory = Container.content(object)
            for _, item in pairs(inventory:getAll()) do
                if not this.trackingLib.markerByObjectId[item.recordId] then
                    local dt = getValidQuestItemData(item.recordId)
                    if dt then
                        hasQuestItem = true
                        itemData[item.recordId] = dt
                    end
                end
            end

            for recId, dt in pairs(itemData) do
                local markerId
                markerId = createItemMarker(object, recId, dt, function ()
                    if not markerId then return end

                    if object:isValid() and Container.content(object):countOf(recId) > 0 then
                        return
                    end

                    trackingInt.removeMarker(markerId)
                end)
            end

            return false
        end,
    }

    this.allQuestItemsMarker = trackingInt.addMarker{
        template = this.allQuestItemsTemplate,
        types = {"Weapon", "Apparatus", "Armor", "Book", "Clothing", "Ingredient", "Light", "Lockpick", "Miscellaneous", "Potion", "Probe", "Repair"},
        active = true,
        objValidateFn = function (marker, template, object)
            if not config.data.tracking.advWMapMarkers.enabled or
                not config.data.tracking.advWMapMarkers.details.questItems then return false end

            if this.trackingLib.markerByObjectId[object.recordId] then return false end

            local dt = getValidQuestItemData(object.recordId)

            if dt then
                createItemMarker(object, object.recordId, dt)
            end

            return false
        end,
    }
end


---@param interface AdvancedWorldMap.Interface
---@param trackingInt AdvWMap_tracking.Interface
function methods.registerEvents(this, interface, trackingInt)
    ---@module "scripts.quest_guider_lite.map.advWMapIntegration"
    this = this
    local events = interface.events
end


return methods