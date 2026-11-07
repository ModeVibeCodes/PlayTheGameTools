"""Actual candidate buttons must never invoke the protected invite API."""
from pathlib import Path
import runpy

suite = runpy.run_path(str(Path(__file__).with_name('smoke.py')))
lua, _ = suite['load']()
lua.execute("""
    directInvites=0;draftCalls=0
    C_GuildInfo={Invite=function() directInvites=directInvites+1;error('Protected invite called') end}
    ChatFrameUtil={GetActiveWindow=function() return nil end,GetChatFocusOverride=function() return nil end,
        OpenChat=function(text) draftCalls=draftCalls+1;draft=text end}
    addon:SetModuleEnabled('foreverRecruitment',true)
    local m=addon.ForeverRecruitment
    assert(m.Invite==nil)
    addon:ToggleConfig();addon:SelectConfigPage('foreverRecruitment')
    m.order={'Test Surname'}
    m.candidates['Test Surname']={name='Test Surname',level=10,class='Mage',zone='Elwynn Forest'}
    m.page:Refresh()
    assert(m.cells[1][2].label:GetText()=='Player Menu Link' and m.cells[1][5]==nil)
    m.cells[1][2].scripts.OnClick()
    assert(messages[#messages]:find('|Hplayer:Test Surname|h[Test Surname]|h',1,true))
    assert(directInvites==0 and m.db.history['Test Surname']==nil)
    m.cells[1][1].scripts.OnClick();assert(draftCalls==1 and directInvites==0)
    local before=#messages
    testLockdown=true;testCombat=true;m:NativeLink('Test Surname');assert(#messages==before)
    testLockdown=false;testCombat=false
    m.cells[1][3].scripts.OnClick();assert(m.db.history['Test Surname']=='contacted')
    assert(m.cells[1].name==nil and directInvites==0)
    m.pending=10;m.scanning=true
    FireEvent('ADDON_ACTION_FORBIDDEN','AnotherAddon','UNKNOWN()');assert(m.pending==10 and not m.scanBlocked)
    FireEvent('ADDON_ACTION_FORBIDDEN','ModeTools','UNKNOWN()')
    assert(m.scanBlocked and m.pending==nil and not m.scanning)
    addon:SetModuleEnabled('foreverRecruitment',false)
    addon:SetModuleEnabled('foreverRecruitment',true);assert(m.scanBlocked)
""")
state=lua.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
restored,_=suite['load'](state)
restored.execute("assert(addon.ForeverRecruitment.db.history['Test Surname']=='contacted')")
print('PASS candidate native links/drafts, zero protected invitations, history persistence, combat and UNKNOWN rejection guards')
