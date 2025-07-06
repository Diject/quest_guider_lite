local storage = require('openmw.storage')
local async = require('openmw.async')

local tableLib = require("scripts.quest_guider_lite.utils.table")
local commonData = require("scripts.quest_guider_lite.common")


local this = {}

this.data = require("scripts.quest_guider_lite.config").data

this.storageSection = storage.playerSection(commonData.storageSectionName)
this.storageSection:subscribe(async:callback(function(section, key)
    if key then
        tableLib.setValueByPath(this.data, key, this.storageSection:get(key))
    else
        this.loadFromStorage()
    end
end))


function this.loadFromStorage()
    local data = this.storageSection:asTable() or {}
    for path, value in pairs(data) do
        tableLib.setValueByPath(this.data, path, value)
    end
end


this.loadFromStorage()


function this.setValue(str, val)
    this.storageSection:set(str, val)
    return tableLib.setValueByPath(this.data, str, val)
end

function this.getValue(str)
    return tableLib.getValueByPath(this.data, str)
end

return this