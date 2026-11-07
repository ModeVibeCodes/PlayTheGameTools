"""Standalone data, native coordinate conversion and redistribution contract."""
from smoke import load
from build_release import payload

lua,_=load()
lua.execute(r'''
    local C,L,P=addon.DungeonLootCatalog,addon.DungeonLootLocations,addon.DungeonLootProvider
    ForeverDungeonJournal_NS=nil;Lootified=nil;AtlasLoot=nil;LibQuestieDB=nil;QuestieLoader=nil
    local direct=0
    function CreateVector2D(x,y) return {x=x,y=y} end
    Enum=Enum or {};Enum.UIMapType={Zone=3}
    C_Map={
        GetMapPosFromWorldPos=function(continent,world,override)
            direct=direct+1
            assert(continent==0 and world.x==522.4 and world.y==1626.2,'catalog world axes reach native API unchanged')
            assert(override==1415 or override==1421)
            return override,override==1415 and {x=.2,y=.3} or {x=.43,y=.41}
        end,
        GetMapInfoAtPosition=function(map,x,y)
            return {mapID=1421,mapType=3}
        end,
    }
    local first=L:WorldPoint({0,522.4,1626.2},'First label')
    assert(first and first.mapID==1421 and first.x==.43 and first.y==.41)
    local count=direct;first.x=.9
    local second=L:WorldPoint({0,522.4,1626.2},'Another label')
    assert(second.x==.43 and second.label=='Another label' and direct==count,'cached geometry returns fresh, correctly labeled points')
    C_Map.GetMapPosFromWorldPos=function() return 1415,{x={secret=true},y=.3} end
    assert(not L:WorldPoint({0,1,2},'Secret rejected'))
    C_Map.GetMapPosFromWorldPos=function() return 1415,{x=1.5,y=.3} end
    assert(not L:WorldPoint({0,3,4},'Invalid rejected'))
    C_Map=nil
    assert(not L:WorldPoint({0,7,8},'Missing API rejected'))
    local info=P:Read('Shadowfang Keep')
    assert(info.available and #info.quests==7 and info.source:find('Bundled',1,true))
    local found={};for _,q in ipairs(info.quests) do found[q.id]=q end
    assert(found[78307].classOnly=='ROGUE' and #found[78307].chain>0)
    assert(found[95140].items[1].id==267369 and #found[95140].pickupTargets>0)
    assert(found[1806].items[1].id==6953 and #found[1806].chain>0)
    local complete=P:Read('The Drowned City')
    assert(complete.available and complete.lootIncomplete and #complete.quests==0,'newest snapshot gaps stay explicit')
    local saved=addon.DungeonLootCatalog
    addon.DungeonLootCatalog=nil
    local missing=P:Read('Shadowfang Keep')
    assert(not missing.available and missing.source:find('Restart WoW',1,true))
    addon.DungeonLootCatalog=saved
    C.Data.Quests[999999]={name='Reward fixture',choice={6953},reward={277210},pre={}}
    local reward=C:Quest(999999,{name='Shadowfang Keep'})
    assert(reward.rewardChoice and reward.rewardItems[1][1]==6953 and reward.fixedRewardItems[1][1]==277210)
    C.Data.Quests[999999]=nil
    local raw=C.Data.Quests[1098]
    info.quests[1].name='Modified UI copy'
    assert(raw.name=='Deathstalkers in Shadowfang')
    local old=GetFileIDFromPath
    GetFileIDFromPath=function() return 0 end
    C.artCache={}
    local fallback=P:Read('Ragefire Chasm')
    assert(fallback.card.iconOnly,'missing native artwork uses a native icon, not an external asset')
    GetFileIDFromPath=old;C.artCache={}
''')
files,order,toc=payload()
assert 'ForeverDungeonJournal' not in toc
assert 'LICENSES/GPL-3.0.txt' in files and b'GNU GENERAL PUBLIC LICENSE' in files['LICENSES/GPL-3.0.txt']
assert 'CATALOG_SOURCES.md' in files
for name in ('Items','Instances','Quests'):
    data=files[f'Modules/DungeonLootCatalog{name}.lua']
    assert b'SPDX-License-Identifier: GPL-3.0-only' in data and b'Modified 2026-11-07' in data
for name in order:
    if 'DungeonLoot' in name:
        data=files[name]
        assert b'Interface\\\\AddOns\\\\ForeverDungeonJournal' not in data
        assert b'Interface\\\\AddOns\\\\Lootified' not in data
        assert b'_G.ForeverDungeonJournal_NS' not in data
print('PASS standalone baseline, native world-coordinate guards/cache, SFK continuity, honest gaps, native art fallback and bundled GPL notices')
