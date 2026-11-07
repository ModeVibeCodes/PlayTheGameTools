"""Shared Edit Mode, native timing, gradients and centered campfire layout."""
from campfire_monitor import FIXTURE
from smoke import load

lua,_=load(before=FIXTURE)
lua.execute(r'''
tips[102]={lines={{leftText='Camp Benefits'},
 {leftText='Camp Chair: 2% increased critical strike chance.'},
 {leftText='Incense Candle: Intellect increased by 4.'},
 {leftText='Fish Bowl: All stats increased by 8%.'},
 {leftText='Spell ID: 1229741'},
 {leftText='Spell ID:',rightText='999999'},
 {leftText='|cffff0000Spell ID:|r',rightText='777777'},
 {leftText='Stamina +12 (Spell ID: 1230124)'},
}}
auras={{spellId=C.NEARBY,auraInstanceID=101,icon=135805},
 {spellId=C.BENEFITS,auraInstanceID=102,duration=3600,expirationTime=testClock+3600}}
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
assert(C.active and addon.PositionManager.elements.campfireMonitor)
assert(Plain(C.frame.buffTitle:GetText())=='Camp Buffs')
assert(Plain(C.frame.buffTimer:GetText())=='1:00:00 remaining')
assert(C.frame.buffTitle:GetText():find('|cffff941fC',1,true),'orange gradient begins title')
assert(C.frame.buffTitle:GetText():find('|cffff1f14s|r',1,true),'red gradient ends title')
assert(C.frame.buffTimer:GetText():find('|cffffffff',1,true),'timer gradient begins white')
assert(C.frame.text:GetText():find('|cffff40402% Crit|r',1,true),'Crit red')
assert(C.frame.text:GetText():find('|cff408cff4 Int|r',1,true),'Int blue')
assert(C:BuffColor('8% Stats')[3]~=C:BuffColor('12 Stamina')[3],'other stats distinct')
assert(not ShownText(C.frame):find('Spell ID',1,true) and not ShownText(C.frame):find('999999',1,true) and not ShownText(C.frame):find('777777',1,true))
assert(Plain(C.frame.text:GetText()):find('12 Stamina',1,true),'inline ID removed without losing amount')
assert(C.frame.icon.anchor[1]=='TOP' and C.frame.icon.anchor[2]==C.frame and C.frame.icon.anchor[4]==0)
assert(C.frame.caption.justifyH=='CENTER' and Plain(C.frame.caption:GetText())=='Campfire Nearby')
assert(C.frame.caption.anchor[3]<C.frame.icon.anchor[5],'status is below centered icon')
local start=C:Remaining()
testClock=testClock+1;C.timerDriver.scripts.OnUpdate(C.timerDriver,1)
assert(C:Remaining()==start-1 and Plain(C.frame.buffTimer:GetText())=='59:59 remaining')
assert(C:TimerColor(601)[2]==1 and C:TimerColor(600)[2]==0.85)
assert(C:TimerColor(121)[2]==0.85 and C:TimerColor(120)[2]==0.22)
testClock=auras[2].expirationTime-600;C:UpdateTimerText()
assert(C.frame.buffTimer:GetText():find('|cffffd926',1,true),'yellow countdown gradient endpoint')
testClock=auras[2].expirationTime-120;C:UpdateTimerText()
assert(C.frame.buffTimer:GetText():find('|cffff3829',1,true),'red countdown gradient endpoint')
assert(C:SetOption('timerWarningMinutes',5) and C:SetOption('timerCriticalMinutes',1))
assert(not C:SetOption('timerCriticalMinutes',5),'critical threshold stays below warning')
C:SetOption('separateBenefits',true)
local pm=addon.PositionManager
assert(pm.elements.campfireBuffs and pm.elements.campfireBuffs.label=='Camp Buffs')
assert(C.benefitsFrame.buffTitle:IsShown() and not C.benefitsFrame.icon:IsShown())
assert(pm.elements.campfireMonitor.editMode and pm.elements.campfireBuffs.editMode)
addon:SetEditMode(true)
assert(C.editing and C.frame:IsShown() and C.benefitsFrame:IsShown())
assert(pm.elements.campfireMonitor.decoration.handle:IsShown() and pm.elements.campfireBuffs.decoration.handle:IsShown())
assert(pm:SelectElement('campfireBuffs') and addon.EditMode:Selected().id=='campfireBuffs')
assert(addon.EditMode:SetCoordinate('x',150) and C.db.benefitsX==150)
assert(pm:SetOffsets('campfireMonitor',-100,50) and C.db.x==-100 and C.db.y==50)
C.benefitsFrame.centerX=650;C.benefitsFrame.centerY=430
assert(pm:StartDragging('campfireBuffs'))
local anchor=C.benefitsFrame.anchor
FireEvent('UNIT_AURA','player');assert(C.benefitsFrame.anchor==anchor,'no reanchor during Edit Mode drag')
pm:StopDragging('campfireBuffs')
assert(C.db.benefitsX==150 and C.db.benefitsY==30)
assert(C.benefitsFrame:GetScript('OnUpdate')==nil,'timer never occupies manager drag update slot')
addon:SetEditMode(false);assert(not C.editing)
C:SetOption('separateBenefits',false)
assert(not pm.elements.campfireBuffs.editMode and not C.benefitsFrame:IsShown())
addon:SetEditMode(true)
assert(not pm:SelectElement('campfireBuffs'),'joined mode has no ghost buff element')
addon:SetEditMode(false)
-- Hidden/unknown native timing is not a fresh one-hour countdown.
auras[2].duration={secret=true};auras[2].expirationTime={secret=true};C:Refresh()
assert(C:Remaining()==nil and Plain(C.frame.buffTimer:GetText())=='Time unavailable')
assert(not C.timerDriver:GetScript('OnUpdate'))
assert(C:SetOption('compactBenefits',false))
assert(not ShownText(C.frame):find('Spell ID',1,true),'full native-text mode also removes IDs')
auras={{spellId=C.BENEFITS,auraInstanceID=102,duration=3600,expirationTime=testClock+300}}
C:Refresh();assert(Plain(C.frame.caption:GetText())=='No Nearby Campfire')
assert(not ShownText(C.frame):find('yards',1,true) and C.frame.arrow==nil,'no fabricated position/navigation')
auras={};C:Refresh();assert(not C.frame:IsShown())
addon:SetEditMode(true)
assert(C.frame:IsShown() and Plain(C.frame.buffTimer:GetText()):find('Preview:',1,true),'no-aura edit sample is labeled')
addon:SetEditMode(false);assert(not C.frame:IsShown())
addon:SetModuleEnabled('lootSparkles',false)
assert(not pm.elements.campfireMonitor.editMode and not C.timerDriver:GetScript('OnUpdate'))
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE)
restored.execute('''
assert(not C.frame)
assert(C:SetOption('x',25),'offset editing before a runtime element exists')
addon:SetModuleEnabled('lootSparkles',true)
assert(addon.PositionManager:GetPosition('campfireMonitor').x==25)
assert(C.db.x==25 and C.db.y==50)
assert(C.db.timerWarningMinutes==5 and C.db.timerCriticalMinutes==1)
assert(not C.editing,'edit state not persisted')
''')
print('PASS shared Edit Mode handles/coordinates/dragging/persistence, timer boundaries/gradients, secret timing, colored stats, spell-ID filtering and centered status-only icon (mock only)')
