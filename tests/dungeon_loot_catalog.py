"""All-dungeon navigation/coverage; actual rendering remains a native check."""
from smoke import load

lua, _ = load()
lua.execute(r'''
    function UnitFactionGroup() return "Alliance" end
    local M,P,L=addon.DungeonLoot,addon.DungeonLootProvider,addon.DungeonLootLocations
    local source={DB={
        ['Fixture Burrow']={level='13-18',location='Fixture North',entrance={mapID=1454,x=.4,y=.5},
            bosses={{name='Burrow Boss',loot={{100010,'Burrow Loot','Head'}}}},
            quests={{id=100020,name='Burrow Task',pickup='Fixture Giver, North',turnin='Fixture Giver, North',objective='Collect a fixture'},
                {id=100021,name='Interior Task',pickup='Fixture Ghost, inside Fixture Burrow',turnin='Fixture Ghost, inside the dungeon'}}},
        ['Fixture Citadel']={level='27-35',location='Fixture South',entrance={mapID=1436,x=.6,y=.7},
            bosses={{name='Citadel Boss',loot={{100011,'Citadel Loot','Chest'}}},{name='Rare Citadel',rare=true,loot={}},{name='Other loot',trash=true,loot={}}},
            quests={{id=100022,name='Citadel Task',pickup='Unknown giver',turnin='Unknown finisher',faction='Alliance'}}},
        ['Fixture Preview']={level='58-60',previewOnly=true},
        ['Fixture Raid']={level='60-60',isRaid=true,bosses={}},
    },QUEST_START_MAPS={[100020]={mapID=1454,x=.12,y=.34,label='Fixture Giver',detail='Known stairway hint'}},
      DUNGEON_HOME_ART={['Fixture Burrow']='Interface\\Glues\\LoadingScreens\\Fixture',
        ['Fixture Citadel']='Interface\\AddOns\\ForeverDungeonJournal\\Media\\Fixture'},
      DUNGEON_HOME_TEXCOORD={['Fixture Citadel']={0,1,.06,.94}}}
    addon.DungeonLootCatalog.Read=function() return source end
    local original=addon.ProfileCodec.Encode(source)
    local queried={}
    LibQuestieDB={Quest={startedBy=function(id) queried[id]=true end}}
    local data=P:Read('Fixture Burrow')
    assert(#data.cards==3 and #data.catalog==3 and #data.quests==2 and data.bossCount==1)
    assert(not queried[100022],'only selected dungeon normalizes quests')
    assert(data.card.faction=='Horde' and data.cards[2].card.faction=='Alliance')
    assert(data.cards[2].card.crop[3]==.06)
    assert(#data.quests[1].turninTargets==1 and data.quests[1].turninTargets[1].x==.12,'recorded giver reused for exact-name return')
    assert(data.quests[1].turninTargets[1].detail=='Known stairway hint')
    assert(#data.quests[2].pickupTargets==1 and data.quests[2].pickupTargets[1].detail:find('Entrance marker only',1,true))
    data.quests[1].turninTargets[1].x=.9
    assert(source.QUEST_START_MAPS[100020].x==.12,'no coordinate aliases')
    assert(#P:Read('Fixture Citadel').quests[1].turninTargets==0,'unknown destinations remain unknown')
    local index=L:RecordedIndex({DB={},QUEST_START_MAPS={
        [1]={mapID=1454,x=.1,y=.2,targetName='Duplicate'},[2]={mapID=1436,x=.2,y=.3,targetName='Duplicate'}}})
    assert(not L:FindRecorded('Duplicate, somewhere',index),'ambiguous giver names do not pick a map')
    assert(not L:FindRecorded('Fixture',L:RecordedIndex(source)),'no substring match')
    assert(not L:Interior('Inside a different inn','Fixture Burrow',source.DB['Fixture Burrow'].entrance))
    LibQuestieDB=nil
    addon:SetModuleEnabled('dungeonLoot',true);addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    local page=M.page
    local function Plain(s) return (s or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','') end
    local function Find(pane,name)
        for _,slot in ipairs(pane.slots) do if slot.visible and Plain(slot.button.label:GetText())==name then return slot end end
        error('Missing '..name)
    end
    local preview=Find(page.rootPane,'Fixture Preview')
    assert(preview.callback==nil and not preview.button.mouse and preview.subtitle:GetText():find('Data not available yet',1,true))
    local burrow=Find(page.rootPane,'Fixture Burrow')
    burrow.button:GetScript('OnClick')(burrow.button)
    assert(M.view.dungeon=='Fixture Burrow' and M.data.name=='Fixture Burrow')
    assert(Plain(page.context:GetText()):find('Fixture Burrow',1,true) and page.context:IsShown())
    Find(page.detailPane,'Burrow Loot  (loading details)')
    M:Navigate(nil);page.search:SetText('Citadel')
    assert(Find(page.rootPane,'Fixture Citadel').visible)
    for _,slot in ipairs(page.rootPane.slots) do if slot.visible then assert(Plain(slot.button.label:GetText())~='Fixture Burrow') end end
    M:Navigate('Fixture Citadel','quests')
    assert(M.data.name=='Fixture Citadel' and #M.data.bosses==3 and M.view.quest==1)
    assert(M.data.bossCount==1 and M.data.rareCount==1)
    assert(Find(page.detailPane,'Citadel Task').visible)
    function UnitFactionGroup() return 'Horde' end;M:ReadData();page:Refresh()
    Find(page.detailPane,'No quests match your character or search.')
    function UnitFactionGroup() return 'Alliance' end;M:ReadData();page:Refresh()
    M:Navigate('Fixture Burrow','loot');assert(M.view.boss==1 and M.view.quest==nil)
    assert(M.data.bosses[1].name=='Burrow Boss','selection and data do not leak across dungeons')
    M:Navigate(nil);assert(not page.context:IsShown())
    assert(original==addon.ProfileCodec.Encode(source),'whole provider remains read-only')
    addon.DungeonLootCatalog.Read=function() return {} end;M:Navigate(nil)
    local sfk=Find(page.rootPane,'Shadowfang Keep')
    assert(sfk.subtitle:GetText():find('unavailable',1,true),'missing provider has an explicit state')
''')
print('PASS multi-dungeon selection, brackets, previews, lazy reads, recorded locations, ambiguity and provider isolation')

