local _,addon=...
local W,T=addon.ConfigWidgets,addon.InterfaceTheme
local panels={{"options","Options"},{"text","Text"},{"appearance","Appearance"},{"position","Position"}}

local function Measure(label)
    local width=label:GetStringWidth()
    if (issecretvalue and issecretvalue(width)) or type(width)~="number" or width~=width or width<0 or width==math.huge then width=#(label:GetText() or "")*11 end
    return math.max(1,math.ceil(width))
end

function W.ModeFooterCaption(page,note)
    local row=CreateFrame("Frame",nil,page.content)
    note=note or W.Label(row,"",nil,0,0,400,T.muted)
    note:SetParent(row);row.settingsFooterNote=note
    page.modeFooterRows=page.modeFooterRows or {};page.modeFooterRows[#page.modeFooterRows+1]=row
    page.modeFooterLayout=true
    return row,note
end

-- Dungeon Loot keeps its pooled, navigable catalog. Only its General settings
-- get compact panels; recycled rows carry the panel of their current content.
function W.SetupModeBrowser(page,root)
    local state={panel="options",buttons={}};page.modeBrowser=state
    local strip=CreateFrame("ScrollFrame",nil,page);strip:SetHeight(34)
    strip:SetPoint("TOPLEFT",0,-44);strip:SetPoint("TOPRIGHT",0,-44)
    local content=CreateFrame("Frame",nil,strip);content:SetSize(600,42);strip:SetScrollChild(content)
    state.viewport,state.content=strip,content
    local rule=W.Fill(page,T.line,"BACKGROUND");rule:ClearAllPoints();rule:SetPoint("TOPLEFT",0,-78);rule:SetPoint("TOPRIGHT",0,-78);rule:SetHeight(1)
    local header=CreateFrame("Frame",nil,page);header:SetPoint("TOPLEFT",12,-88);header:SetPoint("TOPRIGHT",-12,-88);header:SetHeight(38)
    local heading=W.Heading(header,"Options",20,0,0,100,T.text)
    local separator=W.Label(header,"·",nil,0,0,8,T.muted);addon.Media:BindInterfaceFont(separator,GameFontHighlight,14)
    separator:ClearAllPoints();separator:SetPoint("LEFT",heading,"RIGHT",8,0)
    local description=W.Label(header,"",nil,0,0,300,T.muted);description:ClearAllPoints();description:SetPoint("LEFT",separator,"RIGHT",8,0)
    local footer=W.ModeFooterCaption(root,description)
    footer.visibleWhen=function() return addon.DungeonLoot.active and addon.DungeonLoot.view.tab=="general" end
    separator:Hide()
    local _,align=W.ModeHeadingRule(header,heading)
    local choices={{"options","Options","Show the shortcut icon or choose its keybinding."},{"appearance","Appearance","Adjust the shortcut icon size and opacity."},
        {"position","Position","Move or reset the shortcut icon."},{"data","Data","Review and refresh the bundled dungeon data."}}
    function page:SelectModeBrowserPanel(panel) state.panel=panel;root.scrollbar:SetValue(0);self:Layout() end
    for _,entry in ipairs(choices) do
        local panel=entry[1];local button=W.Button(content,entry[2],112,30,"subTab");state.buttons[#state.buttons+1]=button
        button:SetScript("OnClick",function() page:SelectModeBrowserPanel(panel) end)
    end
    function root:ModeRowVisible(row,original)
        return original and (addon.DungeonLoot.view.tab~="general" or not row.settingsBrowserPanel or row.settingsBrowserPanel==state.panel)
    end
    function page:LayoutModeBrowser()
        local active=addon.DungeonLoot.active and addon.DungeonLoot.view.tab=="general"
        strip:SetShown(active);rule:SetShown(active);header:SetShown(active)
        local width=math.max(1,self:GetWidth());content:SetWidth(width)
        local cell=math.min(112,math.max(1,(width-18)/4))
        for i,entry in ipairs(choices) do
            local button=state.buttons[i];local selected=state.panel==entry[1]
            button:ClearAllPoints();button:SetPoint("TOPLEFT",(i-1)*(cell+6),selected and -4 or -12);button:SetSize(cell,30);button:SetSelected(selected)
            button.label:ClearAllPoints();button.label:SetPoint("CENTER",0,selected and 0 or 4);button.label:SetWidth(math.max(1,cell-16));button.label:SetWordWrap(false)
            if selected then heading:SetText(entry[2]);description:SetText(entry[3]) end
        end
        heading:SetWidth(Measure(heading));align()
        return active
    end
end
function W.ModeHeadingRule(parent,heading)
    local line=parent:CreateTexture(nil,"ARTWORK");line.modeAsset="ModeHeaderLine";W.Paint(line,T.line,0.7)
    line:SetHeight(1)
    local function Align()
        local width=math.min(heading:GetWidth(),Measure(heading))
        line:ClearAllPoints();line:SetPoint("TOPLEFT",heading,"BOTTOMLEFT",0,-4);line:SetWidth(width)
    end
    Align();return line,Align
end

local function CompactColors(page)
    for _,color in ipairs(page.settingsColors or {}) do
        color.hex:Hide();if color.apply then color.apply:Hide() end
        color.pick:SetWidth(80)
    end
end

local function PairColors(page)
    local candidates={
        textColor={"Font Size","Name Font Size","Food Font Size","Bar Text Size"},
        sessionTextColor={"Session Text Size"},
        backgroundColor={"Background opacity","Background Opacity","Food Background Opacity"},
        borderColor={"Border Opacity","Food Border Opacity"},
    }
    for _,color in ipairs(page.settingsColors or {}) do
        local original=color.host.row;local route=original.modeRoute
        if route and original.settingsHost==color.host then
            for _,title in ipairs(candidates[color.key] or {}) do
                local paired
                for _,row in ipairs(page.rows) do
                    local target=row.modeRoute
                    if row.settingsTitle==title and target and target.feature==route.feature and target.panel==route.panel and row.settingsHost.slider and not row.layoutChildren then
                        paired=row;break
                    end
                end
                if paired then
                    original.modePaired=true;color.host:SetParent(paired);color.host.row=paired;color.host.rowLabel=paired.settingsLabel
                    paired.modePairedColor=color
                    local host=paired.settingsHost
                    function paired:layoutChildren(width)
                        local wide=width>=420;self:SetHeight(wide and 46 or 82)
                        self.settingsLabel:SetWidth(152)
                        host:ClearAllPoints();host:SetPoint("TOPLEFT",self,"TOPLEFT",164,-10);host:SetSize(math.max(1,width-(wide and 264 or 176)),26)
                        color.host:ClearAllPoints();color.host:SetSize(80,30)
                        if wide then color.host:SetPoint("TOPRIGHT",self,"TOPRIGHT",-12,-8)
                        else color.host:SetPoint("TOPLEFT",self,"TOPLEFT",164,-46) end
                    end
                    for _,entry in ipairs(page.searchEntries) do if entry.row==original then entry.row=paired end end
                    break
                end
            end
        end
    end
end

-- Existing rows, controls, callbacks, search entries and visibility predicates
-- remain the owners of their behavior. This layer only routes and lays them out.
function W.ApplyModeModuleLayout(page,id)
    if T.id~="mode" or page.modeLayout then return end
    local plan=W.ModeLayoutPlans[id]
    if not plan then return end
    CompactColors(page)
    local state={plan=plan,features=plan.features or {},routes={},buttons={},panels={},groups={},last={}}
    page.modeLayout=state
    if plan.decorateOnly then
        for _,row in ipairs(page.rows) do
            local heading=row.subsectionHeading or (row.sectionHeader and row.heading)
            if heading then
                addon.Media:BindInterfaceFont(heading,GameFontNormalLarge,20,nil,"heading")
                local _,align=W.ModeHeadingRule(row,heading);row:HookScript("OnSizeChanged",align)
            end
        end
        return
    end
    if plan.preserveSections then
        local previousTabs=page.sectionTabs
        W.SectionTabs(page)
        if page.sectionTabs and not previousTabs then page.sectionTabs:SetPoint("TOPLEFT");page.sectionTabs:SetPoint("TOPRIGHT",-24,0) end
        for _,section in ipairs(page.sections) do state.features[#state.features+1]={section.title,section.title} end
    elseif page.sectionTabs then page.sectionTabs:Hide() end
    for _,row in ipairs(page.rows) do
        local feature,panel
        if plan.route then feature,panel=plan.route(row) end
        if feature then
            row.modeRoute={feature=feature,panel=panel or "options"};state.routes[row]=row.modeRoute
            if row.divider then row.divider:Hide() end
            row.gapBefore=0;row.gapAfter=2
            if row.settingsStandaloneToggle and not row.settingsToggles then
                local host=row.settingsHost;local button=row.settingsStandaloneToggle
                row.settingsLabel:Hide();host:ClearAllPoints();host:SetAllPoints(row)
                local cell=CreateFrame("Button",nil,host);cell:EnableMouse(true);cell:RegisterForClicks("LeftButtonUp")
                local label=W.Label(cell,row.settingsTitle,nil,28,-13,136,T.secondary);label:SetWordWrap(true)
                button:SetParent(cell);button:ClearAllPoints();button:SetPoint("TOPLEFT",-7,-6)
                cell:SetScript("OnClick",function() local click=button:GetScript("OnClick");if button:IsEnabled() and click then click(button) end end)
                cell:HookScript("OnEnter",function() button.hovered=true;button:RefreshAppearance() end)
                cell:HookScript("OnLeave",function() button.hovered=false;button:RefreshAppearance() end)
                row.settingsToggles={{frame=cell,button=button,label=label}}
                function row:layoutChildren(width) self:SetHeight(42);cell:ClearAllPoints();cell:SetPoint("TOPLEFT");cell:SetSize(width,42);label:SetWidth(math.max(1,width-36)) end
            end
            if row.settingsTitle and row.settingsTitle~="" and not row.layoutChildren and row:GetHeight()<=52 then row:SetHeight(math.min(row:GetHeight(),48)) end
            if row.settingsToggles then
                local host=CreateFrame("Frame",nil,page.content);host:Hide()
                state.groups[#state.groups+1]={row=row,host=host,original=row.settingsHost,cells=row.settingsToggles}
            end
        end
    end
    PairColors(page)
    state.feature=state.features[1] and state.features[1][1];state.panel="options"
    local bar=CreateFrame("Frame",nil,page);state.bar=bar;bar:SetHeight(78)
    local viewport=CreateFrame("ScrollFrame",nil,bar);state.panelViewport=viewport
    viewport:SetHeight(34)
    local tabContent=CreateFrame("Frame",nil,viewport);tabContent:SetSize(600,42);viewport:SetScrollChild(tabContent);state.panelContent=tabContent
    local rule=W.Fill(bar,T.line,"BACKGROUND");rule:ClearAllPoints();rule:SetPoint("BOTTOMLEFT");rule:SetPoint("BOTTOMRIGHT");rule:SetHeight(1);state.rule=rule
    local header=CreateFrame("Frame",nil,page.content);header:SetHeight(40);state.header=header
    state.heading=W.Heading(header,"Options",20,0,0,100,T.text)
    state.separator=W.Label(header,"·",nil,0,0,8,T.muted)
    addon.Media:BindInterfaceFont(state.separator,GameFontHighlight,14)
    state.separator:ClearAllPoints();state.separator:SetPoint("LEFT",state.heading,"RIGHT",8,0)
    state.description=W.Label(header,"",nil,0,0,300,T.muted)
    state.description:ClearAllPoints();state.description:SetPoint("LEFT",state.separator,"RIGHT",8,0);state.description:SetWordWrap(true)
    state.underline,state.alignUnderline=W.ModeHeadingRule(header,state.heading)
    state.footer=W.ModeFooterCaption(page,state.description)
    state.footer.visibleWhen=function() return state.footerShown end
    local function Available(feature,panel)
        for row,route in pairs(state.routes) do
            if route.feature==feature and route.panel==panel and not row.sectionHeader and not row.subsectionHeading then return true end
        end
        return false
    end
    state.available=Available
    function page:SelectModePanel(feature,panel)
        feature=feature or state.feature
        state.last[state.feature]=state.panel
        if plan.preserveSections then
            for _,section in ipairs(self.sections) do
                if section.title==feature and section~=self.selectedSection then self:SelectSectionTab(section) end
            end
            if self.selectedSection then feature=self.selectedSection.title end
        end
        state.feature=feature;state.panel=panel or state.last[feature] or "options"
        if not Available(feature,state.panel) then
            for _,entry in ipairs(panels) do if Available(feature,entry[1]) then state.panel=entry[1];break end end
        end
        if plan.select then plan.select(self,feature) end
        state.last[feature]=state.panel
        self.scrollbar:SetValue(0)
        addon:CloseTimerColorPicker();if addon.CloseFontDropdown then addon:CloseFontDropdown() end
        self:Layout()
    end
    if not plan.preserveSections then
        for _,entry in ipairs(state.features) do
            local feature=entry[1]
            local button=W.Button(bar,entry[2],120,36,"roundedTab");state.buttons[#state.buttons+1]=button
            button:SetScript("OnClick",function() page:SelectModePanel(feature) end)
        end
    end
    if id=="foreverRogue" then
        for i,button in ipairs(page.displayButtons) do
            local feature=i==1 and "watchStyle" or "launcherStyle"
            button:HookScript("OnClick",function() if button:IsEnabled() then page:SelectModePanel(feature,"appearance") end end)
        end
    end
    for _,entry in ipairs(panels) do
        local panel=entry[1]
        local button=W.Button(tabContent,entry[2],112,30,"subTab");state.panels[panel]=button
        button:SetScript("OnClick",function() page:SelectModePanel(nil,panel) end)
    end
    local originalVisible=page.ModeRowVisible
    function page:ModeRowVisible(row,original)
        local route=row.modeRoute
        if route then
            return not row.sectionHeader and not row.subsectionHeading and not row.modeSide and not row.modeReplacedNavigation and not row.modePaired and route.feature==state.feature and route.panel==state.panel
        end
        if originalVisible then return originalVisible(self,row,original) end
        return original
    end
    -- Search continues to reveal the original setting and runs existing gates.
    for _,entry in ipairs(page.searchEntries) do
        local route=entry.row.modeRoute
        if route then
            local reveal=entry.onReveal
            entry.onReveal=function()
                if reveal then reveal() end
                page:SelectModePanel(route.feature,route.panel)
            end
        end
    end
    local oldExpand=page.SetSectionExpanded
    function page:SetSectionExpanded(section,expanded)
        if not plan.preserveSections then
            section.expanded=expanded;self:Layout()
        else oldExpand(self,section,expanded) end
    end
    local oldPanel=page.LayoutSectionPanel
    function page:LayoutSectionPanel(top)
        if oldPanel then top=oldPanel(self,top) end
        state.previewTop=top
        return top -- Layout below owns its own viewport offsets.
    end
    local layout=page.Layout
    function page:Layout()
        if state.layingOut then return end
        state.layingOut=true
        if plan.preserveSections and self.selectedSection then
            local feature=self.selectedSection.title
            if feature~=state.feature then state.last[state.feature]=state.panel;state.feature=feature;state.panel=state.last[feature] or "options" end
            if not Available(feature,state.panel) then
                for _,entry in ipairs(panels) do if Available(feature,entry[1]) then state.panel=entry[1];break end end
            end
        end
        local hasSettings=false;local panelCount=0
        for _,entry in ipairs(panels) do
            local available=Available(state.feature,entry[1]);state.panels[entry[1]]:SetShown(available)
            if available then hasSettings=true;panelCount=panelCount+1 end
        end
        local dataHeader=plan.preserveSections and not hasSettings and not self.campfirePilot
        local top
        if self.previewArea then top=(state.previewTop or 46)-(not plan.preserveSections and self.sectionTabs and 40 or 0)
        else top=plan.preserveSections and 40 or 0 end
        local owned=not self.campfirePilot or (self.selectedSection and self.selectedSection.title=="Loot Sparkles")
        if not owned then state.viewportTop=nil end
        local mainHeight=not plan.preserveSections and #state.features>1 and 44 or 0
        local barHeight=hasSettings and mainHeight+(panelCount>1 and 34 or 0)+8 or 0
        bar:SetShown(owned and barHeight>0)
        if state.barTop~=top then
            state.barTop=top
            bar:ClearAllPoints();bar:SetPoint("TOPLEFT",0,-top);bar:SetPoint("TOPRIGHT",-24,-top)
        end
        if bar:GetHeight()~=math.max(1,barHeight) then bar:SetHeight(math.max(1,barHeight)) end
        local width=bar:GetWidth()
        if width<64 then width=state.tabWidth or math.max(480,self.scroll:GetWidth())
        else state.tabWidth=width end
        W.LayoutModePills(state.buttons,width)
        for i,button in ipairs(state.buttons) do
            button:SetShown(mainHeight>0)
            button:SetSelected(state.features[i][1]==state.feature)
        end
        viewport:ClearAllPoints();viewport:SetPoint("TOPLEFT",0,-mainHeight);viewport:SetPoint("TOPRIGHT",0,-mainHeight)
        viewport:SetShown(panelCount>1);tabContent:SetWidth(width)
        local x=0;local tabWidth=math.min(112,math.max(1,(width-6*math.max(0,panelCount-1))/math.max(1,panelCount)))
        for _,entry in ipairs(panels) do
            local button=state.panels[entry[1]];local active=state.panel==entry[1]
            button:SetShown(panelCount>1 and Available(state.feature,entry[1]));button:SetSelected(active)
            if Available(state.feature,entry[1]) then
                button:ClearAllPoints();button:SetPoint("TOPLEFT",x,active and -4 or -12);button:SetSize(tabWidth,30)
                button.label:ClearAllPoints();button.label:SetPoint("CENTER",0,active and 0 or 4);button.label:SetWidth(math.max(1,tabWidth-16));button.label:SetWordWrap(false)
                x=x+tabWidth+6
            end
        end
        rule:ClearAllPoints();rule:SetPoint("TOPLEFT",0,-mainHeight-(panelCount>1 and 34 or 0));rule:SetPoint("TOPRIGHT",0,-mainHeight-(panelCount>1 and 34 or 0))
        rule:SetShown(panelCount>1)
        header:SetShown(owned and (hasSettings or dataHeader))
        local sliderCount,toggleCount=0,0
        for row,route in pairs(state.routes) do
            local active=route.feature==state.feature and route.panel==state.panel and (not row.visibleWhen or row.visibleWhen())
            if active and row.settingsHasSlider then sliderCount=sliderCount+1 end
            if active and row.settingsToggles then toggleCount=toggleCount+#row.settingsToggles end
        end
        local wide=self.scroll:GetWidth()>=800
        local mixed=owned and hasSettings and wide and sliderCount>0 and toggleCount>0
        local summary=owned and hasSettings and wide and not mixed and state.feature~="general" and state.feature~="General"
        local leftY=42
        for _,group in ipairs(state.groups) do
            local row=group.row;local route=row.modeRoute
            local move=mixed and route.feature==state.feature and route.panel==state.panel and (not row.visibleWhen or row.visibleWhen())
            row.modeSide=move;group.host:SetShown(move)
            for _,cell in ipairs(group.cells) do if cell.frame:GetParent()~=(move and group.host or group.original) then cell.frame:SetParent(move and group.host or group.original) end end
            if move then
                group.host:ClearAllPoints();group.host:SetPoint("TOPLEFT",self.contentInset,-leftY);group.host:SetSize(172,#group.cells*42);group.host.offset=leftY
                for i,cell in ipairs(group.cells) do
                    cell.frame:ClearAllPoints();cell.frame:SetPoint("TOPLEFT",0,-(i-1)*42);cell.frame:SetSize(172,42);cell.label:SetWidth(136)
                end
                leftY=leftY+#group.cells*42
            end
        end
        if owned then
            self.layoutInsetLeft=(mixed or summary) and 188 or 0
            self.layoutTopInset=summary and 0 or ((hasSettings or dataHeader) and 36 or 0)
            self.layoutMinHeight=mixed and leftY+12 or (summary and 112 or 0)
            local viewportTop=top+barHeight
            if state.viewportTop~=viewportTop then
                state.viewportTop=viewportTop
                self.scroll:ClearAllPoints();self.scroll:SetPoint("TOPLEFT",0,-viewportTop);self.scroll:SetPoint("BOTTOMRIGHT",-24,0)
                self.scrollbar:ClearAllPoints();self.scrollbar:SetPoint("TOPRIGHT",-4,-viewportTop-4);self.scrollbar:SetPoint("BOTTOMRIGHT",-4,4)
            end
        end
        header:ClearAllPoints();header:SetPoint("TOPLEFT",self.contentInset,-4);header:SetWidth(summary and 172 or math.max(1,self.scroll:GetWidth()-self.contentInset*2-4))
        local title="Options";for _,entry in ipairs(panels) do if entry[1]==state.panel then title=entry[2] end end
        if dataHeader then title=state.feature end
        state.heading:SetText(title);state.heading:SetWidth(Measure(state.heading));state.alignUnderline()
        state.separator:Hide()
        state.footerShown=owned and (hasSettings or dataHeader)
        state.description:SetText(dataHeader and "Browse the current information below." or W.ModePanelDescriptions[state.panel]);state.mixed=mixed
        layout(self)
        for _,group in ipairs(state.groups) do
            if group.row.modeSide then
                for i,cell in ipairs(group.cells) do
                    cell.frame:ClearAllPoints();cell.frame:SetPoint("TOPLEFT",0,-(i-1)*42);cell.frame:SetSize(172,42);cell.label:SetWidth(136)
                end
            end
        end
        -- Search highlights the host that is actually visible after a gutter move.
        for _,entry in ipairs(self.searchEntries) do
            local base=entry.modeBaseRow or entry.row;entry.modeBaseRow=base
            if base.modeRoute and base.modeSide then
                for _,group in ipairs(state.groups) do if group.row==base then entry.row=group.host end end
            elseif base.modeRoute then entry.row=base end
        end
        state.layingOut=false
    end
    bar:SetScript("OnSizeChanged",function() page:Layout() end)
    addon.Media:RegisterFontListener(bar,function() page:Layout() end)
    page:SelectModePanel(state.feature,"options")
    if page.UpdatePreviewLayout then page:UpdatePreviewLayout() end
end
