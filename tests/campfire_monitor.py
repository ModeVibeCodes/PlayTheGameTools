"""Campfire aura/tooltip/lifecycle fixtures; not native rendering acceptance."""
from smoke import load

FIXTURE=r'''
C=addon.CampfireMonitor;M=addon.LootSparkles
function Plain(text) return (text or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','') end
function ShownText(frame)
 local lines={}
 for _,key in ipairs({'caption','buffTitle','buffTimer','text','details'}) do
  local label=frame[key];if label and label:IsShown() then lines[#lines+1]=Plain(label:GetText()) end
 end
 return table.concat(lines,'\n')
end
auras={};auraReads=0;tooltipReads=0
C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
 assert(unit=='player' and filter=='HELPFUL');auraReads=auraReads+1
 if rejectAura then error('restricted aura') end
 return auras[index]
end}
tips={
 [101]={lines={{leftText='Campfire Nearby'},{leftText='A campfire is close.'}}},
 [102]={lines={{leftText='Camp Benefits'},
  {leftText='First Aid Kit: +12 Stamina\nIncense Candle: +4 Intellect'},
  {leftText={secret=true}}, {leftText='First Aid Kit: +12 Stamina'}, {rightText='Native extra detail'}}},
}
C_TooltipInfo={GetUnitBuffByAuraInstanceID=function(unit,id)
 assert(unit=='player');tooltipReads=tooltipReads+1;return tips[id]
end}
'''

lua,_=load(before=FIXTURE)
lua.execute(r'''
assert(not C.active and not C.db.enabled and not C.frame and not next(C.events.events))
assert(M.db.sparklesEnabled==true,'preserve existing sparkle enable semantics')
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
local page=M.page
assert(#page.sections==2 and page.sectionTabs and #page.sectionTabs.buttons==2)
assert(page.sections[1].title=='Loot Sparkles' and page.sections[2].title=='Campfire Monitor')
page.sectionTabs.buttons[2].scripts.OnClick()
assert(page.selectedSection==page.sections[2] and page.campfireControls.enabled.frame:IsShown())
assert(page.sparkleControls.sparklesEnabled.row==nil) -- cell stays a toggle grid, not another navigation page
assert(C:SetOption('enabled',true) and not C.active,'master still off')
addon:SetModuleEnabled('lootSparkles',true)
assert(C.active and C.snapshot.known and not C.snapshot.nearby and not C.frame:IsShown())
assert(C.events.events.UNIT_AURA and C.events.unitEvents.UNIT_AURA[1]=='player')
local read=auraReads;FireEvent('UNIT_AURA','target');assert(auraReads==read)
auras={{spellId=C.NEARBY,auraInstanceID=101,icon=135805},
 {spellId=C.BENEFITS,auraInstanceID=102}, {spellId=C.WELCOMING,auraInstanceID=103}}
FireEvent('UNIT_AURA','player')
assert(C.frame:IsShown() and C.snapshot.nearby and C.snapshot.complete)
assert(ShownText(C.frame):find('Campfire Nearby',1,true))
assert(ShownText(C.frame):find('12 Stamina',1,true))
assert(ShownText(C.frame):find('12 Stamina',1,true))
local _,count=ShownText(C.frame):gsub('12 Stamina','');assert(count==1,'deduplicate native lines')
assert(not ShownText(C.frame):find('secret',1,true))
assert(C:SetOption('showNearbyDetails',true) and ShownText(C.frame):find('A campfire is close.',1,true))
assert(C:SetOption('showProfessionGuide',true) and #C.professions==12)
assert(ShownText(C.frame):find('Profession guide (possible features)',1,true))
assert(C:SetOption('showIcon',false) and not C.frame.icon:IsShown())
assert(C:SetOption('showText',false));assert(ShownText(C.frame):find('Campfire Nearby',1,true),'text fallback when icon off')
assert(C:SetOption('showIcon',true));assert(C.frame.icon:IsShown())
assert(C:SetOption('width',400) and C:SetOption('fontSize',18) and C:SetOption('opacity',50))
assert(C.frame:GetWidth()==400 and C.frame:GetAlpha()==0.5)
assert(C:SetOption('textColor',{0.2,0.7,1}))
assert(not C:SetOption('textColor',{1,{secret=true},0}))
assert(not C:SetOption('width',-1) and not C:SetOption('fontSize',0/0))
assert(not C:SetOption('enabled',1) and not C:SetOption('unknown',true))
assert(M:SetOption('sparklesEnabled',false) and C.active,'independent tab switch')
assert(not M.running)
assert(C:SetOption('enabled',false) and not C.frame:IsShown() and not next(C.events.events))
assert(M:SetOption('sparklesEnabled',true) and M.active)
assert(C:SetOption('enabled',true))
auras={{spellId=C.BENEFITS,auraInstanceID=102}}
FireEvent('UNIT_AURA','player')
assert(not C.snapshot.nearby and C.frame:IsShown(),'joined earned buffs remain visible without claiming nearby fire')
assert(C:SetOption('alwaysShow',true) and C:SetOption('showText',true))
assert(C.frame:IsShown() and ShownText(C.frame):find('No Nearby Campfire',1,true))
assert(ShownText(C.frame):find('12 Stamina',1,true),'earned buffs remain separate from the nearby status')
auras={{secret=true}};FireEvent('UNIT_AURA','player')
assert(not C.snapshot.known and not C.snapshot.nearby)
assert(ShownText(C.frame):find('Campfire Status Unavailable',1,true))
assert(not ShownText(C.frame):find('No Camp Benefits detected',1,true))
auras={{spellId=C.NEARBY,auraInstanceID=101},{spellId={secret=true}}};FireEvent('UNIT_AURA','player')
assert(C.snapshot.nearby and not C.snapshot.complete)
assert(C:BuildBenefitsText():find('Camp Benefits unavailable.',1,true),'partial scan does not prove benefit absence')
rejectAura=true;FireEvent('UNIT_AURA','player');assert(not C.snapshot.nearby and not C.snapshot.known)
rejectAura=nil
auras={{spellId=C.NEARBY,auraInstanceID=101}};FireEvent('UNIT_AURA','player')
read=auraReads;testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
assert(not C.frame:IsShown() and auraReads==read,'combat defaults to no aura reads')
C:Render();assert(not C.frame:IsShown(),'font refresh cannot bypass combat visibility')
assert(not C:SetOption('showInCombat',true))
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED');assert(C.frame:IsShown())
assert(C:SetOption('showInCombat',true))
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED');assert(C.frame:IsShown())
rejectAura=true;FireEvent('UNIT_AURA','player')
assert(not C.snapshot.nearby and ShownText(C.frame):lower():find('unavailable',1,true))
testCombat=false;testLockdown=false;rejectAura=nil;FireEvent('PLAYER_REGEN_ENABLED')
assert(C:SetOption('locked',false))
C.frame.centerX=540;C.frame.centerY=420
C.frame.scripts.OnDragStart();assert(C.frame.moving)
C.frame.scripts.OnDragStop();assert(not C.frame.moving and C.db.x==40 and C.db.y==20)
page.campfireReset.scripts.OnClick();assert(C.db.x==0 and C.db.y==-240)
assert(C:SetOption('locked',true))
assert(C:TogglePreview() and C.previewing and ShownText(C.frame):find('Preview:',1,true))
page.campfireRefresh.scripts.OnClick();assert(not C.previewing,'Refresh Status returns to native data')
C:TogglePreview()
page:SelectSectionTab(1);assert(not C.previewing,'tab navigation ends preview')
page:SelectSectionTab(2);C:TogglePreview();page:Hide();assert(not C.previewing,'closing page ends preview')
addon:SetModuleEnabled('lootSparkles',false)
assert(not C.active and not C.frame:IsShown() and not next(C.events.events))
assert(C:TogglePreview() and not C.active and C.frame:IsShown(),'explicit preview works with master off')
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
assert(not C.previewing and not C.frame:IsShown(),'combat cancels synthetic preview')
testCombat=false;testLockdown=false
assert(not C.events.scripts.OnUpdate,'no campfire polling')
''')

