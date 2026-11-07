local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
local WINDOW_WIDTH, WINDOW_HEIGHT = 1120, 760
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
    local minX=-width/2-w/2+HEADER_RESERVED*ratio+keep
    local maxX=width/2+w/2-keep
    local minY=-height/2-h/2+keep
    local maxY=height/2-h/2+64*ratio-keep
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
    local welcome = CreateFrame("Frame", nil, page.content)
    welcome:SetSize(400, 132)
    welcome.gapAfter = 12
    W.Texture(welcome, "InsetPanel")
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
        if index == 1 then label = W.Heading(welcome, text, 18, 14, -10, 360, T.primary)
        else label = W.Label(welcome, text, nil, 14, -18 - (index - 1) * 20, 360, index == 3 and T.secondary or T.text) end
        label:SetPoint("TOPRIGHT", -14, index == 1 and -10 or -18 - (index - 1) * 20)
    end
    page.rows[#page.rows + 1] = welcome
    page.cursor = 144
    -- Forever readiness keeps profile services available without exposing controls.
    if not addon.Edition or addon.Edition.name ~= "Forever" then addon:CreateProfileHub(page) end
    page:Section("Modules", nil, false)
    page.moduleRows = {}
    for _, id in ipairs(addon.moduleOrder) do
        local module = addon.modules[id]
        if not module.developer then
        local row = CreateFrame("Frame", nil, page.content)
        row:SetPoint("TOPLEFT", 0, -page.cursor)
        row:SetSize(400, 48)
        row:EnableMouse(true)
        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then addon:SelectConfigPage(id) end
        end)
        W.Texture(row, "InsetPanel")
        local navigate = W.Button(row, module.title, 250, 40, "tab")
        navigate:SetPoint("TOPLEFT", 4, -4)
        navigate:SetPoint("BOTTOMRIGHT", -72, 4)
        navigate.label:ClearAllPoints()
        navigate.label:SetJustifyH("LEFT")
        navigate.label:SetPoint("LEFT", 12, 0)
        navigate.label:SetPoint("RIGHT", -104, 0)
        local status = W.Label(navigate, "", nil, 0, 0, 86, T.muted)
        status:ClearAllPoints()
        status:SetPoint("RIGHT", -8, 0)
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
        page.moduleRows[id] = { row = row, navigate = navigate, toggle = toggle, status = status }
        page.cursor = page.cursor + 52
        end
    end
    page:Finish()
    return page
end

