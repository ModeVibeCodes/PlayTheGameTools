local _, addon = ...
local M, W = addon.EnhancedExperienceBar, addon.ConfigWidgets
if not M then return end
function M:CreateConfigPage(parent)
    local page = W.Page(parent, 620); self.page = page
    local function Toggles(entries)
        local items = {}
        for _, entry in ipairs(entries) do
            local key = entry[2]
            items[#items + 1] = {label = entry[1], get = function() return self.db[key] end,
                set = function(v) self:SetOption(key, v) end}
        end
        page:ToggleGrid(items)
    end
    local function Slider(label, key, suffix)
        local r = self.ranges[key]
        page.refreshers[#page.refreshers + 1] = W.Slider(page:Row(label, 48), r[1], r[2], r[3],
            function() return self.db[key] end, function(v) self:SetOption(key, v) end, suffix, true)
    end
    page:Section("General")
    page:ToggleGrid({{label = "Enable Enhanced Experience Bar", get = function() return self.enabled end,
        set = function(v) if self:CanConfigure() then addon:SetModuleEnabled(self.id, v) end end}})
    Toggles({{"Blizzard Style Texture", "blizzardStyle"}, {"Hide at Maximum Level", "hideAtMax"}})
    local help = W.Label(page:Row("Forecasts", 110),
        "Upper lane: rested bonus pool. Lower lane: completed quest reward XP. Both start at current XP and clip at the next level; labels show full percentages of this level. Rested does not boost quest rewards. Expand collapsed quest log headers for a complete estimate.", nil, 0, -4, 360, addon.Theme.muted)
    help:SetWordWrap(true)
    page:Section("Layout")
    Slider("Bar Width", "width"); Slider("Bar Height", "height"); Slider("Bar Scale", "scale", "%")
    Slider("Bar Opacity", "opacity", "%"); Slider("Forecast Opacity", "overlayOpacity", "%")
    Toggles({{"Show Rested Overlay", "showRestedOverlay"}, {"Show Quest Overlay", "showQuestOverlay"}})
    page:Section("Text")
    Toggles({{"Show Current XP Percent", "showXP"}, {"Show XP Values", "showValues"},
        {"Show Rested Percent", "showRested"}, {"Show Completed Quest Percent", "showQuests"}, {"Text Outline", "outline"}})
    local owner = {db = {appearance = self.db}}
    function owner:CanConfigure() return M:CanConfigure() end
    function owner:SetAppearance(key, value) return M:SetOption(key, value) end
    function owner:GetFonts() return M:GetFonts() end
    local _, refresh = W.FontDropdown(page:Row("Font"), owner); page.refreshers[#page.refreshers + 1] = refresh
    Slider("Bar Text Size", "fontSize"); Slider("Bar Text Vertical Offset", "textOffset")
    local align = W.Select(page:Row("Text Alignment", 48), 240,
        function() return {{id = "LEFT", label = "Left"}, {id = "CENTER", label = "Center"}, {id = "RIGHT", label = "Right"}} end,
        function() return self.db.align end, function(v) self:SetOption("align", v) end)
    page.refreshers[#page.refreshers + 1] = function() align:Refresh() end
    page:Section("Session")
    Toggles({{"Show Session Time", "showSession"}, {"Show XP per Hour", "showRate"}, {"Session Text Above Bar", "sessionAbove"}})
    Slider("Session Text Size", "sessionFontSize"); Slider("Session Text Gap", "sessionGap")
    local note = W.Label(page:Row("Session Scope", 80), "Session starts when enabled or after /reload. XP/hr includes observed XP gains and idle time. Reset Session starts a fresh measurement.", nil, 0, -4, 360, addon.Theme.muted)
    note:SetWordWrap(true)
    local reset = W.Button(page:Row("Session Tracking", 48), "Reset Session", 180, 28); reset:SetPoint("LEFT")
    reset:SetScript("OnClick", function() self:ResetSession() end)
    page:Section("Colors")
    Toggles({{"Use Native XP Colors", "nativeColors"}})
    for _, item in ipairs({{"Normal XP Color", "normalColor"}, {"Rested XP Color", "restedColor"},
        {"Quest Forecast Color", "questColor"}, {"Text Color", "textColor"},
        {"Background Color", "backgroundColor"}, {"Border Color", "borderColor"}}) do
        local native = item[2] == "normalColor" or item[2] == "restedColor"
        W.ColorRow(page, owner, item[1], item[2], function() return not native or not self.db.nativeColors end)
    end
    page:Section("Position")
    W.PositionControls(page, self)
    page:Finish(); return page
end
