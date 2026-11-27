local _,addon=...
local M=addon.BuffReminders
if not M then return end
local D=addon.BuffRemindersData
local Public,Number=D.Public,D.Number

-- Two plain (unprotected) displays, each placed and styled in Layout:
--   buffReminders       your reminders as icons, text or the single most urgent one
--   buffRemindersGroup  the group watcher: one small icon per player with their name
-- Neither frame takes secure actions; BuffRemindersSecure.lua lays click
-- buttons over them out of combat, and BuffRemindersMenu.lua adds the choice menus.
local MAIN,GROUP="buffReminders","buffRemindersGroup"
M.MAIN_ID,M.GROUP_ID=MAIN,GROUP
local WHITE={1,1,1}
local LABEL_COLOR={0.91,0.89,0.81}
local FALLBACK_ICON=134400
local OUTLINE_FLAGS={none="",outline="OUTLINE",thick="THICKOUTLINE"}

local function Paint(texture,color,alpha) texture:SetColorTexture(color[1],color[2],color[3],alpha or 1) end

local function Text(parent,size,scope)
    local text=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    addon.Media:BindInterfaceFont(text,GameFontHighlight,size,scope)
    text.baseSize=size
    text:SetShadowColor(0,0,0,1);text:SetShadowOffset(1,-1)
    text:SetWordWrap(false)
    return text
end

-- Border drawn inside the icon, so its size never changes the icon's footprint.
local function Edges(frame)
    local edges={}
    for i=1,4 do edges[i]=frame:CreateTexture(nil,"OVERLAY") end
    return edges
end
local function EdgeColor(button,color,alpha,size)
    size=size or 1
    local e=button.edges
    if button.edgeSize~=size then
        button.edgeSize=size
        e[1]:ClearAllPoints();e[1]:SetPoint("TOPLEFT");e[1]:SetPoint("TOPRIGHT");e[1]:SetHeight(size)
        e[2]:ClearAllPoints();e[2]:SetPoint("BOTTOMLEFT");e[2]:SetPoint("BOTTOMRIGHT");e[2]:SetHeight(size)
        e[3]:ClearAllPoints();e[3]:SetPoint("TOPLEFT");e[3]:SetPoint("BOTTOMLEFT");e[3]:SetWidth(size)
        e[4]:ClearAllPoints();e[4]:SetPoint("TOPRIGHT");e[4]:SetPoint("BOTTOMRIGHT");e[4]:SetWidth(size)
    end
    for _,t in ipairs(e) do
        if color and size>0 then Paint(t,color,alpha or 1);t:Show() else t:Hide() end
    end
end
M.EdgeColor=EdgeColor

-- Icon button: icon, state border, timer, charges, hand label and an optional player name.
local function Icon(self,parent,scope)
    local b=CreateFrame("Button",nil,parent)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetAllPoints();b.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    b.edges=Edges(b)
    b.timer=Text(b,11,scope);b.count=Text(b,10,scope);b.name=Text(b,9,scope);b.label=Text(b,10,scope)
    b.count:SetPoint("TOPRIGHT",-2,-2)
    b:SetScript("OnEnter",function() self:ShowTooltip(b) end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnClick",function(_,button)
        if button=="RightButton" and b.entry and not b.entry.sample then self:Dismiss(b.dismissKey or b.entry.key) end
    end)
    b:Hide()
    return b
end

function M:CreateDisplay()
    if self.frame then return end
    local T=addon.InterfaceTheme
    local f=CreateFrame("Frame","PlayTheGameToolsBuffRemindersFrame",UIParent)
    self.frame=f
    f:Hide();f:SetSize(200,48);f:SetFrameStrata("MEDIUM");f:SetClampedToScreen(true);f:EnableMouse(false)
    -- A real rectangle before Layout registers it; Position Manager takes over from there.
    f:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
    f.background=f:CreateTexture(nil,"BACKGROUND");f.background:SetAllPoints()
    addon.Media:PaintSurface(f.background,T.panel,0.55,MAIN)
    f.icons={};f.rows={}
    f.label=Text(f,12,MAIN);f.sub=Text(f,10,MAIN)
    f.empty=Text(f,11,MAIN);f.empty:SetPoint("CENTER");f.empty:SetTextColor(T.muted[1],T.muted[2],T.muted[3])
    -- Glow pulse runs only while an expiring reminder is shown with glow on.
    self.pulse=CreateFrame("Frame",nil,f)
    self.pulseScript=function(_,elapsed)
        self.pulseTime=(self.pulseTime or 0)+elapsed
        local alpha=0.55+0.45*math.sin(self.pulseTime*4)
        local look=self.db.look
        for _,b in ipairs(f.icons) do if b:IsShown() and b.glowing then EdgeColor(b,look.colorExpiring,alpha,math.max(1,look.borderSize)) end end
    end

    local g=CreateFrame("Frame","PlayTheGameToolsBuffRemindersGroupFrame",UIParent)
    self.groupFrame=g
    g:Hide();g:SetSize(200,60);g:SetFrameStrata("MEDIUM");g:SetClampedToScreen(true);g:EnableMouse(false)
    g:SetPoint("CENTER",UIParent,"CENTER",self.db.groupX,self.db.groupY)
    g.background=g:CreateTexture(nil,"BACKGROUND");g.background:SetAllPoints()
    addon.Media:PaintSurface(g.background,T.panel,0.6,GROUP)
    g.headers={};g.tiles={};g.rows={}
end

