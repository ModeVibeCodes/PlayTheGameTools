"""v2 settings window shell: size, header, reload banner, A-Z sidebar, page header,
search and /ptg dev (mock only, not native WoW)."""
from smoke import load

# No shipped module is class-only since Rogue Tools retired; a stand-in keeps
# the class filter, class icon and long-description wrap covered.
CLASS_TOOL = r'''
addon:RegisterModule('testClassTool',{title='Rogue Test Tools',category='qualityOfLife',defaultEnabled=false,
 classIcon='Interface\\Icons\\ClassIcon_Rogue',searchAliases={'poison'},
 configDescription='A class-only stand-in module whose description is long enough to need a second line in the page header of the settings window.'})
'''

lua, _ = load(before=CLASS_TOOL)
lua.execute(r'''
local function Click(button) button:GetScript('OnClick')(button) end
local function Encode() return addon.ProfileCodec.Encode(PTGToolsDB) end
SlashCmdList.PLAYTHEGAMETOOLS()
local w=addon.configWindow
assert(w:IsShown())

-- Window: 960x640, fitted to small screens, position recovery intact.
assert(w:GetWidth()==960 and w:GetHeight()==640 and w.sidebarWidth==232)
assert(w.scale==1,'fits a 1280x800 screen unscaled')
UIParent.width,UIParent.height=800,560
addon:UpdateWindowBounds()
assert(math.abs(w.scale-math.min((800-32)/960,(560-32)/640))<1e-9 and w:GetWidth()==960,'scales down to fit, never resizes')
UIParent.width,UIParent.height=1280,800
addon:UpdateWindowBounds();assert(w.scale==1)
addon.db.window.x,addon.db.window.y=-100000,100000
assert(addon:RecoverWindowPosition())
assert(addon.db.window.x>-100000 and addon.db.window.y<100000,'an off-screen position is pulled back')
assert(addon:ResetConfigWindowPosition() and addon.db.window.x==0 and addon.db.window.y==0)

-- Header: brand on the left, exactly Layout and Close on the right.
assert(w.title:GetText()=='Play The Game Tools' and w.brandLogo)
assert(w.headerBar:GetHeight()==48)
assert(w.previewButton==nil and w.reloadButton==nil and w.profileButton==nil,'Preview, Reload and Profile header buttons removed')
assert(w.layoutButton.label:GetText()=='Layout' and w.closeButton.label:GetText()=='X')
assert(w.closeButton.points[1][1]=='RIGHT' and w.closeButton.points[1][2]==w.headerControls,'Close is rightmost')
assert(w.layoutButton.points[1][2]==w.closeButton,'Layout sits left of Close')
assert(w.editButton==w.layoutButton,'one Layout control')
-- The drag strip runs from the brand to the controls and stays recoverable.
local drag=w.header
assert(drag.points[1][1]=='TOPLEFT' and drag.points[2][1]=='BOTTOMRIGHT' and drag.points[2][2]==w.headerControls and drag.points[2][3]=='BOTTOMLEFT')
assert(w.headerReserved>=w.headerControls:GetWidth() and w.headerReserved<w:GetWidth()/2,'only the controls are reserved')
drag.scripts.OnDragStart();assert(w.moving,'dragging starts');drag.scripts.OnDragStop();assert(not w.moving)
testCombat=true;drag.scripts.OnDragStart();assert(not w.moving,'no dragging in combat');testCombat=false

-- Sidebar: search first, then one flat A-Z list with on/off dots; no
-- Dashboard, no category headings, no Developer Mode; Settings pinned below.
local listed=addon:ListedConfigPages()
assert(#listed==#addon.moduleOrder-1,'every gameplay module except Developer Mode')
local titles={}
for i,row in ipairs(w.navigation.rows) do
    assert(row==w.navigationButtons[listed[i]] and row==w.sidebarModuleButtons[listed[i]])
    assert(row.skinStyle=='tab' and row.stateDot and row.listed)
    titles[i]=row.label:GetText()
    assert(titles[i]==addon.modules[listed[i]].title)
    if i>1 then assert(titles[i-1]:lower()<titles[i]:lower(),'A to Z: '..titles[i-1]..' / '..titles[i]) end
end
assert(#w.navigation.rows==#listed)
for _,cid in ipairs(addon.categoryOrder) do assert(w.navigationButtons[cid]==nil,'no category heading '..cid) end
assert(#addon.categoryOrder==4 and addon.categories.timers.modules[1]=='combatTimer','category data kept for other code')
assert(w.navigationButtons.foundation==nil and w.navigationButtons.dashboard==nil)
assert(w.navigationButtons.globalSettings==w.settingsButton and w.settingsButton.label:GetText()=='Settings')
assert(w.settingsButton.points[1][1]=='BOTTOMLEFT' and w.settingsButton:GetParent()==w.sidebar,'Settings pinned at the bottom')
for _,row in ipairs(w.navigation.rows) do assert(row~=w.settingsButton) end
assert(w.searchInput:GetParent()==w.sidebar and w.searchInput.points[1][1]=='TOPLEFT','search heads the sidebar')
-- Dots follow the module switch.
local timerRow=w.navigationButtons.combatTimer
addon:SetModuleEnabled('combatTimer',false)
assert(not timerRow.moduleOn and timerRow.stateDot.vertexColor[1]==addon.InterfaceTheme.lineStrong[1])
addon:SetModuleEnabled('combatTimer',true)
assert(timerRow.moduleOn)
assert(timerRow.stateDot.vertexColor[2]==addon.InterfaceTheme.primary[2],'on dot uses the accent')
-- Clicking a row opens its page.
Click(w.navigationButtons.threatMeter)
assert(w.selectedPage=='threatMeter' and w.pages.threatMeter:IsShown() and w.navigationButtons.threatMeter.selected)
assert(not timerRow.selected)

-- Page header: title, description and one switch; nothing echoes it.
local h=w.moduleHeader
assert(h.state==nil,'no Enabled/Disabled label')
assert(h.title:GetText()=='Threat Meter' and h.description:GetText()==addon.modules.threatMeter.configDescription)
assert(h.toggle:IsShown() and h.toggle.selected==addon.modules.threatMeter.enabled)
local was=addon.modules.threatMeter.enabled
Click(h.toggle);assert(addon.modules.threatMeter.enabled==not was and h.toggle.selected==not was)
Click(h.toggle);assert(addon.modules.threatMeter.enabled==was)
for _,id in ipairs(addon.moduleOrder) do
    addon:SelectConfigPage(id)
    assert(h.title:IsShown() and h.title:GetText()==addon.modules[id].title,id)
    for _,region in ipairs({h.title,h.description,h.toggle.label}) do
        local text=region:GetText() or ''
        assert(text~='Enabled' and text~='Disabled',id..' echoes the switch')
    end
end
addon:SelectConfigPage('testClassTool')
assert(h.title:IsShown() and h.title:GetText()=='Rogue Test Tools','class tools show their title')
local W=addon.ConfigWidgets
assert(h.description:GetText()==addon.modules.testClassTool.configDescription and h.description.wordWrap and h.description.justifyV=='TOP','long descriptions wrap')
assert(h.description.height==W.PAGE_DESCRIPTION_HEIGHT and h:GetHeight()==W.PAGE_HEADER_HEIGHT and 30+W.PAGE_DESCRIPTION_HEIGHT<=W.PAGE_HEADER_HEIGHT-12,'two description lines clear the divider')
assert(w.navigationButtons.testClassTool.classIcon.texture==addon.modules.testClassTool.classIcon,'class icon in the sidebar row')
Click(w.settingsButton)
assert(w.selectedPage=='globalSettings' and h.title:GetText()=='Settings')
assert(h.description:GetText()=='Look, game options and profiles for the whole addon.')
assert(not h.toggle:IsShown(),'Settings has no switch')
assert(w.settingsButton.selected)

-- Last page used this session; the window reopens on it.
local before=Encode()
for _,id in ipairs(listed) do Click(w.navigationButtons[id]) end
Click(w.settingsButton)
addon:SelectConfigPage('dungeonLoot');w:Hide();w:Show()
assert(w.selectedPage=='dungeonLoot' and w.pages.dungeonLoot:IsShown())
assert(Encode()==before,'navigation writes no saved settings')

-- Reload banner: hidden until ReloadManager has a request.
local banner,R=w.reloadBanner,addon.ReloadManager
assert(not banner:IsShown() and not R:IsPending())
local host=w.pages.dungeonLoot:GetParent()
local function HostTop() return host.points[#host.points-1][5] end
local resting=HostTop()
addon:SelectConfigPage('globalSettings')
w.pages.globalSettings.themeButtons[1].scripts.OnClick()
assert(R:IsPending() and banner:IsShown(),'theme change shows the banner')
assert(banner.message:GetText()=='Applies after a reload' and banner.reason:GetText()==R:GetReason())
assert(banner.reason:GetText():find('Modern',1,true),banner.reason:GetText())
assert(HostTop()<resting,'page moves below the banner')
assert(banner.reloadButton.label:GetText()=='Reload now')
reloads=0;C_UI.Reload=function() reloads=reloads+1 end
testCombat=true;Click(banner.reloadButton)
assert(reloads==0 and banner.reason:GetText():find('combat',1,true),'combat reload stays blocked and says why')
testCombat=false;Click(banner.reloadButton);assert(reloads==1,'Reload now reloads')
addon:SelectConfigPage('combatTimer');assert(banner:IsShown(),'banner shows on every page')
w.pages.globalSettings.themeButtons[2].scripts.OnClick()
assert(not R:IsPending() and not banner:IsShown() and HostTop()==resting,'banner leaves when nothing is pending')
R:Request('fixture','Apply fixture.');assert(banner:IsShown() and banner.reason:GetText()=='Apply fixture.')
R:Clear('fixture');assert(not banner:IsShown())

-- Layout enters the existing Edit Mode on the current module's first display.
addon:SetModuleEnabled('combatTimer',true)
addon:SelectConfigPage('combatTimer')
Click(w.layoutButton)
assert(addon.editMode and addon.EditMode:Selected().module.id=='combatTimer',"starts on this page's display")
assert(not w:IsShown(),'settings steps aside for Layout')
addon:SetEditMode(false)
assert(not addon.editMode and w:IsShown() and w.selectedPage=='combatTimer','returns to the same page')

-- Search finds modules and settings, opens the page and flashes the row.
local input=w.searchInput
local results=addon:SearchSettings('threat meter')
assert(results[1].kind=='module' and results[1].module.id=='threatMeter' and results[1].title=='Threat Meter')
assert(not results[1].label:find('Quality of Life',1,true),'no category names in results')
local font=addon:SearchSettings('fast loot')
assert(font[1] and font[1].module.id=='globalSettings' and font[1].entry and font[1].context:find('^Settings') and font[1].title=='Fast loot','Settings page is searchable')
input:SetFocus();input:SetText('fast loot')
assert(w.searchResults:IsShown() and not w.navigation:IsShown(),'results replace the list while typing')
local first=input.buttons[1]
assert(first:IsShown() and first.label:GetText()==font[1].title and first.context:GetText()==font[1].context)
local row=font[1].entry.row
Click(first)
assert(w.selectedPage=='globalSettings' and row.searchHighlight,'jumps to the setting and flashes it')
assert(input:GetText()=='' and w.navigation:IsShown() and not w.searchResults:IsShown(),'list returns after a jump')
input:SetText('threat meter');input.scripts.OnEnterPressed(input)
assert(w.selectedPage=='threatMeter' and input:GetText()=='','Enter opens the first result')
input:SetText('zzzz-no-match')
assert(input.empty:IsShown() and input.empty:GetText():find('Nothing matches',1,true) and not input.buttons[1]:IsShown())
input.scripts.OnEscapePressed(input)
assert(input:GetText()=='' and w.navigation:IsShown(),'Escape clears the search')
for _,result in ipairs(addon:SearchSettings('developer mode')) do assert(result.module.id~='foundation','Developer Mode is not searchable') end

-- /ptg dev opens Developer Mode; /ptg still toggles; edit mode exits first.
w:Hide()
SlashCmdList.PLAYTHEGAMETOOLS('dev')
assert(w:IsShown() and w.selectedPage=='foundation' and h.title:GetText()=='Developer Mode' and not h.toggle:IsShown())
SlashCmdList.PLAYTHEGAMETOOLS(' DEV ');assert(w:IsShown() and w.selectedPage=='foundation')
SlashCmdList.PLAYTHEGAMETOOLS();assert(not w:IsShown())
assert(addon:SetEditMode(true))
SlashCmdList.PLAYTHEGAMETOOLS('dev')
assert(not addon.editMode and w:IsShown() and w.selectedPage=='foundation')
SlashCmdList.PLAYTHEGAMETOOLS('resetwindow');assert(w:IsShown() and addon.db.window.x==0)
''')

