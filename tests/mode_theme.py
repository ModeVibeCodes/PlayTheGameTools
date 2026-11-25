"""Opt-in theme navigation, reload and preservation contracts; not native WoW."""
from smoke import load

lua, _ = load()
lua.execute('''
    addon:ToggleConfig();addon:SelectConfigPage('globalSettings')
    local buttons=addon.configWindow.pages.globalSettings.themeButtons
    buttons[3].scripts.OnClick()
    assert(addon.db.window.theme=='mode' and addon.InterfaceTheme.id=='blizzard')
    assert(addon.ReloadManager.requests.interfaceTheme and buttons[3].selected)
    buttons[2].scripts.OnClick()
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
    addon.db.globalMedia.texture='background:PTG Graphite'
    local before=addon.ProfileCodec.Encode(PTGToolsDB)
    addon:ToggleConfig()
    local w=addon.configWindow
    assert(w.canvas.texture==addon.Media:GetTexture('ModeSurface') and w.bodySurface.texture==addon.Media:GetTexture('ModeSurface'),'custom global texture cannot replace mode materials on reload')
    assert(T.pageBackground[1]==42/255 and T.pageBackground[2]==42/255 and T.pageBackground[3]==42/255,'Mode module-page shade is neutral #2A2A2A')
    assert(w.bodySurface.vertexColor[1]==42/255 and T.sidebar[1]==35/255 and T.panel[1]==48/255,'only the module-page area darkens; sidebar and existing panels retain their shades')
    assert(w.bodyDetail.texture==addon.Media:GetTexture('ModePageDetail') and w.bodyDetail.vertexColor[4]==0.18,'Figma abstract page detail stays faint')
    assert(w.bodyDetail:GetParent()==w.bodySurface:GetParent() and w.bodyDetail.layer=='BACKGROUND' and not w.bodyDetail.slice,'static full-frame detail stays below page controls')
    testMissingTextures={[addon.Media:GetTexture('ModePageDetail')]=true}
    local missing=addon.ConfigWidgets.ModePageDetail(w,-12)
    assert(missing.color[4]==0,'undiscovered detail stays transparent without replacing the base material')
    testMissingTextures=nil
    local popup=addon.ConfigWidgets.Popup(w.layoutButton,180,60)
    local surface=addon.ConfigWidgets.Fill(popup,T.panel)
    assert(surface.texture==addon.Media:GetTexture('ModeSurface'),'detached configuration popups keep mode material')
    local display=CreateFrame('Frame',nil,UIParent):CreateTexture(nil,'BACKGROUND')
    addon.Media:PaintSurface(display,T.panel,1,'combatTimer')
    assert(display.texture==addon.Media.defaultStatusBar,'a saved Global Texture is no longer applied to module displays')
    local moduleFrame=CreateFrame('Frame',nil,UIParent)
    addon.Media:ApplyBackdrop(moduleFrame,{bgFile='original'},'lootSparkles')
    assert(moduleFrame.backdrop.bgFile==display.texture,'module backdrops take the built-in surface')
    assert(w.title:GetText()=='Play The Game Tools' and w.sidebarWidth==212,'one brand text in every theme')
    assert(w.title.color[1]==0 and w.title.color[2]==240/255 and w.title.color[3]==1,'cyan branding')
    assert(w.brandLogo and not w.headerArt:IsShown() and not w.columnEdge:IsShown())
    assert(w.brandLogo.points[1][5]==0,'logo centers inside the header without overlapping navigation')
    assert(w.canvasSheen.gradient.minimum.a==0.018 and w.bodySheen.gradient.maximum.a==0,'static neutral background sheen')
    assert(w.closeButton.points[1][1]=='RIGHT' and w.closeButton.points[1][2]==w.headerControls,'close is rightmost')
    assert(w.layoutButton.points[1][2]==w.closeButton and w.profileButton==nil,'Layout is immediately left of close')
    assert(T.muted[1]<T.secondary[1] and T.secondary[1]<T.text[1],'descriptor hierarchy')
    assert(w.searchInput:GetParent()==w.sidebar and w.searchInput.points[1][1]=='TOPLEFT','sidebar search')
    assert(w.headerReserved>=w.headerControls:GetWidth(),'header controls stay reachable after off-screen recovery')
    assert(w.canvas.modeAsset=='ModeSurface' and not w.bodyBorder and not w.border.shown,'page perimeter borders removed')
    local first=w.navigationButtons[addon:ListedConfigPages()[1]]
    assert(w.title.font[1]:find('Lato%-Bold.ttf') and first.label.font[1]:find('Lato%-Regular.ttf'))
    assert(w.categoryNavigation==nil,'no duplicate module strip')
    -- One flat A-Z list: no category headings or nested children.
    for _,row in ipairs(w.navigation.rows) do
        assert(row.skinStyle=='tab' and row:IsShown() and row.label:GetText():sub(1,3)~='\194\183 ')
        assert(row.label.font[2]<=T.fontSize.body and not row.label.wordWrap)
        assert(row.label:GetStringWidth()<=row:GetWidth()-row.textReserve,'single-line row fits '..row.label:GetText())
    end
    for _,cid in ipairs(addon.categoryOrder) do assert(w.navigationButtons[cid]==nil) end
    for _,id in ipairs(addon.moduleOrder) do
        addon:SelectConfigPage(id)
        assert(w.selectedPage==id and w.pages[id]:IsShown(),id)
        assert(w.moduleHeader.title:GetText()==addon.modules[id].title,id)
        if w.sidebarModuleButtons[id] then assert(w.sidebarModuleButtons[id].selected,id) end
    end
    local results=addon:SearchSettings('Combat Timer')
    assert(#results>0)
    -- Renamed modules keep their old names as search aliases.
    for query,id in pairs({['points of interest']='cityLabels',['enhanced experience']='enhancedExperienceBar',['quick access bars']='foreverQuickAccess'}) do
        local found=addon:SearchSettings(query)
        assert(found[1] and found[1].module.id==id,'old module name still finds '..id)
    end
    assert(addon.modules.cityLabels.title=='Map Labels' and addon.modules.enhancedExperienceBar.title=='Experience Bar')
    assert(addon.modules.foreverQuickAccess.title=='Profession & Food Bars' and addon.modules.foreverRogue.title=='Rogue Tools')
    addon:SelectConfigPage(results[1].module.id)
    assert(w.sidebarModuleButtons.combatTimer:IsShown() and w.sidebarModuleButtons.combatTimer.selected,'search routing selects the row')
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
    local oldText=b.label:GetText();b.label:SetText('Profession & Food Bars')
    b:SetWidth(164);b.scripts.OnSizeChanged(b)
    assert(not b.label.wordWrap and b.label:GetStringWidth()<=164-b.textReserve,'long title fits one line at constrained width')
    b.label:SetText(oldText);b:SetWidth(oldWidth);b.scripts.OnSizeChanged(b)
    local page=w.pages.combatTimer
    assert(page.contentInset==12)
    for _,row in ipairs(page.rows) do if row:IsShown() then assert(row.points[1][4]==12,'visible rows keep the border padding; there is no checkbox gutter') end end
    assert(page.scrollbar.thumbTexture:GetWidth()==4,'one scroll thumb size in every theme')
    local check=addon.ConfigWidgets.Button(UIParent,'',18,18,'checkbox')
    assert(check.fill.modeAsset=='ModeCheckSurface' and check.switchOutline.rounded)
    local button=addon.ConfigWidgets.Button(UIParent,'Refresh',100,28)
    assert(button.fill.modeAsset=='ModeControlSurface' and button.outline.rounded)
    assert(button.fill.points[1][4]==1 and button.fill.points[1][5]==-1,'button background stays within border')
    local toggle=w.moduleHeader.toggle
    assert(toggle.switchOutline.rounded and toggle.fill.modeAsset=='ModeToggleSurface' and toggle.knob.modeAsset=='ModeThumb','rounded track and circular thumb')
    assert(not toggle.fill.slice and not toggle.switchOutline.edges[1].slice,'small controls use full oval sprites')
    assert(toggle.fill:GetWidth()==32 and toggle.fill:GetHeight()==16,'toggle has a one-unit rim')
    assert(check.fill:GetWidth()==16 and check.fill:GetHeight()==16,'checkbox has a one-unit rim')
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
            assert(rim.vertexColor[1]==43/255 and rim.vertexColor[2]==43/255 and rim.vertexColor[3]==43/255 and rim.vertexColor[4]==1,'border remains charcoal in both states')
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
    addon:SelectConfigPage('globalSettings');assert(not b.activeGlow:IsShown())
    assert(addon.ProfileCodec.Encode(PTGToolsDB)==before,'navigation preserves all saved preferences')
    local media=addon.Media
    local original=addon.db.globalMedia.font
    addon.db.globalMedia.font='media:PTG JetBrains Mono';media:RefreshFonts()
    assert(w.title.font[1]:find('Lato%-Bold.ttf'),'a saved Global Font no longer overrides the theme font')
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
    assert(#page.sections==4 and page.themeButtons[3].selected and not page.mediaControls,'theme cards, no media pickers')
    assert(page.themeButtons[3].current:IsShown() and not page.themeButtons[1].current:IsShown(),'applied theme marked Current')
    reloads=0;C_UI.Reload=function() reloads=reloads+1 end
    page.themeButtons[2].scripts.OnClick()
    local reload=w.reloadBanner.reloadButton
    assert(w.reloadBanner:IsShown(),'pending theme shows the reload banner')
    reload.scripts.OnClick();assert(reloads==1)
    testCombat=true;reload.scripts.OnClick();assert(reloads==1,'combat reload remains blocked');testCombat=false
''')
# Other themes share the same layout/behavior; only colors, borders and textures differ.
back, _ = load(mode.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
back.execute('''
    addon:ToggleConfig();addon:SelectConfigPage('combatTimer')
    local w=addon.configWindow
    assert(addon.InterfaceTheme.id=='blizzard' and w.categoryNavigation==nil and w.layoutButton and w.searchInput:GetParent()==w.sidebar,'same navigation, header and search')
    assert(not w.bodyDetail and not w.bodySurface,'Blizzard keeps its own page material')
    assert(w.sidebarModuleButtons.combatTimer:IsShown() and w.pages.combatTimer.modeLayout,'same sidebar and page layout')
    local popup=CreateFrame('Frame',nil,UIParent)
    assert(addon.ConfigWidgets.BlizzardBackdrop(popup,'tooltip'))
    assert(popup.backdrop.bgFile==[[Interface\\Tooltips\\UI-Tooltip-Background]],'Blizzard popup retains native theme background with a custom global texture')
    assert(popup.backdrop.edgeFile==addon.ConfigWidgets.BlizzardArt.tooltipBorder and popup.backdrop.edgeSize==16,'Blizzard popup retains the stock tooltip edge')
    addon:SetInterfaceTheme('modern')
''')
modern, _ = load(back.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
modern.execute('''
    addon:ToggleConfig();addon:SelectConfigPage('combatTimer')
    local w=addon.configWindow
    assert(addon.InterfaceTheme.id=='modern' and w.categoryNavigation==nil and w.layoutButton,'same navigation and header')
    assert(not w.bodyDetail and not w.bodySurface,'Modern keeps its own page material')
    assert(w.navigationButtons.timers==nil and w.navigationButtons.combatTimer.skinStyle=='tab','same flat module list')
    assert(addon.db.globalMedia.texture=='background:PTG Graphite' and not w.canvas.texture,'Modern retains flat canvas without resetting global selection')
    local fill=addon.ConfigWidgets.Fill(w,addon.InterfaceTheme.panel)
    assert(not fill.texture,'Modern settings panels ignore global texture')
    assert(w.sidebarModuleButtons.combatTimer.label.font[2]<=addon.InterfaceTheme.fontSize.body)
''')
print('PASS mode palette/materials/font, text-only hover, sidebar search, all pages, A-Z sidebar/reload banner, persistence and identical layout across themes')
