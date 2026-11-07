local _, addon = ...
local T = addon.InterfaceTheme
local W = {}
addon.ConfigWidgets = W

-- Popups escape settings ScrollFrame clipping; anchors still follow the owned button.
function W.PlacePopup(menu,button)
    local ratio=button:GetEffectiveScale()/UIParent:GetEffectiveScale()
    menu:SetScale(ratio)
    local bottom=button.GetBottom and button:GetBottom()
    local below=not (issecretvalue and issecretvalue(bottom)) and type(bottom)=="number" and bottom*ratio or 0
    menu:ClearAllPoints()
    if below<menu:GetHeight()*ratio+8 then menu:SetPoint("BOTTOMLEFT",button,"TOPLEFT",0,4)
    else menu:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-4) end
end
function W.Popup(button,width,height)
    local menu=CreateFrame("Frame",nil,UIParent)
    menu:Hide();menu:SetSize(width,height);menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(200);menu:SetClampedToScreen(true);menu:EnableMouse(true)
    W.PlacePopup(menu,button)
    return menu
end
function W.GlowDropdown(parent,getter,setter,allowed)
    return W.Select(parent,260,function()
        local result={}
        for _,option in ipairs(addon.Glow.Options()) do
            if not allowed or allowed[option.id] then result[#result+1]=option end
        end
        return result
    end,function()
        local value=getter();local descriptor=addon.Glow.styles[value]
        local label=descriptor and descriptor.label or value
        return value,label..(addon.Glow.Available(value) and "" or " (unavailable; Border)")
    end,setter)
end

local function InterfaceColor(color)
    for key, original in pairs(addon.Theme) do
        if color == original then return T[key] or color end
    end
    return color
end

function W.StateColor(enabled)
    return enabled and T.enabled or T.off
end

function W.CrispText(region)
    -- Supported native pixel rounding; no global UI scale or font engine changes.
    if region.SetRoundLayoutToNearestPixel then region:SetRoundLayoutToNearestPixel(true) end
    region:SetShadowOffset(0, 0)
end

local function Paint(texture, color, alpha)
    texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end
W.Paint = Paint

function W.Fill(frame, color, layer, inset, alpha)
    color = InterfaceColor(color)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND")
    inset = inset or 0
    texture:SetPoint("TOPLEFT", inset, -inset)
    texture:SetPoint("BOTTOMRIGHT", -inset, inset)
    Paint(texture, color, alpha)
    return texture
end

-- Four 1px edges. Vertical edges stop short of the corners so translucent
-- outlines never double up.
function W.Outline(frame, color, layer, inset, alpha)
    inset = inset or 0
    local edges = {}
    local function Edge(a, ax, ay, b, bx, by, horizontal)
        local edge = frame:CreateTexture(nil, layer or "BORDER")
        edge:SetPoint(a, ax, ay); edge:SetPoint(b, bx, by)
        if horizontal then edge:SetHeight(1) else edge:SetWidth(1) end
        edges[#edges + 1] = edge
        return edge
    end
    Edge("TOPLEFT", inset, -inset, "TOPRIGHT", -inset, -inset, true)
    Edge("BOTTOMLEFT", inset, inset, "BOTTOMRIGHT", -inset, inset, true)
    Edge("TOPLEFT", inset, -inset - 1, "BOTTOMLEFT", inset, inset + 1)
    Edge("TOPRIGHT", -inset, -inset - 1, "BOTTOMRIGHT", -inset, inset + 1)
    local outline = { edges = edges }
    function outline:SetColor(value, opacity)
        for _, edge in ipairs(self.edges) do Paint(edge, InterfaceColor(value), opacity) end
    end
    function outline:SetShown(shown)
        for _, edge in ipairs(self.edges) do edge:SetShown(shown) end
    end
    outline:SetColor(color, alpha)
    return outline
end

-- Flat skin. Every legacy art key resolves to solid fills and hairlines, so
-- callers that still name a key keep working without bundled artwork.
local SKIN = {
    Window = { fill = "panel", line = "lineStrong" },
    Header = { fill = "surface" },
    Sidebar = { fill = "sidebar" },
    RaisedPanel = { fill = "panel" },
    InsetPanel = { fill = "surface" },
    BorderSilver = { line = "lineStrong" },
    InputField = { fill = "field", line = "lineStrong", focus = true },
    AccentMint = { fill = "line" },
    AccentLavender = { fill = "line" },
    UnderlineMint = { fill = "primary" },
    AtelierEdge = { fill = "line" },
    RoundMarker = { fill = "highlight" },
    ScrollThumb = { fill = "highlight" },
    SliderThumb = { fill = "highlight" },
    SliderTrack = { fill = "line" },
    AtelierFocus = { clear = true },
    AtelierBloom = { clear = true },
    AtelierSelection = { clear = true },
    ReadyCheck = { clear = true },
}
W.Skin = SKIN

function W.Texture(frame, key, layer, inset, alpha)
    local skin = assert(SKIN[key], "Play The Game Tools: unknown texture " .. tostring(key))
    local texture
    if skin.fill or skin.clear then
        texture = W.Fill(frame, skin.fill and T[skin.fill] or T.background, layer, inset, skin.clear and 0 or alpha)
    else
        -- Outline-only keys return an invisible anchor region for callers.
        texture = W.Fill(frame, T.background, layer, inset, 0)
    end
    if skin.line then
        texture.outline = W.Outline(frame, T[skin.line], skin.fill and "BORDER" or layer, inset, alpha)
    end
    if skin.focus and frame.HookScript and frame.HasFocus then
        -- Inputs show an accent hairline while they own keyboard focus.
        frame:HookScript("OnEditFocusGained", function() texture.outline:SetColor(T.primary, 0.85) end)
        frame:HookScript("OnEditFocusLost", function() texture.outline:SetColor(T[skin.line]) end)
    end
    return texture
end

function W.Label(parent, text, font, x, y, width, color)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x or 0, y or 0)
    label:SetWidth(width or 360)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(InterfaceColor(color) or T.text))
    label:SetText(text)
    W.CrispText(label)
    addon.Media:BindInterfaceFont(label, _G[font or "GameFontHighlight"])
    return label
