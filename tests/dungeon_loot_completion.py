"""Completion history, deduplicated chain tasks, card alignment and bracket jumps."""
from smoke import load

lua,_=load()
lua.execute(r'''
    local M,P,C=addon.DungeonLoot,addon.DungeonLootProvider,addon.DungeonLootCatalog
    function UnitFactionGroup() return 'Horde' end
    function UnitClass() return 'Mage','MAGE',8 end
    local log,done={},{}
    C_QuestLog={IsOnQuest=function(id) return log[id]==true end,
        IsQuestFlaggedCompleted=function(id) return done[id]==true end}
    addon:SetModuleEnabled('dungeonLoot',true);addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    local page=M.page
    local function Plain(text) return (text or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','') end
    local function Find(pane,name)
        for _,slot in ipairs(pane.slots) do if slot.visible and Plain(slot.button.label:GetText())==name then return slot end end
        error('Missing '..name)
    end
    M:Navigate(nil)
    local rol=Find(page.rootPane,'Ruins of Lordaeron')
    assert(Plain(rol.questProgress:GetText()):find('You have 0/6 possible quests',1,true))
    assert(rol.questProgress.points[1][1]=='BOTTOMRIGHT' and rol.questProgress.justifyH=='RIGHT')
    local _,size=rol.questProgress:GetFont();assert(size==14)
    assert(rol.button.label.justifyH=='CENTER' and rol.button.label.justifyV=='MIDDLE')
    assert(rol.button.label.points[1][2]==rol.topBand)
    for _,icon in ipairs(rol.button.factionIcons) do if icon:IsShown() then
        assert(icon.points[1][1]=='LEFT' and icon.points[1][2]==rol.button.label and icon.points[1][3]=='RIGHT')
    end end
    local heading=Find(page.rootPane,'Suggested Starting Levels 20–29')
    assert(heading.headingLine:IsShown() and heading.headingLine:GetHeight()==1)
    assert(heading.button.label:GetText():find('|cff0974f1',1,true),'bracket gradient starts with stronger blue')
    local jump
    for _,button in ipairs(page.jumpButtons) do if button.bracket=='20–29' then jump=button end end
    assert(page.jumpBar:IsShown() and jump and jump:IsShown())
    jump:GetScript('OnClick')(jump)
    assert(page.rootPane.scrollbar:GetValue()==math.max(0,heading.row.offset-4),'jump uses actual layout offset')
    M:Navigate('Ruins of Lordaeron','quests')
    assert(not page.jumpBar:IsShown(),'jump strip only on dungeon index')
    local count=0;local quest
    for _,q in ipairs(M.data.quests) do if q.name=='Unending Torment' then count=count+1;quest=q end end
    assert(count==1 and #quest.stages==3 and quest.completionIDs[1]==97290)
    assert(quest.stages[1].id==97288 and quest.stages[2].id==97289 and quest.stages[3].id==97290)
    -- Completing the first stage does not complete the final dungeon task.
    done[97288]=true;log[97289]=true;FireEvent('QUEST_LOG_UPDATE')
    assert(not M.data.questStates[quest.id].completed and M.data.questStates[quest.id].inLog)
    assert(quest.currentStage.id==97289,'active intermediate chain stage is retained')
    local row=Find(page.listPane,'Unending Torment')
    assert(Plain(row.subtitle:GetText()):find('In your log',1,true))
    M:SelectEntry('quest',(function() for i,q in ipairs(M.data.quests) do if q==quest then return i end end end)())
    local seen=false
    for _,slot in ipairs(page.detailPane.slots) do if slot.visible and Plain(slot.button.label:GetText())=='In your log' then seen=true end end
    assert(seen,'detail pane also clearly marks the picked-up quest')
    local stageButtons
    for _,slot in ipairs(page.detailPane.slots) do if slot.visible and #slot.cells==3 then stageButtons=slot end end
    assert(stageButtons and stageButtons.cells[2].selected,'compact stage buttons select the active chain step')
    stageButtons.cells[3]:GetScript('OnClick')(stageButtons.cells[3]);assert(M.view.stageID==97290)
    M:SelectEntry('quest',M.view.quest);assert(M.view.stageID==nil,'entry selection resets manual stage inspection')
    done[97289]=true;log={[97290]=true};FireEvent('QUEST_LOG_UPDATE')
    assert(quest.currentStage.id==97290,'advancing a chain redraws even when the aggregate pickup count is unchanged')
    log={};done[97290]=true;FireEvent('QUEST_LOG_UPDATE')
    assert(M.data.questStates[quest.id].completed)
    assert(Plain(Find(page.listPane,'Unending Torment').subtitle:GetText()):find('Completed',1,true))
    for _,card in ipairs(M.data.cards) do if card.name=='Ruins of Lordaeron' then
        for _,header in ipairs(card.questHeaders) do if P:Eligible(header,M.data.player) then
            for _,id in ipairs(#header.completionIDs>0 and header.completionIDs or {header.id}) do done[id]=true end
        end end
    end end
    FireEvent('QUEST_LOG_UPDATE');M:Navigate(nil)
    assert(Plain(Find(page.rootPane,'Ruins of Lordaeron').questProgress:GetText())=='All quests completed')
    C_QuestLog.IsQuestFlaggedCompleted=function() return {secret=true} end
    FireEvent('QUEST_LOG_UPDATE')
    assert(not Plain(Find(page.rootPane,'Ruins of Lordaeron').questProgress:GetText()):find('All quests completed',1,true),'restricted history cannot claim completion')
    -- Unrelated same-title quests, faction/class variants and preAny alternatives are not merged.
    local Q=C.Data.Quests
    local fixture={
      [999001]={name='Repeated',side='H'},
      [999002]={name='Repeated',side='H',pre={999001}},
      [999003]={name='Repeated',side='H'},
      [999004]={name='Repeated',side='A',pre={999002}},
      [999005]={name='Repeated',side='H',classes={'MAGE'},pre={999002}},
      [999006]={name='Repeated',side='H',preAny={{999002}}},
    }
    for id,q in pairs(fixture) do Q[id]=q end
    local groups=C:Groups('completion-test',{999001,999002,999003,999004,999005,999006,999001})
    assert(#groups==5 and #groups[1].ids==2 and groups[1].terminal[1]==999002)
    for id in pairs(fixture) do Q[id]=nil end
    Q[999007]={name='Cyclic',pre={999008}};Q[999008]={name='Cyclic',pre={999007}}
    assert(#C:Groups('cycle-test',{999007,999008})==2,'cycles cannot invent a terminal completed task')
    Q[999007],Q[999008]=nil,nil
    -- Every collapsed task has its original IDs represented as stages; no source mutations.
    for _,instance in ipairs(C.Data.Instances) do if instance.kind=='dungeon' then
        local covered={}
        for _,group in ipairs(C:Groups(instance.key,C.Data.InstanceQuests[instance.key] or {})) do
            for _,id in ipairs(group.ids) do assert(not covered[id]);covered[id]=true end
            for _,id in ipairs(group.ids) do
                local found=false;for _,stage in ipairs(group.stages) do if stage==id then found=true end end
                assert(found,'every original chain entry remains available in the grouped detail')
            end
        end
        for _,id in ipairs(C.Data.InstanceQuests[instance.key] or {}) do assert(covered[id]) end
    end end
    M:Navigate(nil);page.search:SetText('Ruins of Lordaeron')
    for _,button in ipairs(page.jumpButtons) do if button:IsShown() then assert(button.bracket=='10–19') end end
    M:Navigate('Ruins of Lordaeron','quests');addon:SetModuleEnabled('dungeonLoot',false)
    assert(not page.jumpBar:IsShown() and not M.events.events.QUEST_LOG_UPDATE)
''')
print('PASS completed history, Ruins 6-quest total, chain stages/status, guarded completion, all catalog group coverage, centered card anchors and bracket jumps')
