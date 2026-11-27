local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local D=addon.BuffRemindersData

-- Buff Reminders: warns when your class buffs, poisons, imbues, totems, group
-- buffs or food are missing or about to run out.
-- Forever hides aura data from addons in combat (SecretWhenUnitAuraRestricted),
-- so buffs are read out of combat and their stored end times keep counting
-- down through combat. Deaths, your own casts, totem slots, weapon enchants and
-- resources stay readable in combat and keep the estimate honest. The display
-- is a plain frame; click-to-reapply lives in BuffRemindersSecure.lua.
local M={title="Buff Reminders",category="qualityOfLife",defaultEnabled=false,Data=D,Initialize=D.Initialize,
    configDescription="Warns when your class buffs, poisons, imbues, totems, group buffs or food are missing or about to run out.",
    searchAliases={"buff reminder","buffs","blessings","totems","poisons","imbues","soulstone","food buff","well fed","reminders"}}
addon.BuffReminders=M
addon:RegisterModule("buffReminders",M)
-- Rogue Tools (foreverRogue) was retired into Buff Reminders. Its saved table
-- stays in profiles, unread after the one-time adoption, and old exports import.
addon.retiredModules=addon.retiredModules or {}
addon.retiredModules.foreverRogue="buffReminders"

M.TICK=0.5
local Public,Number,Call,Field,Truthy=D.Public,D.Number,D.Call,D.Field,D.Truthy

local detectSets={}
for _,b in ipairs(D.buffs) do
    if b.detect then local set={};for _,id in ipairs(b.detect) do set[id]=true end;detectSets[b.key]=set end
end
M.detectSets=detectSets

function M:Now() local t=Call(GetTime);return Number(t,0) and t or 0 end
function M:InCombat() return D.InCombat() end

-- Settings ----------------------------------------------------------------

function M:CanConfigure() return not self:InCombat() end
local function Valid(self,mutate)
    local copy=addon.ProfileCodec.Copy(self.db)
    mutate(copy)
    if not pcall(self.Initialize,copy) then return false end
    mutate(self.db)
    return true
end
function M:SetOption(key,value)
    if not self:CanConfigure() or key=="buffs" or key=="totems" or key=="choices" or key=="where" or key=="look" or key=="watchLook" then return false end
    if self.db[key]==nil or value==nil then return false end
    if not Valid(self,function(db) db[key]=value end) then return false end
    self:Changed();return true
end
function M:SetGroupOption(group,key,value)
    local valid={buffs=true,totems=true,choices=true,where=true,look=true,watchLook=true}
    if not self:CanConfigure() or not valid[group] or type(self.db[group])~="table" or self.db[group][key]==nil or value==nil then return false end
    -- Colours are copied, so a caller's table never becomes the saved one.
    if type(value)=="table" then value={value[1],value[2],value[3]} end
    if not Valid(self,function(db) db[group][key]=value end) then return false end
    -- Look changes come from Layout sliders: redraw only, no new read.
    if group=="look" or group=="watchLook" then self:Update();if addon.RefreshConfig then addon:RefreshConfig() end;return true end
    self:Changed();return true
end
function M:SetBuff(key,value) return self:SetGroupOption("buffs",key,value) end
function M:Changed()
    self:RefreshKnowledge()
    self:Update(true)
    if self.ApplyStyle then self:ApplyStyle() end
    if self.SyncEditElements then self:SyncEditElements() end
    if addon.RefreshConfig then addon:RefreshConfig() end
end

-- Class, spells and resources ---------------------------------------------

function M:PlayerClass()
    local _,class=Call(UnitClass,"player")
    return Public(class) and type(class)=="string" and class or nil
end
function M:Known(id)
    if not Number(id,1,2147483647) then return false end
    local book=C_SpellBook
    if book and (Truthy(book.IsSpellKnownOrInSpellBook,id) or Truthy(book.IsSpellKnown,id)) then return true end
    return Truthy(IsPlayerSpell,id) or Truthy(IsSpellKnown,id)
end
-- Highest known rank of a chain, or nil.
-- Cached until spells change (SPELLS_CHANGED, settings), since it runs every tick.
function M:Best(chain)
    if type(chain)~="table" then return end
    self.bestCache=self.bestCache or {}
    local cached=self.bestCache[chain]
    if cached~=nil then return cached or nil end
    local best=false
    for i=#chain,1,-1 do if self:Known(chain[i]) then best=chain[i];break end end
    self.bestCache[chain]=best
    return best or nil
end
function M:SpellName(id)
    local name=Call(C_Spell and C_Spell.GetSpellName,id)
    if Public(name) and type(name)=="string" and name~="" then return name end
    local info=Call(C_Spell and C_Spell.GetSpellInfo,id)
    name=Field(info,"name")
    if Public(name) and type(name)=="string" and name~="" then return name end
