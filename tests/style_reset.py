"""v2 one-time styling reset: listed styling keys only, once per profile, with
one notice. Mock only: no in-game rendering or SavedVariables write is claimed.
"""
from smoke import load

# A pre-v2 profile (no v2StyleReset marker) with custom display styling, plus
# behaviour, visibility, position and Style card values that must survive.
OLD = r'''
PTGToolsDB={schemaVersion=1,profileVersion=1,defaultProfile='Default',characters={},profiles={Default={
 modules={
  combatTimer={enabled=true,showOutOfCombat=true,position={x=40,y=-120,target='screen',placement='center',style={scale=150,background=false}},
   appearance={format='plain',font='chat',fontMedia='',fontSize=30,outline=true,textColor={1,0,0},
    backgroundColor={0,0,1},backgroundOpacity=0.8,scale=1.5}},
  foreverQuickAccess={enabled=true,iconSize=50,columns=3,showNames=true,showTooltips=false,textColor={0.2,0.2,0.2},x=12,
   food={iconSize=44,columns=2,backgroundOpacity=20,x=5,y=-200,selected={[4536]=true}}},
  enhancedExperienceBar={enabled=true,width=900,barTexture='flat',showValues=true,sessionX=40,textOffset=3,
   normalColor={0.1,0.9,0.1},nativeColors=false,questFormat='both'},
  foreverRogue={enabled=false,direction='DOWN',visibleRows=3,watchStyle={iconSize=60,showHands=false,timerColor={0,1,0}},
   launcherStyle={labelText='Kit',cropIcons=false,borderSize=4},flyoutStyle={cellWidth=300,columns=2}},
  lootSparkles={enabled=true,campfire={contributionTitleSize=20,compactBenefits=false,contributionVisibleRows=3,
   contributionX=30,headerColor={0,0,1},showIcon=false,benefitsScale=120}},
 }}}}
'''

lua, _ = load(before=OLD)
lua.execute(r'''
local R,db=addon.StyleReset,addon.db
assert(db.v2StyleReset.cleared==true,'an old profile with custom styling is cleared')
local t=db.modules.combatTimer
assert(t.appearance.fontSize==20 and t.appearance.font=='game' and not t.appearance.outline and t.appearance.textColor[2]==1)
assert(t.appearance.backgroundOpacity==0.4 and t.appearance.scale==1 and t.appearance.backgroundColor[3]==53/255)
assert(t.showOutOfCombat==true and t.enabled and t.appearance.format=='plain','behaviour kept')
assert(addon.PositionManager:GetPosition('combatTimer').x==40,'position kept')
local style=addon.PositionManager:GetStyle('combatTimer');assert(style.scale==150 and style.background==false,'Style card kept')
local q=db.modules.foreverQuickAccess
assert(q.iconSize==36 and q.textColor[1]==0.9 and q.columns==3 and q.showNames and not q.showTooltips and q.x==12)
assert(q.food.iconSize==36 and q.food.backgroundOpacity==65 and q.food.columns==2 and q.food.selected[4536] and q.food.x==5)
local x=db.modules.enhancedExperienceBar
assert(x.width==600 and x.barTexture=='default' and x.normalColor[1]==0.58 and x.nativeColors==true)
assert(x.showValues and x.sessionX==40 and x.textOffset==3 and x.questFormat=='both','behaviour and offsets kept')
local r=db.modules.foreverRogue
assert(r.watchStyle.iconSize==40 and r.watchStyle.timerColor[1]==1 and r.launcherStyle.borderSize==0 and r.launcherStyle.cropIcons==true)
assert(r.flyoutStyle.cellWidth==210,'per-part defaults')
assert(r.direction=='DOWN' and r.visibleRows==3 and r.watchStyle.showHands==false and r.launcherStyle.labelText=='Kit' and r.flyoutStyle.columns==2)
local c=db.modules.lootSparkles.campfire
assert(c.contributionTitleSize==14 and c.headerColor[3]==0.12 and c.benefitsScale==100)
assert(c.compactBenefits==false and c.contributionVisibleRows==3 and c.contributionX==30 and c.showIcon==false,'kept keys')
-- Displays render the default look.
assert(addon.modules.combatTimer.text.font[2]==20,'timer renders the default size')
-- One chat line, once; the notice shows in the settings window until dismissed.
local lines=0;for _,m in ipairs(messages) do if m:find(R.MESSAGE,1,true) then lines=lines+1 end end
assert(lines==1,'one chat line')
assert(R:Pending())
addon:ToggleConfig()
local w=addon.configWindow;local n=w.styleNotice
assert(n:IsShown() and n.message:GetText()==R.MESSAGE and n.hint:GetText()=='Use Layout to restyle displays.')
assert(n.dismissButton.label:GetText()=='Dismiss')
-- Dismissal is stored; the page moves back up.
n.dismissButton.scripts.OnClick()
assert(not n:IsShown() and not R:Pending() and PTGToolsDB.styleResetNotice.dismissed==true)
R:Announce();local again=0;for _,m in ipairs(messages) do if m:find(R.MESSAGE,1,true) then again=again+1 end end
assert(again==1,'no second chat line')
-- Idempotent: running the clear again changes nothing.
assert(not R.Clear(addon.ProfileCodec.Copy(addon.db),addon.ProfileValidation.template))
-- A later change is not cleared again on reload (the marker is kept).
assert(addon.modules.combatTimer:SetAppearance('fontSize',33))
''')
saved = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
again, _ = load(saved)
again.execute(r'''
assert(addon.db.modules.combatTimer.appearance.fontSize==33,'cleared once per profile, not every load')
assert(addon.db.v2StyleReset.cleared==true and not addon.StyleReset:Pending(),'dismissed stays dismissed')
addon:ToggleConfig();assert(not addon.configWindow.styleNotice:IsShown())
for _,m in ipairs(messages) do assert(not m:find(addon.StyleReset.MESSAGE,1,true),'no chat line after dismissal') end
''')

