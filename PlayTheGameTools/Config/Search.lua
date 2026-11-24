local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
local RESULT_LIMIT, RESULT_HEIGHT, RESULT_STEP = 8, 38, 40

local function Normalize(text)
    return (text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function Match(text, query)
    text = Normalize(text)
    if text == query then return 0 end
    if text:sub(1, #query) == query then return 1 end
    if text:find(query, 1, true) then return 2 end
end

-- Searchable pages: the sidebar's module pages, then Settings.
local function SearchablePages(self)
    local pages = {}
    for _, id in ipairs(self.moduleOrder) do
        if not self.IsConfigPageListed or self:IsConfigPageListed(id) then pages[#pages + 1] = self.modules[id] end
    end
    if self.SETTINGS_PAGE then pages[#pages + 1] = self.SETTINGS_PAGE end
    return pages
end

function addon:SearchSettings(query, limit)
    query = Normalize(query)
    if query == "" then self.searchPending = false; return {} end
    local results = {}
    local combat = InCombatLockdown() or UnitAffectingCombat("player")
    self.searchPending = combat
    for _, module in ipairs(SearchablePages(self)) do
        local id = module.id
        local page = self.configWindow.pages[id]
        if not page and not combat then page = self:EnsureConfigPage(id) end
        local moduleText = module.title .. " " .. (module.configDescription or "") .. " " .. (module.description or "") .. " " .. id
        if module.tabTitle then moduleText = moduleText .. " " .. module.tabTitle end
        if module.searchAliases then moduleText = moduleText .. " " .. table.concat(module.searchAliases, " ") end
        local score = Match(module.title, query)
        if score == nil and Match(moduleText, query) then score = 3 end
        if score then
            results[#results + 1] = { module = module, label = module.title, score = score, kind = "module",
                title = module.title, context = module.configDescription or module.description or "" }
        end
        for _, entry in ipairs(page and page.searchEntries or {}) do
            -- Display styling is edited in Edit Mode, not on this page.
            local base = entry.modeBaseRow or entry.campfireBaseRow or entry.row
            if not (base and base.editAppearance) then
                local rank = Match(entry.label, query)
                for _, alias in ipairs(entry.keywords or {}) do
                    local aliasRank = Match(alias, query)
                    if aliasRank then rank = math.min(rank or 99, aliasRank + 1) end
                end
                if rank == nil then
                    local context = moduleText .. " " .. (entry.section and entry.section.title or "")
                    if Match(context, query) then rank = 4 end
                end
                if rank then
                    local where = module.title
                    if entry.kind == "setting" and entry.section then where = where .. " > " .. entry.section.title end
                    results[#results + 1] = { module = module, entry = entry, label = where .. " > " .. entry.label,
                        score = rank, kind = entry.kind, title = entry.label, context = where }
                end
            end
        end
    end
    table.sort(results, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        if a.kind ~= b.kind then return a.kind == "setting" or (a.kind == "module" and b.kind == "section") end
        return a.label < b.label
    end)
    limit = limit or RESULT_LIMIT
    while #results > limit do table.remove(results) end
    return results
end

-- The search field heads the sidebar. While it holds text, its results take
-- the place of the module list; choosing one opens the page and flashes the
-- setting.
function addon:CreateSettingsSearch(sidebar, list)
    local input = CreateFrame("EditBox", nil, sidebar)
    input:SetPoint("TOPLEFT", 0, 0)
    input:SetPoint("TOPRIGHT", 0, 0)
    input:SetHeight(28)
    input:SetAutoFocus(false)
    input:SetMaxLetters(80)
    input:SetFontObject(GameFontHighlight)
    input:SetTextInsets(10, 10, 0, 0)
    self.Media:BindInterfaceFont(input, GameFontHighlight)
    W.Texture(input, "InputField")
    local placeholder = W.Label(input, "Search", nil, 0, 0, 160, T.muted)
    placeholder:ClearAllPoints(); placeholder:SetPoint("LEFT", 10, 0)
    local panel = CreateFrame("Frame", nil, sidebar)
    panel:Hide()
    panel:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", 0, 0)
    local empty = W.Label(panel, "", nil, 10, -8, 160, T.muted)
    empty:SetPoint("TOPRIGHT", -10, -8)
    empty:SetWordWrap(true)
    local buttons = {}
    local function Open(result)
        if not result then return end
        input:ClearFocus()
        self:SelectConfigPage(result.module.id)
        if result.entry then self.configWindow.pages[result.module.id]:Reveal(result.entry) end
    end
    for index = 1, RESULT_LIMIT do
        local button = W.Button(panel, "", 180, RESULT_HEIGHT, "tab")
        button:SetPoint("TOPLEFT", 0, -(index - 1) * RESULT_STEP)
        button:SetPoint("TOPRIGHT", -10, -(index - 1) * RESULT_STEP)
        button.modeLeftAligned = true
        button.label:ClearAllPoints()
        button.label:SetPoint("TOPLEFT", 10, -5)
        button.label:SetPoint("TOPRIGHT", -10, -5)
        button.label:SetJustifyH("LEFT")
        button.label:SetWordWrap(false)
        button.context = W.Label(button, "", nil, 10, -21, 160, T.muted)
        button.context:SetPoint("TOPRIGHT", -10, -21)
        button.context:SetWordWrap(false)
        self.Media:BindInterfaceFont(button.context, GameFontHighlight, T.fontSize.small)
        button:SetScript("OnClick", function() Open(button.result) end)
        buttons[index] = button
    end
    function self:RefreshSettingsSearch()
        local text = input:GetText() or ""
        placeholder:SetShown(text == "" and not input:HasFocus())
        local active = Normalize(text) ~= ""
        local results = active and self:SearchSettings(text) or {}
        for index, button in ipairs(buttons) do
            local result = results[index]
            button.result = result
            button:SetShown(result ~= nil)
            if result then
                button.label:SetText(result.title)
                button.context:SetText(result.context)
            end
        end
        empty:SetText(active and #results == 0 and ("Nothing matches \"" .. text .. "\".") or "")
        empty:SetShown(active and #results == 0)
        panel:SetShown(active)
        list:SetShown(not active)
        input.results = results
    end
    function self:CloseSettingsSearch()
        input:ClearFocus()
        if (input:GetText() or "") ~= "" then input:SetText("") else self:RefreshSettingsSearch() end
    end
    input:SetScript("OnTextChanged", function() self:RefreshSettingsSearch() end)
    input:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    input:SetScript("OnEditFocusLost", function() placeholder:SetShown((input:GetText() or "") == "") end)
    input:SetScript("OnEnterPressed", function() Open(input.results and input.results[1]) end)
    input:SetScript("OnEscapePressed", function() self:CloseSettingsSearch() end)
    input:SetText("")
    input.panel, input.buttons, input.empty = panel, buttons, empty
    self.configWindow.searchInput = input
    self.configWindow.searchResults = panel
    self:RefreshSettingsSearch()
end
