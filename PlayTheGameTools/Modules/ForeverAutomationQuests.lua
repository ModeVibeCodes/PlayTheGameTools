local _, addon = ...
local M = addon.ForeverAutomation
-- Independent implementation from inspected Forever contracts; no frame clicks,
-- popup manipulation, secure wrappers, timers or alternate action routes.
local modifiers = { shift = "IsShiftKeyDown", ctrl = "IsControlKeyDown", alt = "IsAltKeyDown" }
local function Plain(v) return not (issecretvalue and issecretvalue(v)) end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d, e = pcall(fn, ...)
    local function Public(v) if Plain(v) then return v end end
    if ok then return Public(a), Public(b), Public(c), Public(d), Public(e) end
end
local function Field(t, key)
    if not Plain(t) or type(t) ~= "table" then return end
    return Read(function() return t[key] end)
end
local function Number(v, low, high)
    return Plain(v) and type(v) == "number" and v == v and v >= low and v <= high and v == math.floor(v)
end
local function ID(v) return Number(v, 1, 2147483647) end
local function Log(name, id) return Read(C_QuestLog and C_QuestLog[name], id) end
local function Ordinary(id)
    return ID(id) and Log("IsRepeatableQuest", id) == false
end
local function Acceptable(id)
    return Ordinary(id) and Log("IsOnQuest", id) == false and Log("IsQuestFlaggedCompleted", id) == false
end
local function Completable(id)
    return Ordinary(id) and Log("IsOnQuest", id) == true and Log("IsComplete", id) == true
end
local function NoPayment()
    return Read(GetQuestMoneyToGet) == 0
end
local function NoRequiredItems()
    -- Required inventory/currency hand-ins are deliberately manual in this phase.
    return Read(GetNumQuestItems) == 0 and Read(GetNumQuestCurrencies) == 0
end
local function InteractionEnded()
    local types = Enum and Enum.PlayerInteractionType
    local fn = C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType
    if not types or types.Gossip == nil or types.QuestGiver == nil then return false end
    return Read(fn, types.Gossip) == false and Read(fn, types.QuestGiver) == false
end

function M:SetModifier(value)
    if not Plain(value) or type(value) ~= "string" or not modifiers[value] then return false end
    self.db.bypassModifier = value
    if self.questSession then self.questSession.paused = true end
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

function M:QuestAction(key, id, fn, ...)
    local s = self.questSession
    if not s or s.paused or self.questBlocked or not self.active or type(fn) ~= "function" then return end
    local token = key .. ":" .. id
    if s.done[token] then return end
    if s.count >= 64 then s.paused = true; return end
    -- Mark before calling: native actions may synchronously dispatch another event.
    s.done[token] = true; s.count = s.count + 1
    local ok, result = pcall(fn, ...)
    if not ok or not Plain(result) or result == false then
        self.questBlocked = true
        self:ConfigureQuests()
    end
    -- Native quest functions commonly return nothing; an invocation is not proof
    -- of acceptance. Never retry or claim success from this result.
end

