local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- Read-only guild roster: members by class with search and filters, plus
-- breakdowns by level, rank, race, last online and zone. Members come from the
-- same C_Club calls Blizzard's Forever member list uses, and are held for the
-- session only: nothing about the roster, the search or the filters is written
-- to SavedVariables.
local M={title="Roster",category="guildTools",defaultEnabled=false,
    configDescription="Search your guild and see it broken down by class, level, rank, race, zone and last online.",
    searchAliases={"guild roster","guild members","class totals","class summary","member search","roster search",
        "guild analytics","last online","guild ranks","online members"}}
addon.ForeverGuildRoster=M
addon:RegisterModule("foreverGuildRoster",M)

M.CLASSES={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
M.UNKNOWN="UNKNOWN" -- members whose class the client has not supplied, so totals stay complete
M.RESCAN_DELAY=0.5  -- roster events arrive in bursts; one read covers each burst
M.STATUS={
    off="Turn on the switch at the top of this page to view your guild.",
    noGuild="You are not in a guild.",
    loading="Loading guild members...",
    restricted="Guild data is restricted right now. The list updates when it is available again.",
    unavailable="Guild member data is unavailable.",
}
local EVENTS={"GUILD_ROSTER_UPDATE","PLAYER_GUILD_UPDATE","CLUB_MEMBER_ADDED","CLUB_MEMBER_REMOVED",
    "CLUB_MEMBER_UPDATED","CLUB_MEMBERS_UPDATED"}

-- Forever's level cap; the top bracket holds only capped members.
M.LEVEL_BUCKETS={"60","50–59","40–49","30–39","20–29","10–19","1–9"}
M.LAST_ONLINE={"Online Now","Within a Day","1–6 Days","1–4 Weeks","1–3 Months","3–12 Months","Over a Year"}
M.ZONE_LIMIT=10 -- busiest zones listed by name; the rest share one line
M.ALL_CLASSES="ALL"
M.STATUS_FILTERS={{id="all",label="All Members"},{id="online",label="Online"},{id="offline",label="Offline"}}
M.NOBODY_ONLINE="Nobody is online right now."
-- Values from Forever's ClubMemberPresence; Enum supplies them in the client.
local PRESENCE={Online=1,OnlineMobile=2,Offline=3,Away=4,Busy=5}

local validClass={};for _,c in ipairs(M.CLASSES) do validClass[c]=true end
local LIST_ORDER={};for i,c in ipairs(M.CLASSES) do LIST_ORDER[i]=c end
LIST_ORDER[#LIST_ORDER+1]=M.UNKNOWN
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function EmptySnapshot() return {total=0,online=0,members={},stats={}} end
-- Detail fields are optional: a restricted or missing one reads as unknown.
local function Text(v) if Public(v) and type(v)=="string" and v~="" then return v end end
local function Whole(v,low)
    if Public(v) and type(v)=="number" and v==v and v>=(low or 0) and v<math.huge and v%1==0 then return v end
end
local function Presence()
    local enum=Enum and Enum.ClubMemberPresence
    return type(enum)=="table" and enum or PRESENCE
end

function M:ClassName(classFile)
    if classFile==M.UNKNOWN then return "Unknown" end
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]) or
        (classFile:sub(1,1)..classFile:sub(2):lower())
end
function M:ClassColor(classFile)
    local c=validClass[classFile] and addon.GlobalSettings:GetClassColor(classFile)
    if c then return c.r,c.g,c.b end
    return 0.7,0.7,0.7
end

local function ClassFile(classID)
    if classID==nil then return M.UNKNOWN end
    local info=C_CreatureInfo.GetClassInfo(classID)
    local file=info and info.classFile
    return validClass[file] and file or M.UNKNOWN
end

local function RaceName(raceID,cache)
    local id=Whole(raceID,1)
    if not id or not C_CreatureInfo.GetRaceInfo then return nil end
    if cache[id]==nil then
        local info=C_CreatureInfo.GetRaceInfo(id)
        cache[id]=Public(info) and type(info)=="table" and Text(info.raceName) or false
    end
    return cache[id] or nil
