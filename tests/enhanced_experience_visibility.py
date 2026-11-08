"""Provider visibility ownership and restoration fixtures; not native WoW."""
from enhanced_experience_bar import SETUP
from smoke import load

PROVIDERS = r'''
StatusTrackingBarInfo={BarsEnum={Experience=3,Reputation=1}}
nativeXP=CreateFrame('Frame');nativeRep=CreateFrame('Frame')
nativeContainer=CreateFrame('Frame');nativeContainer.bars={[3]=nativeXP,[1]=nativeRep}
nativeContainer.current=nativeXP
function nativeContainer:GetShownBar() return self.current end
function nativeContainer:UpdateShownState() self:SetShown(self.current~=nil) end
nativeContainer:Show()
StatusTrackingBarManager={barContainers={nativeContainer}}
EllesmereEAB_XPBar=CreateFrame('Frame');EllesmereEAB_XPBar:Show()
euiWantsShown=true;ownerUpdates=0
function EllesmereEAB_XPBar._updateFunc()
 ownerUpdates=ownerUpdates+1;EllesmereEAB_XPBar:SetShown(euiWantsShown)
end
-- These unrelated frames/settings must never be modified.
otherSuite=CreateFrame('Frame');otherSuite:Show()
providerSettings={rep=true,xp=true,style='forever'}
'''
lua, _ = load(before=SETUP + PROVIDERS)
lua.execute(r'''
local M=addon.EnhancedExperienceBar
addon:SetModuleEnabled(M.id,true)
assert(M.db.barChoice=='ptg' and not M.db.hideBlizzardXP and not M.db.hideEllesmereXP)
assert(M.frame:IsShown() and nativeContainer:IsShown() and EllesmereEAB_XPBar:IsShown(),'no default suppression')
assert(M:ChooseXPBar(true))
assert(M.frame:IsShown() and not nativeContainer:IsShown() and not EllesmereEAB_XPBar:IsShown())
nativeContainer:Show();EllesmereEAB_XPBar:Show()
assert(not nativeContainer:IsShown() and not EllesmereEAB_XPBar:IsShown(),'owner refresh cannot resurrect opted-out XP')
testCombat=true;testLockdown=true
nativeContainer:Show();EllesmereEAB_XPBar:Show()
assert(not nativeContainer:IsShown() and not EllesmereEAB_XPBar:IsShown(),'only verified unprotected frames hidden in combat')
assert(not M:ChooseXPBar(false))
testCombat=false;testLockdown=false
nativeContainer.current=nativeRep;nativeContainer:Show()
assert(nativeContainer:IsShown(),'native reputation remains visible')
assert(M:SetOption('hideEllesmereXP',false) and EllesmereEAB_XPBar:IsShown())
nativeContainer.current=nativeXP;nativeContainer:Hide();nativeContainer:Show()
assert(not nativeContainer:IsShown())
assert(M:ChooseXPBar(false) and not M.frame:IsShown() and nativeContainer:IsShown())
assert(not addon.PositionManager.elements[M.id].editMode,'existing-provider mode has no PTG Edit handle')
assert(otherSuite:IsShown() and providerSettings.rep and providerSettings.xp and providerSettings.style=='forever')
assert(M:ChooseXPBar(true))
euiWantsShown=false;assert(M:ChooseXPBar(false))
assert(not EllesmereEAB_XPBar:IsShown(),'restore respects owner disabled/max-level state')
assert(nativeContainer:IsShown())
euiWantsShown=true;EllesmereEAB_XPBar._updateFunc();assert(M:ChooseXPBar(true))
testCombat=true;testLockdown=true;addon:SetModuleEnabled(M.id,false)
assert(M.otherBarsPending and not nativeContainer:IsShown())
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(nativeContainer:IsShown() and EllesmereEAB_XPBar:IsShown() and not M.otherBarsPending)
assert(next(M.otherBarEvents.events)==nil,'disabled module releases event listeners after restoration')
-- Load-on-demand provider discovery; a protected replacement is never touched.
addon:SetModuleEnabled(M.id,true)
local old=EllesmereEAB_XPBar;EllesmereEAB_XPBar=CreateFrame('Frame');EllesmereEAB_XPBar.protected=true
EllesmereEAB_XPBar:Show();FireEvent('ADDON_LOADED','EllesmereUIActionBars')
assert(EllesmereEAB_XPBar:IsShown(),'protected foreign frame skipped')
assert(M:OtherBarsStatus():find('unsupported'))
EllesmereEAB_XPBar=old
local state=addon.ProfileCodec.Copy(addon.db);state.modules[M.id].barChoice='unknown'
assert(not addon.ProfileValidation:Validate(state),'provider setting validated')
''')
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(encoded=state, before=SETUP + PROVIDERS)
restored.execute('''
local M=addon.EnhancedExperienceBar
assert(M.enabled and M.db.hideBlizzardXP and M.db.hideEllesmereXP)
assert(not nativeContainer:IsShown() and not EllesmereEAB_XPBar:IsShown())
''')
print('PASS opt-in provider choice, XP-only hiding, re-show hooks, combat guards, owner-aware restore, disabled cleanup, protected frames and persistence')
