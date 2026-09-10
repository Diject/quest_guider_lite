local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')

local borders = require("scripts.quest_guider_lite.ui.borders")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local config = require("scripts.quest_guider_lite.config")

local borderTextures = borders.textures

local this = {}

uiUtils.customTemplates = this


this.box = {
    type = ui.TYPE.Widget,
    content = ui.content{
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[1],
                tileH = false,
                tileV = true,
                size = util.vector2(2, 0),
                relativeSize = util.vector2(0, 1),
                position = util.vector2(0, 2),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[2],
                tileH = false,
                tileV = true,
                size = util.vector2(2, 0),
                relativeSize = util.vector2(0, 1),
                position = util.vector2(2, 2),
                relativePosition = util.vector2(1, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[3],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 2),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(2, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[4],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 2),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(2, 2),
                relativePosition = util.vector2(0, 1),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[5],
                size = util.vector2(2, 2),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[6],
                size = util.vector2(2, 2),
                position = util.vector2(2, 0),
                relativePosition = util.vector2(1, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[7],
                size = util.vector2(2, 2),
                position = util.vector2(0, 2),
                relativePosition = util.vector2(0, 1),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[8],
                size = util.vector2(2, 2),
                position = util.vector2(2, 2),
                relativePosition = util.vector2(1, 1),
            },
        },
        {
            external = { slot = true },
            props = {
                position = util.vector2(2, 2),
                relativeSize = util.vector2(1, 1),
            }
        }
    },
}

this.boxSolid = auxUi.deepLayoutCopy(this.box)
this.boxSolid.type = ui.TYPE.Container
this.boxSolid.content:insert(1, {
    type = ui.TYPE.Image,
    props = {
        resource = uiUtils.whiteTexture,
        color = config.data.ui.backgroundColor,
        relativeSize = util.vector2(1, 1),
        size = util.vector2(4, 4),
        alpha = config.data.ui.backgroundAlpha ~= 100 and config.data.ui.backgroundAlpha * 0.01 or nil
    },
})

this.boxSolidOpaque = auxUi.deepLayoutCopy(this.box)
this.boxSolidOpaque.type = ui.TYPE.Container
this.boxSolidOpaque.content:insert(1, {
    type = ui.TYPE.Image,
    props = {
        resource = uiUtils.whiteTexture,
        color = config.data.ui.backgroundColor,
        relativeSize = util.vector2(1, 1),
        size = util.vector2(4, 4),
    },
})

this.boxSolidThick = {
    type = ui.TYPE.Container,
    content = ui.content{
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                color = config.data.ui.backgroundColor,
                relativeSize = util.vector2(1, 1),
                size = util.vector2(8, 8),
                alpha = config.data.ui.backgroundAlpha ~= 100 and config.data.ui.backgroundAlpha * 0.01 or nil
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[9],
                tileH = false,
                tileV = true,
                size = util.vector2(4, 0),
                relativeSize = util.vector2(0, 1),
                position = util.vector2(0, 4),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[10],
                tileH = false,
                tileV = true,
                size = util.vector2(4, 0),
                relativeSize = util.vector2(0, 1),
                position = util.vector2(4, 4),
                relativePosition = util.vector2(1, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[11],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 4),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(4, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[12],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 4),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(4, 4),
                relativePosition = util.vector2(0, 1),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[13],
                size = util.vector2(4, 4),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[14],
                size = util.vector2(4, 4),
                position = util.vector2(4, 0),
                relativePosition = util.vector2(1, 0),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[15],
                size = util.vector2(4, 4),
                position = util.vector2(0, 4),
                relativePosition = util.vector2(0, 1),
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borderTextures[16],
                size = util.vector2(4, 4),
                position = util.vector2(4, 4),
                relativePosition = util.vector2(1, 1),
            },
        },
        {
            external = { slot = true },
            props = {
                position = util.vector2(4, 4),
                relativeSize = util.vector2(1, 1),
            }
        }
    },
}


