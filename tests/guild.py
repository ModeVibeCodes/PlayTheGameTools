"""Guild: Guild Roster + Guild Recruitment merged into one module and one window; not WoW.

Covers the one-time switch adoption, old saved tables and profiles, the settings
page and its header button, the Roster/Recruit tabs, the History menu, the Quick
Actions entry, old search names and the recruit guards. Mock only.
"""
from smoke import load

COMMON = r'''
    G,R,Roster=addon.ForeverGuild,addon.ForeverRecruitment,addon.ForeverGuildRoster
    function Click(frame) frame.scripts.OnClick(frame) end
'''


def started(db):
    lua, _ = load(before='PTGToolsDB=' + db)
    lua.execute(COMMON)
    return lua


# --- One module under the Recruitment ID; the Roster ID is retired. ---------
lua = started('nil')
lua.execute(r'''
    assert(G==R and addon.modules.foreverRecruitment==G and addon.modules.foreverGuildRoster==nil,'one Guild module, foreverRecruitment ID')
    assert(G.title=='Guild' and G.category=='guildTools' and G.defaultEnabled==false and not G.enabled)
    assert(addon.retiredModules.foreverGuildRoster=='foreverRecruitment')
    local listed=0;for _,id in ipairs(addon:ListedConfigPages()) do if id=='foreverRecruitment' then listed=listed+1 end end
    assert(listed==1,'one sidebar entry')
    assert(G.db.rosterAdopted==true and addon.db.modules.foreverGuildRoster==nil,'nothing to adopt on a fresh install')
''')

# --- The Guild switch is on if either old module was on. ---------------------
cases = {
    "{modules={foreverGuildRoster={enabled=true}}}": True,
    "{modules={foreverRecruitment={enabled=true}}}": True,
    "{modules={foreverGuildRoster={enabled=true},foreverRecruitment={enabled=false}}}": True,
    "{modules={foreverGuildRoster={enabled=false},foreverRecruitment={enabled=false}}}": False,
    "{modules={foreverGuildRoster={enabled=false}}}": False,
}
for db, expected in cases.items():
    case = started(db)
    case.globals().expected = expected
    case.globals().hadRoster = 'foreverGuildRoster' in db
    case.execute(r'''
        assert(G.enabled==expected and G.db.enabled==expected and G.active==(expected or nil),'adopted switch')
        assert(G.db.rosterAdopted==true)
        assert((type(addon.db.modules.foreverGuildRoster)=='table')==hadRoster,'old Roster table kept, none invented')
        if expected then assert(Roster.active==true) end
    ''')

# --- Recruit data stays where it is; turning Guild off later sticks. --------
legacy = ("{modules={foreverGuildRoster={enabled=true},foreverRecruitment={enabled=false,minLevel=20,maxLevel=40,"
          "chunkSize=3,message='Hi there',reinviteDays=7,classes={MAGE=true,WARRIOR=false},"
          "history={Alpha='skip',Beta=4000000000},records={invited=4,joined=2,declined=1}}}}")
first = started(legacy)
first.execute(r'''
    assert(G.enabled,'roster switch adopted')
    local db=G.db
    assert(db.minLevel==20 and db.maxLevel==40 and db.chunkSize==3 and db.message=='Hi there','level picks kept')
    assert(db.classes.MAGE==true and db.classes.WARRIOR==false,'class picks kept')
    assert(db.history.Alpha=='skip' and db.history.Beta==4000000000,'invite and never-invite history kept')
    assert(db.records.invited==4 and db.records.joined==2 and db.records.declined==1,'statistics kept')
    assert(addon.db.modules.foreverGuildRoster.enabled==true,'old Roster table only read')
    addon:SetModuleEnabled('foreverRecruitment',false)
''')
saved = first.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
second, _ = load(saved)
second.execute(COMMON)
second.execute(r'''
    assert(not G.enabled and G.db.rosterAdopted==true,'adoption runs once: Guild stays off')
    assert(addon.db.modules.foreverGuildRoster.enabled==true,'old Roster table untouched')
    assert(G.db.history.Alpha=='skip' and G.db.records.invited==4 and G.db.minLevel==20)
''')

# --- Profiles exported before the merge still import. -----------------------
lua = started('nil')
lua.execute(r'''
    local C,P=addon.ProfileCodec,addon.ProfileManager
    local old=C.Encode({version=1,name='Before Guild',profile={schemaVersion=1,
        modules={foreverGuildRoster={enabled=true},foreverRecruitment={enabled=false,minLevel=15}}}})
    local ok,reason,name=P:Import(old)
    assert(ok,reason)
    local profile=P.root.profiles[name]
    assert(profile.modules.foreverGuildRoster.enabled==true and profile.modules.foreverRecruitment.minLevel==15,'both old tables kept')
    assert(profile.modules.foreverRecruitment.rosterAdopted==nil,'adopted when that profile is next loaded')
    local bad=C.Encode({version=1,name='Bad',profile={schemaVersion=1,modules={noSuchModule={enabled=true}}}})
    assert(not P:Import(bad),'unknown module IDs are still refused')
    local text=P:Export(P.activeName)
    local exported=C.Decode(text).profile.modules
    assert(exported.foreverRecruitment and exported.foreverGuildRoster==nil,'exports carry the Guild table only')
''')

