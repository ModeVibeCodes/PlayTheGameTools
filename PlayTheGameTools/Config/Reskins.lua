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
    local function Select(label,key,choices)
        local b=W.Select(page:Row(label,44),250,choices,function()
            local v=M.db[key];for _,e in ipairs(choices()) do if e.id==v then return v,e.label end end;return v,v
        end,function(v) M:SetAppearance(key,v) end)
        page.refreshers[#page.refreshers+1]=function() b:Refresh() end
    end
    local function Choices(items) return function() local t={};for _,v in ipairs(items) do t[#t+1]={id=v,label=v} end;return t end end
    local function Media(kind)
        return function()
            local list=kind=="border" and addon.Media:GetBorders() or addon.Media:GetTextures();local result={}
            if kind=="texture" then result[1]={id="mode",label="Mode Surface"} end
            for _,e in ipairs(list) do result[#result+1]={id=e.key,label=e.label} end
            return result
        end
    end
    page:Section("Options",nil,false)
    Toggle("Show Quick Stats","quickStats");Toggle("Show Enhancements","enhancements")
    local status=W.Label(page:Row("Status",70),"",nil,0,-4,420,T.muted);status:SetWordWrap(true)
    page.refreshers[#page.refreshers+1]=function() status:SetText(M.active and (M.pending and "Waiting until out of combat." or M.status or "Waiting for character panel.") or "Disabled. Native appearance restored outside combat.") end
    page:Section("Text",nil,false)
    local _,refresh=W.FontDropdown(page:Row("Text Font",42),owner);page.refreshers[#page.refreshers+1]=refresh
    Slider("Font Size","fontSize");Toggle("Text Outline","outline");Toggle("Text Shadow","shadow")
    for _,e in ipairs({{"Text Color","textColor"},{"Enchant Color","enchantColor"},{"Weapon Enhancement Color","imbueColor"},{"Unknown Enhancement Color","unknownColor"}}) do W.ColorRow(page,owner,e[1],e[2]) end
    page:Section("Appearance",nil,false)
    Select("Surface Texture","texture",Media("texture"));Slider("Background Opacity","backgroundOpacity");Slider("Foreground Opacity","foregroundOpacity")
    for _,e in ipairs({{"Background Color","backgroundColor"},{"Foreground Color","foregroundColor"},{"Accent Color","accentColor"}}) do W.ColorRow(page,owner,e[1],e[2]) end
    page:Section("Borders",nil,false)
    Select("Border Media","border",Media("border"));Slider("Border Size","borderSize");Slider("Border Padding","padding")
    Slider("Border X Offset","borderX");Slider("Border Y Offset","borderY");Slider("Border Opacity","borderOpacity");W.ColorRow(page,owner,"Border Color","borderColor")
    page:Section("Position",nil,false)
    Select("Quick Stats Anchor","statsAnchor",Choices({"TOPLEFT","TOP","TOPRIGHT"}))
    Select("Quick Stats Alignment","statsAlign",Choices({"LEFT","CENTER","RIGHT"}))
    Slider("Quick Stats X Offset","statsX");Slider("Quick Stats Y Offset","statsY");Slider("Quick Stats Width","statsWidth")
    Select("Enhancement Alignment","enchantAlign",Choices({"AUTO","LEFT","CENTER","RIGHT"}))
    Slider("Enhancement X Offset","enchantX");Slider("Enhancement Y Offset","enchantY");Slider("Enhancement Width","enchantWidth")
    local note=W.Label(page:Row("About Character Reskins",130),"Uses the Mode palette regardless of your configuration theme. Media lists include registered SharedMedia assets, not every unregistered client file. Green: permanent enchants; lavender: weapon imbues; amber: unreadable enchant. Unrecognized effects keep a short name. Quick stats use player values outside combat; — means unavailable. Disable another addon's character skin before enabling this one. Changes apply outside combat; /reload restores a clean baseline.",nil,0,-4,420,T.muted)
    note:SetWordWrap(true);page:FooterNote(note)
    W.SectionTabs(page);page:Finish();return page
end
for _,id in ipairs({"damageMeterReskin","chatReskin"}) do
    addon.modules[id].CreateConfigPage=function(self,parent)
        local page=W.Page(parent,480);page:Section(self.title,nil,false)
        W.Label(page:Row("Planned Phase",90),"Not implemented yet. Refine Character Panel first; this page has no runtime changes or enable switch.",nil,0,-4,420,T.muted):SetWordWrap(true)
        page:Finish();return page
    end
end
