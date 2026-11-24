local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,W,T=addon.CampfireMonitor,addon.ConfigWidgets,addon.InterfaceTheme
-- Presentation routes only: every control keeps its original getter/setter.
local routes={
    enabled={"general","options"},showInCombat={"general","options"},textColor={"general","text"},
    headerGradient={"buffs","text"},headerColor={"buffs","text"},headerEndColor={"buffs","text"},
    showIcon={"monitor","options"},showText={"monitor","options"},showNearbyDetails={"monitor","options"},
    showProfessionGuide={"monitor","options"},alwaysShow={"monitor","options"},
    fontSize={"monitor","text"},
    showBenefits={"buffs","options"},separateBenefits={"buffs","options"},compactBenefits={"buffs","text"},
    colorStats={"buffs","text"},benefitsFontSize={"buffs","text"},
    showContributionPopup={"contributions","options"},
    contributionUseInterfaceFont={"contributions","text"},contributionOutline={"contributions","text"},
    contributionHeaderGradient={"contributions","text"},
}
local function Route(key)
    local route=routes[key]
    if route then return route[1],route[2] end
    if key:find("^contribution") then
        if key:find("^contributionShow") or key=="contributionTooltips" then return "contributions","options" end
        if key:find("^contributionFont") or key:find("Align$") then return "contributions","text" end
        for _,role in ipairs({"Title","Name","Info","Action","Hint","Footer","Dismiss"}) do
            if key:find("^contribution"..role) then return "contributions","text" end
        end
        return "contributions","appearance"
    end
    return key:find("^benefits") and "buffs" or "monitor","appearance"
