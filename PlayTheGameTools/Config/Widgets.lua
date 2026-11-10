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
    menu.ptgMediaScope=addon.Media:FrameScope(button)
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
    if T.blizzardArt then
        -- Stock interface text carries a soft drop shadow; it keeps gold and
        -- parchment legible on the textured stone without raising contrast.
        region:SetShadowColor(0, 0, 0, 0.85)
        region:SetShadowOffset(1, -1)
    else
        region:SetShadowOffset(0, 0)
    end
end

local function Paint(texture, color, alpha)
    if texture.modeAsset then
        local usable=texture.appliedModeAsset==texture.modeAsset or addon.Media:ApplyTexture(texture,texture.modeAsset,color)
        if usable then
            texture.appliedModeAsset=texture.modeAsset
            texture:SetVertexColor(color[1], color[2], color[3], alpha or color[4] or 1)
            return
        end
        -- Missing borders must never become opaque rectangles over controls.
        if texture.modeAsset:find("Border",1,true) then texture:SetColorTexture(0,0,0,0);return end
    end
    texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end
W.Paint = Paint

-- Static neutral sheen over the large Figma material, below all controls/text.
-- Reuses the gradient API already used by the Forever map renderer.
function W.ModeSheen(frame,inset)
    local texture=frame:CreateTexture(nil,"BACKGROUND",nil,2)
    inset=inset or 0
    texture:SetPoint("TOPLEFT",inset,-inset);texture:SetPoint("BOTTOMRIGHT",-inset,inset)
    texture.modeAsset="ModeSurface";Paint(texture,{1,1,1,1})
    if texture.SetGradient and CreateColor then
        texture:SetGradient("VERTICAL",CreateColor(1,1,1,0.018),CreateColor(1,1,1,0))
    else texture:SetAlpha(0.008) end
    return texture
end

function W.Fill(frame, color, layer, inset, alpha)
    color = InterfaceColor(color)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND")
    inset = inset or 0
    texture:SetPoint("TOPLEFT", inset, -inset)
    texture:SetPoint("BOTTOMRIGHT", -inset, inset)
    Paint(texture, color, alpha)
    if T.id=="mode" and color==T.line then
        texture.modeAsset="ModeDivider";Paint(texture,color,alpha)
    end
    if color==T.panel or color==T.surface or color==T.sidebar or color==T.field or color==T.background then
        if T.id == "mode" and (addon.Media:GlobalStyle("texture") or "default") == "default" then
            texture.modeAsset = "ModeSurface"
            Paint(texture, color, alpha)
        else addon.Media:PaintSurface(texture,color,alpha) end
    end
    return texture
end

-- Four 1px edges. Vertical edges stop short of the corners so translucent
-- outlines never double up.
function W.Outline(frame, color, layer, inset, alpha, scope)
    scope=scope or addon.Media:FrameScope(frame)
    inset = inset or 0
    local style=addon.Media:GlobalStyle("border",scope) or "thin"
    if T.id == "mode" and not frame.ptgSquareOutline and (style == "thin" or style == "none") then
        local texture=frame:CreateTexture(nil,layer or "BORDER")
        texture:SetPoint("TOPLEFT",inset,-inset);texture:SetPoint("BOTTOMRIGHT",-inset,inset)
        texture.modeAsset=frame.modeBorderAsset or "ModeBorder"
        local outline={edges={texture},shown=true,kind=style,rounded=true}
        function outline:SetShown(shown) self.shown=shown;texture:SetShown(shown and self.kind~="none") end
        function outline:SetColor(value,opacity)
            Paint(texture,InterfaceColor(value),opacity or 0.36)
            self.kind=addon.Media:GlobalStyle("border",scope)=="none" and "none" or "thin"
            self:SetShown(self.shown)
        end
        outline:SetColor(color,alpha)
        return outline
    end
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
    local outline = { edges = edges, shown = true }
    function outline:SetColor(value, opacity)
        for _, edge in ipairs(self.edges) do Paint(edge, InterfaceColor(value), opacity) end
        local style=addon.Media:GlobalStyle("border",scope) or "thin"
        self.kind=style=="none" and "none" or style=="thin" and "thin" or "shared"
        if self.kind=="shared" then
            if not self.view then self.view={};addon.Border.Create(self.view,frame) end
            addon.Border.Apply(self.view,{borderStyle=style,borderColor=InterfaceColor(value),
                borderOpacity=opacity or 1,inset=true,size=64})
        end
        self:SetShown(self.shown)
    end
    function outline:SetShown(shown)
        self.shown=shown
        for _,edge in ipairs(self.edges) do edge:SetShown(shown and self.kind=="thin") end
        if self.view then
            self.view.iconBorder:SetShown(shown and self.kind=="shared" and self.view.borderKind=="thin")
            if self.view.borderFrame then self.view.borderFrame:SetShown(shown and self.kind=="shared" and self.view.borderKind=="shared") end
        end
    end
    outline:SetColor(color, alpha)
    return outline