function M:IconFor(e)
    local b,s=e.buff,e.state or {}
    if s.icon and Public(s.icon) and not self:HasMenu(b) then return s.icon end
    if b.kind=="totem" then
        local t=D.TotemType(b.element,self.db.totems[b.element])
        local id=t and (self:Best(t.spells) or t.spells[1])
        return id and self:SpellIcon(id) or FALLBACK_ICON
    end
    if b.kind=="food" then
        local id=self:LastFood()
        return id and self:ItemIcon(id) or b.icon
    end
    if b.key=="weaponOil" then
        local id=self:LastItem(b) or D.items.weaponOil[1]
        return self:ItemIcon(id) or b.icon
    end
    if b.poison or b.key=="weaponStone" then
        local list=D.items[self:ItemFamily(b)] or {}
        local id=self:BestItem(list) or list[1]
        return id and self:ItemIcon(id) or FALLBACK_ICON
    end
    if b.key=="soulstone" then return self:ItemIcon(self:BestItem(D.items.soulstone) or 5232) or self:SpellIcon(693) or FALLBACK_ICON end
    if b.icon then return b.icon end
    local chain=self:ChainFor(b)
    local id=chain and (self:Best(chain) or chain[1]) or (b.detect and b.detect[1])
    return id and self:SpellIcon(id) or FALLBACK_ICON
end

local function Clock(seconds)
    if seconds>=3600 then return math.floor(seconds/3600+0.5).."h" end
    if seconds>=60 then return math.ceil(seconds/60).."m" end
    return math.max(0,math.floor(seconds+0.5)).."s"
end
M.Clock=Clock

function M:TimerText(e)
    if e.status=="missing" then return e.buff.kind=="totem" and "Not placed" or "Missing" end
    if e.status=="unknown" then return "?" end
    if e.left and e.left>0 then return (e.estimated and "~" or "")..Clock(e.left) end
    if e.charges then return e.charges.."c" end
    return ""
end

-- "MH" / "OH" or "Main Hand" / "Off Hand", for per-hand reminders only.
function M:HandLabel(b)
    if not b or not b.hand then return end
    if self.db.look.labelStyle=="long" then return b.hand==1 and "Main Hand" or "Off Hand" end
    return b.hand==1 and "MH" or "OH"
end

-- The name a reminder shows: "Poison Missing (MH)", "Windfury Totem Missing", "Arcane Intellect 3m".
function M:EntryName(e)
    local b=e.buff
    if e.combined then return e.combined end
    if b.kind=="totem" then
        local t=D.TotemType(b.element,self.db.totems[b.element]);return t and t.label or b.name
    end
    if b.key=="soulstone" then
        if e.resource=="none" then return "Soulstone (no shard)" end
        if not self:BestItem(D.items.soulstone) and e.status=="missing" then return "Create Soulstone" end
        return "Soulstone"
    end
    if b.choice and b.kind~="weapon" and b.key~="armor" and b.key~="demonPet" then return D.ChoiceLabel(b.choice,self.db.choices[b.choice]) or b.name end
    return b.name
end

