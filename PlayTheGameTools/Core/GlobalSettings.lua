local _,addon=...
local G={status={},lootGeneration=0}
addon.GlobalSettings=G
G.classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local classDefaults={WARRIOR={.78,.61,.43},PALADIN={.96,.55,.73},HUNTER={.67,.83,.45},ROGUE={1,.96,.41},
    PRIEST={1,1,1},SHAMAN={0,.44,.87},MAGE={.25,.78,.92},WARLOCK={.53,.53,.93},DRUID={1,.49,.04}}
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Number(v,low,high) return Public(v) and type(v)=="number" and v==v and v>=low and v<=high end
local function Combat() return InCombatLockdown() or UnitAffectingCombat("player") end
local function Read(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d,e,f,g=pcall(fn,...)
    if not ok then return end
    local function Safe(v) if Public(v) then return v end end
    return Safe(a),Safe(b),Safe(c),Safe(d),Safe(e),Safe(f),Safe(g)
end
function G:ValidateOptions(db)
    assert(type(db)=="table","Global options must be a table; retained.")
    for key,default in pairs({autoLoot=false,adoptAutoLoot=false,fastLoot=false,cameraZoom=4,autoScale=true,uiScale=71,hideErrors=false}) do
        if db[key]==nil then db[key]=default end
        assert(type(db[key])==type(default),"Invalid global option: "..key)
    end
    assert(Number(db.cameraZoom,1,4),"Invalid camera zoom factor.")
    assert(Number(db.uiScale,40,115),"Invalid global UI scale.")
    if db.classColors==nil then db.classColors={} end
    assert(type(db.classColors)=="table","Invalid class colors.")
    for class,color in pairs(db.classColors) do
        assert(classDefaults[class] and type(color)=="table","Invalid class color.")
        for i=1,3 do assert(Number(color[i],0,1),"Invalid class color channel.") end
    end
end
function G:Prepare(profile)
    if profile.globalOptions==nil then
        local old=profile.modules and profile.modules.foreverAutomation
        local optedIn=old and old.enabled==true and old.autoLoot==true or false
        profile.globalOptions={autoLoot=optedIn,adoptAutoLoot=not optedIn}
    end
    self:ValidateOptions(profile.globalOptions)
end
function G:GetClassColor(class)
    if not Public(class) or type(class)~="string" then return end
    local options=addon.db and addon.db.globalOptions
    local color=options and options.classColors[class]
    if color then return {r=color[1],g=color[2],b=color[3]} end
    local native=Read(C_ClassColor and C_ClassColor.GetClassColor,class) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if Public(native) and type(native)=="table" and Number(native.r,0,1) and Number(native.g,0,1) and Number(native.b,0,1) then return native end
    color=classDefaults[class]
    if color then return {r=color[1],g=color[2],b=color[3]} end
end
function G:SetClassColor(class,color)
    if Combat() or not classDefaults[class] then return false end
    if color~=nil then
        if type(color)~="table" then return false end
        for i=1,3 do if not Number(color[i],0,1) then return false end end
        color={color[1],color[2],color[3]}
    end
    addon.db.globalOptions.classColors[class]=color
    addon.ReloadManager:Request("classColors","Apply custom class colors throughout the addon.")
    return true
end
function G:Resolution()
    local width,height=Read(GetPhysicalScreenSize)
    if Number(width,320,32768) and Number(height,200,32768) then return width,height end
end
function G:RecommendedScale()
    local _,height=self:Resolution()
    if height then return math.max(40,math.min(115,768/height*100)) end
    return addon.db.globalOptions.uiScale
end
function G:WriteCVar(name,value)
    if Combat() then return false end
    local current,_,_,_,locked,secure,readOnly=Read(C_CVar and C_CVar.GetCVarInfo,name)
    if type(current)~="string" or locked~=false or secure~=false or readOnly~=false then
        self.status[name]="Unavailable or restricted by the game.";return false
    end
    if current~=tostring(value) then
        local accepted=Read(C_CVar.SetCVar,name,tostring(value))
        if accepted~=true then self.status[name]="The game did not accept this setting.";return false end
    end
    local result=Read(C_CVar.GetCVar,name)
    if type(result)~="string" then result=select(1,Read(C_CVar.GetCVarInfo,name)) end
    local numeric=tonumber(result)
    if not Number(numeric,0,100) then self.status[name]="Cannot verify the accepted value.";return false end
    self.status[name]=math.abs(numeric-tonumber(value))<.001 and "Applied." or ("Game accepted "..result.." (clamped).")
    return true,numeric
end
function G:ApplyScale()
    if Combat() then self.pending=true;return end
    if self.applyingScale then return end
    local desired=self.db.autoScale and self:RecommendedScale() or self.db.uiScale
    if self.db.autoScale and not self:Resolution() then self.status.uiScale="Resolution is not available yet.";return end
    self.applyingScale=true
    if not self:WriteCVar("useUiScale",1) then self.applyingScale=false;return end
    -- The native graphics slider starts at .65. UIParent's supported scale API
    -- also allows the pixel-based 768/1440 scale below that graphics-slider floor.
    if not self:WriteCVar("uiScale",math.max(.65,desired/100)) then self.applyingScale=false;return end
    local ok=pcall(UIParent.SetScale,UIParent,desired/100)
    local actual=Read(UIParent.GetScale,UIParent)
    self.status.uiScale=ok and Number(actual,.1,2) and math.abs(actual-desired/100)<.001 and "Applied." or "The game did not accept the UI scale."
    self.applyingScale=false
end
function G:ApplyErrors()
    local frame=UIErrorsFrame
    if not frame or not frame.IsEventRegistered then return end
    if self.db.hideErrors then
        if not self.errorOwner then
            self.restoreErrors=Read(frame.IsEventRegistered,frame,"UI_ERROR_MESSAGE")==true
            frame:UnregisterEvent("UI_ERROR_MESSAGE");self.errorOwner=frame
        end
    elseif self.errorOwner then
        if self.restoreErrors and not self.errorOwner:IsEventRegistered("UI_ERROR_MESSAGE") then self.errorOwner:RegisterEvent("UI_ERROR_MESSAGE") end
        self.errorOwner,self.restoreErrors=nil,nil
    end
end
function G:Apply()
    if Combat() then self.pending=true;return end
    self.pending=false
    local ok,value=self:WriteCVar("cameraDistanceMaxZoomFactor",self.db.cameraZoom)
    if ok and Number(value,1,4) then self.db.cameraZoom=value end
    if self.db.adoptAutoLoot then
        local native=Read(C_CVar and C_CVar.GetCVarBool,"autoLootDefault")
        if type(native)=="boolean" then self.db.autoLoot=native;self.db.adoptAutoLoot=false end
    end
    if not self.db.adoptAutoLoot then self:WriteCVar("autoLootDefault",self.db.autoLoot and 1 or 0) end
    self:ApplyScale();self:ApplyErrors()
end
function G:SetOption(key,value)
    if Combat() or not ({autoLoot=true,fastLoot=true,cameraZoom=true,autoScale=true,uiScale=true,hideErrors=true})[key] then return false end
    local candidate=addon.ProfileCodec.Copy(self.db);candidate[key]=value
    if not pcall(self.ValidateOptions,self,candidate) then return false end
    self.db[key]=value
    if key=="uiScale" then self.db.autoScale=false end
    if key=="autoLoot" then self.db.adoptAutoLoot=false;self:WriteCVar("autoLootDefault",value and 1 or 0) end
    if key=="fastLoot" then self:ConfigureLoot() end
    self:Apply()
    if addon.configWindow then addon:RefreshConfig() end
    return true
end
function G:ConfigureLoot()
    self.lootGeneration=self.lootGeneration+1
    for _,event in ipairs({"LOOT_READY","LOOT_CLOSED"}) do
        self.events:UnregisterEvent(event)
        if self.db.fastLoot then self.events:RegisterEvent(event) end
    end
end
function G:LootReady(autoloot)
    self.lootGeneration=self.lootGeneration+1
    if Combat() or not self.db.fastLoot or self.lootBlocked or not Public(autoloot) or autoloot~=true
        or type(LootSlot)~="function" or not (C_Timer and C_Timer.After) then return end
    local count=Read(GetNumLootItems)
    if not Number(count,1,1000) or count%1~=0 then return end
    local generation=self.lootGeneration
    for slot=1,count do
        local index=slot
        C_Timer.After(slot*.05,function()
            if generation~=self.lootGeneration or not self.db.fastLoot or self.lootBlocked or Combat() then return end
            -- Native confirmations and the stock loot window remain in charge.
            if not pcall(LootSlot,index) then self.lootBlocked=true;self.lootGeneration=self.lootGeneration+1 end
        end)
    end
end
function G:Start()
    if self.events then return end
    self.db=addon.db.globalOptions
    local events=CreateFrame("Frame");self.events=events
    for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","DISPLAY_SIZE_CHANGED","UI_SCALE_CHANGED","PLAYER_REGEN_ENABLED","ADDON_LOADED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event,...)
        if event=="LOOT_READY" then self:LootReady(...)
        elseif event=="LOOT_CLOSED" then self.lootGeneration=self.lootGeneration+1
        elseif event=="UI_SCALE_CHANGED" then self:ApplyScale()
        elseif event=="ADDON_LOADED" then if not Combat() then self:ApplyErrors();addon.Media:ApplyGameFonts() end
        elseif event=="PLAYER_REGEN_ENABLED" then
            if self.pending then self:Apply() end
            if addon.Media.pending then addon.Media:RefreshFonts() end
        else self:Apply();addon.Media:RefreshFonts() end
    end)
    self:ConfigureLoot();self:Apply()
end
