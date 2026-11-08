"""The merged Quick Actions launcher: ring layout, closing rules, Edit Mode and Class Training's popout."""
from smoke import load

SETUP = r'''
    Q,pm,CT,DL=addon.QuickActions,addon.PositionManager,addon.ForeverClassTraining,addon.DungeonLoot
    -- Fixture-level training data; the catalog reader has its own coverage.
    function ForceTraining()
        CT.RefreshTraining=function(self) self.snapshot={class=addon.ForeverTrainingData.class};self.rows=self.rows or {};self:SyncTrainingDisplays();return true end
        CT:RefreshTraining()
    end
    function Offset(button)
        local p=button.points[#button.points]
        return p[4],p[5]
    end
    function Click(frame) frame.scripts.OnClick(frame) end
'''

lua, _ = load()
lua.execute(SETUP)
lua.execute(r'''
    assert(not addon.modules.quickActions and #addon.moduleOrder==10,'no page or switch of its own')
    ForceTraining()
    local b,ring=Q.launcher,Q.ring
    assert(b and b:IsShown() and b.icon.texture=='Interface\\Icons\\INV_Misc_Gear_01' and b.clamped)
    assert(pm.elements.quickActionsLauncher.label=='Quick Actions' and #b.ring==48)
    assert(CT.shortcut:GetParent()==ring and CT.shortcut.icon.texture=='Interface\\Icons\\INV_Misc_Book_09')
    assert(not ring:IsShown(),'starts closed')

    -- Only Class Training: one icon directly above.
    assert(Q.count==1);Click(b);assert(ring:IsShown())
    local x,y=Offset(CT.shortcut);assert(math.abs(x)<0.001 and y==74)
    Click(b);assert(not ring:IsShown(),'main button toggles the ring shut')

    -- Two icons sit opposite each other in a stable order.
    addon:SetModuleEnabled('dungeonLoot',true)
    assert(Q.count==2 and DL.shortcut:GetParent()==ring)
    local x1,y1=Offset(CT.shortcut);local x2,y2=Offset(DL.shortcut)
    assert(math.abs(x1)<0.001 and y1==74 and math.abs(x2)<0.001 and math.abs(y2+74)<0.001)
    assert(b.clampInsets[1]==-74 and b.clampInsets[2]==74 and b.clampInsets[3]==74 and b.clampInsets[4]==-74,'ring stays on screen')

    -- Larger icons widen the ring and its screen margin.
    DL:SetShortcutOption('shortcutSize',72)
    local _,wide=Offset(CT.shortcut);assert(wide==20+36+34)
    assert(b.clampInsets[2]==wide+36-20)
    DL:SetShortcutOption('shortcutSize',40)

    -- Clicking an icon closes the ring and runs that icon's action.
    Click(b);assert(ring:IsShown())
    Click(DL.shortcut)
    assert(not ring:IsShown() and addon.configWindow:IsShown() and DL.page:IsShown())
    addon.configWindow:Hide()

    -- Class Training's popout survives the ring closing and anchors to the launcher.
    Click(b);Click(CT.shortcut)
    local f=CT.trainingFlyout
    assert(not ring:IsShown() and f:IsShown() and b.openGlow:IsShown(),'popout stays open with the glow on the main button')
    b.centerX=320;b.centerY=240
    assert(CT:PlaceTrainingFlyout() and f:IsShown())
    Click(f.minimizeButton);assert(not f:IsShown() and not b.openGlow:IsShown())
    Click(b);Click(CT.shortcut);assert(f:IsShown())
    Click(b);Click(CT.shortcut);assert(not f:IsShown() and not ring:IsShown(),'reopening the ring and clicking again closes it')

    -- Removing an icon re-spreads the rest and closes its popout.
    Click(b);Click(CT.shortcut);assert(f:IsShown())
    CT.db.showShortcut=false;CT:SyncTrainingDisplays()
    assert(not f:IsShown() and not CT.shortcut:IsShown() and Q.count==1 and b:IsShown())
    local _,top=Offset(DL.shortcut);assert(top==74,'remaining icon takes the first slot')
    -- With nothing left the main button and its Edit Mode element go too.
    addon:SetModuleEnabled('dungeonLoot',false)
    assert(Q.count==0 and not b:IsShown() and not pm.elements.quickActionsLauncher.editMode)
    CT.db.showShortcut=true;CT:SyncTrainingDisplays();assert(Q.count==1 and b:IsShown() and pm.elements.quickActionsLauncher.editMode)

    -- Combat closes the ring and blocks reopening it.
    Click(b);assert(ring:IsShown())
    testCombat=true;FireEvent('PLAYER_REGEN_DISABLED');assert(not ring:IsShown())
    Click(b);assert(not ring:IsShown(),'no ring in combat')
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')

    -- Edit Mode closes the ring; clicks select and drags do not open it.
    Click(b);assert(ring:IsShown())
    assert(addon:SetEditMode(true) and not ring:IsShown())
    local e=pm.elements.quickActionsLauncher
    assert(pm.selected==e.id and e.decoration.handle:IsShown())
    Click(b);assert(not ring:IsShown())
    local timer=C_Timer.After;local queued={};C_Timer.After=function(_,fn) queued[#queued+1]=fn end
    b.centerX=800;b.centerY=300
    b.scripts.OnDragStart(b);assert(e.dragging and b.wasDragged)
    b.scripts.OnDragStop(b);assert(not e.dragging)
    addon:SetEditMode(false);assert(b.mouse)
    Click(b);assert(not ring:IsShown(),'release after a drag is not a click')
    for _,fn in ipairs(queued) do fn() end;C_Timer.After=timer
    assert(addon.db.positions.quickActionsLauncher.x==e.position.x)
    Click(b);assert(ring:IsShown());Click(b)
    -- The panel's module-settings button has no page to open for the launcher.
    assert(addon:SetEditMode(true) and pm.selected==e.id)
    local settings=addon.editWindow.settingsButton
    assert(not settings:IsEnabled())
    Click(settings);assert(addon.editMode,'stays in Edit Mode instead of opening a missing page')
    addon:SetEditMode(false)
    CT.db.shortcutPosition={x=11,y=22}
''')
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(state)
restored.execute(SETUP)
restored.execute(r'''
    local before=addon.ProfileCodec.Copy(addon.db.positions.quickActionsLauncher)
    ForceTraining()
    local p=pm:GetPosition('quickActionsLauncher')
    assert(p.x==before.x and p.y==before.y,'launcher position survives reload')
    assert(CT.db.shortcutPosition.x==11,'old icon position left in the profile')
''')
# First run after updating: the launcher takes over a moved Class Training icon.
upgrade, _ = load(before='''
    PTGToolsDB={modules={foreverClassTraining={enabled=true,shortcutPosition={x=250,y=-60}},
        dungeonLoot={enabled=true,shortcutPosition={x=9,y=9}}},positions={dungeonLootShortcut={target="screen",placement="center",x=9,y=9}}}
''')
upgrade.execute(SETUP)
upgrade.execute(r'''
    ForceTraining()
    local e=pm.elements.quickActionsLauncher
    assert(e.position.x==250 and e.position.y==-60,'seeded from the Class Training icon')
    assert(addon.db.positions.dungeonLootShortcut.x==9 and DL.db.shortcutPosition.x==9,'older settings untouched')
    assert(pm:ResetPosition(e.id) and e.position.x==-180 and e.position.y==-140,'reset uses the factory spot')
''')
# Malformed saved data is reported and retried without building new frames.
broken, _ = load(before='''
    PTGToolsDB={modules={dungeonLoot={enabled=true}}}
    local register=addon.PositionManager.RegisterElement
    addon.PositionManager.RegisterElement=function(self,id,...)
        if id=='quickActionsLauncher' then return false,'invalid-offsets' end
        return register(self,id,...)
    end
''')
broken.execute(SETUP)
broken.execute(r'''
    assert(DL.shortcut and Q.launcher and not Q.element and Q.launcherFailure=='invalid-offsets')
    assert(Q.launcher:IsShown() and Q.launcher.mouse,'still usable at its starting spot')
    local launcher,before=Q.launcher,#frames
    for _=1,3 do FireEvent('PLAYER_REGEN_ENABLED') end
    assert(#frames==before and Q.launcher==launcher,'no rebuilt frames on retry')
    local noop=Q:ResetPosition();assert(noop==false)
''')
# Logging in during combat defers construction to the owners' next safe sync.
deferred, _ = load(before='testCombat=true;PTGToolsDB={modules={dungeonLoot={enabled=true}}}')
deferred.execute(SETUP)
deferred.execute(r'''
    assert(not Q.launcher and not DL.shortcut)
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    assert(Q.launcher and Q.launcher:IsShown() and DL.shortcut:IsShown() and Q.element)
''')
print('PASS Quick Actions ring layout, closing rules, popout anchoring/glow, availability, combat, Edit Mode, position seeding/retention and failure recovery')
