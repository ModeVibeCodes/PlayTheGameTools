"""Layout mode: entry and exit, the bar, selection, Grid, combat, the Style card's
position section and secret-value capability (mock only)."""
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
    panel=addon.editWindow;card=panel.styleCard
    assert(pm:SelectElement(id))
    assert(panel:IsShown() and not config:IsShown() and card:IsShown())
end
function Visible(frame)
    while frame do if not frame:IsShown() then return false end;frame=frame:GetParent() end
    return true
end
function Left()
    assert(addon.editMode==false,'mode flag cleared')
    assert(not panel:IsShown(),'Layout bar closed')
    assert(not card:IsShown(),'Style card closed')
    assert(not config.editSuspended,'config no longer suspended')
end
'''

CASES = {
    'the bar reads Layout, the cue, Drag to move, Grid and Done': r'''
assert(addon:SetEditMode(true))
panel=addon.editWindow
assert(panel:GetName()=='PlayTheGameToolsEditWindow','frame name kept')
assert(panel.title:GetText()=='Layout')
assert(panel.cue:GetText()=='Click a display to style it' and panel.cue.color[1]==addon.InterfaceTheme.primary[1],'highlighted cue')
assert(panel.hint:GetText()=='Drag to move')
assert(panel.gridLabel:GetText()=='Grid' and panel.gridButton:IsShown())
assert(panel.doneButton.label:GetText()=='Done' and panel.exitButton==panel.doneButton)
''',
    'Done leaves Layout and returns to settings': r'''
Enter()
Click(panel.doneButton)
Left();assert(config:IsShown())
''',
    'Preview mode no longer exists as a separate state': r'''
assert(addon.SetPreviewMode==nil and addon.previewMode==nil)
''',
    'Layout shows every enabled display with sample data and its name': r'''
addon:SetModuleEnabled('threatMeter',true)
local timer,threat=addon.modules.combatTimer,addon.ThreatMeter
assert(not timer.frame:IsShown(),'timer hidden out of combat')
assert(addon:SetEditMode(true))
assert(timer.preview and timer.editing and timer.frame:IsShown(),'timer shows its preview in Layout')
assert(timer.text:GetText()=='01:23','sample time')
assert(threat.previewing and threat.editing and threat.frame:IsShown())
for _,key in ipairs({'combatTimer','threatMeter'}) do
    local d=pm.elements[key].decoration
    assert(d and d.frame:IsShown() and d.label:IsShown(),'name tag shown on '..key)
end
assert(pm.elements.threatMeter.decoration.label:GetText()=='Threat Meter')
assert(pm.selected==nil and not addon.editWindow.styleCard:IsShown(),'no Style card until a display is clicked')
addon:SetEditMode(false)
assert(not timer.preview and not timer.editing and not timer.frame:IsShown())
assert(not threat.previewing and not threat.editing)
''',
    'clicking a display opens its Style card beside it; X closes it': r'''
assert(addon:SetEditMode(true))
card=addon.editWindow.styleCard
local frame=pm.elements[id].frame
frame:GetScript('OnMouseDown')(frame,'LeftButton')
assert(pm.selected==id and card:IsShown() and card.title:GetText()=='Combat Timer')
local point,relative=card:GetPoint(1)
assert(relative==frame,'card sits beside the display')
local handle=pm.elements[id].decoration.handle
Click(card.closeButton)
assert(pm.selected==nil and not card:IsShown())
handle:GetScript('OnMouseDown')(handle,'LeftButton')
assert(pm.selected==id and card:IsShown(),'the name tag opens the card too')
''',
    'EditElementAppearance opens Layout with that display\'s card': r'''
assert(addon:EditElementAppearance(id))
assert(addon.editMode and pm.selected==id and addon.editWindow.styleCard:IsShown())
''',
    'escape leaves the mode without opening the game menu': r'''
Enter()
panel:GetScript('OnKeyDown')(panel,'ESCAPE')
Left();assert(config:IsShown() and panel.propagate==false)
''',
    'exit keeps positions already written': r'''
Enter()
assert(E:SetCoordinate('x',120) and E:SetCoordinate('y',-60))
Click(panel.doneButton)
local p=pm:GetPosition(id);assert(p.x==120 and p.y==-60)
assert(addon.db.modules.combatTimer.position.x==120)
''',
    'exit commits a typed coordinate that was not applied yet': r'''
Enter()
Click(card.positionToggle);assert(card.positionOpen and Visible(card.xInput))
card.xInput:SetFocus();card.xInput:SetText('77')
Click(panel.doneButton)
Left();assert(pm:GetPosition(id).x==77,'typed value committed')
''',
    'exit ends the drag in progress and saves it': r'''
Enter()
local frame=pm.elements[id].frame
local before=pm:GetPosition(id).x
assert(pm:StartDragging(id));frame.centerX=frame.centerX+40
Click(panel.doneButton)
Left();assert(not pm.elements[id].dragging and not frame.moving)
assert(pm:GetPosition(id).x==before+40,'drag saved')
''',
    'Grid is off by default; on, it shows guide lines and snaps a dropped display': r'''
