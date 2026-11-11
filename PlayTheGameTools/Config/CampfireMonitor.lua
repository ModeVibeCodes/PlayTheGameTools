local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,W,T=addon.CampfireMonitor,addon.ConfigWidgets,addon.InterfaceTheme
-- Presentation routes only: every control keeps its original getter/setter.
local routes={
    enabled={"general","options"},showInCombat={"general","options"},textColor={"general","text"},
    headerGradient={"buffs","text"},headerColor={"buffs","text"},headerEndColor={"buffs","text"},
    showIcon={"monitor","options"},showText={"monitor","options"},showNearbyDetails={"monitor","options"},
    showProfessionGuide={"monitor","options"},alwaysShow={"monitor","options"},locked={"monitor","position"},
    fontSize={"monitor","text"},x={"monitor","position"},y={"monitor","position"},
    showBenefits={"buffs","options"},separateBenefits={"buffs","options"},compactBenefits={"buffs","text"},
    colorStats={"buffs","text"},benefitsLocked={"buffs","position"},benefitsX={"buffs","position"},
    benefitsY={"buffs","position"},benefitsFontSize={"buffs","text"},
    showContributionPopup={"contributions","options"},contributionLocked={"contributions","position"},
    contributionX={"contributions","position"},contributionY={"contributions","position"},
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
    local pilot=T.id=="mode"
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
        if label=="Shared Style" or label=="Buffs TLDR" then page:FooterNote(text) end
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
    Note("Module Elements","Nearby-fire monitor, earned Camp Buffs, and profession contributions.",42)
    local function WindowGroup(id,title)
        page:Group(title);local row=page.rows[#page.rows]
        targets[id]={section=row.section,row=row}
    end
    page:Group("General")
    Toggles({{"Enable Campfire Monitor","enabled"},{"Show In Combat","showInCombat"}})
    local status=Note("Campfire Status","",42);page.campfireStatus=status
    local tools=page:Row("Tools",34)
    page.campfireEdit=Button(tools,"Open Edit Mode",0,function()
        if self.active and addon.LootSparkles:OutsideCombat() then
            addon:SetEditMode(true);addon.PositionManager:SelectElement("campfireMonitor")
        end
    end)
    page.campfireRefresh=Button(tools,"Refresh Status",190,function()
        if addon.LootSparkles:OutsideCombat() then self:StopPreview();self:Refresh() end
    end)
    local placement=page:Row("Preview & Placement",34)
    page.campfirePreview=Button(placement,"Preview",0,function() self:TogglePreview() end)
    page.campfireMove=Button(placement,"Move Windows",190,function() self:SetPlacementMode(not self.placing) end)
    Toggles({{"Header Gradient","headerGradient"}})
    Color("Text Color","textColor");Color("Header Color","headerColor");Color("Header Gradient End","headerEndColor")
    Note("Shared Style","Text Color is shared by status and untyped stats. Header colors apply to Camp Buffs; Contributions has its own style. Pick opens the color wheel.")
    page.refreshers[#page.refreshers+1]=function()
        local s=self.snapshot or {}
        status:SetText(self.previewing and "Preview only." or
            (not self.owner.active and "Enable Gameplay Enhancements using its header toggle." or
            (not self.db.enabled and "Campfire Monitor disabled." or
            (s.nearby and "Campfire Nearby" or (s.known and "No Nearby Campfire" or "Campfire status unavailable.")))))
        page.campfirePreview.label:SetText(self.previewing and "Stop Preview" or "Preview")
        page.campfireMove.label:SetText(self.placing and "Finish Moving" or "Move Windows")
    end
    WindowGroup("monitor","Campfire Icon")
    Toggles({{"Show Campfire Icon","showIcon"},{"Show Status Text","showText"},
        {"Show Nearby Native Details","showNearbyDetails"},{"Show Profession Guide","showProfessionGuide"},
        {"Always Show Monitor","alwaysShow"},{"Lock Campfire Monitor","locked"}})
    Slider("Icon Size","iconSize");Slider("Status Text Size","fontSize");Slider("Icon Window Width","width")
    Slider("Icon Window Scale","scale","%");Slider("Icon Window Opacity","opacity","%")
    Slider("Icon Background Opacity","backgroundOpacity","%")
    Slider("Icon Horizontal Offset","x");Slider("Icon Vertical Offset","y")
    page.campfireReset=Button(page:Row("Icon Position",34),"Reset Position",0,function()
        if addon.LootSparkles:OutsideCombat() then self:ResetWindowPosition(false) end
    end)
    WindowGroup("buffs","Camp Buffs")
    Toggles({{"Show Your Camp Benefits","showBenefits"},{"Compact Buff Text","compactBenefits"},
        {"Separate Buff Window","separateBenefits"},{"Lock Buff Window","benefitsLocked"},{"Color Stats by Type","colorStats"}})
    Slider("Buff Text Size","benefitsFontSize");Slider("Buff Window Width","benefitsWidth")
    Slider("Buff Window Scale","benefitsScale","%");Slider("Buff Window Opacity","benefitsOpacity","%")
    Slider("Buff Background Opacity","benefitsBackgroundOpacity","%")
    Slider("Buff Horizontal Offset","benefitsX");Slider("Buff Vertical Offset","benefitsY")
    page.campfireBuffReset=Button(page:Row("Buff Position",34),"Reset Buff Position",0,function()
        if addon.LootSparkles:OutsideCombat() then self:ResetWindowPosition(true) end
    end)
    Note("Buffs TLDR","Detach for independent size, background and position. Joined buffs share the icon window. Duration comes from the native tooltip; no added countdown.")
    WindowGroup("contributions","Camp Contributions")
    Toggles({{"Show Contribution Popup","showContributionPopup"}})
    local detected=page:Row("Detected Kits",64)
    page.contributionStatus=W.Label(detected,"",nil,0,-4,280,T.muted);page.contributionStatus:SetWordWrap(true)
    page.contributionRefresh=Button(detected,"Refresh",300,function() A:RefreshDetected() end,100)
    local window=page:Row("Contribution Window",34)
    page.contributionOpen=Button(window,"Open Contributions",0,function() A:Open() end)
    page.contributionPreview=Button(window,"Preview Contributions",190,function() A:TogglePreview() end)
    local position=page:Row("Contribution Position",34)
    page.contributionEdit=Button(position,"Edit Contributions",0,function()
        if A.active and addon.LootSparkles:OutsideCombat() then
            addon:SetEditMode(true);addon.PositionManager:SelectElement("campfireContributions")
        end
    end)
    page.contributionReset=Button(position,"Reset Position",190,function()
        if addon.LootSparkles:OutsideCombat() then
            if addon.PositionManager.elements.campfireContributions then
                addon.PositionManager:SetPosition("campfireContributions",{target="screen",placement="center",x=0,y=120})
            else self.db.contributionX=0;self.db.contributionY=120 end
            A.positionFailure=nil;A:OnSnapshot(self.snapshot)
        end
    end)
    Slider("Contribution Scale","contributionScale","%");Slider("Contribution Opacity","contributionOpacity","%")
    Slider("Contribution Background","contributionBackgroundOpacity","%")
    page:Group("Contribution Window Style")
    Toggles({{"Lock Contribution Window","contributionLocked"},{"Show Contribution Title","contributionShowTitle"},
        {"Show Contribution Hint","contributionShowHint"},{"Show Contribution Footer","contributionShowFooter"}})
    Slider("Contribution Width","contributionWidth");Slider("Contribution Padding","contributionPadding")
    Slider("Contribution Border Size","contributionBorderSize");Slider("Contribution Border Opacity","contributionBorderOpacity","%")
    Color("Contribution Background Color","contributionBackgroundColor");Color("Contribution Border Color","contributionBorderColor")
    Slider("Contribution Horizontal Offset","contributionX");Slider("Contribution Vertical Offset","contributionY")
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
    Note("Contributions TLDR","Ready bag kits appear at a fire. Click Place, then finish native targeting. Preview works anywhere. Drag the header or use Edit Contributions; Reset Position brings it back.",64)
    if pilot then self:ApplyModeConfigLayout(page,firstRow,section) end
end

-- Campfire-only Mode pilot. Other themes keep the existing long-form groups.
-- Selection is session presentation state, never a saved module option.
function C:ApplyModeConfigLayout(page,firstRow,section)
    local state={element="general",panel="options",last={},buttons={},panels={},section=section,searchEntries={},sideRows={}}
    page.campfirePilot=state
    local headingSize=T.fontSize.section+5
    state.headerLines={}
    local function AlignUnderline(line,heading)
        local measured=heading:GetStringWidth()
        if (issecretvalue and issecretvalue(measured)) or type(measured)~="number" or measured~=measured or measured<=0 or measured==math.huge then measured=8 end
        measured=math.min(measured,math.max(8,heading:GetWidth()))
        local width=math.max(8,math.ceil(measured))
        line:ClearAllPoints();line:SetSize(width,1)
        local justify=heading.GetJustifyH and heading:GetJustifyH() or "LEFT"
        if justify=="CENTER" then line:SetPoint("TOP",heading,"BOTTOM",0,-4)
        elseif justify=="RIGHT" then line:SetPoint("TOPRIGHT",heading,"BOTTOMRIGHT",(width-measured)/2,-4)
        else line:SetPoint("TOPLEFT",heading,"BOTTOMLEFT",(measured-width)/2,-4) end
    end
    local function Underline(parent,heading)
        local line=parent:CreateTexture(nil,"BORDER")
        line.modeAsset="ModeHeaderLine";W.Paint(line,T.line,0.7)
        state.headerLines[#state.headerLines+1]={line=line,heading=heading}
        AlignUnderline(line,heading)
        return line
    end
    local elements={{"general","General"},{"monitor","Campfire Icon"},{"buffs","Camp Buffs"},{"contributions","Contributions"}}
    local panels={{"options","Options"},{"text","Text"},{"appearance","Appearance"},{"position","Position"}}
    local labels={
        ["Module Elements"]={"general","options"},["Campfire Status"]={"general","options"},
        ["Tools"]={"general","options"},["Preview & Placement"]={"general","options"},
        ["Shared Style"]={"general","text"},["Icon Position"]={"monitor","position"},
        ["Buff Position"]={"buffs","position"},["Buffs TLDR"]={"buffs","options"},
        ["Detected Kits"]={"contributions","options"},["Contribution Window"]={"contributions","options"},
        ["Contribution Position"]={"contributions","position"},["Contribution Font"]={"contributions","text"},
        ["Title Alignment"]={"contributions","text"},["Row Text Alignment"]={"contributions","text"},
        ["Contributions TLDR"]={"contributions","options"},
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
    -- General is one form: Options first, then shared Text settings.
    for index,row in ipairs(page.rows) do
        if index>=firstRow and row.subsectionHeading and row.subsectionHeading:GetText()=="General" then
            row.campfireSectionHeader=true;row.campfireElement="general";row.campfirePanel="options"
            row.subsectionHeading:SetText("Options");row:SetHeight(40)
            addon.Media:BindInterfaceFont(row.subsectionHeading,GameFontNormalLarge,headingSize,nil,"heading")
            row.campfireUnderline=Underline(row,row.subsectionHeading)
        end
    end
    local textHeader=CreateFrame("Frame",nil,page.content)
    textHeader:SetHeight(40);textHeader.section=section
    textHeader.campfireSectionHeader=true;textHeader.campfireElement="general";textHeader.campfirePanel="text"
    textHeader.subsectionHeading=W.Heading(textHeader,"Text",headingSize,0,-10,360,T.text)
    textHeader.campfireUnderline=Underline(textHeader,textHeader.subsectionHeading)
    state.textHeader=textHeader
    for index,row in ipairs(page.rows) do
        if row==page.campfireColors.textColor.host.row then table.insert(page.rows,index,textHeader);break end
    end
    -- Pair existing size and color controls. The native picker retains color
    -- editing; redundant in-page hex/Apply controls stay hidden in this pilot.
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
        if (row.subsectionHeading and not row.campfireSectionHeader) or (entry and (entry.label=="Jump To" or entry.label=="Module Elements")) then row.campfireHidden=true end
        row.campfireElement=row.campfireElement or "general";row.campfirePanel=row.campfirePanel or "options"
        local previous=row.visibleWhen
        row.visibleWhen=function()
            return not row.campfireHidden and not row.campfireSide and row.campfireElement==state.element and (state.element=="general" or row.campfirePanel==state.panel) and (not previous or previous())
        end
        -- Shorter form rhythm; preserve the underlying row/setting labels.
        row.gapBefore=0;row.gapAfter=2
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
                local descriptions={
                    ["Shared Style"]="Changes the monitor's text and buff text when stat colors are off. Contributions has its own text colors.",
                    ["Buffs TLDR"]="Keep buffs with the monitor or use a separate window with its own size, background and position. Buff duration comes from the game.",
                    ["Contributions TLDR"]="Shows ready kits from your bags. Preview works anywhere. Use Place at a campfire, then choose where to put the kit.",
                }
                if descriptions[entry.label] then note:SetText(descriptions[entry.label]) end
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
    local bar=CreateFrame("Frame",nil,page);state.bar=bar
    bar:SetPoint("TOPLEFT",0,-40);bar:SetPoint("TOPRIGHT",-24,-40);bar:SetHeight(100)
    state.caption=W.Label(bar,"",nil,4,-78,440,T.muted)
    state.footer,state.footerNote=W.ModeFooterCaption(page)
    state.footer.visibleWhen=function() return page.selectedSection==section end
    state.caption:SetPoint("TOPRIGHT",-8,-78);state.caption:SetWordWrap(false)
    local rule=W.Fill(bar,T.line,"BACKGROUND")
    state.rule=rule;rule:SetHeight(1)
    state.summary=CreateFrame("Frame",nil,page.content)
    state.summary:SetPoint("TOPLEFT",page.contentInset,-8);state.summary:SetSize(172,160)
    state.summaryTitle=W.Heading(state.summary,"",headingSize,0,0,172,T.text)
    state.summaryTitle:SetWordWrap(true)
    state.summaryUnderline=Underline(state.summary,state.summaryTitle)
    state.summaryText=W.Label(state.summary,"",nil,0,0,172,T.muted)
    state.summaryText:ClearAllPoints();state.summaryText:SetPoint("TOPLEFT",state.summaryTitle,"BOTTOMLEFT",0,-8)
    state.summaryText:SetWordWrap(true)
    state.inlineHeader=CreateFrame("Frame",nil,page.content)
    state.inlineHeader:SetPoint("TOPLEFT",page.contentInset,-4);state.inlineHeader:SetHeight(36)
    state.inlineTitle=W.Heading(state.inlineHeader,"",headingSize,0,0,100,T.text)
    state.inlineSeparator=W.Label(state.inlineHeader,"·",nil,0,0,8,T.muted)
    addon.Media:BindInterfaceFont(state.inlineSeparator,GameFontHighlight,14)
    state.inlineSeparator:ClearAllPoints();state.inlineSeparator:SetPoint("LEFT",state.inlineTitle,"RIGHT",8,0)
    state.inlineText=W.Label(state.inlineHeader,"",nil,0,0,440,T.muted)
    state.inlineText:ClearAllPoints();state.inlineText:SetPoint("LEFT",state.inlineSeparator,"RIGHT",8,0)
    state.inlineText:SetPoint("RIGHT",-8,0);state.inlineText:SetWordWrap(false)
    state.inlineUnderline=Underline(state.inlineHeader,state.inlineTitle)
    state.toggleGroups={}
    for _,cells in ipairs(page.toggleGrids or {}) do
        local host=cells[1].frame:GetParent()
        if host.row.section==section then
            local left=CreateFrame("Frame",nil,state.summary)
            left.row=left;left.section=section
            left.campfireElement,left.campfirePanel=host.row.campfireElement,host.row.campfirePanel
            state.sideRows[host.row]=left
            state.toggleGroups[#state.toggleGroups+1]={cells=cells,host=host,row=host.row,left=left}
        end
    end
    function page:SelectCampfirePanel(element,panel)
        if element~="general" and element~="monitor" and element~="buffs" and element~="contributions" then return end
        panel=panel or state.last[element] or "options"
        if panel~="options" and panel~="text" and panel~="appearance" and panel~="position" then return end
        if element=="general" then panel="options" end
        state.element,state.panel,state.last[element]=element,panel,panel
        self.scrollbar:SetValue(0)
        if self.sectionTabs and self.selectedSection~=section then self:SelectSectionTab(section) else self:Layout() end
        if addon.CloseTimerColorPicker then addon:CloseTimerColorPicker() end
        if addon.CloseFontDropdown then addon:CloseFontDropdown() end
    end
    state.pillButtons={}
    for _,entry in ipairs(elements) do
        local id=entry[1]
        local button=W.Button(bar,entry[2],120,30,"roundedTab")
        button:SetScript("OnClick",function() page:SelectCampfirePanel(id) end);state.buttons[id]=button
        state.pillButtons[#state.pillButtons+1]=button
    end
    state.panelViewport=CreateFrame("ScrollFrame",nil,bar)
    state.panelViewport:SetPoint("TOPLEFT",12,-38);state.panelViewport:SetPoint("TOPRIGHT",-12,-38);state.panelViewport:SetHeight(34)
    state.panelContent=CreateFrame("Frame",nil,state.panelViewport);state.panelContent:SetSize(456,42)
    state.panelViewport:SetScrollChild(state.panelContent)
    for _,entry in ipairs(panels) do
        local id=entry[1]
        local button=W.Button(state.panelContent,entry[2],104,30,"subTab")
        button:SetScript("OnClick",function() page:SelectCampfirePanel(state.element,id) end);state.panels[id]=button
    end
    local captions={
        general={options="Turn on the monitor, preview its windows and choose the shared text color."},
        monitor={options="Choose the icon and information to show.",text="Set the status text size. Change its color in General.",appearance="Change the icon size and the window's size and transparency.",position="Lock the window or move it on screen."},
        buffs={options="Show buffs with the monitor or in a separate window.",text="Change buff text size, stat colors and the title's colors.",appearance="Change the separate buff window's size and transparency.",position="Lock the buff window or move it on screen."},
        contributions={options="Choose what to show and preview the contribution window.",text="Change fonts, text sizes, colors and alignment.",appearance="Change the window, border, kit icons and row spacing.",position="Lock or move the contribution window."},
    }
    local layout=page.Layout
    function page:Layout()
        if state.layingOut then return end
        state.layingOut=true
        local active=self.sectionTabs and self.selectedSection==section
        if not active and self.modeLayout then state.viewportTop=nil end
        local wide=self.scroll:GetWidth()>=800
        local general=state.element=="general"
        local sliderCount,toggleCount=0,0
        for _,host in pairs(self.campfireSliders) do
            if host.row.campfireElement==state.element and host.row.campfirePanel==state.panel then sliderCount=sliderCount+1 end
        end
        for _,group in ipairs(state.toggleGroups) do
            if group.row.campfireElement==state.element and group.row.campfirePanel==state.panel then toggleCount=toggleCount+#group.cells end
        end
        local mixed=active and wide and not general and sliderCount>0 and toggleCount>0
        local compactHeader=active and not wide and not general
        state.togglesLeft=mixed
        if active or not self.modeLayout then
            self.layoutInsetLeft=active and wide and not general and 188 or 0
            self.layoutTopInset=(mixed or compactHeader) and 44 or 0
            self.layoutMinHeight=mixed and 60+toggleCount*42 or 0
        end
        state.summary:SetShown(active and wide and not general)
        state.summaryTitle:SetShown(not mixed);state.summaryText:Hide();state.summaryUnderline:SetShown(not mixed)
        state.inlineHeader:SetShown(mixed or compactHeader)
        state.inlineSeparator:Hide();state.inlineText:Hide()
        state.inlineHeader:SetWidth(math.max(456,self.scroll:GetWidth()-4-self.contentInset*2))
        for _,group in ipairs(state.toggleGroups) do
            local move=mixed and group.row.campfireElement==state.element and group.row.campfirePanel==state.panel
            group.row.campfireSide=move;group.left:SetShown(move)
            for _,cell in ipairs(group.cells) do
                local target=move and group.left or group.host
                if cell.frame:GetParent()~=target then cell.frame:SetParent(target) end
                cell.button:ClearAllPoints();cell.button:SetPoint("TOPLEFT",move and -6 or -7,-6)
            end
        end
        state.caption:Hide()
        bar:SetShown(active)
        local height=general and 56 or 84
        bar:SetHeight(height)
        local top=active and 48+height or 40
        if (active or not self.modeLayout) and state.viewportTop~=top then
            state.viewportTop=top
            self.scroll:ClearAllPoints();self.scroll:SetPoint("TOPLEFT",0,-top);self.scroll:SetPoint("BOTTOMRIGHT",-24,0)
            self.scrollbar:ClearAllPoints();self.scrollbar:SetPoint("TOPRIGHT",-4,-top-4);self.scrollbar:SetPoint("BOTTOMRIGHT",-4,4)
        end
        if active then state.footerNote:SetText(captions[state.element][state.panel]) end
        layout(self)
        local leftY=40
        for _,group in ipairs(state.toggleGroups) do
            if group.row.campfireSide then
                group.left:ClearAllPoints();group.left:SetPoint("TOPLEFT",0,-leftY);group.left:SetSize(172,#group.cells*42)
                group.left.offset=leftY+8
                for i,cell in ipairs(group.cells) do
                    cell.frame:ClearAllPoints();cell.frame:SetPoint("TOPLEFT",0,-(i-1)*42);cell.frame:SetSize(172,42)
                    cell.label:SetWidth(136)
                end
                leftY=leftY+#group.cells*42
            end
        end
        state.summary:SetHeight(math.max(160,leftY+12))
        for _,entry in ipairs(state.searchEntries) do
            local side=state.sideRows[entry.campfireBaseRow]
            entry.row=side and side:IsShown() and side or entry.campfireBaseRow
        end
        if active then
            local width=math.max(456,self.content:GetWidth()-self.contentInset*2)
            page.contributionFont:SetWidth(math.max(160,math.min(260,width-198)))
            local available=bar:GetWidth()
            if available<64 then available=state.tabWidth or self.scroll:GetWidth() end
            if available<64 then available=width end
            state.tabWidth=available
            local padding=math.min(12,available/8)
            local usable=available-padding*2
            local cell=W.LayoutModePills(state.pillButtons,available) or 128
            state.panelContent:SetWidth(usable)
            state.panelViewport:SetVerticalScroll(0)
            state.panelViewport:SetShown(not general)
            for i,entry in ipairs(elements) do
                local button=state.buttons[entry[1]]
                button:SetSelected(state.element==entry[1])
            end
            for i,entry in ipairs(panels) do
                local button=state.panels[entry[1]]
                local selected=state.panel==entry[1]
                local tabWidth=math.min(112,cell)
                -- The viewport clips eight units below the separator on tucked tabs.
                button:ClearAllPoints();button:SetPoint("TOPLEFT",(i-1)*(tabWidth+6),selected and -4 or -12);button:SetSize(tabWidth,30)
                button.label:ClearAllPoints();button.label:SetPoint("CENTER",0,selected and 0 or 4)
                button.label:SetWidth(tabWidth-16);button.label:SetWordWrap(false);button:SetSelected(selected)
                button:SetShown(not general)
            end
            rule:ClearAllPoints();rule:SetPoint("TOPLEFT",0,general and -48 or -72);rule:SetPoint("TOPRIGHT",0,general and -48 or -72)
            state.caption:ClearAllPoints();state.caption:SetPoint("TOPLEFT",4,general and -56 or -80);state.caption:SetPoint("TOPRIGHT",-8,general and -56 or -80)
            state.caption:SetText(captions[state.element][state.panel])
            local title
            for _,entry in ipairs(panels) do if entry[1]==state.panel then title=entry[2] end end
            state.summaryTitle:SetText(general and "General Settings" or title)
            state.summaryText:SetText(captions[state.element][state.panel])
            state.inlineTitle:SetText(title)
            local measured=state.inlineTitle:GetStringWidth()
            if (issecretvalue and issecretvalue(measured)) or type(measured)~="number" or measured~=measured or measured<=0 or measured==math.huge then measured=#title*11 end
            state.inlineTitle:SetWidth(math.ceil(measured))
            state.inlineText:SetText(captions[state.element][state.panel])
            for _,entry in ipairs(state.headerLines) do AlignUnderline(entry.line,entry.heading) end
        end
        state.layingOut=false
    end
    for _,entry in ipairs(page.searchEntries) do
        if entry.section==section and not entry.row.sectionHeader then
            local previous=entry.onReveal
            entry.campfireBaseRow=entry.row;state.searchEntries[#state.searchEntries+1]=entry
            local element,panel=entry.row.campfireElement,entry.row.campfirePanel
            entry.onReveal=function()
                if previous then previous() end
                page:SelectCampfirePanel(element,panel)
            end
        end
    end
    -- Retain internal jump routing for callers, though the old jump strip is
    -- replaced by the visible element tabs in this pilot.
    for _,id in ipairs({"monitor","buffs","contributions"}) do
        local target=page.campfireJumpTargets[id]
        target.onReveal=function() page:SelectCampfirePanel(id,"options") end
        for index=firstRow,#page.rows do
            local row=page.rows[index]
            if not row.campfireHidden and row.campfireElement==id and row.campfirePanel=="options" then target.row=row;break end
        end
    end
    bar:SetScript("OnSizeChanged",function() page:Layout() end)
    addon.Media:RegisterFontListener(bar,function() page:Layout() end)
end
