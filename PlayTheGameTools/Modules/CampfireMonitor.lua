local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
-- An independent subfeature under the Gameplay Enhancements master, like the
-- Food Bar under Quick Access. Do not treat earned buffs as proximity evidence.
local C={NEARBY=1283391,BENEFITS=1229741,WELCOMING=1229739,CRAFTING=1289723}
addon.CampfireMonitor=C
local P=addon.LootSparkles
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Number(v,lo,hi) return Public(v) and type(v)=="number" and v==v and v>=lo and v<=hi end
local function Call(fn,...)
    if type(fn)~="function" then return false end
    local ok,v=pcall(fn,...)
    if not ok or not Public(v) then return false end
    return true,v
end
local function Field(t,key)
    if not Public(t) or type(t)~="table" then return end
    local ok,v=Call(function() return t[key] end)
    if ok then return v end
end
C.ranges={contributionX={-10000,10000,1},contributionY={-10000,10000,1},timerWarningMinutes={1,60,1},timerCriticalMinutes={1,30,1},fontSize={10,24,1},iconSize={16,64,2},width={200,600,10},scale={50,150,5},
    opacity={20,100,5},backgroundOpacity={0,100,5},benefitsX={-10000,10000,1},benefitsY={-10000,10000,1},
    benefitsWidth={100,600,10},benefitsFontSize={10,24,1},benefitsScale={50,150,5},
    benefitsOpacity={20,100,5},benefitsBackgroundOpacity={0,100,5},x={-10000,10000,1},y={-10000,10000,1}}
C.defaults={headerGradient=false,timerGradient=false,dynamicTimerColor=true,colorStats=true,showContributionPopup=true,contributionX=0,contributionY=120,timerWarningMinutes=10,timerCriticalMinutes=2,enabled=false,showIcon=true,showText=true,showBenefits=true,showNearbyDetails=false,
    showProfessionGuide=false,alwaysShow=false,showInCombat=false,locked=true,fontSize=14,
    iconSize=32,width=320,scale=100,opacity=100,backgroundOpacity=65,x=0,y=-240,compactBenefits=true,separateBenefits=false,
    benefitsLocked=true,benefitsX=260,benefitsY=-240,benefitsWidth=220,benefitsFontSize=14,
    benefitsScale=100,benefitsOpacity=100,benefitsBackgroundOpacity=0}
C.colorDefaults={textColor={1,0.85,0.5},headerColor={1,0.58,0.12},headerEndColor={1,0.12,0.08},
    timerColor={1,1,1},timerGoodColor={0.25,1,0.4},timerWarningColor={1,0.85,0.15},
    timerCriticalColor={1,0.22,0.16},critColor={1,0.25,0.25},intColor={0.25,0.55,1}}
function C.Initialize(db)
    if db.campfire==nil then db.campfire={} end
    local settings=db.campfire
    assert(type(settings)=="table","Invalid Campfire Monitor settings")
    for key,default in pairs(C.defaults) do
        if settings[key]==nil then settings[key]=default end
        local v,r=settings[key],C.ranges[key]
        assert(Public(v) and type(v)==type(default),"Invalid Campfire Monitor setting: "..key)
        if r then assert(Number(v,r[1],r[2]) and (v-r[1])%r[3]==0,"Invalid Campfire Monitor range: "..key) end
    end
    assert(settings.timerCriticalMinutes<settings.timerWarningMinutes,"Red threshold must be below yellow threshold")
    for key,default in pairs(C.colorDefaults) do
        if settings[key]==nil then settings[key]={unpack(default)} end
        assert(Public(settings[key]) and type(settings[key])=="table","Invalid Campfire Monitor color: "..key)
        for i=1,3 do assert(Number(settings[key][i],0,1),"Invalid Campfire Monitor color: "..key) end
    end
end

-- Read only player HELPFUL auras through the documented modern accessor.
-- A complete readable scan proves absence. Restricted/error/truncated data is
-- unknown, clears prior proximity, and never masquerades as a departure/arrival.
function C:Scan()
    local snapshot={nearby=false,known=false}
    local fn=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(fn)~="function" then snapshot.message="Player aura API unavailable.";return snapshot end
    local uncertain=false
    for index=1,255 do
        local ok,aura=Call(fn,"player",index,"HELPFUL")
        if not ok then uncertain=true;break end
        if aura==nil then snapshot.known=not uncertain;snapshot.complete=not uncertain;break end
        local id=Field(aura,"spellId")
        if not Number(id,1,2147483647) then uncertain=true
        else
            local kind=id==self.NEARBY and "near" or id==self.BENEFITS and "benefits" or
                (id==self.WELCOMING or id==self.CRAFTING) and "welcoming" or nil
            if kind then
                snapshot[kind]={index=index,instance=Field(aura,"auraInstanceID"),icon=Field(aura,"icon"),duration=Field(aura,"duration"),expiration=Field(aura,"expirationTime")}
                if kind=="near" then snapshot.nearby=true end
            end
        end
    end
    if snapshot.nearby then snapshot.known=true end
    if not snapshot.known then snapshot.message="Campfire status unavailable." end
    return snapshot
