"""v2 split of Gameplay Enhancements into Loot Sparkles and Campfire Monitor:
first-switch adoption, untouched saved keys, positions/styles and old search
terms (mock only; not native acceptance)."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

# A real saved profile with Campfire positions and a Style card style.
base, _ = load(before=FIXTURE + EXTRA)
base.execute(r'''
local PM=addon.PositionManager
addon:SetModuleEnabled('campfireMonitor',true)
assert(PM.elements.campfireMonitor and PM.elements.campfireMonitor.module==addon.modules.campfireMonitor,'element keeps its ID, owned by the new module')
assert(PM:SetOffsets('campfireMonitor',140,-60))
assert(addon:SetEditMode(true) and PM:SetStyle('campfireMonitor','scale',120));addon:SetEditMode(false)
assert(C:SetOption('width',400) and C:SetOption('contributionX',33) and C:SetOption('contributionY',44))
''')
saved = base.eval('addon.ProfileCodec.Encode(PTGToolsDB)')

LEGACY = r'''
local db=addon.ProfileCodec.Decode(savedProfile)
local m=db.profiles.Default.modules
m.campfireMonitor=nil
m.lootSparkles.splitMasterEnabled=nil
m.lootSparkles.enabled=oldMaster
m.lootSparkles.sparklesEnabled=oldSparkles
m.lootSparkles.campfire.enabled=oldCamp
PTGToolsDB=db
'''


def lua_value(value):
    return 'nil' if value is None else ('true' if value else 'false')


def legacy_setup(master, sparkles, camp):
    """Rewrites the saved profile into its pre-split shape before startup."""
    return (FIXTURE + EXTRA + '\nsavedProfile=[====[' + saved + ']====]\n'
            + 'oldMaster=' + lua_value(master) + ';oldSparkles=' + lua_value(sparkles)
            + ';oldCamp=' + lua_value(camp) + '\n' + LEGACY)


CASES = [
    (True, True, True, True, True),
    (True, False, True, False, True),
    (True, True, False, True, False),
    (True, None, None, True, False),  # untouched inner flags had these defaults
    (False, True, True, False, False),
]
for master, sparkles, camp, want_loot, want_camp in CASES:
    lua, _ = load(before=legacy_setup(master, sparkles, camp))
    lua.globals().wantLoot, lua.globals().wantCamp = want_loot, want_camp
    lua.execute(r'''
local m=addon.db.modules;local PM=addon.PositionManager
assert(addon.modules.lootSparkles.enabled==wantLoot and addon.modules.campfireMonitor.enabled==wantCamp,'old master AND old inner flag')
-- Nothing moved or erased: the old inner flags stay saved, unread.
assert(m.lootSparkles.sparklesEnabled==oldSparkles and m.lootSparkles.campfire.enabled==oldCamp,'old inner flags kept')
assert(m.lootSparkles.splitMasterEnabled==oldMaster and m.campfireMonitor.adoptedSplit==true)
assert(C.db==m.lootSparkles.campfire and C.db.width==400 and C.db.contributionX==33 and C.db.contributionY==44,'Campfire reads its settings in place')
-- Positions and Style card styles stay on the same element IDs.
assert(addon.db.positions.campfireMonitor.x==140 and addon.db.positions.campfireMonitor.style.scale==120)
if wantCamp then
 local e=PM.elements.campfireMonitor
 assert(e and e.position==addon.db.positions.campfireMonitor and e.module==addon.modules.campfireMonitor,'saved position applies')
 assert(PM:GetStyle('campfireMonitor').scale==120 and C.db.x==140,'saved style and offsets apply')
end
''')
    # Adopted once: the player's later choice is never overwritten.
    again, _ = load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'), before=FIXTURE + EXTRA)
    again.globals().wantCamp = want_camp
    again.execute(r'''
assert(addon.modules.campfireMonitor.enabled==wantCamp)
addon:SetModuleEnabled('campfireMonitor',not wantCamp)
''')
    third, _ = load(again.eval('addon.ProfileCodec.Encode(PTGToolsDB)'), before=FIXTURE + EXTRA)
    third.globals().wantCamp = want_camp
    third.execute("assert(addon.modules.campfireMonitor.enabled==(not wantCamp),'adopted once, then the switch is the player choice')")

fresh, _ = load(before=FIXTURE + EXTRA)
fresh.globals().savedProfile = saved
fresh.execute(r'''
-- An old exported profile records the old master during validation, on a copy.
local old=addon.ProfileCodec.Decode(savedProfile).profiles.Default
old.modules.campfireMonitor=nil;old.modules.lootSparkles.splitMasterEnabled=nil
old.modules.lootSparkles.enabled=true;old.modules.lootSparkles.sparklesEnabled=false;old.modules.lootSparkles.campfire.enabled=true
local candidate=assert(addon.ProfileValidation:Validate(old))
assert(candidate.modules.lootSparkles.enabled==false and candidate.modules.lootSparkles.splitMasterEnabled==true,'validation records the old master')
assert(candidate.modules.lootSparkles.campfire.enabled==true and candidate.modules.lootSparkles.sparklesEnabled==false)
assert(old.modules.lootSparkles.splitMasterEnabled==nil,'validation works on a detached copy')
-- Fresh installs: both off, no inner flags written.
local m=addon.db.modules
assert(not addon.modules.lootSparkles.enabled and not addon.modules.campfireMonitor.enabled)
assert(m.lootSparkles.sparklesEnabled==nil and m.lootSparkles.campfire.enabled==nil and m.lootSparkles.splitMasterEnabled==false)
-- Two sidebar entries, each with its own switch.
local listed={};for _,id in ipairs(addon:ListedConfigPages()) do listed[id]=true end
assert(listed.campfireMonitor and listed.lootSparkles,'two sidebar entries')
assert(addon.modules.campfireMonitor.title=='Campfire Monitor' and addon.modules.lootSparkles.title=='Loot Sparkles')
-- Old search terms still find the right page.
addon:ToggleConfig()
local function Top(query) local r=addon:SearchSettings(query)[1];return r and r.module.id end
local function Finds(query,id) for _,r in ipairs(addon:SearchSettings(query,40)) do if r.module.id==id and r.kind=='module' then return true end end end
assert(Top('campfire')=='campfireMonitor','campfire')
assert(Top('camp contributions')=='campfireMonitor','camp contributions')
assert(Finds('gameplay enhancements','campfireMonitor') and Finds('gameplay enhancements','lootSparkles'),'gameplay enhancements finds both pages')
assert(Top('loot sparkles')=='lootSparkles')
''')
print('PASS Gameplay Enhancements split: first switches = old master AND old inner flag, old keys kept unread, adopted once, settings read in place, element IDs/positions/styles kept, import validation and old search terms (mock only)')
