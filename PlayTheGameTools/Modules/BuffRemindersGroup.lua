local _,addon=...
local M=addon.BuffReminders
if not M then return end
local D=addon.BuffRemindersData
local Public,Number,Call,Truthy=D.Public,D.Number,D.Call,D.Truthy

-- Group watcher: the buffs you provide (blessings, Fortitude, Divine Spirit,
-- Arcane Intellect, Mark of the Wild) on every group member, plus the one-target
-- buffs you keep on someone (Soulstone, Thorns). Read out of combat; counted in
-- combat; deaths clear a member's buffs at once (UnitIsDeadOrGhost stays readable).

-- Which blessing chain an aura spell belongs to.
local blessingFamily={}
for family,chains in pairs({might={"might","greaterMight"},wisdom={"wisdom","greaterWisdom"},kings={"kings","greaterKings"}}) do
    for _,name in ipairs(chains) do for _,id in ipairs(D.chains[name]) do blessingFamily[id]=family end end
end
M.blessingFamily=blessingFamily

local function UnitName(unit)
    local name=Call(_G.UnitName,unit)
    if Public(name) and type(name)=="string" and name~="" then return name end
end
local function UnitClassFile(unit)
    local _,class=Call(UnitClass,unit)
    if Public(class) and type(class)=="string" then return class end
end

