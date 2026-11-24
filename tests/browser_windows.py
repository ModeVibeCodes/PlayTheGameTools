"""Dungeon Loot and Class Training browsers as standalone windows (v2)."""
from smoke import load

SCRIPT = r'''
    local DL,CT,D=addon.DungeonLoot,addon.ForeverClassTraining,addon.Dialogs
    addon:SetModuleEnabled('dungeonLoot',true);addon:SetModuleEnabled('foreverClassTraining',true)
    -- Page header: the open button names the window and works while the module is on.
    addon:ToggleConfig();addon:SelectConfigPage('foreverClassTraining')
    local header=addon.configWindow.moduleHeader;local open=header.openButton
    assert(open:IsShown() and open.label:GetText()=='Open Class Training' and open:IsEnabled())
    local page=addon.configWindow.pages.foreverClassTraining
    for _,section in ipairs(page.sections) do
        assert(section.title~='Upcoming Abilities' and section.title~='Available & Known','lists left the settings page')
    end
    open.scripts.OnClick(open)
    local window=CT.trainingWindow
    assert(window and window:IsShown() and window:GetName()=='PlayTheGameToolsClassTrainingWindow')
    assert(not addon.configWindow:IsShown(),'opening the tool closes the settings window')
    assert(CT.trainingBrowser:GetParent()==window.body.host or CT.trainingBrowser.host:GetParent()==window.body)
    assert(CT.trainingBrowser.selectedTab=='Upcoming Abilities' and window.raised)
    -- Tabs switch the same pooled rows.
    local rows=#CT.trainingBrowser.trainingRows
    CT.trainingBrowser.tabButtons[2].scripts.OnClick(CT.trainingBrowser.tabButtons[2])
    assert(CT.trainingBrowser.selectedTab=='Available & Known' and #CT.trainingBrowser.trainingRows==rows)
    assert(CT.trainingBrowser.tabButtons[2].selected and not CT.trainingBrowser.tabButtons[1].selected)
    -- Escape closes it through the shared handler.
    assert(PlayTheGameToolsEscapeHandler:IsShown())
    PlayTheGameToolsEscapeHandler:Hide();assert(not window:IsShown(),'Escape closes Class Training')
    -- The level-up window's Training button opens Available & Known in the window.
    CT:OpenTrainingWindow('Upcoming Abilities');CT:OpenTrainingWindow('Available & Known')
    assert(window:IsShown() and CT.trainingBrowser.selectedTab=='Available & Known')
    -- Dragging records the position for the session; reopening keeps it.
    window.centerX,window.centerY=300,200
    window.scripts.OnDragStart(window);assert(window.moving)
    window.scripts.OnDragStop(window);assert(not window.moving)
    local saved=addon.BrowserWindowPositions.PlayTheGameToolsClassTrainingWindow
    assert(saved and saved.x and saved.y)
    window:Hide();window:Show()
    local point=window.points[1];assert(point[1]=='CENTER' and point[4]==saved.x and point[5]==saved.y,'position kept for the session')
    -- Combat: both windows open, render and close without protected calls.
    window:Hide();testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
    assert(CT:OpenTrainingWindow() and window:IsShown())
    assert(CT.trainingBrowser.statusLabel:GetText():find('Pending',1,true),'combat shows the last result, pending')
    assert(DL:OpenDungeonLoot() and DL.window:IsShown() and not window:IsShown(),'one tool window at a time')
    DL.window:Hide();testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
    -- The Settings button returns to the module's settings page.
    DL:OpenDungeonLoot();DL.window.settingsButton.scripts.OnClick(DL.window.settingsButton)
    assert(addon.configWindow:IsShown() and addon.configWindow.selectedPage=='dungeonLoot' and not DL.window:IsShown())
    assert(header.openButton.label:GetText()=='Open Dungeon Loot')
    -- Off: the header button is disabled and the windows close.
    addon:SetModuleEnabled('dungeonLoot',false);addon:RefreshConfig()
    assert(header.openButton:IsShown() and not header.openButton:IsEnabled())
    CT:OpenTrainingWindow();addon:SetModuleEnabled('foreverClassTraining',false);assert(not window:IsShown())
    -- Pages without a window have no open button.
    addon:SelectConfigPage('combatTimer');assert(not header.openButton:IsShown())
'''

lua, _ = load()
lua.execute(SCRIPT)
lua.execute("addon.db.window.theme='blizzard'")
blizzard, _ = load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
blizzard.execute(r'''
    local DL=addon.DungeonLoot
    addon:SetModuleEnabled('dungeonLoot',true)
    assert(addon.InterfaceTheme.blizzardArt and DL:OpenDungeonLoot() and DL.window:IsShown())
    assert(DL.window.blizzardBackdrop,'Blizzard theme draws the stock backdrop on the window')
''')
print('PASS header open buttons, Class Training/Dungeon Loot windows, tabs, Escape, session position, combat open, Settings return, disable, Blizzard theme (mock only)')
