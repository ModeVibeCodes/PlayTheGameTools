"""One open window at a time and topmost-first Escape (mock only, not WoW)."""
from smoke import load

lua, addon = load()
lua.execute(r'''
local D=addon.Dialogs
local escape=D.escapeFrame
local function Escape()
    -- Blizzard's CloseSpecialWindows hides each listed frame that is shown.
    assert(escape:IsShown(),'Escape is claimed while a dialog is open')
    escape:Hide();D:Sync()
end
local function Count(list,name) local n=0;for _,v in ipairs(list) do if v==name then n=n+1 end end;return n end
assert(Count(UISpecialFrames,'PlayTheGameToolsEscapeHandler')==1,'one stand-in in the native Escape list')
assert(Count(UISpecialFrames,'PlayTheGameToolsRecruitmentFrame')==0 and Count(UISpecialFrames,'PlayTheGameToolsRecruitmentCopyFrame')==0)
assert(not escape:IsShown(),'nothing open: Escape reaches the game menu')

-- Settings and its own preview pop-out share a group and stay open together.
addon:ToggleConfig()
local config=addon.configWindow
assert(config:IsShown() and escape:IsShown())
local module=addon.modules.combatTimer
assert(addon:ShowModulePreview(module))
local popout=addon.previewPopout
assert(popout:IsShown() and config:IsShown(),'preview pop-out stays with settings')

-- Escape closes the most recent first, then settings, then releases Escape.
Escape();assert(not popout:IsShown() and config:IsShown(),'Escape closes the pop-out first')
Escape();assert(not config:IsShown(),'Escape then closes settings')
assert(not escape:IsShown(),'Escape is released once everything is closed')

-- Opening the recruiter closes settings, and the reverse.
local R=addon.ForeverRecruitment
addon:ToggleConfig();assert(config:IsShown())
R:OpenWindow();local recruiter=R.window
assert(recruiter:IsShown() and not config:IsShown(),'recruiter replaces settings')
assert(recruiter.points[#recruiter.points][1]=='CENTER','recruiter centers instead of docking to closed settings')
R:ShowCopyBox('Fixture');local copy=R.copyFrame
assert(copy:IsShown() and recruiter:IsShown(),'copy box stays with its recruiter')
Escape();assert(not copy:IsShown() and recruiter:IsShown())
addon:ToggleConfig();assert(config:IsShown() and not recruiter:IsShown(),'settings replaces recruiter')

-- Edit Mode replaces settings; leaving it returns to settings and nothing else.
R:OpenWindow();assert(not config:IsShown())
addon:ToggleConfig();assert(config:IsShown() and not recruiter:IsShown())
assert(addon:SetEditMode(true))
local edit=addon.editWindow
assert(edit:IsShown() and not config:IsShown())
R:OpenWindow()
assert(recruiter:IsShown() and not edit:IsShown() and not addon.editMode,'opening a window leaves Edit Mode')
assert(not config:IsShown(),'Edit Mode returning to settings does not stack it over the recruiter')
Escape();assert(not recruiter:IsShown() and not escape:IsShown())

-- An automatic reload prompt never closes anything; a window opened later does.
addon:ToggleConfig()
addon.ReloadManager.prompt=nil
local pending=addon.ReloadManager.IsPending
addon.ReloadManager.IsPending=function() return true end
addon:ShowReloadPrompt();local prompt=addon.ReloadManager.prompt
assert(prompt:IsShown() and config:IsShown(),'notices do not close windows')
Escape();assert(not prompt:IsShown() and config:IsShown(),'Escape answers the prompt first')
-- Closing settings with a reload pending still asks, even when another window replaced it.
R:OpenWindow();assert(recruiter:IsShown() and not config:IsShown())
assert(prompt:IsShown(),'settings closing re-asks for the pending reload')
Escape();assert(not prompt:IsShown() and recruiter:IsShown())
addon.ReloadManager.IsPending=pending
local notice=CreateFrame('Frame',nil,UIParent);notice:Hide();D:Register(notice,{kind='notice'})
notice:Show();assert(notice:IsShown() and recruiter:IsShown())
addon:ToggleConfig();assert(config:IsShown() and not notice:IsShown() and not recruiter:IsShown(),'a new window closes older notices')
config:Hide();prompt:Hide();D:Sync()

-- Dropdown menus are layers: Escape closes them before their window.
addon:ToggleConfig()
local owner=CreateFrame('Button',nil,config)
local popup=addon.ConfigWidgets.Popup(owner,100,100)
popup:Show();assert(config:IsShown(),'a menu does not close its window')
Escape();assert(not popup:IsShown() and config:IsShown())
Escape();assert(not config:IsShown() and not escape:IsShown())

-- The level-up popup preview sits beside settings; Escape closes it first.
local M=addon.ForeverClassTraining
addon:SetModuleEnabled(M.id,true)
addon:ToggleConfig();assert(M:PreviewDing())
assert(M.dingWindow:IsShown() and config:IsShown(),'popup preview stays with settings')
Escape();assert(not M.dingWindow:IsShown() and config:IsShown())
config:Hide();D:Sync()

-- A window that closes itself releases Escape on the next frame.
addon:ToggleConfig();config:Hide();D:Sync()
assert(not escape:IsShown() and not D.watcher:IsShown())
print('PASS dialogs: one window at a time, grouped companions, notices, menus and topmost-first Escape')
''')
print(lua.globals().messages[len(lua.globals().messages)])
