local _,addon=...
if not addon.ForeverRogue then return end
local M,D=addon.ForeverRogue,addon.ForeverRogueData
local function Label(parent) return parent:CreateFontString(nil,"OVERLAY","GameFontHighlight") end
local function Surface(parent)
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate");f:SetFrameStrata("MEDIUM");f:Hide();return f
end
local function Paint(f,s)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile=s.borderSize>0 and "Interface\\Buttons\\WHITE8X8" or nil,edgeSize=math.max(1,s.borderSize)})
    f:SetBackdropColor(s.backgroundColor[1],s.backgroundColor[2],s.backgroundColor[3],s.backgroundOpacity/100)
    f:SetBackdropBorderColor(s.borderColor[1],s.borderColor[2],s.borderColor[3],s.borderSize>0 and s.borderOpacity/100 or 0)
    f:SetScale(s.scale/100);f:SetAlpha(s.opacity/100)
end
function M:StopDrag()
    local f=self.dragging;if not f then return end
    f:StopMovingOrSizing();self.dragging=nil
    local x,y=f:GetCenter();local cx,cy=UIParent:GetCenter();local s=f:GetScale()
    if D.Number(x,-100000,100000) and D.Number(y,-100000,100000) and D.Number(cx,-100000,100000) and D.Number(cy,-100000,100000) then
        self.db[f.xKey]=math.floor(x*s-cx+0.5);self.db[f.yKey]=math.floor(y*s-cy+0.5)
    end
end
function M:DragHandle(f,xKey,yKey,lock)
    f.xKey,f.yKey,f.lockKey=xKey,yKey,lock;f:SetMovable(true);f:SetClampedToScreen(true);f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function()
        if D.OutsideCombat() and (not self.db[lock] or self.editing) then self.dragging=f;f:StartMoving() end
    end)
    f:SetScript("OnDragStop",function() self:StopDrag() end)
