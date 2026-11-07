local _,addon=...
local W,PM,P=addon.ConfigWidgets,addon.PositionManager,addon.Positioning

-- Shared compact chooser, with plain centered selected text and bounded menu.
function W.Select(parent,width,choices,getter,setter)
    local button=W.Button(parent,"",width or 260,30)
    button:SetPoint("LEFT");button.label:SetJustifyH("CENTER");button.label:SetWidth((width or 260)-16)
    local menu=W.Popup(button,width or 260,240)
    W.Texture(menu,"Window")
    local scroll=CreateFrame("ScrollFrame",nil,menu);scroll:SetPoint("TOPLEFT",6,-6);scroll:SetPoint("BOTTOMRIGHT",-6,6);scroll:EnableMouseWheel(true)
    local content=CreateFrame("Frame",nil,scroll);content:SetSize((width or 260)-12,1);scroll:SetScrollChild(content)
    local rows,offset={},0
    function button:Refresh()
        local value,label=getter();self.label:SetText(label or tostring(value or ""))
        if not menu:IsShown() then return end
        local actualWidth=button:GetWidth()
        local items=choices();menu:SetSize(actualWidth,math.min(240,12+#items*30));content:SetSize(actualWidth-12,#items*30)
        W.PlacePopup(menu,button)
        local max=math.max(0,#items*30-228);offset=math.min(offset,max);scroll:SetVerticalScroll(offset)
        scroll:SetScript("OnMouseWheel",function(_,delta) offset=math.max(0,math.min(max,offset-delta*30));scroll:SetVerticalScroll(offset) end)
        for i,item in ipairs(items) do
            if not rows[i] then
                local row=W.Button(content,"",(width or 260)-12,28,"tab");rows[i]=row;row:SetPoint("TOPLEFT",0,-(i-1)*30)
                row:SetScript("OnClick",function() menu:Hide();setter(row.choice.id);button:Refresh() end)
            end
            local row=rows[i];row:SetWidth(actualWidth-12);row.label:SetWidth(actualWidth-28)
            row.choice=item;row.label:SetText(item.label);row:SetSelected(item.id==value);row:Show()
        end
        for i=#items+1,#rows do rows[i]:Hide() end
    end
    button:SetScript("OnClick",function()
        if InCombatLockdown() or UnitAffectingCombat("player") or not button:IsEnabled() then return end
        local shown=menu:IsShown();if addon.CloseFontDropdown then addon:CloseFontDropdown() end
        menu:SetShown(not shown);offset=0;button:Refresh()
    end)
    button:SetScript("OnHide",function() menu:Hide() end)
    addon.fontDropdownMenus=addon.fontDropdownMenus or {};addon.fontDropdownMenus[menu]=true
    button.menu,button.rows=menu,rows
    return button
end

function W.PositionControls(page,module)
    local function Position() return PM:GetPosition(module.positionElementId or module.id) end
    local id=module.positionElementId or module.id
    local function Attachment() return P:Attachment(Position(),PM.elements[id].subject.originPoint) end
    local function Refresh(fn) page.refreshers[#page.refreshers+1]=fn end
    local controls=page:Row("Anchor",48)
    local function Choices()
        local result={}
        local labels={screen="Screen",player="Player Frame",target="Target Frame",party="Party Frames",focus="Focus Frame",minimap="Minimap"}
        for _,item in ipairs(PM:GetAllowedTargets(id)) do
            local label=labels[item.id] or item.label
            result[#result+1]={id=item.id,label=label}
        end
        if PM.elements[id].allowedTargets.selected then result[#result+1]={id="picker",label="Select Frame"} end
        return result
    end
    local function Get()
        local position=Position();local target=position.target
        local label=target:sub(1,6)=="frame:" and target:sub(7) or target
        for _,choice in ipairs(Choices()) do if choice.id==target then label=choice.label;break end end
        if target~="screen" and not P:Resolve(target) then label=label.." (unavailable)" end
        return target,label=="screen" and "Screen" or label
    end
    local function Set(target)
        if target=="picker" then addon.FrameAnchors:Start(id)
        else PM:ChangeTarget(id,target);if module.ApplyAppearance then module:ApplyAppearance() end end
        if addon.RefreshConfig then addon:RefreshConfig() end
    end
    local anchor=W.Select(controls,280,function() return Choices() end,function() return Get() end,Set)
    function controls.row:layoutChildren(width)
        local fieldWidth=math.max(140,math.min(360,width-198))
        anchor:SetWidth(fieldWidth);anchor.label:SetWidth(fieldWidth-16)
    end
    page.anchorDropdown=anchor
    page.positionAnchorRows=page.positionAnchorRows or {};page.positionAnchorRows[#page.positionAnchorRows+1]=controls.row
    Refresh(function() anchor:Refresh() end)
    local currentPoint,currentRelative=Attachment()
    local mode=currentPoint==currentRelative and "align" or "outside"
    local modes,refreshModes=W.Exclusive(page:Row("Attachment Mode",48),{{label="Aligned",value="align",width=108},{label="Outside",value="outside",width=108}},function() return mode end,function(value)
        mode=value
        local _,relative=Attachment();PM:SetAlignment(id,relative,mode=="outside")
        if addon.RefreshConfig then addon:RefreshConfig() end
    end);page.attachmentModeButtons=modes;Refresh(refreshModes)
    local holder=page:Row("Anchor Preset",108)
    page.anchorPointButtons={}
    local labels={TOPLEFT="Top Left",TOP="Top",TOPRIGHT="Top Right",LEFT="Left",CENTER="Center",RIGHT="Right",BOTTOMLEFT="Bottom Left",BOTTOM="Bottom",BOTTOMRIGHT="Bottom Right"}
    for i,point in ipairs(P.points) do
        local button=W.Button(holder,labels[point],90,30,"choice")
        button:SetPoint("TOPLEFT",((i-1)%3)*94,-math.floor((i-1)/3)*34)
        button:SetScript("OnClick",function() PM:SetAlignment(id,point,mode=="outside");if addon.RefreshConfig then addon:RefreshConfig() end end)
        Refresh(function() local _,relative=Attachment();button:SetSelected(relative==point) end)
        page.anchorPointButtons[i]=button
    end
    -- Advanced fields distinguish the module attachment from the target point.
    for _,key in ipairs({"point","relativePoint"}) do
        local dropdown=W.Select(page:Row(key=="point" and "Module Point" or "Frame Point",48),260,function()
            local items={};for _,point in ipairs(P.points) do items[#items+1]={id=point,label=labels[point]} end;return items
        end,function() local point,relative=Attachment();local value=key=="point" and point or relative;return value,labels[value] end,function(value)
            local point,relative=Attachment();PM:SetAttachment(id,key=="point" and value or point,key=="relativePoint" and value or relative)
            if addon.RefreshConfig then addon:RefreshConfig() end
        end)
        Refresh(function() dropdown:Refresh() end)
    end
    for _,axis in ipairs({"x","y"}) do
        local row=page:Row(string.upper(axis).." Offset",48)
        local function Get() return Position()[axis] end
        local function Set(value) local position=Position();position[axis]=value;PM:SetPosition(id,position,true);if addon.RefreshConfig then addon:RefreshConfig() end end
        local function Extent() return math.ceil(axis=="x" and UIParent:GetWidth() or UIParent:GetHeight()) end
        local refresh=W.Slider(row,-Extent(),Extent(),5,Get,Set,nil,{minimum=function() return -Extent() end,maximum=Extent})
        Refresh(function() row.slider:SetMinMaxValues(-Extent(),Extent());refresh() end)
        page[axis.."PositionInput"],page[axis.."PositionSlider"]=row.numericInput,row.slider
    end
    local reset=W.Button(page:Row("Reset Position",48),"Reset Position",160,30,"secondary");reset:SetPoint("LEFT")
    reset:SetScript("OnClick",function() PM:ResetPosition(id);if addon.RefreshConfig then addon:RefreshConfig() end end)
    page.resetPositionButton=reset
    return anchor
end
