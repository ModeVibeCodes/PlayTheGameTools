local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local F,W=addon.ForeverFoodBar,addon.ConfigWidgets
function F:AddConfig(page)
    local function Toggle(label,key)
        page:ToggleGrid({{label=label,get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}})
    end
    page:Section("Food Bar")
    -- One switch for the bar: the saved enabled and shown flags turn on and off together.
    page:ToggleGrid({{label="Show Food Bar",get=function() return self:IsOn() end,set=function(v) self:SetShown(v) end}})
    Toggle("Include Bandages","includeBandages")
    local text=W.Label(page:Row("Food Bar Status",100),"",nil,0,-4,280,addon.Theme.muted);text:SetWordWrap(true)
    text:GetParent().row.visibleWhen=function() return self.active==true end
    -- No Refresh Bags button: BAG_UPDATE_DELAYED and ITEM_DATA_LOAD_RESULT rescan.
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
        text:SetText(self.message or "Carried food appears here outside combat.")
        for i,cell in ipairs(page.foodCells) do
            local p=self.foodChoices[i];local label=p and (p.name.." ("..p.count..")") or "Food item"
            cell.label:SetText(label);cell.searchEntry.label=label
            cell.frame:SetEnabled(p~=nil);cell.button:SetEnabled(p~=nil)
        end
        page:Layout()
    end
    -- Food bar styling lives in Layout (the Style card).
    page:ToggleGrid({{label="Food Tooltips",get=function() return self.db.showTooltips end,set=function(v) self:SetOption("showTooltips",v) end},
        {label="Show Food Names",get=function() return self.db.showNames end,set=function(v) self:SetOption("showNames",v) end}})
end
