local util = require('openmw.util')

local this = {}

this.dataStorageName = "QuestGuider:dataStorage"
this.localDataName = "QuestGuider:playerData"

this.defaultColorData = {202/255, 165/255, 96/255}
this.defaultColor = util.color.rgb(this.defaultColorData[1], this.defaultColorData[2], this.defaultColorData[3])

this.playerQuestDataLabel = "playerQuests"

return this