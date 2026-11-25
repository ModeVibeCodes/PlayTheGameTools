"""Map Labels: bundled data, trainer modes, icons, map provider lifecycle and settings (mock only).

The map canvas below models the inspected Forever Blizzard_MapCanvas contract
(AcquirePin/RemoveAllPinsByTemplate, data provider callbacks); it is not proof
of native rendering, icon availability or profession API behavior.
"""
import re
from smoke import load, ROOT

data = (ROOT / 'PlayTheGameTools/Modules/CityLabelsData.lua').read_text(encoding='utf-8')
assert 'Data from Efficient Games (https://efficient.games), licensed under CC BY 4.0' in data
assert re.search(r'eg-link-output-wowf at [0-9a-f]{40}', data), 'source commit recorded'
assert 'Changed:' in data, 'CC BY 4.0 change notice'
classic = (ROOT / 'PlayTheGameTools/Modules/CityLabelsClassicData.lua').read_text(encoding='utf-8')
assert re.search(r'cmangos/classic-db\)\n-- at [0-9a-f]{40}', classic) and 'GPL-3.0' in classic and 'Changed:' in classic
for path in ('THIRD_PARTY_NOTICES.md', 'PlayTheGameTools/THIRD_PARTY_NOTICES.md'):
    notices = (ROOT / path).read_text(encoding='utf-8')
    assert 'Efficient Games' in notices and 'CC BY 4.0' in notices, path
    assert 'CMaNGOS classic-db' in notices and 'GPL-3.0' in notices, path

