"""Global UI/media, account profiles and optimization contracts; not native WoW."""
from smoke import load

SETUP=r'''
screenWidth,screenHeight=1920,1080
function GetPhysicalScreenSize() return screenWidth,screenHeight end
cvars={cameraDistanceMaxZoomFactor='1.9',uiScale='1',useUiScale='0',autoLootDefault='0'}
cvarWrites={};cvarLocked={};zoomMaximum=4
C_CVar={
 GetCVarInfo=function(key) return cvars[key],cvars[key],false,false,cvarLocked[key] or false,false,false end,
 GetCVar=function(key) return cvars[key] end,
 GetCVarBool=function(key) return cvars[key]=='1' end,
 SetCVar=function(key,value)
  assert(not testCombat and not testLockdown,'No CVar writes in combat')
  cvarWrites[#cvarWrites+1]={key,value}
  if rejectedCVar==key then return false end
  if key=='cameraDistanceMaxZoomFactor' then value=tostring(math.min(zoomMaximum,tonumber(value))) end
  cvars[key]=value;return true
 end}
UIErrorsFrame=CreateFrame('Frame',nil,UIParent)
UIErrorsFrame:RegisterEvent('UI_ERROR_MESSAGE');UIErrorsFrame:RegisterEvent('UI_INFO_MESSAGE')
lootCalls={};lootCount=3
function GetNumLootItems() return lootCount end
function LootSlot(slot) assert(not testCombat and not testLockdown);lootCalls[#lootCalls+1]=slot end
'''