-- Missing Main-hand and Off-hand reminders of one kind read as one line in text mode.
function M:TextLines(shown,keepSlots)
    local lines,used={},{}
    -- In combat every line keeps its own slot, so nothing is merged.
    for _,pair in ipairs(keepSlots and {} or {{"poisonMain","poisonOff","Poison"},{"imbueMain","imbueOff","Imbue"}}) do
        local hands={}
        for _,e in ipairs(shown) do
            if (e.key==pair[1] or e.key==pair[2]) and e.status=="missing" then hands[#hands+1]=e end
        end
        if #hands>0 then
            local tags={}
            for _,e in ipairs(hands) do tags[#tags+1]=self:HandLabel(e.buff);used[e.key]=true end
            lines[#lines+1]={entry=hands[1],keys=hands[1].key..(hands[2] and ","..hands[2].key or ""),label=pair[3].." Missing ("..table.concat(tags,"/")..")",value="",status="missing",dim=hands[1].resource~="ok"}
        end
    end
    for _,e in ipairs(shown) do
        if not used[e.key] then
            local name=self:EntryName(e)
            local label,value
            if e.buff.poison or e.key=="imbueMain" or e.key=="imbueOff" then name=(e.buff.poison and "Poison" or "Imbue").." ("..self:HandLabel(e.buff)..")" end
            if e.status=="missing" and not e.combined then label=name.." Missing";value=""
            else label=name..(e.who and e.who~="you" and " ("..e.who..")" or "");value=self:TimerText(e) end
            if e.combined then label=e.combined;value=e.combinedDetail or "" end
            lines[#lines+1]={entry=e,keys=e.slotKeys or e.dismissKeys or e.key,label=label,value=value,status=e.status,dim=e.resource~="ok",estimated=e.estimated}
        end
    end
    return lines
end

-- Several missing totems may show as one "Totems Missing" reminder.
function M:GroupTotems(shown)
    if self.db.totemMode~="one" then return shown end
    local missing,out={},{}
    for _,e in ipairs(shown) do if e.buff.kind=="totem" and e.status=="missing" then missing[#missing+1]=e end end
    if #missing<2 then return shown end
    local names,keys={},{}
    for _,e in ipairs(missing) do
        local t=D.TotemType(e.buff.element,self.db.totems[e.buff.element])
        names[#names+1]=t and t.label:gsub(" Totem$","") or e.buff.short;keys[#keys+1]=e.key
    end
    local combinedAdded=false
    for _,e in ipairs(shown) do
        if e.buff.kind=="totem" and e.status=="missing" then
            if not combinedAdded then
                combinedAdded=true
                out[#out+1]={buff=e.buff,key="totems",state={},status="missing",resource=e.resource,combined="Totems Missing",
                    combinedDetail="("..table.concat(names,", ")..")",dismissKeys=table.concat(keys,","),totems=missing}
            end
        else out[#out+1]=e end
    end
    return out
end

local function StyleSize(id,size)
    return addon.PositionManager:StyleFontSize(id,size,id==MAIN and M.renderStyle or nil)
end
-- Fonts are bound once per size; the Media registry redraws them on global font changes.
local function SetFont(text,id,size,scope)
    local applied=StyleSize(id,size)
    if text.appliedSize==applied and not text.customFont then return end
    text.appliedSize,text.customFont=applied,nil
    addon.Media:BindInterfaceFont(text,GameFontHighlight,applied,scope or id)
end

-- The timer and label font chosen on the Style card (game, chat or a SharedMedia font).
function M:TextFont()
    local key=self.db.look.timerFont
    local media=addon.Media
    if key=="chat" then return media.chatFont or GameFontHighlight:GetFont() end
    if key:sub(1,6)=="media:" then
        local path=media:GetFont(key:sub(7))
        if path then return path end
    end
    return media.gameFont or GameFontHighlight:GetFont()
end
-- Display text in the chosen font, size and outline; reapplied only when one changes.
local function SetLookFont(self,text,size)
    local look=self.db.look
    local path,applied,flags=self.renderFont or self:TextFont(),StyleSize(MAIN,size),OUTLINE_FLAGS[look.timerOutline]
    local key=tostring(path).."|"..applied.."|"..flags
    if text.customFont==key then return end
    addon.Media:UnbindInterfaceFont(text)
    if not text:SetFont(path,applied,flags) then text:SetFont(GameFontHighlight:GetFont(),applied,flags) end
    text:SetShadowOffset(look.timerOutline=="none" and 1 or 0,look.timerOutline=="none" and -1 or 0)
    text.customFont,text.appliedSize=key,nil
end
M.SetLookFont=SetLookFont

function M:ClassColor(class)
    local c=class and addon.GlobalSettings and addon.GlobalSettings:GetClassColor(class)
    return c and {c.r,c.g,c.b} or WHITE
end

function M:StateColor(status)
    if self.db.look.timerColor=="white" then return WHITE end
    if status=="missing" then return {1,0.42,0.38} end
    if status=="expiring" then return self.db.look.colorExpiring end
    return {0.9,0.9,0.9}
end

-- Main display ----------------------------------------------------------------

-- Space every icon reserves above and below itself, so all icons share one line
-- whether or not each shows a hand label.
function M:Bands(list,withTimer)
    local look=self.db.look
    local timerH=StyleSize(MAIN,look.timerSize)+3
    local labelH=StyleSize(MAIN,look.labelSize)+3
    local labels=false
    if look.labels then for _,e in ipairs(list) do if e.buff and e.buff.hand then labels=true end end end
    local top,bottom=0,0
    if labels and look.labelPosition=="above" then top=top+labelH end
    if withTimer and look.timer=="above" then top=top+timerH end
    if withTimer and look.timer=="below" then bottom=bottom+timerH end
    if labels and look.labelPosition=="under" then bottom=bottom+labelH end
    return top,bottom,labels,timerH
end

function M:Render(shown)
    local f=self.frame
    if not f then return end
    self.renderStyle=addon.PositionManager:GetStyle(MAIN)
    self.renderFont=self:TextFont()
    local placing=(self.editing or self.previewing) and self.active
    if not self.active then f:Hide();self.slots={};return end
    local list=placing and self:Samples() or self:GroupTotems(shown)
    -- In combat, reminders keep the places they had when combat began, so the
    -- click buttons laid over them (which can't move in combat) still match.
    local frozenView=false
    if self.suppressed and not placing then list={} end
    if self:InCombat() and self.frozen and not placing and not self.suppressed then
        frozenView=true
        local byKey,ordered,used={},{},{}
        for _,e in ipairs(list) do
            byKey[e.key]=byKey[e.key] or e
            if e.dismissKeys then for k in e.dismissKeys:gmatch("[^,]+") do byKey[k]=byKey[k] or e end end
        end
        for _,keys in ipairs(self.frozen) do
            local e
            for k in tostring(keys):gmatch("[^,]+") do if not e and byKey[k] and not used[byKey[k]] then e=byKey[k] end end
            e=e or self:FrozenEntry(tostring(keys):match("^[^,]+"))
            if e then used[e]=true;e.slotKeys=keys;ordered[#ordered+1]=e end
        end
        for _,e in ipairs(list) do if not used[e] then e.late=true;ordered[#ordered+1]=e end end
        list=ordered
    end
    self.frozenCount=frozenView and #self.frozen or nil
    self.slots={}
    local look=self.db.look
    local mode=self.db.mode
    for _,b in ipairs(f.icons) do b:Hide();b.glowing=false end
    for _,r in ipairs(f.rows) do r:Hide() end
    f.label:Hide();f.sub:Hide();f.empty:Hide()
    f.background:SetShown(addon.PositionManager:StyleBackground(MAIN))
    if #list==0 then
        f:Hide()
        self:SetPulse(false)
        return
    end
    -- Frame size is held in combat: the frame is centre-anchored, so resizing it
    -- would slide every icon away from the click button laid over it.
    local function Size(w,h) if not frozenView then f:SetSize(w,h) end end
    local width,height,gap=look.iconWidth,look.iconHeight,look.spacing
    local anyGlow=false
    if mode=="text" then
        local lines=self:TextLines(list,frozenView)
        local textW,lineHeight=0,StyleSize(MAIN,look.timerSize)+6
        for i,line in ipairs(lines) do
            local r=f.rows[i]
            if not r then
                r=CreateFrame("Button",nil,f);r:RegisterForClicks("LeftButtonUp","RightButtonUp")
                r.label=Text(r,12,MAIN);r.value=Text(r,12,MAIN)
                r.label:SetPoint("LEFT",4,0);r.label:SetJustifyH("LEFT");r.value:SetPoint("RIGHT",-4,0);r.value:SetJustifyH("RIGHT")
                r:SetScript("OnEnter",function() self:ShowTooltip(r) end)
                r:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
                r:SetScript("OnClick",function(_,button) if button=="RightButton" and r.entry and not r.entry.sample then self:Dismiss(r.dismissKey) end end)
                f.rows[i]=r
            end
            SetLookFont(self,r.label,look.timerSize);SetLookFont(self,r.value,look.timerSize)
            r.entry,r.dismissKey=line.entry,line.keys
            r.label:SetText(line.label);r.value:SetText(line.value)
            local c=line.dim and {0.55,0.55,0.55} or self:StateColor(line.status)
            r.label:SetTextColor(c[1],c[2],c[3]);r.value:SetTextColor(c[1],c[2],c[3])
            local w=(r.label:GetStringWidth() or 0)+(r.value:GetStringWidth() or 0)+28
            if Number(w,0,4000) then textW=math.max(textW,w) end
            r.line=line;r.index=i
            self.slots[#self.slots+1]={region=r,entry=line.entry,keys=line.keys,late=line.entry.late}
        end
        textW=math.max(160,textW)
        for i,r in ipairs(f.rows) do
            if i<=#lines then
                r:ClearAllPoints();r:SetPoint("TOPLEFT",4,-4-(i-1)*lineHeight);r:SetSize(textW,lineHeight);r:Show()
            end
        end
        Size(textW+8,#lines*lineHeight+8)
    elseif mode=="single" then
        if not frozenView then table.sort(list,function(a,b)
            local ra,rb=a.status=="missing" and 0 or 1,b.status=="missing" and 0 or 1
            if ra~=rb then return ra<rb end
            return (a.left or 0)<(b.left or 0)
        end) end
        local e=list[1]
        local top=self:Bands({e},false)
        local b=self:PaintIcon(1,e,false)
        b:ClearAllPoints();b:SetPoint("TOPLEFT",6,-6-top)
        anyGlow=b.glowing
        local lines=self:TextLines({e})
        SetLookFont(self,f.label,look.timerSize);SetLookFont(self,f.sub,math.max(8,look.timerSize-2))
        local c=self:StateColor(e.status)
        f.label:SetTextColor(0.95,0.93,0.86);f.sub:SetTextColor(c[1],c[2],c[3])
        f.label:SetText(lines[1] and lines[1].label or self:EntryName(e))
        f.sub:SetText((e.status=="missing" and "Missing" or (e.left and ("Expires in "..self:TimerText(e)) or ""))..(#list>1 and ("  ·  +"..(#list-1).." more") or ""))
        f.label:ClearAllPoints();f.label:SetPoint("TOPLEFT",b,"TOPRIGHT",8,-2);f.label:Show()
        f.sub:ClearAllPoints();f.sub:SetPoint("BOTTOMLEFT",b,"BOTTOMRIGHT",8,2);f.sub:Show()
        local w=math.max(f.label:GetStringWidth() or 0,f.sub:GetStringWidth() or 0)
        Size(width+20+(Number(w,0,4000) and w or 120),height+12+top)
        self.slots[1]={region=b,entry=e,keys=e.slotKeys or e.dismissKeys or e.key,late=e.late}
    else
        local vertical=look.grow=="down" or look.grow=="up"
        local count=math.max(#list,self:MaxIcons())
        local top,bottom=self:Bands(list,true)
        -- In combat the bands stay as they were at combat start, like the frame size.
        if frozenView and self.frozenBands then top,bottom=self.frozenBands[1],self.frozenBands[2]
        else self.lastBands={top,bottom} end
        local cellW,cellH=width+gap,top+height+bottom+gap
        local frameW=vertical and width or count*width+(count-1)*gap
        local frameH=vertical and (count*(top+height+bottom)+(count-1)*gap) or top+height+bottom
        Size(frameW+8,frameH+8)
        for i,e in ipairs(list) do
            local b=self:PaintIcon(i,e,true)
            anyGlow=anyGlow or b.glowing
            b:ClearAllPoints()
            local n=self.frozenCount or #list
            if look.grow=="right" then b:SetPoint("TOPLEFT",4+(i-1)*cellW,-4-top)
            elseif look.grow=="left" then b:SetPoint("TOPRIGHT",-4-(i-1)*cellW,-4-top)
            elseif look.grow=="center" then
                local used=n*width+(n-1)*gap
                b:SetPoint("TOPLEFT",4+(frameW-used)/2+(i-1)*cellW,-4-top)
            elseif look.grow=="down" then b:SetPoint("TOPLEFT",4,-4-top-(i-1)*cellH)
            else b:SetPoint("BOTTOMLEFT",4,4+bottom+(i-1)*cellH) end
            self.slots[#self.slots+1]={region=b,entry=e,keys=e.slotKeys or e.dismissKeys or e.key,late=e.late}
        end
    end
    f:Show()
    self:SetPulse(anyGlow and look.glow)
end

-- The display keeps room for every reminder that can apply, so it grows from a fixed edge.
function M:MaxIcons()
    local n=0
    for _,b in ipairs(D.buffs) do if self:Applicable(b) then n=n+1 end end
    return math.max(1,math.min(n,12))
end

function M:FrozenEntry(key)
    local b=D.byKey[key]
    if not b then return end
    local s=self.states[key] or {}
    return {buff=b,key=key,state=s,status="ok",left=self:Remaining(s),estimated=true,resource="ok",frozen=true}
end

function M:PaintIcon(index,e,withText)
    local f,look=self.frame,self.db.look
    local b=f.icons[index]
    if not b then b=Icon(self,f,MAIN);f.icons[index]=b end
    b:SetSize(look.iconWidth,look.iconHeight)
    b.entry,b.dismissKey=e,e.slotKeys or e.dismissKeys or e.key
    local icon=self:IconFor(e)
    b.icon:SetTexture(icon or FALLBACK_ICON)
    -- Keep the art square on non-square icons by trimming the long side.
    local w,h=look.iconWidth,look.iconHeight
    local cx,cy=0.07,0.07
    if w>h then cy=0.07+0.43*(1-h/w) elseif h>w then cx=0.07+0.43*(1-w/h) end
    b.icon:SetTexCoord(cx,1-cx,cy,1-cy)
    local dim=e.resource~="ok" and not e.sample
    b.icon:SetDesaturated(dim or e.status=="missing" or e.frozen==true)
    local shade=dim and 0.45 or (e.status=="missing" and 0.75 or 1)
    b.icon:SetVertexColor(shade,shade,shade)
    b:SetAlpha(dim and 0.6 or (e.frozen and 0.5 or 1))
    b.glowing=false
    local size=look.borderSize
    if e.status=="missing" then EdgeColor(b,dim and {0.4,0.4,0.4} or look.colorMissing,1,size)
    elseif e.status=="expiring" then EdgeColor(b,look.colorExpiring,1,size);b.glowing=not dim and look.glow
    elseif look.fineBorder then EdgeColor(b,look.colorFine,1,size)
    else EdgeColor(b,nil) end
    -- Timer: below, above, inside (top, centre, bottom) or hidden.
    SetLookFont(self,b.timer,look.timerSize);SetFont(b.count,MAIN,10)
    local label=look.labels and self:HandLabel(e.buff)
    local timerPos=look.timer
    if label and look.labelPosition=="top" and timerPos=="top" then timerPos="bottom" end
    if not withText and (timerPos=="below" or timerPos=="above") then timerPos="hidden" end
    local text=e.sample and (e.status=="missing" and "Missing" or Clock(e.left or 60)) or self:TimerText(e)
    local timerH=StyleSize(MAIN,look.timerSize)+3
    b.timer:ClearAllPoints()
    if timerPos=="below" then b.timer:SetPoint("TOP",b,"BOTTOM",0,-2)
    elseif timerPos=="above" then b.timer:SetPoint("BOTTOM",b,"TOP",0,2)
    elseif timerPos=="top" then b.timer:SetPoint("TOP",b,"TOP",0,-2)
    elseif timerPos=="center" then b.timer:SetPoint("CENTER",b,"CENTER",0,0)
    else b.timer:SetPoint("BOTTOM",b,"BOTTOM",0,2) end
    b.timer:SetText(text);b.timer:SetShown(timerPos~="hidden" and text~="")
    local c=self:StateColor(e.status)
    b.timer:SetTextColor(c[1],c[2],c[3])
    -- Hand label: above the icon, inside at the top, or below the timer.
    b.label:ClearAllPoints()
    if label then
        SetLookFont(self,b.label,look.labelSize)
        b.label:SetText(label);b.label:SetTextColor(LABEL_COLOR[1],LABEL_COLOR[2],LABEL_COLOR[3])
        if look.labelPosition=="top" then b.label:SetPoint("TOP",b,"TOP",0,-2)
        elseif look.labelPosition=="under" then b.label:SetPoint("TOP",b,"BOTTOM",0,-2-(timerPos=="below" and timerH or 0))
        else b.label:SetPoint("BOTTOM",b,"TOP",0,2+(timerPos=="above" and timerH or 0)) end
        b.label:Show()
    else b.label:Hide() end
    b.count:SetText(e.charges and tostring(e.charges) or "");b.count:SetShown(self.db.showCharges and e.charges~=nil)
    -- One-target buffs name who has them, like the group watcher.
    local who=e.who
    if who and who~="you" and self.db.watchLook.names then
        local member=self.members and self.members[who]
        self:PaintName(b.name,who,member and member.class,"bottom",MAIN)
    else b.name:Hide() end
    b:Show()
    return b
end

function M:PaintName(text,name,class,position,id)
    local w=self.db.watchLook
    SetFont(text,id,w.nameSize)
    local color=w.nameColor=="class" and self:ClassColor(class) or WHITE
    text:SetTextColor(color[1],color[2],color[3])
    text:SetText(name:sub(1,w.nameLetters))
    text:ClearAllPoints()
    local parent=text:GetParent()
    if position=="top" then text:SetPoint("TOP",parent,"TOP",0,-1)
    elseif position=="below" then text:SetPoint("TOP",parent,"BOTTOM",0,-2)
    else text:SetPoint("BOTTOM",parent,"BOTTOM",0,1) end
    text:Show()
end

function M:SetPulse(on)
    if not self.pulse then return end
    local current=self.pulse:GetScript("OnUpdate")
    if on and not current then self.pulse:SetScript("OnUpdate",self.pulseScript)
    elseif not on and current then self.pulse:SetScript("OnUpdate",nil) end
end

-- Group watcher -----------------------------------------------------------------

function M:GroupApplies()
    if not self.active or not self.db.watchGroup then return false end
    for _,b in ipairs(D.buffs) do if b.party and b.class==self.class and self.db.buffs[b.key] then return true end end
    return false
end

function M:RenderGroup()
    local g=self.groupFrame
    if not g then return end
    local placing=(self.editing or self.previewing) and self.active
    local rows
    if placing then rows=self:GroupApplies() and self:SampleGroup() or {}
    elseif self.active and self.db.show and self:PlaceAllowed() and not (self:InCombat() and (self.db.when=="neededOOC" or self.db.when=="alwaysOOC")) then rows=self:GroupEntries()
    else rows={} end
    self.groupSlots={}
    for _,t in ipairs(g.tiles) do t:Hide() end
    for _,h in ipairs(g.headers) do h:Hide() end
    for _,r in ipairs(g.rows) do r:Hide() end
    if #rows==0 then g:Hide();return end
    -- In combat every player keeps the tile place they had when it began (their
    -- click button can't move); players who join mid-fight wait for combat to end.
    local frozen=self.groupFrozen and self:InCombat() and not placing
    local positions=frozen and (self.groupPositions or {}) or {}
    if not frozen then self.groupPositions=positions end
    local function Place(region,key,x,y)
        region:ClearAllPoints()
        if frozen then
            local p=positions[key]
            if not p then region:Hide();return false end
            region:SetPoint("TOPLEFT",p[1],p[2])
        else positions[key]={x,y};region:SetPoint("TOPLEFT",x,y) end
        region:Show();return true
    end
    g.background:SetShown(addon.PositionManager:StyleBackground(GROUP))
    local w=self.db.watchLook
    local raid=Public(IsInRaid) and D.Truthy(IsInRaid) and not placing
    local size=raid and math.max(16,math.floor(w.iconSize*0.75+0.5)) or w.iconSize
    local gap=w.spacing
    local nameBelow=w.names and w.namePosition=="below" and StyleSize(GROUP,w.nameSize)+3 or 0
    local y,width,tileIndex,headerIndex,rowIndex=-6,0,0,0,0
    for _,row in ipairs(rows) do
        headerIndex=headerIndex+1
        local h=g.headers[headerIndex]
        if not h then h=Text(g,10,GROUP);h:SetJustifyH("LEFT");g.headers[headerIndex]=h end
        SetFont(h,GROUP,10)
        local T=addon.InterfaceTheme
        h:SetTextColor(T.primary[1],T.primary[2],T.primary[3])
        local label=row.buff.key=="blessing" and "Blessings" or row.buff.name
        h:SetText(string.upper((raid and "Raid" or "Party").." · "..label).."  "..row.ok.."/"..#row.members..(row.missing>0 and ("  ·  "..row.missing.." missing") or ""))
        h:ClearAllPoints();h:SetPoint("TOPLEFT",6,y);h:Show()
        local hw=h:GetStringWidth();if Number(hw,0,4000) then width=math.max(width,hw+12) end
        y=y-StyleSize(GROUP,10)-6
        if self.db.watchMode=="list" and not raid then
            for _,m in ipairs(row.members) do
                rowIndex=rowIndex+1
                local r=g.rows[rowIndex]
                if not r then
                    r=CreateFrame("Button",nil,g);r:RegisterForClicks("LeftButtonUp","RightButtonUp")
                    r.label=Text(r,11,GROUP);r.value=Text(r,11,GROUP)
                    r.label:SetPoint("LEFT",2,0);r.value:SetPoint("RIGHT",-2,0);r.value:SetJustifyH("RIGHT")
                    r:SetScript("OnEnter",function() self:ShowTooltip(r) end)
                    r:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
                    g.rows[rowIndex]=r
                end
                SetFont(r.label,GROUP,11);SetFont(r.value,GROUP,11)
                local c=self:ClassColor(m.class)
                r.label:SetText(m.name..(m.family and ("  ·  "..(D.ChoiceLabel("blessing",m.family) or "")) or ""));r.label:SetTextColor(c[1],c[2],c[3])
                r.value:SetText(self:MemberText(m));local vc=self:MemberColor(m);r.value:SetTextColor(vc[1],vc[2],vc[3])
                r.member,r.row=m,row
                r:SetSize(220,16)
                local placed=Place(r,row.buff.key..":"..m.name,6,y)
                width=math.max(width,232)
                y=y-18
                if placed then self.groupSlots[#self.groupSlots+1]={region=r,member=m,buff=row.buff} end
            end
        else
            -- Icons: grouped by class in raids, so a full raid stays one compact strip.
            local groups,order={},{}
            if raid then
                for _,m in ipairs(row.members) do
                    local c=m.class or "?"
                    if not groups[c] then groups[c]={};order[#order+1]=c end
                    groups[c][#groups[c]+1]=m
                end
            else groups.all=row.members;order={"all"} end
            local x,perRow,lineHeight=6,raid and 10 or 8,size+nameBelow+gap
            local col=0
            for gi,c in ipairs(order) do
                if gi>1 then x=x+gap+6;col=col+0.5 end
                for _,m in ipairs(groups[c]) do
                    if col>=perRow then col=0;x=6;y=y-lineHeight end
                    tileIndex=tileIndex+1
                    local t=g.tiles[tileIndex]
                    if not t then t=Icon(self,g,GROUP);g.tiles[tileIndex]=t end
                    self:PaintTile(t,m,row,size,raid)
                    local placed=Place(t,row.buff.key..":"..m.name,x,y)
                    x=x+size+gap;col=col+1
                    width=math.max(width,x+4)
                    if placed then self.groupSlots[#self.groupSlots+1]={region=t,member=m,buff=row.buff} end
                end
            end
            y=y-lineHeight-2
        end
    end
    if not frozen then g:SetSize(math.max(width,120),-y+4) end
    g:Show()
end

function M:MemberText(m)
    if m.status=="dead" then return "Dead" end
    if m.status=="missing" then return "Missing" end
    if m.status=="unknown" then return "?" end
    return m.left and ((m.estimated and "~" or "")..Clock(m.left)) or "Active"
end
function M:MemberColor(m)
    if m.status=="missing" then return {1,0.42,0.38} end
    if m.status=="expiring" then return self.db.look.colorExpiring end
    if m.status=="dead" or m.status=="unknown" then return {0.55,0.55,0.55} end
    return {0.85,0.83,0.77}
end

function M:PaintTile(t,m,row,size,raid)
    local w=self.db.watchLook
    t:SetSize(size,size)
    t.entry=nil;t.member=m
    local b=row.buff
    local chain=m.family and D.chains[m.family] or self:ChainFor(b)
    local spell=chain and (self:Best(chain) or chain[1])
    t.icon:SetTexture(spell and self:SpellIcon(spell) or FALLBACK_ICON)
    local gone=m.status=="missing" or m.status=="dead"
    t.icon:SetDesaturated(gone)
    local shade=m.status=="dead" and 0.35 or (gone and 0.7 or 1)
    t.icon:SetVertexColor(shade,shade,shade)
    t:SetAlpha(1);t.glowing=false
    local look=self.db.look
    if m.status=="missing" then EdgeColor(t,look.colorMissing,1,look.borderSize)
    elseif m.status=="expiring" then EdgeColor(t,look.colorExpiring,1,look.borderSize)
    elseif look.fineBorder then EdgeColor(t,look.colorFine,1,look.borderSize) else EdgeColor(t,nil) end
    SetFont(t.count,GROUP,math.max(8,math.floor(size*0.28)))
    local timer=w.timers and not raid and m.left and m.status~="missing" and m.status~="dead"
    t.count:SetText(timer and ((m.estimated and "~" or "")..Clock(m.left)) or (m.status=="dead" and "X" or ""))
    t.count:SetShown(timer or m.status=="dead")
    t.timer:Hide()
    if w.names then self:PaintName(t.name,m.name,m.class,w.namePosition,GROUP) else t.name:Hide() end
end

-- Tooltips ------------------------------------------------------------------------

function M:ShowTooltip(owner)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,"ANCHOR_TOP")
    if owner.member then
        local m=owner.member
        GameTooltip:SetText(m.name)
        GameTooltip:AddLine(self:MemberText(m),1,1,1)
        if self.db.click then GameTooltip:AddLine("Left-click to rebuff "..m.name..".",0.7,0.7,0.7) end
    elseif owner.entry then
        local e=owner.entry
        GameTooltip:SetText(e.combined or self:EntryName(e))
        local status=e.status=="missing" and "Missing" or e.status=="expiring" and ("Expires in "..self:TimerText(e)) or self:TimerText(e)
        GameTooltip:AddLine(status,1,1,1)
        if e.estimated and e.left then GameTooltip:AddLine("Counted from the last read before combat.",0.7,0.7,0.7) end
        if e.resource=="mana" then GameTooltip:AddLine("Not enough mana right now.",0.8,0.5,0.5)
        elseif e.resource=="none" then GameTooltip:AddLine("Nothing to apply it with.",0.8,0.5,0.5) end
        if self.db.click and not e.buff.noClick then GameTooltip:AddLine(e.late and "Click to reapply works once combat ends." or "Left-click to reapply.",0.7,0.7,0.7) end
        if self.db.dismiss then GameTooltip:AddLine("Right-click to dismiss until your next loading screen.",0.7,0.7,0.7) end
    end
    GameTooltip:Show()
end

-- Layout ------------------------------------------------------------------------------

-- Text size on the Style card rescales every custom-font text on the next draw.
function M:ApplyStyle()
    if not self.frame then return end
    for _,b in ipairs(self.frame.icons) do b.timer.customFont=nil;b.label.customFont=nil end
    for _,r in ipairs(self.frame.rows) do r.label.customFont=nil;r.value.customFont=nil end
    self.frame.label.customFont=nil;self.frame.sub.customFont=nil
    self:Update()
end

local function Look(self,key) return function() return self.db.look[key] end end
local function SetLook(self,key) return function(v) if addon.editMode then self:SetGroupOption("look",key,v) end end end
local function Watch(self,key) return function() return self.db.watchLook[key] end end
local function SetWatch(self,key) return function(v) if addon.editMode then self:SetGroupOption("watchLook",key,v) end end end

-- Extra rows this display adds to its Layout Style card. Only the first group
-- starts open; the rest fold so the card fits the screen.
function M:StyleGroups(id)
    if id==MAIN then
        local L=D.lookRanges
        local function Range(key,label) return {kind="slider",label=label,min=L[key][1],max=L[key][2],step=1,get=Look(self,key),set=SetLook(self,key)} end
        local function Color(key,label) return {kind="color",label=label,get=Look(self,key),set=SetLook(self,key)} end
        local function Fonts()
            local out={}
            for _,font in ipairs(addon.Media:GetFonts()) do out[#out+1]={id=font.media and ("media:"..font.media) or font.key,label=font.label} end
            return out
        end
        return {
            {title="Display",rows={
                {kind="select",label="Grow",choices={{id="right",label="Right"},{id="left",label="Left"},{id="center",label="Center"},{id="down",label="Down"},{id="up",label="Up"}},get=Look(self,"grow"),set=SetLook(self,"grow")},
                Range("spacing","Spacing"),
                {kind="select",label="Menus open",choices={{id="up",label="Up"},{id="down",label="Down"},{id="left",label="Left"},{id="right",label="Right"}},get=Look(self,"menuDirection"),set=SetLook(self,"menuDirection")},
                {kind="toggle",label="Glow",get=Look(self,"glow"),set=SetLook(self,"glow")},
                {kind="toggle",label="Sound",get=Look(self,"sound"),set=SetLook(self,"sound")},
            }},
            {title="Icons",rows={
                Range("iconWidth","Width"),Range("iconHeight","Height"),Range("borderSize","Border size"),
                Color("colorMissing","Missing"),Color("colorExpiring","Expiring"),
                {kind="toggle",label="Fine border",get=Look(self,"fineBorder"),set=SetLook(self,"fineBorder")},
                Color("colorFine","Fine colour"),
            }},
            {title="Timer text",rows={
                {kind="select",label="Font",choices=Fonts,get=Look(self,"timerFont"),set=SetLook(self,"timerFont")},
                Range("timerSize","Size"),
                {kind="select",label="Outline",choices={{id="none",label="None"},{id="outline",label="Outline"},{id="thick",label="Thick"}},get=Look(self,"timerOutline"),set=SetLook(self,"timerOutline")},
                {kind="select",label="Position",choices={{id="below",label="Below icon"},{id="above",label="Above icon"},{id="bottom",label="Inside, bottom"},{id="center",label="Inside, centre"},{id="top",label="Inside, top"},{id="hidden",label="Hidden"}},get=Look(self,"timer"),set=SetLook(self,"timer")},
                {kind="select",label="Colour",choices={{id="state",label="By state"},{id="white",label="White"}},get=Look(self,"timerColor"),set=SetLook(self,"timerColor")},
            }},
            {title="Hand labels",rows={
                {kind="toggle",label="Show",get=Look(self,"labels"),set=SetLook(self,"labels")},
                {kind="select",label="Text",choices={{id="short",label="MH / OH"},{id="long",label="Main Hand / Off Hand"}},get=Look(self,"labelStyle"),set=SetLook(self,"labelStyle")},
                Range("labelSize","Size"),
                {kind="select",label="Position",choices={{id="above",label="Above icon"},{id="top",label="Inside, top"},{id="under",label="Below the timer"}},get=Look(self,"labelPosition"),set=SetLook(self,"labelPosition")},
            }},
        }
    end
    return {{title="Group watcher",rows={
        {kind="slider",label="Icon size",min=D.watchRanges.iconSize[1],max=D.watchRanges.iconSize[2],step=1,get=Watch(self,"iconSize"),set=SetWatch(self,"iconSize")},
        {kind="slider",label="Spacing",min=D.watchRanges.spacing[1],max=D.watchRanges.spacing[2],step=1,get=Watch(self,"spacing"),set=SetWatch(self,"spacing")},
        {kind="toggle",label="Names",get=Watch(self,"names"),set=SetWatch(self,"names")},
        {kind="select",label="Name place",choices={{id="bottom",label="Bottom"},{id="top",label="Top"},{id="below",label="Below icon"}},get=Watch(self,"namePosition"),set=SetWatch(self,"namePosition")},
        {kind="select",label="Name colour",choices={{id="class",label="Class colour"},{id="white",label="White"}},get=Watch(self,"nameColor"),set=SetWatch(self,"nameColor")},
        {kind="slider",label="Name size",min=D.watchRanges.nameSize[1],max=D.watchRanges.nameSize[2],step=1,get=Watch(self,"nameSize"),set=SetWatch(self,"nameSize")},
        {kind="slider",label="Letters",min=D.watchRanges.nameLetters[1],max=D.watchRanges.nameLetters[2],step=1,get=Watch(self,"nameLetters"),set=SetWatch(self,"nameLetters")},
        {kind="toggle",label="Timers",get=Watch(self,"timers"),set=SetWatch(self,"timers")},
    }}}
end

-- Reset on the Style card also returns this display's own look to its defaults.
function M:ResetLook(id)
    if self:InCombat() then return end
    local key=id==MAIN and "look" or "watchLook"
    local defaults=id==MAIN and D.LOOK or D.WATCH_LOOK
    for k,v in pairs(defaults) do self.db[key][k]=type(v)=="table" and {v[1],v[2],v[3]} or v end
    self:ApplyStyle()
end

function M:RegisterPositions()
    if not self.frame or self:InCombat() then return end
    local PM=addon.PositionManager
    for _,spec in ipairs({{MAIN,self.frame,"Buff Reminders",0,-160,"x","y"},{GROUP,self.groupFrame,"Buff Reminders: Group",0,-230,"groupX","groupY"}}) do
        local id,frame=spec[1],spec[2]
        if not PM.elements[id] then
            local ok,element=PM:RegisterModuleDisplay(id,frame,self,{label=spec[3],defaultX=spec[4],defaultY=spec[5],xKey=spec[6],yKey=spec[7],
                canDrag=function() return self.active==true end,
                onStyleChanged=function() self:ApplyStyle() end,
                onPositionChanged=function() if self.LayoutSecure then self:LayoutSecure() end;if self.LayoutTabs then self:LayoutTabs() end end,
                onRegistered=function(registered) self:Decorate(registered) end})
            if ok then self:Decorate(element) end
        end
    end
    self:SyncEditElements()
end

function M:Decorate(element)
    if not element then return end
    element.styleGroups=self:StyleGroups(element.id)
    element.backgroundDefault=false
    element.onLayoutReset=function() self:ResetLook(element.id) end
    element.editMode=self.active==true and (element.id==MAIN or self:GroupApplies())
    self:Update()
    addon.PositionManager:RefreshSelection()
end

function M:SyncEditElements()
    local PM=addon.PositionManager
    for _,id in ipairs({MAIN,GROUP}) do
        local e=PM.elements[id]
        if e then
            e.editMode=self.active==true and (id==MAIN or self:GroupApplies())
            if not e.editMode then PM:StopDragging(id) end
        end
    end
end

function M:HideAll()
    if self.frame then self.frame:Hide() end
    if self.groupFrame then self.groupFrame:Hide() end
    self:SetPulse(false)
    self.slots,self.groupSlots={},{}
    if self.LayoutSecure then self:LayoutSecure() end
    local PM=addon.PositionManager
    for _,id in ipairs({MAIN,GROUP}) do
        local e=PM.elements[id]
        if e then e.editMode=false;PM:StopDragging(id) end
    end
end