end
function M:SpellIcon(id)
    local icon=Call(C_Spell and C_Spell.GetSpellTexture,id)
    if Public(icon) and (type(icon)=="number" or type(icon)=="string") then return icon end
    local info=Call(C_Spell and C_Spell.GetSpellInfo,id)
    icon=Field(info,"iconID")
    if Number(icon,1) then return icon end
end
function M:ItemCount(id)
    local cache=self.countCache
    if cache and cache[id] then return cache[id] end
    local n=self:ReadItemCount(id)
    if cache then cache[id]=n end
    return n
end
function M:ReadItemCount(id)
    local n=Call(C_Item and C_Item.GetItemCount,id)
    if not Number(n,0) then n=Call(GetItemCount,id) end
    return Number(n,0) and n or 0
end
function M:ItemIcon(id)
    local icon=Call(C_Item and C_Item.GetItemIconByID,id)
    if Number(icon,1) then return icon end
    local _,_,_,_,texture=Call(C_Item and C_Item.GetItemInfoInstant,id)
    if Public(texture) and (type(texture)=="number" or type(texture)=="string") then return texture end
end
function M:BestItem(list)
    for _,id in ipairs(list or {}) do if self:ItemCount(id)>0 then return id end end
end
-- Chain to cast for a buff: its own chain, or the chain of its saved choice.
function M:ChainFor(b)
    local db=self.db
    if b.choice then
        local pick=db.choices[b.choice]
        -- Imbues are chosen per hand (last used on this character).
        if (b.key=="imbueMain" or b.key=="imbueOff") and self.GetLastUsed then
            local hand=self:GetLastUsed(b.key)
            if type(hand)=="string" and D.chains[hand] and D.ChoiceLabel("imbue",hand) then pick=hand end
        end
        if b.choice=="blessing" then
            for _,c in ipairs(D.choices.blessing) do if c.id==pick then return D.chains[c.cast] end end
        elseif b.choice=="armor" and pick=="auto" then
            return self:Best(D.chains.iceArmor) and D.chains.iceArmor or self:Best(D.chains.mageArmor) and D.chains.mageArmor or D.chains.frostArmor
        end
        return D.chains[pick]
    end
    if b.cast then
        local chain=D.chains[b.cast]
        if b.fallback and not self:Best(chain) then return D.chains[b.fallback] end
        return chain
    end
end
-- Whether the player can have this buff at all (class, learned spell, choice).
function M:Applicable(b)
    if b.class~="ALL" and b.class~=self.class then return false end
    if b.kind=="totem" then
        local t=D.TotemType(b.element,self.db.totems[b.element])
        return t~=nil and self:Best(t.spells)~=nil
    end
    if not self.db.buffs[b.key] then return false end
    if b.kind=="food" or b.key=="elixir" or b.key=="weaponOil" then return true end
    if b.poison or b.key=="weaponStone" then return true end
    if b.key=="soulstone" then return self:Best(D.chains.createSoulstone)~=nil or self:BestItem(D.items.soulstone)~=nil end
    if b.kind=="active" then
        for _,id in ipairs(b.detect) do if self:Known(id) then return true end end
        return false
    end
    if b.kind=="pet" and b.key=="demonPet" then
        for _,c in ipairs(D.choices.demon) do if self:Best(D.chains[c.id]) then return true end end
        return false
    end
    return self:Best(self:ChainFor(b))~=nil
end

