"""Guild Tools -> Roster: members grouped by class and per-class totals; not WoW."""
from smoke import load

lua, _ = load()
lua.execute(r'''
    R=addon.ForeverGuildRoster
    local CLASS={[1]='WARRIOR',[8]='MAGE',[11]='DRUID'}
    C_CreatureInfo={GetClassInfo=function(id) return CLASS[id] and {classFile=CLASS[id],className=CLASS[id],classID=id} or nil end}
    inGuild=true;locked=false;requests=0;reads=0
    members={{name='zed',classID=8},{name='Alice',classID=8},{name='Bob',classID=1},{name='Noclass'}}
    function IsInGuild() return inGuild end
    C_GuildInfo=C_GuildInfo or {}
    C_GuildInfo.GuildRoster=function() requests=requests+1 end
    C_ChatInfo=C_ChatInfo or {}
    C_ChatInfo.InChatMessagingLockdown=function() return locked end
    C_Club={GetGuildClubId=function() return 77 end,
        GetClubMembers=function(id) assert(id==77);reads=reads+1;local ids={};for i=1,#members do ids[i]=i end;return ids end,
        GetMemberInfo=function(id,i) assert(id==77);return members[i] end}

    function Count(classFile)
        for _,cell in ipairs(page.summaryCells) do if cell.classFile==classFile then return cell.count:GetText() end end
    end
    function Visible()
        local out={}
        for _,label in ipairs(page.nameLabels) do if label:IsShown() then out[#out+1]=label:GetText() end end
        return table.concat(out,',')
    end
    function Open()
        addon:ToggleConfig();addon:SelectConfigPage('foreverGuildRoster')
        page=R.page
    end
    function Watching()
        local n=0;if R.events then for _ in pairs(R.events.events) do n=n+1 end end;return n
    end
''')

