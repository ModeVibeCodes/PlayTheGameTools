"""Dungeon Loot icon/keybinding routing, drag persistence and combat/lifecycle guards."""
import xml.etree.ElementTree as ET
from smoke import load
from build_release import payload

files,_,_=payload()
binding=ET.fromstring(files['Bindings.xml'])[0]
lua,_=load()
lua.globals().bindingAction=binding.text.strip()
lua.execute(r'''
    local M=addon.DungeonLoot
    assert(not M.active and not M.shortcut and M.db.showShortcut==nil and not M.db.shortcutLocked,'no ring switch is seeded')
    assert(BINDING_HEADER_PTGTOOLS=='Play The Game Tools' and BINDING_NAME_PTGTOOLS_DUNGEON_LOOT=='Open Dungeon Loot')
    -- The binding opens the disabled module's settings without enabling it or loading its catalog.
    local read=addon.DungeonLootProvider.Read
    addon.DungeonLootProvider.Read=function() error('disabled shortcut must not query catalog') end
    assert(loadstring(bindingAction))()
    assert(addon.configWindow:IsShown() and addon.configWindow.pages.dungeonLoot:IsShown() and not M.active)
    addon.DungeonLootProvider.Read=read
    addon:SetModuleEnabled('dungeonLoot',true)
    local b=M.shortcut
    assert(b and b:IsShown() and b:GetWidth()==40 and b:GetParent()==addon.QuickActions.ring)
    M:Navigate('Shadowfang Keep','quests')
    b:GetScript('OnClick')(b)
    assert(M.view.dungeon==nil and M.view.tab=='loot' and M.page:IsShown())
    addon.configWindow:Hide();b:GetScript('OnClick')(b)
    assert(addon.configWindow:IsShown() and M.page:IsShown())
    assert(b:GetScript('OnDragStart')==nil,'ring icons do not move on their own')
    testCombat=true;FireEvent('PLAYER_REGEN_DISABLED')
    assert(not PlayTheGameToolsOpenDungeonLoot())
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    -- An old saved showShortcut=false is not read: a module that is on is in the ring.
    M.db.showShortcut=false;M:SyncShortcut();assert(b:IsShown())
    M.db.showShortcut=nil
    assert(PlayTheGameToolsOpenDungeonLoot() and M.view.dungeon==nil,'keybind opens Dungeon Loot')
    M:Navigate(nil,'general')
    local function Click(label)
        for _,slot in ipairs(M.page.rootPane.slots) do
            if slot.visible and slot.button.label:GetText()==label then slot.button:GetScript('OnClick')(slot.button);return end
        end
        error('Missing '..label)
    end
    for _,slot in ipairs(M.page.rootPane.slots) do
        local text=slot.visible and slot.button.label:GetText() or ''
        assert(not text:find('Lock Shortcut',1,true),'lock row removed')
        assert(not text:find('Show Shortcut',1,true),'no Quick Actions switch')
    end
    local launcher=addon.PositionManager.elements.quickActionsLauncher
    assert(addon.PositionManager:SetOffsets(launcher.id,12,34))
    assert(M:ResetShortcutPosition() and launcher.position.x==-180 and launcher.position.y==-140,'module API resets; the page leaves placement to Edit Mode')
    for _,slot in ipairs(M.page.rootPane.slots) do assert(not (slot.visible and slot.button.label:GetText():find('Position',1,true)),'no page position rows') end
    M.db.shortcutPosition={x=70,y=-90};M.db.shortcutLocked=true
    addon:SetModuleEnabled('dungeonLoot',false)
    assert(not b:IsShown() and next(M.shortcutEvents.events)==nil)
    assert(PlayTheGameToolsOpenDungeonLoot() and not M.active,'binding never enables a disabled module')
    addon:SetModuleEnabled('dungeonLoot',true)
    assert(M.shortcut==b and b:IsShown(),'frame reused across enable cycles')
    local candidate=addon.ProfileCodec.Copy(addon.db)
    candidate.modules.dungeonLoot.shortcutPosition.x=0/0
    assert(not addon.ProfileValidation:Validate(candidate),'invalid profile position rejected')
    -- The retired switch is left unread, so an old value never blocks an import.
    candidate=addon.ProfileCodec.Copy(addon.db);candidate.modules.dungeonLoot.showShortcut=false
    assert(addon.ProfileValidation:Validate(candidate),'old visibility value ignored')
''')
encoded=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded)
restored.execute('''
    local M=addon.DungeonLoot
    assert(M.active and M.db.shortcutPosition.x==70 and M.db.shortcutPosition.y==-90)
    assert(M.db.shortcutLocked and M.shortcut:IsShown())
''')
deferred,_=load(encoded,before='testCombat=true')
deferred.execute('''
    local M=addon.DungeonLoot
    assert(M.active and not M.shortcut)
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    assert(M.shortcut and M.shortcut:IsShown())
''')
print('PASS native binding payload, direct index routing, disabled/hidden icon behavior, ring-owned placement, combat, General controls, retained legacy settings, profile validation/restore and deferred creation')
