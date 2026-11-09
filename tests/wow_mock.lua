-- Strict local test doubles: these do not simulate Blizzard rendering/security.
frames = {}
textures = {}
SlashCmdList = {}
testClock = 100
testCombat = false
testLockdown = false
clockReads = 0
function GetLocale() return "enUS" end
strmatch=string.match
bit={band=function(a,b)
    local value,place=0,1
    while a>0 and b>0 do
        if a%2==1 and b%2==1 then value=value+place end
        a,b,place=math.floor(a/2),math.floor(b/2),place*2
    end
    return value
end}
C_UIFileAsset={IsKnownFile=function(path)
    if type(path)~="string" then return false end
    if path:find("AddOns\\EllesmereUI\\",1,true) or path:find("AddOns\\AyijeUI\\",1,true) then
        return testProviderFonts and testProviderFonts[path]==true or false
    end
    return not (testMissingTextures and testMissingTextures[path])
end}
function securecallfunction(fn,...) return fn(...) end
function geterrorhandler() return function(message) error(message) end end
function GetTime() clockReads = clockReads + 1; return testClock end
function UnitAffectingCombat(unit) assert(unit == "player"); return testCombat end
function InCombatLockdown() return testLockdown end

local methods = {}
function issecretvalue(value) return type(value) == "table" and rawget(value, "secret") == true end
function methods:IsForbidden() return self.forbidden == true end
function methods:IsProtected() return self.protected == true end
function methods:IsAnchoringRestricted() return self.restricted == true end
function methods:IsAnchoringSecret() return self.secretAnchor == true end
function methods:CanBeAccessedInContext() return self.accessible ~= false end
local function RefreshScript(self,name)
    local primary=self.scriptHandlers and self.scriptHandlers[name]
    local hooks=self.scriptHooks and self.scriptHooks[name]
    if not hooks then self.scripts[name]=primary;return end
    self.scripts[name]=function(...)
        if primary then primary(...) end
        for _,hook in ipairs(hooks) do hook(...) end
    end
end
function methods:SetScript(name, handler)
    self.scriptHandlers=self.scriptHandlers or {};self.scriptHandlers[name]=handler
    RefreshScript(self,name)
end
function methods:GetScript(name) return self.scriptHandlers and self.scriptHandlers[name] end
function methods:HookScript(name, handler)
    self.scriptHooks=self.scriptHooks or {};self.scriptHooks[name]=self.scriptHooks[name] or {}
    table.insert(self.scriptHooks[name],handler);RefreshScript(self,name)
end
function methods:RegisterEvent(event)
    assert(not self.events[event], "duplicate registration: " .. event)
    self.events[event] = true
end
function methods:RegisterUnitEvent(event, ...)
    -- Record native filter intent. FireEvent deliberately injects arbitrary
    -- payloads so existing restricted/unassigned-unit guard fixtures still run.
    self:RegisterEvent(event)
    self.unitEvents = self.unitEvents or {}
    self.unitEvents[event] = {...}
end
function methods:UnregisterEvent(event)
    self.events[event] = nil
    if self.unitEvents then self.unitEvents[event] = nil end
end
function methods:UnregisterAllEvents() self.events = {}; self.unitEvents = nil end
function methods:IsEventRegistered(event) return self.events[event]==true end
function methods:Show()
    if self.shown then return end
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    if not self.shown then return end
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function methods:SetSize(w, h)
    if self.resizeBounds then
        w = math.max(self.resizeBounds[1], math.min(self.resizeBounds[3], w))
        h = math.max(self.resizeBounds[2], math.min(self.resizeBounds[4], h))
    end
    self.width = w; self.height = h; self.layoutWrites = (self.layoutWrites or 0) + 1
