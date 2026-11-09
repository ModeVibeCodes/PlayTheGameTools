local _, addon = ...
-- Deliberately separate settings: dormant Retail Automation opt-ins stay dormant.
local M = { title = "Automation", category = "qualityOfLife", defaultEnabled = false }
addon.ForeverAutomation = M
addon:RegisterModule("foreverAutomation", M)

local function Plain(value)
    return not (issecretvalue and issecretvalue(value))
end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    local function Public(value) if Plain(value) then return value end end
    if ok then return Public(a), Public(b), Public(c), Public(d), Public(e), Public(f), Public(g) end
end

function M:Capability()
    if self.blocked then return false, "Unavailable this session: native setting rejected; leave manual and review." end
    if not C_CVar or type(C_CVar.GetCVarBool) ~= "function" or type(C_CVar.SetCVar) ~= "function" then
        return false, "Native Auto Loot setting unavailable."
    end
    local value, _, _, _, locked, secure, readOnly = Read(C_CVar.GetCVarInfo, "autoLootDefault")
    if type(value) ~= "string" or locked ~= false or secure ~= false or readOnly ~= false then
        return false, "Native Auto Loot setting is not verified writable and non-secure."
    end
    return true
end

function M:ApplyAutoLoot()
    -- Same one-shot policy as Retail: no loot engine, watcher or disable restore.
    if addon.GlobalSettings then return end
    if not self.active or self.db.autoLoot ~= true or not addon.Feedback:Allowed() or not self:Capability() then return end
    if Read(C_CVar.GetCVarBool, "autoLootDefault") ~= false then return end
    local ok, result = pcall(C_CVar.SetCVar, "autoLootDefault", "1")
    if not ok or not Plain(result) or result ~= true then
        self.blocked = true
        return
    end
    if Read(C_CVar.GetCVarBool, "autoLootDefault") == true then addon:PrintAction("Auto Loot enabled.", "autoLoot") end
end

function M:SetOption(key, value)
    if (key ~= "autoLoot" and key ~= "autoAccept" and key ~= "autoTurnIn" and
        key ~= "sellJunk" and key ~= "sellGrayEquipment" and key ~= "repair" and key ~= "autoGossip") or not Plain(value) or type(value) ~= "boolean" then return false end
    if key == "autoLoot" and value and not self:Capability() then return false end
    self.db[key] = value
    if key == "autoLoot" then
        if value then self:ApplyAutoLoot() end
    elseif key == "autoAccept" or key == "autoTurnIn" then
        if self.questSession then self.questSession.paused = true end
        self:ConfigureQuests()
    elseif key == "sellJunk" or key == "sellGrayEquipment" or key == "repair" then
        self:ConfigureMerchant()
    end
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

function M:SetRepairThreshold(value)
    if not Plain(value) or type(value) ~= "number" or value ~= value or value < 5 or value > 100 or value % 5 ~= 0 then return false end
    self.db.maxRepairCostPercent = value
    self:ConfigureMerchant()
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

function M:GossipCapability()
    return false, "Deferred: the native option data cannot verify harmless dialogue or exclude consequential services. No Auto Gossip selections are made."
end

function M:OnEnable() self.active = true; self:ConfigureQuests(); self:ConfigureMerchant(); self:ApplyAutoLoot() end
function M:OnDisable() self.active = false; self:ConfigureQuests(); self:ConfigureMerchant() end
