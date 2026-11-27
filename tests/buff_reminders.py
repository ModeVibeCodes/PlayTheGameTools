"""Buff Reminders: class filtering, read-and-count timing, combat estimates,
deaths, resources, totems, text mode, group watcher, secure click layer,
Layout Style card groups, Rogue handover and profile validation.
Mock only: native aura secrecy, secure casting and rendering need in-game checks."""
from rogue_poisons import SETUP
from smoke import load

BR = r'''
testClass='MAGE';testAurasSecret=false;testNoMana=false;testPet=false;testGroup=false
known={};auras={player={}};members={};dead={};totems={};counts={}
spellNames={[1459]='Arcane Intellect',[1460]='Arcane Intellect',[168]='Frost Armor',[8512]='Windfury Totem',
 [10613]='Windfury Totem',[5675]='Mana Spring Totem',[8017]='Rockbiter Weapon',[324]='Lightning Shield',
 [19740]='Blessing of Might',[19742]='Blessing of Wisdom',[20217]='Blessing of Kings',[693]='Create Soulstone',
 [19705]='Well Fed',[433]='Food',[467]='Thorns'}
function UnitClass(unit)
 if unit=='player' then return testClass,testClass,1 end
 local m=members[unit];if m then return m.class,m.class,1 end
end
function UnitName(unit) if unit=='player' then return 'Fixture' end;local m=members[unit];return m and m.name end
function UnitExists(unit) if unit=='player' then return true end;if unit=='pet' then return testPet end;return members[unit]~=nil end
function UnitIsUnit(a,b) return a==b end
function UnitIsDeadOrGhost(unit) return dead[unit]==true end
function IsInGroup() return testGroup end
function IsInRaid() return false end
function GetNumSubgroupMembers() local n=0;for i=1,4 do if members['party'..i] then n=i end end;return n end
function GetNumGroupMembers() return testGroup and GetNumSubgroupMembers()+1 or 0 end
function IsInInstance() return false,'none' end
function IsResting() return false end
function IsMounted() return false end
function UnitOnTaxi() return false end
C_Secrets={ShouldAurasBeSecret=function() return testAurasSecret end,ShouldTotemSlotBeSecret=function() return false end}
C_UnitAuras={GetAuraDataByIndex=function(unit,i,filter)
 assert(filter=='HELPFUL')
 local a=(auras[unit] or {})[i]
 if a and testAurasSecret then return {secret=true} end
 return a
end}
C_Spell=C_Spell or {}
local spellInfo=C_Spell.GetSpellInfo
C_Spell.GetSpellName=function(id) return spellNames[id] or (spells and spells[id] and spells[id].name) end
C_Spell.GetSpellTexture=function(id) return 5000+id end
C_Spell.IsSpellUsable=function(id) if testNoMana then return false,true end;return true,false end
C_SpellBook=C_SpellBook or {}
local isKnown=C_SpellBook.IsSpellKnown
C_SpellBook.IsSpellKnown=function(id) return known[id]==true or (isKnown and isKnown(id)) or false end
C_Item=C_Item or {}
C_Item.GetItemCount=function(id)
 if counts[id] then return counts[id] end
 local n=0
 for _,bag in pairs(bags or {}) do for _,p in ipairs(bag) do if p.itemID==id then n=n+p.stackCount end end end
 return n
end
C_Item.GetItemIconByID=function(id) return 7000+id end
function GetTotemInfo(slot) local t=totems[slot];if not t then return false,'',0,0,nil,1,nil end;return true,t.name,t.start,t.duration,t.icon,1,t.spell end
function Aura(unit,id,left,extra)
 auras[unit]=auras[unit] or {}
 local a={spellId=id,name=spellNames[id],expirationTime=left and testClock+left or 0,duration=left and 3600 or 0,applications=0,sourceUnit='player'}
 for k,v in pairs(extra or {}) do a[k]=v end
 table.insert(auras[unit],a);return a
end
function Keys(list) local out={};for _,e in ipairs(list) do out[e.key]=e end;return out end
function Button(key) for _,b in ipairs(addon.BuffReminders.securePool.main) do if b:IsShown() and b.dismissKey==key then return b end end end
function NoFood() addon.db.modules.buffReminders.buffs.food=false end
function Combat(on) testCombat=on;testLockdown=on;testAurasSecret=on;FireEvent(on and 'PLAYER_REGEN_DISABLED' or 'PLAYER_REGEN_ENABLED') end
local create=CreateFrame
secureButtons={}
function CreateFrame(kind,name,parent,template)
 local f=create(kind,name,parent,template)
 if template=='SecureActionButtonTemplate' then
  f.attributes={};f.protected=true;secureButtons[#secureButtons+1]=f
  function f:SetAttribute(k,v) assert(not testLockdown,'secure attribute changed in combat');self.attributes[k]=v end
  function f:GetAttribute(k) return self.attributes[k] end
  for _,method in ipairs({'Show','Hide','SetPoint','ClearAllPoints','SetSize'}) do
   local original=f[method]
   f[method]=function(self,...) assert(not testLockdown,'secure '..method..' in combat');return original(self,...) end
  end
 end
 return f
end
'''