# --- Settings page: a note and Open Guild in the header. --------------------
lua = started('nil')
lua.execute(r'''
    addon:ToggleConfig();addon:SelectConfigPage('foreverRecruitment')
    local window=addon.configWindow;local page=G.page
    assert(window.pages.foreverRecruitment==page and window.moduleHeader.title:GetText()=='Guild')
    assert(window.moduleHeader.description:GetText()=='Search your guild, and find guildless players to invite.')
    assert(page.note:GetText()==G.PAGE_NOTE and #page.sections==0,'no settings sections on the page')
    -- The shared page-header button (openLabel), as Dungeon Loot and Class Training use.
    local open=window.moduleHeader.openButton
    assert(G.openLabel=='Open Guild' and page.openButton==nil and open:IsShown() and open.label:GetText()=='Open Guild')
    local anchor=open.points[#open.points]
    assert(anchor[1]=='RIGHT' and anchor[2]==window.moduleHeader.toggle and anchor[3]=='LEFT','Open Guild sits left of the switch')
    assert(open.enabled==false,'Open Guild waits for the switch')
    Click(open);assert(not G.window or not G.window:IsShown(),'disabled button opens nothing')
    Click(window.moduleHeader.toggle)
    assert(G.enabled and open.enabled==true)
    for _,entry in ipairs(page.searchEntries) do
        assert(entry.label~='Clear Invite History' and entry.label~='Recruiter Window' and entry.label~='Level range','window-only controls are not on the page')
    end
    Click(open)
    assert(G.window:IsShown() and not window:IsShown() and G.tab=='roster','Open Guild opens the window on Roster')

    -- Old names find Guild first.
    addon:ToggleConfig()
    for _,query in ipairs({'roster','guild roster','recruitment','guild recruitment','recruiter','whisper','levels per search','class summary'}) do
        local found=addon:SearchSettings(query)
        assert(found[1] and found[1].module==G,'search finds Guild: '..query)
    end
''')

# --- Window: Roster and Recruit tabs, History menu, /ptgr. ------------------
lua = started('nil')
lua.execute(r'''
    addon:SetModuleEnabled('foreverRecruitment',true)
    G:OpenWindow()
    local f=G.window
    assert(f:GetName()=='PlayTheGameToolsRecruitmentFrame' and f.title:GetText()=='Guild','old frame name kept')
    assert(f.tabs.roster.label:GetText()=='Roster' and f.tabs.recruit.label:GetText()=='Recruit')
    assert(G.tab=='roster' and f.tabs.roster.selected and not f.tabs.recruit.selected and f.panels.roster:IsShown())
    assert(Roster.viewShown and not f.panels.recruit:IsShown())
    Click(f.tabs.recruit)
    assert(G.tab=='recruit' and f.panels.recruit:IsShown() and not f.panels.roster:IsShown() and not Roster.viewShown)
    -- Level range, levels per search and class picks sit on the Recruit tab with the results.
    assert(f.classChecks[1]:GetParent()==f.panels.recruit and f.scan:GetParent()==f.panels.recruit)
    assert(f.content:GetParent():GetParent():GetParent()==f.panels.recruit,'results list on the Recruit tab')
    assert(f.power:GetParent()==f,'one switch in the window header')

    -- One History menu holds the three clear/reset actions.
    G.db.history={Alpha='skip',Beta=4000000000};G.db.records.invited=3;G.db.records.joined=1
    local menu=f.historyMenu
    assert(f.history.label:GetText()=='History' and f.history:GetParent()==f.panels.recruit and not menu:IsShown())
    local labels={};for i,item in ipairs(menu.items) do labels[i]=item.label:GetText() end
    assert(table.concat(labels,'|')=='Clear Invite History|Clear Never-Invite List|Reset Statistics',table.concat(labels,'|'))
    Click(f.history);assert(menu:IsShown())
    Click(menu.items[1]);assert(not menu:IsShown() and G.db.history.Alpha=='skip' and G.db.history.Beta==nil,'invite history cleared, never-invite kept')
    Click(f.history);Click(menu.items[2]);assert(next(G.db.history)==nil,'never-invite list cleared')
    Click(f.history);Click(menu.items[3]);assert(G.db.records.invited==0 and G.db.records.joined==0,'statistics reset')
    assert(f.stats:GetText()=='Invited: 0   Joined: 0   Declined: 0')
    Click(f.history);f.history:Hide();assert(not menu:IsShown(),'the menu closes with its tab')
    f.history:Show()

    -- The tab is kept for the session; /ptgr opens Recruit.
    f:Hide();G:OpenWindow();assert(G.tab=='recruit','last tab reopens')
    f:Hide();G:SelectTab('roster');f:Hide()
    SlashCmdList.PLAYTHEGAMETOOLSRECRUIT()
    assert(f:IsShown() and G.tab=='recruit','/ptgr opens the Recruit tab')
    SlashCmdList.PLAYTHEGAMETOOLSRECRUIT();assert(not f:IsShown(),'/ptgr again closes it')
    G:OpenWindow('roster');SlashCmdList.PLAYTHEGAMETOOLSRECRUIT()
    assert(f:IsShown() and G.tab=='recruit','/ptgr switches an open window to Recruit')
    G:ToggleWindow();assert(not f:IsShown())

    -- The window switch turns the whole module off, roster included.
    G:OpenWindow('roster');assert(Roster.watching)
    Click(f.power);assert(not G.enabled and not Roster.active and not Roster.watching and Roster.status==Roster.STATUS.off)
    Click(f.power);assert(G.enabled and Roster.active and Roster.watching)
''')

