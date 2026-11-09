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
-- Same graphite surfaces and hairlines as the settings window. Mint marks one
-- state only, your own row; it turns amber when you are close to pulling.
local WIDTH,HEADER,ROW,GAP,PAD=220,22,18,2,4
local FLAT="Interface\\Buttons\\WHITE8X8"
local WARN={232/255,176/255,75/255}
local PET_COLOR={0.5,0.53,0.58}
local DEFAULT_COLOR={0.6,0.6,0.6}
local MESSAGES={unavailable="Threat data isn't available on this client.",
    noTarget="Target an enemy to see threat.",noThreat="No threat on this target yet."}
M.MESSAGES=MESSAGES

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

local function Paint(texture,color,alpha) texture:SetColorTexture(color[1],color[2],color[3],alpha or 1) end

local function Text(parent,size,color,justify)
    local text=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    addon.Media:BindInterfaceFont(text,GameFontHighlight,size,"threatMeter")
    text:SetTextColor(color[1],color[2],color[3],1)
    text:SetJustifyH(justify or "LEFT");text:SetWordWrap(false)
    return text
end

-- Four 1px edges; the vertical ones stop short so corners never double up.
local function Outline(frame)
    local edges={}
    for _,p in ipairs({{"TOPLEFT",0,0,"TOPRIGHT",0,0,true},{"BOTTOMLEFT",0,0,"BOTTOMRIGHT",0,0,true},
        {"TOPLEFT",0,-1,"BOTTOMLEFT",0,1},{"TOPRIGHT",0,-1,"BOTTOMRIGHT",0,1}}) do
        local edge=frame:CreateTexture(nil,"BORDER")
        edge:SetPoint(p[1],p[2],p[3]);edge:SetPoint(p[4],p[5],p[6])
        if p[7] then edge:SetHeight(1) else edge:SetWidth(1) end
        edges[#edges+1]=edge
    end
    return {edges=edges,SetColor=function(o,color) for _,e in ipairs(o.edges) do Paint(e,color) end end}
end

function M:CreateFrame()
    if self.frame then return end
    local T=addon.InterfaceTheme
    local f=CreateFrame("Frame","PlayTheGameToolsThreatMeterFrame",UIParent)
    self.frame=f
    f:Hide();f:SetSize(WIDTH,HEADER+1+PAD*2+ROW);f:SetFrameStrata("MEDIUM");f:SetClampedToScreen(true)
    f:SetMovable(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function()
        if self.active and not self.db.locked then f:StartMoving();f.dragging=true end
    end)
    f:SetScript("OnDragStop",function() self:StopDrag() end)
    f:SetScript("OnHide",function() self:StopDrag() end)
    -- The border brightens under the pointer while the meter can be dragged.
    f:SetScript("OnEnter",function() if not self.db.locked then f.border:SetColor(T.secondary) end end)
    f:SetScript("OnLeave",function() f.border:SetColor(T.lineStrong) end)

    local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();addon.Media:PaintSurface(bg,T.panel,0.94,"threatMeter")
    f.border=addon.ConfigWidgets.Outline(f,T.lineStrong,nil,nil,nil,"threatMeter");f.border:SetColor(T.lineStrong)
    local header=f:CreateTexture(nil,"BORDER")
    header:SetPoint("TOPLEFT",1,-1);header:SetPoint("TOPRIGHT",-1,-1);header:SetHeight(HEADER);addon.Media:PaintSurface(header,T.surface,1,"threatMeter")
    local rule=f:CreateTexture(nil,"BORDER")
    rule:SetPoint("TOPLEFT",1,-1-HEADER);rule:SetPoint("TOPRIGHT",-1,-1-HEADER);rule:SetHeight(1);Paint(rule,T.line)
    f.title=Text(f,12,T.text)
    f.title:SetPoint("TOPLEFT",PAD+5,-1);f.title:SetSize(WIDTH-PAD*2-90,HEADER)
    f.hint=Text(f,10,T.muted,"RIGHT")
    f.hint:SetPoint("TOPRIGHT",-PAD-5,-1);f.hint:SetSize(80,HEADER);f.hint:SetText("Drag to move")
    f.empty=Text(f,11,T.muted)
    f.empty:SetPoint("TOPLEFT",PAD+5,-(HEADER+1+PAD));f.empty:SetSize(WIDTH-PAD*2-10,ROW)

    f.rows={}
    for i=1,self.MAX_ROWS do
        local bar=CreateFrame("StatusBar",nil,f)
        bar:SetSize(WIDTH-PAD*2,ROW)
        bar:SetPoint("TOPLEFT",PAD,-(HEADER+1+PAD+(i-1)*(ROW+GAP)))
        bar:SetStatusBarTexture(addon.Media:GetSurfaceTexture("threatMeter"));bar:SetMinMaxValues(0,100)
        local track=bar:CreateTexture(nil,"BACKGROUND");track:SetAllPoints();addon.Media:PaintSurface(track,T.field,1,"threatMeter")
        bar.edge=bar:CreateTexture(nil,"OVERLAY")
        bar.edge:SetPoint("TOPLEFT");bar.edge:SetPoint("BOTTOMLEFT");bar.edge:SetWidth(2)
        bar.nameText=Text(bar,11,T.text)
        bar.nameText:SetPoint("LEFT",7,0);bar.nameText:SetWidth(WIDTH-PAD*2-56)
        bar.percentText=Text(bar,11,T.text,"RIGHT")
        bar.percentText:SetPoint("RIGHT",-6,0);bar.percentText:SetWidth(44)
        for _,text in ipairs({bar.nameText,bar.percentText}) do
            text:SetShadowColor(0,0,0,0.9);text:SetShadowOffset(1,-1)
        end
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
    local me=Call(UnitGUID,"player")
    if not (Public(me) and type(me)=="string") then me=nil end
    local function Add(unit,owner)
        if not Truthy(UnitExists,unit) then return end
        local guid=Call(UnitGUID,unit)
        if Public(guid) and type(guid)=="string" then
            if seen[guid] then return end
            seen[guid]=true
        else guid=nil end
        list[#list+1]={unit=unit,owner=owner,player=unit=="player" or (me~=nil and guid==me)}
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
    e.unit,e.player=u.unit,u.player
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
    local entries,message={},nil
    if not self:Available() then
        message=MESSAGES.unavailable
    elseif hasTarget then
        entries=self:Collect()
        if #entries==0 then message=MESSAGES.noThreat end
    else
        message=MESSAGES.noTarget
    end
    self.entries=entries
    f.title:SetText(hasTarget and self:Available() and Name("target") or "Threat")
    f.hint:SetShown(not self.db.locked)
    f.empty:SetText(message or "");f.empty:SetShown(message~=nil)
    local T=addon.InterfaceTheme
    local shown=math.min(#entries,self.MAX_ROWS)
    for i,bar in ipairs(f.rows) do
        local e=entries[i]
        if e then
            local fill,label=M.Display(e)
            bar:SetValue(fill)
            bar:SetStatusBarColor(e.color[1],e.color[2],e.color[3],e.player and 0.9 or 0.7)
            bar.nameText:SetText(e.name)
            bar.percentText:SetText(label)
            local holding=e.aggro or e.tanking or (e.status or 0)>=2
            bar.warn=e.player and not holding and fill>=90 or false
            if e.player then Paint(bar.edge,bar.warn and WARN or T.primary) end
            bar.edge:SetShown(e.player==true)
            bar:Show()
        else
            bar:Hide()
        end
    end
    local body=shown>0 and shown*ROW+(shown-1)*GAP or ROW
    f:SetHeight(HEADER+1+PAD*2+body)
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
