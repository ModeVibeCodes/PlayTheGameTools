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
    local f=CreateFrame("Frame","ModeToolsThreatMeterFrame",UIParent)
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
    f:SetScript("OnUpdate",function(_,elapsed)
        -- Threat events do not cover every group member, so poll while shown.
        self.elapsed=self.elapsed+elapsed
        if self.elapsed>=self.UPDATE_INTERVAL then self.elapsed=0;self:Update() end
    end)
    f:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_THREAT_LIST_UPDATE" and unit~="target" then return end
        self:Update()
    end)
    self:ApplyPosition()
end

function M:HasTarget()
    return Truthy(UnitExists,"target") and Truthy(UnitCanAttack,"player","target")
        and not Truthy(UnitIsDeadOrGhost,"target")
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

function M:Collect()
    local entries={}
    for _,u in ipairs(self:Units()) do
        local tanking,_,scaled=Call(UnitDetailedThreatSituation,u.unit,"target")
        if Number(scaled,0,1000) then
            local color=PET_COLOR
            if not u.owner then
                local _,classFile=Call(UnitClass,u.unit)
                local c=Public(classFile) and type(classFile)=="string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
                color=c and {c.r,c.g,c.b} or DEFAULT_COLOR
            end
            local name=Name(u.unit)
            if u.owner then name=name.." ("..Name(u.owner)..")" end
            entries[#entries+1]={name=name,percent=math.min(100,scaled),
                tanking=Public(tanking) and tanking==true,color=color}
        end
    end
    table.sort(entries,function(a,b)
        if a.tanking~=b.tanking then return a.tanking end
        if a.percent~=b.percent then return a.percent>b.percent end
        return a.name<b.name
    end)
    return entries
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
            bar:SetValue(e.percent)
            bar:SetStatusBarColor(e.color[1],e.color[2],e.color[3],0.85)
            bar.nameText:SetText(e.name)
            bar.percentText:SetText(string.format("%d%%",math.floor(e.percent+0.5)))
            bar:Show()
        else
            bar:Hide()
        end
    end
    f:SetHeight(PAD*2+HEADER+shown*(ROW+1))
    f:Show()
end

local EVENTS={"PLAYER_TARGET_CHANGED","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE",
    "GROUP_ROSTER_UPDATE","UNIT_PET","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD"}

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
