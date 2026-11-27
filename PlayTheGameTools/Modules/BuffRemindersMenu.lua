local _,addon=...
local M=addon.BuffReminders
if not M then return end
local D=addon.BuffRemindersData
local Public,Number,Call,Field=D.Public,D.Number,D.Call,D.Field

-- Choice menus. A reminder with a choice (poison per hand, food, imbue per
-- hand, oil, stone, blessing, aura, aspect, armor, demon, totem) applies what
-- you used last on a plain click. Its corner tab opens a menu of everything you
-- could apply; picking one applies it and makes it the new default.
-- Item picks are remembered per character (db.lastUsed[guid]); spell picks are
-- the saved choices. The menu holds secure buttons, so it opens out of combat
-- only and a Blizzard state driver closes it the moment combat starts.
local ROW,WIDTH,PAD=26,232,6
local ITEM_KEYS={poisonMain=true,poisonOff=true,food=true,weaponOil=true,weaponStone=true,imbueMain=true,imbueOff=true}

function M:HasMenu(b)
    if not b then return false end
    return b.kind=="totem" or ITEM_KEYS[b.key]==true or b.choice~=nil
end

-- Last used, per character --------------------------------------------------

-- Cached while readable: in some instances the client hides your GUID from addons.
function M:CharacterKey()
    local guid=Call(UnitGUID,"player")
    if Public(guid) and type(guid)=="string" and guid~="" and #guid<=100 then self.guid=guid end
    return self.guid
end
function M:LastUsedRow(create)
    local guid=self:CharacterKey()
    local all=self.db and self.db.lastUsed
    if not guid or type(all)~="table" then return end
    local row=all[guid]
    if not row and create then
        local n=0
        for _ in pairs(all) do n=n+1 end
        if n>=200 then return end
        row={};all[guid]=row
    end
    return row
