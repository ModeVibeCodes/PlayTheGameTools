local _,addon=...
local W,T,G=addon.ConfigWidgets,addon.InterfaceTheme,addon.GlobalSettings

-- One-line descriptions under each theme preview.
local CAPTIONS={
    modern="Graphite with a mint accent and square edges. The default for new installs.",
    blizzard="Dark stone in a metal frame with gold headings, like the game's own dialogs.",
    mode="Soft grey with a cyan accent and rounded corners. The mode brand look.",
}
-- The Blizzard theme's metal window frame, drawn as three hairlines at preview size.
local METAL={{0,0,0,1},{0.553,0.522,0.463,1},{0.29,0.267,0.231,1}}
local MINI_HEIGHT=96

local function Solid(texture,color,alpha)
    texture:SetColorTexture(color[1],color[2],color[3],alpha or color[4] or 1)
    return texture
end
-- Mode's rounded art tinted from its palette; a plain fill if the file is refused.
local function Rounded(texture,key,color)
    if addon.Media:ApplyTexture(texture,key,color) then
        texture:SetVertexColor(color[1],color[2],color[3],color[4] or 1)
    else Solid(texture,color) end
    return texture
end
local function Ring(frame,color,inset,layer)
    local edges={}
    for i=1,4 do edges[i]=Solid(frame:CreateTexture(nil,layer or "BORDER"),color) end
    edges[1]:SetPoint("TOPLEFT",inset,-inset);edges[1]:SetPoint("TOPRIGHT",-inset,-inset);edges[1]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT",inset,inset);edges[2]:SetPoint("BOTTOMRIGHT",-inset,inset);edges[2]:SetHeight(1)
    edges[3]:SetPoint("TOPLEFT",inset,-inset-1);edges[3]:SetPoint("BOTTOMLEFT",inset,inset+1);edges[3]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT",-inset,-inset-1);edges[4]:SetPoint("BOTTOMRIGHT",-inset,inset+1);edges[4]:SetWidth(1)
    return edges
end
local function MiniText(frame,id,text,size,color,weight)
    local label=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    if not label:SetFont(addon.Media:ThemeFont(id,weight),size,"") then label:SetFont(GameFontHighlightSmall:GetFont(),size,"") end
    label:SetJustifyH("LEFT");label:SetWordWrap(false);label:SetText(text)
    label:SetTextColor(color[1],color[2],color[3],color[4] or 1)
    if id=="blizzard" then label:SetShadowColor(0,0,0,0.85);label:SetShadowOffset(1,-1) else label:SetShadowOffset(0,0) end
    return label
end

