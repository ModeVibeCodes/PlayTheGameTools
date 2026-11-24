local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.CityLabels,addon.ConfigWidgets,addon.InterfaceTheme

-- The single source line on the page. The full notice, word for word, stays
-- in Settings > About ("Data sources") and in the notice files.
M.SOURCE_LINE="Locations: Efficient Games (CC BY 4.0), with CMaNGOS classic-db (GPL-3.0) where none is recorded yet."

-- Opens Settings and flashes the About "Data sources" row, as search does.
function M:ShowDataSources()
    addon:SelectConfigPage("globalSettings")
    local settings=addon.configWindow and addon.configWindow.pages.globalSettings
    if not settings then return false end
    for _,entry in ipairs(settings.searchEntries) do
        if entry.label=="Data sources" then settings:Reveal(entry);return true end
    end
    return false
end

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
    -- One chip per saved service key, plus the other-faction filter.
    page:Group("Services")
    local services={}
    for _,entry in ipairs(self.CATEGORIES) do services[#services+1]=entry end
    local showNames
    for _,entry in ipairs(self.FILTERS) do
        if entry.key=="showNames" then showNames=entry else services[#services+1]=entry end
    end
    local chipItems={}
    for _,entry in ipairs(services) do
        local key=entry.key
        chipItems[#chipItems+1]={label=entry.label,get=function() return self.db[key] end,set=function(v) self:SetOption(key,v) end}
    end
    for i,chip in ipairs(W.Chips(page,chipItems)) do page.cityLabelControls[services[i].key]=chip end
    page:Group("Appearance")
    Grid({showNames})
    for _,entry in ipairs({{"Icon Size","iconSize"},{"Name Size","fontSize"}}) do
        local key=entry[2];local range=self.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(entry[1],48),range[1],range[2],range[3],
            function() return self.db[key] end,function(v) self:SetOption(key,v) end,nil,true)
    end
    -- Footnotes belong to no group; they end the page.
    page.activeGroup=nil
    local sourceRow=page:Row("Locations",40)
    sourceRow.rowLabel:Hide();sourceRow:ClearAllPoints();sourceRow:SetAllPoints(sourceRow.row)
    local note=W.Label(sourceRow,self.SOURCE_LINE,nil,0,-12,440,T.muted)
    note:SetWordWrap(true)
    local about=W.Button(sourceRow,"Full notice in About",160,26,"secondary")
    about:SetScript("OnClick",function() self:ShowDataSources() end)
    function sourceRow.row:layoutChildren(width)
        local textWidth=math.max(120,width-176)
        note:SetWidth(textWidth)
        local height=note:GetStringHeight()
        if (issecretvalue and issecretvalue(height)) or type(height)~="number" or height~=height or height<0 or height==math.huge then height=14 end
        self:SetHeight(math.max(40,height+24))
        about:ClearAllPoints();about:SetPoint("TOPRIGHT",self,"TOPRIGHT",0,-7)
    end
    page.cityLabelSource,page.cityLabelSourceButton=note,about
    local status=W.Label(page:Row("Map Status",40),"",nil,0,-4,440,T.muted)
    status:SetWordWrap(true)
    status:GetParent().row.visibleWhen=function() return addon.CityLabelsMap.lastError~=nil end
    page.refreshers[#page.refreshers+1]=function() status:SetText(addon.CityLabelsMap.lastError or "") end
    page.cityLabelStatus=status
    page:Finish()
    return page
end