# Mage: class filtering, timing, combat estimates, resources, dismissal, display modes, secure layer.
lua, _ = load(before=SETUP + BR)
lua.execute(r'''
local B,D,PM=addon.BuffReminders,addon.BuffRemindersData,addon.PositionManager
assert(addon.modules.buffReminders==B and B.title=='Buff Reminders' and B.defaultEnabled==false,'Buff Reminders, off by default')
assert(not B.db.enabled and not B.active,'starts off')
known[1459]=true;known[1460]=true;known[168]=true
Aura('player',168,1800)
NoFood()
addon:SetModuleEnabled('buffReminders',true)
assert(B.active and B.class=='MAGE')
local shown=Keys(B.shown)
assert(shown.arcaneIntellect and shown.arcaneIntellect.status=='missing','missing Arcane Intellect shown')
assert(not shown.armor,'30 min of armor left is not due')
assert(not shown.battleShout and not shown.blessing and not shown.poisonMain,'other classes never appear')
assert(B.frame:IsShown() and B.frame.icons[1]:IsShown() and B.frame.icons[1].timer:GetText()=='Missing')
-- Click layer: highest known rank, on yourself; laid out of combat over the icon.
local s=Button('arcaneIntellect')
assert(B.secureAvailable and s and s:IsShown() and s:GetAttribute('type1')=='spell' and s:GetAttribute('spell1')==1460 and s:GetAttribute('unit1')=='player','left-click casts the highest rank')
assert(s.dismissKey=='arcaneIntellect' and not B.frame.icons[1].mouse,'the click button covers the icon')

-- Read: three minutes left is inside the automatic warning (25% of 60 min, up to 5 min).
auras.player={};Aura('player',168,1800);Aura('player',1460,180)
FireEvent('UNIT_AURA','player')
shown=Keys(B.shown)
assert(shown.arcaneIntellect.status=='expiring' and B.frame.icons[1].timer:GetText()=='3m','expiring with time left')

-- Combat: auras turn secret; the stored end time keeps counting, marked as an estimate.
Combat(true)
assert(B.frozen and B.frozen[1]=='arcaneIntellect','click slots frozen at combat start')
Advance(60)
shown=Keys(B.shown)
assert(shown.arcaneIntellect.estimated and B.frame.icons[1].timer:GetText()=='~2m','counted from the last read')
Advance(125)
shown=Keys(B.shown)
assert(shown.arcaneIntellect.status=='missing','an estimate that runs out reads as missing')
-- Your own cast is visible in combat and restarts the timer; the slot stays put, faded.
FireEvent('UNIT_SPELLCAST_SUCCEEDED','player','cast',1460)
assert(not Keys(B.shown).arcaneIntellect,'reapplied in combat')
assert(B.slots[1].entry.frozen and B.slots[1].keys=='arcaneIntellect','the frozen slot keeps its place under its click button')
auras.player={};Aura('player',168,1800);Aura('player',1460,3600)
Combat(false)
assert(not B.frozen and not Keys(B.shown).arcaneIntellect,'combat end reads again')
assert(not s:IsShown(),'nothing to click once the buff is fine')

-- Resources: out of mana always dims (never hides); dismissal lasts until a loading screen.
auras.player={};Aura('player',168,1800)
testNoMana=true;B:SetOption('cant','hide')
shown=Keys(B.shown)
assert(shown.arcaneIntellect and shown.arcaneIntellect.resource=='mana','mana shortage dims, never hides')
assert(B.frame.icons[1].icon.desaturated==true and B.frame.icons[1].alpha==0.6)
testNoMana=false;B:SetOption('cant','dim')
assert(B:Dismiss('arcaneIntellect') and not Keys(B.shown).arcaneIntellect,'right-click dismisses')
FireEvent('PLAYER_ENTERING_WORLD')
assert(Keys(B.shown).arcaneIntellect,'back after a loading screen')

-- Display modes: text reads like the game; most urgent shows one.
assert(B:SetOption('mode','text'))
assert(B.frame.rows[1]:IsShown() and B.frame.rows[1].label:GetText()=='Arcane Intellect Missing','text mode')
assert(B:SetOption('mode','single') and B.frame.label:GetText()=='Arcane Intellect Missing','most urgent only')
assert(B:SetOption('mode','icons'))
assert(not B:SetOption('mode','huge') and not B:SetOption('look',{}) and not B:SetGroupOption('look','iconSize',500),'validated')
assert(B:SetOption('when','always') and Keys(B.shown).armor,'Always shows buffs that are fine too')
assert(B:SetOption('when','needed'))

-- Layout: two displays, samples while placing, and this display's own Style card groups.
assert(addon:SetEditMode(true))
assert(PM.elements.buffReminders and PM.elements.buffReminders.editMode,'reminders placed in Layout')
assert(PM.elements.buffRemindersGroup and PM.elements.buffRemindersGroup.editMode,'Mage provides a group buff: watcher placed too')
assert(B.slots[1].entry.sample and not s:IsShown(),'samples while placing; no click buttons')
local card=addon.editWindow.styleCard
assert(PM:SelectElement('buffReminders') and card:IsShown())
local groups=card.extras.buffReminders
assert(groups and groups[1].title=='Display' and #groups[1].rows==6 and groups[1].toggle:IsShown(),'Display group on the card')
assert(card.sliders.scale.label:GetText()=='Scale','shared rows still first')
local spec=PM.elements.buffReminders.styleGroups[1].rows
spec[1].set('down');spec[2].set(52)
assert(B.db.look.grow=='down' and B.db.look.iconSize==52 and B.frame.icons[1].width==52,'card changes the look')
assert(PM:ResetLayout('buffReminders') and B.db.look.grow=='right' and B.db.look.iconSize==40,'Reset restores the look')
assert(PM:SelectElement('buffRemindersGroup') and card.extras.buffRemindersGroup[1].title=='Group watcher')
assert(not groups[1].toggle:IsShown(),'other display groups hidden')
addon:SetEditMode(false)
assert(not B:SetGroupOption('look','grow','up') or true)

-- Settings page: one scroll, no styling rows; search finds it.
addon:ToggleConfig();addon:SelectConfigPage('buffReminders')
local page=addon:EnsureConfigPage('buffReminders')
local titles={}
for _,section in ipairs(page.sections) do titles[#titles+1]=section.title end
assert(table.concat(titles,'|')=='Reminder|Mage Buffs|Group|General|Where to Show|Look','page sections: '..table.concat(titles,'|'))
assert(page.buffControls['When'] and page.buffControls['Armor to cast'] and page.buffControls['Watcher shows'])
local found=false
for _,r in ipairs(addon:SearchSettings('well fed')) do found=found or r.label:find('Buff Reminders',1,true)~=nil end
assert(found,'search finds Buff Reminders')

-- Profile: round trip and strict validation.
local V=addon.ProfileValidation
local encoded=addon.ProfileCodec.Encode(PTGToolsDB)
assert(addon.ProfileCodec.Decode(encoded),'round trip')
local bad=addon.ProfileCodec.Copy(addon.db);bad.modules.buffReminders.look.iconSize=500
assert(V:Validate(bad)==nil,'bad look refused')
bad=addon.ProfileCodec.Copy(addon.db);bad.modules.buffReminders.totems.air='notATotem'
assert(V:Validate(bad)==nil,'bad totem refused')
assert(V:Validate(addon.db),'current profile valid')
addon:SetModuleEnabled('buffReminders',false)
assert(not B.frame:IsShown() and not PM.elements.buffReminders.editMode,'off hides everything')
''')

