local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- Read-only guild list grouped by class. Members come from the same C_Club calls
-- Blizzard's Forever member list uses, and are held for the session only: nothing
-- about the roster is written to SavedVariables.
local M={title="Roster",category="guildTools",defaultEnabled=false,
    configDescription="See every guild member listed by class, with a total for each class.",
    searchAliases={"guild roster","guild members","class totals","class summary"}}
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

local validClass={};for _,c in ipairs(M.CLASSES) do validClass[c]=true end
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function EmptySnapshot() return {total=0,members={}} end

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

-- Returns a complete snapshot, or nil and the reason the current list should stay.
-- A single restricted value rejects the read rather than publishing a partial list.
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
    local snapshot=EmptySnapshot()
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
                list[#list+1]=name
                snapshot.total=snapshot.total+1
            end
        end
    end
    if snapshot.total==0 then return nil,M.STATUS.loading end
    for _,list in pairs(snapshot.members) do
        table.sort(list,function(a,b)
            local lowerA,lowerB=a:lower(),b:lower()
            if lowerA~=lowerB then return lowerA<lowerB end
            return a<b
        end)
    end
    return snapshot
end

function M:Count(classFile)
    local list=self.snapshot.members[classFile]
    return list and #list or 0
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
