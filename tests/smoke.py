"""Lua 5.1 syntax, startup, UI construction and settings restoration; not WoW."""
import io
from pathlib import Path
import sys
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_release import ROOT, payload, archive_bytes
from lupa.lua51 import LuaRuntime


def load(encoded=None, project=18):
    files, order, toc = payload()
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
    lua.globals().testProject = project
    lua.execute('''
        WOW_PROJECT_MAINLINE=1; WOW_PROJECT_CAMELOT=18; WOW_PROJECT_ID=testProject
        messages={}; function print(s) messages[#messages+1]=s end
        C_UI={Reload=function() end}
        function UnitClass() return 'Rogue','ROGUE',4 end
        function UnitGUID() return 'Player-Collaboration-Fixture' end
        function UnitFullName() return 'Fixture','TestRealm' end
    ''')
    metadata = {line[3:].split(':', 1)[0]: line.split(':', 1)[1].strip()
                for line in toc.splitlines() if line.startswith('## ')}
    lua.globals().metadata = lua.table_from(metadata)
    lua.execute('C_AddOns.GetAddOnMetadata=function(_,key) return metadata[key] end')
    addon = lua.table()
    execute = lua.eval('function(s,n,...) local f,e=loadstring(s,n); assert(f,e); return f(...) end')
    for name in order:
        execute(files[name].decode('utf-8-sig'), name, 'ModeTools', addon)
    lua.globals().addon = addon
    if encoded is not None:
        lua.globals().encoded = encoded
        lua.execute('ModeToolsDB=addon.ProfileCodec.Decode(encoded)')
    lua.execute("FireEvent('ADDON_LOADED','ModeTools'); FireEvent('PLAYER_LOGIN')")
    return lua, addon


