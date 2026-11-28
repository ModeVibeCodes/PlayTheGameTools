local _,addon=...
local M=addon.BuffReminders
if not M then return end
local D=addon.BuffRemindersData
local Public,Number=D.Public,D.Number

-- Click to reapply. Secure action buttons (SecureActionButtonTemplate) are a
-- separate layer on UIParent, laid over the visual reminders out of combat.
-- They are never parented or anchored to the displays, so the displays stay
-- unprotected and movable. In combat nothing here is shown, hidden, moved or
-- rebound: buttons placed before the fight keep working where they are, and
-- reminders that first appear mid-fight are visual only until combat ends.
-- Left-click casts; right-click only dismisses (PreClick, insecure display work).
-- Buffs for another player use one macro rule: your friendly target, else you.
local TARGET_OR_SELF="[@target,help,nodead][@player]"
local ATTRIBUTES={"type1","spell1","unit1","item1","macrotext1","target-slot1"}

function M:CreateSecure()
    if self.secureAvailable~=nil or self:InCombat() then return end
    local ok,probe=pcall(CreateFrame,"Button",nil,UIParent,"SecureActionButtonTemplate")
    if not ok or type(probe)~="table" or type(probe.SetAttribute)~="function" then
        self.secureAvailable=false
        if ok and type(probe)=="table" and probe.Hide then probe:Hide() end
        return
    end
    self.secureAvailable=true
    -- One container for every button. With a "When ... (OOC)" setting a secure
    -- state driver hides it in combat, so no invisible button stays clickable.
    self.secureLayer=CreateFrame("Frame",nil,UIParent)
    self.secureLayer:SetAllPoints(UIParent)
    self.securePool={main={},group={}}
    probe:SetParent(self.secureLayer)
    self:PrepareSecure(probe)
    self.securePool.main[1]=probe
end