this.btnBoxSolidThick = {
    type = ui.TYPE.Container,
    content = ui.content{
        -- {
        --     type = ui.TYPE.Image,
        --     props = {
        --         resource = uiUtils.whiteTexture,
        --         color = config.data.ui.backgroundColor,
        --         relativeSize = util.vector2(1, 1),
        --         size = util.vector2(8, 8)
        --     },
        -- },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borders.textures[11],
                tileH = true,
                tileV = false,
                size = util.vector2(1, 4),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(4, 4),
                relativePosition = util.vector2(0, 1),
            },
        }
    },
}

this.btnBoxSolidThick.content:add {
    external = { slot = true },
    props = {
        position = util.vector2(4, 4),
        relativeSize = util.vector2(1, 1),
    }
}

this.underlineBoxThin = {
    type = ui.TYPE.Container,
    content = ui.content{
        {
            type = ui.TYPE.Image,
            props = {
                resource = borders.textures[3],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 2),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(2, 2),
                relativePosition = util.vector2(0, 1),
            },
        }
    },
}

this.underlineBoxThin.content:add {
    external = { slot = true },
    props = {
        position = util.vector2(2, 2),
        relativeSize = util.vector2(1, 1),
    }
}

this.longHorizontalLineThin = {
    type = ui.TYPE.Image,
    props = {
        resource = ui.texture{ path = "textures/menu_thin_border_top.dds" },
        tileH = true,
        tileV = false,
        size = util.vector2(0, 1),
        relativeSize = util.vector2(0.8, 0),
        relativePosition = util.vector2(0.1, 0),
    },
}

this.fullHorizontalLineThin = {
    type = ui.TYPE.Image,
    props = {
        resource = ui.texture{ path = "textures/menu_thin_border_top.dds" },
        tileH = true,
        tileV = false,
        size = util.vector2(0, 1),
        relativeSize = util.vector2(1, 0),
        relativePosition = util.vector2(0.1, 0),
    },
}

-- use the simpler and more performant version for backgroundAlpha == 100, otherwise use a version that has a border around the content
this.journalEntryBackgroundContainer = config.data.ui.backgroundAlpha == 100 and {
    type = ui.TYPE.Container,
    content = ui.content{
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                color = config.data.ui.defaultColor,
                relativeSize = util.vector2(1, 1),
                size = util.vector2(6, 6),
                alpha = 0.25,
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                color = config.data.ui.backgroundColor,
                relativeSize = util.vector2(1, 1),
                size = util.vector2(2, 2),
                position = util.vector2(2, 2),
            },
        },
        {
            external = { slot = true },
            props = {
                position = util.vector2(3, 3),
                relativeSize = util.vector2(1, 1),
                size = util.vector2(3, 3),
            }
        }
    },
} or {
    type = ui.TYPE.Container,
    content = ui.content{
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                tileH = true,
                tileV = false,
                color = config.data.ui.defaultColor,
                relativeSize = util.vector2(1, 0),
                size = util.vector2(6, 3),
                alpha = 0.25,
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                tileH = true,
                tileV = false,
                color = config.data.ui.defaultColor,
                relativePosition = util.vector2(0, 1),
                position = util.vector2(0, 3),
                relativeSize = util.vector2(1, 0),
                size = util.vector2(6, 3),
                alpha = 0.25,
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                tileH = false,
                tileV = true,
                color = config.data.ui.defaultColor,
                position = util.vector2(0, 3),
                relativeSize = util.vector2(0, 1),
                size = util.vector2(3, 0),
                alpha = 0.25,
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                tileH = false,
                tileV = true,
                color = config.data.ui.defaultColor,
                relativePosition = util.vector2(1, 0),
                position = util.vector2(3, 3),
                relativeSize = util.vector2(0, 1),
                size = util.vector2(3, 0),
                alpha = 0.25,
            },
        },
        {
            external = { slot = true },
            props = {
                position = util.vector2(3, 3),
                relativeSize = util.vector2(1, 1),
                size = util.vector2(3, 3),
            }
        }
    },
}


return this