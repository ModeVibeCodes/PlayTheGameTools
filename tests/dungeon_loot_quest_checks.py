"""Completed dungeon quests are marked off in the quest list, detail pane and chain stages."""
from smoke import load

lua,_=load()
lua.execute(r'''
    local M,P,T=addon.DungeonLoot,addon.DungeonLootProvider,addon.InterfaceTheme
    function UnitFactionGroup() return 'Horde' end
    function UnitClass() return 'Mage','MAGE',8 end
    local log,done={},{}
    C_QuestLog={IsOnQuest=function(id) return log[id]==true end,
        IsQuestFlaggedCompleted=function(id) return done[id]==true end}
    addon:SetModuleEnabled('dungeonLoot',true);addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    local page=M.page
    local CHECK='Interface\\Buttons\\UI-CheckBox-Check'
    local function Plain(text) return (text or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','') end
    local function Find(pane,name)
        for _,slot in ipairs(pane.slots) do
            if slot.visible and slot.button:IsShown() and Plain(slot.button.label:GetText())==name then return slot end
        end
        error('Missing '..name)
    end
    local function Checked(slot) return slot.check~=nil and slot.check:IsShown() end
    local function Stages()
        for _,slot in ipairs(page.detailPane.slots) do
            if slot.visible and #slot.cells==3 and slot.cells[1]:IsShown() then return slot end
        end
        error('Missing stage buttons')
    end
    local function Eligible()
        local list={}
        for _,q in ipairs(M.data.quests) do if P:Eligible(q,M.data.player)==true then list[#list+1]=q end end
        return list
    end

    M:Navigate('Ruins of Lordaeron','quests')
    local quest,index
    for i,q in ipairs(M.data.quests) do if q.name=='Unending Torment' then quest,index=q,i end end
    assert(quest and #quest.stages==3 and quest.stages[3].id==97290)

    -- Nothing completed: every quest title sits in the same check column, none marked.
    assert(#Eligible()==6)
    for _,q in ipairs(Eligible()) do
        local row=Find(page.listPane,q.name)
        assert(row.button.label.points[1][4]==32,'quest titles share one check column')
        assert(not Checked(row) and row.button.labelColor==T.text)
    end

    -- An earlier chain stage is marked on its stage button only.
    done[97288]=true;log[97289]=true;FireEvent('QUEST_LOG_UPDATE')
    assert(quest.stages[1].completed==true and quest.stages[2].completed==false and quest.stages[3].completed==false)
    assert(not Checked(Find(page.listPane,'Unending Torment')),'an earlier stage does not mark off the whole chain')
    M:SelectEntry('quest',index)
    local stages=Stages()
    assert(stages.cells[1].check:IsShown() and stages.cells[1].check.texture==CHECK)
    assert(stages.cells[1].label.points[1][4]==8 and stages.cells[1].check.points[1][2]==stages.cells[1].label)
    assert(not stages.cells[2].check:IsShown() and stages.cells[2].label.points[1][4]==0)
    assert(stages.cells[1]:GetWidth()==84,'stage buttons leave room for the check')
    local status=Find(page.detailPane,'In your log')
    assert(not Checked(status) and status.button.label.points[1][4]==12,'only a completed status takes the check column')

    -- The final stage completes the dungeon task: list row and detail are marked off.
    done[97289]=true;done[97290]=true;log={};FireEvent('QUEST_LOG_UPDATE')
    local row=Find(page.listPane,'Unending Torment')
    assert(Checked(row) and row.check.texture==CHECK and row.check.desaturated==true)
    local c=row.check.vertexColor
    assert(math.abs(c[1]-0.475)<0.001 and math.abs(c[2]-0.851)<0.001 and math.abs(c[3]-0.549)<0.001,'check uses the Completed green')
    assert(row.check:GetWidth()==16 and row.check.points[1][1]=='TOPRIGHT' and row.check.points[1][2]==row.button.label)
    assert(row.button.label.points[1][4]==32 and row.button.labelColor==T.muted,'completed quests are dimmed in place')
    assert(Plain(row.subtitle:GetText()):find('Completed',1,true),'the check keeps its written status')
    for _,q in ipairs(Eligible()) do if q~=quest then
        local other=Find(page.listPane,q.name)
        assert(not Checked(other) and other.button.labelColor==T.text)
    end end
    status=Find(page.detailPane,'Completed')
    assert(Checked(status) and status.button.label.points[1][4]==32)
    stages=Stages()
    for i=1,3 do assert(stages.cells[i].check:IsShown()) end

    -- Recycled rows on another tab never carry a stale check.
    M:Navigate('Ruins of Lordaeron','loot')
    for _,pane in ipairs({page.listPane,page.detailPane}) do for _,slot in ipairs(pane.slots) do
        assert(not (slot.visible and Checked(slot)),'recycled rows drop the check')
    end end
    local boss=Find(page.listPane,M.data.bosses[1].name)
    assert(boss.button.label.points[1][4]==60,'boss rows keep their portrait layout')

    -- Restricted or unknown history never marks anything off.
    M:Navigate('Ruins of Lordaeron','quests')
    C_QuestLog.IsQuestFlaggedCompleted=function() return {secret=true} end
    FireEvent('QUEST_LOG_UPDATE')
    for _,q in ipairs(Eligible()) do assert(not Checked(Find(page.listPane,q.name))) end
    for _,q in ipairs(M.data.quests) do if q.name=='Unending Torment' then quest=q end end
    for _,stage in ipairs(quest.stages) do assert(stage.completed==false) end

    -- A refused check file leaves no empty marker and keeps the titles aligned.
    C_QuestLog.IsQuestFlaggedCompleted=function(id) return done[id]==true end
    testMissingTextures={[CHECK]=true}
    FireEvent('QUEST_LOG_UPDATE')
    row=Find(page.listPane,'Unending Torment')
    assert(not Checked(row) and row.button.label.points[1][4]==32 and row.button.labelColor==T.muted)
    M:SelectEntry('quest',(function() for i,q in ipairs(M.data.quests) do if q.name=='Unending Torment' then return i end end end)())
    stages=Stages()
    for i=1,3 do assert(not stages.cells[i].check:IsShown() and stages.cells[i].label.points[1][4]==0) end
    testMissingTextures=nil

    addon:SetModuleEnabled('dungeonLoot',false)
    assert(not M.events.events.QUEST_LOG_UPDATE)
''')
print('PASS completed quests marked off in list/detail/stages, shared check column, dimmed titles, stage-only progress, recycling, restricted history and refused texture')
