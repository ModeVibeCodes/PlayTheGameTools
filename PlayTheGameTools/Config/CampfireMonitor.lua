local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,W,T=addon.CampfireMonitor,addon.ConfigWidgets,addon.InterfaceTheme
function C:AddConfig(page)
    page.campfireControls={};page.campfireColors={};page.campfireSliders={}
    local A=addon.CampContributions
    local function Toggles(entries)
        local items={}
        for _,entry in ipairs(entries) do
            local key=entry[2]
            items[#items+1]={label=entry[1],get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}
        end
        local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=210})
        for i,entry in ipairs(entries) do page.campfireControls[entry[2]]=cells[i] end
    end
    local function Slider(label,key,suffix)
        local r=self.ranges[key]
        local row=page:Row(label,42);page.campfireSliders[key]=row
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
        local pick,hex,apply=W.ColorRow(page,owner,label,key)
        page.campfireColors[key]={pick=pick,hex=hex,apply=apply}
    end
    local function Button(row,label,x,callback,width)
        local b=W.Button(row,label,width or 180,28);b:SetPoint("LEFT",x or 0,0)
        b:SetScript("OnClick",function() callback();page:Refresh() end);return b
    end
    local function Note(label,text,height)
        local text=W.Label(page:Row(label,height or 52),text,nil,0,-4,440,T.muted);text:SetWordWrap(true);return text
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
end
