"""Icon controls are visible without Customize; real per-icon geometry is styled.
Static UI mocks do not establish in-game rendering or native action acceptance.
"""
from rogue_poisons import SETUP
from smoke import load

lua,_=load(before=SETUP)
lua.execute(r'''
local M=addon.ForeverRogue
addon:SetModuleEnabled('foreverRogue',true);M:SetOption('flyout',true)
addon:ToggleConfig();addon:SelectConfigPage('foreverRogue');local p=M.page
assert(not p.customize and p.iconGroups.watchStyle:IsShown() and p.iconGroups.launcherStyle:IsShown())
local function Visible(frame)
 while frame do if not frame:IsShown() then return false end;frame=frame:GetParent() end
 return true
end
assert(Visible(p.poisonSliders['watchStyle:iconSize']) and Visible(p.poisonSliders['watchStyle:iconGap']))
assert(not p.poisonSliders['watchStyle:iconPadding'] and not p.poisonSliders['launcherStyle:iconPadding'] and not p.poisonSliders['flyoutStyle:iconPadding'])
assert(not p.poisonSliders['watchStyle:spacing'] and not p.poisonSliders['watchStyle:cellWidth'])
assert(Visible(p.poisonSliders['launcherStyle:iconBorderSize']))
assert(not M.watchButtons[1].iconEdges[1]:IsShown() and not M.watchButtons[1].iconBackground:IsShown(),'Default reminder remains bare')
local a,b=M.watchButtons[1],M.watchButtons[2]
local input=p.poisonSliders['watchStyle:iconGap'].numericInput
for _,gap in ipairs({0,8,30,120}) do
 input:SetText(tostring(gap));input.scripts.OnEnterPressed()
 assert(M.db.watchStyle.iconGap==gap and b.points[1][4]-a.points[1][4]-a:GetWidth()==gap,'Gap is the true space between icon buttons')
end
input:SetText('30');input.scripts.OnEnterPressed()
input=p.poisonSliders['watchStyle:iconSize'].numericInput;input:SetText('52');input.scripts.OnEnterPressed()
assert(a:GetWidth()==52 and b:GetWidth()==52 and M.db.launcherStyle.iconSize==40)
M:SetStyle('watchStyle','iconPadding',16)
assert(a.icon.points[1][4]==0 and a.icon.points[2][4]==0,'Legacy image inset is retained but no longer affects artwork')
M:SetStyle('watchStyle','iconBorderSize',4);M:SetStyle('watchStyle','iconBorderOpacity',65)
M:SetStyle('watchStyle','iconBorderColor',{0.2,0.7,0.9});M:SetStyle('watchStyle','iconOpacity',40)
for _,button in ipairs(M.watchButtons) do
 assert(button.iconEdges[1]:IsShown() and button.iconEdges[1].height==4)
 assert(button.iconEdges[1].color[2]==0.7 and button.iconEdges[1].color[4]==0.65)
 assert(button.icon.vertexColor[4]==0.4)
end
assert(M.db.watchStyle.borderSize==0 and M.db.watchStyle.backgroundOpacity==0,'Icon border does not add reminder-window chrome')
M:SetStyle('launcherStyle','iconSize',56);M:SetStyle('launcherStyle','iconPadding',5)
M:SetStyle('launcherStyle','iconBorderSize',3);M:SetStyle('launcherStyle','iconBorderColor',{1,0.3,0.7})
assert(M.openButton.icon.points[1][4]==M.db.launcherStyle.padding+3)
assert(M.openButton.iconEdges[1].height==3 and M.openButton.iconEdges[1].color[1]==1)
assert(M.watchButtons[1].iconEdges[1].height==4,'Two icon styles remain independent')
M:SetStyle('watchStyle','iconBackgroundOpacity',50);M:SetStyle('watchStyle','iconBackgroundColor',{0.1,0.2,0.3})
assert(a.iconBackground:IsShown() and a.iconBackground.color[4]==0.5)
M:SetStyle('watchStyle','iconSize',20);M:SetStyle('watchStyle','iconBorderSize',6)
assert(a.icon.points[1][4]==6 and a.icon.points[2][4]==-6,'Border leaves positive drawable texture area')
assert(not M:SetStyle('watchStyle','iconGap',121) and not M:SetStyle('watchStyle','iconGap',-1))
assert(not M:SetStyle('watchStyle','iconBorderColor',{2,0,0}))
local source=addon.PositionManager:GetPosition('roguePoisonReminder')
M:EnterElementEdit(false);assert(addon.PositionManager.elements.roguePoisonReminder.decoration.frame:IsShown())
addon:SetEditMode(false)
assert(addon.PositionManager:GetPosition('roguePoisonReminder').x==source.x)
M:MinimalReminder();assert(not a.iconEdges[1]:IsShown() and not a.iconBackground:IsShown())
M:SetStyle('watchStyle','iconBorderSize',2)
''')
saved=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded=saved,before=SETUP)
restored.execute(r'''
local M=addon.ForeverRogue
assert(M.db.watchStyle.iconPadding==16 and M.db.watchStyle.iconBorderSize==2 and M.db.watchStyle.iconGap==30)
assert(M.db.launcherStyle.iconSize==56 and M.db.launcherStyle.iconBorderSize==3)
assert(M.openButton.iconEdges[1].height==3)
local defaults={launcherStyle={borderSize=2,borderColor={0.72,0.3,1}},flyoutStyle={borderSize=1,borderColor={0.32,0.4,0.48}},watchStyle={spacing=24,cellWidth=200,iconPadding=10}}
M.Initialize(defaults)
assert(defaults.launcherStyle.borderSize==0 and defaults.launcherStyle.borderColor[1]==0.32 and defaults.flyoutStyle.borderSize==0)
assert(defaults.watchStyle.iconGap==24 and defaults.watchStyle.iconPadding==10 and defaults.watchStyle.cellWidth==200,'Legacy preferences retained while gap migrates')
local custom={launcherStyle={borderSize=4,borderColor={0.1,0.2,0.3},iconBorderSize=3,iconBorderColor={0.72,0.3,1}},flyoutStyle={borderSize=2,borderColor={0.7,0.8,0.9}}}
M.Initialize(custom);assert(custom.launcherStyle.borderSize==4 and custom.launcherStyle.iconBorderSize==3 and custom.flyoutStyle.borderSize==2)
defaults.launcherStyle.borderSize=2;defaults.launcherStyle.borderColor={0.72,0.3,1};M.Initialize(defaults)
assert(defaults.launcherStyle.borderSize==2,'Migration runs once, so border options remain usable')
''')
print('PASS Rogue icon controls: real edge gap, removed inset controls, numeric fields, borderless defaults/custom retention, icon styling, bounds, independence, Minimal, Edit Mode and persistence')
