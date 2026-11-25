"""Profession & Food Bars put one Quick Actions ring icon per shown profession. Mock only."""
from smoke import load

BEFORE = r'''
function GetProfessions() return 11,nil,12,nil,14 end
function GetProfessionInfo(index)
 if index==11 then return 'Alchemy',136240,120,150,1,0,171 end
 if index==12 then return 'First Aid',135966,300,300,1,0,129 end
 if index==14 then return 'Cooking',133971,75,150,1,0,185 end
end
opened={}
C_TradeSkillUI={OpenTradeSkill=function(id) opened[#opened+1]=id;return true end}
'''

lua, _ = load(before=BEFORE)
lua.execute(r'''
local Q,M=addon.QuickActions,addon.ForeverQuickAccess
local function Ids()
 local list={}
 for i=1,5 do local a=Q.actions['profession'..i];if a and a.available then list[#list+1]=a end end
 return list
end
assert(#Ids()==0,'no ring icons while the module is off')
addon:SetModuleEnabled('foreverQuickAccess',true)
local shown=Ids()
assert(#shown==3,'one ring icon per learned profession')
assert(shown[1].button:GetParent()==Q.ring and shown[1].button.icon.texture==136240,'icon is the profession icon')
assert(shown[1].order>30 and shown[3].order>shown[1].order,'after Class Training, Dungeon Loot and Guild')
assert(Q.launcher:IsShown(),'the launcher is shown')
-- Clicking a ring icon closes the ring and opens that profession.
Q:SetExpanded(true);shown[2].button.scripts.OnClick(shown[2].button)
assert(opened[1]==129 and not Q.ring:IsShown(),'opens First Aid and closes the ring')
-- Hiding a profession on the page takes it out of the ring.
assert(M:SetHidden(129,true))
shown=Ids();assert(#shown==2 and M.ringSlots[2].profession.id==185,'hidden profession leaves the ring')
shown[2].button.scripts.OnClick(shown[2].button);assert(opened[2]==185)
assert(M:SetHidden(129,false) and #Ids()==3)
-- Combat: the click does nothing.
testCombat=true;shown=Ids();shown[1].button.scripts.OnClick(shown[1].button);assert(#opened==2,'no opening in combat');testCombat=false
-- Turning the module off removes every profession icon.
addon:SetModuleEnabled('foreverQuickAccess',false)
assert(#Ids()==0,'module off: profession icons gone')
''')
print('PASS Quick Actions professions: one ring icon per shown profession, opens it, follows hidden professions, combat-safe, leaves with the module (mock only)')
