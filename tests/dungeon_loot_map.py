"""Quest map API/schema contract and UI tests; no claim of native map support."""
from smoke import load

lua,_=load()
lua.execute('''
    function UnitClass() return "Mage","MAGE",8 end
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
    -- Model the inspected native pool contract, not a plain canvas child.
    MapCanvasPinMixin={
        OnReleased=function() end,
        SetIgnoreGlobalPinScale=function(self,v) self.ignoreGlobalPinScale=v end,
        SetScalingLimits=function(self,...) self.scalingLimits={...} end,
        UseFrameLevelType=function(self,v) self.frameLevelType=v end,
        SetPosition=function(self,x,y) self.normalizedX,self.normalizedY=x,y;self.owningMap:SetPinPosition(self,x,y) end,
        ApplyCurrentPosition=function(self) self.owningMap:SetPinPosition(self,self.normalizedX,self.normalizedY) end,
        ApplyCurrentScale=function(self) self:SetScale(1/(self.owningMap.canvasScale or 1));self:ApplyCurrentPosition() end,
    }
    local freePins,activePins={},{}
    local acquisitions=0
    function WorldMapFrame:SetPinPosition(pin,x,y)
        pin:SetParent(canvas);pin:ClearAllPoints();pin:SetFrameLevel(2200)
        pin:SetPoint('CENTER',canvas,'TOPLEFT',canvas:GetWidth()*x/pin:GetScale(),-canvas:GetHeight()*y/pin:GetScale())
    end
    function WorldMapFrame:AcquirePin(template,...)
        assert(template=='PlayTheGameToolsDungeonLootMapPinTemplate')
        local pin=table.remove(freePins)
        if not pin then
            pin=CreateFrame('Frame',nil,canvas)
            for k,v in pairs(PlayTheGameToolsDungeonLootMapPinMixin) do pin[k]=v end
            pin:OnLoad()
            pin:SetScript('OnMouseUp',function(owner,button,inside) if inside then owner:OnMouseClickAction(button) end end)
        end
        assert(not activePins[pin]);activePins[pin]=true;acquisitions=acquisitions+1
        pin.owningMap=self;pin:Show();pin:OnAcquired(...)
        assert(not pin:ShouldMouseButtonBePassthrough('RightButton'))
        return pin
    end
    function WorldMapFrame:RemovePin(pin)
        assert(activePins[pin],'only release pins owned by native pool')
        activePins[pin]=nil;pin:Hide();pin:ClearAllPoints();pin:OnReleased();pin.owningMap=nil
        freePins[#freePins+1]=pin
    end
    function WorldMapFrame:RemoveAllPinsByTemplate(template)
        assert(template=='PlayTheGameToolsDungeonLootMapPinTemplate')
        local pins={};for pin in pairs(activePins) do pins[#pins+1]=pin end
        for _,pin in ipairs(pins) do self:RemovePin(pin) end
    end
    local opens=0
    function ShowUIPanel(map) opens=opens+1;map:Show() end
    WorldMapFrame:SetScript('OnHide',function() if Map.provider then Map.provider:OnHide() end end)
    addon:SetModuleEnabled('dungeonLoot',true)
    addon:ToggleConfig();addon:SelectConfigPage('dungeonLoot')
    assert(Map:Open(target,'pickup'))
    assert(opens==1 and WorldMapFrame.mapID==1421 and #Map.lines==2 and Map.markers[1]:IsShown())
    local acquired=acquisitions
    Map.provider:RefreshAllData();Map.provider:OnCanvasSizeChanged()
    assert(acquisitions==acquired,'refresh reuses pins; no acquire/dirty-canvas feedback loop')
    local nativePin=Map.markers[1]
    assert(activePins[nativePin] and nativePin.frameLevelType=='PIN_FRAME_LEVEL_TOPMOST')
    WorldMapFrame.canvasScale=.5
    Map.provider:OnCanvasScaleChanged()
    assert(nativePin:GetScale()==2 and nativePin.points[1][4]==50 and nativePin.points[1][5]==-60,'native normalized positioning compensates zoom')
    WorldMapFrame.canvasScale=1;Map.provider:OnCanvasScaleChanged()
    assert(Map.lines[1].start[3]==100 and Map.lines[1].start[4]==-120)
    assert(Map.lines[1].finish[3]==200 and Map.lines[1].finish[4]==-180)
    assert(not addon.configWindow:IsShown(),'map is not hidden behind addon dialog')
    WorldMapFrame:Hide();assert(Map.target==nil and not Map.lines[1]:IsShown() and addon.configWindow:IsShown())
    testCombat=true
    local ok,reason=Map:Open(target,'pickup');assert(not ok and reason:find('combat') and opens==1)
    testCombat=false
    assert(Map:Open(target,'objective'));WorldMapFrame:SetMapID(1458)
    assert(#Map.markers==0 and not next(activePins) and not Map.lines[1]:IsShown(),'wrong-map pins released')
    WorldMapFrame:SetMapID(1421);assert(Map.lines[1]:IsShown())
    addon:SetModuleEnabled('dungeonLoot',false);assert(Map.target==nil and not Map.lines[1]:IsShown())
    addon:SetModuleEnabled('dungeonLoot',true)
    RAID_CLASS_COLORS={MAGE={r=.25,g=.78,b=.92}};LOCALIZED_CLASS_NAMES_MALE={MAGE='Mage'}
    ForeverDungeonJournal_NS={DB={['Shadowfang Keep']={bosses={},quests={{id=100002,name='Fixture Quest',
        classOnly='MAGE',faction='Both',pickup='Fixture Patrol',turnin='Fixture Finisher',note='Important acquisition note',
        objective='Find fixture',requires=10,rewardItems={}}}}},QUEST_PREREQ_CHAINS={[100002]={{id=100003,name='Prerequisite'}}}}
    addon.DungeonLootCatalog.Read=function() return ForeverDungeonJournal_NS end
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
            assert(slot.copyButton:IsShown() and slot.copyButton.label:GetText()=='Copy Coordinates')
            slot.copyButton:GetScript('OnClick')(slot.copyButton)
            assert(M.coordinateFrame:IsShown() and M.coordinateFrame.edit:GetText()=='Map 1421: 10.0, 20.0')
            assert(M.coordinateFrame.edit:HasFocus() and M.coordinateFrame.edit.highlighted)
            M.coordinateFrame.edit:GetScript('OnEscapePressed')()
            assert(not M.coordinateFrame:IsShown() and not M.coordinateFrame.edit:HasFocus())
        end
        assert(slot.mapKind~='objective','objective actions removed')
        if text=='Fixture Patrol' or text=='Patrol target' then
            assert(not slot.button.label:GetText():find('|c',1,true),'NPC subheader is solid text')
            assert(slot.headerGlow[1]:IsShown())
        end
        assert(slot.button.label.spacing==4 or slot.mapKind,'moderate line leading')
        assert(not text:lower():find('approx',1,true))
        assert(text~='Quest notes' and text~='Hide notes')
    end end
    assert(page.detailPane.slots[noteIndex].row:GetHeight()<28,'reduced prose row gaps')
    C_Map={GetMapInfo=function(id) assert(id==1421);return {name='Silverpine Forest'} end}
    M:ShowCoordinates(target)
    assert(M.coordinateFrame.edit:GetText()=='Silverpine Forest: 10.0, 20.0')
    M:SelectEntry('quest',1)
    assert(not M.coordinateFrame:IsShown() and not M.coordinateFrame.edit:HasFocus(),'selection clears stale coordinates')
    assert(noteIndex and objectiveIndex and noteIndex<objectiveIndex and mapButton)
    assert(page.quests.underline:IsShown() and not page.home.underline:IsShown())
    local accent=addon.InterfaceTheme.primary
    assert(page.quests.underline.gradient==nil and page.quests.underline.color[2]==accent[2],'solid accent tab underline')
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
    assert(addon.DungeonLootWidgets.Gradient==nil,'no per-letter gradient text')
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
    assert(pin:IsShown() and pin:GetWidth()==36 and pin.label=='Approximate location - Right Click to Hide Icon' )
    assert(pin.icon:GetWidth()==24 and pin.icon.points[1][1]=='CENTER')
    assert(pin.rim.gradient.minimum.r==159/255 and pin.rim.gradient.maximum.b==241/255)
    assert(activePins[pin] and pin:GetFrameLevel()==2200,'native manager supplies topmost pin level')
    pin:GetScript('OnMouseUp')(pin,'LeftButton',true);assert(Map.target)
    pin:GetScript('OnMouseUp')(pin,'RightButton',true)
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
        local beforeOpen=questQueries
        canvas:SetSize(0,0)
        assert(Map:Open(L:Targets(1098,'pickup')[1],'pickup'))
        assert(not pin:IsShown(),'wait for usable canvas dimensions')
        canvas=CreateFrame('Frame');canvas:SetSize(800,500)
        for _,fn in ipairs(pending) do fn() end;pending={}
        pin=Map.markers[1]
        assert(pin:IsShown() and pin:GetParent()==canvas and activePins[pin],'native pin rebinds replaced canvas after layout')
        assert(pin.points[1][4]==344 and pin.points[1][5]==-205,'settled canvas coordinates')
        Map:Dismiss()
        for _,fn in ipairs(pending) do fn() end;pending={}
        assert(not pin:IsShown())
        assert(questQueries==beforeOpen,'marker opening/rendering/dismissal never reads the quest log')
        WorldMapFrame:Hide() -- Reopening settings refreshes the dungeon card counts.
    end
    assert(nativeOpens==2)
    assert(Map:Open(L:Targets(1098,'pickup')[1],'pickup'))
    Map:Dismiss()
    for _,fn in ipairs(pending) do fn() end
    assert(not next(activePins) and #Map.markers==0,'queued callbacks cannot resurrect dismissed markers')
    C_Timer.After=timer
    C_XMLUtil={GetTemplateInfo=function() return nil end}
    local ok,reason=Map:Open(L:Targets(1098,'pickup')[1],'pickup')
    assert(not ok and reason:find('Restart WoW',1,true),'missing template cannot claim success')
    C_XMLUtil=nil
    local acquire=WorldMapFrame.AcquirePin
    WorldMapFrame.AcquirePin=function() error('fixture pin failure') end
    ok,reason=Map:Open(L:Targets(1098,'pickup')[1],'pickup')
    assert(not ok and reason:find('fixture pin failure',1,true) and M.mapStatus==reason,'render failure is actionable')
    assert(not next(activePins) and Map.target==nil)
    WorldMapFrame.AcquirePin=acquire

''')
print('PASS quest map pins, ordered patrol geometry, combat guards, cleanup, read-only source, notes, class/chain styling and toolbar anchors (mock only)')
