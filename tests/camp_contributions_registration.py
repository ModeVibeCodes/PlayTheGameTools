"""Contribution registration occurs after Show; unavailable geometry cannot spam."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

GEOMETRY=r'''
mode='delayed';layoutReady=false;registrationAttempts=0
local register=addon.PositionManager.RegisterElement
function addon.PositionManager:RegisterElement(id,frame,options)
 if id=='campfireContributions' then
  registrationAttempts=registrationAttempts+1
  assert(frame:IsShown(),'never register a hidden contribution frame')
  assert(frame.title and frame.hint and frame.footer and frame.content and frame.viewport,'finish construction before registration')
  if not frame.originalCenter then
   frame.originalCenter=frame.GetCenter
   frame.GetCenter=function(f)
    if mode=='delayed' and not layoutReady then return nil,nil end
    if mode=='unavailable' then return nil,nil end
    return f.originalCenter(f)
   end
  end
  if mode=='protected' then frame.protected=true end
 end
 return register(self,id,frame,options)
end
function Enable() addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true) end
function Tick()
 local callback=A.positionDriver and A.positionDriver:GetScript('OnUpdate')
 assert(callback,'expected one deferred registration');callback(A.positionDriver,0.016)
end
'''

lua,_=load(before=FIXTURE+EXTRA+GEOMETRY)
lua.execute(r'''
Enable();A:TogglePreview()
assert(A.window:IsShown() and A.window.sample:IsShown() and A.positionRetryPending)
assert(registrationAttempts==1 and not addon.PositionManager.elements.campfireContributions)
for i=1,10 do FireEvent('BAG_UPDATE_DELAYED') end
assert(registrationAttempts==1,'events cannot multiply a pending retry')
layoutReady=true;Tick()
assert(registrationAttempts==2 and addon.PositionManager.elements.campfireContributions)
assert(not A.positionDriver:GetScript('OnUpdate') and not A.positionRetryPending and not A.positionFailure)
assert(A.window:IsShown() and #macroCalls==0)
''')

failed,_=load(before=FIXTURE+EXTRA+GEOMETRY)
failed.execute(r'''
mode='unavailable';Enable()
auras={{spellId=C.NEARBY,auraInstanceID=101}};FireEvent('UNIT_AURA','player')
assert(A.window:IsShown() and #A.items==2 and registrationAttempts==1)
Tick()
assert(A.positionFailure=='invalid-frame' and not A.window:IsShown())
assert(A.buttons[1]:GetAttribute('type1')==nil and A.buttons[1]:GetAttribute('macrotext1')==nil)
for i=1,174 do FireEvent('BAG_UPDATE_DELAYED');FireEvent('UNIT_AURA','player') end
assert(registrationAttempts==2 and not A.positionDriver:GetScript('OnUpdate'),'no retry/assert loop')
assert(A:Summary():find('invalid-frame',1,true) and #macroCalls==0)
mode='ready';assert(A:Open())
assert(registrationAttempts==3 and not A.positionFailure and addon.PositionManager.elements.campfireContributions)
assert(A.window:IsShown() and A.buttons[1]:GetAttribute('type1')=='macro')
''')

for cancel in ('combat','disable','dismiss'):
    state,_=load(before=FIXTURE+EXTRA+GEOMETRY)
    state.globals().cancelCase=cancel
    state.execute(r'''
Enable();A:TogglePreview();assert(A.positionRetryPending)
local callback=A.positionDriver:GetScript('OnUpdate')
if cancelCase=='combat' then testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
elseif cancelCase=='disable' then C:SetOption('showContributionPopup',false)
else A:Dismiss() end
assert(not A.window:IsShown() and not A.positionDriver:GetScript('OnUpdate'))
layoutReady=true;callback(A.positionDriver,0.016)
assert(registrationAttempts==1 and #macroCalls==0,'stale callback is inert')
''')

protected,_=load(before=FIXTURE+EXTRA+GEOMETRY)
protected.execute(r'''
mode='protected';Enable();A:TogglePreview()
assert(A.positionFailure=='protected-frame' and registrationAttempts==1)
assert(not A.window:IsShown() and not A.positionRetryPending,'no retry/bypass for protected rejection')
for i=1,5 do FireEvent('BAG_UPDATE_DELAYED') end
assert(registrationAttempts==1)
''')
print('PASS shown/complete construction before registration, deferred layout recovery, bounded permanent failure, 174-event suppression, native attributes cleared, manual recovery, protected rejection and cancellation (mock only)')