end

-- Headings carry hierarchy through size and neutral color; the accent is
-- reserved for state, so an accent request is rendered in the text color.
function W.Heading(parent, text, size, x, y, width, color)
    color = InterfaceColor(color)
    if color == nil or color == T.primary then color = T.text end
    local label = W.Label(parent, text, "GameFontNormalLarge", x, y, width, color)
    addon.Media:BindInterfaceFont(label, GameFontNormalLarge, size)
    return label
end

-- Visual recipes per button style: fill, outline and label color for each state.
local BUTTON = {
    button = {
        fill = "surface", line = "lineStrong", label = "text",
        hoverFill = "hover", hoverLine = "secondary",
        pressedFill = "panel", selectedLine = "primary",
    },
    primary = {
        fill = "primary", label = "ink", hoverFill = "highlight", pressedFill = "primary",
        selectedLabel = "ink",
    },
    secondary = {
        line = "line", label = "secondary",
        hoverFill = "surface", hoverLine = "lineStrong", hoverLabel = "text",
        pressedFill = "panel", selectedLine = "primary",
    },
    choice = {
        line = "line", label = "muted",
        hoverFill = "surface", hoverLabel = "text",
        selectedFill = "surface", selectedLine = "primary", selectedLabel = "text",
    },
    tab = {
        label = "secondary", hoverFill = "surface", hoverLabel = "text",
        selectedFill = "surface", selectedLabel = "text", edge = true,
    },
    underline = {
        label = "muted", hoverLabel = "text", selectedLabel = "text",
    },
}

local function Color(key) return key and T[key] end

