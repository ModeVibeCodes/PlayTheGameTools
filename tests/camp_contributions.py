"""Camp contribution inventory/readiness gates and native-template click intent."""
from campfire_monitor import FIXTURE
from smoke import load

EXTRA=r'''
A=addon.CampContributions
bagReads=0;macroCalls={};timers={};requests={}
C_Timer.After=function(delay,callback) timers[#timers+1]={delay=delay,callback=callback} end
Constants={InventoryConstants={NumBagSlots=0,NumReagentBagSlots=0}}
function GetProfessions() return 11,nil,12,nil,14 end
function GetProfessionInfo(index)
 if index==11 then return 'Alchemy',135805,300,300,1,0,171 end
 if index==12 then return 'First Aid',135805,300,300,1,0,129 end
 if index==14 then return 'Cooking',135805,300,300,1,0,185 end
end
bag={
 {itemID=279956,stackCount=2,isLocked=false},
 {itemID=279956,stackCount=3,isLocked=false},
 {itemID=279968,stackCount=1,isLocked=false},
 {itemID=279962,stackCount=1,isLocked=false},
 {itemID=279981,stackCount=1,isLocked=false},
 {itemID=123,stackCount=1,isLocked=false},
 {itemID=279970,stackCount=1,isLocked=false,start=100,duration=3600},
}
names={[279956]='Mana Well',[279968]='First Aid Kit',[279962]='Incense Candle',
 [279981]='Basic Campfire Kit',[123]='Unrelated Item',[279970]='Fermenter'}
unusable={}
C_Container={
 GetContainerNumSlots=function(b) assert(b==0 and not testCombat);bagReads=bagReads+1;return #bag end,
 GetContainerItemInfo=function(b,s) assert(b==0 and not testCombat);return bag[s] end,
 GetContainerItemCooldown=function(b,s)
  assert(b==0 and not testCombat);local item=bag[s]
  return item.start or 0,item.duration or 0,item.cooldownEnabled or 1
 end,
}
C_Item={
 IsUsableItem=function(id) assert(not testCombat);if unusable[id] then return unusable[id] end;return true,false end,
 GetItemNameByID=function(id) return names[id] end,
 GetItemInfoInstant=function(id) return id,'Consumable','Other','',135805,0,8 end,
 RequestLoadItemDataByID=function(id) requests[#requests+1]=id end,
}
C_Macro={RunMacroText=function(text) macroCalls[#macroCalls+1]=text end}
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=create(kind,name,parent,template)
 if template=='InsecureActionButtonTemplate' then
  if rejectTemplate then f.protected=true end
  f.nativeClick=function(button,key,down)
   -- Bounded model of native OOC gating and a user up-click, not WoW proof.
   if testLockdown or testCombat or down then return end
   if button:GetAttribute('type1')=='macro' then C_Macro.RunMacroText(button:GetAttribute('macrotext1')) end
  end
  f:SetScript('OnClick',f.nativeClick)
  f.attributes={}
  function f:SetAttribute(key,value)
   assert(not testLockdown and not testCombat,'no combat item-attribute writes')
   self.attributes[key]=value
  end
  function f:GetAttribute(key) return self.attributes[key] end
 end
 return f
end
'''
lua,_=load(before=FIXTURE+EXTRA)
lua.execute(r'''
assert(not A.active and not A.window and bagReads==0 and #macroCalls==0)
local count,professions=0,{}
for id,profession in pairs(A.catalog) do count=count+1;professions[profession]=true end
assert(count==36 and not A.catalog[279981] and not A.catalog[279961] and not A.catalog[279974])
local n=0;for _ in pairs(professions) do n=n+1 end;assert(n==12)
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
assert(A.active and not A.window and bagReads==0,'no bag scan before proximity')
auras={{spellId=C.NEARBY,auraInstanceID=101}};FireEvent('UNIT_AURA','player')
assert(#A.items==2 and A.window:IsShown() and #macroCalls==0)
assert(A.items[1].id==279956 and A.items[1].count==5 and A.items[2].id==279968)
local reads=bagReads;FireEvent('UNIT_AURA','player');assert(bagReads==reads,'cached bag scan')
local b=A.buttons[1]
assert(b:GetScript('OnClick')==b.nativeClick and not (b.scriptHooks and b.scriptHooks.OnClick))
assert(b:GetAttribute('macrotext1')=='/stopmacro [combat]\n/use [nocombat] item:279956')
b.nativeClick(b,'LeftButton',true);b.nativeClick(b,'LeftButton',false)
assert(#macroCalls==1,'only modeled hardware click dispatches')
assert(not macroCalls[1]:find('@cursor',1,true) and not macroCalls[1]:find('@player',1,true))
A:Dismiss();assert(A.dismissed and not A.window:IsShown() and b:GetAttribute('type1')==nil)
FireEvent('BAG_UPDATE_DELAYED');assert(not A.window:IsShown())
rejectAura=true;FireEvent('UNIT_AURA','player');rejectAura=nil
FireEvent('UNIT_AURA','player');assert(A.dismissed and not A.window:IsShown(),'unknown is not reentry')
assert(A:Open() and A.window:IsShown())
auras={};FireEvent('UNIT_AURA','player');assert(not A.window:IsShown() and not A.dismissed)
auras={{spellId=C.NEARBY,auraInstanceID=101}};FireEvent('UNIT_AURA','player')
assert(A.window:IsShown(),'fresh visit rearms')
bag[1].isLocked=true;bag[2].isLocked={secret=true};unusable[279968]={secret=true}
FireEvent('ITEM_LOCK_CHANGED',0,1);assert(#A.items==0 and not A.window:IsShown())
bag[1].isLocked=false;bag[2].isLocked=false;unusable[279968]=nil
FireEvent('BAG_UPDATE_DELAYED');assert(A.window:IsShown())
local old=bagReads
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED');assert(not A.window:IsShown())
FireEvent('BAG_UPDATE_DELAYED');assert(bagReads==old)
b.nativeClick(b,'LeftButton',false);assert(#macroCalls==1,'combat blocks action')
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED');assert(A.window:IsShown())
C:TogglePreview();assert(not A.window:IsShown(),'preview never authorizes actions')
C:StopPreview();assert(A.window:IsShown())
addon:SetEditMode(true);assert(not A.window:IsShown(),'Edit Mode hides actions')
addon:SetEditMode(false);assert(A.window:IsShown())
bag={{itemID=279970,stackCount=1,isLocked=false,start=testClock,duration=60}}
FireEvent('BAG_UPDATE_COOLDOWN');assert(#A.items==0 and not A.window:IsShown())
local wake=timers[#timers];assert(wake.delay==60.1)
testClock=testClock+61;wake.callback()
assert(#A.items==1 and A.items[1].id==279970 and A.window:IsShown() and #macroCalls==1)
assert(A.buttons[2]:GetAttribute('type1')==nil,'old rows cleared')
names[279970]=nil;FireEvent('BAG_UPDATE_DELAYED')
assert(#A.items==0 and not A.window:IsShown() and requests[1]==279970)
names[279970]='Fermenter';FireEvent('ITEM_DATA_LOAD_RESULT',279970,true);assert(A.window:IsShown())
local saved=GetProfessionInfo
GetProfessionInfo=function(index) if index==11 then return 'Herbalism',135805,300,300,1,0,182 end;return saved(index) end
FireEvent('SKILL_LINES_CHANGED');assert(#A.items==0 and not A.window:IsShown(),'profession loss')
GetProfessionInfo=saved;FireEvent('SKILL_LINES_CHANGED');assert(A.window:IsShown())
A.window.centerX=550;A.window.centerY=450
A.window.header.scripts.OnDragStart();assert(A.window.dragging)
local anchor=A.window.anchor;FireEvent('BAG_UPDATE_DELAYED');assert(A.window.anchor==anchor)
A.window.header.scripts.OnDragStop();assert(C.db.contributionX==50 and C.db.contributionY==50)
C:SetOption('showContributionPopup',false)
assert(C.active and not A.active and not next(A.events.events) and not A.window:IsShown())
C:SetOption('showContributionPopup',true);assert(A.active and A.window:IsShown())
addon:SetModuleEnabled('lootSparkles',false)
local before=bagReads
for _,timer in ipairs(timers) do if timer.delay>=60 then timer.callback() end end
assert(not A.active and not A.window:IsShown() and bagReads==before and #macroCalls==1)
assert(not A.events.scripts.OnUpdate,'no inventory polling')
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE+EXTRA)
restored.execute('assert(C.db.contributionX==50 and C.db.contributionY==50 and not A.active)')
denied,_=load(before=FIXTURE+EXTRA)
denied.execute('''
rejectTemplate=true
auras={{spellId=C.NEARBY,auraInstanceID=101}}
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
assert(A.blocked and not A.window:IsShown() and #macroCalls==0)
''')
print('PASS camp contribution profession/bag/readiness filters, native-template click intent, cache/cooldown wake, dismissal/rearm, metadata, combat, preview/Edit Mode, persistence and template rejection (mock only)')
