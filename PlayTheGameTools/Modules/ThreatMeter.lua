local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- No-frills threat list for the player's current hostile target. Reads only the
-- client's UnitDetailedThreatSituation; plain (unprotected) frames, so it is
-- safe to update, show and hide in combat. Pets are optional and off by default.
local M={title="Threat Meter",category="qualityOfLife",defaultEnabled=false,
    configDescription="Threat on your current target for you and your group, with optional pets."}
addon.ThreatMeter=M
addon:RegisterModule("threatMeter",M)

M.MAX_ROWS=10
M.UPDATE_INTERVAL=0.5
local WIDTH,HEADER,ROW,PAD=200,18,16,3
local BAR_TEXTURE="Interface\\TargetingFrame\\UI-StatusBar"
local PET_COLOR={0.55,0.6,0.65}
local DEFAULT_COLOR={0.6,0.6,0.6}

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Number(v,low,high) return Public(v) and type(v)=="number" and v==v and v>=low and v<=high end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d,e=pcall(fn,...)
    if ok then return a,b,c,d,e end
end
local function Truthy(fn,...) local v=Call(fn,...);return Public(v) and v==true end

-- Pure defaults and validation; profile validation runs this on detached copies.
function M.Initialize(db)
    for k,v in pairs({showPets=false,locked=false,hideOutOfCombat=false,x=320,y=-120}) do
        if db[k]==nil then db[k]=v end
    end
    for _,k in ipairs({"showPets","locked","hideOutOfCombat"}) do
        assert(type(db[k])=="boolean","Invalid Threat Meter setting: "..k)
    end
    assert(Number(db.x,-4000,4000) and Number(db.y,-4000,4000),"Invalid Threat Meter position")
end

function M:Available() return type(UnitDetailedThreatSituation)=="function" end

function M:SetOption(key,value)
    if key~="showPets" and key~="locked" and key~="hideOutOfCombat" then return false end
    if type(value)~="boolean" then return false end
    self.db[key]=value
    if key=="locked" then self:StopDrag() end
    self:Update()
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

function M:ResetPosition()
    self:StopDrag()
    self.db.x,self.db.y=320,-120
    self:ApplyPosition()
end

function M:ApplyPosition()
    if not self.frame then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
end

function M:StopDrag()
    local f=self.frame
    if not f or not f.dragging then return end
    f:StopMovingOrSizing();f.dragging=nil
    local x,y=f:GetCenter();local cx,cy=UIParent:GetCenter()
    if Number(x,-100000,100000) and Number(y,-100000,100000) and Number(cx,-100000,100000) and Number(cy,-100000,100000) then
        self.db.x=math.floor(math.max(-4000,math.min(4000,x-cx))+0.5)
        self.db.y=math.floor(math.max(-4000,math.min(4000,y-cy))+0.5)
    end
    self:ApplyPosition()
end

function M:CreateFrame()
    if self.frame then return end
    local f=CreateFrame("Frame","PlayTheGameToolsThreatMeterFrame",UIParent)
    self.frame=f
    f:Hide();f:SetSize(WIDTH,HEADER+PAD*2);f:SetFrameStrata("MEDIUM");f:SetClampedToScreen(true)
    f:SetMovable(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function()
        if self.active and not self.db.locked then f:StartMoving();f.dragging=true end
    end)
    f:SetScript("OnDragStop",function() self:StopDrag() end)
    f:SetScript("OnHide",function() self:StopDrag() end)
    local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0,0,0,0.5)
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    f.title:SetPoint("TOPLEFT",PAD+2,-PAD-2);f.title:SetWidth(WIDTH-PAD*2-4);f.title:SetJustifyH("LEFT")
    f.rows={}
    for i=1,self.MAX_ROWS do
        local bar=CreateFrame("StatusBar",nil,f)
        bar:SetSize(WIDTH-PAD*2,ROW)
        bar:SetPoint("TOPLEFT",PAD,-(PAD+HEADER+(i-1)*(ROW+1)))
        bar:SetStatusBarTexture(BAR_TEXTURE);bar:SetMinMaxValues(0,100)
        bar.nameText=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        bar.nameText:SetPoint("LEFT",4,0);bar.nameText:SetWidth(WIDTH-PAD*2-52);bar.nameText:SetJustifyH("LEFT")
        bar.percentText=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        bar.percentText:SetPoint("RIGHT",-4,0);bar.percentText:SetJustifyH("RIGHT")
        bar:Hide()
        f.rows[i]=bar
    end
    self.elapsed=0
    -- Threat events fire in bursts and miss some group members, so the list is
    -- refreshed on a fixed interval while shown instead of per threat event.
    f:SetScript("OnUpdate",function(_,elapsed)
        self.elapsed=self.elapsed+elapsed
        if self.elapsed>=self.UPDATE_INTERVAL then self.elapsed=0;self:Update() end
    end)
    f:SetScript("OnEvent",function() self:Update() end)
    self:ApplyPosition()
end

-- Forever can return secret values field by field. A secret is never compared
-- or tested; a secret hostility answer is treated as "possibly hostile".
function M:HasTarget()
    if not Truthy(UnitExists,"target") or Truthy(UnitIsDeadOrGhost,"target") then return false end
    local hostile=Call(UnitCanAttack,"player","target")
    return not Public(hostile) or hostile==true
end

