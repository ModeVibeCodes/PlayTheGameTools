"""Character-sheet ownership, restricted reads and lifecycle; not native rendering."""
from smoke import load

lua, _ = load()
lua.execute(r'''
    local methods=getmetatable(UIParent).__index
    function methods:IsObjectType(kind) return self.kind==kind end
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
    local icon=CharacterHeadSlot:CreateTexture(nil,'ARTWORK')
    local name=CharacterFrame:CreateFontString(nil,'OVERLAY');name:SetFont('Original',17,'OUTLINE');name:SetTextColor(.8,.7,.6,1)
    CharacterFrame.TitleContainer=CreateFrame('Frame',nil,CharacterFrame)
    CharacterFrame.TitleContainer.fixtureRegions={name}
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
    assert(M.surfaces[CharacterHeadSlot]:GetFrameLevel()<CharacterHeadSlot:GetFrameLevel(),'fill stays behind native icon')
    assert(M.stats:GetText():find('Strength: 10',1,true) and M.stats:GetText():find('Attack Power: 13',1,true))
    assert(M.labels[1]:GetText():find('Str / Agi',1,true))
    assert(not M.labels[1]:GetText():find('100',1,true),'base item stat excluded')
    assert(M.Summarize('Instant Poison IV')=='Instant Poison')
    assert(M.Summarize('+5 All Stats')=='All Stats')
    assert(not M:SetAppearance('fontSize',99) and M.db.fontSize==11)
    assert(not M:SetAppearance('statsAlign','INVALID'))
    assert(M:SetAppearance('fontSize',13) and name.font[2]==13)
    testCombat=true
    assert(not M:SetAppearance('statsX',20))
    addon:SetModuleEnabled('characterReskin',false)
    assert(art:GetAlpha()==0 and M.pending,'restoration deferred during combat')
    testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
    assert(art:GetAlpha()==.75 and name.font[1]=='Original' and name.font[2]==17)
    assert(not M.stats:IsShown() and not M.labels[1]:IsShown() and not M.events:IsEventRegistered('PLAYER_REGEN_ENABLED'))
    addon:SetModuleEnabled('characterReskin',true)
    PaperDollFrame:Hide()
    assert(art:GetAlpha()==.75,'other character tabs restore native shell')
    PaperDollFrame:Show();assert(art:GetAlpha()==0)
    UnitStat=function() return 1,{secret=true} end
    C_TooltipInfo.GetInventoryItem=function() return {lines={{type=15,leftText={secret=true}}}} end
    M:Refresh();assert(M.stats:GetText():find('Strength: —',1,true))
    assert(M.labels[1]:GetText():find('Unknown',1,true),'secret enchant not parsed')
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
    C_TooltipInfo=nil;M:Refresh();assert(M.labels[1]:GetText():find('Unknown',1,true))
    addon:SetModuleEnabled('damageMeterReskin',true)
    assert(not addon.modules.damageMeterReskin.enabled,'planned pages cannot enable')
    addon:ToggleConfig();addon:SelectConfigPage('damageMeterReskin')
    assert(not addon.configWindow.moduleHeader.toggle:IsShown())
    addon:SelectConfigPage('characterReskin');assert(addon.configWindow.moduleHeader.toggle:IsShown())
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
