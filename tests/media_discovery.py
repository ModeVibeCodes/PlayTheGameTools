"""Known disabled providers, persisted LSM media, collisions and absent assets."""
from smoke import load

SETUP=r'''
installedProviders={AyijeUI=true,DisabledProvider=true,NewProvider=true}
C_AddOns.DoesAddOnExist=function(name) return installedProviders[name]==true end
C_AddOns.LoadAddOn=function() error('Never load another addon for its media') end
C_AddOns.EnableAddOn=function() error('Never enable another addon for its media') end
C_AddOns.GetAddOnEnableState=function() return 0 end
testProviderFonts={}
testProviderFonts[ [[Interface\AddOns\AyijeUI\Media\Fonts\Expressway.ttf]] ]=true
testProviderFonts[ [[Interface\AddOns\AyijeUI\Media\Statusbar\focus.tga]] ]=true
testProviderFonts[ [[Interface\AddOns\AyijeUI\Media\Borders\Ayije_Thin.tga]] ]=true
'''
lua,_=load(before=SETUP)
lua.execute(r'''
local M=addon.Media
assert(M:GetFont('AyijeUI: Expressway')==[[Interface\AddOns\AyijeUI\Media\Fonts\Expressway.ttf]])
assert(M:GetStatusBar('media:AyijeUI: focus')==[[Interface\AddOns\AyijeUI\Media\Statusbar\focus.tga]])
assert(M:GetBorder('media:AyijeUI: Ayije_Thin').path==[[Interface\AddOns\AyijeUI\Media\Borders\Ayije_Thin.tga]])
local lib=M.library
for _,kind in ipairs({'font','statusbar','background','border'}) do
 assert(lib:Register(kind,'Remembered '..kind,[[Interface\AddOns\DisabledProvider\media\]]..kind..(kind=='font' and '.ttf' or '.tga')))
 assert(addon.ProfileManager.root.mediaRegistry[kind]['Remembered '..kind])
end
addon.db.globalMedia.font='media:Remembered font'
local exported=assert(addon.ProfileManager:Export(addon.ProfileManager.activeName))
assert(not addon.ProfileCodec.Decode(exported).profile.mediaRegistry,'machine media paths excluded from profile exports')
local owner={};local refreshes=0
M:RegisterBorderListener(owner,function() refreshes=refreshes+1 end)
testCombat=true
lib:Register('border','Late edge',[[Interface\AddOns\DisabledProvider\media\late.tga]])
assert(refreshes==0 and M.borderPending and M.pending,'media rendering deferred in combat')
testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(refreshes==1 and not M.borderPending,'deferred borders refresh after combat')
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=SETUP)
restored.execute(r'''
local M=addon.Media
assert(M:GetFont('Remembered font')==[[Interface\AddOns\DisabledProvider\media\font.ttf]])
assert(M:GetStatusBar('media:Remembered statusbar'))
assert(M:GetBorder('media:Remembered border').kind=='shared')
local found=false
for _,choice in ipairs(M:GetTextures()) do if choice.key=='background:Remembered background' then found=true end end
assert(found,'cached backgrounds join texture choices without provider execution')
''')
missing,_=load(state,before=SETUP+"\ninstalledProviders.DisabledProvider=false\n")
missing.execute(r'''
assert(not addon.Media:GetFont('Remembered font'))
assert(not addon.Media:GetStatusBar('media:Remembered statusbar'))
assert(not addon.Media:GetBorder('media:Remembered border'))
assert(addon.db.globalMedia.font=='media:Remembered font','uninstalled selection retained for recovery')
assert(addon.Media:GetDisplayFont({font='game',fontMedia=''})==addon.Media.gameFont)
''')
collision,_=load(state,before=SETUP+r'''
LibStub('LibSharedMedia-3.0'):Register('font','Remembered font',[[Interface\AddOns\NewProvider\new.ttf]])
''')
collision.execute(r'''
assert(addon.Media:GetFont('Remembered font')==[[Interface\AddOns\NewProvider\new.ttf]],'current registration wins over cache')
assert(addon.ProfileManager.root.mediaRegistry.font['Remembered font']==[[Interface\AddOns\NewProvider\new.ttf]])
''')
unknown,_=load(state,before=SETUP+r'''
testMissingTextures={}
local base=[[Interface\AddOns\DisabledProvider\media\]]
for _,kind in ipairs({'font','statusbar','background','border'}) do
 testMissingTextures[base..kind..(kind=='font' and '.ttf' or '.tga')]=true
end
''')
unknown.execute("assert(not addon.Media:GetFont('Remembered font') and not addon.Media:GetBorder('media:Remembered border'))")
print('PASS disabled-provider fonts/bars/borders, cached four-kind media across reload, no loading/enabling, collision ownership, export isolation and missing assets')