files, order, _ = payload()
lua, addon = load()
lua.execute('''
    assert(addon.initialized and #addon.moduleOrder==6 and #addon.categoryOrder==4)
    assert(addon.Edition.name=='Forever' and addon.developmentPhase=='Forever Beta')
    assert(addon.PartyCooldownSessions==nil and addon.InterruptTracking==nil)
    assert(SLASH_MODETOOLS1=='/modetools' and SLASH_MODETOOLS2=='/mode')
    SlashCmdList.MODETOOLS()
    assert(addon.configWindow.title:GetText()=='Play The Game Tools')
    assert(addon.configWindow.moduleHeader.title:GetText()=='Dashboard')
    assert(addon.configWindow.pages.dashboard.welcomeTexts[1]=='Welcome to Play The Game Tools!')
    for _,id in ipairs(addon.moduleOrder) do
        addon:SelectConfigPage(id)
        assert(addon.configWindow.pages[id],id)
        assert(addon.configWindow.moduleHeader.title:GetText()==addon.modules[id].title,id)
    end
    addon.db.window.x=123; addon.db.window.y=45
    addon:SetModuleEnabled('combatTimer',true)
    assert(addon.modules.combatTimer.enabled)
''')
state = lua.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
restored, _ = load(state)
restored.execute('''
    assert(addon.db.window.x==123 and addon.db.window.y==45)
    assert(addon.modules.combatTimer.enabled)
    addon:SetModuleEnabled('combatTimer',false)
    assert(not addon.modules.combatTimer.enabled)
''')
recruit, _ = load()
recruit.execute('''
    local R=addon.ForeverRecruitment
    ERR_GUILD_INVITE_S='You have invited %s to join your guild.'
    ERR_GUILD_JOIN_S='%s has joined the guild.'
    ERR_GUILD_DECLINE_S='%s declines your invitation to join the guild.'
    function IsInGuild() return true end
    function CanGuildInvite() return true end
    whispers={}
    function SendChatMessage(text,kind,_,target) whispers[#whispers+1]={text,kind,target} end
    local results,sent={},{}
    C_FriendList={SendWho=function(q) sent[#sent+1]=q end, SetWhoToUi=function() end,
        GetNumWhoResults=function() return #results,results.total or #results end,
        GetWhoInfo=function(i) return results[i] end}
    addon:SetModuleEnabled('foreverRecruitment',true)
    R:SetOption('minLevel',10);R:SetOption('maxLevel',19);R:SetOption('chunkSize',5)
    for _,c in ipairs(R.CLASSES) do R.db.classes[c]=(c=='MAGE') end
    R:ResetScan()
    R:ToggleWindow();assert(R.window:IsShown())
    local f=R.window
    assert(#f.classChecks==9 and f.power.selected==true)
    f.classChecks[1].scripts.OnClick();assert(R.db.classes.WARRIOR==true,'window class checkbox')
    f.classChecks[1].scripts.OnClick();assert(R.db.classes.WARRIOR==false)
    f.minInput:SetText('12');f.minInput.scripts.OnEnterPressed(f.minInput);assert(R.db.minLevel==12,'window level input')
    f.minInput:SetText('10');f.minInput.scripts.OnEnterPressed(f.minInput);assert(R.db.minLevel==10)
    f.message:SetText('Join us');f.message.scripts.OnEnterPressed(f.message);assert(R.db.message=='Join us')
    f.whisperCheck.scripts.OnClick();assert(R.db.whisperEnabled==true);f.whisperCheck.scripts.OnClick()
    f.power.scripts.OnClick();assert(not R.enabled);f.power.scripts.OnClick();assert(R.enabled)
    R:Scan()
    assert(sent[1]=='c-"Mage" 10-14' and R:QueueRemaining()==1,sent[1])
    results={{fullName='Alpha',level=12,filename='MAGE',fullGuildName='',area='Elwynn'},
        {fullName='Beta',level=13,filename='MAGE',fullGuildName='Guild',area='Elwynn'},
        {fullName='Gamma',level=40,filename='MAGE',fullGuildName='',area='Elwynn'}}
    results.total=60
    FireEvent('WHO_LIST_UPDATE')
    assert(#R.candidates==1 and R.candidates[1].name=='Alpha')
    assert(R:QueueRemaining()==3 and R.queue[1].min==10 and R.queue[1].max==12,'capped range split')
    Advance(6);R:Scan()
    assert(#R.candidates==0 and #sent==2,'manual scan clears the list')
    results={{fullName='Delta',level=11,filename='MAGE',fullGuildName='',area='Westfall'}}
    FireEvent('WHO_LIST_UPDATE')
    assert(#R.candidates==1)
    R.db.whisperEnabled=true
    R:InviteCandidate(1)
    assert(#R.candidates==0 and R.copyFrame:IsShown() and R.copyFrame.eb:GetText()=='Delta')
    assert(type(R.db.history.Delta)=='number' and R:RecentlyInvited('Delta'))
    FireEvent('CHAT_MSG_SYSTEM','You have invited Delta to join your guild.')
    assert(R.db.records.invited==1 and whispers[1][2]=='WHISPER' and whispers[1][3]=='Delta')
    FireEvent('CHAT_MSG_SYSTEM','Delta has joined the guild.')
    assert(R.db.records.joined==1)
    Advance(6);R:Scan()
    FireEvent('WHO_LIST_UPDATE')
    assert(#R.candidates==0,'recently invited players are skipped')
    results={{fullName='Echo',level=15,filename='MAGE',fullGuildName='',area='Duskwood'}}
    Advance(6);R:Scan();FireEvent('WHO_LIST_UPDATE')
    R:SkipCandidate(1,true)
    assert(R.db.history.Echo=='skip' and R:IsBlacklisted('Echo'))
    R.db.history.Legacy='contacted'
    local text=addon.ProfileManager:Export(addon.ProfileManager.root.defaultProfile)
    assert(text and not addon.ProfileCodec.Decode(text).profile.modules.foreverRecruitment.history,'history is not exported')
    addon:ToggleConfig();addon:SelectConfigPage('foreverRecruitment')
    assert(addon.configWindow.pages.foreverRecruitment==R.page)
''')
ding, _ = load()
ding.execute('''
    local M=addon.ForeverClassTraining
    local requests,level=0,9
    function IsLoggedIn() return true end
    function UnitLevel(unit) assert(unit=='player'); return level end
    function RequestTimePlayed() requests=requests+1 end
    addon:SetModuleEnabled('foreverClassTraining',false)
    addon:SetModuleEnabled('foreverClassTraining',true)
    assert(M.active and requests==1,'one /played request on enable')
    FireEvent('PLAYER_ENTERING_WORLD')
    assert(requests==1,'no repeat /played request per session')
    FireEvent('TIME_PLAYED_MSG',90000,3000)
    Advance(725);level=10;FireEvent('PLAYER_LEVEL_UP',10)
    assert(M:GuildDingText(10)=='Ding 10, that took me 1h 02m 05s',M:GuildDingText(10))
    Advance(61);level=11;FireEvent('PLAYER_LEVEL_UP',11)
    assert(M:GuildDingText(11)=='Ding 11, that took me 1m 01s',M:GuildDingText(11))
    M:SetPopupOption('showLevelTime',false)
    assert(M:GuildDingText(11)=='Ding 11','time omitted when Time to Level is off')
    M:SetPopupOption('showLevelTime',true)
    assert(requests==2,'re-request after Time to Level is turned back on')
    Advance(30);level=12;FireEvent('PLAYER_LEVEL_UP',12)
    assert(M:GuildDingText(12)=='Ding 12','no time without a /played baseline')
''')
legacy = recruit.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
migrated, _ = load(legacy)
migrated.execute('''
    local R=addon.ForeverRecruitment
    assert(type(R.db.history.Legacy)=='number' and R.db.history.Echo=='skip','legacy contacted entries migrate')
    assert(R.db.records.invited==1 and R.db.minLevel==10 and R.db.classes.MAGE==true)
''')
wrong, _ = load(project=1)
wrong.execute('assert(not addon.initialized and ModeToolsDB==nil)')
archive = archive_bytes(files)
assert archive == archive_bytes(files)
with zipfile.ZipFile(io.BytesIO(archive)) as zipped:
    assert sorted(zipped.namelist()) == sorted('ModeTools/' + n for n in files)
    for name, data in files.items():
        assert zipped.read('ModeTools/' + name) == data
assert not any(p in n.split('/') for n in files for p in ('WTF','SavedVariables','.git','tests','tools'))
print(f'PASS {len(order)} Lua chunks, Forever startup, all module pages, title/commands, profile roundtrip, wrong-client block, deterministic ZIP')
