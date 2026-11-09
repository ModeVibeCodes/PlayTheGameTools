local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local M = { title = "Enhanced Experience Bar", category = "questingLeveling", defaultEnabled = false,
    description = "Experience, rested pool, total quest log rewards and session progress.", supportsAnchoring = true }
addon.EnhancedExperienceBar = M
addon:RegisterModule("enhancedExperienceBar", M)

function M.Public(v) return not (issecretvalue and issecretvalue(v)) end
function M.Number(v, low, high)
    return M.Public(v) and type(v) == "number" and v == v and v >= low and v <= high
end
function M.Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b = pcall(fn, ...)
    if ok then
        local readable = M.Public(a)
        if not M.Public(a) then a = nil end
        if not M.Public(b) then b = nil end
        return a, b, readable
    end
end
local function Field(t, key)
    if M.Public(t) and type(t) == "table" then return M.Read(function() return t[key] end) end
end
M.ranges = { width = {180, 1600, 10}, height = {12, 80, 1}, scale = {50, 200, 5},
    opacity = {10, 100, 5}, overlayOpacity = {10, 100, 5}, fontSize = {8, 28, 1},
    sessionFontSize = {8, 24, 1}, textOffset = {-100, 100, 1}, sessionGap = {0, 80, 1},
    restedOpacity = {10, 100, 5}, questOpacity = {10, 100, 5}, textOpacity = {10, 100, 5},
    sessionOpacity = {10, 100, 5}, sessionWidth = {180, 1600, 10}, sessionX = {-500, 500, 1} }
local defaults = { width = 600, height = 24, scale = 100, opacity = 100, overlayOpacity = 75,
    font = "game", fontMedia = "", fontSize = 12, sessionFontSize = 11, outline = true,
    textOffset = 0, sessionGap = 6, sessionAbove = false, align = "CENTER", blizzardStyle = false,
    nativeColors = true, showXP = true, showRested = true, showQuests = true, showValues = false,
    showRestedOverlay = true, showQuestOverlay = true, showSession = true, showRate = true,
    hideAtMax = true, normalColor = {0.58, 0, 0.55}, restedColor = {0, 0.39, 0.88},
    questColor = {1, 0.78, 0.2}, textColor = {0.95, 0.96, 1}, backgroundColor = {0.07, 0.08, 0.1},
    borderColor = {0.26, 0.31, 0.38}, restedOverlayColor = {0, 0.39, 0.88},
    barTexture = "default", questFormat = "percent", separator = "dash", sessionSeparator = "dash",
    restedOpacity = 45, questOpacity = 35, textOpacity = 100, sessionOpacity = 100,
    sessionFont = "game", sessionFontMedia = "", sessionOutline = true, sessionAlign = "CENTER",
    sessionTextColor = {0.95, 0.96, 1}, sessionWidth = 600, sessionX = 0,
    barChoice = "ptg", hideBlizzardXP = false, hideEllesmereXP = false }
