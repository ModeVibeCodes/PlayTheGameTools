"""Camp Buffs native-only duration and shared Edit Mode behavior (mock only)."""
from campfire_monitor import FIXTURE
from smoke import load

lua,_=load(before=FIXTURE)
lua.execute(r'''
tips[102]={lines={{leftText='Camp Benefits'},
 {leftText='You have gained the following camp benefits:'},
 {leftText='Camp Chair: 2% increased critical strike chance.'},
 {leftText='Incense Candle: Intellect increased by 4.'},
 {leftText='Fish Bowl: All stats increased by 8%.'},
 {leftText='Spell ID: 1229741'},
 {leftText='Spell ID:',rightText='999999'},
 {leftText='Stamina +12 (Spell ID: 1230124)'},
 {leftText='2 hours remaining'},
 {leftText='Mana Well: Regenerate 29 Mana every 5 sec'},
}}
auras={{spellId=C.NEARBY,auraInstanceID=101,icon=135805},
 {spellId=C.BENEFITS,auraInstanceID=102,duration=3600,expirationTime=testClock+3600}}
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
local pm=addon.PositionManager
assert(C.active and pm.elements.campfireMonitor)
assert(Plain(C.frame.buffTitle:GetText())=='Camp Buffs')
assert(C.frame.buffTimer==nil and C.timerDriver==nil and C.TimerLabel==nil,'no custom timer or update driver')
local _,count=ShownText(C.frame):gsub('remaining','');assert(count==1,'native tooltip duration appears once')
assert(Plain(C.frame.text:GetText()):find('2 hours remaining',1,true))
assert(not Plain(C.frame.text:GetText()):find('gained',1,true),'native intro removed')
assert(not ShownText(C.frame):find('Spell ID',1,true) and not ShownText(C.frame):find('999999',1,true))
assert(Plain(C.frame.text:GetText()):find('12 Stamina',1,true))
assert(Plain(C.frame.text:GetText()):find('29 Mana / 5 sec',1,true),'periodic stat preserved')
assert(C.frame.text:GetText():find('|cffff40402% Crit|r',1,true))
assert(C.frame.text:GetText():find('|cff408cff4 Int|r',1,true))
assert(C:SetOption('headerGradient',true))
assert(C.frame.buffTitle:GetText():find('|r|cff',1,true))
assert(C.frame.icon.anchor[1]=='TOP' and C.frame.caption.justifyH=='CENTER')
assert(C:SetOption('benefitsFontSize',18))
assert(C.frame.text.font[2]==18,'buff font size applies in joined mode')
C:SetOption('separateBenefits',true)
assert(C.benefitsFrame.buffTimer==nil and C.benefitsFrame.buffTitle:IsShown())
local _,n=ShownText(C.benefitsFrame):gsub('remaining','');assert(n==1)
addon:SetEditMode(true)
assert(C.editing and C.frame:IsShown() and C.benefitsFrame:IsShown())
assert(pm.elements.campfireBuffs.decoration.handle:IsShown())
assert(pm:SelectElement('campfireBuffs'))
assert(addon.EditMode:SetCoordinate('x',150) and C.db.benefitsX==150)
assert(pm:SetOffsets('campfireMonitor',-100,50))
C.benefitsFrame.centerX=650;C.benefitsFrame.centerY=430
assert(pm:StartDragging('campfireBuffs'))
local anchor=C.benefitsFrame.anchor;FireEvent('UNIT_AURA','player')
assert(C.benefitsFrame.anchor==anchor)
pm:StopDragging('campfireBuffs');assert(C.db.benefitsX==150 and C.db.benefitsY==30)
addon:SetEditMode(false);C:SetOption('separateBenefits',false)
assert(not pm.elements.campfireBuffs.editMode and not C.benefitsFrame:IsShown())
C:SetOption('compactBenefits',false)
assert(not Plain(C.frame.text:GetText()):find('gained',1,true))
assert(Plain(C.frame.text:GetText()):find('2 hours remaining',1,true),'native full-text duration kept')
auras={};C:Refresh();assert(not C.frame:IsShown())
addon:SetEditMode(true)
assert(C.frame:IsShown() and C.frame.buffTimer==nil and Plain(C.frame.text:GetText()):find('2%% Crit'))
addon:SetEditMode(false);addon:SetModuleEnabled('lootSparkles',false)
assert(not pm.elements.campfireMonitor.editMode and not C.timerDriver)
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE)
restored.execute('''
assert(C.db.benefitsX==150 and C.db.benefitsY==30 and C.db.x==-100 and C.db.y==50)
assert(C.db.headerGradient and C.db.benefitsFontSize==18 and not C.timerDriver)
''')
print('PASS native-only duration in joined/detached/full text, no countdown/driver, shared Edit Mode, stat/header colors and independent buff font size (mock only)')
