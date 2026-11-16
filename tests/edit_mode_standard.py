"""One Edit Mode standard: every display is managed, resets go home after reload,
settings pages carry no placement rows, and idle timers stay off (mock only)."""
from campfire_monitor import FIXTURE
from smoke import load

lua, _ = load(before=FIXTURE)
lua.execute(r'''
local PM=addon.PositionManager
for _,id in ipairs({'combatTimer','threatMeter','lootSparkles'}) do addon:SetModuleEnabled(id,true) end
C:SetOption('enabled',true);C:SetOption('alwaysShow',true)
for _,id in ipairs({'combatTimer','threatMeter','campfireMonitor'}) do assert(PM.elements[id],'managed display '..id) end
-- No settings page offers placement: it lives only in Edit Mode.
addon:ToggleConfig()
local banned={['Positioning']=true,['Position']=true,['Food Positioning']=true}
for _,id in ipairs(addon.moduleOrder) do
 local page=addon:EnsureConfigPage(id)
 for _,section in ipairs(page.sections or {}) do assert(not banned[section.title],'placement section on '..id) end
 for _,row in ipairs(page.rows or {}) do
  local title=row.settingsTitle or ''
  -- Text/sparkle offsets inside a display are appearance, not screen placement.
  local inner={['Bar Text Vertical Offset']=true,['Session Horizontal Offset']=true,['Vertical Offset']=true}
  assert(not title:find('Offset',1,true) or inner[title],'offset row on '..id..': '..title)
  for _,cell in ipairs(row.settingsToggles or {}) do assert(not cell.label:GetText():find('^Lock '),'lock toggle on '..id) end
 end
end
assert(addon:SetEditMode(true))
assert(PM:SetOffsets('campfireMonitor',75,-30) and PM:SetOffsets('threatMeter',40,40))
addon:SetEditMode(false)
-- The XP session clock exists only while session text is shown.
addon:SetModuleEnabled('enhancedExperienceBar',true)
local X=addon.EnhancedExperienceBar
assert(X.tick,'clock runs while session text is shown')
X:SetOption('showSession',false);assert(X.tick,'XP/hr still needs the clock')
X:SetOption('showRate',false);assert(X.tick==nil,'no clock when nothing uses it')
X:SetOption('showRate',true);assert(X.tick)
''')
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(state, before=FIXTURE)
restored.execute(r'''
local PM=addon.PositionManager
assert(addon.db.positions.campfireMonitor.x==75,'moved position persists')
assert(addon:SetEditMode(true))
assert(PM:ResetPosition('campfireMonitor') and PM:ResetPosition('threatMeter'))
local camp,threat=PM:GetPosition('campfireMonitor'),PM:GetPosition('threatMeter')
assert(camp.x==0 and camp.y==-240,'campfire resets to its home, not the reloaded position')
assert(threat.x==320 and threat.y==-120,'threat meter resets to its home')
addon:SetEditMode(false)
''')
combat, _ = load(before=FIXTURE)
combat.execute(r'''
local PM=addon.PositionManager
testCombat=true;testLockdown=true
addon:SetModuleEnabled('threatMeter',true)
assert(not PM.elements.threatMeter,'no registration in combat')
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(PM.elements.threatMeter,'registers once combat ends')
''')
layout, _ = load(before=FIXTURE)
layout.execute(r'''
local PM,P=addon.PositionManager,addon.Positioning
-- A frame shown this frame can lack a rectangle until the next layout pass.
local geometry,pending=P.Geometry,true
P.Geometry=function(self,frame)
 if pending and frame==_G.PlayTheGameToolsThreatMeterFrame then return nil end
 return geometry(self,frame)
end
addon:SetModuleEnabled('threatMeter',true)
assert(not PM.elements.threatMeter and PM.layoutDriver:GetScript('OnUpdate'),'one retry is scheduled')
pending=false -- the next layout pass resolves the rectangle
PM.layoutDriver:GetScript('OnUpdate')(PM.layoutDriver,0)
P.Geometry=geometry
assert(PM.elements.threatMeter and PM.elements.threatMeter.editMode,'registered on the next frame')
assert(not PM.layoutDriver:GetScript('OnUpdate'),'no retry loop')
-- Empty bars are still placeable in Edit Mode, as labeled placeholders.
addon:SetModuleEnabled('foreverQuickAccess',true)
local Q=addon.ForeverQuickAccess
assert((Q.visibleCount or 0)==0 and not Q.bar:IsShown(),'empty bar hidden normally')
assert(addon:SetEditMode(true))
assert(Q.bar:IsShown() and Q.bar.placeholder:IsShown() and PM.elements.foreverQuickAccess.editMode,'placeholder in Edit Mode')
addon:SetEditMode(false)
assert(not Q.bar:IsShown() and not PM.elements.foreverQuickAccess.editMode,'placeholder leaves with Edit Mode')
''')
print('PASS Edit Mode standard: managed displays, no page placement rows, home resets after reload, post-combat and next-frame registration, empty-bar placeholders, idle XP clock off (mock only)')
