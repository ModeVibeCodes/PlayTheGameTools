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

function W.Fill(frame, color, layer, inset, alpha)
    color = InterfaceColor(color)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND")
    inset = inset or 0
    texture:SetPoint("TOPLEFT", inset, -inset)
    texture:SetPoint("BOTTOMRIGHT", -inset, inset)
    texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    return texture
end

function W.Texture(frame, key, layer, inset, alpha)
    local texture = W.Fill(frame, T.background, layer, inset)
    addon.Media:ApplyInterfaceTexture(texture, key, T.background)
    if alpha then texture:SetAlpha(alpha) end
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

function W.Heading(parent, text, size, x, y, width, color)
    local label = W.Label(parent, text, "GameFontNormalLarge", x, y, width, color or T.primary)
    addon.Media:BindInterfaceFont(label, GameFontNormalLarge, size)
    label:SetShadowColor(0, 0, 0, 0.12)
    label:SetShadowOffset(0, -1)
    return label
end

function W.Button(parent, text, width, height, style)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 120, height or 30)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    button.skinStyle = style or "button"
    local icon = style == "toggle" or style == "checkbox"
    local normal = style == "toggle" and "ToggleOff" or style == "checkbox" and "CheckboxOff"
        or style == "tab" and "TabDefault" or style == "secondary" and "ButtonSecondary" or "ButtonDefault"
    local active = style == "toggle" and "ToggleMint" or style == "checkbox" and "CheckboxMint"
        or (style == "tab" or style == "choice") and "TabSelected" or "ButtonActive"
    button.fill = W.Texture(button, normal)
    local highlight = W.Texture(button, icon and "AtelierFocus" or "ButtonHover", "HIGHLIGHT", 0, icon and 0.25 or 0.45)
    highlight:SetBlendMode("BLEND")
    local pressed = W.Texture(button, (icon or style == "tab" or style == "choice") and normal or "ButtonPressed", "ARTWORK")
    local disabled = W.Texture(button, (icon or style == "tab") and normal or "ButtonDisabled", "ARTWORK")
    button.activeGlow = W.Texture(button, icon and active or "AtelierSelection", "ARTWORK", 0, icon and 0.10 or 0.65)
    button.activeGlow:SetBlendMode("BLEND")
    button.activeGlow:Hide()
    if icon then
        local h = math.min(style == "toggle" and 26 or 24, height or 30)
        local w = style == "toggle" and h * 2 or h
        for _, region in ipairs({ button.fill, highlight, pressed, disabled, button.activeGlow }) do
            region:ClearAllPoints()
            region:SetPoint("CENTER")
            region:SetSize(w, h)
        end
        disabled:SetAlpha(0.4)
    end
    disabled:SetDesaturated(true)
    if not icon then
        button.selectionEdge = W.Texture(button, "AccentMint", "ARTWORK", 0, 0.8)
        button.selectionEdge:ClearAllPoints()
        button.selectionEdge:SetPoint("BOTTOMLEFT", 8, 1)
        button.selectionEdge:SetPoint("BOTTOMRIGHT", -8, 1)
        button.selectionEdge:SetHeight(1)
        button.selectionEdge:Hide()
    end
    button:SetNormalTexture(button.fill)
    button:SetHighlightTexture(highlight, "BLEND")
    button:SetPushedTexture(pressed)
    button:SetDisabledTexture(disabled)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    addon.Media:BindInterfaceFont(button.label, GameFontHighlight)
    W.CrispText(button.label)
    function button:RefreshAppearance()
        local available = self:IsEnabled()
        local color = self.labelColor or (self.selected and T.primary or (style == "choice" and T.muted or T.text))
        if not available then color = T.unavailable end
        local brighten = available and self.hovered and 0.07 or 0
        self.label:SetTextColor(math.min(1,color[1]+brighten), math.min(1,color[2]+brighten), math.min(1,color[3]+brighten), color[4] or 1)
        self.label:SetShadowColor(T.primary[1],T.primary[2],T.primary[3],available and self.hovered and 0.16 or 0)
        self.label:SetShadowOffset(0,-1)
        self.activeGlow:SetShown(available and (self.selected == true or self.moduleEnabled == true))
        if self.selectionEdge then self.selectionEdge:SetShown(available and self.selected == true) end
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
        if self.selected ~= selected then
            self.selected = selected
            addon.Media:ApplyInterfaceTexture(self.fill, selected and active or normal, T.background)
            if icon or style == "tab" or style == "choice" then
                addon.Media:ApplyInterfaceTexture(pressed, selected and active or normal, T.background)
            end
        end
        self:RefreshAppearance()
    end
    -- Hooks preserve existing tooltip and hide handlers on consumers.
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

