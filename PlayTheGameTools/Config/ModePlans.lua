local _,addon=...
local W=addon.ConfigWidgets

-- Explicit presentation routes, never saved settings or gameplay categories.
-- A missing route stays in Options, so newly added controls remain reachable.
local textLabels={}
for _,label in ipairs({"Font","Font Size","Text outline","Text Color","Name Font","Name Font Size","Name Color","Name Outline",
    "Show Profession Names","Food Font","Food Font Size","Food Text Color","Food Name Outline","Show Food Names",
    "Title Text Size","Ability Text Size","Detail Text Size","Popout Text Size"}) do textLabels[label]=true end
local function Label(row)
    if row.settingsTitle and row.settingsTitle~="" then return row.settingsTitle end
    local names={};for _,cell in ipairs(row.settingsToggles or {}) do names[#names+1]=cell.label:GetText() end
    return table.concat(names,"|")
end
W.ModeLayoutPlans={
    characterReskin={decorateOnly=true},
    damageMeterReskin={decorateOnly=true},
    chatReskin={decorateOnly=true},
    combatTimer={features={{"timer","Combat Timer"}},route=function(row)
        local section=row.section and row.section.title
        if section=="Positioning" then return "timer","position" end
        local label=Label(row)
        if textLabels[label] then return "timer","text" end
        if section=="Display" and label~="Timer format" then return "timer","appearance" end
        return "timer","options"
    end},
    foreverAutomation={features={{"Quests","Quests"},{"Merchant","Merchant"},{"Dialogue","Dialogue"}},route=function(row)
        return row.settingsGroupTitle or row.settingsGroup or "Quests","options"
    end},
    foreverQuickAccess={features={{"professions","Professions"},{"food","Food Bar"}},route=function(row)
        local section=row.section and row.section.title or ""
        local food=section:sub(1,4)=="Food"
        local feature=food and "food" or "professions"
        if section=="Positioning" or section=="Food Positioning" then return feature,"position" end
        if textLabels[Label(row)] then return feature,"text" end
        if section=="Layout" or section=="Food Layout" or section=="Appearance" or section=="Food Appearance" then
            if Label(row)=="Show Tooltips" or Label(row)=="Food Tooltips" then return feature,"options" end
            return feature,"appearance"
        end
        return feature,"options"
    end},
    threatMeter={features={{"meter","Threat Meter"}},route=function(row)
        return "meter",(row.settingsGroupTitle or row.settingsGroup)=="Position" and "position" or "options"
    end},
    enhancedExperienceBar={features={{"bar","XP Bar"},{"session","Session Text"}},route=function(row)
        local section=row.section and row.section.title
        if section=="Session Text" then
            local label=Label(row)
            return "session",(label=="Session Scope" or label=="Session Tracking") and "options" or "text"
        end
        if section=="Position" then return "bar","position" end
        if section=="Bar Text" then return "bar","text" end
        if section=="Layout" or section=="Bar Appearance" or section=="Colors" then return "bar","appearance" end
        return "bar","options"
    end},
    -- These pages own section-dependent catalogs or feature gating. Keep their
    -- original section selection methods and dynamic row pools intact.
    foreverClassTraining={preserveSections=true,route=function(row)
        local section=row.section
        if not section or section.title=="Upcoming Abilities" or section.title=="Available & Known" then return end
        local label=Label(row)
        if textLabels[label] then return section.title,"text" end
        if row.settingsHasSlider then return section.title,"appearance" end
        return section.title,"options"
    end},
    lootSparkles={preserveSections=true,route=function(row)
        if not row.section or row.section.title~="Loot Sparkles" then return end
        if Label(row)=="Name Font Size" then return "Loot Sparkles","text" end
        return "Loot Sparkles",(row.settingsGroupTitle or row.settingsGroup)=="Appearance" and "appearance" or "options"
    end},
    foreverRecruitment={preserveSections=true,route=function(row) if row.section then return row.section.title,"options" end end},
    foreverGuildRoster={preserveSections=true},
    foundation={decorateOnly=true},
    foreverRogue={features={{"general","General"},{"watchStyle","Poison Reminder"},{"launcherStyle","Quick Icon"},{"flyoutStyle","Expanded Menu"},{"apply","Quick Apply"}},
        route=function(row)
            if row.modeFeature then return row.modeFeature,row.modePanel or "appearance" end
            if row.section and row.section.title=="Settings" then return "apply","options" end
            return "general","options"
        end,
        select=function(page,feature)
            if feature=="watchStyle" then page.customize="reminder"
            elseif feature=="launcherStyle" or feature=="flyoutStyle" then page.customize="quick";page.quickCustomize=feature=="flyoutStyle" and "menu" or "icon" end
        end},
}

W.ModePanelDescriptions={options="Choose what this display shows and when it appears.",text="Set the font, size, color and placement of text.",
    appearance="Adjust the size, spacing, colors and opacity.",position="Move, anchor or lock this display."}
