"""Guild Tools -> Roster: class grouping, search/filters, analytics and tabs; not WoW."""
from smoke import load

lua, _ = load()
lua.execute(r'''
    R=addon.ForeverGuildRoster
    local CLASS={[1]='WARRIOR',[8]='MAGE',[11]='DRUID'}
    local RACE={[1]='Human',[2]='Orc',[4]='Night Elf'}
    raceReads=0
    C_CreatureInfo={GetClassInfo=function(id) return CLASS[id] and {classFile=CLASS[id],className=CLASS[id],classID=id} or nil end,
        GetRaceInfo=function(id) raceReads=raceReads+1;return RACE[id] and {raceName=RACE[id],clientFileString=RACE[id],raceID=id} or nil end}
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
    GameTooltip={lines={},shown=false}
    function GameTooltip:SetOwner(owner) self.owner=owner;self.lines={} end
    function GameTooltip:SetText(text) self.lines={text} end
    function GameTooltip:AddLine(text) self.lines[#self.lines+1]=text end
    function GameTooltip:Show() self.shown=true end
    function GameTooltip:Hide() self.shown=false end

    function Count(classFile)
        for _,cell in ipairs(page.summaryCells) do if cell.classFile==classFile then return cell.count:GetText() end end
    end
    function Visible()
        local out={}
        for _,cell in ipairs(page.memberCells) do if cell:IsShown() then out[#out+1]=cell.name:GetText() end end
        return table.concat(out,',')
    end
    function Open()
        addon:ToggleConfig();addon:SelectConfigPage('foreverGuildRoster')
        page=R.page
    end
    function Watching()
        local n=0;if R.events then for _ in pairs(R.events.events) do n=n+1 end end;return n
    end
    function Bars(key)
        local out={}
        for i,entry in ipairs(page.charts[key].entries) do out[i]=entry.label..'='..entry.count end
        return table.concat(out,',')
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
    local row=page.membersRow
    row:layoutChildren(320)
    local narrow=row:GetHeight()
    row:layoutChildren(900)
    assert(row:GetHeight()<=narrow,'wider page never needs more height')
    members={};for i=1,500 do members[i]={name=string.format('M%03d',i),classID=1} end
    R:Rescan();row:layoutChildren(600)
    local seen={}
    for i=1,500 do
        local p=page.memberCells[i].points[1];local key=p[4]..':'..p[5]
        assert(not seen[key],'name cells do not overlap');seen[key]=true
    end
    assert(row:GetHeight()>=167*22,'row grows so the page scrolls to every member')

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

    -- Unavailable client API degrades to a message.
    local club=C_Club;C_Club=nil;R:Rescan()
    assert(R.status==R.STATUS.unavailable,'missing C_Club is reported');C_Club=club
    R:Rescan();assert(R.status==nil)
''')

