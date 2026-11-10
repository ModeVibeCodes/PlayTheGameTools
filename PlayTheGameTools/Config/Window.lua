local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
local WINDOW_WIDTH, WINDOW_HEIGHT = 1120, 760
local SIDEBAR_WIDTH, HEADER_HEIGHT = 240, 56
-- Reserve the reload control as well as Preview/Edit/Close for safe dragging.
local HEADER_RESERVED = 360 + 24 + 16

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

local function GenericPage(parent, module)
    local page = W.Page(parent)
    page:Finish()
    return page
end

local function Dashboard(parent)
    local page = W.Page(parent)
    -- Credits sit as plain type on the canvas; no card is needed to group them.
    local welcome = CreateFrame("Frame", nil, page.content)
    welcome:SetSize(400, 118)
    welcome.gapAfter = 8
    local lines = {
        "Welcome to Play The Game Tools!",
        "Created by Mode",
        "Inspired by Atrocity, Kira, NSRT, ExBoss, and others!",
        "If bug is found please contact Mode on Discord",
        "Discord: NoJumperMike",
    }
    page.welcomeTexts = lines
    for index, text in ipairs(lines) do
        local label
        if index == 1 then label = W.Heading(welcome, text, T.fontSize.section, 0, -4, 360, T.text)
        else label = W.Label(welcome, text, nil, 0, -12 - (index - 1) * 20, 360, index == 2 and T.secondary or T.muted) end
        label:SetPoint("TOPRIGHT", 0, index == 1 and -4 or -12 - (index - 1) * 20)
    end
    page.rows[#page.rows + 1] = welcome
    page.cursor = 126
    -- Forever readiness keeps profile services available without exposing controls.
    if not addon.Edition or addon.Edition.name ~= "Forever" then addon:CreateProfileHub(page) end
    page:Section("Modules", nil, false)
    page.moduleRows = {}
    for _, id in ipairs(addon.moduleOrder) do
        local module = addon.modules[id]
        if not module.developer then
        local row = CreateFrame("Frame", nil, page.content)
        row:SetPoint("TOPLEFT", 0, -page.cursor)
        row:SetSize(400, 56)
        row.gapAfter = 0
        row:EnableMouse(true)
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then addon:SelectConfigPage(id) end
        end)
        local divider = W.Fill(row, T.line, "BORDER")
        divider:ClearAllPoints(); divider:SetPoint("TOPLEFT"); divider:SetPoint("TOPRIGHT"); divider:SetHeight(1)
        -- The whole row opens the module; the switch on the right toggles it.
        local navigate = W.Button(row, module.title, 250, 54, "tab")
        navigate:SetPoint("TOPLEFT", 0, -1)
        navigate:SetPoint("BOTTOMRIGHT", -76, 0)
        navigate.label:ClearAllPoints()
        navigate.label:SetJustifyH("LEFT")
        navigate.label:SetPoint("TOPLEFT", 14, -12)
        navigate.label:SetPoint("TOPRIGHT", -96, -12)
        navigate:SetLabelColor(T.text)
        local summary = W.Label(navigate, module.configDescription or module.description or "", nil, 14, -30, 360, T.muted)
        summary:SetPoint("TOPRIGHT", -96, -30)
        summary:SetWordWrap(false)
        local status = W.Label(navigate, "", nil, 0, 0, 86, T.muted)
        status:ClearAllPoints()
        status:SetPoint("RIGHT", -8, 0)
        status:SetJustifyH("RIGHT")
        local toggle = W.Button(row, "", 52, 26, "toggle")
        toggle:SetPoint("RIGHT", -12, 0)
        navigate:SetScript("OnClick", function() addon:SelectConfigPage(id) end)
        toggle:SetScript("OnClick", function() addon:SetModuleEnabled(id, not module.enabled) end)
        page.refreshers[#page.refreshers + 1] = function()
            status:SetText(module.enabled and "Enabled" or "Disabled")
            status:SetTextColor(unpack(W.StateColor(module.enabled)))
            toggle:SetSelected(module.enabled)
        end
        page.rows[#page.rows + 1] = row
        page.moduleRows[id] = { row = row, navigate = navigate, toggle = toggle, status = status, summary = summary }
        page.cursor = page.cursor + 56
        end
    end
    page:Finish()
    return page
end

function addon:CreateConfig()
    local mode = T.id == "mode"
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
    if mode then window.canvasSheen=W.ModeSheen(window) end
    window.border = W.Outline(window, T.lineStrong, "OVERLAY")
    if mode then window.border:SetShown(false) end
    -- Sublevel 1 keeps the column above the canvas within the same draw layer.
    local column = window:CreateTexture(nil, "BACKGROUND", nil, 1)
    W.Paint(column, T.sidebar)
    column:SetPoint("TOPLEFT", 1, -1); column:SetPoint("BOTTOMLEFT", 1, 1)
    column:SetWidth(sidebarWidth)
    if mode then
        column.modeAsset="ModeSurface";W.Paint(column,T.sidebar)
        column:ClearAllPoints();column:SetPoint("TOPLEFT",8,-8);column:SetPoint("BOTTOMLEFT",8,8)
        column:SetWidth(sidebarWidth-8)
    end
    local columnEdge = W.Fill(window, T.line, "BORDER")
    columnEdge:ClearAllPoints(); columnEdge:SetPoint("TOPLEFT", sidebarWidth + 1, -1)
    columnEdge:SetPoint("BOTTOMLEFT", sidebarWidth + 1, 1); columnEdge:SetWidth(1)
    if mode then columnEdge:Hide() end
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

    -- A non-interactive header owns disjoint drag and button regions.
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
    if mode then window.headerArt:Hide() end
    window.title = W.Heading(header, mode and "PTG Tools" or "Play The Game Tools", T.fontSize.section, 20 + edge, -21, sidebarWidth - 24 - edge, mode and T.heading or T.text)
    if mode then
        window.title:SetTextColor(unpack(T.primary))
        local logo=header:CreateTexture(nil,"ARTWORK")
        logo:SetPoint("LEFT",14,0);logo:SetSize(38,38)
        addon.Media:ApplyTexture(logo,"ModeLogo")
        window.brandLogo=logo
        window.title:ClearAllPoints();window.title:SetPoint("LEFT",logo,"RIGHT",8,0)
        window.title:SetWidth(sidebarWidth-72)
    end
    window.title:SetWordWrap(false)
    local controls = CreateFrame("Frame", nil, header)
    controls:SetPoint("TOPRIGHT", -16 - edge, -14 - edge / 2)
    controls:SetSize(mode and 464 or 360, 28)
    window.headerReserved=mode and 720 or HEADER_RESERVED
    controls:SetFrameLevel(header:GetFrameLevel() + 1)
    controls:EnableMouse(false)
    function self:UpdateConfigTitle(id)
        -- The brand stays fixed; the page header below names the current page.
        window.title:SetText(mode and "PTG Tools" or "Play The Game Tools")
    end
    local drag = CreateFrame("Frame", nil, header)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("BOTTOMRIGHT", controls, "BOTTOMLEFT", -16, -14)
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
    local edit = HeaderButton("Edit Mode", 92)
    edit:SetPoint("RIGHT", close, "LEFT", -16, 0)
    edit:SetScript("OnClick", function() self:SetEditMode(not self.editMode) end)
    local preview = HeaderButton("Preview", 80)
    preview:SetPoint("RIGHT", edit, "LEFT", -8, 0)
    preview:SetScript("OnClick", function() self:SetPreviewMode(not self.previewMode) end)
    local reload = HeaderButton("Reload", 72)
    reload:SetPoint("RIGHT", preview, "LEFT", -8, 0)
    reload:SetScript("OnClick", function()
        local _,reason=self.ReloadManager:Reload()
        print("Play The Game Tools: "..reason)
    end)
    window.reloadButton=reload
    window.previewButton, window.editButton, window.closeButton = preview, edit, close
    if mode then
        local profile=HeaderButton("Profile:",132)
        profile:SetPoint("RIGHT",close,"LEFT",-8,0)
        edit:ClearAllPoints();edit:SetPoint("RIGHT",profile,"LEFT",-8,0)
        profile.label:ClearAllPoints();profile.label:SetPoint("LEFT",10,0)
        profile.label:SetWidth(42);profile.label:SetJustifyH("LEFT");profile.label:SetWordWrap(false)
        profile.profileName=W.Label(profile,self.ProfileManager.activeName,nil,0,0,68,T.primary)
        profile.profileName:ClearAllPoints();profile.profileName:SetPoint("LEFT",56,0);profile.profileName:SetPoint("RIGHT",-8,0)
        profile.profileName:SetWordWrap(false)
        function profile:LayoutProfileText()
            local function Measure(label)
                local value=label:GetStringWidth()
                if (issecretvalue and issecretvalue(value)) or type(value)~="number" or value~=value or value<=0 or value==math.huge then
                    return #(label:GetText() or "")*7
                end
                return math.ceil(value)
            end
            local prefix=Measure(self.label)
            local name=math.min(Measure(self.profileName),math.max(32,196-28-prefix-8))
            local group=prefix+8+name
            local width=math.max(132,math.min(196,group+28))
            self:SetWidth(width)
            self.label:ClearAllPoints();self.label:SetPoint("LEFT",(width-group)/2,0);self.label:SetWidth(prefix)
            self.profileName:ClearAllPoints();self.profileName:SetPoint("LEFT",self.label,"RIGHT",8,0);self.profileName:SetWidth(name)
            controls:SetWidth(width+312)
            window.headerReserved=math.max(window.headerReserved or 720,controls:GetWidth()+232)
        end
        self.Media:RegisterFontListener(profile,function(owner) owner:LayoutProfileText() end)
        local refresh=profile.RefreshAppearance
        function profile:RefreshAppearance()
            refresh(self)
            self.label:SetTextColor(unpack(T.secondary));self.label:SetShadowColor(0,0,0,0);self.label:SetShadowOffset(0,0)
            self.profileName:SetTextColor(unpack(self:IsEnabled() and T.primary or T.unavailable))
            self.profileName:SetShadowColor(T.primary[1],T.primary[2],T.primary[3],self:IsEnabled() and self.hovered and 0.55 or 0)
            self.profileName:SetShadowOffset(0,-1)
        end
        profile:RefreshAppearance()
        profile:LayoutProfileText()
        profile:SetScript("OnClick",function()
            self:SelectConfigPage("globalSettings")
            window.pages.globalSettings:SelectSectionTab(2)
        end)
        window.profileButton=profile
    end

    local sidebar = CreateFrame("Frame", nil, window)
    sidebar:SetPoint("TOPLEFT", 12 + edge, -HEADER_HEIGHT - 4)
    sidebar:SetPoint("BOTTOMLEFT", 12 + edge, 12 + edge)
    sidebar:SetWidth(sidebarWidth - 22 - edge)
    local navigation = W.Page(sidebar, 0)
    navigation:ClearAllPoints()
    navigation:SetPoint("TOPLEFT", 0, mode and 0 or -44)
    navigation:SetPoint("BOTTOMRIGHT")

    local body = CreateFrame("Frame", nil, window)
    local contentGap=mode and 24 or 30
    body:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", contentGap, -16)
    window.contentLeft=sidebarWidth-10+contentGap
    body:SetPoint("BOTTOMRIGHT", -28, 16 + edge)
    if mode then
        window.bodySurface=W.Fill(body,T.panel,"BACKGROUND",-12)
        window.bodySheen=W.ModeSheen(body,-12)
    end
    local moduleHeader = W.ModuleHeader(body)
    window.moduleHeader = moduleHeader
    local pageHost = CreateFrame("Frame", nil, body)
    pageHost:SetPoint("TOPLEFT", 0, -W.PAGE_HEADER_HEIGHT)
    pageHost:SetPoint("BOTTOMRIGHT")
    local pages, navigationButtons = {}, {}
    local categoryNavigation = self:CreateCategoryNavigation(body, navigationButtons)
    window.categoryNavigation = categoryNavigation
    local selected = "dashboard"
    local RefreshSidebar
    -- Session-local disclosure state: mode categories start expanded on reload.
    local collapsed = {}
    window.collapsedCategories = collapsed

    function self:RefreshConfig()
        if window.profileButton then
            window.profileButton.profileName:SetText(self.ProfileManager.activeName)
            window.profileButton:LayoutProfileText()
        end
        moduleHeader:Refresh()
        preview:SetSelected(self.previewMode)
        edit:SetSelected(self.editMode)
        self.ReloadManager:Refresh()
        for id, button in pairs(navigationButtons) do
            local selectedModule = self.modules[selected]
            button:SetSelected(id == selected or (self.categories[id] ~= nil and selectedModule and selectedModule.category == id) or false)
            if button.status then
                local enabled = self.modules[id].enabled
                button.status:SetText(enabled and "On" or "Off")
                button.status:SetTextColor(unpack(W.StateColor(enabled)))
            end
            if button.RefreshModuleState then button:RefreshModuleState() end
        end
        for _, page in pairs(pages) do page:Refresh() end
    end
    function self:EnsureConfigPage(id)
        if not pages[id] then
            local module = self.modules[id]
            pageHost.ptgMediaScope=module and id or nil
            if id == "dashboard" then pages[id] = Dashboard(pageHost)
            elseif id == "globalSettings" then pages[id] = self:CreateGlobalSettingsPage(pageHost)
            elseif module.CreateConfigPage then pages[id] = module:CreateConfigPage(pageHost)
            else pages[id] = GenericPage(pageHost, module) end
            pages[id].ptgMediaScope=pageHost.ptgMediaScope
            pageHost.ptgMediaScope=nil
            pages[id]:Hide()
        end
        return pages[id]
    end
    local function Select(id, preserveDisclosure)
        if addon.FrameAnchors and selected~=id then addon.FrameAnchors:Stop() end
        if selected~=id and addon.PreviewStates then addon.PreviewStates:Stop(selected) end
        local category = self.categories[id]
        if category then id = category.selectedModule or category.modules[1] end
        local module = self.modules[id]
        category = module and module.category and self.categories[module.category] or nil
        if category then category.selectedModule = id end
        if self.CloseSettingsSearch then self:CloseSettingsSearch() end
        if selected ~= id and self.CloseTimerColorPicker then self:CloseTimerColorPicker() end
        if selected ~= id and self.CloseFontDropdown then self:CloseFontDropdown() end
        if selected ~= id then self:CloseModulePreview() end
        for _, page in pairs(pages) do page:Hide() end
        selected = id
        self:UpdateConfigTitle(id)
        window.selectedPage = id
        window.selectedCategory = category and category.id or nil
        categoryNavigation:SetCategory(not mode and category or nil, id)
        if mode and category and not preserveDisclosure then collapsed[category.id] = nil end
        if RefreshSidebar then RefreshSidebar(category, id) end
        -- Category tabs, when present, sit above the page header.
        local top = not mode and category and 44 or 0
        moduleHeader:ClearAllPoints()
        moduleHeader:SetPoint("TOPLEFT", 0, -top)
        moduleHeader:SetPoint("TOPRIGHT", 0, -top)
        pageHost:ClearAllPoints()
        pageHost:SetPoint("TOPLEFT", 0, -top - W.PAGE_HEADER_HEIGHT)
        pageHost:SetPoint("BOTTOMRIGHT", 0, 0)
        moduleHeader:SetModule(module)
        if id=="globalSettings" then
            moduleHeader.title:SetText("Global Settings")
            moduleHeader.description:SetText("Shared appearance defaults for the entire addon suite.")
        end
        self:EnsureConfigPage(id)
        if not pages[id].UpdatePreviewLayout then
            pages[id]:ClearAllPoints();pages[id]:SetPoint("TOPLEFT");pages[id]:SetPoint("BOTTOMRIGHT")
        end
        if pages[id].SelectSectionTab then pages[id]:SelectSectionTab(1) end
        pages[id]:Show()
        pages[id]:Layout()
        self:RefreshConfig()
    end
    function self:SelectConfigPage(id)
        assert(id == "dashboard" or id == "globalSettings" or self.modules[id] or (self.categories[id] and #self.categories[id].modules > 0), "Play The Game Tools: unknown settings page.")
        Select(id)
    end
    local function AddNavigation(id, label, developer)
        local isHeading = mode and self.categories[id] ~= nil
        local button = W.Button(developer and sidebar or navigation.content, label, developer and sidebarWidth - 22 - edge or 184, 34, isHeading and "categoryHeading" or "tab")
        button.categoryID = isHeading and id or nil
        if developer then button:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 0, 0)
        else button:SetPoint("TOPLEFT", 0, -navigation.cursor) end
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT", 12, 0)
        button.label:SetPoint("RIGHT", -54, 0)
        button.label:SetJustifyH("LEFT")
        if mode then
            button.modeLeftAligned=true
            button.label:ClearAllPoints()
            button.label:SetPoint("LEFT", 10, 0)
            button.label:SetPoint("RIGHT", -10, 0)
            button.label:SetWordWrap(false)
            addon.Media:BindInterfaceFont(button.label, GameFontHighlight, isHeading and T.fontSize.group or T.fontSize.body, nil, isHeading and "heading" or nil)
            if isHeading then
                button:SetLabelColor(T.heading)
                button.gapBefore = 10
            end
        end
        button:SetScript("OnClick", function()
            if isHeading then
                collapsed[id] = not collapsed[id]
                RefreshSidebar(self.categories[window.selectedCategory], selected)
            else Select(id) end
        end)
        if self.modules[id] and not self.modules[id].developer then
            button.status = W.Label(button, "", nil, 0, 0, 24, T.muted)
            button.status:ClearAllPoints()
            button.status:SetPoint("RIGHT", -10, 0)
            button.status:SetJustifyH("RIGHT")
            addon.Media:BindInterfaceFont(button.status, GameFontHighlight, T.fontSize.small)
        end
        navigationButtons[id] = button
        if not developer then
            navigation.rows[#navigation.rows + 1] = button
            navigation.cursor = navigation.cursor + 36
        else
            navigation:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", 0, 12)
            local line = W.Fill(sidebar, T.line, "ARTWORK")
            line:ClearAllPoints(); line:SetPoint("BOTTOMLEFT", 0, 40); line:SetPoint("BOTTOMRIGHT", 0, 40); line:SetHeight(1)
        end
    end
    local sidebarRoots = {}
    AddNavigation("dashboard", "Dashboard")
    AddNavigation("globalSettings", "Global Settings")
    for _, id in ipairs(self.categoryOrder) do
        if #self.categories[id].modules > 0 then AddNavigation(id, self.categories[id].title) end
    end
    for _, id in ipairs(self.moduleOrder) do
        if not self.modules[id].developer and not self.modules[id].category then AddNavigation(id, self.modules[id].title) end
    end
    for _, id in ipairs(self.moduleOrder) do
        if self.modules[id].developer then AddNavigation(id, self.modules[id].title, true) end
    end
    for _,row in ipairs(navigation.rows) do sidebarRoots[#sidebarRoots+1]=row end
    local nested = {}
    window.sidebarModuleButtons = nested
    local function NestedButton(id)
        if nested[id] then return nested[id] end
        local module=addon.modules[id]
        local title = module.tabTitle or module.title
        local button=W.Button(navigation.content,mode and ("· " .. title) or title,184,mode and 32 or 28,"tab")
        button.modeLeftAligned=mode
        button.atelierNested=true
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT",mode and 16 or 24,0)
        if module.classIcon then
            button.classIcon=button:CreateTexture(nil,"ARTWORK");button.classIcon:SetPoint("LEFT",24,0);button.classIcon:SetSize(18,18);button.classIcon:SetTexture(module.classIcon)
            button.label:ClearAllPoints();button.label:SetPoint("LEFT",48,0)
        end
        button.label:SetPoint("RIGHT",-10,0)
        button.label:SetJustifyH("LEFT")
        if mode then button.label:SetWordWrap(false) end
        addon.Media:BindInterfaceFont(button.label,GameFontHighlight,mode and T.fontSize.body or T.fontSize.small)
        if mode and module.classIcon then
            -- Keep class identity while giving every child the same dot prefix.
            button.classIcon:ClearAllPoints();button.classIcon:SetPoint("RIGHT",-8,0)
            button.label:ClearAllPoints();button.label:SetPoint("LEFT",16,0);button.label:SetPoint("RIGHT",-32,0)
        end
        if mode then
            -- Measure against a separate unbounded label: the visible label's
            -- anchors must stay intact, and truncation must not hide its width.
            local probe=navigation.fontProbe
            if not probe then
                probe=navigation:CreateFontString(nil,"OVERLAY","GameFontHighlight")
                probe:Hide();probe:SetWidth(0);probe:SetWordWrap(false);navigation.fontProbe=probe
            end
            function button:FitNavigationText()
                addon.Media:BindInterfaceFont(probe,GameFontHighlight,T.fontSize.body)
                probe:SetText(self.label:GetText())
                local measured=probe:GetStringWidth()
                local available=math.max(1,self:GetWidth()-(module.classIcon and 48 or 26))
                local size=T.fontSize.body
                if not (issecretvalue and issecretvalue(measured)) and type(measured)=="number" and measured>available and measured<math.huge then
                    size=math.max(1,math.floor(size*available/measured*4)/4)
                end
                addon.Media:BindInterfaceFont(self.label,GameFontHighlight,size)
                W.AlignTextLine(self,self.selectionEdge)
            end
            button:HookScript("OnSizeChanged",function(owner) owner:FitNavigationText() end)
            addon.Media:RegisterFontListener(button,function(owner) owner:FitNavigationText() end)
        end
        button:SetScript("OnClick",function() Select(id) end)
        nested[id]=button
        return button
    end
    RefreshSidebar=function(category,id)
        for _,button in pairs(nested) do button:Hide() end
        navigation.rows={}
        for _,root in ipairs(sidebarRoots) do
            navigation.rows[#navigation.rows+1]=root
            local group = mode and root.categoryID and self.categories[root.categoryID] or nil
            local expanded = mode and group and not collapsed[group.id]
            if mode and group then root.expanded = expanded == true end
            if expanded or (not mode and category and root==navigationButtons[category.id]) then
                for _,moduleID in ipairs((group or category).modules) do
                    local button=NestedButton(moduleID)
                    button:SetSelected(moduleID==id)
                    navigation.rows[#navigation.rows+1]=button
                end
            end
        end
        navigation:Layout()
        if mode then for _,button in pairs(nested) do if button:IsShown() then button:FitNavigationText() end end end
        -- Reveal the clicked/search-routed module in the same existing scroll view.
        local button=nested[id]
        if button and category and (not mode or not collapsed[category.id]) then
            local offset=button.offset or 0
            local value=navigation.scrollbar:GetValue()
            local visible=navigation.scroll:GetHeight()
            if offset<value then navigation.scrollbar:SetValue(offset)
            elseif offset+button:GetHeight()>value+visible then navigation.scrollbar:SetValue(offset+button:GetHeight()-visible) end
        end
    end
    navigation:Finish()
    window.navigation = navigation
    window.navigationButtons, window.pages = navigationButtons, pages
    self:CreateSettingsSearch(sidebar)
    window:RegisterEvent("UI_SCALE_CHANGED")
    window:RegisterEvent("DISPLAY_SIZE_CHANGED")
    window:SetScript("OnEvent", function()
        self:FinishWindowInteraction(); self:UpdateWindowBounds()
        self:UpdateModulePreviewBounds()
        if self.EditMode then self.EditMode:ViewportChanged() end
    end)
    window:SetScript("OnShow", function()
        if self.ReloadManager.prompt then self.ReloadManager.prompt:Hide() end
        self:UpdateWindowBounds(); Select(selected, true)
        -- Fills in labels left blank by a font still loading on a fresh launch.
        addon.Media:ScheduleTextRedraw()
    end)
    window:SetScript("OnHide", function()
        if self.FrameAnchors then self.FrameAnchors:Stop() end
        if self.PreviewStates then self.PreviewStates:StopAll() end
        self:FinishWindowInteraction()
        if self.CloseTimerColorPicker then self:CloseTimerColorPicker() end
        if self.CloseFontDropdown then self:CloseFontDropdown() end
        self:CloseModulePreview()
        if self.CloseSettingsSearch then self:CloseSettingsSearch() end
        if window.editSuspended then return end
        self:ResetDisplayModes()
        self:NotifyConfigClosed()
    end)
    self:UpdateWindowBounds(true)
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