native,_=load()
native.execute(r'''
    local M,P,C=addon.DungeonLoot,addon.DungeonLootProvider,addon.DungeonLootCatalog
    -- Any accidental lookup of DungeonJournal fails immediately; none is loaded.
    ForeverDungeonJournal_NS=setmetatable({},{__index=function() error('external catalog access') end})
    LibQuestieDB=nil;QuestieLoader=nil
    local original={}
    for _,instance in ipairs(C.Data.Instances) do original[instance.key]=addon.ProfileCodec.Encode(instance) end
    addon:SetModuleEnabled('dungeonLoot',true);addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    local initial=P:Read()
    assert(#initial.cards==35)
    local active,preview,bosses,quests,pickups,returns,maxSlots=0,0,0,0,0,0,0
    for _,card in ipairs(initial.cards) do
        if card.previewOnly then preview=preview+1
        else
            active=active+1
            assert(card.available and card.card.art and not card.card.iconOnly,card.name)
            M:Navigate(card.name,'loot')
            assert(M.data.available and M.page.listPane:IsShown() and M.page.loot:IsEnabled())
            assert(M.data.name==card.name and #M.data.quests==card.questCount)
            for i=1,#M.data.bosses do M:SelectEntry('boss',i);bosses=bosses+1 end
            M:Navigate(card.name,'quests')
            for i,q in ipairs(M.data.quests) do
                M:SelectEntry('quest',i);M.view.showPrerequisites=true;M.page:Refresh();quests=quests+1
                if #q.pickupTargets>0 then pickups=pickups+1 end
                if #q.turninTargets>0 then returns=returns+1 end
                for _,slot in ipairs(M.page.detailPane.slots) do if slot.visible then assert(slot.mapKind~='objective') end end
            end
            maxSlots=math.max(maxSlots,#M.page.detailPane.slots)
            assert(#M.page.detailPane.slots<750,'pooled detail growth bounded')
        end
    end
    assert(active==31 and preview==4)
    for _,instance in ipairs(C.Data.Instances) do assert(original[instance.key]==addon.ProfileCodec.Encode(instance),instance.key..' source changed') end
    M:Navigate('Shadowfang Keep','quests')
    assert(#M.data.quests==7 and M.data.bossCount==8 and M.data.rareCount==1,'SFK pilot continuity')
    catalogAudit={active=active,preview=preview,bosses=bosses,quests=quests,pickups=pickups,returns=returns,maxSlots=maxSlots}
''')
audit=dict(native.globals().catalogAudit.items())
print('PASS bundled catalog with external addons absent (mock): '+', '.join(f'{k}={v}' for k,v in sorted(audit.items())))
