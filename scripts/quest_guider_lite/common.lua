local util = require('openmw.util')

local this = {}

this.dataStorageName = "QuestGuider:dataStorage"
this.localDataName = "QuestGuider:playerData"

this.defaultColorData = {202/255, 165/255, 96/255}
this.defaultColor = util.color.rgb(this.defaultColorData[1], this.defaultColorData[2], this.defaultColorData[3])

this.selectedColorData = {0.2, 1, 0.2}
this.selectedColor = util.color.rgb(this.selectedColorData[1], this.selectedColorData[2], this.selectedColorData[3])

this.journalDateColorData = {0.8, 0.2, 0.2}
this.journalDateColor = util.color.rgb(this.journalDateColorData[1], this.journalDateColorData[2], this.journalDateColorData[3])

this.playerQuestDataLabel = "playerQuests"

return this