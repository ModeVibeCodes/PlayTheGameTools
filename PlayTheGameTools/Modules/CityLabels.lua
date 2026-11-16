local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- World map labels for trainers and town services. Locations come from the
-- bundled Efficient Games data (CityLabelsData.lua), with Classic spawn
-- positions (CityLabelsClassicData.lua) where Efficient Games has none yet.
-- Nothing is recorded or saved besides these display preferences. Drawing
-- lives in CityLabelsMap.lua.
local M={title="City Labels",category="qualityOfLife",defaultEnabled=false,
    configDescription="Trainers, banks, inns, flight masters and other services labeled on your world map."}
addon.CityLabels=M
addon:RegisterModule("cityLabels",M)

-- Trainers follow your character by default: Mine, All or Off.
M.MODES={
    {key="classTrainerMode",kind="classTrainer",label="Class Trainers"},
    {key="professionTrainerMode",kind="professionTrainer",label="Profession Trainers"},
}
M.MODE_CHOICES={{value="mine",label="Mine"},{value="all",label="All"},{value="off",label="Off"}}
-- Each setting shows one kind of label. Order is the settings page order.
M.CATEGORIES={
    {key="weaponMasters",kind="weaponMaster",label="Weapon Masters",default=true},
    {key="banks",kind="bank",label="Banks",default=true},
    {key="auctionHouses",kind="auctionHouse",label="Auction Houses",default=true},
    {key="inns",kind="inn",label="Inns",default=true},
    {key="flightMasters",kind="flightMaster",label="Flight Masters",default=true},
    {key="otherServices",kind="otherService",label="Guild & Transmog",default=true},
    {key="stableMasters",kind="stableMaster",label="Stable Masters",default=false},
    {key="mailboxes",kind="mailbox",label="Mailboxes",default=false},
    {key="repairs",kind="repair",label="Repair Vendors",default=false},
    {key="vendors",kind="vendor",label="Other Vendors",default=false},
}
M.FILTERS={
    {key="otherFaction",label="Other Faction",default=false},
    {key="showNames",label="Show Names",default=true},
}
-- The minimum stays 8 so sizes saved by the first release remain valid.
M.ranges={iconSize={8,32,1},fontSize={8,16,1}}
local DEFAULT_SIZES={iconSize=16,fontSize=11}

-- Standard game icons; the map falls back to a colored dot if one is missing.
local ICON="Interface\\Icons\\"
M.ICONS={
    weaponMaster={ICON.."INV_Sword_04"}, bank={ICON.."INV_Misc_Bag_07"},
    auctionHouse={ICON.."INV_Misc_Coin_02"}, inn={ICON.."INV_Misc_Rune_01"},
    flightMaster={ICON.."Ability_Mount_Wyvern_01",ICON.."Ability_Mount_Gryphon_01"},
    stableMaster={ICON.."Ability_Hunter_BeastTaming"}, mailbox={ICON.."INV_Letter_15",ICON.."INV_Letter_01"},
    repair={ICON.."INV_Hammer_20"}, vendor={ICON.."INV_Box_01"},
    ["Guild Master"]={ICON.."INV_Shirt_GuildTabard_01"}, Transmogrifier={ICON.."INV_Shirt_White_01"},
}
M.PROFESSION_ICONS={
    Alchemy="Trade_Alchemy",Blacksmithing="Trade_BlackSmithing",Enchanting="Trade_Engraving",
    Engineering="Trade_Engineering",Herbalism="Spell_Nature_NatureTouchGrow",Leatherworking="INV_Misc_ArmorKit_17",
    Mining="Trade_Mining",Skinning="INV_Misc_Pelt_Wolf_01",Tailoring="Trade_Tailoring",Cooking="INV_Misc_Food_15",
    ["First Aid"]="Spell_Holy_SealOfSacrifice",Fishing="Trade_Fishing",
}
-- Native skill-line IDs, as Quick Access and Camp Contributions read them.
M.SKILL_LINES={[171]="Alchemy",[164]="Blacksmithing",[333]="Enchanting",[202]="Engineering",[182]="Herbalism",
    [165]="Leatherworking",[186]="Mining",[393]="Skinning",[197]="Tailoring",[185]="Cooking",[129]="First Aid",[356]="Fishing"}
-- Kinds whose map text would only repeat the icon's meaning everywhere.
M.ICON_ONLY={mailbox=true}

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local MODE_VALUES={mine=true,all=true,off=true}

-- Pure defaults and validation; profile validation runs this on detached copies.
-- The first release saved classTrainers/allClasses/professionTrainers switches:
-- they seed the trainer modes once and are otherwise kept but unread.
function M.Initialize(db)
    if db.classTrainerMode==nil then
        db.classTrainerMode=db.classTrainers==false and "off" or db.allClasses==true and "all" or "mine"
    end
    if db.professionTrainerMode==nil then
        db.professionTrainerMode=db.professionTrainers==false and "off" or "mine"
    end
    for _,mode in ipairs(M.MODES) do
        assert(type(db[mode.key])=="string" and MODE_VALUES[db[mode.key]],"Invalid City Labels setting: "..mode.key)
    end
    for _,group in ipairs({M.CATEGORIES,M.FILTERS}) do
        for _,entry in ipairs(group) do
            if db[entry.key]==nil then db[entry.key]=entry.default end
            assert(type(db[entry.key])=="boolean","Invalid City Labels setting: "..entry.key)
        end
    end
    for key,range in pairs(M.ranges) do
        if db[key]==nil then db[key]=DEFAULT_SIZES[key] end
        local v=db[key]
        assert(type(v)=="number" and v>=range[1] and v<=range[2] and v%range[3]==0,"Invalid City Labels setting: "..key)
    end
