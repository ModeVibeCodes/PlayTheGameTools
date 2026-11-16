"""Shared Campfire layout: reachability, search, callbacks and theme parity."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

baseline,_=load(before=FIXTURE+EXTRA)
baseline.execute('''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
function Keys(t) local out={} for k in pairs(t) do out[#out+1]=k end table.sort(out);return table.concat(out,'|') end
assert(M.page.campfirePilot,'Modern uses the same element/panel layout')
assert(not M.page.campfireColors.textColor.hex:IsShown(),'same picker-only color rows in every theme')
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
-- Settings show each element's Options; Text and Appearance are styled in
-- Edit Mode on the matching display (edit_mode_appearance.py).
for _,element in ipairs({'general','monitor','buffs','contributions'}) do
 for _,panel in ipairs({'options','text','appearance'}) do
  page:SelectCampfirePanel(element,panel)
  assert(pilot.element==element and pilot.panel=='options' and pilot.buttons[element].selected)
  assert(pilot.buttons[element].outline.rounded and not pilot.buttons[element].activeGlow:IsShown(),'rounded tabs keep text-only hover/selection')
  assert(pilot.buttons[element].modeFixedSprite,'a custom global border cannot square the pilot tabs')
  local rim=pilot.buttons[element].outline.edges[1]
  assert(rim.modeAsset=='ModePillSurface' and rim.layer=='BACKGROUND' and pilot.buttons[element].fill.layer=='ARTWORK','high-resolution pill border backs the same smooth fill shape')
  assert(pilot.buttons[element].outline.shown and pilot.buttons[element].fill.points[1][4]==1.5,'main pill fill stays inside the outer border')
  if element=='general' then
   assert(page.campfireControls.enabled.frame:GetParent().row:IsShown(),'General shows its options')
   local text=page.campfireColors.textColor.host.row
   assert(text.editAppearance and not text:IsShown(),'shared text color is styled in Edit Mode')
  end
  for _,tab in pairs(pilot.panels) do assert(not tab:IsShown(),'no Text/Appearance subpage tabs in settings') end
  assert(not pilot.panelViewport:IsShown())
  for key,cell in pairs(page.campfireControls) do if cell.frame:GetParent().row:IsShown() then foundControls[key]=true end end
  for key,host in pairs(page.campfireSliders) do if host.row:IsShown() then foundSliders[key]=true end end
  for key,color in pairs(page.campfireColors) do if color.host.row:IsShown() then foundColors[key]=true end end
 end
end
-- Everything not shown here is owned by Edit Mode, never lost.
for key,cell in pairs(page.campfireControls) do if cell.frame:GetParent().row.editAppearance then assert(not foundControls[key]);foundControls[key]=true end end
for key,host in pairs(page.campfireSliders) do if host.row.editAppearance then assert(not foundSliders[key]);foundSliders[key]=true end end
for key,color in pairs(page.campfireColors) do if color.host.row.editAppearance then assert(not foundColors[key]);foundColors[key]=true end end
assert(Keys(foundControls)==controlKeys and Keys(foundSliders)==sliderKeys and Keys(foundColors)==colorKeys,'every control is reachable in settings or Edit Mode')
assert(addon.ProfileCodec.Encode(PTGToolsDB)==saved,'tab changes never write saved options')
page:SelectCampfirePanel('general','text')
assert(pilot.panel=='options' and not page.campfireColors.textColor.host.row:IsShown(),'legacy General Text links land on Options')
assert(page.layoutInsetLeft==0,'General aligns with the left page edge')
assert(pilot.textHeader.subsectionHeading.font[2]==20 and pilot.textHeader.campfireUnderline:GetHeight()==1,'prominent content header has a subtle underline')
assert(pilot.summaryTitle.font[2]==20 and pilot.summaryText.color[1]==addon.InterfaceTheme.muted[1],'larger heading and muted description')
assert(pilot.inlineSeparator.font[2]==14 and pilot.inlineText.points[1][4]==8,'larger separator and tighter description gap')
for _,entry in ipairs(pilot.headerLines) do
 local line,heading=entry.line,entry.heading
 local measured=math.min(heading:GetStringWidth(),math.max(8,heading:GetWidth()))
 assert(line:GetHeight()==1 and line.modeAsset=='ModeHeaderLine','all content headings share the same thin fading rule')
 assert(math.abs(line.points[1][4]+line:GetWidth()/2-measured/2)<.001,'underline center matches the visible left-aligned heading text')
end
for _,color in pairs(page.campfireColors) do assert(not color.hex:IsShown() and not color.apply:IsShown() and color.pick:GetWidth()==80,'pilot color editing uses the picker without redundant hex/Apply controls') end
testMissingTextures={[addon.Media:GetTexture('ModePillSurface')]=true}
local fallback=addon.ConfigWidgets.Button(UIParent,'Pill',156,30,'roundedTab')
assert(fallback.fill.texture==addon.Media:GetTexture('ModeToggleSurface') and fallback.outline.edges[1].texture==addon.Media:GetTexture('ModeToggleSurface'),'an undiscovered capsule uses matching rounded fallback art for border and fill')
testMissingTextures=nil
page:SelectCampfirePanel('monitor','text')
assert(page.campfireSliders.fontSize.row.editAppearance and not page.campfireSliders.fontSize.row:IsShown() and not page.campfireSliders.x,'placement and styling live in Edit Mode')
page:SelectCampfirePanel('buffs','text')
assert(page.campfireSliders.benefitsFontSize.row.editAppearance and page.campfireColors.headerColor.host.row.editAppearance)
page:SelectCampfirePanel('contributions','text')
local size=page.campfireSliders.contributionTitleSize
local color=page.campfireColors.contributionTitleColor
assert(color.host:GetParent()==size.row and color.host.row==size.row,'text size and color share one row')
for _,role in ipairs({'Background','Border','Row','Hover'}) do
 local opacity=page.campfireSliders['contribution'..role..'Opacity']
 assert(page.campfireColors['contribution'..role..'Color'].host:GetParent()==opacity.row,'color and opacity stay paired')
end
for _,width in ipairs({1000,840,480}) do
 page.scroll:SetWidth(width);pilot.bar:SetWidth(width);page:Layout()
 assert(size.row:GetHeight()==46,'picker-only paired row fits even at the narrow supported width')
 assert(size:GetWidth()>100 and color.host:GetWidth()==80,'removed hex/Apply space goes to the slider')
 assert(pilot.summary:IsShown()==(width~=480) and page.layoutInsetLeft==(width~=480 and 188 or 0),'reference-style left column collapses on narrow pages')
 -- Options here are checkboxes only, so no left checkbox column is needed.
 assert(not pilot.togglesLeft and pilot.inlineHeader:IsShown()==(width==480) and not pilot.inlineText:IsShown(),'compact header only on narrow pages')
 local cell=page.campfireControls.contributionUseInterfaceFont
 assert((cell.frame:GetParent()~=page.campfireControls.enabled.frame:GetParent()) and cell.frame:GetWidth()>0)
 assert(not size.row.divider:IsShown(),'pilot uses group separators instead of per-field lines')
 local first,last=pilot.buttons.general,pilot.buttons.contributions
 local left=first.points[1][4];local right=last.points[1][4]+last:GetWidth()
 assert(left>=0 and right<=width and math.abs((left+right)/2-width/2)<.001,'pill row stays centered within the page at each width')
 assert(first:GetWidth()==last:GetWidth() and first.points[1][5]==last.points[1][5] and not last.label.wordWrap,'pills resize equally on one row')
 assert(first:GetWidth()<=128 and first:GetWidth()/first:GetHeight()==4,'primary capsules keep the same preferred size and circular end proportions')
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
assert(not pilot.bar:IsShown() and page.modeLayout.bar:IsShown() and page.scroll.points[1][5]==-page.modeLayout.viewportTop,'Loot Sparkles uses the shared Mode panels independently of the approved Campfire pilot')
local clear=page.scroll.ClearAllPoints;local anchorChanges=0
function page.scroll:ClearAllPoints() anchorChanges=anchorChanges+1;page:Layout();clear(self) end
page:SelectCampfirePanel('general','options')
assert(anchorChanges==1 and not pilot.layingOut,'native size callbacks cannot recurse through viewport layout')
page.scroll.ClearAllPoints=clear
page.scroll:SetWidth(1000)
for _,query in ipairs({'Compact Buff Text','Title Color','Kit Name Size'}) do
 for _,result in ipairs(addon:SearchSettings(query)) do
  local row=result.entry and (result.entry.campfireBaseRow or result.entry.row)
  assert(not (row and row.editAppearance),'settings search does not offer Edit Mode styling: '..result.label)
 end
end
page:SelectSectionTab(1)
local target
for _,entry in ipairs(page.searchEntries) do if entry.label=='Show Kit Icons' then target=entry;break end end
assert(target)
page:Reveal(target)
assert(page.selectedSection==page.sections[2] and pilot.element=='contributions' and pilot.panel=='options' and target.row:IsShown(),'search reveals the correct element')
for _,id in ipairs({'monitor','buffs','contributions'}) do
 page.campfireJumps[id].scripts.OnClick()
 assert(pilot.element==id and pilot.panel=='options','existing jump callers retain routing')
end
page:SelectCampfirePanel('monitor','appearance')
page:SelectCampfirePanel('buffs','text');page:SelectCampfirePanel('monitor')
assert(pilot.panel=='options','settings always show Options')
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
assert(M.page.campfirePilot and table.concat(out,'|')==controlKeys,'Blizzard uses the same controls and layout')
''')
print('PASS shared rounded Campfire panels, complete control parity/reachability, paired text layout, search, callbacks and preview cleanup (mock only)')