function W.Button(parent, text, width, height, style)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 120, height or 30)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    style = style or "button"
    button.skinStyle = style
    if style == "toggle" or style == "checkbox" then return W.Switch(button, text, height, style) end
    local recipe = BUTTON[style] or BUTTON.button
    button.fill = W.Fill(button, T.surface, "BACKGROUND")
    button.outline = W.Outline(button, T.line, "BORDER")
    -- Kept for consumers that tint the selected state directly.
    button.activeGlow = W.Fill(button, T.primary, "ARTWORK", 0, 0.08)
    button.activeGlow:Hide()
    if recipe.edge then
        -- Selected navigation rows carry a 2px accent bar on the leading edge.
        button.selectionEdge = W.Fill(button, T.primary, "OVERLAY")
        button.selectionEdge:ClearAllPoints()
        button.selectionEdge:SetPoint("TOPLEFT"); button.selectionEdge:SetPoint("BOTTOMLEFT")
        button.selectionEdge:SetWidth(2)
        button.selectionEdge:Hide()
    end
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    addon.Media:BindInterfaceFont(button.label, GameFontHighlight)
    W.CrispText(button.label)
    function button:RefreshAppearance()
        local available = self:IsEnabled()
        local hovered = available and self.hovered
        local pressed = hovered and self.pressed
        local selected = available and self.selected == true
        local fill = recipe.fill
        local line = recipe.line
        local label = recipe.label
        if selected then
            fill = recipe.selectedFill or fill
            line = recipe.selectedLine or line
            label = recipe.selectedLabel or "primary"
        end
        if hovered then
            fill = recipe.hoverFill or fill
            line = recipe.hoverLine or line
            label = selected and label or recipe.hoverLabel or label
        end
        if pressed then fill = recipe.pressedFill or fill end
        local fillColor, lineColor = Color(fill), Color(line)
        if selected and line == "primary" and hovered then lineColor = T.primary end
        if not available then
            fillColor = recipe.fill and (style == "primary" and T.surface or T.sidebar) or nil
            lineColor = recipe.line and T.line or nil
        end
        if fillColor then Paint(self.fill, fillColor) else Paint(self.fill, T.background, 0) end
        if lineColor then
            self.outline:SetColor(lineColor, selected and line == "primary" and 0.7 or nil)
            self.outline:SetShown(true)
        else self.outline:SetShown(false) end
        local color = self.labelColor or Color(label) or T.text
        if not available then color = T.unavailable end
        self.label:SetTextColor(color[1], color[2], color[3], color[4] or 1)
        self.activeGlow:SetShown(selected and style ~= "primary" and style ~= "underline")
        if self.selectionEdge then self.selectionEdge:SetShown(selected) end
    end
    function button:SetLabelColor(color)
        self.labelColor = color
        self:RefreshAppearance()
    end
    local nativeSetEnabled = button.SetEnabled
    function button:SetEnabled(enabled)
        nativeSetEnabled(self, enabled)
        self:RefreshAppearance()
    end
    function button:SetSelected(selected)
        self.selected = selected
        self:RefreshAppearance()
    end
    -- Hooks preserve existing tooltip and hide handlers on consumers.
    button:HookScript("OnEnter",function(self) self.hovered=true;self:RefreshAppearance() end)
    button:HookScript("OnLeave",function(self) self.hovered=false;self.pressed=false;self:RefreshAppearance() end)
    button:HookScript("OnMouseDown",function(self) self.pressed=true;self:RefreshAppearance() end)
    button:HookScript("OnMouseUp",function(self) self.pressed=false;self:RefreshAppearance() end)
    button:HookScript("OnHide",function(self) self.hovered=false;self.pressed=false;self:RefreshAppearance() end)
    button:RefreshAppearance()
    return button
end

-- Square switch (toggle) and checkbox. Both are sharp-cornered to match the
-- rest of the shell; state is carried by fill, not by artwork.
function W.Switch(button, text, height, style)
    local toggle = style == "toggle"
    local h = toggle and 18 or 16
    local w = toggle and 34 or 16
    local track = button:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("CENTER"); track:SetSize(w, h)
    local frame = CreateFrame("Frame", nil, button)
    frame:SetPoint("CENTER"); frame:SetSize(w, h)
    local outline = W.Outline(frame, T.lineStrong, "BORDER")
    local mark = button:CreateTexture(nil, "ARTWORK")
    mark:SetSize(toggle and 12 or 8, toggle and 12 or 8)
    button.fill, button.knob, button.switchOutline = track, mark, outline
    -- Inert stand-in so shared consumers can still address the glow region.
    button.activeGlow = W.Fill(button, T.primary, "ARTWORK", 0, 0)
    button.activeGlow:Hide()
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    addon.Media:BindInterfaceFont(button.label, GameFontHighlight)
    W.CrispText(button.label)
    function button:RefreshAppearance()
        local available = self:IsEnabled()
        local on = self.selected == true
        local hovered = available and self.hovered
        Paint(track, toggle and (on and T.primary or T.surface) or T.field)
        outline:SetColor(on and T.primary or (hovered and T.secondary or T.lineStrong))
        mark:ClearAllPoints()
        if toggle then
            mark:SetPoint(on and "RIGHT" or "LEFT", track, on and "RIGHT" or "LEFT", on and -3 or 3, 0)
            Paint(mark, on and T.ink or (hovered and T.text or T.secondary))
            mark:Show()
        else
            mark:SetPoint("CENTER", track, "CENTER", 0, 0)
            Paint(mark, T.primary)
            mark:SetShown(on)
        end
        local alpha = available and 1 or 0.4
        track:SetAlpha(alpha); mark:SetAlpha(alpha)
        for _, edge in ipairs(outline.edges) do edge:SetAlpha(alpha) end
        local color = self.labelColor or T.text
        self.label:SetTextColor(color[1], color[2], color[3], available and (color[4] or 1) or 0.5)
    end
    function button:SetLabelColor(color) self.labelColor = color; self:RefreshAppearance() end
    local nativeSetEnabled = button.SetEnabled
    function button:SetEnabled(enabled) nativeSetEnabled(self, enabled); self:RefreshAppearance() end
    function button:SetSelected(selected) self.selected = selected; self:RefreshAppearance() end
    button:HookScript("OnEnter",function(self) self.hovered=true;self:RefreshAppearance() end)
    button:HookScript("OnLeave",function(self) self.hovered=false;self:RefreshAppearance() end)
    button:HookScript("OnHide",function(self) self.hovered=false;self:RefreshAppearance() end)
    button:RefreshAppearance()
    return button
