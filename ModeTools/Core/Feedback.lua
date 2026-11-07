local _,addon=...
local F={last={}}
addon.Feedback=F
local function Plain(v) return not (issecretvalue and issecretvalue(v)) end
-- Routine output is never deferred out of a restricted callback.
function F:Allowed(allowCombat)
    local ok,allowed=pcall(function()
        if allowCombat~=true and (InCombatLockdown() or UnitAffectingCombat("player")) then return false end
        local api,types=C_RestrictedActions,Enum and Enum.AddOnRestrictionType
        if api and type(api.GetAddOnRestrictionState)=="function" then
            if type(types)~="table" then return false end
            local inactive=Enum.AddOnRestrictionState and Enum.AddOnRestrictionState.Inactive
            if inactive==nil then return false end
            for _,kind in pairs(types) do
                if type(kind)=="number" then
                    local state=api.GetAddOnRestrictionState(kind)
                    if not Plain(state) or state~=inactive then return false end
                end
            end
        end
        return true
    end)
    return ok and allowed==true
end
function addon:PrintAction(message,key)
    if not F:Allowed() or not Plain(message) or type(message)~="string" or #message>240 then return false end
    local now=GetTime()
    key=key or message
    if not Plain(key) or type(key)~="string" then return false end
    if F.last[key] and now-F.last[key]<2 then return false end
    local sent=pcall(print,"|cff80ef80[Play The Game Tools]|r |cffdde3ed"..message:gsub("|","||").."|r")
    if sent then F.last[key]=now end
    return sent
end