lua.execute(r'''
    -- Off by default, and silent until turned on.
    assert(R.category=='guildTools' and R.defaultEnabled==false and not R.enabled)
    Open()
    assert(addon.configWindow.pages.foreverGuildRoster==page)
    assert(requests==0 and reads==0 and Watching()==0,'disabled page reads nothing')
    assert(page.statusLabel:GetText():find('switch',1,true) and page.totalLabel:GetText()=='Total Members: 0')

    -- Every member appears once, under their class, alphabetically.
    addon:SetModuleEnabled('foreverGuildRoster',true)
    assert(requests==1 and reads==1 and Watching()>0,'roster requested once while visible')
    assert(R.status==nil and page.totalLabel:GetText()=='Total Members: 4')
    assert(Visible()=='Bob,Alice,zed,Noclass','warrior before mage before unknown; names sorted: '..Visible())
    assert(page.classHeadings.MAGE:GetText()=='Mage (2)' and page.classHeadings.WARRIOR:GetText()=='Warrior (1)')
    assert(page.classHeadings.UNKNOWN:GetText()=='Unknown (1)')
    assert(page.classHeadings.PRIEST==nil,'empty classes get no list heading')

    -- The summary covers all nine classes, including zeros.
    assert(Count('MAGE')==2 and Count('WARRIOR')==1 and Count('PRIEST')==0 and Count('DRUID')==0)
    assert(Count('UNKNOWN')==1)
    assert(#page.summaryCells==10 and page.summaryCells[10].name:IsShown(),'unknown shows when used')
    members[4]=nil;R:Rescan()
    assert(Count('UNKNOWN')==0 and not page.summaryCells[10].name:IsShown(),'unknown hides when unused')
    assert(not page.classHeadings.UNKNOWN:IsShown() and Visible()=='Bob,Alice,zed')

    -- Roster events coalesce into a single read.
    local queued={};local realAfter=C_Timer.After
    C_Timer.After=function(_,fn) queued[#queued+1]=fn end
    reads=0
    FireEvent('GUILD_ROSTER_UPDATE',true);FireEvent('CLUB_MEMBER_UPDATED',77,1);FireEvent('CLUB_MEMBER_ADDED',77,5)
    assert(#queued==1 and reads==0,'burst schedules one read')
    members[4]={name='Cara',classID=11};queued[1]()
    assert(reads==1 and Count('DRUID')==1 and page.totalLabel:GetText()=='Total Members: 4')
    C_Timer.After=realAfter

    -- A long list wraps to the available width without overlapping names.
    local row=page.rows[#page.rows]
    row:layoutChildren(320)
    local narrow=row:GetHeight()
    row:layoutChildren(900)
    assert(row:GetHeight()<=narrow,'wider page never needs more height')
    members={};for i=1,500 do members[i]={name=string.format('M%03d',i),classID=1} end
    R:Rescan();row:layoutChildren(600)
    local seen={}
    for i=1,500 do
        local p=page.nameLabels[i].points[1];local key=p[4]..':'..p[5]
        assert(not seen[key],'name cells do not overlap');seen[key]=true
    end
    assert(row:GetHeight()>=125*22,'row grows so the page scrolls to every member')

    -- Restricted reads keep the current list instead of publishing a partial one.
    members={{name='Dee',classID=8},{name={secret=true},classID=8}}
    R:Rescan()
    assert(R.snapshot.total==500 and R.status==R.STATUS.restricted,'secret name rejects the read')
    members={{name='Dee',classID={secret=true}}}
    R:Rescan();assert(R.snapshot.total==500 and R.status==R.STATUS.restricted,'secret class rejects the read')
    locked=true;members={{name='Dee',classID=8}};reads=0
    R:Rescan();assert(reads==0 and R.status==R.STATUS.restricted,'lockdown skips the read')
    locked=false;R:Rescan()
    assert(R.status==nil and R.snapshot.total==1 and Visible()=='Dee','recovers when data returns')

    -- Encoded placeholders are not shown as members.
    members={{name='|Kq123|k',classID=8},{name='Eve',classID=8}}
    R:Rescan();assert(R.snapshot.total==1 and Visible()=='Eve')

    -- Native failures and an empty client response leave the list alone.
    local good=C_Club.GetClubMembers
    C_Club.GetClubMembers=function() error('not initialized') end
    R:Rescan();assert(R.status==R.STATUS.unavailable and R.snapshot.total==1)
    C_Club.GetClubMembers=function() return {} end
    R:Rescan();assert(R.status==R.STATUS.loading and R.snapshot.total==1)
    C_Club.GetClubMembers=good

    -- Leaving the guild clears the list.
    inGuild=false;R:Rescan()
    assert(R.status==R.STATUS.noGuild and R.snapshot.total==0 and Visible()=='' and page.totalLabel:GetText()=='Total Members: 0')
    inGuild=true;members={{name='Fay',classID=8}};R:Rescan()

    -- Events stop with the page, and restart with it.
    page:Hide();assert(Watching()==0 and not R.watching,'hidden page listens to nothing')
    local before=reads
    FireEvent('GUILD_ROSTER_UPDATE',true);assert(reads==before)
    requests=0;page:Show();assert(requests==1 and Watching()>0,'reopening requests a fresh roster')

    -- A rescan that was queued before the page closed does nothing.
    local held;C_Timer.After=function(_,fn) held=fn end
    FireEvent('GUILD_ROSTER_UPDATE',true);page:Hide();before=reads;held()
    assert(reads==before,'stale rescan dropped');C_Timer.After=realAfter
    page:Show()

    -- Turning it off clears the list and the switch still works afterwards.
    addon:SetModuleEnabled('foreverGuildRoster',false)
    assert(Watching()==0 and R.snapshot.total==0 and R.status==R.STATUS.off and Visible()=='')
    addon:SetModuleEnabled('foreverGuildRoster',true)
    assert(R.watching and R.snapshot.total==1 and Visible()=='Fay')

    -- Search reaches the page; roster names never reach saved or exported settings.
    local found=addon:SearchSettings('guild roster')
    assert(found[1] and found[1].module==R,'search routes to the Roster page')
    local encoded=addon.ProfileCodec.Encode(PTGToolsDB)
    assert(not encoded:find('Fay',1,true) and not encoded:find('Alice',1,true),'no roster data persisted')
    local keys=0;for key in pairs(R.db) do assert(key=='enabled','only the switch is stored: '..tostring(key));keys=keys+1 end
    assert(keys==1)

    -- Unavailable client API degrades to a message.
    local club=C_Club;C_Club=nil;R:Rescan()
    assert(R.status==R.STATUS.unavailable,'missing C_Club is reported');C_Club=club
''')
print('PASS guild roster: class grouping, totals, restricted/secret handling, event scope, no persistence')
