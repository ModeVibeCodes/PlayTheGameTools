local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.LootSparkles,addon.ConfigWidgets,addon.InterfaceTheme

function M:CreateConfigPage(parent)
    local page=W.Page(parent,480); self.page=page
    page:Group("Loot Sparkles")
    page.sparkleControls={}
    for _,entry in ipairs({{"Quest Item Sparkles","questSparkles"},{"Ore Veins","ore"},
        {"Herbs","herbs"},{"Quest Objects","questObjects"},{"Corpses With Loot","corpses"},
        {"Show Object Names","showNames"}}) do
        local key=entry[2]
        page.sparkleControls[key]=page:ToggleGrid({{label=entry[1],
            get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}})[1]
    end
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
    page:Finish(); return page
end