# Shaman: totem picks, combined "Totems Missing", weapon imbue, charges.
lua, _ = load(before=SETUP + BR + "testClass='SHAMAN'")
lua.execute(r'''
local B=addon.BuffReminders
for _,id in ipairs({8512,10613,5675,8017,324}) do known[id]=true end
enchants[0]={{hasEnchant=true,enchantType=3,timeLeft=3000*1000,enchantIconID=401,enchantID=900}}
weaponIDs[17]=nil
Aura('player',324,500,{applications=3})
NoFood()
addon:SetModuleEnabled('buffReminders',true)
assert(not Keys(B.shown).shield,'three charges: fine')
auras.player[1].applications=1;FireEvent('UNIT_AURA','player')
local shown=Keys(B.shown)
assert(shown['totem:air'] and shown['totem:air'].status=='missing','Windfury Totem reminds when not placed')
assert(not shown.imbueMain and not shown.imbueOff,'imbue fine; no off-hand weapon, no off-hand reminder')
assert(shown.shield and shown.shield.status=='expiring' and shown.shield.charges==1,'one charge left warns')
assert(Button('totem:air'):GetAttribute('spell1')==10613,'totem icon casts the highest rank')
totems[4]={name='Windfury Totem',start=testClock,duration=300,spell=10613}
FireEvent('PLAYER_TOTEM_UPDATE',4)
assert(not Keys(B.shown)['totem:air'],'placed')
totems[4]=nil
assert(B:SetGroupOption('totems','water','manaSpring') and B:SetOption('totemMode','one'))
shown=B.shown
local combined
for _,e in ipairs(B:GroupTotems(shown)) do if e.key=='totems' then combined=e end end
assert(combined and combined.combinedDetail=='(Mana Spring, Windfury)','one Totems Missing reminder')
local macro=Button('totem:water,totem:air'):GetAttribute('macrotext1')
assert(macro=='/castsequence reset=15 Mana Spring Totem, Windfury Totem','drops the missing totems in turn: '..tostring(macro))
-- Totem changes stay readable in combat.
Combat(true)
totems[4]={name='Windfury Totem',start=testClock,duration=300,spell=10613}
FireEvent('PLAYER_TOTEM_UPDATE',4)
assert(not Keys(B.shown)['totem:air'],'placed in combat')
Combat(false)
''')

