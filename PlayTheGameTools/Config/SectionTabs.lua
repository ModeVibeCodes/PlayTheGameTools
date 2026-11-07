local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme

-- Session-only presentation of existing section/row metadata, also used by search.
function W.SectionTabs(page, order)
    if page.sectionTabs or #page.sections < 2 then return end
    local sections = {}
    if order then
        for _, title in ipairs(order) do
            for _, section in ipairs(page.sections) do if section.title == title then sections[#sections+1] = section end end
        end
    else for _, section in ipairs(page.sections) do sections[#sections+1] = section end end
    assert(#sections == #page.sections, "Play The Game Tools: settings tabs must include every section.")
    local strip = CreateFrame("Frame", nil, page)
    strip:SetHeight(34)
    -- Underline tabs rest on one baseline hairline across the strip.
    strip.baseline = W.Fill(strip, T.line, "BACKGROUND")
    strip.baseline:ClearAllPoints(); strip.baseline:SetPoint("BOTTOMLEFT", 0, 2); strip.baseline:SetPoint("BOTTOMRIGHT", 0, 2)
    strip.baseline:SetHeight(1)
    local viewport = CreateFrame("ScrollFrame", nil, strip)
    viewport:SetPoint("TOPLEFT", 0, 0); viewport:SetPoint("BOTTOMRIGHT", 0, 0)
    local content = CreateFrame("Frame", nil, viewport); content:SetSize(1, 32); viewport:SetScrollChild(content)
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
        local x = 0
        for i, section in ipairs(sections) do
            local button = self.buttons[i]
            button.label:SetWidth(0)
            local measured = button.label:GetStringWidth()
            if (issecretvalue and issecretvalue(measured)) or type(measured) ~= "number" or measured~=measured or measured<0 or measured==math.huge then measured = #section.title * 8 end
            local width = math.max(64, math.ceil(measured) + 28)
            button:ClearAllPoints(); button:SetPoint("TOPLEFT", x, 0); button:SetSize(width, 30)
            button.label:SetWidth(width-24);button.label:SetWordWrap(false)
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
        local button = W.Button(content, section.title, 100, 30, "underline")
        button.underline = W.Fill(button, T.primary, "OVERLAY")
        button.underline:ClearAllPoints(); button.underline:SetPoint("BOTTOMLEFT", 10, 0)
        button.underline:SetPoint("BOTTOMRIGHT", -10, 0); button.underline:SetHeight(2)
        button.underline:Hide()
        button:SetScript("OnClick", function() page:SelectSectionTab(section) end)
        strip.buttons[i] = button
    end
    left:SetScript("OnClick", function() strip:Scroll(offset - 160) end)
    right:SetScript("OnClick", function() strip:Scroll(offset + 160) end)
    viewport:EnableMouseWheel(true); viewport:SetScript("OnMouseWheel", function(_, delta) strip:Scroll(offset - delta * 100) end)
    strip:SetScript("OnSizeChanged", function() strip:Layout() end)
    page.sectionTabs = strip
    addon.Media:RegisterFontListener(strip, function(owner) owner:Layout() end)
    strip:Layout()
    page:SelectSectionTab(1)
    if page.UpdatePreviewLayout then page:UpdatePreviewLayout() end
end
