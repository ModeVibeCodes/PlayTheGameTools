local _,addon=...
local V,C={},addon.ProfileCodec
addon.ProfileValidation=V
local function Check(value,template,path)
    assert(type(value)==type(template),"Invalid setting type: "..path)
    if type(template)=="table" then
        for key,item in pairs(template) do Check(value[key],item,path.."."..tostring(key)) end
    end
end
local function Bounds(value,low,high,label)
    assert(C.Number(value) and value>=low and value<=high,"Invalid setting range: "..label)
end
local function Choice(value,choices,label)
    assert(type(value)=="string" and choices[value],"Invalid setting choice: "..label)
end
local function Colors(value)
    for key,item in pairs(value) do
        if type(item)=="table" then
            if type(key)=="string" and (key:lower():find("color",1,true) or key=="colors") then
                if item[1]~=nil then for i=1,3 do Bounds(item[i],0,1,key) end end
            end
            Colors(item)
        end
    end
end
function V:Normalize(source)
    local profile=C.Copy(source)
    addon:PrepareDatabase(profile)
    for _,id in ipairs(addon.moduleOrder) do
        if profile.modules[id]==nil then profile.modules[id]={} end
        local db=profile.modules[id];assert(type(db)=="table","Invalid module: "..id)
        if db.enabled==nil then db.enabled=addon.modules[id].defaultEnabled~=false end
        assert(type(db.enabled)=="boolean","Invalid module enable state: "..id)
    end
    if addon.LootSparkles then addon.LootSparkles.Initialize(profile.modules.lootSparkles) end
    Colors(profile.modules)
    local display=addon.modules.battleRez and profile.modules.battleRez.display
    if type(display)=="table" then
        for _,component in ipairs({"charges","timer","icon"}) do
            if type(display[component])=="table" then
                for key,value in pairs(display[component]) do
                    if type(value)=="number" then
                        local checked=addon.BattleRezSettings.ComponentValue(component,key,value)
                        if checked~=nil then assert(checked==value,"Invalid Battle Resurrection component range.") end
                    end
                end
            end
        end
    end
    if addon.ForeverRecruitment then addon.ForeverRecruitment.Initialize(profile.modules.foreverRecruitment) end
    if addon.ThreatMeter then addon.ThreatMeter.Initialize(profile.modules.threatMeter) end
    if addon.ForeverQuickAccessData then addon.ForeverQuickAccessData.Initialize(profile.modules.foreverQuickAccess) end
    if addon.modules.potionTracker then addon.PotionSettings.Initialize(profile.modules.potionTracker) end
    if addon.modules.racialAwareness then addon.RacialAwarenessSettings.Initialize(profile.modules.racialAwareness) end
    if addon.modules.partyCooldowns then addon.PartyCooldownSettings.Initialize(profile.modules.partyCooldowns) end
    local dungeon=profile.modules.dungeonCasts
    if addon.modules.dungeonCasts then addon.DungeonCastsSettings.Initialize(dungeon,{db=dungeon}) end
    if addon.FocusCastBarSettings then addon.FocusCastBarSettings.Initialize(profile.modules.focusCastBar) end
    if addon.modules.lootChoiceAlerts then
    addon.LootChoiceSettings.Initialize(profile.modules.lootChoiceAlerts)
    addon.LootChoiceSettings.Validate(profile.modules.lootChoiceAlerts)
    end
    if addon.modules.battleRez then addon.BattleRezSettings.Initialize(profile.modules.battleRez) end
    if addon.modules.automation then
    local automation=profile.modules.automation
    for _,feature in ipairs(addon.Automation.features) do
        if automation[feature.key]==nil then automation[feature.key]=feature.key=="autoLoot" end
        assert(type(automation[feature.key])=="boolean","Invalid Automation preference.")
    end
    automation.inviteFilter=automation.inviteFilter or "friendsGuild"
    Choice(automation.inviteFilter,{friends=true,guild=true,friendsGuild=true,everyone=true},"inviteFilter")
    end
    if addon.modules.foreverAutomation then
        Choice(profile.modules.foreverAutomation.bypassModifier,{shift=true,ctrl=true,alt=true},"bypassModifier")
        local threshold=profile.modules.foreverAutomation.maxRepairCostPercent
        Bounds(threshold,5,100,"maxRepairCostPercent")
        assert(threshold%5==0,"Invalid repair percentage increment.")
    end
    for key,value in pairs(profile.developer) do assert(type(value)=="boolean","Invalid diagnostic preference: "..tostring(key)) end
    Colors(profile.modules)
    if not self.template then
        -- Use the same defaults and pure setting initializers as runtime modules.
        -- Sentinel prevents recursion; the detached baseline creates no frames.
        self.template=false
        if next(source)==nil then self.template=C.Copy(profile)
        else self.template=self:Normalize({}) end
    end
    Check(profile,self.template or profile,"profile")
    for _,id in ipairs({"combatTimer","battleRez","InterruptTracker"}) do
        if addon.modules[id] then
        local a=profile.modules[id].appearance
        Bounds(a.fontSize,10,id=="InterruptTracker" and 24 or 48,id..".fontSize")
        Bounds(a.scale,0.5,2,id..".scale");Bounds(a.backgroundOpacity,0,1,id..".backgroundOpacity")
        Choice(a.font,{game=true,chat=true},id..".font")
        end
    end
    if addon.modules.combatTimer then Choice(profile.modules.combatTimer.appearance.format,{plain=true,round=true,square=true},"timer.format") end
    if addon.modules.battleRez then Choice(profile.modules.battleRez.appearance.format,{charges=true,maximum=true,recharge=true,combined=true},"rez.format") end
    if addon.modules.InterruptTracker then
    local interrupt=profile.modules.InterruptTracker
    Choice(interrupt.visibility,{always=true,party=true,combat=true},"interrupt.visibility")
    local a=interrupt.appearance
    Choice(a.growth,{up=true,down=true},"interrupt.growth")
    Choice(a.cooldownBarMode,{normal=true,desaturated=true,custom=true},"interrupt.cooldownBarMode")
    if a.iconPosition then Choice(a.iconPosition,{left=true,right=true,hidden=true},"interrupt.iconPosition") end
    if a.readyIndicator then Choice(a.readyIndicator,{ready=true,checkmark=true,none=true},"interrupt.readyIndicator") end
    for key,range in pairs({iconSize={12,64},iconGap={0,20},rowHeight={16,64},rowSpacing={0,16},barWidth={160,600},barBorderSize={1,12},iconBorderSize={1,12},barBorderOpacity={0,1},iconBorderOpacity={0,1}}) do
        Bounds(a[key],range[1],range[2],"interrupt."..key)
    end
    for id,enabled in pairs(interrupt.blacklist) do
        assert(C.Number(id) and id>0 and id==math.floor(id) and id<=2147483647 and type(enabled)=="boolean","Invalid interrupt blacklist.")
    end
    end
    if addon.modules.battleRez then
    local rez=profile.modules.battleRez
    Choice(rez.visibility,{encounter=true,combat=true,always=true},"rez.visibility")
    end
    if profile.positions then
        assert(type(profile.positions)=="table","Invalid positions.")
        for id,position in pairs(profile.positions) do assert(type(id)=="string" and addon.PositionManager:ValidatePosition(position,true),"Invalid saved position.") end
    end
    if addon.modules.combatTimer then assert(addon.PositionManager:ValidatePosition(profile.modules.combatTimer.position,true),"Invalid timer position.") end
    return profile
end
function V:Validate(source)
    local ok,result=pcall(self.Normalize,self,source)
    if not ok then return nil,"Invalid profile preferences: "..tostring(result):sub(-240) end
    return result
end
