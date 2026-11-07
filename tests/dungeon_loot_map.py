"""Quest map API/schema contract and UI tests; no claim of native map support."""
from smoke import load

lua,_=load()
lua.execute('''
    local M,L,Map=addon.DungeonLoot,addon.DungeonLootLocations,addon.DungeonLootMap
    local records={spawns={[42]={{10,20},{30,40}}},waypoints={[42]={{{10,20},{20,30},{30,40}}}}}
    local original=addon.ProfileCodec.Encode(records)
    LibQuestieDB={Quest={
        startedBy=function() return {{101}} end,finishedBy=function() return {{102}} end,
        objectives=function() return {{{101,'Patrol target',1}}} end},
        Npc={name=function(id) return id==101 and 'Fixture Patrol' or 'Fixture Finisher' end,
            spawns=function() return records.spawns end,waypoints=function(id) return id==101 and records.waypoints or nil end}}
    QuestieLoader={ImportModule=function(_,name) assert(name=='ZoneDB');return {GetUiMapIdByAreaId=function(_,area) assert(area==42);return 1421 end} end}
    local target=L:Targets(100002,'pickup')[1]
    assert(target.mapID==1421 and #target.points==2 and #target.paths==1 and #target.paths[1]==3)
    target.points[1][1]=.9;assert(original==addon.ProfileCodec.Encode(records),'no source alias')
    target=L:Targets(100002,'pickup')[1]
    assert(#L:Targets(100002,'turnin')[1].paths==0,'multiple spawn points are not a patrol')
    local save=records.waypoints
    records.waypoints={[42]={{{10,20},{secret=true},{30,40}}}}
    assert(#L:Targets(100002,'pickup')[1].paths==0,'invalid path point does not create a bridge')
    records.waypoints=save
    local canvas=CreateFrame('Frame');canvas:SetSize(1000,600)
    getmetatable(canvas).__index.CreateLine=function()
        local line=CreateFrame('Frame')
        function line:SetThickness(v) self.thickness=v end
        function line:SetStartPoint(...) self.start={...} end
        function line:SetEndPoint(...) self.finish={...} end
        return line
    end
    WorldMapFrame=CreateFrame('Frame');WorldMapFrame:Hide()
    function WorldMapFrame:GetCanvas() return canvas end
    function WorldMapFrame:GetMapID() return self.mapID end
    function WorldMapFrame:SetMapID(id) self.mapID=id;self.provider:OnMapChanged() end
    function WorldMapFrame:AddDataProvider(provider) self.provider=provider;provider:OnAdded(self) end
    MapCanvasDataProviderMixin={OnAdded=function(self,map) self.map=map end,OnMapChanged=function(self) self:RefreshAllData() end}
    function CreateFromMixins(base) local copy={};for k,v in pairs(base) do copy[k]=v end;return copy end
    local opens=0
    function ShowUIPanel(map) opens=opens+1;map:Show() end
    WorldMapFrame:SetScript('OnHide',function() if Map.provider then Map.provider:OnHide() end end)
    addon:SetModuleEnabled('dungeonLoot',true)
    addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    assert(Map:Open(target,'pickup'))
    assert(opens==1 and WorldMapFrame.mapID==1421 and #Map.lines==2 and Map.markers[1]:IsShown())
    assert(Map.lines[1].start[3]==100 and Map.lines[1].start[4]==-120)
    assert(Map.lines[1].finish[3]==200 and Map.lines[1].finish[4]==-180)
    assert(not addon.configWindow:IsShown(),'map is not hidden behind addon dialog')
    WorldMapFrame:Hide();assert(Map.target==nil and not Map.lines[1]:IsShown() and addon.configWindow:IsShown())
    testCombat=true
    local ok,reason=Map:Open(target,'pickup');assert(not ok and reason:find('combat') and opens==1)
    testCombat=false
    assert(Map:Open(target,'objective'));WorldMapFrame:SetMapID(1458)
    assert(not Map.markers[1]:IsShown() and not Map.lines[1]:IsShown(),'wrong-map overlay hidden')
    WorldMapFrame:SetMapID(1421);assert(Map.lines[1]:IsShown())
    addon:SetModuleEnabled('dungeonLoot',false);assert(Map.target==nil and not Map.lines[1]:IsShown())
    addon:SetModuleEnabled('dungeonLoot',true)
    RAID_CLASS_COLORS={MAGE={r=.25,g=.78,b=.92}};LOCALIZED_CLASS_NAMES_MALE={MAGE='Mage'}
    ForeverDungeonJournal_NS={DB={['Shadowfang Keep']={bosses={},quests={{id=100002,name='Fixture Quest',
        classOnly='MAGE',faction='Both',pickup='Fixture Patrol',turnin='Fixture Finisher',note='Important acquisition note',
        objective='Find fixture',requires=10,rewardItems={}}}}},QUEST_PREREQ_CHAINS={[100002]={{id=100003,name='Prerequisite'}}}}
    M:ReadData();addon.configWindow:Show();M:Navigate('Shadowfang Keep','quests')
    local page=M.page
    assert(page.faction:GetWidth()==128 and page.faction:GetHeight()==28)
    assert(#page.faction.points==1 and page.faction.points[1][1]=='TOPRIGHT','no inherited left anchor')
    local anchor=page.search.points[2]
    assert(anchor[2]==page.faction and anchor[3]=='TOPLEFT' and anchor[4]==-10)
    local class,chain,noteIndex,objectiveIndex,mapButton
    local function Plain(text) return text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','') end
    for _,slot in ipairs(page.listPane.slots) do if slot.visible and slot.subtitle:IsShown() then
        class=slot.subtitle:GetText():find('|cff40c7ebMage',1,true)
        chain=slot.subtitle:GetText():find('Chain',1,true)
        assert(slot.row:GetHeight()>=56 and slot.subtitle.justifyV=='TOP')
    end end
    assert(class and chain)
    for index,slot in ipairs(page.detailPane.slots) do if slot.visible then
        local text=Plain(slot.button.label:GetText())
        if text=='Important acquisition note' then noteIndex=index end
        if text=='2. Objective' then objectiveIndex=index end
        if text=='View on Map' and slot.mapKind=='pickup' then
            mapButton=slot.button
            assert(mapButton:GetWidth()==128 and mapButton:GetHeight()==28)
            assert(slot.subtitle:GetText()=='Fixture Patrol'..' · Patrol')
        end
        assert(not text:lower():find('approx',1,true))
        assert(text~='Quest notes' and text~='Hide notes')
    end end
    assert(noteIndex and objectiveIndex and noteIndex<objectiveIndex and mapButton)
    mapButton:GetScript('OnClick')(mapButton)
    assert(Map.target and #Map.target.paths==1,'actual map action callback')
    local hasGlow=false
    for _,slot in ipairs(page.detailPane.slots) do
        if slot.visible and slot.headerGlow then
            assert(#slot.headerGlow==4 and slot.headerGlow[1]:IsShown() and slot.headerGlow[1].alpha==.12)
            hasGlow=true;break
        end
    end
    assert(hasGlow)
    local gradient=addon.DungeonLootWidgets.Gradient('Objective')
    assert(Plain(gradient)=='Objective' and select(2,gradient:gsub('|cff',''))==9)
    for kind,colors in pairs({header={'9fccfa','0974f1'},boss={'f83d5c','fd4b2f'},quest={'fada5e','faf2df'}}) do
        local value=addon.DungeonLootWidgets.Gradient('AB',kind)
        assert(value=='|cff'..colors[1]..'A|r|cff'..colors[2]..'B|r',kind..' exact gradient endpoints')
    end
    LibQuestieDB=nil;QuestieLoader=nil
    assert(#L:Targets(100002,'turnin')==0)
    assert(#L:Targets(100002,'pickup',{mapID=1421,x=.4,y=.5,label='Recorded pickup'})==1)
    assert(#L:Targets(100002,'pickup',{mapID=1421,x=2,y=.5})==0)
    assert(original==addon.ProfileCodec.Encode(records))
    -- All seven visible SFK quests have owned pickup/turn-in estimates without Questie.
    for _,id in ipairs({1098,1740,1013,1014,1806,95140,78307}) do
        for _,kind in ipairs({'pickup','turnin'}) do
            local owned=L:Targets(id,kind)
            assert(#owned==1 and owned[1].approximate and #owned[1].paths==0)
        end
    end
    local owned=L:Targets(1098,'turnin')[1]
    assert(owned.mapID==1421 and owned.label:find('inside SFK',1,true) and owned.detail:find('Entrance marker only',1,true))
    owned.x=.1;assert(L:Targets(1098,'turnin')[1].x==.45,'owned records return fresh copies')
    assert(#L:Targets(95140,'objective')==0,'unknown final kill is not invented')
    assert(Map:Open(L:Targets(1098,'pickup')[1],'pickup'))
    local pin=Map.markers[1]
    assert(pin:IsShown() and pin:GetWidth()==40 and pin.caption:GetText()=='High Executor Hadrec')
    assert(pin.clickRegistration=='RightButtonUp' and pin:GetFrameLevel()>canvas:GetFrameLevel()+50)
    pin:GetScript('OnClick')(pin,'LeftButton');assert(Map.target)
    pin:GetScript('OnClick')(pin,'RightButton')
    assert(not pin:IsShown() and Map.target==nil and WorldMapFrame:IsShown(),'right click removes only our overlay, not the map')
    WorldMapFrame:Hide();assert(addon.configWindow:IsShown(),'dismiss keeps return-to-settings behavior')
    -- Deferred canvas layout and native entry point, independent of quest ownership.
    local pending={}
    local timer=C_Timer.After
    C_Timer.After=function(_,fn) pending[#pending+1]=fn end
    local nativeOpens,questQueries=0,0
    C_Map=C_Map or {}
    C_Map.OpenWorldMap=function(id)
        nativeOpens=nativeOpens+1;WorldMapFrame:Show();WorldMapFrame:SetMapID(id)
    end
    C_QuestLog={IsOnQuest=function() error('quest log must not gate custom markers') end}
    for _,hasQuest in ipairs({false,true}) do
        IsQuestFlaggedCompleted=function() error('completion must not gate custom markers') end
        C_QuestLog.IsOnQuest=function() questQueries=questQueries+1;return hasQuest end
        canvas:SetSize(0,0)
        assert(Map:Open(L:Targets(1098,'pickup')[1],'pickup'))
        assert(not pin:IsShown(),'wait for usable canvas dimensions')
        canvas=CreateFrame('Frame');canvas:SetSize(800,500)
        for _,fn in ipairs(pending) do fn() end;pending={}
        assert(pin:IsShown() and Map.overlay:GetParent()==canvas,'rebind replaced canvas after layout')
        assert(pin.points[1][4]==344 and pin.points[1][5]==-205,'settled canvas coordinates')
        Map:Dismiss()
        for _,fn in ipairs(pending) do fn() end;pending={}
        assert(not pin:IsShown())
        WorldMapFrame:Hide()
    end
    assert(nativeOpens==2 and questQueries==0)
    assert(Map:Open(L:Targets(1098,'pickup')[1],'pickup'))
    Map:Dismiss()
    for _,fn in ipairs(pending) do fn() end
    assert(not pin:IsShown(),'queued callbacks cannot resurrect dismissed markers')
    C_Timer.After=timer

''')
print('PASS quest map pins, ordered patrol geometry, combat guards, cleanup, read-only source, notes, class/chain styling and toolbar anchors (mock only)')
