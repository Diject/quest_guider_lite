local util = require('openmw.util')

local commonData = require("scripts.quest_guider_lite.common")
local tableLib = require("scripts.quest_guider_lite.utils.table")


local this = {}

---@class questGuider.config
this.default = {
    tracking = {
        autoTrack = true,
        trackDisabled = false,
        colored = true,
        minChance = 10, -- %
        maxPos = 20,
        proximity = 25000,
        questGiverProximity = 8000,
        hudMarkers = {
            enabled = true,
            range = 80,
            rayTracing = true,
            opacity = 100, -- %
        }
    },
    journal = {
        overrideJournal = false,
        menuKey = "H",
        objectNames = 3,
        widthProportional = 70, -- %
        heightProportional = 55, -- %
        width = 1100,
        height = 700,
        position = { -- %
            x = 20,
            y = 20,
        },
        listRelativeSize = 30, -- %
        trackedColorMarks = true,
        maxColorMarks = 10,
        textHeightMul = 0.5,
        textHeightMulRecord = 0.7,
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