# Paladin: group watcher with names, deaths, member rebuff by click.
lua, _ = load(before=SETUP + BR + "testClass='PALADIN'")
lua.execute(r'''
local B=addon.BuffReminders
for _,id in ipairs({19740,19742,20217,465}) do known[id]=true end
testGroup=true
members.party1={name='Tankard',class='WARRIOR'};members.party2={name='Mendra',class='PRIEST'}
Aura('player',465);Aura('player',19740,3000)
Aura('party1',19740,1500)
NoFood()
addon:SetModuleEnabled('buffReminders',true)
local rows=B:GroupEntries()
assert(#rows==1 and rows[1].buff.key=='blessing' and #rows[1].members==2)
local m1,m2=rows[1].members[1],rows[1].members[2]
assert(m1.name=='Tankard' and m1.status=='ok' and m1.family=='might','your Might on the warrior')
assert(m2.status=='missing' and m2.family=='wisdom','priest gets Wisdom by default')
assert(B.groupFrame:IsShown())
local tile=B.groupFrame.tiles[2]
assert(tile.name:GetText()=='Mendr' and tile.name:IsShown(),'name inside the icon, 5 letters')
local c=addon.GlobalSettings:GetClassColor('PRIEST')
assert(tile.name.color[1]==c.r,'class colour')
local g=B.securePool.group[2]
assert(g:GetAttribute('unit1')=='party2' and g:GetAttribute('spell1')==19742,'click blesses that player')
-- In combat a death clears that player's buffs.
Combat(true)
dead.party1=true;Advance(1)
rows=B:GroupEntries()
assert(rows[1].members[1].status=='dead','death seen in combat')
dead.party1=nil
Combat(false)
assert(B:SetGroupOption('watchLook','namePosition','top') and B:SetGroupOption('watchLook','nameColor','white'))
assert(B.groupFrame.tiles[2].name.color[1]==1,'white names')
assert(B:SetOption('watchMode','list') and B.groupFrame.rows[1]:IsShown(),'list view')
''')

# Warlock: Soulstone only in a group, needs a stone or a shard, target-or-self click.
lua, _ = load(before=SETUP + BR + "testClass='WARLOCK'")
lua.execute(r'''
local B=addon.BuffReminders
known[693]=true;known[706]=true;known[688]=true
counts[6265]=1;testPet=true
Aura('player',706,1500)
NoFood()
addon:SetModuleEnabled('buffReminders',true)
assert(not Keys(B.shown).soulstone,'solo: no Soulstone reminder')
testGroup=true;members.party1={name='Mendra',class='PRIEST'};B:RefreshRoster();B:Update(true)
local e=Keys(B.shown).soulstone
assert(e and e.status=='missing' and B:EntryName(e)=='Create Soulstone','shard only: create one')
counts[16893]=1;B:Update(true)
local action=B:ActionFor(Keys(B.shown).soulstone)
assert(action.type=='macro' and action.text=='/use [@target,help,nodead][@player] item:16893','your target, or you')
counts[16893]=0;counts[6265]=0;B:SetOption('cant','hide')
assert(not Keys(B.shown).soulstone,'no stone or shard: hidden when set to hide')
B:SetOption('cant','dim');counts[6265]=1
Aura('party1',20707,1700)
B:Update(true)
assert(not Keys(B.shown).soulstone and B.states.soulstone.who=='Mendra','your stone on Mendra')
''')

