local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
local WINDOW_WIDTH, WINDOW_HEIGHT = 960, 640
local SIDEBAR_WIDTH, HEADER_HEIGHT = 212, 48
-- Reserve the header controls (Layout/Close) for safe dragging.
local HEADER_RESERVED = 160
local BANNER_HEIGHT, BANNER_GAP = 44, 12
local NAV_ROW_HEIGHT, NAV_ROW_STEP = 30, 32

-- The Settings page is not a module; search and the page header name it here.
addon.SETTINGS_PAGE = {
    id = "globalSettings",
    title = "Settings",
    description = "Look, game options and profiles for the whole addon.",
}

local function InCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end
function addon:RecoverWindowPosition()
    local window=self.configWindow
    if not window or InCombat() then return false end
    local ratio=window:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    local w,h=window:GetWidth()*ratio,window:GetHeight()*ratio
    local keep=math.min(40,width/4,height/4)
    -- Retain a draggable header fragment, not the full window rectangle.
    local minX=-width/2-w/2+(window.headerReserved or HEADER_RESERVED)*ratio+keep
    local maxX=width/2+w/2-keep
    local minY=-height/2-h/2+keep
    local maxY=height/2-h/2+HEADER_HEIGHT*ratio-keep
    self.db.window.x=math.max(minX,math.min(maxX,self.db.window.x))
    self.db.window.y=math.max(minY,math.min(maxY,self.db.window.y))
    return true
end
function addon:ResetConfigWindowPosition()
    if InCombat() then print("Play The Game Tools: reset the configuration window outside combat.");return false end
    self:FinishWindowInteraction()
    self.db.window.x,self.db.window.y=0,0
    if not self.configWindow then self:CreateConfig() end
    self:UpdateWindowBounds();self.configWindow:Show();return true
end

function addon:FinishWindowInteraction()
    local window = self.configWindow
    if not window or not window.moving then return end
    window:StopMovingOrSizing()
    window.moving = false
    local ratio = window:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x, y = window:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if x and y and parentX and parentY then
        self.db.window.x, self.db.window.y = x * ratio - parentX, y * ratio - parentY
    end
    if InCombat() then
        window.boundsPending = true
    else
        self:RecoverWindowPosition()
        window:ClearAllPoints()
        window:SetPoint("CENTER", UIParent, "CENTER", self.db.window.x / ratio, self.db.window.y / ratio)
    end
end

function addon:UpdateWindowBounds(initial)
    local window = self.configWindow
    if not window then return end
    if InCombat() and not initial then window.boundsPending = true; return end
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    -- Legacy saved dimensions are intentionally ignored and left untouched.
    local scale = math.min(1, math.max(1, width - 32) / WINDOW_WIDTH, math.max(1, height - 32) / WINDOW_HEIGHT)
    window:SetScale(scale)
    window:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    if not InCombat() then self:RecoverWindowPosition() end
    window:ClearAllPoints()
    window:SetPoint("CENTER", UIParent, "CENTER", self.db.window.x / scale, self.db.window.y / scale)
    window.boundsPending = false
end

-- A class tool, marked by its stock class icon, is listed only for that class.
-- An unreadable class keeps the page listed; the page itself explains it.
local function RequiredClass(module)
    local name = type(module.classIcon) == "string" and module.classIcon:match("ClassIcon_(%a+)$")
    return name and name:upper() or nil
end
function addon:IsConfigPageListed(id)
    local module = self.modules[id]
    if not module or module.developer then return false end
    local required = RequiredClass(module)
    if not required or type(UnitClass) ~= "function" then return true end
    local ok, _, class = pcall(UnitClass, "player")
    if not ok or (issecretvalue and issecretvalue(class)) or type(class) ~= "string" then return true end
    return class == required
end

