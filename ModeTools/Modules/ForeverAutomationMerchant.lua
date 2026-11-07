local _, addon = ...
local M = addon.ForeverAutomation
-- Per-stack native requests in a verified merchant context. No bulk sell,
-- pickup/click fallback, cursor mutation, timer, guild funding or bag rescan loop.
local function Plain(v) return not (issecretvalue and issecretvalue(v)) end
local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    local function Public(v) if Plain(v) then return v end end
    if ok then return Public(a), Public(b), Public(c), Public(d), Public(e), Public(f), Public(g) end
end
local function Field(t, key)
    if not Plain(t) or type(t) ~= "table" then return end
    return Read(function() return t[key] end)
end
local function Number(v, low, high)
    return Plain(v) and type(v) == "number" and v == v and v >= low and v <= high and v == math.floor(v)
end
local function Text(v) return Plain(v) and type(v) == "string" and #v > 0 and #v <= 1024 end
local function Location(bag, slot)
    return Read(ItemLocation and ItemLocation.CreateFromBagAndSlot, ItemLocation, bag, slot)
end
local function BagAllowed(bag)
    if not C_Container then return false end
    if bag == 0 then return Read(C_Container.GetBackpackSellJunkDisabled) == false end
    local flag = Enum and Enum.BagSlotFlags and Enum.BagSlotFlags.ExcludeJunkSell
    return Number(flag, 0, 2147483647) and Read(C_Container.GetBagSlotFlag, bag, flag) == false
end
local function Equipment(id, link, loc)
    local itemID, _, _, equipLoc, _, classID, subClassID = Read(C_Item.GetItemInfoInstant, link)
    local inventoryType = Read(C_Item.GetItemInventoryType, loc)
    local equippable = Read(C_Item.IsEquippableItem, link)
    local none = Enum and Enum.InventoryType and Enum.InventoryType.IndexNonEquipType
    local questClass = Enum and Enum.ItemClass and Enum.ItemClass.Questitem
    if itemID ~= id or not Number(classID, 0, 20) or not Number(subClassID, 0, 255) or
        not Number(questClass, 12, 12) or classID == questClass or not Number(none, 0, 0) or
        not Number(inventoryType, 0, 34) or type(equipLoc) ~= "string" or #equipLoc > 64 then return end
    if equippable == false and inventoryType == none and equipLoc == "" then
        -- Weapon/armor class with contradictory non-equipment metadata stays manual.
        if classID ~= 2 and classID ~= 4 then return false end
    elseif equippable == true and inventoryType ~= none and equipLoc ~= "" then return true end
end
local function NoQuestAssociation(quest)
    if not Plain(quest) or type(quest) ~= "table" then return false end
    local ok, clear = pcall(function()
        local id, active, item = quest.questID, quest.isActive, quest.isQuestItem
        -- Do not collapse a restricted optional quest ID into an ordinary nil.
        return Plain(id) and id == nil and Plain(active) and active == false and Plain(item) and item == false
    end)
    return ok and clear == true
end
local function Candidate(bag, slot, allowEquipment)
    if not BagAllowed(bag) then return end
    local info = Read(C_Container.GetContainerItemInfo, bag, slot)
    local id, quality, count = Field(info, "itemID"), Field(info, "quality"), Field(info, "stackCount")
    local poor = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor
    if not Number(poor, 0, 0) or not Number(quality, 0, 8) or quality ~= poor or
        not Number(id, 1, 2147483647) or not Number(count, 1, 2147483647) then return end
    if Field(info, "isLocked") ~= false or Field(info, "hasNoValue") ~= false or
        Field(info, "hasLoot") ~= false or Field(info, "isReadable") ~= false then return end
    local link = Field(info, "hyperlink")
    if not Text(link) or Read(C_Container.GetContainerItemID, bag, slot) ~= id then return end
    local quest = Read(C_Container.GetContainerItemQuestInfo, bag, slot)
    if not NoQuestAssociation(quest) then return end
    local loc = Location(bag, slot)
    if not loc or Read(C_Item and C_Item.DoesItemExist, loc) ~= true or
        Read(C_Item and C_Item.CanBeRefunded, loc) ~= false then return end
    local guid = Read(C_Item.GetItemGUID, loc)
    if not Text(guid) then return end
    local equipment = Equipment(id, link, loc)
    if equipment == nil or (equipment and allowEquipment ~= true) then return end
    return { bag = bag, slot = slot, id = id, guid = guid, link = link, count = count, equipment = equipment }
