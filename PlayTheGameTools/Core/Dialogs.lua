local _, addon = ...

-- One owner for the addon's windows, dialogs and pop-ups.
--   window: opening it closes every other open window/notice outside its group.
--   notice: an automatic prompt; it never closes anything when it appears.
--   layer:  a menu over its owner; only Escape closes it.
-- Escape closes the most recently opened entry first. A single hidden frame
-- in Blizzard's UISpecialFrames list stands in for all of them, so the stock
-- Escape path (CloseAllWindows) runs it and the game menu stays closed.
-- Only ordinary, unprotected addon frames are registered; nothing here is
-- restricted in combat.
local D = { entries = {}, open = {}, serial = 0 }
addon.Dialogs = D

local function Visible(frame)
    if frame.IsVisible then return frame:IsVisible() == true end
    return frame:IsShown() == true
end

local function Report(message)
    local handler = geterrorhandler and geterrorhandler()
    if handler then handler(message) end
end

function D:Close(entry)
    local ok, message = pcall(entry.close or entry.frame.Hide, entry.frame)
    if not ok then Report(message) end
    if Visible(entry.frame) then return false end
    self.open[entry] = nil
    return true
end

-- Every open entry that a newly opened window replaces. Notices that appear
-- while those are closing (a reload prompt) stay; reopened windows do not.
local function Victims(self, entry)
    local victims = {}
    for other in pairs(self.open) do
        if other ~= entry and other.kind ~= "layer" and other.group ~= entry.group and Visible(other.frame)
            and (other.kind == "window" or (other.serial or 0) < entry.serial) then
            victims[#victims + 1] = other
        end
    end
    return victims
end

function D:Opened(entry)
    self.serial = self.serial + 1
    entry.serial = self.serial
    self.open[entry] = true
    if entry.kind == "window" and not self.closing then
        self.closing = true
        -- A closed window may show another (Edit Mode returns to settings).
        for _ = 1, 4 do
            local victims = Victims(self, entry)
            if #victims == 0 then break end
            for _, other in ipairs(victims) do self:Close(other) end
        end
        self.closing = nil
    end
    self:Sync()
end

function D:Register(frame, options)
    options = options or {}
    local entry = self.entries[frame]
    if not entry then
        entry = { frame = frame }
        self.entries[frame] = entry
        -- Hooked, so the frame's own OnShow keeps running first.
        frame:HookScript("OnShow", function() D:Opened(entry) end)
    end
    self:Configure(frame, options)
    -- New frames start shown; one never hidden first gets no OnShow.
    if not self.open[entry] and Visible(frame) then self:Opened(entry) end
    return entry
end

-- Kind and group can change between showings (a preview vs. a real popup).
function D:Configure(frame, options)
    local entry = self.entries[frame]
    if not entry then return end
    entry.kind = options.kind or entry.kind or "window"
    if options.group ~= nil then entry.group = options.group end
    entry.group = entry.group or entry
    if options.close ~= nil then entry.close = options.close end
end

function D:Top()
    local top
    for entry in pairs(self.open) do
        if not Visible(entry.frame) then
            self.open[entry] = nil
        elseif not top or (entry.serial or 0) > (top.serial or 0) then
            top = entry
        end
    end
    return top
end

function D:CloseTop()
    local top = self:Top()
    if not top then return false end
    return self:Close(top)
end

function D:CloseAll()
    for entry in pairs(self.open) do
        if entry.kind ~= "layer" and Visible(entry.frame) then self:Close(entry) end
    end
    self:Sync()
end

-- The stand-in frame is shown exactly while something of ours is open, so
-- Escape falls through to the game menu when nothing is.
local escape = CreateFrame("Frame", "PlayTheGameToolsEscapeHandler", UIParent)
escape:Hide()
D.escapeFrame = escape
if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "PlayTheGameToolsEscapeHandler") end
local watcher = CreateFrame("Frame")
watcher:Hide()
D.watcher = watcher

function D:Sync()
    -- Never re-show the stand-in from inside its own Escape hide.
    if self.escaping then watcher:Show(); return end
    local open = self:Top() ~= nil
    if escape:IsShown() ~= open then
        self.syncing = true
        escape:SetShown(open)
        self.syncing = nil
    end
    -- Dialogs also close themselves; the watcher notices on the next frame.
    watcher:SetShown(open)
end

escape:SetScript("OnHide", function()
    if D.syncing then return end
    D.escaping = true
    local ok, message = pcall(D.CloseTop, D)
    D.escaping = nil
    if not ok then Report(message) end
    -- Re-armed next frame if more remain; never re-shown inside this Escape.
    watcher:Show()
end)
watcher:SetScript("OnUpdate", function() D:Sync() end)
