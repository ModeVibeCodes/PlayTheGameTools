local _,addon=...
if not addon.ForeverRogue then return end
local M,D,W=addon.ForeverRogue,addon.ForeverRogueData,addon.ConfigWidgets
function M:CreateConfigPage(parent)
    local page=W.Page(parent,480);self.page=page;page.poisonControls={};page.poisonStyles={}
    local function Note(label,text,height)
        local t=W.Label(page:Row(label,height or 72),text,nil,0,-4,320,addon.Theme.muted);t:SetWordWrap(true);return t
    end
    local function Toggle(label,key,group)
        local cell=page:ToggleGrid({{label=label,get=function() return (group and self.db[group] or self.db)[key] end,
            set=function(v) if group then self:SetStyle(group,key,v) else self:SetOption(key,v) end end}})[1]
        if group then page.poisonStyles[group]=page.poisonStyles[group] or {};page.poisonStyles[group][key]=cell else page.poisonControls[key]=cell end
    end
    local function Slider(label,key,group,suffix)
        local r=group and D.styleRanges[key] or D.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(label,48),r[1],r[2],r[3],function() return (group and self.db[group] or self.db)[key] end,
            function(v) if group then self:SetStyle(group,key,v) else self:SetOption(key,v) end end,suffix,true)
    end
    local function Select(label,key,choices,group)
        local select=W.Select(page:Row(label,48),300,choices,function()
            local value=(group and self.db[group] or self.db)[key]
            for _,choice in ipairs(choices()) do if choice.id==value then return value,choice.label end end
            if key=="quickApply" then
                local kind,id=value:match("^(%a+):(%d+)$");id=tonumber(id)
                local name=kind=="item" and D.Call(C_Item and C_Item.GetItemNameByID,id)
                if kind=="spell" then local p=D.Spell(id);name=p and p.name end
                return value,(name or "Selected poison").." (unavailable)"
            end
            return value,value.." (unavailable)"
        end,function(v) if group then self:SetStyle(group,key,v) else self:SetOption(key,v) end end)
        page.refreshers[#page.refreshers+1]=function() select:Refresh() end
        return select
    end
    local function Button(row,label,fn)
        local b=W.Button(page:Row(row,48),label,180,28);b:SetPoint("LEFT")
        b:SetScript("OnClick",function() if self:CanConfigure() then fn();page:Refresh() end end);return b
    end
    page:Section("Poison Watcher")
    page:ToggleGrid({{label="Enable Rogue Tools",get=function() return self.enabled end,set=function(v) if self:CanConfigure() then addon:SetModuleEnabled(self.id,v) end end}})
    Toggle("Enable Poison Watcher","watcher");Toggle("Show Watcher In Combat","showInCombat")
    Slider("Reminder Threshold (minutes)","threshold",nil," min")
    local status=Note("Poison Status","",100)
    page.refreshers[#page.refreshers+1]=function()
        status:SetText(not self.isRogue and "Rogue characters only." or not self.active and "Enable Rogue Tools to scan carried and learned poisons." or
            ((self.status or "Ready.")..(self.lastMessage and ("\n"..self.lastMessage) or "")))
    end
    page:Section("Poison Quick Apply")
    page.quickApply=Select("Poison Refresh Quick Apply:","quickApply",function()
        local list={{id="last",label="Last Used Poison (per hand)"}}
        for _,p in ipairs(self.choices) do list[#list+1]={id=p.key,label=p.name..(p.kind=="item" and (" ("..p.count.." carried)") or " (learned spell)")} end
        return list
    end)
    Note("Quick Apply Behavior","Last Used Poison remembers each character and hand from observed poison applications. Carried poison items are used directly; learned castable poisons also appear. Choose a specific poison to override. If no previous poison can be identified, select one or apply through the flyout first. Out-of-stock, unknown or positioning states explain why a click cannot apply.",144)
    page.refreshPoisonButton=Button("Inventory and Learned Poisons","Refresh Poisons",function() self:Refresh() end)
    page:Section("Poison Flyout")
    Toggle("Enable Poison Flyout","flyout");Toggle("Always Show Poison Flyout","alwaysShow")
    Note("Flyout Visibility","The Poisons profession icon appears when either equipped hand is missing poison or reaches the reminder threshold. Always Show Poison Flyout keeps the icon visible outside combat. Click it to open the menu; Main Hand and Off Hand apply separately. Combat closes the menu. The watcher and flyout are independent.",112)
    Select("Flyout Direction","direction",function() return {{id="UP",label="Up"},{id="DOWN",label="Down"},{id="LEFT",label="Left"},{id="RIGHT",label="Right"}} end)
    Slider("Visible Flyout Rows","visibleRows")
    local function Style(group,title,watcher,launcher)
        page:Section(title)
        local owner={db={appearance=self.db[group]}}
        function owner:CanConfigure() return M:CanConfigure() end
        function owner:SetAppearance(key,value) return M:SetStyle(group,key,value) end
        function owner:GetFonts() return addon.Media:GetFonts() end
        local function S(label,key,suffix) Slider(label,key,group,suffix) end
        local function T(label,key) Toggle(label,key,group) end
        local function Color(label,key) W.ColorRow(page,owner,label,key) end
        S("Icon Size","iconSize");S("Scale","scale","%");S("Opacity","opacity","%")
        S("Padding","padding");T("Crop Icons","cropIcons");T("Show Tooltips","tooltips")
        Color("Icon Tint","iconColor")
        if not launcher then
            T("Show Icons","showIcons");T("Show Hand Labels","showHands");T("Show Poison Names","showNames");T("Show Inventory Counts","showCounts")
            S("Cell Width","cellWidth");S("Icon Spacing","spacing");S("Label Gap","labelGap")
            S("Text Size","fontSize");T("Text Outline","outline")
            local _,refresh=W.FontDropdown(page:Row("Text Font"),owner);page.refreshers[#page.refreshers+1]=refresh
            Color("Text Color","textColor")
            if watcher then
                T("Vertical Watcher Layout","vertical");T("Show Remaining Time","showTimers");S("Timer Text Size","timerSize");Color("Timer Text Color","timerColor")
                Select("Timer Position","timerPosition",function() return {{id="CENTER",label="On Icon"},{id="TOP",label="Above Icon"},{id="BOTTOM",label="Below Labels"}} end,group)
            else S("Poison Columns","columns") end
        end
        Color("Background Color","backgroundColor");S("Background Opacity","backgroundOpacity","%")
        Color("Border Color","borderColor");S("Border Opacity","borderOpacity","%");S("Border Size","borderSize")
    end
    Style("watchStyle","Watcher Appearance",true,false)
    page:Section("Watcher Position")
    Toggle("Lock Poison Watcher","locked")
    Slider("Watcher Horizontal Offset","x");Slider("Watcher Vertical Offset","y")
    Button("Watcher Preview","Toggle Poison Preview",function() self.previewing=not self.previewing;self:Refresh() end)
    Button("Watcher Screen Position","Reset Watcher Position",function() self.db.x=0;self.db.y=-140;self:Refresh() end)
    Style("launcherStyle","Flyout Icon Appearance",false,true)
    Style("flyoutStyle","Flyout Menu Appearance",false,false)
    page:Section("Flyout Position")
    Toggle("Lock Poison Flyout","flyoutLocked")
    Slider("Flyout Horizontal Offset","menuX");Slider("Flyout Vertical Offset","menuY")
    Note("Move Poison Elements","Unlock the watcher or flyout and drag its background or icon outside combat. Relock to apply poisons. The menu follows its icon and selected Flyout Direction. Preview shows positions without applying poisons.",88)
    Button("Flyout Screen Position","Reset Flyout Position",function() self.db.menuX=200;self.db.menuY=-140;self:Refresh() end)
    page:Finish();return page
end