-- Group units other than the player, in roster order.
function M:GroupUnits()
    local units={}
    if Truthy(IsInRaid) then
        local count=Call(GetNumGroupMembers)
        count=Number(count,0,40) and count or 0
        for i=1,count do
            local unit="raid"..i
            if Truthy(UnitExists,unit) and not Truthy(UnitIsUnit,unit,"player") then units[#units+1]=unit end
        end
    else
        local count=Call(GetNumSubgroupMembers)
        count=Number(count,0,4) and count or 0
        for i=1,count do if Truthy(UnitExists,"party"..i) then units[#units+1]="party"..i end end
    end
    return units
end

function M:RefreshRoster()
    local roster={}
    for _,unit in ipairs(self:GroupUnits()) do
        local name=UnitName(unit)
        if name then roster[#roster+1]={unit=unit,name=name,class=UnitClassFile(unit)} end
    end
    self.roster=roster
    self.members=self.members or {}
    local keep={}
    for _,m in ipairs(roster) do keep[m.name]=true;self.members[m.name]=self.members[m.name] or {buffs={}} end
    for name in pairs(self.members) do if not keep[name] then self.members[name]=nil end end
    self.playerName=UnitName("player")
end

-- Buffs the watcher tracks for this class.
function M:WatchedBuffs()
    local out={}
    if not self.db.watchGroup then return out end
    for _,b in ipairs(D.buffs) do
        if b.party and b.class==self.class and self.db.buffs[b.key] and self:Applicable(b) then out[#out+1]=b end
    end
    return out
end

function M:BlessingFor(member)
    local family=member.blessing or D.DEFAULT_BLESSING[member.class or ""] or "might"
    if not self:Best(D.chains[family]) then family="might" end
    return family
end

local function Mine(rec) return rec.source==nil or rec.source=="player" or rec.source=="pet" end

function M:ScanGroup(now)
    self.roster=self.roster or {}
    local watched=self:WatchedBuffs()
    local groupKinds={}
    for _,b in ipairs(D.buffs) do if b.kind=="group" and b.class==self.class then groupKinds[#groupKinds+1]=b end end
    if #watched==0 and #groupKinds==0 then return end
    local found={}
    local function Check(unit,name,list)
        for _,b in ipairs(groupKinds) do
            for _,rec in ipairs(list) do
                if self.detectSets[b.key][rec.id] and Mine(rec) and (not found[b.key] or (rec.expires or math.huge)>(found[b.key].expires or math.huge)) then
                    found[b.key]={expires=rec.expires,duration=rec.duration,who=name,unit=unit}
                end
            end
        end
    end
    local complete=true
    local mine=self:ReadAuras("player")
    if mine then Check("player","you",mine) else complete=false end
    for _,m in ipairs(self.roster) do
        local member=self.members[m.name] or {buffs={}};self.members[m.name]=member
        member.unit,member.class=m.unit,m.class
        local list=self:ReadAuras(m.unit)
        if list then
            Check(m.unit,m.name,list)
            for _,b in ipairs(watched) do
                local best
                for _,rec in ipairs(list) do
                    if self.detectSets[b.key][rec.id] and (not b.mine or Mine(rec)) and (not best or (rec.expires or math.huge)>(best.expires or math.huge)) then best=rec end
                end
                local s=member.buffs[b.key] or {};member.buffs[b.key]=s
                s.present=best~=nil;s.expires=best and best.expires or nil;s.estimated=false
                if best and b.key=="blessing" then member.blessing=blessingFamily[best.id] or member.blessing end
            end
        else complete=false end
    end
    -- Only a complete read proves a one-target buff is gone.
    for _,b in ipairs(groupKinds) do
        local s=self.states[b.key] or {};self.states[b.key]=s
        local f=found[b.key]
        if f then s.present=true;s.expires=f.expires;s.who=f.who;s.whoUnit=f.unit;s.estimated=false;if f.duration then s.duration=f.duration end
        elseif complete then s.present=false;s.expires=nil;s.who=nil;s.whoUnit=nil end
    end
end

-- In combat: a death clears that member's buffs. A Soulstone outlives death.
function M:UpdateGroupDeaths()
    for name,member in pairs(self.members or {}) do
        if member.unit and Truthy(UnitIsDeadOrGhost,member.unit) then
            for _,s in pairs(member.buffs) do s.present=false;s.expires=nil end
            member.dead=true
        else member.dead=false end
    end
    local thorns=self.states.thorns
    if thorns and thorns.whoUnit and Truthy(UnitIsDeadOrGhost,thorns.whoUnit) then thorns.present=false;thorns.expires=nil end
end

-- Your cast on a group member (target from UNIT_SPELLCAST_SENT) restarts that member's timer.
function M:OnGroupCast(spell,now)
    local target=self.lastCastTarget
    for _,b in ipairs(D.buffs) do
        if b.class==self.class and b.kind=="group" and self.detectSets[b.key] then
            local chain=self:ChainFor(b)
            local hit=self.detectSets[b.key][spell]
            if chain then for _,id in ipairs(chain) do hit=hit or id==spell end end
            if hit then
                local s=self.states[b.key] or {};self.states[b.key]=s
                local member=target and self.members and self.members[target]
                s.present=true;s.expires=now+(s.duration or b.duration);s.estimated=true
                s.who=member and target or "you";s.whoUnit=member and member.unit or "player"
            end
        end
    end
    if not target or not self.members or not self.members[target] then return end
    local member=self.members[target]
    for _,b in ipairs(self:WatchedBuffs()) do
        local hit=false
        if b.key=="blessing" then
            local family=blessingFamily[spell]
            if family then hit=true;member.blessing=family end
        else
            local chain=self:ChainFor(b)
            for _,id in ipairs(chain or {}) do hit=hit or id==spell end
            hit=hit or self.detectSets[b.key][spell]==true
        end
        if hit then
            local s=member.buffs[b.key] or {};member.buffs[b.key]=s
            s.present=true;s.expires=now+b.duration;s.estimated=self:InCombat()
        end
    end
end

-- Display rows: one per watched buff, each with every member's status.
function M:GroupEntries()
    local out={}
    local now=self:Now()
    for _,b in ipairs(self:WatchedBuffs()) do
        local row={buff=b,members={},ok=0,missing=0}
        for _,m in ipairs(self.roster or {}) do
            local member=self.members[m.name] or {buffs={}}
            local s=member.buffs[b.key] or {}
            local left=s.expires and s.expires-now or nil
            local status
            if member.dead then status="dead"
            elseif s.present==nil then status="unknown"
            elseif not s.present or (left and left<=0) then status="missing"
            elseif left and self.db.timeReminder and left<=self:WarnAt(b,s) then status="expiring"
            else status="ok" end
            local family=b.key=="blessing" and self:BlessingFor({blessing=member.blessing,class=m.class}) or nil
            row.members[#row.members+1]={name=m.name,class=m.class,unit=m.unit,status=status,left=status~="missing" and left or nil,
                estimated=s.estimated or (self:InCombat() and s.present~=nil),family=family}
            if status=="ok" or status=="expiring" then row.ok=row.ok+1 elseif status=="missing" then row.missing=row.missing+1 end
        end
        if #row.members>0 then out[#out+1]=row end
    end
    return out
end

function M:SampleGroup()
    local b
    for _,buff in ipairs(D.buffs) do if buff.party and buff.class==self.class then b=buff;break end end
    b=b or D.byKey.fortitude
    local names={{"Tankard","WARRIOR"},{"Mendra","PRIEST"},{"Fizzle","MAGE"},{"Brakk","HUNTER"}}
    local row={buff=b,members={},ok=2,missing=1,sample=true}
    for i,n in ipairs(names) do
        row.members[i]={name=n[1],class=n[2],status=i==3 and "missing" or (i==2 and "expiring" or "ok"),left=i==2 and 180 or 1800,
            family=b.key=="blessing" and (D.DEFAULT_BLESSING[n[2]] or "might") or nil}
    end
    return {row}
end
