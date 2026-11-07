local _,addon=...
local R,W,T=addon.ReloadManager,addon.ConfigWidgets,addon.InterfaceTheme
function addon:ShowReloadPrompt()
    if not R:IsPending() or InCombatLockdown() or UnitAffectingCombat("player") then return end
    local dialog=R.prompt
    if not dialog then
        dialog=CreateFrame("Frame",nil,UIParent);dialog:Hide();R.prompt=dialog
        dialog:SetSize(460,180);dialog:SetPoint("CENTER");dialog:SetFrameStrata("DIALOG");dialog:SetFrameLevel(240)
        dialog:EnableMouse(true);dialog:SetClampedToScreen(true)
        W.Texture(dialog,"Window");W.Texture(dialog,"BorderSilver","BORDER")
        local message=W.Label(dialog,"Play The Game Tools needs to reload your UI to apply recent changes.",nil,16,-16,428,T.text);message:SetWordWrap(true)
        dialog.reason=W.Label(dialog,"",nil,16,-58,428,T.muted);dialog.reason:SetWordWrap(true)
        dialog.status=W.Label(dialog,"",nil,16,-96,428,T.muted);dialog.status:SetWordWrap(true)
        local now=W.Button(dialog,"Reload Now",120,30,"primary");now:SetPoint("BOTTOMLEFT",16,14)
        local later=W.Button(dialog,"Later",100,30,"secondary");later:SetPoint("LEFT",now,"RIGHT",10,0)
        now:SetScript("OnClick",function()
            local ok,reason=R:Reload();dialog.status:SetText(reason)
            if ok then dialog:Hide() end
        end)
        later:SetScript("OnClick",function() dialog:Hide() end)
        dialog.reloadNow,dialog.later=now,later
    end
    dialog:SetScale(math.max(0.1,math.min(1,(UIParent:GetWidth()-24)/460,(UIParent:GetHeight()-24)/180)))
    dialog.reason:SetText(R:GetReason());dialog.status:SetText("");dialog:Show()
end
