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
C.ranges={fontSize={10,24,1},iconSize={16,64,2},width={200,600,10},scale={50,150,5},
    opacity={20,100,5},backgroundOpacity={0,100,5},benefitsX={-10000,10000,1},benefitsY={-10000,10000,1},
    benefitsWidth={100,600,10},benefitsFontSize={10,24,1},benefitsScale={50,150,5},
    benefitsOpacity={20,100,5},benefitsBackgroundOpacity={0,100,5},x={-10000,10000,1},y={-10000,10000,1}}
C.defaults={enabled=false,showIcon=true,showText=true,showBenefits=true,showNearbyDetails=false,
    showProfessionGuide=false,alwaysShow=false,showInCombat=false,locked=true,fontSize=14,
    iconSize=32,width=320,scale=100,opacity=100,backgroundOpacity=65,x=0,y=-240,compactBenefits=true,separateBenefits=false,
    benefitsLocked=true,benefitsX=260,benefitsY=-240,benefitsWidth=220,benefitsFontSize=14,
    benefitsScale=100,benefitsOpacity=100,benefitsBackgroundOpacity=0}
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
    if settings.textColor==nil then settings.textColor={1,0.85,0.5} end
    assert(type(settings.textColor)=="table","Invalid Campfire Monitor color")
    for i=1,3 do assert(Number(settings.textColor[i],0,1),"Invalid Campfire Monitor color") end
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
                snapshot[kind]={index=index,instance=Field(aura,"auraInstanceID"),icon=Field(aura,"icon")}
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
        for _,key in ipairs({"leftText","rightText"}) do
            local text=Field(row,key)
            if type(text)=="string" then
                text=text:sub(1,2048):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
                text=text:gsub("|T.-|t",""):gsub("|A.-|a","")
                for line in text:gmatch("[^\r\n]+") do
                    line=line:match("^%s*(.-)%s*$")
                    if line~="" and not seen[line] then lines[#lines+1]=line;seen[line]=true end
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
function C:BuildBenefitsText()
    local s=self.snapshot or {}
    if self.previewing then return "Preview buffs\n2% Crit\n8% Stats" end
    if not s.benefits then
        if self.placing then return "Camp buffs" end
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
    local s,db=self.snapshot or {},self.db
    local title=self.previewing and "Preview: Campfire Nearby" or
        (not self.active and self.placing and "Campfire Monitor") or
        (s.nearby and (s.welcoming and "Campfire Nearby - Resting" or "Campfire Nearby") or
        (s.known and "No nearby campfire" or (s.message or "Campfire status unavailable.")))
    local parts={}
    if db.showText or not db.showIcon then parts[#parts+1]=title end
    if db.showNearbyDetails and s.near and not self.previewing then
        local lines=self:TooltipLines(s.near)
        if #lines>0 then parts[#parts+1]="Nearby camp (native)";for _,line in ipairs(lines) do parts[#parts+1]=line end end
    end
    if db.showBenefits and not db.separateBenefits then
        if not db.compactBenefits and s.benefits then parts[#parts+1]="Your Camp Benefits" end
        parts[#parts+1]=self:BuildBenefitsText()
    end
    if db.showProfessionGuide then
        parts[#parts+1]="Profession guide (possible features)"
        for _,entry in ipairs(self.professions) do parts[#parts+1]=entry[1]..": "..entry[2] end
    end
    return table.concat(parts,"\n")
end
function C:SetOption(key,value)
    if not P:OutsideCombat() or (self.defaults[key]==nil and key~="textColor") then return false end
    if not Public(value) then return false end
    local candidate=addon.ProfileCodec.Copy(self.owner.db);candidate.campfire[key]=value
    if not pcall(self.Initialize,candidate) then return false end
    self.db[key]=type(value)=="table" and {unpack(value)} or value
    self:SyncEnabled()
    if self.owner.page then self.owner.page:Refresh() end
    return true
end
function C:Refresh()
    if not self.active and not self.previewing and not self.placing then self:HideDisplays();return end
    local combat=not P:OutsideCombat()
    if combat and (not self.db.showInCombat or self.previewing or self.placing) then
        self.previewing=false;self.placing=false;self.snapshot={known=false,message="Paused during combat."}
        self:StopDrag();self:HideDisplays()
    else
        self.snapshot=self.active and self:Scan() or {known=false}
        self:Render()
    end
    if self.owner.page then self.owner.page:Refresh() end
end
function C:SyncEnabled()
    self.active=self.owner.active==true and self.db.enabled
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
            self:StopDrag();self.previewing=false;self.placing=false;self:SyncEnabled();return
        end
        self:Refresh()
    end)
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
    if self.previewing then self.previewing=false;self:SyncEnabled() end
end
function C:Attach(owner)
    self.owner=owner;self.db=owner.db.campfire;self.snapshot={known=false}
    self:SyncEnabled()
end
