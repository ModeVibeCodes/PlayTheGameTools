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
assert(not CP.campfireColors and not CP.campfireSliders,'v2: no styling rows in any theme')
addon.db.window.theme='mode'
addon.db.globalMedia.border='media:PTG Clean'
''')
controls=baseline.eval('Keys(CP.campfireControls)')
state=baseline.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
lua,_=load(state,before=FIXTURE+EXTRA)
lua.globals().controlKeys=controls
lua.execute(r'''
addon:ToggleConfig();addon:SelectConfigPage('campfireMonitor')
local page=C.module.page
assert(not page.campfirePilot and not page.SelectCampfirePanel and not page.sectionTabs and not page.modeLayout,'its own page: no element pills, panel tabs or section tabs')
assert(#page.sections==0,'its groups are the headings; no section above them')
function Keys(t) local out={} for k in pairs(t) do out[#out+1]=k end table.sort(out);return table.concat(out,'|') end
assert(Keys(page.campfireControls)==controlKeys,'the same switches in every theme')
-- Styling switches left the page with the other Layout styling rows.
for _,key in ipairs({'headerGradient','compactBenefits','colorStats','contributionUseInterfaceFont','contributionOutline','contributionHeaderGradient'}) do
 assert(not page.campfireControls[key],'styling switch removed: '..key)
end
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
assert(not order:find('Contribution Text',1,true),'the styling-only group is gone')
-- Every remaining control is on the page, at every width.
local foundControls={}
for _,width in ipairs({1000,840,480}) do
 page.scroll:SetWidth(width);page:Layout()
 for key,cell in pairs(page.campfireControls) do local row=cell.frame:GetParent().row
  if row:IsShown() then foundControls[key]=true;assert(row.points[1][4]==page.contentInset,'one column') end end
end
assert(page.campfireControls.enabled==nil and page.campfireControls.showInCombat.frame:GetParent().row:IsShown() and page.campfireControls.showContributionPopup.frame:GetParent().row:IsShown())
assert(Keys(foundControls)==controlKeys,'every control is reachable on the page')
for _,row in ipairs(page.rows) do assert(row.editAppearance==nil,'no hidden styling rows') end
assert(addon.ProfileCodec.Encode(PTGToolsDB)==saved,'layout never writes saved options')
local kits=page.campfireControls.contributionShowIcons.frame:GetParent().row
assert(not kits.divider:IsShown(),'compact rows use group headings instead of per-field lines')
-- Existing switch callbacks still operate.
addon:SetModuleEnabled('campfireMonitor',true)
page.campfireControls.contributionShowIcons.frame.scripts.OnClick()
assert(C.db.contributionShowIcons==false,'toggle callback retained')
page.campfireControls.contributionShowIcons.frame.scripts.OnClick()
assert(C.db.contributionShowIcons==true)
-- Search: removed styling rows are never offered; a hit scrolls to and shows its row.
page.scroll:SetWidth(1000);page:Layout()
for _,query in ipairs({'Compact Buff Text','Title Color','Kit Name Size'}) do
 for _,result in ipairs(addon:SearchSettings(query)) do
  assert(result.module.id~='campfireMonitor' or not result.entry or result.entry.kind=='section','no removed styling row offered: '..result.label)
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
print('PASS Campfire groups on one scroll: switch parity/reachability, no styling rows, search scroll, jumps, callbacks and preview cleanup (mock only)')
