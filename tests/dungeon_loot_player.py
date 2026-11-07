"""Player eligibility, per-card quest-log progress and visible-only event refresh."""
from smoke import load

lua,_=load()
lua.execute(r'''
    local M,P,C=addon.DungeonLoot,addon.DungeonLootProvider,addon.DungeonLootCatalog
    local faction,class='Horde','ROGUE'
    function UnitFactionGroup() return faction end
    function UnitClass() return class,class,4 end
    local log,calls={},{}
    C_QuestLog={IsOnQuest=function(id) calls[id]=(calls[id] or 0)+1;return log[id]==true end}
    local source={DB={Fixture={name='Fixture',level='20-30',location='Test',bosses={},quests={
        {id=1,name='Neutral',faction='Both'},
        {id=2,name='Horde',faction='Horde'},
        {id=3,name='Alliance',faction='Alliance'},
        {id=4,name='Rogue',faction='Both',classOnly='ROGUE'},
        {id=5,name='Mage',faction='Both',classOnly='MAGE'},
        {id=6,name='Shared classes',faction='Both',classes={'MAGE','ROGUE'}},
        {id=7,name='Alliance rogue',faction='Alliance',classes={'ROGUE'}},
    }}}}
    source.QUEST_PREREQ_CHAINS={[1]={{id=20,name='Neutral prerequisite'},{id=21,name='Alliance prerequisite'},{id=22,name='Mage prerequisite'}}}
    source.QUEST_PREREQ_DETAILS={[20]={faction='Both'},[21]={faction='Alliance'},[22]={classOnly='MAGE'}}
    local original=addon.ProfileCodec.Encode(source)
    local read=C.Read;C.Read=function() return source end
    addon:SetModuleEnabled('dungeonLoot',true);addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    local page=M.page
    local function Plain(text) return (text or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','') end
    local function Card()
        for _,slot in ipairs(page.rootPane.slots) do
            if slot.visible and Plain(slot.button.label:GetText())=='Fixture' then return slot end
        end
        error('Fixture card missing')
    end
    local function HasQuest(name)
        for _,slot in ipairs(page.listPane.slots) do
            if slot.visible and Plain(slot.button.label:GetText())==name then return true end
        end
        return false
    end
    M:Navigate(nil)
    local card=Card();local text=card.questProgress:GetText()
    assert(Plain(text):find('You have 0/4 possible quests',1,true))
    assert(text:find('|cff9fccfa',1,true) and Plain(text):find('Rogue quests: 0/2 in log',1,true))
    assert(card.row:GetHeight()==180 and card.bottomBand:GetHeight()>=44,'footer adapts without changing the base image size')
    assert(not page.faction.mouse,'faction badge is automatic')
    log={[1]=true,[4]=true,[3]=true,[5]=true,[7]=true};calls={}
    FireEvent('QUEST_LOG_UPDATE')
    text=Card().questProgress:GetText()
    assert(Plain(text):find('You have 2/4 possible quests',1,true) and text:find('|cffFADA5E',1,true))
    assert(Plain(text):find('Rogue quests: 1/2 in log',1,true))
    assert(not calls[3] and not calls[5] and not calls[7],'ineligible log records never enter either numerator')
    M:Navigate('Fixture','quests')
    assert(HasQuest('Neutral') and HasQuest('Horde') and HasQuest('Rogue') and HasQuest('Shared classes'))
    assert(not HasQuest('Alliance') and not HasQuest('Mage') and not HasQuest('Alliance rogue'))
    assert(page.faction.label:GetText()=='Horde')
    assert(#M.data.quests[1].chain==1 and M.data.quests[1].chain[1].id==20,'prerequisites use the same character restrictions')
    -- Search and existing selection remain stable when only progress changes.
    page.search:SetText('Rogue');local selected=M.view.quest
    log[2],log[6]=true,true;FireEvent('QUEST_LOG_UPDATE')
    assert(M.view.quest==selected and M.view.search=='Rogue')
    assert(not P:UpdateQuestState(M.data),'unchanged log totals do not request another redraw')
    M:Navigate(nil);assert(Card().questProgress:GetText():find('|cff79d98cYou have 4/4',1,true))
    faction,class='Alliance','MAGE';M:Navigate('Fixture','quests')
    assert(HasQuest('Alliance') and HasQuest('Mage') and HasQuest('Shared classes'))
    assert(not HasQuest('Horde') and not HasQuest('Rogue') and not HasQuest('Alliance rogue'))
    M:Navigate(nil);assert(Plain(Card().questProgress:GetText()):find('You have 4/4 possible quests',1,true))
    faction,class='Horde','WARRIOR';M:Navigate(nil)
    assert(Plain(Card().questProgress:GetText()):find('You have 2/2 possible quests',1,true))
    assert(not Plain(Card().questProgress:GetText()):find('Warrior quests:',1,true),'no irrelevant class line')
    -- Unknown/restricted reads must not look like a reliable zero.
    C_QuestLog.IsOnQuest=function() return {secret=true} end
    FireEvent('QUEST_LOG_UPDATE');assert(Plain(Card().questProgress:GetText()):find('Quest log unavailable',1,true))
    C_QuestLog=nil;M:ReadData();page:Refresh()
    assert(Plain(Card().questProgress:GetText()):find('Quest log unavailable',1,true))
    UnitFactionGroup=nil;UnitClass=nil;M:ReadData();page:Refresh()
    assert(Plain(Card().questProgress:GetText()):find('eligibility unavailable',1,true))
    M:Navigate('Fixture','quests');assert(HasQuest('Neutral') and not HasQuest('Rogue') and not HasQuest('Horde'))
    local isolated=P:Read('Fixture')
    isolated.cards[1].questHeaders[6].classes[1]='WARRIOR'
    assert(original==addon.ProfileCodec.Encode(source),'exposed restriction metadata cannot mutate the source')
    assert(M.events.events.QUEST_LOG_UPDATE)
    page:Hide();assert(not M.events.events.QUEST_LOG_UPDATE)
    page:Show();assert(M.events.events.QUEST_LOG_UPDATE)
    addon:SetModuleEnabled('dungeonLoot',false);assert(not M.events.events.QUEST_LOG_UPDATE)
    -- Real bundled class metadata, including SFK's collection-stage aliases.
    C.Read=read
    faction,class='Horde','PALADIN'
    function UnitFactionGroup() return faction end
    function UnitClass() return class,class,2 end
    log={[95140]=true};C_QuestLog={IsOnQuest=function(id) return log[id]==true end}
    local data=P:Read('Shadowfang Keep');local sfk
    for _,entry in ipairs(data.cards) do if entry.name=='Shadowfang Keep' then sfk=entry end end
    assert(sfk.questState.classTotal==1 and sfk.questState.classInLog==1)
    faction='Alliance';log={[1654]=true};data=P:Read('Shadowfang Keep')
    for _,entry in ipairs(data.cards) do if entry.name=='Shadowfang Keep' then sfk=entry end end
    assert(sfk.questState.classTotal==1 and sfk.questState.classInLog==1,'Paladin collection stage counts')
    class='ROGUE';log={[78261]=true};data=P:Read('Shadowfang Keep')
    for _,entry in ipairs(data.cards) do if entry.name=='Shadowfang Keep' then sfk=entry end end
    assert(sfk.questState.classTotal==1 and sfk.questState.classInLog==1,'Rogue collection stage counts')
    log[78307]=true;P:UpdateQuestState(data)
    assert(sfk.questState.classInLog==1,'chain stages are not counted twice')
''')
print('PASS faction/class eligibility, multi-class quests, colored card counts, live quest-log updates, unknown API guards, lifecycle and SFK collection stages')
