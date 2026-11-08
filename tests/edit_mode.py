"""Edit Mode exit, combat, panel anchor controls and secret-value capability (mock only)."""
from smoke import load

SETUP = r'''
PlayerFrame=PlayerFrame or CreateFrame('Frame','PlayerFrame',UIParent)
PlayerFrame:SetPoint('CENTER',UIParent,'CENTER',0,0)
addon:SetModuleEnabled('combatTimer',true)
pm,E,id=addon.PositionManager,addon.EditMode,'combatTimer'
addon:ToggleConfig()
config=addon.configWindow
assert(config:IsShown())
function Click(button) button:GetScript('OnClick')(button) end
function Pick(dropdown,choice)
    Click(dropdown)
    for _,row in ipairs(dropdown.rows) do
        if row:IsShown() and row.choice.id==choice then Click(row);return end
    end
    error('dropdown has no choice '..tostring(choice))
end
function Enter()
    assert(addon:SetEditMode(true))
    panel=addon.editWindow
    assert(pm:SelectElement(id))
    assert(panel:IsShown() and not config:IsShown())
end
function Left()
    assert(addon.editMode==false and addon.previewMode==false,'mode flags cleared')
    assert(not panel:IsShown(),'panel closed')
    assert(not config.editSuspended,'config no longer suspended')
end
'''

CASES = {
    'exit button is labelled Exit, leaves the mode and returns to settings': r'''
Enter()
assert(panel.exitButton.label:GetText()=='Exit')
Click(panel.exitButton)
Left();assert(config:IsShown())
''',
    'escape leaves the mode without opening the game menu': r'''
Enter()
panel:GetScript('OnKeyDown')(panel,'ESCAPE')
Left();assert(config:IsShown() and panel.propagate==false)
''',
    'exit keeps positions already written': r'''
Enter()
assert(E:SetCoordinate('x',120) and E:SetCoordinate('y',-60))
Click(panel.exitButton)
local p=pm:GetPosition(id);assert(p.x==120 and p.y==-60)
assert(addon.db.modules.combatTimer.position.x==120)
''',
    'exit commits a typed coordinate that was not applied yet': r'''
Enter()
panel.xInput:SetFocus();panel.xInput:SetText('77')
Click(panel.exitButton)
Left();assert(pm:GetPosition(id).x==77,'typed value committed')
''',
    'exit ends the drag in progress and saves it': r'''
Enter()
local frame=pm.elements[id].frame
local before=pm:GetPosition(id).x
assert(pm:StartDragging(id));frame.centerX=frame.centerX+40
Click(panel.exitButton)
Left();assert(not pm.elements[id].dragging and not frame.moving)
assert(pm:GetPosition(id).x==before+40,'drag saved')
''',
    'a module error cannot strand the panel': r'''
Enter()
local module=addon.modules.combatTimer
local original=module.SetEditMode
module.SetEditMode=function() error('module failure') end
local ok,message=pcall(Click,panel.exitButton)
module.SetEditMode=original
assert(not ok and tostring(message):find('module failure',1,true),'error stays visible')
Left();assert(config:IsShown())
''',
    'combat ends the mode without reopening settings': r'''
local closed=0
local module=addon.modules.combatTimer
local original=module.OnConfigClosed
module.OnConfigClosed=function(self) closed=closed+1;if original then original(self) end end
Enter()
assert(closed==0,'suspending settings is not closing them')
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
Left();assert(not config:IsShown(),'settings stay closed in combat')
assert(closed==1,'close cleanup still ran')
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(not config:IsShown(),'settings stay closed after combat')
addon:ToggleConfig();assert(config:IsShown() and closed==1,'settings reopen normally')
''',
    'combat discards an unfinished drag': r'''
assert(pm:SetOffsets(id,10,20))
Enter()
local frame=pm.elements[id].frame
assert(pm:StartDragging(id));frame.centerX=frame.centerX+90
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
Left();local p=pm:GetPosition(id);assert(p.x==10 and p.y==20)
''',
    'edit mode cannot start in combat': r'''
testCombat=true;testLockdown=true
assert(addon:SetEditMode(true)==false and not addon.editMode)
''',
    'target dropdown keeps offsets and custom points': r'''
Enter()
assert(pm:SetOffsets(id,30,-20) and pm:SetAttachment(id,'TOP','BOTTOM'))
Pick(panel.targetDropdown,'player')
local p=pm:GetPosition(id)
assert(p.target=='player' and p.x==30 and p.y==-20)
assert(p.point=='TOP' and p.relativePoint=='BOTTOM')
''',
    'reset offset only resets offsets': r'''
Enter()
Pick(panel.targetDropdown,'player')
assert(pm:SetOffsets(id,30,-20) and pm:SetAttachment(id,'TOP','BOTTOM'))
Click(panel.resetOffset)
local p=pm:GetPosition(id)
assert(p.x==0 and p.y==0 and p.target=='player')
assert(p.point=='TOP' and p.relativePoint=='BOTTOM')
''',
    'reset offset restores the placement gap': r'''
Enter()
Pick(panel.targetDropdown,'player');Pick(panel.placementDropdown,'below')
assert(pm:SetOffsets(id,44,44))
Click(panel.resetOffset)
local p=pm:GetPosition(id);assert(p.x==0 and p.y==-8 and p.placement=='below')
''',
    'placement dropdown applies the preset and keeps nudges': r'''
Enter()
Pick(panel.targetDropdown,'player')
assert(pm:SetOffsets(id,0,0) and pm:SetAttachment(id,'TOP','BOTTOM'))
Pick(panel.placementDropdown,'above')
local p=pm:GetPosition(id)
assert(p.placement=='above' and p.point==nil and p.relativePoint==nil)
assert(p.x==0 and p.y==8,'default gap applied')
assert(pm:SetOffsets(id,5,12))
Pick(panel.placementDropdown,'below')
p=pm:GetPosition(id);assert(p.placement=='below' and p.x==5 and p.y==-4,'nudge carried over')
''',
    'legacy SetAnchor contract is unchanged': r'''
Enter()
assert(pm:SetOffsets(id,30,-20) and pm:SetAttachment(id,'TOP','BOTTOM'))
assert(E:SetAnchor('player','above'))
local p=pm:GetPosition(id)
assert(p.target=='player' and p.x==0 and p.y==8 and p.point==nil)
''',
    'anchors work on a client without issecretvalue': r'''
local P,F=addon.Positioning,addon.FrameAnchors
local real=issecretvalue
issecretvalue=nil
local player=P:Resolve('player')
local valid=F:ValidID('frame:PlayerFrame')
local named=F:Resolve('frame:PlayerFrame')
issecretvalue=real
assert(player==PlayerFrame,'named target resolves')
assert(valid and named==PlayerFrame,'custom frame resolves')
''',
    'secret values are still rejected when the API exists': r'''
local P,F=addon.Positioning,addon.FrameAnchors
assert(not F:ValidID({secret=true}))
local real=_G.PlayerFrame
_G.PlayerFrame={secret=true}
local resolved=P:Resolve('player')
_G.PlayerFrame=real
assert(resolved==nil)
''',
}

failures = []
for name, body in CASES.items():
    lua, _ = load()
    try:
        lua.execute(SETUP)
        lua.execute(body)
    except Exception as error:  # Report every failing behavior, not only the first.
        failures.append(f'{name}: {error}')
for failure in failures:
    print('FAIL', failure)
assert not failures, f'{len(failures)} of {len(CASES)} Edit Mode cases failed'
print(f'PASS {len(CASES)} Edit Mode exit, combat, panel anchor and secret-value cases (mock only)')