end

-- Preserve the client's own localized descriptions, amounts and bonus rows.
-- This raw reader does not infer stats; compact formatting happens separately.
-- No tooltip-frame scraping, hooks or guessed stat amounts.
function C:TooltipLines(aura)
    if not aura or not C_TooltipInfo then return {} end
    local ok,data
    if Number(aura.instance,1,2147483647) and type(C_TooltipInfo.GetUnitBuffByAuraInstanceID)=="function" then
        ok,data=Call(C_TooltipInfo.GetUnitBuffByAuraInstanceID,"player",aura.instance)
    elseif type(C_TooltipInfo.GetUnitAura)=="function" then
        ok,data=Call(C_TooltipInfo.GetUnitAura,"player",aura.index,"HELPFUL")
    end
    local source=ok and Field(data,"lines")
    if not Public(source) or type(source)~="table" then return {} end
    local lines,seen={},{}
    for i=2,64 do
        local row=Field(source,i)
        if row==nil then break end
        local label=Field(row,"leftText")
        if not (type(label)=="string" and self:IsMetadata(label)) then
            for _,key in ipairs({"leftText","rightText"}) do
                local text=Field(row,key)
                if type(text)=="string" then
                    text=text:sub(1,2048):gsub("|cn[%w_]+:",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
                    text=text:gsub("\194\160"," ")
                    text=text:gsub("|T.-|t",""):gsub("|A.-|a","")
                    for line in text:gmatch("[^\r\n]+") do
                        line=line:match("^%s*(.-)%s*$")
                        local lower=line:lower()
                        local metadata=lower:find("%s*%(%s*spell%s*id%s*:%s*#?%s*%d+%s*%)%s*$") or
                            lower:find("%s*%[%s*spell%s*id%s*:%s*#?%s*%d+%s*%]%s*$") or
                            lower:find("%s+spell%s*id%s*:%s*#?%s*%d+%s*$")
                        if metadata then line=line:sub(1,metadata-1):match("^%s*(.-)%s*$") end
                        if line~="" and not self:IsMetadata(line) and not self:IsTimerLine(line) and not self:IsBuffPreamble(line) and not seen[line] then lines[#lines+1]=line;seen[line]=true end
                    end
                end
            end
        end
    end
    return lines
end

-- General profession reference, never a claim about the nearby camp's objects.
C.professions={
    {"Alchemy","Mana regeneration"},{"Blacksmithing","Strength"},
    {"Cooking","Cooking and camp feature slots"},{"Enchanting","Armor, stats and resistances"},
    {"Engineering","Reagents; higher-tier services"},{"First Aid","Stamina"},
    {"Fishing","All stats"},{"Herbalism","Intellect"},{"Leatherworking","Rested experience"},
    {"Mining","Melee attack power"},{"Skinning","Critical strike chance"},{"Tailoring","Spirit"},
}
-- Compact only unambiguous English stat descriptions. Values always come from
-- the current native tooltip; unfamiliar/localized text remains readable as-is.
local stats={
    {"critical","Crit"},{"critically","Crit"},{"crit","Crit"},{"all stats","Stats"},{"all attributes","Stats"},{"stats","Stats"},
    {"resistance","Resists"},{"resistances","Resists"},{"attack power","AP"},{"spell damage","Spell Power"},
    {"spell power","Spell Power"},{"healing","Healing"},{"strength","Strength"},
    {"stamina","Stamina"},{"intellect","Int"},{"spirit","Spirit"},{"armor","Armor"},
    {"rested","Rested XP"},{"mana","Mana"},
}
function C.CompactLine(line)
    local body=line:match("^[^:]+:%s*(.+)$") or line
    local prefix=(line:match("^([^:]+):") or ""):lower()
    local segments=body:gsub(",%s+","\n"):gsub(";%s*","\n")
    local results,unknown={},{}
    for segment in segments:gmatch("[^\n]+") do
        local lower=segment:lower();local label,ambiguous
        for _,entry in ipairs(stats) do
            if lower:find("%f[%a]"..entry[1].."%f[%A]") then
                if label and label~=entry[2] then ambiguous=true end
                label=entry[2]
            end
        end
        if not label then
            for _,entry in ipairs(stats) do
                if prefix:find("%f[%a]"..entry[1].."%f[%A]") then
                    if label and label~=entry[2] then ambiguous=true end
                    label=entry[2]
                end
            end
        end
        local values={}
        for value,percent in segment:gmatch("([%+%-]?%d[%d%.,]*)%s*(%%?)") do
            value=value:gsub("^%+",""):gsub("[%.,]+$","")
            values[#values+1]=value..percent
        end
        local short
        if label and not ambiguous then
            if #values==1 then short=values[1].." "..label
            elseif #values==0 and label=="Rested XP" then short=label
            elseif label=="Mana" and #values==2 then
                local period=lower:match("every%s+(%d+)%s+sec")
                if period and values[2]==period then short=values[1].." Mana / "..period.." sec" end
            end
        end
        if short then results[#results+1]=short
        else
            local fragment=segment:match("^%s*(.-)%s*$")
            if fragment~="" and fragment:lower()~="and" then unknown[#unknown+1]=fragment end
        end
    end
    if #results==0 then return {line} end
    for _,fragment in ipairs(unknown) do results[#results+1]=fragment end
    return results
end
-- Native public timing only. A private/missing expiration never becomes a
-- guessed hour-long timer. Edit/preview samples are explicitly labeled.
function C:IsBuffSample()
    return self.previewing or (self.editing and not (self.snapshot or {}).benefits)
end
function C:Remaining()
    if self:IsBuffSample() then return 2700 end
    local aura=(self.snapshot or {}).benefits
    if not aura or not Number(aura.expiration,0.001,1e12) or not Number(aura.duration,0.001,1e9) then return end
    local ok,now=Call(GetTime)
    if ok and Number(now,0,1e12) then return math.max(0,aura.expiration-now) end
end
function C:TimerColor(seconds)
    if not self.db.dynamicTimerColor then return self.db.timerColor end
    if not Number(seconds,0,1e12) then return self.db.timerColor end
    if seconds<=self.db.timerCriticalMinutes*60 then return self.db.timerCriticalColor end
    if seconds<=self.db.timerWarningMinutes*60 then return self.db.timerWarningColor end
    return self.db.timerGoodColor
end
function C:TimerLabel()
    local seconds=self:Remaining()
    if seconds==nil then return "Time unavailable",nil end
    local whole=math.ceil(seconds)
    local text
    if whole<=0 then text="Expired"
    elseif whole>=3600 then text=string.format("%d:%02d:%02d remaining",math.floor(whole/3600),math.floor(whole/60)%60,whole%60)
    else text=string.format("%02d:%02d remaining",math.floor(whole/60),whole%60) end
    if self:IsBuffSample() then text="Preview: "..text end
    return text,seconds
end
function C.Gradient(text,first,last)
    local output={}
    for i=1,#text do
        local t=(i-1)/math.max(1,#text-1)
        local function Channel(n) return math.floor((first[n]+(last[n]-first[n])*t)*255+0.5) end
        output[i]=string.format("|cff%02x%02x%02x%s|r",Channel(1),Channel(2),Channel(3),text:sub(i,i))
    end
    return table.concat(output)
end
local buffColors={
    {"crit",{1,0.25,0.25}}, {"critical",{1,0.25,0.25}}, {"critically",{1,0.25,0.25}},
    {"int",{0.25,0.55,1}}, {"intellect",{0.25,0.55,1}}, {"stats",{0.8,0.55,1}},
    {"stamina",{0.3,1,0.5}}, {"strength",{1,0.6,0.25}}, {"spirit",{0.3,0.95,0.95}},
    {"armor",{0.7,0.8,0.9}}, {"ap",{1,0.85,0.3}}, {"attack power",{1,0.85,0.3}},
    {"spell power",{0.75,0.45,1}}, {"healing",{0.3,1,0.75}}, {"mana",{0.45,0.75,1}},
    {"rested",{1,0.9,0.55}}, {"resists",{1,0.5,0.85}}, {"resistance",{1,0.5,0.85}},
    {"resistances",{1,0.5,0.85}},
}
function C:BuffColor(line)
    if not self.db.colorStats then return self.db.textColor end
    local lower=line:lower()
    if lower:find("%f[%a]crit%f[%A]") or lower:find("critical",1,true) then return self.db.critColor end
    if lower:find("%f[%a]int%f[%A]") or lower:find("intellect",1,true) then return self.db.intColor end
    for _,entry in ipairs(buffColors) do
        if lower:find("%f[%a]"..entry[1].."%f[%A]") then return entry[2] end
    end
    return self.db.textColor
end
function C:ColorBuffText(text)
    local lines={}
    for line in text:gmatch("[^\n]+") do
        local rgb=self:BuffColor(line)
        lines[#lines+1]=string.format("|cff%02x%02x%02x%s|r",math.floor(rgb[1]*255+0.5),
            math.floor(rgb[2]*255+0.5),math.floor(rgb[3]*255+0.5),line)
    end
    return table.concat(lines,"\n")
end
-- Strip native aura footer timing, not amounts such as Mana every 5 sec.
function C:IsBuffPreamble(line)
    local text=line:lower():gsub("folloing","following"):gsub("[%p]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    return text=="camp benefits" or text=="camp buffs" or
        text:match("^you have gained the following camp benefits$") or
        text:match("^you gained the following camp benefits$") or
        text:match("^gained the following camp benefits$") or
        text:match("^the following camp benefits$")
end
function C:IsTimerLine(line)
    local text=line:lower():gsub("[()]", ""):gsub("remaing", "remaining")
        :gsub("%s+", " "):match("^%s*(.-)%s*$")
    text=text:gsub("[%.!:%s]+$", "")
    text=text:gsub("^time%s+remaining%s*:?%s*",""):gsub("^remaining%s+time%s*:?%s*","")
        :gsub("^time%s+left%s*:?%s*",""):gsub("^remaining%s*:?%s*","")
        :gsub("^duration%s*:?%s*",""):gsub("^expires?%s+in%s+","")
        :gsub("%s+remaining[%.!]?%s*$",""):gsub("%s+left[%.!]?%s*$","")
    if text:match("^%d+:%d%d$") or text:match("^%d+:%d%d:%d%d$") then return true end
    local units={d=true,day=true,days=true,h=true,hr=true,hrs=true,hour=true,hours=true,
        m=true,min=true,mins=true,minute=true,minutes=true,s=true,sec=true,secs=true,second=true,seconds=true}
    local count=0
    local remainder=text:gsub("(%d[%d%.,]*)%s*(%a+)",function(amount,unit)
        if units[unit] then count=count+1;return "" end
        return amount..unit
    end):gsub("[%s,%.]+","")
    return count>0 and remainder==""
end
function C:IsMetadata(line)
    local lower=line:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):lower()
    if lower:match("^spell%s*id%s*[:#%-]?%s*#?%s*%d+%s*$") or
        lower:match("^aura%s*id%s*[:#%-]?%s*#?%s*%d+%s*$") or
        lower:match("^id%s*[:#]%s*%d+%s*$") or lower:match("^spell%s*id%s*[:#]?%s*$") then return true end
    local id=tonumber(lower)
    return id==self.NEARBY or id==self.BENEFITS or id==self.WELCOMING or id==self.CRAFTING
end
function C:MonitorStatus()
    local s=self.snapshot or {}
    if self.previewing then return "Preview: Campfire Nearby" end
    if s.nearby then return "Campfire Nearby" end
    if s.known or self.editing or self.placing then return "No Nearby Campfire" end
    return "Campfire Status Unavailable"
end
function C:StyledText(text,first,last,gradient)
    if gradient then return self.Gradient(text,first,last) end
    return string.format("|cff%02x%02x%02x%s|r",math.floor(last[1]*255+0.5),
        math.floor(last[2]*255+0.5),math.floor(last[3]*255+0.5),text)
end
function C:HeaderText(text)
    return self:StyledText(text,self.db.headerColor,self.db.headerGradient and self.db.headerEndColor or self.db.headerColor,self.db.headerGradient)
end
function C:UpdateTimerText()
    local label,seconds=self:TimerLabel()
    local colored=self:StyledText(label,self.db.timerColor,self:TimerColor(seconds),self.db.timerGradient)
    for _,f in pairs({self.frame,self.benefitsFrame}) do
        if f and f.buffTimer and f:IsShown() and f.buffTimer:IsShown() then f.buffTimer:SetText(colored) end
    end
end
function C:UpdateTimerDriver()
    if not self.timerDriver then self.timerDriver=CreateFrame("Frame") end
    self.timerDriver:SetScript("OnUpdate",nil)
    local visible=false
    for _,f in pairs({self.frame,self.benefitsFrame}) do
        if f and f:IsShown() and f.buffTimer:IsShown() then visible=true end
    end
    if not visible or self:IsBuffSample() or self:Remaining()==nil then return end
    local elapsed=0
    self.timerDriver:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=1 then elapsed=0;self:UpdateTimerText() end
    end)
end

function C:BuildBenefitsText()
    local s=self.snapshot or {}
    if self:IsBuffSample() then return "2% Crit\n8% Stats" end
    if not s.benefits then
        if self.placing then return "No active buffs" end
        return s.complete and "No Camp Benefits detected." or "Camp Benefits unavailable."
    end
    local lines=self:TooltipLines(s.benefits)
    if #lines==0 then return "Native benefit details unavailable." end
    if not self.db.compactBenefits then return table.concat(lines,"\n") end
    local compact,seen={},{}
    for _,line in ipairs(lines) do
        for _,short in ipairs(self.CompactLine(line)) do
            if not seen[short] then compact[#compact+1]=short;seen[short]=true end
        end
    end
    return table.concat(compact,"\n")
end

function C:BuildText()
    local s,parts=self.snapshot or {},{}
    if self.db.showNearbyDetails and s.near and not self.previewing then
        local lines=self:TooltipLines(s.near)
        if #lines>0 then parts[#parts+1]="Nearby camp (native)";for _,line in ipairs(lines) do parts[#parts+1]=line end end
    end
    if self.db.showProfessionGuide then
        parts[#parts+1]="Profession guide (possible features)"
        for _,entry in ipairs(self.professions) do parts[#parts+1]=entry[1]..": "..entry[2] end
    end
    return table.concat(parts,"\n")
end
function C:SetOption(key,value)
    if not P:OutsideCombat() or (self.defaults[key]==nil and self.colorDefaults[key]==nil) then return false end
    if not Public(value) then return false end
    local candidate=addon.ProfileCodec.Copy(self.owner.db);candidate.campfire[key]=value
    if not pcall(self.Initialize,candidate) then return false end
    self.db[key]=type(value)=="table" and {unpack(value)} or value
    if self.SyncPositionOption then self:SyncPositionOption(key) end
    self:SyncEnabled()
    if self.owner.page then self.owner.page:Refresh() end
    return true
end
function C:Refresh()
    if not self.active and not self.previewing and not self.placing then
        self:HideDisplays()
        if addon.CampContributions then addon.CampContributions:OnSnapshot(self.snapshot) end
        return
    end
    local combat=not P:OutsideCombat()
    if combat and (not self.db.showInCombat or self.previewing or self.placing) then
        self.previewing=false;self.placing=false;self.snapshot={known=false,message="Paused during combat."}
        self:StopDrag();self:HideDisplays()
    else
        self.snapshot=self.active and self:Scan() or {known=false}
        self:Render()
    end
    if addon.CampContributions then addon.CampContributions:OnSnapshot(self.snapshot) end
    if self.owner.page then self.owner.page:Refresh() end
end
function C:SyncEnabled()
    self.active=self.owner.active==true and self.db.enabled
    self.editing=self.active and addon.editMode and P:OutsideCombat() or false
    if not self.events then self.events=CreateFrame("Frame") end
    self.events:UnregisterAllEvents()
    if self.active then
        self.events:RegisterUnitEvent("UNIT_AURA","player")
        self.events:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    if self.active or self.previewing or self.placing then self.events:RegisterEvent("PLAYER_REGEN_DISABLED") end
    self.events:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_AURA" and (not Public(unit) or unit~="player") then return end
        if event=="PLAYER_REGEN_DISABLED" then
            if addon.CampContributions then addon.CampContributions.previewing=false end
            self:StopDrag();self.previewing=false;self.placing=false;self:SyncEnabled();return
        end
        self:Refresh()
    end)
    if addon.CampContributions then addon.CampContributions:SyncEnabled(self) end
    self:SyncEditDisplays()
    self:Refresh()
end
function C:SetPlacementMode(enabled)
    if enabled and not P:OutsideCombat() then return false end
    if not enabled then self:StopDrag() end
    self.placing=enabled==true;self:SyncEnabled();return true
end
function C:TogglePreview()
    if not P:OutsideCombat() then return false end
    self.previewing=not self.previewing;self:SyncEnabled();return true
end
function C:StopPreview()
    if addon.CampContributions then addon.CampContributions:StopPreview() end
    if self.previewing then self.previewing=false;self:SyncEnabled() end
end
function C:Attach(owner)
    self.owner=owner;self.db=owner.db.campfire;self.snapshot={known=false}
    self:SyncEnabled()
end
