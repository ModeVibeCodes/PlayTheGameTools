local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
addon:RegisterCategory("classTools",{title="Class Tools"})
local D=addon.ForeverRogueData
local M={title="Rogue",category="classTools",classIcon="Interface\\Icons\\ClassIcon_Rogue",defaultEnabled=false,Data=D,Initialize=D.Initialize,
    configDescription="Poison Reminder highlights weapons that need poison. Quick Access Poisons offers one-click applications outside combat."}
addon.ForeverRogue=M;addon:RegisterModule("foreverRogue",M)
function M:OnInitialize()
    self.Initialize(self.db);self.known={};self.choices={};self.byKey={};self.requested={};self.previous={};self.recentChanges={};self.dismissed={};self.chargeSources={}
    local _,class=UnitClass("player");self.isRogue=D.Public(class) and class=="ROGUE"
end
function M:CanConfigure() return D.OutsideCombat() end
function M:SetOption(key,value)
    if not self:CanConfigure() then return false end
    local copy=addon.ProfileCodec.Copy(self.db);copy[key]=value
    if not pcall(self.Initialize,copy) then return false end
    self.db[key]=value
    if key=="quickApply" then self.lastMessage=nil end
    if key=="x" or key=="y" or key=="menuX" or key=="menuY" then self:SyncPosition(key) end
    self:Refresh();return true
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
    if row then row[hand==1 and "main" or "off"]=p.key;row.last=p.key;self.lastMessage=nil end
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
                old.weapon==s.weapon and (old.missing or old.enchant~=s.enchant or s.seconds>(old.seconds or 0)+2 or
                    (s.hasCharges and old.hasCharges and s.charges>old.charges))
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
    local family=tonumber(self.db.quickApply:match("^family:(%d+)$"))
    if family then return self.known[family],"This poison is unavailable. Carry it or choose Recent in Settings." end
    if self.db.quickApply~="last" then return self.byKey[self.db.quickApply],"Selected poison is unavailable. Restock it or choose a poison in Settings." end
    local history=self:History();local key=history and (history[hand==1 and "main" or "off"] or history.last)
    if key then return self.byKey[key],"Last-used poison is unavailable. Restock it or choose a poison in Settings." end
    return state.poison,"No last-used poison recorded. Choose a poison in Settings or apply one through Quick Access Poisons."
end
function M:Refresh()
    if not self.active or not self.isRogue then return end
    if D.OutsideCombat() then self:Discover();self:CreateDisplay();self:Layout() end
    self:Render()
    if D.OutsideCombat() then self:SyncEditElements();if self.page and self.page:IsShown() then self.page:Refresh() end end
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
function M:SetEditMode(v) self:StopDrag();self.editing=v;if v then self.menuOpen=false end;self:Refresh() end

-- Position Manager owns saved coordinates and Edit Mode decorations. Explicit
-- unlocked dragging outside Edit Mode forwards to the same position storage.
function M:RegisterPositions()
    local PM=addon.PositionManager
    for _,f in ipairs({self.watcher,self.launcher}) do
        local e=PM.elements[f.elementId]
        if e and e.position~=(addon.db.positions and addon.db.positions[f.elementId]) then PM:UnregisterElement(f.elementId);e=nil end
        if not e then
            -- Match the other registered displays: native geometry must exist
            -- before the manager asks for the owned frame's rectangle.
            local shown=f:IsShown();f:Show()
            local ok,registered=PM:RegisterElement(f.elementId,f,{moduleId=self.id,anchoring=false,allowedTargets={"screen"},
                defaultPosition={target="screen",placement="center",x=self.db[f.xKey],y=self.db[f.yKey]},
                canDrag=function() return self.active and self.db[f.enableKey] end,
                onPositionChanged=function(element,position)
                    self.db[f.xKey],self.db[f.yKey]=math.floor(position.x+0.5),math.floor(position.y+0.5)
                    if self.page then self.page:Refresh() end
                    if not element.dragging and not self.layingOut then self:Layout() end
                end,
                onHighlight=function()
                    if not addon.editMode then f:EnableMouse(D.OutsideCombat() and not self.db[f.lockKey]) end
                end})
            assert(ok,"Play The Game Tools: Rogue position registration failed: "..tostring(registered))
            e=registered;e.label=f.enableKey=="watcher" and "Rogue: Poison Reminder" or "Rogue: Quick Access Poisons"
            e.defaults={target="screen",placement="center",x=f.enableKey=="watcher" and 0 or 200,y=-140}
            if not shown then f:Hide() end
        end
        if not f.rogueDragHooks then
            f.rogueDragHooks=true
            f:HookScript("OnDragStart",function() if not addon.editMode then self:StartElementDrag(f) end end)
            f:HookScript("OnDragStop",function() self:StopDrag() end)
            f:HookScript("OnHide",function() self:StopDrag() end)
        end
        e.editMode=self.active and self.db[f.enableKey] or false
        self.db[f.xKey],self.db[f.yKey]=math.floor(e.position.x+0.5),math.floor(e.position.y+0.5)
        PM:ApplyPosition(f.elementId)
    end
