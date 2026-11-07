"""Persistent SFK lists, condensed quest details, source isolation and item events."""
import argparse
from pathlib import Path
from smoke import load

lua, _ = load()
lua.execute('''
    local M=addon.DungeonLoot
    assert(not M.enabled and M.category=='questingLeveling')
    addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    local page=M.page
    local function Texts(pane)
        local out={}
        for _,host in ipairs({page.rootPane,page.listPane,page.detailPane}) do
            if host:IsShown() and (not pane or host==pane) then
                for _,slot in ipairs(host.slots) do if slot.visible then
                    out[#out+1]=slot.button.label:GetText()
                    if slot.subtitle:IsShown() then out[#out+1]=slot.subtitle:GetText() end
                end end
            end
        end
        return table.concat(out,'\\n')
    end
    function Contains(text,pane) return Texts(pane):find(text,1,true)~=nil end
    function Find(text,pane,clickable)
        for _,host in ipairs({page.rootPane,page.listPane,page.detailPane}) do
            if host:IsShown() and (not pane or pane==host) then
                for _,slot in ipairs(host.slots) do
                    if slot.visible and (not clickable or slot.callback) and slot.button.label:GetText():find(text,1,true) then return slot.button,slot end
                end
            end
        end
        error('Missing control: '..text..' in '..Texts(pane))
    end
    function Click(text,pane) local b=Find(text,pane,true);b:GetScript('OnClick')(b) end
    assert(Contains('Enable Dungeon Loot'))
    addon:SetModuleEnabled('dungeonLoot',true)
    Click('Shadowfang Keep');assert(Contains('Enable DungeonJournal'))
    local source={DB={['Another Dungeon']={},['Shadowfang Keep']={
        bosses={{name='Fixture Boss',npcID=100006,loot={{100001,'Fixture Item','Back',2}}},
            {name='Second Boss',rare=true,loot={{100007,'Second Item','Head',2}}},
            {name='Extra Fixture',trash=true,loot={}}},
        quests={{id=100002,name='Fixture Quest',pickup='Fixture NPC, Fixture zone',turnin='Fixture End NPC',
            objective='Fixture objective',faction='Horde',requires=10,note='Long optional fixture note',rewardChoice=true,
            startMap={label='Fixture NPC',x=.123,y=.456},rewardItems={{100003,'Fixture Reward',2}},
            rewards='Choose: Fixture Reward\\n100 XP'},
            {id=100004,name='Other Quest',faction='Alliance',objective='Other objective'}}}},
        STATIC_DISPLAY_IDS={[100006]=1234},QUEST_PREREQ_CHAINS={[100002]={{id=100005,name='Fixture prerequisite'}}},
        QUEST_PREREQ_DETAILS={[100005]={pickup='Prereq NPC',objective='Prereq objective'}}}
    ForeverDungeonJournal_NS=source
    local before=addon.ProfileCodec.Encode(source)
    local snapshot=addon.DungeonLootProvider:Read()
    assert(#snapshot.catalog==1 and snapshot.bossCount==1 and snapshot.rareCount==1)
    snapshot.bosses[1].items[1].name='Changed copy'
    assert(source.DB['Shadowfang Keep'].bosses[1].loot[1][2]=='Fixture Item')
    SetPortraitTextureFromCreatureDisplayID=function(texture,id) assert(id==1234);texture.displayID=id end
    page.general:GetScript('OnClick')(page.general)
    assert(page.reload:GetWidth()==86 and page.reload:GetHeight()==28)
    page.reload:GetScript('OnClick')(page.reload)
    page.home:GetScript('OnClick')(page.home)
    local _,card=Find('Shadowfang Keep')
    assert(card.art:IsShown() and card.row:GetHeight()==230)
    assert(Contains('1 bosses + 1 rare') and Contains('2 quests') and not Contains('Another Dungeon'))
    Click('Shadowfang Keep')
    assert(page.listPane:IsShown() and page.detailPane:IsShown() and not page.rootPane:IsShown())
    assert(M.view.boss==1 and Contains('Fixture Item',page.detailPane),'first boss auto-selected')
    assert(Contains('Second Boss',page.listPane) and not Contains('< All bosses'))
    local first=Find('Fixture Boss',page.listPane);assert(first.selected)
    local left=page.listPane;left.scroll:SetHeight(100);page:Layout();left.scrollbar:SetValue(42)
    local paneIdentity=left
    Click('Second Boss',left)
    assert(M.view.boss==2 and Contains('Second Item',page.detailPane))
    assert(page.listPane==paneIdentity and Contains('Fixture Boss',left),'persistent list is reused')
    assert(left.scrollbar:GetValue()==42,'boss selection preserves independent list scroll')
    local second=Find('Second Boss',left);assert(second.selected and not first.selected)
    local requests=0
    C_Item={RequestLoadItemDataByID=function(id) requests=requests+1 end}
    M.attempted={};Click('Fixture Boss',left);page:Refresh();assert(requests==1)
    local loaded=false
    C_Item.GetItemInfo=function(id) if loaded and id==100001 then return 'Live Fixture Item','item:100001',2,10,5,'Armor','Cloth',1,'INVTYPE_CLOAK',123 end end
    loaded=true;FireEvent('GET_ITEM_INFO_RECEIVED',100001,true)
    assert(Contains('Live Fixture Item',page.detailPane) and Contains('Second Boss',left))
    GameTooltip={SetOwner=function() end,SetHyperlink=function(_,link) tooltipLink=link end,Show=function() end,Hide=function() tooltipHidden=true end}
    local item=Find('Live Fixture Item',page.detailPane);item.scripts.OnEnter(item);assert(tooltipLink=='item:100001')
    item.scripts.OnLeave(item);assert(tooltipHidden)
    page.search:SetText('Second');assert(M.view.boss==2 and Contains('Second Item',page.detailPane))
    page.search:SetText('no match');assert(Contains('No bosses match') and M.view.boss==nil)
    page.search:SetText('');assert(M.view.boss==1)
    page.quests:GetScript('OnClick')(page.quests)
    assert(M.view.quest==1 and Contains('Other Quest',left) and Contains('Fixture objective',page.detailPane))
    assert(Contains('Starts at') and Contains('Fixture End NPC') and Contains('Choose one reward'))
    assert(Contains('12.3, 45.6') and Contains('100 XP'))
    assert(not Contains('Long optional fixture note') and not Contains('Prereq NPC'))
    Click('Prerequisites (1)',page.detailPane);assert(Contains('Prereq NPC'))
    Click('Quest notes',page.detailPane);assert(Contains('Long optional fixture note'))
    Click('Other Quest',left)
    assert(M.view.quest==2 and Contains('Other objective',page.detailPane) and Contains('Fixture Quest',left))
    assert(not M.view.showNotes and not M.view.showPrerequisites and not Contains('< All quests'))
    M.view.faction='Horde';page:Refresh();assert(M.view.quest==1 and not Contains('Other Quest',left))
    page.search:SetText('no match');assert(Contains('No quests match') and M.view.quest==nil)
    page.search:SetText('');M.view.faction='all';page:Refresh()
    local slots=#page.detailPane.slots
    for i=1,10 do Click('Other Quest',left);Click('Fixture Quest',left);Click('Prerequisites (1)',page.detailPane);Click('Quest notes',page.detailPane) end
    assert(#page.detailPane.slots==slots,'detail pool stays bounded')
    assert(before==addon.ProfileCodec.Encode(source),'source tables remain unchanged')
    page.loot:GetScript('OnClick')(page.loot);assert(M.view.boss==1,'selection retained across tabs')
    page:Hide();assert(next(M.events.events)==nil)
    page:Show();assert(M.events.events.GET_ITEM_INFO_RECEIVED)
    addon:SetModuleEnabled('dungeonLoot',false);assert(Contains('Enable Dungeon Loot') and next(M.events.events)==nil)
    addon:SetModuleEnabled('dungeonLoot',true)
''')
state = lua.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
restored, _ = load(state)
restored.execute("assert(addon.DungeonLoot.enabled)")
parser = argparse.ArgumentParser()
parser.add_argument('--reference-directory', type=Path)
args = parser.parse_args()
if args.reference_directory:
    native, _ = load()
    native.execute("ForeverDungeonJournal_NS={Constants={ALBA_FAIRMOON_LOCATION='Reference location'}}")
    execute = native.eval('function(s,n,ns) local f,e=loadstring(s,n);assert(f,e);return f("ForeverDungeonJournal",ns) end')
    for name in ('Dungeons','SharedLoot','Bosses','QuestMaps','QuestChains','QuestRewards','QuestShareability','QuestUpdates'):
        path=args.reference_directory / 'Data' / (name+'.lua')
        execute(path.read_text(encoding='utf-8-sig'),str(path),native.globals().ForeverDungeonJournal_NS)
    native.execute('''
        local M=addon.DungeonLoot
        addon:SetModuleEnabled('dungeonLoot',true)
        addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot');M:Navigate('Shadowfang Keep')
        assert(M.data.bossCount==8 and M.data.rareCount==1 and #M.data.quests==7)
        for i=1,#M.data.bosses do M:SelectEntry('boss',i) end
        M:Navigate('Shadowfang Keep','quests')
        for i=1,#M.data.quests do
            M:SelectEntry('quest',i);M.view.showNotes=true;M.view.showPrerequisites=true;M.page:Refresh()
        end
    ''')
    print('PASS installed SFK data: 8 bosses + 1 rare, 7 quest detail panes (mock only)')
print('PASS persistent lists, auto-selection, in-place details, filters, collapsed quests, source isolation, item events and profiles')