end

-- Stock interface artwork for the Blizzard theme. These are long-standing
-- shared client files (the same ones the stock panel button, tooltip, dialog,
-- checkbox and input box templates draw). Every consumer keeps its flat
-- drawing underneath or as the fallback when a file is refused.
local ART = {
    buttonUp = "Interface\\Buttons\\UI-Panel-Button-Up",
    buttonDown = "Interface\\Buttons\\UI-Panel-Button-Down",
    buttonDisabled = "Interface\\Buttons\\UI-Panel-Button-Disabled",
    buttonHighlight = "Interface\\Buttons\\UI-Panel-Button-Highlight",
    checkbox = "Interface\\Buttons\\UI-CheckBox-Up",
    checkboxHighlight = "Interface\\Buttons\\UI-CheckBox-Highlight",
    check = "Interface\\Buttons\\UI-CheckBox-Check",
    checkDisabled = "Interface\\Buttons\\UI-CheckBox-Check-Disabled",
    input = "Interface\\Common\\Common-Input-Border",
    sliderThumb = "Interface\\Buttons\\UI-SliderBar-Button-Horizontal",
    rowHighlight = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight",
    dialogBackground = "Interface\\DialogFrame\\UI-DialogBox-Background",
    dialogBorder = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tooltipBackground = "Interface\\Tooltips\\UI-Tooltip-Background",
    tooltipBorder = "Interface\\Tooltips\\UI-Tooltip-Border",
}
W.BlizzardArt = ART

-- Left/middle/right slices of a stock 3-slice texture. Returns nil when the
-- client refuses the file so callers keep their flat drawing.
local SLICE_KEYS = { "left", "middle", "right" }
local function ThreeSlice(frame, layer, file, edge, coords)
    local parts = {}
    for index, name in ipairs(SLICE_KEYS) do
        local texture = frame:CreateTexture(nil, layer)
        parts[name] = texture
        if texture:SetTexture(file) == false then
            for _, key in ipairs(SLICE_KEYS) do if parts[key] then parts[key]:Hide() end end
            return nil
        end
        local c = coords[index]
        texture:SetTexCoord(c[1], c[2], c[3], c[4])
    end
    parts.left:SetPoint("TOPLEFT"); parts.left:SetPoint("BOTTOMLEFT"); parts.left:SetWidth(edge)
    parts.right:SetPoint("TOPRIGHT"); parts.right:SetPoint("BOTTOMRIGHT"); parts.right:SetWidth(edge)
    parts.middle:SetPoint("TOPLEFT", parts.left, "TOPRIGHT", 0, 0); parts.middle:SetPoint("BOTTOMRIGHT", parts.right, "BOTTOMLEFT", 0, 0)
    function parts:SetFile(path) for _, key in ipairs(SLICE_KEYS) do self[key]:SetTexture(path) end end
    function parts:SetAlpha(alpha) for _, key in ipairs(SLICE_KEYS) do self[key]:SetAlpha(alpha) end end
    return parts
end
local BUTTON_SLICES = { { 0, 0.09375, 0, 0.6875 }, { 0.09375, 0.53125, 0, 0.6875 }, { 0.53125, 0.625, 0, 0.6875 } }
local INPUT_SLICES = { { 0, 0.0625, 0, 0.625 }, { 0.0625, 0.9375, 0, 0.625 }, { 0.9375, 1, 0, 0.625 } }

