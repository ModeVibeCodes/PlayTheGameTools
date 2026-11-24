"""Settings page, predefined themes, account profiles and game options contracts; not native WoW."""
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
function AutoLootWrites() local n=0;for _,w in ipairs(cvarWrites) do if w[1]=='autoLootDefault' then n=n+1 end end;return n end
UIErrorsFrame=CreateFrame('Frame',nil,UIParent)
UIErrorsFrame:RegisterEvent('UI_ERROR_MESSAGE');UIErrorsFrame:RegisterEvent('UI_INFO_MESSAGE')
lootCalls={};lootCount=3
function GetNumLootItems() return lootCount end
function LootSlot(slot) assert(not testCombat and not testLockdown);lootCalls[#lootCalls+1]=slot end
'''

lua,_=load(before=SETUP)
lua.execute(r'''
local M,G,P=addon.Media,addon.GlobalSettings,addon.ProfileManager
assert(M.library and #M:GetFonts()>4 and #M:GetBorders()>4,'bundled LSM is available without another addon')
assert(M:GetFont('PTG JetBrains Mono'):find('JetBrainsMono%-Regular.ttf'))
assert(M.library:HashTable('statusbar')['PTG Graphite'] and M.library:HashTable('background')['PTG Matte'])
assert(M.library:HashTable('border')['Blizzard Tooltip'] and M.library:HashTable('border')['PTG Clean'])
assert(M.SetGlobalStyle==nil and M.GetTextures==nil,'no Global Font/Texture/Border pickers remain')
assert(cvars.cameraDistanceMaxZoomFactor=='4' and cvars.uiScale=='1' and cvars.useUiScale=='0','startup leaves UI scale alone')
assert(cvars.autoLootDefault=='0' and AutoLootWrites()==0,'startup never writes the game Auto Loot option')
addon:ToggleConfig();addon:SelectConfigPage('globalSettings')
local w=addon.configWindow;local page=w.pages.globalSettings
assert(w.moduleHeader.title:GetText()=='Settings' and not w.moduleHeader.toggle:IsShown())
local titles={};for i,s in ipairs(page.sections) do titles[i]=s.title end
assert(table.concat(titles,'|')=='Appearance|Game|Profile|About','one page, four sections in order')
assert(not page.sectionTabs and not page.mediaControls,'no section tabs and no media pickers')
for _,entry in ipairs(page.searchEntries) do
 local label=(entry.label or ''):lower()
 assert(not label:find('auto loot') and not label:find('global font') and not label:find('global texture') and not label:find('global border'),'removed controls are not searchable: '..label)
end
-- Theme preview cards: one per predefined theme, chosen one outlined, applied one Current.
local cards=page.themeButtons
assert(#cards==3 and cards[1].themeID=='modern' and cards[2].themeID=='blizzard' and cards[3].themeID=='mode')
for _,card in ipairs(cards) do
 assert(card.mini and card.mini.rows and #card.mini.rows==2 and card.caption:GetText()~='','drawn preview and caption')
 assert(card.mini.palette==addon.InterfaceThemes[card.themeID].palette,'each preview uses its own palette')
end
assert(cards[2].mini.rows[1].switch.color[1]==addon.InterfaceThemes.blizzard.palette.primary[1],'on switch drawn in the theme accent')
assert(cards[1].selected and cards[1].current:IsShown() and not cards[2].current:IsShown())
assert(cards[1].selectedOutline.edges[1]:IsShown() and not cards[2].selectedOutline.edges[1]:IsShown(),'chosen card outlined')
cards[3].scripts.OnClick()
assert(addon.db.window.theme=='mode' and addon.ReloadManager.requests.interfaceTheme and cards[3].selected and not cards[1].selected)
assert(cards[1].current:IsShown() and not cards[3].current:IsShown(),'Current stays on the theme on screen until reload')
cards[1].scripts.OnClick();assert(addon.db.window.theme=='modern' and not addon.ReloadManager.requests.interfaceTheme)
-- Saved global media is retained but never applied.
addon.db.globalMedia.font='media:PTG JetBrains Mono';addon.db.globalMedia.texture='media:PTG Satin';addon.db.globalMedia.border='media:PTG Clean'
M:RefreshFonts();M:RefreshBorders()
assert(GameFontNormalLarge:GetFont()=='Fonts/FRIZQT__.TTF' and ChatFontNormal:GetFont()=='Fonts/ARIALN.TTF','game UI fonts untouched')
assert(M.ApplyGameFonts==nil,'no game-wide font rewrite')
assert(not w.title.font[1]:find('JetBrains'),'settings window ignores a saved Global Font')
assert(M:GetDisplayFont({font='game',fontMedia=''})==M.gameFont,'displays without their own font use the game font')
assert(M:GetDisplayFont({font='chat',fontMedia=''})==M.chatFont,'explicit local chat choice retained')
addon:SetModuleEnabled('combatTimer',true)
local timer=addon.modules.combatTimer
timer:ApplyAppearance()
assert(timer.text.font[1]==M.gameFont and timer.globalBorder.borderKind~='shared','saved Global Font/Border not applied to displays')
assert(timer.background.texture==M.defaultStatusBar,'saved Global Texture not applied to displays')
assert(addon.db.globalMedia.font=='media:PTG JetBrains Mono' and addon.db.globalMedia.texture=='media:PTG Satin' and addon.db.globalMedia.border=='media:PTG Clean','saved values untouched')
addon:SelectConfigPage('combatTimer')
local font=w.pages.combatTimer.fontDropdown
font.scripts.OnClick()
for _,row in ipairs(font.rows) do if row.choice.key=='media:PTG JetBrains Mono' then row.scripts.OnClick();break end end
assert(timer.text.font[1]==M:GetFont('PTG JetBrains Mono'),'per-display font choice still applies')
font.scripts.OnClick()
for _,row in ipairs(font.rows) do if row.choice.key=='global' then row.scripts.OnClick();break end end
assert(timer.text.font[1]==M.gameFont)
-- Class colors: nine swatches, the existing picker, one Reset.
addon:SelectConfigPage('globalSettings')
assert(#G.classes==9 and page.classColorButtons.DRUID and not page.classColorButtons.DRUID.reset)
assert(not page.classColorReset:IsEnabled(),'Reset waits for a custom color')
local picker=page.classColorButtons.MAGE.pick
testCombat=true;picker.scripts.OnClick();assert(not ColorPickerFrame:IsShown(),'no picker in combat');testCombat=false
picker.scripts.OnClick();assert(ColorPickerFrame:IsShown())
ColorPickerFrame.r,ColorPickerFrame.g,ColorPickerFrame.b=.2,.3,.4;ColorPickerFrame.info.swatchFunc()
assert(G:GetClassColor('MAGE').g==.3 and addon.ForeverRecruitment:ClassColor('MAGE')==.2)
local r,g,b=addon.ForeverGuildRoster:ClassColor('MAGE');assert(r==.2 and g==.3 and b==.4)
assert(picker.fill.color[2]==.3 and page.classColorReset:IsEnabled(),'swatch shows the custom color')
ColorPickerFrame.info.cancelFunc();assert(not addon.db.globalOptions.classColors.MAGE,'picker cancel restores inheritance')
assert(G:SetClassColor('MAGE',{.2,.3,.4}) and G:SetClassColor('DRUID',{.1,.1,.1}) and not G:SetClassColor('MAGE',{1,2,3}))
testCombat=true;page.classColorReset.scripts.OnClick();assert(addon.db.globalOptions.classColors.MAGE,'no reset in combat');testCombat=false
page:Refresh();page.classColorReset.scripts.OnClick()
assert(next(addon.db.globalOptions.classColors)==nil and not page.classColorReset:IsEnabled(),'one Reset returns all nine')
assert(G:SetClassColor('MAGE',{.2,.3,.4}))
-- Game options on the page.
local fast=page.optimizationControls.fastLoot
fast.scripts.OnClick();assert(G.db.fastLoot and fast.selected)
fast.scripts.OnClick();assert(not G.db.fastLoot and not fast.selected)
page.optimizationControls.hideErrors.scripts.OnClick();assert(G.db.hideErrors)
page.optimizationControls.hideErrors.scripts.OnClick();assert(not G.db.hideErrors)
assert(page.zoomSlider and not page.fastLootNotice:GetParent().row:IsShown(),'Fast Loot notice only after a rejection')
G.lootBlocked=true;page:Refresh();assert(page.fastLootNotice:GetParent().row:IsShown());G.lootBlocked=nil;page:Refresh()
assert(AutoLootWrites()==0,'no Auto Loot writes from the page')
-- About.
assert(page.aboutVersion:GetText()==addon.buildVersion and addon.buildVersion~='')
local function Reads(value) return value:GetParent().rowLabel:GetText()..' '..value:GetText() end
assert(Reads(page.aboutCredits)=='Created by Mode and Prox','credits')
assert(Reads(page.aboutBugs)=='Bug reports Discord NoJumperMike','bug reports go to Discord NoJumperMike')
addon:SelectConfigPage('cityLabels')
local notice=w.pages.cityLabels.cityLabelSource:GetText()
addon:SelectConfigPage('globalSettings')
assert(page.dataSourcesNotice:GetText()==notice,'full Points of Interest notice, copied exactly')
-- Profile: one dropdown plus Manage.
assert(addon.PositionManager:SetOffsets('combatTimer',123,-87))
page:SelectSectionTab(3);assert(page.selectedSection.title=='Profile' and page.scrollbar:GetValue()>0,'indexes follow the page order')
page:SelectSectionTab(1);assert(page.selectedSection.title=='Appearance' and page.scrollbar:GetValue()==0,'section 1 is the top')
local hub=page.profileHub
assert(hub.select and hub.manage and not hub.specToggle,'Forever has no spec controls')
testCombat=true;hub.manage.scripts.OnClick();assert(not hub.menu:IsShown());testCombat=false
hub.manage.scripts.OnClick();assert(hub.menu:IsShown())
for _,kind in ipairs({'new','duplicate','rename','import','export','delete'}) do assert(hub.menuItems[kind],kind) end
hub.menuItems.new.scripts.OnClick()
local dialog=hub:Dialog()
assert(not hub.menu:IsShown() and dialog:IsShown() and dialog:Kind()=='new' and dialog.confirm.label:GetText()=='Create')
dialog.nameInput:SetText('Raid');dialog.confirm.scripts.OnClick()
assert(not dialog:IsShown() and P.root.profiles.Raid,'New creates a profile')
assert(P.root.profiles.Raid.modules.combatTimer.enabled and P.root.profiles.Raid.modules.combatTimer.position.x==123)
assert(P.root.profiles.Raid.globalOptions.classColors.MAGE[2]==.3)
hub.select.scripts.OnClick()
for _,row in ipairs(hub.select.rows) do if row.choice.id=='Raid' then row.scripts.OnClick();break end end
assert(P:Character().pendingProfile=='Raid' and hub.status:GetText():find('after a reload',1,true),'switch waits for a reload')
assert(hub.select.label:GetText()=='Raid')
-- Export the chosen profile through the dialog.
hub.menuItems.export.scripts.OnClick()
assert(dialog:Kind()=='export' and dialog:Target()=='Raid' and #dialog.editor:GetText()>100 and dialog.editor.highlighted,'export is displayed for copying')
assert(not dialog.confirm:IsShown() and dialog.cancel.label:GetText()=='Close')
exported=dialog.editor:GetText();dialog.cancel.scripts.OnClick();assert(not dialog:IsShown())
-- Import a string under a new name.
hub.menuItems.import.scripts.OnClick()
assert(dialog:Kind()=='import' and not dialog.confirm:IsEnabled())
dialog.editor:SetText(exported);dialog.nameInput:SetText('Imported')
assert(dialog.confirm:IsEnabled() and dialog.confirm.label:GetText()=='Import')
dialog.confirm.scripts.OnClick()
assert(P.root.profiles.Imported and P.root.profiles.Imported.globalMedia.font=='media:PTG JetBrains Mono','saved media keys travel untouched')
assert(P.root.profiles.Imported.modules.combatTimer.position.y==-87 and P.root.profiles.Imported.globalOptions.classColors.MAGE[3]==.4)
local envelope=addon.ProfileCodec.Decode(exported)
assert(not envelope.profile.accountSelection and not envelope.profile.characters and not envelope.profile.profiles)
-- Duplicate and rename act on the profile chosen inside the dialog.
hub.menuItems.duplicate.scripts.OnClick();assert(dialog:Target()=='Raid')
dialog.nameInput:SetText('Raid Copy');dialog.confirm.scripts.OnClick();assert(P.root.profiles['Raid Copy'])
hub.menuItems.rename.scripts.OnClick();dialog.target.scripts.OnClick()
for _,row in ipairs(dialog.target.rows) do if row.choice.id=='Raid Copy' then row.scripts.OnClick();break end end
assert(dialog:Target()=='Raid Copy' and dialog.nameInput:GetText()=='Raid Copy')
dialog.nameInput:SetText('Alt');dialog.confirm.scripts.OnClick()
assert(P.root.profiles.Alt and not P.root.profiles['Raid Copy'])
-- Delete never removes the profile in use or the one waiting to apply.
assert(not P:Delete(P.activeName) and P.root.profiles[P.activeName])
assert(not P:Delete('Raid') and P.root.profiles.Raid,'pending switch kept')
hub.menuItems.delete.scripts.OnClick()
assert(dialog:Kind()=='delete' and dialog:Target()~=P.activeName and dialog:Target()~='Raid','offers a profile that can be deleted')
dialog.target.scripts.OnClick()
for _,row in ipairs(dialog.target.rows) do if row.choice.id==P.activeName then row.scripts.OnClick();break end end
assert(dialog.remove:IsShown() and not dialog.confirm:IsShown() and dialog.remove.label:GetText()=='Delete')
dialog.remove.scripts.OnClick();assert(dialog:IsShown() and dialog.feedback:GetText():find('in use',1,true))
dialog.target.scripts.OnClick()
for _,row in ipairs(dialog.target.rows) do if row.choice.id=='Alt' then row.scripts.OnClick();break end end
dialog.remove.scripts.OnClick()
assert(not P.root.profiles.Alt and not dialog:IsShown(),'Delete removes the chosen profile')
assert(P:Select('Raid',true) and P:Character().pendingProfile=='Raid')
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
assert(P:Delete('Default') and P.root.defaultProfile=='Raid Shared','deleting the fallback profile moves the fallback to the profile in use')
assert(AutoLootWrites()==0)
''')

runtime,_=load(before=SETUP)
runtime.execute(r'''
local G=addon.GlobalSettings
assert(not G.db.fastLoot)
assert(not G:SetOption('autoLoot',true) and not G:SetOption('autoLoot',false),'Auto Loot option removed')
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
-- The game's own UI scale is never touched.
local priorScale=UIParent:GetScale()
screenWidth,screenHeight=2560,1440;FireEvent('DISPLAY_SIZE_CHANGED');FireEvent('UI_SCALE_CHANGED');G:Apply()
assert(UIParent:GetScale()==priorScale and cvars.uiScale=='1' and cvars.useUiScale=='0','UI scale untouched')
assert(G.ApplyScale==nil and not G:SetOption('uiScale',80) and not G:SetOption('autoScale',true),'no UI scale option')
zoomMaximum=3.5;cvars.cameraDistanceMaxZoomFactor='1.9';assert(G:SetOption('cameraZoom',4) and G.db.cameraZoom==3.5)
assert(G.status.cameraDistanceMaxZoomFactor:find('clamped'))
local writes=#cvarWrites;testCombat=true
assert(not G:SetOption('cameraZoom',3) and not G:SetOption('hideErrors',true))
G:Apply();assert(G.pending and #cvarWrites==writes)
FireEvent('LOOT_READY',true);assert(#cvarWrites==writes)
testCombat=false;FireEvent('PLAYER_REGEN_ENABLED');assert(not G.pending and #cvarWrites>=writes)
testLockdown=true;assert(not G:SetOption('cameraZoom',2));testLockdown=false
rejectedCVar='cameraDistanceMaxZoomFactor';G.db.cameraZoom=3;G:Apply()
assert(G.status.cameraDistanceMaxZoomFactor:find('not accept'))
local invalid=addon.ProfileCodec.Copy(addon.db);invalid.globalOptions.cameraZoom=0/0
assert(not addon.ProfileValidation:Validate(invalid),'invalid profile does not publish')
assert(AutoLootWrites()==0 and cvars.autoLootDefault=='0','Auto Loot left to the game')
''')
# A profile saved before Auto Loot was removed keeps its keys; the game's own option is left alone.
legacy,_=load(before=SETUP+"\ncvars.autoLootDefault='1'\n")
legacy.execute("addon.db.globalOptions.autoLoot=false;addon.db.globalOptions.adoptAutoLoot=false")
old,_=load(legacy.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=SETUP+"\ncvars.autoLootDefault='1'\n")
old.execute(r'''
assert(AutoLootWrites()==0 and cvars.autoLootDefault=='1','a saved Auto Loot off no longer turns off the game option')
assert(addon.db.globalOptions.autoLoot==false and addon.db.globalOptions.adoptAutoLoot==false,'retired keys retained')
assert(addon.GlobalSettings:SetOption('fastLoot',true) and AutoLootWrites()==0)
''')
print('PASS Settings page (theme previews, class swatches, game options, profile Manage dialogs, About), saved global media retained but unapplied, no Auto Loot writes, account profiles/import/export/delete, loot epochs, untouched UI scale, zoom readback and combat guards')
