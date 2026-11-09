"""Optional per-weapon charge reminders; guards do not prove native API behavior."""
from rogue_poisons import SETUP
from smoke import load

lua,_=load(before=SETUP)
lua.execute(r'''
local M=addon.ForeverRogue
function Charged(slot,seconds,n,icon,id)
 Poison(slot,seconds,icon,id);enchants[slot][1].charges=n
end
Charged(0,1800,60);Charged(1,1800,60,302)
addon:SetModuleEnabled('foreverRogue',true);M:SetOption('flyout',true)
assert(M.db.timeReminder and M.db.chargeReminder and M.db.chargeThreshold==10 and not M.db.showPoisonCharges)
assert(not M.watcher:IsShown() and not M.launcher:IsShown())
-- Inclusive 5..25 boundaries, independent hands and shared launcher predicate.
for threshold=5,25 do
 assert(M:SetOption('chargeThreshold',threshold))
 Charged(0,1800,threshold+1);Charged(1,1800,60,302);M:Refresh()
 assert(not M.watcher:IsShown() and not M.launcher:IsShown())
 Charged(0,1800,threshold);M.ticker.callback()
 assert(M.watchButtons[1]:IsShown() and not M.watchButtons[2]:IsShown() and M.launcher:IsShown())
 assert(M.watchButtons[1].description:find('Poison charges: '..threshold,1,true))
 Charged(0,1800,threshold-1);M.ticker.callback();assert(M.watchButtons[1]:IsShown())
end
assert(not M:SetOption('chargeThreshold',4) and not M:SetOption('chargeThreshold',26) and not M:SetOption('chargeThreshold',10.5))
M:SetOption('chargeThreshold',10);M:SetOption('chargeReminder',false)
assert(not M.watcher:IsShown() and not M.launcher:IsShown(),'Charge trigger is independently optional')
Charged(0,300,60);M:Refresh();assert(M.watchButtons[1]:IsShown(),'Timer still works with charge trigger off')
M:SetOption('timeReminder',false);assert(not M.watcher:IsShown())
M:SetOption('chargeReminder',true);Charged(0,1800,60);Charged(1,1800,7,302);M:Refresh()
assert(not M.watchButtons[1]:IsShown() and M.watchButtons[2]:IsShown(),'Another poison family/hand can report charges')
for _,id in ipairs(M.Data.families) do
 local info=C_Spell.GetSpellInfo(id);Charged(1,1800,7,info.iconID,12000+id);M:Refresh()
 assert(M.watchButtons[2]:IsShown() and M.watchButtons[2].icon.texture==info.iconID,'Every family uses the same native charge field')
end
M:SetOption('showPoisonCharges',true);assert(M.watchButtons[2].poisonCharges:GetText()=='7c' and M.watchButtons[2].poisonCharges:IsShown())
assert(not M.watchButtons[2].count:IsShown(),'Applied charges are separate from carried inventory counts')
-- Missing/restricted/malformed charge fields preserve the public timer path.
M:SetOption('timeReminder',true)
for _,value in ipairs({{secret=true},'7',-1,2.5}) do
 Charged(0,1800,value);Charged(1,1800,60,302);M:Refresh()
 assert(not M.watcher:IsShown() and not M:ReadHand(1).hasCharges)
 Charged(0,299,value);M:Refresh();assert(M.watchButtons[1]:IsShown() and not M.watchButtons[1].poisonCharges:IsShown())
end
Poison(0,1800);M:Refresh();assert(not M.watcher:IsShown(),'No charge field is not treated as zero/exhaustion')
Charged(0,1800,0,301,9000);M:Refresh();assert(not M.watcher:IsShown(),'Unobserved zero is not a false no-charge reminder')
Charged(0,1800,5,301,9000);M:Refresh();assert(M.watchButtons[1]:IsShown())
Charged(0,1800,0,301,9000);M:Refresh();assert(M.watchButtons[1]:IsShown() and M.watchButtons[1].poisonCharges:GetText()=='0c','Public zero after positive count is exhausted')
Charged(0,1800,0,301,9001);M:Refresh();assert(not M.watcher:IsShown(),'Charge capability does not carry to another enchant')
-- Decreasing charges do not rearm dismissal; replenishment does.
Charged(0,1800,8);M:Refresh();M:DismissReminder(1)
Charged(0,1800,7);M:Refresh();assert(not M.watchButtons[1]:IsShown())
Charged(0,1800,12);M:Refresh();assert(not M.dismissed[1])
Charged(0,1800,10);M:Refresh();assert(M.watchButtons[1]:IsShown())
-- Charge thresholds can cross in combat, with native dispatch still blocked.
M:SetOption('chargeThreshold',25);Charged(0,1800,26);M:Refresh();assert(not M.watcher:IsShown())
local n=#applications;testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
Charged(0,1800,25);M.ticker.callback();assert(M.watchButtons[1]:IsShown() and not M.launcher:IsShown())
Click(M.watchButtons[1]);assert(#applications==n)
local tip=M.watchButtons[1].description;M.ticker.callback();assert(M.watchButtons[1].description==tip,'Combat tooltip does not accumulate charge text')
Charged(0,1800,{secret=true});M.ticker.callback();assert(not M.watcher:IsShown(),'Restricted count is not inferred from previous public count')
testCombat=false;testLockdown=false;Charged(0,1800,25);FireEvent('PLAYER_REGEN_ENABLED');assert(M.launcher:IsShown())
-- Existing missing/unknown warnings remain even if both numeric triggers are off.
M:SetOption('timeReminder',false);M:SetOption('chargeReminder',false);enchants[0]={};M:Refresh();assert(M.watchButtons[1]:IsShown())
Charged(0,1800,60);M:Refresh();assert(not M.watcher:IsShown())
addon:ToggleConfig();addon:SelectConfigPage('foreverRogue');local p=M.page
assert(p.poisonControls.timeReminder and p.poisonControls.chargeReminder and p.poisonControls.showPoisonCharges)
p.poisonSliders['root:chargeThreshold'].numericInput:SetText('15');p.poisonSliders['root:chargeThreshold'].numericInput.scripts.OnEnterPressed()
assert(M.db.chargeThreshold==15)
p.poisonControls.chargeReminder.frame.scripts.OnClick();assert(M.db.chargeReminder)
M:MinimalReminder();assert(not M.db.showPoisonCharges and not M.watchButtons[1].poisonCharges:IsShown())
M:SetOption('chargeReminder',false)
''')
saved=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded=saved,before=SETUP)
restored.execute(r'''
local M=addon.ForeverRogue
assert(M.db.chargeThreshold==15 and not M.db.timeReminder and not M.db.chargeReminder and not M.db.showPoisonCharges)
assert(next(M.chargeSources)==nil,'Charge capability observations are session-only')
''')
print('PASS Rogue charges: 5..25 inclusive boundaries, either-trigger visibility, all families/hands, optional counters, unknown/zero semantics, dismissal/replenishment, combat, real UI fields and persistence')