lua,_=load(before=SETUP)
lua.execute(r'''
local M,G,P=addon.Media,addon.GlobalSettings,addon.ProfileManager
assert(M.library and #M:GetFonts()>4 and #M:GetTextures()>6 and #M:GetBorders()>4,'bundled LSM is available without another addon')
assert(M:GetFont('PTG JetBrains Mono'):find('JetBrainsMono%-Regular.ttf'))
assert(M.library:HashTable('statusbar')['PTG Graphite'])
assert(M.library:HashTable('border')['Blizzard Tooltip'])
assert(M.library:HashTable('border')['PTG Clean'] and M.library:HashTable('background')['PTG Matte'])
assert(cvars.cameraDistanceMaxZoomFactor=='4' and math.abs(UIParent:GetScale()-768/1080)<.00001)
addon:ToggleConfig();addon:SelectConfigPage('globalSettings')
local w=addon.configWindow;local page=w.pages.globalSettings
assert(w.moduleHeader.title:GetText()=='Global Settings' and not w.moduleHeader.toggle:IsShown())
assert(#page.sections==4 and page.sections[1].title=='Appearance' and page.sections[2].title=='Profiles')
assert(page.sectionTabs:GetNumPoints()==2 and page.scroll.points[1][5]==-40,'tabs are anchored above scrolling controls')
for key in pairs(page.mediaControls) do assert(key:sub(1,7)=='global:','no per-module overrides on page') end
assert(page.profileHub and not page.profileHub.specToggle:GetParent():GetParent():IsShown(),'Forever spec controls omitted')
assert(#G.classes==9 and page.classColorButtons.DRUID)
local function Choose(kind,id)
 local b=page.mediaControls['global:'..kind];b.scripts.OnClick();assert(b.menu:IsShown())
 for _,row in ipairs(b.rows) do if row.choice.id==id then row.scripts.OnClick();return end end
 error('Missing dropdown choice '..id)
end
Choose('font','media:PTG JetBrains Mono');Choose('texture','media:PTG Satin');Choose('border','media:PTG Clean')
assert(addon.ReloadManager.requests.globalMedia)
M:RefreshFonts()
local path=M:GetFont('PTG JetBrains Mono')
assert(GameFontHighlight:GetFont()==path and GameFontNormalLarge:GetFont()==path and ChatFontNormal:GetFont()==path,'standard game UI fonts follow global')
assert(select(2,GameFontNormalLarge:GetFont())==16,'game font size retained')
assert(M:GetDisplayFont({font='game',fontMedia=''})==path)
assert(M:GetDisplayFont({font='chat',fontMedia=''})==M.chatFont,'explicit local chat choice retained')
addon:SetModuleEnabled('combatTimer',true)
local timer=addon.modules.combatTimer
timer:ApplyAppearance();assert(timer.text.font[1]==path and timer.globalBorder.borderKind=='shared')
assert(timer.background.texture==M.library:HashTable('statusbar')['PTG Satin'])
addon:SelectConfigPage('combatTimer')
local font=w.pages.combatTimer.fontDropdown
font.scripts.OnClick()
for _,row in ipairs(font.rows) do if row.choice.key=='game' then row.scripts.OnClick();break end end
assert(timer.db.appearance.fontMedia=='builtin:game' and timer.text.font[1]==M.gameFont,'module override pins original game face')
font.scripts.OnClick()
for _,row in ipairs(font.rows) do if row.choice.key=='global' then row.scripts.OnClick();break end end
assert(timer.text.font[1]==path)
addon:SelectConfigPage('globalSettings');page:SelectSectionTab(4)
local picker=page.classColorButtons.MAGE.pick;picker.scripts.OnClick()
ColorPickerFrame.r,ColorPickerFrame.g,ColorPickerFrame.b=.2,.3,.4;ColorPickerFrame.info.swatchFunc()
assert(G:GetClassColor('MAGE').g==.3 and addon.ForeverRecruitment:ClassColor('MAGE')==.2)
local r,g,b=addon.ForeverGuildRoster:ClassColor('MAGE');assert(r==.2 and g==.3 and b==.4)
assert(page.classColorButtons.MAGE.pick.label.color[2]==.3)
ColorPickerFrame.info.cancelFunc();assert(not addon.db.globalOptions.classColors.MAGE,'picker cancel restores inheritance')
assert(G:SetClassColor('MAGE',{.2,.3,.4}) and not G:SetClassColor('MAGE',{1,2,3}))
assert(addon.PositionManager:SetOffsets('combatTimer',123,-87))
page:SelectSectionTab(2)
local hub=page.profileHub;hub.nameInput:SetText('Raid');hub.create.scripts.OnClick()
assert(P.root.profiles.Raid.modules.combatTimer.enabled and P.root.profiles.Raid.modules.combatTimer.position.x==123)
assert(P.root.profiles.Raid.globalOptions.classColors.MAGE[2]==.3)
assert(P:Select('Raid',true) and P:Character().pendingProfile=='Raid')
hub.export.scripts.OnClick();assert(#hub.editor:GetText()>100,'export is displayed for copying')
exported=assert(P:Export('Raid'))
local ok,reason,name=P:Import(exported,'Imported');assert(ok,reason)
assert(name=='Imported' and P.root.profiles.Imported.globalMedia.font=='media:PTG JetBrains Mono')
assert(P.root.profiles.Imported.modules.combatTimer.enabled and P.root.profiles.Imported.modules.combatTimer.position.y==-87)
assert(P.root.profiles.Imported.globalOptions.classColors.MAGE[3]==.4)
local envelope=addon.ProfileCodec.Decode(exported)
assert(not envelope.profile.accountSelection and not envelope.profile.characters and not envelope.profile.profiles)
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
alt,_=load(state,before=SETUP+"\nfunction UnitGUID() return 'Player-OtherCharacter' end\n")
alt.execute(r'''
local P=addon.ProfileManager
assert(P.activeName=='Raid' and P:Character()==P.root.accountSelection,'selection shared across characters')
assert(addon.modules.combatTimer.enabled and addon.modules.combatTimer.db.position.x==123)
assert(addon.GlobalSettings:GetClassColor('MAGE').b==.4)
assert(P:Rename('Raid','Raid Shared') and P:Character().activeProfile=='Raid Shared')
assert(P.root.profiles.Imported.globalMedia.font==addon.db.globalMedia.font)
''')

runtime,_=load(before=SETUP)
runtime.execute(r'''
local G=addon.GlobalSettings
assert(not G.db.fastLoot)
assert(G:SetOption('autoLoot',true) and cvars.autoLootDefault=='1')
assert(G:SetOption('autoLoot',false) and cvars.autoLootDefault=='0')
assert(G:SetOption('fastLoot',true))
local queue={};C_Timer.After=function(delay,fn) queue[#queue+1]={delay,fn} end
FireEvent('LOOT_READY',false);assert(#queue==0,'native manual/modifier session stays manual')
FireEvent('LOOT_READY',true);assert(#queue==3 and queue[1][1]==.05 and math.abs(queue[3][1]-.15)<.00001)
FireEvent('LOOT_CLOSED');for _,t in ipairs(queue) do t[2]() end;assert(#lootCalls==0,'stale callbacks cancelled')
queue={};FireEvent('LOOT_READY',true);for _,t in ipairs(queue) do t[2]() end
assert(#lootCalls==3 and lootCalls[1]==1 and lootCalls[3]==3)
queue={};FireEvent('LOOT_READY',true);G:SetOption('fastLoot',false)
for _,t in ipairs(queue) do t[2]() end;assert(#lootCalls==3)
assert(G:SetOption('hideErrors',true) and not UIErrorsFrame:IsEventRegistered('UI_ERROR_MESSAGE'))
assert(UIErrorsFrame:IsEventRegistered('UI_INFO_MESSAGE'),'information retained')
assert(G:SetOption('hideErrors',false) and UIErrorsFrame:IsEventRegistered('UI_ERROR_MESSAGE'))
UIErrorsFrame:UnregisterEvent('UI_ERROR_MESSAGE')
G:SetOption('hideErrors',true);G:SetOption('hideErrors',false)
assert(not UIErrorsFrame:IsEventRegistered('UI_ERROR_MESSAGE'),'do not restore an event suppressed by another owner')
screenWidth,screenHeight=2560,1440;FireEvent('DISPLAY_SIZE_CHANGED');FireEvent('UI_SCALE_CHANGED')
assert(math.abs(UIParent:GetScale()-768/1440)<.00001 and tonumber(cvars.uiScale)==.65)
assert(G:SetOption('uiScale',80) and not G.db.autoScale and UIParent:GetScale()==.8)
assert(G:SetOption('autoScale',true) and math.abs(UIParent:GetScale()-768/1440)<.00001)
zoomMaximum=3.5;cvars.cameraDistanceMaxZoomFactor='1.9';assert(G:SetOption('cameraZoom',4) and G.db.cameraZoom==3.5)
assert(G.status.cameraDistanceMaxZoomFactor:find('clamped'))
local writes=#cvarWrites;testCombat=true
assert(not G:SetOption('cameraZoom',3) and not G:SetOption('hideErrors',true))
G:Apply();assert(G.pending and #cvarWrites==writes)
FireEvent('LOOT_READY',true);assert(#cvarWrites==writes)
testCombat=false;FireEvent('PLAYER_REGEN_ENABLED');assert(not G.pending and #cvarWrites>=writes)
testLockdown=true;assert(not G:SetOption('autoLoot',true));testLockdown=false
rejectedCVar='cameraDistanceMaxZoomFactor';G.db.cameraZoom=3;G:Apply()
assert(G.status.cameraDistanceMaxZoomFactor:find('not accept'))
local invalid=addon.ProfileCodec.Copy(addon.db);invalid.globalOptions.uiScale=0/0
assert(not addon.ProfileValidation:Validate(invalid),'invalid profile does not publish')
''')
adopted,_=load(before=SETUP+"\ncvars.autoLootDefault='1'\n")
adopted.execute(r'''
local G,P=addon.GlobalSettings,addon.ProfileManager
assert(G.db.autoLoot and not G.db.adoptAutoLoot and cvars.autoLootDefault=='1','first adoption preserves existing native preference')
assert(P:Create('No Auto Loot'))
P.root.profiles['No Auto Loot'].globalOptions.autoLoot=false
assert(P:Select('No Auto Loot',true))
''')
off,_=load(adopted.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=SETUP+"\ncvars.autoLootDefault='1'\n")
off.execute("assert(not addon.GlobalSettings.db.autoLoot and cvars.autoLootDefault=='0','profile switching restores explicit off as well as on')")
print('PASS bundled LSM, game/addon fonts, module overrides, account profiles/import/export/positions, class picker, loot epochs, scale/zoom readback and combat guards')
