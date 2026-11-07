local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end

local M = {title="Gameplay Enhancements", category="questingLeveling", defaultEnabled=false,
    configDescription="Independent quality-of-life features. Choose a tab and enable the features you want."}
addon.LootSparkles = M
addon:RegisterModule("lootSparkles", M)

M.defaults = {sparklesEnabled=true, questSparkles=true, ore=true, herbs=true, questObjects=true, corpses=true,
    showNames=true, size=36, opacity=85, fontSize=14, offsetY=-45}
M.ranges = {size={16,72,2}, opacity={20,100,5}, fontSize={10,24,1}, offsetY={-120,60,5}}
local softCVars = {SoftTargetInteract="3", SoftTargetIconGameObject="1",
    SoftTargetInteractRange="60", SoftTargetInteractArc="2", SoftTargetInteractOnlyInRange="0"}
local questCVar = "outlineModeShowLootEffectWhenDisabled"
local gateCVar = "SoftTargetNameplateInteract"

function M.Public(v) return not (issecretvalue and issecretvalue(v)) end
function M.Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and M.Public(value) then return value end
end
function M:OutsideCombat()
    return self.Read(InCombatLockdown) == false and self.Read(UnitAffectingCombat, "player") == false
end
function M.Initialize(db)
    for key, default in pairs(M.defaults) do
        if db[key] == nil then db[key] = default end
        local value, range = db[key], M.ranges[key]
        assert(M.Public(value) and type(value) == type(default), "Invalid Loot Sparkles setting: "..key)
        if range then
            assert(value == value and value >= range[1] and value <= range[2] and
                (value-range[1]) % range[3] == 0, "Invalid Loot Sparkles range: "..key)
        end
    end
    if addon.CampfireMonitor then addon.CampfireMonitor.Initialize(db) end
end
function M:HasNodes() return self.db.ore or self.db.herbs or self.db.questObjects or self.db.corpses end
function M:Conflict()
    for _, name in ipairs({"ForeverLootSparkles", "Lueur"}) do
        if self.Read(C_AddOns and C_AddOns.IsAddOnLoaded, name) == true then return name end
    end
end
function M:GetCVar(name) return self.Read(C_CVar and C_CVar.GetCVar, name) end

-- Ownership lives outside profiles: imports/exports must never restore another
-- player's graphics settings. Persist it across /reload and normal logout.
function M:Ownership()
    local root = addon.ProfileManager.root
    if type(root.lootSparkleCVars) ~= "table" then root.lootSparkleCVars = {} end
    return root.lootSparkleCVars
end
function M:Write(name, value, force)
    if not self:OutsideCombat() or not C_CVar or type(C_CVar.SetCVar) ~= "function" then return false end
    if self.rejected and self.rejected[name] then return false end
    local current = self:GetCVar(name)
    if type(current) ~= "string" then self.status="Unavailable setting: "..name; return false end
    local owned = self:Ownership()
    local record = owned[name]
    if record and (type(record) ~= "table" or type(record.before) ~= "string" or type(record.last) ~= "string") then
        owned[name] = nil; record = nil
    end
    -- Respect a subsequent player change until an explicit option is enabled.
    if record and current ~= record.last and not force then return false end
    if current == value then return true end
    if not record then record={before=current,last=current}; owned[name]=record end
    local ok = pcall(C_CVar.SetCVar, name, value)
    if ok and self:GetCVar(name) == value then record.last=value; return true end
    self.rejected=self.rejected or {}; self.rejected[name]=true
    self.status="Client rejected setting: "..name
    return false
end
function M:Restore(name)
    local owned = self:Ownership()
    local record = owned[name]
    if not record then return end
    if not self:OutsideCombat() then self.pending=true; return end
    if type(record) ~= "table" or type(record.before) ~= "string" or type(record.last) ~= "string" then owned[name]=nil; return end
    local current = self:GetCVar(name)
    if current == record.last and current ~= record.before then
        if not C_CVar or type(C_CVar.SetCVar) ~= "function" then return end
        pcall(C_CVar.SetCVar, name, record.before)
        if self:GetCVar(name) ~= record.before then self.status="Restoration pending: "..name; return end
    elseif current == nil then return end
    owned[name]=nil
end
function M:Gate(open)
    return self:Write(gateCVar, open and "1" or "0", false)
