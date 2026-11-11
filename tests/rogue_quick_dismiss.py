"""Quick Access right-click dismissal is session-only and never applies poison."""
from rogue_poisons import SETUP
from smoke import load

lua, _ = load(before=SETUP)
lua.execute(r'''
local M=addon.ForeverRogue
addon:SetModuleEnabled('foreverRogue',true);M:SetOption('flyout',true)
addon:ToggleConfig();addon:SelectConfigPage('foreverRogue')
local function Right() M.openButton.scripts.OnClick(M.openButton,'RightButton') end
local n=#applications
Click(M.openButton);assert(M.menu:IsShown())
Right()
assert(M.quickDismissed and not M.launcher:IsShown() and not M.menu:IsShown() and not M.menuOpen)
assert(M.watchButtons[1]:IsShown() and M.watchButtons[2]:IsShown(),'Launcher dismissal leaves reminder hands alone')
assert(M.page.settingsButtons[2]:IsEnabled(),'Restore is available for launcher-only dismissal')
M.ticker.callback();FireEvent('BAG_UPDATE_DELAYED');M:SetOption('alwaysShow',true)
assert(not M.launcher:IsShown(),'Polling, inventory refresh and Always visibility do not undo dismissal')
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(not M.launcher:IsShown(),'Dismissal survives combat transitions')
M:SetPreviewMode(true);assert(M.launcher:IsShown());Right();assert(M.launcher:IsShown())
M:SetPreviewMode(false);assert(not M.launcher:IsShown())
assert(M:EnterElementEdit(true));assert(M.launcher:IsShown())
Right();assert(M.launcher:IsShown() and addon.PositionManager.selected=='rogueQuickPoisons')
addon:SetEditMode(false);assert(not M.launcher:IsShown())
M:SetOption('watcher',false);assert(M.page.settingsButtons[2]:IsEnabled())
M.page.settingsButtons[2].scripts.OnClick()
assert(not M.quickDismissed and M.launcher:IsShown() and not M.menu:IsShown())
M:SetOption('dismissOnRightClick',false);Right()
assert(not M.launcher:IsShown() and not M.menuOpen,'Quick Access dismissal is independent of the Reminder toggle')
M:RestoreReminders()
Click(M.openButton);assert(M.menu:IsShown());Click(M.openButton);assert(not M.menu:IsShown())
assert(M.page.settingsButtons[3]:IsEnabled())
M.page.settingsButtons[3].scripts.OnClick();assert(not M.launcher:IsShown())
assert(not M.page.settingsButtons[3]:IsEnabled(),'Dismiss button reflects current state')
M:Refresh();assert(not M.launcher:IsShown() and #applications==n,'No click consumed or applied poison')
assert(M.db.quickDismissed==nil,'Dismissal never enters SavedVariables')
''')
saved=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded=saved,before=SETUP)
restored.execute("assert(not addon.ForeverRogue.quickDismissed and addon.ForeverRogue.launcher:IsShown(),'Reload restores Quick Access')")
print('PASS Quick Access: right-click hide/menu close, restore, reload, visibility, combat transitions, preview/Edit Mode, toggle and no poison use')
