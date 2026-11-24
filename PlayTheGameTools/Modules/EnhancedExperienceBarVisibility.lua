local _, addon = ...
local M = addon.EnhancedExperienceBar
if not M then return end

-- Independent adapters for inspected native Forever/Ellesmere 9.7.8 frames.
-- No provider settings, methods, event registrations or source files are replaced.
local records = setmetatable({}, {__mode = "k"})
local function Safe(frame)
    if not M.Public(frame) or not frame or type(frame.HookScript) ~= "function" then return false end
    if M.Read(frame.IsForbidden, frame) ~= false or M.Read(frame.IsProtected, frame) ~= false then return false end
    return true
end
local function Wants(kind)
    return M.active and M.db.barChoice == "ptg" and M.db[kind == "native" and "hideBlizzardXP" or "hideEllesmereXP"]
end
local function IsXP(record)
    return record.kind == "ellesmere" or M.Read(record.frame.GetShownBar, record.frame) == record.xpBar
end
local function Suppress(record)
    if not Wants(record.kind) or not IsXP(record) or not Safe(record.frame) or record.blocked or record.hiding then return end
    if M.Read(record.frame.IsShown, record.frame) then
        record.suppressed = true
        record.hiding = true
        local ok = pcall(record.frame.Hide, record.frame)
        record.hiding = false
        if not ok or M.Read(record.frame.IsShown, record.frame) ~= false then record.blocked, record.suppressed = true, false end
    end
end
local function Track(frame, kind, xpBar)
    if not Safe(frame) then return end
    if kind == "ellesmere" and type(frame._updateFunc) ~= "function" then return end
    if kind == "native" and (type(frame.GetShownBar) ~= "function" or type(frame.UpdateShownState) ~= "function") then return end
    local record = records[frame]
    if not record then
        record = {frame = frame, kind = kind, xpBar = xpBar}
        records[frame] = record
        frame:HookScript("OnShow", function() Suppress(record) end)
    end
    record.xpBar = xpBar
    return record
end
local function Restore(record)
    if not record.suppressed then return true end
    if not M:CanConfigure() then return false end
    if not Safe(record.frame) then return false end
    -- Let the owner's normal update decide current visibility (max level, Never,
    -- watched reputation, etc.), rather than unconditionally showing the frame.
    local update = record.kind == "native" and record.frame.UpdateShownState or record.frame._updateFunc
    if type(update) ~= "function" then return false end
    record.suppressed = false
    local ok
    if record.kind == "native" then ok = pcall(update, record.frame) else ok = pcall(update) end
    if not ok then record.suppressed = true end
    return ok
end
-- EllesmereEAB_XPBar belongs to EllesmereUIActionBars; its hide switch is
-- offered only while that addon is loaded.
function M:EllesmereLoaded()
    return self.Read(C_AddOns and C_AddOns.IsAddOnLoaded, "EllesmereUIActionBars") == true
end
local function Watch(self)
    if not self.otherBarEvents then
        self.otherBarEvents = CreateFrame("Frame")
        self.otherBarEvents:SetScript("OnEvent", function()
            self:SyncOtherBars()
            if self.page then self.page:Refresh() end
        end)
    end
    self.otherBarEvents:UnregisterAllEvents()
    if self.active or self.otherBarsPending then
        self.otherBarEvents:RegisterEvent("ADDON_LOADED")
        self.otherBarEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.otherBarEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end
function M:SyncOtherBars()
    if not self:CanConfigure() then self.otherBarsPending = true; Watch(self); return end
    self.otherBarsPending = false
    local manager = _G.StatusTrackingBarManager
    local info = _G.StatusTrackingBarInfo
    local xpIndex = info and info.BarsEnum and info.BarsEnum.Experience
    if self.Public(manager) and manager and self.Public(manager.barContainers) and type(manager.barContainers) == "table" and self.Number(xpIndex, 0, 100) then
        for _, container in ipairs(manager.barContainers) do
            if self.Public(container) and container and self.Public(container.bars) and type(container.bars) == "table" then
                local xpBar = container.bars[xpIndex]
                if self.Public(xpBar) and xpBar then
                    local record = Track(container, "native", xpBar)
                    if record and Wants("native") then Suppress(record) end
                end
            end
        end
    end
    local ellesmere = _G.EllesmereEAB_XPBar
    local record = ellesmere and Track(ellesmere, "ellesmere")
    if record and Wants("ellesmere") then Suppress(record) end
    local pending = false
    for _, entry in pairs(records) do
        if not Wants(entry.kind) and not Restore(entry) then pending = true end
    end
    self.otherBarsPending = pending
    local element = addon.PositionManager.elements[self.id]
    if element then element.editMode = self.active and self.db.barChoice == "ptg" or false end
    Watch(self)
end
function M:ChooseXPBar(ptgOnly)
    if not self:CanConfigure() then return false end
    self.db.barChoice = ptgOnly and "ptg" or "existing"
    if ptgOnly then self.db.hideBlizzardXP, self.db.hideEllesmereXP = true, true end
    if ptgOnly and not self.enabled then addon:SetModuleEnabled(self.id, true) end
    self:SyncOtherBars(); self:Render()
    addon.EditMode:RefreshElements()
    if self.page then self.page:Refresh() end
    return true
end
