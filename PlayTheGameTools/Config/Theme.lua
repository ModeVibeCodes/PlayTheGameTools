local _, addon = ...

-- Palette shared by the shell, settings controls and PlayTheGameTools edit overlays.
addon.Theme = {
    primary = { 128 / 255, 239 / 255, 128 / 255, 1 }, -- #80EF80
    secondary = { 230 / 255, 184 / 255, 1, 1 },      -- #E6B8FF
    surface = { 104 / 255, 104 / 255, 104 / 255, 1 }, -- #686868
    background = { 0.075, 0.082, 0.09, 1 },
    panel = { 0.105, 0.114, 0.122, 1 },
    text = { 0.94, 0.95, 0.95, 1 },
    muted = { 0.72, 0.75, 0.77, 1 },
    ink = { 0.06, 0.08, 0.065, 1 },
    spacing = { small = 8, medium = 16, large = 24 },
}

local function RGB(r, g, b, a) return { r / 255, g / 255, b / 255, a or 1 } end

-- Configuration-only palette. Gameplay consumers keep addon.Theme unchanged.
-- Graphite neutrals with one mint accent. The accent marks state only
-- (on, selected, focused); headings and body copy stay neutral.
addon.InterfaceTheme = {
    -- Accent and state
    primary = RGB(127, 219, 151),      -- #7FDB97 mint, kin to the gameplay #80EF80
    enabled = RGB(127, 219, 151),
    off = RGB(128, 133, 141),          -- neutral: "off" is a state, not an error
    unavailable = RGB(80, 84, 91),
    highlight = RGB(242, 243, 244),
    ink = RGB(12, 26, 16),             -- text placed on the accent
    -- Surfaces, darkest to lightest
    background = RGB(15, 16, 18),      -- window canvas
    sidebar = RGB(20, 21, 24),
    panel = RGB(24, 25, 29),           -- popups, dialogs
    surface = RGB(31, 33, 37),         -- resting controls
    hover = RGB(38, 40, 45),
    field = RGB(11, 12, 14),           -- text inputs sit below the canvas
    -- Hairlines
    line = RGB(36, 38, 43),
    lineStrong = RGB(58, 61, 68),
    -- Type
    text = RGB(231, 232, 234),
    secondary = RGB(169, 173, 180),
    muted = RGB(128, 133, 141),
    -- One spacing scale and one font scale for every settings surface.
    spacing = addon.Theme.spacing,
    fontSize = { small = 11, body = 12, group = 13, section = 15, page = 18, display = 20 },
}
