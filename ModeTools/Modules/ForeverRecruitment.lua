local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- Independent pilot; Olympus 2.5.1 was inspected, not copied.
addon:RegisterCategory("guildTools",{title="Guild Tools"})
local M={title="Recruitment",category="guildTools",defaultEnabled=false,
    configDescription="Pilot: find guildless players, prepare whispers and request individual guild invites."}
addon.ForeverRecruitment=M
addon:RegisterModule("foreverRecruitment",M)

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Text(v,limit)
    return Public(v) and type(v)=="string" and #v<=limit and not v:find("[%c|]")
end
local function Number(v,low,high)
    return Public(v) and type(v)=="number" and v==v and v>=low and v<=high and v%1==0
end
function M.Initialize(db)
    for k,v in pairs({minLevel=1,maxLevel=60,zone="",message="Hello! Our guild is recruiting. Would you like to hear more?"}) do
        if db[k]==nil then db[k]=v end
    end
    assert(Number(db.minLevel,1,60) and Number(db.maxLevel,1,60) and db.minLevel<=db.maxLevel,"Invalid recruitment level range")
    assert(Text(db.zone,80) and not db.zone:find('["\\]'),"Invalid recruitment zone")
    assert(Text(db.message,200),"Invalid recruitment message")
    if db.history==nil then db.history={} end
    assert(type(db.history)=="table","Invalid recruitment history")
    local count=0
    for name,state in pairs(db.history) do
        count=count+1
        assert(Text(name,120) and (state=="contacted" or state=="skip"),"Invalid recruitment record")
    end
    assert(count<=500,"Recruitment history exceeds 500 records")
end
function M:OnInitialize()
    self.Initialize(self.db);self.candidates={};self.order={};self.offset=0
    self.status="Pilot ready. Enable Recruitment, then click Start Scan."
end
function M:Refresh(message)
    if message then self.status=message end
    if self.page then self.page:Refresh() end
end
function M:OutsideCombat()
    if not InCombatLockdown then return false end
    local state=InCombatLockdown()
    return Public(state) and state==false
end
function M:Ready() return self.active and self:OutsideCombat() end
function M:SetOption(key,value)
    if not self:Ready() or self.scanning then return false end
    local copy=addon.ProfileCodec.Copy(self.db);copy[key]=value
    if not pcall(self.Initialize,copy) then return false end
    self.db[key]=value;return true
end
function M:Remember(name,state)
    local count=0;for _ in pairs(self.db.history) do count=count+1 end
    if not self.db.history[name] and count>=500 then
        self:Refresh("History full (500). No record saved; use Clear History to start a new list.");return false
    end
    self.db.history[name]=state;self:Refresh();return true
end
function M:StartScan()
    if not self:Ready() then return end
    self:StopScan();self.candidates={};self.order={};self.seen={};self.offset=0
    self.level=self.db.minLevel;self.scanning=true
    self:NextSearch()
end
function M:StopScan()
    self.scanning=false;self.pending=nil;self.generation=(self.generation or 0)+1
    self:Refresh("Scan stopped. Existing candidates retained.")
end
function M:NextSearch()
    if not self:Ready() or not self.scanning or self.pending then return end
    if self.scanBlocked then self:Refresh("Search blocked this session. Use native Who, then Read Who Results.");return end
    if self.level>self.db.maxLevel then self.scanning=false;self:Refresh("Scan complete. Results are observations, not a full realm census.");return end
    if self.lastSearch and GetTime()-self.lastSearch<9 then self:Refresh("Wait 9 seconds between searches, then click Next Search.");return end
    if not C_FriendList or type(C_FriendList.SendWho)~="function" then
        self:Refresh("Search API unavailable. Use native Who, then Read Who Results.");return
    end
    local query=tostring(self.level).."-"..tostring(self.level)
    if self.db.zone~="" then query=query..' z-"'..self.db.zone..'"' end
    self.pending=self.level;self.lastSearch=GetTime();self.generation=(self.generation or 0)+1
    local generation=self.generation
    self:Refresh("Waiting for Who results at level "..self.level..".")
    -- Keep Blizzard's Who UI active; never unregister its event listeners.
    if type(C_FriendList.SetWhoToUi)=="function" then pcall(C_FriendList.SetWhoToUi,true) end
    local ok=pcall(C_FriendList.SendWho,query,Enum and Enum.SocialWhoOrigin and Enum.SocialWhoOrigin.Social or nil)
    if not ok then self.scanBlocked=true;self.pending=nil;self:Refresh("Search rejected. Use native Who, then Read Who Results.");return end
    C_Timer.After(12,function()
        if self.active and self.generation==generation and self.pending then
            self.pending=nil
            self:Refresh("No results received. Next Search retries this level; Stop Scan cancels.")
        end
    end)
