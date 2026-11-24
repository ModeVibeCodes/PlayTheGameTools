local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local F,D,W=addon.ForeverFoodBar,addon.ForeverQuickAccessData,addon.ConfigWidgets
function F:AddConfig(page)
    local function Toggle(label,key)
        page:ToggleGrid({{label=label,get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}})
    end
    local function Slider(label,key,suffix)
        local r=D.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(label,48),r[1],r[2],r[3],function() return self.db[key] end,function(v) self:SetOption(key,v) end,suffix,true)
    end
    page:Section("Food Bar")
    -- One switch for the bar: the saved enabled and shown flags turn on and off together.
    page:ToggleGrid({{label="Show Food Bar",get=function() return self:IsOn() end,set=function(v) self:SetShown(v) end}})
    Toggle("Include Bandages","includeBandages")
    local text=W.Label(page:Row("Food Bar Status",100),"",nil,0,-4,280,addon.Theme.muted);text:SetWordWrap(true)
    text:GetParent().row.visibleWhen=function() return self.active==true end
    local refresh=W.Button(page:Row("Carried Items",48),"Refresh Bags",180,28);refresh:SetPoint("LEFT")
    refresh:SetScript("OnClick",function() if D.OutsideCombat() then self:Scan();self:Render();page:Refresh() end end)
    page.foodCells={}
    for i=1,self.limit do
        local cell=page:ToggleGrid({{label="Food item "..i,
            get=function() local p=(self.foodChoices or {})[i];return p and self.db.selected[p.id] or false end,
            set=function(v) local p=(self.foodChoices or {})[i];if p then self:Select(p.id,v) end end}})[1]
        cell.searchEntry=page.searchEntries[#page.searchEntries];cell.row=page.rows[#page.rows]
        cell.row.visibleWhen=function() return (self.foodChoices or {})[i]~=nil end
        page.foodCells[i]=cell
    end
    page.refreshers[#page.refreshers+1]=function()
        text:SetText(self.message or "Enable Food Bar or click Refresh Bags outside combat to select carried food.")
        for i,cell in ipairs(page.foodCells) do
            local p=self.foodChoices[i];local label=p and (p.name.." ("..p.count..")") or "Food item"
            cell.label:SetText(label);cell.searchEntry.label=label
            cell.frame:SetEnabled(p~=nil);cell.button:SetEnabled(p~=nil)
        end
        page:Layout()
    end
    page:Section("Food Layout")
    Slider("Food Bar Scale","scale","%")
    Slider("Food Icon Size","iconSize");Slider("Food Icons Per Row","columns")
    Slider("Food Icon Spacing","spacing");Slider("Food Bar Padding","padding")
    Toggle("Show Food Names","showNames");Slider("Food Font Size","fontSize")
    Toggle("Food Tooltips","showTooltips")
    page:Section("Food Appearance")
    local owner={db={appearance=self.db}}
    function owner:CanConfigure() return D.OutsideCombat() end
    function owner:SetAppearance(key,value) return F:SetOption(key,value) end
    function owner:GetFonts() return addon.Media:GetFonts() end
    local _,fontRefresh=W.FontDropdown(page:Row("Food Font"),owner);page.refreshers[#page.refreshers+1]=fontRefresh
    Toggle("Food Name Outline","outline")
    W.ColorRow(page,owner,"Food Background Color","backgroundColor");Slider("Food Background Opacity","backgroundOpacity","%")
    W.ColorRow(page,owner,"Food Border Color","borderColor");Slider("Food Border Opacity","borderOpacity","%")
    W.ColorRow(page,owner,"Food Text Color","textColor")
end
