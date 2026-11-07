local _, addon = ...
local M, W, T = addon.DungeonLoot, addon.ConfigWidgets, addon.InterfaceTheme

function M:CreateConfigPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page.searchEntries = {}
    self.page = page
    local nav = CreateFrame("Frame", nil, page)
    nav:SetPoint("TOPLEFT");nav:SetPoint("TOPRIGHT");nav:SetHeight(36)
    local buttons = {}
    local function Tab(text, callback)
        local b=W.Button(nav,text,90,32,"underline")
        b.underline=b:CreateTexture(nil,"OVERLAY");b.underline:SetColorTexture(1,1,1,1)
        b.underline:SetGradient("HORIZONTAL",CreateColor(159/255,204/255,250/255,1),CreateColor(9/255,116/255,241/255,1))
        b.underline:SetPoint("BOTTOMLEFT",10,0);b.underline:SetPoint("BOTTOMRIGHT",-10,0);b.underline:SetHeight(2);b.underline:Hide()
        b:SetScript("OnClick",callback);buttons[#buttons+1]=b;return b
    end
    page.home=Tab("Dungeons",function() self:Navigate(nil) end)
    page.loot=Tab("Boss Loot",function() self:Navigate(self.view.dungeon,"loot") end)
    page.quests=Tab("Quests",function() self:Navigate(self.view.dungeon,"quests") end)
    page.general=Tab("General",function() self:Navigate(nil,"general") end)
    local toolbar=CreateFrame("Frame",nil,page)
    toolbar:SetPoint("TOPLEFT",0,-42);toolbar:SetPoint("TOPRIGHT",0,-42);toolbar:SetHeight(30)
    page.search=CreateFrame("EditBox",nil,toolbar)
    page.search:SetPoint("TOPLEFT");page.search:SetHeight(28)
    page.search:SetAutoFocus(false);page.search:SetMaxLetters(80);page.search:SetFontObject(GameFontHighlight)
    page.search:SetTextInsets(8,8,0,0);W.Texture(page.search,"InputField")
    page.searchHint=W.Label(page.search,"Search names",nil,8,-7,130,T.muted)
    page.search:SetScript("OnTextChanged",function(box)
        self.view.search=box:GetText() or "";page.searchHint:SetShown(self.view.search=="")
        page.listPane.scrollbar:SetValue(0);page:Refresh()
    end)
    page.search:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    page.faction=W.Button(toolbar,"Faction unknown",128,28)
    page.faction:EnableMouse(false)
    page.faction:ClearAllPoints();page.faction:SetPoint("TOPRIGHT");page.faction:SetSize(128,28)
    page.faction.label:ClearAllPoints();page.faction.label:SetPoint("TOPLEFT",8,0);page.faction.label:SetPoint("BOTTOMRIGHT",-8,0);page.faction.label:SetJustifyV("MIDDLE")
    page.context=W.Label(page,"",nil,12,-80,500,T.text)
    page.context:SetPoint("TOPRIGHT",-12,-80);page.context:SetWordWrap(false)
    local function Pane(minimum)
        local pane=W.Page(page,minimum)
        pane:ClearAllPoints()
        return pane,addon.DungeonLootWidgets.New(pane,self)
    end
    local root,rootRows=Pane(280)
    page.rootPane=root
    local left,leftRows=Pane(140)
    local right,rightRows=Pane(180)
    page.listPane,page.detailPane=left,right
    W.Fill(left,T.sidebar);W.Fill(right,T.panel)
    local function Add(...) return rightRows:Add(...) end
    local function Heading(text) Add(text,nil,nil,T.secondary,nil,{heading=true,gradient=M.view.tab=="quests" and "quest" or "header"}) end
    local function Item(item,prefix,expanded)
        local name,icon,quality,loaded=self:ItemInfo(item)
        local color=T.text
        if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
            local c=ITEM_QUALITY_COLORS[quality];color={c.r,c.g,c.b,1}
        end
        local options
        local text=(prefix or "")..name
        if expanded then
            options={expandedItem=true,subtitle=self:ItemDetails(item) or ((item.slot and (item.slot.."\n") or "").."Hover for full item details.")}
        else text=text..(item.slot and ("\n"..item.slot) or "") end
        Add(text..(loaded and "" or "  (loading details)"),nil,item,color,icon,options)
    end
    local function MapButtons(targets,kind)
        for _,target in ipairs(targets or {}) do
            local location=target
            rightRows:MapAction(target,kind,function()
                local ok,reason=addon.DungeonLootMap:Open(location,kind)
                M.mapStatus=not ok and reason or nil
                page:Refresh()
            end)
        end
    end
    local function Subheader(text)
        if text then Add(text,nil,nil,T.text,nil,{subheader=true,gradient="npc"}) end
    end
    local function LocationNotes(targets)
        local seen={}
        for _,target in ipairs(targets or {}) do
            if target.detail and not seen[target.detail] then Add(target.detail,nil,nil,T.muted);seen[target.detail]=true end
        end
    end
    local function Objective(q)
        local seen={}
        for _,target in ipairs(q.objectiveTargets or {}) do
            if not seen[target.label] then Subheader(target.label);seen[target.label]=true end
        end
        Add(q.objective or "Objective unknown.");LocationNotes(q.objectiveTargets)
    end
    local function TurnIn(q)
        Subheader(q.turnin or "Location unknown")
        if q.finish then Add(q.finish) end
        LocationNotes(q.turninTargets);MapButtons(q.turninTargets,"turnin")
    end
    local function Acquisition(q)
        Subheader(q.pickup or "Location unknown")
        local text=""
        if q.start then text=q.start end
        if q.startObject then text=text.."\n"..q.startObject end
        if q.startHint then text=text.."\n"..q.startHint end
        if text~="" then Add((text:gsub("^\n",""))) end
        LocationNotes(q.pickupTargets)
        if q.startItem then Item(q.startItem,"Starts quest: ") end
        MapButtons(q.pickupTargets,"pickup")
    end
    local function QuestDetail(q)
        Add(q.name,nil,nil,T.text,nil,{heading=true,gradient="quest",faction=q.faction})
        Add((q.requires and ("Level "..q.requires.."+") or "Level unknown").." · "..addon.DungeonLootWidgets.ClassesText(q),nil,nil,T.muted)
        if q.warning then Add(q.warning,nil,nil,T.primary) end
        if q.note then Add(q.note,nil,nil,T.secondary) end
        if q.description and q.description~=q.note then Add(q.description,nil,nil,T.secondary) end
        if M.mapStatus then Add(M.mapStatus,nil,nil,T.primary) end
        Heading("1. Starts at");Acquisition(q)
        Heading("2. Objective");Objective(q)
        Heading("3. Turn in");TurnIn(q)
        Heading(q.rewardChoice and "Choose one reward" or "Rewards")
        for _,item in ipairs(q.items) do Item(item) end
        if q.fixedItems and #q.fixedItems>0 then Heading("Also rewards");for _,item in ipairs(q.fixedItems) do Item(item) end end
        -- Avoid repeating every item name in the prose reward summary.
        local rewards=q.rewards
        if #q.items>0 then rewards=rewards and rewards:match("\n(.+)$") end
        if rewards then Add(rewards,nil,nil,T.muted)
        elseif q.rewardSummary and q.rewardSummary~="" then Add(q.rewardSummary,nil,nil,T.muted) end
        if #q.items==0 and not rewards then Add("Rewards unknown.",nil,nil,T.muted) end
        if #q.chain>0 then
            Add((M.view.showPrerequisites and "Hide prerequisites" or "Prerequisites").." ("..#q.chain..")",function()
                M.view.showPrerequisites=not M.view.showPrerequisites;page:Refresh()
            end)
            if M.view.showPrerequisites then
                for index,step in ipairs(q.chain) do
                    Add(index..". "..step.name,nil,nil,T.primary)
                    Acquisition(step)
                    if step.objective then Heading("Objective");Objective(step) end
                    if step.turnin then Heading("Turn in");TurnIn(step) end
                    if step.note then Add(step.note) end
                    if step.description then Add(step.description) end
                end
            end
        end
    end
    function page:Layout()
        local width=self:GetWidth()
        for index,b in ipairs(buttons) do
            b:ClearAllPoints();b:SetSize((width-12)/4,32);b:SetPoint("TOPLEFT",(index-1)*(width+4)/4,0)
        end
        local questTab=M.active and M.view.dungeon~=nil and M.view.tab=="quests"
        self.faction:SetShown(questTab)
        self.faction:ClearAllPoints();self.faction:SetPoint("TOPRIGHT",toolbar,"TOPRIGHT",0,0);self.faction:SetSize(128,28)
        self.search:ClearAllPoints();self.search:SetPoint("TOPLEFT",toolbar,"TOPLEFT",0,0)
        if questTab then self.search:SetPoint("TOPRIGHT",self.faction,"TOPLEFT",-10,0)
        else self.search:SetPoint("TOPRIGHT",toolbar,"TOPRIGHT",0,0) end
        root:SetPoint("TOPLEFT",0,-84);root:SetPoint("BOTTOMRIGHT")
        local top=(M.active and M.view.dungeon and M.view.tab~="general") and -112 or -84
        local leftWidth=math.max(160,math.min(300,width*0.37))
        left:SetPoint("TOPLEFT",0,top);left:SetPoint("BOTTOMLEFT");left:SetWidth(leftWidth)
        right:SetPoint("TOPLEFT",left,"TOPRIGHT",12,0);right:SetPoint("BOTTOMRIGHT")
        root:Layout();left:Layout();right:Layout()
    end
    function page:Refresh()
        if self.refreshing then return end
        self.refreshing=true
        M:HideTooltip();M.tooltipInstances={};rootRows:Reset();leftRows:Reset();rightRows:Reset()
        local v=M.view
        local data=M.active and (M.data or M:ReadData()) or nil
        local browser=M.active and data.available and v.dungeon~=nil and v.tab~="general"
        root:SetShown(not browser);left:SetShown(browser);right:SetShown(browser)
        toolbar:SetShown(M.active and v.tab~="general")
        self.context:SetShown(browser)
        if browser then self.context:SetText(addon.DungeonLootWidgets.Gradient(data.name).."  ·  "..data.card.suggestedLevel) end
        self.home:SetSelected(v.dungeon==nil and v.tab~="general")
        self.loot:SetSelected(v.dungeon~=nil and v.tab=="loot");self.quests:SetSelected(v.dungeon~=nil and v.tab=="quests")
        self.general:SetSelected(v.tab=="general")
        self.loot:SetEnabled(M.active and v.dungeon~=nil and data.available);self.quests:SetEnabled(M.active and v.dungeon~=nil and data.available)
        for _,button in ipairs(buttons) do button.underline:SetShown(button.selected==true) end
        self.faction:EnableMouse(false)
        self.faction.label:SetText(data and data.player and data.player.faction or "Faction unknown")
        if not M.active then
            rootRows:Add("Enable Dungeon Loot with the switch above to browse loot and quests.")
        elseif v.tab=="general" then
            rootRows:Add("General",nil,nil,T.secondary,nil,{heading=true})
            rootRows:Add(data.providerSource or data.source,nil,nil,T.muted)
            rootRows:Add("Bundled data: Lootified by Alen / CMaNGOS. GPLv3; no warranty. See CATALOG_SOURCES.md and LICENSES/GPL-3.0.txt.",nil,nil,T.muted)
            rootRows:Add("Loot and quest availability can change. Suggested levels are a guide, not an entry requirement.",nil,nil,T.muted)
            rootRows:Add("Dungeon emblems show the surrounding territory; quest emblems show who can take the quest.",nil,nil,T.muted)
            local refresh=rootRows:Add("Refresh",function() M.attempted={};M:ReadData();page:Refresh() end)
            self.reload=refresh.button;self.reload:SetWidth(86)
            -- Keep the refresh target compact rather than filling the settings page.
            refresh.button:ClearAllPoints();refresh.button:SetPoint("TOPLEFT");refresh.button:SetSize(86,28)
        elseif not v.dungeon then
            local shown,group=0,nil
            for _,dungeon in ipairs(data.cards) do
                if M:Matches(dungeon.name) then
                    local lower=dungeon.levelLow and (math.floor(dungeon.levelLow/10)*10)
                    local bracket=lower and (lower>=50 and "50–60" or (lower.."–"..(lower+9))) or "Unknown"
                    if bracket~=group then
                        rootRows:Add("Suggested starting levels "..bracket,nil,nil,T.secondary,nil,{heading=true});group=bracket
                    end
                    local name=dungeon.name
                    local open
                    if not dungeon.previewOnly then open=function() M:Navigate(name) end end
                    rootRows:Dungeon(dungeon,open)
                    shown=shown+1
                end
            end
            if shown==0 then rootRows:Add("No dungeons match your search.") end
            if not data.available and #data.cards==1 and not data.cards[1].available then rootRows:Add(data.source,nil,nil,T.muted) end
        elseif not data.available then rootRows:Add(data.source,nil,nil,T.muted)
        else
            local entries={}
            leftRows:Add(v.tab=="loot" and "Bosses" or "Quests",nil,nil,T.secondary,nil,{heading=true,gradient=v.tab=="quests" and "quest" or "header"})
            if v.tab=="loot" then
                for _,extras in ipairs({false,true}) do
                    for index,boss in ipairs(data.bosses) do
                        if boss.extra==extras and M:Matches(boss.name) then entries[#entries+1]={index=index,entry=boss} end
                    end
                end
            else
                for index,q in ipairs(data.quests) do
                    local faction=addon.DungeonLootProvider:Eligible(q,data.player)==true
                    if faction and M:Matches(q.name) then entries[#entries+1]={index=index,entry=q} end
                end
            end
            local key=v.tab=="loot" and "boss" or "quest"
            local selected
            for _,entry in ipairs(entries) do if entry.index==v[key] then selected=entry.entry end end
            if not selected then
                v[key]=entries[1] and entries[1].index or nil;selected=entries[1] and entries[1].entry
                v.showPrerequisites,v.showNotes=false,false
                right.scrollbar:SetValue(0)
            end
            local extrasHeading=false
            for _,record in ipairs(entries) do
                local entry,index=record.entry,record.index
                local options={compact=true,selected=v[key]==index,gradient=key=="boss" and "boss" or "quest"}
                if key=="boss" then
                    if entry.extra and not extrasHeading then leftRows:Add("Other loot",nil,nil,T.secondary,nil,{heading=true});extrasHeading=true end
                    options.portrait=entry
                    options.subtitle=entry.rare and "Rare encounter" or (#entry.items.." items")
                else
                    options.faction=entry.faction
                    options.subtitle=(entry.requires and ("Level "..entry.requires.."+") or "Level unknown")..((entry.classOnly or #entry.classes>0) and (" · "..addon.DungeonLootWidgets.ClassesText(entry)) or "")..(#entry.chain>0 and " · Chain" or "")
                end
                leftRows:Add(entry.name,function() M:SelectEntry(key,index) end,nil,T.text,nil,options)
            end
            if not selected then
                local message
                if key=="boss" then message=#data.bosses==0 and "No bosses recorded for this dungeon." or "No bosses match your search."
                else message=#data.quests==0 and "No quests recorded for this dungeon." or "No quests match your character or search." end
                leftRows:Add(message);Add(message)
            elseif key=="boss" then
                Add(selected.name,nil,nil,T.text,nil,{heading=true,gradient="boss",portrait=selected})
                if data.lootIncomplete then Add("Loot records may be incomplete.",nil,nil,T.muted) end
                for _,item in ipairs(selected.items) do Item(item,nil,#selected.items<=5) end
                if #selected.items==0 then Add("Loot unknown.") end
            else QuestDetail(selected) end
        end
        self:Layout();self.refreshing=nil
    end
    page:SetScript("OnSizeChanged",function() page:Layout() end)
    page:SetScript("OnShow",function() if self.active then self:ReadData() end;self:SyncEvents();page:Refresh() end)
    page:SetScript("OnHide",function() self:SyncEvents();self:HideTooltip();if self.coordinateFrame then self.coordinateFrame:Hide() end end)
    page:Refresh()
    return page
end