function M:QuestMenu(gossip)
    local active, available
    if gossip then
        active = Read(C_GossipInfo and C_GossipInfo.GetActiveQuests)
        available = Read(C_GossipInfo and C_GossipInfo.GetAvailableQuests)
    end
    local function Count(rows, fn)
        if not gossip then return Read(fn) end
        if not Plain(rows) or type(rows) ~= "table" then return end
        return Read(function() return #rows end)
    end
    local a, b = Count(active, GetNumActiveQuests), Count(available, GetNumAvailableQuests)
    if not Number(a, 0, 64) or not Number(b, 0, 64) then return end
    -- Visit one eligible entry per event; never select a scripted gossip option.
    if self.db.autoTurnIn == true then
        for i = 1, a do
            local id, complete, ignored
            if gossip then
                local row = Field(active, i)
                id, complete, ignored = Field(row, "questID"), Field(row, "isComplete"), Field(row, "isIgnored")
            else
                id = Read(GetActiveQuestID, i)
                local title; title, complete = Read(GetActiveTitle, i)
                ignored = false
            end
            if complete == true and ignored == false and Completable(id) then
                if not self.questSession.done["active:" .. id] then
                    self:QuestAction("active", id, gossip and C_GossipInfo.SelectActiveQuest or SelectActiveQuest, gossip and id or i)
                    return
                end
            end
        end
    end
    if self.db.autoAccept == true then
        for i = 1, b do
            local id, repeatable
            if gossip then
                local row = Field(available, i)
                id, repeatable = Field(row, "questID"), Field(row, "repeatable")
            else
                local trivial, frequency, legendary
                trivial, frequency, repeatable, legendary, id = Read(GetAvailableQuestInfo, i)
            end
            if repeatable == false and Acceptable(id) then
                if not self.questSession.done["available:" .. id] then
                    self:QuestAction("available", id, gossip and C_GossipInfo.SelectAvailableQuest or SelectAvailableQuest, gossip and id or i)
                    return
                end
            end
        end
    end
end

function M:QuestEvent(event, arg)
    if not self.active or self.questBlocked then return end
    if event == "PLAYER_ENTERING_WORLD" then self.questSession = nil; self.questUnknownInteraction = nil; return end
    -- QUEST_FINISHED can be a stage transition within the same conversation.
    if event == "QUEST_FINISHED" then return end
    if event == "GOSSIP_CLOSED" or event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        if event == "GOSSIP_CLOSED" and (not Plain(arg) or arg ~= false) then return end
        if InteractionEnded() then self.questSession = nil; self.questUnknownInteraction = nil end
        return
    end
    local guid = Read(UnitGUID, "npc")
    if type(guid) ~= "string" or not (guid:match("^Creature%-%w") or guid:match("^Vehicle%-%w")) then
        self.questUnknownInteraction = true
        return
    end
    if not self.questSession or self.questSession.guid ~= guid then
        self.questSession = { guid = guid, done = {}, count = 0, paused = self.questUnknownInteraction }
    end
    local s = self.questSession
    local name = Plain(self.db.bypassModifier) and modifiers[self.db.bypassModifier]
    -- Unknown key/combat state is manual too. Bypass persists through all stages.
    if not name or Read(_G[name]) ~= false or Read(InCombatLockdown) ~= false or
        Read(UnitAffectingCombat, "player") ~= false or not addon.Feedback:Allowed() then s.paused = true end
    if s.paused then return end
    if event == "QUEST_GREETING" or event == "GOSSIP_SHOW" then self:QuestMenu(event == "GOSSIP_SHOW"); return end
    local id = Read(GetQuestID)
    if not Ordinary(id) then return end
    if event == "QUEST_DETAIL" and self.db.autoAccept == true then
        if not Plain(arg) or (arg ~= nil and arg ~= 0) then return end
        if Read(QuestIsFromAdventureMap) ~= false or Read(QuestIsFromAreaTrigger) ~= false or
            Read(QuestGetAutoAccept) ~= false or Read(QuestFlagsPVP) ~= false then return end
        if Acceptable(id) and NoPayment() then self:QuestAction("accept", id, AcceptQuest) end
    elseif self.db.autoTurnIn == true and Completable(id) and NoPayment() and NoRequiredItems() then
        if event == "QUEST_PROGRESS" and Read(IsQuestCompletable) == true then
            self:QuestAction("progress", id, CompleteQuest)
        elseif event == "QUEST_COMPLETE" then
            local choices = Read(GetNumQuestChoices)
            if Number(choices, 0, 1) then self:QuestAction("reward", id, GetQuestReward, choices) end
        end
    end
end

function M:ConfigureQuests()
    local enabled = self.active and not self.questBlocked and (self.db.autoAccept == true or self.db.autoTurnIn == true)
    if not enabled then
        if self.questFrame then self.questFrame:UnregisterAllEvents(); self.questFrame:SetScript("OnEvent", nil) end
        self.questSession = nil
        self.questUnknownInteraction = nil
        return
    end
    if not self.questFrame then self.questFrame = CreateFrame("Frame") end
    self.questFrame:UnregisterAllEvents()
    self.questFrame:SetScript("OnEvent", function(_, event, ...) self:QuestEvent(event, ...) end)
    for _, event in ipairs({"QUEST_GREETING", "GOSSIP_SHOW", "QUEST_FINISHED", "GOSSIP_CLOSED",
        "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", "PLAYER_ENTERING_WORLD"}) do self.questFrame:RegisterEvent(event) end
    if self.db.autoAccept == true then self.questFrame:RegisterEvent("QUEST_DETAIL") end
    if self.db.autoTurnIn == true then self.questFrame:RegisterEvent("QUEST_PROGRESS"); self.questFrame:RegisterEvent("QUEST_COMPLETE") end
end