# Rogue: one-time adoption of Poison Reminder settings, handover, text mode, item click.
lua, _ = load(before=SETUP)
lua.execute("addon.db.modules.foreverRogue.threshold=7;addon.db.modules.foreverRogue.chargeThreshold=12;addon.db.modules.buffReminders={enabled=false}")
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
lua, _ = load(state, before=SETUP + BR + "testClass='ROGUE'")
lua.execute(r'''
local B,R=addon.BuffReminders,addon.ForeverRogue
assert(B.db.poisonWarn==7 and B.db.poisonCharges==12 and B.db.rogueAdopted,'Poison Reminder settings adopted once')
assert(addon.db.modules.foreverRogue.threshold==7,'Rogue settings untouched')
NoFood()
addon:SetModuleEnabled('foreverRogue',true)
assert(not R:HandedOver(),'Rogue Tools keeps its reminder while Buff Reminders is off')
addon:SetModuleEnabled('buffReminders',true)
assert(R:HandedOver() and not R.watcher:IsShown(),'Buff Reminders takes over the poison reminder')
local shown=Keys(B.shown)
assert(shown.poisonMain.status=='missing' and shown.poisonOff.status=='missing')
local s=Button('poisonMain')
assert(s:GetAttribute('type1')=='item' and s:GetAttribute('item1')=='item:6949' and s:GetAttribute('target-slot1')==16,'best carried Instant Poison on the main hand')
assert(B:SetOption('mode','text') and B.frame.rows[1].label:GetText()=='Poison Missing (MH/OH)','one line for both hands')
Poison(0,300,301,700)
FireEvent('WEAPON_ENCHANT_CHANGED')
assert(Keys(B.shown).poisonMain.status=='expiring' and B.frame.rows[2].label:GetText()=='Poison (MH)','7 min warning adopted')
assert(B:SetBuff('poisonMain',false) and B:SetBuff('poisonOff',false) and not R:HandedOver(),'turning poisons off hands back')
addon:ToggleConfig()
local page=addon:EnsureConfigPage('foreverRogue');page:Refresh()
assert(not page.handoverNote:GetParent().row.visibleWhen(),'no handover note once handed back')
''')
# Review regressions: bounded Layout registration, held geometry in combat, charges only
# for stacked auras, fixed warning fallback, mouse on unclickable reminders, sound not
# replayed, OOC settings hide the click layer in combat, retry after restricted reads,
# exact cast targets, frozen watcher places.
lua, _ = load(before=SETUP + BR + "testClass='PRIEST'")
lua.execute(r"""
local B,PM=addon.BuffReminders,addon.PositionManager
for _,id in ipairs({1243,588}) do known[id]=true end
sounds=0;SOUNDKIT={RAID_WARNING=8959};function PlaySound() sounds=sounds+1 end
drivers={};function RegisterStateDriver(frame,state,values) drivers[frame]=values end
function UnregisterStateDriver(frame,state) drivers[frame]=nil end
NoFood()
-- A display that can't register yet (layout pending) never loops.
local register=PM.RegisterModuleDisplay;local calls=0
PM.RegisterModuleDisplay=function(...) calls=calls+1;return false,'layout-pending' end
addon:SetModuleEnabled('buffReminders',true)
B:SetOption('show',true);B:SetOption('mode','icons');B:Update();B:Update();B:Update()
assert(calls<=8,'bounded registration attempts: '..calls)
PM.RegisterModuleDisplay=register;B.registerTries=0;B:Update()
assert(PM.elements.buffReminders,'registers once possible')
-- Inner Fire without stacks: no charge badge, not expiring; Fortitude shows no 0 badge.
Aura('player',588,580,{applications=0});Aura('player',1243,3000,{applications=0})
FireEvent('UNIT_AURA','player')
assert(not Keys(B.shown).innerFire and B.states.innerFire.charges==nil,'unstacked aura has no charges')
B:SetOption('when','always')
for _,icon in ipairs(B.frame.icons) do if icon:IsShown() then assert(icon.count:GetText()=='','no 0 badge') end end
B:SetOption('when','needed')
-- A fixed 15 min warning never makes a 10 min buff due from the start.
assert(B:SetOption('warnMinutes',15))
auras.player={};Aura('player',588,600,{duration=600});Aura('player',1243,600);FireEvent('UNIT_AURA','player')
assert(not Keys(B.shown).innerFire,'short buff falls back to automatic timing')
assert(Keys(B.shown).fortitude and Keys(B.shown).fortitude.status=='expiring','60 min buff warns at 15 min')
assert(B:SetOption('warnMinutes',0))
-- Sound: once for a new reminder, not again after a dismount.
assert(B:SetGroupOption('look','sound',true))
auras.player={};Aura('player',588,600);FireEvent('UNIT_AURA','player')
assert(sounds==1,'one sound for the new Fortitude reminder: '..sounds)
function IsMounted() return true end;B:Update()
function IsMounted() return false end;B:Update()
assert(sounds==1,'no replay after dismount')
-- Unclickable reminder (nothing to apply with) keeps its mouse for tooltip and dismiss.
B.db.buffs.food=true;B:Update(true)
local foodSlot;for _,s in ipairs(B.slots) do if s.entry.key=='food' then foodSlot=s end end
assert(foodSlot and not foodSlot.covered and foodSlot.region.mouse==true,'no button over food: icon takes the mouse')
B.db.buffs.food=false;B:Update(true)
-- Combat: frame size held while a late reminder appears in text mode.
assert(B:SetOption('mode','text'))
Combat(true)
local w,h=B.frame.width,B.frame.height
auras.player={};Advance(1);B:Update()
assert(B.frame.width==w and B.frame.height==h,'frame size held in combat')
Combat(false)
-- Restricted reads after combat retry on the next tick.
auras.player={};Aura('player',588,600);Aura('player',1243,3000)
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
testCombat=false;testLockdown=false;testAurasSecret=true;FireEvent('PLAYER_REGEN_ENABLED')
assert(B.retryRead,'still restricted: retry pending')
testAurasSecret=false;Advance(1)
assert(not B.retryRead and not Keys(B.shown).fortitude,'read once restrictions lift')
-- When Needed (OOC): the click layer is hidden in combat by a secure state driver.
assert(B:SetOption('mode','icons') and B:SetOption('when','neededOOC'))
assert(drivers[B.secureLayer]=='[combat] hide; show','OOC setting registers the visibility driver')
auras.player={};FireEvent('UNIT_AURA','player')
Combat(true)
assert(not B.frame:IsShown() and B.frozen==nil,'hidden in combat, no placeholders')
Combat(false)
assert(B:SetOption('when','needed') and drivers[B.secureLayer]==nil,'driver removed for In-combat settings')
-- A cast's target only applies to that cast (castGUID).
testGroup=true;members.party1={name='Mendra',class='MAGE'};B:RefreshRoster();B:Update(true)
Combat(true)
FireEvent('UNIT_SPELLCAST_SENT','player','Mendra','guid-1',1243)
FireEvent('UNIT_SPELLCAST_SUCCEEDED','player','guid-2',1243)
assert(B.states.fortitude.present and not B.members.Mendra.buffs.fortitude.present,'unmatched cast: yours, not for Mendra')
FireEvent('UNIT_SPELLCAST_SENT','player','Mendra','guid-3',1243)
FireEvent('UNIT_SPELLCAST_SUCCEEDED','player','guid-3',1243)
assert(B.members.Mendra.buffs.fortitude.present and B.members.Mendra.buffs.fortitude.estimated,'matched cast restarts the timer for Mendra')
local gw,gh=B.groupFrame.width,B.groupFrame.height
dead.party1=true;Advance(1)
assert(B.groupFrame.width==gw and B.groupFrame.height==gh,'watcher size held in combat')
dead.party1=nil
Combat(false)
""")
print('PASS Buff Reminders: classes, read-and-count timing, combat estimates/frozen slots, own casts, deaths, resources, dismissal, icons/text/single, totems and Totems Missing, imbues/charges, group watcher with names and clicks, Soulstone target-or-self, secure layer never touched in combat, Layout card groups and Reset, page, search, validation, Rogue adoption and handover')
