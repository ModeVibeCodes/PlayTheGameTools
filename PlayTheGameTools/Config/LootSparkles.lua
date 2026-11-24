local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.LootSparkles,addon.ConfigWidgets,addon.InterfaceTheme

function M:CreateConfigPage(parent)
    local page=W.Page(parent,480); self.page=page
    -- Its own page since the v2 split. The module switch is the only enable.
    page.sparkleControls={}
    local function Option(label,key) return {label=label,key=key,get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end} end
    page:Group("Sparkle On")
    local targets={Option("Quest Item Sparkles","questSparkles"),Option("Ore Veins","ore"),Option("Herbs","herbs"),
        Option("Quest Objects","questObjects"),Option("Corpses With Loot","corpses")}
    for i,chip in ipairs(W.Chips(page,targets)) do page.sparkleControls[targets[i].key]=chip end
    page:Group("Options")
    page.sparkleControls.showNames=page:ToggleGrid({Option("Show Object Names","showNames")},{maxColumns=2,minimumCellWidth=210})[1]
    page:Group("Appearance")
    for _,entry in ipairs({{"Sparkle Size","size"},{"Sparkle Opacity","opacity"},
        {"Name Font Size","fontSize"},{"Vertical Offset","offsetY"}}) do
        local key=entry[2]; local range=self.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(entry[1],48),range[1],range[2],range[3],
            function() return self.db[key] end,function(v) self:SetOption(key,v) end,key=="opacity" and "%" or nil,true)
    end
    -- Shown only for a real notice, never to repeat the on/off switches.
    page:Group("Availability")
    local status=W.Label(page:Row("Loot Sparkles Status",80),"",nil,0,-4,440,T.muted)
    status:SetWordWrap(true); page.sparkleStatus=status
    local availability=page.rows[#page.rows-1]
    status:GetParent().row.visibleWhen=function() return self:StatusNotice()~=nil end
    availability.visibleWhen=status:GetParent().row.visibleWhen
    page.refreshers[#page.refreshers+1]=function() status:SetText(self:StatusNotice() or "");page:Layout() end
    page:Finish(); return page
end
