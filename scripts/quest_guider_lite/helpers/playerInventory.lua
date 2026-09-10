local playerRef = require("openmw.self")
local Actor = require("openmw.types").Actor
local core = require("openmw.core")

local inventory = Actor.inventory(playerRef)


local this = {}

---@type table<string, integer> by item record id, item count
this.items = {}
---@type table<string, integer> by item record id, item count
this.difference = {}


function this.snapshot(doNotClearDifference)
    this.difference = doNotClearDifference and this.difference or {}
    local newItems = {}
    for _, item in pairs(inventory:getAll()) do
        local id = item.recordId
        newItems[id] = (newItems[id] or 0) + item.count
        if not this.items[id] then
            this.difference[id] = (this.difference[id] or 0) + item.count
        end
    end

    for id, count in pairs(this.items) do
        local newCount = newItems[id] or 0
        if newCount ~= count then
            this.difference[id] = (this.difference[id] or 0) + newCount - count
        end
    end

    this.items = newItems
end


function this.getCount(itemId)
    return inventory:countOf(itemId) or 0
end


return this