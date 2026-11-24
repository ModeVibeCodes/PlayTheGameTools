local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
-- The Guild window and the Guild settings page. The window keeps the old
-- Recruiter's frame name and Dialogs group; its Roster tab is built by
-- Config/ForeverGuildRoster.lua and its Recruit tab by Config/ForeverRecruitment.lua.
local M,W,T=addon.ForeverGuild,addon.ConfigWidgets,addon.InterfaceTheme
local Roster=addon.ForeverGuildRoster

M.WINDOW_TABS={{id="roster",label="Roster"},{id="recruit",label="Recruit"}}
M.DEFAULT_TAB="roster"
M.PAGE_NOTE="Roster and Recruit are tabs in the Guild window. Level range, classes and invite history live on the Recruit tab, next to the results they change."
local TAB_W,TAB_H=84,26

local function ValidTab(id)
    for _,tab in ipairs(M.WINDOW_TABS) do if tab.id==id then return id end end
    return M.DEFAULT_TAB
end

---------------------------------------------------------------------------
-- Guild window
---------------------------------------------------------------------------
function M:CreateWindow()
    local width,height=M.WINDOW_W,M.WINDOW_H
    local f=CreateFrame("Frame","PlayTheGameToolsRecruitmentFrame",UIParent)
    self.window=f
    -- Same strata as the settings window (DIALOG); raised on show so it opens in front.
    f:SetSize(width,height);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
    if f.SetToplevel then f:SetToplevel(true) end
    f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
    f:Hide()
    W.Texture(f,"Window")
    f.title=W.Heading(f,"Guild",T.fontSize.section,16,-14,72,T.text)

    local close=W.Button(f,"Close",64,24,"secondary");close:SetPoint("TOPRIGHT",-12,-10)
    close:SetScript("OnClick",function() f:Hide() end)
    local settings=W.Button(f,"Settings",76,24,"secondary");settings:SetPoint("RIGHT",close,"LEFT",-6,0)
    settings:SetScript("OnClick",function()
        if not addon.configWindow or not addon.configWindow:IsShown() then addon:ToggleConfig() end
        if addon.SelectConfigPage then addon:SelectConfigPage(M.id) end
    end)
    -- The module switch, so Guild can be turned on without the settings window.
    -- The switch is the state; no Enabled/Disabled text repeats it.
    local power=W.Button(f,"",44,24,"toggle");power:SetPoint("RIGHT",settings,"LEFT",-10,0)
    power:SetScript("OnClick",function() if M:OutsideCombat() then addon:SetModuleEnabled(M.id,not M.enabled);M:RefreshWindow() end end)
    f.power=power
    f.refreshers={}
    f.refreshers[1]=function() power:SetSelected(M.enabled==true) end

    -- Roster and Recruit tabs beside the title; each panel fills the window.
    f.tabs,f.panels={},{}
    for i,tab in ipairs(M.WINDOW_TABS) do
        local button=W.Button(f,tab.label,TAB_W,TAB_H,"tab")
        button:SetPoint("TOPLEFT",96+(i-1)*(TAB_W+6),-9)
        button:SetScript("OnClick",function() M:SelectTab(tab.id) end)
        f.tabs[tab.id]=button
        local panel=CreateFrame("Frame",nil,f);panel:SetAllPoints(f)
        f.panels[tab.id]=panel
    end
    local divider=W.Fill(f,T.line,"BORDER")
    divider:ClearAllPoints();divider:SetPoint("TOPLEFT",12,-42);divider:SetPoint("TOPRIGHT",-12,-42);divider:SetHeight(1)

    self:BuildRecruitTab(f,f.panels.recruit)
    Roster:BuildView(f,f.panels.roster)

    f:SetScript("OnShow",function() M:SelectTab(M.tab);M:RefreshWindow();M:SyncQuickAction() end)
    f:SetScript("OnHide",function() Roster:SetViewShown(false);M:SyncQuickAction() end)
    addon.Dialogs:Register(f,{group="recruiter"})
    return f
end

-- The tab is remembered for the session only.
function M:SelectTab(id)
    id=ValidTab(id)
    self.tab=id
    local f=self.window
    if not f then return end
    for key,panel in pairs(f.panels) do
        panel:SetShown(key==id)
        f.tabs[key]:SetSelected(key==id)
    end
    -- The roster is read only while its tab can be seen.
    Roster:SetViewShown(id=="roster" and f:IsShown())
    if id=="roster" then Roster:RenderPage() else self:RefreshWindow() end
end

function M:OpenWindow(tab)
    if tab then self.tab=ValidTab(tab) end
    if not self.window then self:CreateWindow() end
    local f=self.window
    -- Opening the Guild window closes the settings window, so it always centers.
    f:ClearAllPoints();f:SetPoint("CENTER")
    f:Show()
    self:SelectTab(self.tab)
    if f.Raise then f:Raise() end
end
function M:ToggleWindow(tab)
    if self.window and self.window:IsShown() and (not tab or ValidTab(tab)==self.tab) then self.window:Hide()
    else self:OpenWindow(tab) end
end

-- The old Recruiter command opens the Guild window on its Recruit tab.
SLASH_PLAYTHEGAMETOOLSRECRUIT1="/ptgr"
SlashCmdList.PLAYTHEGAMETOOLSRECRUIT=function()
    if addon.initialized then M:ToggleWindow("recruit") end
end

---------------------------------------------------------------------------
-- Settings page: the page header's Open Guild button (openLabel, the shared
-- header hook in Config/Window.lua) opens the window; everything else lives
-- there.
---------------------------------------------------------------------------
function M:CreateConfigPage(parent)
    local page=W.Page(parent,320);self.page=page

    local controls=page:Row("",48)
    table.remove(page.searchEntries) -- an empty label would be a blank search result
    local row=controls.row
    controls.rowLabel:Hide();row.divider:Hide()
    controls:ClearAllPoints();controls:SetAllPoints(row)
    local note=W.Label(controls,M.PAGE_NOTE,nil,0,-6,520,T.muted);note:SetWordWrap(true)
    function row:layoutChildren(width) note:SetWidth(width) end
    page.note=note
    -- The old module names find this page first, as "Guild > Open Guild". The
    -- result scrolls to the top and outlines the page header's Open Guild button.
    page.searchEntries[#page.searchEntries+1]={label="Open Guild",row=row,kind="setting",
        flash=function() return addon.configWindow and addon.configWindow.moduleHeader.openButton end,
        keywords={"roster","guild roster","recruitment","guild recruitment","recruiter","recruiter window"}}
    page:Finish()
    return page
end