end
local function Same(a, b)
    return a and b and a.id == b.id and a.guid == b.guid and a.link == b.link and a.count == b.count and a.equipment == b.equipment
end
local function PendingResolved(item)
    local loc = Location(item.bag, item.slot)
    if not loc then return false end
    local exists = Read(C_Item and C_Item.DoesItemExist, loc)
    if exists == false then return true end
    if exists ~= true then return false end
    local guid = Read(C_Item and C_Item.GetItemGUID, loc)
    return Text(guid) and guid ~= item.guid
end

function M:MerchantContext()
    if Read(InCombatLockdown) ~= false or Read(UnitAffectingCombat, "player") ~= false or not addon.Feedback:Allowed() then return false end
    local kind = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Merchant
    if not Number(kind, 0, 2147483647) or
        Read(C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType, kind) ~= true then return false end
    if not MerchantFrame or Read(MerchantFrame.IsForbidden, MerchantFrame) ~= false or
        Read(MerchantFrame.CanBeAccessedInContext, MerchantFrame) ~= true or
        Read(MerchantFrame.IsShown, MerchantFrame) ~= true or Field(MerchantFrame, "selectedTab") ~= 1 then return false end
    if Read(InRepairMode) ~= false or Read(SpellIsTargeting) ~= false or type(GetCursorInfo) ~= "function" then return false end
    local ok, cursor = pcall(GetCursorInfo)
    return ok and Plain(cursor) and cursor == nil
end

function M:StopMerchantWork()
    local v = self.merchantVisit
    if v then v.stopped = true; v.queue = {}; v.pending = nil end
    if self.merchantFrame then
        self.merchantFrame:UnregisterEvent("BAG_UPDATE_DELAYED")
        self.merchantFrame:UnregisterEvent("MERCHANT_UPDATE")
    end
end

function M:MerchantAction(key, fn, ...)
    if not self.active or self.db[key] ~= true or not self.merchantVisit or self.merchantVisit.stopped or
        (self.merchantBlocked and self.merchantBlocked[key]) or not self:MerchantContext() or type(fn) ~= "function" then return false end
    local ok, result = pcall(fn, ...)
    if not ok or not Plain(result) or result == false then
        self.merchantBlocked = self.merchantBlocked or {}; self.merchantBlocked[key] = true
        return false
    end
    -- Void means only that a request was invoked. Never claim a sale/repair succeeded.
    return true
end

function M:RepairMerchant()
    local v = self.merchantVisit
    if not v or v.repairAttempted or self.db.repair ~= true or not self:MerchantContext() then return end
    v.repairAttempted = true -- exactly one eligibility assessment per visit, no funds watcher
    if Read(CanMerchantRepair) ~= true then return end
    local cost, canRepair = Read(GetRepairAllCost)
    local money = Read(GetMoney)
    local threshold = self.db.maxRepairCostPercent
    if canRepair ~= true or not Number(cost, 1, 9007199254740991) or not Number(money, 0, 9007199254740991) or
        not Number(threshold, 5, 100) or threshold % 5 ~= 0 then return end
    if money == 0 or money < cost then
        addon:PrintAction("Auto Repair skipped: insufficient personal funds.", "foreverRepairSkipped")
        return
    end
    -- Equivalent to cost / money * 100 <= threshold, using whole copper to avoid
    -- rounding an exact boundary (e.g. 55/100) above the selected percentage.
    local limit = math.floor(money / 100) * threshold + math.floor((money % 100) * threshold / 100)
    if cost > limit then
        addon:PrintAction("Auto Repair skipped: bill exceeds Maximum Repair Cost (%).", "foreverRepairSkipped")
        return
    end
    self:MerchantAction("repair", RepairAllItems, false)
end

