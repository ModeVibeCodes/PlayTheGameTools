local _, addon = ...
local P = addon.ForeverTrainingData
addon:RegisterCategory("questingLeveling",{title="Questing & Leveling"})
local M = {title="Class Training", category="questingLeveling", defaultEnabled=true,
    configDescription="Browse your class training, upcoming levels and known ranks."}
addon.ForeverClassTraining = M
addon:RegisterModule("foreverClassTraining", M)

function M:SelectPlayerCatalog()
    local G=P.NewGuard(_G)
    local ok,name,class=G:Call(UnitClass,"player")
    local available,changed=P.SelectClass(ok and class or nil)
    self.className=available and (type(name)=="string" and name or class) or nil
    if changed then
        self.snapshot,self.rows,self.spellLabels,self.spellIcons=nil,nil,nil,nil
        self.pendingDing,self.lastLevelClock,self.lastClockLevel,self.levelDuration=nil,nil,nil,nil
        self.pendingGuildDing=nil;self.guildDingDraft=nil;self.guildDingStatus=nil
        if self.dingWindow then self.dingWindow:Hide() end
        if self.CloseTrainingFlyout then self:CloseTrainingFlyout() end
    end
    return available
end

function M:OnInitialize() self:SelectPlayerCatalog() end

local events = {"PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "SPELLS_CHANGED",
    "LEARNED_SPELL_IN_SKILL_LINE", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
    "TRAIT_CONFIG_UPDATED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "SPELL_DATA_LOAD_RESULT", "TRAINER_SHOW", "TRAINER_UPDATE", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "PLAYER_MONEY"}

function M:ScanSpellbook(snapshot)
    local G = P.NewGuard(_G)
    snapshot.book = {}
    local fn = G:Get(C_SpellBook, "FindSpellBookSlotForSpell")
    local playerBank = G:Get(G:Get(Enum, "SpellBookSpellBank"), "Player")
    if not G:Integer(playerBank, 0, 16) then return end
    for _, id in ipairs(P.catalog.ids) do
        -- Include hidden/flyout entries, exclude future and off-spec entries.
        local ok, slot, bank = G:Call(fn, id, true, true, false, false)
        if ok then
            if slot == nil then snapshot.book[id] = false
            elseif G:Integer(slot, 1, 4096) and bank == playerBank then
                local readable, info = G:Call(G:Get(C_SpellBook, "GetSpellBookItemInfo"), slot, bank)
                local spell = readable and G:Get(info, "spellID")
                local offspec = readable and G:Get(info, "isOffSpec")
                if G:Integer(spell, 1, 2147483647) and offspec == false then snapshot.book[id] = spell == id end
            end
        end
    end
end

function M:OutsideCombat()
    local G = P.NewGuard(_G)
    local ok, lockdown = G:Call(InCombatLockdown)
    local valid, combat = G:Call(UnitAffectingCombat, "player")
    return ok and valid and lockdown == false and combat == false
end

function M:RefreshTraining()
    if not self.active then return false end
    if not self:OutsideCombat() then self.dirty = true; return false end
    self.dirty = false
    local G = P.NewGuard(_G)
    self.snapshot, self.rows = nil, nil
    if not self:SelectPlayerCatalog() then
        self.message = "Class training unavailable for this character."
    else
        local snapshot = P.NewReader(_G, P.catalog):Capture()
        if snapshot then
            self:ScanSpellbook(snapshot)
            if not self:OutsideCombat() then self.dirty=true;return false end
            self.snapshot, self.rows = snapshot, P.ResolveTraining(snapshot)
            self.message = self.className .. " · Level " .. (snapshot.level or "?")
        else self.message = "Character data unavailable. Try Refresh outside combat." end
    end
    if self.UpdateTrainingPage then self:UpdateTrainingPage() end
    if self.SyncTrainingDisplays then self:SyncTrainingDisplays() end
    return self.snapshot ~= nil
end

function M:QueueRefresh()
    self.dirty = true
    if self.queued or not self.active or not self:OutsideCombat() then return end
    self.queued = true
    local generation = self.generation
    C_Timer.After(0.15, function()
        if generation ~= self.generation or not self.active then return end
        self.queued = false
        self:RefreshTraining()
    end)
end

function M:OnEnable()
    self.active = true
    self.generation = (self.generation or 0) + 1
    if not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
    self.eventFrame:SetScript("OnEvent", function(_, event, id)
        if event=="PLAYER_MONEY" then self:UpdateFlyoutMoney();return end
        if event == "PLAYER_REGEN_DISABLED" then
            self.dirty=true
            self:CloseTrainingFlyout()
            if self.shortcut and self.shortcut.moving then self.shortcut:StopMovingOrSizing();self.shortcut.moving=false end
            if self.dingWindow then self.dingWindow:Hide() end
            return
        end
        if event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED" then
            if self.trainingFlyout and self.trainingFlyout:IsShown() and self:OutsideCombat() then self:RenderTrainingFlyout() end
            return
        end
        if event == "PLAYER_LEVEL_UP" then
            local G = P.NewGuard(_G)
            if G:Integer(id, 1, 1000) then
                if self.db.levelAlerts~=false then self.pendingDing=id;self:RecordLevelTime(id) end
                if self.db.levelAlerts~=false and self.db.guildDing~=false and (not self.lastGuildDing or id>self.lastGuildDing) then
                    self.lastGuildDing=id;self.pendingGuildDing=id
                end
            end
        end
        if event == "SPELL_DATA_LOAD_RESULT" then
            local G = P.NewGuard(_G)
            if not G:Integer(id, 1, 2147483647) or not self.requestedMetadata or not self.requestedMetadata[id] then return end
        end
        self:QueueRefresh()
    end)
    for _, event in ipairs(events) do self.eventFrame:RegisterEvent(event) end
    self:RefreshTraining()
end

function M:OnDisable()
    self.active = false
    self.generation = (self.generation or 0) + 1
    self.queued, self.dirty, self.snapshot, self.rows = nil, nil, nil, nil
    self.pendingDing = nil
    self.pendingGuildDing=nil;self.guildDingDraft=nil;self.guildDingStatus=nil
    self.lastLevelClock,self.lastClockLevel,self.levelDuration=nil,nil,nil
    if self.shortcut then self.shortcut:Hide() end
    if self.dingWindow then self.dingWindow:Hide() end
    self:CloseTrainingFlyout()
    if self.eventFrame then self.eventFrame:UnregisterAllEvents(); self.eventFrame:SetScript("OnEvent", nil) end
    if self.UpdateTrainingPage then self:UpdateTrainingPage() end
end

function M:SpellLabel(id)
    self.spellLabels = self.spellLabels or {}
    if self.spellLabels[id] then return self.spellLabels[id] end
    if not self:OutsideCombat() then return self.spellLabels[id] or "Loading ability…" end
    local G = P.NewGuard(_G)
    local ok, info = G:Call(C_Spell and C_Spell.GetSpellInfo, id)
    local name = ok and G:Get(info, "name")
    if type(name) ~= "string" then
        self.requestedMetadata = self.requestedMetadata or {}
        if self.active and not self.requestedMetadata[id] then
            self.requestedMetadata[id] = true
            G:Call(C_Spell and C_Spell.RequestLoadSpellData, id)
        end
        return "Loading ability…"
    end
    local valid, subtext = G:Call(C_Spell and C_Spell.GetSpellSubtext, id)
    local label = name .. (valid and type(subtext) == "string" and subtext ~= "" and (" (" .. subtext .. ")") or "")
    self.spellLabels[id] = label
    return label
end

function M:SpellPresentation(record)
    local G = P.NewGuard(_G)
    local name = self:SpellLabel(record.id)
    local icon = self.spellIcons and self.spellIcons[record.id]
    if not icon and self:OutsideCombat() then
        local ok, info = G:Call(C_Spell and C_Spell.GetSpellInfo, record.id)
        local value = ok and G:Get(info, "iconID")
        if G:Integer(value, 1, 2147483647) then
            self.spellIcons = self.spellIcons or {}; self.spellIcons[record.id] = value; icon = value
        end
    end
    -- Native subtext when available; pinned metadata supplies rank before lazy loading.
    if not name:find("(", 1, true) then name = name .. " · Rank " .. record.rank end
    return name, icon or 134400
end