end

local booleans,modes={}, {}
for _,group in ipairs({M.CATEGORIES,M.FILTERS}) do for _,entry in ipairs(group) do booleans[entry.key]=true end end
for _,mode in ipairs(M.MODES) do modes[mode.key]=true end
local kindSetting={}
for _,entry in ipairs(M.CATEGORIES) do kindSetting[entry.kind]=entry.key end
M.kindSetting=kindSetting

function M:SetOption(key,value)
    if booleans[key] then
        if type(value)~="boolean" then return false end
    elseif modes[key] then
        if not MODE_VALUES[value] then return false end
    elseif M.ranges[key] then
        local range=M.ranges[key]
        if type(value)~="number" then return false end
        value=math.max(range[1],math.min(range[2],math.floor(value/range[3]+0.5)*range[3]))
    else
        return false
    end
    self.db[key]=value
    self:Refresh()
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

-- Faction and class decide which rows apply; unreadable values show everything
-- rather than guessing.
function M:Player()
    local faction,class
    if type(UnitFactionGroup)=="function" then
        local ok,value=pcall(UnitFactionGroup,"player")
        if ok and Public(value) and (value=="Alliance" or value=="Horde") then faction=value:sub(1,1) end
    end
    if type(UnitClass)=="function" then
        local ok,_,token=pcall(UnitClass,"player")
        if ok and Public(token) and type(token)=="string" then class=token end
    end
    return faction,class
end

-- Learned professions by English name, with their native icons. Read through
-- the shared Quick Access reader (outside combat only); the last good read is
-- kept for combat. nil means never read: every profession trainer then shows.
function M:Professions()
    local D=addon.ForeverQuickAccessData
    if D and D.OutsideCombat() then
        local list=D.ReadProfessions()
        if list then
            local known={}
            for _,profession in ipairs(list) do
                local name=M.SKILL_LINES[profession.id]
                if name then known[name]=profession.icon end
            end
            self.professions=known
        end
    end
    return self.professions
end

function M:Icons(kind,label,class,known)
    local icons={}
    if kind=="classTrainer" and type(class)=="string" then
        icons[1]=ICON.."ClassIcon_"..class:sub(1,1)..class:sub(2):lower()
    elseif kind=="professionTrainer" then
        if known and known[label] then icons[#icons+1]=known[label] end
        if M.PROFESSION_ICONS[label] then icons[#icons+1]=ICON..M.PROFESSION_ICONS[label] end
    else
        for _,path in ipairs(M.ICONS[label] or M.ICONS[kind] or {}) do icons[#icons+1]=path end
    end
    return icons
end

local function Wanted(db,kind,label,token,class,known)
    if kind=="classTrainer" then
        local mode=db.classTrainerMode
        return mode=="all" or mode=="mine" and (not class or token==class)
    elseif kind=="professionTrainer" then
        local mode=db.professionTrainerMode
        return mode=="all" or mode=="mine" and (not known or known[label]~=nil)
    end
    return db[kindSetting[kind]]==true
end

-- Rows are { kind, x, y, label, names, side, class }; returns fresh tables.
-- Classic rows come second and are marked, so tooltips can say so.
function M:Entries(mapID)
    local out={}
    if not Public(mapID) or type(mapID)~="number" then return out end
    local db=self.db
    local faction,class=self:Player()
    local known=db.professionTrainerMode=="mine" and self:Professions() or self.professions
    for _,source in ipairs({addon.CityLabelsData,addon.CityLabelsClassicData}) do
        local classic=source==addon.CityLabelsClassicData
        for _,row in ipairs(source and source.maps[mapID] or {}) do
            local kind,label,side,token=row[1],row[4],row[6],row[7]
            if Wanted(db,kind,label,token,class,known) and (db.otherFaction or not side or not faction or side==faction) then
                out[#out+1]={kind=kind,x=row[2],y=row[3],label=label,names=row[5],side=side,class=token,classic=classic,
                    icons=self:Icons(kind,label,token,known),showName=db.showNames and not M.ICON_ONLY[kind]}
            end
        end
    end
    return out
end

function M:Refresh()
    if addon.CityLabelsMap then addon.CityLabelsMap:Refresh() end
end

function M:OnInitialize()
    self.Initialize(self.db)
end

function M:OnEnable()
    self.active=true
    addon.CityLabelsMap:Attach()
    self:Refresh()
end

function M:OnDisable()
    self.active=false
    -- The provider stays registered with the map but draws nothing.
    addon.CityLabelsMap:Clear()
end
