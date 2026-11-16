local _,addon=...
local W=addon.ConfigWidgets

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
