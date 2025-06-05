local util = require('openmw.util')

local this = {}

function this.copyVector3(vector)
    return util.vector3(vector.x, vector.y, vector.z)
end


return this