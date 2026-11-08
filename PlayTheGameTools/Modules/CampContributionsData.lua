local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local A={items={},dirty=true}
addon.CampContributions=A
local D=addon.ForeverQuickAccessData
-- Native camp-contribution item identities, independently grouped by skill
-- line. Source/attribution: docs/CAMP_CONTRIBUTIONS.md and third-party notices.
-- Fire kits are intentionally excluded: this popup contributes to an existing
-- fire. Native usability, not guessed recipe skill thresholds, gates each kit.
A.catalog={
    [279956]=171,[279970]=171,[279990]=171, -- Alchemy
    [279944]=164,[279988]=164,[279955]=164, -- Blacksmithing
    [279957]=185,[279982]=185,             -- Cooking: feast / oven
    [279976]=333,[279985]=333,[279987]=333, -- Enchanting
    [279950]=202,[279949]=202,[279989]=202, -- Engineering
    [279968]=129,[279940]=129,[279951]=129, -- First Aid
    [279967]=356,[279965]=356,[279966]=356, -- Fishing
    [279962]=182,[279964]=182,[279947]=182, -- Herbalism
    [279978]=165,[279941]=165,[279945]=165, -- Leatherworking
    [279960]=186,[279948]=186,[279952]=186, -- Mining
    [279979]=393,[279969]=393,[279938]=393, -- Skinning
    [279973]=197,[279972]=197,[279943]=197,[279959]=197, -- Tailoring / both banners
}
function A.Read(fn,...)
    if type(fn)~="function" then return false end
    local ok,a,b,c,d,e,f,g=pcall(fn,...)
    if not ok then return false end
    for _,v in pairs({a,b,c,d,e,f,g}) do if not D.Public(v) then return false end end
    return true,a,b,c,d,e,f,g
end
function A.Field(t,key)
    if not D.Public(t) or type(t)~="table" then return end
    local ok,value=A.Read(function() return t[key] end)
    if ok then return value end
end
function A:Scan()
    if self.scanning or not D.OutsideCombat() then return end
    self.scanning=true;self.dirty=false;self.items={};self.generation=(self.generation or 0)+1
    local function Finish(message) self.message=message;self.scanning=nil end
    local professions,message=D.ReadProfessions()
    if not professions then Finish(message or "Profession data unavailable.");return end
    local learned={}
    for _,p in ipairs(professions) do learned[p.id]=p.name end
    if not C_Container or not C_Item or type(C_Item.IsUsableItem)~="function" or
        type(C_Container.GetContainerItemCooldown)~="function" then
        Finish("Native carried-item availability reader unavailable.");return
    end
    local constants=Constants and Constants.InventoryConstants
    local bags=self.Field(constants,"NumBagSlots")
    local reagents=self.Field(constants,"NumReagentBagSlots")
    local clock,now=self.Read(GetTime)
    if not D.Number(bags,0,8) or bags%1~=0 or not D.Number(reagents,0,2) or reagents%1~=0 or
        not clock or not D.Number(now,0,1e12) then Finish("Native bag/clock data unavailable.");return end
    local byID,pending,skipped,earliest={},0,0,nil
    for bag=0,bags+reagents do
        local ok,slots=self.Read(C_Container.GetContainerNumSlots,bag)
        if not ok or not D.Number(slots,0,200) or slots%1~=0 then
            self.items={};Finish("Bag data unavailable. Use Refresh Contributions outside combat.");return
        end
        for slot=1,slots do
            local valid,info=self.Read(C_Container.GetContainerItemInfo,bag,slot)
            local id=valid and self.Field(info,"itemID")
            if D.Number(id,1,2147483647) and self.catalog[id] and learned[self.catalog[id]] then
                local count,locked=self.Field(info,"stackCount"),self.Field(info,"isLocked")
                local usable,canUse=self.Read(C_Item.IsUsableItem,id)
                local cool,start,duration,enabled=self.Read(C_Container.GetContainerItemCooldown,bag,slot)
                if D.Number(count,1,2147483647) and count%1==0 and locked==false and usable and canUse==true and
                    cool and D.Number(start,0,1e12) and D.Number(duration,0,86400) and enabled==1 then
                    local remaining=math.max(0,start+duration-now)
                    if duration>0 and remaining>0 then earliest=math.min(earliest or remaining,remaining)
                    else
                        local named,name=self.Read(C_Item.GetItemNameByID,id)
                        local detailed,actual,_,_,_,icon=self.Read(C_Item.GetItemInfoInstant,id)
                        if named and type(name)=="string" and name~="" and detailed and actual==id and
                            ((D.Number(icon,1,2147483647)) or (type(icon)=="string" and icon~="")) then
                            local entry=byID[id]
                            if not entry then
                                entry={id=id,name=name,icon=icon,profession=learned[self.catalog[id]],count=0}
                                byID[id]=entry;self.items[#self.items+1]=entry
                            end
                            entry.count=entry.count+count
                        else
                            pending=pending+1;self.requested=self.requested or {}
                            if not self.requested[id] and type(C_Item.RequestLoadItemDataByID)=="function" then
                                self.requested[id]=true;pcall(C_Item.RequestLoadItemDataByID,id)
                            end
                        end
                    end
                else skipped=skipped+1 end
            end
        end
    end
    table.sort(self.items,function(a,b)
        if a.profession~=b.profession then return a.profession<b.profession end
        if a.name~=b.name then return a.name<b.name end
        return a.id<b.id
    end)
    local status=#self.items>0 and (#self.items.." ready camp contributions in your bags.") or
        "No ready carried camp kits for your learned professions."
    if earliest then status=status.." Other kits are on cooldown." end
    if pending>0 then status=status.." Item details are loading." end
    if skipped>0 then status=status.." Unusable, locked or unreadable kits skipped." end
    Finish(status)
    if earliest and not self.dismissed then
        local generation=self.generation
        C_Timer.After(earliest+0.1,function()
            if self.active and generation==self.generation then
                self.dirty=true;self:OnSnapshot(self.camp.snapshot)
            end
        end)
    end
end
