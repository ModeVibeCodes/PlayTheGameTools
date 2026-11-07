local addonName, addon = ...
-- Package failure must stop before ADDON_LOADED can initialize/migrate settings.
if addon.Edition and not addon.Edition:CheckClient() then return end
addon.developmentPhase="Dev Phase 8.21 — Death Knight Recovery"
function addon:BuildIdentification()
    local ok,version=false,nil
    if C_AddOns and type(C_AddOns.GetAddOnMetadata)=="function" then
        ok,version=pcall(C_AddOns.GetAddOnMetadata,addonName,"Version")
    end
    if not ok or (issecretvalue and issecretvalue(version)) or type(version)~="string" or version=="" then version="unknown" end
    self.buildVersion=version:sub(1,48)
    return "v"..self.buildVersion.." | "..self.developmentPhase
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, loadedName)
    if loadedName ~= addonName or addon.initialized then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    if addon.Edition and not addon.Edition:CheckClient() then return end
    addon.Media:AttachLibrary()
    addon:InitializeDatabase()
    local ok,reason=pcall(addon.InitializeModules,addon)
    if not ok then addon.ProfileManager:InitializationFailed(reason);error(reason) end
    addon.ProfileManager:CommitInitialization()
    addon.initialized = true
    addon:InitializeDisplayModes()
    addon.Media:Initialize()
    addon.ProfileManager:Start()
    if not addon.Edition or addon.Edition.name ~= "Forever" then
        addon.PartyCooldownSessions:Initialize(ModeToolsDB)
    end
    addon.ReloadManager:Start()
    addon:PrintAction(addon:BuildIdentification(), "welcome")

    SLASH_MODETOOLS1 = "/modetools"
    SlashCmdList.MODETOOLS = function(text)
        if type(text)=="string" and text:lower():match("^%s*resetwindow%s*$") then
            addon:ResetConfigWindowPosition();return
        end
        addon:ToggleConfig()
    end
end)
