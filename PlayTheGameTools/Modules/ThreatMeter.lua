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
-- Same graphite surfaces and hairlines as the settings window. The theme accent
-- marks one state only, your own row, with a stripe in its own gutter left of
-- the bar so it sits on the panel, never on a class color. Close to pulling,
-- the stripe turns red and a red frame surrounds your bar.
local WIDTH,HEADER,ROW,GAP,PAD=220,22,18,2,4
local MARK=2
local BAR_LEFT,BAR_WIDTH=PAD+MARK+GAP,WIDTH-PAD*2-MARK-GAP
local FLAT="Interface\\Buttons\\WHITE8X8"
-- Red, unlike every theme accent (mint, gold, cyan), so a warning never
-- reads as the ordinary marker.
local WARN={240/255,86/255,72/255}
M.WARN_COLOR=WARN
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

-- Placement belongs to Edit Mode; the saved lock flag is kept but no longer read.
function M:SetOption(key,value)
    if key~="showPets" and key~="hideOutOfCombat" then return false end
    if type(value)~="boolean" then return false end
    self.db[key]=value
    self:Update()
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

function M:ApplyPosition()
    if not self.frame then return end
    local PM=addon.PositionManager
    if PM.elements.threatMeter then PM:ApplyPosition("threatMeter");return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
end

function M:RegisterPosition()
    local ok,element=addon.PositionManager:RegisterModuleDisplay("threatMeter",self.frame,self,{
        label="Threat Meter",defaultX=320,defaultY=-120,canDrag=function() return self.active==true end,
        onStyleChanged=function() self:ApplyStyle() end,
        onRegistered=function(registered) registered.editMode=self.active==true;self:Update();addon.PositionManager:RefreshSelection() end})
    if ok then element.editMode=self.active==true end
end

function M:StopDrag()
    if addon.PositionManager.elements.threatMeter then addon.PositionManager:StopDragging("threatMeter") end
end

local function Paint(texture,color,alpha) texture:SetColorTexture(color[1],color[2],color[3],alpha or 1) end

local function Text(parent,size,color,justify)
    local text=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    addon.Media:BindInterfaceFont(text,GameFontHighlight,size,"threatMeter")
    text.baseSize=size
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
    -- Position Manager owns dragging; the meter itself never takes the mouse.
    f:EnableMouse(false)

    local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();addon.Media:PaintSurface(bg,T.panel,0.94,"threatMeter");f.background=bg
    f.border=addon.ConfigWidgets.Outline(f,T.lineStrong,nil,nil,nil,"threatMeter");f.border:SetColor(T.lineStrong)
    local header=f:CreateTexture(nil,"BORDER")
    header:SetPoint("TOPLEFT",1,-1);header:SetPoint("TOPRIGHT",-1,-1);header:SetHeight(HEADER);addon.Media:PaintSurface(header,T.surface,1,"threatMeter")
    local rule=f:CreateTexture(nil,"BORDER");f.header,f.rule=header,rule
    rule:SetPoint("TOPLEFT",1,-1-HEADER);rule:SetPoint("TOPRIGHT",-1,-1-HEADER);rule:SetHeight(1);Paint(rule,T.line)
    f.title=Text(f,12,T.text)
    f.title:SetPoint("TOPLEFT",PAD+5,-1);f.title:SetSize(WIDTH-PAD*2-10,HEADER)
    f.empty=Text(f,11,T.muted)
    f.empty:SetPoint("TOPLEFT",PAD+5,-(HEADER+1+PAD));f.empty:SetSize(WIDTH-PAD*2-10,ROW)

    f.rows={}
    for i=1,self.MAX_ROWS do
        local bar=CreateFrame("StatusBar",nil,f)
        bar:SetSize(BAR_WIDTH,ROW)
        bar:SetPoint("TOPLEFT",BAR_LEFT,-(HEADER+1+PAD+(i-1)*(ROW+GAP)))
        bar:SetStatusBarTexture(addon.Media:GetSurfaceTexture("threatMeter"));bar:SetMinMaxValues(0,100)
        local track=bar:CreateTexture(nil,"BACKGROUND");track:SetAllPoints();addon.Media:PaintSurface(track,T.field,1,"threatMeter")
        -- Gutter stripe, one row-gap left of the bar.
        bar.edge=bar:CreateTexture(nil,"OVERLAY")
        bar.edge:SetPoint("TOPRIGHT",bar,"TOPLEFT",-GAP,0);bar.edge:SetPoint("BOTTOMRIGHT",bar,"BOTTOMLEFT",-GAP,0)
        bar.edge:SetWidth(MARK)
        -- 1px warning frame just outside the bar, over the panel and row gaps.
        bar.warnFrame=CreateFrame("Frame",nil,bar)
        bar.warnFrame:SetPoint("TOPLEFT",-1,1);bar.warnFrame:SetPoint("BOTTOMRIGHT",1,-1)
        Outline(bar.warnFrame):SetColor(WARN)
        bar.warnFrame:Hide()
        bar.nameText=Text(bar,11,T.text)
        bar.nameText:SetPoint("LEFT",7,0);bar.nameText:SetWidth(BAR_WIDTH-56)
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
    -- refreshed on a fixed interval, but only while a target is being shown.
    -- A separate driver keeps the meter's own OnUpdate free for dragging.
    self.driver=CreateFrame("Frame",nil,f)
    self.poll=function(_,elapsed)
        self.elapsed=self.elapsed+elapsed
        if self.elapsed>=self.UPDATE_INTERVAL then self.elapsed=0;self:Update() end
    end
    f:SetScript("OnEvent",function() self:Update() end)
    self:ApplyStyle()
    self:ApplyPosition()
