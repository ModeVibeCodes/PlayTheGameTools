local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme

function W.FitModeTab(button,width)
    local available=math.max(1,width-16)
    button.label:SetWordWrap(false);button.label:SetWidth(0)
    addon.Media:BindInterfaceFont(button.label,GameFontHighlight,12)
    local measured=button.label:GetStringWidth()
    if not (issecretvalue and issecretvalue(measured)) and type(measured)=="number" and measured==measured and measured>available and measured<math.huge then
        addon.Media:BindInterfaceFont(button.label,GameFontHighlight,math.max(8,12*available/measured))
    end
    button.label:SetWidth(available)
    if button.selectionEdge then W.AlignTextLine(button,button.selectionEdge) end
end

-- The capsule export is 4:1. Keep that aspect ratio instead of stretching its
-- round ends into ellipses on pages with only two or three sections.
function W.LayoutModePills(buttons,available)
    if available<64 or #buttons==0 then return end
    local gap=8
    local width=math.min(128,math.max(1,(available-24-gap*(#buttons-1))/#buttons))
    local height=width/4
    local start=(available-width*#buttons-gap*(#buttons-1))/2
    for i,button in ipairs(buttons) do
        local x=start+(i-1)*(width+gap)
        button:ClearAllPoints();button:SetPoint("TOPLEFT",x,(height-36)/2);button:SetSize(width,height)
        W.FitModeTab(button,width)
        button.tabX,button.tabWidth=x,width
    end
    return width
end

-- Session-only presentation of existing section/row metadata, also used by search.
function W.SectionTabs(page, order)
    if page.sectionTabs or #page.sections < 2 then return end
    local modePills=T.id=="mode" and page.modePillSections
    local sections = {}
    if order then
        for _, title in ipairs(order) do
            for _, section in ipairs(page.sections) do if section.title == title then sections[#sections+1] = section end end
        end
    else for _, section in ipairs(page.sections) do sections[#sections+1] = section end end
    assert(#sections == #page.sections, "Play The Game Tools: settings tabs must include every section.")
    local strip = CreateFrame("Frame", nil, page)
    strip:SetHeight(modePills and 40 or 34)
    if modePills then strip:SetPoint("TOPLEFT");strip:SetPoint("TOPRIGHT",-24,0) end
    -- Underline tabs rest on one baseline hairline across the strip.
    strip.baseline = W.Fill(strip, T.line, "BACKGROUND")
    strip.baseline:ClearAllPoints(); strip.baseline:SetPoint("BOTTOMLEFT", 0, 2); strip.baseline:SetPoint("BOTTOMRIGHT", 0, 2)
    strip.baseline:SetHeight(1)
    if modePills then strip.baseline:Hide() end
    local viewport = CreateFrame("ScrollFrame", nil, strip)
    viewport:SetPoint("TOPLEFT", 0, 0); viewport:SetPoint("BOTTOMRIGHT", 0, 0)
    local content = CreateFrame("Frame", nil, viewport); content:SetSize(1, modePills and 38 or 32); viewport:SetScrollChild(content)
    local left = W.Button(strip, "<", 26, 28, "secondary"); left:SetPoint("LEFT")
    local right = W.Button(strip, ">", 26, 28, "secondary"); right:SetPoint("RIGHT")
    strip.buttons, strip.sections, strip.viewport = {}, sections, viewport
    strip.previousButton, strip.nextButton = left, right
    left:Hide(); right:Hide() -- overflow remains mouse-wheel/automatic, without visible indicators
    local offset = 0
    function strip:Scroll(value)
        offset = math.max(0, math.min(self.maximum or 0, value))
        viewport:SetHorizontalScroll(offset)
        left:SetEnabled(offset > 0); right:SetEnabled(offset < (self.maximum or 0))
    end
    function strip:Layout()
        if modePills then
            -- Anchored children can still report zero while their parent is
            -- resolving size. Keep the existing hit targets until the viewport
            -- delivers its own size event, rather than saving one-pixel pills.
            local available=viewport:GetWidth()
            if available<64 then return end
            W.LayoutModePills(self.buttons,available)
            content:SetWidth(available);self.maximum=0;self:Scroll(0);return
        end
        local x = 0
        for i, section in ipairs(sections) do
            local button = self.buttons[i]
            button.label:SetWidth(0)
            local measured = button.label:GetStringWidth()
            if (issecretvalue and issecretvalue(measured)) or type(measured) ~= "number" or measured~=measured or measured<0 or measured==math.huge then measured = #section.title * 8 end
            local width = math.max(64, math.ceil(measured) + 28)
            button:ClearAllPoints(); button:SetPoint("TOPLEFT", x, 0); button:SetSize(width, 30)
            button.label:SetWidth(width-24);button.label:SetWordWrap(false)
            if T.id=="mode" and button.underline then W.AlignTextLine(button,button.underline) end
            button.tabX, button.tabWidth = x, width
            x = x + width + 4
        end
        content:SetWidth(x)
        self.maximum = math.max(0, x - viewport:GetWidth())
        self:Scroll(offset)
        for i,section in ipairs(sections) do
            if page.selectedSection==section then
                local button=self.buttons[i]
                if button.tabX<offset then self:Scroll(button.tabX)
                elseif button.tabX+button.tabWidth>offset+viewport:GetWidth() then self:Scroll(button.tabX+button.tabWidth-viewport:GetWidth()) end
            end
        end
    end
    function page:SelectSectionTab(section)
        if type(section) == "number" then section = sections[section] end
        if not section then return end
        self.selectedSection = section; section.expanded = true
        for i, item in ipairs(sections) do
            local active = item == section
            strip.buttons[i]:SetSelected(active); strip.buttons[i].underline:SetShown(active)
            if active then
                local button = strip.buttons[i]
                if button.tabX and button.tabX < offset then strip:Scroll(button.tabX)
                elseif button.tabX and button.tabX + button.tabWidth > offset + viewport:GetWidth() then
                    strip:Scroll(button.tabX + button.tabWidth - viewport:GetWidth())
                end
            end
        end
        self.scrollbar:SetValue(0)
        if self.OnSectionTabChanged then self:OnSectionTabChanged(section) end
        self:Layout()
        if addon.CloseTimerColorPicker then addon:CloseTimerColorPicker() end
        if addon.CloseFontDropdown then addon:CloseFontDropdown() end
    end
    for i, section in ipairs(sections) do
        local button = W.Button(content, section.title, 100, 30, modePills and "roundedTab" or "underline")
        if T.id=="mode" then
            button.underline=button.selectionEdge;W.AlignTextLine(button,button.underline)
        else
            button.underline = W.Fill(button, T.primary, "OVERLAY")
            button.underline:ClearAllPoints(); button.underline:SetPoint("BOTTOMLEFT", 10, 0)
            button.underline:SetPoint("BOTTOMRIGHT", -10, 0); button.underline:SetHeight(2)
        end
        button.underline:Hide()
        button:SetScript("OnClick", function() page:SelectSectionTab(section) end)
        strip.buttons[i] = button
    end
    left:SetScript("OnClick", function() strip:Scroll(offset - 160) end)
    right:SetScript("OnClick", function() strip:Scroll(offset + 160) end)
    viewport:EnableMouseWheel(true); viewport:SetScript("OnMouseWheel", function(_, delta) strip:Scroll(offset - delta * 100) end)
    strip:SetScript("OnSizeChanged", function() strip:Layout() end)
    if modePills then
        viewport:SetScript("OnSizeChanged",function() strip:Layout() end)
        strip:HookScript("OnShow",function() strip:Layout() end)
    end
    page.sectionTabs = strip
    addon.Media:RegisterFontListener(strip, function(owner) owner:Layout() end)
    strip:Layout()
    page:SelectSectionTab(1)
    if page.UpdatePreviewLayout then page:UpdatePreviewLayout() end
end
