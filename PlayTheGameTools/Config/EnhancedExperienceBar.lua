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
    -- Texture, size, fonts and colors are styled in Layout (the Style card);
    -- session tracking is the one session control left on the page.
    page:Section("Session Text")
    local reset = W.Button(page:Row("Session Tracking", 48), "Reset Session", 180, 28); reset:SetPoint("LEFT")
    reset:SetScript("OnClick", function() self:ResetSession() end)
    page:Finish(); return page
end