# A detailed roster: levels, races, ranks, zones, notes, presence and time offline.
lua.execute(r'''
    Enum={ClubMemberPresence={Unknown=0,Online=1,OnlineMobile=2,Offline=3,Away=4,Busy=5}}
    local P=Enum.ClubMemberPresence
    members={
        {name='Alice',classID=8,level=60,race=1,zone='Orgrimmar',guildRank='Officer',guildRankOrder=2,
            memberNote='Raid lead',officerNote='Bank alt',presence=P.Online},
        {name='Bob',classID=1,level=42,race=2,zone='Stranglethorn Vale',guildRank='Member',guildRankOrder=4,
            presence=P.Away},
        {name='Cara',classID=11,level=8,race=4,zone='Teldrassil',guildRank='Guild Master',guildRankOrder=1,
            presence=P.Offline,lastOnlineYear=0,lastOnlineMonth=0,lastOnlineDay=3,lastOnlineHour=5},
        {name='Dax',classID=1,level=60,race=2,guildRank='Member',guildRankOrder=4,
            presence=P.Offline,lastOnlineYear=1,lastOnlineMonth=2,lastOnlineDay=0,lastOnlineHour=0},
        {name='Eve',classID=8,level=55,race=1,zone='Ironforge',guildRank='Member',guildRankOrder=4,
            presence=P.OnlineMobile,lastOnlineYear=0,lastOnlineMonth=0,lastOnlineDay=0,lastOnlineHour=2},
        {name='Finn',classID=8,level={secret=true},race=99,zone={secret=true},guildRank='Member',guildRankOrder=4,
            officerNote={secret=true},presence=P.Busy},
    }
    raceReads=0
    R:Rescan()
    assert(R.status==nil and R.snapshot.total==6,'restricted optional details keep the member listed')
    assert(raceReads==4,'each race is looked up once per read: '..raceReads)
    assert(R.snapshot.online==3,'online, away and busy are in the game; mobile and offline are not')
    assert(page.onlineLabel:GetText()=='Online Now: 3')
    assert(page.resultLabel:GetText()=='6 members, 3 online')
    local finn=R.snapshot.members.MAGE[3]
    assert(finn.name=='Finn' and finn.level==nil and finn.zone==nil and finn.officerNote==nil and finn.race==nil)

    -- Names carry their level and an online marker.
    local function Cell(name) for _,cell in ipairs(page.memberCells) do if cell:IsShown() and cell.name:GetText()==name then return cell end end end
    assert(Cell('Alice').level:GetText()=='60' and Cell('Alice').dot:IsShown())
    assert(Cell('Cara').level:GetText()=='8' and not Cell('Cara').dot:IsShown())
    assert(Cell('Finn').level:GetText()=='' and Cell('Finn').dot:IsShown())

    -- Hovering a name shows who they are, where they are or when they were last on, and notes.
    Cell('Alice').scripts.OnEnter(Cell('Alice'))
    local text=table.concat(GameTooltip.lines,'|')
    assert(GameTooltip.shown and GameTooltip.owner==Cell('Alice'))
    assert(text=='Alice|Level 60 Human Mage|Rank: Officer|Online in Orgrimmar|Note: Raid lead|Officer Note: Bank alt',text)
    Cell('Alice').scripts.OnLeave(Cell('Alice'));assert(not GameTooltip.shown)
    assert(table.concat(R:Describe(Cell('Cara').member),'|')=='Level 8 Night Elf Druid|Rank: Guild Master|Last online 3 days ago')
    assert(R:Describe(Cell('Dax').member)[3]=='Last online 1 year ago')
    assert(R:Describe(Cell('Eve').member)[3]=='Online in mobile chat')
    assert(R:LastOnlineText({lastOnline={0,0,0,0}})=='Last online less than an hour ago')
    assert(R:LastOnlineText({lastOnline={0,0,0,1}})=='Last online 1 hour ago' and R:LastOnlineText({})=='Offline')

    -- A tooltip left open follows the roster, and closes with the page.
    Cell('Bob').scripts.OnEnter(Cell('Bob'))
    members[2].zone='Booty Bay';R:Rescan()
    assert(GameTooltip.shown and GameTooltip.lines[4]=='Online in Booty Bay','open tooltip refreshed')
    page:Hide();assert(not GameTooltip.shown,'closing the page closes its tooltip')
    GameTooltip:Show();page:Show();page:Hide()
    assert(GameTooltip.shown,'a tooltip the page did not open is left alone')
    GameTooltip:Hide();page:Show()

    -- Search matches name, class, race, zone, rank and notes, ignoring case.
    local box=page.searchBox
    local function Search(text) box:SetText(text);return Visible() end
    assert(Search('ALI')=='Alice' and not page.searchHint:IsShown())
    assert(page.resultLabel:GetText()=='Showing 1 of 6 members')
    assert(Search('booty')=='Bob','zone')
    assert(Search('night elf')=='Cara','race')
    assert(Search('guild master')=='Cara','rank')
    assert(Search('raid lead')=='Alice','member note')
    assert(Search('bank alt')=='Alice','officer note')
    assert(Search('druid')=='Cara','class name')
    assert(Search('  60 ')=='Dax,Alice','a number searches levels')
    assert(Search('40-59')=='Bob,Eve' and Search('59 - 40')=='Bob,Eve','level ranges in either order')
    assert(Search('nobody')=='' and page.resultLabel:GetText()=='No members match your search.')
    assert(page.classHeadings.MAGE:IsShown()==false,'empty groups lose their heading')
    assert(Search('')=='Bob,Dax,Alice,Eve,Finn,Cara' and page.searchHint:IsShown())
    assert(page.classHeadings.MAGE:GetText()=='Mage (3)')

    -- Class and status filters combine with the search.
    local function Choose(select,label)
        select.scripts.OnClick(select)
        for _,choice in ipairs(select.rows) do if choice:IsShown() and choice.label:GetText()==label then choice.scripts.OnClick(choice);return end end
        error('no choice '..label)
    end
    Choose(page.classFilter,'Mage')
    assert(Visible()=='Alice,Eve,Finn' and page.classFilter.label:GetText()=='Mage')
    assert(page.classHeadings.MAGE:GetText()=='Mage (3)' and page.resultLabel:GetText()=='Showing 3 of 6 members')
    Choose(page.statusFilter,'Online')
    assert(Visible()=='Alice,Finn','online mages')
    Choose(page.statusFilter,'Offline')
    assert(Visible()=='Eve','mobile chat is not in the game')
    Choose(page.classFilter,'All Classes');assert(Visible()=='Dax,Eve,Cara')
    assert(Search('60')=='Dax','status and level together')
    Search('');Choose(page.statusFilter,'All Members')
    assert(not R:FilterActive() and Visible()=='Bob,Dax,Alice,Eve,Finn,Cara')
    -- Filters survive a roster refresh.
    Choose(page.classFilter,'Warrior');R:Rescan();assert(Visible()=='Bob,Dax')
    Choose(page.classFilter,'All Classes')

    -- The filters drop below the search box on a narrow page.
    local toolbar=page.searchBox:GetParent().row
    toolbar:layoutChildren(800);local wide=toolbar:GetHeight()
    assert(page.classFilter.points[1][5]==-8,'inline on a wide page')
    toolbar:layoutChildren(320)
    assert(toolbar:GetHeight()>wide and page.classFilter.points[1][4]==0,'wrapped on a narrow page')

    -- Breakdowns: fixed brackets keep zeros; Unknown appears only when used.
    assert(Bars('level')=='60=2,50–59=1,40–49=1,30–39=0,20–29=0,10–19=0,1–9=1,Unknown=1',Bars('level'))
    assert(Bars('rank')=='Guild Master=1,Officer=1,Member=4','ranks in guild order: '..Bars('rank'))
    assert(Bars('race')=='Human=2,Orc=2,Night Elf=1,Unknown=1',Bars('race'))
    assert(Bars('lastOnline')=='Online Now=3,Within a Day=1,1–6 Days=1,1–4 Weeks=0,1–3 Months=0,3–12 Months=0,Over a Year=1',Bars('lastOnline'))
    assert(Bars('zone')=='Booty Bay=1,Orgrimmar=1,Unknown=1','only members in the game: '..Bars('zone'))

    -- Bars scale to the largest entry and show each share.
    local chart=page.charts.level
    chart.row:layoutChildren(600)
    local top,low,empty=chart.bars[1],chart.bars[2],chart.bars[4]
    assert(top.count:GetText()=='2 (33%)' and low.count:GetText()=='1 (17%)',top.count:GetText())
    assert(top.fill.width==top.track.width and math.abs(low.fill.width-top.track.width/2)<=1,'proportional fills')
    assert(not empty.fill:IsShown() and empty.count:GetText()=='0 (0%)')
    assert(chart.row:GetHeight()==8*24+8)

    -- Busy zones are named; the rest share one line.
    members={}
    for i=1,14 do members[i]={name='Z'..i,classID=1,level=20,zone='Zone'..string.char(64+math.min(i,12)),presence=P.Online} end
    R:Rescan()
    assert(#page.charts.zone.entries==11 and page.charts.zone.entries[1].label=='ZoneL' and page.charts.zone.entries[1].count==3)
    assert(page.charts.zone.entries[11].label=='Other Zones' and page.charts.zone.entries[11].count==2,Bars('zone'))
    local count=0;for _,entry in ipairs(page.charts.zone.entries) do count=count+entry.count end
    assert(count==14,'every online member is counted once')

    -- Nobody online leaves a note instead of an empty chart.
    members={{name='Gus',classID=1,level=10,presence=P.Offline}}
    R:Rescan()
    assert(#page.charts.zone.entries==0 and page.charts.zone.empty:GetText()==R.NOBODY_ONLINE and page.charts.zone.empty:IsShown())
    assert(not page.charts.zone.bars[1].label:IsShown(),'stale bars are hidden')
    assert(Bars('lastOnline'):find('Unknown=1',1,true),'offline without a time is unknown')

    -- Two tabs: Members and Analytics; the status line shows above both.
    local tabs=page.sectionTabs
    assert(#tabs.buttons==2 and tabs.buttons[1].label:GetText()=='Members' and tabs.buttons[2].label:GetText()=='Analytics')
    page:SelectSectionTab(1)
    assert(page.membersRow:IsShown() and not page.charts.level.row:IsShown())
    page:SelectSectionTab(2)
    assert(not page.membersRow:IsShown() and page.charts.level.row:IsShown() and page.summaryCells[1].name:IsShown())
    inGuild=false;R:Rescan()
    assert(page.statusLabel:GetParent().row:IsShown(),'status shows on the Analytics tab')
    assert(not page.charts.level.row:IsShown(),'no breakdowns without members')
    page:SelectSectionTab(1)
    assert(page.statusLabel:GetParent().row:IsShown() and not page.resultLabel:GetParent().row:IsShown())
    inGuild=true;members={{name='Fay',classID=8,level=60}};R:Rescan()

    -- Search reaches the page; roster names and searches never reach saved or exported settings.
    for _,query in ipairs({'guild roster','member search','last online'}) do
        local found=addon:SearchSettings(query)
        assert(found[1] and found[1].module==R,'search routes to the Roster page: '..query)
    end
    page.searchBox:SetText('Searchterm')
    local encoded=addon.ProfileCodec.Encode(PTGToolsDB)
    for _,text in ipairs({'Fay','Alice','Searchterm','Orgrimmar','Raid lead'}) do
        assert(not encoded:find(text,1,true),'no roster data persisted: '..text)
    end
    local keys=0;for key in pairs(R.db) do assert(key=='enabled','only the switch is stored: '..tostring(key));keys=keys+1 end
    assert(keys==1)
    page.searchBox:SetText('')
''')
print('PASS guild roster: class grouping, search/filters, tooltips, analytics, tabs, restricted handling, no persistence')
