local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M=addon.DungeonLoot
local function Number(v)
    return not (issecretvalue and issecretvalue(v)) and type(v)=="number" and v==v and math.abs(v)<=100000
end
local function OutsideCombat()
    local ok,lock=pcall(InCombatLockdown)
    local valid,combat=pcall(UnitAffectingCombat,"player")
    return ok and valid and lock==false and combat==false
end
function M.InitializeShortcutSettings(db)
    if db.showShortcut==nil then db.showShortcut=true end
    if db.shortcutLocked==nil then db.shortcutLocked=false end
    assert(type(db.showShortcut)=="boolean" and type(db.shortcutLocked)=="boolean","Invalid Dungeon Loot shortcut preference.")
    if db.shortcutPosition==nil then db.shortcutPosition={x=-230,y=-140} end
    assert(type(db.shortcutPosition)=="table" and Number(db.shortcutPosition.x) and Number(db.shortcutPosition.y),"Invalid Dungeon Loot shortcut position.")
end
function M:OpenDungeonLoot()
    if not addon.initialized then return false end
    if not OutsideCombat() then print("Play The Game Tools: open Dungeon Loot outside combat.");return false end
    if addon.editMode then addon:SetEditMode(false) end
    if not addon.configWindow or not addon.configWindow:IsShown() then addon:ToggleConfig() end
    addon:SelectConfigPage("dungeonLoot")
    if self.active then self:Navigate(nil)
    else self.view.dungeon=nil;self.view.tab="loot";if self.page then self.page:Refresh() end end
    return true
end
-- Native bindings use this shared entry point, independent of icon visibility.
BINDING_HEADER_PTGTOOLS="Play The Game Tools"
BINDING_NAME_PTGTOOLS_DUNGEON_LOOT="Open Dungeon Loot"
function PlayTheGameToolsOpenDungeonLoot() return M:OpenDungeonLoot() end
function M:PositionShortcut()
    local b=self.shortcut;if not b then return end
    local p=self.db.shortcutPosition
    b:ClearAllPoints();b:SetPoint("CENTER",UIParent,"CENTER",p.x,p.y)
end
function M:StopShortcutDrag(save)
    local b=self.shortcut;if not b or not b.moving then return end
    b:StopMovingOrSizing();b.moving=false
    if save and OutsideCombat() then
        local x,y=b:GetCenter();local px,py=UIParent:GetCenter()
        if Number(x) and Number(y) and Number(px) and Number(py) and Number(x-px) and Number(y-py) then
            self.db.shortcutPosition={x=x-px,y=y-py}
        end
    end
    self:PositionShortcut()
    C_Timer.After(0,function() b.wasDragged=nil end)
end
function M:CreateDungeonShortcut()
    if self.shortcut or not OutsideCombat() then return end
    local b=CreateFrame("Button",nil,UIParent)
    self.shortcut=b
    b:SetSize(40,40);b:SetFrameStrata("MEDIUM");b:SetClampedToScreen(true);b:SetMovable(true)
    local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.04,.06,.09,.9)
    local border=b:CreateTexture(nil,"BORDER");border:SetPoint("TOPLEFT",1,-1);border:SetPoint("BOTTOMRIGHT",-1,1)
    border:SetColorTexture(1,1,1,1);border:SetGradient("HORIZONTAL",CreateColor(159/255,204/255,250/255,1),CreateColor(9/255,116/255,241/255,1))
    local icon=b:CreateTexture(nil,"ARTWORK");icon:SetPoint("TOPLEFT",3,-3);icon:SetPoint("BOTTOMRIGHT",-3,3)
    icon:SetTexture("Interface\\Icons\\INV_Misc_TreasureChest01");icon:SetTexCoord(.07,.93,.07,.93)
    b:RegisterForClicks("LeftButtonUp");b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart",function()
        if self.active and not self.db.shortcutLocked and OutsideCombat() then
            b.wasDragged=true;b.moving=true;b:StartMoving()
        end
    end)
    b:SetScript("OnDragStop",function() self:StopShortcutDrag(true) end)
    b:SetScript("OnClick",function()
        if b.wasDragged then b.wasDragged=nil;return end
        if self.active then self:OpenDungeonLoot() end
    end)
    b:SetScript("OnEnter",function()
        if GameTooltip then
            GameTooltip:SetOwner(b,"ANCHOR_RIGHT");GameTooltip:SetText("Dungeon Loot")
            GameTooltip:AddLine(self.db.shortcutLocked and "Click to open. Unlock in Dungeon Loot > General to move." or "Click to open. Drag to move.",.8,.85,.9,true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnHide",function() self:StopShortcutDrag(false);if GameTooltip then GameTooltip:Hide() end end)
    self:PositionShortcut()
end
function M:SyncShortcut()
    self.shortcutEvents:UnregisterAllEvents()
    if self.active then
        self.shortcutEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.shortcutEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    if not self.active or not self.db.showShortcut then
        if self.shortcut then self.shortcut:Hide() end
        return
    end
    if OutsideCombat() then self:CreateDungeonShortcut();self:PositionShortcut() end
    if self.shortcut then self.shortcut:Show() end
end
function M:InitializeShortcut()
    M.InitializeShortcutSettings(self.db)
    self.shortcutEvents=CreateFrame("Frame")
    self.shortcutEvents:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_DISABLED" then self:StopShortcutDrag(false)
        else self:SyncShortcut() end
    end)
end
