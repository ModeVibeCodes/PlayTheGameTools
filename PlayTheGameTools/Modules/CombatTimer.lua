local _, addon = ...

local timer = {
    title = "Combat Timer",
    category = "timers",
    description = "Player combat time. A fight already underway is timed from activation.",
    defaultEnabled = false,
    supportsAnchoring = true,
}

local function InCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

local function Clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function timer:CanConfigure()
    if InCombat() then
        print("Play The Game Tools: change Combat Timer appearance and position outside combat.")
        return false
    end
    return true
end

function timer:GetFonts()
    return addon.Media:GetFonts()
end

function timer:SetAppearance(key, value)
    local layout = key == "font" or key == "fontMedia" or key == "fontSize" or key == "outline" or key == "scale"
    if layout and not self:CanConfigure() then return false end
    if key == "format" then
        if value ~= "plain" and value ~= "square" and value ~= "round" then return false end
    elseif key == "font" then
        if value ~= "game" and value ~= "chat" then return false end
        self.db.appearance.fontMedia = ""
    elseif key == "fontMedia" then
        if type(value) ~= "string" or not addon.Media:GetFont(value) then return false end
    elseif key == "outline" then
        if type(value) ~= "boolean" then return false end
    elseif key == "textColor" or key == "backgroundColor" then
        if type(value) ~= "table" then return false end
        local rgb = {}
        for i = 1, 3 do
            if type(value[i]) ~= "number" or value[i] ~= value[i] then return false end
            rgb[i] = Clamp(value[i], 0, 1)
        end
        value = rgb
    elseif key == "backgroundOpacity" or key == "fontSize" or key == "scale" then
        if type(value) ~= "number" or value ~= value then return false end
        if key == "backgroundOpacity" then value = math.floor(Clamp(value, 0, 1) * 100 + 0.5) / 100
        elseif key == "fontSize" then value = math.floor(Clamp(value, 10, 48) + 0.5)
        else value = math.floor(Clamp(value, 0.5, 2) * 100 + 0.5) / 100 end
    else
        return false
    end
    if layout then self:StopDragging() end
    self.db.appearance[key] = value
    self:ApplyAppearance(layout)
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

function timer:ApplyAppearance(layout)
    local a = self.db.appearance
    addon.CombatTimerDisplay.Apply(self, a, layout)
    if layout ~= false then
        addon.PositionManager:ApplyPosition(self.positionElementId)
    end
    self.lastSecond = nil
    self:UpdateText()
end

function timer:UpdatePresentationLayer()
    if InCombat() then self.layerPending = true; return end
    local elevated = self.preview or self.editing
    self.frame:SetFrameStrata(elevated and "DIALOG" or "MEDIUM")
    local level = addon.configWindow and addon.configWindow:GetFrameLevel() or self.normalFrameLevel
    self.frame:SetFrameLevel(elevated and level + 20 or self.normalFrameLevel)
    self.layerPending = false
end

function timer:SetPreviewMode(show)
    if InCombat() or addon.editMode or addon.previewMode then self.testing=false end
    self.preview = self.active and (show or self.testing) or false
    self.lastSecond = nil
    self:UpdatePresentationLayer()
    self:UpdateText()
    self:UpdateVisibility()
end

-- Reuse the existing presentation sample on the owned display; clock logic stays unchanged.
function timer:SetTestDisplay(enabled)
    if enabled and (not self.active or InCombat() or addon.previewMode or addon.editMode or not addon.configWindow
        or not addon.configWindow:IsShown() or addon.configWindow.selectedPage~=self.id) then return false end
    self.testing=enabled
    self:SetPreviewMode(enabled or addon.previewMode)
    if addon.RefreshModulePreviewLayout then addon:RefreshModulePreviewLayout() end
    return true
end

function timer:SetEditMode(enabled)
    if enabled or InCombat() then self.testing=false end
    self:StopDragging()
    self.editing = self.active and enabled and not InCombat() or false
    self.lastSecond = nil
    self:UpdatePresentationLayer()
    self:UpdateText()
    self:UpdateVisibility()
end

function timer:SetShowOutOfCombat(show)
    self.db.showOutOfCombat = show
    self:UpdateVisibility()
end

function timer:StopDragging()
    return addon.PositionManager:StopDragging(self.positionElementId)
end

function timer:GetEditPosition()
    return addon.PositionManager:GetOffsets(self.positionElementId)
end

function timer:SetEditPosition(x, y)
    if not self:CanConfigure() then return false end
    return addon.PositionManager:SetOffsets(self.positionElementId, x, y)
end

function timer:SetEditHighlight()
    -- Position Manager now owns outlines/handles for all registered elements.
    self.editShade:Hide()
    for _,edge in ipairs(self.editEdges) do edge:Hide() end
    if self.editLabel then self.editLabel:Hide() end
end

function timer:UpdateVisibility()
    self.placement = self.active and self.editing and not self.running or false
    self.frame:EnableMouse(self.placement == true)
    self:SetEditHighlight(addon.EditMode.selected == self.id, addon.EditMode.highlights)
    self.frame:SetShown(self.active and (self.running or self.preview or self.editing or self.db.showOutOfCombat) or false)
    if addon.RefreshConfig then addon:RefreshConfig() end
end

function timer:OnConfigClosed()
    addon.PreviewStates:Stop(self.id)
    if self.testing then self:SetTestDisplay(false) end
    if addon.CloseTimerColorPicker then addon:CloseTimerColorPicker() end
end

