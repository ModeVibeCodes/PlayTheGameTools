local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local D=addon.ForeverQuickAccessData
local F={limit=40}
addon.ForeverFoodBar=F

function F.Initialize(db)
    if db.food==nil then db.food={} end
    local food=db.food;assert(type(food)=="table","Invalid food bar settings")
    if food.y==nil then food.y=-260 end
    D.Initialize(food,true)
    for key,value in pairs({enabled=false,shown=true,includeBandages=false}) do
        if food[key]==nil then food[key]=value end
        assert(type(food[key])=="boolean","Invalid food bar switch: "..key)
    end
    if food.selected==nil then food.selected={} end
    assert(type(food.selected)=="table","Invalid selected food")
    local count=0
    for id,value in pairs(food.selected) do
        count=count+1
        assert(count<=200 and D.Number(id,1,2147483647) and id%1==0 and type(value)=="boolean","Invalid selected food item")
    end
end

local function Read(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d,e,f,g=pcall(fn,...)
    if not ok then return end
    for _,v in pairs({a,b,c,d,e,f,g}) do if not D.Public(v) then return end end
    return a,b,c,d,e,f,g
end
local function Field(t,key)
    if not D.Public(t) or type(t)~="table" then return end
    return Read(function() return t[key] end)
end

-- Food/drink is a shared native subclass (5). Selection is explicit, so drinks
-- are never automatically labelled health food. Bandages use subclass 7.
function F:Scan()
    if not D.OutsideCombat() then self.dirty=true;return false end
    self.dirty=false
    local inventory,byID={},{}
    self.foodChoices={}
    local constants=Constants and Constants.InventoryConstants
    local bags=Field(constants,"NumBagSlots")
    local reagents=Field(constants,"NumReagentBagSlots")
    if D.Number(bags,0,8) and D.Number(reagents,0,2) then bags=bags+reagents else bags=nil end
    if not D.Number(bags,0,10) or bags%1~=0 or not C_Container or not C_Item then
        self.inventory={};self.message="Native carried-bag reader unavailable.";return false
    end
    local pending,uncertain=0,0
    for bag=0,bags do
        local slots=Read(C_Container.GetContainerNumSlots,bag)
        if not D.Number(slots,0,200) or slots%1~=0 then
            self.inventory={};self.message="Bag data unavailable; try Refresh Bags outside combat.";return false
        end
        for slot=1,slots do
            local info=Read(C_Container.GetContainerItemInfo,bag,slot)
            if info~=nil then
                local id,count=Field(info,"itemID"),Field(info,"stackCount")
                if D.Number(id,1,2147483647) and id%1==0 and D.Number(count,1,2147483647) and count%1==0 then
                    local actual,_,_,_,icon,class,subclass=Read(C_Item.GetItemInfoInstant,id)
                    if actual==id and class==0 and (subclass==5 or subclass==7) then
                        local spellName,spellID=Read(C_Item.GetItemSpell,id)
                        local name=Read(C_Item.GetItemNameByID,id)
                        if type(name)=="string" and name~="" and D.Number(icon,1,2147483647) and
                            type(spellName)=="string" and D.Number(spellID,1,2147483647) then
                            local p=byID[id]
                            if not p then
                                p={id=id,name=name,icon=icon,count=0,bandage=subclass==7}
                                byID[id]=p;inventory[#inventory+1]=p
                            end
                            p.count=p.count+count
                        else
                            pending=pending+1
                            self.requested=self.requested or {}
                            if not self.requested[id] and type(C_Item.RequestLoadItemDataByID)=="function" then
                                self.requested[id]=true
                                pcall(C_Item.RequestLoadItemDataByID,id)
                            end
                        end
                    end
                else uncertain=uncertain+1 end
            end
        end
    end
    table.sort(inventory,function(a,b) if a.bandage~=b.bandage then return not a.bandage end;return a.id<b.id end)
    self.inventory=inventory
    for _,p in ipairs(inventory) do if not p.bandage and #self.foodChoices<self.limit then self.foodChoices[#self.foodChoices+1]=p end end
    self.message=("%d carried food/drink or bandage types. Choose food below; drinks stay unselected."):format(#inventory)
    if pending>0 then self.message=self.message.." Item details still loading." end
    if uncertain>0 then self.message=self.message.." Unreadable bag entries skipped." end
    if #inventory>self.limit then self.message=self.message.." At most 40 types are displayed at a time." end
    return true
end

function F:VisibleItems()
    local items={}
    for _,p in ipairs(self.inventory or {}) do
        if (p.bandage and self.db.includeBandages) or (not p.bandage and self.db.selected[p.id]) then
            if #items<self.limit then items[#items+1]=p end
        end
    end
    return items
end
