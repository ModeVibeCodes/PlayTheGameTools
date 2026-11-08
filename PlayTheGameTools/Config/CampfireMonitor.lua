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
    Toggle("Compact Buff Text","compactBenefits")
    Toggle("Separate Buff Window","separateBenefits")
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
    page:Group("Camp Contributions")
    Toggle("Show Contribution Popup","showContributionPopup")
    local contributionStatus=W.Label(page:Row("Contribution Availability",92),"",nil,0,-4,440,T.muted)
    contributionStatus:SetWordWrap(true);page.contributionStatus=contributionStatus
    page.refreshers[#page.refreshers+1]=function()
        contributionStatus:SetText(addon.CampContributions.message or "Ready carried kits for your learned professions appear at a nearby fire, outside combat.")
    end
    local open=W.Button(page:Row("Contribution Window",48),"Open Contributions",180,28);open:SetPoint("LEFT")
    open:SetScript("OnClick",function() addon.CampContributions:Open();page:Refresh() end)
    page.contributionOpen=open
    local refreshContributions=W.Button(page:Row("Carried Camp Kits",48),"Refresh Contributions",180,28);refreshContributions:SetPoint("LEFT")
    refreshContributions:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() then
            addon.CampContributions.dirty=true;addon.CampContributions:OnSnapshot(self.snapshot);page:Refresh()
        end
    end);page.contributionRefresh=refreshContributions
    local contributionHelp=W.Label(page:Row("Contribution Help",120),"Shows ready camp contribution kits carried in your bags for professions you know. Click Place to use one; finish any native placement targeting. The game enforces range, skill, camp slots and shared cooldowns. Dismiss hides this visit's popup; Open Contributions reopens it. Fire-building kits and unrelated items are excluded.",nil,0,-4,440,T.muted)
    contributionHelp:SetWordWrap(true)
    page:Group("Buff Timer")
    Slider("Yellow Below (Minutes)","timerWarningMinutes")
    Slider("Red Below (Minutes)","timerCriticalMinutes")
    local timerHelp=W.Label(page:Row("Timer Colors",72),"The countdown fades from white into green, yellow or red. Red must be below the yellow threshold. Hidden native timing shows Time unavailable.",nil,0,-4,440,T.muted)
    timerHelp:SetWordWrap(true)
    page:Group("Position")
    local edit=W.Button(page:Row("Addon Edit Mode",48),"Open Edit Mode",160,28);edit:SetPoint("LEFT")
    edit:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() and self.active then
            addon:SetEditMode(true);addon.PositionManager:SelectElement("campfireMonitor")
        end
    end);page.campfireEdit=edit
    local move=W.Button(page:Row("Window Placement",48),"Move Windows",160,28);move:SetPoint("LEFT")
    move:SetScript("OnClick",function() self:SetPlacementMode(not self.placing);page:Refresh() end)
    page.campfireMove=move
    page.refreshers[#page.refreshers+1]=function() move.label:SetText(self.placing and "Finish Moving" or "Move Windows") end
    Toggle("Lock Campfire Monitor","locked")
    Slider("Horizontal Offset","x");Slider("Vertical Offset","y")
    local reset=W.Button(page:Row("Monitor Position",48),"Reset Position",160,28);reset:SetPoint("LEFT")
    reset:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() then self:ResetWindowPosition(false);page:Refresh() end
    end);page.campfireReset=reset
    page:Group("Buff Window")
    Toggle("Lock Buff Window","benefitsLocked")
    Slider("Buff Text Size","benefitsFontSize");Slider("Buff Window Width","benefitsWidth")
    Slider("Buff Window Scale","benefitsScale","%");Slider("Buff Window Opacity","benefitsOpacity","%")
    Slider("Buff Background Opacity","benefitsBackgroundOpacity","%")
    Slider("Buff Horizontal Offset","benefitsX");Slider("Buff Vertical Offset","benefitsY")
    local resetBuffs=W.Button(page:Row("Buff Window Position",48),"Reset Buff Position",160,28);resetBuffs:SetPoint("LEFT")
    resetBuffs:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() then self:ResetWindowPosition(true);page:Refresh() end
    end);page.campfireBuffReset=resetBuffs
    local note=W.Label(page:Row("Campfire Help",220),
        "Move Windows lets you drag the monitor and detached buffs outside combat, even when locked. Preview windows can also be dragged. Right-click either window or choose Finish Moving to stop. Separate Buff Window keeps earned buffs in their own window with a saved position and its own size and opacity. Compact Buff Text shortens readable native bonuses; unfamiliar text stays unchanged. Earned buffs can outlast the nearby fire. The profession guide lists possible contributions, not this camp's detected objects. Combat display is off by default.",nil,0,-4,440,T.muted)
    note:SetWordWrap(true)
end
