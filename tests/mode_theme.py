"""Opt-in theme navigation, reload and preservation contracts; not native WoW."""
from smoke import load

lua, _ = load()
lua.execute('''
    addon:ToggleConfig();addon:SelectConfigPage('globalSettings')
    local buttons=addon.configWindow.pages.globalSettings.themeButtons
    buttons[3].scripts.OnClick()
    assert(addon.db.window.theme=='mode' and addon.InterfaceTheme.id=='modern')
    assert(addon.ReloadManager.requests.interfaceTheme and buttons[3].selected)
    buttons[1].scripts.OnClick()
    assert(not addon.ReloadManager.requests.interfaceTheme)
    buttons[3].scripts.OnClick()
''')
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
mode, _ = load(state)
mode.execute('''
    local T=addon.InterfaceTheme
    assert(T.id=='mode' and not T.blizzardArt)
    assert(T.heading[3]>T.heading[1] and T.primary[3]>T.primary[1])
    assert(addon.Theme.primary[1]==128/255 and addon.Theme.primary[2]==239/255,'gameplay palette retained')
    local before=addon.ProfileCodec.Encode(PTGToolsDB)
    addon:ToggleConfig()
    local w=addon.configWindow
    assert(not w.categoryNavigation:IsShown(),'no duplicate module strip')
    local function VisibleRows()
        local result={};for _,row in ipairs(w.navigation.rows) do result[row]=true end;return result
    end
    for _,cid in ipairs(addon.categoryOrder) do
        local category=addon.categories[cid]
        if #category.modules>0 then
            local heading=w.navigationButtons[cid]
            assert(heading.expanded and heading.skinStyle=='categoryHeading')
            assert(heading.label.color[1]==T.heading[1] and heading.label.font[2]==T.fontSize.group)
            local rows=VisibleRows()
            for _,id in ipairs(category.modules) do
                local button=w.sidebarModuleButtons[id]
                assert(rows[button] and button:IsShown() and button.label:GetText():sub(1,3)=='· ')
                assert(button.label.font[2]==T.fontSize.body)
            end
            local selected=w.selectedPage
            heading.scripts.OnClick()
            assert(not heading.expanded and w.selectedPage==selected,'collapse does not navigate or toggle a module')
            rows=VisibleRows()
            for _,id in ipairs(category.modules) do assert(not rows[w.sidebarModuleButtons[id]]) end
            heading.scripts.OnClick();assert(heading.expanded)
        end
    end
    for _,id in ipairs(addon.moduleOrder) do
        addon:SelectConfigPage(id)
        assert(w.selectedPage==id and w.pages[id]:IsShown() and not w.categoryNavigation:IsShown(),id)
        assert(w.moduleHeader.title:GetText()==addon.modules[id].title,id)
        if addon.modules[id].category then assert(w.sidebarModuleButtons[id].selected,id) end
    end
    local cid=addon.modules.combatTimer.category
    addon:SelectConfigPage('combatTimer')
    w.navigationButtons[cid].scripts.OnClick()
    assert(w.collapsedCategories[cid] and w.pages.combatTimer:IsShown(),'active page survives collapse')
    w:Hide();w:Show()
    assert(w.collapsedCategories[cid],'reopening the active page preserves collapsed state')
    addon:SelectConfigPage('dashboard')
    w:Hide();w:Show()
    assert(w.collapsedCategories[cid],'unrelated navigation and reopen retain disclosure')
    local results=addon:SearchSettings('Combat Timer')
    assert(#results>0)
    addon:SelectConfigPage(results[1].module.id)
    assert(not w.collapsedCategories[cid] and w.sidebarModuleButtons.combatTimer:IsShown(),'direct/search routing reveals child')
    local b=w.sidebarModuleButtons.combatTimer
    b.scripts.OnEnter(b);assert(b.activeGlow:IsShown() and b.label.shadowColor[4]>0)
    b:SetEnabled(false);assert(not b.activeGlow:IsShown() and b.label.shadowColor[4]==0)
    b:SetEnabled(true);b.scripts.OnLeave(b)
    assert(b.activeGlow:IsShown(),'selected wash survives mouse leave')
    local toggle=w.moduleHeader.toggle
    toggle:SetSelected(true);assert(toggle.activeGlow:IsShown())
    toggle:SetEnabled(false);assert(not toggle.activeGlow:IsShown())
    toggle:SetEnabled(true);toggle:SetSelected(false)
    toggle.scripts.OnEnter(toggle);assert(toggle.activeGlow:IsShown())
    toggle.scripts.OnLeave(toggle);assert(not toggle.activeGlow:IsShown())
    addon:SelectConfigPage('dashboard');assert(not b.activeGlow:IsShown())
    assert(addon.ProfileCodec.Encode(PTGToolsDB)==before,'navigation preserves all saved preferences')
    addon:SelectConfigPage('globalSettings')
    local page=w.pages.globalSettings
    assert(#page.sections==4 and page.themeButtons[3].selected and page.mediaControls['global:font'])
    reloads=0;C_UI.Reload=function() reloads=reloads+1 end
    w.reloadButton.scripts.OnClick();assert(reloads==1)
    testCombat=true;w.reloadButton.scripts.OnClick();assert(reloads==1,'combat reload remains blocked');testCombat=false
    page.themeButtons[2].scripts.OnClick()
''')
# Switching back restores the original navigation, rather than modifying it.
back, _ = load(mode.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
back.execute('''
    addon:ToggleConfig();addon:SelectConfigPage('combatTimer')
    local w=addon.configWindow
    assert(addon.InterfaceTheme.id=='blizzard' and w.categoryNavigation:IsShown())
    assert(w.sidebarModuleButtons.combatTimer.label:GetText()=='Combat Timer')
    addon:SetInterfaceTheme('modern')
''')
modern, _ = load(back.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
modern.execute('''
    addon:ToggleConfig();addon:SelectConfigPage('combatTimer')
    local w=addon.configWindow
    assert(addon.InterfaceTheme.id=='modern' and w.categoryNavigation:IsShown())
    assert(w.navigationButtons.timers.skinStyle=='tab')
    assert(w.sidebarModuleButtons.combatTimer.label.font[2]==addon.InterfaceTheme.fontSize.small)
''')
print('PASS mode theme, all module pages, collapse/search, reload, persistence and existing themes')
