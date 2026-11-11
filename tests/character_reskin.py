"""Character-sheet ownership, restricted reads and lifecycle; not native rendering."""
from smoke import load

lua, _ = load()
lua.execute(r'''
    local methods=getmetatable(UIParent).__index
    function methods:IsObjectType(kind) return self.kind==kind end
    function methods:GetJustifyH() return self.justifyH or 'LEFT' end
    function methods:GetJustifyV() return self.justifyV or 'TOP' end
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
    assert(not M.active and art:GetAlpha()==.75 and not M.stats)
    addon:SetModuleEnabled('characterReskin',true)
    assert(art:GetAlpha()==0 and icon:GetAlpha()==1,'only owned decoration hidden')
    assert(M.itemBorders[1].edges[1].color[2]==1 and M.itemBorders[1].edges[1].height==2,'strong rarity color on outside edge')
    assert(M.itemBorders[1].points[1][2]==icon,'border follows actual icon bounds')
    assert(M.itemBorders[0].points[1][2]==CharacterAmmoSlotIconTexture and arrowArt:GetAlpha()==0,'ammo border excludes stock bevel/arrow')
    assert(portrait:GetWidth()==28 and name.font[2]==15 and name.justifyV=='MIDDLE' and name.justifyH=='CENTER')
    assert(name.points[1][2]==CharacterFrame.TitleContainer and CharacterFrame.TitleContainer.height==22)
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
    assert(M:SetAppearance('fontSize',13) and name.font[2]==15)
    testCombat=true
    assert(not M:SetAppearance('statsX',20))
    addon:SetModuleEnabled('characterReskin',false)
    assert(art:GetAlpha()==0 and M.pending,'restoration deferred during combat')
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    assert(art:GetAlpha()==.75 and name.font[1]=='Original' and name.font[2]==17)
    assert(portrait:GetWidth()==62 and portrait.points[1][4]==-5 and name.points[1][4]==0 and name.points[1][5]==-5,'native geometry restored')
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
    addon:SetModuleEnabled('damageMeterReskin',true)
    assert(not addon.modules.damageMeterReskin.enabled,'planned pages cannot enable')
    addon:ToggleConfig();addon:SelectConfigPage('damageMeterReskin')
    assert(not addon.configWindow.moduleHeader.toggle:IsShown())
    addon:SelectConfigPage('characterReskin');assert(addon.configWindow.moduleHeader.toggle:IsShown())
    local page=addon.configWindow.pages.characterReskin
    assert(page.tabContentTop>=page.sectionTabs:GetHeight()+12 and page.scroll.points[1][5]==-page.tabContentTop,'scroll viewport below tabs')
    for _,row in ipairs(page.rows) do assert(row.settingsTitle~='Unknown Enhancement Color' and row.settingsTitle~='Border X Offset' and row.settingsTitle~='Surface Texture','irrelevant options removed') end
    assert(not addon.configWindow.pages.dashboard.moduleRows.damageMeterReskin,'planned page has no dashboard toggle')
''')
saved = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(saved)
restored.execute('''
    assert(addon.CharacterReskin.db.fontSize==13 and addon.CharacterReskin.active)
    local copy=addon.ProfileCodec.Copy(addon.db)
    copy.modules.characterReskin.borderSize=100
    assert(not addon.ProfileValidation:Validate(copy))
''')
print('PASS character reskin ownership/restoration, combat deferral, typed enhancements, missing/restricted data, config and profiles')
