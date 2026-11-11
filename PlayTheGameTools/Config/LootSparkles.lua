local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.LootSparkles,addon.ConfigWidgets,addon.InterfaceTheme

function M:CreateConfigPage(parent)
    local page=W.Page(parent,480); self.page=page
    page:Section("Loot Sparkles",nil,false)
    page:Group("Options")
    page.sparkleControls={}
    local options,keys={},{}
    for _,entry in ipairs({{"Enable Loot Sparkles","sparklesEnabled"},{"Quest Item Sparkles","questSparkles"},{"Ore Veins","ore"},
        {"Herbs","herbs"},{"Quest Objects","questObjects"},{"Corpses With Loot","corpses"},
        {"Show Object Names","showNames"}}) do
        local key=entry[2]
        keys[#keys+1]=key
        options[#options+1]={label=entry[1],get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}
    end
    local cells=page:ToggleGrid(options,{maxColumns=2,minimumCellWidth=210})
    for i,key in ipairs(keys) do page.sparkleControls[key]=cells[i] end
    page:Group("Appearance")
    for _,entry in ipairs({{"Sparkle Size","size"},{"Sparkle Opacity","opacity"},
        {"Name Font Size","fontSize"},{"Vertical Offset","offsetY"}}) do
        local key=entry[2]; local range=self.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(entry[1],48),range[1],range[2],range[3],
            function() return self.db[key] end,function(v) self:SetOption(key,v) end,key=="opacity" and "%" or nil,true)
    end
    page:Group("Availability")
    local status=W.Label(page:Row("Loot Sparkles Status",80),"",nil,0,-4,440,T.muted)
    status:SetWordWrap(true); page.sparkleStatus=status
    page.refreshers[#page.refreshers+1]=function() status:SetText(self.status or "Disabled.") end
    local note=W.Label(page:Row("How It Works",200),
        "Highlights the one nearby object selected by the game's Interact Key system, not every node. Enabling turns on Interact Key and object icons; you can change them afterwards. Custom sparkles pause in combat. Gold is in reach; dim is out of reach or unknown; grey means unavailable. A native nameplate may also appear. Disable Forever Loot Sparkles and Lueur before using this module. Turning this module off restores settings it still owns. Quest sparkle removal may require a full game restart, not /reload.",nil,0,-4,440,T.muted)
    note:SetWordWrap(true)
    page:FooterNote(note)
    local campSection=page:Section("Campfire Monitor",nil,false)
    addon.CampfireMonitor:AddConfig(page)
    W.SectionTabs(page)
    page.sectionTabs:SetPoint("TOPLEFT",0,0);page.sectionTabs:SetPoint("TOPRIGHT",-24,0)
    page.scroll:ClearAllPoints();page.scroll:SetPoint("TOPLEFT",0,-40);page.scroll:SetPoint("BOTTOMRIGHT",-24,0)
    page.scrollbar:ClearAllPoints();page.scrollbar:SetPoint("TOPRIGHT",-4,-44);page.scrollbar:SetPoint("BOTTOMRIGHT",-4,4)
    page.OnSectionTabChanged=function(_,section)
        if section~=campSection then addon.CampfireMonitor:StopPreview() end
    end
    page:SetScript("OnHide",function() addon.CampfireMonitor:StopPreview() end)
    page:Finish(); return page
end