end
function M:SyncEditElements()
    local PM=addon.PositionManager
    for _,f in ipairs({self.watcher,self.launcher}) do
        local e=PM.elements[f.elementId]
        if e then e.editMode=self.active and self.db[f.enableKey] or false;if not e.editMode then PM:StopDragging(f.elementId) end end
    end
    PM:RefreshSelection()
end
function M:SyncPosition(key)
    local quick=key=="menuX" or key=="menuY"
    local id=quick and "rogueQuickPoisons" or "roguePoisonReminder"
    local x,y=self.db[quick and "menuX" or "x"],self.db[quick and "menuY" or "y"]
    local PM=addon.PositionManager
    if PM.elements[id] then PM:SetOffsets(id,x,y)
    elseif addon.db.positions and addon.db.positions[id] and PM:ValidatePosition(addon.db.positions[id],true) then
        addon.db.positions[id].x=x;addon.db.positions[id].y=y
    end
end
function M:EnterElementEdit(quick)
    if not self.active or not D.OutsideCombat() or not self.db[quick and "flyout" or "watcher"] then return false end
    self:Refresh();addon:SetEditMode(true)
    return addon.PositionManager:SelectElement(quick and "rogueQuickPoisons" or "roguePoisonReminder")
end
function M:ResetElementPosition(quick)
    if not D.OutsideCombat() then return false end
    local id=quick and "rogueQuickPoisons" or "roguePoisonReminder"
    if addon.PositionManager.elements[id] then addon.PositionManager:ResetPosition(id)
    else self.db[quick and "menuX" or "x"]=quick and 200 or 0;self.db[quick and "menuY" or "y"]=-140;self:SyncPosition(quick and "menuX" or "x") end
    self:Refresh();return true
end
function M:IsDismissed(hand,state)
    local d=self.dismissed[hand]
    if not d then return false end
    if d.enchant and state.missing and d.weapon==state.weapon then
        d.enchant=nil;d.missing=true;d.seconds=0;return true
    end
    if d.weapon~=state.weapon or d.enchant~=state.enchant or d.missing~=state.missing or d.unknown~=state.unknown or state.empty or
        (state.seconds and d.seconds and state.seconds>d.seconds+2) or
        (state.hasCharges and d.charges~=nil and state.charges>d.charges) then self.dismissed[hand]=nil;return false end
    d.seconds=state.seconds;d.charges=state.hasCharges and state.charges or nil;return true
end
function M:DismissReminder(hand)
    if not self.active or self.previewing or self.editing or not self.db.dismissOnRightClick then return false end
    local state=self.reminderStates and self.reminderStates[hand]
    if not state or state.empty then return false end
    self.dismissed[hand]={weapon=state.weapon,enchant=state.enchant,missing=state.missing,unknown=state.unknown,seconds=state.seconds,charges=state.hasCharges and state.charges or nil}
    self:Render();if D.OutsideCombat() and self.page then self.page:Refresh() end;return true
end
function M:DismissQuickAccess()
    if not self.active or not D.OutsideCombat() or self.previewing or self.editing then return false end
    self.quickDismissed=true;self.menuOpen=false
    if GameTooltip then GameTooltip:Hide() end
    self:Render();if self.page then self.page:Refresh() end;return true
end
function M:RestoreReminders() self.dismissed={};self.quickDismissed=nil;self:Refresh() end
function M:MinimalReminder()
    if not D.OutsideCombat() then return false end
    local s=self.db.watchStyle
    s.showIcons=true;s.showHands=true;s.showNames=false;s.showTimers=false;s.showCounts=false;s.backgroundOpacity=0;s.borderSize=0;s.iconBorderSize=0;s.iconBackgroundOpacity=0;self.db.showPoisonCharges=false
    self:Refresh();return true
end
function M:ReminderNeeds(state)
    if state.empty then return false,false end
    if state.unknown or state.missing then return true,false end
    local timeDue=self.db.timeReminder and state.seconds<=self.db.threshold*60
    local chargeDue=self.db.chargeReminder and state.hasCharges and state.charges<=self.db.chargeThreshold
    return timeDue or chargeDue,chargeDue
end