function addon:CreateConfig()
    local window = CreateFrame("Frame", "ModeToolsConfigWindow", UIParent)
    window:Hide()
    self.configWindow = window
    window:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(false)
    window:EnableMouse(true)
    W.Texture(window, "Window")
    W.Texture(window, "BorderSilver", "BORDER")

    -- A non-interactive header owns disjoint drag and button regions.
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(64)
    header:SetFrameLevel(window:GetFrameLevel() + 10)
    header:EnableMouse(false)
    window.headerArt = W.Texture(header, "Header", "BACKGROUND", 3)
    window.title = W.Heading(header, "Play The Game Tools", 23, 24, -18, 740, T.primary)
    local underline = W.Texture(header, "UnderlineMint", "ARTWORK")
    underline:ClearAllPoints()
    underline:SetPoint("TOPLEFT", 24, -51)
    underline:SetSize(112, 2)
    local controls = CreateFrame("Frame", nil, header)
    controls:SetPoint("TOPRIGHT", -24, -18)
    controls:SetSize(360, 30)
    controls:SetFrameLevel(header:GetFrameLevel() + 1)
    controls:EnableMouse(false)
    window.title:SetPoint("TOPRIGHT", controls, "TOPLEFT", -16, 0)
    function self:UpdateConfigTitle(id)
        local item=self.modules[id] or self.categories[id]
        local name=item and item.title or (id=="dashboard" and "Dashboard" or nil)
        window.title:SetText("Play The Game Tools" .. (name and (" — " .. name) or ""))
    end
    local drag = CreateFrame("Frame", nil, header)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("BOTTOMRIGHT", controls, "BOTTOMLEFT", -16, -16)
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
        local button = W.Button(controls, label, width, 30, label == "X" and "secondary" or nil)
        button:SetFrameLevel(controls:GetFrameLevel() + 1)
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonUp")
        return button
    end
    local close = HeaderButton("X", 30)
    close:SetPoint("RIGHT")
    close:SetScript("OnClick", function() window:Hide() end)
    local edit = HeaderButton("Edit Mode", 112)
    edit:SetPoint("RIGHT", close, "LEFT", -12, 0)
    edit:SetScript("OnClick", function() self:SetEditMode(not self.editMode) end)
    local preview = HeaderButton("Preview", 92)
    preview:SetPoint("RIGHT", edit, "LEFT", -12, 0)
    preview:SetScript("OnClick", function() self:SetPreviewMode(not self.previewMode) end)
    local reload = HeaderButton("Reload", 78)
    reload:SetPoint("RIGHT", preview, "LEFT", -12, 0)
    reload:SetScript("OnClick", function()
        local _,reason=self.ReloadManager:Reload()
        print("Play The Game Tools: "..reason)
    end)
    window.reloadButton=reload
    window.previewButton, window.editButton, window.closeButton = preview, edit, close

    local sidebar = CreateFrame("Frame", nil, window)
    sidebar:SetPoint("TOPLEFT", 24, -92)
    sidebar:SetPoint("BOTTOMLEFT", 24, 48)
    sidebar:SetWidth(204)
    W.Texture(sidebar, "Sidebar")
    local edge = W.Texture(sidebar, "AtelierEdge", "BORDER", 0, 0.45)
    edge:ClearAllPoints()
    edge:SetPoint("TOPRIGHT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetWidth(8)
    W.Label(sidebar, "Options", "GameFontDisableSmall", 0, -4, 160, T.secondary)
    local navigation = W.Page(sidebar, 0)
    navigation:ClearAllPoints()
    navigation:SetPoint("TOPLEFT", 0, -62)
    navigation:SetPoint("BOTTOMRIGHT")

    local body = CreateFrame("Frame", nil, window)
    body:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 24, 0)
    body:SetPoint("BOTTOMRIGHT", -24, 48)
    W.Texture(body, "RaisedPanel")
    local moduleHeader = W.ModuleHeader(body)
    window.moduleHeader = moduleHeader
    local pageHost = CreateFrame("Frame", nil, body)
    pageHost:SetPoint("TOPLEFT", 16, 0)
    pageHost:SetPoint("BOTTOMRIGHT", -12, 0)
    local pages, navigationButtons = {}, {}
    local categoryNavigation = self:CreateCategoryNavigation(body, navigationButtons)
    window.categoryNavigation = categoryNavigation
    local selected = "dashboard"
    local RefreshSidebar

    function self:RefreshConfig()
        moduleHeader:Refresh()
        preview:SetSelected(self.previewMode)
        edit:SetSelected(self.editMode)
        self.ReloadManager:Refresh()
        for id, button in pairs(navigationButtons) do
            local selectedModule = self.modules[selected]
            button:SetSelected(id == selected or (self.categories[id] ~= nil and selectedModule and selectedModule.category == id) or false)
            if button.indicator then
                local enabled = self.modules[id].enabled
                button.indicator:SetVertexColor(unpack(W.StateColor(enabled)))
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
            if id == "dashboard" then pages[id] = Dashboard(pageHost)
            elseif module.CreateConfigPage then pages[id] = module:CreateConfigPage(pageHost)
            else pages[id] = GenericPage(pageHost, module) end
            pages[id]:Hide()
        end
        return pages[id]
    end
    local function Select(id)
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
        categoryNavigation:SetCategory(category, id)
        if RefreshSidebar then RefreshSidebar(category, id) end
        moduleHeader:ClearAllPoints()
        moduleHeader:SetPoint("TOPLEFT", 0, category and -38 or 0)
        moduleHeader:SetPoint("TOPRIGHT", 0, category and -38 or 0)
        pageHost:ClearAllPoints()
        pageHost:SetPoint("TOPLEFT", 16, category and -38 or 0)
        pageHost:SetPoint("BOTTOMRIGHT", -12, 0)
        moduleHeader:SetModule(module)
        self:EnsureConfigPage(id)
        if not pages[id].UpdatePreviewLayout and module and not module.developer then
            pages[id]:ClearAllPoints();pages[id]:SetPoint("TOPLEFT",0,-52);pages[id]:SetPoint("BOTTOMRIGHT")
        end
        if pages[id].SelectSectionTab then pages[id]:SelectSectionTab(1) end
        pages[id]:Show()
        pages[id]:Layout()
        self:RefreshConfig()
    end
    function self:SelectConfigPage(id)
        assert(id == "dashboard" or self.modules[id] or (self.categories[id] and #self.categories[id].modules > 0), "Play The Game Tools: unknown settings page.")
        Select(id)
    end
    local function AddNavigation(id, label, developer)
        local button = W.Button(developer and sidebar or navigation.content, label, developer and 204 or 184, 38, "tab")
        if developer then button:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 0, 0)
        else button:SetPoint("TOPLEFT", 0, -navigation.cursor) end
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT", 12, 0)
        button.label:SetPoint("RIGHT", -54, 0)
        button.label:SetJustifyH("LEFT")
        button:SetScript("OnClick", function() Select(id) end)
        if self.modules[id] and not self.modules[id].developer then
            button.status = W.Label(button, "", nil, 0, 0, 24, T.muted)
            button.status:ClearAllPoints()
            button.status:SetPoint("RIGHT", -8, 0)
            button.indicator = W.Texture(button, "RoundMarker", "OVERLAY")
            button.indicator:ClearAllPoints()
            button.indicator:SetPoint("RIGHT", -38, 0)
            button.indicator:SetSize(8, 8)
        end
        navigationButtons[id] = button
        if not developer then
            navigation.rows[#navigation.rows + 1] = button
            navigation.cursor = navigation.cursor + 44
        else
            navigation:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", 0, 10)
            local line = W.Texture(sidebar, "AccentLavender", "ARTWORK")
            line:ClearAllPoints(); line:SetPoint("BOTTOMLEFT", 0, 44); line:SetPoint("BOTTOMRIGHT", 0, 44); line:SetHeight(1)
        end
    end
    local sidebarRoots = {}
    AddNavigation("dashboard", "Dashboard")
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
        local button=W.Button(navigation.content,module.tabTitle or module.title,184,30,"tab")
        button.atelierNested=true
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT",24,0)
        button.label:SetPoint("RIGHT",-10,0)
        button.label:SetJustifyH("LEFT")
        addon.Media:BindInterfaceFont(button.label,GameFontHighlight,11)
        button:SetScript("OnClick",function() Select(id) end)
        nested[id]=button
        return button
    end
    RefreshSidebar=function(category,id)
        for _,button in pairs(nested) do button:Hide() end
        navigation.rows={}
        for _,root in ipairs(sidebarRoots) do
            navigation.rows[#navigation.rows+1]=root
            if category and root==navigationButtons[category.id] then
                for _,moduleID in ipairs(category.modules) do
                    local button=NestedButton(moduleID)
                    button:SetSelected(moduleID==id)
                    navigation.rows[#navigation.rows+1]=button
                end
            end
        end
        navigation:Layout()
        -- Reveal the clicked/search-routed module in the same existing scroll view.
        local button=nested[id]
        if button and category then
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
        self:UpdateWindowBounds(); Select(selected)
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
        for _, module in pairs(self.modules) do
            if module.OnConfigClosed then module:OnConfigClosed() end
        end
        self.ReloadManager:OnWindowClosed()
    end)
    self:UpdateWindowBounds(true)
end

function addon:ToggleConfig()
    if self.editMode then self:SetEditMode(false); return end
    if not self.configWindow then self:CreateConfig() end
    self.configWindow:SetShown(not self.configWindow:IsShown())
end
