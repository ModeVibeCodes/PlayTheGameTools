local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
local HEIGHT = 434

-- Small owned dropdown; options are rebuilt on open, never polled.
local function Dropdown(parent, width, choices, getter, setter)
    local button = W.Button(parent, "", width, 30)
    local menu = CreateFrame("Frame", nil, button)
    menu:Hide()
    menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -4)
    menu:SetWidth(width)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(button:GetFrameLevel() + 30)
    menu:SetClampedToScreen(true)
    W.Texture(menu, "Window")
    local rows = {}
    function button:Refresh()
        local id, text = getter()
        self.label:SetText(text)
        self.label:SetJustifyH("CENTER")
        if not menu:IsShown() then return end
        local items = choices()
        menu:SetHeight(12 + #items * 30)
        for index, item in ipairs(items) do
            local row = rows[index]
            if not row then
                row = W.Button(menu, "", width - 12, 28, "tab")
                row:SetPoint("TOPLEFT", 6, -6 - (index - 1) * 30)
                rows[index] = row
                row:SetScript("OnClick", function() menu:Hide(); setter(row.choice.id); self:Refresh() end)
            end
            row.choice = item
            row.label:SetText(item.label)
            row:SetSelected(item.id == id)
            row:Show()
        end
        for index = #items + 1, #rows do rows[index]:Hide() end
    end
    button:SetScript("OnClick", function()
        if InCombatLockdown() or UnitAffectingCombat("player") then return end
        if parent.anchorMenu and parent.anchorMenu ~= menu then parent.anchorMenu:Hide() end
        parent.anchorMenu = menu
        menu:SetShown(not menu:IsShown()); button:Refresh()
    end)
    button.menu, button.rows = menu, rows
    return button
end

function addon:UpdateEditWindowBounds()
    local window = self.editWindow
    if not window or InCombatLockdown() or UnitAffectingCombat("player") then return end
    window:SetScale(math.max(0.1, math.min(1, (UIParent:GetWidth() - 24) / 340, (UIParent:GetHeight() - 24) / HEIGHT)))
end

function addon:CreateEditWindow()
    local E = self.EditMode
    local window = CreateFrame("Frame", "ModeToolsEditWindow", UIParent)
    window:Hide()
    self.editWindow = window
    window:SetSize(340, HEIGHT)
    window:SetPoint("TOP", UIParent, "TOP", 0, -48)
    window:SetFrameStrata("DIALOG")
    window:SetFrameLevel(80)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    W.Texture(window, "Window")
    W.Texture(window, "BorderSilver", "BORDER")
    local drag = CreateFrame("Frame", nil, window)
    drag:SetPoint("TOPLEFT", 8, -8)
    drag:SetPoint("TOPRIGHT", -8, -8)
    drag:SetHeight(36)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
        if InCombatLockdown() or UnitAffectingCombat("player") then return end
        window.moving = true; window:StartMoving()
    end)
    drag:SetScript("OnDragStop", function() window:StopMovingOrSizing(); window.moving = false end)
    W.Heading(drag, "Play The Game Tools Edit Mode", 20, 10, -4, 280, T.primary)
    local selected = W.Label(window, "", nil, 20, -52, 300, T.secondary)
    local refreshing
    W.Label(window, "X Position", nil, 20, -80, 300)
    W.Label(window, "Y Position", nil, 20, -138, 300)
    local function Coordinate(axis, top)
        local function Get()
            local element = E:Selected()
            if not element then return 0 end
            local px, py = self.PositionManager:GetOffsets(element.id)
            return axis == "x" and px or py
        end
        local function Limits()
            local element = E:Selected()
            if not element then return 0, 0 end
            local lx, hx, ly, hy = E:CoordinateBounds(element)
            if axis == "x" then return lx, hx end
            return ly, hy
        end
        local holder = CreateFrame("Frame", nil, window)
        holder:SetPoint("TOPLEFT", 20, top)
        holder:SetSize(300, 30)
        local low, high = Limits()
        local function Set(value) if not refreshing then E:SetCoordinate(axis, value) end end
        local refresh = W.Slider(holder, low, high, 5, Get, Set, "", {
            minimum = function() local l = Limits(); return l end,
            maximum = function() local _, h = Limits(); return h end,
        })
        local input, slider = holder.numericInput, holder.slider
        input:SetWidth(88)
        slider:SetPoint("RIGHT", -100, 0)
        return input, slider, function()
            local l, h = Limits()
            slider:SetMinMaxValues(l, h)
            refresh()
        end
    end
    local xInput, xSlider, refreshX = Coordinate("x", -104)
    local yInput, ySlider, refreshY = Coordinate("y", -162)
    W.Heading(window, "Snap To UI Element", 16, 20, -202, 300, T.primary)
    local P = self.Positioning
    local function Position()
        local element = E:Selected()
        return element and self.PositionManager:GetPosition(element.id)
    end
    local targets = Dropdown(window, 300, function()
        local element = E:Selected()
        return self.PositionManager:GetAllowedTargets(element and element.id)
    end, function()
        local position = Position()
        local id = position and position.target or "screen"
        if addon.FrameAnchors:ValidID(id) then return id,id:sub(7)..(P:Resolve(id) and "" or " (unavailable)") end
        for _, target in ipairs(P.targets) do
            if target.id == id then return id, target.label .. (P:Resolve(id) and "" or " (unavailable)") end
        end
        return id, "Saved target unavailable"
    end, function(id) local p = Position(); if p then E:SetAnchor(id, p.placement or "center") end end)
    targets:SetPoint("TOPLEFT", 20, -228)
    local placements = Dropdown(window, 188, function() return P.placements end, function()
        local p = Position()
        local placement = P:Placement(p and p.placement)
        return placement.id, placement.label
    end, function(id) local p = Position(); if p then E:SetAnchor(p.target or "screen", id) end end)
    placements:SetPoint("TOPLEFT", 20, -266)
    local reset = W.Button(window, "Reset Offset", 104, 30, "secondary")
    reset:SetPoint("TOPLEFT", 216, -266)
    reset:SetScript("OnClick", function() local p = Position(); if p then E:SetAnchor(p.target or "screen", p.placement or "center") end end)
    local highlights = W.Button(window, "", 30, 30, "checkbox")
    highlights:SetPoint("TOPLEFT", 20, -310)
    highlights:SetScript("OnClick", function() E:SetHighlights(not E.highlights) end)
    W.Label(window, "Show Highlights", nil, 60, -317, 220)
    local settings = W.Button(window, "Open Module Settings", 300, 30)
    settings:SetPoint("TOPLEFT", 20, -348)
    settings:SetScript("OnClick", function()
        if InCombatLockdown() or UnitAffectingCombat("player") then
            print("Play The Game Tools: open element settings outside combat.")
            return
        end
        local element = E:Selected()
        if not element then return end
        local id = element.module.id
        self:SetEditMode(false)
        self:SelectConfigPage(id)
    end)
    local exit = W.Button(window, "Exit / Save", 300, 32)
    exit:SetPoint("TOPLEFT", 20, -386)
    exit:SetSelected(true)
    exit:SetScript("OnClick", function() self:SetEditMode(false) end)
    function self:RefreshEditWindow()
        if refreshing then return end
        refreshing = true
        local element = E:Selected()
        selected:SetText(element and (element.label or element.module.title) or "No enabled movable element")
        settings:SetEnabled(element ~= nil)
        local anchoring = element ~= nil and element.supportsAnchoring == true
        local available = element ~= nil and (not anchoring or P:Resolve(element.position.target or "screen") ~= nil)
        xInput:SetEnabled(available)
        yInput:SetEnabled(available)
        xSlider:SetEnabled(available); ySlider:SetEnabled(available)
        refreshX(); refreshY()
        targets:SetEnabled(anchoring); placements:SetEnabled(anchoring and available); reset:SetEnabled(anchoring and available)
        targets:Refresh(); placements:Refresh()
        highlights:SetSelected(E.highlights)
        refreshing = false
    end
    window.xInput, window.yInput = xInput, yInput
    window.xSlider, window.ySlider = xSlider, ySlider
    window.targetDropdown, window.placementDropdown, window.resetOffset = targets, placements, reset
    window.settingsButton, window.exitButton, window.highlightButton = settings, exit, highlights
    window.selectedLabel = selected
    window:EnableKeyboard(true)
    window:SetPropagateKeyboardInput(true)
    window:SetScript("OnKeyDown", function(_, key)
        if InCombatLockdown() or UnitAffectingCombat("player") then return end
        window:SetPropagateKeyboardInput(key ~= "ESCAPE")
        if key == "ESCAPE" then self:SetEditMode(false) end
    end)
    window:SetScript("OnHide", function()
        targets.menu:Hide(); placements.menu:Hide()
        window:StopMovingOrSizing(); window.moving = false
        if self.editMode and not window.ending then self:SetEditMode(false) end
    end)
end

function addon:BeginEditWorkspace()
    if not self.configWindow then self:CreateConfig() end
    self:FinishWindowInteraction()
    if not self.editWindow then self:CreateEditWindow() end
    self.configWindow.editSuspended = true
    self.configWindow:Hide()
    self:UpdateEditWindowBounds()
    self.editWindow:Show()
    self.Positioning:Refresh()
    self.EditMode:RefreshElements()
end

function addon:FinishEditWorkspace()
    local window = self.editWindow
    if not window then return end
    window.ending = true
    window:Hide()
    window.ending = false
    self.configWindow.editSuspended = false
    self.configWindow:Show()
end
