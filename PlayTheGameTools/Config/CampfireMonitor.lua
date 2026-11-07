local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,W,T=addon.CampfireMonitor,addon.ConfigWidgets,addon.InterfaceTheme
function C:AddConfig(page)
    local function Toggle(label,key)
        local cell=page:ToggleGrid({{label=label,get=function() return self.db[key] end,
            set=function(v) self:SetOption(key,v) end}})[1]
        page.campfireControls[key]=cell
    end
    local function Slider(label,key,suffix)
        local r=self.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(label,48),r[1],r[2],r[3],
            function() return self.db[key] end,function(v) self:SetOption(key,v) end,suffix,true)
    end
    page.campfireControls={}
    Toggle("Enable Campfire Monitor","enabled")
    local status=W.Label(page:Row("Campfire Status",72),"",nil,0,-4,440,T.muted)
    status:SetWordWrap(true);page.campfireStatus=status
    local preview=W.Button(page:Row("Display Preview",48),"Preview",160,28);preview:SetPoint("LEFT")
    preview:SetScript("OnClick",function() self:TogglePreview();page:Refresh() end);page.campfirePreview=preview
    page.refreshers[#page.refreshers+1]=function()
        local s=self.snapshot or {}
        status:SetText(self.previewing and "Preview only; sample benefits are not live data." or
            (not self.owner.active and "Enable Gameplay Enhancements using its header toggle." or
            (not self.db.enabled and "Campfire Monitor disabled." or
            (s.nearby and "Campfire Nearby confirmed by your native buff." or
            (s.known and "No Campfire Nearby buff detected." or (s.message or "Campfire status unavailable."))))))
        preview.label:SetText(self.previewing and "Stop Preview" or "Preview")
    end
    local refresh=W.Button(page:Row("Native Camp Data",48),"Refresh Status",160,28);refresh:SetPoint("LEFT")
    refresh:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() then self:StopPreview();self:Refresh();page:Refresh() end
    end);page.campfireRefresh=refresh
    page:Group("Display")
    Toggle("Show Campfire Icon","showIcon");Toggle("Show Status Text","showText")
    Toggle("Show Your Camp Benefits","showBenefits")
    Toggle("Show Nearby Native Details","showNearbyDetails")
    Toggle("Show Profession Guide","showProfessionGuide")
    Toggle("Always Show Monitor","alwaysShow");Toggle("Show In Combat","showInCombat")
    page:Group("Appearance")
    Slider("Font Size","fontSize");Slider("Icon Size","iconSize");Slider("Monitor Width","width")
    Slider("Monitor Scale","scale","%");Slider("Monitor Opacity","opacity","%")
    Slider("Background Opacity","backgroundOpacity","%")
    local owner={db={appearance=self.db}}
    function owner:CanConfigure() return addon.LootSparkles:OutsideCombat() end
    function owner:SetAppearance(key,value) return C:SetOption(key,value) end
    W.ColorRow(page,owner,"Text Color","textColor")
    page:Group("Position")
    Toggle("Lock Campfire Monitor","locked")
    Slider("Horizontal Offset","x");Slider("Vertical Offset","y")
    local reset=W.Button(page:Row("Monitor Position",48),"Reset Position",160,28);reset:SetPoint("LEFT")
    reset:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() then self.db.x=0;self.db.y=-240;self:Refresh();page:Refresh() end
    end);page.campfireReset=reset
    local note=W.Label(page:Row("Campfire Help",220),
        "Unlock to drag the monitor outside combat; locking makes it click-through. Nearby status comes only from Campfire Nearby, not from lingering Camp Benefits. Your Camp Benefits lists your earned native buff details, which may include earlier camps. The profession guide shows possible contributions, not objects detected at this fire. Native aura data does not provide a complete inventory of nearby camp objects. Sit or craft at the camp to gain its benefits. Combat display is off by default; unreadable data is never reported as a nearby fire.",nil,0,-4,440,T.muted)
    note:SetWordWrap(true)
end
