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
    if db.shortcutSize==nil then db.shortcutSize=40 end
    if db.shortcutOpacity==nil then db.shortcutOpacity=100 end
    assert(Number(db.shortcutSize) and db.shortcutSize>=24 and db.shortcutSize<=72 and db.shortcutSize%2==0,"Invalid Dungeon Loot icon size.")
    assert(Number(db.shortcutOpacity) and db.shortcutOpacity>=25 and db.shortcutOpacity<=100 and db.shortcutOpacity%5==0,"Invalid Dungeon Loot icon opacity.")
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
local QUICK_ACTION="dungeonLoot"
local LOOT_ICON="Interface\\Buttons\\UI-GroupLoot-Dice-Up"
function M:ApplyShortcutAppearance()
    local b=self.shortcut;if not b or not OutsideCombat() then return end
    addon.QuickActions.SizeIcon(b,self.db.shortcutSize)
    b:SetAlpha(self.db.shortcutOpacity/100)
    addon.QuickActions:Layout()
end
function M:SetShortcutOption(key,value)
    if not OutsideCombat() then return false end
    local valid=(key=="shortcutSize" and Number(value) and value>=24 and value<=72 and value%2==0)
        or (key=="shortcutOpacity" and Number(value) and value>=25 and value<=100 and value%5==0)
        or (key=="showShortcut" and type(value)=="boolean")
    if not valid then return false end
    self.db[key]=value;self:SyncShortcut();return true
end
-- The icon lives in the shared ring, so position controls act on its launcher.
function M:ResetShortcutPosition()
    if not OutsideCombat() then return false end
    return addon.QuickActions:ResetPosition()
end
function M:EditShortcutPosition()
    if not self.active or not self.db.showShortcut or not OutsideCombat() then return false end
    self:SyncShortcut()
    return addon.QuickActions:EditPosition()
end
function M:CreateDungeonShortcut()
    if self.shortcut or not OutsideCombat() then return end
    self.shortcut=addon.QuickActions:AddAction(QUICK_ACTION,{order=20,texture=LOOT_ICON,color={.38,.66,.96},
        title="Dungeon Loot",hint="Click to open.",
        onClick=function() if self.active then self:OpenDungeonLoot() end end})
    self:ApplyShortcutAppearance()
end
function M:SyncShortcut()
    self.shortcutEvents:UnregisterAllEvents()
    if self.active then
        self.shortcutEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.shortcutEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.shortcutEvents:RegisterEvent("UPDATE_BINDINGS")
    end
    if not self.active or not self.db.showShortcut then
        self:CancelShortcutBinding()
        addon.QuickActions:SetAvailable(QUICK_ACTION,false)
        return
    end
    if OutsideCombat() then self:CreateDungeonShortcut();self:ApplyShortcutAppearance() end
    addon.QuickActions:SetAvailable(QUICK_ACTION,true)
end
function M:InitializeShortcut()
    M.InitializeShortcutSettings(self.db)
    self.shortcutEvents=CreateFrame("Frame")
    self.shortcutEvents:SetScript("OnEvent",function(_,event)
        if event=="UPDATE_BINDINGS" then
            if not self.bindingWriting and self.page and self.page:IsShown() and self.view.tab=="general" then self.page:Refresh() end
        elseif event=="PLAYER_REGEN_DISABLED" then self:CancelShortcutBinding()
        else self:SyncShortcut() end
    end)
end

