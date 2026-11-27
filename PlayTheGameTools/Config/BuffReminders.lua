local _,addon=...
if not addon.BuffReminders then return end
local M,D,W=addon.BuffReminders,addon.BuffRemindersData,addon.ConfigWidgets

-- One scrolling page. What to remind about and when lives here; how the
-- reminders look (size, growth, spacing, timer, names, glow, sound) lives in
-- Layout, on each display's Style card.
local CHOICE_LABELS={blessing="Blessing to cast",paladinAura="Aura to cast",aspect="Aspect to cast",imbue="Imbue to cast",
    shield="Shield to cast",armor="Armor to cast",demon="Demon to summon",poisonMain="Main-hand poison",poisonOff="Off-hand poison",stone="Stone to use"}

function M:CreateConfigPage(parent)
    local page=W.Page(parent,440);self.page=page
    page.buffControls={}
    local function FullRow(height)
        local c=page:Row("",height);c.rowLabel:Hide();c:ClearAllPoints();c:SetAllPoints(c.row)
        table.remove(page.searchEntries)
        return c,c.row
    end
    local function Select(label,choices,getter,setter,keywords)
        local select=W.Select(page:Row(label,44,keywords),240,function() return choices end,getter,setter)
        page.refreshers[#page.refreshers+1]=function() select:Refresh();select:SetEnabled(self:CanConfigure()) end
        page.buffControls[label]=select
        return select
    end
    local function Options(list)
        return function(value)
            for _,c in ipairs(list) do if c.id==value then return c.id,c.label end end
            return value,tostring(value)
        end
    end
    local function Picker(label,key,list,keywords)
        local getter=Options(list)
        return Select(label,list,function() return getter(self.db[key]) end,function(v) self:SetOption(key,v) end,keywords)
    end
    local function GroupPicker(label,group,key,list,keywords)
        local getter=Options(list)
        return Select(label,list,function() return getter(self.db[group][key]) end,function(v) self:SetGroupOption(group,key,v) end,keywords)
    end
    local function Toggles(items)
        local cells=page:ToggleGrid(items,{maxColumns=2,minimumCellWidth=200})
        for i,item in ipairs(items) do page.buffControls[item.label]=cells[i] end
        return cells
    end
    local function Slider(label,key,low,high,suffix)
        local c=page:Row(label,52)
        local host=CreateFrame("Frame",nil,c);host:SetPoint("TOPLEFT",0,-2);host:SetPoint("BOTTOMRIGHT",0,2)
        page.refreshers[#page.refreshers+1]=W.Slider(host,low,high,1,function() return self.db[key] end,function(v) self:SetOption(key,v) end,suffix,true)
        page.buffControls[label]=host
    end
    local function Visible(predicate) page.rows[#page.rows].visibleWhen=predicate end
    local function Chip(b)
        return {label=b.name,keywords={b.short},get=function() return self.db.buffs[b.key] end,set=function(v) self:SetBuff(b.key,v) end}
    end

    local class=self.class or self:PlayerClass()
    local className=class and D.CLASS_NAMES[class]
    local function Reminding() return self.db.show end

    page:Section("Reminder",nil,false)
    Toggles({{label="Show reminder",get=function() return self.db.show end,set=function(v) self:SetOption("show",v) end},
        {label="Time reminder",get=function() return self.db.timeReminder end,set=function(v) self:SetOption("timeReminder",v) end},
        {label="Charge reminder",get=function() return self.db.chargeReminder end,set=function(v) self:SetOption("chargeReminder",v) end},
        {label="Show charges",get=function() return self.db.showCharges end,set=function(v) self:SetOption("showCharges",v) end},
        {label="Left-click reapplies",get=function() return self.db.click end,set=function(v) self:SetOption("click",v) end},
        {label="Right-click dismisses",get=function() return self.db.dismiss end,set=function(v) self:SetOption("dismiss",v) end}})
    Picker("When","when",{{id="needed",label="When Needed"},{id="neededOOC",label="When Needed (OOC)"},
        {id="alwaysOOC",label="Always Outside Combat"},{id="always",label="Always, Including Combat"}},{"visibility","combat"});Visible(Reminding)
    local warn={}
    for _,v in ipairs(D.WARN_CHOICES) do warn[#warn+1]={id=v,label=v==0 and "Automatic (25%, up to 5 min)" or (v.." min before")} end
    Picker("Warn before expiry","warnMinutes",warn,{"threshold","time left"});Visible(function() return self.db.show and self.db.timeReminder end)
    Picker("Display","mode",{{id="icons",label="Icons with timers"},{id="text",label="Text"},{id="single",label="Most urgent only"}},{"text mode","icons"});Visible(Reminding)
    Picker("Can't apply it","cant",{{id="dim",label="Dim the reminder"},{id="hide",label="Hide the reminder"}},{"resources","reagents","mana"});Visible(Reminding)

    if className then
        local own={}
        for _,b in ipairs(D.buffs) do if b.class==class and b.kind~="totem" then own[#own+1]=b end end
        if #own>0 or class=="SHAMAN" then
            page:Section(className.." Buffs",nil,false)
            if #own>0 then
                local items={};for _,b in ipairs(own) do items[#items+1]=Chip(b) end
                page.classChips=W.Chips(page,items)
            end
            local seen={}
            for _,b in ipairs(own) do
                if b.choice and not seen[b.choice] then
                    seen[b.choice]=true
                    local buff=b
                    GroupPicker(CHOICE_LABELS[b.choice] or b.name,"choices",b.choice,D.choices[b.choice])
                    Visible(function() return self.db.buffs[buff.key] end)
                end
            end
            if class=="ROGUE" then
                Slider("Poison time warning","poisonWarn",D.ranges.poisonWarn[1],D.ranges.poisonWarn[2]," min")
                Visible(function() return self.db.timeReminder and (self.db.buffs.poisonMain or self.db.buffs.poisonOff) end)
                Slider("Poison charge warning","poisonCharges",D.ranges.poisonCharges[1],D.ranges.poisonCharges[2]," charges")
                Visible(function() return self.db.chargeReminder and (self.db.buffs.poisonMain or self.db.buffs.poisonOff) end)
            end
            if class=="SHAMAN" then
                for _,element in ipairs(D.ELEMENTS) do
                    local list={{id="",label="None"}}
                    for _,t in ipairs(D.totems[element.id]) do list[#list+1]={id=t.id,label=t.label} end
                    GroupPicker(element.label.." totem","totems",element.id,list,{"totem","totems"})
                end
                Picker("Several totems missing","totemMode",{{id="each",label="Show each by name"},{id="one",label="One Totems Missing icon"}},{"totem","totems"})
            end
        end
    end

    local watches=false
    for _,b in ipairs(D.buffs) do if b.class==class and b.party then watches=true end end
    if watches then
        page:Section("Group",nil,false)
        Toggles({{label="Watch my buffs on group members",get=function() return self.db.watchGroup end,set=function(v) self:SetOption("watchGroup",v) end}})
        Picker("Watcher shows","watchMode",{{id="icons",label="Icons with names"},{id="list",label="List"}},{"group watcher","party","raid"})
        Visible(function() return self.db.watchGroup end)
    end

    page:Section("General",nil,false)
    local general={}
    for _,b in ipairs(D.buffs) do if b.class=="ALL" then general[#general+1]=Chip(b) end end
    page.generalChips=W.Chips(page,general)

    page:Section("Where to Show",nil,false)
    page.placeChips=W.Chips(page,{
        {label="Open World",get=function() return self.db.where.world end,set=function(v) self:SetGroupOption("where","world",v) end},
        {label="Dungeons",get=function() return self.db.where.dungeon end,set=function(v) self:SetGroupOption("where","dungeon",v) end},
        {label="Raids",get=function() return self.db.where.raid end,set=function(v) self:SetGroupOption("where","raid",v) end},
        {label="Battlegrounds",get=function() return self.db.where.battleground end,set=function(v) self:SetGroupOption("where","battleground",v) end}})
    Picker("While resting","resting",{{id="show",label="Show"},{id="hide",label="Hide"},{id="only",label="Only while resting"}},{"rested","city","inn"})
    Toggles({{label="Hide while mounted or flying",get=function() return self.db.hideMounted end,set=function(v) self:SetOption("hideMounted",v) end},
        {label="Hide while dead",get=function() return self.db.hideDead end,set=function(v) self:SetOption("hideDead",v) end}})

    page:Section("Look",nil,false)
    local c,row=FullRow(40)
    local buttons={}
    for _,spec in ipairs({{"Customize Display",function() addon:EditElementAppearance(M.MAIN_ID) end},
        {"Customize Group Watcher",function() addon:EditElementAppearance(M.GROUP_ID) end},
        {"Restore Dismissed",function() self:RestoreDismissed() end}}) do
        local b=W.Button(c,spec[1],150,28);buttons[#buttons+1]=b
        b:SetScript("OnClick",function() if self:CanConfigure() then spec[2]();page:Refresh() end end)
        page.searchEntries[#page.searchEntries+1]={label=spec[1],section=page.activeSection,row=row,kind="setting"}
    end
    row.layoutChildren=function(_,width)
        local w=math.min(170,(width-(#buttons-1)*8)/#buttons)
        for i,b in ipairs(buttons) do b:ClearAllPoints();b:SetPoint("TOPLEFT",(i-1)*(w+8),-6);b:SetWidth(w) end
    end
    page.lookButtons=buttons
    -- A real notice only: shown when click-to-reapply can't work on this client.
    local note=W.Label(page:Row("Click to Reapply",44),"Unavailable: this client did not provide secure action buttons.",nil,0,-4,420,addon.Theme.muted)
    note:SetWordWrap(true)
    note:GetParent().row.visibleWhen=function() return self.active and self.db.click and self.secureAvailable==false end
    page.secureNote=note
    page.refreshers[#page.refreshers+1]=function()
        buttons[1]:SetEnabled(self.active==true)
        buttons[2]:SetEnabled(self.active==true and self:GroupApplies())
        buttons[3]:SetEnabled(self.active==true and next(self.dismissed or {})~=nil)
    end
    page:Finish()
    return page
end
