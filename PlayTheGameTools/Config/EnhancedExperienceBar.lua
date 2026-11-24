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
    -- Texture, size, fonts and colors are styled in Layout (the Style card).
    -- What the bar shows: each switch turns one piece of information on or off.
    -- Separators, offsets, the quest XP format and the session text's place stay
    -- saved, without a control.
    page:Section("Bar")
    Toggles({{"Show XP percent", "showXP"}, {"Show XP amounts", "showValues"}, {"Show rested XP", "showRested"},
        {"Show quest log XP", "showQuests"}, {"Rested overlay", "showRestedOverlay"}, {"Quest log overlay", "showQuestOverlay"}})
    page:Section("Session Text")
    Toggles({{"Show session progress", "showSession"}, {"Show XP per hour", "showRate"}})
    local reset = W.Button(page:Row("Session Tracking", 48), "Reset Session", 180, 28); reset:SetPoint("LEFT")
    reset:SetScript("OnClick", function() self:ResetSession() end)
    page:Finish(); return page
end
