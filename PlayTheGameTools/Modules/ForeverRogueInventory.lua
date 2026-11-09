local _,addon=...
if not addon.ForeverRogue then return end
local M,D=addon.ForeverRogue,addon.ForeverRogueData
-- Item IDs only provide a family fallback. Names, effects, counts and icons must
-- still come from native item metadata; items are never treated as learned spells.
local itemFamilies={}
for family,ids in pairs({[8679]={6947,6949,6950,8926,8927,8928},[2823]={2892,2893,8984,8985,20844},
    [3408]={3775,3776},[5761]={5237,6951,9186},[13219]={10918,10920,10921,10922}}) do
    for rank,id in ipairs(ids) do itemFamilies[id]={family=family,rank=rank} end
end
function M:Discover()
    if not D.OutsideCombat() then return end
    local names,spells,items={},{},{}
    for _,base in ipairs(D.families) do
        local p=D.Spell(base)
        if p then
            names[p.name]=base
            local id=D.Call(C_SpellBook and C_SpellBook.FindSpellOverrideByID,base)
            if not D.Number(id,1,2147483647) then id=base end
            if D.Call(C_SpellBook and C_SpellBook.IsSpellKnown,id)==true then
                local known=D.Spell(id)
                if known then known.family=base;spells[base]=known end
            end
        end
    end
    local api=C_Flyout;local count=D.Call(api and api.GetNumFlyouts)
    if D.Number(count,0,1024) and count%1==0 then
        for i=1,count do
            local id=D.Call(api.GetFlyoutID,i)
            if D.Number(id,1,2147483647) then
                local info=D.Call(api.GetFlyoutInfo,id);local slots=D.Field(info,"numSlots")
                if D.Field(info,"isKnown")==true and D.Number(slots,0,64) and slots%1==0 then
                    for j=1,slots do
                        local slot=D.Call(api.GetFlyoutSlotInfo,id,j)
                        if D.Field(slot,"isKnown")==true then
                            local spell=D.Field(slot,"overrideSpellID")
                            if not D.Number(spell,1,2147483647) then spell=D.Field(slot,"spellID") end
                            local p=D.Number(spell,1,2147483647) and D.Spell(spell)
                            if p and names[p.name] then p.family=names[p.name];spells[p.family]=p end
                        end
                    end
                end
            end
        end
    end
    self.bagStatus=nil
    local c=Constants and Constants.InventoryConstants
    local bags,reagents=D.Field(c,"NumBagSlots"),D.Field(c,"NumReagentBagSlots")
    if D.Number(bags,0,8) and D.Number(reagents,0,2) and C_Container and C_Item then
        local complete=true
        for bag=0,bags+reagents do
            local slots=D.Call(C_Container.GetContainerNumSlots,bag)
            if not D.Number(slots,0,200) or slots%1~=0 then complete=false;break end
            for slot=1,slots do
                local readable,info=D.Try(C_Container.GetContainerItemInfo,bag,slot)
                if not readable then complete=false;break end
                if info then
                    local id,n=D.Field(info,"itemID"),D.Field(info,"stackCount")
                    if D.Number(id,1,2147483647) and D.Number(n,1,2147483647) then
                        local _,_,_,_,icon,class=D.ItemInfo(id)
                        if class==0 then
                            local ok,effect,effectID=pcall(C_Item.GetItemSpell,id)
                            local name=D.Call(C_Item.GetItemNameByID,id)
                            local family=ok and D.Public(effect) and names[effect]
                            local mapped=itemFamilies[id]
                            if not family and mapped then family=mapped.family end
                            if family and type(name)=="string" and D.Number(icon,1,2147483647) and ok and D.Number(effectID,1,2147483647) then
                                local p=items[id]
                                if not p then
                                    local effectInfo=D.Spell(effectID)
                                    p={id=id,key="item:"..id,kind="item",family=family,name=name,icon=icon,
                                        effectID=effectID,effectIcon=effectInfo and effectInfo.icon,count=0,rank=mapped and mapped.rank or 0}
                                    items[id]=p
                                end
                                -- Locked stacks remain visible in the list but cannot be used.
                                if D.Field(info,"isLocked")==false then p.count=p.count+n end
                            elseif (family or name==nil) and not self.requested[id] and type(C_Item.RequestLoadItemDataByID)=="function" then
                                self.requested[id]=true;pcall(C_Item.RequestLoadItemDataByID,id)
                            end
                        end
                    else complete=false;break end
                end
            end
            if not complete then break end
        end
        if not complete then items={};self.bagStatus="Bag data unavailable; refresh outside combat." end
    else self.bagStatus="Native carried-bag reader unavailable." end
    self.known,self.choices,self.byKey={},{},{}
    for _,p in pairs(items) do self.choices[#self.choices+1]=p end
    for _,p in pairs(spells) do
        p.kind="spell";p.key="spell:"..p.id;p.effectID=p.id;p.count=nil;p.rank=0
        self.choices[#self.choices+1]=p
    end
    table.sort(self.choices,function(a,b)
        if a.family~=b.family then return a.family<b.family end
        if a.kind~=b.kind then return a.kind=="item" end
        if a.rank~=b.rank then return a.rank>b.rank end
        return a.id<b.id
    end)
    while #self.choices>D.limit do table.remove(self.choices) end
    for _,p in ipairs(self.choices) do
        self.byKey[p.key]=p
        if not self.known[p.family] and self:Available(p) then self.known[p.family]=p end
    end
end
function M:Available(p) return p and (p.kind=="spell" or p.count>0) end
function D.FamilyForKey(key)
    if type(key)~="string" then return end
    local family=tonumber(key:match("^family:(%d+)$"));if family then return family end
    local id=tonumber(key:match("^item:(%d+)$"))
    if id and itemFamilies[id] then return itemFamilies[id].family end
    id=tonumber(key:match("^spell:(%d+)$"));local p=id and D.Spell(id)
    if p then for _,base in ipairs(D.families) do local known=D.Spell(base);if known and p.name==known.name then return base end end end
end
function M:MatchIcon(icon)
    local family,first
    for _,p in ipairs(self.choices) do
        if p.icon==icon or p.effectIcon==icon then
            if family and family~=p.family then return end
            family=p.family
            if self:Available(p) and not first then first=p end
        end
    end
    return first
end
function M:ReadCharges(hand,weapon,enchant,info)
    local previous=self.chargeSources[hand]
    if previous and (previous.weapon~=weapon or previous.enchant~=enchant) then self.chargeSources[hand]=nil;previous=nil end
    local charges=D.Field(info,"charges")
    if not D.Number(charges,0,2147483647) or charges%1~=0 then return nil,false end
    if charges>0 then
        self.chargeSources[hand]={weapon=weapon,enchant=enchant};return charges,true
    end
    -- The API supplies no hasCharges flag. A fresh zero can also mean no charge
    -- mechanic. Only treat zero as exhaustion after observing positive charges
    -- on this same weapon/enchant in this session. Never infer a secret count.
    if previous then return 0,true end
    return nil,false
end
function M:ReadHand(hand)
    local slot=hand==1 and 16 or 17
    local readable,item=D.Try(GetInventoryItemID,"player",slot)
    if not readable then return {unknown=true} end
    if item==nil then self.chargeSources[hand]=nil;return {empty=true} end
    if not D.Number(item,1,2147483647) then return {unknown=true} end
    local _,_,_,equip,_,class=D.ItemInfo(item)
    if not D.Number(class,0,30) or type(equip)~="string" then return {unknown=true} end
    if class~=2 or equip=="INVTYPE_RANGED" or equip=="INVTYPE_RANGEDRIGHT" or equip=="INVTYPE_THROWN" then self.chargeSources[hand]=nil;return {empty=true} end
    local enums=Enum and Enum.WeaponSlot
    local weapon=enums and (hand==1 and enums.MainHand or enums.OffHand)
    local imbue=Enum and Enum.ItemEnchantType and Enum.ItemEnchantType.Imbue
    if not D.Number(weapon,0,2) or not D.Number(imbue,0,10) then return {unknown=true,weapon=item} end
    local enchants=D.Call(C_Item and C_Item.GetWeaponEnchantInfo,weapon)
    if type(enchants)~="table" then return {unknown=true,weapon=item} end
    for i=1,16 do
        local valid,e=D.Try(function() return enchants[i] end)
        if not valid then return {unknown=true,weapon=item} end
        if e==nil then break end
        if type(e)~="table" then return {unknown=true,weapon=item} end
        local kind=D.Field(e,"enchantType")
        if kind==nil then return {unknown=true,weapon=item} end
        if kind==imbue then
            local active=D.Field(e,"hasEnchant")
            if active==nil then return {unknown=true,weapon=item} end
            if active then
                local left,icon,id=D.Field(e,"timeLeft"),D.Field(e,"enchantIconID"),D.Field(e,"enchantID")
                if not D.Number(left,0,2147483647) or not D.Number(icon,1,2147483647) or not D.Number(id,1,2147483647) then return {unknown=true,weapon=item} end
                local charges,hasCharges=self:ReadCharges(hand,item,id,e)
                return {seconds=left/1000,icon=icon,enchant=id,weapon=item,poison=self:MatchIcon(icon),charges=charges,hasCharges=hasCharges}
            end
        end
    end
    self.chargeSources[hand]=nil
    return {seconds=0,missing=true,weapon=item}
end
