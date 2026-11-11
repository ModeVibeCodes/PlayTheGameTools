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
   assert(button:GetWidth()>100 and button:GetHeight()==30,'pill must retain a usable click target '..id)
   assert(button.tabX+button.tabWidth<=width,'pills stay inside their resolved viewport '..id)
  end
 end
 strip.buttons[1].scripts.OnClick();assert(p.selectedSection==p.sections[1],'recovered pill is clickable '..id)
end
local quick=addon:EnsureConfigPage('foreverQuickAccess');local quickBar=quick.modeLayout.bar
quickBar:SetWidth(0);quick:Layout()
for _,button in ipairs(quick.modeLayout.buttons) do assert(button:GetWidth()>100,'unresolved custom bar preserves usable pills') end
quickBar:SetWidth(760);quickBar.scripts.OnSizeChanged(quickBar,760,78)
for _,button in ipairs(quick.modeLayout.buttons) do assert(button:GetWidth()>300,'custom pills recover on their own size event') end
local clearBar=quickBar.ClearAllPoints;local barAnchors=0
function quickBar:ClearAllPoints() barAnchors=barAnchors+1;clearBar(self);self.scripts.OnSizeChanged(self,self:GetWidth(),self:GetHeight()) end
quick:Layout();quick:Layout()
assert(barAnchors==0 and not quick.modeLayout.layingOut,'unchanged bar anchors cannot create native size feedback')
quickBar.ClearAllPoints=clearBar
local panels={'options','text','appearance','position'}
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
      if route.feature==s.feature and route.panel==s.panel and not row.sectionHeader and not row.subsectionHeading and not row.modeReplacedNavigation and not row.modePaired and (not row.visibleWhen or row.visibleWhen()) then
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
   if row.modeRoute and not row.sectionHeader and not row.subsectionHeading and not row.modeReplacedNavigation then
    p:Reveal(entry)
    if row.modeRoute.feature==s.feature and (not row.visibleWhen or row.visibleWhen()) then assert(entry.row:IsShown(),'search target not visible '..id..' '..entry.label) end
   end
  end
 end
end
local timer=addon:EnsureConfigPage('combatTimer')
timer.scroll:SetWidth(1000);timer:SelectModePanel('timer','appearance')
assert(timer.layoutInsetLeft==188 and timer.layoutTopInset==0,'wide plain forms keep the heading beside the fields')
timer:SelectModePanel('timer','text')
assert(timer.modeLayout.mixed,'the standalone outline checkbox joins the wide checkbox column')
local paired
for _,color in ipairs(timer.settingsColors) do
 if color.key=='textColor' then paired=color;assert(color.host.row==timer.fontSizeSlider:GetParent().row and color.host.row:IsShown(),'text size and picker share the original slider row') end
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
-- Existing Rogue customization guards still apply, while the new feature pills
-- enter the original presentation state before showing its controls.
local R=addon.ForeverRogue
addon:SetModuleEnabled('foreverRogue',true);R:SetOption('flyout',true)
local p=addon:EnsureConfigPage('foreverRogue')
for _,feature in ipairs({'watchStyle','launcherStyle','flyoutStyle'}) do
 for _,panel in ipairs(panels) do
  p:SelectModePanel(feature,panel);p:Refresh()
  for row,route in pairs(p.modeLayout.routes) do
   if route.feature==feature and route.panel==p.modeLayout.panel and not row.subsectionHeading and (not row.visibleWhen or row.visibleWhen()) then assert(row:IsShown() or row.modeSide) end
  end
 end
end
p:SelectModePanel('watchStyle','text')
local slider=p.poisonSliders['watchStyle:fontSize'].slider
slider:SetValue(19);assert(R.db.watchStyle.fontSize==19,'original slider callback retained')
local outline=p.poisonStyles.watchStyle.outline
local old=R.db.watchStyle.outline;outline.button.scripts.OnClick();assert(R.db.watchStyle.outline~=old,'original checkbox callback retained')
p.scroll:SetWidth(1000);p:Layout()
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
for _,panel in ipairs({'options','appearance','position','data'}) do
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
 local p=addon:EnsureConfigPage(id);assert(not p.modeLayout and not p.modeBrowser,'Blizzard layout stays original')
 for _,color in ipairs(p.settingsColors or {}) do assert(color.hex:IsShown() and (not color.apply or color.apply:IsShown())) end
end
''')
print('PASS Mode module inventory, responsive panels, search, gutter restore, callbacks, browser recycling and theme isolation (mock only)')
