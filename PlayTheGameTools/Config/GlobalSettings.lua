local _,addon=...
local W,T,G=addon.ConfigWidgets,addon.InterfaceTheme,addon.GlobalSettings

function addon:CreateGlobalSettingsPage(parent)
    local page=W.Page(parent)
    local function Choices(kind)
        local source=kind=="font" and self.Media:GetFonts() or kind=="border" and self.Media:GetBorders() or self.Media:GetTextures()
        local result={};for _,choice in ipairs(source) do result[#result+1]={id=choice.key,label=choice.label} end
        return result
    end
    local function Media(kind,label)
        local button=W.Select(page:Row(label,48),280,function() return Choices(kind) end,function()
            local value=self.db.globalMedia[kind]
            for _,choice in ipairs(Choices(kind)) do if choice.id==value then return value,choice.label end end
            return value,self.Media:MediaLabel(value:gsub("^media:",""):gsub("^background:",""))
        end,function(value) self.Media:SetGlobalStyle(kind,value);page:Refresh() end)
        page.refreshers[#page.refreshers+1]=function() button:Refresh() end
        page.mediaControls=page.mediaControls or {};page.mediaControls["global:"..kind]=button
    end
    page:Section("Appearance",nil,false)
    Media("font","Global Font");Media("texture","Global Texture");Media("border","Global Border")
    -- Frames keep the theme they were drawn with, so a change applies on reload.
    local themes, choices = addon.InterfaceThemes, {}
    for _, id in ipairs(themes.order) do choices[#choices + 1] = { label = themes[id].label, value = id, width = 108 } end
    local themeButtons, refreshTheme = W.Exclusive(page:Row("Interface Theme", 48, { "theme", "appearance", "modern", "blizzard", "mode", "default" }),
        choices, function() return addon:ResolveInterfaceTheme(addon.db.window.theme) end,
        function(value) addon:SetInterfaceTheme(value) end)
    page.themeButtons = themeButtons
    page.refreshers[#page.refreshers + 1] = refreshTheme

    page:Section("Profiles",nil,false)
    self:CreateProfileHub(page)

    page:Section("Optimizations",nil,false)
    local controls=page:ToggleGrid({
        {label="Auto Loot",get=function() return G.db.autoLoot end,set=function(v) G:SetOption("autoLoot",v) end},
        {label="Fast Loot",get=function() return G.db.fastLoot end,set=function(v) G:SetOption("fastLoot",v) end},
        {label="Hide Error Text",get=function() return G.db.hideErrors end,set=function(v) G:SetOption("hideErrors",v) end},
    },{maxColumns=3})
    page.optimizationControls={autoLoot=controls[1],fastLoot=controls[2],hideErrors=controls[3]}
    local zoom=page:Row("Camera Max Zoom",48)
    page.refreshers[#page.refreshers+1]=W.Slider(zoom,1,4,.1,function() return G.db.cameraZoom end,function(v) G:SetOption("cameraZoom",v) end,"x",{decimals=1})
    page.zoomSlider=zoom.slider
    -- Shown only when the client rejected Fast Loot this session.
    local blocked=W.Label(page:Row("Fast Loot",40),"Stopped after the client rejected it; loot manually.",nil,0,-4,360,T.primary)
    blocked:GetParent().row.visibleWhen=function() return G.lootBlocked==true end
    page.refreshers[#page.refreshers+1]=function() page:Layout() end

    page:Section("Class Colors",nil,false)
    local host=page:Row("",180);host.rowLabel:Hide();host:ClearAllPoints()
    host:SetPoint("TOPLEFT",host.row,"TOPLEFT",12,-14)
    host:SetPoint("BOTTOMRIGHT",host.row,"BOTTOMRIGHT",-12,14)
    page.classColorGrid=host
    local cells={};page.classColorButtons={}
    for i,class in ipairs(G.classes) do
        local cell=CreateFrame("Frame",nil,host);cells[i]=cell
        local name=LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class:sub(1,1)..class:sub(2):lower()
        local pick=W.Button(cell,name,130,30);pick:SetPoint("TOPLEFT")
        local reset=W.Button(cell,"Reset",54,26,"secondary");reset:SetPoint("LEFT",pick,"RIGHT",5,0)
        pick:SetScript("OnClick",function()
            if InCombatLockdown() or UnitAffectingCombat("player") then return end
            if not ColorPickerFrame and C_AddOns then C_AddOns.LoadAddOn("Blizzard_ColorPickerFrame") end
            if not ColorPickerFrame then return end
            self:CloseTimerColorPicker()
            local old=self.db.globalOptions.classColors[class]
            old=old and {old[1],old[2],old[3]}
            local c=G:GetClassColor(class)
            local function Changed()
                local r,g,b=ColorPickerFrame:GetColorRGB();G:SetClassColor(class,{r,g,b});page:Refresh()
            end
            self.timerPickerCallback=Changed;self.timerPickerOwner=pick
            ColorPickerFrame:SetupColorPickerAndShow({r=c.r,g=c.g,b=c.b,hasOpacity=false,swatchFunc=Changed,
                cancelFunc=function() G:SetClassColor(class,old);page:Refresh() end})
        end)
        reset:SetScript("OnClick",function() G:SetClassColor(class,nil);page:Refresh() end)
        page.refreshers[#page.refreshers+1]=function()
            local c=G:GetClassColor(class);pick:SetLabelColor({c.r,c.g,c.b})
        end
        page.classColorButtons[class]={pick=pick,reset=reset}
    end
    function host.row:layoutChildren(width)
        local available=width-24
        local columns=math.max(1,math.min(3,math.floor(available/210)))
        local size=available/columns
        for i,cell in ipairs(cells) do
            cell:SetSize(size,50);cell:ClearAllPoints();cell:SetPoint("TOPLEFT",((i-1)%columns)*size,-math.floor((i-1)/columns)*50)
        end
        self:SetHeight(math.ceil(#cells/columns)*50+28)
    end
    W.SectionTabs(page)
    page.sectionTabs:SetPoint("TOPLEFT",0,0);page.sectionTabs:SetPoint("TOPRIGHT",-24,0)
    page.scroll:ClearAllPoints();page.scroll:SetPoint("TOPLEFT",0,-40);page.scroll:SetPoint("BOTTOMRIGHT",-24,0)
    page.scrollbar:ClearAllPoints();page.scrollbar:SetPoint("TOPRIGHT",-4,-44);page.scrollbar:SetPoint("BOTTOMRIGHT",-4,4)
    page:Finish();return page
end
