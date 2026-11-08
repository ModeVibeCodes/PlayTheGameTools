"""Lua 5.1 syntax, startup, UI construction and settings restoration; not WoW."""
import io
from pathlib import Path
import sys
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_release import ROOT, payload, archive_bytes
from lupa.lua51 import LuaRuntime


def load(encoded=None, project=18, variable='PTGToolsDB', before=None):
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
        execute(files[name].decode('utf-8-sig'), name, 'PlayTheGameTools', addon)
    lua.globals().addon = addon
    if encoded is not None:
        lua.globals().encoded = encoded
        lua.execute(variable + '=addon.ProfileCodec.Decode(encoded)')
    if before is not None:
        lua.execute(before)
    lua.execute("FireEvent('ADDON_LOADED','PlayTheGameTools'); FireEvent('PLAYER_LOGIN')")
    return lua, addon


files, order, _ = payload()
lua, addon = load()
lua.execute('''
    assert(addon.initialized and #addon.moduleOrder==10 and #addon.categoryOrder==4)
    assert(addon.Edition.name=='Forever' and addon.developmentPhase=='Forever Beta')
    assert(addon.PartyCooldownSessions==nil and addon.InterruptTracking==nil)
    assert(SLASH_PLAYTHEGAMETOOLS1=='/ptg' and SLASH_PLAYTHEGAMETOOLS2==nil)
    SlashCmdList.PLAYTHEGAMETOOLS()
    assert(addon.configWindow.title:GetText()=='Play The Game Tools')
    assert(addon.configWindow.moduleHeader.title:GetText()=='Dashboard')
    -- Opening redraws text set while a shared font may still be loading
    -- (mock timers fire immediately: two passes, each clearing and re-setting).
    local nav=addon.configWindow.navigationButtons.dashboard.label
    assert(nav:GetText()=='Dashboard' and nav.textWrites>=5,'sidebar text redrawn')
    assert(addon.configWindow.title:GetText()=='Play The Game Tools' and addon.configWindow.title.textWrites>=5,'title redrawn')
    local field=CreateFrame('EditBox',nil,UIParent);field:SetText('typed')
    local changes=0;field:SetScript('OnTextChanged',function() changes=changes+1 end)
    addon.Media:BindInterfaceFont(field,GameFontHighlight)
    assert(addon.Media:RedrawInterfaceText() and field:GetText()=='typed' and changes==0,'edit boxes untouched')
    local writes=nav.textWrites;testCombat=true
    assert(addon.Media:RedrawInterfaceText()==false and nav.textWrites==writes,'no redraw in combat')
    testCombat=false;addon.Media:UnbindInterfaceFont(field)
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
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(state)
restored.execute('''
    assert(addon.db.window.x==123 and addon.db.window.y==45)
    assert(addon.modules.combatTimer.enabled)
    addon:SetModuleEnabled('combatTimer',false)
    assert(not addon.modules.combatTimer.enabled)
    -- Interface theme: Modern by default; a choice is saved and needs a reload.
    local T=addon.InterfaceTheme
    assert(addon.db.window.theme=='modern' and T.id=='modern' and not T.blizzardArt)
    SlashCmdList.PLAYTHEGAMETOOLS()
    local themes=addon.configWindow.pages.dashboard.themeButtons
    assert(#themes==2 and themes[1].selected and not themes[2].selected,'theme choice')
    -- Modern contrast: findable control edges, readable muted copy, and
    -- surfaces that step up from the recessed sidebar to hover.
    local function lum(c)
        local function ch(v) return v<=0.03928 and v/12.92 or ((v+0.055)/1.055)^2.4 end
        return 0.2126*ch(c[1])+0.7152*ch(c[2])+0.0722*ch(c[3])
    end
    local function ratio(a,b) local x,y=lum(a),lum(b); if x<y then x,y=y,x end; return (x+0.05)/(y+0.05) end
    assert(ratio(T.lineStrong,T.background)>=3 and ratio(T.lineStrong,T.sidebar)>=3,'control edges findable')
    assert(ratio(T.text,T.background)>=12 and ratio(T.muted,T.background)>=4.5 and ratio(T.muted,T.surface)>=4.5,'readable text')
    assert(lum(T.sidebar)<lum(T.background) and lum(T.background)<lum(T.surface) and lum(T.surface)<lum(T.hover),'surface steps')
    local resting,chosen=themes[2].outline.edges[1].color,themes[1].outline.edges[1].color
    assert(resting[1]==T.lineStrong[1] and resting[4]==1,'unselected choice keeps a visible edge')
    assert(chosen[2]==T.primary[2] and chosen[4]==1,'selected choice has a full accent edge')
    assert(addon.configWindow.navigationButtons.dashboard.selectionEdge.width==3,'selected navigation marker')
    themes[2].scripts.OnClick()
    assert(addon.db.window.theme=='blizzard' and addon.ReloadManager.requests.interfaceTheme,'theme reload request')
    assert(themes[2].selected and T.id=='modern','theme applies only after reload')
    themes[1].scripts.OnClick()
    assert(addon.db.window.theme=='modern' and not addon.ReloadManager.requests.interfaceTheme)
    themes[2].scripts.OnClick()
''')
themed, _ = load(restored.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
themed.execute('''
    local T,W=addon.InterfaceTheme,addon.ConfigWidgets
    local ART=W.BlizzardArt
    assert(T.id=='blizzard' and T.blizzardArt and T.heading[1]>T.heading[3]+0.5,'gold headings')
    assert(T.text[1]<1 and T.text[2]<1 and T.panel[4]==1,'soft body text, opaque popups')
    SlashCmdList.PLAYTHEGAMETOOLS()
    local window=addon.configWindow
    assert(window.blizzardBackdrop=='dialog' and window.backdrop.edgeFile==ART.dialogBorder and window.backdrop.bgFile==nil)
    assert(window.canvas.shown~=false and window.canvas.color[4]==1,'opaque canvas under the dialog border')
    for _,id in ipairs(addon.moduleOrder) do addon:SelectConfigPage(id); assert(window.pages[id],id) end
    addon:SelectConfigPage('dashboard')
    assert(window.closeButton.blizzardArt.middle.texture==ART.buttonUp)
    window.closeButton:SetSelected(true)
    assert(window.closeButton.blizzardArt.middle.texture==ART.buttonDown)
    window.closeButton:SetEnabled(false)
    assert(window.closeButton.blizzardArt.left.texture==ART.buttonDisabled)
    window.closeButton:SetEnabled(true);window.closeButton:SetSelected(false)
    local toggle=window.moduleHeader.toggle
    assert(toggle.fill.texture==ART.checkbox and toggle.knob.texture==ART.check)
    assert(window.navigationButtons.dashboard.blizzardHighlight.shown)
    -- Stock game font, drop shadows, and segmented choices without push-button art.
    assert(window.title.font[1]==GameFontNormalLarge.font[1] and window.title.shadowOffset[1]==1,'stock font with shadow')
    assert(window.pages.dashboard.themeButtons[1].blizzardArt==nil,'choices stay flat')
    local themes=window.pages.dashboard.themeButtons
    assert(themes[2].selected and not addon.ReloadManager.requests.interfaceTheme)
''')
missing, _ = load(themed.eval('addon.ProfileCodec.Encode(PTGToolsDB)'))
missing.execute('''
    -- Refused stock files keep the flat drawing.
    local ART=addon.ConfigWidgets.BlizzardArt
    testMissingTextures={[ART.buttonUp]=true,[ART.checkbox]=true,[ART.input]=true,[ART.sliderThumb]=true}
    SlashCmdList.PLAYTHEGAMETOOLS()
    for _,id in ipairs(addon.moduleOrder) do addon:SelectConfigPage(id) end
    local window=addon.configWindow
    assert(window.closeButton.blizzardArt==nil and window.closeButton.outline.edges[1].shown~=false)
    assert(window.moduleHeader.toggle.switchOutline.edges and window.moduleHeader.toggle.knob.texture==nil)
    testMissingTextures=nil
    -- An unknown saved id renders Modern and is never rewritten.
    addon.db.window.theme='future'
    assert(addon:ApplyInterfaceTheme(addon.db.window.theme)=='modern' and addon.db.window.theme=='future')
''')
adopted, _ = load(state, variable='ModeToolsDB')
adopted.execute('''
    assert(ModeToolsDB==nil and type(PTGToolsDB)=='table','pre-rename settings adopted')
    assert(addon.db.window.x==123 and addon.db.window.y==45)
    assert(addon.modules.combatTimer.enabled)
''')
# The retired standalone recruiter shared this folder name; its stray global is ignored.
foreign, _ = load(state, variable='ModeToolsDB',
                  before="PlayTheGameToolsDB={reinviteDays=7,stats={joined=1},invited={}}")
foreign.execute('''
    assert(ModeToolsDB==nil and addon.db.window.x==123 and addon.modules.combatTimer.enabled)
    assert(PlayTheGameToolsDB.reinviteDays==7 and PlayTheGameToolsDB.window==nil,'recruiter table untouched')
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
    assert(f.message.multiLine==true and f.whisperCheck==nil,'multi-line message box, no after-invite option')
    f.message:SetText('Join\\nus |now ');f.message.scripts.OnEnterPressed(f.message);assert(R.db.message=='Join us now',R.db.message)
    f.message:SetText('Join us');f.message.scripts.OnEnterPressed(f.message)
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
    R:InviteCandidate(1)
    assert(#R.candidates==0 and R.copyFrame:IsShown() and R.copyFrame.eb:GetText()=='Delta')
    assert(type(R.db.history.Delta)=='number' and R:RecentlyInvited('Delta'))
    FireEvent('CHAT_MSG_SYSTEM','You have invited Delta to join your guild.')
    assert(R.db.records.invited==1 and #whispers==0,'a confirmed invite sends no whisper')
    FireEvent('CHAT_MSG_SYSTEM','Delta has joined the guild.')
    assert(R.db.records.joined==1)
    Advance(6);R:Scan()
    FireEvent('WHO_LIST_UPDATE')
    assert(#R.candidates==0,'recently invited players are skipped')
    results={{fullName='Foxtrot',level=16,filename='MAGE',fullGuildName='',area='Duskwood'},
        {fullName='Golf',level=17,filename='MAGE',fullGuildName='',area='Duskwood'}}
    Advance(6);R:Scan();FireEvent('WHO_LIST_UPDATE')
    assert(#R.candidates==2 and f.rows[2].whisper)
    -- Unsaved box text is what gets sent; the row leaves the list without an invite.
    f.message:SetFocus();f.message:SetText('Fresh text')
    f.rows[2].whisper.scripts.OnClick(f.rows[2].whisper)
    f.message:ClearFocus()
    assert(#whispers==1 and whispers[1][1]=='Fresh text' and whispers[1][2]=='WHISPER' and whispers[1][3]=='Golf')
    assert(#R.candidates==1 and R.candidates[1].name=='Foxtrot' and type(R.db.history.Golf)=='number')
    assert(R.db.records.invited==1 and not R.awaitingConfirm.Golf,'a whisper is not an invite')
    local long=string.rep('word ',100)..'end'
    assert(R:SetOption('message',long),'messages longer than one whisper are accepted')
    local parts=R.SplitWhisper(long)
    assert(#parts==2 and table.concat(parts,' ')==long and #parts[1]<=255 and #parts[2]<=255,'split at spaces')
    local unbroken=R.SplitWhisper(string.rep('\\195\\169',200))
    assert(#unbroken==2 and #unbroken[1]==254 and #unbroken[2]==146,'unbroken text keeps UTF-8 characters whole')
    R:WhisperCandidate(1)
    assert(#whispers==3 and whispers[2][3]=='Foxtrot' and whispers[3][3]=='Foxtrot','long message sent in parts')
    R:SetOption('message','')
    results={{fullName='Hotel',level=18,filename='MAGE',fullGuildName='',area='Duskwood'}}
    Advance(6);R:Scan();FireEvent('WHO_LIST_UPDATE')
    R:WhisperCandidate(1)
    assert(#whispers==3 and #R.candidates==1,'an empty message sends nothing and keeps the player')
    R.db.whisperEnabled=true
    results={{fullName='Echo',level=15,filename='MAGE',fullGuildName='',area='Duskwood'}}
    Advance(6);R:Scan();FireEvent('WHO_LIST_UPDATE')
    R:SkipCandidate(1,true)
    assert(R.db.history.Echo=='skip' and R:IsBlacklisted('Echo'))
    R.db.history.Legacy='contacted'
    local text=addon.ProfileManager:Export(addon.ProfileManager.root.defaultProfile)
    assert(text and not addon.ProfileCodec.Decode(text).profile.modules.foreverRecruitment.history,'history is not exported')
    addon:ToggleConfig();addon:SelectConfigPage('foreverRecruitment')
    assert(addon.configWindow.pages.foreverRecruitment==R.page)
    -- Search, class and whisper settings live only in the Recruiter window.
    for _,entry in ipairs(R.page.searchEntries) do
        assert(entry.label~='Minimum Level' and entry.label~='Whisper After Invite' and entry.label~='Search','no duplicated recruiter settings')
        assert(entry.label~='Recruitment Status' and entry.label~='Statistics' and entry.label~='How It Works' and entry.label~='Invites' and entry.label~='Re-invite After (days)','page keeps only Recruiter and History')
    end
    local found=addon:SearchSettings('whisper')
    assert(found[1] and found[1].module==R,'whisper search still routes to Recruitment')
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
legacy = recruit.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
migrated, _ = load(legacy)
migrated.execute('''
    local R=addon.ForeverRecruitment
    assert(type(R.db.history.Legacy)=='number' and R.db.history.Echo=='skip','legacy contacted entries migrate')
    assert(R.db.records.invited==1 and R.db.minLevel==10 and R.db.classes.MAGE==true)
    assert(R.db.whisperEnabled==nil,'retired after-invite option is dropped')
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
    assert(f:IsShown() and f.title:GetText()=='Boar' and not f.empty:IsShown())
    assert(#M.entries==2 and M.entries[1].name=='Fixture' and M.entries[2].name=='Ally','pets hidden by default')
    assert(f.rows[1].percentText:GetText()=='80%' and f.rows[2]:IsShown() and not f.rows[3]:IsShown())
    assert(f.rows[1].edge:IsShown() and not f.rows[2].edge:IsShown(),'your own row is marked')
    assert(f.hint:IsShown(),'drag hint while unlocked')
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
    assert(f.title:GetText()=='Boar','secret hostility is treated as possibly hostile')
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
    assert(f.rows[3].warn==true and f.rows[3].edge:IsShown(),'you are close to pulling')
    UnitDetailedThreatSituation=detailed;UnitIsUnit=nil;units.targettarget=nil;units.player[4]=true
    units.target=nil;FireEvent('PLAYER_TARGET_CHANGED')
    assert(#M.entries==0 and f.title:GetText()=='Threat' and not f.rows[1]:IsShown())
    assert(f.empty:IsShown() and f.empty:GetText()==M.MESSAGES.noTarget)
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
saved = threat.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
reloaded, _ = load(saved)
reloaded.execute('''
    local M=addon.ThreatMeter
    assert(M.db.locked==true and M.db.hideOutOfCombat==true and M.db.showPets==false)
    UnitDetailedThreatSituation=nil
    addon:SetModuleEnabled('threatMeter',true)
    assert(not M.frame:IsShown(),'locked and hidden out of combat')
    M:SetOption('locked',false)
    assert(M.frame:IsShown() and M.frame.empty:GetText()==M.MESSAGES.unavailable)
''')
wrong, _ = load(project=1)
wrong.execute('assert(not addon.initialized and PTGToolsDB==nil)')
archive = archive_bytes(files)
assert archive == archive_bytes(files)
with zipfile.ZipFile(io.BytesIO(archive)) as zipped:
    assert sorted(zipped.namelist()) == sorted('PlayTheGameTools/' + n for n in files)
    for name, data in files.items():
        assert zipped.read('PlayTheGameTools/' + name) == data
assert not any(p in n.split('/') for n in files for p in ('WTF','SavedVariables','.git','tests','tools'))
print(f'PASS {len(order)} Lua chunks, Forever startup, all module pages, title/commands, profile roundtrip, pre-rename settings adoption, wrong-client block, deterministic ZIP')
