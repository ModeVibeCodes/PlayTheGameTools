local addonName,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- Recruitment flow ported from the guild's standalone Play The Game Tools
-- recruiter: class x level-range Who sweeps that split capped ranges, a
-- copy-name box for the native Guild > Add Member dialog, and invite/join/
-- decline tracking from system messages.
addon:RegisterCategory("guildTools",{title="Guild Tools"})
local M={title="Recruitment",category="guildTools",defaultEnabled=false,
    configDescription="Find guildless players by level and class, then invite them through Guild > Add Member.",
    -- Settings that live only in the Recruiter window still route search here.
    searchAliases={"whisper","whisper text","minimum level","maximum level","levels per search","classes","recruiter window"}}
addon.ForeverRecruitment=M
addon:RegisterModule("foreverRecruitment",M)

-- Forever uses the original nine classes.
M.CLASSES={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
M.MAX_WHO_RESULTS=50 -- the server returns at most 50 Who results
M.WHO_DELAY=5        -- seconds between Who searches
M.HISTORY_LIMIT=1000 -- bounded so profile copies stay well inside codec limits
local MAX_LEVEL=60
local DEFAULT_MESSAGE="Hey! <Play The Game> is recruiting. Want a guild invite? Come play with us!"
M.MESSAGE_LETTERS=500 -- what the message box accepts
local MESSAGE_BYTES=M.MESSAGE_LETTERS*4 -- the same letters in the widest UTF-8 encoding
local WHISPER_BYTES=255 -- the game truncates a single chat message past this

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Text(v,limit)
    return Public(v) and type(v)=="string" and #v<=limit and not v:find("[%c|]")
end
local function Number(v,low,high)
    return Public(v) and type(v)=="number" and v==v and v>=low and v<=high and v%1==0
end
local function Now()
    if type(time)=="function" then return time() end
    return os and os.time and os.time() or 0
end
-- "Name-Realm" -> "Name"
local function BaseName(name) return name and (name:match("^([^%-]+)") or name) end
M.BaseName=BaseName
local validClass={};for _,c in ipairs(M.CLASSES) do validClass[c]=true end

-- Pure validation and defaults; also used by profile validation on detached copies.
-- history: [name] = invite time (number), "skip" (never invite) or legacy "contacted".
-- records: invite statistics. Both are runtime keys excluded from profile export.
function M.Initialize(db)
    for k,v in pairs({minLevel=10,maxLevel=MAX_LEVEL,message=DEFAULT_MESSAGE,chunkSize=5,
        reinviteDays=7}) do
        if db[k]==nil then db[k]=v end
    end
    db.whisperEnabled=nil -- retired "whisper after invite" option
    if db.classes==nil then db.classes={} end
    if db.history==nil then db.history={} end
    if db.records==nil then db.records={} end
    for _,key in ipairs({"invited","joined","declined"}) do
        if db.records[key]==nil then db.records[key]=0 end
    end
    assert(Number(db.minLevel,1,MAX_LEVEL) and Number(db.maxLevel,1,MAX_LEVEL) and db.minLevel<=db.maxLevel,"Invalid recruitment level range")
    assert(Number(db.chunkSize,1,MAX_LEVEL),"Invalid recruitment levels per search")
    assert(Number(db.reinviteDays,0,365),"Invalid recruitment re-invite days")
    assert(Text(db.message,MESSAGE_BYTES),"Invalid recruitment message")
    assert(type(db.classes)=="table","Invalid recruitment classes")
    for classFile,enabled in pairs(db.classes) do
        assert(validClass[classFile] and type(enabled)=="boolean","Invalid recruitment class")
    end
    assert(type(db.records)=="table","Invalid recruitment statistics")
    for key,value in pairs(db.records) do
        assert(type(key)=="string" and Number(value,0,10000000),"Invalid recruitment statistic")
    end
    assert(type(db.history)=="table","Invalid recruitment history")
    local count=0
    for name,state in pairs(db.history) do
        count=count+1
        assert(Text(name,120) and (state=="contacted" or state=="skip" or Number(state,0,4102444800)),"Invalid recruitment record")
    end
    assert(count<=M.HISTORY_LIMIT,"Recruitment history exceeds "..M.HISTORY_LIMIT.." records")
end

function M:OnInitialize()
    self.Initialize(self.db)
    -- Earlier "Mark Contacted" entries become invites made now, so they return
    -- after the re-invite window instead of staying hidden permanently.
    local now=Now()
    for name,state in pairs(self.db.history) do
        if state=="contacted" then self.db.history[name]=now end
    end
    self:PruneHistory()
    self.candidates={};self.candidateSet={};self.awaitingConfirm={}
    self.status="Enable Recruitment, pick levels and classes, then click Scan."
end

function M:Print(message)
    print("|cff33ff99Play The Game Tools|r: "..tostring(message))
end
function M:SetStatus(message)
    if message then self.status=message end
    self:Refresh()
end
function M:Refresh()
    if self.page then self.page:Refresh() end
    if self.RefreshWindow then self:RefreshWindow() end
end
function M:OutsideCombat()
    if not InCombatLockdown then return true end
    local state=InCombatLockdown()
    return Public(state) and state==false
end
function M:Ready()
    if not self.active then self:SetStatus("Enable Recruitment first (Guild Tools > Recruitment).");return false end
    if not self:OutsideCombat() then self:SetStatus("Unavailable in combat.");return false end
    return true
end
function M:SetOption(key,value)
    local copy=addon.ProfileCodec.Copy(self.db);copy[key]=value
    if not pcall(self.Initialize,copy) then return false end
    self.db[key]=value
    if key=="minLevel" or key=="maxLevel" or key=="chunkSize" then self:ResetScan() end
    self:Refresh();return true
end
function M:IsClassEnabled(classFile) return self.db.classes[classFile]~=false end
function M:SetClassEnabled(classFile,enabled)
    if not validClass[classFile] then return end
    self.db.classes[classFile]=enabled==true;self:ResetScan();self:Refresh()
end
function M:ClassName(classFile)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]) or
        (classFile:sub(1,1)..classFile:sub(2):lower())