end

-- Layout's Style card: Text size rescales every label, Background hides the
-- panel, header and outline (the threat bars stay).
function M:ApplyStyle()
    local f=self.frame
    if not f then return end
    local PM=addon.PositionManager
    local texts={f.title,f.empty}
    for _,bar in ipairs(f.rows) do texts[#texts+1]=bar.nameText;texts[#texts+1]=bar.percentText end
    for _,text in ipairs(texts) do
        addon.Media:BindInterfaceFont(text,GameFontHighlight,PM:StyleFontSize("threatMeter",text.baseSize),"threatMeter")
    end
    local background=PM:StyleBackground("threatMeter")
    f.background:SetShown(background);f.header:SetShown(background);f.rule:SetShown(background);f.border:SetShown(background)
end

function M:SetPolling(enabled)
    local driver=self.driver
    if not driver then return end
    local current=driver:GetScript("OnUpdate")
    if enabled and not current then self.elapsed=0;driver:SetScript("OnUpdate",self.poll)
    elseif not enabled and current then driver:SetScript("OnUpdate",nil) end
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
        local c=Public(classFile) and type(classFile)=="string" and addon.GlobalSettings:GetClassColor(classFile)
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
    -- Registration needs out-of-combat geometry; retry after a combat start.
    if self.active and not addon.PositionManager.elements.threatMeter and not self:InCombat() then self:RegisterPosition() end
    -- Edit Mode and Preview reveal the meter so it can be placed.
    local placing=self.editing or self.previewing
    local show=self.active and (placing or not self.db.hideOutOfCombat or self:InCombat())
    self:SetPolling(show and hasTarget and self:Available())
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
            bar.warnFrame:SetShown(bar.warn)
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
    self:RegisterPosition()
end

function M:SetEditMode(enabled)
    self.editing=enabled and self.active or false
    local element=addon.PositionManager.elements.threatMeter
    if element then element.editMode=self.active==true end
    self:Update()
end
function M:SetPreviewMode(enabled) self.previewing=enabled and self.active or false;self:Update() end

function M:OnDisable()
    self.active,self.editing,self.previewing=false,false,false
    if not self.frame then return end
    self:StopDrag()
    self.frame:UnregisterAllEvents()
    local element=addon.PositionManager.elements.threatMeter
    if element then element.editMode=false end
    self:Update()
end
