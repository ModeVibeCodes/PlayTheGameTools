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
    combatTimer={features={{"timer","Combat Timer"}},route=function(row)
        local section=row.section and row.section.title
        local label=Label(row)
        if textLabels[label] then return "timer","text" end
        if section=="Display" then return "timer","appearance" end
        return "timer","options"
    end},
    foreverAutomation={features={{"Quests","Quests"},{"Merchant","Merchant"}},route=function(row)
        return row.settingsGroupTitle or row.settingsGroup or "Quests","options"
    end},
    foreverQuickAccess={features={{"professions","Professions"},{"food","Food Bar"}},route=function(row)
        local section=row.section and row.section.title or ""
        local food=section:sub(1,4)=="Food"
        local feature=food and "food" or "professions"
        if textLabels[Label(row)] then return feature,"text" end
        if section=="Layout" or section=="Food Layout" or section=="Appearance" or section=="Food Appearance" then
            if Label(row)=="Show Tooltips" or Label(row)=="Food Tooltips" then return feature,"options" end
            return feature,"appearance"
        end
        return feature,"options"
    end},
    threatMeter={features={{"meter","Threat Meter"}},route=function() return "meter","options" end},
    cityLabels={features={{"labels","Map Labels"}},route=function(row)
        return "labels",(row.settingsGroupTitle or row.settingsGroup)=="Appearance" and "appearance" or "options"
    end},
    enhancedExperienceBar={features={{"bar","XP Bar"},{"session","Session Text"}},route=function(row)
        local section=row.section and row.section.title
        if section=="Session Text" then
            local label=Label(row)
            return "session",(label=="Session Scope" or label=="Session Tracking") and "options" or "text"
        end
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
    -- One feature since Campfire Monitor split out to its own page.
    lootSparkles={features={{"sparkles","Loot Sparkles"}},route=function(row)
        if Label(row)=="Name Font Size" then return "sparkles","text" end
        return "sparkles",(row.settingsGroupTitle or row.settingsGroup)=="Appearance" and "appearance" or "options"
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

-- Panel tabs name the panel; no generic sentence is repeated on every page.
W.ModePanelDescriptions={}

-- Edit Mode owns the Text and Appearance panels of every placeable display:
-- selecting a display there shows these features' styling rows. Settings
-- pages keep only Options for them. Keys are Position Manager element ids;
-- features are the page routes (modeRoute or the Campfire element tags).
-- A third entry is an optional predicate for features that may not apply.
-- Camp buffs style from the icon unless their own window can be selected.
local function CampBuffsShared()
    local buffs=addon.PositionManager.elements.campfireBuffs
    return not addon.CampfireMonitor.db.separateBenefits or not (buffs and buffs.editMode and buffs.module.enabled)
end
W.EditAppearance={
    combatTimer={page="combatTimer",features={{"timer","Combat Timer"}}},
    foreverQuickAccess={page="foreverQuickAccess",features={{"professions","Profession Bar"}}},
    foreverFoodBar={page="foreverQuickAccess",features={{"food","Food Bar"}}},
    enhancedExperienceBar={page="enhancedExperienceBar",features={{"bar","XP Bar"},{"session","Session Text"}}},
    roguePoisonReminder={page="foreverRogue",features={{"watchStyle","Poison Reminder"}}},
    rogueQuickPoisons={page="foreverRogue",features={{"launcherStyle","Quick Icon"},{"flyoutStyle","Expanded Menu"}}},
    -- Camp buffs share the icon window unless they are split into their own.
    campfireMonitor={page="campfireMonitor",features={{"monitor","Campfire Icon"},{"buffs","Camp Buffs",CampBuffsShared},{"general","Shared Text"}}},
    campfireBuffs={page="campfireMonitor",features={{"buffs","Camp Buffs"},{"general","Shared Text"}}},
    campfireContributions={page="campfireMonitor",features={{"contributions","Contributions"}}},
}
-- The Text/Appearance panels are the styling Edit Mode takes over.
W.EditAppearancePanels={text=true,appearance=true}
function W.EditOwnedFeatures(pageId)
    local owned={}
    for _,entry in pairs(W.EditAppearance) do
        if entry.page==pageId then for _,feature in ipairs(entry.features) do owned[feature[1]]=true end end
    end
    return owned
end
