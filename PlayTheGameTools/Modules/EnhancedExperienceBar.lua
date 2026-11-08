local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local M = { title = "Enhanced Experience Bar", category = "questingLeveling", defaultEnabled = false,
    description = "Experience, rested pool, completed quest rewards and session progress.", supportsAnchoring = true }
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
    sessionFontSize = {8, 24, 1}, textOffset = {-100, 100, 1}, sessionGap = {0, 80, 1} }
local defaults = { width = 600, height = 24, scale = 100, opacity = 100, overlayOpacity = 75,
    font = "game", fontMedia = "", fontSize = 12, sessionFontSize = 11, outline = true,
    textOffset = 0, sessionGap = 6, sessionAbove = false, align = "CENTER", blizzardStyle = false,
    nativeColors = true, showXP = true, showRested = true, showQuests = true, showValues = false,
    showRestedOverlay = true, showQuestOverlay = true, showSession = true, showRate = true,
    hideAtMax = true, normalColor = {0.58, 0, 0.55}, restedColor = {0, 0.39, 0.88},
    questColor = {1, 0.78, 0.2}, textColor = {0.95, 0.96, 1}, backgroundColor = {0.07, 0.08, 0.1},
    borderColor = {0.26, 0.31, 0.38} }
function M.Initialize(db)
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
end
function M:CanConfigure() return not InCombatLockdown() and not UnitAffectingCombat("player") end
function M:GetFonts() return addon.Media:GetFonts() end
function M:SetOption(key, value)
    if not self:CanConfigure() or defaults[key] == nil then return false end
    local copy = addon.ProfileCodec.Copy(self.db); copy[key] = value
    if not pcall(self.Initialize, copy) then return false end
    self.db[key] = copy[key]
    if key == "font" then self.db.fontMedia = "" end
    self:ApplyAppearance(); if self.page then self.page:Refresh() end
    return true
end
function M:SetAppearance(key, value) return self:SetOption(key, value) end
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
function M:ScanQuests()
    local api = C_QuestLog
    local count = self.Read(api and api.GetNumQuestLogEntries)
    local total, known, seen = 0, true, {}
    if not self.Number(count, 0, 1000) or type(GetQuestLogRewardXP) ~= "function" then
        self.questXP, self.questKnown = 0, false; return
    end
    for i = 1, count do
        local info = self.Read(api.GetInfo, i)
        local header = Field(info, "isHeader")
        if header == true then
            -- Never expand/reselect the player's log to compute a preview.
            if Field(info, "isCollapsed") == true then known = false end
        elseif header == false then
            local id = Field(info, "questID")
            if self.Number(id, 1, 2147483647) and not seen[id] then
                seen[id] = true
                local complete = self.Read(api.IsComplete, id)
                if complete == true then
                    local reward = self.Read(GetQuestLogRewardXP, id)
                    if self.Number(reward, 0, 1e12) then total = total + reward else known = false end
                elseif complete ~= false then known = false end
            elseif not self.Number(id, 1, 2147483647) then known = false end
        else known = false end
    end
    self.questXP, self.questKnown = total, known
end
function M:OnInitialize()
    self.Initialize(self.db)
    self.sessionXP, self.questXP, self.questKnown = 0, 0, false
    self.positionElementId = self.id
    self:CreateDisplay()
    addon.Media:RegisterFontListener(self, function(module) if module:CanConfigure() then module:ApplyAppearance() end end)
end
function M:Refresh()
    if not self.active then return end
    self:ScanQuests(); self:Render()
end
function M:OnEnable()
    self.active = true
    self.sessionStart, self.sessionXP, self.sessionIncomplete = GetTime(), 0, false
    self.lastXP = self:ReadXP()
    if not self.events then self.events = CreateFrame("Frame") end
    for _, event in ipairs({"PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING",
        "QUEST_LOG_UPDATE", "QUEST_DATA_LOAD_RESULT", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_XP_UPDATE" then
            if not self.Public(unit) or unit ~= "player" then return end
            self:ObserveXP()
        end
        if event == "PLAYER_REGEN_ENABLED" then self:ApplyAppearance() end
        if event == "QUEST_LOG_UPDATE" or event == "QUEST_DATA_LOAD_RESULT" or event == "PLAYER_LEVEL_UP"
            or event == "PLAYER_ENTERING_WORLD" then self:ScanQuests() end
        self:Render()
    end)
    -- Only clock text ticks; XP/log data are read on events, never polled.
    self.tick = C_Timer.NewTicker(1, function() if self.active then self:RenderSession() end end)
    self:Refresh()
end
function M:OnDisable()
    self.active, self.editing, self.preview = false, false, false
    if self.events then self.events:UnregisterAllEvents() end
    if self.tick then self.tick:Cancel(); self.tick = nil end
    addon.PositionManager:StopDragging(self.id); self.frame:Hide()
end
function M:SetEditMode(enabled) self.editing = enabled and self.active or false; self:Render() end
function M:SetPreviewMode(enabled) self.preview = enabled and self.active or false; self:Render() end
