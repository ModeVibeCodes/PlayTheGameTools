"""Mode rollout: full settings inventory, route/search reachability and theme parity.

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
-- Native anchored viewports resolve after their strip. The mock normally gives
-- unsized frames 1024 units, which previously hid this startup ordering bug.
for _,id in ipairs({'foreverGuildRoster','lootSparkles','foreverClassTraining'}) do
 local p=addon:EnsureConfigPage(id);local strip=p.sectionTabs;local viewport=strip.viewport
 local widths={};for i,button in ipairs(strip.buttons) do widths[i]=button:GetWidth() end
 viewport:SetWidth(0);strip:Layout()
 for i,button in ipairs(strip.buttons) do assert(button:GetWidth()==widths[i],'unresolved viewport must not shrink existing click targets '..id) end
 assert(viewport.scripts.OnSizeChanged,'resolved viewport needs its own layout notification '..id)
 for _,width in ipairs({900,720,1080}) do
  viewport:SetWidth(width);viewport.scripts.OnSizeChanged(viewport,width,34)
  for _,button in ipairs(strip.buttons) do
   assert(button:GetWidth()==128 and button:GetHeight()==32,'primary pills have the same default size across pages '..id)
   assert(button.tabX+button.tabWidth<=width,'pills stay inside their resolved viewport '..id)
   assert(-button.points[1][5]+button:GetHeight()<strip:GetHeight(),'rounded border clears the clipping viewport '..id)
  end
  local first,last=strip.buttons[1],strip.buttons[#strip.buttons]
  assert(math.abs((first.tabX+last.tabX+last.tabWidth)/2-width/2)<.001,'fixed-size pill group stays centered '..id)
  assert(not strip.baseline:IsShown(),'no baseline touches the pill border '..id)
 end
 strip.buttons[1].scripts.OnClick();assert(p.selectedSection==p.sections[1],'recovered pill is clickable '..id)
end
local quick=addon:EnsureConfigPage('foreverQuickAccess');local quickBar=quick.modeLayout.bar
quickBar:SetWidth(0);quick:Layout()
for _,button in ipairs(quick.modeLayout.buttons) do assert(button:GetWidth()>100,'unresolved custom bar preserves usable pills') end
quickBar:SetWidth(760);quickBar.scripts.OnSizeChanged(quickBar,760,78)
for _,button in ipairs(quick.modeLayout.buttons) do assert(button:GetWidth()==128 and button:GetHeight()==32,'custom pills recover at the common size on their own size event') end
local clearBar=quickBar.ClearAllPoints;local barAnchors=0
function quickBar:ClearAllPoints() barAnchors=barAnchors+1;clearBar(self);self.scripts.OnSizeChanged(self,self:GetWidth(),self:GetHeight()) end
quick:Layout();quick:Layout()
assert(barAnchors==0 and not quick.modeLayout.layingOut,'unchanged bar anchors cannot create native size feedback')
quickBar.ClearAllPoints=clearBar
local panels={'options','text','appearance'}
for _,id in ipairs(addon.moduleOrder) do
 addon:SelectConfigPage(id)
 local p=addon:EnsureConfigPage(id)
 if id~='dungeonLoot' then assert(p.modeLayout,'Mode rollout missing '..id) else assert(p.modeBrowser) end
 for _,color in ipairs(p.settingsColors or {}) do
  assert(not color.hex:IsShown() and (not color.apply or not color.apply:IsShown()),'native picker replaces redundant fields '..id)
  assert(color.pick:GetWidth()==80)
 end
 local s=p.modeLayout
 if s and not s.plan.decorateOnly then
  local saved=addon.ProfileCodec.Encode(PTGToolsDB)
  for _,size in ipairs({1000,560,1200}) do
   p.scroll:SetWidth(size)
   for _,feature in ipairs(s.features) do
    for _,panel in ipairs(panels) do
     p:SelectModePanel(feature[1],panel);p:Refresh();p:Layout()
     for row,route in pairs(s.routes) do
      -- Display styling (editAppearance) is reached in Edit Mode: edit_mode_appearance.py.
      if route.feature==s.feature and route.panel==s.panel and not row.editAppearance and not row.sectionHeader and not row.subsectionHeading and not row.modeReplacedNavigation and not row.modePaired and (not row.visibleWhen or row.visibleWhen()) then
       assert(row:IsShown() or row.modeSide,'unreachable route '..id..' '..(row.settingsTitle or 'toggle'))
      end
     end
     if not p.campfirePilot or p.selectedSection.title=='Loot Sparkles' then
      assert(s.underline.modeAsset=='ModeHeaderLine' and s.underline:GetHeight()==1 and s.heading.font[2]==20)
      assert(s.panelViewport:GetHeight()==34)
      for panelID,button in pairs(s.panels) do
       if button:IsShown() then
        assert(button.skinStyle=='subTab' and button:GetHeight()==30)
        assert(button.points[1][5]==(s.panel==panelID and -4 or -12),'tab tucks below clipped baseline')
       end
      end
     end
    end
   end
  end
  assert(addon.ProfileCodec.Encode(PTGToolsDB)==saved,'navigation must not edit saved settings '..id)
  for _,entry in ipairs(p.searchEntries) do
   local row=entry.modeBaseRow or entry.row
   if row.modeRoute and not row.editAppearance and not row.sectionHeader and not row.subsectionHeading and not row.modeReplacedNavigation then
    p:Reveal(entry)
    if row.modeRoute.feature==s.feature and (not row.visibleWhen or row.visibleWhen()) then assert(entry.row:IsShown(),'search target not visible '..id..' '..entry.label) end
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
spark:SelectModePanel('Loot Sparkles','options');spark:Layout()
assert(spark.sparkleStatus:GetText()==(addon.LootSparkles:StatusNotice() or ''),'live status keeps its text')
local A=addon.ForeverAutomation;local automation=addon:EnsureConfigPage('foreverAutomation')
automation:SelectModePanel('Quests','options');automation:Refresh();automation:Layout()
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
assert(found,'Loot Sparkles keeps its own switch: the page switch also covers Campfire Monitor')
local Ro=addon.ForeverRogue;local rogue=addon:EnsureConfigPage('foreverRogue');local was=Ro.active
Ro.active=false;rogue:Refresh();assert(not rogue.poisonStatus:GetParent().row:IsShown(),'no disabled echo')
Ro.active=was;rogue:Refresh()
local CM=addon.CampfireMonitor;local campOn=CM.db.enabled
CM.db.enabled=false;spark:Refresh();spark:Layout();assert(not spark.campfireStatus:GetParent().row:IsShown(),'no Campfire disabled echo')
CM.db.enabled=campOn;spark:Refresh()
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
timer.scroll:SetWidth(1000);timer:SelectModePanel('timer','appearance')
assert(timer.modeLayout.panel=='options','timer styling is edited in Edit Mode')
assert(timer.layoutInsetLeft==188 and timer.layoutTopInset==0,'wide plain forms keep the heading beside the fields')
local paired
for _,color in ipairs(timer.settingsColors) do
 if color.key=='textColor' then paired=color;assert(color.host.row==timer.fontSizeSlider:GetParent().row and color.host.row.editAppearance,'text size and picker share the original slider row') end
end
assert(paired)
local clear=timer.scroll.ClearAllPoints
function timer.scroll:ClearAllPoints() self.modeResizeCalls=(self.modeResizeCalls or 0)+1;timer:Layout();clear(self) end
timer:UpdatePreviewLayout();assert(not timer.modeLayout.layingOut and not timer.updatingPreview,'native viewport callbacks cannot recurse through the new layout')
timer.scroll.ClearAllPoints=clear
-- Training keeps its original gating and can rebuild catalog rows after layout.
local CT=addon.ForeverClassTraining;addon:SetModuleEnabled('foreverClassTraining',true)
local training=addon:EnsureConfigPage('foreverClassTraining')
training:SelectModePanel('Level Up Window','text')
assert(training.selectedSection.title=='Level Up Window' and training.modeLayout.panel=='text')
CT.db.levelAlerts=false;training:RenderTraining();assert(training.selectedSection.title=='General','disabled feature tab still falls back to General')
CT.db.levelAlerts=true;training:SelectModePanel('Upcoming Abilities','options')
training.catalogVersion=nil;training:RenderTraining();training:Layout()
assert(training.selectedSection.title=='Upcoming Abilities' and not training.modeLayout.bar:IsShown(),'catalog rebuild stays independent of settings panels')
-- No Quick Actions switch: the shortcut tab follows the module switch alone,
-- whatever an old saved showShortcut says.
for _,cells in ipairs(training.toggleGrids) do for _,cell in ipairs(cells) do assert(cell.label:GetText()~='Shortcut Icon & Menu','no ring switch') end end
CT.db.showShortcut=false;training:RenderTraining()
assert(training.sectionTabs.buttons[3].enabled==true,'shortcut settings stay reachable while the module is on')
training:SelectSectionTab(3);assert(training.selectedSection.title=='Shortcut Icon & Menu')
CT.db.showShortcut=nil;training:SelectSectionTab(1)
-- Existing Rogue customization guards still apply, while the new feature pills
-- enter the original presentation state before showing its controls.
local R=addon.ForeverRogue
addon:SetModuleEnabled('foreverRogue',true);R:SetOption('flyout',true)
local p=addon:EnsureConfigPage('foreverRogue')
for _,feature in ipairs({'watchStyle','launcherStyle','flyoutStyle'}) do
 for _,panel in ipairs(panels) do
  p:SelectModePanel(feature,panel);p:Refresh()
  for row,route in pairs(p.modeLayout.routes) do
   if route.feature==feature and route.panel==p.modeLayout.panel and not row.editAppearance and not row.subsectionHeading and (not row.visibleWhen or row.visibleWhen()) then assert(row:IsShown() or row.modeSide) end
  end
 end
end
p:SelectModePanel('watchStyle','text')
local slider=p.poisonSliders['watchStyle:fontSize'].slider
slider:SetValue(19);assert(R.db.watchStyle.fontSize==19,'original slider callback retained')
local outline=p.poisonStyles.watchStyle.outline
local old=R.db.watchStyle.outline;outline.button.scripts.OnClick();assert(R.db.watchStyle.outline~=old,'original checkbox callback retained')
p:SelectModePanel('general','options');p.scroll:SetWidth(1000);p:Layout()
assert(p.modeLayout.mixed and p.layoutInsetLeft==188,'wide mixed settings use the approved left checkbox gutter')
for _,group in ipairs(p.modeLayout.groups) do
 if group.row.modeSide then
  assert(group.host:IsShown())
  for i,cell in ipairs(group.cells) do assert(cell.frame:GetParent()==group.host and cell.frame.points[1][5]==-(i-1)*42) end
 end
end
p.scroll:SetWidth(560);p:Layout()
assert(not p.modeLayout.mixed and p.layoutInsetLeft==0,'narrow layout restores in-flow toggles')
for _,group in ipairs(p.modeLayout.groups) do for _,cell in ipairs(group.cells) do assert(cell.frame:GetParent()==group.original) end end
-- Source data-browser navigation and row recycling keep independent visibility.
local D=addon.DungeonLoot;addon:SetModuleEnabled('dungeonLoot',true)
addon:SelectConfigPage('dungeonLoot');D:Navigate(nil,'general')
local d=D.page
for _,panel in ipairs({'options','appearance','data'}) do
 d:SelectModeBrowserPanel(panel);d:Refresh()
 local visible=0
 for _,slot in ipairs(d.rootPane.slots) do
  if slot.visible and slot.row.settingsBrowserPanel==panel then assert(slot.row:IsShown());visible=visible+1
  elseif slot.visible and slot.row.settingsBrowserPanel then assert(not slot.row:IsShown()) end
 end
 assert(visible>0,'browser General panel has all its original content')
end
D:Navigate(nil);assert(not d.modeBrowser.viewport:IsShown(),'General panels hide in the catalog')
D:Navigate(nil,'general');d:SelectModeBrowserPanel('appearance')
d.iconSize.slider:SetValue(44);assert(D.db.shortcutSize==44,'browser slider keeps native setter')
-- Shared selection code never changes the Campfire pilot or its preview cleanup.
addon:SelectConfigPage('lootSparkles');local c=addon:EnsureConfigPage('lootSparkles')
for i=1,3 do
 c:SelectCampfirePanel('monitor','text');assert(c.campfirePilot.bar:IsShown() and not c.modeLayout.bar:IsShown())
 c:SelectSectionTab(1);c:SelectModePanel('Loot Sparkles','text');assert(c.modeLayout.header:IsShown() and not c.campfirePilot.bar:IsShown())
end
testCombat=true;testLockdown=true
p:SelectModePanel('launcherStyle','text');d:SelectModeBrowserPanel('options')
testCombat=false;testLockdown=false
addon.db.window.theme='blizzard'
''')
blizzard,_=load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=SETUP)
blizzard.execute(inventory+'''
addon:ToggleConfig();Inventory()
for _,id in ipairs(addon.moduleOrder) do
 local p=addon:EnsureConfigPage(id);assert(p.modeLayout or p.modeBrowser,'Blizzard uses the same layout '..id)
 for _,color in ipairs(p.settingsColors or {}) do assert(not color.hex:IsShown() and color.pick:GetWidth()==80,'same picker-only color rows') end
end
''')
print('PASS Mode module inventory, responsive panels, search, gutter restore, callbacks, browser recycling and identical layout in every theme (mock only)')