-- A tiny settings window drawn in one theme's own palette, edges and font:
-- header strip, sidebar with a selected row, and two rows with an on switch.
local function Miniature(parent,id)
    local p=addon.InterfaceThemes[id].palette
    local rounded=id=="mode"
    local mini=CreateFrame("Frame",nil,parent);mini:SetHeight(MINI_HEIGHT)
    local edge=id=="blizzard" and 3 or rounded and 0 or 1
    local bg=mini:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints()
    if rounded then Rounded(bg,"ModeSurface",p.background) else Solid(bg,p.background) end
    if id=="blizzard" then for i,color in ipairs(METAL) do Ring(mini,color,i-1) end
    elseif rounded then
        local border=mini:CreateTexture(nil,"BORDER");border:SetAllPoints()
        if addon.Media:ApplyTexture(border,"ModeBorder",p.line) then border:SetVertexColor(p.line[1],p.line[2],p.line[3],1) end
    else Ring(mini,p.lineStrong,0) end
    local inner=rounded and 3 or edge
    local title=MiniText(mini,id,"Play The Game Tools",8,p.primary,"heading")
    title:SetPoint("TOPLEFT",inner+6,-inner-4)
    local headLine=Solid(mini:CreateTexture(nil,"ARTWORK"),p.line)
    headLine:SetPoint("TOPLEFT",inner,-17);headLine:SetPoint("TOPRIGHT",-inner,-17);headLine:SetHeight(1)
    local side=mini:CreateTexture(nil,"BACKGROUND",nil,1)
    if rounded then Rounded(side,"ModeSurface",p.sidebar) else Solid(side,p.sidebar) end
    local sideLine=Solid(mini:CreateTexture(nil,"ARTWORK"),p.line);sideLine:SetWidth(1)
    local navigation={}
    for i=1,4 do
        local bar=Solid(mini:CreateTexture(nil,"ARTWORK"),i==1 and p.surface or p.line);bar:SetHeight(7)
        navigation[i]=bar
    end
    local marker=Solid(mini:CreateTexture(nil,"OVERLAY"),p.primary);marker:SetWidth(2)
    marker:SetPoint("TOPLEFT",navigation[1],"TOPLEFT",0,0);marker:SetPoint("BOTTOMLEFT",navigation[1],"BOTTOMLEFT",0,0)
    local heading=MiniText(mini,id,"Automation",9,p.heading,"heading")
    local rows={}
    for i=1,2 do
        -- 20 units: mode's control art has 10-unit rounded corners.
        local row=CreateFrame("Frame",nil,mini);row:SetHeight(20)
        local fill=row:CreateTexture(nil,"BACKGROUND")
        if rounded then fill:SetAllPoints();Rounded(fill,"ModeControlSurface",p.surface)
        else fill:SetPoint("TOPLEFT",1,-1);fill:SetPoint("BOTTOMRIGHT",-1,1);Solid(fill,p.surface);Ring(row,p.line,0) end
        local text=Solid(row:CreateTexture(nil,"ARTWORK"),p.muted);text:SetHeight(2);text:SetPoint("LEFT",5,0)
        local switch=row:CreateTexture(nil,"ARTWORK");switch:SetSize(16,8);switch:SetPoint("RIGHT",-5,0)
        if rounded then Rounded(switch,"ModeToggleSurface",p.primary) else Solid(switch,p.primary) end
        row.text,row.switch=text,switch;rows[i]=row
    end
    function mini:Layout(width)
        self:SetWidth(width)
        local sideWidth=math.floor(width*0.32)
        side:ClearAllPoints()
        if rounded then side:SetPoint("TOPLEFT",2,-19);side:SetPoint("BOTTOMRIGHT",self,"BOTTOMLEFT",sideWidth,2)
        else side:SetPoint("TOPLEFT",edge,-18);side:SetPoint("BOTTOMRIGHT",self,"BOTTOMLEFT",sideWidth,edge) end
        sideLine:ClearAllPoints();sideLine:SetPoint("TOPLEFT",sideWidth,-18);sideLine:SetPoint("BOTTOMLEFT",sideWidth,edge)
        sideLine:SetShown(not rounded)
        for i,bar in ipairs(navigation) do
            bar:ClearAllPoints();bar:SetPoint("TOPLEFT",inner+5,-24-(i-1)*12);bar:SetWidth(math.max(4,sideWidth-inner-10))
        end
        heading:ClearAllPoints();heading:SetPoint("TOPLEFT",sideWidth+8,-23);heading:SetWidth(math.max(4,width-sideWidth-16))
        title:SetWidth(math.max(4,width-2*inner-12))
        for i,row in ipairs(rows) do
            row:ClearAllPoints();row:SetPoint("TOPLEFT",sideWidth+8,-37-(i-1)*25);row:SetPoint("RIGHT",self,"RIGHT",-inner-6,0)
            row.text:SetWidth(math.max(2,(width-sideWidth-inner-14)*0.45))
        end
    end
    mini.palette,mini.rows=p,rows
    return mini
end