end
function M:ClassColor(classFile)
    local c=classFile and addon.GlobalSettings:GetClassColor(classFile)
    if c then return c.r,c.g,c.b end
    return 1,1,1
end

---------------------------------------------------------------------------
-- History (invite times and never-invite list)
---------------------------------------------------------------------------
function M:Lookup(name)
    return self.db.history[name] or self.db.history[BaseName(name)]
end
function M:IsBlacklisted(name) return self:Lookup(name)=="skip" end
function M:RecentlyInvited(name)
    local t=self:Lookup(name)
    return type(t)=="number" and Now()-t<self.db.reinviteDays*86400
end
function M:PruneHistory()
    local now,window=Now(),self.db.reinviteDays*86400
    for name,state in pairs(self.db.history) do
        if type(state)=="number" and now-state>=window then self.db.history[name]=nil end
    end
end
function M:Remember(name,state)
    local history=self.db.history
    if not history[name] then
        local count=0;for _ in pairs(history) do count=count+1 end
        if count>=self.HISTORY_LIMIT then self:PruneHistory();count=0;for _ in pairs(history) do count=count+1 end end
        if count>=self.HISTORY_LIMIT then
            -- Drop the oldest invite time; never-invite entries are kept.
            local oldest,at
            for key,value in pairs(history) do
                if type(value)=="number" and (not at or value<at) then oldest,at=key,value end
            end
            if not oldest then self:Print("Never-invite list is full ("..self.HISTORY_LIMIT.."). Clear it to add more.");return false end
            history[oldest]=nil
        end
    end
    history[name]=state;return true
end
function M:ClearInvited()
    for name,state in pairs(self.db.history) do
        if state~="skip" then self.db.history[name]=nil end
    end
    self:SetStatus("Invite history cleared.")
end
function M:ClearBlacklist()
    for name,state in pairs(self.db.history) do
        if state=="skip" then self.db.history[name]=nil end
    end
    self:SetStatus("Never-invite list cleared.")
