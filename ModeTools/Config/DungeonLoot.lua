local _, addon = ...
local M, W, T = addon.DungeonLoot, addon.ConfigWidgets, addon.InterfaceTheme

function M:CreateConfigPage(parent)
    local page = W.Page(parent, 320)
    self.page = page
    page.slots = {}
    local nav = page:Row("Browse", 48)
    local function Nav(text, x, width, callback)
        local b = W.Button(nav, text, width, 28)
        b:SetPoint("TOPLEFT", x, 0); b:SetScript("OnClick", callback)
        return b
    end
    page.home = Nav("All Dungeons", 0, 112, function() self:Navigate(nil) end)
    page.loot = Nav("Boss Loot", 116, 92, function() self:Navigate(self.view.dungeon, "loot") end)
    page.quests = Nav("Quests", 212, 76, function() self:Navigate(self.view.dungeon, "quests") end)
    -- Full width so navigation fits alongside the existing sidebar at smaller sizes.
    nav.rowLabel:Hide(); nav:ClearAllPoints(); nav:SetPoint("TOPLEFT", nav.row, "TOPLEFT", 0, -8); nav:SetPoint("BOTTOMRIGHT", nav.row, "BOTTOMRIGHT", 0, 4)
    local input = page:Row("Search names", 48)
    page.search = CreateFrame("EditBox", nil, input)
    page.search:SetPoint("TOPLEFT"); page.search:SetPoint("TOPRIGHT"); page.search:SetHeight(28)
    page.search:SetAutoFocus(false); page.search:SetMaxLetters(80); page.search:SetFontObject(GameFontHighlight)
    page.search:SetTextInsets(6, 6, 0, 0); W.Texture(page.search, "InputField")
    page.search:SetScript("OnTextChanged", function(box) self.view.search = box:GetText() or ""; page.scrollbar:SetValue(0); page:Refresh() end)
    page.search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    local filter = page:Row("Quest faction", 48)
    page.faction = W.Select(filter, 180, function() return {
        { id = "all", label = "All factions" }, { id = "Alliance", label = "Alliance" }, { id = "Horde", label = "Horde" }
    } end, function() return self.view.faction, self.view.faction == "all" and "All factions" or self.view.faction end,
    function(value) self.view.faction = value; self.view.quest = nil; page:Refresh() end)
    filter.row.visibleWhen = function() return self.active and self.view.dungeon == "Shadowfang Keep" and self.view.tab == "quests" end
    local refresh = page:Row("Data source", 48)
    page.reload = W.Button(refresh, "Refresh Data", 140, 28)
    page.reload:SetPoint("TOPLEFT"); page.reload:SetScript("OnClick", function() self.attempted = {}; self:ReadData(); page:Refresh() end)

    local used = 0
    local function Add(text, callback, item, color, icon)
        used = used + 1
        local slot = page.slots[used]
        if not slot then
            local control = page:Row("", 44)
            control.rowLabel:Hide(); control:ClearAllPoints()
            control:SetPoint("TOPLEFT", control.row, "TOPLEFT", 0, -3); control:SetPoint("BOTTOMRIGHT", control.row, "BOTTOMRIGHT", 0, 3)
            local button = W.Button(control, "", 300, 38)
            button:SetAllPoints(control)
            button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", 10, -9); button.label:SetPoint("TOPRIGHT", -10, -9)
            button.label:SetJustifyH("LEFT"); button.label:SetWordWrap(true)
            local itemIcon = button:CreateTexture(nil, "ARTWORK")
            itemIcon:SetSize(28, 28); itemIcon:SetPoint("TOPLEFT", 8, -7)
            slot = { control = control, row = control.row, button = button, icon = itemIcon }
            page.slots[used] = slot
            control.row.visibleWhen = function() return slot.visible end
            function control.row:layoutChildren(width)
                local available = math.max(80, width - (slot.item and 58 or 24))
                button.label:SetWidth(available)
                self:SetHeight(math.max(42, button.label:GetStringHeight() + 24))
            end
            button:SetScript("OnClick", function() if slot.callback and M.active then slot.callback() end end)
            button:HookScript("OnEnter", function(owner)
                if slot.item and M.active and GameTooltip then
                    M:HideTooltip(); M.tooltipOwner = owner
                    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink("item:" .. slot.item.id); GameTooltip:Show()
                end
            end)
            button:HookScript("OnLeave", function(owner) if M.tooltipOwner == owner then M:HideTooltip() end end)
        end
        slot.visible, slot.callback, slot.item = true, callback, item
        slot.button.label:ClearAllPoints()
        slot.button.label:SetPoint("TOPLEFT", item and 44 or 10, -9)
        slot.button.label:SetPoint("TOPRIGHT", -10, -9)
        slot.icon:SetShown(item ~= nil)
        if item then slot.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark") end
        slot.button.label:SetText(text)
        slot.button:SetLabelColor(color or T.text)
        -- Text rows remain readable; only clickable rows receive a hover action.
        slot.button:EnableMouse(callback ~= nil or item ~= nil)
        return slot
    end
    local function Item(item)
        local name, icon, quality, loaded = self:ItemInfo(item)
        if not self:Matches(name .. " " .. item.name) then return false end
        local color = T.text
        if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
            local c = ITEM_QUALITY_COLORS[quality]; color = { c.r, c.g, c.b, 1 }
        end
        Add(name .. (item.slot and ("  |  " .. item.slot) or "") .. (loaded and "" or "  (item details pending)"), nil, item, color, icon)
        return true
    end
    local function Detail(q, prefix)
        Add((prefix or "") .. q.name, nil, nil, T.secondary)
        Add("Faction: " .. (q.faction or "Not recorded") .. "  |  Class: " .. (q.classOnly or "All classes") ..
            "  |  Required level: " .. (q.requires or "Unknown"))
        if q.objective then Add("Objective: " .. q.objective) end
        if q.startItem then Add("Starts from item: " .. q.startItem.name, nil, q.startItem) end
        if q.startObject then Add("Starts from object: " .. q.startObject) end
        if q.startHint then Add(q.startHint) end
        Add("Pick up: " .. (q.pickup or "Not recorded"))
        if q.start then Add("Pickup location: " .. q.start) end
        Add("Turn in: " .. (q.turnin or "Not recorded"))
        if q.finish then Add("Turn-in location: " .. q.finish) end
        if q.warning then Add(q.warning, nil, nil, T.primary) end
        if q.note then Add(q.note) end
        if q.description then Add(q.description) end
    end
    function page:Refresh()
        if self.refreshing then return end
        self.refreshing = true
        M:HideTooltip()
        used = 0
        for _, slot in ipairs(self.slots) do slot.visible = false; slot.item = nil; slot.callback = nil end
        local v = M.view
        local data = M.active and (M.data or M:ReadData()) or {}
        self.home:SetSelected(v.dungeon == nil)
        self.loot:SetSelected(v.dungeon ~= nil and v.tab == "loot")
        self.quests:SetSelected(v.dungeon ~= nil and v.tab == "quests")
        self.loot:SetEnabled(M.active and v.dungeon == "Shadowfang Keep")
        self.quests:SetEnabled(M.active and v.dungeon == "Shadowfang Keep")
        self.reload:SetEnabled(M.active)
        self.faction:Refresh()
        if not M.active then
            Add("Enable Dungeon Loot using the module switch above to browse dungeons, boss loot and quests.")
        else
            Add(data.source, nil, nil, T.muted)
            if not v.dungeon then
                Add("Dungeons — select Shadowfang Keep for the pilot. Other dungeon details will follow after review.", nil, nil, T.secondary)
                local count = 0
                for _, name in ipairs(data.catalog) do
                    if M:Matches(name) then
                        count = count + 1
                        local dungeon = name
                        Add(dungeon .. (dungeon == "Shadowfang Keep" and "  —  Pilot" or "  —  Not in this pilot"),
                            function() M:Navigate(dungeon) end)
                    end
                end
                if count == 0 then Add("No dungeons match your search.") end
            elseif v.dungeon ~= "Shadowfang Keep" then
                Add(v.dungeon .. " — details are outside the Shadowfang Keep pilot. Use All Dungeons to return.")
            elseif not data.available then
                Add("Shadowfang Keep — loot and quest data are unavailable, not confirmed absent.")
            else
                Add("Shadowfang Keep  |  " .. (data.location or "Location unknown") .. "  |  Source level range: " .. (data.level or "Unknown"), nil, nil, T.secondary)
                if v.tab == "loot" then
                    local boss = v.boss and data.bosses[v.boss]
                    if boss then
                        Add("< All bosses", function() M:Navigate(v.dungeon, "loot") end)
                        Add(boss.name .. " — Boss Loot", nil, nil, T.secondary)
                        local count = 0
                        for _, item in ipairs(boss.items) do if Item(item) then count = count + 1 end end
                        if count == 0 then Add(#boss.items == 0 and "No loot records supplied. Drops are unknown." or "No items match your search.") end
                    else
                        local count = 0
                        for index, entry in ipairs(data.bosses) do
                            if M:Matches(entry.name) then
                                local selected = index
                                Add(entry.name .. "  —  " .. #entry.items .. " listed items", function() M:Navigate(v.dungeon, "loot", selected) end)
                                count = count + 1
                            end
                        end
                        if count == 0 then Add(#data.bosses == 0 and "No boss records supplied." or "No bosses match your search.") end
                    end
                else
                    local quest = v.quest and data.quests[v.quest]
                    if quest then
                        Add("< All quests", function() M:Navigate(v.dungeon, "quests") end)
                        Detail(quest)
                        if #quest.chain > 0 then
                            Add("Prerequisites listed by the source", nil, nil, T.secondary)
                            for index, step in ipairs(quest.chain) do Detail(step, index .. ". ") end
                        else Add("Prerequisites: none recorded by this source; availability is not guaranteed.") end
                        Add("Quest rewards", nil, nil, T.secondary)
                        if quest.rewards then Add(quest.rewards) end
                        if quest.rewardSummary and quest.rewardSummary ~= "" then Add(quest.rewardSummary) end
                        for _, item in ipairs(quest.items) do Item(item) end
                        if #quest.items == 0 and not quest.rewards then Add("Reward items not recorded.") end
                    else
                        local count = 0
                        for index, q in ipairs(data.quests) do
                            local matchesFaction = v.faction == "all" or not q.faction or q.faction == "Both" or q.faction == v.faction
                            if matchesFaction and M:Matches(q.name) then
                                local selected = index
                                Add(q.name .. "  —  " .. (q.faction or "Faction unknown") .. (q.classOnly and (" / " .. q.classOnly) or ""),
                                    function() M:Navigate(v.dungeon, "quests", nil, selected) end)
                                count = count + 1
                            end
                        end
                        if count == 0 then Add(#data.quests == 0 and "No quest records supplied." or "No quests match your filters.") end
                    end
                end
            end
        end
        self:Layout()
        self.refreshing = nil
    end
    page:SetScript("OnShow", function() if self.active then self:ReadData() end; self:SyncEvents(); page:Refresh() end)
    page:SetScript("OnHide", function() self:SyncEvents(); self:HideTooltip() end)
    page:Finish()
    return page
end