end

-- Exclusive settings use one getter/setter; no independent saved flags.
function W.Exclusive(parent, choices, getter, setter)
    local buttons, x = {}, 0
    for _, choice in ipairs(choices) do
        local value = choice.value
        local button = W.Button(parent, choice.label, choice.width or 132, 30, "choice")
        button:SetPoint("LEFT", x, 0)
        button:SetScript("OnClick", function() setter(value) end)
        buttons[#buttons + 1] = button
        x = x + (choice.width or 132) + 8
    end
    local function Refresh()
        for index, button in ipairs(buttons) do button:SetSelected(getter() == choices[index].value) end
    end
    return buttons, Refresh
end

W.PAGE_HEADER_HEIGHT = 64

-- Page header: title and one-line description on the left, the module's
-- enable switch on the right, closed by a hairline.
function W.ModuleHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(W.PAGE_HEADER_HEIGHT)
    header:EnableMouse(false)
    local title = W.Heading(header, "", T.fontSize.page, 0, -2, 520, T.text)
    title:SetWordWrap(false)
    local description = W.Label(header, "", nil, 0, -30, 520, T.muted)
    description:SetWordWrap(false)
    local toggle = W.Button(header, "", 44, 24, "toggle")
    toggle:SetPoint("TOPRIGHT", 0, -2)
    local state = W.Label(header, "", nil, 0, 0, 80, T.muted)
    state:ClearAllPoints(); state:SetPoint("RIGHT", toggle, "LEFT", -6, 0); state:SetJustifyH("RIGHT")
    title:SetPoint("TOPRIGHT", -140, -2)
    description:SetPoint("TOPRIGHT", -140, -30)
    local divider = W.Fill(header, T.line, "BORDER")
    divider:ClearAllPoints(); divider:SetPoint("BOTTOMLEFT", 0, 12); divider:SetPoint("BOTTOMRIGHT", 0, 12)
    divider:SetHeight(1)
    toggle:SetScript("OnClick", function()
        if header.module then addon:SetModuleEnabled(header.module.id, not header.module.enabled) end
    end)
    function header:Refresh()
        local gameplay = self.module ~= nil and not self.module.developer
        toggle:SetShown(gameplay)
        state:SetShown(gameplay)
        if self.module then
            toggle:SetSelected(self.module.enabled)
            state:SetText(self.module.enabled and "Enabled" or "Disabled")
            state:SetTextColor(unpack(W.StateColor(self.module.enabled)))
        end
    end
    function header:SetModule(module)
        self.module = module
        title:SetText(module and module.title or "Dashboard")
        description:SetText(module and (module.configDescription or module.description or "")
            or "Turn modules on or off, or open one to change its settings.")
        self:Refresh()
    end
    header.title, header.description, header.toggle, header.state, header.divider = title, description, toggle, state, divider
    return header
end

-- Integer by default; optional decimal precision for presentation parameters.
function W.NumericInput(parent, getter, setter, minimum, maximum, width, decimals)
    local input = CreateFrame("EditBox", nil, parent)
    input:SetSize(width or 52, 28)
    input:SetAutoFocus(false)
    input:SetMaxLetters(9)
    input:SetFontObject(GameFontHighlight)
    input:SetTextInsets(8, 8, 0, 0)
    addon.Media:BindInterfaceFont(input, GameFontHighlight)
    W.CrispText(input)
    W.Texture(input, "InputField")
    local applying
    function input:Refresh(force)
        if force or not self:HasFocus() then
            local text = decimals and string.format("%."..decimals.."f",getter()) or tostring(math.floor(getter() + 0.5))
            if text ~= self:GetText() then self:SetText(text) end
        end
    end
    local function Apply()
        if applying then return end
        applying = true
        local text = input:GetText()
        local pattern=decimals and "^%s*[+-]?%d+%.?%d*%s*$" or "^%s*[+-]?%d+%s*$"
        if text:match(pattern) then
            local value = tonumber(text)
            if value and value == value and math.abs(value) < math.huge then
                local low = type(minimum) == "function" and minimum() or minimum
                local high = type(maximum) == "function" and maximum() or maximum
                setter(math.max(low, math.min(high, value)))
            end
        end
        input:ClearFocus()
        input:Refresh(true)
        if input.afterApply then input.afterApply() end
        applying = false
    end
    input:SetScript("OnEnterPressed", Apply)
    input:SetScript("OnEditFocusLost", Apply)
    input:SetScript("OnEscapePressed", function()
        input:Refresh(true)
        input:ClearFocus()
    end)
    input:Refresh(true)
    return input
end

function W.ScrollThumb(bar, height)
    local thumb = W.Texture(bar, "ScrollThumb", "OVERLAY")
    thumb:ClearAllPoints()
    thumb:SetSize(4, height)
    thumb:SetVertexColor(unpack(T.lineStrong))
    bar:SetThumbTexture(thumb)
    bar:HookScript("OnEnter", function() thumb:SetVertexColor(unpack(T.muted)) end)
    bar:HookScript("OnLeave", function() thumb:SetVertexColor(unpack(T.lineStrong)) end)
    return thumb
end

-- Hairline track with an accent fill up to the current value and a flat
-- rectangular thumb.
function W.Slider(parent, minimum, maximum, step, getter, setter, suffix, numeric)
    local label = W.Label(parent, "", nil, 0, -8, 52, T.secondary)
    label:ClearAllPoints()
    label:SetPoint("RIGHT", 0, 0)
    label:SetJustifyH("RIGHT")
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("LEFT", 0, 0)
    slider:SetPoint("RIGHT", -62, 0)
    slider:SetHeight(24)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    local track = W.Texture(slider, "SliderTrack")
    track:ClearAllPoints()
    track:SetPoint("LEFT", 0, 0); track:SetPoint("RIGHT", 0, 0); track:SetHeight(2)
    local progress = W.Fill(slider, T.primary, "BORDER")
    progress:ClearAllPoints()
    progress:SetPoint("LEFT", 0, 0); progress:SetHeight(2); progress:SetWidth(1)
    local thumb = W.Texture(slider, "SliderThumb", "OVERLAY")
    thumb:ClearAllPoints()
    thumb:SetSize(8, 16)
    thumb:SetVertexColor(unpack(T.text))
    slider:SetThumbTexture(thumb)
    local hovered
    local function Tint(color) thumb:SetVertexColor(unpack(color)) end
    local function Progress()
        local low, high = slider:GetMinMaxValues()
        local width = slider:GetWidth()
        if (issecretvalue and (issecretvalue(low) or issecretvalue(high) or issecretvalue(width)))
            or type(low) ~= "number" or type(high) ~= "number" or type(width) ~= "number" then return end
        local span = high - low
        local ratio = span > 0 and (slider:GetValue() - low) / span or 0
        progress:SetWidth(math.max(1, math.min(1, math.max(0, ratio)) * width))
        progress:SetShown(ratio > 0)
    end
    slider:SetScript("OnEnter", function() hovered = true; Tint(T.primary) end)
    slider:SetScript("OnLeave", function() hovered = false; Tint(T.text) end)
    slider:HookScript("OnMouseDown",function(_,button)
        if button=="LeftButton" then Tint(T.highlight) end
    end)
    slider:HookScript("OnMouseUp",function() Tint(hovered and T.primary or T.text) end)
    slider:HookScript("OnHide",function() hovered = false; Tint(T.text) end)
    slider:HookScript("OnSizeChanged", Progress)
    local updating, input
    local function Refresh()
        updating = true
        local value = getter()
        label:SetText(tostring(value) .. (suffix or ""))
        slider:SetValue(value, false) -- programmatic values retain exact integers
        Progress()
        if input then input:Refresh() end
        updating = false
    end
    slider:SetScript("OnValueChanged", function(_, value)
        if updating then return end
        setter(value)
        Refresh()
        if input then input:Refresh(true) end
    end)
    if numeric then
        label:Hide()
        local options = type(numeric) == "table" and numeric or {}
        input = W.NumericInput(parent, getter, setter, options.minimum or minimum, options.maximum or maximum,nil,options.decimals)
        input:SetPoint("RIGHT")
        input.afterApply = Refresh
        parent.numericInput = input
    end
    parent.slider = slider
    return Refresh
end
