"""Shared mocks for weapons, poisons, bags and native item buttons, used by the
Buff Reminders and Layout tests (moved here from the retired Rogue Tools tests).
Mock only: native action acceptance and rendering still need in-game checks.
"""

SETUP=r'''
weaponIDs={[16]=100,[17]=101};weaponClass=2;metadataReady=true
enchants={[0]={},[1]={}};enchantReads=0;bagReads=0;applications={};acceptApplications=true
useOnKeyDown=false;learned={};requested={};missingMetadata={};playerGUID='Rogue-A'
function UnitGUID() return playerGUID end
Enum=Enum or {};Enum.WeaponSlot={MainHand=0,OffHand=1};Enum.ItemEnchantType={Temporary=2,Imbue=3}
Constants=Constants or {};Constants.InventoryConstants={NumBagSlots=1,NumReagentBagSlots=0}
bags={[0]={{itemID=6947,stackCount=5,isLocked=false},{itemID=6949,stackCount=2,isLocked=false},
 {itemID=117,stackCount=5,isLocked=false}},[1]={{itemID=2892,stackCount=4,isLocked=false}}}
items={[6947]={name='Instant Poison I',icon=201,effect=8679},
 [6949]={name='Instant Poison II',icon=202,effect=8686},
 [2892]={name='Deadly Poison',icon=203,effect=2823},[117]={name='Food',icon=204,effect=9999}}
spells={[8679]={name='Instant Poison',iconID=301},[8686]={name='Instant Poison',iconID=301},
 [2823]={name='Deadly Poison',iconID=302},[3408]={name='Crippling Poison',iconID=303},
 [5761]={name='Mind-numbing Poison',iconID=304},[13219]={name='Wound Poison',iconID=305},
 [2842]={name='Poisons',iconID=306},[9999]={name='Food Effect',iconID=307}}
function GetInventoryItemID(unit,slot) assert(unit=='player');return weaponIDs[slot] end
C_Item=C_Item or {}
function C_Item.GetItemInfoInstant(id)
 if id==100 or id==101 then if metadataReady then return id,'Weapon','Dagger','INVTYPE_WEAPON',123,weaponClass,15 end
 else local p=items[id];if p then return id,'Consumable','Other','',p.icon,0,0 end end
end
function C_Item.GetItemNameByID(id) if not missingMetadata[id] then return items[id] and items[id].name end end
function C_Item.GetItemSpell(id)
 if missingMetadata[id] then return end
 local p=items[id];return p and spells[p.effect].name,p and p.effect
end
function C_Item.RequestLoadItemDataByID(id) requested[id]=(requested[id] or 0)+1 end
function C_Item.GetWeaponEnchantInfo(slot) enchantReads=enchantReads+1;return enchants[slot] end
C_Container={GetContainerNumSlots=function(bag) bagReads=bagReads+1;return #(bags[bag] or {}) end,
 GetContainerItemInfo=function(bag,slot) return bags[bag] and bags[bag][slot] end}
C_Spell=C_Spell or {};C_Spell.GetSpellInfo=function(id) return spells[id] end
C_SpellBook=C_SpellBook or {};C_SpellBook.IsSpellKnown=function(id) return learned[id]==true end
C_SpellBook.FindSpellOverrideByID=function(id) return id end
C_Flyout={GetNumFlyouts=function() return 0 end}
function Poison(slot,seconds,icon,id)
 enchants[slot]={{hasEnchant=true,enchantType=3,timeLeft=seconds*1000,enchantIconID=icon or 301,enchantID=id or 700}}
end
function NativeApply(kind,id,target)
 assert(not testCombat and not testLockdown,'Native application in combat')
 if not acceptApplications then return end
 local effect=id
 if kind=='item' then
  local carried,carriedBag,carriedSlot
  for _,bag in pairs(bags) do for slot,p in ipairs(bag) do
   if p.itemID==id and not p.isLocked and p.stackCount>0 then carried=p;carriedBag=bag;carriedSlot=slot;break end
  end end
  if not carried then return end
  effect=items[id].effect;carried.stackCount=carried.stackCount-1
  if carried.stackCount==0 then table.remove(carriedBag,carriedSlot) end
 else assert(learned[id],'Unlearned cast attempted') end
 applications[#applications+1]={kind=kind,id=id,target=target}
 testClock=testClock+2
 FireEvent('UNIT_SPELLCAST_SUCCEEDED','player','cast-guid',effect)
 Poison(target-16,1800,spells[effect].iconID,1000+effect)
 FireEvent('WEAPON_ENCHANT_CHANGED');FireEvent('BAG_UPDATE_DELAYED')
end
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=create(kind,name,parent,template)
 if template=='InsecureActionButtonTemplate' then
  f.attrs={};f.template=template
  function f:RegisterForClicks(...) self.registrations={...} end
  function f:SetAttribute(k,v) assert(not testCombat and not testLockdown,'Attribute mutation during combat');self.attrs[k]=v end
  function f:GetAttribute(k) return self.attrs[k] end
  f:SetScript('OnClick',function(self,button,down)
   local edge=self:GetAttribute('useOnKeyDown');if edge==nil then edge=useOnKeyDown end
   if testLockdown or testCombat or button~='LeftButton' or down~=edge then return end
   local kind=self:GetAttribute('type1');if not kind then return end
   local id=self:GetAttribute(kind..'1')
   if kind=='item' then id=tonumber(id:match('^item:(%d+)$'));assert(id,'Item binding must use native item identifier') end
   NativeApply(kind,id,self:GetAttribute('target-slot1'))
  end)
  local set,hook=f.SetScript,f.HookScript
  function f:SetScript(event,...) assert(event~='OnClick','Native OnClick replaced');return set(self,event,...) end
  function f:HookScript(event,...) assert(event~='OnClick','Native OnClick hooked');return hook(self,event,...) end
 end
 return f
end
function Click(b)
 local parent=b
 while parent do if not parent:IsShown() then return end;parent=parent:GetParent() end
 if b.mouse==false then return end
 if b.template~='InsecureActionButtonTemplate' then if b.scripts.OnClick then b.scripts.OnClick(b,'LeftButton',false) end;return end
 for _,down in ipairs({true,false}) do
  if b.scripts.PreClick then b.scripts.PreClick(b,'LeftButton',down) end
  if b.scripts.OnClick then b.scripts.OnClick(b,'LeftButton',down) end
 end
end
'''
