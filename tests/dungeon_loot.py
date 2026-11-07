"""SFK browser callbacks, visual navigation, provider isolation and item lifecycle.

Optional --reference-directory loads installed data only into an isolated mock.
No reference-addon records or artwork are stored in this test or its artifacts.
"""
import argparse
from pathlib import Path
from smoke import load

lua, _ = load()
lua.execute('''
    local M=addon.DungeonLoot
    assert(not M.enabled and M.category=='questingLeveling')
    addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    local page=M.page
    local function Texts()
        local text={}
        for _,slot in ipairs(page.slots) do if slot.visible then
            if slot.button:IsShown() then
                text[#text+1]=slot.button.label:GetText()
                if slot.subtitle:IsShown() then text[#text+1]=slot.subtitle:GetText() end
            end
            for _,cell in ipairs(slot.cells) do if cell:IsShown() then text[#text+1]=cell.label:GetText() end end
        end end
        return table.concat(text,'\\n')
    end
    function Find(text)
        for _,slot in ipairs(page.slots) do
            if slot.visible and slot.button:IsShown() and slot.button.label:GetText():find(text,1,true) then return slot.button,slot end
        end
        error('Missing visible control: '..text..' in '..Texts())
    end
    function Click(text)
        for _,slot in ipairs(page.slots) do if slot.visible then
            if slot.button:IsShown() and slot.callback and slot.button.label:GetText():find(text,1,true) then
                slot.button:GetScript('OnClick')(slot.button);return
            end
            for _,cell in ipairs(slot.cells) do if cell:IsShown() and cell.label:GetText():find(text,1,true) then cell:GetScript('OnClick')(cell);return end end
        end end
        error('Missing clickable control: '..text..' in '..Texts())
    end
    function Contains(text) return Texts():find(text,1,true)~=nil end
    local function RefreshData()
        local dungeon,tab,boss,quest=M.view.dungeon,M.view.tab,M.view.boss,M.view.quest
        page.general:GetScript('OnClick')(page.general)
        assert(page.reload:IsShown() and page.reload.label:GetText()=='Refresh' and page.reload:GetWidth()==86)
        page.reload:GetScript('OnClick')(page.reload)
        M:Navigate(dungeon,tab,boss,quest)
    end
    assert(Contains('Enable Dungeon Loot'))
    addon:SetModuleEnabled('dungeonLoot',true)
    assert(Contains('Enable DungeonJournal'))
    Click('Shadowfang Keep');assert(Contains('load loot and quests'))
    -- Synthetic schema fixture, not actual loot or quest records.
    local source={Constants={},DB={
        ['Another Dungeon']={},
        ['Shadowfang Keep']={location='Fixture zone',level='10-20',
            bosses={{name='Fixture Boss',npcID=100006,loot={{100001,'Fixture Item','Back',2},{-1,'Invalid'}}},
                {name='Unknown Boss',loot={}},
                {name='Rare Fixture',rare=true,loot={}},
                {name='Extra Fixture',trash=true,loot={}}},
            quests={{id=100002,name='Fixture Quest',pickup='Fixture NPC, Fixture zone',
                turnin='Fixture End NPC',objective='Fixture objective',faction='Horde',classOnly='ROGUE',requires=10,
                startMap={label='Fixture NPC',x=.123,y=.456},note='Fixture note',
                rewardItems={{100003,'Fixture Reward',2}}},
                {id=100004,name='Other Quest',faction='Alliance'}}},
        },STATIC_DISPLAY_IDS={[100006]=1234},QUEST_PREREQ_CHAINS={[100002]={{id=100005,name='Fixture prerequisite'}}},
        QUEST_PREREQ_DETAILS={[100005]={pickup='Prereq NPC',objective='Prereq objective'}},
        QUEST_START_MAPS={[100005]={label='Prereq NPC',x=.2,y=.3}}}
    ForeverDungeonJournal_NS=source
    local before=addon.ProfileCodec.Encode(source)
    source.DB['Shadowfang Keep'].bosses[1].loot[3]={{secret=true},'Restricted ID'}
    local snapshot=addon.DungeonLootProvider:Read()
    assert(#snapshot.catalog==1 and snapshot.catalog[1]=='Shadowfang Keep')
    assert(snapshot.bossCount==2 and snapshot.rareCount==1,'extras not counted as bosses')
    assert(#snapshot.bosses[1].items==1 and snapshot.quests[1].chain[1].start:find('20.0',1,true))
    snapshot.bosses[1].items[1].name='Changed snapshot'
    assert(source.DB['Shadowfang Keep'].bosses[1].loot[1][2]=='Fixture Item','no alias to source tables')
    SetPortraitTextureFromCreatureDisplayID=function(texture,id) assert(id==1234);texture.displayID=id end
    M:Navigate(nil);RefreshData()
    local card,slot=Find('Shadowfang Keep')
    assert(slot.art:IsShown() and slot.art.texture:find('LoadScreenShadowFangKeep',1,true))
    assert(slot.row:GetHeight()==230 and Contains('2 bosses + 1 rare') and Contains('2 quests'))
    assert(Contains('Suggested levels 20–30') and not Contains('Another Dungeon'))
    assert(not Contains('Source:') and not Contains('Community tables') and not Contains('pilot'))
    assert(slot.button.factionIcons[1]:IsShown() and slot.button.factionIcons[1].texture:find('Horde',1,true))
    assert(not page.reload.row and not page.reload.parent.row:IsShown(),'refresh row only in General')
    Click('Shadowfang Keep')
    local foundPortrait=false
    for _,s in ipairs(page.slots) do if s.visible then for _,cell in ipairs(s.cells) do
        if cell:IsShown() and cell.label:GetText()=='Fixture Boss' then assert(cell.portrait.displayID==1234);foundPortrait=true end
    end end end
    assert(foundPortrait and Contains('Other loot'))
    Click('Fixture Boss')
    assert(Contains('Fixture Item') and Contains('loading details'))
    local requests=0
    C_Item={RequestLoadItemDataByID=function(id) requests=requests+1 end}
    RefreshData();page:Refresh();assert(requests==1,'one request per uncached visible item')
    local loaded=false
    C_Item.GetItemInfo=function(id) if loaded and id==100001 then return 'Live Fixture Item','item:100001',2,10,5,'Armor','Cloth',1,'INVTYPE_CLOAK',123 end end
    loaded=true;FireEvent('GET_ITEM_INFO_RECEIVED',100001,true)
    assert(Contains('Live Fixture Item'))
    GameTooltip={SetOwner=function() end,SetHyperlink=function(_,link) tooltipLink=link end,Show=function() end,Hide=function() tooltipHidden=true end}
    local item=Find('Live Fixture Item');item.scripts.OnEnter(item);assert(tooltipLink=='item:100001')
    item.scripts.OnLeave(item);assert(tooltipHidden)
    page.quests:GetScript('OnClick')(page.quests)
    Click('Fixture Quest')
    assert(Contains('Start here') and Contains('Before you go') and Contains('In the dungeon') and Contains('Turn in') and Contains('Rewards'))
    assert(Contains('Fixture NPC, Fixture zone') and Contains('12.3, 45.6') and Contains('Fixture prerequisite'))
    assert(Contains('Prereq NPC') and Contains('Fixture Reward'))
    Click('< All quests')
    page.search:SetText('no match');assert(Contains('No quests match your filters'))
    page.search:SetText('')
    M.view.faction='Alliance';page:Refresh();assert(not Contains('Fixture Quest') and Contains('Other Quest'))
    page.home:GetScript('OnClick')(page.home)
    page.search:SetText('no match');assert(Contains('No dungeons match'))
    page.search:SetText('');assert(not Contains('Another Dungeon'))
    assert(source.DB['Shadowfang Keep'].bosses[1].loot[3][1].secret)
    source.DB['Shadowfang Keep'].bosses[1].loot[3]=nil
    assert(before==addon.ProfileCodec.Encode(source),'provider and UI never mutate the data addon')
    M.view.faction='all';local rows=#page.slots
    for i=1,10 do M:Navigate('Shadowfang Keep');Click('Fixture Boss');page.quests:GetScript('OnClick')(page.quests);Click('Fixture Quest') end
    assert(#page.slots==rows,'row pool stays bounded across navigation')
    -- Missing native portrait renderer stays readable; neutral cards show both emblems.
    SetPortraitTextureFromCreatureDisplayID=nil
    addon.DungeonLootWidgets.Portrait(page.slots[1].icon,{displayID=1234})
    assert(page.slots[1].icon.texture=='Interface\\\\EncounterJournal\\\\UI-EJ-BOSS-Default')
    addon.DungeonLootWidgets.Factions(page.slots[1].button,'Both')
    assert(page.slots[1].button.factionIcons[1]:IsShown() and page.slots[1].button.factionIcons[2]:IsShown())
    page:Hide();assert(next(M.events.events)==nil,'hidden page has no item listener')
    page:Show();assert(M.events.events.GET_ITEM_INFO_RECEIVED)
    addon:SetModuleEnabled('dungeonLoot',false)
    assert(next(M.events.events)==nil and Contains('Enable Dungeon Loot'))
    addon:SetModuleEnabled('dungeonLoot',true)
''')
state = lua.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
restored, _ = load(state)
restored.execute("assert(addon.DungeonLoot.enabled and addon.db.modules.dungeonLoot.enabled)")

