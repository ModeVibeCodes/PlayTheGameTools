local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme

local function Normalize(text)
    return (text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function Match(text, query)
    text = Normalize(text)
    if text == query then return 0 end
    if text:sub(1, #query) == query then return 1 end
    if text:find(query, 1, true) then return 2 end
end

function addon:SearchSettings(query)
    query = Normalize(query)
    if query == "" then self.searchPending = false; return {} end
    local results = {}
    local combat = InCombatLockdown() or UnitAffectingCombat("player")
    self.searchPending = combat
    for _, id in ipairs(self.moduleOrder) do
        local module = self.modules[id]
        local page = self.configWindow.pages[id]
        if not page and not combat then page = self:EnsureConfigPage(id) end
        local moduleText = module.title .. " " .. (module.description or "") .. " " .. id
        local category = module.category and self.categories[module.category]
        if category then moduleText = category.title .. " " .. moduleText end
        if module.tabTitle then moduleText = moduleText .. " " .. module.tabTitle end
        if module.searchAliases then moduleText = moduleText .. " " .. table.concat(module.searchAliases, " ") end
        local score = Match(module.title, query)
        if score == nil and Match(moduleText, query) then score = 3 end
        if score then results[#results + 1] = { module = module, label = (category and category.title .. " > " or "") .. module.title, score = score, kind = "module" } end
        for _, entry in ipairs(page and page.searchEntries or {}) do
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
                local label = (category and category.title .. " > " or "") .. module.title .. " > "
                if entry.kind == "setting" and entry.section then label = label .. entry.section.title .. " > " end
                results[#results + 1] = { module = module, entry = entry, label = label .. entry.label, score = rank, kind = entry.kind }
            end
        end
    end
    table.sort(results, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        if a.kind ~= b.kind then return a.kind == "setting" or (a.kind == "module" and b.kind == "section") end
        return a.label < b.label
    end)
    while #results > 3 do table.remove(results) end
    return results
end

function addon:CreateSettingsSearch(sidebar)
    local mode=T.id=="mode"
    local input = CreateFrame("EditBox", nil, mode and self.configWindow.headerBar or sidebar)
    if mode then
        input:SetPoint("RIGHT",self.configWindow.headerControls,"LEFT",-16,0)
        input:SetWidth(200)
        self.configWindow.header:ClearAllPoints()
        self.configWindow.header:SetPoint("TOPLEFT")
        self.configWindow.header:SetPoint("BOTTOMRIGHT",input,"BOTTOMLEFT",-16,-14)
    else
        input:SetPoint("TOPLEFT", 0, 0)
        input:SetPoint("TOPRIGHT", 0, 0)
    end
    input:SetHeight(30)
    input:SetAutoFocus(false)
    input:SetMaxLetters(80)
    input:SetFontObject(GameFontHighlight)
    input:SetTextInsets(10, 10, 0, 0)
    self.Media:BindInterfaceFont(input, GameFontHighlight)
    W.Texture(input, "InputField")
    local placeholder = W.Label(input, "Search settings...", nil, 0, 0, 180, T.muted)
    placeholder:ClearAllPoints(); placeholder:SetPoint("LEFT", 10, 0)
    local popup = CreateFrame("Frame", nil, input)
    popup:Hide()
    popup:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -4)
    popup:SetSize(340, 124)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(input:GetFrameLevel() + 40)
    popup:SetClampedToScreen(true)
    W.Texture(popup, "Window")
    W.Texture(popup, "BorderSilver", "BORDER")
    local buttons = {}
    for index = 1, 3 do
        local button = W.Button(popup, "", 328, 36, "tab")
        button:SetPoint("TOPLEFT", 6, -6 - (index - 1) * 37)
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT", 12, 0)
        button.label:SetWidth(304)
        button.label:SetJustifyH("LEFT")
        button:SetScript("OnClick", function()
            local result = button.result
            if not result then return end
            input:ClearFocus()
            self:SelectConfigPage(result.module.id)
            if result.entry then self.configWindow.pages[result.module.id]:Reveal(result.entry) end
            popup:Hide()
        end)
        buttons[index] = button
    end
    function self:RefreshSettingsSearch()
        local text = input:GetText() or ""
        placeholder:SetShown(text == "" and not input:HasFocus())
        local results = self:SearchSettings(text)
        for index, button in ipairs(buttons) do
            button.result = results[index]
            button:SetShown(results[index] ~= nil)
            if results[index] then button.label:SetText(results[index].label) end
        end
        if #results > 0 then popup:SetHeight(12 + #results * 37) end
        popup:SetShown(#results > 0)
        input.results = results
    end
    function self:CloseSettingsSearch() popup:Hide(); input:ClearFocus() end
    input:SetScript("OnTextChanged", function() self:RefreshSettingsSearch() end)
    input:SetScript("OnEditFocusGained", function() self:RefreshSettingsSearch(); placeholder:Hide() end)
    input:SetScript("OnEditFocusLost", function() placeholder:SetShown((input:GetText() or "") == "") end)
    input:SetScript("OnEscapePressed", function() input:SetText(""); self:CloseSettingsSearch() end)
    input:SetText("")
    input.popup, input.buttons = popup, buttons
    self.configWindow.searchInput = input
end
