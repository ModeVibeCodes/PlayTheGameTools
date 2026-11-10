"""Mode-only Campfire layout: reachability, search, callbacks and theme parity."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

baseline,_=load(before=FIXTURE+EXTRA)
baseline.execute('''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
function Keys(t) local out={} for k in pairs(t) do out[#out+1]=k end table.sort(out);return table.concat(out,'|') end
assert(not M.page.campfirePilot,'Modern retains existing grouped page')
assert(M.page.campfireColors.textColor.hex:IsShown() and M.page.campfireColors.textColor.apply:IsShown(),'other themes retain their color editors')
addon.db.window.theme='mode'
addon.db.globalMedia.border='media:PTG Clean'
''')
controls=baseline.eval('Keys(M.page.campfireControls)')
sliders=baseline.eval('Keys(M.page.campfireSliders)')
colors=baseline.eval('Keys(M.page.campfireColors)')
state=baseline.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
lua,_=load(state,before=FIXTURE+EXTRA)
lua.globals().controlKeys=controls
lua.globals().sliderKeys=sliders
lua.globals().colorKeys=colors
lua.execute(r'''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
local page=M.page;page:SelectSectionTab(2)
local pilot=page.campfirePilot
assert(pilot and pilot.bar:IsShown() and pilot.element=='general' and pilot.panel=='options')
function Keys(t) local out={} for k in pairs(t) do out[#out+1]=k end table.sort(out);return table.concat(out,'|') end
assert(Keys(page.campfireControls)==controlKeys and Keys(page.campfireSliders)==sliderKeys and Keys(page.campfireColors)==colorKeys,'all original options retained')
local saved=addon.ProfileCodec.Encode(PTGToolsDB)
local foundControls,foundSliders,foundColors={},{},{}
for _,element in ipairs({'general','monitor','buffs','contributions'}) do
 for _,panel in ipairs(element=='general' and {'options'} or {'options','text','appearance','position'}) do
  page:SelectCampfirePanel(element,panel)
  assert(pilot.element==element and pilot.panel==panel and pilot.buttons[element].selected and pilot.panels[panel].selected)
  assert(pilot.buttons[element].outline.rounded and not pilot.buttons[element].activeGlow:IsShown(),'rounded tabs keep text-only hover/selection')
  assert(pilot.buttons[element].modeFixedSprite,'a custom global border cannot square the pilot tabs')
  local rim=pilot.buttons[element].outline.edges[1]
  assert(rim.modeAsset=='ModePillSurface' and rim.layer=='BACKGROUND' and pilot.buttons[element].fill.layer=='ARTWORK','high-resolution pill border backs the same smooth fill shape')
  assert(pilot.buttons[element].outline.shown and pilot.buttons[element].fill.points[1][4]==1.5,'main pill fill stays inside the outer border')
  if element=='general' then
   assert(page.campfireColors.textColor.host.row:IsShown() and page.campfireControls.enabled.frame:GetParent().row:IsShown(),'General combines Options and Text')
   for _,tab in pairs(pilot.panels) do assert(not tab:IsShown(),'General has no subpage tabs') end
  else
   for id,tab in pairs(pilot.panels) do
    assert(tab.skinStyle=='subTab' and tab:GetHeight()==(id==panel and 30 or 22),'selected subtab untucks while others stay tucked')
    assert(tab.points[1][5]-tab:GetHeight()==-72,'every subtab meets the separator baseline')
   end
  end
  for key,cell in pairs(page.campfireControls) do if cell.frame:GetParent().row:IsShown() then foundControls[key]=true end end
  for key,host in pairs(page.campfireSliders) do if host.row:IsShown() then foundSliders[key]=true end end
  for key,color in pairs(page.campfireColors) do if color.host.row:IsShown() then foundColors[key]=true end end
 end
end
assert(Keys(foundControls)==controlKeys and Keys(foundSliders)==sliderKeys and Keys(foundColors)==colorKeys,'every control is reachable through visible pilot panels')
assert(addon.ProfileCodec.Encode(PTGToolsDB)==saved,'tab changes never write saved options')
page:SelectCampfirePanel('general','text')
assert(pilot.panel=='options' and page.campfireColors.textColor.host.row:IsShown(),'legacy General Text links reveal the combined page')
assert(pilot.textHeader.points[1][4]==page.contentInset and page.layoutInsetLeft==0,'General Text heading aligns with the left page edge')
assert(pilot.textHeader.subsectionHeading.font[2]==20 and pilot.textHeader.campfireUnderline:GetHeight()==1,'prominent content header has a subtle underline')
assert(pilot.summaryTitle.font[2]==20 and pilot.summaryText.color[1]==addon.InterfaceTheme.muted[1],'larger heading and muted description')
for _,color in pairs(page.campfireColors) do assert(not color.hex:IsShown() and not color.apply:IsShown() and color.pick:GetWidth()==80,'pilot color editing uses the picker without redundant hex/Apply controls') end
testMissingTextures={[addon.Media:GetTexture('ModePillSurface')]=true}
local fallback=addon.ConfigWidgets.Button(UIParent,'Pill',156,30,'roundedTab')
assert(fallback.fill.texture==addon.Media:GetTexture('ModeToggleSurface') and fallback.outline.edges[1].texture==addon.Media:GetTexture('ModeToggleSurface'),'an undiscovered capsule uses matching rounded fallback art for border and fill')
testMissingTextures=nil
page:SelectCampfirePanel('monitor','text')
assert(page.campfireSliders.fontSize.row:IsShown() and not page.campfireSliders.x.row:IsShown())
page:SelectCampfirePanel('buffs','text')
assert(page.campfireSliders.benefitsFontSize.row:IsShown() and page.campfireColors.headerColor.host.row:IsShown())
page:SelectCampfirePanel('contributions','text')
local size=page.campfireSliders.contributionTitleSize
local color=page.campfireColors.contributionTitleColor
assert(color.host:GetParent()==size.row and color.host.row==size.row,'text size and color share one row')
for _,role in ipairs({'Background','Border','Row','Hover'}) do
 local opacity=page.campfireSliders['contribution'..role..'Opacity']
 assert(page.campfireColors['contribution'..role..'Color'].host:GetParent()==opacity.row,'color and opacity stay paired')
end
for _,width in ipairs({1000,840,480}) do
 page.scroll:SetWidth(width);page:Layout()
 assert(size.row:GetHeight()==46,'picker-only paired row fits even at the narrow supported width')
 assert(size:GetWidth()>100 and color.host:GetWidth()==80,'removed hex/Apply space goes to the slider')
 assert(pilot.summary:IsShown()==(width~=480) and page.layoutInsetLeft==(width~=480 and 188 or 0),'reference-style left column collapses on narrow pages')
 assert(pilot.togglesLeft==(width~=480) and pilot.inlineHeader:IsShown() and pilot.inlineText:IsShown()==(width~=480),'mixed panels use left toggles and an inline description when space allows, with a visible header at every width')
 local cell=page.campfireControls.contributionUseInterfaceFont
 assert((cell.frame:GetParent()~=page.campfireControls.enabled.frame:GetParent()) and cell.frame:GetWidth()>0)
 if width~=480 then assert(cell.frame:GetWidth()==172 and size.row.points[1][4]==page.contentInset+188,'toggles sit under the left header while sliders stay in the right column') end
 assert(not size.row.divider:IsShown(),'pilot uses group separators instead of per-field lines')
end
-- Existing setters and native picker/cancel still operate from the moved controls.
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
size.numericInput:SetText('21');size.numericInput.scripts.OnEnterPressed(size.numericInput)
assert(C.db.contributionTitleSize==21,'numeric callback retained')
local previous=C.db.contributionTitleColor[1]
color.pick.scripts.OnClick()
ColorPickerFrame.r=.2;ColorPickerFrame.g=.3;ColorPickerFrame.b=.4;ColorPickerFrame.info.swatchFunc()
assert(C.db.contributionTitleColor[1]==.2)
ColorPickerFrame.info.cancelFunc();assert(C.db.contributionTitleColor[1]==previous)
page:SelectSectionTab(1)
assert(not pilot.bar:IsShown() and page.scroll.points[1][5]==-40,'Loot Sparkles keeps its original viewport')
local clear=page.scroll.ClearAllPoints;local anchorChanges=0
function page.scroll:ClearAllPoints() anchorChanges=anchorChanges+1;page:Layout();clear(self) end
page:SelectCampfirePanel('general','options')
assert(anchorChanges==1 and not pilot.layingOut,'native size callbacks cannot recurse through viewport layout')
page.scroll.ClearAllPoints=clear
page.scroll:SetWidth(1000);page:SelectCampfirePanel('buffs','text')
local toggleEntry
for _,entry in ipairs(page.searchEntries) do if entry.label=='Compact Buff Text' then toggleEntry=entry;break end end
assert(toggleEntry and toggleEntry.row~=toggleEntry.campfireBaseRow and toggleEntry.row:IsShown(),'left-column toggle search targets its actual visible host')
page:SelectCampfirePanel('monitor','appearance');page:Reveal(toggleEntry)
assert(pilot.element=='buffs' and pilot.panel=='text' and toggleEntry.row:IsShown(),'search retains routing after toggle reparenting')
page.scroll:SetWidth(480);page:Layout()
assert(toggleEntry.row==toggleEntry.campfireBaseRow and toggleEntry.row:IsShown(),'narrow layout restores normal toggle rows and search targets')
page:SelectSectionTab(1)
local target
for _,entry in ipairs(page.searchEntries) do if entry.label=='Title Color' then target=entry;break end end
assert(target and target.row==size.row)
page:Reveal(target)
assert(page.selectedSection==page.sections[2] and pilot.element=='contributions' and pilot.panel=='text' and size.row:IsShown(),'search reveals the correct element and panel')
for _,id in ipairs({'monitor','buffs','contributions'}) do
 page.campfireJumps[id].scripts.OnClick()
 assert(pilot.element==id and pilot.panel=='options','existing jump callers retain routing')
end
page:SelectCampfirePanel('monitor','position')
page:SelectCampfirePanel('buffs','appearance');page:SelectCampfirePanel('monitor')
assert(pilot.panel=='position','each element remembers its last panel in this session')
page.contributionPreview.scripts.OnClick();assert(A.previewing)
page:SelectCampfirePanel('contributions','text');assert(A.previewing,'editing style does not stop preview')
page:SelectSectionTab(1);assert(not A.previewing,'leaving Campfire retains preview cleanup')
testCombat=true;testLockdown=true
page:SelectCampfirePanel('general','options');assert(pilot.bar:IsShown(),'presentation navigation remains combat safe')
testCombat=false;testLockdown=false
addon.db.window.theme='blizzard'
''')
restored,_=load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=FIXTURE+EXTRA)
restored.globals().controlKeys=controls
restored.execute('''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
local out={} for key in pairs(M.page.campfireControls) do out[#out+1]=key end table.sort(out)
assert(not M.page.campfirePilot and table.concat(out,'|')==controlKeys,'Blizzard retains original controls and layout')
''')
print('PASS Mode-only rounded Campfire panels, complete control parity/reachability, paired text layout, search, callbacks and preview cleanup (mock only)')
