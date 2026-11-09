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
assert(Visible(p.poisonSliders['watchStyle:iconSize']) and Visible(p.poisonSliders['watchStyle:spacing']))
assert(Visible(p.poisonSliders['watchStyle:iconPadding']) and Visible(p.poisonSliders['launcherStyle:iconBorderSize']))
assert(not M.watchButtons[1].iconEdges[1]:IsShown() and not M.watchButtons[1].iconBackground:IsShown(),'Default reminder remains bare')
local a,b=M.watchButtons[1],M.watchButtons[2]
local initial=b.points[1][4]-a.points[1][4];local oldSpacing=M.db.watchStyle.spacing
local input=p.poisonSliders['watchStyle:spacing'].numericInput
input:SetText('30');input.scripts.OnEnterPressed()
assert(M.db.watchStyle.spacing==30 and b.points[1][4]-a.points[1][4]==initial+30-oldSpacing)
input=p.poisonSliders['watchStyle:iconSize'].numericInput;input:SetText('52');input.scripts.OnEnterPressed()
assert(a:GetWidth()==52 and b:GetWidth()==52 and M.db.launcherStyle.iconSize==40)
input=p.poisonSliders['watchStyle:iconPadding'].numericInput;input:SetText('6');input.scripts.OnEnterPressed()
assert(a.icon.points[1][4]==6 and a.icon.points[2][4]==-6)
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
assert(M.openButton.icon.points[1][4]==M.db.launcherStyle.padding+5)
assert(M.openButton.iconEdges[1].height==3 and M.openButton.iconEdges[1].color[1]==1)
assert(M.watchButtons[1].iconEdges[1].height==4,'Two icon styles remain independent')
M:SetStyle('watchStyle','iconBackgroundOpacity',50);M:SetStyle('watchStyle','iconBackgroundColor',{0.1,0.2,0.3})
assert(a.iconBackground:IsShown() and a.iconBackground.color[4]==0.5)
M:SetStyle('watchStyle','iconSize',20);M:SetStyle('watchStyle','iconPadding',16)
assert(a.icon.points[1][4]==9 and a.icon.points[2][4]==-9,'Extreme padding leaves positive drawable texture area')
assert(not M:SetStyle('watchStyle','iconPadding',17) and not M:SetStyle('watchStyle','iconBorderColor',{2,0,0}))
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
assert(M.db.watchStyle.iconPadding==16 and M.db.watchStyle.iconBorderSize==2 and M.db.watchStyle.spacing==30)
assert(M.db.launcherStyle.iconSize==56 and M.db.launcherStyle.iconBorderSize==3)
assert(M.openButton.iconEdges[1].height==3)
''')
print('PASS Rogue icon controls: direct visibility, actual numeric fields, spacing, per-icon padding/border/color/opacity/background, bounds, independence, minimal preset, Edit Mode and persistence')
