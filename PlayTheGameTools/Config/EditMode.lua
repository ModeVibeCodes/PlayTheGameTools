local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
-- Layout: the one on-screen mode. Every enabled display shows its sample data
-- with its name, and can be dragged. The bar along the top says what to do and
-- holds Grid and Done. Clicking a display opens its Style card beside it: the
-- same Scale, Opacity, Text size and Background for every display, a Position
-- section for anchoring and exact offsets, Reset and Settings.
-- The bar keeps the earlier Edit Mode window's frame name and Escape handling.
local BAR_HEIGHT, BAR_PAD, BAR_GAP = 44, 14, 14
local CARD_WIDTH, PAD, LABEL = 300, 14, 86
local CONTROL = CARD_WIDTH - PAD * 2 - LABEL
local ROW, HEADER, FOOTER = 36, 44, 50
local CARD_GAP = 16

local function InCombat() return InCombatLockdown() or UnitAffectingCombat("player") end

local function TextWidth(text, fallback)
    local width = text:GetStringWidth()
    if issecretvalue and issecretvalue(width) then return fallback end
    return type(width) == "number" and width > 0 and math.ceil(width) or fallback
end

function addon:UpdateEditWindowBounds()
    local window = self.editWindow
    if not window or InCombat() then return end
    local width = window.contentWidth or window:GetWidth()
    window:SetScale(math.max(0.1, math.min(1, (UIParent:GetWidth() - 24) / width, (UIParent:GetHeight() - 24) / (BAR_HEIGHT + 420))))
end

-- Open Layout with one display's Style card already open.
function addon:EditElementAppearance(id)
    if InCombat() then
        print("Play The Game Tools: open Layout outside combat.")
        return false
    end
    if not self.editMode and not self:SetEditMode(true) then return false end
    local element = self.PositionManager.elements[id]
    if not element or not element.editMode then return false end
    return self.PositionManager:SelectElement(id)
end

-- Guide lines every PM.GRID units out from the centre of the screen. Never
-- takes the mouse, so the game world stays clickable through it.
function addon:RefreshLayoutGrid()
    local show = self.editMode and self.EditMode.grid and self.editWindow and self.editWindow:IsShown() and not InCombat()
    local grid = self.layoutGrid
    if not show then
        if grid then grid:Hide() end
        return
    end
    if not grid then
        grid = CreateFrame("Frame", "PlayTheGameToolsLayoutGrid", UIParent)
        grid:SetAllPoints(UIParent); grid:SetFrameStrata("BACKGROUND"); grid:EnableMouse(false)
        grid.lines = {}
        self.layoutGrid = grid
    end
    local size, width, height = self.PositionManager.GRID, UIParent:GetWidth(), UIParent:GetHeight()
    local used = 0
    local function Line(horizontal, offset)
        used = used + 1
        local line = grid.lines[used]
        if not line then line = grid:CreateTexture(nil, "BACKGROUND"); grid.lines[used] = line end
        local center = offset == 0
        line:SetColorTexture(1, 1, 1, center and 0.22 or 0.08)
        line:ClearAllPoints()
        if horizontal then
            line:SetPoint("LEFT", grid, "LEFT", 0, offset); line:SetPoint("RIGHT", grid, "RIGHT", 0, offset); line:SetHeight(1)
        else
            line:SetPoint("TOP", grid, "TOP", offset, 0); line:SetPoint("BOTTOM", grid, "BOTTOM", offset, 0); line:SetWidth(1)
        end
        line:Show()
    end
    for step = -math.floor(width / 2 / size), math.floor(width / 2 / size) do Line(false, step * size) end
    for step = -math.floor(height / 2 / size), math.floor(height / 2 / size) do Line(true, step * size) end
    for index = used + 1, #grid.lines do grid.lines[index]:Hide() end
    grid:Show()
end

-- Labels that read the same everywhere a target is offered.
local TARGET_LABELS = { screen = "Screen", player = "Player Frame", target = "Target Frame",
    party = "Party Frames", focus = "Focus Frame", minimap = "Minimap" }