end

-- Forever reports time offline as years/months/days/hours, like the native list.
local function LastOnline(info)
    local years=Whole(info.lastOnlineYear)
    if not years then return nil end
    return {years,Whole(info.lastOnlineMonth) or 0,Whole(info.lastOnlineDay) or 0,Whole(info.lastOnlineHour) or 0}
end

local function Member(info,name,classFile,races)
    local presence,state=Presence(),info.presence
    if not Public(state) then state=nil end
    -- The native member count treats Online, Away and Busy as in the game.
    local online=state~=nil and (state==presence.Online or state==presence.Away or state==presence.Busy)
    local member={name=name,classFile=classFile,level=Whole(info.level,1),race=RaceName(info.race,races),
        zone=Text(info.zone),rank=Text(info.guildRank),rankOrder=Whole(info.guildRankOrder,1),
        note=Text(info.memberNote),officerNote=Text(info.officerNote),online=online,
        mobile=state~=nil and state==presence.OnlineMobile}
    if not online then member.lastOnline=LastOnline(info) end
    member.search=table.concat({name,M:ClassName(classFile),member.race or "",member.zone or "",
        member.rank or "",member.note or "",member.officerNote or ""},"\n"):lower()
    return member
end

function M.LevelBucket(level)
    if not level then return nil end
    if level>=60 then return 1 end
    if level<10 then return #M.LEVEL_BUCKETS end
    return #M.LEVEL_BUCKETS-math.floor(level/10)
end
function M.LastOnlineBucket(member)
    if member.online then return 1 end
    local t=member.lastOnline
    if not t then return nil end
    if t[1]>=1 then return 7 end
    if t[2]>=3 then return 6 end
    if t[2]>=1 then return 5 end
    if t[3]>=7 then return 4 end
    if t[3]>=1 then return 3 end
    return 2
end

