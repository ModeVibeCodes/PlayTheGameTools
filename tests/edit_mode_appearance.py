"""Display styling lives in Edit Mode: selecting a display shows its Text and
Appearance rows there; settings pages and search keep only Options (mock only)."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from rogue_poisons import SETUP
from smoke import load

COMMON = r'''
PM,W=addon.PositionManager,addon.ConfigWidgets
function Click(button) button.scripts.OnClick(button) end
function Visible(frame)
 while frame do if not frame:IsShown() then return false end;frame=frame:GetParent() end
 return true
end
function Style() return addon.editWindow.style end
-- Rows the column is showing now, in order.
function StyleRows()
 local rows={}
 for row in pairs(Style().borrowed) do if row:IsShown() then rows[#rows+1]=row end end
 return rows
end
function Titles()
 local out={}
 for _,row in ipairs(StyleRows()) do
  local title=row.settingsTitle
  if title and title~='' then out[title]=true end
  for _,cell in ipairs(row.settingsToggles or {}) do out[cell.label:GetText()]=true end
 end
 return out
end
-- No settings page shows a row that Edit Mode owns, whatever panel is chosen.
function AssertSettingsClean(id)
 local page=addon:EnsureConfigPage(id)
 for _,row in ipairs(page.rows) do
  if row.editAppearance then assert(not row:IsShown() or row.editBorrowed,'styling row shown in settings '..id..' '..tostring(row.settingsTitle)) end
 end
end
'''

lua, _ = load(before=FIXTURE + EXTRA)
lua.execute(COMMON + r'''
for _,id in ipairs({'combatTimer','enhancedExperienceBar','foreverQuickAccess','lootSparkles'}) do addon:SetModuleEnabled(id,true) end
C:SetOption('enabled',true);C:SetOption('alwaysShow',true)
addon:ToggleConfig()
-- Settings pages offer only Options for display features.
local timer=addon:EnsureConfigPage('combatTimer')
for _,panel in ipairs({'options','text','appearance'}) do
 timer:SelectModePanel('timer',panel);timer:Layout()
 assert(timer.modeLayout.panel=='options','display styling panels are not on the settings page')
 assert(not timer.modeLayout.panels.text:IsShown() and not timer.modeLayout.panels.appearance:IsShown())
end
assert(timer.modeLayout.description:GetText():find('Edit Mode',1,true),'the page says where styling went')
AssertSettingsClean('combatTimer')
local xp=addon:EnsureConfigPage('enhancedExperienceBar')
for _,feature in ipairs({'bar','session'}) do
 for _,panel in ipairs({'options','text','appearance'}) do xp:SelectModePanel(feature,panel);xp:Layout() end
end
AssertSettingsClean('enhancedExperienceBar')
local hide
for _,row in ipairs(xp.rows) do for _,cell in ipairs(row.settingsToggles or {}) do
 assert(cell.label:GetText()~='Hide at Maximum Level','the bar always hides at maximum level')
 if cell.label:GetText()=='Hide Blizzard XP Bar' then hide=row end
end end
assert(hide and not hide.editAppearance and hide.modeRoute.panel=='options','behavior toggles stay in settings')
local camp=addon:EnsureConfigPage('lootSparkles');camp:SelectSectionTab(2)
for _,element in ipairs({'general','monitor','buffs','contributions'}) do
 for _,panel in ipairs({'options','text','appearance'}) do
  camp:SelectCampfirePanel(element,panel)
  assert(camp.campfirePilot.panel=='options')
  for _,tab in pairs(camp.campfirePilot.panels) do assert(not tab:IsShown(),'no Text/Appearance subtabs') end
 end
end
AssertSettingsClean('lootSparkles')
-- Loot Sparkles is not a placeable display; its appearance stays in settings.
camp:SelectSectionTab(1);camp:SelectModePanel('Loot Sparkles','appearance')
assert(camp.modeLayout.panel=='appearance','non-display styling is unchanged')
-- Search never leads to a row that settings no longer show.
for _,query in ipairs({'Font Size','Background opacity','Frame scale','Name Font','Bar Texture','Kit Name Size'}) do
 for _,result in ipairs(addon:SearchSettings(query)) do
  local entry=result.entry
  if entry then
   local row=entry.modeBaseRow or entry.campfireBaseRow or entry.row
   assert(not row.editAppearance,'search offers an Edit Mode row: '..result.label)
  end
 end
end
assert(#addon:SearchSettings('Sparkle Size')>0,'non-display styling remains searchable')

-- Selecting a display shows its own styling, borrowed from the same page.
assert(addon:SetEditMode(true))
local window=addon.editWindow
assert(PM:SelectElement('combatTimer') and Style().element=='combatTimer')
local titles=Titles()
for _,title in ipairs({'Font','Font Size','Text outline','Background opacity','Frame scale'}) do assert(titles[title],'timer styling in Edit Mode: '..title) end
assert(not titles['Timer format'] and not titles['Combat visibility'],'options stay in settings')
assert(Visible(timer.fontSizeSlider) and timer.fontSizeSlider:GetParent().row:GetParent()==Style().content,'same control, now in the column')
assert(Style().headings[1].label:GetText()=='Appearance' and Style().headings[2].label:GetText()=='Text')
assert(Style().headings[1].label:IsShown() and Style().headings[2].label:IsShown())
-- Original callbacks still save the same keys and refresh the live display.
local T=addon.modules.combatTimer
timer.fontSizeInput:SetText('31');timer.fontSizeInput.scripts.OnEnterPressed(timer.fontSizeInput)
assert(T.db.appearance.fontSize==31,'numeric callback kept')
local paired
for _,color in ipairs(timer.settingsColors) do if color.key=='textColor' then paired=color end end
assert(paired.host.row==timer.fontSizeSlider:GetParent().row and Visible(paired.pick),'size and color share a row in the column')
local previous=T.db.appearance.textColor[1]
paired.pick.scripts.OnClick()
ColorPickerFrame.r=.2;ColorPickerFrame.g=.3;ColorPickerFrame.b=.4;ColorPickerFrame.info.swatchFunc()
assert(T.db.appearance.textColor[1]==.2,'picker callback kept')
ColorPickerFrame.info.cancelFunc();assert(T.db.appearance.textColor[1]==previous)
Click(timer.outlineButton);assert(T.db.appearance.outline==false or T.db.appearance.outline==true)
local width,height=window:GetWidth(),window:GetHeight()

-- Multi-feature displays get feature tabs; each tab shows its own rows.
assert(PM:SelectElement('enhancedExperienceBar'))
for row in pairs(Style().borrowed) do assert(row.editAppearance.feature~='timer') end
assert(timer.fontSizeSlider:GetParent().row:GetParent()~=Style().content and not timer.fontSizeSlider:GetParent().row.editBorrowed,'previous display returned its rows')
local tabs=Style().tabs
assert(tabs[1]:IsShown() and tabs[2]:IsShown() and tabs[1].label:GetText()=='XP Bar' and tabs[2].label:GetText()=='Session Text')
assert(tabs[1].selected and Titles()['Bar Texture'] and Titles()['Bar Width'] and Titles()['Bar Font'],'XP bar styling')
Click(tabs[2]);assert(Style().feature=='session' and tabs[2].selected and Titles()['Session Font'] and not Titles()['Bar Texture'])
assert(not Titles()['Session Tracking'],'Reset Session stays in settings')
assert(window:GetWidth()==width and window:GetHeight()==height,'panel keeps its shape')
assert(PM:SelectElement('combatTimer') and PM:SelectElement('enhancedExperienceBar') and Style().feature=='session','feature tab remembered this session')

-- Bars: profession and food bars style independently from one page.
local Q,F=addon.ForeverQuickAccess,addon.ForeverFoodBar
F:SetOption('enabled',true);F:SetOption('shown',true)
addon:SetEditMode(false);assert(addon:SetEditMode(true))
assert(PM.elements.foreverQuickAccess.editMode and PM:SelectElement('foreverQuickAccess'))
local t=Titles();assert(t['Bar Scale'] and t['Name Font'] and t['Name Font Size'] and not t['Show Tooltips'] and not t['Food Bar Scale'])
assert(PM.elements.foreverFoodBar and PM.elements.foreverFoodBar.editMode,'food bar placeable in Edit Mode')
assert(PM:SelectElement('foreverFoodBar'))
t=Titles();assert(t['Food Bar Scale'] and t['Food Font'] and t['Food Font Size'] and not t['Food Tooltips'] and not t['Bar Scale'])

-- Campfire windows: each shows its own rows plus the shared header/text colors.
assert(PM:SelectElement('campfireMonitor'))
local tabLabels={};for _,tab in ipairs(Style().tabs) do if tab:IsShown() then tabLabels[#tabLabels+1]=tab.label:GetText() end end
assert(table.concat(tabLabels,'|')=='Campfire Icon|Camp Buffs|Shared Text','buffs share the icon window by default')
t=Titles();assert(t['Icon Size'] and t['Status Text Size'] and t['Icon Window Scale'] and not t['Show Campfire Icon'])
Click(Style().tabs[3]);t=Titles();assert(t['Text Color'] and not t['Header Color'],'shared text color for both windows')
C:SetOption('showBenefits',true);C:SetOption('separateBenefits',true);PM:RefreshSelection()
assert(PM:SelectElement('campfireBuffs'))
assert(PM:SelectElement('campfireMonitor'))
tabLabels={};for _,tab in ipairs(Style().tabs) do if tab:IsShown() then tabLabels[#tabLabels+1]=tab.label:GetText() end end
assert(table.concat(tabLabels,'|')=='Campfire Icon|Shared Text','separate buffs window styles itself')
-- A hidden separate window cannot be selected, so the icon keeps its buff styling.
C:SetOption('showBenefits',false);PM:RefreshSelection();assert(PM:SelectElement('campfireMonitor'))
tabLabels={};for _,tab in ipairs(Style().tabs) do if tab:IsShown() then tabLabels[#tabLabels+1]=tab.label:GetText() end end
assert(table.concat(tabLabels,'|')=='Campfire Icon|Camp Buffs|Shared Text','buff styling stays reachable')
C:SetOption('showBenefits',true);PM:RefreshSelection()
assert(PM:SelectElement('campfireBuffs'))
Click(Style().tabs[1]);t=Titles();assert(t['Buff Text Size'] and t['Buff Window Scale'] and t['Compact Buff Text'] and t['Header Color'] and t['Header Gradient'] and not t['Separate Buff Window'])
assert(PM:SelectElement('campfireContributions'))
t=Titles();assert(t['Contribution Scale'] and t['Contribution Font'] and t['Title Alignment'] and t['Kit Name Size'] and not t['Show Contribution Popup'])
local size=camp.campfireSliders.contributionTitleSize
assert(Visible(size.slider) and Visible(camp.campfireColors.contributionTitleColor.pick),'paired campfire size/color in the column')
size.numericInput:SetText('21');size.numericInput.scripts.OnEnterPressed(size.numericInput)
assert(C.db.contributionTitleSize==21)

-- Displays with no styling say so instead of showing an empty column.
addon:SetModuleEnabled('threatMeter',true);PM:RefreshSelection()
assert(PM:SelectElement('threatMeter'))
assert(Style().note:IsShown() and Style().note:GetText():find('no text or appearance',1,true) and not Style().scroll:IsShown())
assert(next(Style().borrowed)==nil,'nothing on loan for a display without styling')

-- Leaving Edit Mode returns every row to its page; settings stay clean.
assert(PM:SelectElement('campfireContributions'))
Click(window.exitButton)
assert(not addon.editMode and next(Style().borrowed)==nil and Style().element==nil)
assert(size.row:GetParent()==camp.content and not size.row.editBorrowed,'rows go home')
AssertSettingsClean('lootSparkles');AssertSettingsClean('combatTimer')
-- Typing in a moved field and leaving the mode still commits through its own handler.
assert(addon:SetEditMode(true) and PM:SelectElement('combatTimer'))
timer.fontSizeInput:SetFocus();timer.fontSizeInput:SetText('27');timer.fontSizeInput.scripts.OnEnterPressed(timer.fontSizeInput)
assert(T.db.appearance.fontSize==27)
-- Combat ends Edit Mode and returns rows without touching saved settings.
local saved=addon.ProfileCodec.Encode(PTGToolsDB)
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
assert(not addon.editMode and next(Style().borrowed)==nil and timer.fontSizeSlider:GetParent().row:GetParent()==timer.content)
assert(addon.ProfileCodec.Encode(PTGToolsDB)==saved)
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
''')

rogue, _ = load(before=SETUP)
rogue.execute(COMMON + r'''
local R=addon.ForeverRogue
addon:SetModuleEnabled('foreverRogue',true);R:SetOption('flyout',true)
addon:ToggleConfig();addon:SelectConfigPage('foreverRogue')
local p=R.page
local labels={};for _,button in ipairs(p.modeLayout.buttons) do labels[#labels+1]=button.label:GetText() end
assert(table.concat(labels,'|')=='General|Quick Apply','style-only feature pills left the settings page')
AssertSettingsClean('foreverRogue')
-- Customize opens the display itself in Edit Mode.
Click(p.displayButtons[1])
assert(addon.editMode and Style().element=='roguePoisonReminder')
local t=Titles()
assert(t['Text Font'] and t['Window Background Color'] and t['Show Hand Labels'],'reminder styling')
assert(Visible(p.poisonSliders['watchStyle:iconSize']) and Visible(p.poisonSliders['watchStyle:iconGap']),'icon controls are in the column')
p.poisonSliders['watchStyle:fontSize'].slider:SetValue(19);assert(R.db.watchStyle.fontSize==19,'original slider callback')
local outline=p.poisonStyles.watchStyle.outline;local old=R.db.watchStyle.outline
outline.button.scripts.OnClick();assert(R.db.watchStyle.outline~=old,'original checkbox callback')
-- Style setters refresh the hidden page's loaned rows too.
local layouts,layout=0,Style().Layout
Style().Layout=function(...) layouts=layouts+1;return layout(...) end
assert(R:SetStyle('watchStyle','fontSize',18) and layouts>0,'column refreshes after a style change');Style().Layout=layout
assert(PM:SelectElement('rogueQuickPoisons'))
local tabs=Style().tabs
assert(tabs[1].label:GetText()=='Quick Icon' and tabs[2].label:GetText()=='Expanded Menu')
assert(Visible(p.poisonSliders['launcherStyle:iconBorderSize']) and Visible(p.launcherLabelInput),'quick icon styling')
Click(tabs[2]);assert(Style().feature=='flyoutStyle' and Titles()['Menu Direction'] and Visible(p.poisonSliders['flyoutStyle:iconSize']))
assert(not Visible(p.poisonSliders['launcherStyle:iconBorderSize']),'one feature at a time')
addon:SetEditMode(false)
assert(next(Style().borrowed)==nil and p.launcherLabelInput:GetParent().row:GetParent()==p.content)
AssertSettingsClean('foreverRogue')
''')
print('PASS Edit Mode styling column: per-display Text/Appearance rows with original callbacks, feature tabs, rows returned on exit/combat, settings and search keep Options only (mock only)')
