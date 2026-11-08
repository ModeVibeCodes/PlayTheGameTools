local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme

-- The same responsive scrolling and row layout is used on every page.
function W.Page(parent, minimumWidth)
    local page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", 0, -36)
    page:SetPoint("BOTTOMRIGHT")
    page.rows, page.refreshers, page.sections, page.searchEntries, page.cursor = {}, {}, {}, {}, 0
    local scroll = CreateFrame("ScrollFrame", nil, page)
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -24, 0)
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(400, 1)
    scroll:SetScrollChild(content)
    page.content, page.scroll = content, scroll
    page.settingsScroll = scroll

    local bar = CreateFrame("Slider", nil, page)
    bar:SetPoint("TOPRIGHT", -4, -4)
    bar:SetPoint("BOTTOMRIGHT", -4, 4)
    bar:SetWidth(4)
    bar:SetOrientation("VERTICAL")
    bar:SetValueStep(24)
    W.ScrollThumb(bar, 40)
    bar:SetScript("OnValueChanged", function(_, value)
        if page.lastScrollValue~=value and addon.CloseFontDropdown then addon:CloseFontDropdown() end
        page.lastScrollValue=value;scroll:SetVerticalScroll(value)
    end)
    page.scrollbar = bar
    local function Wheel(_,delta) bar:SetValue(bar:GetValue()-delta*42) end
    scroll:SetScript("OnMouseWheel",Wheel)
    content:EnableMouseWheel(true);content:SetScript("OnMouseWheel",Wheel)
    page:EnableMouseWheel(true);page:SetScript("OnMouseWheel",Wheel)
    function page:Layout()
        local width = math.max(minimumWidth or 320, scroll:GetWidth() - 4)
        content:SetWidth(width)
        local cursor = 0
        for _, row in ipairs(self.rows) do
            row:SetWidth(width)
            if row.layoutChildren then row:layoutChildren(width) end
            local show = row.sectionHeader or not row.section or row.section.expanded
            if self.sectionTabs then show = not row.sectionHeader and (not row.section or row.section == self.selectedSection) and (not row.section or row.section.expanded) end
            if row.visibleWhen then show=show and row.visibleWhen() end
            row:SetShown(show)
            if show then
                cursor = cursor + (row.gapBefore or 0)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -cursor)
                row.offset = cursor
                cursor = cursor + row:GetHeight() + (row.gapAfter or 4)
            end
        end
        self.cursor = cursor
        content:SetHeight(cursor + 12)
        local maximum = math.max(0, content:GetHeight() - scroll:GetHeight())
        bar:SetMinMaxValues(0, maximum)
        bar:SetValue(math.min(bar:GetValue(), maximum))
        bar:SetShown(maximum > 0)
    end
    scroll:SetScript("OnSizeChanged", function() page:Layout() end)
    function page:Refresh()
        for _, refresh in ipairs(self.refreshers) do refresh() end
    end
    function page:SetSectionExpanded(section, expanded)
        section.expanded = expanded
        if expanded and self.sectionTabs then self:SelectSectionTab(section) end
        if section.button then section.button.label:SetText(expanded and "Collapse" or "Expand") end
        self:Layout()
        if addon.CloseTimerColorPicker then addon:CloseTimerColorPicker() end
        if addon.CloseFontDropdown then addon:CloseFontDropdown() end
    end
    function page:Reveal(entry)
        if entry.onReveal then entry.onReveal() end
        if entry.section then self:SetSectionExpanded(entry.section, true) end
        self:Layout()
        local row = entry.row
        if row then
            bar:SetValue(math.max(0, row.offset - 8))
            if not row.searchHighlight then row.searchHighlight = W.Fill(row, T.primary, "OVERLAY", 1, 0.08) end
            row.searchHighlight:Show()
            row.searchEpoch = (row.searchEpoch or 0) + 1
            local epoch = row.searchEpoch
            C_Timer.After(1.5, function()
                if row.searchEpoch == epoch then row.searchHighlight:Hide() end
            end)
        end
    end
    function page:Section(title, description, collapsible)
        -- Modern separates sections with more air than rows, so each group
        -- reads as one block; Blizzard keeps its tighter stock rhythm.
        local sectionGap = T.blizzardArt and 24 or 32
        if self.cursor > 0 then self.cursor = self.cursor + sectionGap end
        local header = CreateFrame("Frame", nil, content)
        header:SetPoint("TOPLEFT", 0, -self.cursor)
        header:SetSize(400, description and 62 or 36)
        self.rows[#self.rows + 1] = header
        local section = { title = title, expanded = true, header = header }
        self.sections[#self.sections + 1] = section
        self.activeSection = section
        header.section, header.sectionHeader = section, true
        header.gapBefore = #self.sections > 1 and sectionGap or 0
        self.searchEntries[#self.searchEntries + 1] = { label = title, section = section, row = header, kind = "section" }
        -- Plain heading on the canvas; rows below carry their own dividers.
        local heading = W.Heading(header, title, T.fontSize.section, 0, -8, 360, T.text)
        heading:SetPoint("TOPRIGHT", -92, -8)
        header.heading = heading
        if collapsible ~= false then
            section.button = W.Button(header, "Collapse", 76, 24, "secondary")
            section.button:SetPoint("TOPRIGHT", 0, -4)
            section.button:SetScript("OnClick", function() self:SetSectionExpanded(section, not section.expanded) end)
        end
        if description then
            local note = W.Label(header, description, nil, 0, -34, 360, T.muted)
            note:SetPoint("TOPRIGHT", -8, -34)
        end
        self.cursor = self.cursor + header:GetHeight()
        return section
    end
    function page:Row(title, height, keywords)
        height = height or 52
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("TOPLEFT", 0, -self.cursor)
        row:SetSize(400, height)
        -- Rows sit directly on the canvas, separated by a single top hairline.
        row.divider = W.Fill(row, T.line, "BORDER")
        row.divider:ClearAllPoints(); row.divider:SetPoint("TOPLEFT"); row.divider:SetPoint("TOPRIGHT")
        row.divider:SetHeight(1)
        local label = W.Label(row, title, nil, 0, -17, 172)
        label:SetWordWrap(true)
        local controls = CreateFrame("Frame", nil, row)
        controls:SetPoint("TOPLEFT", 184, -10)
        controls:SetPoint("BOTTOMRIGHT", -14, 10)
        self.rows[#self.rows + 1] = row
        row.section = self.activeSection
        row.gapAfter = 0
        self.searchEntries[#self.searchEntries + 1] = { label = title, keywords = keywords, section = self.activeSection, row = row, kind = "setting" }
        controls.row, controls.rowLabel = row, label
        self.cursor = self.cursor + height + 4
        return controls
    end
    function page:Group(title)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(400, 32)
        row.section, row.gapBefore, row.gapAfter = self.activeSection, 12, 0
        local heading=title:gsub("(%a)([%w]*)",function(first,rest) return first:upper()..rest end)
        row.subsectionHeading=W.Heading(row, heading, T.fontSize.group, 0, -10, 360, T.secondary)
        self.rows[#self.rows + 1] = row
        self.cursor = self.cursor + 42
    end
    -- Full-cell click targets and per-setting search entries; wraps to 1-3 columns.
    function page:ToggleGrid(items, options)
        local controls = self:Row("", 38)
        local row = controls.row
        controls.rowLabel:Hide()
        controls:ClearAllPoints(); controls:SetAllPoints(row)
        local cells = {}
        table.remove(self.searchEntries) -- replace the empty row metadata
        for i, item in ipairs(items) do
            local cell = CreateFrame("Button", nil, controls)
            cell:EnableMouse(true); cell:RegisterForClicks("LeftButtonUp")
            local toggle = W.Button(cell, "", 30, 30, "checkbox")
            toggle:SetPoint("TOPLEFT", -7, -6)
            local label = W.Label(cell, item.label, nil, 28, -13, 120)
            label:SetWordWrap(true)
            local function Click() item.set(not item.get()); self:Refresh() end
            cell:SetScript("OnClick", Click); toggle:SetScript("OnClick", Click)
            -- The whole cell is the hit target, so hovering it lights the box too.
            cell:HookScript("OnEnter", function() toggle.hovered = true; toggle:RefreshAppearance() end)
            cell:HookScript("OnLeave", function() toggle.hovered = false; toggle:RefreshAppearance() end)
            self.refreshers[#self.refreshers + 1] = function() toggle:SetSelected(item.get()) end
            self.searchEntries[#self.searchEntries + 1] = {label=item.label,section=self.activeSection,row=row,kind="setting"}
            cells[i] = {frame=cell,button=toggle,label=label}
        end
        function row:layoutChildren(width)
            local columns = math.max(1, math.min(options and options.maxColumns or 3, #items, math.floor(width / (options and options.minimumCellWidth or 180))))
            local cellWidth = width / columns
            self:SetHeight(math.ceil(#items / columns) * 42)
            for i, cell in ipairs(cells) do
                cell.frame:ClearAllPoints(); cell.frame:SetSize(cellWidth, 42)
                cell.frame:SetPoint("TOPLEFT", ((i-1)%columns)*cellWidth, -math.floor((i-1)/columns)*42)
                cell.label:SetWidth(cellWidth-36)
            end
        end
        self.toggleGrids = self.toggleGrids or {}; self.toggleGrids[#self.toggleGrids+1] = cells
        return cells
    end
    function page:Finish()
        content:SetHeight(self.cursor + 12)
        self:Layout()
        self:Refresh()
    end
    return page
end

