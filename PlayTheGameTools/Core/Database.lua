local _, addon = ...

local SCHEMA_VERSION = 1
local defaults = {
    schemaVersion = SCHEMA_VERSION,
    developer = { interruptLogging = false },
    modules = {
        InterruptTracker = {
            enabled = false, visibility = "party", includePlayer = true, hideUnavailable = false, approximation = true,
            excludeHealers = true, blacklist = {},
            partyPlacement = "below", matchAnchorWidth = false,
            appearance = { font = "game", fontMedia = "", fontSize = 12, outline = false,
                showIcon = true, showName = true, showText = true, showBar = true, showBackground = true,
                iconSize = 20, iconGap = 4, rowHeight = 24, rowSpacing = 3, scale = 1,
                barBorderStyle = "none", barBorderSize = 1, barBorderOpacity = 1, barBorderColor = {1,1,1},
                iconBorderStyle = "none", iconBorderSize = 1, iconBorderOpacity = 1, iconBorderColor = {1,1,1},
                barWidth = 270, barTexture = "default", barColorMode = "custom", barColor = { 128/255,239/255,128/255 },
                growth = "down", showReady = true, nameClassColor = true, nameColor = { 1,1,1 },
                cooldownBarMode = "normal", cooldownBarColor = {201/255,84/255,84/255},
                customCooldownText = false, cooldownTextColor = {201/255,84/255,84/255},
                textColor = { 1, 1, 1 }, backgroundColor = { 28 / 255, 38 / 255, 53 / 255 }, backgroundOpacity = 0.6 },
        },
        battleRez = {
            enabled = false, visibility = "encounter", hideUnavailable = true, showRecharge = true, showMax = true,
            appearance = { format = "maximum", font = "game", fontMedia = "", fontSize = 20, outline = false,
                textColor = { 1, 1, 1 }, backgroundColor = { 28 / 255, 38 / 255, 53 / 255 }, backgroundOpacity = 0.4, scale = 1 },
        },
        combatTimer = {
            enabled = false, position = { x = 0, y = -240, target = "screen", placement = "center" },
            appearance = {
                format = "plain", font = "game", fontMedia = "", fontSize = 20, outline = false,
                textColor = { 1, 1, 1 }, backgroundColor = { 28 / 255, 38 / 255, 53 / 255 },
                backgroundOpacity = 0.4, scale = 1,
            },
            locked = true, showOutOfCombat = false,
        },
    },
    window = { x = 0, y = 0 },
}
if addon.Edition and addon.Edition.name == "Forever" then
    -- Only supported modules receive defaults; retain dormant Retail/unknown keys.
    defaults = { schemaVersion = SCHEMA_VERSION, developer = {},
        modules = { combatTimer = defaults.modules.combatTimer,
            foreverAutomation = { enabled = false, autoLoot = false,
                autoAccept = true, autoTurnIn = true, bypassModifier = "shift",
                sellJunk = true, sellGrayEquipment = false, repair = true, maxRepairCostPercent = 35,
                autoGossip = true } }, window = { x = 0, y = 0 } }
end

-- Fill missing keys only; retain unknown keys for future migrations.
local function ApplyDefaults(target, source, path)
    for key, value in pairs(source) do
        local keyPath = path .. "." .. key
        if type(value) == "table" then
            if target[key] == nil then
                target[key] = {}
            end
            assert(type(target[key]) == "table", keyPath .. " must be a table; settings were not reset.")
            ApplyDefaults(target[key], value, keyPath)
        elseif target[key] == nil then
            target[key] = value
        else
            assert(type(target[key]) == type(value), keyPath .. " has an invalid type; settings were not reset.")
        end
    end
end

-- Pure preparation on a detached candidate; profile migration publishes only
-- after this and module preference validation succeed.
function addon:PrepareDatabase(database)
    assert(type(database)=="table", "PTGToolsDB must be a table; settings were not reset.")
    local version=database.schemaVersion
    assert(version==nil or version==SCHEMA_VERSION,"Play The Game Tools: unsupported database version; settings were not reset.")
    ApplyDefaults(database,defaults,"PTGToolsDB")
    for _,key in ipairs({"x","y"}) do
        local value=database.window[key]
        assert(value==value and math.abs(value)<math.huge,"Play The Game Tools: invalid window position.")
    end
    return database
end
function addon:InitializeDatabase()
    -- One-time adoption of the pre-rename table. Players rename
    -- SavedVariables/ModeTools.lua to PlayTheGameTools.lua; the table is moved,
    -- never reset, and the legacy name is cleared only after it was adopted.
    if PTGToolsDB == nil and type(ModeToolsDB) == "table" then
        PTGToolsDB = ModeToolsDB
        ModeToolsDB = nil
    end
    if PTGToolsDB == nil then
        PTGToolsDB = {}
    end
    assert(type(PTGToolsDB) == "table", "PTGToolsDB must be a table; settings were not reset.")
    self.ProfileManager:Initialize(PTGToolsDB)
end