end
function M:Configure(force)
    self:Release()
    if not self:OutsideCombat() then
        self.pending=true; self.status="Waiting until out of combat to apply or restore client settings."; return
    end
    self.pending=nil
    local conflict = self:Conflict()
    self.running = self.active and self.db.sparklesEnabled and not conflict
    self.status = conflict and ("Paused: disable "..conflict.." in AddOns and reload to avoid competing settings.") or
        (self.active and self.db.sparklesEnabled and "Ready. One nearby interaction target; custom sparkles pause in combat." or "Loot Sparkles disabled. Previous owned settings restored.")
    if self.running and self.db.questSparkles then self:Write(questCVar,"1",force=="questSparkles")
    else self:Restore(questCVar) end
    self.nodes = self.running and self:HasNodes()
    for name, value in pairs(softCVars) do
        if self.nodes then self:Write(name,value,force=="ore" or force=="herbs" or force=="questObjects" or force=="corpses") else self:Restore(name) end
    end
    if self.nodes then self:Evaluate() else self:Restore(gateCVar) end
    self:UpdatePoller()
end
function M:SetOption(key, value)
    if not self:OutsideCombat() or self.defaults[key] == nil or not self.Public(value) then return false end
    local candidate = addon.ProfileCodec.Copy(self.db); candidate[key]=value
    if not pcall(self.Initialize,candidate) then return false end
    self.db[key]=value
    if key=="questSparkles" and value then self.questWasOn=true end
    self:Configure(value == true and key or false)
    if key == "questSparkles" and value == false then self:RestartNotice() end
    if self.page then self.page:Refresh() end
    return true
end
function M:RestartNotice()
    if self.questWasOn then
        print("Play The Game Tools: quest sparkles may remain until a full game restart; /reload is not enough.")
    end
end
function M:UpdatePoller()
    self.driver:SetScript("OnUpdate", nil)
    if self.nodes and self:OutsideCombat() then
        local elapsed = 0
        self.driver:SetScript("OnUpdate", function(_, dt)
            elapsed=elapsed+dt
            if elapsed >= 0.15 then elapsed=0; self:Evaluate() end
        end)
    end
end
function M:OnInitialize()
    self.Initialize(self.db)
    if addon.CampfireMonitor then addon.CampfireMonitor:Attach(self) end
    self.units={}
    self.driver=CreateFrame("Frame")
    self.driver:SetScript("OnEvent",function(_,event,unit)
        if event=="NAME_PLATE_UNIT_ADDED" then
            if self.Public(unit) and type(unit)=="string" then self.units[unit]=true end
            self:Evaluate()
        elseif event=="NAME_PLATE_UNIT_REMOVED" then
            if self.Public(unit) and type(unit)=="string" then self.units[unit]=nil end
            self:Release(); self:Evaluate()
        elseif event=="PLAYER_REGEN_DISABLED" then
            self:Release(); self.driver:SetScript("OnUpdate",nil)
        elseif event=="PLAYER_SOFT_INTERACT_CHANGED" then self:Release(); self:Evaluate()
        elseif event=="CVAR_UPDATE" then
            if self.running and self.db.questSparkles and self.Public(unit) and type(unit)=="string" then
                local key=unit:lower()
                if key=="graphicsquality" or key=="raidgraphicsquality" or key==questCVar:lower() then
                    -- Debounce graphics changes, without running addon code in native options predicates.
                    if not self.reapply then
                        self.reapply=true
                        C_Timer.After(1,function()
                            self.reapply=nil
                            if self.running and self.db.questSparkles then
                                if self:OutsideCombat() then self:Write(questCVar,"1",true) else self.pending=true; self.pendingQuest=true end
                            end
                        end)
                    end
                end
            end
        elseif event=="ADDON_LOADED" then
            if unit=="ForeverLootSparkles" or unit=="Lueur" then self:Configure(false) end
        else
            if event=="PLAYER_ENTERING_WORLD" then self.units={} end
            self:Configure(false)
            if self.pendingQuest and self.running and self.db.questSparkles and self:OutsideCombat() then
                self.pendingQuest=nil; self:Write(questCVar,"1",true)
            end
        end
        if self.page then self.page:Refresh() end
    end)
    -- Retain only the restoration listener while disabled, so a combat disable
    -- can complete its deferred cleanup. No disabled polling or unit reads.
    self.driver:RegisterEvent("PLAYER_REGEN_ENABLED")
    if not self.db.enabled then self:Configure(false) end
end
function M:OnEnable()
    self.active=true
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_SOFT_INTERACT_CHANGED",
        "NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","CVAR_UPDATE","ADDON_LOADED"}) do
        pcall(self.driver.RegisterEvent,self.driver,event)
    end
    self:Configure(false)
    if addon.CampfireMonitor then addon.CampfireMonitor:SyncEnabled() end
    self.questWasOn=self.db.questSparkles
end
function M:OnDisable()
    self.active=false
    self.driver:UnregisterAllEvents(); self.driver:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.nodes=false; self.running=false
    self.driver:SetScript("OnUpdate",nil)
    self:Configure(false); self:RestartNotice()
    if addon.CampfireMonitor then addon.CampfireMonitor:StopPreview();addon.CampfireMonitor:SetPlacementMode(false);addon.CampfireMonitor:SyncEnabled() end
end
