local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme

-- Compact category tab strip; each module keeps its own cached settings page.
function addon:CreateCategoryNavigation(parent, navigationButtons)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint("TOPLEFT", 12, 4)
    view:SetPoint("TOPRIGHT", -12, 4)
    view:SetHeight(36)
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
            local width=math.max(150,math.ceil(measured)+76)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT",x,0);button:SetSize(width,34)
            button.label:SetWidth(width-76)
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
                button = W.Button(strip, module.tabTitle or module.title, 200, 30, "tab")
                button.label:ClearAllPoints()
                button.label:SetPoint("LEFT", 12, 0)
                button.label:SetPoint("RIGHT", -54, 0)
                button.label:SetJustifyH("LEFT")
                button.label:SetWordWrap(false)
                button.status = W.Label(button, "", nil, 0, 0, 24, T.muted)
                button.status:ClearAllPoints(); button.status:SetPoint("RIGHT", -8, 0)
                button.indicator = W.Texture(button, "RoundMarker", "OVERLAY")
                button.indicator:ClearAllPoints(); button.indicator:SetPoint("RIGHT", -38, 0)
                button.indicator:SetSize(8, 8)
                button.underline=W.Fill(button,T.primary,"OVERLAY")
                button.underline:ClearAllPoints();button.underline:SetPoint("BOTTOMLEFT",6,0);button.underline:SetPoint("BOTTOMRIGHT",-6,0);button.underline:SetHeight(2)
                function button:RefreshModuleState()
                    local enabled=addon.modules[id].enabled
                    self.fill:SetDesaturated(false)
                    self.moduleEnabled=enabled
                    self:SetLabelColor(self.selected and T.primary or T.text)
                    self.activeGlow:SetAlpha(self.selected and 0.65 or 0.12)
                    self.activeGlow:SetShown(self:IsEnabled() and (self.selected or enabled))
                    self.underline:SetShown(self.selected==true)
                end
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
