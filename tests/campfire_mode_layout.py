"""Campfire Monitor's own one-scroll page: reachability, search, callbacks and theme parity."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

baseline,_=load(before=FIXTURE+EXTRA)
baseline.execute('''
addon:ToggleConfig();addon:SelectConfigPage('campfireMonitor')
function Keys(t) local out={} for k in pairs(t) do out[#out+1]=k end table.sort(out);return table.concat(out,'|') end
CP=C.module.page
assert(not CP.campfirePilot,'Modern uses the same one-scroll layout')
assert(not CP.campfireColors.textColor.hex:IsShown(),'same picker-only color rows in every theme')
addon.db.window.theme='mode'
addon.db.globalMedia.border='media:PTG Clean'
''')
controls=baseline.eval('Keys(CP.campfireControls)')
sliders=baseline.eval('Keys(CP.campfireSliders)')
colors=baseline.eval('Keys(CP.campfireColors)')
state=baseline.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
lua,_=load(state,before=FIXTURE+EXTRA)
lua.globals().controlKeys=controls
lua.globals().sliderKeys=sliders
lua.globals().colorKeys=colors
lua.execute(r'''
addon:ToggleConfig();addon:SelectConfigPage('campfireMonitor')
local page=C.module.page
assert(not page.campfirePilot and not page.SelectCampfirePanel and not page.sectionTabs and not page.modeLayout,'its own page: no element pills, panel tabs or section tabs')
assert(#page.sections==0,'its groups are the headings; no section above them')
function Keys(t) local out={} for k in pairs(t) do out[#out+1]=k end table.sort(out);return table.concat(out,'|') end
assert(Keys(page.campfireControls)==controlKeys and Keys(page.campfireSliders)==sliderKeys and Keys(page.campfireColors)==colorKeys,'all original options retained')
local saved=addon.ProfileCodec.Encode(PTGToolsDB)
-- Every group heading with a visible row shows, top to bottom, in build order.
local headings,last={},-1
for _,row in ipairs(page.rows) do
 if row.subsectionHeading and row:IsShown() then
  headings[#headings+1]=row.subsectionHeading:GetText();assert(row.offset>last,'groups run top to bottom');last=row.offset
 end
end
local order=table.concat(headings,'|')
assert(order:find('^General|Campfire Icon|Camp Buffs|Camp Contributions'),'element groups replace the pills: '..order)
assert(not order:find('Contribution Text',1,true),'a group holding only Layout styling has no heading')
-- Every control is on the page or styled in Layout, never lost.
local foundControls,foundSliders,foundColors={},{},{}
for _,width in ipairs({1000,840,480}) do
 page.scroll:SetWidth(width);page:Layout()
 for key,cell in pairs(page.campfireControls) do local row=cell.frame:GetParent().row
  if row:IsShown() then foundControls[key]=true;assert(row.points[1][4]==page.contentInset,'one column') end end
 for key,host in pairs(page.campfireSliders) do if host.row:IsShown() then foundSliders[key]=true end end
 for key,color in pairs(page.campfireColors) do if color.host.row:IsShown() then foundColors[key]=true end end
end
assert(page.campfireControls.enabled==nil and page.campfireControls.showInCombat.frame:GetParent().row:IsShown() and page.campfireControls.showContributionPopup.frame:GetParent().row:IsShown())
local text=page.campfireColors.textColor.host.row
assert(text.editAppearance and not text:IsShown(),'shared text color is styled in Layout')
for key,cell in pairs(page.campfireControls) do if cell.frame:GetParent().row.editAppearance then assert(not foundControls[key]);foundControls[key]=true end end
for key,host in pairs(page.campfireSliders) do if host.row.editAppearance then assert(not foundSliders[key]);foundSliders[key]=true end end
for key,color in pairs(page.campfireColors) do if color.host.row.editAppearance then assert(not foundColors[key]);foundColors[key]=true end end
assert(Keys(foundControls)==controlKeys and Keys(foundSliders)==sliderKeys and Keys(foundColors)==colorKeys,'every control is reachable in settings or Layout')
assert(addon.ProfileCodec.Encode(PTGToolsDB)==saved,'layout never writes saved options')
assert(page.campfireSliders.fontSize.row.editAppearance and not page.campfireSliders.fontSize.row:IsShown() and not page.campfireSliders.x,'placement and styling live in Layout')
assert(page.campfireSliders.benefitsFontSize.row.editAppearance and page.campfireColors.headerColor.host.row.editAppearance)
for _,color in pairs(page.campfireColors) do assert(not color.hex:IsShown() and not color.apply:IsShown() and color.pick:GetWidth()==80,'picker-only color rows') end
-- Paired size/color rows keep their shape for the Layout styling rows.
local size=page.campfireSliders.contributionTitleSize
local color=page.campfireColors.contributionTitleColor
assert(color.host:GetParent()==size.row and color.host.row==size.row,'text size and color share one row')
for _,role in ipairs({'Background','Border','Row','Hover'}) do
 local opacity=page.campfireSliders['contribution'..role..'Opacity']
 assert(page.campfireColors['contribution'..role..'Color'].host:GetParent()==opacity.row,'color and opacity stay paired')
end
for _,width in ipairs({1000,480}) do
 size.row:layoutChildren(width-24)
 assert(size.row:GetHeight()==46 and size:GetWidth()>100 and color.host:GetWidth()==80,'paired row fits at every supported width')
end
assert(not size.row.divider:IsShown(),'compact rows use group headings instead of per-field lines')
-- Existing setters and native picker/cancel still operate.
addon:SetModuleEnabled('campfireMonitor',true)
size.numericInput:SetText('21');size.numericInput.scripts.OnEnterPressed(size.numericInput)
assert(C.db.contributionTitleSize==21,'numeric callback retained')
local previous=C.db.contributionTitleColor[1]
color.pick.scripts.OnClick()
ColorPickerFrame.r=.2;ColorPickerFrame.g=.3;ColorPickerFrame.b=.4;ColorPickerFrame.info.swatchFunc()
assert(C.db.contributionTitleColor[1]==.2)
ColorPickerFrame.info.cancelFunc();assert(C.db.contributionTitleColor[1]==previous)
-- Search: no Layout styling offered; a hit scrolls to and shows its row.
page.scroll:SetWidth(1000);page:Layout()
for _,query in ipairs({'Compact Buff Text','Title Color','Kit Name Size'}) do
 for _,result in ipairs(addon:SearchSettings(query)) do
  local row=result.entry and result.entry.row
  assert(not (row and row.editAppearance),'settings search does not offer Layout styling: '..result.label)
 end
end
page:ShowSection(1)
local target
for _,entry in ipairs(page.searchEntries) do if entry.label=='Show Kit Icons' then target=entry;break end end
assert(target)
page:Reveal(target)
local maximum=select(2,page.scrollbar:GetMinMaxValues())
assert(target.row:IsShown() and page.scrollbar:GetValue()==math.min(target.row.offset-8,maximum),'search scrolls to the row')
for _,id in ipairs({'monitor','buffs','contributions'}) do
 page.campfireJumps[id].scripts.OnClick()
 local heading=page.campfireJumpTargets[id].row
 assert(heading.subsectionHeading and heading:IsShown() and page.scrollbar:GetValue()==math.min(heading.offset-8,maximum),'existing jump callers scroll to the group')
end
page.contributionPreview.scripts.OnClick();assert(A.previewing)
page:ShowSection(1);assert(A.previewing,'scrolling keeps the preview')
addon:SelectConfigPage('lootSparkles');assert(not A.previewing,'leaving the page ends the preview')
local spark=addon:EnsureConfigPage('lootSparkles')
assert(not spark.campfirePilot and spark.modeLayout and not spark.sectionTabs,'Loot Sparkles uses the shared one-scroll layout on its own page')
addon:SelectConfigPage('campfireMonitor')
testCombat=true;testLockdown=true
page:ShowSection(1);page:Layout();assert(page.campfireControls.showInCombat.frame:GetParent().row:IsShown(),'scrolling stays combat safe')
testCombat=false;testLockdown=false
addon.db.window.theme='blizzard'
''')
restored,_=load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=FIXTURE+EXTRA)
restored.globals().controlKeys=controls
restored.execute('''
addon:ToggleConfig();addon:SelectConfigPage('campfireMonitor')
local out={} for key in pairs(C.module.page.campfireControls) do out[#out+1]=key end table.sort(out)
assert(not C.module.page.campfirePilot and table.concat(out,'|')==controlKeys,'Blizzard uses the same controls and layout')
''')
print('PASS Campfire groups on one scroll: complete control parity/reachability, paired text layout, search scroll, jumps, callbacks and preview cleanup (mock only)')
