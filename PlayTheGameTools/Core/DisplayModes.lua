local _, addon = ...

-- Session-only coordination. Never store this mode in SavedVariables.
-- Layout is the one on-screen mode: every enabled display shows its sample
-- data (the module's preview) and can be dragged and styled. It replaced the
-- separate Preview and Edit Mode states; addon.editMode is its flag.
addon.editMode = false

function addon:SyncModuleDisplayModes(module)
    local layout = module.enabled and self.editMode or false
    if module.SetPreviewMode then module:SetPreviewMode(layout) end
    if module.SetEditMode then module:SetEditMode(layout) end
end

function addon:RefreshDisplayModes()
    for _, id in ipairs(self.moduleOrder) do self:SyncModuleDisplayModes(self.modules[id]) end
    if self.EditMode then self.EditMode:RefreshElements() end
    if self.RefreshConfig then self:RefreshConfig() end
end

local function CanEnterMode(enabled)
    if enabled and (InCombatLockdown() or UnitAffectingCombat("player")) then
        print("Play The Game Tools: Layout is available outside combat.")
        return false
    end
    return true
end

-- The flag is already off here, so a failed refresh must still close the panel;
-- otherwise every later exit is a no-op. The error is re-raised to stay visible.
local function RefreshAndFinishEditing(self)
    local ok, message = pcall(self.RefreshDisplayModes, self)
    self:FinishEditWorkspace()
    if not ok then error(message, 0) end
end

-- The way in and out of Layout.
function addon:SetEditMode(enabled)
    assert(type(enabled) == "boolean", "Play The Game Tools: Layout requires a boolean.")
    if not CanEnterMode(enabled) then return false end
    if self.editMode == enabled then return true end
    if enabled then
        self.editMode = true
        self:RefreshDisplayModes()
        self:BeginEditWorkspace()
        return true
    end
    -- Typed coordinates are only accepted while the mode is still on.
    if self.CommitEditInputs then
        local ok, message = pcall(self.CommitEditInputs, self)
        if not ok then print("Play The Game Tools: typed position failed: " .. tostring(message)) end
    end
    self.editMode = false
    RefreshAndFinishEditing(self)
    return true
end

function addon:ResetDisplayModes()
    local editing = self.editMode
    self.editMode = false
    if editing then RefreshAndFinishEditing(self) else self:RefreshDisplayModes() end
end

function addon:InitializeDisplayModes()
    if self.displayModeEvents then return end
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if self.FrameAnchors then self.FrameAnchors:Stop() end
            if self.PreviewStates then self.PreviewStates:StopAll() end
            self:ResetDisplayModes()
            if self.FinishWindowInteraction then self:FinishWindowInteraction() end
            if self.CloseTimerColorPicker then self:CloseTimerColorPicker() end
            if self.CloseFontDropdown then self:CloseFontDropdown() end
            if self.CloseModulePreview then self:CloseModulePreview() end
        else
            if self.Positioning then self.Positioning:Refresh() end
            if self.configWindow and self.configWindow.boundsPending then self:UpdateWindowBounds() end
            if self.Media and self.Media.pending then self.Media:RefreshFonts() end
            if self.Media and self.Media.borderPending then self.Media:RefreshBorders() end
            if self.searchPending and self.configWindow and self.configWindow:IsShown() then self:RefreshSettingsSearch() end
        end
        for _, id in ipairs(self.moduleOrder) do
            local module = self.modules[id]
            if module.enabled and module.OnCombatStateChanged then module:OnCombatStateChanged(event == "PLAYER_REGEN_DISABLED") end
        end
    end)
    self.displayModeEvents = events
end
