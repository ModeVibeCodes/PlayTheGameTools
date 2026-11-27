local _,addon=...
local W=addon.ConfigWidgets

-- Explicit presentation routes, never saved settings or gameplay categories.
-- A route names the feature a row belongs to; routed rows get the compact
-- form rhythm (Config/ModeLayout.lua). A missing route stays on the page as
-- built. Display styling is not on these pages: it lives in Layout.
W.ModeLayoutPlans={
    combatTimer={route=function() return "timer" end},
    foreverAutomation={route=function(row)
        return row.settingsGroupTitle or row.settingsGroup or "Quests"
    end},
    foreverQuickAccess={route=function(row)
        local section=row.section and row.section.title or ""
        return section:sub(1,4)=="Food" and "food" or "professions"
    end},
    threatMeter={route=function() return "meter" end},
    cityLabels={route=function() return "labels" end},
    enhancedExperienceBar={route=function(row)
        return row.section and row.section.title=="Session Text" and "session" or "bar"
    end},
    -- The training catalog keeps its own rows, outside these routes.
    foreverClassTraining={route=function(row)
        local section=row.section
        if not section or section.title=="Upcoming Abilities" or section.title=="Available & Known" then return end
        return section.title
    end},
    -- One feature since Campfire Monitor split out to its own page, which
    -- lays out its rows itself (Config/CampfireMonitor.lua).
    lootSparkles={route=function() return "sparkles" end},
    -- Guild (ID foreverRecruitment) has no settings sections: its page is a
    -- note, and the page header's Open Guild button opens the Guild window. A
    -- plan without a route only compacts the page. Guild Roster's plan left
    -- with its page (the retired foreverGuildRoster ID).
    foreverRecruitment={},
    -- Cooldown Profits: the reminder switches and a note; the ranking is the
    -- Cooldown Profits window. A plan without a route only compacts the page.
    cooldownProfits={},
    foundation={},
    foreverRogue={route=function(row)
        return row.section and row.section.title=="Settings" and "apply" or "general"
    end},
}
