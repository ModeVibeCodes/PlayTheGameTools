"""Global inheritance, real dropdowns, persistence, unavailable media and isolation.

Mocks do not establish native font rendering, secure actions, or combat support.
"""
from smoke import load

SETUP = r'''
lsm={data={font={Alpha='Alpha.ttf',Beta='Beta.ttf'},border={Edge='Edge.tga'},
    statusbar={Satin='Satin.tga'},background={Stone='Stone.tga'},sound={}}}
function lsm:HashTable(kind) return self.data[kind] end
function lsm:List(kind) local t={} for k in pairs(self.data[kind]) do t[#t+1]=k end table.sort(t);return t end
function lsm:Fetch(kind,name) return self.data[kind][name] end
function lsm:GetGlobal() return nil end
function lsm:SetGlobal() error('Never change another addon media') end
LibStub=function(name) assert(name=='LibSharedMedia-3.0');return lsm end
'''

lua, _ = load(before=SETUP)
lua.execute(r'''
local M=addon.Media
local originalGame=GameFontHighlight:GetFont()
addon:ToggleConfig();addon:SelectConfigPage('globalSettings')
local w=addon.configWindow;local p=w.pages.globalSettings
assert(w.moduleHeader.title:GetText()=='Global Settings' and not w.moduleHeader.toggle:IsShown())
assert(not addon.modules.globalSettings and w.navigationButtons.globalSettings)
local function Choose(key,id)
    local b=p.mediaControls[key];b.scripts.OnClick();assert(b.menu:IsShown())
    for _,row in ipairs(b.rows) do
        if row.choice and row.choice.id==id then row.scripts.OnClick();return end
    end
    error('Missing media choice: '..id)
end
Choose('global:font','media:Alpha');Choose('global:texture','media:Satin');Choose('global:border','media:Edge')
assert(addon.ReloadManager.requests.globalMedia)
assert(M:GetInterfaceFont()=='Alpha.ttf' and M:GetDisplayFont({font='game',fontMedia=''})=='Alpha.ttf')
assert(M:GetDisplayFont({font='chat',fontMedia=''})==ChatFontNormal:GetFont(),'existing custom chat font retained')
assert(M:GetDisplayFont({font='game',fontMedia='Beta'})=='Beta.ttf','custom media retained')
assert(M:GetStatusBar('default')=='Satin.tga' and M:GetStatusBar('flat')==M.defaultStatusBar)
Choose('combatTimer:font','chat');Choose('combatTimer:texture','background:Stone');Choose('combatTimer:border','none')
addon:SetModuleEnabled('combatTimer',true)
local timer=addon.modules.combatTimer
timer:ApplyAppearance()
assert(M:GetDisplayFont(timer.db.appearance)==ChatFontNormal:GetFont(),'module font override')
assert(timer.background.texture=='Stone.tga','module background override')
assert(timer.globalBorder.borderKind=='none' and not timer.globalBorder.iconBorder:IsShown())
Choose('combatTimer:font','inherit');Choose('combatTimer:texture','inherit');Choose('combatTimer:border','inherit')
timer:ApplyAppearance()
assert(timer.text.font[1]=='Alpha.ttf' and timer.background.texture=='Satin.tga')
assert(timer.globalBorder.borderKind=='shared' and timer.globalBorder.borderFrame:IsShown())
-- Global None removes the actual owned panel edge in both UI themes/modules.
Choose('global:border','none')
local f=CreateFrame('Frame',nil,UIParent,'BackdropTemplate')
M:ApplyBackdrop(f,{bgFile=M.defaultStatusBar,edgeFile='NativeEdge',edgeSize=1},'foreverQuickAccess')
assert(f.backdrop.edgeFile==nil and f.backdrop.bgFile=='Satin.tga')
Choose('foreverQuickAccess:border','thin')
M:ApplyBackdrop(f,{edgeFile='NativeEdge',edgeSize=1},'foreverQuickAccess')
assert(f.backdrop.edgeFile==M.defaultStatusBar,'independent override restores border')
Choose('foreverQuickAccess:border','media:Edge')
M:ApplyBackdrop(f,{edgeFile='NativeEdge',edgeSize=3},'foreverQuickAccess')
assert(f.backdrop.edgeFile=='Edge.tga' and f.backdrop.edgeSize==3,'custom thickness stays adjustable')
Choose('foreverQuickAccess:border','thin')
Choose('foreverAutomation:font','chat')
-- Existing local font selector explicitly chooses Game, then returns to inherit.
addon:SelectConfigPage('combatTimer')
local font
for _,entry in ipairs(addon.configWindow.pages.combatTimer.searchEntries) do
    if entry.label=='Font' then font=entry.row end
end
local owner={db=timer.db,CanConfigure=function() return true end,
    GetFonts=function() return M:GetFonts() end,
    SetAppearance=function(_,key,value) return timer:SetAppearance(key,value) end}
local b=addon.ConfigWidgets.FontDropdown(CreateFrame('Frame',nil,UIParent),owner)
b.scripts.OnClick()
for _,row in ipairs(b.rows) do if row.choice.key=='game' then row.scripts.OnClick();break end end
assert(M:GetDisplayFont(timer.db.appearance)==originalGame and timer.db.appearance.fontMedia=='builtin:game')
b.scripts.OnClick()
for _,row in ipairs(b.rows) do if row.choice.key=='global' then row.scripts.OnClick();break end end
assert(M:GetDisplayFont(timer.db.appearance)=='Alpha.ttf')
assert(GameFontHighlight:GetFont()==originalGame,'Blizzard FontObject untouched')
testCombat=true
local old=addon.db.globalMedia.font
assert(not M:SetGlobalStyle('font','media:Beta') and addon.db.globalMedia.font==old)
testCombat=false;testLockdown=true
assert(not M:SetGlobalStyle('border','thin'))
testLockdown=false
assert(not M:SetGlobalStyle('font','media:NotRegistered'))
''')
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(state, before=SETUP)
restored.execute(r'''
assert(addon.db.globalMedia.font=='media:Alpha' and addon.db.globalMedia.texture=='media:Satin')
assert(addon.db.globalMedia.overrides.foreverQuickAccess.border=='thin')
assert(addon.Media:GetDisplayFont(addon.modules.combatTimer.db.appearance)=='Alpha.ttf')
addon:ToggleConfig();addon:SelectConfigPage('foreverAutomation')
local found=0
for region,spec in pairs(addon.Media.regions) do
    if spec.scope=='foreverAutomation' then
        found=found+1;assert(region.font[1]==ChatFontNormal:GetFont(),'module page text inherits its override')
    end
end
assert(found>0)
''')
missing, _ = load(state)
missing.execute(r'''
assert(addon.db.globalMedia.font=='media:Alpha','unavailable saved selection retained')
assert(addon.Media:GetDisplayFont({font='game',fontMedia=''})==GameFontHighlight:GetFont())
assert(addon.Media:GetSurfaceTexture()==addon.Media.defaultStatusBar)
addon:ToggleConfig();addon:SelectConfigPage('globalSettings')
assert(addon.configWindow.pages.globalSettings.mediaControls['global:font'].label:GetText():find('unavailable'))
''')
print('PASS global media UI, inheritance, overrides, roundtrip, combat guards and unavailable-media fallback')