-- What applying a buff costs, and whether you can pay now.
--   "ok", "mana" (temporary: always dims) or "none" (no item or reagent)
function M:Resource(b)
    -- Item reminders can apply as long as anything in their menu is in your bags.
    if b.kind=="food" then return (self.bagFoods and #self.bagFoods>0) and "ok" or "none" end
    if b.kind=="weapon" then
        if b.key=="weaponOil" then return self:BestItem(D.items.weaponOil) and "ok" or "none" end
        if b.poison or b.key=="weaponStone" then
            for _,c in ipairs(D.choices[b.choice] or {}) do if self:BestItem(D.items[c.id]) then return "ok" end end
            return "none"
        end
    end
    if b.key=="soulstone" then
        if self:BestItem(D.items.soulstone) then return "ok" end
        if self:ItemCount(D.items.soulShard[1])>0 and self:Best(D.chains.createSoulstone) then return "ok" end
        return "none"
    end
    local spell
    if b.kind=="totem" then
        local t=D.TotemType(b.element,self.db.totems[b.element]);spell=t and self:Best(t.spells)
    else spell=self:Best(self:ChainFor(b)) end
    if not spell then return "ok" end
    local usable,noPower=Call(C_Spell and C_Spell.IsSpellUsable,spell)
    if not Public(usable) or usable==nil or usable==true then return "ok" end
    if Public(noPower) and noPower==true then return "mana" end
    return b.resource=="reagent" and "none" or "mana"
end

-- Reading -------------------------------------------------------------------

-- Every helpful aura on a unit, or nil when the list can't be read completely
-- (restricted, secret or erroring). A complete read is the only proof a buff is gone.
function M:ReadAuras(unit)
    if C_Secrets and Truthy(C_Secrets.ShouldAurasBeSecret) then return nil end
    local get=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(get)~="function" then return nil end
    local list={}
    for i=1,255 do
        local ok,a=pcall(get,unit,i,"HELPFUL")
        if not ok then return nil end
        if a==nil then break end
        if not Public(a) or type(a)~="table" then return nil end
        -- Plain AuraData table (checked not secret above): read fields directly; each
        -- value is still checked, since single fields can be secret.
        local id=a.spellId
        if not Number(id,1,2147483647) then return nil end
        local expires,duration,count=a.expirationTime,a.duration,a.applications
        local name,source=a.name,a.sourceUnit
        list[#list+1]={id=id,expires=Number(expires,0.001) and expires or nil,duration=Number(duration,0.001) and duration or nil,
            count=Number(count,0,10000) and count or nil,name=Public(name) and type(name)=="string" and name or nil,
            source=Public(source) and type(source)=="string" and source or nil}
    end
    return list
end
local function Mine(rec) return rec.source==nil or rec.source=="player" or rec.source=="pet" end

function M:FoodNames()
    if self.foodNames then return self.foodNames end
    local names={}
    for _,id in ipairs(D.foodAuras) do local n=self:SpellName(id);if n then names[n]=true end end
    self.foodNames=names
    return names
end
function M:MatchAura(b,list)
    local set=detectSets[b.key];local best
    local names=b.kind=="food" and self:FoodNames() or nil
    for _,rec in ipairs(list) do
        if (set and set[rec.id]) or (names and rec.name and names[rec.name]) then
            if not b.mine or Mine(rec) then
                if not best or (rec.expires or math.huge)>(best.expires or math.huge) then best=rec end
            end
        end
    end
    return best
end

-- Weapon enchants are readable in combat. Per hand and enchant type:
-- {empty} no melee weapon, {unknown}, {missing}, or {expires, charges, icon}.
function M:ReadWeapon(hand,kind)
    local slot=hand==1 and 16 or 17
    local ok,item=pcall(GetInventoryItemID or function() error("unavailable") end,"player",slot)
    if not ok or not Public(item) then return {unknown=true} end
    if item==nil then return {empty=true} end
    if not Number(item,1,2147483647) then return {unknown=true} end
    local _,_,_,equip,_,class=Call(C_Item and C_Item.GetItemInfoInstant,item)
    if not Public(class) or not Public(equip) then return {unknown=true} end
    if class~=2 or equip=="INVTYPE_RANGED" or equip=="INVTYPE_RANGEDRIGHT" or equip=="INVTYPE_THROWN" then return {empty=true} end
    local slots,types=Enum and Enum.WeaponSlot,Enum and Enum.ItemEnchantType
    local weapon=slots and (hand==1 and slots.MainHand or slots.OffHand)
    local wanted=types and types[kind]
    if not Number(weapon,0,2) or not Number(wanted,0,10) then return {unknown=true,weapon=item} end
    local enchants=Call(C_Item and C_Item.GetWeaponEnchantInfo,weapon)
    if not Public(enchants) or type(enchants)~="table" then return {unknown=true,weapon=item} end
    self.chargeSeen=self.chargeSeen or {}
    for i=1,16 do
        local e=Field(enchants,i)
        if e==nil then break end
        if not Public(e) or type(e)~="table" then return {unknown=true,weapon=item} end
        if Field(e,"enchantType")==wanted then
            local active=Field(e,"hasEnchant")
            if not Public(active) or active==nil then return {unknown=true,weapon=item} end
            if active then
                local left,icon,id,charges=Field(e,"timeLeft"),Field(e,"enchantIconID"),Field(e,"enchantID"),Field(e,"charges")
                if not Number(left,0) then return {unknown=true,weapon=item} end
                local seenKey=hand..":"..kind
                local seen=self.chargeSeen[seenKey]
                if seen and (seen.weapon~=item or seen.enchant~=id) then self.chargeSeen[seenKey]=nil;seen=nil end
                local count
                if Number(charges,1,2147483647) then count=charges;self.chargeSeen[seenKey]={weapon=item,enchant=id}
                elseif Number(charges,0,0) and seen then count=0 end
                return {expires=self:Now()+left/1000,charges=count,icon=Number(icon,1) and icon or nil,weapon=item}
            end
        end
    end
    return {missing=true,weapon=item}
end

-- Totem slots: readable unless the client marks the slot secret.
function M:ReadTotem(b)
    local t=D.TotemType(b.element,self.db.totems[b.element])
    if not t then return {missing=true} end
    if C_Secrets and Truthy(C_Secrets.ShouldTotemSlotBeSecret,b.slot) then return {unknown=true} end
    local have,name,start,duration,icon,_,spell=Call(GetTotemInfo,b.slot)
    if not Public(have) or not Public(name) or not Public(start) or not Public(duration) then return {unknown=true} end
    if have~=true then return {missing=true} end
    local match=false
    if Public(spell) and Number(spell,1) then for _,id in ipairs(t.spells) do match=match or id==spell end end
    if not match and type(name)=="string" then
        local base=self:SpellName(t.spells[1])
        match=base~=nil and (name==base or name:find(base,1,true)==1)
    end
    if not match then return {missing=true} end
    local expires=Number(start,0.001) and Number(duration,0.001) and start+duration or nil
    return {expires=expires,icon=Public(icon) and icon or nil}
end

-- Foods in your bags (consumable food with a Food item spell) for the food menu,
-- plus counts of every tracked item so the addon can tell what you just used.
-- Bags are read out of combat only.
function M:FoodSpellNames()
    if self.foodSpellNames then return self.foodSpellNames end
    local names={}
    for _,id in ipairs(D.foodSpells) do local n=self:SpellName(id);if n then names[n]=true end end
    self.foodSpellNames=names
    return names
end

-- Whether a food gives Well Fed, from its tooltip; nil when the tooltip can't be read.
function M:FoodGivesBuff(id)
    self.foodBuffCache=self.foodBuffCache or {}
    if self.foodBuffCache[id]~=nil then return self.foodBuffCache[id] end
    -- Not loaded yet ("Retrieving item information"): ask again on the next scan.
    local cached=Call(C_Item and C_Item.IsItemDataCachedByID,id)
    if Public(cached) and cached==false then return nil end
    local data=Call(C_TooltipInfo and C_TooltipInfo.GetItemByID,id)
    local lines=Field(data,"lines")
    if not Public(lines) or type(lines)~="table" or Field(lines,2)==nil then return nil end
    local wellFed=self:SpellName(19705)
    local result=false
    for i=1,40 do
        local line=Field(lines,i)
        if line==nil then break end
        local text=Field(line,"leftText")
        if Public(text) and type(text)=="string" then
            local lower=text:lower()
            if (wellFed and text:find(wellFed,1,true)) or lower:find("well fed",1,true) or lower:find("experience",1,true) then result=true end
        end
    end
    self.foodBuffCache[id]=result
    return result
end

local tracked
local function Tracked()
    if tracked then return tracked end
    tracked={}
    for family,list in pairs(D.items) do for _,id in ipairs(list) do tracked[id]=family end end
    return tracked
end

function M:ScanBags()
    if self:InCombat() then return end
    local names=self:FoodSpellNames()
    local c=Constants and Constants.InventoryConstants
    local bags=Field(c,"NumBagSlots")
    if not Number(bags,0,8) or not C_Container then return end
    local foods,byId,counts={},{},{}
    local known=Tracked()
    for bag=0,bags do
        local slots=Call(C_Container.GetContainerNumSlots,bag)
        if Number(slots,0,200) then
            for slot=1,slots do
                local info=Call(C_Container.GetContainerItemInfo,bag,slot)
                local id,n=Field(info,"itemID"),Field(info,"stackCount")
                if Number(id,1,2147483647) then
                    n=Number(n,1,100000) and n or 1
                    if known[id] then counts[id]=(counts[id] or 0)+n end
                    local _,_,_,_,icon,class,subclass=Call(C_Item and C_Item.GetItemInfoInstant,id)
                    if class==0 and subclass==5 then
                        local effect=Call(C_Item.GetItemSpell,id)
                        if Public(effect) and effect and names[effect] then
                            if byId[id] then byId[id].count=byId[id].count+n
                            else
                                local f={id=id,count=n,name=self:ItemName(id),icon=Public(icon) and icon or nil,buff=self:FoodGivesBuff(id)}
                                byId[id]=f;foods[#foods+1]=f
                            end
                        end
                    end
                end
            end
        end
    end
    for _,f in ipairs(foods) do counts[f.id]=f.count end
    -- Well Fed foods first, then by name.
    table.sort(foods,function(x,y)
        local rx,ry=x.buff==true and 0 or 1,y.buff==true and 0 or 1
        if rx~=ry then return rx<ry end
        return x.name<y.name
    end)
    self.bagFoods=foods
    self.bestFood=self.LastFood and self:LastFood(true) or nil
    self:LearnFromBags(counts)
end

-- What you used yourself: a food whose count dropped right after you started
-- eating, or a poison whose count dropped as a hand gained a new poison.
-- Best effort; a menu pick is always exact.
function M:LearnFromBags(counts)
    local previous=self.bagCounts
    self.bagCounts=counts
    if not previous or not self.SetLastUsed then return end
    local now=self:Now()
    -- Either order: the eating cast may arrive before or after the bag update.
    for id,n in pairs(previous) do
        if (counts[id] or 0)<n and not Tracked()[id] then
            if self.ateAt and now-self.ateAt<=8 then self:SetLastUsed("food",id);self.ateAt=nil
            else self.foodDrop={id=id,at=now} end
            break
        end
    end
    for _,c in ipairs(D.choices.poisonMain) do
        local before,after=0,0
        for _,id in ipairs(D.items[c.id]) do before=before+(previous[id] or 0);after=after+(counts[id] or 0) end
        if after<before then self.poisonDrop={family=c.id,at=now};self:LearnPoison() end
    end
end
function M:LearnPoison()
    local drop=self.poisonDrop
    local now=self:Now()
    if not drop or now-drop.at>8 or not self.handChanged then return end
    for hand,key in ipairs({"poisonMain","poisonOff"}) do
        local at=self.handChanged[hand]
        if at and now-at<=8 then
            self:SetLastUsed(key,drop.family)
            self.handChanged[hand]=nil;self.poisonDrop=nil
            return
        end
    end
end

-- One weapon read applied to its state; notes a hand that just gained a new poison.
function M:ApplyWeapon(b,s,w)
    s.empty=w.empty
    if w.unknown then return end
    if w.empty then s.present=nil;return end
    if w.missing then s.present=false;s.expires=nil;s.charges=nil;return end
    if b.poison and s.present~=nil and (not s.present or not s.expires or w.expires>s.expires+60) then
        self.handChanged=self.handChanged or {}
        self.handChanged[b.hand]=self:Now()
        self:LearnPoison()
    end
    s.present=true;s.expires=w.expires;s.charges=w.charges;s.icon=w.icon
end

function M:RefreshKnowledge()
    self.bestCache={}
    self.class=self:PlayerClass()
    local name=Call(UnitName,"player")
    if Public(name) and type(name)=="string" then self.playerName=name end
end

-- The read-and-count engine ---------------------------------------------------

-- states[key]={present=true|false|nil, expires=t|nil, charges, estimated, icon, who}
-- full: read every group member too; otherwise only members whose auras changed.
function M:Scan(full)
    local now=self:Now()
    local states=self.states
    local list=self:ReadAuras("player")
    self.readable=list~=nil
    -- Still restricted after combat (encounter, PvP): read again next tick.
    if not list and not self:InCombat() then self.retryRead=true else self.retryRead=nil end
    for _,b in ipairs(D.buffs) do
        if b.class=="ALL" or b.class==self.class then
            local s=states[b.key] or {};states[b.key]=s
            if b.kind=="aura" or b.kind=="food" or b.kind=="active" then
                if list then
                    local rec=self:MatchAura(b,list)
                    s.present=rec~=nil;s.expires=rec and rec.expires or nil
                    -- Applications mean charges only once the aura has been seen stacked.
                    if rec and rec.count and rec.count>1 then s.stacked=true elseif not rec then s.stacked=nil end
                    s.charges=rec and s.stacked and rec.count or nil
                    s.estimated=false;s.readAt=now
                    if rec and rec.duration then s.duration=rec.duration end
                end
            elseif b.kind=="weapon" then
                s.estimated=false
                self:ApplyWeapon(b,s,self:ReadWeapon(b.hand,b.enchant))
            elseif b.kind=="totem" then
                local t=self:ReadTotem(b)
                if t.unknown then s.estimated=s.present~=nil
                elseif t.missing then s.present=false;s.expires=nil;s.estimated=false
                else s.present=true;s.expires=t.expires;s.icon=t.icon;s.estimated=false end
            elseif b.kind=="pet" then
                local exists=Call(UnitExists,"pet")
                if Public(exists) then
                    s.present=exists==true
                    if not s.present and b.skipAura and list then
                        for _,rec in ipairs(list) do for _,id in ipairs(b.skipAura) do if rec.id==id then s.present=true end end end
                    end
                end
            end
        end
    end
    if self.ScanGroup then self:ScanGroup(now,not full and (self.dirtyUnits or {}) or nil) end
    self.dirtyUnits={}
    self.lastScan=now
end

-- Between reads, a stored end time that has passed means the buff is gone.
function M:Remaining(s)
    if not s or not s.expires then return nil end
    return s.expires-self:Now()
end
function M:WarnAt(b,s)
    if b.poison then return self.db.poisonWarn*60 end
    local duration=(s and s.duration) or b.duration
    local minutes=self.db.warnMinutes
    -- A fixed time that would cover half the buff or more falls back to automatic,
    -- so short buffs (Battle Shout, Inner Fire) never warn from the moment they're cast.
    if minutes>0 and (not duration or minutes*60<duration*0.5) then return minutes*60 end
    if not duration then return 0 end
    return math.min(300,duration*0.25)
end

-- One entry per buff that applies: status missing | expiring | ok | unknown.
function M:Evaluate()
    local out={}
    local inGroup=self:InGroup()
    -- Aura timers are estimates whenever auras can't be read now (combat, restrictions).
    local estimating=self:InCombat() or not self.readable
    for _,b in ipairs(D.buffs) do
        if self:Applicable(b) and (not b.groupOnly or inGroup) then
            local s=self.states[b.key] or {}
            local auraKind=b.kind=="aura" or b.kind=="food" or b.kind=="active" or b.kind=="group"
            local entry={buff=b,key=b.key,state=s,estimated=s.estimated or (estimating and auraKind and s.present~=nil)}
            if b.kind=="weapon" and s.empty then entry=nil
            elseif s.present==nil and b.kind~="group" then entry.status="unknown"
            else
                local present=s.present
                local left=self:Remaining(s)
                if present and left and left<=0 then present=false end
                if b.kind=="group" then present=s.present==true and (not left or left>0) end
                entry.left=present and left or nil
                if not present then entry.status="missing"
                else
                    local due=false
                    if self.db.timeReminder and left then due=left<=self:WarnAt(b,s) end
                    if self.db.chargeReminder and s.charges then
                        local limit=b.poison and self.db.poisonCharges or b.charges
                        if limit and s.charges<=limit then due=true end
                    end
                    entry.status=due and "expiring" or "ok"
                end
            end
            if entry then
                entry.charges=s.charges
                entry.resource=self:Resource(b)
                entry.who=s.who
                out[#out+1]=entry
            end
        end
    end
    return out
end

-- Where and when -------------------------------------------------------------

function M:InGroup()
    return Truthy(IsInGroup) or Truthy(IsInRaid) or (Number(Call(GetNumGroupMembers),1) and Call(GetNumGroupMembers)>0) or false
end
function M:PlaceAllowed()
    local db=self.db
    local inside,kind=Call(IsInInstance)
    local place="world"
    if Public(inside) and inside==true and Public(kind) then
        if kind=="party" or kind=="scenario" then place="dungeon" elseif kind=="raid" then place="raid"
        elseif kind=="pvp" or kind=="arena" then place="battleground" end
    end
    if not db.where[place] then return false end
    local resting=Truthy(IsResting)
    if db.resting=="hide" and resting then return false end
    if db.resting=="only" and not resting then return false end
    if db.hideMounted and (Truthy(IsMounted) or Truthy(UnitOnTaxi,"player")) then return false end
    if db.hideDead and Truthy(UnitIsDeadOrGhost,"player") then return false end
    return true
end

-- Entries the display shows now, in catalog order.
function M:Visible(entries)
    local db=self.db
    self.suppressed=true
    if not db.show then return {} end
    local combat=self:InCombat()
    if combat and (db.when=="neededOOC" or db.when=="alwaysOOC") then return {} end
    if not self:PlaceAllowed() then return {} end
    self.suppressed=false
    local all=db.when=="always" or (db.when=="alwaysOOC" and not combat)
    local out={}
    for _,e in ipairs(entries) do
        local due=e.status=="missing" or e.status=="expiring"
        local hide=e.resource=="none" and db.cant=="hide"
        if (due or (all and e.status~="unknown")) and not hide and not (due and self.dismissed[e.key]) then out[#out+1]=e end
    end
    return out
end

-- Dismissed until the next loading screen; a dismissal clears once the buff is fine again.
function M:Dismiss(key)
    if not self.db.dismiss or not key then return false end
    for k in tostring(key):gmatch("[^,]+") do self.dismissed[k]=true end
    self:Update()
    return true
end
function M:RestoreDismissed() self.dismissed={};self:Update();if addon.RefreshConfig then addon:RefreshConfig() end end

-- Main update ------------------------------------------------------------------

function M:Update(rescan)
    if not self.active then return end
    self.countCache={}
    if not self:InCombat() and self.RegisterPositions and not addon.PositionManager.elements[self.MAIN_ID] and (self.registerTries or 0)<3 then
        self.registerTries=(self.registerTries or 0)+1
        self:RegisterPositions()
    end
    if self.retryRead and not self:InCombat() then self.dirty=true end
    if rescan or (self.dirty and not self:InCombat()) or not self.lastScan then
        self.dirty=false
        self:Scan(rescan or not self.lastScan)
    else
        -- Combat: weapons and totems are still read; auras keep their stored end times.
        for _,b in ipairs(D.buffs) do
            if (b.kind=="weapon" or b.kind=="pet" or b.kind=="totem") and (b.class=="ALL" or b.class==self.class) then
                local s=self.states[b.key] or {};self.states[b.key]=s
                if b.kind=="totem" then
                    -- A readable slot is exact; a secret one keeps its estimate.
                    local t=self:ReadTotem(b)
                    if t.missing then s.present=false;s.expires=nil;s.estimated=false
                    elseif not t.unknown then s.present=true;s.expires=t.expires;s.estimated=false end
                elseif b.kind=="weapon" then
                    self:ApplyWeapon(b,s,self:ReadWeapon(b.hand,b.enchant))
                else
                    local exists=Call(UnitExists,"pet");if Public(exists) and exists==true then s.present=true end
                end
            end
        end
        if self.UpdateGroupDeaths then self:UpdateGroupDeaths() end
    end
    local entries=self:Evaluate()
    for _,e in ipairs(entries) do if e.status=="ok" then self.dismissed[e.key]=nil end end
    self.entries=entries
    local shown=self:Visible(entries)
    self:Announce(entries)
    self.shown=shown
    if self.Render then self:Render(shown) end
    if self.RenderGroup then self:RenderGroup() end
    if self.LayoutSecure then self:LayoutSecure() end
    if self.LayoutTabs then self:LayoutTabs() end
end

-- One sound when a reminder first appears; never for the reminders already up at login.
-- Tracks what is due whether or not it is on screen, so dismounting or leaving
-- combat never replays the sound for reminders that were already up.
function M:Announce(entries)
    local now={}
    for _,e in ipairs(entries) do if (e.status=="missing" or e.status=="expiring") and not self.dismissed[e.key] then now[e.key]=true end end
    local fresh=false
    if self.announced then for key in pairs(now) do if not self.announced[key] then fresh=true end end end
    self.announced=now
    if fresh and not self.suppressed and self.db.look.sound and not self.previewing and not self.editing then
        local sound=SOUNDKIT and SOUNDKIT.RAID_WARNING
        if sound then pcall(PlaySound,sound,"Master") end
    end
end

-- Your own casts are visible in combat: a reapplied buff restarts its timer.
function M:OnSpellCast(unit,guid,spell)
    if not Public(unit) or unit~="player" then return end
    -- The target named by UNIT_SPELLCAST_SENT, only for this very cast.
    local sent=self.lastSent;self.lastSent=nil
    self.castTarget=sent and Public(guid) and sent.guid==guid and sent.target or nil
    if not Number(spell,1,2147483647) then return end
    local now=self:Now()
    -- Starting to eat: the next bag read learns which food it was.
    local name=self:SpellName(spell)
    if name and self:FoodSpellNames()[name] then
        self.ateAt=now
        local drop=self.foodDrop
        if drop and now-drop.at<=8 then self:SetLastUsed("food",drop.id);self.foodDrop=nil;self.ateAt=nil end
    end
    for _,b in ipairs(D.buffs) do
        if b.class==self.class or b.class=="ALL" then
            local s=self.states[b.key]
            local hit=false
            if b.kind=="totem" then
                local t=D.TotemType(b.element,self.db.totems[b.element])
                if t then for _,id in ipairs(t.spells) do hit=hit or id==spell end end
            elseif b.kind=="aura" or b.kind=="active" then
                local chain=self:ChainFor(b)
                if chain then for _,id in ipairs(chain) do hit=hit or id==spell end end
                if not hit and b.kind=="active" then hit=detectSets[b.key][spell]==true end
            end
            -- A group buff cast on someone else restarts their timer, not yours.
            local target=self.castTarget
            local onSelf=target==nil or target=="" or target==self.playerName
            if hit and (b.kind~="aura" or not b.party or onSelf) then
                s=s or {};self.states[b.key]=s
                s.present=true;s.estimated=self:InCombat() or not self.readable
                s.expires=(b.kind~="active" and (s.duration or b.duration)) and now+(s.duration or b.duration) or nil
                if b.charges and s.charges then s.charges=nil end
            end
        end
    end
    if self.OnGroupCast then self:OnGroupCast(spell,now) end
    self.castTarget=nil
    self.dirty=true
    self:Update()
end

-- Layout samples ----------------------------------------------------------------

function M:Samples()
    local out={}
    for _,b in ipairs(D.buffs) do
        if (b.class==self.class or b.class=="ALL") and b.kind~="totem" and self.db.buffs[b.key] then
            out[#out+1]={buff=b,key=b.key,state={},status=#out==0 and "missing" or "expiring",left=(#out+1)*60,sample=true,resource="ok"}
            if #out>=4 then break end
        end
    end
    if #out==0 then out[1]={buff=D.byKey.food,key="food",state={},status="missing",sample=true,resource="ok"} end
    return out
end

-- Lifecycle -----------------------------------------------------------------------

local EVENTS={"PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","UNIT_AURA","SPELLS_CHANGED",
    "LEARNED_SPELL_IN_SKILL_LINE","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_SENT","PLAYER_TOTEM_UPDATE","WEAPON_ENCHANT_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED","UNIT_INVENTORY_CHANGED","BAG_UPDATE_DELAYED","UNIT_PET","GROUP_ROSTER_UPDATE",
    "PLAYER_UPDATE_RESTING","ZONE_CHANGED_NEW_AREA","PLAYER_DEAD","PLAYER_ALIVE","PLAYER_UNGHOST"}

-- Units whose auras matter: you and your group. Target and nameplate auras are ignored.
local function Watched(unit)
    return Public(unit) and type(unit)=="string" and (unit=="player" or unit:match("^party%d$")~=nil or unit:match("^raid%d+$")~=nil)
end

function M:OnEvent(event,a,b,c,d)
    if event=="UNIT_SPELLCAST_SUCCEEDED" then self:OnSpellCast(a,b,c);return end
    if (event=="UNIT_INVENTORY_CHANGED" or event=="UNIT_PET") and not (Public(a) and a=="player") then return end
    if event=="UNIT_SPELLCAST_SENT" then
        if Public(a) and a=="player" and Public(b) and type(b)=="string" and Public(c) then self.lastSent={target=b,guid=c} end
        return
    end
    if event=="UNIT_AURA" then
        if self:InCombat() or not Watched(a) then return end
        self.dirtyUnits=self.dirtyUnits or {};self.dirtyUnits[a]=true
        self.dirty=true;self:ScheduleUpdate();return
    end
    if event=="PLAYER_ENTERING_WORLD" then self.dismissed={};self.announced=nil;self.foodNames=nil;self.registerTries=0 end
    if event=="PLAYER_REGEN_ENABLED" then
        -- Anything a combat login or reload postponed: click buttons and Layout registration.
        if self.secureAvailable==nil and self.CreateSecure then self:CreateSecure() end
        self.registerTries=0
        if self.ThawSecure then self:ThawSecure() end
    end
    if event=="PLAYER_REGEN_DISABLED" then
        if self.FreezeSecure then self:FreezeSecure() end
        self:Update();return
    end
    if event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_SKILL_LINE" then self:RefreshKnowledge() end
    if event=="BAG_UPDATE_DELAYED" or event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED" then self:ScanBags() end
    if event=="GROUP_ROSTER_UPDATE" and self.RefreshRoster then self:RefreshRoster() end
    -- Bags, gear, totems and pets only need your own state; these need everyone.
    local full={PLAYER_ENTERING_WORLD=true,PLAYER_REGEN_ENABLED=true,GROUP_ROSTER_UPDATE=true,SPELLS_CHANGED=true,LEARNED_SPELL_IN_SKILL_LINE=true}
    self.dirty=true
    self:Update(full[event]==true and not self:InCombat())
end

-- UNIT_AURA arrives in bursts; read once on the next tick.
function M:ScheduleUpdate()
    if self.pendingUpdate then return end
    self.pendingUpdate=true
    C_Timer.After(0.25,function() self.pendingUpdate=false;if self.active then self:Update() end end)
end

function M:OnInitialize()
    D.AdoptRogue(self.db,addon.db and addon.db.modules)
    self.Initialize(self.db)
    self.states,self.dismissed,self.entries,self.shown={},{},{},{}
    self.class=self:PlayerClass()
end

function M:OnEnable()
    if self.active then return end
    self.active=true
    self:RefreshKnowledge()
    if self.CreateDisplay then self:CreateDisplay() end
    if self.CreateSecure then self:CreateSecure() end
    self.events=self.events or CreateFrame("Frame")
    for _,event in ipairs(EVENTS) do
        if event=="UNIT_AURA" then pcall(self.events.RegisterEvent,self.events,event)
        else pcall(self.events.RegisterEvent,self.events,event) end
    end
    self.events:SetScript("OnEvent",function(_,event,...) self:OnEvent(event,...) end)
    self.ticker=C_Timer.NewTicker(self.TICK,function() if self.active then self:Update() end end)
    self:ScanBags()
    if self.RefreshRoster then self:RefreshRoster() end
    self:Update(true)
    if self.RegisterPositions then self:RegisterPositions() end
end

function M:OnDisable()
    self.active,self.editing,self.previewing=false,false,false
    if self.ticker then self.ticker:Cancel();self.ticker=nil end
    if self.events then self.events:UnregisterAllEvents();self.events:SetScript("OnEvent",nil) end
    if self.HideAll then self:HideAll() end
    if self.LayoutTabs then self:LayoutTabs() end
    if self.CloseMenu then self:CloseMenu() end
    -- Turned off mid-fight: click buttons can only be cleared once combat ends.
    if self.secureAvailable and self:InCombat() and self.events then
        pcall(self.events.RegisterEvent,self.events,"PLAYER_REGEN_ENABLED")
        self.events:SetScript("OnEvent",function()
            self.events:UnregisterAllEvents();self.events:SetScript("OnEvent",nil)
            if not self.active and self.LayoutSecure then self:LayoutSecure() end
        end)
    end
end

function M:SetEditMode(enabled)
    self.editing=enabled and self.active or false
    if self.SyncEditElements then self:SyncEditElements() end
    self:Update()
end
function M:SetPreviewMode(enabled) self.previewing=enabled and self.active or false;self:Update() end