-- Units in the player's group (and their pets, if enabled), without duplicates.
function M:Units()
    local list,seen={},{}
    local function Add(unit,owner)
        if not Truthy(UnitExists,unit) then return end
        local guid=Call(UnitGUID,unit)
        if Public(guid) and type(guid)=="string" then
            if seen[guid] then return end
            seen[guid]=true
        end
        list[#list+1]={unit=unit,owner=owner}
    end
    local pets=self.db.showPets
    if Truthy(IsInRaid) then
        local count=Call(GetNumGroupMembers)
        count=Number(count,0,40) and count or 0
        for i=1,count do
            Add("raid"..i)
            if pets then Add("raidpet"..i,"raid"..i) end
        end
    end
    Add("player");if pets then Add("pet","player") end
    local party=Call(GetNumSubgroupMembers)
    party=Number(party,0,4) and party or 0
    for i=1,party do
        Add("party"..i)
        if pets then Add("partypet"..i,"party"..i) end
    end
    return list
end

local function Name(unit)
    local name=Call(UnitName,unit)
    if Public(name) and type(name)=="string" and name~="" then return name end
    return "Unknown"
end

local function Connected(unit)
    local connected=Call(UnitIsConnected,unit)
    return not Public(connected) or connected~=false
end

-- One threat row, or nil when the client reports nothing for this unit.
function M:Entry(u)
    if Truthy(UnitIsDeadOrGhost,u.unit) or not Connected(u.unit) then return end
    local tanking,status,scaled,_,raw=Call(UnitDetailedThreatSituation,u.unit,"target")
    local hidden=not Public(tanking) or not Public(status) or not Public(scaled) or not Public(raw)
    if not Number(status,0,3) then
        status=Call(UnitThreatSituation,u.unit,"target")
        hidden=hidden or not Public(status)
    end
    local e={tanking=Public(tanking) and tanking==true,
        status=Number(status,0,3) and status or nil,
        percent=Number(scaled,0,1000) and math.min(100,scaled) or nil,
        raw=Number(raw,0,1e15) and raw or nil}
    if not (e.percent or e.status or e.tanking or hidden) then return end
    e.hidden=hidden and not e.percent and not e.status
    e.name=Name(u.unit)
    if u.owner then
        e.name=e.name.." ("..Name(u.owner)..")"
        e.color=PET_COLOR
    else
        local _,classFile=Call(UnitClass,u.unit)
        local c=Public(classFile) and type(classFile)=="string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        e.color=c and {c.r,c.g,c.b} or DEFAULT_COLOR
    end
    e.unit=u.unit
    return e
end

local function Rank(e)
    if e.aggro then return 3 end
    if e.tanking or (e.status or 0)>=2 then return 2 end
    if e.status==1 then return 1 end
    return 0
end

function M:Collect()
    local entries={}
    for _,u in ipairs(self:Units()) do entries[#entries+1]=self:Entry(u) end
    -- The mob's own target holds aggro, when the client exposes it.
    if Truthy(UnitExists,"targettarget") then
        for _,e in ipairs(entries) do
            if Truthy(UnitIsUnit,"targettarget",e.unit) then e.aggro=true;break end
        end
    end
    -- Raw threat orders melee and ranged correctly; percent is the fallback.
    table.sort(entries,function(a,b)
        local ra,rb=Rank(a),Rank(b)
        if ra~=rb then return ra>rb end
        if (a.raw~=nil)~=(b.raw~=nil) then return a.raw~=nil end
        if a.raw and a.raw~=b.raw then return a.raw>b.raw end
        if (a.percent~=nil)~=(b.percent~=nil) then return a.percent~=nil end
        if a.percent and a.percent~=b.percent then return a.percent>b.percent end
        return a.name<b.name
    end)
    return entries
end

-- Bar fill and label; without a percentage, the threat status is shown instead.
function M.Display(e)
    if e.percent then return e.percent,string.format("%d%%",math.floor(e.percent+0.5)) end
    if e.aggro or e.tanking or (e.status or 0)>=2 then return 100,"Aggro" end
    if e.status==1 then return 90,"High" end
    if e.hidden then return 0,"Hidden" end
    return 25,"Low"
end

function M:InCombat()
    return Truthy(UnitAffectingCombat,"player") or Truthy(InCombatLockdown)
end

function M:Update()
    local f=self.frame
    if not f then return end
    local hasTarget=self:HasTarget()
    -- Unlocked frames stay visible so they can be placed.
    local show=self.active and (not self.db.locked or not self.db.hideOutOfCombat or self:InCombat())
    f:EnableMouse(self.active and not self.db.locked or false)
    if not show then self.entries={};f:Hide();return end
    local entries={}
    if not self:Available() then
        f.title:SetText("Threat: unavailable on this client")
    elseif hasTarget then
        entries=self:Collect()
        f.title:SetText("Threat: "..Name("target"))
    else
        f.title:SetText("Threat: no target")
    end
    self.entries=entries
    local shown=math.min(#entries,self.MAX_ROWS)
    for i,bar in ipairs(f.rows) do
        local e=entries[i]
        if e then
            local fill,label=M.Display(e)
            bar:SetValue(fill)
            bar:SetStatusBarColor(e.color[1],e.color[2],e.color[3],0.85)
            bar.nameText:SetText(e.name)
            bar.percentText:SetText(label)
            bar:Show()
        else
            bar:Hide()
        end
    end
    f:SetHeight(PAD*2+HEADER+shown*(ROW+1))
    f:Show()
end

local EVENTS={"PLAYER_TARGET_CHANGED","GROUP_ROSTER_UPDATE","UNIT_PET",
    "PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD"}

function M:OnInitialize()
    self.Initialize(self.db)
    self.entries={}
end

function M:OnEnable()
    if self.active then return end
    self.active=true
    self:CreateFrame()
    -- Tolerate events the Forever client may not define.
    for _,event in ipairs(EVENTS) do pcall(self.frame.RegisterEvent,self.frame,event) end
    self:Update()
end

function M:OnDisable()
    self.active=false
    if not self.frame then return end
    self:StopDrag()
    self.frame:UnregisterAllEvents()
    self:Update()
end
