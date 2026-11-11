local _,addon=...
local M,W,T=addon.CharacterReskin,addon.ConfigWidgets,addon.InterfaceTheme
if not M then return end
function M:CreateConfigPage(parent)
    local page=W.Page(parent,480);self.page=page
    local owner={db={appearance=self.db}}
    function owner:CanConfigure() return M:CanConfigure() end
    function owner:SetAppearance(k,v) return M:SetAppearance(k,v) end
    function owner:GetFonts() return M:GetFonts() end
    local function Slider(label,key)
        local r=M.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(label,48),r[1],r[2],r[3],function() return M.db[key] end,function(v) M:SetAppearance(key,v) end,nil,true)
    end
    local function Toggle(label,key)
        page:ToggleGrid({{label=label,get=function() return M.db[key] end,set=function(v) M:SetAppearance(key,v) end}})
    end
    page:Section("Options",nil,false)
    Toggle("Show Enhancements","enhancements");Toggle("Show Gold","showGold");Toggle("Show Durability","showDurability")
    local status=W.Label(page:Row("Status",70),"",nil,0,-4,420,T.muted);status:SetWordWrap(true)
    page.refreshers[#page.refreshers+1]=function() status:SetText(M.active and (M.pending and "Waiting until out of combat." or M.status or "Waiting for character panel.") or "Disabled. Native appearance restored outside combat.") end
    page:Section("Quick Stats",nil,false)
    Toggle("Show Quick Stats","quickStats")
    local quickOwner={db={appearance=self.db.quickStyle}}
    function quickOwner:CanConfigure() return M:CanConfigure() end
    function quickOwner:GetFonts() return M:GetFonts() end
    function quickOwner:SetAppearance(key,value)
        local style=addon.ProfileCodec.Copy(M.db.quickStyle);style[key]=value;return M:SetAppearance("quickStyle",style)
    end
    page.refreshers[#page.refreshers+1]=function() quickOwner.db.appearance=M.db.quickStyle end
    local _,quickRefresh=W.FontDropdown(page:Row("Quick Stats Font",42),quickOwner);page.refreshers[#page.refreshers+1]=quickRefresh
    page.refreshers[#page.refreshers+1]=W.Slider(page:Row("Quick Stats Font Size",48),8,22,1,function() return M.db.quickStyle.fontSize end,function(v) quickOwner:SetAppearance("fontSize",v) end,nil,true)
    page:ToggleGrid({{label="Quick Stats Outline",get=function() return M.db.quickStyle.outline end,set=function(v) quickOwner:SetAppearance("outline",v) end},
        {label="Quick Stats Shadow",get=function() return M.db.quickStyle.shadow end,set=function(v) quickOwner:SetAppearance("shadow",v) end}},{maxColumns=2,minimumCellWidth=210})
    W.ColorRow(page,quickOwner,"Quick Stats Color","textColor")
    Slider("Quick Stats Gap","quickStatsX");Slider("Quick Stats Y Offset","quickStatsY");Slider("Quick Stats Width","quickStatsWidth")
    page:Group("Displayed Stats")
    local choices={}
    for _,name in ipairs(M.statNames) do
        local stat=name
        choices[#choices+1]={label=stat,get=function() return M.db.statsShown[stat] end,set=function(v)
            local selected=addon.ProfileCodec.Copy(M.db.statsShown);selected[stat]=v;M:SetAppearance("statsShown",selected)
        end}
    end
    page.statControls=page:ToggleGrid(choices,{maxColumns=2,minimumCellWidth=210})
    page:Section("Text",nil,false)
    local _,refresh=W.FontDropdown(page:Row("Text Font",42),owner);page.refreshers[#page.refreshers+1]=refresh
    Slider("Font Size","fontSize");Toggle("Text Outline","outline");Toggle("Text Shadow","shadow")
    for _,e in ipairs({{"Text Color","textColor"},{"Enchant Color","enchantColor"},{"Weapon Enhancement Color","imbueColor"}}) do W.ColorRow(page,owner,e[1],e[2]) end
    Slider("Character Name Size","titleSize")
    page:Section("Appearance",nil,false)
    W.ColorRow(page,owner,"Panel Color","panelColor");Slider("Panel Opacity","panelOpacity")
    Slider("Class Icon Size","portraitSize");Slider("Item Rarity Border Size","itemBorderSize")
    W.ColorRow(page,owner,"Control Accent Color","accentColor")
    page:Section("Borders",nil,false)
    Slider("Panel Border Size","frameSize");Slider("Panel Border Opacity","frameOpacity")
    W.ColorRow(page,owner,"Panel Border Color","frameColor")
    page:Section("Position",nil,false)
    Slider("Enhancement X Offset","enchantX");Slider("Enhancement Y Offset","enchantY");Slider("Enhancement Width","enchantWidth")
    local note=W.Label(page:Row("About Character Reskins",130),"Uses the Mode palette regardless of your configuration theme. The panel uses the same dark Mode navigation material. Green: permanent enchants; lavender: recognized weapon imbues. Unreadable enhancements are hidden. Unrecognized effects keep a short name. Quick stats use player values outside combat; a dash means unavailable. Disable another addon's character skin before enabling this one. Changes apply outside combat; /reload restores a clean baseline.",nil,0,-4,420,T.muted)
    note:SetWordWrap(true);page:FooterNote(note)
    W.SectionTabs(page)
    -- This page has no Preview layer to reserve the tab strip's height.
    -- Keep the scroll viewport and its scrollbar entirely below the pills.
    if page.sectionTabs then
        page.sectionTabs:ClearAllPoints();page.sectionTabs:SetPoint("TOPLEFT");page.sectionTabs:SetPoint("TOPRIGHT",-24,0)
        local top=page.sectionTabs:GetHeight()+12
        page.scroll:ClearAllPoints();page.scroll:SetPoint("TOPLEFT",0,-top);page.scroll:SetPoint("BOTTOMRIGHT",-24,0)
        page.scrollbar:ClearAllPoints();page.scrollbar:SetPoint("TOPRIGHT",-4,-top-4);page.scrollbar:SetPoint("BOTTOMRIGHT",-4,4)
        page.tabContentTop=top
    end
    page:Finish();return page
end
for _,id in ipairs({"damageMeterReskin","chatReskin"}) do
    addon.modules[id].CreateConfigPage=function(self,parent)
        local page=W.Page(parent,480);page:Section(self.title,nil,false)
        W.Label(page:Row("Planned Phase",90),"Not implemented yet. Refine Character Panel first; this page has no runtime changes or enable switch.",nil,0,-4,420,T.muted):SetWordWrap(true)
        page:Finish();return page
    end
end
