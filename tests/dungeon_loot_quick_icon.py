"""Quick Icon appearance, shared Edit Mode and General's hardware binding editor."""
from smoke import load

lua,_=load()
lua.execute(r'''
    local M,pm=addon.DungeonLoot,addon.PositionManager
    local action='PTGTOOLS_DUNGEON_LOOT'
    local bindings={F1='UNRELATED',['CTRL-D']='OTHER_ACTION'};local saved=0
    function GetBindingKey(a)
        local keys={};for key,owner in pairs(bindings) do if owner==a then keys[#keys+1]=key end end
        table.sort(keys);return unpack(keys)
    end
    function GetBindingAction(key) return bindings[key] or '' end
    function GetCurrentBindingSet() return 2 end
    function SetBinding(key,owner) bindings[key]=owner;FireEvent('UPDATE_BINDINGS');return true end
    function SaveBindings(set) assert(set==2);saved=saved+1 end
    function IsShiftKeyDown() return false end
    function IsControlKeyDown() return true end
    function IsAltKeyDown() return false end
    addon:SetModuleEnabled('dungeonLoot',true);addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    M:Navigate(nil,'general')
    local b=M.shortcut;local e=pm.elements.dungeonLootShortcut
    assert(b and e and b.mouse and b.icon and #b.ring==48)
    assert(b.icon.texture=='Interface\\Buttons\\UI-GroupLoot-Dice-Up' and b.icon:GetWidth()>0,'native loot icon is explicitly sized')
    assert(e.label=='Dungeon Loot Quick Icon' and e.draggable and e.editMode and not e.supportsAnchoring)
    local function Click(label)
        if label=='Set Keybinding' then M.page.bindingControl.set.scripts.OnClick(M.page.bindingControl.set);return end
        for _,slot in ipairs(M.page.rootPane.slots) do if slot.visible and slot.button.label:GetText()==label then
            if slot.callback then slot.button.scripts.OnClick(slot.button) end;return slot
        end end
        error('Missing '..label)
    end
    Click('Quick Icon');Click('Keybinding');assert(M.page.bindingControl.field:GetText()=='Not bound')
    M.page.iconSize.slider:SetValue(64);M.page.iconOpacity.slider:SetValue(60)
    assert(M.db.shortcutSize==64 and b:GetWidth()==64 and b.alpha==.6)
    assert(not M:SetShortcutOption('shortcutSize',73) and not M:SetShortcutOption('shortcutOpacity',0))
    assert(M:EditShortcutPosition() and addon.editMode and pm.selected=='dungeonLootShortcut')
    assert(e.decoration.handle:IsShown())
    assert(pm:SetOffsets(e.id,120,-80))
    assert(M.db.shortcutPosition.x==120 and M.db.shortcutPosition.y==-80,'managed coordinates sync legacy shortcut preferences')
    b.scripts.OnClick(b);assert(addon.editMode,'edit clicks select instead of opening the browser')
    b.centerX=700;b.centerY=500
    b.scripts.OnDragStart(b);assert(e.dragging)
    b.scripts.OnDragStop(b);assert(not e.dragging)
    addon:SetEditMode(false);assert(b.mouse,'shared Edit Mode must not leave the launcher mouse-disabled')
    M:Navigate(nil,'general')
    Click('Set Keybinding')
    local capture=M.bindingCapture
    assert(capture:IsShown() and capture.keyboard and capture.propagate==false)
    capture.scripts.OnKeyDown(capture,'LSHIFT');assert(saved==0)
    capture.scripts.OnKeyDown(capture,'D')
    assert(bindings['CTRL-D']==action and saved==1 and not capture:IsShown() and not capture.keyboard and capture.propagate)
    assert(M.page.bindingControl.field:GetText()=='CTRL-D' and not M.page.bindingControl.field.keyboard and not M.page.bindingControl.field.mouse)
    bindings['ALT-D']=action;FireEvent('UPDATE_BINDINGS');assert(M.page.bindingControl.field:GetText()=='ALT-D, CTRL-D');bindings['ALT-D']=nil
    local ok,reason=M:SaveShortcutBinding('F1')
    assert(ok and bindings.F1==action and not bindings['CTRL-D'],'chosen key overrides its previous action')
    assert(M:SaveShortcutBinding('CTRL-D') and not bindings.F1);bindings.F1='UNRELATED'
    -- Failure before any write when ownership cannot be read.
    local getAction=GetBindingAction;GetBindingAction=function() error('unavailable') end
    assert(not M:SaveShortcutBinding('F3') and bindings['CTRL-D']==action and not bindings.F3)
    GetBindingAction=getAction
    local setBinding=SetBinding;SetBinding=function(key,owner) if key=='F5' then return false end;return setBinding(key,owner) end
    assert(not M:SaveShortcutBinding('F5') and bindings['CTRL-D']==action and not bindings.F5)
    SetBinding=setBinding
    -- Failed persistence rolls this action back, preserving unrelated bindings.
    local save=SaveBindings;SaveBindings=function() error('rejected save') end
    assert(not M:SaveShortcutBinding('F1') and bindings['CTRL-D']==action and bindings.F1=='UNRELATED','failed save restores overwritten action and previous shortcut')
    SaveBindings=save
    Click('Set Keybinding');capture.scripts.OnKeyDown(capture,'ESCAPE');assert(not capture.keyboard and bindings['CTRL-D']==action)
    Click('Set Keybinding');M:Navigate(nil,'loot');assert(not capture:IsShown() and not capture.keyboard)
    M:Navigate(nil,'general');Click('Set Keybinding')
    testCombat=true;FireEvent('PLAYER_REGEN_DISABLED')
    assert(not capture:IsShown() and not capture.keyboard and not M:SaveShortcutBinding('F4'))
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    M:Navigate(nil,'general');bindings['ALT-D']=action;Click('Clear Keybinding')
    assert(not bindings['CTRL-D'] and not bindings['ALT-D'] and bindings.F1=='UNRELATED' and M:ShortcutBindingLabel()=='Not bound' and M.page.bindingControl.field:GetText()=='Not bound')
    Click('Set Keybinding');M.page:Hide();assert(not capture:IsShown() and not capture.keyboard)
    M.page:Show();Click('Set Keybinding');addon:SetModuleEnabled('dungeonLoot',false)
    assert(not capture.keyboard and not b:IsShown() and not e.editMode)
''')
encoded=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded)
restored.execute(r'''
    local M=addon.DungeonLoot
    assert(M.db.shortcutSize==64 and M.db.shortcutOpacity==60)
    local before=addon.ProfileCodec.Copy(addon.db.positions.dungeonLootShortcut)
    addon:SetModuleEnabled('dungeonLoot',true)
    assert(M.shortcut:GetWidth()==64 and M.shortcut.alpha==.6)
    local position=addon.PositionManager:GetPosition('dungeonLootShortcut')
    assert(position.x==before.x and position.y==before.y,'existing managed record survives reload')
    local candidate=addon.ProfileCodec.Copy(addon.db);candidate.modules.dungeonLoot.shortcutSize=23
    assert(not addon.ProfileValidation:Validate(candidate),'invalid imported icon size rejected')
''')
print('PASS native icon geometry/ring, size/opacity controls, managed Edit Mode coordinates/drag/mouse state, inline binding field/capture/override/save/rollback and cleanup')
