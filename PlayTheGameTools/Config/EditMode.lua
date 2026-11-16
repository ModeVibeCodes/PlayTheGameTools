local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
-- Edit Mode is the single home for placement. Every registered display uses
-- the same panel: choose the element, its anchor, its offsets, reset or exit.
local WIDTH, PAD, LABEL = 340, 20, 84
local CONTROL = WIDTH - PAD * 2 - LABEL
local ROW = 38
local TOP = 56
local HEIGHT = TOP + ROW * 5 + 150

local function InCombat() return InCombatLockdown() or UnitAffectingCombat("player") end

function addon:UpdateEditWindowBounds()
    local window = self.editWindow
    if not window or InCombat() then return end
    window:SetScale(math.max(0.1, math.min(1, (UIParent:GetWidth() - 24) / WIDTH, (UIParent:GetHeight() - 24) / HEIGHT)))
end

-- Labels that read the same everywhere a target is offered.
local TARGET_LABELS = { screen = "Screen", player = "Player Frame", target = "Target Frame",
    party = "Party Frames", focus = "Focus Frame", minimap = "Minimap" }

function addon:CreateEditWindow()
    local E, PM, P = self.EditMode, self.PositionManager, self.Positioning
    local window = CreateFrame("Frame", "PlayTheGameToolsEditWindow", UIParent)
    window:Hide()
    self.editWindow = window
    window:SetSize(WIDTH, HEIGHT)
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
        if InCombat() then return end
        window.moving = true; window:StartMoving()
    end)
    drag:SetScript("OnDragStop", function() window:StopMovingOrSizing(); window.moving = false end)
    window.title = W.Heading(drag, "Edit Mode", T.fontSize.section, 12, -8, 280, T.text)
    local refreshing

    local function Selected() return E:Selected() end
    local function Row(index, text)
        local top = -TOP - (index - 1) * ROW
        local label = W.Label(window, text, nil, PAD, top - 8, LABEL - 8, T.secondary)
        local host = CreateFrame("Frame", nil, window)
        host:SetPoint("TOPLEFT", PAD + LABEL, top)
        host:SetSize(CONTROL, 30)
        return host, label
    end
    local function Dropdown(index, text, choices, getter, setter)
        local host, label = Row(index, text)
        local button = W.Select(host, CONTROL, choices, getter, setter)
        button:ClearAllPoints(); button:SetPoint("TOPLEFT")
        return button, label
    end

    -- Element: every enabled display that can be placed, in registration order.
    local elements = Dropdown(1, "Element", function()
        local items = {}
        for _, id in ipairs(PM.order) do
            local element = PM.elements[id]
            if element.editMode and element.module.enabled then
                items[#items + 1] = { id = id, label = element.label or element.module.title }
            end
        end
        return items
    end, function()
        local element = Selected()
        if not element then return nil, "No movable element" end
        return element.id, element.label or element.module.title
    end, function(id) PM:SelectElement(id) end)

    local function Position()
        local element = Selected()
        return element and PM:GetPosition(element.id)
    end
    local targets, targetLabel = Dropdown(2, "Anchor To", function()
        local element, items = Selected(), {}
        if not element then return items end
        for _, item in ipairs(PM:GetAllowedTargets(element.id)) do
            items[#items + 1] = { id = item.id, label = TARGET_LABELS[item.id] or item.label }
        end
        if element.supportsAnchoring and element.allowedTargets.selected and type(GetMouseFoci) == "function" then
            items[#items + 1] = { id = "picker", label = "Select Frame..." }
        end
        return items
    end, function()
        local position = Position()
        local id = position and position.target or "screen"
        local label = TARGET_LABELS[id] or (addon.FrameAnchors:ValidID(id) and id:sub(7)) or id
        if not P:Resolve(id) then label = label .. " (unavailable)" end
        return id, label
    end, function(id)
        local element = Selected()
        if not element then return end
        if id == "picker" then addon.FrameAnchors:Start(element.id) else E:SetTarget(id) end
    end)
    local placements, placementLabel = Dropdown(3, "Attach", function() return P.placements end, function()
        local p = Position()
        local placement = P:Placement(p and p.placement)
        return placement.id, placement.label
    end, function(id) E:SetPlacement(id) end)

    local function Coordinate(index, axis)
        local host = Row(index, axis == "x" and "X Offset" or "Y Offset")
        local function Limits()
            local element = Selected()
            if not element then return 0, 0 end
            local lx, hx, ly, hy = E:CoordinateBounds(element)
            if axis == "x" then return lx, hx end
            return ly, hy
        end
        local function Get()
            local element = Selected()
            if not element then return 0 end
            local x, y = PM:GetOffsets(element.id)
            return axis == "x" and x or y
        end
        local low, high = Limits()
        local refresh = W.Slider(host, low, high, 1, Get, function(value)
            if not refreshing then E:SetCoordinate(axis, value) end
        end, "", {
            minimum = function() local l = Limits(); return l end,
            maximum = function() local _, h = Limits(); return h end,
        })
        local input, slider = host.numericInput, host.slider
        input:SetWidth(64)
        slider:SetPoint("RIGHT", -72, 0)
        return input, slider, function()
            local l, h = Limits()
            slider:SetMinMaxValues(l, h)
            refresh()
        end
    end
    local xInput, xSlider, refreshX = Coordinate(4, "x")
    local yInput, ySlider, refreshY = Coordinate(5, "y")

    local footer = -TOP - ROW * 5 - 6
    local rule = W.Fill(window, T.line, "ARTWORK")
    rule:ClearAllPoints(); rule:SetPoint("TOPLEFT", PAD, footer); rule:SetPoint("TOPRIGHT", -PAD, footer); rule:SetHeight(1)
    local highlights = W.Button(window, "", 30, 30, "checkbox")
    highlights:SetPoint("TOPLEFT", PAD - 6, footer - 10)
    highlights:SetScript("OnClick", function() E:SetHighlights(not E.highlights) end)
    local highlightLabel = W.Label(window, "Show Highlights", nil, PAD + 30, footer - 17, 200)
    local half = (WIDTH - PAD * 2 - 8) / 2
    local reset = W.Button(window, "Reset Position", half, 30, "secondary")
    reset:SetPoint("TOPLEFT", PAD, footer - 48)
    reset:SetScript("OnClick", function()
        local element = Selected()
        if element and not InCombat() then PM:ResetPosition(element.id) end
    end)
    local settings = W.Button(window, "Settings", half, 30, "secondary")
    settings:SetPoint("TOPLEFT", PAD + half + 8, footer - 48)
    settings:SetScript("OnClick", function()
        if InCombat() then return end
        local element = Selected()
        if not element or not self.modules[element.module.id] then return end
        local id = element.module.id
        self:SetEditMode(false)
        self:SelectConfigPage(id)
    end)
    local exit = W.Button(window, "Exit", WIDTH - PAD * 2, 32)
    exit:SetPoint("TOPLEFT", PAD, footer - 88)
    exit:SetSelected(true)
    exit:SetScript("OnClick", function() self:SetEditMode(false) end)

    function self:RefreshEditWindow()
        if refreshing then return end
        refreshing = true
        local element = Selected()
        local anchoring = element ~= nil and element.supportsAnchoring == true
        local available = element ~= nil and P:Resolve(element.position.target or "screen") ~= nil
        elements:SetEnabled(element ~= nil)
        settings:SetEnabled(element ~= nil and self.modules[element.module.id] ~= nil)
        reset:SetEnabled(element ~= nil)
        xInput:SetEnabled(available); yInput:SetEnabled(available)
        xSlider:SetEnabled(available); ySlider:SetEnabled(available)
        refreshX(); refreshY()
        -- Screen-only displays keep the rows so the panel never changes shape.
        targets:SetEnabled(anchoring); placements:SetEnabled(anchoring and available)
        targetLabel:SetTextColor(unpack(anchoring and T.secondary or T.unavailable))
        placementLabel:SetTextColor(unpack(anchoring and T.secondary or T.unavailable))
        elements:Refresh(); targets:Refresh(); placements:Refresh()
        highlights:SetSelected(E.highlights)
        refreshing = false
    end
    -- Clearing focus runs the numeric input's normal apply.
    function self:CommitEditInputs() xInput:ClearFocus(); yInput:ClearFocus() end
    window.elementDropdown = elements
    window.xInput, window.yInput = xInput, yInput
    window.xSlider, window.ySlider = xSlider, ySlider
    window.targetDropdown, window.placementDropdown, window.resetPosition = targets, placements, reset
    window.settingsButton, window.exitButton, window.highlightButton = settings, exit, highlights
    window.highlightLabel = highlightLabel
    window:EnableKeyboard(true)
    window:SetPropagateKeyboardInput(true)
    window:SetScript("OnKeyDown", function(_, key)
        if InCombat() then return end
        window:SetPropagateKeyboardInput(key ~= "ESCAPE")
        if key == "ESCAPE" then self:SetEditMode(false) end
    end)
    window:SetScript("OnHide", function()
        for _, dropdown in ipairs({ elements, targets, placements }) do dropdown.menu:Hide() end
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
    -- Never put the settings window over a pull; suspending skipped its close cleanup.
    if InCombat() then
        self:NotifyConfigClosed()
    else
        self.configWindow:Show()
    end
end
