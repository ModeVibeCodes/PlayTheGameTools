local _,addon=...
local R={requests={},drafts={}}
addon.ReloadManager=R
local function Combat() return InCombatLockdown() or UnitAffectingCombat("player") end
function R:IsPending() return next(self.requests)~=nil end
function R:GetReason()
    local keys,reasons={},{}
    for key in pairs(self.requests) do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys) do reasons[#reasons+1]=self.requests[key].reason end
    return table.concat(reasons," ")
end
function R:Refresh()
    local window=addon.configWindow
    if window and window.reloadButton then window.reloadButton:SetSelected(self:IsPending()) end
    if self.prompt then
        if not self:IsPending() then self.prompt:Hide()
        elseif self.prompt:IsShown() then self.prompt.reason:SetText(self:GetReason()) end
    end
end
function R:Request(key,reason,validate)
    assert(type(key)=="string" and key~="" and type(reason)=="string" and #reason<=200,"Play The Game Tools: invalid reload request.")
    assert(validate==nil or type(validate)=="function","Play The Game Tools: invalid reload validator.")
    self.requests[key]={reason=reason,validate=validate};self:Refresh()
end
function R:Clear(key) self.requests[key]=nil;self:Refresh() end
function R:SetDraft(key,dirty) self.drafts[key]=dirty and true or nil end
function R:SyncProfile()
    local P=addon.ProfileManager
    if not P or not P.root then return end
    local c=P:Character();local target=c and c.pendingProfile or P.queued and P.queued.name
    if target and target~=P.activeName then
        self:Request("profile","Apply profile: "..target..".",function() return P:ValidatePending() end)
    else self:Clear("profile") end
end
function R:Reload()
    if Combat() then return false,"Reload is unavailable during combat. Try again afterwards." end
    if next(self.drafts) then return false,"Finish or clear the unsent profile import before reloading." end
    for _,request in pairs(self.requests) do
        if request.validate then local ok,reason=request.validate();if not ok then return false,reason end end
    end
    local reload=ReloadUI
    if addon.Edition and addon.Edition.name=="Forever" and C_UI and type(C_UI.Reload)=="function" then
        reload=C_UI.Reload
    end
    if type(reload)~="function" then return false,"Reload is unavailable; use /reload when safe." end
    reload();return true,"Reload requested."
end
function R:OnWindowClosed()
    if not self:IsPending() then return end
    if Combat() then print("Play The Game Tools: reload pending; use Reload outside combat.");return end
    if addon.ShowReloadPrompt then addon:ShowReloadPrompt() end
end
function R:Start()
    if self.events then return end
    self.events=CreateFrame("Frame");self.events:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.events:SetScript("OnEvent",function() if self.prompt then self.prompt:Hide() end end)
    self:SyncProfile()
end