-- Shared top-right enable cluster; retained heading metadata stays hidden.
function W.ModuleHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(28)
    header:EnableMouse(false)
    -- Keep metadata available to callers without repeating the window breadcrumb.
    local title = W.Heading(header, "", 24, 148, -8, 360, T.primary)
    local description = W.Label(header, "", nil, 16, -42, 360, T.text)
    title:Hide(); description:Hide()
    local toggle = W.Button(header, "", 44, 22, "toggle")
    toggle:SetPoint("TOPRIGHT", -14, -4)
    local state = W.Label(header, "", nil, 16, -6, 140, T.muted)
    state:ClearAllPoints();state:SetPoint("TOP",toggle,"BOTTOM",0,-3);state:SetWidth(80);state:SetJustifyH("CENTER")
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
        header:SetHeight(28)
        title:SetText(module and module.title or "Dashboard")
        description:SetText(module and (module.configDescription or module.description or "") or "")
        self:Refresh()
    end
    header.title, header.description, header.toggle, header.state = title, description, toggle, state
    return header
end

-- Integer by default; optional decimal precision for presentation parameters.
function W.NumericInput(parent, getter, setter, minimum, maximum, width, decimals)
    local input = CreateFrame("EditBox", nil, parent)
    input:SetSize(width or 52, 30)
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
    thumb:SetSize(8, height)
    thumb:SetVertexColor(unpack(T.primary))
    bar:SetThumbTexture(thumb)
    return thumb
end

function W.Slider(parent, minimum, maximum, step, getter, setter, suffix, numeric)
    local label = W.Label(parent, "", nil, 0, -8, 52, T.secondary)
    label:ClearAllPoints()
    label:SetPoint("RIGHT", 0, 0)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("LEFT", 0, 0)
    slider:SetPoint("RIGHT", -62, 0)
    slider:SetHeight(24)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    W.Texture(slider, "SliderTrack")
    local thumb = W.Texture(slider, "SliderThumb", "OVERLAY")
    thumb:ClearAllPoints()
    thumb:SetSize(16, 16)
    thumb:SetVertexColor(unpack(T.primary))
    local focus = W.Texture(slider, "AtelierFocus", "BORDER", 0, 0.25)
    focus:ClearAllPoints()
    focus:SetPoint("CENTER", thumb, "CENTER", 0, 0)
    focus:SetSize(24, 24)
    slider:SetThumbTexture(thumb)
    thumb:SetAlpha(0.9)
    slider:SetScript("OnEnter", function() thumb:SetAlpha(1);focus:SetAlpha(0.45) end)
    slider:SetScript("OnLeave", function() thumb:SetAlpha(0.9);focus:SetAlpha(0.25) end)
    slider:HookScript("OnMouseDown",function(_,button)
        if button=="LeftButton" then focus:SetAlpha(0.65);thumb:SetVertexColor(unpack(T.highlight)) end
    end)
    slider:HookScript("OnMouseUp",function()
        focus:SetAlpha(0.25);thumb:SetVertexColor(unpack(T.primary))
    end)
    slider:HookScript("OnHide",function()
        focus:SetAlpha(0.25);thumb:SetVertexColor(unpack(T.primary));thumb:SetAlpha(0.9)
    end)
    local updating, input
    local function Refresh()
        updating = true
        local value = getter()
        label:SetText(tostring(value) .. (suffix or ""))
        slider:SetValue(value, false) -- programmatic values retain exact integers
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