end
function M:ReadWhoResults(manual)
    if not self:Ready() or (not manual and not self.pending) then return end
    if not C_FriendList or type(C_FriendList.GetNumWhoResults)~="function" or type(C_FriendList.GetWhoInfo)~="function" then
        self:Refresh("Who results API unavailable.");return
    end
    local ok,count,total=pcall(C_FriendList.GetNumWhoResults)
    if not ok or not Number(count,0,50) then self:Refresh("Who results unavailable or restricted.");return end
    local records={}
    for i=1,count do
        local readable,info=pcall(C_FriendList.GetWhoInfo,i)
        if readable and Public(info) and type(info)=="table" then
            -- Shared Who responses have no request ID. Reject mismatched levels;
            -- same-level searches from another addon cannot be distinguished.
            if not manual and (not Number(info.level,1,60) or info.level~=self.pending) then
                self:Refresh("Who response did not match this level; still waiting.");return
            end
            records[#records+1]=info
        end
    end
    for _,info in ipairs(records) do
        local name=info.fullName
        if Text(name,120) and name~="" and not name:find("[:%[%]]") and
            Text(info.fullGuildName,160) and info.fullGuildName=="" and Number(info.level,1,60) then
            if self.candidates[name] then self.candidates[name]=nil end
            if not self.db.history[name] and info.level>=self.db.minLevel and info.level<=self.db.maxLevel and
                Text(info.area,160) and (self.db.zone=="" or info.area:lower()==self.db.zone:lower()) then
                if not self.seen then self.seen={} end
                if not self.seen[name] and #self.order<500 then self.order[#self.order+1]=name;self.seen[name]=true end
                if not self.seen[name] then break end
                self.candidates[name]={name=name,level=info.level,class=Text(info.classStr,80) and info.classStr or "?",zone=info.area}
            end
        elseif Text(name,120) and self.candidates[name] then self.candidates[name]=nil end
    end
    if manual then self.scanning=false
    elseif self.pending then self.level=self.pending+1 end
    self.pending=nil;self.generation=(self.generation or 0)+1
    local capped=count>=50 or (Number(total,0,10000000) and total>count)
    self:Refresh(capped and "Who results capped. Narrow Zone and rescan; some players are missing." or "Results read. Click Next Search to continue.")
end
function M:Draft(name)
    if not self:Ready() or not self.candidates[name] or self.db.history[name] then return end
    if not ChatFrameUtil or type(ChatFrameUtil.OpenChat)~="function" then self:Refresh("Native chat input unavailable.");return end
    for _,getter in ipairs({"GetActiveWindow","GetChatFocusOverride"}) do
        if type(ChatFrameUtil[getter])=="function" then
            local ok,box=pcall(ChatFrameUtil[getter])
            if not ok or not Public(box) then return end
            if box then
                local readable,text=pcall(box.GetText,box)
                if not readable or not Text(text,10000) or text~="" then self:Refresh("Finish or clear your current chat draft first.");return end
            end
        end
    end
    local ok=pcall(ChatFrameUtil.OpenChat,"/w "..name.." "..self.db.message)
    self:Refresh(ok and "Draft prepared. Review recipient and text; Enter sends. Mark Contacted after sending." or "Chat draft unavailable.")
end
function M:NativeLink(name)
    if not self:Ready() or not self.candidates[name] then return end
    print("Play The Game Tools Recruitment: |Hplayer:"..name.."|h["..name.."]|h — right-click the name for the native player menu.")
    self:Refresh("Player link printed in chat. Right-click it and use the native guild invitation option if available.")
end
function M:Invite(name)
    if not self:Ready() or self.inviteBlocked or not self.candidates[name] or self.db.history[name]=="skip" then return end
    local guild=IsInGuild and IsInGuild();local permission=CanGuildInvite and CanGuildInvite()
    if not Public(guild) or guild~=true or not Public(permission) or permission~=true then
        self:Refresh("Guild membership and invite permission required.");return
    end
    if not C_GuildInfo or type(C_GuildInfo.Invite)~="function" then self:Refresh("Guild invitation API unavailable. Use Player Menu Link.");return end
    if self.lastInvite and GetTime()-self.lastInvite<2 then self:Refresh("Wait 2 seconds before another invite request.");return end
    self.lastInvite=GetTime()
    self:Refresh("Invite requested for "..name.."; delivery and acceptance are unconfirmed.")
    local ok=pcall(C_GuildInfo.Invite,name)
    if not ok then self.inviteBlocked=true;self:Refresh("Invite rejected. Disabled for this session; use Player Menu Link.") end
end
function M:OnEnable()
    self.active=true
    if not self.events then self.events=CreateFrame("Frame") end
    for _,event in ipairs({"WHO_LIST_UPDATE","ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent",function(_,event,owner,operation)
        if event=="PLAYER_REGEN_DISABLED" then self:StopScan();self:Refresh("Combat: scan cancelled; recruitment actions unavailable.")
        elseif event=="PLAYER_REGEN_ENABLED" then self:Refresh("Combat ended. Click Start Scan to begin a new sweep.")
        elseif event=="WHO_LIST_UPDATE" then self:ReadWhoResults(false)
        elseif Text(owner,120) and owner=="ModeTools" and Text(operation,200) then
            if operation:find("Invite",1,true) then self.inviteBlocked=true;self:Refresh("Forever blocked addon invitations. Disabled for this session; use Player Menu Link.")
            elseif operation:find("SendWho",1,true) then self.scanBlocked=true;self.pending=nil;self:Refresh("Forever blocked addon searches. Use native Who, then Read Who Results.") end
        end
    end)
    self:Refresh("Ready. Click Start Scan; each Next Search requires its own click.")
end
function M:OnDisable()
    self.active=false;self:StopScan()
    if self.events then self.events:UnregisterAllEvents() end
    self:Refresh("Recruitment disabled.")
end
