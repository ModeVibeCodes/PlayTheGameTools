local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
addon:RegisterCategory("classTools",{title="Class Tools"})
local D=addon.ForeverRogueData
local M={title="Rogue",category="classTools",defaultEnabled=false,Data=D,Initialize=D.Initialize,
    configDescription="Per-weapon poison reminders, inventory-backed quick apply and an optional poison flyout."}
addon.ForeverRogue=M;addon:RegisterModule("foreverRogue",M)
function M:OnInitialize()
    self.Initialize(self.db);self.known={};self.choices={};self.byKey={};self.requested={};self.previous={};self.recentChanges={}
    local _,class=UnitClass("player");self.isRogue=D.Public(class) and class=="ROGUE"
end
function M:CanConfigure() return D.OutsideCombat() end
function M:SetOption(key,value)
    if not self:CanConfigure() then return false end
    local copy=addon.ProfileCodec.Copy(self.db);copy[key]=value
    if not pcall(self.Initialize,copy) then return false end
    self.db[key]=value;self:Refresh();return true
end
function M:SetStyle(group,key,value)
    if not self:CanConfigure() or (group~="watchStyle" and group~="flyoutStyle" and group~="launcherStyle") then return false end
    local copy=addon.ProfileCodec.Copy(self.db);copy[group][key]=value
    if key=="font" then copy[group].fontMedia="" end
    if not pcall(self.Initialize,copy) then return false end
    self.db[group][key]=value
    if key=="font" then self.db[group].fontMedia="" end
    self:Refresh();return true
end
function M:History(create)
    local guid=D.Call(UnitGUID,"player")
    if type(guid)~="string" or #guid>100 then return end
    local row=self.db.history[guid]
    if not row and create then
        local n=0;for _ in pairs(self.db.history) do n=n+1 end
        if n>=200 then return end
        row={};self.db.history[guid]=row
    end
    return row
end
function M:Remember(hand,p)
    if not D.OutsideCombat() or not p then return end
    local row=self:History(true)
    if row then row[hand==1 and "main" or "off"]=p.key;row.last=p.key end
end
function M:Observe(states)
    if not D.OutsideCombat() then return end
    local now=GetTime();local pending=self.confirmedCast
    if pending and now-pending.time>10 then self.confirmedCast=nil;pending=nil end
    local changed={}
    for hand,s in ipairs(states) do
        local old=self.previous[hand]
        if not s.unknown and not s.empty then
            changed[hand]=not s.missing and old and not old.unknown and
                old.weapon==s.weapon and (old.missing or old.enchant~=s.enchant or s.seconds>(old.seconds or 0)+2)
            if changed[hand] then self.recentChanges[hand]=now end
        end
    end
    local confirmedHand
    if pending then
        local p=pending.poison or self.byKey[pending.key];local candidates={}
        for hand,s in ipairs(states) do
            local recent=self.recentChanges[hand]
            local correlated=changed[hand] or (recent and recent<=pending.time and pending.time-recent<=1)
            if p and not s.unknown and not s.empty and not s.missing and correlated and (not pending.hand or pending.hand==hand) and
                (pending.hand or (s.poison and s.poison.family==p.family) or s.icon==p.icon or s.icon==p.effectIcon) then candidates[#candidates+1]=hand end
        end
        if #candidates==1 then
            confirmedHand=candidates[1];self:Remember(confirmedHand,p);states[confirmedHand].poison=p;self.confirmedCast=nil
        end
    end
    for hand,s in ipairs(states) do
        if not s.unknown and not s.empty then
            if s.poison and hand~=confirmedHand then
                local history=self:History();local key=history and history[hand==1 and "main" or "off"]
                local last=key and self.byKey[key]
                if not key or (last and last.family~=s.poison.family) or (not last and changed[hand]) then self:Remember(hand,s.poison) end
            end
            self.previous[hand]=s
        end
    end
end
function M:SpellSucceeded(unit,spell)
    if not D.OutsideCombat() or not D.Public(unit) or unit~="player" or not D.Number(spell,1,2147483647) then return end
    local attempt=self.attempt;local p=attempt and (attempt.poison or self.byKey[attempt.key])
    if p and GetTime()-attempt.time<=10 and p.effectID==spell then
        self.confirmedCast={key=p.key,poison=p,hand=attempt.hand,time=GetTime()};self.attempt=nil;return
    end
    local found
    for _,candidate in ipairs(self.choices) do
        if candidate.effectID==spell then
            if found and found.key~=candidate.key then return end
            found=candidate
        end
    end
    if found then self.confirmedCast={key=found.key,poison=found,time=GetTime()} end
end
function M:QuickPoison(hand,state)
    if self.db.quickApply~="last" then return self.byKey[self.db.quickApply],"Selected poison is unavailable. Restock it or choose another Poison Refresh Quick Apply entry." end
    local history=self:History();local key=history and (history[hand==1 and "main" or "off"] or history.last)
    if key then return self.byKey[key],"Last-used poison is unavailable. Restock it or choose another Poison Refresh Quick Apply entry." end
    return state.poison,"No last-used poison recorded. Choose Poison Refresh Quick Apply or apply a carried poison through the flyout."
end
function M:Refresh()
    if not self.active or not self.isRogue then return end
    if D.OutsideCombat() then self:Discover();self:CreateDisplay();self:Layout() end
    self:Render()
end
function M:OnEnable()
    self.active=true
    if not self.isRogue then return end
    self.events=self.events or CreateFrame("Frame")
    for _,e in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_EQUIPMENT_CHANGED","WEAPON_ENCHANT_CHANGED","SPELLS_CHANGED","SPELL_FLYOUT_UPDATE","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT","BAG_UPDATE_DELAYED","UNIT_SPELLCAST_SUCCEEDED"}) do self.events:RegisterEvent(e) end
    self.events:SetScript("OnEvent",function(_,event,a,b,c)
        if event=="UNIT_SPELLCAST_SUCCEEDED" then self:SpellSucceeded(a,c);return end
        if event=="PLAYER_REGEN_DISABLED" then self:StopDrag();self.menuOpen=false;self.previewing=false;self.editing=false;self.attempt=nil end
        if event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
            if not D.Public(a) or not self.requested[a] then return end
        end
        self:Refresh()
    end)
    self.ticker=C_Timer.NewTicker(1,function() if self.active then self:Render() end end)
    self:Refresh()
end
function M:OnDisable()
    self.active=false;self.previewing=false;self.editing=false;self.menuOpen=false;self.attempt=nil;self.confirmedCast=nil;self.previous={};self.recentChanges={}
    self:StopDrag()
    if self.ticker then self.ticker:Cancel();self.ticker=nil end
    if self.events then self.events:UnregisterAllEvents();self.events:SetScript("OnEvent",nil) end
    for _,f in ipairs({self.watcher,self.launcher,self.menu}) do if f then f:Hide() end end
end
function M:SetPreviewMode(v) self.previewing=v;self:Refresh() end
function M:SetEditMode(v) self.editing=v;self:Refresh() end