function M:PrepareSecure(b)
    b:Hide()
    b:SetFrameStrata("MEDIUM")
    if b.SetFrameLevel then b:SetFrameLevel(20) end
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:SetAttribute("useOnKeyDown",false)
    b:SetScript("PreClick",function(btn,button)
        if button=="RightButton" and btn.dismissKey then self:Dismiss(btn.dismissKey) end
    end)
    -- No default to apply yet (nothing used, or none left): the click opens the menu.
    b:SetScript("PostClick",function(btn,button)
        if button=="LeftButton" and btn.openMenu and not self:InCombat() and self.OpenMenu then self:OpenMenu(btn.openMenu,btn.menuMessage) end
    end)
    -- No tooltip over a reminder dismissed mid-fight (its icon is hidden, the button can't be).
    b:SetScript("OnEnter",function(btn) if btn.region and btn.region:IsShown() then self:ShowTooltip(btn.region) end end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

function M:SecureButton(pool,index)
    local list=self.securePool[pool]
    if list[index] then return list[index] end
    if self:InCombat() then return end
    local ok,b=pcall(CreateFrame,"Button",nil,self.secureLayer or UIParent,"SecureActionButtonTemplate")
    if not ok or type(b)~="table" or type(b.SetAttribute)~="function" then return end
    self:PrepareSecure(b)
    list[index]=b
    return b
end

-- What a left-click does for a reminder; nil when it can't be applied by click.
function M:ActionFor(e)
    local b=e.buff
    if not b or b.noClick or e.sample then return end
    if e.totems then
        local names={}
        for _,t in ipairs(e.totems) do
            local kind=D.TotemType(t.buff.element,self.db.totems[t.buff.element])
            local spell=kind and self:Best(kind.spells)
            local name=spell and self:SpellName(spell)
            if name then names[#names+1]=name end
        end
        if #names==0 then return end
        return {type="macro",text="/castsequence reset=15 "..table.concat(names,", ")}
    end
    -- Items apply what you used last; with none, the click opens the menu instead.
    if b.kind=="food" then
        local food=self:LastFood(true)
        return food and {type="item",item="item:"..food} or nil
    end
    if b.kind=="weapon" then
        local slot=b.hand==1 and 16 or 17
        if b.poison or b.key=="weaponStone" then
            local item=self:BestItem(D.items[self:ItemFamily(b)])
            return item and {type="item",item="item:"..item,slot=slot} or nil
        end
        if b.key=="weaponOil" then
            local item=self:LastItem(b)
            return item and self:ItemCount(item)>0 and {type="item",item="item:"..item,slot=slot} or nil
        end
        local spell=self:Best(self:ChainFor(b))
        return spell and {type="spell",spell=spell} or nil
    end
    if b.kind=="totem" then
        local kind=D.TotemType(b.element,self.db.totems[b.element])
        local spell=kind and self:Best(kind.spells)
        return spell and {type="spell",spell=spell} or nil
    end
    if b.key=="soulstone" then
        local stone=self:BestItem(D.items.soulstone)
        if stone then return {type="macro",text="/use "..TARGET_OR_SELF.." item:"..stone} end
        local create=self:Best(D.chains.createSoulstone)
        return create and {type="spell",spell=create,unit="player"} or nil
    end
    if b.kind=="group" then
        local spell=self:Best(self:ChainFor(b))
        local name=spell and self:SpellName(spell)
        return name and {type="macro",text="/cast "..TARGET_OR_SELF.." "..name} or nil
    end
    local spell=self:Best(self:ChainFor(b))
    return spell and {type="spell",spell=spell,unit=b.kind=="pet" and nil or "player"} or nil
end

-- A group watcher icon casts that player's buff on them.
function M:MemberAction(member,buff)
    if not member or member.status=="dead" or not member.unit or member.sample then return end
    local chain=member.family and D.chains[member.family] or self:ChainFor(buff)
    local spell=self:Best(chain)
    return spell and {type="spell",spell=spell,unit=member.unit} or nil
end

local function Signature(action)
    if not action then return "none" end
    return table.concat({action.type or "",tostring(action.spell or ""),action.unit or "",action.item or "",action.text or "",tostring(action.slot or "")},"|")
end

function M:BindSecure(b,action)
    local signature=Signature(action)
    if b.signature==signature then return end
    for _,name in ipairs(ATTRIBUTES) do b:SetAttribute(name,nil) end
    if action then
        if action.type=="spell" then
            b:SetAttribute("spell1",action.spell)
            if action.unit then b:SetAttribute("unit1",action.unit) end
        elseif action.type=="item" then
            b:SetAttribute("item1",action.item)
            if action.slot then b:SetAttribute("target-slot1",action.slot) end
        elseif action.type=="macro" then
            b:SetAttribute("macrotext1",action.text)
        end
        b:SetAttribute("type1",action.type)
    end
    b.signature=signature
end

-- Screen rectangle of a region, in UIParent units.
function M:ScreenRect(region)
    if not region then return end
    local left,bottom,width,height=region:GetLeft(),region:GetBottom(),region:GetWidth(),region:GetHeight()
    local scale=region:GetEffectiveScale()
    local parent=UIParent:GetEffectiveScale()
    for _,v in ipairs({left,bottom,width,height,scale,parent}) do if not Number(v,-100000,100000) then return end end
    if parent<=0 then return end
    local ratio=scale/parent
    return left*ratio,bottom*ratio,width*ratio,height*ratio
end
local function Rect(region) return M:ScreenRect(region) end

function M:SecureActive()
    return self.secureAvailable and self.active and self.db.click and not self.editing and not self.previewing
end

-- Visual icons take the mouse (tooltip, right-click dismiss) only where no
-- click button covers them, and never while placing in Layout.
function M:SlotMouse()
    local placing=self.editing or self.previewing
    for _,list in ipairs({self.slots or {},self.groupSlots or {}}) do
        for _,slot in ipairs(list) do
            if slot.region and slot.region.EnableMouse then slot.region:EnableMouse(not slot.covered and not placing) end
        end
    end
end

-- Hidden in combat only when the display itself is (When Needed (OOC) / Always Outside Combat).
function M:SecureVisibility()
    local layer=self.secureLayer
    if not layer then return end
    local ooc=self.db.when=="neededOOC" or self.db.when=="alwaysOOC"
    if self.secureDriver==ooc then return end
    self.secureDriver=ooc
    if ooc and type(RegisterStateDriver)=="function" then pcall(RegisterStateDriver,layer,"visibility","[combat] hide; show")
    else
        if type(UnregisterStateDriver)=="function" then pcall(UnregisterStateDriver,layer,"visibility") end
        layer:Show()
    end
end

function M:LayoutSecure()
    if not self.secureAvailable then
        if not self:InCombat() then self:SlotMouse() end
        return
    end
    if self:InCombat() then self.securePending=true;return end
    self.securePending=false
    self:SecureVisibility()
    local on=self:SecureActive()
    local function Place(pool,slots,actionOf)
        local used=0
        if on then
            for _,slot in ipairs(slots or {}) do
                slot.covered=false
                local action=not slot.late and actionOf(slot)
                local region=slot.region
                -- A reminder with a menu keeps its button even with nothing to apply: the click opens the menu.
                local menu=not action and not slot.late and slot.entry and not slot.entry.sample and not slot.entry.totems
                    and self.HasMenu and self:HasMenu(slot.entry.buff)
                if (action or menu) and region and region:IsShown() then
                    local x,y,w,h=Rect(region)
                    if x then
                        used=used+1
                        local b=self:SecureButton(pool,used)
                        if not b then used=used-1;break end
                        self:BindSecure(b,action)
                        b:ClearAllPoints();b:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y);b:SetSize(w,h)
                        b.region,b.dismissKey=region,slot.keys
                        b.openMenu=menu and slot or nil
                        b.menuMessage=menu and self:MenuMessage(slot.entry) or nil
                        slot.covered=true
                        b:Show()
                    end
                end
            end
        end
        for i=used+1,#self.securePool[pool] do
            local b=self.securePool[pool][i]
            b:Hide();b.region,b.dismissKey,b.openMenu=nil,nil,nil
        end
    end
    Place("main",self.slots,function(slot) return self:ActionFor(slot.entry) end)
    Place("group",self.groupSlots,function(slot) return self:MemberAction(slot.member,slot.buff) end)
    self:SlotMouse()
end

-- Combat start: remember where every clickable reminder sits, so the display
-- keeps them there until combat ends.
function M:FreezeSecure()
    -- Only worth holding places when click buttons are actually laid over them.
    -- (With an out-of-combat-only When setting the whole layer hides instead.)
    local ooc=self.db.when=="neededOOC" or self.db.when=="alwaysOOC"
    if not self:SecureActive() or ooc then self.frozen,self.groupFrozen=nil,nil;return end
    local keys={}
    for _,slot in ipairs(self.slots or {}) do keys[#keys+1]=slot.keys end
    self.frozen=keys
    self.frozenBands=self.lastBands
    self.groupFrozen=true
end
function M:ThawSecure()
    self.frozen,self.groupFrozen,self.frozenBands=nil,nil,nil
    if self.securePending then self:LayoutSecure() end
end

-- Why a click opened the menu instead of applying something.
function M:MenuMessage(e)
    local b=e.buff
    local last
    if b.kind=="food" then last=self:LastFood(false)
    elseif b.key=="weaponOil" then last=self:LastItem(b) end
    if last then return "None left of "..self:ItemName(last)..". Pick another; it becomes the default." end
    if b.poison or b.key=="weaponStone" then
        local label=D.ChoiceLabel(b.choice,self:ItemFamily(b))
        return label and ("No "..label.." in your bags. Pick another; it becomes the default.") or nil
    end
    return "Nothing used yet. Pick one; it becomes the default for the next click."
end
