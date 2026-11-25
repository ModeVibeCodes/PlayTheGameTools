"""Professions open through Blizzard's action template, from the bar and from one
Quick Actions ring icon per profession. Mock only: the template is a bounded model,
not proof that the Forever client dispatches the /cast."""
from smoke import load

BEFORE = r'''
function GetProfessions() return 11,nil,12,nil,14 end
-- name, icon, rank, maxRank, numAbilities, spellOffset, skillLine
function GetProfessionInfo(index)
 if index==11 then return 'Alchemy',136240,120,150,1,20,171 end
 if index==12 then return 'First Aid',135966,300,300,1,30,129 end
 if index==14 then return 'Skinning',134366,75,150,1,40,393 end
end
Enum=Enum or {};Enum.SpellBookSpellBank={Player=0,Pet=1}
local book={[21]={name='Alchemy',spellID=2259,isPassive=false},[31]={name='First Aid',spellID=3273,isPassive=false},
 [41]={name='Skinning',spellID=8613,isPassive=true}}
C_SpellBook=C_SpellBook or {}
C_SpellBook.GetSpellBookItemInfo=function(slot,bank) assert(bank==0);return book[slot] end
casts={}
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=create(kind,name,parent,template)
 if template=='InsecureActionButtonTemplate' then
  f.attributes={}
  function f:SetAttribute(key,value) assert(not testCombat,'no combat attribute writes');self.attributes[key]=value end
  function f:GetAttribute(key) return self.attributes[key] end
  -- Bounded model of the template: a user up-click runs the macro; /stopmacro [combat] stops it.
  f:SetScript('OnClick',function(button,key,down)
   if down or button:GetAttribute('type1')~='macro' then return end
   local text=button:GetAttribute('macrotext1')
   if testCombat and text:find('/stopmacro [combat]',1,true) then return end
   casts[#casts+1]=text:match('/cast (.+)$')
  end)
 end
 return f
end
'''

lua, _ = load(before=BEFORE)
lua.execute(r'''
local Q,M,D=addon.QuickActions,addon.ForeverQuickAccess,addon.ForeverQuickAccessData
local function Click(b)
 b.scripts.OnClick(b,'LeftButton',false)
 if b.scripts.PostClick then b.scripts.PostClick(b,'LeftButton',false) end
end
local function Ring()
 local list={}
 for i=1,5 do local a=Q.actions['profession'..i];if a and a.available then list[#list+1]=a end end
 return list
end
-- The spell that opens a profession: the first non-passive spell in its range.
assert(D.ProfessionSpell(20,1)=='Alchemy' and select(2,D.ProfessionSpell(20,1))==2259)
assert(D.ProfessionSpell(40,1)==nil,'passive-only gathering skill has nothing to open')
assert(#Ring()==0,'no ring icons while the module is off')
addon:SetModuleEnabled('foreverQuickAccess',true)

-- Bar: action-template buttons carry a guarded /cast; no direct API call.
local bar=M.bar.buttons
assert(bar[1].nativeReady and bar[1]:GetAttribute('type1')=='macro')
assert(bar[1]:GetAttribute('macrotext1')=='/stopmacro [combat]\n/cast Alchemy','guarded /cast macro')
assert(bar[3].profession.name=='Skinning' and bar[3]:GetAttribute('type1')==nil,'nothing to cast for Skinning')
assert(bar[1]:GetAttribute('useOnKeyDown')==false,'acts on release')
Click(bar[2]);assert(casts[1]=='First Aid','bar opens First Aid')
-- Layout: the bar holds no action, and a click selects it.
addon:SetEditMode(true)
assert(bar[1]:GetAttribute('type1')==nil,'no action while editing')
Click(bar[1]);assert(#casts==1,'Layout click casts nothing')
addon:SetEditMode(false);assert(bar[1]:GetAttribute('type1')=='macro','armed again after Layout')

-- Ring: one secure icon per profession with a window, in order after the others.
local shown=Ring()
assert(#shown==2,'Alchemy and First Aid; Skinning has no window')
assert(shown[1].button:GetParent()==Q.ring and shown[1].button.icon.texture==136240)
assert(shown[1].order>30 and shown[2].order>shown[1].order,'after Class Training, Dungeon Loot and Guild')
assert(shown[1].button:GetAttribute('macrotext1')=='/stopmacro [combat]\n/cast Alchemy')
Q:SetExpanded(true);Click(shown[1].button)
assert(casts[2]=='Alchemy' and not Q.ring:IsShown(),'ring click casts and closes the ring')
-- A hidden profession leaves the ring and the bar.
assert(M:SetHidden(171,true))
shown=Ring();assert(#shown==1 and shown[1].button:GetAttribute('macrotext1'):find('First Aid',1,true),'hidden profession leaves the ring')
assert(M:SetHidden(171,false) and #Ring()==2)
-- Combat: the macro guard stops the cast.
testCombat=true;Click(Ring()[1].button);assert(#casts==2,'no cast in combat');testCombat=false
-- Turning the module off removes every profession icon.
addon:SetModuleEnabled('foreverQuickAccess',false)
assert(#Ring()==0,'module off: profession icons gone')
for _,m in ipairs(messages) do assert(not m:find('Blocked',1,true)) end
''')
print('PASS Profession opening: spellbook spell lookup, action-template /cast macro on the bar and one ring icon per profession, Layout inert, hidden/combat/off (mock only)')