# --- Quick Actions: one Guild entry while the module is on. -----------------
lua = started('nil')
lua.execute(r'''
    local Q=addon.QuickActions
    assert(not Q.actions.recruitment,'off: no ring entry')
    addon:SetModuleEnabled('foreverRecruitment',true)
    local action=Q.actions.recruitment
    assert(action and action.available and G.shortcut:IsShown())
    local tips={}
    GameTooltip={SetOwner=function() end,SetText=function(_,text) tips[#tips+1]=text end,Show=function() end,Hide=function() end,
        AddLine=function(_,text) tips[#tips+1]=text end}
    G.shortcut.scripts.OnEnter(G.shortcut)
    assert(tips[1]=='Guild' and tips[2]=='Click to open or close the Guild window.',table.concat(tips,'|'))
    local count=0;for id in pairs(Q.actions) do if id=='recruitment' or id=='roster' or id=='guild' then count=count+1 end end
    assert(count==1,'one Guild entry')
    Click(G.shortcut);assert(G.window:IsShown())
    Click(G.shortcut);assert(not G.window:IsShown())
    addon:SetModuleEnabled('foreverRecruitment',false)
    assert(not action.available and not G.shortcut:IsShown(),'off: out of the ring')
''')

# --- Recruit guards are unchanged: switch, combat, Who cooldown. ------------
lua = started('nil')
lua.execute(r'''
    function IsInGuild() return true end
    function CanGuildInvite() return true end
    local sent,whispers={}, {}
    function SendChatMessage(text,kind,_,target) whispers[#whispers+1]=target end
    local results={}
    C_FriendList={SendWho=function(q) sent[#sent+1]=q end,SetWhoToUi=function() end,
        GetNumWhoResults=function() return #results,#results end,GetWhoInfo=function(i) return results[i] end}
    R:Scan();assert(#sent==0 and R.status=='Turn Guild on first.','off: no Who search')
    addon:SetModuleEnabled('foreverRecruitment',true)
    for _,c in ipairs(R.CLASSES) do R.db.classes[c]=(c=='MAGE') end;R:ResetScan()
    testLockdown=true
    R:Scan();assert(#sent==0 and R.status=='Unavailable in combat.','combat: no Who search')
    testLockdown=false
    R:Scan();assert(#sent==1)
    R:Scan();assert(#sent==1 and R.status:find('before the next scan',1,true),'Who cooldown kept')
    results={{fullName='Kilo',level=20,filename='MAGE',fullGuildName='',area='Elwynn'},
        {fullName='Lima',level=21,filename='MAGE',fullGuildName='',area='Elwynn'}}
    FireEvent('WHO_LIST_UPDATE');assert(#R.candidates==2)
    testLockdown=true
    R:WhisperCandidate(1);R:InviteCandidate(1)
    assert(#whispers==0 and #R.candidates==2 and not (R.copyFrame and R.copyFrame:IsShown()),'combat: no whisper or invite')
    testLockdown=false
    function IsInGuild() return false end
    R:InviteCandidate(1);assert(#R.candidates==2 and R.status=='You are not in a guild.')
''')
print('PASS guild: one module (foreverRecruitment ID), one-time switch adoption, old tables/profiles kept, page header button, tabs, History menu, ring entry, old search names, recruit guards')