function M.Initialize(db)
    if db.restedOverlayColor == nil and db.nativeColors == false and type(db.restedColor) == "table" then
        db.restedOverlayColor = {unpack(db.restedColor)}
    end
    -- Split the old shared text settings without changing the player's current look.
    if db.barTexture == nil then db.barTexture = db.blizzardStyle and "blizzardXP" or "default" end
    for target, source in pairs({sessionFont = "font", sessionFontMedia = "fontMedia", sessionOutline = "outline",
        sessionAlign = "align", sessionTextColor = "textColor", sessionWidth = "width"}) do
        if db[target] == nil and db[source] ~= nil then
            db[target] = type(db[source]) == "table" and {unpack(db[source])} or db[source]
        end
    end
    for key, value in pairs(defaults) do
        if db[key] == nil then db[key] = type(value) == "table" and {unpack(value)} or value end
        local v = db[key]
        assert(type(v) == type(value), "Invalid experience bar setting: " .. key)
        if M.ranges[key] then
            local r = M.ranges[key]; assert(M.Number(v, r[1], r[2]) and v % r[3] == 0, "Invalid experience bar range: " .. key)
        elseif type(value) == "table" then
            for i = 1, 3 do assert(M.Number(v[i], 0, 1), "Invalid experience bar color") end
        end
    end
    assert(db.font == "game" or db.font == "chat", "Invalid experience font")
    assert(#db.fontMedia <= 160, "Invalid experience font media")
    assert(db.align == "LEFT" or db.align == "CENTER" or db.align == "RIGHT", "Invalid experience alignment")
    assert(db.sessionFont == "game" or db.sessionFont == "chat", "Invalid session font")
    assert(#db.sessionFontMedia <= 160, "Invalid session font media")
    assert(db.sessionAlign == "LEFT" or db.sessionAlign == "CENTER" or db.sessionAlign == "RIGHT", "Invalid session alignment")
    assert(db.questFormat == "percent" or db.questFormat == "value" or db.questFormat == "both", "Invalid quest XP format")
    assert(db.separator == "dash" or db.separator == "dot", "Invalid experience separator")
    assert(db.sessionSeparator == "dash" or db.sessionSeparator == "dot", "Invalid session separator")
    assert(db.barChoice == "ptg" or db.barChoice == "existing", "Invalid XP bar choice")
    assert(db.barTexture == "default" or db.barTexture == "flat" or db.barTexture == "blizzardXP" or db.barTexture == "blizzardStatus"
        or (#db.barTexture <= 166 and db.barTexture:sub(1, 6) == "media:" and #db.barTexture > 6), "Invalid bar texture")
end
function M:CanConfigure() return not InCombatLockdown() and not UnitAffectingCombat("player") end
function M:GetFonts() return addon.Media:GetFonts() end
function M:SetOption(key, value)
    if not self:CanConfigure() or defaults[key] == nil then return false end
    local copy = addon.ProfileCodec.Copy(self.db); copy[key] = value
    if not pcall(self.Initialize, copy) then return false end
    self.db[key] = copy[key]
    if key == "font" then self.db.fontMedia = "" end
    if key == "sessionFont" then self.db.sessionFontMedia = "" end
    if key == "barChoice" or key == "hideBlizzardXP" or key == "hideEllesmereXP" then
        self:SyncOtherBars(); addon.EditMode:RefreshElements()
    end
    self:ApplyAppearance(); if self.page then self.page:Refresh() end
    return true
end
function M:SetAppearance(key, value) return self:SetOption(key, value) end
function M:GetTextureChoices()
    local choices = {{id = "default", label = "Use Global Setting"}, {id = "flat", label = "Flat"}, {id = "blizzardXP", label = "Blizzard XP"},
        {id = "blizzardStatus", label = "Blizzard Status Bar"}}
    for _, item in ipairs(addon.Media:GetStatusBars()) do
        if item.key ~= "default" then choices[#choices + 1] = {id = item.key, label = item.label} end
    end
    return choices
end
function M:ReadXP()
    local xp, maximum, level = self.Read(UnitXP, "player"), self.Read(UnitXPMax, "player"), self.Read(UnitLevel, "player")
    if not self.Number(xp, 0, 1e12) or not self.Number(maximum, 0, 1e12) or not self.Number(level, 1, 1000) then return end
    local capped = self.Read(GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel)
    local disabled = self.Read(IsXPUserDisabled)
    return {xp = xp, maximum = maximum, level = level, capped = capped == true or maximum == 0, disabled = disabled == true}
end
function M:ObserveXP()
    local current, previous = self:ReadXP(), self.lastXP
    if current and previous then
        local delta
        if current.level == previous.level and current.xp >= previous.xp then delta = current.xp - previous.xp
        elseif current.level == previous.level + 1 then delta = previous.maximum - previous.xp + current.xp end
        if self.Number(delta, 0, 1e12) then self.sessionXP = self.sessionXP + delta else self.sessionIncomplete = true end
    end
    if not current or not previous then self.sessionIncomplete = true end
    self.lastXP = current
end
function M:ResetSession()
    if not self:CanConfigure() then return false end
    self.sessionStart, self.sessionXP, self.sessionIncomplete = GetTime(), 0, false
    self.lastXP = self:ReadXP(); self:Render(); return true
end
function M:ScanQuests(force)
    if self.scanningQuests then return end
    local api = C_QuestLog
    local count, numQuests = self.Read(api and api.GetNumQuestLogEntries)
    local total, known, seen, expanded = 0, true, {}, {}
    if not self.Number(count, 0, 1000) or type(GetQuestLogRewardXP) ~= "function" then
        self.questXP, self.questKnown = 0, false; return
    end
    -- Layout notifications from our temporary header reads must not cause a rescan loop.
    -- Objective progress alone does not change an all-quests XP total. Structural,
    -- level and reward-data events explicitly invalidate this signature.
    local signature = {tostring(count), self.Number(numQuests, 0, 1000) and tostring(numQuests) or "?"}
    for i = 1, count do
        local row = self.Read(api.GetInfo, i)
        local id = Field(row, "questID")
        signature[#signature + 1] = self.Number(id, 0, 2147483647) and tostring(id) or "?"
        signature[#signature + 1] = Field(row, "isCollapsed") == true and "collapsed" or "open"
    end
    signature = table.concat(signature, ":")
    if not force and signature == self.questSignature then return end
    self.scanningQuests, self.questSignature = true, signature
    local selected = self.Read(api.GetSelectedQuest)
    local canExpand = self:CanConfigure() and type(ExpandQuestHeader) == "function" and type(CollapseQuestHeader) == "function"
    local ok = pcall(function()
        local i = 1
        while i <= count and i <= 1000 do
            local info = self.Read(api.GetInfo, i)
            local header = Field(info, "isHeader")
            if header == true then
                if Field(info, "isCollapsed") == true then
                    if canExpand then
                        expanded[#expanded + 1] = i
                        local opened = pcall(ExpandQuestHeader, i)
                        local updated = self.Read(api.GetInfo, i)
                        local newCount = self.Read(api.GetNumQuestLogEntries)
                        if not opened or Field(updated, "isCollapsed") ~= false or not self.Number(newCount, count, 1000) then
                            known = false
                        else count = newCount end
                    else known = false end
                end
            elseif header == false then
                local id = Field(info, "questID")
                if self.Number(id, 1, 2147483647) and not seen[id] then
                    seen[id] = true
                    local reward = self.Read(GetQuestLogRewardXP, id)
                    if self.Number(reward, 0, 1e12) then total = total + reward else known = false end
                elseif not self.Number(id, 1, 2147483647) then known = false end
            else known = false end
            i = i + 1
        end
    end)
    -- Reverse order keeps the expanded indices valid while restoring the layout.
    for i = #expanded, 1, -1 do
        if not pcall(CollapseQuestHeader, expanded[i]) then known = false end
    end
    if #expanded > 0 and self.Number(selected, 1, 2147483647) and self.Read(api.GetSelectedQuest) ~= selected then
        self.Read(api.SetSelectedQuest, selected)
    end
    self.scanningQuests = false
    if not ok then known = false end
    local scanned = 0; for _ in pairs(seen) do scanned = scanned + 1 end
    if self.Number(numQuests, 0, 1000) and scanned < numQuests then known = false end
    self.questXP, self.questKnown = total, known
end
function M:OnInitialize()
    self.Initialize(self.db)
    self.sessionXP, self.questXP, self.questKnown = 0, 0, false
    self.positionElementId = self.id
    self:CreateDisplay()
    addon.Media:RegisterFontListener(self, function(module) if module:CanConfigure() then module:ApplyAppearance() end end)
    addon.Media:RegisterStatusBarListener(self, function(module) module:Render() end)
end
function M:Refresh()
    if not self.active then return end
    self:ScanQuests(true); self:Render()
end
function M:OnEnable()
    self.active = true
    self:SyncOtherBars()
    self.sessionStart, self.sessionXP, self.sessionIncomplete = GetTime(), 0, false
    self.lastXP = self:ReadXP()
    if not self.events then self.events = CreateFrame("Frame") end
    for _, event in ipairs({"PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING",
        "QUEST_LOG_UPDATE", "QUEST_DATA_LOAD_RESULT", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN",
        "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_XP_UPDATE" then
            if not self.Public(unit) or unit ~= "player" then return end
            self:ObserveXP()
        end
        if event == "PLAYER_REGEN_ENABLED" then self:ApplyAppearance() end
        if event ~= "PLAYER_XP_UPDATE" and event ~= "UPDATE_EXHAUSTION" and event ~= "PLAYER_UPDATE_RESTING" then
            self:ScanQuests(event ~= "QUEST_LOG_UPDATE")
        end
        self:Render()
    end)
    -- Only clock text ticks; XP/log data are read on events, never polled.
    self.tick = C_Timer.NewTicker(1, function() if self.active then self:RenderSession() end end)
    self:Refresh()
end
function M:OnDisable()
    self.active, self.editing, self.preview = false, false, false
    self:SyncOtherBars()
    if self.events then self.events:UnregisterAllEvents() end
    if self.tick then self.tick:Cancel(); self.tick = nil end
    addon.PositionManager:StopDragging(self.id); self.frame:Hide()
end
function M:SetEditMode(enabled) self.editing = enabled and self.active or false; self:Render() end
function M:SetPreviewMode(enabled) self.preview = enabled and self.active or false; self:Render() end
