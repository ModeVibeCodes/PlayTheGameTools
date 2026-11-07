local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local M = { title = "Dungeon Loot", category = "questingLeveling", defaultEnabled = false,
    configDescription = "Browse dungeon boss loot and quests. Shadowfang Keep pilot." }
addon.DungeonLoot = M
addon:RegisterModule("dungeonLoot", M)

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
function M:OnInitialize()
    self.view = { tab = "loot", search = "", faction = "all" }
    self.requested, self.attempted = {}, {}
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, _, id)
        if Public(id) and type(id) == "number" and self.requested[id] then
            self.requested[id] = nil
            if self.active and self.page and self.page:IsShown() then self.page:Refresh() end
        end
    end)
end
function M:SyncEvents()
    self.events:UnregisterAllEvents()
    if self.active and self.page and self.page:IsShown() then self.events:RegisterEvent("GET_ITEM_INFO_RECEIVED") end
end
function M:OnEnable()
    self.active = true
    self:SyncEvents()
end
function M:OnDisable()
    self.active = false
    self.events:UnregisterAllEvents()
    self:HideTooltip()
end
function M:HideTooltip()
    if self.tooltipOwner and GameTooltip then GameTooltip:Hide() end
    self.tooltipOwner = nil
end
function M:ItemInfo(item)
    local name, icon, quality
    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getter) == "function" then
        local ok, n, _, q, _, _, _, _, _, _, texture = pcall(getter, item.id)
        if ok then
            if Public(n) and type(n) == "string" then name = n end
            if Public(q) and type(q) == "number" then quality = q end
            if Public(texture) and (type(texture) == "number" or type(texture) == "string") then icon = texture end
        end
    end
    if not name and self.active and self.page and self.page:IsShown() and not self.attempted[item.id] and C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
        self.attempted[item.id], self.requested[item.id] = true, true
        local ok = pcall(C_Item.RequestLoadItemDataByID, item.id)
        if not ok then self.requested[item.id] = nil end
    end
    return name or item.name, icon or "Interface\\Icons\\INV_Misc_QuestionMark", quality, name ~= nil
end
function M:Matches(text)
    return self.view.search == "" or tostring(text):lower():find(self.view.search:lower(), 1, true) ~= nil
end
function M:ReadData()
    self.data = addon.DungeonLootProvider:Read()
    return self.data
end
function M:Navigate(dungeon, tab, boss, quest)
    self:HideTooltip()
    self.view.dungeon, self.view.tab = dungeon, tab or "loot"
    self.view.boss, self.view.quest, self.view.search = boss, quest, ""
    if self.page then
        self.page.search:SetText("")
        self.page.scrollbar:SetValue(0)
        self.page:Refresh()
    end
end
