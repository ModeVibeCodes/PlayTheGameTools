"""Layout's Style card: the same Scale, Opacity, Text size and Background for every
display, validated storage in the display's position record, generic Scale and
Opacity, each display's Text size/Background hook, Reset, combat deferral,
persistence and profile export (mock only; not native rendering acceptance)."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from rogue_poisons import SETUP
from smoke import load

COMMON = r'''
PM,P=addon.PositionManager,addon.Positioning
function Click(button) button:GetScript('OnClick')(button) end
function Size(text) local _,size=text:GetFont();return size end
function Near(a,b) return math.abs(a-b)<0.0001 end
'''

lua, _ = load(before=FIXTURE + EXTRA)
lua.execute(COMMON + r'''
for _,id in ipairs({'combatTimer','threatMeter','enhancedExperienceBar','foreverQuickAccess','lootSparkles'}) do addon:SetModuleEnabled(id,true) end
C:SetOption('enabled',true);C:SetOption('alwaysShow',true)
local F=addon.ForeverFoodBar;F:SetOption('enabled',true);F:SetOption('shown',true)
addon:ToggleConfig()
local T,TM,X,Q=addon.modules.combatTimer,addon.ThreatMeter,addon.EnhancedExperienceBar,addon.ForeverQuickAccess

-- The old per-display styling rows stay off settings pages and out of search
-- (a later pass removes them); Layout no longer borrows them either.
for _,id in ipairs({'combatTimer','enhancedExperienceBar','foreverQuickAccess','lootSparkles'}) do
 local page=addon:EnsureConfigPage(id)
 for _,row in ipairs(page.rows) do
  if row.editAppearance then assert(not row:IsShown() and not row.editBorrowed,'styling row shown on '..id) end
 end
end
for _,query in ipairs({'Font Size','Background opacity','Frame scale','Bar Texture'}) do
 for _,result in ipairs(addon:SearchSettings(query)) do
  local entry=result.entry
  if entry then
   local row=entry.row
   assert(not row.editAppearance,'search offers a removed styling row: '..result.label)
  end
 end
end

-- Nothing is styled until the card is used: no saved style record, frames untouched.
for id in pairs(PM.elements) do assert(PM.elements[id].position.style==nil,'no style saved for '..id) end
assert(not PM:SetStyle('combatTimer','scale',150),'the card is Layout-only')

-- One card, the same four controls, for every display.
assert(addon:SetEditMode(true))
local card=addon.editWindow.styleCard
local displays={combatTimer='Combat Timer',threatMeter='Threat Meter',enhancedExperienceBar=X.title,
 foreverQuickAccess='Profession Bar',foreverFoodBar='Food Bar',campfireMonitor='Campfire Monitor'}
for id,title in pairs(displays) do
 assert(PM.elements[id] and PM.elements[id].editMode,'in Layout: '..id)
 assert(PM:SelectElement(id) and card:IsShown() and card.title:GetText()==title,'card for '..id)
 assert(card.sliders.scale.label:GetText()=='Scale' and card.sliders.opacity.label:GetText()=='Opacity')
 assert(card.sliders.text.label:GetText()=='Text size' and card.backgroundRow.label:GetText()=='Background')
 assert(card.sliders.text.slider:IsEnabled(),'text sizes for '..id)
 assert(card.resetButton.label:GetText()=='Reset' and card.settingsButton.label:GetText()=='Settings')
 assert(card.settingsButton:IsEnabled(),'settings page for '..id)
end
assert(addon.editWindow.style==nil,'no borrowed styling column')

-- Validation: unknown keys and wrong types are refused; numbers are clamped and rounded.
assert(not PM:SetStyle('combatTimer','font',12) and not PM:SetStyle('combatTimer','scale','big'))
assert(not PM:SetStyle('combatTimer','background','no') and not PM:SetStyle('nope','scale',100))
assert(not PM:SetStyle('combatTimer','scale',0/0),'NaN refused')
assert(PM:SetStyle('combatTimer','scale',999) and PM:GetStyle('combatTimer').scale==200)
assert(PM:SetStyle('combatTimer','opacity',1) and PM:GetStyle('combatTimer').opacity==10)
assert(PM:SetStyle('combatTimer','text',87.4) and PM:GetStyle('combatTimer').text==87)
assert(PM:ResetLayout('combatTimer') and addon.db.modules.combatTimer.position.style==nil)

-- Scale and Opacity are generic: the frame is scaled and faded, its centre stays put,
-- and the display's own scale/alpha keep working underneath.
local frame=T.frame
assert(PM:SetOffsets('combatTimer',40,-100))
local x,y=P:Geometry(frame)
assert(PM:SelectElement('combatTimer'))
card.sliders.scale.slider:SetValue(150)
assert(PM:GetStyle('combatTimer').scale==150 and addon.db.modules.combatTimer.position.style.scale==150,'saved with its position')
assert(Near(frame.scale,1.5) and frame:GetScale()==1,'style multiplies; GetScale is the display\'s own')
local nx,ny=P:Geometry(frame);assert(Near(nx,x) and Near(ny,y),'centre unchanged by scaling')
local p=PM:GetPosition('combatTimer');assert(p.x==40 and p.y==-100)
T.db.appearance.scale=0.5;T:ApplyAppearance()
assert(Near(frame.scale,0.75),'module scale x style scale')
T.db.appearance.scale=1;T:ApplyAppearance()
card.sliders.opacity.slider:SetValue(50)
assert(Near(frame.alpha,0.5) and frame:GetAlpha()==1)

-- Text size and Background: Combat Timer.
card.sliders.text.slider:SetValue(150)
assert(Size(T.text)==30,'20 x 150%')
assert(card.backgroundRow.switch.selected)
Click(card.backgroundRow.switch)
assert(PM:GetStyle('combatTimer').background==false and not card.backgroundRow.switch.selected)
assert(T.background.vertexColor[4]==0,'fill cleared')
assert(T.globalBorder.borderKey:find('^none:'),'border removed')
assert(T.db.appearance.fontSize==20 and T.db.appearance.backgroundOpacity==0.4,'old settings untouched')
Click(card.backgroundRow.switch);assert(T.background.vertexColor[4]==0.4)

-- Threat Meter: every label, panel and header.
assert(PM:SetStyle('threatMeter','text',200))
assert(Size(TM.frame.title)==24 and Size(TM.frame.rows[1].nameText)==22)
assert(PM:SetStyle('threatMeter','background',false))
assert(not TM.frame.background:IsShown() and not TM.frame.header:IsShown() and not TM.frame.rule:IsShown())
assert(TM.frame.rows[1].nameText,'bars stay')
assert(PM:SetStyle('threatMeter','background',true) and TM.frame.background:IsShown() and TM.frame.header:IsShown())

-- Experience Bar: both texts; Background hides the fill and border, never the XP.
assert(PM:SetStyle(X.id,'text',150) and Size(X.text)==math.floor(X.db.fontSize*1.5+0.5))
assert(Size(X.sessionText)==math.floor(X.db.sessionFontSize*1.5+0.5))
assert(PM:SetStyle(X.id,'background',false) and not X.background:IsShown() and X.frame.borderColor[4]==0)
assert(X.xpFill:IsShown(),'the bar itself stays')
assert(PM:SetStyle(X.id,'background',true) and X.background:IsShown())

-- Profession and Food Bars.
assert(PM:SetStyle('foreverQuickAccess','background',false) and Q.bar.backdropColor[4]==0 and Q.bar.borderColor[4]==0)
assert(Q.db.backgroundOpacity>0,'saved opacity untouched')
assert(PM:SetStyle('foreverQuickAccess','scale',120) and Near(Q.bar.scale,Q.db.scale/100*1.2))
assert(PM:SetStyle('foreverFoodBar','background',false) and F.bar.backdropColor[4]==0)
assert(PM:SetStyle('foreverFoodBar','scale',80) and Near(F.bar.scale,F.db.scale/100*0.8))

-- Campfire Monitor.
local base=C.db.fontSize
assert(PM:SetStyle('campfireMonitor','text',200) and Size(C.frame.caption)==base*2)
assert(PM:SetStyle('campfireMonitor','background',false) and C.frame.backdropColor[4]==0 and C.frame.borderColor[4]==0)

-- Reset restores this display's style and default position only.
assert(PM:SetOffsets('threatMeter',11,22))
Click(card.closeButton);assert(PM:SelectElement('threatMeter'))
Click(card.resetButton)
local s=PM:GetStyle('threatMeter')
assert(s.text==100 and s.background and addon.db.positions.threatMeter.style==nil)
assert(Size(TM.frame.title)==12 and TM.frame.background:IsShown())
p=PM:GetPosition('threatMeter');assert(p.x==320 and p.y==-120,'default position')
assert(PM:GetStyle('combatTimer').scale==150,'other displays keep their style')

-- Profile export carries styles inside the positions it already exports.
assert(PM:SetStyle('threatMeter','opacity',70))
local text=addon.ProfileManager:Export(addon.ProfileManager.activeName)
local envelope=addon.ProfileCodec.Decode(text)
assert(envelope.profile.positions.threatMeter.style.opacity==70)
assert(envelope.profile.modules.combatTimer.position.style.scale==150)
local candidate=addon.ProfileManager:PrepareImport(text,'Styled Copy')
assert(candidate and candidate.positions.threatMeter.style.opacity==70,'import accepts styles')

-- Combat: a style change waits until combat ends and is then applied.
addon:SetEditMode(false)
addon.db.positions.threatMeter.style={scale=150}
testCombat=true;testLockdown=true
assert(PM:ApplyStyle('threatMeter',true)==false and Near(TM.frame.scale,1),'never rescaled in combat')
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(Near(TM.frame.scale,1.5),'applied after combat')

-- A malformed saved style reads as defaults and is left untouched.
addon.db.positions.threatMeter.style={scale='huge',opacity=-4,background='no'}
local bad=addon.db.positions.threatMeter.style
s=PM:GetStyle('threatMeter');assert(s.scale==100 and s.opacity==100 and s.text==100 and s.background==true)
assert(PM:ApplyStyle('threatMeter',true) and Near(TM.frame.scale,1) and addon.db.positions.threatMeter.style==bad)
assert(not PM:ValidateStyle(bad) and PM:ValidateStyle({scale=150,background=false}))
addon.db.positions.threatMeter.style={opacity=70}
assert(PM:ApplyStyle('threatMeter'))

-- Unregistering returns the frame to its own methods and values.
assert(PM:UnregisterElement('threatMeter'))
assert(rawget(TM.frame,'SetScale')==nil and rawget(TM.frame,'GetAlpha')==nil)
assert(Near(TM.frame:GetAlpha(),1) and Near(TM.frame:GetScale(),1))
TM:Update();assert(PM.elements.threatMeter and Near(TM.frame.alpha,0.7),'re-registration reapplies the saved style')
''')

state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(state, before=FIXTURE + EXTRA)
restored.execute(COMMON + r'''
local T,TM=addon.modules.combatTimer,addon.ThreatMeter
assert(addon.db.modules.combatTimer.position.style.scale==150)
assert(Near(T.frame.scale,1.5) and Near(T.frame.alpha,0.5) and Size(T.text)==30,'timer style after reload')
assert(PM:GetStyle('threatMeter').opacity==70 and Near(TM.frame.alpha,0.7),'threat style after reload')
''')

camp, _ = load(before=FIXTURE + EXTRA)
camp.execute(COMMON + r'''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
local page=M.page;page:ShowSection(2)
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
page.contributionPreview.scripts.OnClick()
assert(A.window:IsShown())
assert(addon:SetEditMode(true) and PM:SelectElement('campfireContributions'))
local f=A.window
assert(addon.editWindow.styleCard.title:GetText()=='Camp Contributions')
local title=Size(f.title)
assert(PM:SetStyle('campfireContributions','text',150) and Size(f.title)==math.floor(C.db.contributionTitleSize*1.5+0.5))
assert(PM:SetStyle('campfireContributions','background',false) and f.backdropColor[4]==0 and f.borderColor[4]==0)
assert(C.db.contributionBackgroundOpacity>0)
assert(PM:SetStyle('campfireContributions','scale',50) and f:GetScale()==C.db.contributionScale/100)
''')

rogue, _ = load(before=SETUP)
rogue.execute(COMMON + r'''
local M=addon.ForeverRogue
addon:SetModuleEnabled('foreverRogue',true);M:SetOption('flyout',true)
addon:ToggleConfig()
assert(addon:SetEditMode(true))
local card=addon.editWindow.styleCard
for _,id in ipairs({'roguePoisonReminder','rogueQuickPoisons'}) do
 assert(PM.elements[id].editMode and PM:SelectElement(id) and card:IsShown() and card.sliders.text.slider:IsEnabled())
end
local s=M.db.watchStyle
assert(PM:SetStyle('roguePoisonReminder','text',200) and Size(M.watchButtons[1].caption)==s.fontSize*2)
assert(Size(M.watchButtons[1].timer)==s.timerSize*2)
assert(PM:SetStyle('roguePoisonReminder','background',false) and M.watcher.backdropColor[4]==0)
assert(M.db.watchStyle.backgroundOpacity==s.backgroundOpacity,'saved settings untouched')
-- Quick Access Poisons: the launcher is styled, and its separate menu follows it.
local launcher,menu=M.db.launcherStyle,M.db.flyoutStyle
assert(PM:SetStyle('rogueQuickPoisons','scale',150))
assert(Near(M.launcher.scale,launcher.scale/100*1.5) and Near(M.menu.scale,menu.scale/100*1.5))
assert(PM:SetStyle('rogueQuickPoisons','opacity',50) and Near(M.menu.alpha,menu.opacity/100*0.5))
''')
print('PASS Layout Style card: one card for every display, validation, generic Scale/Opacity, Text size and Background on Combat Timer, Threat Meter, XP bar, Profession/Food bars, Campfire, Contributions, Rogue and Quick Actions, Reset, combat deferral, reload and profile export (mock only)')
