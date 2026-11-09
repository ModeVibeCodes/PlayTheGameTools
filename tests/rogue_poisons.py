"""Inventory-backed native-template dispatch and independent customization mocks.
Models item actions rather than assuming poison items are learned spells.
Native action acceptance, event order and rendering still require in-game checks.
"""
from smoke import load

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
lua,_=load(before=SETUP)
lua.execute(r'''
local M=addon.ForeverRogue
assert(not M.enabled and not M.watcher and bagReads==0 and enchantReads==0)
addon:SetModuleEnabled('foreverRogue',true)
assert(#M.choices==3 and M.known[8679].kind=='item','Poisons discovered with zero learned spells')
assert(M.byKey['item:6947'].count==5 and not M.byKey['item:117'])
assert(M.watcher:IsShown() and M.watchButtons[1].timer:GetText()=='Missing')
Click(M.watchButtons[1]);assert(#applications==0 and M.lastMessage:find('No last%-used'),'Inert selection explains itself')
assert(M:SetOption('quickApply','item:6947'));Click(M.watchButtons[1])
assert(#applications==1 and applications[1].kind=='item' and applications[1].id==6947 and applications[1].target==16)
assert(not M.watchButtons[1]:IsShown() and M:History().main=='item:6947','Exact item recorded only after successful native observation')
M:SetOption('quickApply','last');Click(M.watchButtons[2])
assert(#applications==2 and applications[2].target==17 and M:History().off=='item:6947','Missing other hand uses last observed poison')
assert(not M.watcher:IsShown())
M:SetOption('flyout',true);assert(not M.launcher:IsShown(),'Healthy weapons hide launcher by default')
assert(M.openButton.icon.texture==306 and M.db.launcherStyle.borderColor[1]==0.72)
Poison(0,300);M.ticker.callback();assert(M.launcher:IsShown() and M.watchButtons[1]:IsShown())
Poison(0,301);M.ticker.callback();assert(not M.launcher:IsShown(),'Threshold boundary is inclusive')
assert(M:SetOption('alwaysShow',true));assert(M.launcher:IsShown())
Click(M.openButton);assert(M.menu:IsShown())
local deadly
for i,p in ipairs(M.choices) do if p.id==2892 then deadly=M.menuRows[i] end end
assert(deadly);Click(deadly[2])
assert(applications[#applications].id==2892 and applications[#applications].target==17 and M:History().off=='item:2892')
M:SetOption('alwaysShow',false);assert(not M.launcher:IsShown() and not M.menu:IsShown())
-- A native/manual bag use also updates history for the changed hand.
M.attempt=nil;NativeApply('item',6949,16)
assert(M:History().main=='item:6949','Manual cast and weapon-enchant events identify exact last item')
Poison(0,299);Poison(1,299,302);M:Refresh()
assert(M.watchButtons[1].attrs.item1=='item:6949' and M.watchButtons[2].attrs.item1=='item:2892')
-- Native guard blocks before the addon has processed the combat event.
local n=#applications;testCombat=true;testLockdown=true;Click(M.watchButtons[1]);assert(#applications==n)
FireEvent('PLAYER_REGEN_DISABLED');assert(M.watcher:IsShown() and not M.launcher:IsShown() and not M.menu:IsShown())
assert(not M:SetOption('alwaysShow',true) and not M:SetStyle('watchStyle','iconSize',60))
enchants[0]={secret=true};M.ticker.callback();assert(M.watchButtons[1].timer:GetText()=='Unknown')
testCombat=false;testLockdown=false;Poison(0,301);FireEvent('PLAYER_REGEN_ENABLED')
assert(not M.watchButtons[1]:IsShown());Poison(0,299)
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED');assert(M.watchButtons[1]:IsShown(),'Threshold crossed during combat')
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
-- Watcher and flyout are independent; unlocking and preview keep use inert.
M:SetOption('watcher',false);assert(not M.watcher:IsShown() and M.launcher:IsShown())
Click(M.openButton);assert(M.menu:IsShown());n=#applications
M:SetOption('flyoutLocked',false);Click(deadly[1]);assert(#applications==n)
M:SetOption('flyoutLocked',true);M:SetOption('watcher',true);M:SetPreviewMode(true)
Click(M.watchButtons[1]);assert(#applications==n and M.menu:IsShown(),'Expanded preview is inert')
M:SetPreviewMode(false);M:SetOption('locked',false);Click(M.watchButtons[1]);assert(#applications==n)
M:SetOption('locked',true)
-- Independent geometry, colors, font, label and timer controls apply immediately.
local menuSize=M.db.flyoutStyle.iconSize
assert(M:SetStyle('watchStyle','iconSize',60) and M.db.flyoutStyle.iconSize==menuSize)
assert(M:SetStyle('watchStyle','vertical',true));assert(M.watcher:GetHeight()>M.watcher:GetWidth())
assert(M:SetStyle('watchStyle','showHands',false) and not M.watchButtons[1].caption:IsShown())
assert(M:SetStyle('watchStyle','timerPosition','TOP'))
assert(M:SetStyle('flyoutStyle','columns',2) and M:SetOption('visibleRows',1))
assert(M:SetStyle('launcherStyle','borderColor',{0.1,0.2,0.3}))
assert(not M:SetStyle('watchStyle','iconSize',999) and not M:SetOption('direction','BAD'))
assert(not M:SetStyle('watchStyle','textColor',{2,0,0}) and not M:SetOption('quickApply','arbitrary'))
addon:ToggleConfig();addon:SelectConfigPage('foreverRogue')
assert(#M.page.poisonGrid==6 and M.page.poisonStyles.flyoutStyle.showNames and M.page.quickVisibility)
-- No idle bag scan; ticker only reads each weapon once.
local reads=bagReads;local ench=enchantReads;M.ticker.callback();assert(bagReads==reads and enchantReads==ench+2)
local ticker=M.ticker;addon:SetModuleEnabled('foreverRogue',false)
assert(ticker.cancelled and not M.watcher:IsShown() and not M.menu:IsShown())
''')
saved=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded=saved,before=SETUP)
restored.execute(r'''
local M=addon.ForeverRogue
assert(M.db.watchStyle.iconSize==60 and M.db.flyoutStyle.columns==2 and M.db.launcherStyle.borderColor[2]==0.2)
assert(M.db.history['Rogue-A'].main=='item:6949' and not M.enabled)
playerGUID='Rogue-B';addon:SetModuleEnabled('foreverRogue',true)
assert(not M:History(),'Last-used history is character-specific')
''')
edge,_=load(before=SETUP)
edge.execute(r'''
local M=addon.ForeverRogue;addon:SetModuleEnabled('foreverRogue',true)
M:SetOption('quickApply','item:6947');acceptApplications=false;Click(M.watchButtons[1])
assert(not M:History(),'Rejected click must not become last-used poison')
acceptApplications=true
for _,edge in ipairs({true,false}) do
 useOnKeyDown=edge;enchants[0]={};M:Refresh();local n=#applications;Click(M.watchButtons[1]);assert(#applications==n+1)
end
-- Last carried dose disappearing during the action must still be remembered.
M:SetOption('quickApply','item:6949');enchants[0]={};bags[0][2].stackCount=1;M:Refresh();Click(M.watchButtons[1])
assert(M:History().main=='item:6949')
bags[0][2].itemID=117;M:Refresh();M:SetOption('quickApply','last');enchants[0]={};M:Refresh()
assert(M.watchButtons[1].attrs.type1==nil,'Unavailable remembered poison cannot apply')
-- Bag moves trigger fresh item-ID bindings rather than stale bag/slot locations.
bags[0][1],bags[1][1]=bags[1][1],bags[0][1];FireEvent('BAG_UPDATE_DELAYED')
assert(M.byKey['item:6947'] and M.byKey['item:2892'])
-- Metadata/cache readiness, locked stacks, secret entries and empty weapons.
bags[1][1].isLocked=true;M:SetOption('quickApply','item:6947');M:Refresh()
assert(M.byKey['item:6947'].count==0 and not M.watchButtons[1].action)
bags[1][1].isLocked=false;missingMetadata[6947]=true;M:Refresh();assert(requested[6947]==1)
M:Refresh();assert(requested[6947]==1,'Metadata request is bounded')
missingMetadata[6947]=nil;FireEvent('ITEM_DATA_LOAD_RESULT',6947,true);assert(M.byKey['item:6947'])
enchants[0]={{secret=true}};M:Refresh();assert(M.watchButtons[1].timer:GetText()=='Unknown' and not M.watchButtons[1].action)
weaponIDs[17]=nil;M:Refresh();assert(not M.watchButtons[2]:IsShown())
weaponClass=4;M:Refresh();assert(not M.watchButtons[1]:IsShown())
''')
legacy,_=load(before=SETUP+r'''
local db=PTGToolsDB -- settings are initialized by ADDON_LOADED below
''')
legacy.execute(r'''
local M=addon.ForeverRogue;local old={iconSize=52,fontSize=16,scale=125,opacity=80,locked=false,mainPoison=2823,custom='keep'}
M.Initialize(old);assert(old.watchStyle.iconSize==52 and old.watchStyle.fontSize==16 and old.watchStyle.scale==125 and old.custom=='keep' and not old.locked)
learned[2823]=true;addon:SetModuleEnabled('foreverRogue',true);assert(M.byKey['spell:2823'])
''')
other,_=load(before=SETUP+"\nfunction UnitClass() return 'Warrior','WARRIOR',1 end")
other.execute("addon:SetModuleEnabled('foreverRogue',true);assert(not addon.ForeverRogue.watcher and enchantReads==0 and bagReads==0)")
print('PASS Rogue poisons: real item identifiers without learned spells, native click edges/hand slots, confirmed last-use, inventory/cache/lock states, threshold launcher, independent styles, combat/preview, migration and persistence')