state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE)
restored.execute('''
assert(C.db.enabled and C.db.width==400 and C.db.fontSize==18 and C.db.opacity==50)
assert(C.db.textColor[2]==0.7 and not C.active)
assert(M.db.sparklesEnabled and not M.enabled)
addon:SetModuleEnabled('lootSparkles',true);assert(C.active)
local candidate=addon.ProfileCodec.Copy(addon.db);candidate.modules.lootSparkles.campfire.width=2
assert(not addon.ProfileValidation:Validate(candidate))
C_UnitAuras=nil;C:Refresh();assert(not C.snapshot.known)
''')

# Index fallback, missing details and complete scan/truncation boundaries.
fallback,_=load(before=FIXTURE)
fallback.execute('''
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
C_TooltipInfo={GetUnitAura=function(unit,index,filter)
 assert(unit=='player' and filter=='HELPFUL');return tips[102]
end}
auras={{spellId=C.NEARBY},{spellId=C.BENEFITS}}
C:Refresh();assert(ShownText(C.frame):find('12 Stamina',1,true))
C_TooltipInfo=nil;C:Refresh();assert(ShownText(C.frame):find('Native benefit details unavailable.',1,true))
C_UnitAuras.GetAuraDataByIndex=function() return {spellId=7} end
C:Refresh();assert(not C.snapshot.known,'bounded scan cannot prove absence without terminator')
''')
print('PASS Campfire Monitor tabs, independent switches, native proximity/earned details, unknown and secret data, combat, preview, position, persistence and profile validation (mock only)')
