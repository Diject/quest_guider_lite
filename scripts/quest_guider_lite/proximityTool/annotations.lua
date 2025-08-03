---@class proximityTool.marker
---@field record string|proximityTool.record record information for the marker
---@field groupName string? group name for the marker. Markers with the same group name will be grouped
---@field positions proximityTool.positionData[]? positions that the marker will track
---@field objectId string? record id, objects with this id will be tracked by the marker. The name field will be automatically assigned as the object's name
---@field object any? GameObject that will be tracked by the marker. Not saved between game sessions
---@field objectIds string[]? several record ids, objects with these ids will be tracked by the marker
---@field itemId string? record id of the item, the presence of which is required for the tracked object
---@field temporary boolean? if true, the marker will not be saved to game save files
---@field shortTerm boolean? if true, the marker will be removed when changing location

---@class proximityTool.marker.cellData
---@field id string? cell id
---@field isExterior boolean required!

---@class proximityTool.positionData
---@field cell proximityTool.marker.cellData cell data
---@field position {x: number, y: number, z: number}

---@class proximityTool.record
---@field name string? display name for the marker(s)
---@field description string|string[]? description in the tooltip for the marker
---@field note string? short description under the marker name
---@field nameColor number[]? color of the name field
---@field descriptionColor number[]|number[][]? color(s) of the description field
---@field noteColor number[]? color(s) of the note field
---@field icon string? path to the icon displayed next to the name
---@field iconColor number[]? color of the icon
---@field iconRatio number? height to width ratio of the icon
---@field alpha number? transparency
---@field proximity number? distance from the object when the marker will be visible
---@field priority number? priority for the marker. Markers with higher priority will be higher in the list
---@field temporary boolean? if true, the record will not be saved to game save files
---@field events table<string, function>?
---@field options proximityTool.record.options? some additional options

---@class proximityTool.record.options
---@field showGroupIcon boolean? *true* by default
---@field showNoteIcon boolean? *true* by default
---@field enableGroupEvent boolean? *true* by default
---@field trackAllTypesTogether boolean? *false* by default

---@class proximityTool.hudm
---@field modName string required
---@field objects any[]? list of object references that this marker should track
---@field objectIds string[]? list of object record ids that this marker should track
---@field itemId string? markers will be removed for objects that do not have this item. Unresolved containers are considered as having it
---@field params table required. HUDM parameters
---@field version number HUDM version for this marker
---@field hidden boolean? if true, this marker will not be shown
---@field temporary boolean? if true, this marker will not be saved to the save file
---@field shortTerm boolean? if true, this marker will be removed after one of the tracked objects is invalidated



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