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
    assert(addon.initialized and #addon.moduleOrder==7 and #addon.categoryOrder==4)
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
legacy = recruit.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
migrated, _ = load(legacy)
migrated.execute('''
    local R=addon.ForeverRecruitment
    assert(type(R.db.history.Legacy)=='number' and R.db.history.Echo=='skip','legacy contacted entries migrate')
    assert(R.db.records.invited==1 and R.db.minLevel==10 and R.db.classes.MAGE==true)
''')
threat, _ = load()
threat.execute('''
    local M=addon.ThreatMeter
    assert(not M.enabled and M.db.showPets==false,'off by default, pets off by default')
    local units={player={'Fixture','WARRIOR',80,true},pet={'Wolf',nil,95},
        party1={'Ally','MAGE',60},partypet1={'Imp',nil,30},target={'Boar'}}
    function UnitExists(u) return units[u]~=nil end
    function UnitGUID(u) return 'GUID-'..u end
    function UnitName(u) return units[u] and units[u][1] end
    function UnitClass(u) local x=units[u];return x and x[1],x and x[2] end
    function UnitCanAttack(_,u) return u=='target' end
    function UnitIsDeadOrGhost() return false end
    function IsInRaid() return false end
    function GetNumSubgroupMembers() return 1 end
    function UnitDetailedThreatSituation(u,mob)
        assert(mob=='target');local x=units[u]
        if x and x[3] then return x[4]==true,x[4] and 3 or 0,x[3],x[3],x[3]*100 end
    end
    RAID_CLASS_COLORS={WARRIOR={r=0.78,g=0.61,b=0.43},MAGE={r=0.41,g=0.8,b=0.94}}
    addon:SetModuleEnabled('threatMeter',true)
    local f=M.frame
    assert(f:IsShown() and f.title:GetText()=='Threat: Boar')
    assert(#M.entries==2 and M.entries[1].name=='Fixture' and M.entries[2].name=='Ally','pets hidden by default')
    assert(f.rows[1].percentText:GetText()=='80%' and f.rows[2]:IsShown() and not f.rows[3]:IsShown())
    M:SetOption('showPets',true)
    assert(#M.entries==4 and M.entries[1].name=='Fixture' and M.entries[2].name=='Wolf (Fixture)','tanking first, then highest')
    assert(M.entries[4].name=='Imp (Ally)')
    -- Secret fields fall back to threat status; secrets are never compared.
    local secret={secret=true}
    local detailed=UnitDetailedThreatSituation
    UnitDetailedThreatSituation=function(u,mob)
        if u=='party1' then return secret,secret,secret,secret,secret end
        if u=='partypet1' then return secret,secret,secret,secret,secret end
        return detailed(u,mob)
    end
    function UnitThreatSituation(u) if u=='party1' then return 1 end;if u=='partypet1' then return secret end end
    function UnitCanAttack() return secret end
    M:Update()
    assert(f.title:GetText()=='Threat: Boar','secret hostility is treated as possibly hostile')
    local byName={};for i,e in ipairs(M.entries) do byName[e.name]={i,e} end
    assert(select(2,M.Display(byName.Ally[2]))=='High' and byName.Ally[1]==2,'status fallback ranks above lower threat')
    assert(select(2,M.Display(byName['Imp (Ally)'][2]))=='Hidden')
    UnitDetailedThreatSituation=detailed;UnitThreatSituation=nil
    function UnitCanAttack(_,u) return u=='target' end
    -- Raw threat orders rows; the mob's target holds aggro.
    units.player[4]=false
    UnitDetailedThreatSituation=function(u,mob)
        if u=='party1' then return false,1,90,120,5000 end
        if u=='player' then return false,1,95,100,4000 end
        return detailed(u,mob)
    end
    units.targettarget={'Wolf'}
    function UnitIsUnit(a,b) return a=='targettarget' and b=='pet' end
    M:Update()
    assert(M.entries[1].name=='Wolf (Fixture)' and M.entries[1].aggro,'mob target first')
    assert(M.entries[2].name=='Ally' and M.entries[3].name=='Fixture','raw threat order')
    UnitDetailedThreatSituation=detailed;UnitIsUnit=nil;units.targettarget=nil;units.player[4]=true
    units.target=nil;FireEvent('PLAYER_TARGET_CHANGED')
    assert(#M.entries==0 and f.title:GetText()=='Threat: no target' and not f.rows[1]:IsShown())
    M:SetOption('locked',true);M:SetOption('hideOutOfCombat',true)
    assert(not f:IsShown(),'hidden out of combat when locked')
    testCombat=true;units.target={'Boar'};FireEvent('PLAYER_REGEN_DISABLED')
    assert(f:IsShown() and #M.entries==4)
    testCombat=false
    addon:ToggleConfig();addon:SelectConfigPage('threatMeter')
    assert(addon.configWindow.pages.threatMeter==M.page)
    M.page.threatControls.showPets.frame.scripts.OnClick();assert(M.db.showPets==false)
    addon:SetModuleEnabled('threatMeter',false)
    assert(not f:IsShown())
''')
saved = threat.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
reloaded, _ = load(saved)
reloaded.execute('''
    local M=addon.ThreatMeter
    assert(M.db.locked==true and M.db.hideOutOfCombat==true and M.db.showPets==false)
    UnitDetailedThreatSituation=nil
    addon:SetModuleEnabled('threatMeter',true)
    assert(not M.frame:IsShown(),'locked and hidden out of combat')
    M:SetOption('locked',false)
    assert(M.frame:IsShown() and M.frame.title:GetText()=='Threat: unavailable on this client')
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
