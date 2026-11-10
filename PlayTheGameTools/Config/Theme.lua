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

-- Configuration-only palettes. Gameplay consumers keep addon.Theme unchanged.
-- Modern: graphite neutrals with one mint accent. The accent marks state only
-- (on, selected, focused); headings and body copy stay neutral.
-- Surfaces step in clear increments so the eye can tell them apart: the
-- sidebar is recessed below the canvas, popups and resting controls sit above
-- it, and hover is one more step up. Control edges (buttons, inputs, boxes,
-- slider tracks) reach ~3:1 against the canvas so every target is findable;
-- row dividers stay quiet at ~1.5:1 so they group without striping.
-- Contrast on the canvas: text ~14:1, secondary ~9:1, muted ~6:1,
-- unavailable ~3.5:1.
local MODERN = {
    -- Accent and state
    primary = RGB(127, 219, 151),      -- #7FDB97 mint, kin to the gameplay #80EF80
    enabled = RGB(127, 219, 151),
    off = RGB(146, 152, 161),          -- neutral: "off" is a state, not an error
    unavailable = RGB(106, 111, 120),
    highlight = RGB(242, 243, 244),
    ink = RGB(12, 26, 16),             -- text placed on the accent
    -- Surfaces, darkest to lightest
    sidebar = RGB(15, 16, 19),         -- recessed navigation column
    field = RGB(13, 14, 17),           -- text inputs sit below the canvas
    background = RGB(23, 24, 28),      -- window canvas
    panel = RGB(33, 35, 41),           -- popups, dialogs
    surface = RGB(39, 42, 49),         -- resting controls, selected rows
    hover = RGB(52, 56, 65),
    -- Hairlines
    line = RGB(52, 55, 64),            -- dividers
    lineStrong = RGB(98, 103, 115),    -- control edges
    -- Type: off-white rather than pure white keeps long reading soft.
    text = RGB(226, 228, 232),
    heading = RGB(236, 237, 240),
    secondary = RGB(180, 185, 193),
    muted = RGB(146, 152, 161),
}

-- Blizzard: the stock look (gold headings, warm parchment labels, the stock
-- dialog, button, checkbox and input art from Config/Widgets.lua), tuned for
-- long reading. Text is warm off-white rather than pure white and gold is kept
-- for headings and button labels, so nothing on the dark stone glares.
-- Contrast on the canvas: text ~13:1, labels ~9:1, muted ~6:1, hairlines ~1.4:1.
local BLIZZARD = {
    primary = { 0.90, 0.74, 0.26, 1 },     -- accent: focus, slider fill, selection edge
    enabled = { 0.42, 0.80, 0.42, 1 },     -- calm green, not neon
    off = { 0.55, 0.53, 0.50, 1 },
    unavailable = { 0.36, 0.35, 0.33, 1 },
    highlight = { 1, 0.95, 0.84, 1 },      -- hovered labels
    ink = { 0.1, 0.07, 0, 1 },
    background = { 0.035, 0.033, 0.03, 1 },
    sidebar = { 0, 0, 0, 0.3 },
    panel = { 0.045, 0.042, 0.04, 1 },     -- opaque: popups never show the world through
    surface = { 0.17, 0.14, 0.08, 0.7 },
    hover = { 0.24, 0.20, 0.11, 0.75 },
    field = { 0, 0, 0, 0.5 },
    line = { 0.36, 0.31, 0.22, 0.5 },
    lineStrong = { 0.50, 0.43, 0.30, 1 },
    text = { 0.85, 0.83, 0.77, 1 },
    heading = { 0.98, 0.80, 0.12, 1 },     -- stock gold, headings only
    secondary = { 0.76, 0.70, 0.55, 1 },   -- parchment for labels and values
    muted = { 0.58, 0.56, 0.52, 1 },
}

-- mode: configuration-only graphite surfaces and a cyan accent. Existing palettes,
-- gameplay colors and the default theme remain unchanged.
local MODE = {
    primary = RGB(0, 240, 255), enabled = RGB(127, 219, 151),
    off = RGB(179, 179, 179), unavailable = RGB(114, 114, 114),
    highlight = RGB(212, 212, 212), ink = RGB(24, 24, 24),
    sidebar = RGB(35, 35, 35), field = RGB(37, 37, 37),
    background = RGB(43, 43, 43), panel = RGB(48, 48, 48),
    surface = RGB(53, 53, 53), hover = RGB(53, 53, 53),
    line = RGB(66, 66, 66), lineStrong = RGB(179, 179, 179),
    text = RGB(212, 212, 212), heading = RGB(212, 212, 212),
    secondary = RGB(179, 179, 179), muted = RGB(160, 160, 160),
}

-- Saved values are ids; an unknown id falls back to the default at runtime
-- and is never rewritten.
addon.InterfaceThemes = {
    order = { "modern", "blizzard", "mode" },
    default = "modern",
    modern = { label = "Modern", palette = MODERN },
    blizzard = { label = "Blizzard", palette = BLIZZARD, blizzardArt = true },
    mode = { label = "mode", palette = MODE },
}

local function Copy(color) return { color[1], color[2], color[3], color[4] or 1 } end

addon.InterfaceTheme = {
    id = "modern",
    -- One spacing scale and one font scale for every settings surface.
    spacing = addon.Theme.spacing,
    fontSize = { small = 11, body = 12, group = 13, section = 15, page = 18, display = 20 },
}
for key, color in pairs(MODERN) do addon.InterfaceTheme[key] = Copy(color) end

function addon:ResolveInterfaceTheme(id)
    local themes = self.InterfaceThemes
    if type(id) == "string" and themes[id] and themes[id].palette then return id end
    return themes.default
end

-- Colors are rewritten in place: settings files hold addon.InterfaceTheme and
-- its color tables as upvalues. Call before any settings frame is built; frames
-- keep the colors they were drawn with until the next UI reload.
function addon:ApplyInterfaceTheme(id)
    id = self:ResolveInterfaceTheme(id)
    local theme, T = self.InterfaceThemes[id], self.InterfaceTheme
    for key, color in pairs(theme.palette) do
        local target = T[key]
        if target then
            target[1], target[2], target[3], target[4] = color[1], color[2], color[3], color[4] or 1
        else
            T[key] = Copy(color)
        end
    end
    T.id, T.blizzardArt = id, theme.blizzardArt == true
    self.appliedInterfaceTheme = id
    return id
end

-- Saves the choice to the active profile and requests a reload; returning
-- to the theme already on screen withdraws that request.
function addon:SetInterfaceTheme(id)
    local theme = self.InterfaceThemes[id]
    assert(type(id) == "string" and theme and theme.palette, "Play The Game Tools: unknown interface theme.")
    self.db.window.theme = id
    if id == self.appliedInterfaceTheme then
        self.ReloadManager:Clear("interfaceTheme")
    else
        self.ReloadManager:Request("interfaceTheme", "Apply interface theme: " .. theme.label .. ".")
    end
    if self.configWindow and self.RefreshConfig then self:RefreshConfig() end
end
