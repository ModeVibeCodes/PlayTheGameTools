"""Actual contribution sliders, numeric fields, reset and Edit Mode controls."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

lua,_=load(before=FIXTURE+EXTRA)
lua.execute(r'''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
local page=M.page;page.sectionTabs.buttons[2].scripts.OnClick()
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
page.contributionPreview.scripts.OnClick()
assert(A.window:IsShown())
-- Native-style hidden rectangles: a re-open must be shown before re-anchoring.
local getCenter=A.window.GetCenter
A.window.GetCenter=function(f) if not f:IsShown() then return nil,nil end;return getCenter(f) end
page.contributionPreview.scripts.OnClick();assert(not A.window:IsShown())
page.contributionPreview.scripts.OnClick();assert(A.window:IsShown() and not A.positionFailure)
local function Numeric(key,text)
 local input=page.campfireSliders[key].numericInput
 input:SetText(text);input.scripts.OnEnterPressed(input)
 return input:GetText()
end
local scale=page.campfireSliders.contributionScale.slider
scale:SetValue(75);assert(C.db.contributionScale==75 and A.window:GetScale()==0.75)
assert(Numeric('contributionScale','83')=='85' and A.window:GetScale()==0.85,'numeric edits snap to supported step')
assert(Numeric('contributionOpacity','63')=='65' and A.window:GetAlpha()==0.65)
assert(Numeric('contributionBackgroundOpacity','52')=='50' and A.window.backdropColor[4]==0.5)
page.contributionEdit.scripts.OnClick()
assert(addon.editMode and A.window.strata=='MEDIUM' and addon.editWindow.strata=='DIALOG','workspace is above the editable panel')
local pm=addon.PositionManager;local e=pm.elements.campfireContributions
assert(pm.selected==e.id and e.decoration.handle:IsShown())
local input=addon.editWindow.xInput
input:SetText('145');input.scripts.OnEnterPressed(input)
assert(C.db.contributionX==145 and pm:GetPosition(e.id).x==145)
input=addon.editWindow.yInput;input:SetText('-65');input.scripts.OnEnterPressed(input)
assert(C.db.contributionY==-65)
e.decoration.handle.scripts.OnDragStart();assert(e.dragging)
A.window.centerX=650;A.window.centerY=420
e.decoration.handle.scripts.OnDragStop();assert(not e.dragging and C.db.contributionX==53 and C.db.contributionY==-43,'scaled drag coordinates')
assert(e.position.x==53 and e.position.y==-43,'round the managed position, not a callback copy')
FireEvent('UNIT_AURA','player')
assert(C.db.contributionX%1==0 and C.db.contributionY%1==0)
assert(Numeric('contributionOpacity','70')=='70' and A.window:GetAlpha()==0.7,'settings still work after fractional drag')
Numeric('contributionOpacity','65')
-- Repair the specific legacy fractional setting without replacing the position.
local legacy=addon.ProfileCodec.Copy(M.db);legacy.campfire.contributionX=52.5;legacy.campfire.contributionY=-43.2
C.Initialize(legacy);assert(legacy.campfire.contributionX==53 and legacy.campfire.contributionY==-43)
addon.editWindow.exitButton.scripts.OnClick()
assert(not addon.editMode and A.window.strata=='DIALOG')
-- Reopen preview after Exit; reset is the actual settings button.
if not A.previewing then page.contributionPreview.scripts.OnClick() end
page.contributionReset.scripts.OnClick()
assert(C.db.contributionX==0 and C.db.contributionY==120)
assert(pm:GetPosition(e.id).x==0 and pm:GetPosition(e.id).y==120)
assert(A.window:GetScale()==0.85 and A.window:GetAlpha()==0.65)
for _,entry in ipairs(page.searchEntries) do
 assert(entry.label~='Crit Color' and entry.label~='Int Color')
end
assert(C:BuffColor('2% Crit')[1]==1 and C:BuffColor('2% Crit')[2]==0.25)
assert(C:BuffColor('4 Int')[1]==0.25 and C:BuffColor('4 Int')[3]==1)
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE+EXTRA)
restored.execute('''
assert(C.db.contributionScale==85 and C.db.contributionOpacity==65 and C.db.contributionBackgroundOpacity==50)
A:TogglePreview();assert(A.window:GetScale()==0.85 and A.window:GetAlpha()==0.65)
assert(C.db.contributionX==0 and C.db.contributionY==120)
''')
print('PASS real sliders/numeric inputs, step normalization, edit layers/coordinates/handle drag/Exit, hidden reopen/reset, fixed Crit/Int and persistence (mock only)')
