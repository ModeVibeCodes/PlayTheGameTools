local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
-- Edit Mode is the single home for placement and display styling. Every
-- registered display uses the same panel: on the left choose the element, its
-- anchor, its offsets, reset or exit; on the right style the selected element.
local LEFT, PAD, LABEL = 340, 20, 84
local CONTROL = LEFT - PAD * 2 - LABEL
local ROW = 38
local TOP = 56
-- The styling column fits the settings rows' widest (280-unit) choosers.
local STYLE = 540
local WIDTH, HEIGHT = LEFT + STYLE, 500
local TABS = 40

local function InCombat() return InCombatLockdown() or UnitAffectingCombat("player") end

function addon:UpdateEditWindowBounds()
    local window = self.editWindow
    if not window or InCombat() then return end
    window:SetScale(math.max(0.1, math.min(1, (UIParent:GetWidth() - 24) / WIDTH, (UIParent:GetHeight() - 24) / HEIGHT)))
end

-- Open a display's styling: Edit Mode with that display selected.
function addon:EditElementAppearance(id)
    if InCombat() then
        print("Play The Game Tools: edit display appearance outside combat.")
        return false
    end
    if not self.editMode and not self:SetEditMode(true) then return false end
    local element = self.PositionManager.elements[id]
    if not element or not element.editMode then return false end
    return self.PositionManager:SelectElement(id)
end

