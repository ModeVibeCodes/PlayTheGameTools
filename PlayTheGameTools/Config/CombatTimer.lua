local _, addon = ...
local widgets = addon.ConfigWidgets

local function Hex(rgb)
    return string.format("#%02X%02X%02X", math.floor(rgb[1] * 255 + 0.5), math.floor(rgb[2] * 255 + 0.5), math.floor(rgb[3] * 255 + 0.5))
end

local function ParseHex(value)
    value = value:gsub("^#", "")
    if not value:match("^%x%x%x%x%x%x$") then return end
    return { tonumber(value:sub(1, 2), 16) / 255, tonumber(value:sub(3, 4), 16) / 255, tonumber(value:sub(5, 6), 16) / 255 }
end

function addon:CloseTimerColorPicker()
    if self.timerPickerCallback and ColorPickerFrame and self.timerPickerCallback == ColorPickerFrame.swatchFunc then
        ColorPickerFrame:Hide()
    end
    self.timerPickerCallback = nil
    self.timerPickerOwner = nil
end

function widgets.ColorRow(page, timer, title, key, enabledGetter, host, options)
    local function Enabled() return not enabledGetter or enabledGetter() end
    local function Action(parent, text, width, callback)
        local button = widgets.Button(parent, text, width, 30)
        button:SetPoint("LEFT")
        button:SetScript("OnClick", function() callback(); page:Refresh() end)
        return button
    end
    local row = host or page:Row(title)
    local pick
    pick = Action(row, "Pick", 72, function()
        if not Enabled() or not timer:CanConfigure() then return end
        if not ColorPickerFrame then C_AddOns.LoadAddOn("Blizzard_ColorPickerFrame") end
        if not ColorPickerFrame then
            print(addon.InterfaceTheme.id=="mode" and "Play The Game Tools: Blizzard color picker is unavailable on this client." or "Play The Game Tools: Blizzard color picker is unavailable; use the RGB hex field.")
            return
        end
        addon:CloseTimerColorPicker()
        local oldColor = timer.db.appearance[key]
        local previous = { oldColor[1], oldColor[2], oldColor[3] }
        local swatch = function()
            if not Enabled() then return end
            local r, g, b = ColorPickerFrame:GetColorRGB()
            timer:SetAppearance(key, { r, g, b })
            page:Refresh()
        end
        addon.timerPickerCallback = swatch
        addon.timerPickerOwner = pick
        ColorPickerFrame:SetupColorPickerAndShow({
            r = oldColor[1], g = oldColor[2], b = oldColor[3], hasOpacity = false,
            swatchFunc = swatch,
            cancelFunc = function() timer:SetAppearance(key, previous); page:Refresh() end,
        })
    end)
    local sample = (options and options.separateSwatch and row or pick):CreateTexture(nil, "OVERLAY")
    sample:SetPoint("LEFT", 6, 0)
    sample:SetSize(12, 16)
    local hex = CreateFrame("EditBox", nil, row)
    hex:SetPoint("LEFT", 80, 0)
    hex:SetSize(96, 30)
    hex:SetAutoFocus(false)
    hex:SetMaxLetters(7)
    hex:SetFontObject(GameFontHighlight)
    addon.Media:BindInterfaceFont(hex, GameFontHighlight)
    hex:SetTextInsets(8, 8, 0, 0)
    widgets.Texture(hex, "InputField")
    local applyingHex
    local function ApplyHex()
        if applyingHex then return end
        applyingHex=true
        if not Enabled() then hex:ClearFocus(); page:Refresh(); applyingHex=false;return end
        local rgb = ParseHex(hex:GetText())
        if rgb then timer:SetAppearance(key, rgb)
        else print("Play The Game Tools: enter exactly six RGB hex digits, for example #FFFFFF.") end
        hex:ClearFocus()
        page:Refresh();applyingHex=false
    end
    local apply
    if not (options and options.immediateHex) then apply = Action(row, "Apply", 64, ApplyHex) end
    if apply then apply:ClearAllPoints();apply:SetPoint("LEFT",184,0) end
    hex:SetScript("OnEnterPressed", ApplyHex)
    if options and options.immediateHex then hex:SetScript("OnEditFocusLost",ApplyHex) end
    hex:SetScript("OnEscapePressed", function() applyingHex=true;hex:ClearFocus();page:Refresh();applyingHex=false end)
    page.refreshers[#page.refreshers + 1] = function()
        local color = timer.db.appearance[key]
        if not (options and options.immediateHex) or not hex:HasFocus() then hex:SetText(Hex(color)) end
        sample:SetColorTexture(color[1], color[2], color[3], 1)
        local enabled = Enabled()
        pick:SetEnabled(enabled);if apply then apply:SetEnabled(enabled) end;hex:SetEnabled(enabled)
        sample:SetAlpha(enabled and 1 or 0.4)
        row.rowLabel:SetTextColor(unpack(enabled and addon.Theme.text or addon.Theme.muted))
        if not enabled and addon.timerPickerOwner == pick then addon:CloseTimerColorPicker() end
    end
    page.settingsColors=page.settingsColors or {}
    page.settingsColors[#page.settingsColors+1]={host=row,pick=pick,hex=hex,apply=apply,sample=sample,key=key}
    return pick, hex, apply, sample
end

-- Shared existing timer controls; module-specific formats/behavior are supplied by callers.
function addon:CreateTimerOptions(parent, timer, options)
    options = options or {}
    local page = widgets.Page(parent)
    self[timer.id .. "Options"] = page
    local function Action(parent, text, width, callback, style)
        local button = widgets.Button(parent, text, width, 30, style)
        button:SetPoint("LEFT")
        button:SetScript("OnClick", function() callback(); page:Refresh() end)
        return button
    end
    local function Slider(title, minimum, maximum, step, getter, setter, suffix, numeric)
        local row = page:Row(title)
        page.refreshers[#page.refreshers + 1] = widgets.Slider(row, minimum, maximum, step, getter, setter, suffix, numeric)
        if title == "Font Size" then page.fontSizeInput, page.fontSizeSlider = row.numericInput, row.slider
        elseif title == "Background opacity" then page.opacityInput, page.opacitySlider = row.numericInput, row.slider
        elseif title == "Frame scale" then page.scaleInput, page.scaleSlider = row.numericInput, row.slider end
    end

    widgets.Preview(page, timer)
    page:Section("Display")
    local formats = options.formats or { { "plain", "MM:SS" }, { "square", "[MM:SS]" }, { "round", "(MM:SS)" } }
    local formatRow = page:Row(options.formatTitle or "Timer format")
    local offset = 0
    for index, choice in ipairs(formats) do
        local key, label = choice[1], choice[2]
        local width = choice[3] or 78
        local button = Action(formatRow, label, width, function() timer:SetAppearance("format", key) end)
        button:ClearAllPoints()
        button:SetPoint("LEFT", offset, 0)
        offset = offset + width + 8
        page.refreshers[#page.refreshers + 1] = function() button:SetSelected(timer.db.appearance.format == key) end
    end
    local font, refreshFont = widgets.FontDropdown(page:Row("Font", nil, { "font selection", "typeface" }), timer)
    page.fontDropdown = font
    page.refreshers[#page.refreshers + 1] = refreshFont
    Slider("Font Size", 10, 48, 1, function() return timer.db.appearance.fontSize end, function(v) timer:SetAppearance("fontSize", v) end, nil, true)
    local outline = Action(page:Row("Text outline", nil, { "font outline" }), "", 30, function() timer:SetAppearance("outline", not timer.db.appearance.outline) end, "checkbox")
    page.outlineButton = outline
    page.refreshers[#page.refreshers + 1] = function()
        outline:SetSelected(timer.db.appearance.outline)
    end

    widgets.ColorRow(page, timer, "Text Color", "textColor")
    widgets.ColorRow(page, timer, "Background Color", "backgroundColor")
    Slider("Background opacity", 0, 100, 5,
        function() return math.floor(timer.db.appearance.backgroundOpacity * 100 + 0.5) end,
        function(v) timer:SetAppearance("backgroundOpacity", v / 100) end, "%", { minimum = 1, maximum = 100 })

    Slider("Frame scale", 50, 200, 5,
        function() return math.floor(timer.db.appearance.scale * 100 + 0.5) end,
        function(v) timer:SetAppearance("scale", v / 100) end, "%", true)

    page:Section("Behavior")
    if options.behavior then options.behavior(page, Action)
    else
    local visibility, refreshVisibility = widgets.Exclusive(page:Row("Combat visibility", nil, { "always visible", "only in combat", "show", "hide" }), {
        { label = "Always Visible", value = true, width = 132 },
        { label = "Only in Combat", value = false, width = 148 },
    }, function() return timer.db.showOutOfCombat end, function(value) timer:SetShowOutOfCombat(value); page:Refresh() end)
    page.visibilityButtons = visibility
    page.refreshers[#page.refreshers + 1] = refreshVisibility
    end
    page:Section("Positioning")
    widgets.PositionControls(page,timer)
    widgets.SectionTabs(page)
    page:SetScript("OnHide",function() if timer.OnConfigClosed then timer:OnConfigClosed() end end)
    page:Finish()
    return page
end

function addon:CreateCombatTimerOptions(parent)
    return self:CreateTimerOptions(parent, self.modules.combatTimer)
end

addon.modules.combatTimer.configDescription = "Displays elapsed time while you are in combat."
addon.modules.combatTimer.CreateConfigPage = function(_, parent)
    return addon:CreateCombatTimerOptions(parent)
end

function addon:CreateTimerConfigPreview(timer, parent, renderer)
    renderer = renderer or self.CombatTimerDisplay
    local view = { frame = CreateFrame("Frame", nil, parent) }
    view.frame:SetPoint("CENTER")
    view.frame:EnableMouse(false)
    view.background = view.frame:CreateTexture(nil, "BACKGROUND")
    view.background:SetAllPoints()
    view.text = view.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    view.text:SetPoint("CENTER")
    function view:Refresh()
        -- Existing combat-safe color/format updates still refresh the sample.
        local layout = not (InCombatLockdown() or UnitAffectingCombat("player")) or not self.ready
        renderer.Apply(self, timer.db.appearance, layout)
        if layout then
            local scale = math.min(timer.db.appearance.scale,
                math.max(1, parent:GetWidth()) / self.frame:GetWidth(),
                math.max(1, parent:GetHeight()) / self.frame:GetHeight())
            self.frame:SetScale(scale)
        end
        local seconds=addon.PreviewStates:Sample(timer.id)
        self.text:SetText(seconds and renderer.Format(seconds,timer.db.appearance.format) or (renderer.Sample and renderer.Sample(timer.db) or renderer.Format(84, timer.db.appearance.format)))
        self.ready = true
    end
    function view:RenderSimulation() local seconds=addon.PreviewStates:Sample(timer.id);self.text:SetText(renderer.Format(seconds or 84,timer.db.appearance.format)) end
    return view
end

addon.modules.combatTimer.CreateConfigPreview = function(timer, parent)
    return addon:CreateTimerConfigPreview(timer, parent)
end

-- Register with the timer's page, so editions need no unrelated simulation services.
addon.PreviewStates:Register("combatTimer",{
    states={{id="default",label="Normal Preview"},{id="running",label="Running Timer"},{id="inactive",label="Inactive Timer"}},previewAnimated="running",animated={running=true},
    sample=function(mode,elapsed) return mode=="running" and math.floor(84+elapsed) or 0 end,
})
