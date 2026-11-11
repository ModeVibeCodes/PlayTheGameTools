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
    local questStatus = W.Label(page:Row("Quest Automation", 80), "", nil, 0, -4, 440, T.muted)
    questStatus:SetWordWrap(true)
    page.questStatusLabel = questStatus
    page:FooterNote(questStatus,function() return self.questBlocked end)
    page.refreshers[#page.refreshers + 1] = function()
        select:Refresh()
        questStatus:SetText(self.questBlocked and "Unavailable this session: native quest action rejected. Leave quests manual and review before retrying." or
            "Hold the selected key while opening an NPC interaction to keep it manual. Repeatables, payments, required items/currencies and multiple reward choices stay manual. Native acceptance pending.")
    end
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
    local merchantStatus = W.Label(page:Row("Merchant Automation", 80), "", nil, 0, -4, 440, T.muted)
    merchantStatus:SetWordWrap(true); page.merchantStatusLabel = merchantStatus
    page:FooterNote(merchantStatus,function()
        local blocked=self.merchantBlocked or {};return blocked.sellJunk or blocked.repair
    end)
    page.refreshers[#page.refreshers + 1] = function()
        local blocked = self.merchantBlocked or {}
        merchantStatus:SetText((blocked.sellJunk or blocked.repair) and
            ("Unavailable this session after rejection: " .. (blocked.sellJunk and "Auto Sell Junk " or "") .. (blocked.repair and "Auto Repair" or "") .. ". Leave affected actions manual and review.") or
            "Gray equipment requires its separate opt-in. Repair uses personal funds once per visit, within the selected percentage of your balance. Changes apply on the next visit. Native acceptance pending.")
    end
    page:Group("Dialogue")
    local gossip = page:ToggleGrid({{
        label = "Auto Gossip", get = function() return self.db.autoGossip == true end,
        set = function(value) self:SetOption("autoGossip", value) end,
    }})
    page.automationControls.autoGossip = gossip[1]
    local gossipStatus = W.Label(page:Row("Auto Gossip Availability", 80), "", nil, 0, -4, 440, T.muted)
    gossipStatus:SetWordWrap(true); page.gossipStatusLabel = gossipStatus
    page.refreshers[#page.refreshers + 1] = function()
        local available, reason = self:GossipCapability()
        gossip[1].frame:SetEnabled(available); gossip[1].button:SetEnabled(available)
        gossip[1].label:SetTextColor(unpack(T.muted)); gossipStatus:SetText(reason)
    end
    page.refreshers[#page.refreshers+1]=function() if page.modeFooterLayout then page:Layout() end end
    page:Finish()
    return page
end
