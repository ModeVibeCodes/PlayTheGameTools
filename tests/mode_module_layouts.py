"""One scroll per module: full settings inventory, reachability, search and theme parity.

Mock UI geometry/callback checks are not in-game visual or API acceptance.
"""
from smoke import load
from rogue_poisons import SETUP

inventory = r'''
function Inventory()
 local out={}
 for _,id in ipairs(addon.moduleOrder) do
  local p=addon:EnsureConfigPage(id);local titles={}
  for _,row in ipairs(p.rows or {}) do
   if row.settingsTitle and row.settingsTitle~='' then titles[#titles+1]=row.settingsTitle end
   if row.settingsTitle=='' then for _,cell in ipairs(row.settingsToggles or {}) do titles[#titles+1]=cell.label:GetText() end end
  end
  table.sort(titles);out[#out+1]=id..':'..table.concat(titles,'|')
 end
 return table.concat(out,'\n')
end
'''
base,_=load(before=SETUP)
base.execute("addon:ToggleConfig()"+inventory)
expected=base.eval('Inventory()')
base.execute("addon.db.window.theme='mode'")
lua,_=load(base.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=SETUP)
lua.globals().expectedInventory=expected
lua.execute(inventory+r'''
addon:ToggleConfig()
assert(Inventory()==expectedInventory,'all original module setting rows retained')
-- One scroll per module: no pills, panel tabs or section tabs; every section
-- that holds a visible row is a titled group, in page order.
for _,id in ipairs(addon.moduleOrder) do
 addon:SelectConfigPage(id)
 local p=addon:EnsureConfigPage(id)
 -- Campfire Monitor routes its own rows on its own page (CampfireMonitor.lua);
 -- Dungeon Loot's page holds settings only, its browser is a window.
 if id=='dungeonLoot' then assert(not p.modeBrowser and not p.rootPane and p==addon.DungeonLoot.settingsPage,'Dungeon Loot settings only; its browser is a window')
 elseif id=='campfireMonitor' then assert(not p.campfirePilot and not p.modeLayout and p.modeFooterLayout)
 else assert(p.modeLayout,'Mode rollout missing '..id) end
 assert(not p.sectionTabs and not p.SelectSectionTab and not p.SelectModePanel,'no tab navigation '..id)
 if p.modeLayout then assert(not p.modeLayout.bar and not p.modeLayout.buttons and not p.modeLayout.panels,'no pills or panel tabs '..id) end
 for _,color in ipairs(p.settingsColors or {}) do
  assert(not color.hex:IsShown() and (not color.apply or not color.apply:IsShown()),'native picker replaces redundant fields '..id)
  assert(color.pick:GetWidth()==80)
 end
 local s=p.modeLayout
 if s then
  local saved=addon.ProfileCodec.Encode(PTGToolsDB)
  for _,size in ipairs({1000,560,1200}) do
   p.scroll:SetWidth(size);p:Refresh();p:Layout()
   for row,route in pairs(s.routes) do
    -- Display styling is not on these pages (v2): layout_style.py.
    assert(row.editAppearance==nil and row.modePaired==nil and row.modeReplacedNavigation==nil,'no hidden styling rows '..id)
    if not row.sectionHeader and not row.subsectionHeading and (not row.visibleWhen or row.visibleWhen()) then
     assert(row:IsShown(),'unreachable row '..id..' '..(row.settingsTitle or 'toggle'))
     assert(row.points[1][4]==p.contentInset,'one column, no gutter '..id)
     if row.section then assert(row.section.header:IsShown(),'a shown row has its section heading '..id..' '..row.section.title) end
    end
   end
   local last=-1
   for _,section in ipairs(p.sections) do
    local header=section.header
    if header:IsShown() then assert(header.offset>last,'sections run top to bottom '..id);last=header.offset;assert(id=='foundation' or not section.button,'plain group heading (Developer keeps its folds) '..id) end
   end
  end
  assert(addon.ProfileCodec.Encode(PTGToolsDB)==saved,'layout must not edit saved settings '..id)
  -- A search hit scrolls the one page to the row and flashes it.
  for _,entry in ipairs(p.searchEntries) do
   local row=entry.row
   if row.modeRoute and not row.sectionHeader and not row.subsectionHeading then
    -- Hold the 1.5 s fade so the flash can be seen (mock timers fire at once).
    local after,faded=C_Timer.After,nil;C_Timer.After=function(delay,callback) assert(delay==1.5);faded=callback end
    p.scrollbar:SetValue(0);p:Reveal(entry);C_Timer.After=after
    if not row.visibleWhen or row.visibleWhen() then
     assert(row:IsShown(),'search target not visible '..id..' '..entry.label)
     local maximum=select(2,p.scrollbar:GetMinMaxValues())
     assert(p.scrollbar:GetValue()==math.min(math.max(0,row.offset-8),maximum),'search scrolls to the row '..id..' '..entry.label)
     assert(row.searchHighlight:IsShown(),'search flashes the row '..id)
     faded();assert(not row.searchHighlight:IsShown(),'the flash fades')
    end
   end
  end
 end
end
-- Redundant prose is gone; live status and rejection warnings remain, and
-- warnings only appear while something is actually blocked.
local removed={['How It Works']=true,['Visibility Help']=true,['Food Selection']=true,['Move Bar']=true,
 ['Other Addon Suites']=true,['Forecasts']=true,['Session Scope']=true,['Shared Style']=true,['Buffs TLDR']=true,['Contributions TLDR']=true}
for _,id in ipairs(addon.moduleOrder) do
 for _,row in ipairs(addon:EnsureConfigPage(id).rows or {}) do assert(not removed[row.settingsTitle or ''],'redundant note remains '..id..' '..tostring(row.settingsTitle)) end
end
local spark=addon:EnsureConfigPage('lootSparkles')
spark:Layout()
assert(spark.sparkleStatus:GetText()==(addon.LootSparkles:StatusNotice() or ''),'live status keeps its text')
local A=addon.ForeverAutomation;local automation=addon:EnsureConfigPage('foreverAutomation')
automation:Refresh();automation:Layout()
local questRow
for _,row in ipairs(automation.rows) do if row.settingsTitle=='Quest Automation' then questRow=row end end
assert(questRow and not questRow:IsShown(),'no quest status text while nothing is blocked')
A.questBlocked=true;automation:Refresh()
assert(questRow:IsShown() and automation.questStatusLabel:GetText():find('Unavailable this session',1,true),'rejection warning appears')
A.questBlocked=nil;automation:Refresh();assert(not questRow:IsShown())
-- Auto Gossip could never be turned on, so it and its explanation are gone.
for _,row in ipairs(automation.rows) do
 assert(row.settingsTitle~='Auto Gossip Availability' and row.settingsGroupTitle~='Dialogue','no Dialogue placeholder')
 for _,cell in ipairs(row.settingsToggles or {}) do assert(cell.label:GetText()~='Auto Gossip','no Auto Gossip switch') end
end
assert(not A:SetOption('autoGossip',true) and A.GossipCapability==nil)
-- Status rows never just repeat a switch; real notices still show.
local LS=addon.LootSparkles;local sparkRow=spark.sparkleStatus:GetParent().row
LS.status='Loot Sparkles disabled. Previous owned settings restored.';spark:Refresh()
assert(not sparkRow:IsShown() and LS:StatusNotice()==nil,'no on/off echo')
LS.status='Client rejected setting: SoftTargetInteract';spark:Refresh()
assert(sparkRow:IsShown() and spark.sparkleStatus:GetText():find('rejected',1,true),'real notice shown')
LS.status=nil;spark:Refresh();assert(not sparkRow:IsShown())
local found=false
for _,cells in ipairs(spark.toggleGrids) do for _,cell in ipairs(cells) do found=found or cell.label:GetText()=='Enable Loot Sparkles' end end
for _,chip in pairs(spark.sparkleControls) do found=found or chip.label:GetText()=='Enable Loot Sparkles' end
assert(not found and #spark.chipRows==1,'own module since the split: the module switch is the only switch')
local Ro=addon.ForeverRogue;local rogue=addon:EnsureConfigPage('foreverRogue');local was=Ro.active
Ro.active=false;rogue:Refresh();assert(not rogue.poisonStatus:GetParent().row:IsShown(),'no disabled echo')
Ro.active=was;rogue:Refresh()
local CM=addon.CampfireMonitor;local camp=addon:EnsureConfigPage('campfireMonitor');local campOn=CM.module.active
CM.module.active=false;camp:Refresh();camp:Layout();assert(not camp.campfireStatus:GetParent().row:IsShown(),'no Campfire disabled echo')
CM.module.active=campOn;camp:Refresh()
-- Food Bar: one switch for the two saved flags.
local F=addon.ForeverFoodBar;local qa=addon:EnsureConfigPage('foreverQuickAccess');local labels={}
for _,cells in ipairs(qa.toggleGrids) do for _,cell in ipairs(cells) do labels[cell.label:GetText()]=cell end end
assert(labels['Show Food Bar'] and not labels['Enable Food Bar'],'one Food Bar switch')
F.db.enabled,F.db.shown=true,false;assert(not F:IsOn(),'old hidden bar reads off')
assert(F:SetShown(true) and F.db.enabled and F.db.shown and F:IsOn())
assert(F:SetShown(false) and not F.db.enabled and not F.db.shown and not F.active)
qa:Refresh();qa:Layout()
for _,row in ipairs(qa.rows) do if row.settingsTitle=='Food Bar Status' then assert(not row:IsShown(),'no Food Bar status while off') end end
-- Manual refresh buttons are gone: game events update this data.
addon:SetModuleEnabled('foreverClassTraining',true)
local CTm,trainingPage=addon.ForeverClassTraining,addon:EnsureConfigPage('foreverClassTraining')
local manual={Spellbook=true,['Update Learned List']=true,['Carried Items']=true}
for _,page in ipairs({trainingPage,qa}) do for _,row in ipairs(page.rows) do assert(not manual[row.settingsTitle or ''],'manual refresh remains: '..tostring(row.settingsTitle)) end end
assert(trainingPage.refreshButton==nil)
for _,event in ipairs({'SPELLS_CHANGED','LEARNED_SPELL_IN_SKILL_LINE'}) do assert(CTm.eventFrame.events[event],'training listens to '..event) end
local QA=addon.ForeverQuickAccess;addon:SetModuleEnabled('foreverQuickAccess',true)
for _,event in ipairs({'SKILL_LINES_CHANGED','SPELLS_CHANGED'}) do assert(QA.events.events[event],'professions listen to '..event) end
F:SetShown(true);for _,event in ipairs({'BAG_UPDATE_DELAYED','ITEM_DATA_LOAD_RESULT'}) do assert(F.events.events[event],'food listens to '..event) end
F:SetShown(false)
local timer=addon:EnsureConfigPage('combatTimer')
timer.scroll:SetWidth(1000);timer:Layout()
assert(#timer.sections==1 and timer.sections[1].title=='Behavior' and timer.sections[1].header:IsShown(),'the Display section left with its styling rows; Behavior stays')
assert(timer.sections[1].header.offset==0,'the first shown group starts the scroll')
assert(not timer.fontSizeSlider and not timer.fontDropdown and (not timer.settingsColors or #timer.settingsColors==0),'no Combat Timer styling rows')
for _,result in ipairs(addon:SearchSettings('Display')) do assert(not (result.module.id=='combatTimer' and result.kind=='section'),'no search hit for a heading that never shows') end
local clear=timer.scroll.ClearAllPoints
function timer.scroll:ClearAllPoints() self.modeResizeCalls=(self.modeResizeCalls or 0)+1;timer:Layout();clear(self) end
timer:UpdatePreviewLayout();assert(not timer.updatingPreview,'native viewport callbacks cannot recurse through the layout')
timer.scroll.ClearAllPoints=clear
-- Training: the old tab gating is section visibility; the catalog lists
-- upcoming abilities and the rest under their own headings.
local CT=addon.ForeverClassTraining;addon:SetModuleEnabled('foreverClassTraining',true)
local training=addon:EnsureConfigPage('foreverClassTraining')
training:RenderSettings()
assert(#training.sections==3 and training.sections[1].header:IsShown() and training.sections[2].header:IsShown() and training.sections[3].header:IsShown())
CT.db.levelAlerts=false;training:RenderSettings()
assert(not training.sections[2].header:IsShown() and not training.popupPreviewButton:GetParent().row:IsShown(),'Level Up Window hides with its switch')
CT.db.levelAlerts=true;training:RenderSettings()
assert(training.sections[2].header:IsShown())
-- The ability lists are not settings: no section on the page, and the catalog
-- rebuilds in the Class Training window, apart from the settings page.
for _,section in ipairs(training.sections) do assert(section.title~='Upcoming Abilities' and section.title~='Available & Known','lists left the settings page') end
assert(CT:OpenTrainingWindow('Upcoming Abilities') and CT.trainingWindow:IsShown())
local browser=CT.trainingBrowser
browser.catalogVersion=nil;browser:RenderTraining();browser:Layout()
assert(browser.selectedTab=='Upcoming Abilities' and #browser.trainingRows>0,'catalog rebuild in the window')
CT.trainingWindow:Hide()
-- No Quick Actions switch: shortcut settings follow the module switch alone,
-- whatever an old saved showShortcut says.
for _,cells in ipairs(training.toggleGrids) do for _,cell in ipairs(cells) do assert(cell.label:GetText()~='Shortcut Icon & Menu','no ring switch') end end
CT.db.showShortcut=false;training:RenderSettings()
assert(training.sections[3].header:IsShown(),'shortcut settings stay reachable while the module is on')
training:ShowSection(3);assert(training.selectedSection.title=='Shortcut Icon & Menu')
addon:SetModuleEnabled('foreverClassTraining',false);training:RenderSettings()
assert(not training.sections[3].header:IsShown(),'shortcut settings hide with the module')
addon:SetModuleEnabled('foreverClassTraining',true);CT.db.showShortcut=nil;training:ShowSection(1)
-- Rogue: styling lives in Layout; the page's own sliders and switches keep
-- their callbacks, and toggles stay in their own rows at every width.
local R=addon.ForeverRogue
addon:SetModuleEnabled('foreverRogue',true);R:SetOption('flyout',true)
local p=addon:EnsureConfigPage('foreverRogue')
assert(not p.poisonStyles and not p.poisonSliders['watchStyle:fontSize'],'no Rogue styling rows')
local slider=p.poisonSliders['root:threshold'].slider
slider:SetValue(9);assert(R.db.threshold==9,'original slider callback retained')
local charges=p.poisonControls.showPoisonCharges
local old=R.db.showPoisonCharges;charges.button.scripts.OnClick();assert(R.db.showPoisonCharges~=old,'original checkbox callback retained')
-- Searching rogue never offers an unlabelled row.
for _,result in ipairs(addon:SearchSettings('rogue')) do
 assert(not result.entry or (result.entry.label and result.entry.label~=''),'empty search label: '..result.label)
 assert(not result.label:find('> $'),'result ends in an empty label: '..result.label)
end
for _,width in ipairs({1000,560}) do
 p.scroll:SetWidth(width);p:Layout()
 for _,cells in ipairs(p.toggleGrids) do for _,cell in ipairs(cells) do assert(cell.frame:GetParent().row,'toggle stays in its row') end end
end
assert(p.sections[1].header:IsShown() and p.sections[2].header:IsShown() and p.sections[2].header.offset>p.sections[1].header.offset)
-- Dungeon Loot: the settings page holds the former General content; the
-- index and lists are the window's, which has no General tab.
local D=addon.DungeonLoot;addon:SetModuleEnabled('dungeonLoot',true)
addon:SelectConfigPage('dungeonLoot')
local d=D.settingsPage
assert(d:IsShown() and d.bindingControl and d.reload and d.dataSource:GetText()~='','settings page has its original General content')
assert(not d.sectionTabs and #d.sections==3 and d.sections[3].header:IsShown(),'one scroll: Quick Icon, Keybinding, Dungeon Data')
d.iconSize.slider:SetValue(44);assert(D.db.shortcutSize==44,'settings slider keeps native setter')
assert(D:OpenDungeonLoot() and D.window:IsShown() and D.page:IsShown() and D.page:GetParent()==D.window.body)
assert(D.page.general==nil and D.page.modeBrowser==nil,'no General tab in the window')
D.window:Hide()
-- Campfire Monitor has its own one-scroll page since the split, with no pills.
addon:SelectConfigPage('campfireMonitor');local c=addon:EnsureConfigPage('campfireMonitor')
assert(not c.campfirePilot and not c.SelectCampfirePanel and not c.sectionTabs,'no Campfire element pills or panel tabs')
assert(not addon:EnsureConfigPage('lootSparkles').campfireControls,'Loot Sparkles no longer hosts Campfire rows')
testCombat=true;testLockdown=true
p:Layout()
testCombat=false;testLockdown=false
addon.db.window.theme='blizzard'
''')
blizzard,_=load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=SETUP)
blizzard.execute(inventory+'''
addon:ToggleConfig();Inventory()
for _,id in ipairs(addon.moduleOrder) do
 local p=addon:EnsureConfigPage(id);assert(p.modeLayout or (id=='dungeonLoot' and p==addon.DungeonLoot.settingsPage) or (id=='campfireMonitor' and p.campfireControls and not p.campfirePilot),'Blizzard uses the same layout '..id)
 for _,color in ipairs(p.settingsColors or {}) do assert(not color.hex:IsShown() and color.pick:GetWidth()==80,'same picker-only color rows') end
end
''')
print('PASS one scroll per module: inventory, reachability, section order, search scroll/flash, callbacks, browser recycling and identical layout in every theme (mock only)')