lua, _ = load()
lua.execute('''
    local M,Map,D,C=addon.CityLabels,addon.CityLabelsMap,addon.CityLabelsData,addon.CityLabelsClassicData
    assert(M and Map and D and C and M.title=='Map Labels' and M.category=='qualityOfLife')
    assert(not M.enabled and addon.db.modules.cityLabels.enabled==false,'opt-in')
    -- Every bundled row is well formed and uses a known kind.
    local kinds={};for _,c in ipairs(M.CATEGORIES) do kinds[c.kind]=true end
    for _,m in ipairs(M.MODES) do kinds[m.kind]=true end
    local rows={}
    for name,source in pairs({data=D,classic=C}) do
        rows[name]=0
        for mapID,list in pairs(source.maps) do
            assert(type(mapID)=='number' and mapID>0)
            for _,row in ipairs(list) do
                rows[name]=rows[name]+1
                assert(kinds[row[1]],'known kind '..tostring(row[1]))
                assert(row[2]>=0 and row[2]<=1 and row[3]>=0 and row[3]<=1,'normalized position')
                assert(type(row[4])=='string' and row[4]~='' and type(row[5])=='string')
                assert(row[6]==nil or row[6]=='A' or row[6]=='H')
                assert((row[1]=='classTrainer')==(row[7]~=nil),'only class trainers carry a class')
                if row[1]=='professionTrainer' then assert(M.PROFESSION_ICONS[row[4]],'profession label '..row[4]) end
            end
        end
    end
    assert(rows.data>100 and rows.classic>100 and D.maps[1453] and D.maps[1454],'both sources bundled')
    -- The reported Undercity gaps: gossip-only alchemists and unrecorded warlock trainers.
    local function Has(source,mapID,label) for _,row in ipairs(source.maps[mapID] or {}) do if row[4]==label then return row end end end
    assert(Has(D,1458,'Alchemy'),'Undercity alchemy trainer recorded through its gossip window')
    local warlock=Has(C,1458,'Warlock Trainer')
    assert(warlock and warlock[7]=='WARLOCK' and warlock[2]>.8 and warlock[3]<.2,'Undercity warlock trainers from Classic positions')

    -- Defaults, validation and first-release settings.
    local db=M.db
    assert(db.classTrainerMode=='mine' and db.professionTrainerMode=='mine','trainers follow your character by default')
    assert(db.banks and not db.mailboxes and not db.vendors and db.showNames and db.iconSize==16 and db.fontSize==11)
    assert(not M:SetOption('banks','yes') and not M:SetOption('unknown',true) and not M:SetOption('classTrainerMode','some'))
    assert(M:SetOption('iconSize',99) and db.iconSize==32,'clamped')
    assert(M:SetOption('iconSize',16))
    for _,case in ipairs({{{},'mine','mine'},{{classTrainers=false,professionTrainers=false},'off','off'},
        {{classTrainers=true,allClasses=true,professionTrainers=true},'all','mine'},{{iconSize=8,allClasses=false},'mine','mine'}}) do
        local old=case[1];M.Initialize(old)
        assert(old.classTrainerMode==case[2] and old.professionTrainerMode==case[3],'first-release switches seed the modes')
    end
    local V=addon.ProfileValidation
    assert(V:Validate({modules={cityLabels={iconSize=3}}})==nil,'out-of-range profile value rejected')
    assert(V:Validate({modules={cityLabels={classTrainerMode='bad'}}})==nil,'unknown mode rejected')
    assert(V:Validate({modules={cityLabels={banks=false,classTrainers=false}}}).modules.cityLabels.classTrainerMode=='off')

    -- Filters: faction, class mode, profession mode, categories.
    function UnitFactionGroup() return 'Alliance' end
    function UnitClass() return 'Mage','MAGE',8 end
    local professions={{'Alchemy',136240,50,75,0,0,171}}
    function GetProfessions() return professions[1] and 1 or nil,nil,nil,nil,nil end
    function GetProfessionInfo(i) return unpack(professions[i]) end
    D.maps[999999]={
        {'bank',.5,.5,'Bank','Banker A','A'},{'bank',.6,.6,'Bank','Banker H','H'},
        {'classTrainer',.1,.1,'Mage Trainer','M - Mage Trainer','A','MAGE'},
        {'classTrainer',.2,.2,'Rogue Trainer','R - Rogue Trainer','A','ROGUE'},
        {'professionTrainer',.25,.25,'Alchemy','Al - Alchemist','A'},
        {'professionTrainer',.26,.26,'Mining','Mi - Miner','A'},
        {'mailbox',.3,.3,'Mailbox',''},{'inn',.4,.4,'Inn','Innkeeper'},
    }
    C.maps[999999]={{'classTrainer',.7,.7,'Mage Trainer','Classic Mage - Mage Trainer','A','MAGE'}}
    local function Labels(list) local out={};for _,e in ipairs(list) do out[#out+1]=e.label end;table.sort(out);return table.concat(out,',') end
    assert(Labels(M:Entries(999999))=='Alchemy,Bank,Inn,Mage Trainer,Mage Trainer','your class, your professions, your faction')
    local mine=M:Entries(999999)
    for _,e in ipairs(mine) do
        if e.label=='Alchemy' then assert(e.icons[1]==136240 and e.icons[2]=='Interface\\\\Icons\\\\Trade_Alchemy','native profession icon first') end
        if e.kind=='classTrainer' then assert(e.icons[1]=='Interface\\\\Icons\\\\ClassIcon_Mage') end
        if e.kind=='bank' then assert(e.icons[1]=='Interface\\\\Icons\\\\INV_Misc_Bag_07' and not e.classic) end
    end
    assert(mine[#mine].classic and mine[#mine].names=='Classic Mage - Mage Trainer','Classic rows come after and are marked')
    db.classTrainerMode='all';db.professionTrainerMode='all';db.otherFaction=true;db.mailboxes=true
    assert(Labels(M:Entries(999999))=='Alchemy,Bank,Bank,Inn,Mage Trainer,Mage Trainer,Mailbox,Mining,Rogue Trainer')
    for _,e in ipairs(M:Entries(999999)) do assert(e.showName==(e.kind~='mailbox'),'mailboxes are icon only') end
    db.classTrainerMode='off';db.professionTrainerMode='off';db.otherFaction=false;db.mailboxes=false;db.inns=false
    assert(Labels(M:Entries(999999))=='Bank')
    db.classTrainerMode='mine';db.professionTrainerMode='mine';db.inns=true
    -- Professions read outside combat are kept for combat; a new one appears once learned.
    testCombat=true;professions[2]={'Mining',136248,1,75,0,0,186}
    function GetProfessions() return 1,2,nil,nil,nil end
    assert(not Labels(M:Entries(999999)):find('Mining'),'combat keeps the last read')
    testCombat=false
    assert(Labels(M:Entries(999999)):find('Mining'),'learned profession shows after combat')
    -- Never read (or unreadable) professions show every profession trainer rather than guessing.
    M.professions=nil;GetProfessions=nil
    assert(Labels(M:Entries(999999))=='Alchemy,Bank,Inn,Mage Trainer,Mage Trainer,Mining')
    GetProfessions=function() return 1,nil,nil,nil,nil end;table.remove(professions,2)
    UnitFactionGroup=function() error('unreadable') end
    assert(#M:Entries(999999)==6,'unknown faction shows both sides rather than guessing')
    function UnitFactionGroup() return 'Alliance' end
    assert(#M:Entries(123)==0 and #M:Entries(nil)==0)
    local entries=M:Entries(999999);entries[1].x=9
    assert(D.maps[999999][1][2]==.5,'entries are copies')

    -- Enabling before the map addon loads waits for it; nothing is force-loaded.
    C_AddOns.LoadAddOn=function() error('Map Labels must not force-load the map') end
    WorldMapFrame=nil
    addon:SetModuleEnabled('cityLabels',true)
    assert(M.active and not Map.provider and Map.events.events.ADDON_LOADED)

    -- Model the native map canvas.
    local canvas=CreateFrame('Frame');canvas:SetSize(1000,600)
    local map=CreateFrame('Frame');map:Hide()
    function map:GetCanvas() return canvas end
    function map:GetMapID() return self.mapID end
    function map:SetMapID(id) self.mapID=id;if self:IsShown() then for p in pairs(self.providers) do p:RefreshAllData() end end end
    map.providers={}
    function map:AddDataProvider(p) self.providers[p]=true;p:OnAdded(self);if self:IsShown() then p:RefreshAllData() end end
    MapCanvasDataProviderMixin={OnAdded=function(self,m) self.owningMap=m end}
    function CreateFromMixins(base) local c={};for k,v in pairs(base) do c[k]=v end;return c end
    MapCanvasPinMixin={OnReleased=function(self) self.released=(self.released or 0)+1 end,
        SetIgnoreGlobalPinScale=function(self,v) self.ignoreGlobalPinScale=v end,
        SetScalingLimits=function(self,...) self.scalingLimits={...} end,
        UseFrameLevelType=function(self,v) self.frameLevelType=v end,
        SetPosition=function(self,x,y) self.normalizedX,self.normalizedY=x,y end,
        ApplyCurrentScale=function(self) self.scaled=true end,
        -- Native base calls SetPassThroughButtons, which the game blocks in combat.
        CheckMouseButtonPassthrough=function() assert(not testCombat,'blocked: SetPassThroughButtons in combat') end}
    local active,acquired={},0
    function map:AcquirePin(template,...)
        assert(template=='PlayTheGameToolsCityLabelsMapPinTemplate')
        local pin=CreateFrame('Frame',nil,canvas)
        for k,v in pairs(PlayTheGameToolsCityLabelsMapPinMixin) do pin[k]=v end
        pin.pinTemplate=template;pin:OnLoad();pin:Show();pin:OnAcquired(...)
        pin:CheckMouseButtonPassthrough('RightButton')
        active[pin]=true;acquired=acquired+1
        return pin
    end
    function map:RemoveAllPinsByTemplate(template)
        assert(template=='PlayTheGameToolsCityLabelsMapPinTemplate')
        for pin in pairs(active) do pin:Hide();pin:OnReleased();active[pin]=nil end
    end
    local function Count() local n=0;for _ in pairs(active) do n=n+1 end;return n end
    local function Find(label,classic) for pin in pairs(active) do if pin.entry.label==label and (classic==nil or pin.entry.classic==classic) then return pin end end end

    -- Map addon loads during combat: attach waits for combat to end.
    WorldMapFrame=map;testCombat=true
    FireEvent('ADDON_LOADED','Blizzard_WorldMap')
    assert(not Map.provider and Map.events.events.PLAYER_REGEN_ENABLED,'no map provider changes in combat')
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    assert(Map.provider and map.providers[Map.provider] and not next(Map.events.events),'attached once out of combat')

    -- Showing a map draws its labels: an icon in a service-colored edge.
    map:Show();map:SetMapID(999999)
    assert(Count()==5,'Alchemy, Bank, Inn and two Mage Trainers: '..tostring(Map.lastError))
    local bank=Find('Bank')
    assert(bank.normalizedX==.5 and bank.normalizedY==.5 and bank:GetWidth()==16)
    assert(bank.text:GetText()=='Bank' and bank.text:IsShown() and bank.ignoreGlobalPinScale and bank.scaled)
    assert(bank.frameLevelType=='PIN_FRAME_LEVEL_AREA_POI')
    assert(bank.icon:IsShown() and bank.icon.texture=='Interface\\\\Icons\\\\INV_Misc_Bag_07' and not bank.dot:IsShown())
    local c=Map.COLORS.bank;assert(bank.edge:IsShown() and bank.edge.vertexColor[1]==c[1] and bank.edge.vertexColor[3]==c[3])
    assert(Find('Alchemy').icon.texture==136240,'your own profession icon')
    -- A missing icon file falls back to the next one, then to the colored dot.
    testMissingTextures={['Interface\\\\Icons\\\\INV_Misc_Bag_07']=true,['Interface\\\\Icons\\\\ClassIcon_Mage']=true}
    RAID_CLASS_COLORS={MAGE={r=.25,g=.78,b=.92}}
    M:SetOption('fontSize',14)
    bank=Find('Bank');local mage=Find('Mage Trainer',false)
    assert(not bank.icon:IsShown() and not bank.edge:IsShown() and bank.dot:IsShown() and bank.dot.vertexColor[1]==c[1])
    assert(mage.dot:IsShown() and mage.dot.vertexColor[1]==.25,'class trainers use class colors')
    testMissingTextures=nil;M:Refresh()
    -- Tooltip lists who is there and credits the right source.
    local lines={}
    GameTooltip={SetOwner=function(self,o) self.owner=o end,SetText=function(_,t) lines[#lines+1]=t end,
        AddLine=function(_,t) lines[#lines+1]=t end,Show=function(self) self.shown=true end,
        Hide=function(self) self.shown=false end,IsShown=function(self) return self.shown end,GetOwner=function(self) return self.owner end}
    Find('Mage Trainer',false):OnMouseEnter()
    assert(lines[1]=='Mage Trainer' and lines[2]=='M - Mage Trainer' and lines[#lines]:find('Efficient Games',1,true))
    lines={};Find('Mage Trainer',true):OnMouseEnter()
    assert(lines[2]=='Classic Mage - Mage Trainer' and lines[3]:find('Classic position',1,true) and lines[#lines]:find('CMaNGOS',1,true))

    -- Settings redraw the open map; names can be hidden.
    M:SetOption('showNames',false)
    assert(Count()==5 and not Find('Bank').text:IsShown())
    M:SetOption('banks',false);assert(Count()==4 and not Find('Bank'))
    M:SetOption('banks',true);M:SetOption('showNames',true)
    M:SetOption('classTrainerMode','off');assert(Count()==3 and not Find('Mage Trainer'))
    M:SetOption('classTrainerMode','mine')
    map:SetMapID(424242);assert(Count()==0,'unlabeled map clears our pins')
    map:SetMapID(999999);assert(Count()==5)
    -- Opening or changing the map in combat redraws without restricted calls.
    testCombat=true;map:SetMapID(424242);map:SetMapID(999999)
    assert(Count()==5 and Map.lastError==nil,'combat redraw: '..tostring(Map.lastError));testCombat=false

    -- Disabling clears pins and later refreshes draw nothing; re-enable redraws.
    Find('Bank'):OnMouseEnter();assert(GameTooltip.shown)
    addon:SetModuleEnabled('cityLabels',false)
    assert(Count()==0 and not GameTooltip.shown and Map.provider)
    map:SetMapID(999999);assert(Count()==0)
    addon:SetModuleEnabled('cityLabels',true);assert(Count()==5)

    -- A drawing failure is reported and does not break the map.
    local acquire=map.AcquirePin
    map.AcquirePin=function() error('fixture pin failure') end
    local printed=#messages
    assert(Map:RefreshAllData()==false and Map.lastError:find('fixture pin failure',1,true))
    Map:RefreshAllData();assert(#messages==printed+1,'reported once')
    map.AcquirePin=acquire;assert(Map:RefreshAllData() and Map.lastError==nil and Count()==5)

    -- Settings page: every control is present and drives the saved setting.
    addon:ToggleConfig();addon:SelectConfigPage('cityLabels')
    local page=M.page
    for _,group in ipairs({M.CATEGORIES,M.FILTERS}) do
        for _,entry in ipairs(group) do assert(page.cityLabelControls[entry.key].label:GetText()==entry.label) end
    end
    -- Services are one wrapping row of chips, one per saved key (plus Other
    -- Faction); Show Names stays a switch under Appearance.
    local chips=page.cityLabelControls.mailboxes:GetParent()
    for _,entry in ipairs(M.CATEGORIES) do assert(page.cityLabelControls[entry.key]:GetParent()==chips and page.cityLabelControls[entry.key].mark,'chip: '..entry.key) end
    assert(page.cityLabelControls.otherFaction:GetParent()==chips and page.cityLabelControls.showNames.frame,'Other Faction is a chip, Show Names a switch')
    assert(#chips.row.settingsChips==#M.CATEGORIES+1,'eleven service chips')
    assert(not page.cityLabelControls.mailboxes.selected and M.db.mailboxes==false)
    page.cityLabelControls.mailboxes.scripts.OnClick()
    assert(M.db.mailboxes==true and page.cityLabelControls.mailboxes.selected,'a chip drives its saved key')
    page.cityLabelControls.banks.scripts.OnClick();assert(M.db.banks==false and not page.cityLabelControls.banks.selected)
    page.cityLabelControls.banks.scripts.OnClick();assert(M.db.banks==true)
    local found
    for _,result in ipairs(addon:SearchSettings('Mailboxes')) do if result.entry and result.entry.row==chips.row then found=true end end
    assert(found,'search finds a chip and flashes its row')
    local professionButtons=page.cityLabelModes.professionTrainerMode
    assert(#professionButtons==3 and professionButtons[1].label:GetText()=='Mine' and professionButtons[1].selected)
    professionButtons[2].scripts.OnClick();page:Refresh()
    assert(M.db.professionTrainerMode=='all' and professionButtons[2].selected and not professionButtons[1].selected)
    page.cityLabelModes.classTrainerMode[3].scripts.OnClick()
    assert(M.db.classTrainerMode=='off')
    assert(page.cityLabelSource:GetText()==M.SOURCE_LINE and M.SOURCE_LINE=='Locations: Efficient Games (CC BY 4.0), with CMaNGOS classic-db (GPL-3.0) where none is recorded yet.')
    M.db.vendors=false
''')
reloaded, _ = load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
reloaded.execute('''
    local M=addon.CityLabels
    assert(M.enabled and M.db.mailboxes==true and M.db.fontSize==14 and M.db.showNames==true,'preferences persist')
    assert(M.db.professionTrainerMode=='all' and M.db.classTrainerMode=='off','trainer modes persist')
''')
# Settings saved by the first release (switches, 12px dots) load unchanged and seed the modes.
first, _ = load(before='''
    PTGToolsDB={modules={cityLabels={enabled=true,classTrainers=true,allClasses=true,professionTrainers=true,iconSize=12,banks=false}}}
''')
first.execute('''
    local db=addon.CityLabels.db
    assert(addon.CityLabels.enabled and db.classTrainerMode=='all' and db.professionTrainerMode=='mine')
    assert(db.iconSize==12 and db.banks==false and db.classTrainers==true and db.allClasses==true,'saved values kept')
''')
print('PASS Map Labels data/attribution (Efficient Games + CMaNGOS), Undercity gaps, Mine/All/Off trainer modes with profession detection, '
      'icons with fallback, Classic tooltip, first-release settings, combat-safe map attach, settings and persistence (mock only)')
