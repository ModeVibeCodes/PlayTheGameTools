local _,addon=...
local W,G,T=addon.ConfigWidgets,addon.Glow,addon.Theme

-- Opt-in frontend for owned glow consumers; no module-specific setting names.
-- options: get(), set(key,value), setParameter(style,key,value), canConfigure().
-- Optional allowedStyles set filters both choices and parameter/search rows.
function W.GlowControls(page,options)
    local function Enabled() return options.canConfigure() and options.get().enabled end
    local function Refresh(fn) page.refreshers[#page.refreshers+1]=fn end
    local pair=page:Row("",76)
    pair.rowLabel:Hide();pair:ClearAllPoints();pair:SetAllPoints(pair.row)
    local styleHost=CreateFrame("Frame",nil,pair);styleHost:SetHeight(30)
    local colorHost=CreateFrame("Frame",nil,pair);colorHost:SetHeight(30);colorHost.rowLabel=pair.rowLabel
    local styleLabel=W.Label(pair,"Glow Style",nil,12,-5,200,T.secondary)
    local colorLabel=W.Label(pair,"Glow Color",nil,12,-5,200,T.secondary)
    local style=W.GlowDropdown(styleHost,function() return options.get().style end,function(value) options.set("style",value) end,options.allowedStyles)
    local proxy={db={appearance=options.get()}}
    function proxy:CanConfigure() return Enabled() end
    function proxy:SetAppearance(key,value) return options.set(key,value) end
    local pick,hex,apply,swatch=W.ColorRow(page,proxy,"Glow Color","color",Enabled,colorHost,{immediateHex=true,separateSwatch=true})
    pick:ClearAllPoints();pick:SetPoint("LEFT",24,0);pick:SetWidth(72)
    hex:ClearAllPoints();hex:SetPoint("LEFT",104,0);hex:SetWidth(96)
    function pair.row:layoutChildren(width)
        local stacked=width<480
        local half=stacked and width or width/2
        self:SetHeight(stacked and 140 or 76)
        styleHost:ClearAllPoints();styleHost:SetPoint("TOPLEFT",12,-28);styleHost:SetWidth(half-24)
        colorHost:ClearAllPoints();colorHost:SetPoint("TOPLEFT",stacked and 12 or half+6,stacked and -92 or -28);colorHost:SetWidth(half-24)
        style:SetWidth(half-24);style.label:SetWidth(half-40)
        colorLabel:ClearAllPoints();colorLabel:SetPoint("TOPLEFT",stacked and 12 or half+6,stacked and -69 or -5)
        styleLabel:SetWidth(half-24);colorLabel:SetWidth(half-24)
    end
    Refresh(function() style:Refresh();style:SetEnabled(Enabled()) end)
    page.searchEntries[#page.searchEntries+1]={label="Glow Style",section=page.activeSection,row=pair.row,kind="setting"}
    page.searchEntries[#page.searchEntries+1]={label="Glow Color",section=page.activeSection,row=pair.row,kind="setting"}
    local result={style=style,styles={},colorPick=pick,colorHex=hex,colorSwatch=swatch,colorApply=apply,colorRow=pair.row}
    local function Grid(parameters,ownerStyle)
        local controls=page:Row("",68)
        controls.rowLabel:Hide();controls:ClearAllPoints();controls:SetAllPoints(controls.row)
        controls.row.visibleWhen=ownerStyle and function() return options.get().style==ownerStyle end or nil
        local cells={}
        for i,key in ipairs(parameters) do
            local definition=G.definitions[key] or {label=key=="opacity" and "Glow Opacity" or "Glow Intensity",minimum=0,maximum=100,step=5}
            local cell=CreateFrame("Frame",nil,controls)
            local label=W.Label(cell,definition.label,nil,10,-5,200,T.text)
            local field=CreateFrame("Frame",nil,cell);field:SetPoint("TOPLEFT",10,-25);field:SetPoint("BOTTOMRIGHT",-10,8)
            local function Get()
                return ownerStyle and options.get().styles[ownerStyle][key] or options.get()[key]*100
            end
            local function Set(value)
                if ownerStyle then options.setParameter(ownerStyle,key,value) else options.set(key,value/100) end
            end
            local refresh=W.Slider(field,definition.minimum,definition.maximum,definition.step,Get,Set,nil,
                definition.step<1 and {decimals=2} or true)
            Refresh(function()
                refresh();local enabled=Enabled() and (not ownerStyle or G.Available(ownerStyle))
                field.slider:SetEnabled(enabled);field.numericInput:SetEnabled(enabled)
            end)
            cells[i]={frame=cell,label=label,slider=field.slider,numericInput=field.numericInput,key=key}
            page.searchEntries[#page.searchEntries+1]={label=definition.label,section=page.activeSection,row=controls.row,kind="setting",
                onReveal=ownerStyle and function() options.set("style",ownerStyle) end or nil}
        end
        function controls.row:layoutChildren(width)
            local columns=width>=560 and 2 or 1
            self:SetHeight(math.ceil(#cells/columns)*68)
            for i,cell in ipairs(cells) do
                cell.frame:ClearAllPoints();cell.frame:SetPoint("TOPLEFT",((i-1)%columns)*width/columns,-math.floor((i-1)/columns)*68)
                cell.frame:SetSize(width/columns,68);cell.label:SetWidth(width/columns-20)
            end
        end
        return cells
    end
    for _,id in ipairs({"border","pulse","pixel","autocast","button","gcd","shape"}) do
        if not options.allowedStyles or options.allowedStyles[id] then result.styles[id]=Grid(G.parameters[id],id) end
    end
    result.common=Grid({"opacity","intensity"})
    return result
end
