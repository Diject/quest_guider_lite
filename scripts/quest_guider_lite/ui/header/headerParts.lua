local ui = require("openmw.ui")
local util = require("openmw.util")


local headerTextures = {
    ui.texture{ path = "textures/menu_head_block_top.dds" },
    ui.texture{ path = "textures/menu_head_block_right.dds" },
    ui.texture{ path = "textures/menu_head_block_bottom.dds" },
    ui.texture{ path = "textures/menu_head_block_left.dds" },
    ui.texture{ path = "textures/menu_head_block_middle.dds" },
    ui.texture{ path = "textures/menu_head_block_top_left_corner.dds" },
    ui.texture{ path = "textures/menu_head_block_top_right_corner.dds" },
    ui.texture{ path = "textures/menu_head_block_bottom_right_corner.dds" },
    ui.texture{ path = "textures/menu_head_block_bottom_left_corner.dds" },
}


local fullHeader = {
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[5],
            tileH = true,
            tileV = true,
            relativeSize = util.vector2(1, 1),
            position = util.vector2(2, 2),
            size = util.vector2(-4, -4),
        }
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[1],
            tileH = true,
            tileV = false,
            size = util.vector2(-4, 2),
            relativeSize = util.vector2(1, 0),
            position = util.vector2(2, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[2],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(-2, 2),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[3],
            tileH = true,
            tileV = false,
            size = util.vector2(-4, 2),
            relativeSize = util.vector2(1, 0),
            position = util.vector2(2, -2),
            relativePosition = util.vector2(0, 1),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[4],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(0, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[6],
            size = util.vector2(2, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[7],
            size = util.vector2(2, 2),
            position = util.vector2(-2, 0),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[8],
            size = util.vector2(2, 2),
            position = util.vector2(-2, -2),
            relativePosition = util.vector2(1, 1),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[9],
            size = util.vector2(2, 2),
            position = util.vector2(0, -2),
            relativePosition = util.vector2(0, 1),
        },
    },
}


local rightPart = {
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[2],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(-2, 2),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[7],
            size = util.vector2(2, 2),
            position = util.vector2(-2, 0),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[8],
            size = util.vector2(2, 2),
            position = util.vector2(-2, -2),
            relativePosition = util.vector2(1, 1),
        },
    },
}

local leftPart = {
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[4],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(0, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[6],
            size = util.vector2(2, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[9],
            size = util.vector2(2, 2),
            position = util.vector2(0, -2),
            relativePosition = util.vector2(0, 1),
        },
    },
}


local buttonDownTextures = {
    ui.texture{ path = "textures/menu_rightbuttondown_top.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_right.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_bottom.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_left.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_center.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_top_left.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_top_right.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_bottom_right.dds" },
    ui.texture{ path = "textures/menu_rightbuttondown_bottom_left.dds" },
}

local buttonUpTextures = {
    ui.texture{ path = "textures/menu_rightbuttonup_top.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_right.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_bottom.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_left.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_center.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_top_left.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_top_right.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_bottom_right.dds" },
    ui.texture{ path = "textures/menu_rightbuttonup_bottom_left.dds" },
}


local pinnedBtn = {
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[5],
            tileH = true,
            tileV = true,
            relativeSize = util.vector2(1, 1),
            position = util.vector2(2, 2),
            size = util.vector2(-4, -4),
        }
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[1],
            tileH = true,
            tileV = false,
            size = util.vector2(-4, 2),
            relativeSize = util.vector2(1, 0),
            position = util.vector2(2, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[2],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(-2, 2),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[3],
            tileH = true,
            tileV = false,
            size = util.vector2(-4, 2),
            relativeSize = util.vector2(1, 0),
            position = util.vector2(2, -2),
            relativePosition = util.vector2(0, 1),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[4],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(0, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[6],
            size = util.vector2(2, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[7],
            size = util.vector2(2, 2),
            position = util.vector2(-2, 0),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[8],
            size = util.vector2(2, 2),
            position = util.vector2(-2, -2),
            relativePosition = util.vector2(1, 1),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonDownTextures[9],
            size = util.vector2(2, 2),
            position = util.vector2(0, -2),
            relativePosition = util.vector2(0, 1),
        },
    },
}

local unpinnedBtn = {
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[5],
            tileH = true,
            tileV = true,
            relativeSize = util.vector2(1, 1),
            position = util.vector2(2, 2),
            size = util.vector2(-4, -4),
        }
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[1],
            tileH = true,
            tileV = false,
            size = util.vector2(-4, 2),
            relativeSize = util.vector2(1, 0),
            position = util.vector2(2, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[2],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(-2, 2),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[3],
            tileH = true,
            tileV = false,
            size = util.vector2(-4, 2),
            relativeSize = util.vector2(1, 0),
            position = util.vector2(2, -2),
            relativePosition = util.vector2(0, 1),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[4],
            tileH = false,
            tileV = true,
            size = util.vector2(2, -4),
            relativeSize = util.vector2(0, 1),
            position = util.vector2(0, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[6],
            size = util.vector2(2, 2),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[7],
            size = util.vector2(2, 2),
            position = util.vector2(-2, 0),
            relativePosition = util.vector2(1, 0),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[8],
            size = util.vector2(2, 2),
            position = util.vector2(-2, -2),
            relativePosition = util.vector2(1, 1),
        },
    },
    {
        type = ui.TYPE.Image,
        props = {
            resource = buttonUpTextures[9],
            size = util.vector2(2, 2),
            position = util.vector2(0, -2),
            relativePosition = util.vector2(0, 1),
        },
    },
}


return {
    full = fullHeader,
    left = leftPart,
    right = rightPart,
    pinnedBtn = pinnedBtn,
    unpinnedBtn = unpinnedBtn,
    textures = headerTextures
}