-- Hardware-driven binding editor. The selected key replaces its current action;
-- failed writes restore both that action and Dungeon Loot's previous keys.
local ACTION="PTGTOOLS_DUNGEON_LOOT"
local function Read(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end
function M:ShortcutBindingKeys()
    if type(GetBindingKey)~="function" then return nil end
    local values={pcall(GetBindingKey,ACTION)}
    if not values[1] then return nil end
    local keys={}
    for i=2,#values do
        local key=values[i]
        if (issecretvalue and issecretvalue(key)) or type(key)~="string" then return nil end
        keys[#keys+1]=key
    end
    return keys
end
function M:ShortcutBindingLabel()
    local keys=self:ShortcutBindingKeys()
    if not keys then return "Unavailable" end
    return #keys>0 and table.concat(keys,", ") or "Not bound"
end
function M:SaveShortcutBinding(key)
    if not OutsideCombat() then return false,"Change keybindings outside combat." end
    if key~=nil and (type(key)~="string" or #key>80 or not key:match("^[A-Z0-9_%-]+$")) then return false,"Unsupported key." end
    local keys=self:ShortcutBindingKeys()
    local set=Read(GetCurrentBindingSet)
    if not keys or (set~=1 and set~=2) or type(SetBinding)~="function" or type(SaveBindings)~="function" then
        return false,"Keybinding APIs unavailable; use WoW Key Bindings."
    end
    local oldAction=""
    if key then oldAction=Read(GetBindingAction,key) end
    if key and type(oldAction)~="string" then return false,"Cannot read this key's binding." end
    -- Verify ownership again before clearing existing keys.
    for _,old in ipairs(keys) do if Read(GetBindingAction,old)~=ACTION then return false,"Bindings changed; try again." end end
    local function Bind(k,action)
        local ok,result=pcall(SetBinding,k,action)
        return ok and result==true
    end
    local function Restore()
        if key then Bind(key,oldAction~="" and oldAction or nil) end
        for _,old in ipairs(keys) do Bind(old,ACTION) end
    end
    local function Finish(ok,message) self.bindingWriting=nil;return ok,message end
    self.bindingWriting=true
    if key and not Bind(key,ACTION) then Restore();return Finish(false,"This client rejected the keybinding.") end
    for _,old in ipairs(keys) do
        if old~=key and not Bind(old,nil) then Restore();return Finish(false,"Could not change the previous binding.") end
    end
    local ok,result=pcall(SaveBindings,set) -- native success may return nil
    if not ok or result==false then
        Restore();pcall(SaveBindings,set)
        return Finish(false,"Could not save bindings; use WoW Key Bindings.")
    end
    return Finish(true,key and ("Bound to "..key..".") or "Dungeon Loot keybinding cleared.")
end
function M:CancelShortcutBinding()
    local f=self.bindingCapture;if not f then return end
    f:SetScript("OnKeyDown",nil);pcall(f.EnableKeyboard,f,false);pcall(f.SetPropagateKeyboardInput,f,true);f:Hide()
end
function M:CaptureShortcutBinding()
    if not self.active or not OutsideCombat() or not self.page or not self.page:IsShown() or self.view.tab~="general" then return false end
    if not self.bindingCapture then
        local W=addon.ConfigWidgets
        local f=CreateFrame("Frame",nil,self.page);f:SetSize(380,124);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG")
        f:SetFrameLevel(self.page:GetFrameLevel()+100);f:EnableMouse(true);W.Texture(f,"Window")
        f.title=W.Label(f,"Press a key for Dungeon Loot",nil,14,-14,350)
        f.hint=W.Label(f,"Modifiers allowed. Escape cancels.",nil,14,-42,350)
        f.hint:SetWordWrap(true)
        local cancel=W.Button(f,"Cancel",80,26);cancel:SetPoint("BOTTOMRIGHT",-12,12)
        cancel:SetScript("OnClick",function() self:CancelShortcutBinding() end)
        f:SetScript("OnHide",function()
            f:SetScript("OnKeyDown",nil);pcall(f.EnableKeyboard,f,false);pcall(f.SetPropagateKeyboardInput,f,true)
        end)
        self.bindingCapture=f
    end
    local f=self.bindingCapture
    f.hint:SetText("Modifiers allowed. Escape cancels.")
    f:SetScript("OnKeyDown",function(_,key)
        if not OutsideCombat() then self:CancelShortcutBinding();return end
        if type(key)~="string" or (issecretvalue and issecretvalue(key)) then return end
        if key=="ESCAPE" then self:CancelShortcutBinding();return end
        if key=="LSHIFT" or key=="RSHIFT" or key=="LCTRL" or key=="RCTRL" or key=="LALT" or key=="RALT" then return end
        key=key:upper()
        if Read(IsShiftKeyDown)==true then key="SHIFT-"..key end
        if Read(IsControlKeyDown)==true then key="CTRL-"..key end
        if Read(IsAltKeyDown)==true then key="ALT-"..key end
        local ok,message=self:SaveShortcutBinding(key)
        self.bindingStatus=message
        if ok then self:CancelShortcutBinding();self.page:Refresh()
        else f.hint:SetText(message) end
    end)
    f:Show()
    local ok=pcall(function() f:EnableKeyboard(true);f:SetPropagateKeyboardInput(false) end)
    if not ok then self:CancelShortcutBinding();return false end
    return true
end
