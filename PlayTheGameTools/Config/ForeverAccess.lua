local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" or not addon.Edition:CheckClient() then return end

local function PublicFalse(fn,arg)
    if type(fn)~="function" or type(issecretvalue)~="function" then return false end
    local ok,value=pcall(fn,arg)
    if not ok then return false end
    local readable,secret=pcall(issecretvalue,value)
    return readable and secret==false and value==false
end
local function OutsideCombat()
    return PublicFalse(InCombatLockdown) and PublicFalse(UnitAffectingCombat,"player")
end

local installed=false
local function InstallMenuAccess()
    local menu=GameMenuFrame
    if installed then return true end
    if not menu or type(menu.InitButtons)~="function" or type(menu.AddButton)~="function" or
        type(hooksecurefunc)~="function" or type(HideUIPanel)~="function" then return false end
    hooksecurefunc(menu,"InitButtons",function(owner)
        if not addon.initialized or not OutsideCombat() then return end
        -- Native Reset releases this pooled button on each rebuild; AddButton marks layout dirty.
        local button=owner:AddButton("|cff50c8bdPlay The Game Tools|r",function()
            if not addon.initialized or not OutsideCombat() then return end
            HideUIPanel(owner)
            if addon.editMode then addon:SetEditMode(false) end
            if not addon.configWindow or not addon.configWindow:IsShown() then addon:ToggleConfig() end
        end)
        -- Keep native layout, controller traversal and narration in the same order.
        if type(owner.buttons)=="table" and owner.buttons[#owner.buttons]==button then
            table.remove(owner.buttons);table.insert(owner.buttons,1,button)
            for i,item in ipairs(owner.buttons) do
                item.layoutIndex=i
                if NarrationUtil and type(NarrationUtil.MakeIndexInfo)=="function" then
                    item.NarrationGetIndexInfo=function() return NarrationUtil.MakeIndexInfo(i,#owner.buttons) end
                end
            end
        end
        if owner.ResetGamepadButtons and owner.SetupGamepadButtons then
            owner:ResetGamepadButtons();owner:SetupGamepadButtons()
        end
    end)
    installed=true
    return true
end

-- Blizzard_GameMenu may load later. No force-load, timer or native layout replacement.
if not InstallMenuAccess() then
    local wait=CreateFrame("Frame")
    wait:RegisterEvent("ADDON_LOADED")
    wait:SetScript("OnEvent",function(self)
        if InstallMenuAccess() then self:UnregisterAllEvents();self:SetScript("OnEvent",nil) end
    end)
end
