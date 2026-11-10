"""SharedMedia/MyMedia activation, registration, manual disable and plain names."""
from smoke import load

SETUP=r'''
services={SharedMedia=0,SharedMedia_MyMedia=0};loadedServices={};enables={};loads={};saves=0
C_AddOns.DoesAddOnExist=function(name) return services[name]~=nil end
C_AddOns.IsAddOnLoaded=function(name) return loadedServices[name]==true end
C_AddOns.GetAddOnEnableState=function(name) return services[name] or 0 end
C_AddOns.EnableAddOn=function(name)
 assert(not testCombat and not testLockdown);assert(services[name]~=nil)
 enables[#enables+1]=name;services[name]=2
end
C_AddOns.SaveAddOns=function() saves=saves+1 end
C_AddOns.LoadAddOn=function(name)
 assert(not testCombat and not testLockdown);assert(services[name]~=nil,'No other providers loaded')
 loads[#loads+1]=name
 if rejectService then return nil,'CORRUPT' end
 local lib=LibStub('LibSharedMedia-3.0')
 if name=='SharedMedia' then
  lib:Register('font','Adventure',[[Interface\AddOns\SharedMedia\fonts\adventure\Adventure.ttf]])
  lib:Register('statusbar','Aluminium',[[Interface\AddOns\SharedMedia\statusbar\Aluminium]])
  lib:Register('background','Bricks',[[Interface\AddOns\SharedMedia\background\bricks.tga]])
  lib:Register('border','RothSquare',[[Interface\AddOns\SharedMedia\border\roth.tga]])
 else lib:Register('font','My Custom Font (Personal)',[[Interface\AddOns\SharedMedia_MyMedia\font\custom.ttf]]) end
 loadedServices[name]=true;FireEvent('ADDON_LOADED',name);return true
end
'''
lua,_=load(before=SETUP)
lua.execute(r'''
local M=addon.Media
assert(M.sharedMediaStatus=='Ready' and #enables==2 and #loads==2 and saves==2)
assert(M:GetFont('Adventure') and M:GetStatusBar('media:Aluminium') and M:GetBorder('media:RothSquare'))
assert(M:GetFont('My Custom Font (Personal)'))
for _,getter in ipairs({'GetFonts','GetTextures','GetBorders','GetStatusBars'}) do
 for _,choice in ipairs(M[getter](M)) do assert(not choice.label:find('[()]'),'media choices contain names only') end
end
addon:ToggleConfig();addon:SelectConfigPage('globalSettings')
local page=addon.configWindow.pages.globalSettings
local button=page.mediaControls['global:texture'];button.scripts.OnClick()
local found=false
for _,row in ipairs(button.rows) do
 assert(not row.label:GetText():find('[()]'))
 if row.choice.id=='media:Aluminium' then row.scripts.OnClick();found=true;break end
end
assert(found and button.label:GetText()=='Aluminium')
local profile=addon.ProfileCodec.Decode(assert(addon.ProfileManager:Export(addon.ProfileManager.activeName))).profile
assert(not profile.sharedMediaActivation,'service setup is machine/account state, not a profile option')
testCombat=true;M:EnsureSharedMedia();assert(M.sharedMediaPending and #enables==2)
testCombat=false;FireEvent('PLAYER_REGEN_ENABLED');assert(not M.sharedMediaPending)
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
disabled,_=load(state,before=SETUP)
disabled.execute(r'''
assert(#enables==0 and #loads==0,'later manual disables remain respected')
assert(addon.Media.sharedMediaStatus=='Disabled in AddOns')
assert(addon.Media:GetFont('Adventure'),'remembered media still works without loading its provider')
''')
failed,_=load(before=SETUP+'\nrejectService=true\n')
failed.execute(r'''
assert(addon.Media.sharedMediaStatus=='Reload or check AddOns')
local calls=#loads;addon.Media:EnsureSharedMedia();assert(#loads==calls,'no retry loop on native rejection')
''')
print('PASS explicit SharedMedia/MyMedia activation, asset registrations, plain dropdown names, account state isolation, combat deferral, manual disables and load failure')
