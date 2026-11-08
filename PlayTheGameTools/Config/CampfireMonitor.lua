local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,W,T=addon.CampfireMonitor,addon.ConfigWidgets,addon.InterfaceTheme
function C:AddConfig(page)
    page.campfireControls={};page.campfireColors={}
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
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(label,42),r[1],r[2],r[3],
            function() return self.db[key] end,function(v) self:SetOption(key,v) end,suffix,true)
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
    Note("Shared Style","Text Color is shared by status and untyped stats. Header colors apply to Camp Buffs and Contributions. Pick opens the color wheel.")
    page.refreshers[#page.refreshers+1]=function()
        local s=self.snapshot or {}
        status:SetText(self.previewing and "Preview only." or
            (not self.owner.active and "Enable Gameplay Enhancements using its header toggle." or
            (not self.db.enabled and "Campfire Monitor disabled." or
            (s.nearby and "Campfire Nearby" or (s.known and "No Nearby Campfire" or "Campfire status unavailable.")))))
        page.campfirePreview.label:SetText(self.previewing and "Stop Preview" or "Preview")
        page.campfireMove.label:SetText(self.placing and "Finish Moving" or "Move Windows")
    end
    page:Group("Campfire Icon")
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
    page:Group("Camp Buffs")
    Toggles({{"Show Your Camp Benefits","showBenefits"},{"Compact Buff Text","compactBenefits"},
        {"Separate Buff Window","separateBenefits"},{"Lock Buff Window","benefitsLocked"},{"Color Stats by Type","colorStats"}})
    Color("Crit Color","critColor");Color("Int Color","intColor")
    Slider("Buff Text Size","benefitsFontSize");Slider("Buff Window Width","benefitsWidth")
    Slider("Buff Window Scale","benefitsScale","%");Slider("Buff Window Opacity","benefitsOpacity","%")
    Slider("Buff Background Opacity","benefitsBackgroundOpacity","%")
    Slider("Buff Horizontal Offset","benefitsX");Slider("Buff Vertical Offset","benefitsY")
    page.campfireBuffReset=Button(page:Row("Buff Position",34),"Reset Buff Position",0,function()
        if addon.LootSparkles:OutsideCombat() then self:ResetWindowPosition(true) end
    end)
    Note("Buffs TLDR","Detach for independent size, background and position. Joined buffs share the icon window. Duration comes from the native tooltip; no added countdown.")
    page:Group("Camp Contributions")
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
            A:OnSnapshot(self.snapshot)
        end
    end)
    Slider("Contribution Scale","contributionScale","%");Slider("Contribution Opacity","contributionOpacity","%")
    Slider("Contribution Background","contributionBackgroundOpacity","%")
    page.refreshers[#page.refreshers+1]=function()
        page.contributionStatus:SetText(A:Summary())
        page.contributionPreview.label:SetText(A.previewing and "Stop Preview" or "Preview Contributions")
    end
    Note("Contributions TLDR","Ready bag kits appear at a fire. Click Place, then finish native targeting. Preview works anywhere. Drag the header or use Edit Contributions; Reset Position brings it back.",64)
end