local SLIDERS = {
    { key = "scale", label = "Scale" },
    { key = "opacity", label = "Opacity" },
    { key = "text", label = "Text size" },
}

local function CreateStyleCard(owner, window)
    local E, PM, P = owner.EditMode, owner.PositionManager, owner.Positioning
    local card = CreateFrame("Frame", nil, window)
    card:Hide()
    card:SetSize(CARD_WIDTH, 200)
    card:SetFrameStrata("DIALOG"); card:SetFrameLevel(window:GetFrameLevel() + 10)
    card:SetClampedToScreen(true)
    card:EnableMouse(true)
    W.Texture(card, "Window")
    W.Texture(card, "BorderSilver", "BORDER")
    local function Selected() return E:Selected() end

    card.title = W.Heading(card, "", T.fontSize.section, PAD, -13, CARD_WIDTH - PAD * 2 - 34, T.text)
    local close = W.Button(card, "X", 26, 26, "secondary")
    close:SetPoint("TOPRIGHT", -10, -9)
    close:SetScript("OnClick", function() E:Deselect() end)
    card.closeButton = close
    local rule = W.Fill(card, T.line, "ARTWORK")
    rule:ClearAllPoints(); rule:SetPoint("TOPLEFT", PAD, -HEADER); rule:SetSize(CARD_WIDTH - PAD * 2, 1)

    local rows = {}
    local function Row(text)
        local label = W.Label(card, text, nil, PAD, 0, LABEL - 8, T.secondary)
        local host = CreateFrame("Frame", nil, card)
        host:SetSize(CONTROL, 30)
        local row = { label = label, host = host }
        rows[#rows + 1] = row
        return row
    end
    local refreshing
    card.sliders = {}
    for _, spec in ipairs(SLIDERS) do
        local row = Row(spec.label)
        local range = PM.STYLE[spec.key]
        row.refresh = W.Slider(row.host, range.minimum, range.maximum, 5, function()
            local element = Selected()
            return element and PM:GetStyle(element.id)[spec.key] or range.default
        end, function(value)
            local element = Selected()
            if not refreshing and element then PM:SetStyle(element.id, spec.key, value) end
        end, "%")
        row.slider = row.host.slider
        card.sliders[spec.key] = row
    end
    local background = Row("Background")
    local switch = W.Button(background.host, "", 34, 30, "toggle")
    switch:SetPoint("LEFT")
    switch:SetScript("OnClick", function()
        local element = Selected()
        if element and not InCombat() then PM:SetStyle(element.id, "background", not PM:GetStyle(element.id).background) end
    end)
    background.switch = switch
    card.backgroundRow = background

    -- A display may add its own groups below the shared rows
    -- (element.styleGroups: {{title=, rows={{kind=slider|select|toggle, label=, ...}}}}).
    -- Each group folds like Position; values are saved by the display itself.
    local Hold -- defined with the card's other slider handling below
    card.extras, card.extraOpen = {}, {}
    local function BuildExtras(element)
        if card.extras[element.id] or type(element.styleGroups) ~= "table" then return card.extras[element.id] end
        local built = {}
        for index, spec in ipairs(element.styleGroups) do
            local group = { title = spec.title, rows = {} }
            -- Only the first group starts open, so a long card still fits the screen.
            if card.extraOpen[spec.title] == nil then card.extraOpen[spec.title] = index == 1 end
            group.toggle = W.Button(card, spec.title, CARD_WIDTH - PAD * 2, 28, "secondary")
            group.toggle:SetScript("OnClick", function()
                card.extraOpen[spec.title] = not card.extraOpen[spec.title]
                owner:RefreshEditWindow()
            end)
            for _, rowSpec in ipairs(spec.rows or {}) do
                local row = Row(rowSpec.label)
                local function Set(value)
                    if refreshing or InCombat() then return end
                    rowSpec.set(value)
                    if card:IsShown() then card:Refresh() end
                end
                if rowSpec.kind == "slider" then
                    row.refresh = W.Slider(row.host, rowSpec.min, rowSpec.max, rowSpec.step or 1, rowSpec.get, Set, rowSpec.suffix or "")
                    Hold(row.host.slider)
                elseif rowSpec.kind == "select" then
                    -- choices: a list, or a function returning one (fonts known at open time).
                    local function Choices()
                        if type(rowSpec.choices) == "function" then return rowSpec.choices() end
                        return rowSpec.choices
                    end
                    local select = W.Select(row.host, CONTROL, Choices, function()
                        local value = rowSpec.get()
                        for _, choice in ipairs(Choices()) do if choice.id == value then return choice.id, choice.label end end
                        return value, tostring(value)
                    end, Set)
                    select:ClearAllPoints(); select:SetPoint("TOPLEFT")
                    row.dropdown, row.refresh = select, function() select:Refresh() end
                elseif rowSpec.kind == "color" then
                    -- Swatch that opens the game's colour picker; cancel restores the old colour.
                    local swatch = CreateFrame("Button", nil, row.host)
                    swatch:SetSize(34, 22); swatch:SetPoint("LEFT", 0, 0)
                    swatch.edge = swatch:CreateTexture(nil, "BORDER"); swatch.edge:SetAllPoints(); swatch.edge:SetColorTexture(0, 0, 0, 1)
                    swatch.fill = swatch:CreateTexture(nil, "ARTWORK"); swatch.fill:SetPoint("TOPLEFT", 1, -1); swatch.fill:SetPoint("BOTTOMRIGHT", -1, 1)
                    swatch:SetScript("OnClick", function()
                        if InCombat() or not ColorPickerFrame then return end
                        local old = rowSpec.get()
                        local function Apply(color) Set({ color[1], color[2], color[3] }) end
                        ColorPickerFrame:SetupColorPickerAndShow({ r = old[1], g = old[2], b = old[3], hasOpacity = false,
                            swatchFunc = function() local r, g, b = ColorPickerFrame:GetColorRGB(); Apply({ r, g, b }) end,
                            cancelFunc = function() Apply(old) end })
                    end)
                    row.swatch, row.refresh = swatch, function() local c = rowSpec.get(); swatch.fill:SetColorTexture(c[1], c[2], c[3], 1) end
                else
                    local toggle = W.Button(row.host, "", 34, 30, "toggle")
                    toggle:SetPoint("LEFT")
                    toggle:SetScript("OnClick", function() Set(not rowSpec.get()) end)
                    row.switch, row.refresh = toggle, function() toggle:SetSelected(rowSpec.get() == true) end
                end
                group.rows[#group.rows + 1] = row
            end
            built[#built + 1] = group
        end
        card.extras[element.id] = built
        return built
    end
    card.BuildExtras = BuildExtras

    -- Anchoring and exact offsets, folded away until asked for.
    local positionToggle = W.Button(card, "Position", CARD_WIDTH - PAD * 2, 28, "secondary")
    positionToggle:SetScript("OnClick", function()
        card.positionOpen = not card.positionOpen
        owner:RefreshEditWindow()
    end)
    card.positionToggle = positionToggle
    local position = {}
    local function Dropdown(text, choices, getter, setter)
        local row = Row(text)
        local button = W.Select(row.host, CONTROL, choices, getter, setter)
        button:ClearAllPoints(); button:SetPoint("TOPLEFT")
        row.dropdown = button
        position[#position + 1] = row
        return button, row
    end
    local function Position()
        local element = Selected()
        return element and PM:GetPosition(element.id)
    end
    local targets, targetRow = Dropdown("Anchor To", function()
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
        local p = Position()
        local id = p and p.target or "screen"
        local label = TARGET_LABELS[id] or (addon.FrameAnchors:ValidID(id) and id:sub(7)) or id
        if not P:Resolve(id) then label = label .. " (unavailable)" end
        return id, label
    end, function(id)
        local element = Selected()
        if not element then return end
        if id == "picker" then addon.FrameAnchors:Start(element.id) else E:SetTarget(id) end
    end)
    local placements, placementRow = Dropdown("Attach", function() return P.placements end, function()
        local p = Position()
        local placement = P:Placement(p and p.placement)
        return placement.id, placement.label
    end, function(id) E:SetPlacement(id) end)
    local function Coordinate(axis)
        local row = Row(axis == "x" and "X Offset" or "Y Offset")
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
        local refresh = W.Slider(row.host, low, high, 1, Get, function(value)
            if not refreshing then E:SetCoordinate(axis, value) end
        end, "", {
            minimum = function() local l = Limits(); return l end,
            maximum = function() local _, h = Limits(); return h end,
        })
        local input, slider = row.host.numericInput, row.host.slider
        input:SetWidth(64)
        slider:SetPoint("RIGHT", -72, 0)
        row.input, row.slider = input, slider
        row.refresh = function()
            local l, h = Limits()
            slider:SetMinMaxValues(l, h)
            refresh()
        end
        position[#position + 1] = row
        return row
    end
    local xRow, yRow = Coordinate("x"), Coordinate("y")
    card.targetDropdown, card.placementDropdown = targets, placements
    card.xInput, card.yInput, card.xSlider, card.ySlider = xRow.input, yRow.input, xRow.slider, yRow.slider

    local half = (CARD_WIDTH - PAD * 2 - 8) / 2
    local reset = W.Button(card, "Reset", half, 30, "secondary")
    reset:SetScript("OnClick", function()
        local element = Selected()
        if element and not InCombat() then PM:ResetLayout(element.id) end
    end)
    local settings = W.Button(card, "Settings", half, 30, "secondary")
    settings:SetScript("OnClick", function()
        if InCombat() then return end
        local element = Selected()
        if not element or not owner.modules[element.module.id] then return end
        local id = element.module.id
        owner:SetEditMode(false)
        owner:SelectConfigPage(id)
    end)
    card.resetButton, card.settingsButton = reset, settings

    local function Place(row, y)
        row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", PAD, -y - 8)
        row.host:ClearAllPoints(); row.host:SetPoint("TOPLEFT", PAD + LABEL, -y)
        row.label:Show(); row.host:Show()
    end
    local function Hide(row) row.label:Hide(); row.host:Hide() end
    function card:Layout()
        local y = HEADER + 10
        for _, spec in ipairs(SLIDERS) do Place(self.sliders[spec.key], y); y = y + ROW end
        Place(background, y); y = y + ROW
        local element = Selected()
        for id, groups in pairs(card.extras) do
            local current = element and element.id == id
            for _, group in ipairs(groups) do
                local open = card.extraOpen[group.title] == true
                if current then
                    group.toggle:ClearAllPoints(); group.toggle:SetPoint("TOPLEFT", PAD, -y - 2)
                    group.toggle.label:SetText(group.title .. (open and "  -" or "  +"))
                    group.toggle:Show()
                    y = y + ROW
                else group.toggle:Hide() end
                for _, row in ipairs(group.rows) do
                    if current and open then Place(row, y); y = y + ROW
                    else Hide(row); if row.dropdown then row.dropdown.menu:Hide() end end
                end
            end
        end
        positionToggle:ClearAllPoints(); positionToggle:SetPoint("TOPLEFT", PAD, -y - 2)
        positionToggle.label:SetText(self.positionOpen and "Position  -" or "Position  +")
        y = y + ROW
        for _, row in ipairs(position) do
            if self.positionOpen then Place(row, y); y = y + ROW else Hide(row) end
        end
        reset:ClearAllPoints(); reset:SetPoint("TOPLEFT", PAD, -y - 6)
        settings:ClearAllPoints(); settings:SetPoint("TOPLEFT", PAD + half + 8, -y - 6)
        self:SetHeight(y + FOOTER)
    end

    -- Beside the display, on the side with more room. While the display is
    -- dragged the card follows it; otherwise it is pinned to that spot on screen,
    -- so rescaling or offsetting the display never moves the slider being used.
    function card:Attach(element, follow)
        self:ClearAllPoints()
        local x = P:Geometry(element.frame)
        local cx = UIParent:GetCenter()
        if x and cx and x > cx then
            self:SetPoint("RIGHT", element.frame, "LEFT", -CARD_GAP, 0)
        else
            self:SetPoint("LEFT", element.frame, "RIGHT", CARD_GAP, 0)
        end
        self.attached, self.pinned = element.id, false
        if follow then return end
        local left, top = self:GetLeft(), self:GetTop()
        if issecretvalue and (issecretvalue(left) or issecretvalue(top)) then return end
        if type(left) ~= "number" or type(top) ~= "number" then return end
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        self.pinned = true
    end

    -- Holding a card slider keeps the card where it is until release.
    function Hold(slider)
        slider:HookScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then card.holding = true end
        end)
        local function Release()
            if not card.holding then return end
            card.holding = false
            if card:IsShown() then card:Refresh() end
        end
        slider:HookScript("OnMouseUp", Release)
        slider:HookScript("OnHide", Release)
    end
    for _, spec in ipairs(SLIDERS) do Hold(card.sliders[spec.key].slider) end
    Hold(xRow.slider); Hold(yRow.slider)

    function card:Refresh()
        local element = Selected()
        if not element then
            self.attached = nil
            for _, row in ipairs(position) do if row.dropdown then row.dropdown.menu:Hide() end end
            self:Hide()
            return
        end
        refreshing = true
        self.title:SetText(element.label or element.module.title)
        local style = PM:GetStyle(element.id)
        for _, spec in ipairs(SLIDERS) do self.sliders[spec.key].refresh() end
        local text = self.sliders.text
        text.slider:SetEnabled(element.styleText)
        text.label:SetTextColor(unpack(element.styleText and T.secondary or T.unavailable))
        switch:SetSelected(style.background)
        for _, group in ipairs(BuildExtras(element) or {}) do
            for _, row in ipairs(group.rows) do row.refresh() end
        end
        local anchoring = element.supportsAnchoring == true
        local available = P:Resolve(element.position.target or "screen") ~= nil
        targets:SetEnabled(anchoring); placements:SetEnabled(anchoring and available)
        targetRow.label:SetTextColor(unpack(anchoring and T.secondary or T.unavailable))
        placementRow.label:SetTextColor(unpack(anchoring and T.secondary or T.unavailable))
        for _, row in ipairs({ xRow, yRow }) do
            row.input:SetEnabled(available); row.slider:SetEnabled(available); row.refresh()
        end
        targets:Refresh(); placements:Refresh()
        settings:SetEnabled(owner.modules[element.module.id] ~= nil)
        self:Layout()
        -- A card follows its display while it is dragged; only re-pick a side when
        -- settled, and never while one of its own sliders is held.
        if element.dragging then
            if self.attached ~= element.id or self.pinned then self:Attach(element, true) end
        elseif self.attached ~= element.id or not self.holding then
            self:Attach(element)
        end
        self:Show()
        refreshing = false
    end
    function card:CloseMenus()
        for _, row in ipairs(position) do if row.dropdown then row.dropdown.menu:Hide() end end
        for _, groups in pairs(card.extras) do
            for _, group in ipairs(groups) do
                for _, row in ipairs(group.rows) do if row.dropdown then row.dropdown.menu:Hide() end end
            end
        end
    end
    return card
end

function addon:CreateEditWindow()
    local E, PM = self.EditMode, self.PositionManager
    local window = CreateFrame("Frame", "PlayTheGameToolsEditWindow", UIParent)
    window:Hide()
    self.editWindow = window
    window:SetSize(600, BAR_HEIGHT)
    window:SetPoint("TOP", UIParent, "TOP", 0, -24)
    window:SetFrameStrata("DIALOG")
    window:SetFrameLevel(80)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function()
        if InCombat() then return end
        window.moving = true; window:StartMoving()
    end)
    window:SetScript("OnDragStop", function() window:StopMovingOrSizing(); window.moving = false end)
    W.Texture(window, "Window")
    W.Texture(window, "BorderSilver", "BORDER")

    local title = W.Heading(window, "Layout", T.fontSize.section, BAR_PAD, -12, 120, T.text)
    local cue = W.Label(window, "Click a display to style it", nil, 0, -15, 220, T.primary)
    local hint = W.Label(window, "Drag to move", nil, 0, -15, 140, T.muted)
    local grid = W.Button(window, "", 34, 30, "toggle")
    grid:SetScript("OnClick", function() E:SetGrid(not E.grid) end)
    local gridLabel = W.Label(window, "Grid", nil, 0, -15, 60, T.secondary)
    local done = W.Button(window, "Done", 76, 30)
    done:SetSelected(true)
    done:SetScript("OnClick", function() self:SetEditMode(false) end)
    local empty = W.Label(window, "Turn on a module with a display to place it here.", nil, 0, 0, 420, T.muted)
    empty:ClearAllPoints(); empty:SetPoint("TOP", window, "BOTTOM", 0, -10); empty:SetJustifyH("CENTER")
    window.title, window.cue, window.hint, window.gridButton, window.gridLabel = title, cue, hint, grid, gridLabel
    window.doneButton, window.emptyLabel = done, empty
    -- Earlier name for Done, kept for callers of the Edit Mode window.
    window.exitButton = done

    function window:LayoutBar()
        local x = BAR_PAD
        local function Put(region, width, y)
            region:ClearAllPoints(); region:SetPoint("LEFT", window, "LEFT", x, y or 0)
            region:SetWidth(width); x = x + width + BAR_GAP
        end
        Put(title, TextWidth(title, 56))
        Put(cue, TextWidth(cue, 170))
        Put(hint, TextWidth(hint, 90))
        local gridX = x
        grid:ClearAllPoints(); grid:SetPoint("LEFT", window, "LEFT", gridX, 0); x = x + 40
        Put(gridLabel, TextWidth(gridLabel, 30))
        done:ClearAllPoints(); done:SetPoint("LEFT", window, "LEFT", x, 0); x = x + done:GetWidth() + BAR_PAD - 4
        self.contentWidth = x
        self:SetWidth(x)
    end
    window:LayoutBar()

    local card = CreateStyleCard(self, window)
    window.styleCard = card

    function self:RefreshEditWindow()
        if not self.editWindow then return end
        grid:SetSelected(E.grid)
        local count = 0
        for _, id in ipairs(PM.order) do
            local element = PM.elements[id]
            if element.editMode and element.module.enabled then count = count + 1 end
        end
        empty:SetShown(count == 0)
        card:Refresh()
    end
    -- Clearing focus runs the numeric input's normal apply.
    function self:CommitEditInputs() card.xInput:ClearFocus(); card.yInput:ClearFocus() end
    window:EnableKeyboard(true)
    window:SetPropagateKeyboardInput(true)
    window:SetScript("OnKeyDown", function(_, key)
        if InCombat() then return end
        window:SetPropagateKeyboardInput(key ~= "ESCAPE")
        if key == "ESCAPE" then self:SetEditMode(false) end
    end)
    window:SetScript("OnShow", function() self:RefreshLayoutGrid() end)
    window:SetScript("OnHide", function()
        card:CloseMenus(); card:Hide(); card.attached = nil
        window:StopMovingOrSizing(); window.moving = false
        self:RefreshLayoutGrid()
        if self.editMode and not window.ending then self:SetEditMode(false) end
    end)
    self.Dialogs:Register(window, { group = "editMode" })
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
    self:RefreshLayoutGrid()
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