-- Sidebar order: module pages by title, A to Z.
function addon:ListedConfigPages()
    local listed = {}
    for _, id in ipairs(self.moduleOrder) do
        if self:IsConfigPageListed(id) then listed[#listed + 1] = id end
    end
    table.sort(listed, function(a, b)
        local x, y = self.modules[a].title:lower(), self.modules[b].title:lower()
        if x ~= y then return x < y end
        return a < b
    end)
    return listed
end

local function GenericPage(parent, module)
    local page = W.Page(parent)
    page:Finish()
    return page
end

-- Page header: title and a description of up to two lines on the left, the
-- module's one on/off switch on the right, closed by a hairline. The switch
-- is the state; no Enabled/Disabled text repeats it.
local function PageHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(W.PAGE_HEADER_HEIGHT)
    header:EnableMouse(false)
    local title = W.Heading(header, "", T.fontSize.page, 0, -2, 520, T.text)
    title:SetPoint("TOPRIGHT", -64, -2)
    title:SetWordWrap(false)
    local description = W.Label(header, "", nil, 0, -30, 520, T.muted)
    description:SetPoint("TOPRIGHT", -64, -30)
    -- Long descriptions (Rogue Tools) wrap; the fixed height holds two lines.
    description:SetHeight(W.PAGE_DESCRIPTION_HEIGHT)
    description:SetJustifyV("TOP")
    description:SetWordWrap(true)
    local toggle = W.Button(header, "", 44, 24, "toggle")
    toggle:SetPoint("TOPRIGHT", 0, -2)
    local divider = W.Fill(header, T.line, "BORDER")
    divider:ClearAllPoints(); divider:SetPoint("BOTTOMLEFT", 0, 12); divider:SetPoint("BOTTOMRIGHT", 0, 12)
    divider:SetHeight(1)
    toggle:SetScript("OnClick", function()
        if header.module then addon:SetModuleEnabled(header.module.id, not header.module.enabled) end
    end)
    function header:Refresh()
        local gameplay = self.module ~= nil and not self.module.developer
        toggle:SetShown(gameplay)
        if gameplay then toggle:SetSelected(self.module.enabled) end
    end
    -- module is nil for the Settings page, which has no switch.
    function header:SetModule(module, info)
        self.module = module
        info = info or module
        title:SetText(info.title)
        description:SetText(info.configDescription or info.description or "")
        self:Refresh()
    end
    header.title, header.description, header.toggle, header.divider = title, description, toggle, divider
    return header
end

-- Pending reload requests show at the top of the page area until applied.
local function ReloadBanner(parent)
    local banner = CreateFrame("Frame", nil, parent)
    banner:Hide()
    banner:SetHeight(BANNER_HEIGHT)
    banner.fill = W.Fill(banner, T.surface, "BACKGROUND")
    banner.outline = W.Outline(banner, T.primary, "BORDER", 0, 0.6)
    banner.accent = W.Fill(banner, T.primary, "ARTWORK")
    banner.accent:ClearAllPoints(); banner.accent:SetPoint("TOPLEFT"); banner.accent:SetPoint("BOTTOMLEFT")
    banner.accent:SetWidth(2)
    local reload = W.Button(banner, "Reload now", 104, 28, "primary")
    reload:SetPoint("RIGHT", -8, 0)
    banner.message = W.Label(banner, "Applies after a reload", nil, 14, -6, 400, T.text)
    banner.message:SetPoint("TOPRIGHT", -124, -6)
    banner.message:SetWordWrap(false)
    banner.reason = W.Label(banner, "", nil, 14, -23, 400, T.muted)
    banner.reason:SetPoint("TOPRIGHT", -124, -23)
    banner.reason:SetWordWrap(false)
    banner.reloadButton = reload
    return banner
end

function addon:CreateConfig()
    -- Every theme shares this layout and behavior; a theme only changes the
    -- palette, borders and textures ("art") drawn on it.
    local art = T.id == "mode"
    local sidebarWidth=SIDEBAR_WIDTH
    local window = CreateFrame("Frame", "PlayTheGameToolsConfigWindow", UIParent)
    window:Hide()
    self.configWindow = window
    window.sidebarWidth=sidebarWidth
    window:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(false)
    window:EnableMouse(true)
    -- Flat app shell: a canvas, a full-height sidebar column and one hairline frame.
    window.canvas = W.Fill(window, T.background, "BACKGROUND")
    if art then window.canvasSheen=W.ModeSheen(window) end
    window.border = W.Outline(window, T.lineStrong, "OVERLAY")
    if art then window.border:SetShown(false) end
    -- Sublevel 1 keeps the column above the canvas within the same draw layer.
    local column = window:CreateTexture(nil, "BACKGROUND", nil, 1)
    W.Paint(column, T.sidebar)
    column:SetPoint("TOPLEFT", 1, -1); column:SetPoint("BOTTOMLEFT", 1, 1)
    column:SetWidth(sidebarWidth)
    if art then
        column.modeAsset="ModeSurface";W.Paint(column,T.sidebar)
        column:ClearAllPoints();column:SetPoint("TOPLEFT",8,-8);column:SetPoint("BOTTOMLEFT",8,8)
        column:SetWidth(sidebarWidth-8)
    end
    local columnEdge = W.Fill(window, T.line, "BORDER")
    columnEdge:ClearAllPoints(); columnEdge:SetPoint("TOPLEFT", sidebarWidth + 1, -1)
    columnEdge:SetPoint("BOTTOMLEFT", sidebarWidth + 1, 1); columnEdge:SetWidth(1)
    if art then columnEdge:Hide() end
    window.columnEdge=columnEdge
    window.sidebarColumn = column
    -- Blizzard theme: the stock dialog box replaces the canvas and hairline
    -- frame; the sidebar column and its edge sit inside the dialog border.
    if T.blizzardArt and W.BlizzardBackdrop(window, "dialog") then
        -- The stock dialog stone is partly transparent, so it sits on an
        -- opaque canvas held inside the border.
        window.border:SetShown(false)
        local canvas = window.canvas
        canvas:ClearAllPoints()
        canvas:SetPoint("TOPLEFT", 11, -12); canvas:SetPoint("BOTTOMRIGHT", -12, 11)
        W.Paint(canvas, T.background, 1)
        if canvas.SetDrawLayer then canvas:SetDrawLayer("BACKGROUND", -2) end
        local stone = window:CreateTexture(nil, "BACKGROUND", nil, -1)
        stone:SetAllPoints(canvas)
        if stone.SetHorizTile and stone:SetTexture(W.BlizzardArt.dialogBackground, "REPEAT", "REPEAT") ~= false then
            stone:SetHorizTile(true); stone:SetVertTile(true)
        else stone:Hide() end
        window.blizzardStone = stone
        column:ClearAllPoints()
        column:SetPoint("TOPLEFT", 11, -12); column:SetPoint("BOTTOMLEFT", 11, 11)
        column:SetWidth(SIDEBAR_WIDTH - 10)
        columnEdge:ClearAllPoints(); columnEdge:SetPoint("TOPLEFT", SIDEBAR_WIDTH + 1, -12)
        columnEdge:SetPoint("BOTTOMLEFT", SIDEBAR_WIDTH + 1, 11); columnEdge:SetWidth(1)
    end

    -- The stock dialog border is about 12px deep; Blizzard content keeps a
    -- clear margin inside it instead of sitting on its inner edge.
    local edge = window.blizzardBackdrop and 8 or 0

    -- A non-interactive header owns disjoint drag and button regions:
    -- the brand on the left, Layout and Close on the right.
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER_HEIGHT)
    header:SetFrameLevel(window:GetFrameLevel() + 10)
    header:EnableMouse(false)
    window.headerArt = W.Fill(header, T.line, "BORDER")
    window.headerArt:ClearAllPoints()
    window.headerArt:SetPoint("BOTTOMLEFT", sidebarWidth + 2, 0); window.headerArt:SetPoint("BOTTOMRIGHT", -1, 0)
    window.headerArt:SetHeight(1)
    if art then window.headerArt:Hide() end
    local logo=header:CreateTexture(nil,"ARTWORK")
    logo:SetPoint("LEFT",14+edge,-edge/2);logo:SetSize(30,30)
    addon.Media:ApplyTexture(logo,"ModeLogo")
    window.brandLogo=logo
    window.title = W.Heading(header, "Play The Game Tools", T.fontSize.section, 0, 0, sidebarWidth, T.heading)
    window.title:SetTextColor(unpack(T.primary))
    window.title:ClearAllPoints();window.title:SetPoint("LEFT",logo,"RIGHT",8,0)
    window.title:SetWidth(sidebarWidth+120)
    window.title:SetWordWrap(false)
    local controls = CreateFrame("Frame", nil, header)
    controls:SetPoint("TOPRIGHT", -14 - edge, -10 - edge / 2)
    controls:SetSize(124, 28)
    controls:SetFrameLevel(header:GetFrameLevel() + 1)
    controls:EnableMouse(false)
    window.headerReserved=controls:GetWidth()+30+edge
    local drag = CreateFrame("Frame", nil, header)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("BOTTOMRIGHT", controls, "BOTTOMLEFT", -16, -10)
    drag:SetFrameLevel(header:GetFrameLevel() + 1)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
        if InCombat() then return end
        window.moving = true
        window:StartMoving()
    end)
    drag:SetScript("OnDragStop", function() self:FinishWindowInteraction() end)
    window.header, window.headerBar, window.headerControls = drag, header, controls
    local function HeaderButton(label, width)
        local button = W.Button(controls, label, width, 28, "secondary")
        button:SetFrameLevel(controls:GetFrameLevel() + 1)
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonUp")
        return button
    end
    local close = HeaderButton("X", 28)
    close:SetPoint("RIGHT")
    close:SetScript("OnClick", function() window:Hide() end)
    local layout = HeaderButton("Layout", 88)
    layout:SetPoint("RIGHT", close, "LEFT", -8, 0)
    layout:SetScript("OnClick", function()
        if self.editMode then self:SetEditMode(false); return end
        local page = window.selectedPage
        if not self:SetEditMode(true) then return end
        -- Opened from a module page: start on that module's first display.
        local PM = self.PositionManager
        for _, id in ipairs(PM.order) do
            local element = PM.elements[id]
            if element.module.id == page and element.editMode and element.module.enabled then PM:SelectElement(id); break end
        end
    end)
    -- editButton names the same control for older consumers.
    window.layoutButton, window.editButton, window.closeButton = layout, layout, close

    local sidebar = CreateFrame("Frame", nil, window)
    sidebar:SetPoint("TOPLEFT", 12 + edge, -HEADER_HEIGHT - 4)
    sidebar:SetPoint("BOTTOMLEFT", 12 + edge, 12 + edge)
    sidebar:SetWidth(sidebarWidth - 22 - edge)
    window.sidebar = sidebar
    -- Settings is pinned below the module list, under a hairline.
    local settingsButton = W.Button(sidebar, "Settings", sidebarWidth - 22 - edge, NAV_ROW_HEIGHT, "tab")
    settingsButton:SetPoint("BOTTOMLEFT"); settingsButton:SetPoint("BOTTOMRIGHT")
    local footerLine = W.Fill(sidebar, T.line, "ARTWORK")
    footerLine:ClearAllPoints(); footerLine:SetPoint("BOTTOMLEFT", 0, NAV_ROW_HEIGHT + 8)
    footerLine:SetPoint("BOTTOMRIGHT", 0, NAV_ROW_HEIGHT + 8); footerLine:SetHeight(1)
    window.sidebarFooterLine = footerLine
    local navigation = W.Page(sidebar, 0)
    navigation:ClearAllPoints()
    navigation:SetPoint("TOPLEFT", 0, -40)
    navigation:SetPoint("BOTTOMRIGHT", settingsButton, "TOPRIGHT", 0, 16)
    -- A narrow gutter for the thin scroll thumb leaves room for full titles.
    navigation.scroll:ClearAllPoints()
    navigation.scroll:SetPoint("TOPLEFT"); navigation.scroll:SetPoint("BOTTOMRIGHT", -10, 0)
    navigation.scrollbar:ClearAllPoints()
    navigation.scrollbar:SetPoint("TOPRIGHT", 0, -2); navigation.scrollbar:SetPoint("BOTTOMRIGHT", 0, 2)

    local body = CreateFrame("Frame", nil, window)
    local contentGap=24
    body:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", contentGap, -12)
    window.contentLeft=sidebarWidth-10+contentGap
    body:SetPoint("BOTTOMRIGHT", -28, 16 + edge)
    if art then
        window.bodySurface=W.Fill(body,T.pageBackground,"BACKGROUND",-12)
        window.bodyDetail=W.ModePageDetail(body,-12)
        window.bodySheen=W.ModeSheen(body,-12)
    end
    local moduleHeader = PageHeader(body)
    window.moduleHeader = moduleHeader
    local banner = ReloadBanner(body)
    banner:SetPoint("TOPLEFT", 0, -W.PAGE_HEADER_HEIGHT)
    banner:SetPoint("TOPRIGHT", 0, -W.PAGE_HEADER_HEIGHT)
    window.reloadBanner = banner
    local pageHost = CreateFrame("Frame", nil, body)
    local pages, navigationButtons = {}, {}
    local selected
    local function AnchorPageHost()
        local top = W.PAGE_HEADER_HEIGHT + (banner:IsShown() and BANNER_HEIGHT + BANNER_GAP or 0)
        pageHost:ClearAllPoints()
        pageHost:SetPoint("TOPLEFT", 0, -top)
        pageHost:SetPoint("BOTTOMRIGHT", 0, 0)
    end
    AnchorPageHost()
    banner.reloadButton:SetScript("OnClick", function()
        local ok, reason = self.ReloadManager:Reload()
        if not ok then banner.reason:SetText(reason) end
        print("Play The Game Tools: " .. reason)
    end)
    function self:RefreshReloadBanner()
        local R = self.ReloadManager
        local pending = R:IsPending()
        if pending then banner.reason:SetText(R:GetReason()) end
        if pending == banner:IsShown() then return end
        banner:SetShown(pending)
        AnchorPageHost()
        local current = selected and pages[selected]
        if current and current:IsShown() then current:Layout() end
    end

    function self:RefreshConfig()
        moduleHeader:Refresh()
        layout:SetSelected(self.editMode)
        self.ReloadManager:Refresh()
        for id, button in pairs(navigationButtons) do
            button:SetSelected(id == selected)
            if button.RefreshModuleState then button:RefreshModuleState() end
        end
        -- Only the visible page refreshes; a cached page refreshes when it is
        -- selected or the window reopens (both run this function again).
        local current = selected and pages[selected]
        if current and window:IsShown() then current:Refresh() end
    end
    function self:EnsureConfigPage(id)
        if not pages[id] then
            local module = self.modules[id]
            pageHost.ptgMediaScope=module and id or nil
            if id == "globalSettings" then pages[id] = self:CreateGlobalSettingsPage(pageHost)
            elseif module.CreateConfigPage then pages[id] = module:CreateConfigPage(pageHost)
            else pages[id] = GenericPage(pageHost, module) end
            if W.ApplyModeModuleLayout and module then W.ApplyModeModuleLayout(pages[id],id) end
            pages[id].ptgMediaScope=pageHost.ptgMediaScope
            pageHost.ptgMediaScope=nil
            pages[id]:Hide()
        end
        return pages[id]
    end
    -- Keep the selected sidebar row inside the list's scroll view.
    local function RevealNavigation(id)
        local button = navigationButtons[id]
        if not button or not button.listed then return end
        local offset = button.offset or 0
        local value = navigation.scrollbar:GetValue()
        local visible = navigation.scroll:GetHeight()
        if offset < value then navigation.scrollbar:SetValue(offset)
        elseif offset + button:GetHeight() > value + visible then navigation.scrollbar:SetValue(offset + button:GetHeight() - visible) end
    end
    local function Select(id)
        -- Categories are module data only; a category id opens its first module.
        local category = self.categories[id]
        if category then id = category.modules[1] end
        if addon.FrameAnchors and selected~=id then addon.FrameAnchors:Stop() end
        if selected and selected~=id and addon.PreviewStates then addon.PreviewStates:Stop(selected) end
        local module = self.modules[id]
        if self.CloseSettingsSearch then self:CloseSettingsSearch() end
        if selected ~= id and self.CloseTimerColorPicker then self:CloseTimerColorPicker() end
        if selected ~= id and self.CloseFontDropdown then self:CloseFontDropdown() end
        if selected ~= id and self.CloseModulePreview then self:CloseModulePreview() end
        for _, page in pairs(pages) do page:Hide() end
        selected = id
        window.selectedPage = id
        AnchorPageHost()
        if id == "globalSettings" then moduleHeader:SetModule(nil, self.SETTINGS_PAGE)
        else moduleHeader:SetModule(module) end
        self:EnsureConfigPage(id)
        if not pages[id].UpdatePreviewLayout then
            pages[id]:ClearAllPoints();pages[id]:SetPoint("TOPLEFT");pages[id]:SetPoint("BOTTOMRIGHT")
        end
        if pages[id].SelectSectionTab then pages[id]:SelectSectionTab(1) end
        pages[id]:Show()
        pages[id]:Layout()
        self:RefreshConfig()
        RevealNavigation(id)
    end
    function self:SelectConfigPage(id)
        assert(id == "globalSettings" or self.modules[id] or (self.categories[id] and #self.categories[id].modules > 0), "Play The Game Tools: unknown settings page.")
        Select(id)
    end

    -- Shrinks the font only when a title would not fit on one line. Measures a
    -- separate unbounded label so the visible label's anchors stay intact.
    local probe = navigation:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    probe:Hide(); probe:SetWidth(0); probe:SetWordWrap(false)
    navigation.fontProbe = probe
    local function FitText(button)
        addon.Media:BindInterfaceFont(probe, GameFontHighlight, T.fontSize.body)
        probe:SetText(button.label:GetText())
        local measured = probe:GetStringWidth()
        local available = math.max(1, button:GetWidth() - button.textReserve)
        local size = T.fontSize.body
        if not (issecretvalue and issecretvalue(measured)) and type(measured) == "number" and measured > available and measured < math.huge then
            size = math.max(1, math.floor(size * available / measured * 4) / 4)
        end
        addon.Media:BindInterfaceFont(button.label, GameFontHighlight, size)
        if button.selectionEdge then W.AlignTextLine(button, button.selectionEdge) end
    end
    local function NavigationRow(parent, id, title, width)
        local button = W.Button(parent, title, width, NAV_ROW_HEIGHT, "tab")
        button.modeLeftAligned = true
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT", 10, 0)
        button.label:SetJustifyH("LEFT")
        button.label:SetWordWrap(false)
        button.textReserve = 20
        button:SetScript("OnClick", function() Select(id) end)
        button:HookScript("OnSizeChanged", FitText)
        addon.Media:RegisterFontListener(button, FitText)
        navigationButtons[id] = button
        return button
    end
    local function ModuleRow(id)
        local module = self.modules[id]
        local button = NavigationRow(navigation.content, id, module.title, sidebarWidth - 32 - edge)
        button.listed = true
        -- A small dot carries the module's on/off state: accent on, dim off.
        local dot = button:CreateTexture(nil, "OVERLAY")
        dot:SetSize(8, 8); dot:SetPoint("RIGHT", -10, 0)
        dot.modeAsset = "ModeThumb"
        button.stateDot = dot
        local right = -26
        if module.classIcon then
            button.classIcon = button:CreateTexture(nil, "ARTWORK")
            button.classIcon:SetSize(14, 14); button.classIcon:SetPoint("RIGHT", dot, "LEFT", -6, 0)
            button.classIcon:SetTexture(module.classIcon)
            right = -46
        end
        button.label:SetPoint("RIGHT", right, 0)
        button.textReserve = 10 - right
        function button:RefreshModuleState()
            self.moduleOn = module.enabled == true
            W.Paint(dot, self.moduleOn and T.primary or T.lineStrong)
        end
        button:RefreshModuleState()
        return button
    end
    for _, id in ipairs(self:ListedConfigPages()) do
        local button = ModuleRow(id)
        button:SetPoint("TOPLEFT", 0, -navigation.cursor)
        button.gapAfter = NAV_ROW_STEP - NAV_ROW_HEIGHT
        navigation.rows[#navigation.rows + 1] = button
        navigation.cursor = navigation.cursor + NAV_ROW_STEP
    end
    navigationButtons.globalSettings = settingsButton
    settingsButton.modeLeftAligned = true
    settingsButton.label:ClearAllPoints()
    settingsButton.label:SetPoint("LEFT", 10, 0); settingsButton.label:SetPoint("RIGHT", -10, 0)
    settingsButton.label:SetJustifyH("LEFT")
    settingsButton.label:SetWordWrap(false)
    addon.Media:BindInterfaceFont(settingsButton.label, GameFontHighlight, T.fontSize.body)
    settingsButton:SetScript("OnClick", function() Select("globalSettings") end)
    navigation:Finish()
    for _, button in pairs(navigationButtons) do if button.textReserve then FitText(button) end end
    window.navigation = navigation
    window.settingsButton = settingsButton
    -- Module rows by id; the list itself is navigation.rows.
    window.sidebarModuleButtons = {}
    for id, button in pairs(navigationButtons) do if button.listed then window.sidebarModuleButtons[id] = button end end
    window.navigationButtons, window.pages = navigationButtons, pages
    self:CreateSettingsSearch(sidebar, navigation)
    window:RegisterEvent("UI_SCALE_CHANGED")
    window:RegisterEvent("DISPLAY_SIZE_CHANGED")
    window:SetScript("OnEvent", function()
        self:FinishWindowInteraction(); self:UpdateWindowBounds()
        if self.UpdateModulePreviewBounds then self:UpdateModulePreviewBounds() end
        if self.EditMode then self.EditMode:ViewportChanged() end
    end)
    window:SetScript("OnShow", function()
        if self.ReloadManager.prompt then self.ReloadManager.prompt:Hide() end
        self:UpdateWindowBounds()
        -- The last page used this session, or the first module on first open.
        Select(selected or self:ListedConfigPages()[1] or "globalSettings")
        -- Fills in labels left blank by a font still loading on a fresh launch.
        addon.Media:ScheduleTextRedraw()
    end)
    window:SetScript("OnHide", function()
        if self.FrameAnchors then self.FrameAnchors:Stop() end
        if self.PreviewStates then self.PreviewStates:StopAll() end
        self:FinishWindowInteraction()
        if self.CloseTimerColorPicker then self:CloseTimerColorPicker() end
        if self.CloseFontDropdown then self:CloseFontDropdown() end
        if self.CloseModulePreview then self:CloseModulePreview() end
        if self.CloseSettingsSearch then self:CloseSettingsSearch() end
        if window.editSuspended then return end
        self:ResetDisplayModes()
        self:NotifyConfigClosed()
    end)
    -- Opening settings closes the addon's other windows; Escape closes it.
    self.Dialogs:Register(window, { group = "settings" })
    self:UpdateWindowBounds(true)
end

-- Developer Mode is not in the sidebar; /ptg dev opens its page.
function addon:OpenDeveloperPage()
    local id
    for _, moduleID in ipairs(self.moduleOrder) do
        if self.modules[moduleID].developer then id = moduleID; break end
    end
    if not id then return false end
    if self.editMode then self:SetEditMode(false) end
    if not self.configWindow then self:CreateConfig() end
    self.configWindow:Show()
    self:SelectConfigPage(id)
    return true
end

function addon:NotifyConfigClosed()
    for _, module in pairs(self.modules) do
        if module.OnConfigClosed then module:OnConfigClosed() end
    end
    self.ReloadManager:OnWindowClosed()
end

function addon:ToggleConfig()
    if self.editMode then self:SetEditMode(false); return end
    if not self.configWindow then self:CreateConfig() end
    self.configWindow:SetShown(not self.configWindow:IsShown())
end