-- Theme picker: one preview card per predefined theme. A choice is saved and
-- applies after a reload, through the existing theme reload request.
local function ThemeCards(page)
    local controls=page:Row("Theme",220,{"theme","appearance","modern","blizzard","mode","preview"})
    local row=controls.row
    controls:ClearAllPoints();controls:SetPoint("TOPLEFT",0,-36);controls:SetPoint("BOTTOMRIGHT",0,4)
    row.settingsLabel:ClearAllPoints();row.settingsLabel:SetPoint("TOPLEFT",0,-12);row.settingsLabel:SetWidth(60)
    local note=W.Label(row,"· applies after a reload","GameFontHighlightSmall",0,-14,240,T.muted)
    note:ClearAllPoints();note:SetPoint("LEFT",row.settingsLabel,"LEFT",row.settingsLabel:GetStringWidth()+6,0)
    local cards={}
    for index,id in ipairs(addon.InterfaceThemes.order) do
        local theme=addon.InterfaceThemes[id]
        local card=CreateFrame("Button",nil,controls);card:EnableMouse(true);card:RegisterForClicks("LeftButtonUp")
        card.themeID=id
        card.outline=W.Outline(card,T.lineStrong,"BORDER")
        card.selectedOutline=W.Outline(card,T.primary,"BORDER",1)
        card.mini=Miniature(card,id);card.mini:SetPoint("TOPLEFT",6,-6)
        card.label=W.Label(card,theme.label,nil,6,-(MINI_HEIGHT+14),200,T.heading)
        card.current=W.Label(card,"Current","GameFontHighlightSmall",0,0,80,T.muted)
        card.current:ClearAllPoints();card.current:SetPoint("LEFT",card.label,"LEFT",card.label:GetStringWidth()+6,0)
        card.caption=W.Label(card,CAPTIONS[id] or "","GameFontHighlightSmall",6,-(MINI_HEIGHT+32),200,T.muted)
        card.caption:SetWordWrap(true)
        function card:RefreshAppearance()
            local chosen=self.selected==true
            self.outline:SetColor(chosen and T.primary or (self.hovered and T.muted or T.lineStrong),1)
            self.selectedOutline:SetShown(chosen)
            self.current:SetShown(addon.appliedInterfaceTheme==self.themeID)
        end
        function card:SetSelected(selected) self.selected=selected;self:RefreshAppearance() end
        card:SetScript("OnClick",function() addon:SetInterfaceTheme(id);page:Refresh() end)
        card:SetScript("OnEnter",function(self) self.hovered=true;self:RefreshAppearance() end)
        card:SetScript("OnLeave",function(self) self.hovered=false;self:RefreshAppearance() end)
        cards[index]=card
    end
    function row:layoutChildren(width)
        local columns=width>=480 and #cards or 1
        local gap=10
        local cardWidth=math.floor((width-gap*(columns-1))/columns)
        local tallest=0
        for _,card in ipairs(cards) do
            card.mini:Layout(cardWidth-12)
            card.label:SetWidth(cardWidth-12);card.caption:SetWidth(cardWidth-12)
            card.current:ClearAllPoints();card.current:SetPoint("LEFT",card.label,"LEFT",card.label:GetStringWidth()+6,0)
            local height=card.caption:GetStringHeight()
            if (issecretvalue and issecretvalue(height)) or type(height)~="number" or height~=height or height<0 or height==math.huge then height=28 end
            tallest=math.max(tallest,MINI_HEIGHT+32+height+10)
        end
        for index,card in ipairs(cards) do
            local column,line=(index-1)%columns,math.floor((index-1)/columns)
            card:ClearAllPoints();card:SetSize(cardWidth,tallest)
            card:SetPoint("TOPLEFT",column*(cardWidth+gap),-line*(tallest+gap))
        end
        local lines=math.ceil(#cards/columns)
        self:SetHeight(36+lines*tallest+(lines-1)*gap+12)
    end
    page.refreshers[#page.refreshers+1]=function()
        local chosen=addon:ResolveInterfaceTheme(addon.db.window.theme)
        for _,card in ipairs(cards) do card:SetSelected(card.themeID==chosen) end
    end
    return cards
end

-- One row of nine class swatches; clicking one opens the color picker.
local function ClassColors(page)
    local controls=page:Row("Class colors",72,{"class","color","colour","roster","recruiter","threat"})
    addon:AddSettingsHint(controls,"Used in the roster, recruiter and threat meter. Click one to change it.",72)
    page.classColorGrid=controls
    page.classColorButtons={}
    local swatches={}
    for i,class in ipairs(G.classes) do
        local name=LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class:sub(1,1)..class:sub(2):lower()
        local swatch=CreateFrame("Button",nil,controls);swatch:SetSize(20,20);swatch:EnableMouse(true);swatch:RegisterForClicks("LeftButtonUp")
        swatch.className=name
        Ring(swatch,{0,0,0,0.6},0)
        swatch.fill=swatch:CreateTexture(nil,"ARTWORK");swatch.fill:SetPoint("TOPLEFT",1,-1);swatch.fill:SetPoint("BOTTOMRIGHT",-1,1)
        swatch.hover=Ring(swatch,T.text,-2,"OVERLAY")
        for _,line in ipairs(swatch.hover) do line:Hide() end
        swatch:SetScript("OnEnter",function(self)
            for _,line in ipairs(self.hover) do line:Show() end
            if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(name);GameTooltip:Show() end
        end)
        swatch:SetScript("OnLeave",function(self)
            for _,line in ipairs(self.hover) do line:Hide() end
            if GameTooltip then GameTooltip:Hide() end
        end)
        swatch:SetScript("OnClick",function()
            if InCombatLockdown() or UnitAffectingCombat("player") then return end
            if not ColorPickerFrame and C_AddOns then C_AddOns.LoadAddOn("Blizzard_ColorPickerFrame") end
            if not ColorPickerFrame then return end
            addon:CloseTimerColorPicker()
            local old=addon.db.globalOptions.classColors[class]
            old=old and {old[1],old[2],old[3]}
            local c=G:GetClassColor(class)
            local function Changed()
                local r,g,b=ColorPickerFrame:GetColorRGB();G:SetClassColor(class,{r,g,b});page:Refresh()
            end
            addon.timerPickerCallback=Changed;addon.timerPickerOwner=swatch
            ColorPickerFrame:SetupColorPickerAndShow({r=c.r,g=c.g,b=c.b,hasOpacity=false,swatchFunc=Changed,
                cancelFunc=function() G:SetClassColor(class,old);page:Refresh() end})
        end)
        page.refreshers[#page.refreshers+1]=function()
            local c=G:GetClassColor(class);swatch.fill:SetColorTexture(c.r,c.g,c.b,1)
        end
        page.classColorButtons[class]={pick=swatch}
        swatches[i]=swatch
    end
    local reset=W.Button(controls,"Reset",72,26,"secondary")
    reset:SetScript("OnClick",function()
        if InCombatLockdown() or UnitAffectingCombat("player") then return end
        addon:CloseTimerColorPicker()
        G:ResetClassColors();page:Refresh()
    end)
    page.refreshers[#page.refreshers+1]=function() reset:SetEnabled(next(addon.db.globalOptions.classColors)~=nil) end
    page.classColorReset=reset
    local row=controls.row
    local previous=row.layoutChildren
    function row:layoutChildren(width)
        local available=math.max(26,width-198)
        local perLine=math.max(1,math.min(#swatches,math.floor((available+6)/26)))
        for i,swatch in ipairs(swatches) do
            swatch:ClearAllPoints();swatch:SetPoint("TOPLEFT",((i-1)%perLine)*26,-3-math.floor((i-1)/perLine)*26)
        end
        reset:ClearAllPoints()
        local lines=math.ceil(#swatches/perLine)
        if perLine==#swatches and available>=#swatches*26+84 then reset:SetPoint("TOPLEFT",#swatches*26+6,0)
        else reset:SetPoint("TOPLEFT",0,-lines*26-4);lines=lines+1 end
        self:SetHeight(math.max(72,lines*26+24))
        if previous then previous(self,width) end
    end
end

local function Switch(page,label,key,keywords)
    local controls=page:Row(label,44,keywords)
    local toggle=W.Button(controls,"",44,24,"toggle");toggle:SetPoint("LEFT")
    toggle:SetScript("OnClick",function() G:SetOption(key,not G.db[key]);page:Refresh() end)
    page.refreshers[#page.refreshers+1]=function() toggle:SetSelected(G.db[key]==true) end
    return toggle
end

local function Fact(page,label,text,keywords)
    local value=W.Label(page:Row(label,40,keywords),text,nil,0,-7,420,T.secondary)
    value:GetParent().row.layoutChildren=function(_,width) value:SetWidth(math.max(80,width-198)) end
    return value
end

-- Settings -> Settings: Appearance, Game, Profile, About on one scrolling page.
function addon:CreateGlobalSettingsPage(parent)
    local page=W.Page(parent)
    page:Section("Appearance",nil,false)
    page.themeButtons=ThemeCards(page)
    ClassColors(page)

    page:Section("Game",nil,false)
    page.optimizationControls={
        fastLoot=Switch(page,"Fast loot","fastLoot",{"loot","fast"}),
        hideErrors=Switch(page,"Hide red error text","hideErrors",{"error","errors","red text"}),
    }
    local zoom=page:Row("Camera distance",48,{"camera","zoom","distance"})
    page.refreshers[#page.refreshers+1]=W.Slider(zoom,1,4,.1,function() return G.db.cameraZoom end,function(v) G:SetOption("cameraZoom",v) end,"x",{decimals=1})
    page.zoomSlider=zoom.slider
    -- Shown only when the client rejected Fast Loot this session.
    local blocked=W.Label(page:Row("Fast loot",40),"Stopped after the client rejected it; loot manually.",nil,0,-4,360,T.primary)
    blocked:GetParent().row.visibleWhen=function() return G.lootBlocked==true end
    page.fastLootNotice=blocked

    page:Section("Profile",nil,false)
    self:CreateProfileHub(page)

    page:Section("About",nil,false)
    page.aboutVersion=Fact(page,"Version",self.buildVersion or "unknown",{"version","about"})
    page.aboutCredits=Fact(page,"Created by","Mode and Prox",{"credits","author","about"})
    page.aboutBugs=Fact(page,"Bug reports","Discord NoJumperMike",{"bugs","discord","support","about"})
    local sources=page:Row("Data sources",96,{"license","licence","attribution","efficient games","cmangos"})
    local source=addon.CityLabelsData and addon.CityLabelsData.source
    local poi=W.Label(sources,addon.modules.cityLabels and addon.modules.cityLabels.title or "Map Labels",nil,0,-7,420,T.secondary)
    -- Same notice as the Map Labels page. Map Labels' old names are that
    -- module's search aliases, so they are not keywords here.
    local notice=W.Label(sources,"Data from Efficient Games (efficient.games), licensed CC BY 4.0, from WoW: Forever client builds "
        ..(source and source.builds or "?").."; each label marks where players stood to use the service. Where they have not recorded one yet, "
        .."the Classic spawn position from CMaNGOS classic-db (GPL-3.0) is shown and its tooltip says so.",nil,0,-27,420,T.muted)
    notice:SetWordWrap(true)
    page.dataSourcesNotice,page.dataSourcesTitle=notice,poi
    function sources.row:layoutChildren(width)
        local textWidth=math.max(80,width-198)
        poi:SetWidth(textWidth);notice:SetWidth(textWidth)
        local height=notice:GetStringHeight()
        if (issecretvalue and issecretvalue(height)) or type(height)~="number" or height~=height or height<0 or height==math.huge then height=56 end
        self:SetHeight(math.max(52,47+height))
    end

    -- One scroll like every page: opening it shows section 1, the top
    -- (page:ShowSection in Config/Pages.lua).
    -- Rows that appear, disappear or rewrap on refresh.
    page.refreshers[#page.refreshers+1]=function() page:Layout() end
    page:Finish();return page
end
