local _, addon = ...

-- Palette shared by the shell, settings controls and ModeTools edit overlays.
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


-- Configuration-only palette. Gameplay consumers keep addon.Theme unchanged.
addon.InterfaceTheme = {
    primary = { 214 / 255, 193 / 255, 155 / 255, 1 }, -- champagne #D6C19B
    enabled = { 128 / 255, 239 / 255, 128 / 255, 1 },
    off = { 0.91, 0.38, 0.36, 1 },
    unavailable = { 0.48, 0.49, 0.50, 1 },
    highlight = { 0.98, 0.93, 0.83, 1 },
    secondary = { 0.74, 0.70, 0.63, 1 },
    surface = { 0.29, 0.28, 0.26, 1 },
    background = { 32 / 255, 32 / 255, 32 / 255, 1 },
    panel = { 44 / 255, 44 / 255, 44 / 255, 1 },
    text = { 0.89, 0.88, 0.85, 1 },
    muted = { 0.65, 0.64, 0.60, 1 },
    ink = { 0.09, 0.085, 0.075, 1 },
    spacing = addon.Theme.spacing,
}
