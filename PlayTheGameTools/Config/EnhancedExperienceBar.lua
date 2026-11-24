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
        return page:ToggleGrid(items)
    end
    local function Slider(label, key, suffix)
        local r = self.ranges[key]
        page.refreshers[#page.refreshers + 1] = W.Slider(page:Row(label, 48), r[1], r[2], r[3],
            function() return self.db[key] end, function(v) self:SetOption(key, v) end, suffix, true)
    end
    local function Select(label, key, choices)
        local button = W.Select(page:Row(label, 48), 260, function() return choices end,
            function()
                local value = self.db[key]
                for _, choice in ipairs(choices) do if choice.id == value then return value, choice.label end end
                return value
            end, function(v) self:SetOption(key, v) end)
        page.refreshers[#page.refreshers + 1] = function() button:Refresh() end
    end
    local owner = {db = {appearance = self.db}}
    function owner:CanConfigure() return M:CanConfigure() end
    function owner:SetAppearance(key, value) return M:SetOption(key, value) end
    function owner:GetFonts() return M:GetFonts() end
    local alignment = {{id = "LEFT", label = "Left"}, {id = "CENTER", label = "Center"}, {id = "RIGHT", label = "Right"}}
    local separators = {{id = "dash", label = "Dash (-)"}, {id = "dot", label = "Dot (·)"}}
    page:Section("General")
    page:Section("Other XP Bars")
    -- The module switch chooses the PTG bar; these hide the other bars.
    Toggles({{"Hide Blizzard XP Bar", "hideBlizzardXP"}})
    -- Only offered while Ellesmere's action bars (which own its XP bar) are loaded.
    Toggles({{"Hide Ellesmere XP Bar", "hideEllesmereXP"}})
    page.ellesmereRow = page.rows[#page.rows]
    page.ellesmereRow.visibleWhen = function() return self:EllesmereLoaded() end
    page.searchEntries[#page.searchEntries].available = page.ellesmereRow.visibleWhen
    page.refreshers[#page.refreshers + 1] = function() page:Layout() end
    -- At maximum level the bar hides itself; there is no switch for it.
    page:Section("Bar Appearance")
    local texture = W.Select(page:Row("Bar Texture", 48), 280, function() return self:GetTextureChoices() end,
        function()
            for _, choice in ipairs(self:GetTextureChoices()) do
                if choice.id == self.db.barTexture then return choice.id, choice.label end
            end
            return self.db.barTexture, addon.Media:MediaLabel(self.db.barTexture:sub(7))
        end, function(v) self:SetOption("barTexture", v) end)
    page.textureDropdown = texture
    page.refreshers[#page.refreshers + 1] = function() texture:Refresh() end
    page:Section("Layout")
    Slider("Bar Width", "width"); Slider("Bar Height", "height"); Slider("Bar Scale", "scale", "%")
    Slider("Bar Opacity", "opacity", "%")
    Slider("Rested Overlay Opacity", "restedOpacity", "%"); Slider("Quest Overlay Opacity", "questOpacity", "%")
    Toggles({{"Show Rested Overlay", "showRestedOverlay"}, {"Show Quest Overlay", "showQuestOverlay"}})
    page:Section("Bar Text")
    Toggles({{"Show Current XP Percent", "showXP"}, {"Show XP Values", "showValues"},
        {"Show Rested Percent", "showRested"}, {"Show Quest Log XP", "showQuests"}, {"Bar Text Outline", "outline"}})
    Select("Quest Log XP Format", "questFormat", {{id = "percent", label = "Percent"}, {id = "value", label = "XP Amount"}, {id = "both", label = "Percent and XP Amount"}})
    local _, refresh = W.FontDropdown(page:Row("Bar Font"), owner); page.refreshers[#page.refreshers + 1] = refresh
    Slider("Bar Text Size", "fontSize"); Slider("Bar Text Vertical Offset", "textOffset")
    Slider("Bar Text Opacity", "textOpacity", "%"); W.ColorRow(page, owner, "Bar Text Color", "textColor")
    Select("Bar Text Alignment", "align", alignment); Select("Bar Text Separator", "separator", separators)
    page:Section("Session Text")
    Toggles({{"Show Session Time", "showSession"}, {"Show XP per Hour", "showRate"}, {"Session Text Above Bar", "sessionAbove"}})
    Slider("Session Text Size", "sessionFontSize"); Slider("Session Text Gap", "sessionGap")
    Slider("Session Text Width", "sessionWidth"); Slider("Session Horizontal Offset", "sessionX")
    Slider("Session Text Opacity", "sessionOpacity", "%"); Toggles({{"Session Text Outline", "sessionOutline"}})
    local sessionKeys = {font = "sessionFont", fontMedia = "sessionFontMedia"}
    local sessionOwner = {db = {appearance = setmetatable({}, {__index = function(_, key) return M.db[sessionKeys[key] or key] end})}}
    function sessionOwner:CanConfigure() return M:CanConfigure() end
    function sessionOwner:SetAppearance(key, value) return M:SetOption(sessionKeys[key] or key, value) end
    function sessionOwner:GetFonts() return M:GetFonts() end
    local _, sessionRefresh = W.FontDropdown(page:Row("Session Font"), sessionOwner)
    page.refreshers[#page.refreshers + 1] = sessionRefresh
    W.ColorRow(page, owner, "Session Text Color", "sessionTextColor")
    Select("Session Text Alignment", "sessionAlign", alignment); Select("Session Text Separator", "sessionSeparator", separators)
    local reset = W.Button(page:Row("Session Tracking", 48), "Reset Session", 180, 28); reset:SetPoint("LEFT")
    reset:SetScript("OnClick", function() self:ResetSession() end)
    page:Section("Colors")
    Toggles({{"Use Native XP Colors", "nativeColors"}})
    for _, item in ipairs({{"Normal XP Fill Color", "normalColor"}, {"Rested XP Fill Color", "restedColor"},
        {"Rested XP Overlay Color", "restedOverlayColor"}, {"Quest Log XP Overlay Color", "questColor"},
        {"Background Color", "backgroundColor"}, {"Border Color", "borderColor"}}) do
        local native = item[2] == "normalColor" or item[2] == "restedColor"
        W.ColorRow(page, owner, item[1], item[2], function() return not native or not self.db.nativeColors end)
    end
    page:Finish(); return page
end
