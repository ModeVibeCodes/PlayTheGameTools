local _,addon=...
local S={providers={},states={},phases={},views={}}
addon.PreviewStates=S
local function Visible(frame)
    for _=1,20 do
        if not frame then return true end
        if not frame:IsShown() then return false end
        frame=frame:GetParent()
    end
    return false
end
function S:Register(id,provider)
    if self.providers[id] or not addon.modules[id] or type(provider)~="table" or type(provider.sample)~="function" or type(provider.states)~="table" or #provider.states==0 then return false end
    local seen={}
    for _,item in ipairs(provider.states) do
        if type(item)~="table" or type(item.id)~="string" or item.id=="" or type(item.label)~="string" or seen[item.id] then return false end
        seen[item.id]=true
    end
    if provider.previewAnimated and (not seen[provider.previewAnimated] or not provider.animated or not provider.animated[provider.previewAnimated]) then return false end
    self.providers[id]=provider;self.states[id]=provider.states[1].id;self.phases[id]=0
    self.views[id]=setmetatable({},{__mode="k"});return true
end
function S:Sample(id)
    local provider=self.providers[id]
    if not provider or self.states[id]==provider.states[1].id then return nil end
    return provider.sample(self.states[id],self.phases[id] or 0)
end
function S:Mode(id) return self.states[id] end
function S:RegisterView(id,view) if self.views[id] then self.views[id][view]=true end end
function S:UnregisterView(id,view) if self.views[id] then self.views[id][view]=nil;self:UpdateDriver() end end
function S:Unregister(id)
    if not self.providers[id] then return false end
    self:Stop(id)
    self.providers[id],self.states[id],self.phases[id],self.views[id]=nil,nil,nil,nil
    local module=addon.modules[id];if module and module.simulationLabel then module.simulationLabel:Hide() end
    self:UpdateDriver();return true
end
function S:OnScreen(id)
    local module=addon.modules[id]
    if module and module.IsSimulationVisible then return module:IsSimulationVisible() end
    return module and module.frame and module.frame:IsShown() and (module.testing or module.preview or module.editing)
end
function S:HasConsumer(id)
    if self:OnScreen(id) then return true end
    for view in pairs(self.views[id] or {}) do if Visible(view.frame) then return true end end
end
function S:Badge(id)
    local module=addon.modules[id]
    if not module.frame then return end
    local sim=self.providers[id] and self.states[id]~=self.providers[id].states[1].id
    local show=module.testing or (sim and self:OnScreen(id))
    if show and not module.simulationLabel and not InCombatLockdown() and not UnitAffectingCombat("player") then
        local label=module.frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        label:SetPoint("BOTTOM",module.frame,"TOP",0,4);label:SetText("SIMULATION")
        addon.Media:BindInterfaceFont(label,GameFontHighlight,10);label:SetTextColor(unpack(addon.Theme.secondary));module.simulationLabel=label
    end
    if module.simulationLabel then module.simulationLabel:SetShown(show and true or false) end
end
function S:Refresh(id,ticking)
    for view in pairs(self.views[id] or {}) do
        if Visible(view.frame) then
            if ticking and view.RenderSimulation then view:RenderSimulation() else view:Refresh() end
        end
    end
    local module=addon.modules[id]
    if self:OnScreen(id) then
        if module.Render then module:Render() elseif module.UpdateText then module.lastSecond=nil;module:UpdateText() end
    end
    self:Badge(id)
end
function S:UpdateDriver()
    local needed=false
    for id,provider in pairs(self.providers) do
        self:Badge(id)
        if self:IsAnimating(id) and self:HasConsumer(id) then needed=true end
    end
    if not self.driver and needed then self.driver=CreateFrame("Frame") end
    if not self.driver then return end
    if not needed then self.driver:SetScript("OnUpdate",nil);return end
    if self.driver:GetScript("OnUpdate") then return end
    local elapsed=0
    self.driver:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt;if elapsed<0.1 then return end
        local step=elapsed;elapsed=0
        for id,provider in pairs(self.providers) do
            if self:IsAnimating(id) and self:HasConsumer(id) then
                local nextPhase=(self.phases[id] or 0)+step
                self.phases[id]=provider.duration and math.min(nextPhase,provider.duration()) or nextPhase
                self:Refresh(id,true)
            end
        end
        self:UpdateDriver()
    end)
end
function S:IsAnimating(id)
    local provider=self.providers[id]
    return provider and provider.animated and provider.animated[self.states[id]]
        and (not provider.duration or (self.phases[id] or 0)<provider.duration())
end
function S:Set(id,state)
    local provider=self.providers[id]
    if not provider or (issecretvalue and issecretvalue(state)) or type(state)~="string" or InCombatLockdown() or UnitAffectingCombat("player") then return false end
    local valid=false;for _,item in ipairs(provider.states) do if item.id==state then valid=true end end
    if not valid then return false end
    if self.states[id]==state and not provider.restartOnSelect then return true end
    if provider.reset then provider.reset() end
    self.states[id],self.phases[id]=state,0
    self:Refresh(id);self:UpdateDriver()
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end
function S:Stop(id)
    local provider=self.providers[id]
    if not provider then return end
    if provider.reset then provider.reset() end
    self.states[id],self.phases[id]=provider.states[1].id,0
    self:Refresh(id);self:UpdateDriver()
end
function S:StopAll() for id in pairs(self.providers) do self:Stop(id) end end

-- Presentation mode is session-only and independent of embedded/external location.
-- Providers may opt into animation by naming one of their registered states.
function S:CanAnimate(id)
    local p=self.providers[id]
    return p and p.previewAnimated and p.animated and p.animated[p.previewAnimated] or false
end
function S:PreviewMode(id)
    local p=self.providers[id]
    return p and self:CanAnimate(id) and self.states[id]==p.previewAnimated and "animated" or "static"
end
function S:SetPreviewMode(id,mode)
    local p=self.providers[id]
    if not p or (mode~="static" and mode~="animated") then return false end
    if mode=="animated" and not self:CanAnimate(id) then return false end
    return self:Set(id,mode=="animated" and p.previewAnimated or p.states[1].id)
end
