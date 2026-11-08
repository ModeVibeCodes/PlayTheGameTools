local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,W,T=addon.CampfireMonitor,addon.ConfigWidgets,addon.InterfaceTheme
function C:AddConfig(page)
    local function Toggles(entries)
        local items={}
        for _,entry in ipairs(entries) do
            local key=entry[2]
            items[#items+1]={label=entry[1],get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}
        end
        local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=210})
        for i,entry in ipairs(entries) do page.campfireControls[entry[2]]=cells[i] end
    end
    local function Toggle(label,key) Toggles({{label,key}}) end
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
    Toggles({{"Show Campfire Icon","showIcon"},{"Show Status Text","showText"},
        {"Show Your Camp Benefits","showBenefits"},{"Compact Buff Text","compactBenefits"},
        {"Separate Buff Window","separateBenefits"},{"Show Nearby Native Details","showNearbyDetails"},
        {"Show Profession Guide","showProfessionGuide"},{"Always Show Monitor","alwaysShow"},
        {"Show In Combat","showInCombat"},{"Lock Campfire Monitor","locked"},{"Lock Buff Window","benefitsLocked"}})
    page:Group("Appearance")
    Slider("Font Size","fontSize");Slider("Icon Size","iconSize");Slider("Monitor Width","width")
    Slider("Monitor Scale","scale","%");Slider("Monitor Opacity","opacity","%")
    Slider("Background Opacity","backgroundOpacity","%")
    local owner={db={appearance=self.db}}
    function owner:CanConfigure() return addon.LootSparkles:OutsideCombat() end
    function owner:SetAppearance(key,value) return C:SetOption(key,value) end
    page:Group("Text Colors")
    Toggles({{"Header Gradient","headerGradient"},{"Timer Gradient","timerGradient"},
        {"Dynamic Timer Color","dynamicTimerColor"},{"Color Stats by Type","colorStats"}})
    page.campfireColors={}
    for _,entry in ipairs({{"Text Color","textColor"},{"Header Color","headerColor"},
        {"Header Gradient End","headerEndColor"},{"Timer Color","timerColor"},
        {"Timer Green","timerGoodColor"},{"Timer Yellow","timerWarningColor"},
        {"Timer Red","timerCriticalColor"},{"Crit Color","critColor"},{"Int Color","intColor"}}) do
        local pick,hex,apply=W.ColorRow(page,owner,entry[1],entry[2])
        page.campfireColors[entry[2]]={pick=pick,hex=hex,apply=apply}
    end
    page:Group("Camp Contributions")
    Toggle("Show Contribution Popup","showContributionPopup")
    local A=addon.CampContributions
    local detected=W.Label(page:Row("Detected Kits",68),"",nil,0,-4,440,T.muted)
    detected:SetWordWrap(true);page.contributionStatus=detected
    local tools=page:Row("Contribution Window",42)
    local open=W.Button(tools,"Open Contributions",180,28);open:SetPoint("LEFT")
    open:SetScript("OnClick",function() A:Open();page:Refresh() end);page.contributionOpen=open
    local sample=W.Button(tools,"Preview Contributions",180,28);sample:SetPoint("LEFT",190,0)
    sample:SetScript("OnClick",function() A:TogglePreview();page:Refresh() end);page.contributionPreview=sample
    local actions=page:Row("Contribution Tools",42)
    local refresh=W.Button(actions,"Refresh Contributions",180,28);refresh:SetPoint("LEFT")
    refresh:SetScript("OnClick",function() A:RefreshDetected();page:Refresh() end);page.contributionRefresh=refresh
    local editContributions=W.Button(actions,"Edit Contributions",180,28);editContributions:SetPoint("LEFT",190,0)
    editContributions:SetScript("OnClick",function()
        if A.active and addon.LootSparkles:OutsideCombat() then
            addon:SetEditMode(true);addon.PositionManager:SelectElement("campfireContributions")
        end
    end);page.contributionEdit=editContributions
    page.refreshers[#page.refreshers+1]=function()
        detected:SetText(A:Summary())
        sample.label:SetText(A.previewing and "Stop Preview" or "Preview Contributions")
    end
    local help=W.Label(page:Row("Contributions TLDR",76),
        "Ready profession kits from your bags appear at a fire. Place uses the native item; finish targeting. Dismiss hides this visit. Preview is safe anywhere; drag its header or use Edit Contributions.",nil,0,-4,440,T.muted)
    help:SetWordWrap(true)
    page:Group("Buff Timer")
    Slider("Yellow Below (Minutes)","timerWarningMinutes")
    Slider("Red Below (Minutes)","timerCriticalMinutes")
    local timerHelp=W.Label(page:Row("Timer Colors",72),"Dynamic color: green > yellow > red. Red threshold must be lower. Gradients are optional; Pick opens the color wheel. Unreadable timing stays unavailable.",nil,0,-4,440,T.muted)
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
    Slider("Horizontal Offset","x");Slider("Vertical Offset","y")
    local reset=W.Button(page:Row("Monitor Position",48),"Reset Position",160,28);reset:SetPoint("LEFT")
    reset:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() then self:ResetWindowPosition(false);page:Refresh() end
    end);page.campfireReset=reset
    page:Group("Buff Window")
    Slider("Buff Text Size","benefitsFontSize");Slider("Buff Window Width","benefitsWidth")
    Slider("Buff Window Scale","benefitsScale","%");Slider("Buff Window Opacity","benefitsOpacity","%")
    Slider("Buff Background Opacity","benefitsBackgroundOpacity","%")
    Slider("Buff Horizontal Offset","benefitsX");Slider("Buff Vertical Offset","benefitsY")
    local resetBuffs=W.Button(page:Row("Buff Window Position",48),"Reset Buff Position",160,28);resetBuffs:SetPoint("LEFT")
    resetBuffs:SetScript("OnClick",function()
        if addon.LootSparkles:OutsideCombat() then self:ResetWindowPosition(true);page:Refresh() end
    end);page.campfireBuffReset=resetBuffs
    local note=W.Label(page:Row("Campfire TLDR",76),
        "Move Windows or Edit Mode positions the monitor/buffs. Separate Buff Window detaches earned bonuses. Compact Buff Text shortens stats. The guide is a reference, not a detected camp inventory.",nil,0,-4,440,T.muted)
    note:SetWordWrap(true)
end