-- The styling column shows the selected display's Text and Appearance rows.
-- Rows are borrowed from its settings page, so every control keeps its own
-- getter, setter, refresher and saved key; they return when the selection
-- changes or Edit Mode ends. Settings pages never show these rows.
local PANELS = { { "appearance", "Appearance" }, { "text", "Text" } }
local function CreateStyleColumn(owner, window)
    local column = { borrowed = {}, parents = {}, headings = {}, tabs = {}, selected = {} }
    local x = LEFT + PAD
    local rule = W.Fill(window, T.line, "ARTWORK")
    rule:ClearAllPoints(); rule:SetPoint("TOPLEFT", LEFT, -TOP); rule:SetPoint("BOTTOMLEFT", LEFT, PAD); rule:SetWidth(1)
    local scroll = CreateFrame("ScrollFrame", nil, window)
    scroll:SetPoint("TOPLEFT", x, -TOP); scroll:SetPoint("BOTTOMRIGHT", -PAD - 12, PAD)
    local content = CreateFrame("Frame", nil, scroll)
    local width = STYLE - PAD * 2 - 12
    content:SetSize(width, 1)
    scroll:SetScrollChild(content)
    local bar = CreateFrame("Slider", nil, window)
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0); bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)
    bar:SetWidth(4); bar:SetOrientation("VERTICAL"); bar:SetValueStep(24)
    W.ScrollThumb(bar, 40)
    bar:SetScript("OnValueChanged", function(_, value)
        if owner.CloseFontDropdown then owner:CloseFontDropdown() end
        scroll:SetVerticalScroll(value)
    end)
    local function Wheel(_, delta) bar:SetValue(bar:GetValue() - delta * 42) end
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel", Wheel)
    content:EnableMouseWheel(true); content:SetScript("OnMouseWheel", Wheel)
    local note = W.Label(window, "", nil, x, -TOP - 8, STYLE - PAD * 2, T.muted)
    note:SetWordWrap(true)
    column.scroll, column.content, column.scrollbar, column.note = scroll, content, bar, note

    local function Spec() return column.element and W.EditAppearance[column.element] end
    -- Campfire rows carry their own rule; the page's wrapper filters by its tabs.
    local function Visible(row)
        local tag = row.editAppearance
        local predicate
        if tag.campfire then predicate = tag.visible else predicate = row.visibleWhen end
        return not predicate or predicate()
    end
    local function Eligible(row, feature, panel)
        local tag = row.editAppearance
        if not tag or tag.feature ~= feature or tag.panel ~= panel then return false end
        if row.sectionHeader or row.subsectionHeading or row.campfireSectionHeader or row.campfireHidden
            or row.modePaired or row.modeReplacedNavigation then return false end
        return Visible(row) and true or false
    end
    -- Some pages gate a feature's rows on their own session choice (Rogue's
    -- Customize state); select the feature before reading its rows.
    local function Prepare(feature)
        local plan = W.ModeLayoutPlans[Spec().page]
        if plan and plan.select then plan.select(column.page, feature) end
    end
    local function Rows(feature, panel)
        local rows = {}
        for _, row in ipairs(column.page.rows) do
            if Eligible(row, feature, panel) then rows[#rows + 1] = row end
        end
        return rows
    end
    local function Features()
        local items = {}
        for _, entry in ipairs(Spec().features) do
            if not entry[3] or entry[3]() then
                Prepare(entry[1])
                for _, panel in ipairs(PANELS) do
                    if #Rows(entry[1], panel[1]) > 0 then items[#items + 1] = entry; break end
                end
            end
        end
        return items
    end
    local function Heading(index, text)
        local heading = column.headings[index]
        if not heading then
            heading = { label = W.Heading(content, text, 20, 0, 0, 200, T.text) }
            heading.line, heading.align = W.ModeHeadingRule(content, heading.label)
            column.headings[index] = heading
        end
        heading.label:SetText(text); heading.label:SetWidth(width)
        heading.label:Show(); heading.line:Show(); heading.align()
        return heading.label
    end
    local function Tab(index)
        local button = column.tabs[index]
        if not button then
            button = W.Button(window, "", 150, 28, "choice")
            button:SetScript("OnClick", function()
                if not column.element or not button.feature then return end
                column.selected[column.element] = button.feature
                bar:SetValue(0); column:Layout()
            end)
            column.tabs[index] = button
        end
        return button
    end

    function column:Return()
        if owner.CloseFontDropdown then owner:CloseFontDropdown() end
        if owner.CloseTimerColorPicker then owner:CloseTimerColorPicker() end
        -- Detach first: hiding a focused field applies it and refreshes the
        -- page, which must not borrow rows again while they are going home.
        local page, borrowed, parents = self.page, self.borrowed, self.parents
        self.page, self.borrowed, self.parents = nil, {}, {}
        if page then page.editRefreshed = nil end
        local any = false
        for row in pairs(borrowed) do
            row.editBorrowed = nil
            row:Hide(); row:SetParent(parents[row]); row:ClearAllPoints()
            any = true
        end
        if page and any then page:Layout() end
    end

    function column:Layout()
        if self.layingOut then return end
        self.layingOut = true
        for _, heading in ipairs(self.headings) do heading.label:Hide(); heading.line:Hide() end
        for _, button in ipairs(self.tabs) do button:Hide() end
        local features = self.page and Features() or {}
        local feature
        for _, entry in ipairs(features) do if entry[1] == self.selected[self.element] then feature = entry[1] end end
        feature = feature or (features[1] and features[1][1])
        if #features > 1 then
            local cell = math.min(160, (STYLE - PAD * 2 - 8 * (#features - 1)) / #features)
            for index, entry in ipairs(features) do
                local button = Tab(index)
                button.feature = entry[1]; button.label:SetText(entry[2])
                button:ClearAllPoints(); button:SetPoint("TOPLEFT", x + (index - 1) * (cell + 8), -TOP)
                button:SetSize(cell, 28); button:SetSelected(entry[1] == feature); button:Show()
            end
        end
        local top = TOP + (#features > 1 and TABS or 0)
        scroll:ClearAllPoints(); scroll:SetPoint("TOPLEFT", x, -top); scroll:SetPoint("BOTTOMRIGHT", -PAD - 12, PAD)
        local shown, y, count = {}, 0, 0
        if feature then
            Prepare(feature)
            for _, panel in ipairs(PANELS) do
                local rows = Rows(feature, panel[1])
                if #rows > 0 then
                    count = count + 1
                    if count > 1 then y = y + 16 end
                    local label = Heading(count, panel[2])
                    label:ClearAllPoints(); label:SetPoint("TOPLEFT", 0, -y)
                    y = y + 34
                    for _, row in ipairs(rows) do
                        if not self.borrowed[row] then
                            self.borrowed[row], self.parents[row] = true, row:GetParent()
                            row.editBorrowed = true; row:SetParent(content)
                        end
                        shown[row] = true
                        row:SetWidth(width)
                        if row.layoutChildren then row:layoutChildren(width) end
                        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:Show()
                        y = y + row:GetHeight() + 2
                    end
                end
            end
        end
        -- A row whose own rule no longer applies stays on loan, hidden.
        for row in pairs(self.borrowed) do if not shown[row] then row:Hide() end end
        local element = self.element and addon.PositionManager.elements[self.element]
        note:SetText(not element and "Select a display to style it."
            or ((element.label or element.module.title) .. " has no text or appearance settings."))
        note:SetShown(count == 0)
        scroll:SetShown(count > 0)
        content:SetHeight(math.max(1, y + 12))
        local maximum = math.max(0, y + 12 - (HEIGHT - top - PAD))
        bar:SetMinMaxValues(0, maximum)
        bar:SetValue(math.min(bar:GetValue(), maximum))
        bar:SetShown(count > 0 and maximum > 0)
        self.feature = feature
        self.layingOut = false
    end

    function column:Show(element)
        local id = element and element.id or nil
        if id ~= nil and id == self.element then return end
        self:Return()
        self.element = id
        bar:SetValue(0)
        local spec = Spec()
        if spec and owner.modules[spec.page] and owner.EnsureConfigPage then
            local page = owner:EnsureConfigPage(spec.page)
            self.page = page
            -- Setters refresh their page; refreshed values can change which rows apply.
            page.editRefreshed = function() column:Layout() end
            self:Layout()
            page:Refresh()
        else
            self:Layout()
        end
    end
    return column
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
    local style = CreateStyleColumn(self, window)
    window.style = style
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

    -- The actions rest at the bottom of the placement column.
    local footer = -HEIGHT + 144
    local rule = W.Fill(window, T.line, "ARTWORK")
    rule:ClearAllPoints(); rule:SetPoint("TOPLEFT", PAD, footer); rule:SetSize(LEFT - PAD * 2, 1)
    local highlights = W.Button(window, "", 30, 30, "checkbox")
    highlights:SetPoint("TOPLEFT", PAD - 6, footer - 10)
    highlights:SetScript("OnClick", function() E:SetHighlights(not E.highlights) end)
    local highlightLabel = W.Label(window, "Show Highlights", nil, PAD + 30, footer - 17, 200)
    local half = (LEFT - PAD * 2 - 8) / 2
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
    local exit = W.Button(window, "Exit", LEFT - PAD * 2, 32)
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
        style:Show(element)
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
        style:Return(); style.element = nil
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
