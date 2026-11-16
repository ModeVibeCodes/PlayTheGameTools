"""City Labels: bundled data, filters, map provider lifecycle and settings (mock only).

The map canvas below models the inspected Forever Blizzard_MapCanvas contract
(AcquirePin/RemoveAllPinsByTemplate, data provider callbacks); it is not proof
of native rendering.
"""
import re
from smoke import load, ROOT

data = (ROOT / 'PlayTheGameTools/Modules/CityLabelsData.lua').read_text(encoding='utf-8')
assert 'Data from Efficient Games (https://efficient.games), licensed under CC BY 4.0' in data
assert re.search(r'eg-link-output-wowf at [0-9a-f]{40}', data), 'source commit recorded'
assert 'Changed:' in data, 'CC BY 4.0 change notice'
notices = (ROOT / 'THIRD_PARTY_NOTICES.md').read_text(encoding='utf-8')
assert 'Efficient Games' in notices and 'CC BY 4.0' in notices
assert (ROOT / 'PlayTheGameTools/THIRD_PARTY_NOTICES.md').read_text(encoding='utf-8').count('Efficient Games') >= 1

lua, _ = load()
lua.execute('''
    local M,Map,D=addon.CityLabels,addon.CityLabelsMap,addon.CityLabelsData
    assert(M and Map and D and M.title=='City Labels' and M.category=='qualityOfLife')
    assert(not M.enabled and addon.db.modules.cityLabels.enabled==false,'opt-in')
    -- Every bundled row is well formed and uses a known kind.
    local kinds={};for _,c in ipairs(M.CATEGORIES) do kinds[c.kind]=true end
    local rows=0
    for mapID,list in pairs(D.maps) do
        assert(type(mapID)=='number' and mapID>0)
        for _,row in ipairs(list) do
            rows=rows+1
            assert(kinds[row[1]],'known kind '..tostring(row[1]))
            assert(row[2]>=0 and row[2]<=1 and row[3]>=0 and row[3]<=1,'normalized position')
            assert(type(row[4])=='string' and row[4]~='' and type(row[5])=='string')
            assert(row[6]==nil or row[6]=='A' or row[6]=='H')
            assert((row[1]=='classTrainer')==(row[7]~=nil),'only class trainers carry a class')
        end
    end
    assert(rows>100 and D.maps[1453] and D.maps[1454],'Stormwind and Orgrimmar labels bundled')

    -- Defaults and validation.
    assert(M.db.classTrainers and M.db.banks and not M.db.mailboxes and not M.db.vendors and M.db.showNames)
    assert(M.db.iconSize==12 and M.db.fontSize==11)
    assert(not M:SetOption('banks','yes') and not M:SetOption('unknown',true))
    assert(M:SetOption('iconSize',99) and M.db.iconSize==24,'clamped')
    assert(M:SetOption('iconSize',12))
    local V=addon.ProfileValidation
    local profile=V:Validate({modules={cityLabels={iconSize=3}}})
    assert(profile==nil,'out-of-range profile value rejected')
    assert(V:Validate({modules={cityLabels={banks=false}}}).modules.cityLabels.banks==false)

    -- Filters: faction, own class, categories.
    function UnitFactionGroup() return 'Alliance' end
    function UnitClass() return 'Mage','MAGE',8 end
    D.maps[999999]={
        {'bank',.5,.5,'Bank','Banker A','A'},{'bank',.6,.6,'Bank','Banker H','H'},
        {'classTrainer',.1,.1,'Mage Trainer','M - Mage Trainer','A','MAGE'},
        {'classTrainer',.2,.2,'Rogue Trainer','R - Rogue Trainer','A','ROGUE'},
        {'mailbox',.3,.3,'Mailbox',''},{'inn',.4,.4,'Inn','Innkeeper'},
    }
    local function Labels(list) local out={};for _,e in ipairs(list) do out[#out+1]=e.label end;table.sort(out);return table.concat(out,',') end
    assert(Labels(M:Entries(999999))=='Bank,Inn,Mage Trainer','own faction, own class, mailboxes off')
    M.db.allClasses=true;M.db.otherFaction=true;M.db.mailboxes=true
    assert(Labels(M:Entries(999999))=='Bank,Bank,Inn,Mage Trainer,Mailbox,Rogue Trainer')
    for _,e in ipairs(M:Entries(999999)) do assert(e.showName==(e.kind~='mailbox'),'mailboxes are dots only') end
    M.db.allClasses=false;M.db.otherFaction=false;M.db.mailboxes=false;M.db.inns=false
    assert(Labels(M:Entries(999999))=='Bank,Mage Trainer')
    M.db.inns=true
    UnitFactionGroup=function() error('unreadable') end
    assert(#M:Entries(999999)==4,'unknown faction shows both sides rather than guessing')
    function UnitFactionGroup() return 'Alliance' end
    assert(#M:Entries(123)==0 and #M:Entries(nil)==0)
    local entries=M:Entries(999999);entries[1].x=9
    assert(D.maps[999999][1][2]==.5,'entries are copies')

    -- Enabling before the map addon loads waits for it; nothing is force-loaded.
    C_AddOns.LoadAddOn=function() error('City Labels must not force-load the map') end
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
        ApplyCurrentScale=function(self) self.scaled=true end}
    local active,acquired={},0
    function map:AcquirePin(template,...)
        assert(template=='PlayTheGameToolsCityLabelsMapPinTemplate')
        local pin=CreateFrame('Frame',nil,canvas)
        for k,v in pairs(PlayTheGameToolsCityLabelsMapPinMixin) do pin[k]=v end
        pin.pinTemplate=template;pin:OnLoad();pin:Show();pin:OnAcquired(...)
        active[pin]=true;acquired=acquired+1
        return pin
    end
    function map:RemoveAllPinsByTemplate(template)
        assert(template=='PlayTheGameToolsCityLabelsMapPinTemplate')
        for pin in pairs(active) do pin:Hide();pin:OnReleased();active[pin]=nil end
    end
    local function Count() local n=0;for _ in pairs(active) do n=n+1 end;return n end
    local function Find(label) for pin in pairs(active) do if pin.entry.label==label then return pin end end end

    -- Map addon loads during combat: attach waits for combat to end.
    WorldMapFrame=map;testCombat=true
    FireEvent('ADDON_LOADED','Blizzard_WorldMap')
    assert(not Map.provider and Map.events.events.PLAYER_REGEN_ENABLED,'no map provider changes in combat')
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    assert(Map.provider and map.providers[Map.provider] and not next(Map.events.events),'attached once out of combat')

    -- Showing a map draws its labels with the saved style.
    map:Show();map:SetMapID(999999)
    assert(Count()==3,'Bank, Inn and Mage Trainer: '..tostring(Map.lastError))
    local bank=Find('Bank')
    assert(bank.normalizedX==.5 and bank.normalizedY==.5 and bank:GetWidth()==12)
    assert(bank.text:GetText()=='Bank' and bank.text:IsShown() and bank.ignoreGlobalPinScale and bank.scaled)
    assert(bank.frameLevelType=='PIN_FRAME_LEVEL_AREA_POI')
    local c=Map.COLORS.bank;assert(bank.dot.vertexColor[1]==c[1] and bank.dot.vertexColor[3]==c[3])
    RAID_CLASS_COLORS={MAGE={r=.25,g=.78,b=.92}}
    M:SetOption('fontSize',14)
    local mage=Find('Mage Trainer')
    assert(mage.dot.vertexColor[1]==.25,'class trainers use class colors')
    -- Tooltip lists who is there and credits the data.
    local lines={}
    GameTooltip={SetOwner=function(self,o) self.owner=o end,SetText=function(_,t) lines[#lines+1]=t end,
        AddLine=function(_,t) lines[#lines+1]=t end,Show=function(self) self.shown=true end,
        Hide=function(self) self.shown=false end,IsShown=function(self) return self.shown end,GetOwner=function(self) return self.owner end}
    mage:OnMouseEnter()
    assert(lines[1]=='Mage Trainer' and lines[2]=='M - Mage Trainer' and lines[#lines]:find('Efficient Games',1,true))

    -- Settings redraw the open map; names can be hidden.
    M:SetOption('showNames',false)
    assert(Count()==3 and not Find('Bank').text:IsShown())
    M:SetOption('banks',false);assert(Count()==2 and not Find('Bank'))
    M:SetOption('banks',true);M:SetOption('showNames',true)
    map:SetMapID(424242);assert(Count()==0,'unlabeled map clears our pins')
    map:SetMapID(999999);assert(Count()==3)

    -- Disabling clears pins and later refreshes draw nothing; re-enable redraws.
    Find('Bank'):OnMouseEnter();assert(GameTooltip.shown)
    addon:SetModuleEnabled('cityLabels',false)
    assert(Count()==0 and not GameTooltip.shown and Map.provider)
    map:SetMapID(999999);assert(Count()==0)
    addon:SetModuleEnabled('cityLabels',true);assert(Count()==3)

    -- A drawing failure is reported and does not break the map.
    local acquire=map.AcquirePin
    map.AcquirePin=function() error('fixture pin failure') end
    local printed=#messages
    assert(Map:RefreshAllData()==false and Map.lastError:find('fixture pin failure',1,true))
    Map:RefreshAllData();assert(#messages==printed+1,'reported once')
    map.AcquirePin=acquire;assert(Map:RefreshAllData() and Map.lastError==nil and Count()==3)

    -- Settings page: every control is present and drives the saved setting.
    addon:ToggleConfig();addon:SelectConfigPage('cityLabels')
    local page=M.page
    for _,group in ipairs({M.CATEGORIES,M.FILTERS}) do
        for _,entry in ipairs(group) do assert(page.cityLabelControls[entry.key].label:GetText()==entry.label) end
    end
    page.cityLabelControls.mailboxes.frame.scripts.OnClick()
    assert(M.db.mailboxes==true and page.cityLabelControls.mailboxes.button.selected)
    assert(page.cityLabelSource:GetText():find('CC BY 4.0',1,true))
    M.db.vendors=false
''')
reloaded, _ = load(lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
reloaded.execute('''
    local M=addon.CityLabels
    assert(M.enabled and M.db.mailboxes==true and M.db.fontSize==14 and M.db.showNames==true,'preferences persist')
''')
print('PASS City Labels data/attribution, faction/class/category filters, deferred and combat-safe map attach, pins, tooltip credit, disable/redraw, failure reporting, settings and persistence (mock only)')
