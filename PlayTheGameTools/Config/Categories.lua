local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme

-- Compact category tab strip; each module keeps its own cached settings page.
function addon:CreateCategoryNavigation(parent, navigationButtons)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint("TOPLEFT", 0, 0)
    view:SetPoint("TOPRIGHT", 0, 0)
    view:SetHeight(36)
    view.baseline = W.Fill(view, T.line, "BACKGROUND")
    view.baseline:ClearAllPoints(); view.baseline:SetPoint("BOTTOMLEFT", 0, 1); view.baseline:SetPoint("BOTTOMRIGHT", 0, 1)
    view.baseline:SetHeight(1)
    local viewport=CreateFrame("ScrollFrame",nil,view)
    viewport:SetPoint("TOPLEFT");viewport:SetPoint("BOTTOMRIGHT")
    local strip = CreateFrame("Frame", nil, viewport)
    strip:SetSize(1,36);viewport:SetScrollChild(strip)
    local offset=0
    function view:Scroll(value)
        offset=math.max(0,math.min(self.maximum or 0,value));viewport:SetHorizontalScroll(offset)
    end
    viewport:EnableMouseWheel(true);viewport:SetScript("OnMouseWheel",function(_,delta) view:Scroll(offset-delta*100) end)
    view.buttons = {}
    function view:LayoutTabs()
        local category = self.category
        if not category then return end
        local x=0
        for _, id in ipairs(category.modules) do
            local button = self.buttons[id]
            button.label:SetWidth(0)
            local measured=button.label:GetStringWidth()
            if (issecretvalue and issecretvalue(measured)) or type(measured)~="number" or measured~=measured or measured<0 or measured==math.huge then measured=#(addon.modules[id].tabTitle or addon.modules[id].title)*9 end
            local width
            if addon.modules[id].classIcon then
                button.status:SetWidth(0)
                local statusWidth=button.status:GetStringWidth()
                if (issecretvalue and issecretvalue(statusWidth)) or type(statusWidth)~="number" or statusWidth~=statusWidth or statusWidth<0 or statusWidth==math.huge then statusWidth=24 end
                statusWidth=math.max(18,math.ceil(statusWidth))
                button.label:SetWidth(math.ceil(measured))
                button.status:SetWidth(statusWidth)
                width=34+math.ceil(measured)+8+statusWidth+8
            else width=math.max(120,math.ceil(measured)+64);button.label:SetWidth(width-64) end
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT",x,0);button:SetSize(width,34)
            button.tabX,button.tabWidth=x,width;x=x+width+4
        end
        strip:SetWidth(math.max(1,x-4));self.maximum=math.max(0,x-4-viewport:GetWidth());self:Scroll(offset)
        for _,id in ipairs(category.modules) do local button=self.buttons[id]
            if button.selected then
                if button.tabX<offset then self:Scroll(button.tabX)
                elseif button.tabX+button.tabWidth>offset+viewport:GetWidth() then self:Scroll(button.tabX+button.tabWidth-viewport:GetWidth()) end
            end
        end
    end
    viewport:SetScript("OnSizeChanged", function() view:LayoutTabs() end)
    function view:SetCategory(category, selected)
        self.category = category
        for _, button in pairs(self.buttons) do button:Hide() end
        self:SetShown(category ~= nil)
        if not category then return end
        for _, id in ipairs(category.modules) do
            local module = addon.modules[id]
            local button = self.buttons[id]
            if not button then
                button = W.Button(strip, module.tabTitle or module.title, 200, 30, "underline")
                button.label:ClearAllPoints()
                button.label:SetPoint("LEFT", 12, 0)
                if module.classIcon then
                    button.classIcon=button:CreateTexture(nil,"ARTWORK");button.classIcon:SetPoint("LEFT",8,0);button.classIcon:SetSize(20,20);button.classIcon:SetTexture(module.classIcon)
                    button.label:ClearAllPoints();button.label:SetPoint("LEFT",34,0)
                else
                    button.label:SetPoint("RIGHT", -48, 0)
                end
                button.label:SetJustifyH("LEFT")
                button.label:SetWordWrap(false)
                button.status = W.Label(button, "", nil, 0, 0, 30, T.muted)
                button.status:ClearAllPoints(); button.status:SetPoint("RIGHT", -12, 0)
                button.status:SetJustifyH("RIGHT")
                if module.classIcon then
                    button.status:ClearAllPoints();button.status:SetPoint("LEFT",button.label,"RIGHT",8,0)
                    button.status:SetJustifyH("LEFT");button.status:SetWordWrap(false)
                end
                addon.Media:BindInterfaceFont(button.status, GameFontHighlight, T.fontSize.small)
                button.underline=W.Fill(button,T.primary,"OVERLAY")
                button.underline:ClearAllPoints();button.underline:SetPoint("BOTTOMLEFT",10,0);button.underline:SetPoint("BOTTOMRIGHT",-10,0);button.underline:SetHeight(2)
                button.underline:Hide()
                function button:RefreshModuleState()
                    self.moduleEnabled=addon.modules[id].enabled
                    self:SetLabelColor(self.selected and T.text or (self.hovered and T.text or T.secondary))
                    self.underline:SetShown(self.selected==true)
                    if module.classIcon then view:LayoutTabs() end
                end
                button:HookScript("OnEnter",function(self) self:RefreshModuleState() end)
                button:HookScript("OnLeave",function(self) self:RefreshModuleState() end)
                button:SetScript("OnClick", function() addon:SelectConfigPage(id) end)
                self.buttons[id], navigationButtons[id] = button, button
            end
            button:SetSelected(id == selected)
            button:Show()
        end
        self:LayoutTabs()
    end
    for _, id in ipairs(self.categoryOrder) do
        local category = self.categories[id]
        if #category.modules > 0 then view:SetCategory(category) end
    end
    view:SetCategory(nil)
    addon.Media:RegisterFontListener(view,function(owner) owner:LayoutTabs() end)
    return view
end
