local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.ThreatMeter,addon.ConfigWidgets,addon.InterfaceTheme

function M:CreateConfigPage(parent)
    local page=W.Page(parent,480)
    self.page=page
    page:Group("Display")
    local cells=page:ToggleGrid({
        {label="Show Pets",get=function() return self.db.showPets end,set=function(v) self:SetOption("showPets",v) end},
        {label="Hide Out of Combat",get=function() return self.db.hideOutOfCombat end,set=function(v) self:SetOption("hideOutOfCombat",v) end},
    })
    page.threatControls={showPets=cells[1],hideOutOfCombat=cells[2]}
    local note=W.Label(page:Row("Threat Meter",96),
        "Lists threat on your current hostile target for you and your group, highest first. 100% is holding aggro; if the client hides a percentage, the row shows Aggro, High, Low or Hidden. Hide Out of Combat applies only while the meter is locked.",
        nil,0,-4,440,T.muted)
    note:SetWordWrap(true)
    page:Group("Position")
    local lock=page:ToggleGrid({
        {label="Lock Threat Meter",get=function() return self.db.locked end,set=function(v) self:SetOption("locked",v) end},
    })
    page.threatControls.locked=lock[1]
    local reset=W.Button(page:Row("Threat Meter Position",48),"Reset Position",180,28);reset:SetPoint("LEFT")
    reset:SetScript("OnClick",function() self:ResetPosition();page:Refresh() end)
    page.threatReset=reset
    local status=W.Label(page:Row("Availability",64),"",nil,0,-4,440,T.muted)
    status:SetWordWrap(true)
    page.threatStatus=status
    page.refreshers[#page.refreshers+1]=function()
        status:SetText(self:Available() and "Unlock to drag the meter. Threat comes from the client and may be missing for some group members." or
            "Unavailable: this client does not provide threat data.")
    end
    page:Finish()
    return page
end
