local _, addon = ...
local M, W, T = addon.ForeverAutomation, addon.ConfigWidgets, addon.Theme

function M:CreateConfigPage(parent)
    local page = W.Page(parent, 480)
    page.automationControls = {}
    page:Group("Quests")
    local quests = page:ToggleGrid({
        { label = "Auto Accept Quests", get = function() return self.db.autoAccept == true end,
            set = function(value) self:SetOption("autoAccept", value) end },
        { label = "Auto Turn-In Quests", get = function() return self.db.autoTurnIn == true end,
            set = function(value) self:SetOption("autoTurnIn", value) end },
    })
    page.automationControls.autoAccept, page.automationControls.autoTurnIn = quests[1], quests[2]
    local select = W.Select(page:Row("Modifier Bypass", 48), 280,
        function() return {{id="shift",label="Shift"},{id="ctrl",label="Ctrl"},{id="alt",label="Alt"}} end,
        function() return self.db.bypassModifier, ({shift="Shift",ctrl="Ctrl",alt="Alt"})[self.db.bypassModifier] end,
        function(value) self:SetModifier(value) end)
    page.modifierDropdown = select
    -- Status rows appear only when the client rejected an action this session.
    local questStatus = W.Label(page:Row("Quest Automation", 48), "Unavailable this session: the client rejected a quest action. Quests stay manual.", nil, 0, -4, 440, T.primary)
    questStatus:SetWordWrap(true)
    page.questStatusLabel = questStatus
    questStatus:GetParent().row.visibleWhen = function() return self.questBlocked == true end
    page.refreshers[#page.refreshers + 1] = function() select:Refresh() end
    page:Group("Merchant")
    local merchant = page:ToggleGrid({
        { label = "Auto Sell Junk", get = function() return self.db.sellJunk == true end,
            set = function(value) self:SetOption("sellJunk", value) end },
        { label = "Auto Repair", get = function() return self.db.repair == true end,
            set = function(value) self:SetOption("repair", value) end },
        { label = "Auto Sell Gray Equipment", get = function() return self.db.sellGrayEquipment == true end,
            set = function(value) self:SetOption("sellGrayEquipment", value) end },
    })
    page.automationControls.sellJunk, page.automationControls.repair = merchant[1], merchant[2]
    page.automationControls.sellGrayEquipment = merchant[3]
    local thresholdRow = page:Row("Maximum Repair Cost (%)", 48)
    page.refreshers[#page.refreshers + 1] = W.Slider(thresholdRow, 5, 100, 5,
        function() return self.db.maxRepairCostPercent end, function(value) self:SetRepairThreshold(value) end, "%")
    page.repairThresholdSlider = thresholdRow.slider
    local merchantStatus = W.Label(page:Row("Merchant Automation", 48), "", nil, 0, -4, 440, T.primary)
    merchantStatus:SetWordWrap(true); page.merchantStatusLabel = merchantStatus
    merchantStatus:GetParent().row.visibleWhen = function()
        local blocked = self.merchantBlocked or {}; return (blocked.sellJunk or blocked.repair) and true or false
    end
    page.refreshers[#page.refreshers + 1] = function()
        local blocked = self.merchantBlocked or {}
        merchantStatus:SetText("Unavailable this session: " .. (blocked.sellJunk and "Auto Sell Junk " or "") .. (blocked.repair and "Auto Repair" or "") .. " was rejected by the client.")
    end
    -- Blocked-state rows can appear after a session rejection.
    page.refreshers[#page.refreshers + 1] = function() page:Layout() end
    page:Finish()
    return page
end
