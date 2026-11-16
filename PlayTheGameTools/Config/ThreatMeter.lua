local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.ThreatMeter,addon.ConfigWidgets,addon.InterfaceTheme

-- Placement lives in Edit Mode; this page only holds what the meter shows.
function M:CreateConfigPage(parent)
    local page=W.Page(parent,480)
    self.page=page
    page:Group("Display")
    local cells=page:ToggleGrid({
        {label="Show Pets",get=function() return self.db.showPets end,set=function(v) self:SetOption("showPets",v) end},
        {label="Hide Out of Combat",get=function() return self.db.hideOutOfCombat end,set=function(v) self:SetOption("hideOutOfCombat",v) end},
    })
    page.threatControls={showPets=cells[1],hideOutOfCombat=cells[2]}
    -- Only shown when it matters: the client provides no threat data at all.
    local status=W.Label(page:Row("Availability",40),"Unavailable: this client does not provide threat data.",nil,0,-4,440,T.muted)
    status:SetWordWrap(true)
    status:GetParent().row.visibleWhen=function() return not self:Available() end
    page.threatStatus=status
    page:Finish()
    return page
end
