local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.CityLabels,addon.ConfigWidgets,addon.InterfaceTheme

-- Labels draw on the world map itself, so there is nothing to place in Edit Mode.
function M:CreateConfigPage(parent)
    local page=W.Page(parent,480)
    self.page=page
    page.cityLabelControls,page.cityLabelModes={},{}
    local function Grid(entries)
        local items={}
        for _,entry in ipairs(entries) do
            local key=entry.key
            items[#items+1]={label=entry.label,get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}
        end
        local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=210})
        for i,entry in ipairs(entries) do page.cityLabelControls[entry.key]=cells[i] end
    end
    page:Group("Labels")
    -- Mine follows your class and learned professions; All shows every trainer.
    for _,mode in ipairs(self.MODES) do
        local key=mode.key
        local choices={}
        for _,choice in ipairs(self.MODE_CHOICES) do choices[#choices+1]={label=choice.label,value=choice.value,width=96} end
        local buttons,refresh=W.Exclusive(page:Row(mode.label,48,{"trainer","mine","all","off"}),choices,
            function() return self.db[key] end,function(value) self:SetOption(key,value) end)
        page.cityLabelModes[key]=buttons
        page.refreshers[#page.refreshers+1]=refresh
    end
    Grid(self.CATEGORIES)
    page:Group("Filters")
    Grid(self.FILTERS)
    page:Group("Appearance")
    for _,entry in ipairs({{"Icon Size","iconSize"},{"Name Size","fontSize"}}) do
        local key=entry[2];local range=self.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(entry[1],48),range[1],range[2],range[3],
            function() return self.db[key] end,function(v) self:SetOption(key,v) end,nil,true)
    end
    page:Group("Source")
    local source=addon.CityLabelsData and addon.CityLabelsData.source
    local note=W.Label(page:Row("Locations",96),"Data from Efficient Games (efficient.games), licensed CC BY 4.0, from WoW: Forever client builds "
        ..(source and source.builds or "?").."; each label marks where players stood to use the service. Where they have not recorded one yet, "
        .."the Classic spawn position from CMaNGOS classic-db (GPL-3.0) is shown and its tooltip says so.",nil,0,-4,440,T.muted)
    note:SetWordWrap(true)
    page.cityLabelSource=note
    local status=W.Label(page:Row("Map Status",40),"",nil,0,-4,440,T.muted)
    status:SetWordWrap(true)
    status:GetParent().row.visibleWhen=function() return addon.CityLabelsMap.lastError~=nil end
    page.refreshers[#page.refreshers+1]=function() status:SetText(addon.CityLabelsMap.lastError or "") end
    page.cityLabelStatus=status
    page:Finish()
    return page
end
