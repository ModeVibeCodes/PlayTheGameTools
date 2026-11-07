local _, addon = ...
local M, W, T = addon.DungeonLoot, addon.ConfigWidgets, addon.InterfaceTheme

function M:CreateConfigPage(parent)
    local page = W.Page(parent, 320)
    self.page = page
    local rows = addon.DungeonLootWidgets.New(page, self)
    local nav = page:Row("", 44)
    nav.rowLabel:Hide();nav:ClearAllPoints();nav:SetPoint("TOPLEFT",nav.row,"TOPLEFT",0,-4);nav:SetPoint("BOTTOMRIGHT",nav.row,"BOTTOMRIGHT",0,4)
    local buttons = {}
    local function Tab(text, callback)
        local button=W.Button(nav,text,80,32,"underline")
        button:SetScript("OnClick",callback);buttons[#buttons+1]=button
        return button
    end
    page.home=Tab("Dungeons",function() self:Navigate(nil) end)
    page.loot=Tab("Boss Loot",function() self:Navigate(self.view.dungeon,"loot") end)
    page.quests=Tab("Quests",function() self:Navigate(self.view.dungeon,"quests") end)
    page.general=Tab("General",function() self:Navigate(nil,"general") end)
    function nav.row:layoutChildren(width)
        for i,button in ipairs(buttons) do
            button:ClearAllPoints();button:SetSize((width-12)/4,32);button:SetPoint("TOPLEFT",(i-1)*(width+4)/4,0)
        end
    end
    local input=page:Row("Search names",48)
    input.row.visibleWhen=function() return self.active and self.view.tab~="general" and not self.view.quest end
    page.search=CreateFrame("EditBox",nil,input)
    page.search:SetPoint("TOPLEFT");page.search:SetPoint("TOPRIGHT");page.search:SetHeight(28)
    page.search:SetAutoFocus(false);page.search:SetMaxLetters(80);page.search:SetFontObject(GameFontHighlight)
    page.search:SetTextInsets(6,6,0,0);W.Texture(page.search,"InputField")
    page.search:SetScript("OnTextChanged",function(box) self.view.search=box:GetText() or "";page.scrollbar:SetValue(0);page:Refresh() end)
    page.search:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    local filter=page:Row("Quest faction",48)
    page.faction=W.Select(filter,180,function() return {
        {id="all",label="All factions"},{id="Alliance",label="Alliance"},{id="Horde",label="Horde"}
    } end,function() return self.view.faction,self.view.faction=="all" and "All factions" or self.view.faction end,
    function(value) self.view.faction=value;self.view.quest=nil;page:Refresh() end)
    filter.row.visibleWhen=function() return self.active and self.view.dungeon=="Shadowfang Keep" and self.view.tab=="quests" and not self.view.quest end
    local refresh=page:Row("Dungeon data",40)
    refresh.row.visibleWhen=function() return self.view.tab=="general" end
    page.reload=W.Button(refresh,"Refresh",86,24)
    page.reload:SetPoint("TOPLEFT");page.reload:SetScript("OnClick",function() self.attempted={};self:ReadData();page:Refresh() end)

    local function Add(...) return rows:Add(...) end
    local function Heading(text) Add(text,nil,nil,T.secondary,nil,{heading=true}) end
    local function Item(item, prefix, unfiltered)
        local name,icon,quality,loaded=self:ItemInfo(item)
        if not unfiltered and not self:Matches(name.." "..item.name) then return false end
        local color=T.text
        if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
            local c=ITEM_QUALITY_COLORS[quality];color={c.r,c.g,c.b,1}
        end
        Add((prefix or "")..name..(item.slot and ("  ·  "..item.slot) or "")..(loaded and "" or "  (loading details)"),nil,item,color,icon)
        return true
    end
    local function Acquisition(q)
        Add("Pick up: "..(q.pickup or "Location unknown"))
        if q.start then Add(q.start) end
        if q.startItem then Item(q.startItem,"Quest-starting item: ",true) end
        if q.startObject then Add("Quest-starting object: "..q.startObject) end
        if q.startHint then Add(q.startHint) end
    end
    local function QuestDetail(q)
        Add(q.name,nil,nil,T.text,nil,{heading=true,faction=q.faction})
        Add((q.classOnly or "All classes").."  ·  "..(q.requires and ("Requires level "..q.requires) or "Required level unknown").."  ·  "..(q.faction or "Faction unknown"),nil,nil,T.muted)
        Heading("Start here");Acquisition(q)
        Heading("Before you go")
        if #q.chain>0 then
            for index,step in ipairs(q.chain) do
                Add(index..". "..step.name,nil,nil,T.primary)
                Acquisition(step)
                if step.objective then Add(step.objective) end
                if step.turnin then Add("Turn in: "..step.turnin) end
                if step.note then Add(step.note) end
                if step.description then Add(step.description) end
            end
        else Add("No prerequisites recorded.",nil,nil,T.muted) end
        if q.warning then Add(q.warning,nil,nil,T.primary) end
        Heading("In the dungeon")
        if q.objective then Add(q.objective) end
        if q.note then Add(q.note) end
        if q.description then Add(q.description) end
        Heading("Turn in")
        Add(q.turnin or "Location unknown")
        if q.finish then Add(q.finish) end
        Heading("Rewards")
        if q.rewards then Add(q.rewards) end
        if q.rewardSummary and q.rewardSummary~="" then Add(q.rewardSummary) end
        for _,item in ipairs(q.items) do Item(item,nil,true) end
        if #q.items==0 and not q.rewards then Add("Rewards unknown.",nil,nil,T.muted) end
    end
    local function Bosses(data, extras)
        local entries={}
        for index,entry in ipairs(data.bosses) do
            if entry.extra==extras and self:Matches(entry.name) then
                local selected=index
                entries[#entries+1]={name=entry.name,displayID=entry.displayID,icon=entry.icon,
                    detail=(entry.rare and "Rare encounter · " or "")..#entry.items.." items",
                    callback=function() self:Navigate("Shadowfang Keep","loot",selected) end}
            end
        end
        if #entries>0 then rows:Grid(entries) end
        return #entries
    end
    function page:Refresh()
        if self.refreshing then return end
        self.refreshing=true
        M:HideTooltip();rows:Reset()
        local v=M.view
        local data=M.active and (M.data or M:ReadData()) or nil
        self.home:SetSelected(v.dungeon==nil and v.tab~="general")
        self.loot:SetSelected(v.dungeon~=nil and v.tab=="loot")
        self.quests:SetSelected(v.dungeon~=nil and v.tab=="quests")
        self.general:SetSelected(v.tab=="general")
        self.loot:SetEnabled(M.active and v.dungeon=="Shadowfang Keep")
        self.quests:SetEnabled(M.active and v.dungeon=="Shadowfang Keep")
        self.reload:SetEnabled(M.active);self.faction:Refresh()
        if not M.active then
            Add("Enable Dungeon Loot with the switch above to browse loot and quests.")
        elseif v.tab=="general" then
            Heading("General")
            Add(data.source,nil,nil,T.muted)
            Add("Loot and quest availability can change. Suggested levels are a guide, not an entry requirement.",nil,nil,T.muted)
            Add("Faction emblems on dungeon cards show the surrounding territory. Quest emblems show who can take each quest.",nil,nil,T.muted)
        elseif not v.dungeon then
            Heading("Suggested levels "..data.card.suggestedLevel)
            if M:Matches("Shadowfang Keep") then rows:Dungeon(data,function() M:Navigate("Shadowfang Keep") end)
            else Add("No dungeons match your search.") end
            if not data.available then Add(data.source,nil,nil,T.muted) end
        elseif not data.available then
            Heading("Shadowfang Keep");Add(data.source,nil,nil,T.muted)
        elseif v.tab=="loot" then
            local boss=v.boss and data.bosses[v.boss]
            if boss then
                Add("< All bosses",function() M:Navigate("Shadowfang Keep","loot") end)
                Add(boss.name,nil,nil,T.text,nil,{heading=true,portrait=boss})
                Heading("Loot")
                local count=0
                for _,item in ipairs(boss.items) do if Item(item) then count=count+1 end end
                if count==0 then Add(#boss.items==0 and "Loot unknown." or "No items match your search.") end
            else
                Heading("Shadowfang Keep · Bosses")
                local regular=Bosses(data,false)
                local hasExtra=false
                for _,entry in ipairs(data.bosses) do if entry.extra and M:Matches(entry.name) then hasExtra=true end end
                if hasExtra then Heading("Other loot");Bosses(data,true) end
                if regular==0 and not hasExtra then Add("No bosses match your search.") end
            end
        elseif v.tab=="quests" then
            local quest=v.quest and data.quests[v.quest]
            if quest then
                Add("< All quests",function() M:Navigate("Shadowfang Keep","quests") end)
                QuestDetail(quest)
            else
                Heading("Shadowfang Keep · Quests")
                local count=0
                for index,q in ipairs(data.quests) do
                    local faction=v.faction=="all" or not q.faction or q.faction=="Both" or q.faction==v.faction
                    if faction and M:Matches(q.name) then
                        local selected=index
                        Add(q.name,function() M:Navigate("Shadowfang Keep","quests",nil,selected) end,nil,T.text,nil,
                            {faction=q.faction,subtitle=(q.classOnly or "All classes").." · "..(q.requires and ("Level "..q.requires.."+") or "Level unknown").."\n"..(q.pickup or "Pickup location unknown")})
                        count=count+1
                    end
                end
                if count==0 then Add("No quests match your filters.") end
            end
        end
        self:Layout();self.refreshing=nil
    end
    page:SetScript("OnShow",function() if self.active then self:ReadData() end;self:SyncEvents();page:Refresh() end)
    page:SetScript("OnHide",function() self:SyncEvents();self:HideTooltip() end)
    page:Finish()
    return page
end
