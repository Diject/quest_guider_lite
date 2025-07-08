local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates

local config = require("scripts.quest_guider_lite.configLib")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local interval = require("scripts.quest_guider_lite.ui.interval")


local this = {}


---@param params {meta : questGuider.ui.questBoxMeta?, recordInfo : questGuider.playerQuest.storageQuestInfo?, fontSize : integer?}
function this.getContentForTooltip(params)
    if not params or (not params.meta and not params.recordInfo) then return ui.content{} end

    local meta = params.meta
    local recordInfo = params.recordInfo

    local list = {}

    if meta then
        local arrayIndexByDiaId = {}
        local count = 1
        for _, info in ipairs(meta.params.playerQuestData.list) do
            if not arrayIndexByDiaId[info.diaId] then
                arrayIndexByDiaId[info.diaId] = count
                table.insert(list, {diaId = info.diaId, index = info.index})
                count = count + 1
            else
                list[arrayIndexByDiaId[info.diaId]].index = info.index
            end
        end
    elseif recordInfo then
        table.insert(list, {diaId = recordInfo.diaId, index = recordInfo.index})
    end

    local idStr
    for _, qData in ipairs(list) do
        if not idStr then
            idStr = string.format("ID: \"%s\" (%s)", qData.diaId, tostring(qData.index))
        else
            idStr = string.format("%s, \"%s\" (%s)", idStr, qData.diaId, tostring(qData.index))
        end
    end
    idStr = idStr or ""

    local startedInStr = "Received in ???"
    if meta and meta.params.playerQuestData.list[1] then
        local firstRecordData = meta.params.playerQuestData.list[1]
        if firstRecordData.cellData then
            startedInStr = string.format("Started in \"%s\"", firstRecordData.cellData.name)
        end
    elseif recordInfo and recordInfo.cellData then
        startedInStr = string.format("Received in \"%s\"", recordInfo.cellData.name)
    end

    local width = config.data.journal.width / 3
    local fontSize = params.fontSize or (meta and meta.params.fontSize) or 18
    local idTextHeight = uiUtils.getTextHeight(idStr, fontSize, width, config.data.journal.textHeightMul)
    local startedInHeight = uiUtils.getTextHeight(startedInStr, fontSize, width, config.data.journal.textHeightMul)

    return ui.content{
        {
            template = templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = idStr,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                size = util.vector2(width, idTextHeight),
                textSize = fontSize,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Start,
            },
        },
        interval(0, fontSize),
        {
            template = templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = startedInStr,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                size = util.vector2(width, startedInHeight),
                textSize = fontSize,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Start,
            },
        },
    }
end

return this