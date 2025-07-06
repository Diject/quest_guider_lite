local tableLib = require("scripts.quest_guider_lite.utils.table")


local this = {}

---@class questGuider.config
this.default = {
    tracking = {
        minChance = 0.1,
        maxPos = 20,
    },
    journal ={
        objectNames = 3,
    },
    ui = {
        menuKey = "H",
        fontSize = 20,
    },
}


---@class questGuider.config
this.data = tableLib.deepcopy(this.default)

return this