function timer:UpdateText()
    local seconds = self.running and math.floor(math.max(0, GetTime() - self.startedAt)) or ((self.preview or self.editing) and 83 or 0)
    if (self.preview or self.editing or self.testing) and not self.running then seconds=addon.PreviewStates:Sample(self.id) or seconds end
    if seconds ~= self.lastSecond then
        self.text:SetText(addon.CombatTimerDisplay.Format(seconds, self.db.appearance.format))
        self.lastSecond = seconds
    end
end

function timer:StartCombat(partial)
    if not self.active or self.running then return end
    self:StopDragging()
    self.placement = false
    self.preview, self.editing, self.testing = false, false, false
    if addon.CloseTimerColorPicker then addon:CloseTimerColorPicker() end
    self.running = true
    self.partial = partial
    self.startedAt = GetTime()
    self.lastSecond = nil
    self.refreshElapsed = 0
    self:UpdateText()
    self.frame:SetScript("OnUpdate", self.updateHandler)
    self:UpdateVisibility()
end

function timer:StopCombat()
    self.running = false
    self.startedAt = nil
    self.partial = false
    self.frame:SetScript("OnUpdate", nil)
    self:UpdatePresentationLayer()
    self.lastSecond = nil
    self:UpdateText()
    self:UpdateVisibility()
end

function timer:SynchronizeCombat()
    -- Query only the player; encounter/group combat has different semantics.
    if UnitAffectingCombat("player") then
        self:StartCombat(true)
    else
        self:StopCombat()
    end
end

function timer:OnInitialize()
    if self.frame then return end
    local a = self.db.appearance
    for key, bounds in pairs({ backgroundOpacity = { 0, 1, 100 }, fontSize = { 10, 48, 1 }, scale = { 0.5, 2, 100 } }) do
        assert(a[key] == a[key], "Play The Game Tools: invalid Combat Timer appearance number.")
        a[key] = math.floor(Clamp(a[key], bounds[1], bounds[2]) * bounds[3] + 0.5) / bounds[3]
    end
    for _, key in ipairs({ "textColor", "backgroundColor" }) do
        for i = 1, 3 do
            assert(a[key][i] == a[key][i], "Play The Game Tools: invalid Combat Timer RGB value.")
            a[key][i] = Clamp(a[key][i], 0, 1)
        end
    end
    local frame = CreateFrame("Frame", "PlayTheGameToolsCombatTimerFrame", UIParent)
    frame:Hide()
    frame:SetSize(144, 56)
    frame:SetPoint("CENTER", UIParent, "CENTER", self.db.position.x, self.db.position.y)
    frame:SetFrameStrata("MEDIUM")
    frame:EnableMouse(false)

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints()
    self.editShade = frame:CreateTexture(nil, "BORDER")
    self.editShade:SetAllPoints()
    local accent = addon.Theme.primary
    self.editShade:SetColorTexture(accent[1], accent[2], accent[3], 0.22)
    self.editShade:Hide()
    self.editEdges = {}
    for _, points in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local edge = frame:CreateTexture(nil, "OVERLAY")
        edge:SetPoint(points[1])
        edge:SetPoint(points[2])
        edge:SetColorTexture(accent[1], accent[2], accent[3], 1)
        if #self.editEdges < 2 then edge:SetHeight(2) else edge:SetWidth(2) end
        edge:Hide()
        self.editEdges[#self.editEdges + 1] = edge
    end
    self.normalFrameLevel = frame:GetFrameLevel()

    self.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.text:SetPoint("CENTER", 0, 0)
    self.text:SetTextColor(0.78, 0.87, 0.95, 1)
    self.frame = frame
    self.editLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.editLabel:SetPoint("BOTTOM", frame, "TOP", 0, 4)
    self.editLabel:SetText(self.title)
    addon.Media:BindInterfaceFont(self.editLabel, GameFontDisableSmall)
    self.editLabel:Hide()
    self.positionElementId = "combatTimer"
    local registered, reason = addon.PositionManager:RegisterElement(self.positionElementId, frame, {
        moduleId = self.id, legacyPosition = true,
        defaultPosition = { target = "screen", placement = "center", x = 0, y = -240 },
        canDrag = function() return self.active and self.placement end,
        onHighlight = function(_, selected, show) self:SetEditHighlight(selected, show) end,
    })
    assert(registered, "Play The Game Tools: Combat Timer position registration failed: " .. tostring(reason))
    self:ApplyAppearance()
    addon.Media:RegisterFontListener(self, function(module)
        module:StopDragging()
        module:ApplyAppearance(true)
    end)

    self.updateHandler = function(_, elapsed)
        self.refreshElapsed = self.refreshElapsed + elapsed
        if self.refreshElapsed >= 0.2 then
            self.refreshElapsed = self.refreshElapsed % 0.2
            self:UpdateText()
        end
    end
    frame:SetScript("OnEvent", function(_, event)
        if not self.active then return end
        if event == "PLAYER_REGEN_DISABLED" then
            self:StartCombat(false)
        elseif event == "PLAYER_REGEN_ENABLED" then
            self:StopCombat()
        elseif event == "PLAYER_ENTERING_WORLD" then
            self:SynchronizeCombat()
        end
    end)
end

function timer:OnEnable()
    if self.active then return end
    -- The registry sets module.enabled after this callback; use local active state.
    self.active = true
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:SynchronizeCombat()
end

function timer:OnDisable()
    self.active = false
    self:StopDragging()
    self.placement = false
    self.preview, self.editing, self.testing = false, false, false
    if addon.CloseTimerColorPicker then addon:CloseTimerColorPicker() end
    self.frame:UnregisterAllEvents()
    self:StopCombat()
end

addon:RegisterModule("combatTimer", timer)