end
function M:Action(parent,hand,styleKey,dragOwner)
    local b=CreateFrame("Button",nil,parent,"InsecureActionButtonTemplate")
    b.nativeReady=D.Call(b.IsProtected,b)==false and type(b:GetScript("OnClick"))=="function"
    -- Explicit release dispatch keeps observer intent aligned with the native
    -- action edge, independently of the player's action-bar key-down preference.
    b:SetAttribute("useOnKeyDown",false)
    b:RegisterForClicks("LeftButtonDown","LeftButtonUp");b.styleKey=styleKey;b.hand=hand
    b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetAllPoints()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b.caption=Label(b);b.timer=Label(b);b.name=Label(b);b.count=Label(b)
    b:SetScript("OnEnter",function()
        if GameTooltip and self.db[styleKey].tooltips and b.description then GameTooltip:SetOwner(b,"ANCHOR_TOP");GameTooltip:SetText(b.description);GameTooltip:Show() end
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    -- Observe intent only. The template remains the sole owner of item/spell use.
    b:SetScript("PreClick",function(_,button,down)
        if not D.OutsideCombat() or button~="LeftButton" or down then return end
        if b.action then self.attempt={key=b.action.key,poison=b.action,hand=hand,time=GetTime()}
        elseif not down then
            self.lastMessage=b.description or "No available poison selected."
            print("Play The Game Tools: "..self.lastMessage)
            if self.page then self.page:Refresh() end
        end
    end)
    if dragOwner then
        b:RegisterForDrag("LeftButton")
        b:SetScript("OnDragStart",function() dragOwner:GetScript("OnDragStart")() end)
        b:SetScript("OnDragStop",function() self:StopDrag() end)
    end
    return b
end
function M:Bind(b,p,allow,reason,locked)
    if not D.OutsideCombat() then b:EnableMouse(false);return end
    allow=allow and self:Available(p) and b.nativeReady and locked and not self.editing and not self.previewing
    local key=allow and p.key or false
    if b.boundKey~=key then
        b:SetAttribute("type1",nil);b:SetAttribute("spell1",nil);b:SetAttribute("item1",nil);b:SetAttribute("target-slot1",nil)
        if allow then
            b:SetAttribute(p.kind=="item" and "item1" or "spell1",p.kind=="item" and ("item:"..p.id) or p.id)
            b:SetAttribute("target-slot1",b.hand==1 and 16 or 17);b:SetAttribute("type1",p.kind)
        end
        b.boundKey=key
    end
    b.action=allow and p or nil;b:EnableMouse(true)
    b.description=allow and (p.name.." — "..(b.hand==1 and "Main Hand" or "Off Hand")..". Click outside combat to apply.") or
        (not b.nativeReady and "Native out-of-combat action template unavailable." or
        (not locked or self.previewing or self.editing) and "Positioning / preview: application is disabled. Relock and finish preview to apply." or
        (p and not self:Available(p)) and "This poison is out of stock or its carried stacks are locked." or reason or "No poison available. Select Poison Refresh Quick Apply or use the flyout.")
end
function M:CreateDisplay()
    if self.watcher or not D.OutsideCombat() then return end
    self.watcher=Surface(UIParent);self:DragHandle(self.watcher,"x","y","locked")
    self.watchButtons={self:Action(self.watcher,1,"watchStyle",self.watcher),self:Action(self.watcher,2,"watchStyle",self.watcher)}
    self.launcher=Surface(UIParent);self:DragHandle(self.launcher,"menuX","menuY","flyoutLocked")
    local open=CreateFrame("Button",nil,self.launcher);self.openButton=open
    open.icon=open:CreateTexture(nil,"ARTWORK");open:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    open:SetScript("OnClick",function()
        if D.OutsideCombat() and self.active and self.db.flyout and self.db.flyoutLocked and not self.previewing and not self.editing then
            if #self.choices==0 then
                self.lastMessage="No usable poison found. Carry poison items, then click Refresh Poisons."
                print("Play The Game Tools: "..self.lastMessage);if self.page then self.page:Refresh() end;return
            end
            self.menuOpen=not self.menuOpen;self:Refresh()
        end
    end)
    open:RegisterForDrag("LeftButton")
    open:SetScript("OnDragStart",function() self.launcher:GetScript("OnDragStart")() end)
    open:SetScript("OnDragStop",function() self:StopDrag() end)
    open:SetScript("OnEnter",function()
        if GameTooltip and self.db.launcherStyle.tooltips then GameTooltip:SetOwner(open,"ANCHOR_TOP");GameTooltip:SetText("Poisons — click to choose Main Hand or Off Hand.");GameTooltip:Show() end
    end)
    open:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    self.menu=Surface(UIParent);self.menu:SetFrameStrata("DIALOG");self.menu:SetClampedToScreen(true)
    self.menuScroll=CreateFrame("ScrollFrame",nil,self.menu);self.menuScroll:EnableMouseWheel(true)
    self.menuContent=CreateFrame("Frame",nil,self.menuScroll);self.menuScroll:SetScrollChild(self.menuContent)
    self.menuScroll:SetScript("OnMouseWheel",function(_,delta)
        if D.OutsideCombat() then self.scrollOffset=math.max(0,math.min(self.scrollMaximum or 0,(self.scrollOffset or 0)-delta*40));self.menuScroll:SetVerticalScroll(self.scrollOffset) end
    end)
    self.scrollHint=Label(self.menu);self.scrollHint:SetPoint("BOTTOM",0,4)
    self.menuRows={}
    for i=1,D.limit do self.menuRows[i]={name=Label(self.menuContent),self:Action(self.menuContent,1,"flyoutStyle"),self:Action(self.menuContent,2,"flyoutStyle")} end
end
local function Cell(b,s,showName)
    local size=s.iconSize;b:SetSize(size,size);b.icon:SetTexCoord(s.cropIcons and 0.06 or 0,s.cropIcons and 0.94 or 1,s.cropIcons and 0.06 or 0,s.cropIcons and 0.94 or 1)
    b.icon:SetVertexColor(unpack(s.iconColor));b.icon:SetShown(s.showIcons)
    for _,t in ipairs({b.caption,b.name,b.count}) do D.Font(t,s,false) end;D.Font(b.timer,s,true)
    b.caption:ClearAllPoints();b.caption:SetPoint("TOP",b,"BOTTOM",0,-s.labelGap);b.caption:SetText(b.hand==1 and "Main Hand" or "Off Hand");b.caption:SetShown(s.showHands)
    b.name:ClearAllPoints();b.name:SetPoint("TOP",b,"BOTTOM",0,-s.labelGap-(s.showHands and (s.fontSize+s.labelGap) or 0));b.name:SetWidth(s.cellWidth);b.name:SetWordWrap(false);b.name:SetShown(showName and s.showNames)
    b.count:ClearAllPoints();b.count:SetPoint("BOTTOMRIGHT",-2,2)
    b.timer:ClearAllPoints()
    if s.timerPosition=="TOP" then b.timer:SetPoint("BOTTOM",b,"TOP",0,s.labelGap)
    elseif s.timerPosition=="BOTTOM" then
        local y=s.labelGap+(s.showHands and s.fontSize+s.labelGap or 0)+(showName and s.showNames and s.fontSize+s.labelGap or 0)
        b.timer:SetPoint("TOP",b,"BOTTOM",0,-y)
    else b.timer:SetPoint("CENTER") end
end
local function Height(s,names,timers)
    return s.iconSize+(s.showHands and s.fontSize+s.labelGap or 0)+(names and s.showNames and s.fontSize+s.labelGap or 0)+
        (timers and s.showTimers and s.timerPosition~="CENTER" and s.timerSize+s.labelGap or 0)
end
function M:Layout()
    if not self.watcher or not D.OutsideCombat() then return end
    local db=self.db;local s=db.watchStyle;local cell=math.max(s.cellWidth,s.iconSize)
    local height=Height(s,true,true);local top=s.showTimers and s.timerPosition=="TOP" and s.timerSize+s.labelGap or 0
    Paint(self.watcher,s);self.watcher:ClearAllPoints();self.watcher:SetPoint("CENTER",UIParent,"CENTER",db.x/(s.scale/100),db.y/(s.scale/100))
    self.watcher:SetSize(s.padding*2+(s.vertical and cell or cell*2+s.spacing),s.padding*2+(s.vertical and height*2+s.spacing or height))
    for i,b in ipairs(self.watchButtons) do
        Cell(b,s,true);b:ClearAllPoints()
        b:SetPoint("TOP",self.watcher,"TOPLEFT",s.padding+cell/2+(not s.vertical and (i-1)*(cell+s.spacing) or 0),-s.padding-top-(s.vertical and (i-1)*(height+s.spacing) or 0))
    end
    s=db.launcherStyle;Paint(self.launcher,s);self.launcher:ClearAllPoints()
    self.launcher:SetPoint("CENTER",UIParent,"CENTER",db.menuX/(s.scale/100),db.menuY/(s.scale/100));self.launcher:SetSize(s.iconSize+s.padding*2,s.iconSize+s.padding*2)
    self.openButton:SetAllPoints();self.openButton.icon:ClearAllPoints();self.openButton.icon:SetPoint("TOPLEFT",s.padding,-s.padding);self.openButton.icon:SetPoint("BOTTOMRIGHT",-s.padding,s.padding)
    local profession=D.Spell(2842);self.openButton.icon:SetTexture(profession and profession.icon or "Interface\\Icons\\Trade_BrewPoison")
    self.openButton.icon:SetTexCoord(s.cropIcons and 0.06 or 0,s.cropIcons and 0.94 or 1,s.cropIcons and 0.06 or 0,s.cropIcons and 0.94 or 1)
    self.openButton.icon:SetVertexColor(unpack(s.iconColor))
    s=db.flyoutStyle;Paint(self.menu,s)
    local width=math.max(s.cellWidth,s.iconSize*2+s.spacing);local nameHeight=s.showNames and s.fontSize+s.labelGap or 0
    local rowHeight=Height(s,false,false)+nameHeight+s.spacing
    local rows=math.max(1,math.ceil(#self.choices/s.columns));local visible=math.min(rows,db.visibleRows)
    local bodyWidth=width*s.columns+s.spacing*(s.columns-1);local viewHeight=visible*rowHeight-s.spacing
    self.menu:SetSize(bodyWidth+s.padding*2,viewHeight+s.padding*2+(rows>visible and s.fontSize+8 or 0))
    self.menuScroll:ClearAllPoints();self.menuScroll:SetPoint("TOPLEFT",s.padding,-s.padding);self.menuScroll:SetSize(bodyWidth,viewHeight)
    self.menuContent:SetSize(bodyWidth,rows*rowHeight-s.spacing)
    self.scrollMaximum=math.max(0,(rows-visible)*rowHeight);self.scrollOffset=math.min(self.scrollOffset or 0,self.scrollMaximum);self.menuScroll:SetVerticalScroll(self.scrollOffset)
    D.Font(self.scrollHint,s,false);self.scrollHint:SetText("Mouse wheel to scroll");self.scrollHint:SetShown(rows>visible)
    self.menu:ClearAllPoints()
    local anchors={UP={"BOTTOMLEFT","TOPLEFT",0,5},DOWN={"TOPLEFT","BOTTOMLEFT",0,-5},LEFT={"TOPRIGHT","TOPLEFT",-5,0},RIGHT={"TOPLEFT","TOPRIGHT",5,0}}
    local a=anchors[db.direction];self.menu:SetPoint(a[1],self.launcher,a[2],a[3],a[4])
    for i,row in ipairs(self.menuRows) do
        local x=((i-1)%s.columns)*(width+s.spacing);local y=-math.floor((i-1)/s.columns)*rowHeight
        D.Font(row.name,s,false);row.name:ClearAllPoints();row.name:SetPoint("TOPLEFT",x,y);row.name:SetWidth(width);row.name:SetWordWrap(false)
        for hand=1,2 do local b=row[hand];Cell(b,s,false);b:ClearAllPoints();b:SetPoint("TOP",self.menuContent,"TOPLEFT",x+width*(hand==1 and 0.25 or 0.75),y-nameHeight) end
    end
end
function M:Render()
    if not self.active or not self.isRogue or not self.watcher then return end
    if not self.db.watcher and not self.db.flyout then self.watcher:Hide();self.launcher:Hide();self.menu:Hide();return end
    local db=self.db;local ooc=D.OutsideCombat();local states={self:ReadHand(1),self:ReadHand(2)}
    self:Observe(states)
    local preview=ooc and (self.previewing or self.editing);local any,due=false,false
    for hand,b in ipairs(self.watchButtons) do
        local state=states[hand];local p,reason=self:QuickPoison(hand,state);local s=db.watchStyle
        local needs=not state.empty and (state.unknown or state.seconds<=db.threshold*60);due=due or needs
        local placement=ooc and (preview or not db.locked)
        local show=db.watcher and (ooc or db.showInCombat) and (needs or placement)
        if show then
            any=true;b.icon:SetTexture(state.icon or (p and p.icon) or "Interface\\Icons\\Trade_BrewPoison")
            local text=state.empty and "No weapon" or state.unknown and "Unknown" or state.missing and "Missing" or string.format("%d:%02d",math.floor(state.seconds/60),math.floor(state.seconds%60))
            b.timer:SetText(placement and "Preview" or text);b.timer:SetShown(s.showTimers)
            b.name:SetText(p and p.name or "Select Poison");b.name:SetShown(s.showNames)
            b.count:SetText(p and p.count and tostring(p.count) or "");b.count:SetShown(s.showCounts and p~=nil and p.count~=nil)
        end
        self:Bind(b,p,show and not state.empty and not state.unknown,
            state.unknown and "Weapon poison information is unavailable or restricted." or reason,db.locked)
        b:SetShown(show and true or false)
    end
    self.watcher:SetShown(any)
    local launcher=ooc and db.flyout and (due or db.alwaysShow or preview or not db.flyoutLocked)
    self.launcher:SetShown(launcher);self.openButton:SetEnabled(ooc)
    if not launcher then self.menuOpen=false end
    local menu=launcher and (self.menuOpen or preview or not db.flyoutLocked)
    for i,row in ipairs(self.menuRows) do
        local p=self.choices[i];local s=db.flyoutStyle
        row.name:SetText(p and (p.name..(p.kind=="spell" and " (learned)" or "")) or "");row.name:SetShown(menu and p~=nil and s.showNames)
        for hand=1,2 do
            local b=row[hand];local state=states[hand]
            if p then b.icon:SetTexture(p.icon);b.count:SetText(p.count and tostring(p.count) or "") end
            b.timer:Hide();b.name:Hide();b.count:SetShown(s.showCounts and p~=nil and p.count~=nil)
            self:Bind(b,p,menu and not state.empty and state.weapon~=nil,
                "No equipped melee weapon in this hand.",db.flyoutLocked)
            b:SetShown(menu and p~=nil)
        end
    end
    self.menu:SetShown(menu and #self.choices>0)
    self.status=self.bagStatus or (#self.choices==0 and "No usable poison found. Carry poison items, then click Refresh Poisons." or
        (#self.choices.." poison choices. Quick Apply defaults to each character's last observed poison; unavailable choices explain why when clicked."))
end
