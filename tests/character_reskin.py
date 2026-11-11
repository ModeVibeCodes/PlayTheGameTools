"""Character-sheet ownership, restricted reads and lifecycle; not native rendering."""
from smoke import load

lua, _ = load()
CASES = r'''
    local methods=getmetatable(UIParent).__index
    local createFont=methods.CreateFontString
    function methods:CreateFontString(name,layer,inherits)
        local text=createFont(self,name,layer,inherits)
        if inherits then text.font={GameFontHighlight:GetFont()} end
        text.strictFont=true;return text
    end
    local setText=methods.SetText
    function methods:SetText(value)
        assert(not self.strictFont or self.font,'FontString:SetText(): Font not set')
        return setText(self,value)
    end
    function methods:IsObjectType(kind) return self.kind==kind end
    function methods:GetJustifyH() return self.justifyH or 'LEFT' end
    function methods:GetJustifyV() return self.justifyV or 'TOP' end
    function methods:GetTexture() return self.texture end
    function methods:GetTexCoord() return unpack(self.texCoord or {0,0,0,1,1,0,1,1}) end
    function methods:CreateMaskTexture() local mask=self:CreateTexture(nil,'OVERLAY');mask.kind='MaskTexture';return mask end
    function methods:AddMaskTexture(mask) self.mask=mask end
    function methods:GetAtlas() return self.atlas end
    function methods:GetNormalTexture() return self.normalTexture end
    function methods:GetPushedTexture() return self.pushedTexture end
    function methods:GetHighlightTexture() return self.highlightTexture end
    function methods:GetChecked() return self.checked==true end
    function methods:SetAllPoints(relative)
        self:ClearAllPoints();self:SetPoint('TOPLEFT',relative or self:GetParent(),'TOPLEFT',0,0);self:SetPoint('BOTTOMRIGHT',relative or self:GetParent(),'BOTTOMRIGHT',0,0)
    end
    function methods:GetRegions() return unpack(self.fixtureRegions or {}) end
    function methods:GetChildren() return unpack(self.fixtureChildren or {}) end
    function methods:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
    function methods:GetShadowColor() return unpack(self.shadowColor or {0,0,0,0}) end
    function methods:GetShadowOffset() return unpack(self.shadowOffset or {0,0}) end
    CharacterFrame=CreateFrame('Frame',nil,UIParent)
    CharacterFrame:SetFrameLevel(40)
    CharacterFrame.LeftPaneHost=CreateFrame('Frame',nil,CharacterFrame)
    CharacterFrame.RightPaneHost=CreateFrame('Frame',nil,CharacterFrame)
    PaperDollFrame=CreateFrame('Frame',nil,CharacterFrame)
    PaperDollFrame.CharacterModelScene=CreateFrame('Frame',nil,PaperDollFrame)
    local art=CharacterFrame:CreateTexture(nil,'BACKGROUND');art:SetAlpha(.75)
    CharacterFrame.fixtureRegions={art}
    CharacterHeadSlot=CreateFrame('Button',nil,PaperDollFrame)
    local icon=CharacterHeadSlot:CreateTexture(nil,'ARTWORK');CharacterHeadSlot.icon=icon
    CharacterHeadSlot:SetPoint('TOPLEFT',PaperDollFrame,'TOPLEFT',30,-80)
    GetInventoryItemQuality=function(_,slot) return slot==1 and 2 or 1 end
    GetItemQualityColor=function(q) assert(q==2);return .12,1,0 end
    local name=CharacterFrame:CreateFontString(nil,'OVERLAY');name:SetFont('Original',17,'OUTLINE');name:SetTextColor(.8,.7,.6,1)
    CharacterFrame.TitleContainer=CreateFrame('Frame',nil,CharacterFrame)
    CharacterFrame.TitleContainer.fixtureRegions={name};CharacterFrame.TitleContainer.TitleText=name
    name:SetPoint('TOP',CharacterFrame.TitleContainer,'TOP',0,-5)
    CharacterFrame.PortraitContainer=CreateFrame('Frame',nil,CharacterFrame)
    local portrait=CharacterFrame.PortraitContainer:CreateTexture(nil,'OVERLAY');CharacterFrame.PortraitContainer.portrait=portrait
    portrait:SetTexture('FixtureSpecIcon');portrait:SetTexCoord(.1,.2,.1,.8,.6,.2,.6,.8);name:SetText('Fixture Player')
    portrait:SetSize(62,62);portrait:SetPoint('TOPLEFT',CharacterFrame,'TOPLEFT',-5,7)
    local clicked=0
    local function Button(parent)
        local button=CreateFrame('Button',nil,parent);button:SetSize(32,32)
        button.Icon=button:CreateTexture(nil,'ARTWORK');button.Icon:SetSize(42,42)
        button.normalTexture=button:CreateTexture(nil,'BACKGROUND')
        button.fixtureRegions={button.Icon,button.normalTexture}
        button:SetScript('OnClick',function() clicked=clicked+1 end)
        return button
    end
    CharacterFrame.CloseButton=Button(CharacterFrame)
    CharacterFrame.RightPaneToggleButton=Button(CharacterFrame)
    PaperDollSidebarTab1=Button(CharacterFrame);PaperDollSidebarTab1.checked=true
    PaperDollFrame.CharacterModelScene.ControlFrame={zoomInButton=Button(PaperDollFrame.CharacterModelScene)}
    CharacterAmmoSlot=Button(PaperDollFrame);CharacterAmmoSlotIconTexture=CharacterAmmoSlot.Icon
    local arrow=CreateFrame('Frame',nil,CharacterAmmoSlot);local arrowArt=arrow:CreateTexture(nil,'OVERLAY')
    arrowArt.atlas='UI-Character-Info-GearSlot-Arrow';arrow.fixtureRegions={arrowArt};CharacterAmmoSlot.fixtureChildren={arrow}
    local pane=CreateFrame('Frame',nil,CharacterFrame.RightPaneHost)
    local race=pane:CreateTexture(nil,'BACKGROUND');pane.fixtureRegions={race}
    local divider=CreateFrame('Frame',nil,CharacterFrame.RightPaneHost)
    local dividerArt=divider:CreateTexture(nil,'OVERLAY');dividerArt.atlas='common-framedivider';dividerArt:SetAlpha(.65)
    divider.fixtureRegions={dividerArt};CharacterFrame.RightPaneHost.fixtureChildren={divider}
    pane.ScrollBar=CreateFrame('Frame',nil,pane)
    pane.ScrollBar.Track=CreateFrame('Frame',nil,pane.ScrollBar)
    pane.ScrollBar.Track.Thumb=Button(pane.ScrollBar.Track)
    pane.ScrollBar.Track.Begin=pane.ScrollBar.Track:CreateTexture(nil,'ARTWORK')
    pane.ScrollBar.Track.fixtureRegions={pane.ScrollBar.Track.Begin}
    pane.ScrollBar.Back=Button(pane.ScrollBar);pane.ScrollBar.Forward=Button(pane.ScrollBar)
    GetMoney=function() return 123456 end
    GetInventoryItemDurability=function(slot) if slot==1 then return 50,100 elseif slot==5 then return 100,200 end end
    function CharacterFrame:GetStatsPane() return pane end
    local function StatsText()
        local values={};for _,row in ipairs(addon.CharacterReskin.stats.rows) do values[#values+1]=row:GetText() end
        return table.concat(values,'\n')
    end
    UnitStat=function(_,i) return 1,10*i end
    UnitArmor=function() return 1,123 end
    UnitAttackPower=function() return 10,5,-2 end
    Enum={TooltipDataLineType={ItemEnchantmentPermanent=15}}
    GetInventoryItemLink=function(_,slot) return slot==1 and 'item:100:123:0' or nil end
    C_TooltipInfo={GetInventoryItem=function(_,slot) return {lines={
        {type=0,leftText='+100 Agility'}, -- base stats must not become enhancement text
        {type=15,leftText='+4 Strength and +3 Agility'},
    }} end}
    local M=addon.CharacterReskin
    local legacy={fontSize=14,textColor={.3,.4,.5}}
    M.Initialize(legacy);assert(legacy.quickStyle.fontSize==14 and legacy.quickStyle.textColor[1]==.3)
    legacy.fontSize=12;M.Initialize(legacy);assert(legacy.quickStyle.fontSize==14,'one-time quick style migration')
    assert(not M.active and art:GetAlpha()==.75 and not M.stats)
    addon:SetModuleEnabled('characterReskin',true)
    assert(art:GetAlpha()==0 and icon:GetAlpha()==1,'only owned decoration hidden')
    assert(M.itemBorders[1].edges[1].color[2]==1 and M.itemBorders[1].edges[1].height==2,'strong rarity color on outside edge')
    assert(M.itemBorders[1].points[1][2]==icon,'border follows actual icon bounds')
    assert(M.itemBorders[0].points[1][2]==CharacterAmmoSlotIconTexture and arrowArt:GetAlpha()==0,'ammo border excludes stock bevel/arrow')
    assert(portrait:GetWidth()==62 and portrait:GetAlpha()==0 and M.portraitView:GetWidth()==28,'native portrait untouched under cropped copy')
    assert(M.portraitView.icon.mask==M.portraitView.mask and M.portraitView.mask.points[1][4]==1,'circular mask crops one pixel inside rim')
    assert(M.portraitView.icon.texture=='FixtureSpecIcon' and M.portraitView.icon.texCoord[1]==.1,'native spec/class texture coordinates retained')
    assert(name:GetAlpha()==0 and M.headerTitle.text.font[2]==15 and M.headerTitle.text.justifyV=='MIDDLE' and M.headerTitle.text.justifyH=='CENTER')
    assert(M.headerTitle.height==28 and M.headerTitle.points[1][2]==CharacterFrame.LeftPaneHost and M.headerTitle.points[2][2]==CharacterFrame.LeftPaneHost,'name shares level/class model pane center')
    assert(M.headerTitle.points[1][4]==48 and M.headerTitle.points[2][4]==-48,'equal model-pane name margins')
    assert(dividerArt:GetAlpha()==0,'native model/stats divider removed')
    assert(not M.surfaces[CharacterFrame.LeftPaneHost].backdrop and not M.surfaces[CharacterFrame.RightPaneHost].backdrop and not M.surfaces[CharacterFrame].line:IsShown(),'no nested frame crossbars')
    assert(M.surfaces[CharacterFrame].borderColor[1]==66/255,'subtle unified outer frame')
    assert(pane.ScrollBar.Track.Begin:GetAlpha()==0 and M.scrollViews[pane.ScrollBar].thumb.line.width==2,'slim Mode scroll thumb replaces stock artwork')
    assert(M.footer.gold:GetText()=='12g 34s 56c' and M.footer.durability:GetText()=='Durability: 50%','gold and weighted worn durability')
    assert(M.db.showGold and M.db.showDurability and M.footer.durability.points[1][5]>M.footer.gold.points[1][5])
    GetMoney=function() return 200000 end;FireEvent('PLAYER_MONEY');assert(M.footer.gold:GetText()=='20g 00s 00c')
    GetInventoryItemDurability=function(slot) if slot==1 then return 100,100 elseif slot==5 then return 200,200 end end
    FireEvent('UPDATE_INVENTORY_DURABILITY');assert(M.footer.durability:GetText()=='Durability: 100%')
    M:SetAppearance('showGold',false);assert(not M.footer.gold:IsShown() and M.footer.durability.points[1][5]==0)
    M:SetAppearance('showGold',true)
    assert(race:GetAlpha()==0 and M.surfaces[pane].fill.vertexColor[1]==35/255,'stats pane uses navigation gray')
    assert(CharacterFrame.CloseButton.normalTexture:GetAlpha()==0 and M.buttonSkins[CharacterFrame.CloseButton].label:GetText()=='X')
    assert(PaperDollSidebarTab1.Icon:GetAlpha()==1 and PaperDollSidebarTab1.Icon:GetWidth()==28)
    PaperDollSidebarTab1.scripts.OnClick(PaperDollSidebarTab1);assert(clicked==1,'native click callback retained')
    assert(M.buttonSkins[PaperDollFrame.CharacterModelScene.ControlFrame.zoomInButton].label:GetText()=='+')
    assert(M.stats.points[1][1]=='TOPLEFT' and M.stats.points[1][2]==CharacterHeadSlot and M.stats.points[1][3]=='TOPRIGHT' and M.stats.points[1][4]==6)
    assert(#M.stats.rows==18 and M.stats.rows[2].points[1][5]==-14,'individual rows stay inside dedicated stats frame')
    assert(StatsText():find('Strength: 10',1,true) and StatsText():find('Attack Power: 13',1,true))
    assert(M.labels[1]:GetText():find('Str / Agi',1,true))
    assert(not M.labels[1]:GetText():find('100',1,true),'base item stat excluded')
    assert(M.Summarize('Instant Poison IV')=='Instant Poison')
    assert(M.Summarize('+5 All Stats')=='All Stats')
    assert(not M:SetAppearance('fontSize',99) and M.db.fontSize==11)
    assert(not M:SetAppearance('statsAlign','INVALID'))
    assert(M:SetAppearance('fontSize',13) and M.headerTitle.text.font[2]==15 and M.stats.rows[1].font[2]==11)
    local selected=addon.ProfileCodec.Copy(M.db.statsShown);selected.Strength=false
    M:SetAppearance('statsShown',selected);assert(not StatsText():find('Strength:',1,true) and M.stats.rows[1]:GetText():find('Agility:',1,true),'hidden stats compact')
    for key in pairs(selected) do selected[key]=false end
    M:SetAppearance('statsShown',selected);assert(not M.stats:IsShown(),'all stats off hides list')
    for key in pairs(selected) do selected[key]=true end
    M:SetAppearance('statsShown',selected)
    local style=addon.ProfileCodec.Copy(M.db.quickStyle);style.fontSize=18;M:SetAppearance('quickStyle',style)
    assert(M.stats.rows[1].font[2]==18 and M.headerTitle.text.font[2]==15 and M.db.fontSize==13,'quick stats style independent')
    local bad=addon.ProfileCodec.Copy(M.db.statsShown);bad.Strength='yes';assert(not M:SetAppearance('statsShown',bad))
    local badStyle=addon.ProfileCodec.Copy(M.db.quickStyle);badStyle.fontSize=100;assert(not M:SetAppearance('quickStyle',badStyle))
    testCombat=true
    assert(not M:SetAppearance('statsX',20))
    addon:SetModuleEnabled('characterReskin',false)
    assert(art:GetAlpha()==0 and M.pending,'restoration deferred during combat')
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    assert(art:GetAlpha()==.75 and name.font[1]=='Original' and name.font[2]==17)
    assert(dividerArt:GetAlpha()==.65,'native divider restored on disable')
    assert(portrait:GetWidth()==62 and portrait.points[1][4]==-5 and name.points[1][4]==0 and name.points[1][5]==-5,'native geometry restored')
    assert(portrait:GetAlpha()==1 and name:GetAlpha()==1 and pane.ScrollBar.Track.Begin:GetAlpha()==1 and not M.portraitView:IsShown() and not M.headerTitle:IsShown() and not M.footer:IsShown(),'custom chrome/footer fully restored')
    assert(arrowArt:GetAlpha()==1 and CharacterFrame.CloseButton.normalTexture:GetAlpha()==1)
    assert(not M.stats:IsShown() and not M.labels[1]:IsShown() and not M.events:IsEventRegistered('PLAYER_REGEN_ENABLED'))
    addon:SetModuleEnabled('characterReskin',true)
    PaperDollFrame:Hide()
    assert(art:GetAlpha()==.75,'other character tabs restore native shell')
    PaperDollFrame:Show();assert(art:GetAlpha()==0)
    UnitStat=function() return 1,{secret=true} end
    C_TooltipInfo.GetInventoryItem=function() return {lines={{type=15,leftText={secret=true}}}} end
    M:Refresh();assert(StatsText():find('Strength: —',1,true))
    assert(M.labels[1]:GetText()=='' and not M.labels[1]:IsShown(),'secret enhancement hidden')
    Enum.WeaponSlot={MainHand=0,OffHand=1};Enum.ItemEnchantType={Imbue=1}
    C_Item=C_Item or {}
    C_Item.GetWeaponEnchantInfo=function(slot)
        assert(slot==0 or slot==1)
        return {{enchantType=1,hasEnchant=true,enchantIconID=777}}
    end
    C_Spell=C_Spell or {};C_Spell.GetSpellInfo=function() return {name='Instant Poison IV',iconID=777} end
    assert(M:Enhancement(16):find('Instant Poison',1,true),'imbues independent of Rogue feature enable state')
    C_Item.GetWeaponEnchantInfo=function() return {{enchantType=1,hasEnchant={secret=true}}} end
    assert(not M:Enhancement(16):find('Poison',1,true),'restricted imbue is never inferred')
    C_TooltipInfo=nil;M:Refresh();assert(M.labels[1]:GetText()=='' and not M.labels[1]:IsShown())
    GetMoney=function() return {secret=true} end
    GetInventoryItemDurability=function() return {secret=true},100 end
    FireEvent('PLAYER_MONEY');assert(M.footer.gold:GetText()=='Gold: —' and M.footer.durability:GetText()=='Durability: —','restricted footer values never formatted')
    M:SetAppearance('showGold',false);M:SetAppearance('showDurability',false);assert(not M.footer:IsShown())
    local register=M.events.RegisterEvent
    addon:SetModuleEnabled('characterReskin',false)
    M.events.RegisterEvent=function(owner,event)
        if event=='UPDATE_INVENTORY_DURABILITY' then error('unavailable in fixture build') end
        return register(owner,event)
    end
    addon:SetModuleEnabled('characterReskin',true)
    assert(M.active and M.events:IsEventRegistered('UPDATE_INVENTORY_ALERTS'),'optional event rejection cannot abort activation')
    M.events.RegisterEvent=register
    addon:SetModuleEnabled('damageMeterReskin',true)
    assert(not addon.modules.damageMeterReskin.enabled,'planned pages cannot enable')
    addon:ToggleConfig();addon:SelectConfigPage('damageMeterReskin')
    assert(not addon.configWindow.moduleHeader.toggle:IsShown())
    addon:SelectConfigPage('characterReskin');assert(addon.configWindow.moduleHeader.toggle:IsShown())
    local page=addon.configWindow.pages.characterReskin
    local quick
    for _,section in ipairs(page.sections) do if section.title=='Quick Stats' then quick=section end end
    assert(quick and #page.statControls==18,'dedicated quick stats pill and per-stat choices')
    page:SelectSectionTab(quick)
    page.statControls[1].frame.scripts.OnClick();assert(not M.db.statsShown.Strength)
    page.statControls[1].frame.scripts.OnClick();assert(M.db.statsShown.Strength)
    assert(page.tabContentTop>=page.sectionTabs:GetHeight()+12 and page.scroll.points[1][5]==-page.tabContentTop,'scroll viewport below tabs')
    for _,row in ipairs(page.rows) do assert(row.settingsTitle~='Unknown Enhancement Color' and row.settingsTitle~='Border X Offset' and row.settingsTitle~='Surface Texture','irrelevant options removed') end
    assert(not addon.configWindow.pages.dashboard.moduleRows.damageMeterReskin,'planned page has no dashboard toggle')
'''
lua.execute(CASES)
saved = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(saved)
restored.execute('''
    assert(addon.CharacterReskin.db.fontSize==13 and addon.CharacterReskin.active)
    assert(addon.CharacterReskin.db.quickStyle.fontSize==18 and addon.CharacterReskin.db.statsShown.Strength and not addon.CharacterReskin.db.showGold and not addon.CharacterReskin.db.showDurability)
    local copy=addon.ProfileCodec.Copy(addon.db)
    copy.modules.characterReskin.borderSize=100
    assert(not addon.ProfileValidation:Validate(copy))
''')
# Model the real reload ordering: an enabled profile, already-open character
# panel and UpdatePortrait occurring before the native title text is populated.
setup = CASES.split('    local M=addon.CharacterReskin', 1)[0]
boot, _ = load(saved, before=setup + r'''
    PTGToolsDB.profiles.Default.modules.characterReskin.showGold=true
    PTGToolsDB.profiles.Default.modules.characterReskin.showDurability=true
    CharacterFrame.TitleContainer.TitleText:SetText(nil)
''')
boot.execute(r'''
    assert(addon.initialized and addon.CharacterReskin.active,'open-panel startup must complete')
    local M=addon.CharacterReskin
    assert(M.headerTitle.text:GetText()=='' and M.headerTitle.text.font,'font assigned even before native name exists')
    assert(M.footer.gold.font and M.footer.durability.font and M.footer.gold:GetText()=='12g 34s 56c')
    CharacterFrame.TitleContainer.TitleText:SetText('Fixture Player')
    M:Refresh();assert(M.headerTitle.text:GetText()=='Fixture Player')
''')
print('PASS character reskin ownership/restoration, combat deferral, typed enhancements, missing/restricted data, config and profiles')
