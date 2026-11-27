local _,addon=...
if not addon.ForeverRogue then return end
local M,D,W=addon.ForeverRogue,addon.ForeverRogueData,addon.ConfigWidgets
function M:CreateConfigPage(parent)
    local page=W.Page(parent,400);self.page=page
    page.poisonControls={};page.poisonSliders={};page.poisonGrid={}
    local function FullRow(label,height)
        local c=page:Row(label,height);c.rowLabel:Hide();c:ClearAllPoints();c:SetAllPoints(c.row)
        -- An unlabelled full-width row is not a search result: its controls add their own entries.
        if label=="" then table.remove(page.searchEntries) end
        return c,c.row
    end
    local function Note(text,height)
        local c,row=FullRow("",height or 44);local t=W.Label(c,text,nil,0,-8,380,addon.Theme.muted);t:SetWordWrap(true)
        row.layoutChildren=function(_,width) t:SetWidth(width-12) end
        if text and text~="" then page:FooterNote(t) end
        return t
    end
    -- e = {label, key[, style group]}: a group key is one display part's
    -- information switch (saved in that part's style table).
    local function Toggles(entries)
        local items={}
        for _,e in ipairs(entries) do local key,group=e[2],e[3]
            items[#items+1]={label=e[1],get=function() return (group and self.db[group] or self.db)[key] end,
                set=function(v) if group then self:SetStyle(group,key,v) else self:SetOption(key,v) end end}
        end
        local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=190})
        for i,e in ipairs(entries) do page.poisonControls[e[3] and (e[3]..":"..e[2]) or e[2]]=cells[i] end
    end
    local function Sliders(entries)
        for first=1,#entries,2 do
            local c,row=FullRow("",66);local cells={}
            for i=first,math.min(first+1,#entries) do
                local e=entries[i];local label,key,suffix=e[1],e[2],e[3];local r=D.ranges[key]
                local f=CreateFrame("Frame",nil,c);local text=W.Label(f,label,nil,0,-4,220,addon.Theme.secondary)
                local control=CreateFrame("Frame",nil,f);control:SetPoint("TOPLEFT",0,-23);control:SetPoint("BOTTOMRIGHT",0,4)
                page.refreshers[#page.refreshers+1]=W.Slider(control,r[1],r[2],r[3],function() return self.db[key] end,
                    function(v) self:SetOption(key,v) end,suffix,true)
                cells[#cells+1]={frame=f,label=text};page.poisonSliders["root:"..key]=control
                page.searchEntries[#page.searchEntries+1]={label=label,section=page.activeSection,row=row,kind="setting"}
            end
            row.layoutChildren=function(_,width)
                local cols=width>=420 and 2 or 1;local w=math.min(260,(width-(cols-1)*16)/cols);row:SetHeight(math.ceil(#cells/cols)*66)
                for i,cell in ipairs(cells) do cell.frame:ClearAllPoints();cell.frame:SetPoint("TOPLEFT",((i-1)%cols)*(w+16),-math.floor((i-1)/cols)*66);cell.frame:SetSize(w,62);cell.label:SetWidth(w) end
            end
        end
    end
    local function Select(label,choices,getter,setter)
        local select=W.Select(page:Row(label,44),230,function() return choices end,getter,setter)
        page.refreshers[#page.refreshers+1]=function() select:Refresh() end;return select
    end
    local function Buttons(entries)
        local c,row=FullRow("",38);local buttons={}
        for _,e in ipairs(entries) do local fn=e[2];local b=W.Button(c,e[1],130,28);buttons[#buttons+1]=b
            b:SetScript("OnClick",function() if self:CanConfigure() then fn();page:Refresh() end end)
            page.searchEntries[#page.searchEntries+1]={label=e[1],section=page.activeSection,row=row,kind="setting"}
        end
        row.layoutChildren=function(_,width)
            local w=math.min(160,(width-(#buttons-1)*8)/#buttons)
            for i,b in ipairs(buttons) do b:ClearAllPoints();b:SetPoint("TOPLEFT",(i-1)*(w+8),-4);b:SetWidth(w) end
        end
        return buttons
    end
    local function Visible(predicate) page.rows[#page.rows].visibleWhen=predicate end
    -- Two groups, as in the v2 mockup. Styling lives in Layout: Customize opens
    -- the display there. Layout-only keys (vertical, columns, label/timer
    -- positions, label text, visible menu rows) stay saved without a control.
    page:Section("Poison Reminder",nil,false)
    local function Reminder() return self.db.watcher and not self:HandedOver() end
    local handC,handRow=FullRow("",52)
    page.handoverNote=W.Label(handC,"Buff Reminders now shows your poison reminder, with the same time, charge and dismiss settings. Turn off its poison reminders to use this one again.",nil,0,-8,380,addon.Theme.muted)
    page.handoverNote:SetWordWrap(true)
    handRow.layoutChildren=function(_,width) page.handoverNote:SetWidth(width-12) end
    handRow.visibleWhen=function() return self:HandedOver() end
    Toggles({{"Show reminder","watcher"}});Visible(function() return not self:HandedOver() end)
    local choices={{id="needed",label="When Needed"},{id="neededOOC",label="When Needed (OOC)"},{id="alwaysOOC",label="Always Outside Combat"},{id="always",label="Always, Including Combat"}}
    page.reminderVisibility=Select("When",choices,function() for _,c in ipairs(choices) do if c.id==self.db.reminderVisibility then return c.id,c.label end end end,function(v) self:SetOption("reminderVisibility",v) end)
    Visible(Reminder)
    Toggles({{"Use Time Threshold","timeReminder"},{"Use Charge Threshold","chargeReminder"}});Visible(Reminder)
    Sliders({{"Reminder Threshold (min)","threshold"," min"},{"Charge Threshold","chargeThreshold"," charges"}});Visible(Reminder)
    Toggles({{"Show icons","showIcons","watchStyle"},{"Show weapon hands","showHands","watchStyle"},{"Show poison names","showNames","watchStyle"},
        {"Show time left","showTimers","watchStyle"},{"Show item counts","showCounts","watchStyle"},
        {"Show poison charges","showPoisonCharges"},{"Right-click to dismiss","dismissOnRightClick"}});Visible(Reminder)
    page.displayButtons={Buttons({{"Customize Reminder",function() addon:EditElementAppearance("roguePoisonReminder") end}})[1]}
    page:Section("Quick Poisons",nil,false)
    local function Quick() return self.db.flyout end
    Toggles({{"Show quick poisons","flyout"}})
    page.quickVisibility=Select("When",{{id="needed",label="When Needed"},{id="always",label="Always Outside Combat"}},function()
        return self.db.alwaysShow and "always" or "needed",self.db.alwaysShow and "Always Outside Combat" or "When Needed"
    end,function(v) self:SetOption("alwaysShow",v=="always") end)
    Visible(Quick)
    local directions={{label="Up",value="UP",width=72},{label="Down",value="DOWN",width=72},{label="Left",value="LEFT",width=72},{label="Right",value="RIGHT",width=72}}
    local menu,refreshMenu=W.Exclusive(page:Row("Menu opens",44,{"direction","menu direction"}),directions,
        function() return self.db.direction end,function(v) self:SetOption("direction",v);page:Refresh() end)
    page.directionButtons=menu;page.refreshers[#page.refreshers+1]=refreshMenu;Visible(Quick)
    Toggles({{"Show icon","showIcons","launcherStyle"},{"Show icon label","showNames","launcherStyle"},{"Show icon count","showCounts","launcherStyle"},
        {"Icon tooltip","tooltips","launcherStyle"},{"Show menu icons","showIcons","flyoutStyle"},{"Show menu names","showNames","flyoutStyle"},
        {"Show menu counts","showCounts","flyoutStyle"},{"Menu tooltips","tooltips","flyoutStyle"}});Visible(Quick)
    page.displayButtons[2]=Buttons({{"Customize Quick Access",function() addon:EditElementAppearance("rogueQuickPoisons") end}})[1]
    page:Section("Settings",nil,false)
    local c,gridRow=FullRow("Poison Refresh Quick Apply",92)
    for i=1,6 do
        local family=i>1 and D.families[i-1] or nil
        local b=CreateFrame("Button",nil,c,"BackdropTemplate");page.poisonGrid[i]=b;b.family=family
        addon.Media:ApplyBackdrop(b,{edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2},"foreverRogue")
        b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetPoint("TOPLEFT",2,-2);b.icon:SetPoint("BOTTOMRIGHT",-2,2);b.icon:SetTexCoord(0.06,0.94,0.06,0.94)
        local stripe=b:CreateTexture(nil,"OVERLAY");stripe:SetPoint("BOTTOMLEFT",2,2);stripe:SetPoint("BOTTOMRIGHT",-2,2);stripe:SetHeight(18);stripe:SetColorTexture(0,0,0,0.85)
        b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.label:SetPoint("BOTTOM",0,5);b.label:SetFont(addon.Media:GetInterfaceFont(),10,"OUTLINE");b.label:SetTextColor(1,0.95,0.65)
        b.count=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.count:SetPoint("TOPRIGHT",-4,-4);b.count:SetFont(addon.Media:GetInterfaceFont(),11,"OUTLINE")
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        b:SetScript("OnClick",function() if self:CanConfigure() and b.available then self:SetOption("quickApply",family and ("family:"..family) or "last");page:Refresh() end end)
        b:SetScript("OnEnter",function() if GameTooltip then GameTooltip:SetOwner(b,"ANCHOR_TOP");GameTooltip:SetText(b.tip or "Poison");GameTooltip:Show() end end)
        b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    end
    gridRow.layoutChildren=function(_,width)
        local cols=width>=516 and 6 or 3;gridRow:SetHeight(math.ceil(6/cols)*88)
        for i,b in ipairs(page.poisonGrid) do b:ClearAllPoints();b:SetPoint("TOPLEFT",((i-1)%cols)*86,-6-math.floor((i-1)/cols)*88);b:SetSize(76,76);b.label:SetWidth(72) end
    end
    page.settingsButtons=Buttons({{"Refresh Poisons",function() self:Refresh() end},{"Restore Dismissed",function() self:RestoreReminders() end},{"Dismiss Quick Access",function() self:DismissQuickAccess() end}})
    local status=Note("",52);page.poisonStatus=status
    -- Shown only for a real message, never to repeat the module switch.
    local function StatusText() return not self.isRogue and "Rogue characters only." or self.active and (self.lastMessage or self.status) or nil end
    status:GetParent().row.visibleWhen=function() return StatusText()~=nil end
    page.refreshers[#page.refreshers+1]=function()
        local selected=self.byKey[self.db.quickApply];local family=selected and selected.family or D.FamilyForKey(self.db.quickApply)
        for i,b in ipairs(page.poisonGrid) do
            local p=b.family and D.Spell(b.family) or D.Spell(2842);local name=p and p.name or ({"Recent","Instant","Deadly","Crippling","Mind-numbing","Wound"})[i]
            local count=0;for _,item in ipairs(self.choices) do if item.family==b.family and item.count then count=count+item.count end end
            b.available=not b.family or self:Available(self.known[b.family]) or false
            b.icon:SetTexture(p and p.icon or "Interface\\Icons\\Trade_BrewPoison");b.icon:SetDesaturated(not b.available);b.icon:SetVertexColor(b.available and 1 or 0.4,b.available and 1 or 0.4,b.available and 1 or 0.4)
            b.label:SetText(i==1 and "Recent" or name:match("^(%S+)"));b.count:SetText(b.family and tostring(count) or "")
            b.tip=i==1 and "Most Recent — use each hand's last observed poison." or (name.." — "..count.." carried"..(b.available and ". Select for quick apply." or ". Not learned or available in your inventory."))
            b:SetEnabled(self:CanConfigure() and b.available)
            local active=i==1 and self.db.quickApply=="last" or b.family and family==b.family
            b:SetBackdropBorderColor(active and 1 or 0.28,active and 0.85 or 0.32,active and 0.3 or 0.38,1)
        end
        page.settingsButtons[2]:SetEnabled(self.active and (next(self.dismissed)~=nil or self.quickDismissed==true))
        page.settingsButtons[3]:SetEnabled(self.active and self.db.flyout and not self.quickDismissed and not self.editing and not self.previewing)
        page.displayButtons[1]:SetEnabled(self:PartOn("watcher"));page.displayButtons[2]:SetEnabled(self.db.flyout)
        status:SetText(StatusText() or "")
        page:Layout()
    end
    page:Finish();return page
end
