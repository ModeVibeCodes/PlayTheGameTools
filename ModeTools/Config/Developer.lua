local _, addon = ...
local W, T = addon.ConfigWidgets, addon.Theme
local module = addon.modules.foundation

module.CreateConfigPage = function(self, parent)
    local page = W.Page(parent)
    -- Page-local parent gating; shared page/search/scroll framework unchanged.
    local section, expand = page.Section, page.SetSectionExpanded
    page.developerGroups, page.developerGroupIndex = {}, {}
    local selectedGroup=1
    local jumpRow=page:Row("Jump to developer group",76)
    jumpRow.rowLabel:ClearAllPoints();jumpRow.rowLabel:SetPoint("TOPLEFT",14,-6)
    jumpRow:ClearAllPoints();jumpRow:SetPoint("TOPLEFT",jumpRow.row,"TOPLEFT",14,-36)
    jumpRow:SetPoint("BOTTOMRIGHT",jumpRow.row,"BOTTOMRIGHT",-14,8)
    local jump=W.Select(jumpRow,300,function()
        local choices={}
        for i,group in ipairs(page.developerGroups) do choices[#choices+1]={id=i,label=group.title} end
        return choices
    end,function()
        local group=page.developerGroups[selectedGroup]
        return selectedGroup,group and group.title or "General Diagnostics"
    end,function(id)
        local group=page.developerGroups[id]
        if not group then return end
        selectedGroup=id;page:SetSectionExpanded(group,true);page:Layout()
        page.scrollbar:SetValue(math.max(0,(group.header.offset or 0)-8))
    end)
    function jumpRow.row:layoutChildren(width)
        jumpRow.rowLabel:SetWidth(math.max(100,width-28))
        jump:SetWidth(math.max(100,width-28));jump.label:SetWidth(math.max(84,width-44))
    end
    page.developerJump=jump
    page.refreshers[#page.refreshers+1]=function() jump:Refresh() end
    function page:SetSectionExpanded(item, value)
        if item.parentGroup then
            if value and not item.parentGroup.expanded then self:SetSectionExpanded(item.parentGroup,true) end
            item.developerExpanded=value
            expand(self,item,value and item.parentGroup.expanded)
        else
            expand(self,item,value)
            for _,child in ipairs(item.childSections or {}) do
                expand(self,child,value and child.developerExpanded)
            end
        end
    end
    local function Group(title, builder, opened, defaults)
        local group=section(page,title,nil,true)
        group.childSections={}
        page.developerGroups[#page.developerGroups+1]=group
        page.developerGroupIndex[title]=group
        local first=#page.rows+1
        page.Section=function(owner,name,description)
            local child=section(owner,name,description,true)
            child.parentGroup=group;child.developerExpanded=defaults and defaults[name]==true or false
            group.childSections[#group.childSections+1]=child
            return child
        end
        builder()
        page.Section=section
        for i=first,#page.rows do
            local row=page.rows[i]
            local visible=row.visibleWhen
            row.visibleWhen=function() return group.expanded and (not visible or visible()) end
        end
        page:SetSectionExpanded(group,opened==true)
    end
    Group("General Diagnostics",function()
        local schema = W.Label(page:Row("Database schema"), "", nil, 0, -8, 180, T.secondary)
        local count = W.Label(page:Row("Registered modules"), "", nil, 0, -8, 180, T.secondary)
        local controls = page:Row("Registry diagnostic")
        local toggle = W.Button(controls, "", 52, 26, "toggle")
        toggle:SetPoint("LEFT")
        local status = W.Label(controls, "", nil, 62, -8, 180, T.muted)
        toggle:SetScript("OnClick", function() addon:SetModuleEnabled("foundation", not self.enabled) end)
        page.refreshers[#page.refreshers + 1] = function()
            schema:SetText(tostring(addon.db.schemaVersion))
            count:SetText(tostring(#addon.moduleOrder))
            toggle:SetSelected(self.enabled)
            status:SetText(self.status)
        end
        page.diagnosticToggle = toggle
    end,true)
    -- Included diagnostics follow the package boundary, not disabled module defaults.
    if not addon.Edition or addon.Edition.name ~= "Forever" then
    Group("Party Cooldowns — Live Diagnostics",function()
        addon:CreatePartyCooldownDiagnostics(page)
        local note=W.Label(page:Row("Automatic Reports",64),"Use Mythic+ → Party Cooldowns → General → Session Diagnostics for automatic run reports. Controls below are advanced manual snapshots and isolated tests.",nil,0,-4,370,T.muted)
        note:SetWordWrap(true)
    end,true,{["Party Cooldown Diagnostics"]=true})
    Group("Party Cooldowns — Recovery Experiments",function()
        addon:CreateExperimentalBarkskinRecovery(page)
        addon:CreateExperimentalAuraSensor(page)
    end,false,{["Experimental Continuous Recovery — Phase 8.21"]=true})
    Group("Party Cooldowns — Visual Prototypes",function()
        addon:CreateExperimentalMovingVeil(page)
        addon:CreateExperimentalAuraBorder(page)
        addon:CreateBarkskinMovingVeil(page)
    end)
    Group("Legacy & Historical Tests",function()
        addon:CreateExperimentalBrewRecovery(page)
        addon:CreateExperimentalEncodedGray(page)
    end)
    Group("Other Module Diagnostics",function()
        addon:CreateInterruptDiagnostics(page)
        addon:CreateDungeonCastsDiagnostics(page)
        addon:CreateAutomationDiagnostics(page)
        addon:CreateLootChoiceDiagnostics(page)
        if addon.CreateRacialAwarenessDiagnostics then addon:CreateRacialAwarenessDiagnostics(page) end
    end)
    end
    page:Finish()
    return page
end
