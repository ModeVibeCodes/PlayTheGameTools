"""Startup regression for the reported legacy fractional contribution offsets."""
from campfire_monitor import FIXTURE
from smoke import load

lua,_=load(before=FIXTURE)
lua.execute(r'''
local root=PTGToolsDB
local camp=root.profiles.Default.modules.lootSparkles.campfire
camp.contributionX=422.5;camp.contributionY=200.8331298828125
camp.width=400;camp.iconSize=40;camp.headerGradient=true
root.profiles.Default.modules.lootSparkles.sparklesEnabled=false
root.profileRecovery={reason='prior invalid contributionX',backup={marker='retain recovery snapshot'}}
root.migrationBackup={marker='retain migration snapshot'}
''')
encoded=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(encoded,before=FIXTURE)
restored.execute(r'''
local root=PTGToolsDB;local camp=addon.db.modules.lootSparkles.campfire
assert(addon.initialized and addon.ProfileManager.activeName=='Default')
assert(camp.contributionX==423 and camp.contributionY==201,'repair exact owner-reported saved offsets at startup')
assert(camp.width==400 and camp.iconSize==40 and camp.headerGradient)
assert(not addon.db.modules.lootSparkles.sparklesEnabled,'unrelated feature setting retained')
assert(root.profileRecovery.backup.marker=='retain recovery snapshot')
assert(root.migrationBackup.marker=='retain migration snapshot')
assert(root.profiles.Default.modules.lootSparkles.campfire==camp)
''')
again,_=load(restored.eval('addon.ProfileCodec.Encode(PTGToolsDB)'),before=FIXTURE)
again.execute('assert(addon.initialized and C.db.contributionX==423 and C.db.contributionY==201)')
print('PASS full profile startup with reported 422.5/200.8331298828125 offsets, retained settings/recovery snapshots and second reload (mock only)')