end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width or 1024 end
function methods:GetLeft() local x = self:GetCenter(); return x - self:GetWidth() / 2 end
function methods:GetBottom() local _, y = self:GetCenter(); return y - self:GetHeight() / 2 end
function methods:SetResizable(value) self.resizable = value end
function methods:SetResizeBounds(...) self.resizeBounds = {...} end
function methods:StartSizing(point) self.sizingPoint = point; self.sizing = true end
function methods:SetParent(parent) self.parent=parent end
function methods:SetPoint(point, relative, relativePoint, x, y)
    self.anchor = {point, relative, relativePoint, x, y}
    self.points = self.points or {}
    local target, targetPoint, ox, oy = relative, relativePoint, x, y
    if type(relative) ~= "table" then
        target, targetPoint = self.parent, point
        ox, oy = relative or 0, relativePoint or 0
    end
    self.points[#self.points + 1] = {point, target, targetPoint or point, ox or 0, oy or 0}
    self.layoutWrites = (self.layoutWrites or 0) + 1
    if type(relative) == "table" then
        local px, py = relative:GetCenter()
        local ratio = relative:GetEffectiveScale() / self:GetEffectiveScale()
        local v = { CENTER={0,0}, TOP={0,0.5}, BOTTOM={0,-0.5}, LEFT={-0.5,0}, RIGHT={0.5,0} }
        v.TOPLEFT,v.TOPRIGHT,v.BOTTOMLEFT,v.BOTTOMRIGHT={-0.5,0.5},{0.5,0.5},{-0.5,-0.5},{0.5,-0.5}
        local a, b = v[point], v[relativePoint]
        if a and b then
            self.centerX = (px + b[1] * relative:GetWidth()) * ratio + x - a[1] * self:GetWidth()
            self.centerY = (py + b[2] * relative:GetHeight()) * ratio + y - a[2] * self:GetHeight()
        end
    end
end
function methods:ClearAllPoints() self.points = {} end
function methods:SetAllPoints() end
function methods:GetHeight() return self.height or 240 end
function methods:SetScale(scale) self.scale = scale; self.layoutWrites = (self.layoutWrites or 0) + 1 end
function methods:GetEffectiveScale() return (self.scale or 1) * (self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetCenter()
    -- Opt-in strict rectangle for registration regressions. Historical fixtures
    -- supply synthetic positions; a newly created native frame need not have one.
    if self.requireAnchorForGeometry and (not self.points or #self.points==0) then return nil,nil end
    return self.centerX or 500, self.centerY or 400
end
function methods:EnableMouse(enabled) self.mouse = enabled end
function methods:EnableKeyboard(enabled) self.keyboard = enabled end
function methods:SetPropagateKeyboardInput(value) self.propagate = value end
function methods:SetEnabled(value) self.enabled = value end
function methods:IsEnabled() return self.enabled ~= false end
function methods:RegisterForDrag(button) assert(button == "LeftButton") end
function methods:RegisterForClicks(button) self.clickRegistration = button end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false; self.sizing = false end
function methods:SetText(text)
    local changed = self.text ~= text
    self.text = text; self.textWrites = (self.textWrites or 0) + 1
    if changed and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetTextColor(...) self.color = {...} end
function CreateColor(r,g,b,a) return {r=r,g=g,b=b,a=a} end
function methods:SetGradient(orientation,minimum,maximum)
    assert(orientation=="HORIZONTAL" or orientation=="VERTICAL")
    self.gradient={orientation=orientation,minimum=minimum,maximum=maximum}
end
function methods:SetSpacing(value) self.spacing=value end
function methods:SetVertexColor(...) self.vertexColor = {...} end
function methods:SetStatusBarTexture(path) self.statusBarTexture=path;return true end
function methods:SetStatusBarColor(...) self.statusBarColor={...} end
function methods:SetFormattedText(pattern,...) self:SetText(string.format(pattern,...)) end
function methods:SetShadowColor(...) self.shadowColor = {...} end
function methods:SetShadowOffset(...) self.shadowOffset = {...} end
function methods:SetFont(path, size, flags)
    if testMissingFonts and testMissingFonts[path] then return false end
    self.font = {path, size, flags}; self.layoutWrites = (self.layoutWrites or 0) + 1; return true
end
function methods:GetFont() return unpack(self.font or {"Fonts/FRIZQT__.TTF", 12, ""}) end
function methods:GetStringWidth()
    local _, size = self:GetFont()
    return #(self.text or ""):gsub("[\128-\191]", "") * size * 0.6
end
function methods:GetStringHeight() local _, size = self:GetFont(); return size end
function methods:SetWordWrap(value) self.wordWrap = value end
function methods:SetDesaturated(value) assert(type(value) == "boolean"); self.desaturated = value end
function methods:SetBackdrop(info)
    if testBadBackdrop then error("unsupported border") end
    self.backdrop = info; self.backdropWrites = (self.backdropWrites or 0) + 1
end
function methods:SetBackdropBorderColor(...) self.borderColor = {...} end
function methods:SetBackdropColor(...) self.backdropColor = {...} end
function methods:GetAlpha() return self.alpha or 1 end
function methods:GetScale() return self.scale or 1 end
function methods:GetText() return self.text end
function methods:SetAutoFocus() end
function methods:SetMaxLetters() end
function methods:SetMultiLine(value) self.multiLine = value end
function methods:GetNumLines() local _, count=(self.text or ""):gsub("\n", ""); return count+1 end
function methods:SetFontObject() end
function methods:SetTextInsets() end
function methods:HasFocus() return self.focused == true end
function methods:SetFocus() self.focused = true end
function methods:HighlightText(start, stop) self.highlighted = { start or 0, stop or -1 } end
function methods:ClearFocus()
    if not self.focused then return end
    self.focused = false
    if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function methods:SetOrientation(value) self.orientation = value end
function methods:SetValueStep(step) self.step = step end
function methods:SetObeyStepOnDrag(value) self.obeyStep = value end
function methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
function methods:GetMinMaxValues() return self.low or 0, self.high or 0 end
function methods:GetValue() return self.value or 0 end
function methods:SetValue(value, userInput)
    -- Modeled mouse drag snapping; native rounding still requires client testing.
    if userInput and self.obeyStep and self.step then
        value = (self.low or 0) + math.floor((value - (self.low or 0)) / self.step + 0.5) * self.step
    end
    value = math.max(self.low or value, math.min(self.high or value, value))
    if self.value == value then return end
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value, userInput == true) end
end
function methods:SetThumbTexture(texture) self.thumbTexture = texture end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:SetVerticalScroll(value) self.verticalScroll = value end
function methods:GetVerticalScroll() return self.verticalScroll or 0 end
function methods:EnableMouseWheel() end
function methods:SetJustifyH(value) self.justifyH = value end
function methods:SetJustifyV(value) self.justifyV = value end
function methods:SetFrameStrata(value) self.strata = value end
function methods:SetFrameLevel(value) self.frameLevel = value end
function methods:GetFrameLevel() return self.frameLevel or (self.parent and self.parent:GetFrameLevel() + 1 or 0) end
function methods:SetMovable() end
function methods:SetClampedToScreen(value) self.clamped=value end
function methods:SetClampRectInsets(...) self.clampInsets={...} end
function methods:SetHighlightTexture(texture, blendMode)
    self.highlightTexture = texture
    if blendMode then texture:SetBlendMode(blendMode) end
end
function methods:SetNormalTexture(texture) self.normalTexture = texture end
function methods:SetPushedTexture(texture) self.pushedTexture = texture end
function methods:SetDisabledTexture(texture) self.disabledTexture = texture end
function methods:SetTexture(path)
    self.texture = path
    self.textureWrites = (self.textureWrites or 0) + 1
    return not (testMissingTextures and testMissingTextures[path])
end
function methods:SetTextureSliceMargins(...) self.slice = {...} end
function methods:ClearTextureSlice() self.slice = nil end
function methods:SetTexCoord(...) self.texCoord = {...} end
function methods:SetBlendMode(value) self.blendMode = value end
function methods:SetAlpha(value) self.alpha = value end

local function Object(parent)
    return setmetatable({ parent = parent, shown = true, scripts = {}, events = {} }, { __index = methods })
end
function methods:CreateTexture(_, layer)
    local texture = Object(self)
    texture.kind, texture.layer = "Texture", layer
    textures[#textures + 1] = texture
    return texture
end
function methods:CreateFontString() local text = Object(self); text.kind = "FontString"; return text end
function methods:GetObjectType() return self.kind end
UIParent = Object()
UIParent.width, UIParent.height = 1280, 800
GameFontHighlight = Object()
GameFontNormalLarge = Object()
GameFontNormalLarge.font = {"Fonts/FRIZQT__.TTF", 16, ""}
GameFontDisableSmall = Object()
GameFontDisableSmall.font = {"Fonts/FRIZQT__.TTF", 10, ""}
ChatFontNormal = Object()
ChatFontNormal.font = {"Fonts/ARIALN.TTF", 12, ""}
for _,font in ipairs({GameFontHighlight,GameFontNormalLarge,GameFontDisableSmall,ChatFontNormal}) do font.kind="Font" end
ColorPickerFrame = Object(UIParent)
ColorPickerFrame:Hide()
function ColorPickerFrame:SetupColorPickerAndShow(info)
    self.info = info
    self.swatchFunc = info.swatchFunc
    self.r, self.g, self.b = info.r, info.g, info.b
    self:Show()
end
function ColorPickerFrame:GetColorRGB() return self.r, self.g, self.b end
C_AddOns = {LoadAddOn = function() return true end}
C_Timer = {After = function(_, callback) callback() end} -- immediate modeled expiry; not real timing
testTickers = {}
function C_Timer.NewTicker(period, callback)
    local ticker = { period = period, callback = callback, elapsed = 0 }
    function ticker:Cancel() self.cancelled = true end
    testTickers[#testTickers + 1] = ticker
    return ticker
end
function methods:SetCooldown(start,duration) self.cooldownStart=start;self.cooldownDuration=duration end
function methods:SetDrawSwipe(value) self.drawSwipe=value end
function methods:SetDrawEdge(value) self.drawEdge=value end
function methods:Clear() self.cooldownStart=nil;self.cooldownDuration=nil end
function CreateFrame(kind, name, parent)
    assert(kind == "Frame" or kind == "Button" or kind == "Slider" or kind == "EditBox" or kind == "ScrollFrame" or kind == "Cooldown" or kind == "StatusBar")
    local frame = Object(parent)
    frame.name=name
    frame.kind = kind
    if kind=="EditBox" then
        -- Native EditBox is not a FontString. Keep this method genuinely absent
        -- so a FontString-only measurement call fails in behavioral tests.
        setmetatable(frame,{__index=function(_,key)
            if key=="GetStringHeight" then return nil end
            return methods[key]
        end})
        function frame:GetSpacing() return self.spacing or 0 end
    end
    frame.mouse = kind == "Button" or kind == "Slider" or kind == "EditBox"
    if name then
        assert(not _G[name], "duplicate named frame: " .. name)
        _G[name] = frame
    end
    frames[#frames + 1] = frame
    return frame
end
function FireEvent(event, ...)
    for _, frame in ipairs(frames) do
        if frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, event, ...)
        end
    end
end
function Advance(seconds)
    testClock = testClock + seconds
    for _, frame in ipairs(frames) do
        if frame.shown and frame.scripts.OnUpdate then
            frame.scripts.OnUpdate(frame, seconds)
        end
    end
    -- Model one due tick per Advance, without replaying a backlog at the same timestamp.
    for _, ticker in ipairs(testTickers) do
        if not ticker.cancelled then
            ticker.elapsed = ticker.elapsed + seconds
            if ticker.elapsed >= ticker.period then ticker.elapsed = ticker.elapsed % ticker.period; ticker.callback() end
        end
    end
end

function methods:SetHorizontalScroll(value) self.horizontalScroll=value end
function methods:GetHorizontalScroll() return self.horizontalScroll or 0 end

function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:GetNumPoints() return #(self.points or {}) end
function methods:GetPoint(i) return unpack((self.points or {})[i] or {}) end
