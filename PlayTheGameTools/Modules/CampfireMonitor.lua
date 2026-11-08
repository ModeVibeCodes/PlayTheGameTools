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
C.ranges={contributionX={-10000,10000,1},contributionY={-10000,10000,1},contributionScale={50,150,5},contributionOpacity={20,100,5},contributionBackgroundOpacity={0,100,5},fontSize={10,24,1},iconSize={16,64,2},width={200,600,10},scale={50,150,5},
    opacity={20,100,5},backgroundOpacity={0,100,5},benefitsX={-10000,10000,1},benefitsY={-10000,10000,1},
    benefitsWidth={100,600,10},benefitsFontSize={10,24,1},benefitsScale={50,150,5},
    benefitsOpacity={20,100,5},benefitsBackgroundOpacity={0,100,5},x={-10000,10000,1},y={-10000,10000,1}}
C.defaults={headerGradient=false,contributionScale=100,contributionOpacity=100,contributionBackgroundOpacity=95,colorStats=true,showContributionPopup=true,contributionX=0,contributionY=120,enabled=false,showIcon=true,showText=true,showBenefits=true,showNearbyDetails=false,
    showProfessionGuide=false,alwaysShow=false,showInCombat=false,locked=true,fontSize=14,
    iconSize=32,width=320,scale=100,opacity=100,backgroundOpacity=65,x=0,y=-240,compactBenefits=true,separateBenefits=false,
    benefitsLocked=true,benefitsX=260,benefitsY=-240,benefitsWidth=220,benefitsFontSize=14,
    benefitsScale=100,benefitsOpacity=100,benefitsBackgroundOpacity=0}
C.colorDefaults={textColor={1,0.85,0.5},headerColor={1,0.58,0.12},headerEndColor={1,0.12,0.08}}
-- Contribution appearance stays independent of the icon and Camp Buffs.
C.contributionDefaults={contributionWidth=450,contributionPadding=10,contributionRowHeight=44,
    contributionRowGap=4,contributionVisibleRows=6,contributionIconSize=36,
    contributionTitleSize=14,contributionNameSize=13,contributionInfoSize=11,contributionActionSize=11,
    contributionHintSize=11,contributionFooterSize=11,contributionDismissSize=11,contributionBorderSize=1,contributionBorderOpacity=100,
    contributionRowOpacity=95,contributionIconOpacity=100,contributionHoverOpacity=15,
    contributionShowTitle=true,contributionShowHint=true,contributionShowFooter=true,
    contributionShowIcons=true,contributionShowNames=true,contributionShowProfession=true,
    contributionShowCount=true,contributionShowAction=true,contributionTooltips=true,
    contributionLocked=false,contributionOutline=false,contributionHeaderGradient=false,
    contributionUseInterfaceFont=true,contributionFont="game",contributionFontMedia="",
    contributionTitleAlign="LEFT",contributionTextAlign="LEFT"}
local contributionRanges={Width={280,700,10},Padding={6,24,1},RowHeight={32,96,1},RowGap={0,16,1},VisibleRows={1,12,1},
    IconSize={16,64,1},TitleSize={10,28,1},NameSize={10,24,1},InfoSize={9,20,1},ActionSize={9,24,1},
    HintSize={9,20,1},FooterSize={9,20,1},DismissSize={9,20,1},BorderSize={1,4,1},BorderOpacity={0,100,5},
    RowOpacity={0,100,5},IconOpacity={0,100,5},HoverOpacity={0,100,5}}
for key,value in pairs(C.contributionDefaults) do C.defaults[key]=value end
for key,value in pairs(contributionRanges) do C.ranges["contribution"..key]=value end
C.contributionColors={contributionBackgroundColor={0.035,0.045,0.06},contributionBorderColor={0.32,0.40,0.48},
    contributionRowColor={0.10,0.14,0.18},contributionHoverColor={1,1,1},contributionTitleColor={1,0.58,0.12},
    contributionTitleEndColor={1,0.12,0.08},contributionNameColor={1,1,1},contributionInfoColor={0.65,0.72,0.8},
    contributionDismissColor={1,1,1},contributionActionColor={1,0.82,0.35},contributionHintColor={0.65,0.72,0.8},contributionFooterColor={0.65,0.72,0.8}}
for key,value in pairs(C.contributionColors) do C.colorDefaults[key]=value end
function C.Initialize(db)
    if db.campfire==nil then db.campfire={} end
    local settings=db.campfire
    assert(type(settings)=="table","Invalid Campfire Monitor settings")
    for key,default in pairs(C.defaults) do
        if settings[key]==nil then settings[key]=default end
        local v,r=settings[key],C.ranges[key]
        -- Earlier contribution drags could copy fractional managed coordinates
        -- into integer-only settings, rejecting every subsequent customization.
        if (key=="contributionX" or key=="contributionY") and Number(v,-10000,10000) then
            v=math.floor(v+0.5);settings[key]=v
        end
        assert(Public(v) and type(v)==type(default),"Invalid Campfire Monitor setting: "..key)
        if r then assert(Number(v,r[1],r[2]) and (v-r[1])%r[3]==0,"Invalid Campfire Monitor range: "..key) end
    end
    assert(settings.contributionFont=="game" or settings.contributionFont=="chat","Invalid contribution font")
    assert(#settings.contributionFontMedia<=128,"Invalid contribution media font")
    for _,key in ipairs({"contributionTitleAlign","contributionTextAlign"}) do
        assert(settings[key]=="LEFT" or settings[key]=="CENTER" or settings[key]=="RIGHT","Invalid contribution alignment")
    end
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
                        if line~="" and not self:IsMetadata(line) and not self:IsBuffPreamble(line) and not seen[line] then lines[#lines+1]=line;seen[line]=true end
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
-- Edit Mode supplies sample buffs only when no earned native benefits exist.
function C:IsBuffSample()
    return self.previewing or (self.editing and not (self.snapshot or {}).benefits)
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
-- Omit tooltip introduction/headings; keep native duration text below the stats.
function C:IsBuffPreamble(line)
    local text=line:lower():gsub("folloing","following"):gsub("[%p]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    return text=="camp benefits" or text=="camp buffs" or
        text:match("^you have gained the following camp benefits$") or
        text:match("^you gained the following camp benefits$") or
        text:match("^gained the following camp benefits$") or
        text:match("^the following camp benefits$")
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
    if key=="contributionFont" then self.db.contributionFontMedia="" end
    if key=="contributionX" or key=="contributionY" then
        local PM=addon.PositionManager
        if PM.elements.campfireContributions then PM:SetOffsets("campfireContributions",self.db.contributionX,self.db.contributionY)
        elseif addon.db.positions and addon.db.positions.campfireContributions then
            local saved=addon.db.positions.campfireContributions
            saved.x,saved.y=self.db.contributionX,self.db.contributionY
        end
    elseif self.SyncPositionOption then self:SyncPositionOption(key) end
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
