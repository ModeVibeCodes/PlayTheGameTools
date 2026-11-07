"""Native-text formatting and refresh-safe dual-window movement fixtures."""
from campfire_monitor import FIXTURE
from smoke import load

lua,_=load(before=FIXTURE)
lua.execute(r'''
-- Native tooltip values, not profession-guide constants, determine output.
local cases={
 {'Camp Chair: Chance to critically strike increased by 2%.','2% Crit'},
 {'Fish Bowl: All stats increased by 8%.','8% Stats'},
 {'Fish Bowl: Gain 8% increased stats.','8% Stats'},
 {'First Aid Kit: +12 Stamina','12 Stamina'},
 {'Crit: +2%','2% Crit'},
 {'All Stats: +8%','8% Stats'},
 {'Incense Candle: Intellect increased by 4.','4 Int'},
 {'Banner: Increases Spirit by 11.','11 Spirit'},
 {'Lodestone: +90 melee attack power','90 AP'},
 {'Enchanted Lute: +1,234 Armor','1,234 Armor'},
 {'Camp Chair: Critical strike increased by 2.5%.','2.5% Crit'},
 {'Mana Well: Regenerate 29 Mana every 5 sec.','29 Mana / 5 sec'},
 {'Unknown bonus: +7% Haste','Unknown bonus: +7% Haste'},
 {'Force +8','Force +8'},
 {'Critter Charm: 8%','Critter Charm: 8%'}, -- untranslated/unrecognized text survives
 {'Strength and Stamina increased by 5.','Strength and Stamina increased by 5.'},
}
for _,entry in ipairs(cases) do
 local result=C.CompactLine(entry[1]);assert(#result==1 and result[1]==entry[2],entry[1]..' -> '..table.concat(result,'|'))
end
local multiple=C.CompactLine('Enchanted Lute: 300 Armor, 13 all stats, and 22 resistances')
assert(table.concat(multiple,'|')=='300 Armor|13 Stats|22 Resists')
assert(C.CompactLine('Crit: 2-3% increased critical strike')[1]=='Crit: 2-3% increased critical strike','ambiguous amount is not guessed')
tips[102]={lines={{leftText='Camp Benefits'},
 {leftText='Camp Chair: Critical strike chance increased by 2%.'},
 {leftText='Fish Bowl: All stats increased by 8%.'}}}
auras={{spellId=C.BENEFITS,auraInstanceID=102}}
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
assert(C.snapshot.nearby==false and C.frame:IsShown(),'joined earned buffs survive leaving camp')
assert(Plain(C.frame.text:GetText()):find('2%% Crit\n8%% Stats'))
assert(C:SetOption('separateBenefits',true))
assert(not C.frame:IsShown() and C.benefitsFrame:IsShown())
assert(Plain(C.benefitsFrame.text:GetText())=='2% Crit\n8% Stats')
assert(not C.benefitsFrame.icon:IsShown(),'separate buff window stays simple')
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles');M.page:SelectSectionTab(2)
local page=M.page
assert(C.db.locked and C.db.benefitsLocked,'saved locks are respected outside placement mode')
page.campfireMove.scripts.OnClick()
assert(C.placing and C.frame:IsShown() and C.benefitsFrame:IsShown())
assert(page.campfireMove.label:GetText()=='Finish Moving')
assert(C.frame.mouse and C.benefitsFrame.mouse,'placement mode accepts mouse input even with saved locks')
C.frame.centerX=550;C.frame.centerY=430
local mainAnchor=C.frame.anchor
C.frame.scripts.OnDragStart();assert(C.frame.dragging and C.frame.moving)
FireEvent('UNIT_AURA','player')
assert(C.frame.anchor==mainAnchor and C.frame.dragging,'aura refresh must not re-anchor an active drag')
addon.Media:RefreshFonts()
assert(C.frame.anchor==mainAnchor and C.frame.dragging,'font refresh must not re-anchor an active drag')
C.frame.scripts.OnDragStop();assert(C.db.x==50 and C.db.y==30 and not C.frame.dragging)
assert(C:SetOption('benefitsScale',125))
C.benefitsFrame.centerX=640;C.benefitsFrame.centerY=350
local buffAnchor=C.benefitsFrame.anchor
C.benefitsFrame.scripts.OnDragStart();assert(C.benefitsFrame.dragging)
FireEvent('UNIT_AURA','player');assert(C.benefitsFrame.anchor==buffAnchor)
C.benefitsFrame.scripts.OnDragStop()
assert(C.db.benefitsX==300 and C.db.benefitsY==38,'independent scaled position saved')
C.benefitsFrame.scripts.OnMouseUp(C.benefitsFrame,'RightButton')
assert(not C.placing and not C.benefitsFrame.mouse and not C.frame:IsShown())
assert(C:SetOption('compactBenefits',false))
assert(Plain(C.benefitsFrame.text:GetText()):find('Camp Chair: Critical strike',1,true))
assert(C:SetOption('compactBenefits',true) and C:SetOption('separateBenefits',false))
assert(C.frame:IsShown() and not C.benefitsFrame:IsShown())
assert(C.db.benefitsX==300 and C.db.x==50,'joining preserves both saved positions')
C:SetOption('separateBenefits',true);C:SetPlacementMode(true)
C.benefitsFrame.scripts.OnDragStart()
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
assert(not C.placing and not C.frame:IsShown() and not C.benefitsFrame:IsShown())
assert(not C.benefitsFrame.dragging and not C.benefitsFrame.moving)
assert(not C:SetPlacementMode(true))
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(C.benefitsFrame:IsShown() and not C.frame:IsShown())
C:SetOption('showBenefits',false);assert(not C.benefitsFrame:IsShown())
C:SetOption('showBenefits',true)
auras={};FireEvent('UNIT_AURA','player');assert(not C.benefitsFrame:IsShown(),'no stale buffs when aura ends')
rejectAura=true;FireEvent('UNIT_AURA','player');assert(not C.benefitsFrame:IsShown(),'unknown data is not stale success')
rejectAura=nil
auras={{spellId=C.BENEFITS,auraInstanceID=102}};FireEvent('UNIT_AURA','player')
C:SetPlacementMode(true);addon:SetModuleEnabled('lootSparkles',false)
assert(not C.placing and not C.benefitsFrame:IsShown(),'master disable ends placement and both displays')
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE)
restored.execute('''
assert(C.db.separateBenefits and C.db.compactBenefits and C.db.benefitsScale==125)
assert(C.db.x==50 and C.db.y==30 and C.db.benefitsX==300 and C.db.benefitsY==38)
assert(not C.placing and not C.previewing,'transient placement is never saved')
local candidate=addon.ProfileCodec.Copy(addon.db)
candidate.modules.lootSparkles.campfire.benefitsFontSize=80
assert(not addon.ProfileValidation:Validate(candidate))
''')
preview,_=load(before=FIXTURE)
preview.execute('''
C:SetOption('separateBenefits',true);C:TogglePreview()
assert(C.db.locked and C.db.benefitsLocked and C.frame.mouse and C.benefitsFrame.mouse)
C.frame.scripts.OnDragStart();C.benefitsFrame.scripts.OnDragStart()
assert(C.frame.dragging and C.benefitsFrame.dragging,'both preview windows draggable with saved locks')
C:StopPreview()
assert(not C.frame:IsShown() and not C.benefitsFrame:IsShown())
assert(not C.frame.dragging and not C.benefitsFrame.dragging)
''')
print('PASS compact native stat text, ambiguous/localized fallback, joined/detached earned buffs, placement with saved locks, drag stability under aura/font refresh, scaled independent positions, combat and persistence (mock only)')
