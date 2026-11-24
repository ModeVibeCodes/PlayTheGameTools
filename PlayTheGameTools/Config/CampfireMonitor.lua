local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,W,T=addon.CampfireMonitor,addon.ConfigWidgets,addon.InterfaceTheme
-- Its own page since the v2 split; it was the second tab of Gameplay
-- Enhancements. Leaving the page ends any preview.
function C.module:CreateConfigPage(parent)
    local page=W.Page(parent,480);self.page=page
    C:AddConfig(page)
    page:SetScript("OnHide",function() C:StopPreview() end)
    page:Finish();return page
end
-- Styling of the icon, Camp Buffs and Camp Contributions (sizes, fonts,
-- colors) lives in Layout (the Style card); the page keeps the switches.
function C:AddConfig(page)
    local firstRow,section=#page.rows+1,page.activeSection
    page.campfireControls={}
    local A=addon.CampContributions
    local function Toggles(entries)
        local items={}
        for _,entry in ipairs(entries) do
            local key=entry[2]
            items[#items+1]={label=entry[1],key=key,get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}
        end
        local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=210})
        for i,item in ipairs(items) do page.campfireControls[item.key]=cells[i] end
    end
    local function Button(row,label,x,callback,width)
        local b=W.Button(row,label,width or 180,28);b:SetPoint("LEFT",x or 0,0)
        row.pilotButtons=row.pilotButtons or {};row.pilotButtons[#row.pilotButtons+1]=b
        row.row.campfireButtonHost=row
        b:SetScript("OnClick",function() callback();page:Refresh() end);return b
    end
    local function Note(label,text,height)
        local host=page:Row(label,height or 52)
        local text=W.Label(host,text,nil,0,-4,440,T.muted);text:SetWordWrap(true)
        host.row.campfireNote=text;host.row.campfireNoteHost=host
        return text
    end
    local targets={};page.campfireJumpTargets=targets;page.campfireJumps={}
    local jump=page:Row("Jump To",36)
    jump.rowLabel:Hide();jump:ClearAllPoints();jump:SetAllPoints(jump.row)
    for i,entry in ipairs({{"monitor","Monitor"},{"buffs","Camp Buffs"},{"contributions","Contributions"}}) do
        local id=entry[1]
        page.campfireJumps[id]=Button(jump,entry[2],(i-1)*132,function()
            if targets[id] then page:Reveal(targets[id]) end
        end,124)
    end
    jump.row.layoutChildren=function(_,width)
        local cell=(width-16)/3
        for i,id in ipairs({"monitor","buffs","contributions"}) do
            local button=page.campfireJumps[id];button:SetWidth(cell);button:ClearAllPoints();button:SetPoint("LEFT",(i-1)*(cell+8),0)
        end
    end
    local function WindowGroup(id,title)
        page:Group(title);local row=page.rows[#page.rows]
        targets[id]={section=row.section,row=row}
    end
    page:Group("General")
    -- No inner Enable switch: the module switch is the switch.
    Toggles({{"Show In Combat","showInCombat"}})
    local status=Note("Campfire Status","",42);page.campfireStatus=status
    -- Live proximity only; hidden while it would just repeat a switch.
    status:GetParent().row.visibleWhen=function() return self.previewing or self.owner.active end
    local tools=page:Row("Tools",34)
    page.campfirePreview=Button(tools,"Preview",0,function() self:TogglePreview() end)
    page.campfireRefresh=Button(tools,"Refresh Status",190,function()
        if addon.LootSparkles:OutsideCombat() then self:StopPreview();self:Refresh() end
    end)
    page.refreshers[#page.refreshers+1]=function()
        local s=self.snapshot or {}
        status:SetText(self.previewing and "Preview only." or
            (not self.owner.active and "" or
            (s.nearby and "Campfire Nearby" or (s.known and "No Nearby Campfire" or "Campfire status unavailable."))))
        page.campfirePreview.label:SetText(self.previewing and "Stop Preview" or "Preview")
    end
    WindowGroup("monitor","Campfire Icon")
    Toggles({{"Show Campfire Icon","showIcon"},{"Show Status Text","showText"},
        {"Show Nearby Native Details","showNearbyDetails"},{"Show Profession Guide","showProfessionGuide"},
        {"Always Show Monitor","alwaysShow"}})
    WindowGroup("buffs","Camp Buffs")
    Toggles({{"Show Your Camp Benefits","showBenefits"},{"Separate Buff Window","separateBenefits"}})
    WindowGroup("contributions","Camp Contributions")
    Toggles({{"Show Contribution Popup","showContributionPopup"}})
    local detected=page:Row("Detected Kits",64)
    page.contributionStatus=W.Label(detected,"",nil,0,-4,280,T.muted);page.contributionStatus:SetWordWrap(true)
    page.contributionRefresh=Button(detected,"Refresh",300,function() A:RefreshDetected() end,100)
    local window=page:Row("Contribution Window",34)
    page.contributionOpen=Button(window,"Open Contributions",0,function() A:Open() end)
    page.contributionPreview=Button(window,"Preview Contributions",190,function() A:TogglePreview() end)
    page:Group("Contribution Window Style")
    Toggles({{"Show Contribution Title","contributionShowTitle"},
        {"Show Contribution Hint","contributionShowHint"},{"Show Contribution Footer","contributionShowFooter"}})
    page:Group("Contribution Icons & Rows")
    Toggles({{"Show Kit Icons","contributionShowIcons"},{"Show Kit Names","contributionShowNames"},
        {"Show Profession","contributionShowProfession"},{"Show Bag Count","contributionShowCount"},
        {"Show Place Text","contributionShowAction"},{"Contribution Tooltips","contributionTooltips"}})
    page.refreshers[#page.refreshers+1]=function()
        page.contributionStatus:SetText(A:Summary())
        page.contributionPreview.label:SetText(A.previewing and "Stop Preview" or "Preview Contributions")
    end
    self:ApplyModeConfigLayout(page,firstRow,section)
end

-- Campfire rows on the page's one scroll: each group heading (General,
-- Campfire Icon, Camp Buffs, Camp Contributions...) titles its rows, top to
-- bottom.
function C:ApplyModeConfigLayout(page,firstRow,section)
    page.modeFooterLayout=true
    local entries={}
    for _,entry in ipairs(page.searchEntries) do
        if entry.section==section then entries[entry.row]=entry end
    end
    for index=firstRow,#page.rows do
        local row=page.rows[index]
        local entry=entries[row]
        -- The old jump strip repeats the group headings below.
        if entry and entry.label=="Jump To" then row.campfireHidden=true end
        local previous=row.visibleWhen
        row.visibleWhen=function()
            return not row.campfireHidden and (not previous or previous())
        end
        -- Shorter form rhythm; preserve the underlying row/setting labels.
        if not row.subsectionHeading then row.gapBefore=0;row.gapAfter=2 end
        if row.divider then row.divider:Hide() end
    end
    for index=#page.searchEntries,1,-1 do
        local entry=page.searchEntries[index]
        if entry.section==section and entry.row.campfireHidden then table.remove(page.searchEntries,index) end
    end
    -- Action strips use the full row, avoiding side-by-side button clipping.
    for index=firstRow,#page.rows do
        local row=page.rows[index]
        local entry=entries[row]
        if entry and entry.label~="Jump To" then
            local host=row.campfireButtonHost
            if entry.label=="Detected Kits" then host=nil end
            if host then
                host.rowLabel:Hide();host:ClearAllPoints();host:SetAllPoints(row)
                function row:layoutChildren(width)
                    local gap=8;local count=#host.pilotButtons
                    local cell=math.min(190,(width-(count-1)*gap)/count)
                    for i,button in ipairs(host.pilotButtons) do
                        button:ClearAllPoints();button:SetPoint("LEFT",(i-1)*(cell+gap),0);button:SetWidth(cell)
                        button.label:SetWidth(cell-20);button.label:SetWordWrap(false)
                    end
                end
            end
            if row.campfireNote then
                local note=row.campfireNote
                local host=row.campfireNoteHost
                host.rowLabel:Hide();host:ClearAllPoints();host:SetAllPoints(row)
                note:ClearAllPoints();note:SetPoint("TOPLEFT",0,-4);note:SetPoint("TOPRIGHT",-4,-4)
                note:SetTextColor(unpack(T.muted))
            end
        end
    end
    -- Responsive detected-kit summary and its original Refresh action.
    local detected=page.contributionRefresh:GetParent()
    function detected.row:layoutChildren(width)
        detected.rowLabel:SetWidth(144)
        detected:ClearAllPoints();detected:SetPoint("TOPLEFT",self,"TOPLEFT",156,-8);detected:SetPoint("BOTTOMRIGHT",-8,8)
        page.contributionStatus:SetWidth(math.max(140,width-284))
        page.contributionRefresh:ClearAllPoints();page.contributionRefresh:SetPoint("RIGHT",0,0)
    end
end