# A class-only module is listed, and searchable, only for its class.
warrior, _ = load(before=CLASS_TOOL + "function UnitClass() return 'Warrior','WARRIOR',1 end")
warrior.execute(r'''
SlashCmdList.PLAYTHEGAMETOOLS()
local w=addon.configWindow
assert(not addon:IsConfigPageListed('testClassTool') and w.navigationButtons.testClassTool==nil,'no Rogue row for a Warrior')
for _,row in ipairs(w.navigation.rows) do assert(row.label:GetText()~='Rogue Test Tools') end
for _,result in ipairs(addon:SearchSettings('rogue')) do assert(result.module.id~='testClassTool') end
for _,result in ipairs(addon:SearchSettings('poison')) do assert(result.module.id~='testClassTool') end
assert(#w.navigation.rows==#addon.moduleOrder-2)
''')
secret, _ = load(before=CLASS_TOOL + "function UnitClass() return {secret=true},{secret=true},{secret=true} end")
secret.execute(r'''
assert(addon:IsConfigPageListed('testClassTool'),'an unreadable class keeps the page listed')
''')

# Opening during combat builds the shell; search defers page building.
combat, _ = load()
combat.execute(r'''
testCombat=true
SlashCmdList.PLAYTHEGAMETOOLS()
local w=addon.configWindow
assert(w:IsShown() and w.selectedPage==addon:ListedConfigPages()[1])
for _,id in ipairs(addon.moduleOrder) do if id~=w.selectedPage then assert(w.pages[id]==nil,id) end end
addon:SearchSettings('timer')
assert(addon.searchPending and w.pages.combatTimer==nil,'no page building in combat')
addon:UpdateWindowBounds();assert(w.boundsPending,'bounds wait for the end of combat')
testCombat=false
''')
print('PASS v2 window shell: 960x640 fit/recovery, Layout/Close header, drag, reload banner, A-Z sidebar with dots and pinned Settings, class-only rows, page header, last page, search jump/flash, /ptg dev, combat (mock only)')
