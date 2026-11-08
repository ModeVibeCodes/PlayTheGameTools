local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local A,D=addon.CampContributions,addon.ForeverQuickAccessData
function A:Hide(cancel)
    if cancel then self.generation=(self.generation or 0)+1;self.dirty=true end
    if self.window then self.window:Hide() end
    if D.OutsideCombat() then
        for _,button in ipairs(self.buttons or {}) do
            button:SetAttribute("type1",nil);button:SetAttribute("macrotext1",nil)
        end
    end
end
function A:OnSnapshot(snapshot)
    local s=snapshot or {}
    if s.known and not s.nearby then self.dismissed=false;self.wasNearby=false end
    if not self.active or not D.OutsideCombat() or s.nearby~=true or
        self.camp.previewing or self.camp.editing or self.camp.placing then
        self:Hide(true);return
    end
    if not self.wasNearby then self.dirty=true;self.wasNearby=true end
    if self.dismissed then self:Hide(true);return end
    if self.scanning then return end
    if self.dirty then self:Scan() end
    self:Render()
end
function A:Open()
    if not self.active or not D.OutsideCombat() then return false end
    self.dismissed=false;self.dirty=true;self:OnSnapshot(self.camp.snapshot)
    return self.window and self.window:IsShown() or false
end
function A:Dismiss()
    self.dismissed=true;self:Hide(true)
end
function A:SyncEnabled(camp)
    local active=camp.active and camp.db.showContributionPopup
    local changed=self.active~=active or self.db~=camp.db
    self.camp=camp;self.db=camp.db;self.active=active
    if not self.events then
        self.events=CreateFrame("Frame")
        self.events:SetScript("OnEvent",function(_,event,id)
            if event=="ITEM_DATA_LOAD_RESULT" and (not D.Public(id) or not self.catalog[id]) then return end
            self.dirty=true;self:OnSnapshot(self.camp.snapshot)
            if self.camp.owner.page then self.camp.owner.page:Refresh() end
        end)
    end
    if changed then
        self.events:UnregisterAllEvents();self.dirty=true;self.dismissed=false;self.wasNearby=false
        if active then
            for _,event in ipairs({"BAG_UPDATE_DELAYED","BAG_UPDATE_COOLDOWN","ITEM_LOCK_CHANGED",
                "SKILL_LINES_CHANGED","SPELLS_CHANGED","ITEM_DATA_LOAD_RESULT"}) do self.events:RegisterEvent(event) end
        else self.items={};self:Hide(true) end
    end
end
