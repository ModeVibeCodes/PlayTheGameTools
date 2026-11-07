local addonName, addon = ...

-- Generated packages load this first. The source Retail TOC remains the baseline.
-- Identification is deliberately independent of feature/capability detection.
local E = {}
addon.Edition = E
local function Public(value)
    return not (issecretvalue and issecretvalue(value))
end
local ok, name = false, nil
if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
    ok, name = pcall(C_AddOns.GetAddOnMetadata, addonName, "X-PlayTheGameTools-Edition")
end
if ok and Public(name) and (name == "Retail" or name == "Forever") then E.name = name end

function E:CheckClient()
    local expected = self.name == "Forever" and WOW_PROJECT_CAMELOT or
        self.name == "Retail" and WOW_PROJECT_MAINLINE
    -- Never accept nil == nil or infer a client from a broad version range.
    local valid = self.name ~= nil and Public(expected) and type(expected) == "number"
        and Public(WOW_PROJECT_ID) and type(WOW_PROJECT_ID) == "number"
        and WOW_PROJECT_ID == expected
    if valid then return true end
    self.diagnostic = "Play The Game Tools: " .. (self.name or "unidentified") ..
        " package/client mismatch or unavailable project constants; startup blocked before settings migration."
    if not self.reported then
        self.reported = true
        print(self.diagnostic)
    end
    return false
end
