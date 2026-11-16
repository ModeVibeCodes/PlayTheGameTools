local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- World map labels for trainers and town services. Locations come from the
-- bundled Efficient Games data (CityLabelsData.lua); nothing is recorded or
-- saved besides these display preferences. Drawing lives in CityLabelsMap.lua.
local M={title="City Labels",category="qualityOfLife",defaultEnabled=false,
    configDescription="Trainers, banks, inns, flight masters and other services labeled on your world map."}
addon.CityLabels=M
addon:RegisterModule("cityLabels",M)

-- Each setting shows one kind of label. Order is the settings page order.
M.CATEGORIES={
    {key="classTrainers",kind="classTrainer",label="Class Trainers",default=true},
    {key="professionTrainers",kind="professionTrainer",label="Profession Trainers",default=true},
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
    {key="allClasses",label="All Classes",default=false},
    {key="otherFaction",label="Other Faction",default=false},
    {key="showNames",label="Show Names",default=true},
}
M.ranges={iconSize={8,24,1},fontSize={8,16,1}}
local DEFAULT_SIZES={iconSize=12,fontSize=11}
-- Kinds whose map text would only repeat the dot's meaning everywhere.
M.DOT_ONLY={mailbox=true}

local function Public(v) return not (issecretvalue and issecretvalue(v)) end

-- Pure defaults and validation; profile validation runs this on detached copies.
function M.Initialize(db)
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

local booleans={}
for _,group in ipairs({M.CATEGORIES,M.FILTERS}) do for _,entry in ipairs(group) do booleans[entry.key]=true end end
local kindSetting={}
for _,entry in ipairs(M.CATEGORIES) do kindSetting[entry.kind]=entry.key end
M.kindSetting=kindSetting

function M:SetOption(key,value)
    if booleans[key] then
        if type(value)~="boolean" then return false end
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

-- The player's faction and class decide which rows apply; unreadable values
-- show everything rather than guessing.
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

-- Rows are { kind, x, y, label, names, side, class }; returns fresh tables.
function M:Entries(mapID)
    local data=addon.CityLabelsData
    local rows=data and Public(mapID) and type(mapID)=="number" and data.maps[mapID]
    if not rows then return {} end
    local db,faction,class=self.db,self:Player()
    local out={}
    for _,row in ipairs(rows) do
        local kind,side,token=row[1],row[6],row[7]
        local shown=db[kindSetting[kind]]==true
            and (db.otherFaction or not side or not faction or side==faction)
            and (kind~="classTrainer" or db.allClasses or not class or token==class)
        if shown then
            out[#out+1]={kind=kind,x=row[2],y=row[3],label=row[4],names=row[5],side=side,class=token,
                showName=db.showNames and not M.DOT_ONLY[kind]}
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
