local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local M = { title = "Dungeon Loot", category = "questingLeveling", defaultEnabled = false,
    configDescription = "Find dungeon loot and plan your quests." }
addon.DungeonLoot = M
addon:RegisterModule("dungeonLoot", M)

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
function M:OnInitialize()
    self.view = { tab = "loot", search = "", faction = "all" }
    self.requested, self.attempted, self.tooltipInstances = {}, {}, {}
    self.events = CreateFrame("Frame")
    self.events:SetScript("OnEvent", function(_, event, id)
        if Public(id) and type(id) == "number" and (event == "TOOLTIP_DATA_UPDATE" and self.tooltipInstances[id] or event == "GET_ITEM_INFO_RECEIVED" and self.requested[id]) then
            if event == "GET_ITEM_INFO_RECEIVED" then self.requested[id] = nil end
            if self.active and self.page and self.page:IsShown() then self.page:Refresh() end
        end
    end)
end
function M:SyncEvents()
    self.events:UnregisterAllEvents()
    if self.active and self.page and self.page:IsShown() then
        self.events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        if C_TooltipInfo and type(C_TooltipInfo.GetItemByID) == "function" then self.events:RegisterEvent("TOOLTIP_DATA_UPDATE") end
    end
end
function M:OnEnable()
    self.active = true
    self:SyncEvents()
end
function M:OnDisable()
    if self.coordinateFrame then self.coordinateFrame:Hide() end
    if addon.DungeonLootMap then addon.DungeonLootMap:Clear() end
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
-- Render only public client tooltip text. Never infer stats from the source catalog.
local function TooltipText(value, color)
    if not Public(value) or type(value) ~= "string" or value == "" then return nil end
    if Public(color) and type(color) == "table" and type(color.GetRGB) == "function" then
        local ok, r, g, b = pcall(color.GetRGB, color)
        if ok and Public(r) and Public(g) and Public(b) and type(r) == "number" and type(g) == "number" and type(b) == "number"
            and r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1 then
            return string.format("|cff%02x%02x%02x", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5)) .. value .. "|r"
        end
    end
    return value
end
function M:ItemDetails(item)
    if not self.active or not self.page or not self.page:IsShown() then return nil end
    if not C_TooltipInfo or type(C_TooltipInfo.GetItemByID) ~= "function" then return nil end
    local ok, data = pcall(C_TooltipInfo.GetItemByID, item.id)
    if not ok or not Public(data) or type(data) ~= "table" then return nil end
    if Public(data.dataInstanceID) and type(data.dataInstanceID) == "number" then self.tooltipInstances[data.dataInstanceID] = true end
    if not Public(data.lines) or type(data.lines) ~= "table" then return nil end
    local lines = {}
    -- The first item tooltip line is its title, already displayed beside the icon.
    for index, line in ipairs(data.lines) do
        if index > 1 and Public(line) and type(line) == "table" then
            local left = TooltipText(line.leftText, line.leftColor)
            local right = TooltipText(line.rightText, line.rightColor)
            if left or right then lines[#lines+1] = (left or "") .. (left and right and "   " or "") .. (right or "") end
        end
    end
    return #lines > 0 and table.concat(lines, "\n") or nil
end
function M:Matches(text)
    return self.view.search == "" or tostring(text):lower():find(self.view.search:lower(), 1, true) ~= nil
end
function M:ReadData()
    self.data = addon.DungeonLootProvider:Read(self.view.dungeon)
    return self.data
end
function M:SelectEntry(kind, index)
    if self.coordinateFrame then self.coordinateFrame:Hide() end
    self.mapStatus=nil
    self:HideTooltip()
    self.view[kind] = index
    self.view.showPrerequisites, self.view.showNotes = false, false
    if self.page then
        self.page.detailPane.scrollbar:SetValue(0)
        self.page:Refresh()
    end
end
function M:Navigate(dungeon, tab, boss, quest)
    if self.coordinateFrame then self.coordinateFrame:Hide() end
    self:HideTooltip()
    local sameDungeon = self.view.dungeon == dungeon
    self.view.dungeon, self.view.tab = dungeon, tab or "loot"
    if not sameDungeon then
        self.view.boss,self.view.quest=nil,nil
        self.mapStatus=nil
        if addon.DungeonLootMap then addon.DungeonLootMap:Clear() end
    end
    self:ReadData()
    if boss then self.view.boss = boss end
    if quest then self.view.quest = quest end
    self.view.search = ""
    self.view.showPrerequisites, self.view.showNotes = false, false
    if self.page then
        self.page.search:SetText("")
        self.page.listPane.scrollbar:SetValue(0)
        self.page.detailPane.scrollbar:SetValue(0)
        self.page:Refresh()
    end
end