Enter()
assert(E.grid==false and not panel.gridButton.selected and not (addon.layoutGrid and addon.layoutGrid:IsShown()))
local frame=pm.elements[id].frame
assert(pm:SetOffsets(id,0,0))
assert(pm:StartDragging(id));frame.centerX=frame.centerX+45;frame.centerY=frame.centerY-13;pm:StopDragging(id)
local p=pm:GetPosition(id);assert(p.x==45 and p.y==-13,'no snapping while Grid is off')
Click(panel.gridButton)
assert(E.grid and panel.gridButton.selected and addon.layoutGrid:IsShown())
assert(not addon.layoutGrid.mouse,'the grid never takes the mouse')
assert(pm:StartDragging(id));frame.centerX=frame.centerX+4;frame.centerY=frame.centerY+2;pm:StopDragging(id)
p=pm:GetPosition(id);assert(p.x==64 and p.y==-0,'snapped to the 32-unit grid: '..p.x..','..p.y)
-- Anchored displays keep the exact spot they were dropped on.
Pick(card.targetDropdown,'player')
assert(pm:SetOffsets(id,5,7))
assert(pm:StartDragging(id));frame.centerX=frame.centerX+3;pm:StopDragging(id)
p=pm:GetPosition(id);assert(p.target=='player' and p.x==8 and p.y==7)
Click(panel.doneButton)
assert(not addon.layoutGrid:IsShown(),'grid leaves with Layout')
''',
    'a module error cannot strand the panel': r'''
Enter()
local module=addon.modules.combatTimer
local original=module.SetEditMode
module.SetEditMode=function() error('module failure') end
local ok,message=pcall(Click,panel.doneButton)
module.SetEditMode=original
assert(not ok and tostring(message):find('module failure',1,true),'error stays visible')
Left();assert(config:IsShown())
''',
    'combat ends the mode without reopening settings': r'''
local closed=0
local module=addon.modules.combatTimer
addon:EnsureConfigPage('combatTimer')
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
    'Layout cannot start in combat': r'''
testCombat=true;testLockdown=true
assert(addon:SetEditMode(true)==false and not addon.editMode)
''',
    'the Position section is folded away until opened': r'''
Enter()
assert(not card.positionOpen and not Visible(card.targetDropdown) and not Visible(card.xInput))
local closed=card:GetHeight()
Click(card.positionToggle)
assert(card.positionOpen and Visible(card.targetDropdown) and Visible(card.placementDropdown) and Visible(card.xInput) and Visible(card.yInput))
assert(card:GetHeight()>closed,'the card grows to fit')
Click(card.positionToggle);assert(not Visible(card.targetDropdown))
''',
    'target dropdown keeps offsets and custom points': r'''
Enter()
assert(pm:SetOffsets(id,30,-20) and pm:SetAttachment(id,'TOP','BOTTOM'))
Pick(card.targetDropdown,'player')
local p=pm:GetPosition(id)
assert(p.target=='player' and p.x==30 and p.y==-20)
assert(p.point=='TOP' and p.relativePoint=='BOTTOM')
''',
    'Reset restores the default placement and style': r'''
Enter()
Pick(card.targetDropdown,'player');Pick(card.placementDropdown,'below')
assert(pm:SetOffsets(id,44,44) and pm:SetAttachment(id,'TOP','BOTTOM'))
assert(pm:SetStyle(id,'scale',150) and pm:SetStyle(id,'background',false))
Click(card.resetButton)
local p,d=pm:GetPosition(id),pm.elements[id].defaults
assert(p.target==d.target and p.placement==d.placement and p.x==d.x and p.y==d.y)
assert(p.point==nil and p.relativePoint==nil)
local s=pm:GetStyle(id)
assert(s.scale==100 and s.opacity==100 and s.text==100 and s.background==true)
assert(addon.db.modules.combatTimer.position.style==nil,'no style record left behind')
''',
    'Settings exits Layout and opens the module page': r'''
Enter()
Click(card.settingsButton)
assert(not addon.editMode and config:IsShown() and config.selectedPage=='combatTimer')
''',
    'placement dropdown applies the preset and keeps nudges': r'''
Enter()
Pick(card.targetDropdown,'player')
assert(pm:SetOffsets(id,0,0) and pm:SetAttachment(id,'TOP','BOTTOM'))
Pick(card.placementDropdown,'above')
local p=pm:GetPosition(id)
assert(p.placement=='above' and p.point==nil and p.relativePoint==nil)
assert(p.x==0 and p.y==8,'default gap applied')
assert(pm:SetOffsets(id,5,12))
Pick(card.placementDropdown,'below')
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
assert not failures, f'{len(failures)} of {len(CASES)} Layout cases failed'
print(f'PASS {len(CASES)} Layout bar, selection, Grid, exit, combat, Position section and secret-value cases (mock only)')
