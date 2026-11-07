local _, addon = ...
-- Presentation only, after bootstrap definitions and before ADDON_LOADED.
if addon.Edition and addon.Edition.name == "Forever" then
    addon.developmentPhase = "Forever Beta"
end
