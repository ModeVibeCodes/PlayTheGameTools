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
mode.execute(r'''
    local T=addon.InterfaceTheme
    assert(T.id=='mode' and not T.blizzardArt)
    assert(T.background[1]==43/255 and T.background[1]==T.background[2] and T.background[2]==T.background[3])
    assert(T.text[1]==212/255 and T.secondary[1]==179/255 and T.primary[1]==0 and T.primary[2]==240/255 and T.primary[3]==1)
    assert(addon.Theme.primary[1]==128/255 and addon.Theme.primary[2]==239/255,'gameplay palette retained')
    local before=addon.ProfileCodec.Encode(PTGToolsDB)
    addon:ToggleConfig()
    local w=addon.configWindow
    assert(w.title:GetText()=='PTG Tools' and w.sidebarWidth==240)
    assert(w.title.color[1]==0 and w.title.color[2]==240/255 and w.title.color[3]==1,'cyan branding')
    assert(w.brandLogo and not w.headerArt:IsShown() and not w.columnEdge:IsShown())
    assert(w.brandLogo.points[1][5]==0,'logo centers inside the header without overlapping navigation')
    assert(w.canvasSheen.gradient.minimum.a==0.018 and w.bodySheen.gradient.maximum.a==0,'static neutral background sheen')
    assert(w.profileButton.label:GetText()=='Profile:' and w.profileButton.profileName:GetText()==addon.ProfileManager.activeName)
    assert(w.profileButton.profileName.color[2]==T.primary[2] and w.profileButton.label.color[1]==T.secondary[1])
    assert(w.closeButton.points[1][1]=='RIGHT' and w.closeButton.points[1][2]==w.headerControls,'close is rightmost')
    assert(w.profileButton.points[1][2]==w.closeButton and w.editButton.points[1][2]==w.profileButton,'profile is immediately left of close')
    assert(T.muted[1]<T.secondary[1] and T.secondary[1]<T.text[1],'descriptor hierarchy')
    assert(w.searchInput:GetParent()==w.headerBar and w.searchInput:GetWidth()==200,'header search')
    assert(w.searchInput.points[1][1]=='TOPLEFT' and w.searchInput.points[1][2]==w and w.searchInput.points[1][4]==w.contentLeft,'search aligns with module title')
    assert(w.headerReserved>=w:GetWidth()-w.contentLeft+16,'left search preserves off-screen drag recovery')
    assert(w.canvas.modeAsset=='ModeSurface' and not w.bodyBorder and not w.border.shown,'page perimeter borders removed')
    local profile=w.profileButton
    local group=profile.label:GetWidth()+8+profile.profileName:GetWidth()
    assert(math.abs(profile.label.points[1][4]-(profile:GetWidth()-group)/2)<.001,'profile label and name centered together')
    assert(profile:GetWidth()>=132 and profile:GetWidth()<=196,'profile button proportions bounded')
    for _,name in ipairs({'Mode',string.rep('LongProfile',8)}) do
        profile.profileName:SetText(name);profile:LayoutProfileText()
        local span=profile.label:GetWidth()+8+profile.profileName:GetWidth()
        assert(math.abs(profile.label.points[1][4]-(profile:GetWidth()-span)/2)<.001 and profile:GetWidth()<=196,'short/long profile text balances within header')
    end
    profile.profileName:SetText(addon.ProfileManager.activeName);profile:LayoutProfileText()
    assert(w.title.font[1]:find('Lato%-Bold.ttf') and w.navigationButtons.dashboard.label.font[1]:find('Lato%-Regular.ttf'))
    w.profileButton.scripts.OnClick()
    assert(w.selectedPage=='globalSettings' and w.pages.globalSettings.selectedSection.title=='Profiles','existing profile page shortcut')
    addon:SelectConfigPage('dashboard')
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
                assert(button.label.font[2]<=T.fontSize.body and not button.label.wordWrap)
                assert(button.label:GetStringWidth()<=button:GetWidth()-(addon.modules[id].classIcon and 48 or 26),'single-line child fits '..id)
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
    local resting=b.fill.vertexColor[4]
    b.scripts.OnEnter(b);assert(not b.activeGlow:IsShown() and b.label.shadowColor[4]>0 and b.fill.vertexColor[4]==resting,'text-only hover')
    b:SetEnabled(false);assert(not b.activeGlow:IsShown() and b.label.shadowColor[4]==0)
    b:SetEnabled(true);b.scripts.OnLeave(b)
    assert(not b.activeGlow:IsShown() and b.selectionEdge:IsShown() and b.selectionEdge.modeAsset=='ModeSelection','selected line survives mouse leave')
    assert(b.selectionEdge.points[1][1]=='TOPLEFT' and b.selectionEdge.points[1][2]==b.label,'underline follows text left edge')
    assert(b.selectionEdge:GetWidth()<=b.label:GetStringWidth(),'underline has text width rather than row width')
    local oldWidth=b:GetWidth();b:SetWidth(100);b.scripts.OnSizeChanged(b)
    assert(b.selectionEdge:GetWidth()<=80,'line follows resized text area')
    b:SetWidth(oldWidth);b.scripts.OnSizeChanged(b)
    local oldText=b.label:GetText();b.label:SetText('· Enhanced Experience Bar')
    b:SetWidth(164);b:FitNavigationText()
    assert(not b.label.wordWrap and b.label:GetStringWidth()<=138,'long subcategory fits one line at constrained width')
    b.label:SetText(oldText);b:SetWidth(oldWidth);b:FitNavigationText()
    local page=w.pages.combatTimer
    assert(page.contentInset==12)
    for _,row in ipairs(page.rows) do if row:IsShown() then assert(row.points[1][4]==12,'visible page rows clear left borders') end end
    assert(page.scrollbar.thumbTexture:GetWidth()==2,'thin thumb preserves scrollbar target')
    local check=addon.ConfigWidgets.Button(UIParent,'',18,18,'checkbox')
    assert(check.fill.modeAsset=='ModeCheckSurface' and check.switchOutline.rounded)
    local button=addon.ConfigWidgets.Button(UIParent,'Refresh',100,28)
    assert(button.fill.modeAsset=='ModeControlSurface' and button.outline.rounded)
    assert(button.fill.points[1][4]==1 and button.fill.points[1][5]==-1,'button background stays within border')
    local toggle=w.moduleHeader.toggle
    assert(toggle.switchOutline.rounded and toggle.fill.modeAsset=='ModeToggleSurface' and toggle.knob.modeAsset=='ModeThumb','rounded track and circular thumb')
    assert(not toggle.fill.slice and not toggle.switchOutline.edges[1].slice,'small controls use full oval sprites')
    assert(toggle.fill:GetWidth()==30 and toggle.fill:GetHeight()==14,'enabled toggle fill stays two units inside its border')
    assert(check.fill:GetWidth()==14 and check.fill:GetHeight()==14,'checkbox fill stays inside its border')
    for _,control in ipairs({check,toggle}) do
        local rim=control.switchOutline.edges[1]
        assert(rim.modeAsset==control.fill.modeAsset,'outer silhouette and interior share the same rounded artwork')
        assert(rim:GetParent()==control.fill:GetParent() and rim:GetParent()==control.knob:GetParent(),'all switch regions share one coordinate space')
        assert(rim.layer=='BACKGROUND' and control.fill.layer=='ARTWORK' and control.knob.layer=='OVERLAY','solid backing remains beneath the inset fill and thumb')
        local width,height=control.fill:GetWidth(),control.fill:GetHeight()
        for _,selected in ipairs({false,true,false,true}) do
            control:SetSelected(selected)
            assert(control.fill:GetWidth()==width and control.fill:GetHeight()==height,'state recolors the same inset region')
            assert(control.fill.appliedModeAsset==rim.appliedModeAsset,'state never replaces the interior silhouette')
            if selected then assert(control.fill.vertexColor[4]==1 and rim.vertexColor[1]~=control.fill.vertexColor[1],'checked fill stays opaque inside a distinct rim') end
        end
        control:SetSelected(false)
    end
    local value=27
    local row=CreateFrame('Frame',nil,UIParent)
    addon.ConfigWidgets.Slider(row,0,100,1,function() return value end,function(v) value=v end,'',true)
    assert(row.slider.thumbTexture.modeAsset=='ModeSliderThumb' and row.slider.thumbTexture:GetWidth()==10 and row.slider.thumbTexture:GetHeight()==20,'rounded slider thumb retains size')
    assert(row.numericInput.justifyH=='CENTER','numeric value centered')
    row.numericInput:SetText('42');row.numericInput.scripts.OnEnterPressed()
    assert(value==42,'numeric editing callback retained')
    assert(not check.fill.slice and not check.knob.slice,'checkbox full-sprite round corners')
    testMissingTextures={[addon.Media:GetTexture('ModeCheckSurface')]=true}
    local pendingCheck=addon.ConfigWidgets.Button(UIParent,'',18,18,'checkbox')
    assert(pendingCheck.fill.texture==addon.Media:GetTexture('ModeThumb'),'unavailable new art falls back to a circle, never a solid square')
    testMissingTextures=nil
    local oldBorder=addon.db.globalMedia.border;addon.db.globalMedia.border='media:PTG Clean'
    local customCheck=addon.ConfigWidgets.Button(UIParent,'',18,18,'checkbox')
    assert(customCheck.switchOutline.rounded,'global border must not replace the checkbox silhouette with a rectangle')
    addon.db.globalMedia.border=oldBorder
    toggle:SetSelected(true);assert(not toggle.activeGlow:IsShown())
    toggle:SetEnabled(false);assert(not toggle.activeGlow:IsShown())
    toggle:SetEnabled(true);toggle:SetSelected(false)
    toggle.scripts.OnEnter(toggle);assert(not toggle.activeGlow:IsShown() and toggle.label.shadowColor[4]>0)
    toggle.scripts.OnLeave(toggle);assert(not toggle.activeGlow:IsShown())
    addon:SelectConfigPage('dashboard');assert(not b.activeGlow:IsShown())
    assert(addon.ProfileCodec.Encode(PTGToolsDB)==before,'navigation preserves all saved preferences')
    local media=addon.Media
    local original=addon.db.globalMedia.font
    addon.db.globalMedia.font='media:PTG JetBrains Mono';media:RefreshFonts()
    assert(w.title.font[1]:find('JetBrainsMono%-Regular.ttf'),'explicit font customization retained')
    addon.db.globalMedia.font=original;media:RefreshFonts()
    assert(w.title.font[1]:find('Lato%-Bold.ttf'))
    local t=CreateFrame('Frame',nil,UIParent):CreateTexture(nil,'BACKGROUND')
    t.modeAsset='ModeSurface';testMissingTextures={[media:GetTexture('ModeSurface')]=true}
    addon.ConfigWidgets.Paint(t,T.background)
    assert(t.color[1]==43/255 and t.color[4]==1,'missing art retains a readable solid fallback')
    t=CreateFrame('Frame',nil,UIParent):CreateTexture(nil,'BACKGROUND')
    t.modeAsset='ModeBorder';testMissingTextures={[media:GetTexture('ModeBorder')]=true}
    addon.ConfigWidgets.Paint(t,T.lineStrong);assert(t.color[4]==0,'missing border never covers its controls')
    testMissingTextures=nil
    testMissingFonts={
        [ [[Interface\AddOns\PlayTheGameTools\Media\Fonts\Lato-Regular.ttf]] ]=true,
        [ [[Interface\AddOns\PlayTheGameTools\Media\Fonts\Lato-Bold.ttf]] ]=true,
    }
    media:RefreshFonts();assert(not w.title.font[1]:find('Lato%-'),'undiscovered font keeps native fallback')
    testMissingFonts=nil;media:RefreshFonts()
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
print('PASS mode palette/materials/font, text-only hover, profile/header search, all pages, collapse/reload, persistence and existing themes')