parser = argparse.ArgumentParser()
parser.add_argument('--reference-directory', type=Path)
args = parser.parse_args()
if args.reference_directory:
    native, _ = load()
    native.execute("ForeverDungeonJournal_NS={Constants={ALBA_FAIRMOON_LOCATION='Reference location'}}")
    execute = native.eval('function(s,n,ns) local f,e=loadstring(s,n); assert(f,e); return f("ForeverDungeonJournal",ns) end')
    namespace = native.globals().ForeverDungeonJournal_NS
    for name in ('Dungeons', 'SharedLoot', 'Bosses', 'QuestMaps', 'QuestChains', 'QuestRewards', 'QuestShareability', 'QuestUpdates'):
        path = args.reference_directory / 'Data' / (name + '.lua')
        execute(path.read_text(encoding='utf-8-sig'), str(path), namespace)
    native.execute('''
        local M=addon.DungeonLoot
        addon:SetModuleEnabled('dungeonLoot',true)
        addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
        M:Navigate('Shadowfang Keep')
        local data=M.data
        assert(data.available and #data.catalog==1 and data.bossCount==8 and data.rareCount==1 and #data.quests==7)
        for i,boss in ipairs(data.bosses) do
            if not boss.extra then assert(boss.displayID,'boss portrait metadata missing') end
            M:Navigate('Shadowfang Keep','loot',i)
        end
        for i,q in ipairs(data.quests) do M:Navigate('Shadowfang Keep','quests',nil,i) end
        integrationCounts={data.bossCount,data.rareCount,#data.quests}
    ''')
    counts = native.globals().integrationCounts
    print(f'PASS installed data schema: {counts[1]} SFK bosses + {counts[2]} rare, {counts[3]} quests, native portrait metadata (mock only)')
print('PASS Dungeon Loot cards, portrait grid, source isolation, async items, tooltips, filters, row pooling, lifecycle and profiles')