end
function M:GetLastUsed(key) local row=self:LastUsedRow(false);return row and row[key] end
function M:SetLastUsed(key,value)
    if type(key)~="string" or #key>40 then return end
    if not ((type(value)=="string" and #value<=64) or (Number(value,1,2147483647) and value%1==0)) then return end
    local row=self:LastUsedRow(true)
    if row then row[key]=value end
end

-- Poison or stone family for a reminder: last used on this character, else the saved choice.
function M:ItemFamily(b)
    local v=self:GetLastUsed(b.key)
    if type(v)=="string" then
        for _,c in ipairs(D.choices[b.choice] or {}) do if c.id==v then return v end end
    end
    return self.db.choices[b.choice]
end
-- Last food eaten; carriedOnly limits it to food still in your bags.
function M:LastFood(carriedOnly)
    local v=self:GetLastUsed("food")
    if not Number(v,1,2147483647) then return end
    if carriedOnly and self:ItemCount(v)<=0 then return end
    return v
end
function M:LastItem(b)
    local v=self:GetLastUsed(b.key)
    if Number(v,1,2147483647) then return v end
end
function M:ItemName(id)
    local name=Call(C_Item and C_Item.GetItemNameByID,id)
    if Public(name) and type(name)=="string" and name~="" then return name end
    return "Item "..tostring(id)
end

-- Choices that also have a per-character "last used": the settings page shows
-- and sets the same value the icon's click uses.
local LINKED={poisonMain={"poisonMain"},poisonOff={"poisonOff"},stone={"weaponStone"},imbue={"imbueMain","imbueOff"}}
function M:ChoiceValue(name)
    local keys=LINKED[name]
    if keys then
        local v=self:GetLastUsed(keys[1])
        if type(v)=="string" and D.ChoiceLabel(name,v) then return v end
    end
    return self.db.choices[name]
end
function M:SetChoice(name,value)
    if not self:SetGroupOption("choices",name,value) then return false end
    for _,key in ipairs(LINKED[name] or {}) do self:SetLastUsed(key,value) end
    self:Update()
    return true
end

-- Menu choices -----------------------------------------------------------------

function M:MenuTitle(b)
    if b.kind=="totem" then
        for _,element in ipairs(D.ELEMENTS) do if element.id==b.element then return element.label.." totem" end end
    end
    if b.kind=="food" then return "Food" end
    return b.name
end

-- {id, label, icon, count, last, group, action}; action is nil when it can't be applied now.
function M:MenuOptions(b)
    local out={}
    local slot=b.hand==2 and 17 or 16
    if b.poison or b.key=="weaponStone" then
        local current=self:ItemFamily(b)
        for _,c in ipairs(D.choices[b.choice] or {}) do
            local list=D.items[c.id] or {}
            local best,count=self:BestItem(list),0
            for _,id in ipairs(list) do count=count+self:ItemCount(id) end
            out[#out+1]={id=c.id,label=c.label,icon=self:ItemIcon(best or list[1]),count=count,last=c.id==current,
                action=best and {type="item",item="item:"..best,slot=slot} or nil}
        end
    elseif b.key=="weaponOil" then
        local current=self:LastItem(b)
        for _,id in ipairs(D.items.weaponOil) do
            local n=self:ItemCount(id)
            if n>0 then out[#out+1]={id=id,label=self:ItemName(id),icon=self:ItemIcon(id),count=n,last=id==current,action={type="item",item="item:"..id,slot=slot}} end
        end
    elseif b.kind=="food" then
        local current=self:LastFood(false)
        for _,f in ipairs(self.bagFoods or {}) do
            out[#out+1]={id=f.id,label=f.name,icon=f.icon,count=f.count,last=f.id==current,
                group=f.buff==true and "Well Fed foods" or f.buff==false and "Other food" or nil,action={type="item",item="item:"..f.id}}
        end
    elseif b.kind=="totem" then
        local current=self.db.totems[b.element]
        for _,t in ipairs(D.totems[b.element] or {}) do
            local spell=self:Best(t.spells)
            if spell then out[#out+1]={id=t.id,label=t.label,icon=self:SpellIcon(spell),last=t.id==current,action={type="spell",spell=spell}} end
        end
    elseif b.choice then
        local perHand=b.key=="imbueMain" or b.key=="imbueOff"
        local current=perHand and (self:GetLastUsed(b.key) or self.db.choices.imbue) or self.db.choices[b.choice]
        if b.choice=="armor" and current=="auto" then
            local chain=self:ChainFor(b)
            for id,c in pairs(D.chains) do if c==chain then current=id end end
        end
        for _,c in ipairs(D.choices[b.choice]) do
            if c.id~="auto" then
                local spell=self:Best(D.chains[c.cast or c.id])
                if spell then
                    out[#out+1]={id=c.id,label=c.label,icon=self:SpellIcon(spell),last=c.id==current,
                        action={type="spell",spell=spell,unit=b.kind~="pet" and "player" or nil}}
                end
            end
        end
    end
    return out
end

-- A menu pick becomes the default click for that reminder.
function M:PickOption(b,opt)
    if not b or not opt then return end
    if b.poison or b.key=="weaponStone" or b.key=="weaponOil" or b.kind=="food" or b.key=="imbueMain" or b.key=="imbueOff" then
        self:SetLastUsed(b.key,opt.id)
        if addon.RefreshConfig then addon:RefreshConfig() end
    elseif b.kind=="totem" then
        self:SetGroupOption("totems",b.element,opt.id)
    elseif b.choice then
        self:SetGroupOption("choices",b.choice,opt.id)
    end
end

-- The menu ------------------------------------------------------------------------

local function Text(parent,size,justify)
    local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    addon.Media:BindInterfaceFont(t,GameFontHighlight,size,M.MAIN_ID)
    t:SetJustifyH(justify or "LEFT");t:SetWordWrap(false)
    t:SetShadowColor(0,0,0,1);t:SetShadowOffset(1,-1)
    return t
end

function M:CreateMenu()
    if self.menu then return self.menu end
    if self:InCombat() or not self.secureAvailable then return end
    local ok,menu=pcall(CreateFrame,"Frame","PlayTheGameToolsBuffRemindersMenu",UIParent,"SecureHandlerStateTemplate")
    if not ok or type(menu)~="table" then return end
    local T=addon.InterfaceTheme
    menu:Hide();menu:SetFrameStrata("DIALOG");menu:SetClampedToScreen(true);menu:EnableMouse(true)
    menu:SetSize(WIDTH,ROW+PAD*2)
    menu.bg=menu:CreateTexture(nil,"BACKGROUND");menu.bg:SetAllPoints()
    addon.Media:PaintSurface(menu.bg,T.panel,0.96,M.MAIN_ID)
    menu.edges={}
    for i=1,4 do menu.edges[i]=menu:CreateTexture(nil,"BORDER") end
    M.EdgeColor(menu,T.lineStrong,1,1)
    menu.message=Text(menu,11);menu.message:SetWordWrap(true);menu.message:SetWidth(WIDTH-PAD*2)
    menu.headers,menu.rows={},{}
    -- Combat closes it securely: Blizzard's state driver runs this restricted snippet.
    if type(menu.SetAttribute)=="function" and type(RegisterStateDriver)=="function" then
        -- The driver resolves "1" to the number 1 (SecureStateDriver resolveDriver).
        menu:SetAttribute("_onstate-combat",[[ if newstate == 1 or newstate == "1" then self:Hide() end ]])
        pcall(RegisterStateDriver,menu,"combat","[combat] 1; 0")
    end
    menu:SetScript("OnHide",function() self.menuKey=nil;self:RefreshTabs() end)
    -- Escape closes it like the addon's other menus.
    if addon.Dialogs and addon.Dialogs.Register then pcall(addon.Dialogs.Register,addon.Dialogs,menu,{kind="layer",close=function(frame) if not self:InCombat() then frame:Hide() end end}) end
    self.menu=menu
    return menu
end

function M:MenuRow(index)
    local menu=self.menu
    if menu.rows[index] then return menu.rows[index] end
    if self:InCombat() then return end
    local ok,b=pcall(CreateFrame,"Button",nil,menu,"SecureActionButtonTemplate")
    if not ok or type(b)~="table" or type(b.SetAttribute)~="function" then return end
    b:RegisterForClicks("LeftButtonUp")
    b:SetAttribute("useOnKeyDown",false)
    b:SetSize(WIDTH-PAD*2,ROW)
    b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(ROW-4,ROW-4);b.icon:SetPoint("LEFT",2,0);b.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    b.name=Text(b,11);b.name:SetPoint("LEFT",ROW+4,0);b.name:SetWidth(WIDTH-PAD*2-ROW-48)
    b.count=Text(b,10,"RIGHT");b.count:SetPoint("RIGHT",-4,0)
    b.highlight=b:CreateTexture(nil,"HIGHLIGHT");b.highlight:SetAllPoints();b.highlight:SetColorTexture(0.9,0.74,0.26,0.15)
    -- Insecure bookkeeping around the secure click: remember the pick, then close.
    b:SetScript("PreClick",function(btn) if btn.option and btn.buff then self:PickOption(btn.buff,btn.option) end end)
    b:SetScript("PostClick",function() if not self:InCombat() then self:CloseMenu() end;self:Update() end)
    menu.rows[index]=b
    return b
end

function M:MenuHeader(index)
    local menu=self.menu
    local h=menu.headers[index]
    if not h then h=Text(menu,10);menu.headers[index]=h end
    local c=self.db.look.colorExpiring
    h:SetTextColor(c[1],c[2],c[3])
    return h
end

-- Opens from the display's outer edge in the chosen direction, flipping when
-- there's no room, so it never covers a reminder.
function M:PlaceMenu(menu,region)
    local fx,fy,fw,fh=self:ScreenRect(self.frame)
    local ix,iy,iw,ih=self:ScreenRect(region)
    if not fx or not ix then return false end
    local W,H=UIParent:GetWidth(),UIParent:GetHeight()
    local mw,mh=menu:GetWidth(),menu:GetHeight()
    local dir=self.db.look.menuDirection
    if dir=="up" and fy+fh+8+mh>H then dir="down"
    elseif dir=="down" and fy-8-mh<0 then dir="up"
    elseif dir=="left" and fx-8-mw<0 then dir="right"
    elseif dir=="right" and fx+fw+8+mw>W then dir="left" end
    local x,y
    if dir=="up" then x,y=ix+iw/2-mw/2,fy+fh+8
    elseif dir=="down" then x,y=ix+iw/2-mw/2,fy-8-mh
    elseif dir=="left" then x,y=fx-8-mw,iy+ih-mh
    else x,y=fx+fw+8,iy+ih-mh end
    if dir=="up" or dir=="down" then x=math.max(0,math.min(W-mw,x)) else y=math.max(0,math.min(H-mh,y)) end
    menu:ClearAllPoints()
    menu:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y)
    self.menuPlacement={x=x,y=y,direction=dir}
    return true
end

function M:OpenMenu(slot,message)
    if self:InCombat() or not slot or not slot.entry or not self:HasMenu(slot.entry.buff) then return false end
    local menu=self:CreateMenu()
    if not menu then return false end
    local b=slot.entry.buff
    local options=self:MenuOptions(b)
    for _,h in ipairs(menu.headers) do h:Hide() end
    for _,r in ipairs(menu.rows) do r:Hide();r.option,r.buff=nil,nil end
    local y=-PAD
    if #options==0 then message=message or (b.kind=="food" and "No food in your bags." or "Nothing to apply right now.") end
    if message then
        menu.message:ClearAllPoints();menu.message:SetPoint("TOPLEFT",PAD,y);menu.message:SetText(message);menu.message:Show()
        local h=menu.message:GetStringHeight();y=y-((Number(h,1,200) and h) or 14)-6
    else menu.message:Hide() end
    -- Groups in order; food lists Well Fed foods first when the tooltip tells them apart.
    -- At most 16 rows; the last used always stays in the list.
    if #options>16 then
        local kept,lastKept={},false
        for _,opt in ipairs(options) do
            if #kept<15 or (opt.last and not lastKept) then kept[#kept+1]=opt;lastKept=lastKept or opt.last end
        end
        options=kept
    end
    local groups,order={},{}
    for _,opt in ipairs(options) do
        local g=opt.group or self:MenuTitle(b)
        if not groups[g] then groups[g]={};order[#order+1]=g end
        groups[g][#groups[g]+1]=opt
    end
    table.sort(order,function(a,c)
        local rank={["Well Fed foods"]=1,["Other food"]=3}
        return (rank[a] or 2)<(rank[c] or 2)
    end)
    local rowIndex=0
    for gi,g in ipairs(order) do
        local h=self:MenuHeader(gi)
        h:ClearAllPoints();h:SetPoint("TOPLEFT",PAD+2,y-2);h:SetText(string.upper(g));h:Show()
        y=y-16
        for _,opt in ipairs(groups[g]) do
            local r=self:MenuRow(rowIndex+1)
            if not r then break end
            rowIndex=rowIndex+1
            r.option,r.buff=opt,b
            self:BindSecure(r,opt.action)
            r.icon:SetTexture(opt.icon or 134400)
            r.icon:SetDesaturated(opt.action==nil)
            r.name:SetText(opt.label..(opt.last and "  |cff6bcc6blast used|r" or ""))
            r.count:SetText(opt.count and ("x"..opt.count) or "")
            r:SetAlpha(opt.action and 1 or 0.45)
            r:EnableMouse(opt.action~=nil)
            r:ClearAllPoints();r:SetPoint("TOPLEFT",PAD,y);r:Show()
            y=y-ROW-2
        end
    end
    menu:SetSize(WIDTH,-y+PAD-2)
    if not self:PlaceMenu(menu,slot.region) then return false end
    self.menuKey=slot.entry.key
    menu:Show()
    self:RefreshTabs()
    return true
end

function M:CloseMenu()
    if self.menu and self.menu:IsShown() and not self:InCombat() then self.menu:Hide() end
end
function M:ToggleMenu(slot)
    if self.menu and self.menu:IsShown() and slot and slot.entry and self.menuKey==slot.entry.key then self:CloseMenu();return end
    self:OpenMenu(slot)
end

-- Corner tabs ------------------------------------------------------------------------

local MARK=9
function M:TabButton(index)
    self.tabs=self.tabs or {}
    if self.tabs[index] then return self.tabs[index] end
    local t=CreateFrame("Button",nil,UIParent)
    t:SetFrameStrata("MEDIUM");t:SetFrameLevel(40);t:SetSize(16,16);t:RegisterForClicks("LeftButtonUp")
    t.mark=t:CreateTexture(nil,"OVERLAY");t.mark:SetPoint("BOTTOMRIGHT",0,0);t.mark:SetSize(MARK,MARK)
    -- A small gold fold in the corner: a square whose top-left corner is pulled
    -- down to the bottom-left, where the client supports vertex offsets.
    if type(t.mark.SetVertexOffset)=="function" then pcall(t.mark.SetVertexOffset,t.mark,1,0,-MARK) end
    t:SetScript("OnEnter",function()
        t.hover=true;self:RefreshTabs()
        if GameTooltip and t.slot then
            GameTooltip:SetOwner(t,"ANCHOR_TOP");GameTooltip:SetText("Choose "..self:MenuTitle(t.slot.entry.buff):lower());GameTooltip:Show()
        end
    end)
    t:SetScript("OnLeave",function() t.hover=false;self:RefreshTabs();if GameTooltip then GameTooltip:Hide() end end)
    t:SetScript("OnClick",function() if t.slot and not self:InCombat() then self:ToggleMenu(t.slot) end end)
    self.tabs[index]=t
    return t
end

function M:RefreshTabs()
    for _,t in ipairs(self.tabs or {}) do
        local open=t.slot and t.slot.entry and self.menuKey==t.slot.entry.key and self.menu and self.menu:IsShown()
        local c=self.db.look.colorExpiring
        local lit=(open or t.hover) and true or false
        local key=tostring(lit)..c[1]..","..c[2]..","..c[3]
        if t.drawn~=key then
            t.drawn=key
            t.mark:SetColorTexture(c[1],c[2],c[3],lit and 1 or 0.7)
            local size=lit and MARK+2 or MARK
            t.mark:SetSize(size,size)
            if type(t.mark.SetVertexOffset)=="function" then pcall(t.mark.SetVertexOffset,t.mark,1,0,-size) end
        end
    end
end

-- One tab per clickable icon with a choice, at its bottom-right corner. Out of
-- combat only; tabs are plain buttons, so they hide freely when combat starts.
function M:LayoutTabs()
    local tabs=self.tabs or {}
    local used=0
    local alive=not self:InCombat() and self.secureAvailable and self.active and self.db.click and not self.editing and not self.previewing
    -- Text mode has no tabs, but a click there can still open a menu.
    local on=alive and self.db.mode~="text"
    if on then
        for _,slot in ipairs(self.slots or {}) do
            local e=slot.entry
            if e and not e.sample and not e.late and not e.totems and self:HasMenu(e.buff) and slot.covered and slot.region and slot.region:IsShown() then
                local x,y,w=self:ScreenRect(slot.region)
                if x then
                    used=used+1
                    local t=self:TabButton(used)
                    t.slot=slot
                    t:ClearAllPoints();t:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMLEFT",x+w,y);t:Show()
                end
            end
        end
    end
    for i=used+1,#tabs do tabs[i]:Hide();tabs[i].slot=nil end
    self:RefreshTabs()
    if self.menu and self.menu:IsShown() and not self:InCombat() then
        local open=false
        for _,slot in ipairs(self.slots or {}) do if slot.entry and slot.entry.key==self.menuKey then open=true end end
        if not open or not alive then self:CloseMenu() end
    end
end
