"""Dismissal, responsive settings, migration and real Position Manager contracts.
Native rendering/security acceptance remains an owner in-game check.
"""
from rogue_poisons import SETUP
from smoke import load

lua,_=load(before=SETUP)
lua.execute(r'''
local M,PM=addon.ForeverRogue,addon.PositionManager
addon:SetModuleEnabled('foreverRogue',true);M:SetOption('flyout',true)
assert(M.db.watchStyle.backgroundOpacity==0 and M.db.watchStyle.borderSize==0)
assert(M.watchButtons[1].caption:IsShown() and not M.watchButtons[1].timer:IsShown() and not M.watchButtons[1].count:IsShown())
assert(PM.elements.roguePoisonReminder and PM.elements.rogueQuickPoisons,'Both elements register with the shared manager')
local function Right(b)
 assert(b:IsShown() and b.mouse~=false)
 b.scripts.PreClick(b,'RightButton',false);b.scripts.OnClick(b,'RightButton',false)
end
local n=#applications
Right(M.watchButtons[1]);assert(not M.watchButtons[1]:IsShown() and M.watchButtons[2]:IsShown() and #applications==n)
M.ticker.callback();FireEvent('BAG_UPDATE_DELAYED');assert(not M.watchButtons[1]:IsShown(),'Dismissal survives polling and bag refresh')
M:RestoreReminders();assert(M.watchButtons[1]:IsShown())
Poison(0,200);M:Refresh();Right(M.watchButtons[1]);Poison(0,199);M:Render();assert(not M.watchButtons[1]:IsShown())
Poison(0,1800);M:Render();Poison(0,299);M:Render();assert(M.watchButtons[1]:IsShown(),'Refreshed poison rearms reminder')
Right(M.watchButtons[1]);weaponIDs[16]=101;M:Render();assert(M.watchButtons[1]:IsShown(),'Weapon change rearms reminder')
Right(M.watchButtons[1]);enchants[0]={};M:Render();assert(not M.watchButtons[1]:IsShown(),'Dismissal survives expiration into missing poison')
M:RestoreReminders()
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
Right(M.watchButtons[1]);assert(not M.watchButtons[1]:IsShown() and #applications==n,'Combat dismissal is presentation-only')
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED');M:RestoreReminders()
M:SetOption('dismissOnRightClick',false);Right(M.watchButtons[1]);assert(M.watchButtons[1]:IsShown())
M:SetOption('dismissOnRightClick',true)
-- Explicit visibility states retain the native action combat boundary.
Poison(0,1800);Poison(1,1800,302);M:Refresh();assert(not M.watcher:IsShown())
M:SetOption('reminderVisibility','alwaysOOC');assert(M.watcher:IsShown())
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED');assert(not M.watcher:IsShown())
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
M:SetOption('reminderVisibility','always');testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED');assert(M.watcher:IsShown())
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED');M:SetOption('reminderVisibility','needed')
-- Settings presentation, class branding and family actions.
addon:ToggleConfig();addon:SelectConfigPage('foreverRogue');local p=M.page
assert(#p.sections==3 and p.sections[1].title=='Display' and p.sections[2].title=='Settings' and p.sections[3].title=='Position')
local h=addon.configWindow.moduleHeader
assert(h.classIcon==nil and not h.title:IsShown(),'No duplicate class icon below the tab')
local classTab=addon.configWindow.navigationButtons.foreverRogue
assert(classTab.classIcon.texture==M.classIcon and classTab:GetWidth()<120)
local point,relative,relativePoint,gap=classTab.status:GetPoint(1)
assert(point=='LEFT' and relative==classTab.label and relativePoint=='RIGHT' and gap==8,'On status follows the Rogue label closely')
assert(addon.configWindow.sidebarModuleButtons.foreverRogue.classIcon.texture==M.classIcon,'Class icon appears in the left subcategory')
assert(p.poisonGrid[1].label:GetText()=='Recent' and p.poisonGrid[4].label:GetText()=='Crippling')
assert(p.poisonGrid[2].available and p.poisonGrid[4].icon.desaturated and not p.poisonGrid[4]:IsEnabled())
assert(not p.customize)
p.poisonGrid[2].scripts.OnClick();assert(M.db.quickApply=='family:8679' and #applications==n)
enchants[0]={};M:Refresh();assert(M.watchButtons[1].attrs.item1=='item:6949','Family selection uses available native rank')
Click(M.watchButtons[1]);assert(applications[#applications].id==6949 and applications[#applications].target==16)
p.poisonGrid[1].scripts.OnClick();assert(M.db.quickApply=='last')
p.displayButtons[2].scripts.OnClick();assert(p.customize=='quick')
M:SetStyle('launcherStyle','showNames',true);p.launcherLabelInput:SetText('Poison Kit');p.launcherLabelInput.scripts.OnEnterPressed()
assert(M.openButton.label:GetText()=='Poison Kit' and M.openButton.label:IsShown())
assert(not M:SetStyle('launcherStyle','labelText','bad|text'))
M:SetStyle('launcherStyle','labelPosition','TOP');assert(M.db.launcherStyle.labelPosition=='TOP')
-- Paired controls cap their widths and wrap on narrower settings canvases.
p.scroll.width=650;p:Layout();local x=p.poisonSliders['root:x'];local y=p.poisonSliders['root:y']
assert(x:GetParent():GetWidth()<=260 and y:GetParent():GetWidth()<=260)
assert(x:GetParent():GetPoint(1)=='TOPLEFT' and y:GetParent().points[1][4]>0)
-- Shared Edit Mode highlights and active selection, not a parallel local mover.
assert(M:EnterElementEdit(false));assert(addon.editMode and PM.selected=='roguePoisonReminder')
local a,b=PM.elements.roguePoisonReminder,PM.elements.rogueQuickPoisons
assert(a.decoration.frame:IsShown() and b.decoration.frame:IsShown())
assert(a.label=='Rogue: Poison Reminder' and b.label=='Rogue: Quick Access Poisons')
n=#applications;Click(M.watchButtons[1]);assert(#applications==n)
M.watcher.centerX=530;M.watcher.centerY=460
a.decoration.handle.scripts.OnDragStart();assert(a.dragging)
a.decoration.handle.scripts.OnDragStop();assert(not a.dragging and M.db.x==30 and M.db.y==60)
assert(PM:GetPosition(a.id).x==30 and addon.db.positions[a.id].y==60)
assert(M:EnterElementEdit(true) and PM.selected==b.id)
assert(not M.menu:IsShown());Click(M.watchButtons[1]);assert(PM.selected==a.id and #applications==n)
Click(M.openButton);assert(PM.selected==b.id and not M.menu:IsShown() and #applications==n)
assert(PM:SetCoordinate(b.id,'x',70));assert(M.db.menuX==70)
M:SetOption('watcher',false);assert(not a.editMode and not a.decoration.frame:IsShown())
addon:SetEditMode(false);assert(not a.decoration.frame:IsShown() and not b.decoration.frame:IsShown())
M:SetOption('watcher',true);M:SetOption('x',45);M:SetOption('y',-50)
assert(PM:GetPosition(a.id).x==45 and PM:GetPosition(a.id).y==-50)
M:ResetElementPosition(false);assert(M.db.x==0 and M.db.y==-140)
M:SetOption('flyoutLocked',false);M.launcher.centerX=580;M.launcher.centerY=430
M.openButton.scripts.OnDragStart();assert(M.launcher.moving)
M.openButton.scripts.OnDragStop();assert(M.db.menuX==80 and M.db.menuY==30)
M:SetOption('flyoutLocked',true)
addon:SelectConfigPage('combatTimer');assert(h.title:IsShown() and h.classIcon==nil,'Non-class header restored')
M:SetStyle('watchStyle','backgroundOpacity',50);M:SetStyle('watchStyle','borderSize',3);M:MinimalReminder()
assert(M.db.watchStyle.backgroundOpacity==0 and M.db.watchStyle.borderSize==0 and not M.db.watchStyle.showTimers)
''')
saved=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded=saved,before=SETUP)
restored.execute(r'''
local M=addon.ForeverRogue
assert(M.db.launcherStyle.labelText=='Poison Kit' and M.db.menuX==80 and M.db.menuY==30)
assert(addon.PositionManager:GetPosition('rogueQuickPoisons').x==80)
assert(next(M.dismissed)==nil,'Dismissal is session-only')
local old={watchStyle={backgroundOpacity=85,borderSize=1,showTimers=true,showCounts=true}}
M.Initialize(old);assert(old.watchStyle.backgroundOpacity==0 and old.watchStyle.borderSize==0 and not old.watchStyle.showTimers)
local custom={watchStyle={backgroundOpacity=45,borderSize=3,showTimers=true,custom='preserve'}}
M.Initialize(custom);assert(custom.watchStyle.backgroundOpacity==45 and custom.watchStyle.borderSize==3 and custom.watchStyle.showTimers and custom.watchStyle.custom=='preserve')
assert(not M:SetOption('quickApply','family:9999') and not M:SetOption('reminderVisibility','bad'))
''')
print('PASS Rogue layout: dismissal/rearm/combat, three-section UI, family grid, minimal migration, labels, paired controls, class branding, shared Edit Mode highlights/drag/coordinates, persistence')
