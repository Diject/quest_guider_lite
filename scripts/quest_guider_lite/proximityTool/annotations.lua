---@class proximityTool.marker
---@field record string|proximityTool.record
---@field groupName string?
---@field positions proximityTool.positionData[]?
---@field objectId string?
---@field object any?
---@field objects string[]?
---@field itemId string?
---@field temporary boolean? if true, this marker will not be saved to the save file
---@field shortTerm boolean? if true, this marker will be deleted after the cell has changed

---@class proximityTool.marker.cellData
---@field id string?
---@field gridX integer?
---@field gridY integer?
---@field isExterior boolean

---@class proximityTool.positionData
---@field cell proximityTool.marker.cellData
---@field position {x: number, y: number, z: number}

---@class proximityTool.record
---@field name string?
---@field description string|string[]?
---@field note string?
---@field nameColor number[]?
---@field descriptionColor number[]|number[][]?
---@field noteColor number[]?
---@field icon string?
---@field iconColor number[]?
---@field iconRatio number? image height to width ratio
---@field alpha number?
---@field proximity number?
---@field priority number?
---@field temporary boolean? if true, this record will not be saved to the save file
---@field events table<string, function>?
---@field options proximityTool.record.options?

---@class proximityTool.record.options
---@field showGroupIcon boolean? *true* by default
---@field showNoteIcon boolean? *true* by default
---@field enableGroupEvent boolean? *true* by default

---@class proximityTool.hudm
---@field modName string required
---@field objects any[]? list of object references that this marker should track
---@field objectIds string[]? list of object record ids that this marker should track
---@field params table required. HUDM parameters
---@field version number HUDM version for this marker
---@field hidden boolean? if true, this marker will not be shown
---@field temporary boolean? if true, this marker will not be saved to the save file
---@field shortTerm boolean? if true, this marker will be removed after one of the tracked objects is removed



---@class proximityTool
---@field version integer
---@field addMarker fun(markerData: proximityTool.marker): string?, string?
---@field addRecord fun(recordData: proximityTool.record): string?
---@field update fun()
---@field updateRecord fun(id: string, recordData: proximityTool.record): boolean?
---@field registerEvent fun(eventId: string, recordId: string, func: fun(arg1: any, arg2: any)): boolean?
---@field removeRecord fun(id: string): boolean?
---@field removeMarker fun(id: string, groupId: string): boolean?
---@field setVisibility fun(id: string, groupId: string?, value: boolean): boolean?
---@field getMarkerData fun(id: string, groupId: string?): proximityTool.marker|proximityTool.record|nil
---@field addHUDM fun(hudmData: proximityTool.hudm): string?
---@field updateHUDM fun()
---@field removeHUDM fun(id: string): boolean?
---@field getHUDMdata fun(id: string): proximityTool.hudm?
---@field setHUDMvisibility fun(id: string, value: boolean): boolean?
---@field newRealTimer fun(duration: number, callback: fun(...), ...): function