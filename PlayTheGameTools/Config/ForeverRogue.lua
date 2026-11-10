local _,addon=...
if not addon.ForeverRogue then return end
local M,D,W=addon.ForeverRogue,addon.ForeverRogueData,addon.ConfigWidgets
function M:CreateConfigPage(parent)
    local page=W.Page(parent,400);self.page=page
    page.poisonControls={};page.poisonStyles={};page.poisonSliders={};page.poisonGrid={};page.positionControls={};page.iconGroups={}
    local function FullRow(label,height)
        local c=page:Row(label,height);c.rowLabel:Hide();c:ClearAllPoints();c:SetAllPoints(c.row);return c,c.row
    end
    local function Note(text,height)
        local c,row=FullRow("",height or 44);local t=W.Label(c,text,nil,0,-8,380,addon.Theme.muted);t:SetWordWrap(true)
        row.layoutChildren=function(_,width) t:SetWidth(width-12) end;return t
    end
    local function Toggles(entries,group)
        local items={}
        for _,e in ipairs(entries) do local key=e[2]
            items[#items+1]={label=e[1],get=function() return (group and self.db[group] or self.db)[key] end,
                set=function(v) if group then self:SetStyle(group,key,v) else self:SetOption(key,v) end end}
        end
        local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=190})
        if group then page.poisonStyles[group]=page.poisonStyles[group] or {} end
        for i,e in ipairs(entries) do (group and page.poisonStyles[group] or page.poisonControls)[e[2]]=cells[i] end
    end
    local function Sliders(entries,group)
        for first=1,#entries,2 do
            local c,row=FullRow("",66);local cells={}
            for i=first,math.min(first+1,#entries) do
                local e=entries[i];local label,key,suffix=e[1],e[2],e[3];local r=group and D.styleRanges[key] or D.ranges[key]
                local f=CreateFrame("Frame",nil,c);local text=W.Label(f,label,nil,0,-4,220,addon.Theme.secondary)
                local control=CreateFrame("Frame",nil,f);control:SetPoint("TOPLEFT",0,-23);control:SetPoint("BOTTOMRIGHT",0,4)
                page.refreshers[#page.refreshers+1]=W.Slider(control,r[1],r[2],r[3],function() return (group and self.db[group] or self.db)[key] end,
                    function(v) if group then self:SetStyle(group,key,v) else self:SetOption(key,v) end end,suffix,true)
                cells[#cells+1]={frame=f,label=text};page.poisonSliders[(group or "root")..":"..key]=control
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
        end
        row.layoutChildren=function(_,width)
            local w=math.min(160,(width-(#buttons-1)*8)/#buttons)
            for i,b in ipairs(buttons) do b:ClearAllPoints();b:SetPoint("TOPLEFT",(i-1)*(w+8),-4);b:SetWidth(w) end
        end
        return buttons
    end
    local function Visible(predicate,build)
        local start=#page.rows;build();for i=start+1,#page.rows do page.rows[i].visibleWhen=predicate end
    end
    local function AppearanceOwner(group)
        local owner={db={appearance=self.db[group]}}
        function owner:CanConfigure() return M:CanConfigure() end
        function owner:SetAppearance(key,value) return M:SetStyle(group,key,value) end
        function owner:GetFonts() return addon.Media:GetFonts() end
        return owner
    end
    local function IconControls(group,reminder)
        page:Group(reminder and "Poison Reminder Icons" or "Quick Access Poisons Icon")
        page.iconGroups[group]=page.rows[#page.rows]
        Sliders({{"Icon Size","iconSize"},
            {reminder and "Icon Gap" or "Icon Opacity",reminder and "iconGap" or "iconOpacity",not reminder and "%" or nil},
            {"Icon Border Size","iconBorderSize"},{"Icon Border Opacity","iconBorderOpacity","%"}},group)
        W.ColorRow(page,AppearanceOwner(group),"Icon Border Color","iconBorderColor")
    end
    local function Style(group,launcher,reminder)
        local owner=AppearanceOwner(group)
        if not launcher and not reminder then
            Sliders({{"Icon Size","iconSize"},{"Icon Border Size","iconBorderSize"}},group)
        end
        Sliders({{"Scale","scale","%"},{"Window Opacity","opacity","%"},{"Window Padding","padding"},
            {"Icon Background Opacity","iconBackgroundOpacity","%"}},group)
        if not launcher and not reminder then Sliders({{"Icon Border Opacity","iconBorderOpacity","%"}},group) end
        if not launcher then Sliders({{"Icon Opacity","iconOpacity","%"}},group) end
        W.ColorRow(page,owner,"Icon Background Color","iconBackgroundColor")
        if not launcher and not reminder then W.ColorRow(page,owner,"Icon Border Color","iconBorderColor") end
        if launcher then
            Toggles({{"Show Label","showNames"},{"Show Inventory Count","showCounts"},{"Crop Icon","cropIcons"},{"Show Tooltip","tooltips"}},group)
            Sliders({{"Text Size","fontSize"},{"Label Gap","labelGap"}},group)
            local c=page:Row("Label Text",42);local input=CreateFrame("EditBox",nil,c);input:SetSize(150,26);input:SetPoint("LEFT");input:SetAutoFocus(false);input:SetMaxLetters(40);input:SetFontObject(GameFontHighlight)
            W.Texture(input,"InputField");input:SetTextInsets(6,6,0,0)
            local apply=W.Button(c,"Apply",64,26);apply:SetPoint("LEFT",input,"RIGHT",8,0)
            local function Apply() self:SetStyle(group,"labelText",input:GetText());input:ClearFocus();input:SetText(self.db[group].labelText) end
            apply:SetScript("OnClick",Apply);input:SetScript("OnEnterPressed",Apply)
            input:SetScript("OnEscapePressed",function() input:ClearFocus();input:SetText(self.db[group].labelText) end)
            page.refreshers[#page.refreshers+1]=function() if not input:HasFocus() then input:SetText(self.db[group].labelText) end end;page.launcherLabelInput=input
            Select("Label Position",{{id="TOP",label="Above Icon"},{id="CENTER",label="On Icon"},{id="BOTTOM",label="Below Icon"}},function()
                local v=self.db[group].labelPosition;return v,v=="TOP" and "Above Icon" or v=="CENTER" and "On Icon" or "Below Icon"
            end,function(v) self:SetStyle(group,"labelPosition",v) end)
        else
            Toggles({{"Show Icons","showIcons"},{"Show Hand Labels","showHands"},{"Show Poison Names","showNames"},{"Show Inventory Counts","showCounts"}},group)
            Sliders({{"Text Size","fontSize"},{"Label Gap","labelGap"}},group)
            if not reminder then Sliders({{"Cell Width","cellWidth"},{"Icon Spacing","spacing"}},group) end
            if reminder then
                Toggles({{"Show Remaining Time","showTimers"},{"Vertical Layout","vertical"}},group);Sliders({{"Timer Text Size","timerSize"}},group)
                Select("Timer Position",{{id="CENTER",label="On Icon"},{id="TOP",label="Above Icon"},{id="BOTTOM",label="Below Labels"}},function()
                    local v=self.db[group].timerPosition;return v,v=="TOP" and "Above Icon" or v=="BOTTOM" and "Below Labels" or "On Icon"
                end,function(v) self:SetStyle(group,"timerPosition",v) end)
                W.ColorRow(page,owner,"Timer Color","timerColor")
            else Sliders({{"Poison Columns","columns"}},group) end
        end
        Toggles({{"Text Outline","outline"}},group)
        local _,fontRefresh=W.FontDropdown(page:Row("Text Font",42),owner);page.refreshers[#page.refreshers+1]=fontRefresh
        W.ColorRow(page,owner,"Text Color","textColor");W.ColorRow(page,owner,"Icon Tint","iconColor")
        Sliders({{"Window Background Opacity","backgroundOpacity","%"},{"Window Border Opacity","borderOpacity","%"},{"Window Border Size","borderSize"}},group)
        W.ColorRow(page,owner,"Window Background Color","backgroundColor");W.ColorRow(page,owner,"Window Border Color","borderColor")
    end
    page:Section("Display",nil,false)
    Toggles({{"Poison Reminder","watcher"},{"Quick Access Poisons","flyout"}})
    local choices={{id="needed",label="When Needed"},{id="neededOOC",label="When Needed (OOC)"},{id="alwaysOOC",label="Always Outside Combat"},{id="always",label="Always, Including Combat"}}
    page.reminderVisibility=Select("Reminder Visibility",choices,function() for _,c in ipairs(choices) do if c.id==self.db.reminderVisibility then return c.id,c.label end end end,function(v) self:SetOption("reminderVisibility",v) end)
    page.quickVisibility=Select("Quick Access Visibility",{{id="needed",label="When Needed"},{id="always",label="Always Outside Combat"}},function()
        return self.db.alwaysShow and "always" or "needed",self.db.alwaysShow and "Always Outside Combat" or "When Needed"
    end,function(v) self:SetOption("alwaysShow",v=="always") end)
    Toggles({{"Use Time Threshold","timeReminder"},{"Use Charge Threshold","chargeReminder"}})
    Sliders({{"Reminder Threshold (min)","threshold"," min"},{"Charge Threshold","chargeThreshold"," charges"}})
    Note("Either enabled threshold can show a reminder. Missing poison always needs attention; poisons without readable charges use the timer.",48)
    Toggles({{"Right-click to Dismiss","dismissOnRightClick"},{"Show Poison Charges","showPoisonCharges"}})
    Visible(function() return self.db.watcher end,function() IconControls("watchStyle",true) end)
    Visible(function() return self.db.flyout end,function() IconControls("launcherStyle",false) end)
    page.displayButtons=Buttons({{"Customize Reminder",function() page.customize=page.customize=="reminder" and nil or "reminder" end},{"Customize Quick Access",function() page.customize=page.customize=="quick" and nil or "quick" end}})
    Visible(function() return page.customize=="reminder" and self.db.watcher end,function()
        page:Group("Poison Reminder Appearance");Style("watchStyle",false,true);Buttons({{"Minimal",function() self:MinimalReminder() end}})
    end)
    Visible(function() return page.customize=="quick" and self.db.flyout end,function()
        page:Group("Quick Access Appearance")
        Select("Customize",{{id="icon",label="Icon and Label"},{id="menu",label="Expanded Menu"}},function() return page.quickCustomize or "icon",page.quickCustomize=="menu" and "Expanded Menu" or "Icon and Label" end,function(v) page.quickCustomize=v;page:Refresh() end)
    end)
    Visible(function() return page.customize=="quick" and self.db.flyout and page.quickCustomize~="menu" end,function() Style("launcherStyle",true,false) end)
    Visible(function() return page.customize=="quick" and self.db.flyout and page.quickCustomize=="menu" end,function()
        Style("flyoutStyle",false,false)
        Select("Menu Direction",{{id="UP",label="Up"},{id="DOWN",label="Down"},{id="LEFT",label="Left"},{id="RIGHT",label="Right"}},function() return self.db.direction end,function(v) self:SetOption("direction",v) end)
        Sliders({{"Visible Menu Rows","visibleRows"}})
    end)
    page:Section("Settings",nil,false)
    Note("Choose the poison applied by the reminder buttons. Recent follows the last-used poison for each hand; unavailable types are greyed out.",48)
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
    page.settingsButtons=Buttons({{"Refresh Poisons",function() self:Refresh() end},{"Restore Dismissed",function() self:RestoreReminders() end}})
    local status=Note("",52);page.poisonStatus=status
    page:Section("Position",nil,false)
    local function Position(quick)
        local enabled=quick and "flyout" or "watcher";local lock=quick and "flyoutLocked" or "locked"
        Visible(function() return self.enabled and self.db[enabled] end,function()
            page:Group(quick and "Quick Access Poisons" or "Poison Reminder")
            local buttons=Buttons({{"Enter Edit Mode",function() self:EnterElementEdit(quick) end},{"Reset Position",function() self:ResetElementPosition(quick) end},{"Lock Position",function() self:SetOption(lock,not self.db[lock]) end}})
            page.positionControls[enabled]=buttons;page.refreshers[#page.refreshers+1]=function() buttons[3]:SetSelected(self.db[lock]) end
            Sliders({{"X",quick and "menuX" or "x"},{"Y",quick and "menuY" or "y"}})
        end)
    end
    Position(false);Position(true)
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
        page.settingsButtons[2]:SetEnabled(self.active and next(self.dismissed)~=nil)
        page.displayButtons[1]:SetEnabled(self.db.watcher);page.displayButtons[2]:SetEnabled(self.db.flyout)
        status:SetText(not self.isRogue and "Rogue characters only." or not self.active and "Enable Rogue Tools using the header switch." or (self.lastMessage or self.status or "Ready."))
        page:Layout()
    end
    page:Finish();return page
end