end
function C:AddConfig(page)
    local pilot=true -- the compact one-scroll layout is shared by every theme
    local firstRow,section=#page.rows+1,page.activeSection
    local function Tag(row,key)
        if pilot then row.campfireElement,row.campfirePanel=Route(key) end
    end
    page.campfireControls={};page.campfireColors={};page.campfireSliders={}
    local A=addon.CampContributions
    local function Toggles(entries)
        local groups,order={},{}
        for _,entry in ipairs(entries) do
            local key=entry[2]
            local element,panel=Route(key)
            local id=pilot and element..":"..panel or "all"
            if not groups[id] then groups[id]={};order[#order+1]=id end
            local items=groups[id]
            items[#items+1]={label=entry[1],key=key,get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}
        end
        for _,id in ipairs(order) do
            local items=groups[id]
            local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=210})
            for i,item in ipairs(items) do page.campfireControls[item.key]=cells[i] end
            Tag(cells[1].frame:GetParent().row,items[1].key)
        end
    end
    local function Slider(label,key,suffix)
        local r=self.ranges[key]
        local row=page:Row(label,42);page.campfireSliders[key]=row
        Tag(row.row,key)
        page.refreshers[#page.refreshers+1]=W.Slider(row,r[1],r[2],r[3],
            function() return self.db[key] end,function(v)
                if addon.LootSparkles.Public(v) and type(v)=="number" and v==v and v>=r[1] and v<=r[2] then
                    local stepped=r[1]+math.floor((v-r[1])/r[3]+0.5)*r[3]
                    self:SetOption(key,stepped)
                end
            end,suffix,true)
    end
    local owner={db={appearance=self.db}}
    function owner:CanConfigure() return addon.LootSparkles:OutsideCombat() end
    function owner:SetAppearance(key,value) return C:SetOption(key,value) end
    local function Color(label,key)
        local host=pilot and page:Row(label,42) or nil
        if host then Tag(host.row,key) end
        local pick,hex,apply=W.ColorRow(page,owner,label,key,nil,host)
        page.campfireColors[key]={pick=pick,hex=hex,apply=apply,host=host}
    end
    local function Button(row,label,x,callback,width)
        local b=W.Button(row,label,width or 180,28);b:SetPoint("LEFT",x or 0,0)
        if pilot then
            row.pilotButtons=row.pilotButtons or {};row.pilotButtons[#row.pilotButtons+1]=b
            row.row.campfireButtonHost=row
        end
        b:SetScript("OnClick",function() callback();page:Refresh() end);return b
    end
    local function Note(label,text,height)
        local host=page:Row(label,height or 52)
        local text=W.Label(host,text,nil,0,-4,440,T.muted);text:SetWordWrap(true)
        if pilot then host.row.campfireNote=text;host.row.campfireNoteHost=host end
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
    Toggles({{"Enable Campfire Monitor","enabled"},{"Show In Combat","showInCombat"}})
    local status=Note("Campfire Status","",42);page.campfireStatus=status
    -- Live proximity only; hidden while it would just repeat a switch.
    status:GetParent().row.visibleWhen=function() return self.previewing or (self.owner.active and self.db.enabled) end
    local tools=page:Row("Tools",34)
    page.campfirePreview=Button(tools,"Preview",0,function() self:TogglePreview() end)
    page.campfireRefresh=Button(tools,"Refresh Status",190,function()
        if addon.LootSparkles:OutsideCombat() then self:StopPreview();self:Refresh() end
    end)
    Toggles({{"Header Gradient","headerGradient"}})
    Color("Text Color","textColor");Color("Header Color","headerColor");Color("Header Gradient End","headerEndColor")
    page.refreshers[#page.refreshers+1]=function()
        local s=self.snapshot or {}
        status:SetText(self.previewing and "Preview only." or
            ((not self.owner.active or not self.db.enabled) and "" or
            (s.nearby and "Campfire Nearby" or (s.known and "No Nearby Campfire" or "Campfire status unavailable."))))
        page.campfirePreview.label:SetText(self.previewing and "Stop Preview" or "Preview")
    end
    WindowGroup("monitor","Campfire Icon")
    Toggles({{"Show Campfire Icon","showIcon"},{"Show Status Text","showText"},
        {"Show Nearby Native Details","showNearbyDetails"},{"Show Profession Guide","showProfessionGuide"},
        {"Always Show Monitor","alwaysShow"}})
    Slider("Icon Size","iconSize");Slider("Status Text Size","fontSize");Slider("Icon Window Width","width")
    Slider("Icon Window Scale","scale","%");Slider("Icon Window Opacity","opacity","%")
    Slider("Icon Background Opacity","backgroundOpacity","%")
    WindowGroup("buffs","Camp Buffs")
    Toggles({{"Show Your Camp Benefits","showBenefits"},{"Compact Buff Text","compactBenefits"},
        {"Separate Buff Window","separateBenefits"},{"Color Stats by Type","colorStats"}})
    Slider("Buff Text Size","benefitsFontSize");Slider("Buff Window Width","benefitsWidth")
    Slider("Buff Window Scale","benefitsScale","%");Slider("Buff Window Opacity","benefitsOpacity","%")
    Slider("Buff Background Opacity","benefitsBackgroundOpacity","%")
    WindowGroup("contributions","Camp Contributions")
    Toggles({{"Show Contribution Popup","showContributionPopup"}})
    local detected=page:Row("Detected Kits",64)
    page.contributionStatus=W.Label(detected,"",nil,0,-4,280,T.muted);page.contributionStatus:SetWordWrap(true)
    page.contributionRefresh=Button(detected,"Refresh",300,function() A:RefreshDetected() end,100)
    local window=page:Row("Contribution Window",34)
    page.contributionOpen=Button(window,"Open Contributions",0,function() A:Open() end)
    page.contributionPreview=Button(window,"Preview Contributions",190,function() A:TogglePreview() end)
    Slider("Contribution Scale","contributionScale","%");Slider("Contribution Opacity","contributionOpacity","%")
    Slider("Contribution Background","contributionBackgroundOpacity","%")
    page:Group("Contribution Window Style")
    Toggles({{"Show Contribution Title","contributionShowTitle"},
        {"Show Contribution Hint","contributionShowHint"},{"Show Contribution Footer","contributionShowFooter"}})
    Slider("Contribution Width","contributionWidth");Slider("Contribution Padding","contributionPadding")
    Slider("Contribution Border Size","contributionBorderSize");Slider("Contribution Border Opacity","contributionBorderOpacity","%")
    Color("Contribution Background Color","contributionBackgroundColor");Color("Contribution Border Color","contributionBorderColor")
    page:Group("Contribution Text")
    Toggles({{"Use Interface Font","contributionUseInterfaceFont"},{"Contribution Text Outline","contributionOutline"},
        {"Contribution Title Gradient","contributionHeaderGradient"}})
    local fontOwner={db={appearance={}}}
    function fontOwner:CanConfigure() return addon.LootSparkles:OutsideCombat() end
    function fontOwner:GetFonts() return addon.Media:GetFonts() end
    function fontOwner:SetAppearance(key,value)
        C:SetOption("contributionUseInterfaceFont",false)
        return C:SetOption(key=="font" and "contributionFont" or "contributionFontMedia",value)
    end
    local font,refreshFont=W.FontDropdown(page:Row("Contribution Font"),fontOwner);page.contributionFont=font
    page.refreshers[#page.refreshers+1]=function()
        fontOwner.db.appearance.font=self.db.contributionFont;fontOwner.db.appearance.fontMedia=self.db.contributionFontMedia
        refreshFont()
        if self.db.contributionUseInterfaceFont then font.label:SetText("Interface font") end
    end
    for _,entry in ipairs({{"Title Text Size","TitleSize"},{"Kit Name Size","NameSize"},{"Profession / Count Size","InfoSize"},
        {"Place Text Size","ActionSize"},{"Hint Text Size","HintSize"},{"Footer Text Size","FooterSize"},{"Dismiss Text Size","DismissSize"}}) do Slider(entry[1],"contribution"..entry[2]) end
    for _,entry in ipairs({{"Title Color","TitleColor"},{"Title Gradient End","TitleEndColor"},{"Kit Name Color","NameColor"},
        {"Profession / Count Color","InfoColor"},{"Place Text Color","ActionColor"},{"Dismiss Text Color","DismissColor"},{"Hint Text Color","HintColor"},{"Footer Text Color","FooterColor"}}) do Color(entry[1],"contribution"..entry[2]) end
    local function Alignment(label,key)
        local row=page:Row(label,36)
        for i,value in ipairs({"LEFT","CENTER","RIGHT"}) do
            local button=Button(row,value:sub(1,1)..value:sub(2):lower(),(i-1)*96,function() self:SetOption(key,value) end,88)
            page.refreshers[#page.refreshers+1]=function() button:SetSelected(self.db[key]==value) end
        end
    end
    Alignment("Title Alignment","contributionTitleAlign");Alignment("Row Text Alignment","contributionTextAlign")
    page:Group("Contribution Icons & Rows")
    Toggles({{"Show Kit Icons","contributionShowIcons"},{"Show Kit Names","contributionShowNames"},
        {"Show Profession","contributionShowProfession"},{"Show Bag Count","contributionShowCount"},
        {"Show Place Text","contributionShowAction"},{"Contribution Tooltips","contributionTooltips"}})
    Slider("Kit Icon Size","contributionIconSize");Slider("Kit Icon Opacity","contributionIconOpacity","%")
    Slider("Contribution Row Height","contributionRowHeight");Slider("Contribution Row Spacing","contributionRowGap")
    Slider("Visible Contribution Rows","contributionVisibleRows")
    Color("Contribution Row Color","contributionRowColor");Slider("Contribution Row Opacity","contributionRowOpacity","%")
    Color("Contribution Hover Color","contributionHoverColor");Slider("Contribution Hover Opacity","contributionHoverOpacity","%")
    page.refreshers[#page.refreshers+1]=function()
        page.contributionStatus:SetText(A:Summary())
        page.contributionPreview.label:SetText(A.previewing and "Stop Preview" or "Preview Contributions")
    end
    if pilot then self:ApplyModeConfigLayout(page,firstRow,section) end
end

-- Campfire rows on the page's one scroll: each group heading (General,
-- Campfire Icon, Camp Buffs, Camp Contributions...) titles its rows, top to
-- bottom. Routes are presentation only, never saved module options.
function C:ApplyModeConfigLayout(page,firstRow,section)
    page.modeFooterLayout=true
    local labels={
        ["Campfire Status"]={"general","options"},["Tools"]={"general","options"},
        ["Detected Kits"]={"contributions","options"},["Contribution Window"]={"contributions","options"},
        ["Contribution Font"]={"contributions","text"},
        ["Title Alignment"]={"contributions","text"},["Row Text Alignment"]={"contributions","text"},
    }
    local entries={}
    for _,entry in ipairs(page.searchEntries) do
        if entry.section==section then
            entries[entry.row]=entry
            local route=labels[entry.label]
            if route then entry.row.campfireElement,entry.row.campfirePanel=route[1],route[2] end
        end
    end
    for _,color in pairs(page.campfireColors) do
        color.hex:Hide();color.apply:Hide();color.pick:SetWidth(80)
    end
    -- Pair existing size and color controls. The native picker retains color
    -- editing; redundant in-page hex/Apply controls stay hidden.
    local pairedControls={}
    for _,role in ipairs({"Title","Name","Info","Action","Hint","Footer","Dismiss"}) do
        pairedControls[#pairedControls+1]={"contribution"..role.."Size","contribution"..role.."Color"}
    end
    for _,role in ipairs({"Background","Border","Row","Hover"}) do
        pairedControls[#pairedControls+1]={"contribution"..role.."Opacity","contribution"..role.."Color"}
    end
    for _,keys in ipairs(pairedControls) do
        local size=page.campfireSliders[keys[1]]
        local color=page.campfireColors[keys[2]]
        local sizeRow,colorRow=size.row,color.host.row
        colorRow.campfireHidden=true
        color.host:SetParent(sizeRow);color.host.row=sizeRow;color.host.rowLabel=size.rowLabel
        sizeRow.campfirePairedColor=color
        for _,entry in ipairs(page.searchEntries) do if entry.row==colorRow then entry.row=sizeRow end end
        function sizeRow:layoutChildren(width)
            local wide=width>=420
            self:SetHeight(wide and 46 or 82)
            size.rowLabel:SetWidth(152)
            size:ClearAllPoints();size:SetPoint("TOPLEFT",self,"TOPLEFT",164,-10)
            size:SetSize(wide and width-264 or width-176,26)
            color.host:ClearAllPoints()
            if wide then color.host:SetPoint("TOPRIGHT",self,"TOPRIGHT",-12,-8)
            else color.host:SetPoint("TOPLEFT",self,"TOPLEFT",164,-46) end
            color.host:SetSize(80,30)
        end
    end
    for index=firstRow,#page.rows do
        local row=page.rows[index]
        local entry=entries[row]
        -- The old jump strip and element list repeat the group headings below.
        if entry and (entry.label=="Jump To" or entry.label=="Module Elements") then row.campfireHidden=true end
        row.campfireElement=row.campfireElement or "general";row.campfirePanel=row.campfirePanel or "options"
        local previous=row.visibleWhen
        -- Text and Appearance rows are styled in Layout on the matching
        -- display; it keeps the row's own visibility rule, not this page's.
        if not row.subsectionHeading and W.EditAppearancePanels[row.campfirePanel] then
            row.editAppearance={feature=row.campfireElement,panel=row.campfirePanel,campfire=true,visible=previous}
        end
        row.visibleWhen=function()
            return not row.editAppearance and not row.campfireHidden and (not previous or previous())
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
            if entry.label=="Detected Kits" or entry.label=="Title Alignment" or entry.label=="Row Text Alignment" then host=nil end
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
    -- Alignment choices stay labeled, and narrow settings windows retain all 3.
    for _,label in ipairs({"Title Alignment","Row Text Alignment"}) do
        for row,entry in pairs(entries) do if entry.label==label then
            local host=row.campfireButtonHost
            if host then
                function row:layoutChildren(width)
                    host.rowLabel:SetWidth(144)
                    host:ClearAllPoints();host:SetPoint("TOPLEFT",self,"TOPLEFT",156,-4);host:SetPoint("BOTTOMRIGHT",-8,4)
                    local cell=(width-180)/3
                    for i,button in ipairs(host.pilotButtons) do
                        button:ClearAllPoints();button:SetPoint("LEFT",(i-1)*(cell+8),0);button:SetWidth(cell)
                    end
                end
            end
        end end
    end
end