-- Fixed buckets keep their order and zeros; Unknown appears only when used.
local function Fixed(labels,counts,unknown)
    local list={}
    for i,label in ipairs(labels) do list[i]={label=label,count=counts[i] or 0} end
    if unknown>0 then list[#list+1]={label="Unknown",count=unknown} end
    return list
end
local function Tally(map,key,label,order)
    local entry=map[key]
    if not entry then entry={label=label,count=0,order=order};map[key]=entry end
    entry.count=entry.count+1
end
local function Sorted(map,unknown,compare)
    local list={}
    for _,entry in pairs(map) do list[#list+1]=entry end
    table.sort(list,compare)
    if unknown>0 then list[#list+1]={label="Unknown",count=unknown} end
    return list
end
local function ByCount(a,b)
    if a.count~=b.count then return a.count>b.count end
    return a.label<b.label
end
local function ByRank(a,b)
    if a.order~=b.order then return (a.order or math.huge)<(b.order or math.huge) end
    return a.label<b.label
end

local function BuildStats(snapshot)
    local levels,lastSeen={},{}
    local ranks,races,zones={},{},{}
    local unknown={level=0,lastOnline=0,rank=0,race=0,zone=0}
    for _,list in pairs(snapshot.members) do
        for _,member in ipairs(list) do
            local bucket=M.LevelBucket(member.level)
            if bucket then levels[bucket]=(levels[bucket] or 0)+1 else unknown.level=unknown.level+1 end
            bucket=M.LastOnlineBucket(member)
            if bucket then lastSeen[bucket]=(lastSeen[bucket] or 0)+1 else unknown.lastOnline=unknown.lastOnline+1 end
            if member.rankOrder or member.rank then
                Tally(ranks,member.rankOrder or member.rank,member.rank or ("Rank "..member.rankOrder),member.rankOrder)
            else unknown.rank=unknown.rank+1 end
            if member.race then Tally(races,member.race,member.race) else unknown.race=unknown.race+1 end
            if member.online then
                if member.zone then Tally(zones,member.zone,member.zone) else unknown.zone=unknown.zone+1 end
            end
        end
    end
    local zoneList=Sorted(zones,0,ByCount)
    if #zoneList>M.ZONE_LIMIT then
        local other=0
        for i=#zoneList,M.ZONE_LIMIT+1,-1 do other=other+zoneList[i].count;zoneList[i]=nil end
        zoneList[#zoneList+1]={label="Other Zones",count=other}
    end
    if unknown.zone>0 then zoneList[#zoneList+1]={label="Unknown",count=unknown.zone} end
    snapshot.stats={
        level=Fixed(M.LEVEL_BUCKETS,levels,unknown.level),
        rank=Sorted(ranks,unknown.rank,ByRank),
        race=Sorted(races,unknown.race,ByCount),
        lastOnline=Fixed(M.LAST_ONLINE,lastSeen,unknown.lastOnline),
        zone=zoneList,
    }
end

-- Returns a complete snapshot, or nil and the reason the current list should stay.
-- A restricted name or class rejects the read rather than publishing a partial list.
local function ReadMembers()
    if type(IsInGuild)=="function" then
        local inGuild=IsInGuild()
        if Public(inGuild) and not inGuild then return EmptySnapshot(),M.STATUS.noGuild end
    end
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
        local locked=C_ChatInfo.InChatMessagingLockdown()
        if not Public(locked) or locked then return nil,M.STATUS.restricted end
    end
    local clubId=C_Club.GetGuildClubId()
    if not Public(clubId) then return nil,M.STATUS.restricted end
    if not clubId then return nil,M.STATUS.loading end
    local ids=C_Club.GetClubMembers(clubId)
    if not Public(ids) or type(ids)~="table" then return nil,M.STATUS.restricted end
    local snapshot,races=EmptySnapshot(),{}
    for _,memberId in ipairs(ids) do
        local info=C_Club.GetMemberInfo(clubId,memberId)
        if not Public(info) then return nil,M.STATUS.restricted end
        if info then
            local name,classID=info.name,info.classID
            if not Public(name) or not Public(classID) then return nil,M.STATUS.restricted end
            -- A name carrying "|" is an encoded placeholder, not a character name.
            if type(name)=="string" and name~="" and not name:find("|",1,true) then
                local classFile=ClassFile(classID)
                local list=snapshot.members[classFile]
                if not list then list={};snapshot.members[classFile]=list end
                local member=Member(info,name,classFile,races)
                list[#list+1]=member
                snapshot.total=snapshot.total+1
                if member.online then snapshot.online=snapshot.online+1 end
            end
        end
    end
    if snapshot.total==0 then return nil,M.STATUS.loading end
    for _,list in pairs(snapshot.members) do
        table.sort(list,function(a,b)
            local lowerA,lowerB=a.name:lower(),b.name:lower()
            if lowerA~=lowerB then return lowerA<lowerB end
            return a.name<b.name
        end)
    end
    BuildStats(snapshot)
    return snapshot
end

function M:Count(classFile)
    local list=self.snapshot.members[classFile]
    return list and #list or 0
end
function M:Stat(key) return self.snapshot.stats[key] or {} end

-- Search and filters belong to this session only.
function M:ResetFilter() self.filter={text="",class=M.ALL_CLASSES,status="all"} end
-- A number or "low-high" searches levels; anything else matches name, class,
-- race, zone, rank or notes.
function M.ParseQuery(text)
    text=(type(text)=="string" and text or ""):match("^%s*(.-)%s*$"):lower()
    if text=="" then return nil end
    local level=text:match("^(%d+)$")
    if level then return {low=tonumber(level),high=tonumber(level)} end
    local low,high=text:match("^(%d+)%s*%-%s*(%d+)$")
    if low then
        low,high=tonumber(low),tonumber(high)
        return {low=math.min(low,high),high=math.max(low,high)}
    end
    return {text=text}
end
function M:FilterActive()
    local f=self.filter
    return M.ParseQuery(f.text)~=nil or f.class~=M.ALL_CLASSES or f.status~="all"
end
function M:Matches(member,query)
    local f=self.filter
    if f.class~=M.ALL_CLASSES and member.classFile~=f.class then return false end
    if f.status=="online" and not member.online then return false end
    if f.status=="offline" and member.online then return false end
    if not query then return true end
    if query.text then return member.search:find(query.text,1,true)~=nil end
    return member.level~=nil and member.level>=query.low and member.level<=query.high
end
-- Matching members in list order, grouped by class, and how many matched.
function M:Filtered()
    local query=M.ParseQuery(self.filter.text)
    local groups,shown={},0
    for _,classFile in ipairs(LIST_ORDER) do
        local matches={}
        for _,member in ipairs(self.snapshot.members[classFile] or {}) do
            if self:Matches(member,query) then matches[#matches+1]=member end
        end
        if #matches>0 then groups[#groups+1]={classFile=classFile,members=matches};shown=shown+#matches end
    end
    return groups,shown
end
function M:SetFilter(key,value)
    if self.filter[key]==value then return end
    self.filter[key]=value
    self:RenderPage()
end
function M:ResultText(shown)
    local total=self.snapshot.total
    if total==0 then return "" end
    if self:FilterActive() then
        if shown==0 then return "No members match your search." end
        return string.format("Showing %d of %d members",shown,total)
    end
    return string.format("%d members, %d online",total,self.snapshot.online)
end

local function Plural(count,unit) return count.." "..unit..(count==1 and "" or "s") end
function M:LastOnlineText(member)
    local t=member.lastOnline
    if not t then return "Offline" end
    if t[1]>0 then return "Last online "..Plural(t[1],"year").." ago" end
    if t[2]>0 then return "Last online "..Plural(t[2],"month").." ago" end
    if t[3]>0 then return "Last online "..Plural(t[3],"day").." ago" end
    if t[4]>0 then return "Last online "..Plural(t[4],"hour").." ago" end
    return "Last online less than an hour ago"
end
-- Tooltip lines below the member's name.
function M:Describe(member)
    local who={}
    if member.level then who[#who+1]="Level "..member.level end
    if member.race then who[#who+1]=member.race end
    who[#who+1]=self:ClassName(member.classFile)
    local lines={table.concat(who," ")}
    if member.rank then lines[#lines+1]="Rank: "..member.rank end
    if member.online then lines[#lines+1]=member.zone and ("Online in "..member.zone) or "Online"
    elseif member.mobile then lines[#lines+1]="Online in mobile chat"
    else lines[#lines+1]=self:LastOnlineText(member) end
    if member.note then lines[#lines+1]="Note: "..member.note end
    if member.officerNote then lines[#lines+1]="Officer Note: "..member.officerNote end
    return lines
end
function M:RenderPage()
    if self.page and self.page.RenderRoster then self.page:RenderRoster() end
end
function M:Rescan()
    local ok,snapshot,status=pcall(ReadMembers)
    if not ok then snapshot,status=nil,M.STATUS.unavailable end
    if snapshot then self.snapshot=snapshot end
    self.status=status
    self:RenderPage()
end
function M:ScheduleRescan()
    if self.rescanPending then return end
    self.rescanPending=true
    C_Timer.After(self.RESCAN_DELAY,function()
        self.rescanPending=false
        if self.watching then self:Rescan() end
    end)
end

-- Events and roster requests run only while the page can be seen.
function M:Start()
    if self.watching or not self.active or not self.pageShown then return end
    self.watching=true
    if not self.events then
        self.events=CreateFrame("Frame")
        self.events:SetScript("OnEvent",function() self:ScheduleRescan() end)
    end
    for _,event in ipairs(EVENTS) do self.events:RegisterEvent(event) end
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    self:Rescan()
end
function M:Stop()
    self.watching=false
    if self.events then self.events:UnregisterAllEvents() end
end
function M:SetPageShown(shown)
    self.pageShown=shown
    if shown then self:Start() else self:Stop() end
end

function M:OnInitialize()
    self.snapshot=EmptySnapshot()
    self.status=M.STATUS.off
    self:ResetFilter()
end
function M:OnEnable()
    self.active=true
    self.status=nil
    self:Start()
end
function M:OnDisable()
    self.active=false
    self:Stop()
    self.snapshot=EmptySnapshot()
    self.status=M.STATUS.off
    self:RenderPage()
end