function M:SnapshotJunk()
    local queue = {}
    local constants = Constants and Constants.InventoryConstants
    local bags, reagents = Field(constants, "NumBagSlots"), Field(constants, "NumReagentBagSlots")
    if not Number(bags, 0, 8) or not Number(reagents, 0, 2) or not C_Container then return queue end
    local inspected = 0
    for bag = 0, bags + reagents do
        if BagAllowed(bag) then
            local slots = Read(C_Container.GetContainerNumSlots, bag)
            if Number(slots, 0, 128) then
                for slot = 1, slots do
                    inspected = inspected + 1
                    if inspected > 512 or #queue >= 64 then return queue end
                    local item = Candidate(bag, slot, self.db.sellGrayEquipment)
                    if item then queue[#queue + 1] = item end
                end
            end
        end
    end
    return queue
end

function M:PumpMerchant()
    local v = self.merchantVisit
    if not v or v.processing or v.stopped then return end
    if not self.active or self.db.sellJunk ~= true or (self.merchantBlocked and self.merchantBlocked.sellJunk) or
        not self:MerchantContext() then self:StopMerchantWork(); return end
    v.processing = true
    -- Initial snapshot and attempted GUID ledger bound even synchronous event chains.
    while self.merchantVisit == v and not v.stopped do
        if not self:MerchantContext() then self:StopMerchantWork(); break end
        if v.pending then
            if not PendingResolved(v.pending) then break end
            v.pending = nil
        end
        local item = v.queue[v.index]
        if not item then self:StopMerchantWork(); break end
        v.index = v.index + 1
        if not v.attempted[item.guid] and Same(item, Candidate(item.bag, item.slot, self.db.sellGrayEquipment)) then
            v.attempted[item.guid] = true; v.pending = item
            if not self:MerchantAction("sellJunk", C_Container and C_Container.UseContainerItem, item.bag, item.slot) then
                self:StopMerchantWork(); break
            end
        end
    end
    v.processing = false
end

function M:MerchantEvent(event)
    if event == "MERCHANT_CLOSED" or event == "PLAYER_ENTERING_WORLD" then
        self:StopMerchantWork(); self.merchantVisit = nil; return
    end
    if not self.active then return end
    if event == "MERCHANT_SHOW" then
        if self.merchantVisit then return end
        -- A visit opened in combat/unknown context stays manual until closed/reopened.
        local v = { queue = {}, index = 1, attempted = {}, stopped = not self:MerchantContext() }
        self.merchantVisit = v
        if v.stopped then return end
        v.processing = true
        self:RepairMerchant()
        if self.merchantVisit ~= v or v.stopped then v.processing = false; return end
        if self.db.sellJunk == true and not (self.merchantBlocked and self.merchantBlocked.sellJunk) then v.queue = self:SnapshotJunk() end
        v.processing = false
        if self.merchantVisit ~= v or v.stopped then return end
        if #v.queue > 0 then
            self.merchantFrame:RegisterEvent("BAG_UPDATE_DELAYED")
            self.merchantFrame:RegisterEvent("MERCHANT_UPDATE")
            self:PumpMerchant()
        end
    elseif event == "BAG_UPDATE_DELAYED" or event == "MERCHANT_UPDATE" then self:PumpMerchant() end
end

function M:ConfigureMerchant()
    self:StopMerchantWork()
    if self.merchantFrame then self.merchantFrame:UnregisterAllEvents(); self.merchantFrame:SetScript("OnEvent", nil) end
    local blocked = self.merchantBlocked or {}
    if not self.active or not ((self.db.sellJunk == true and not blocked.sellJunk) or (self.db.repair == true and not blocked.repair)) then
        self.merchantVisit = nil
        return
    end
    if not self.merchantFrame then self.merchantFrame = CreateFrame("Frame") end
    self.merchantFrame:SetScript("OnEvent", function(_, event) self:MerchantEvent(event) end)
    for _, event in ipairs({"MERCHANT_SHOW", "MERCHANT_CLOSED", "PLAYER_ENTERING_WORLD"}) do self.merchantFrame:RegisterEvent(event) end
end