# A brand-new profile shows nothing.
fresh, _ = load()
fresh.execute(r'''
assert(addon.db.v2StyleReset and addon.db.v2StyleReset.cleared==false,'a new profile is marked, nothing cleared')
assert(not addon.StyleReset:Pending())
addon:ToggleConfig();assert(not addon.configWindow.styleNotice:IsShown())
for _,m in ipairs(messages) do assert(not m:find(addon.StyleReset.MESSAGE,1,true),'no chat line') end
-- Old profiles whose saved styling equals the defaults show nothing either.
local plain={modules={combatTimer={appearance={font='game',fontMedia='',fontSize=20,scale=1,textColor={1,1,1}}},
 enhancedExperienceBar={width=600,normalColor={0.58,0,0.55}}}}
local p=assert(addon.ProfileValidation:Validate(plain))
assert(p.v2StyleReset.cleared==false,'default-valued styling is not a reset')
-- Imports: an old export string is cleared on import; a v2 export is untouched.
local old={schemaVersion=1,modules={combatTimer={enabled=true,appearance={fontSize=40,textColor={0,1,0}}}}}
local text=addon.ProfileCodec.Encode({version=1,name='Old',profile=old})
local candidate,name=addon.ProfileManager:PrepareImport(text)
assert(candidate and name=='Old' and candidate.modules.combatTimer.appearance.fontSize==20 and candidate.v2StyleReset.cleared)
assert(candidate.modules.combatTimer.enabled==true)
local exported=assert(addon.ProfileManager:Export('Default'))
local envelope=addon.ProfileCodec.Decode(exported);assert(envelope.profile.v2StyleReset==nil,'the marker is not exported')
local again=assert(addon.ProfileManager:PrepareImport(exported,'Copy'))
assert(again.v2StyleReset.cleared==false,'a v2 export imports without a reset')
-- A malformed marker is refused like any other invalid setting.
assert(not addon.ProfileValidation:Validate({v2StyleReset='yes'}))
''')
print('PASS v2 styling reset: listed keys only, kept behaviour/positions/Style card, once per profile, idempotent, one chat line, dismissible notice stored, fresh/default profiles silent, import/export (mock only)')