end
function M:ResetStats()
    for key in pairs(self.db.records) do self.db.records[key]=0 end
    self:SetStatus("Statistics cleared.")
end

---------------------------------------------------------------------------
-- Who query queue
---------------------------------------------------------------------------
function M:ResetScan() self.queue=nil;self.pending=nil end
function M:BuildQueue()
    local db,q=self.db,{}
    for _,classFile in ipairs(self.CLASSES) do
        if self:IsClassEnabled(classFile) then
            local lo=db.minLevel
            while lo<=db.maxLevel do
                local hi=math.min(lo+db.chunkSize-1,db.maxLevel)
                q[#q+1]={classFile=classFile,min=lo,max=hi}
                lo=hi+1
            end
        end
    end
    self.queue=q
end
function M:QueryText(entry)
    return string.format('c-"%s" %d-%d',self:ClassName(entry.classFile),entry.min,entry.max)
end
function M:QueueRemaining() return self.queue and #self.queue or 0 end
function M:WhoCooldownRemaining()
    if not self.lastWho then return 0 end
    return math.max(0,self.WHO_DELAY-(GetTime()-self.lastWho))
end
-- Called from a button click only: SendWho requires a hardware event.
function M:SendNextQuery()
    if not self:Ready() then return end
    if self:WhoCooldownRemaining()>0 then
        self:SetStatus(string.format("Wait %.0fs before the next scan.",math.ceil(self:WhoCooldownRemaining())));return
    end
    if not C_FriendList or type(C_FriendList.SendWho)~="function" then self:SetStatus("Who search is unavailable.");return end
    if not self.queue or #self.queue==0 then
        self:BuildQueue()
        if #self.queue==0 then self:SetStatus("No classes selected.");return end
        self:Print(string.format("Starting new scan: %d searches queued.",#self.queue))
    end
    local entry=table.remove(self.queue,1)
    self.pending=entry;self.lastWho=GetTime()
    self.friendsWasShown=FriendsFrame and FriendsFrame:IsShown()
    if type(C_FriendList.SetWhoToUi)=="function" then C_FriendList.SetWhoToUi(true) end
    C_FriendList.SendWho(self:QueryText(entry))
    self:SetStatus("Scanning: "..self:QueryText(entry))
end
-- Manual Scan click: start each scan with an empty candidate list.
function M:Scan()
    if not self:Ready() or self:WhoCooldownRemaining()>0 then return self:SendNextQuery() end
    self:ClearCandidates()
    self:SendNextQuery()
end
function M:OnWhoListUpdate()
    local entry=self.pending
    if not entry then return end
    self.pending=nil
    -- Close the Who window if it opened only because of this search.
    if FriendsFrame and FriendsFrame:IsShown() and not self.friendsWasShown and self:OutsideCombat() and HideUIPanel then
        HideUIPanel(FriendsFrame)
    end
    local num,total=C_FriendList.GetNumWhoResults()
    num=Number(num,0,1000) and num or 0
    total=Number(total,0,10000000) and total or num
    -- Truncated results: split the level range and search both halves next.
    if (total>num or num>=self.MAX_WHO_RESULTS) and entry.max>entry.min and self.queue then
        local mid=math.floor((entry.min+entry.max)/2)
        table.insert(self.queue,1,{classFile=entry.classFile,min=mid+1,max=entry.max})
        table.insert(self.queue,1,{classFile=entry.classFile,min=entry.min,max=mid})
    end
    local added=0
    for i=1,num do
        local info=C_FriendList.GetWhoInfo(i)
        if Public(info) and type(info)=="table" and self:AddCandidate(info) then added=added+1 end
    end
    self:SetStatus(string.format("%s: %d found, %d new unguilded. %d searches left.",
        self:QueryText(entry),num,added,self:QueueRemaining()))
end

---------------------------------------------------------------------------
-- Candidates
---------------------------------------------------------------------------
function M:AddCandidate(info)
    local name,guild,level=info.fullName,info.fullGuildName,info.level
    if not Text(name,120) or name=="" or name:find("[:%[%]]") then return false end
    if not Public(guild) or (guild~=nil and guild~="") then return false end
    if not Number(level,1,MAX_LEVEL) or level<self.db.minLevel or level>self.db.maxLevel then return false end
    local classFile=Public(info.filename) and info.filename or nil
    if classFile and not self:IsClassEnabled(classFile) then return false end
    local player=UnitName and UnitName("player")
    if Public(player) and BaseName(name)==player then return false end
    if self:IsBlacklisted(name) or self:RecentlyInvited(name) or self.candidateSet[name] then return false end
    self.candidateSet[name]=true
    self.candidates[#self.candidates+1]={name=name,level=level,classFile=classFile,
        zone=Text(info.area,160) and info.area or ""}
    return true
end
function M:RemoveCandidate(index)
    local c=table.remove(self.candidates,index)
    if c then self.candidateSet[c.name]=nil end
    return c
end
function M:ClearCandidates()
    self.candidates={};self.candidateSet={}
    self:Refresh()
end
function M:CanInvite()
    local guild=IsInGuild and IsInGuild()
    if not Public(guild) or not guild then self:SetStatus("You are not in a guild.");return false end
    if CanGuildInvite then
        local permission=CanGuildInvite()
        if not Public(permission) or not permission then self:SetStatus("Your guild rank can't invite members.");return false end
    end
    return true
end
-- Forever blocks guild invites when an addon calls the invite API, a macro or
-- pre-fills chat, and addons cannot write to the clipboard. The name is shown
-- highlighted so Ctrl+C copies it for the native Guild > Add Member box.
function M:InviteCandidate(index)
    if not self:Ready() or not self:CanInvite() then return end
    local c=self:RemoveCandidate(index or 1)
    if not c then self:SetStatus("No candidates. Scan first.");return end
    -- Record now so later scans skip them; the invite count rises only when
    -- the game confirms "You have invited X to join your guild".
    self:Remember(c.name,Now())
    self.awaitingConfirm[BaseName(c.name)]=c.name
    if self.ShowCopyBox then self:ShowCopyBox(c.name) end
    self:SetStatus(string.format("Ctrl+C, then paste %s into Guild > Add Member. %d candidates left.",c.name,#self.candidates))
end
function M:SkipCandidate(index,blacklist)
    local c=self:RemoveCandidate(index)
    if c and blacklist and self:Remember(c.name,"skip") then self:Print(c.name.." added to the never-invite list.") end
    self:Refresh()
end
-- Chat messages are one line and "|" starts an escape sequence, so a message
-- from the multi-line box is flattened before it is stored.
function M.CleanMessage(text)
    return (text:gsub("|",""):gsub("%c+"," "):match("^ *(.-) *$"))
end
-- Splits a message into whispers that fit the chat limit, at spaces when possible.
function M.SplitWhisper(text)
    local parts={}
    while #text>WHISPER_BYTES do
        local cut=WHISPER_BYTES+1
        while cut>1 and text:sub(cut,cut)~=" " do cut=cut-1 end
        local rest=cut+1
        if cut==1 then
            -- One unbroken word: cut it without splitting a UTF-8 character.
            cut=WHISPER_BYTES+1
            while cut>2 and text:byte(cut)>=0x80 and text:byte(cut)<0xC0 do cut=cut-1 end
            rest=cut
        end
        parts[#parts+1]=text:sub(1,cut-1)
        text=text:sub(rest):match("^ *(.*)$")
    end
    if text~="" then parts[#parts+1]=text end
    return parts
end
function M:WhisperCandidate(index)
    if not self:Ready() then return end
    index=index or 1
    local c=self.candidates[index]
    if not c then self:SetStatus("No candidates. Scan first.");return end
    local parts=self.SplitWhisper(self.db.message)
    if not parts[1] then self:SetStatus("Enter a whisper message first.");return end
    local send=(C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    if type(send)~="function" then self:SetStatus("Whispers are unavailable.");return end
    for _,part in ipairs(parts) do send(part,"WHISPER",nil,c.name) end
    -- Recorded like an invite so later scans don't message them again.
    self:RemoveCandidate(index)
    self:Remember(c.name,Now())
    self:SetStatus(string.format("Whispered %s. %d candidates left.",c.name,#self.candidates))
end
-- Next: invite the first candidate, or run the next search when the list is empty.
function M:Next()
    if self.candidates[1] then self:InviteCandidate(1) else self:SendNextQuery() end
end

---------------------------------------------------------------------------
-- System messages (invite confirmations, joins, declines)
---------------------------------------------------------------------------
local function FormatToPattern(fmt)
    if type(fmt)~="string" then return nil end
    local p=fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$])","%%%1")
    p=p:gsub("%%s","(.+)"):gsub("%%d","(%%d+)")
    return "^"..p.."$"
end
function M:OnInviteConfirmed(who)
    local full=self.awaitingConfirm[BaseName(who)]
    if not full then return end -- an invite made without this module
    self.awaitingConfirm[BaseName(who)]=nil
    self:Remember(full,Now())
    self.db.records.invited=self.db.records.invited+1
    self:Refresh()
end
function M:OnSystemMessage(message)
    if not Text(message,1000) then return end
    self.patterns=self.patterns or {invited=FormatToPattern(ERR_GUILD_INVITE_S),
        joined=FormatToPattern(ERR_GUILD_JOIN_S),declined=FormatToPattern(ERR_GUILD_DECLINE_S)}
    local p=self.patterns
    local who=p.invited and message:match(p.invited)
    if who then self:OnInviteConfirmed(who);return end
    who=p.joined and message:match(p.joined)
    if who then
        if type(self:Lookup(who))=="number" then self.db.records.joined=self.db.records.joined+1;self:Refresh() end
        return
    end
    who=p.declined and message:match(p.declined)
    if who then self.db.records.declined=self.db.records.declined+1;self:Refresh() end
end

---------------------------------------------------------------------------
-- Quick Actions ring icon
---------------------------------------------------------------------------
local QUICK_ACTION="recruitment"
-- The icon is built outside combat only; PLAYER_REGEN_ENABLED retries a deferred build.
function M:SyncQuickAction()
    local Q=addon.QuickActions
    local active=self.active==true
    if active and not self.shortcut and Q.OutsideCombat() then
        self.shortcut=Q:AddAction(QUICK_ACTION,{order=30,texture="Interface\\Icons\\Ability_Warrior_BattleShout",
            color={.96,.62,.28},title="Recruiter",hint="Click to open or close the Recruiter window.",
            onClick=function() if self.active then self:ToggleWindow() end end})
    end
    Q:SetAvailable(QUICK_ACTION,active)
    Q:SetActive(QUICK_ACTION,active and self.window~=nil and self.window:IsShown())
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
function M:OnEnable()
    self.active=true
    if not self.events then self.events=CreateFrame("Frame") end
    for _,event in ipairs({"WHO_LIST_UPDATE","CHAT_MSG_SYSTEM","ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN","PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent",function(_,event,arg1,arg2)
        if event=="WHO_LIST_UPDATE" then self:OnWhoListUpdate()
        elseif event=="CHAT_MSG_SYSTEM" then pcall(self.OnSystemMessage,self,arg1)
        elseif event=="PLAYER_REGEN_ENABLED" then self:SyncQuickAction()
        elseif Public(arg1) and arg1==addonName then
            self:Print("|cffff5555Blocked by the game:|r "..tostring(arg2).." - please report this.")
        end
    end)
    self:SyncQuickAction()
    self:SetStatus("Ready. Pick levels and classes, then click Scan.")
end
function M:OnDisable()
    self.active=false;self:ResetScan()
    if self.events then self.events:UnregisterAllEvents() end
    if self.copyFrame then self.copyFrame:Hide() end
    self:SyncQuickAction()
    self:SetStatus("Recruitment disabled.")
end
