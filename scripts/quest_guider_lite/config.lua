local util = require('openmw.util')

local commonData = require("scripts.quest_guider_lite.common")
local tableLib = require("scripts.quest_guider_lite.utils.table")


local this = {}

---@class questGuider.config
this.default = {
    tracking = {
        autoTrack = true,
        trackDisabled = false,
        minChance = 0.1,
        maxPos = 20,
        proximity = 25000,
        questGiverProximity = 8000,
    },
    journal ={
        menuKey = "H",
        objectNames = 3,
        width = 1100,
        height = 700,
        position = {
            x = 0.2,
            y = 0.2,
        },
        listRelativeSize = 0.3,
    },
    ui = {
        fontSize = 20,
        defaultColor = commonData.defaultColor,
        backgroundColor = commonData.backgroundColor,
        disabledColor = commonData.disabledColor,
        dateColor = commonData.journalDateColor,
        selectionColor = commonData.selectedColor,
        shadowColor = commonData.selectedShadowColor,
        scrollArrowSize = 16,
    },
}


---@class questGuider.config
this.data = tableLib.deepcopy(this.default)

return this