-- Native backdrop on the frame itself, so it draws beneath the frame's own
-- children. Plain frames receive the documented BackdropTemplateMixin.
-- "dialog" is the stock dialog border; anything else is the stock tooltip
-- edge over an opaque panel fill.
function W.BlizzardBackdrop(frame, kind)
    if not frame.SetBackdrop then
        if type(Mixin) ~= "function" or type(BackdropTemplateMixin) ~= "table" then return false end
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropSizeChanged then frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged) end
    end
    local dialog = kind == "dialog"
    local ok = pcall(addon.Media.ApplyBackdrop, addon.Media, frame, {
        -- The dialog owner draws its own opaque canvas and stone (Window.lua).
        bgFile = not dialog and ART.tooltipBackground or nil,
        edgeFile = dialog and ART.dialogBorder or ART.tooltipBorder,
        tile = true, tileSize = dialog and 32 or 16, edgeSize = 1,
        insets = dialog and { left = 11, right = 12, top = 12, bottom = 11 } or { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if not ok then return false end
    if dialog then
        frame:SetBackdropColor(1, 1, 1, 1)
    else
        frame:SetBackdropColor(T.panel[1], T.panel[2], T.panel[3], T.panel[4])
        frame:SetBackdropBorderColor(T.lineStrong[1], T.lineStrong[2], T.lineStrong[3], 1)
    end
    frame.blizzardBackdrop = kind
    return true
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
    if T.blizzardArt then
        -- Window surfaces take the stock tooltip backdrop; their silver edge is
        -- then already drawn. Without a backdrop both keep the flat drawing.
        if (key == "Window" and (frame.blizzardBackdrop or W.BlizzardBackdrop(frame, "tooltip")))
            or (key == "BorderSilver" and frame.blizzardBackdrop) then
            return W.Fill(frame, T.background, layer, inset, 0)
        end
    end
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
    if key == "InputField" and T.blizzardArt then
        local art = ThreeSlice(frame, "BORDER", ART.input, 8, INPUT_SLICES)
        if art then
            -- The stock input border replaces the hairline and its focus tint;
            -- a square fill would poke out past its rounded ends.
            texture.outline:SetShown(false)
            Paint(texture, T.field, 0)
            texture.blizzardArt = art
            return texture
        end
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

-- Headings carry hierarchy through size and the theme's heading color (the
-- text color in Modern, gold in Blizzard); the accent is reserved for state.
function W.Heading(parent, text, size, x, y, width, color)
    color = InterfaceColor(color)
    if color == nil or color == T.primary or color == T.text then color = T.heading end
    local label = W.Label(parent, text, "GameFontNormalLarge", x, y, width, color)
    addon.Media:BindInterfaceFont(label, GameFontNormalLarge, size, nil, "heading")
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
-- List rows draw exactly like plain buttons in Modern; in Blizzard they are
-- stock list rows rather than push buttons.
BUTTON.row = BUTTON.button
-- Modern recipes. Every clickable edge rests at the control-edge contrast so
-- targets read as buttons before they are hovered; hover lifts the fill one
-- clear step, and a selected choice shows a full accent edge on a raised fill.
local MODERN_BUTTON = {
    button = {
        fill = "surface", line = "lineStrong", label = "text",
        hoverFill = "hover", hoverLine = "muted",
        pressedFill = "panel", selectedLine = "primary",
    },
    secondary = {
        line = "lineStrong", label = "secondary",
        hoverFill = "hover", hoverLine = "muted", hoverLabel = "text",
        pressedFill = "surface", selectedFill = "surface", selectedLine = "primary",
    },
    choice = {
        line = "lineStrong", label = "secondary",
        hoverFill = "hover", hoverLine = "muted", hoverLabel = "text",
        selectedFill = "surface", selectedLine = "primary", selectedLabel = "text",
    },
    tab = {
        label = "secondary", hoverFill = "hover", hoverLabel = "text",
        selectedFill = "surface", selectedLabel = "text", edge = true,
    },
    underline = {
        label = "secondary", hoverLabel = "text", selectedLabel = "text",
    },
}
MODERN_BUTTON.row = MODERN_BUTTON.button
-- Blizzard: styles drawn with the stock push-button art, and styles that
-- receive the stock list highlight bar. Segmented choices stay flat: a row of
-- red buttons is loud, and the pressed art alone barely shows which is chosen.
local PUSH = { button = true, primary = true, secondary = true }
local LIST = { tab = true, row = true }

local function Color(key) return key and T[key] end
-- Stock push-button label gold (NORMAL_FONT_COLOR); reads on the red art.
local BUTTON_GOLD = { 1, 0.82, 0, 1 }
local MODE_HEADING = { label = "heading", hoverLabel = "highlight" }

-- The line follows visible text, not the width of its clickable row. Native
-- string measurements are local UI data; reject restricted/invalid results.
function W.AlignTextLine(button, line)
    local width=button.label:GetStringWidth()
    if (issecretvalue and issecretvalue(width)) or type(width)~="number" or width~=width or width<0 or width==math.huge then return end
    width=math.min(width,math.max(8,button:GetWidth()-20))
    local available=button.label:GetWidth()
    if not (issecretvalue and issecretvalue(available)) and type(available)=="number" and available>0 then width=math.min(width,available) end
    line:ClearAllPoints();line:SetSize(math.max(8,width),2)
    local justify=button.label.GetJustifyH and button.label:GetJustifyH() or (button.modeLeftAligned and "LEFT" or "CENTER")
    if justify=="LEFT" then line:SetPoint("TOPLEFT",button.label,"BOTTOMLEFT",0,-2)
    elseif justify=="RIGHT" then line:SetPoint("TOPRIGHT",button.label,"BOTTOMRIGHT",0,-2)
    else line:SetPoint("TOP",button.label,"BOTTOM",0,-2) end
end

function W.Button(parent, text, width, height, style)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 120, height or 30)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    style = style or "button"
    button.skinStyle = style
    if style == "toggle" or style == "checkbox" then return W.Switch(button, text, height, style) end
    -- Resolved per button: the theme is applied after this file loads.
    local recipe = (T.id == "mode" and style == "categoryHeading" and MODE_HEADING)
        or (not T.blizzardArt and MODERN_BUTTON[style]) or BUTTON[style] or BUTTON.button
    button.fill = W.Fill(button, T.surface, "BACKGROUND")
    if T.id=="mode" then
        button.modeBorderAsset="ModeControlBorder"
        button.fill.modeAsset="ModeControlSurface";Paint(button.fill,T.surface)
    end
    button.outline = W.Outline(button, T.line, "BORDER")
    -- Kept for consumers that tint the selected state directly.
    button.activeGlow = W.Fill(button, T.primary, "ARTWORK", 0, 0.08)
    button.activeGlow:Hide()
    if recipe.edge or T.id == "mode" then
        -- Selected navigation rows carry an accent bar on the leading edge
        -- (3px in Modern, where it is the main "you are here" marker).
        button.selectionEdge = W.Fill(button, T.primary, "OVERLAY")
        button.selectionEdge:ClearAllPoints()
        button.selectionEdge:SetPoint("TOPLEFT"); button.selectionEdge:SetPoint("BOTTOMLEFT")
        button.selectionEdge:SetWidth(T.blizzardArt and 2 or 3)
        button.selectionEdge:Hide()
        if T.id == "mode" then
            button.selectionEdge.modeAsset="ModeSelection"
            -- Export already contains cyan; white tint keeps its exact hue.
            Paint(button.selectionEdge,{1,1,1,1})
            button.selectionEdge:SetTexCoord(0,1,0,1)
        end
    end
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    addon.Media:BindInterfaceFont(button.label, GameFontHighlight)
    W.CrispText(button.label)
    if T.blizzardArt and PUSH[style] then
        button.blizzardArt = ThreeSlice(button, "BACKGROUND", ART.buttonUp, 12, BUTTON_SLICES)
        if button.blizzardArt then
            local glow = button:CreateTexture(nil, "HIGHLIGHT")
            glow:SetAllPoints()
            glow:SetTexture(ART.buttonHighlight)
            glow:SetTexCoord(0, 0.625, 0, 0.6875)
            glow:SetBlendMode("ADD")
            button.blizzardButtonHighlight = glow
        end
    elseif T.blizzardArt and LIST[style] then
        local glow = button:CreateTexture(nil, "ARTWORK")
        glow:SetAllPoints()
        glow:Hide()
        if glow:SetTexture(ART.rowHighlight) ~= false then
            glow:SetBlendMode("ADD")
            -- Warm the stock bar so it reads as gold rather than a white flare.
            glow:SetVertexColor(1, 0.82, 0.45)
            button.blizzardHighlight = glow
        end
    end
    -- Stock push button: gold label, white on hover or while held selected.
    local function RefreshPush(self, available, hovered, pressed, selected)
        local down = pressed or selected
        self.blizzardArt:SetFile((not available and ART.buttonDisabled) or (down and ART.buttonDown) or ART.buttonUp)
        Paint(self.fill, T.background, 0)
        self.outline:SetShown(false)
        self.activeGlow:Hide()
        local color = self.labelColor or ((hovered or selected) and T.highlight or BUTTON_GOLD)
        if not available then color = T.unavailable end
        self.label:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    function button:RefreshAppearance()
        local available = self:IsEnabled()
        local hovered = available and self.hovered
        local pressed = hovered and self.pressed
        local selected = available and self.selected == true
        if self.blizzardArt then return RefreshPush(self, available, hovered, pressed, selected) end
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
            self.outline:SetColor(lineColor, T.blizzardArt and selected and line == "primary" and 0.7 or nil)
            self.outline:SetShown(true)
        else self.outline:SetShown(false) end
        local color = self.labelColor or Color(label) or T.text
        if not available then color = T.unavailable end
        self.label:SetTextColor(color[1], color[2], color[3], color[4] or 1)
        self.activeGlow:SetShown(selected and style ~= "primary" and style ~= "underline")
        if T.id == "mode" then
            -- Hover lights text only. A separate etched line marks selection;
            -- resting fills and borders never brighten with hover/selection.
            local plain=style=="tab" or style=="underline" or style=="categoryHeading"
            Paint(self.fill, plain and T.background or T.surface, plain and 0 or 1)
            self.outline:SetShown(not plain)
            if not plain then self.outline:SetColor(T.line,0.8) end
            self.activeGlow:Hide()
            local modeColor=self.labelColor or (style=="categoryHeading" and T.heading or T.secondary)
            if not available then modeColor=T.unavailable
            elseif selected or hovered then modeColor=T.primary end
            self.label:SetTextColor(unpack(modeColor))
            self.label:SetShadowColor(T.primary[1], T.primary[2], T.primary[3], available and (selected or hovered) and 0.55 or 0)
            self.label:SetShadowOffset(0, -1)
        end
        if self.selectionEdge then
            if T.id=="mode" then W.AlignTextLine(self,self.selectionEdge) end
            self.selectionEdge:SetShown(selected)
        end
        if self.blizzardHighlight then
            -- Stock list rows: the highlight bar shows on hover and holds while selected.
            self.blizzardHighlight:SetShown(hovered or selected)
            self.blizzardHighlight:SetAlpha(selected and 0.45 or 0.25)
            self.activeGlow:Hide()
        end
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
    if T.id=="mode" then
        addon.Media:RegisterFontListener(button,function(owner) W.AlignTextLine(owner,owner.selectionEdge) end)
        button:HookScript("OnSizeChanged",function(owner) W.AlignTextLine(owner,owner.selectionEdge) end)
    end
    button:RefreshAppearance()
    return button
end

-- Square switch (toggle) and checkbox. Both are sharp-cornered to match the
-- rest of the shell; state is carried by fill, not by artwork.
-- Blizzard: toggles and checkboxes are both the stock check button.
local function BlizzardCheck(button, text)
    local box = button:CreateTexture(nil, "BACKGROUND")
    if box:SetTexture(ART.checkbox) == false then box:Hide(); return nil end
    box:SetPoint("CENTER"); box:SetSize(26, 26)
    -- Drawn by state rather than the HIGHLIGHT layer so a hovered grid cell
    -- lights its box too.
    local glow = button:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("CENTER"); glow:SetSize(26, 26)
    glow:SetTexture(ART.checkboxHighlight); glow:SetBlendMode("ADD"); glow:Hide()
    local mark = button:CreateTexture(nil, "ARTWORK")
    mark:SetPoint("CENTER"); mark:SetSize(26, 26)
    mark:SetTexture(ART.check)
    button.fill, button.knob = box, mark
    -- Inert stand-ins so shared consumers can still address these regions.
    button.switchOutline = W.Outline(button, T.background, "BORDER", 0, 0)
    button.switchOutline:SetShown(false)
    button.activeGlow = W.Fill(button, T.primary, "ARTWORK", 0, 0)
    button.activeGlow:Hide()
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    addon.Media:BindInterfaceFont(button.label, GameFontHighlight)
    W.CrispText(button.label)
    function button:RefreshAppearance()
        local available = self:IsEnabled()
        mark:SetTexture(available and ART.check or ART.checkDisabled)
        mark:SetShown(self.selected == true)
        box:SetAlpha(available and 1 or 0.5)
        glow:SetShown(available and self.hovered == true)
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

function W.Switch(button, text, height, style)
    if T.blizzardArt then
        local check = BlizzardCheck(button, text)
        if check then return check end
    end
    local toggle = style == "toggle"
    local h = 18
    local w = toggle and 34 or 18
    local track = button:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("CENTER"); track:SetSize(w, h)
    local frame = CreateFrame("Frame", nil, button)
    frame:SetPoint("CENTER"); frame:SetSize(w, h)
    frame.ptgSquareOutline=T.id~="mode"
    if T.id=="mode" then
        track.modeAsset=toggle and "ModeToggleSurface" or "ModeCheckSurface"
        frame.modeBorderAsset=toggle and "ModeToggleBorder" or "ModeCheckBorder"
    end
    local outline = W.Outline(frame, T.lineStrong, "BORDER")
    local mark = button:CreateTexture(nil, "ARTWORK")
    if T.id=="mode" then mark.modeAsset=toggle and "ModeThumb" or "ModeCheckMark" end
    mark:SetSize(toggle and 12 or 10, toggle and 12 or 10)
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
        if toggle then Paint(track, on and T.primary or T.surface)
        -- A ticked box carries a faint accent wash behind its mark, so checked
        -- and unchecked differ in area as well as in the small mark.
        elseif on then Paint(track, T.primary, 0.16) else Paint(track, T.field) end
        outline:SetColor(on and T.primary or (hovered and T.secondary or T.lineStrong))
        if T.id == "mode" then
            self.activeGlow:Hide()
            outline:SetColor(on and T.primary or T.lineStrong)
        end
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
        if T.id == "mode" then
            self.label:SetShadowColor(T.primary[1],T.primary[2],T.primary[3],hovered and 0.55 or 0)
            self.label:SetShadowOffset(0,-1)
        end
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
        local icon=module and module.classIcon
        -- Class identity already appears in the sidebar and category tab.
        title:SetShown(icon==nil)
        description:ClearAllPoints();description:SetPoint("TOPLEFT",0,icon and -2 or -30)
        description:SetPoint("TOPRIGHT",-140,icon and -2 or -30)
        description:SetWordWrap(icon~=nil)
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
    if T.id=="mode" then thumb.modeAsset="ModeScrollThumb";Paint(thumb,T.lineStrong) end
    thumb:SetSize(T.id=="mode" and 2 or 4, height)
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
    -- Modern draws a thicker track at control-edge contrast and a larger thumb
    -- so the slider reads as draggable; Blizzard keeps its hairline.
    local modern = not T.blizzardArt
    local trackHeight = modern and 4 or 2
    local track = W.Texture(slider, "SliderTrack")
    track:ClearAllPoints()
    track:SetPoint("LEFT", 0, 0); track:SetPoint("RIGHT", 0, 0); track:SetHeight(trackHeight)
    if modern then Paint(track, T.lineStrong) end
    local progress = W.Fill(slider, T.primary, "BORDER")
    progress:ClearAllPoints()
    progress:SetPoint("LEFT", 0, 0); progress:SetHeight(trackHeight); progress:SetWidth(1)
    local thumb = W.Texture(slider, "SliderThumb", "OVERLAY")
    thumb:ClearAllPoints()
    thumb:SetSize(modern and 10 or 8, modern and 20 or 16)
    thumb:SetVertexColor(unpack(T.text))
    -- Blizzard: the stock slider knob, untinted.
    local stockThumb = T.blizzardArt and thumb:SetTexture(ART.sliderThumb) ~= false
    if stockThumb then thumb:SetSize(32, 32); thumb:SetVertexColor(1, 1, 1, 1) end
    slider:SetThumbTexture(thumb)
    local hovered
    local function Tint(color) if not stockThumb then thumb:SetVertexColor(unpack(color)) end end
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
