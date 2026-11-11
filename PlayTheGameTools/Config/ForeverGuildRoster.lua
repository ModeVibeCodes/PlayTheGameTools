local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.ForeverGuildRoster,addon.ConfigWidgets,addon.InterfaceTheme

local LINE=22
local SUMMARY_TOP=38   -- room for the totals above the class grid
local SUMMARY_CELL=180
local COUNT_WIDTH=40
local NAME_CELL=170
local LEVEL_WIDTH=26   -- right-aligned level after each name
local DOT=6            -- online marker before each name
local HEADING_HEIGHT=30
local GROUP_GAP=12
local CONTROL_HEIGHT=30
local CONTROL_GAP=8
local SEARCH_MINIMUM=180
local CLASS_SELECT=150
local STATUS_SELECT=130
local CHART_LINE=24
local CHART_LABEL=150
local CHART_COUNT=86
local BAR_HEIGHT=8

-- A page row with no label: its controls span the row and position themselves.
local function BlockRow(page,height)
    local controls=page:Row("",height)
    table.remove(page.searchEntries) -- the empty label would be a blank search result
    local row=controls.row
    controls.rowLabel:Hide()
    controls:ClearAllPoints();controls:SetAllPoints(row)
    return row,controls
end
local function HasMembers() return M.snapshot.total>0 end

-- Only a tooltip this page opened is ever hidden by it.
local tooltipCell
local function HideMemberTooltip()
    if tooltipCell and GameTooltip then GameTooltip:Hide() end
    tooltipCell=nil
end
local function ShowMemberTooltip(cell)
    local member=cell.member
    if not member or not GameTooltip then return end
    tooltipCell=cell
    GameTooltip:SetOwner(cell,"ANCHOR_RIGHT")
    GameTooltip:SetText(member.name,M:ClassColor(member.classFile))
    for _,line in ipairs(M:Describe(member)) do GameTooltip:AddLine(line,0.9,0.9,0.9,true) end
    GameTooltip:Show()
end

function M:CreateConfigPage(parent)
    local page=W.Page(parent,320);self.page=page

    -- Shown above both tabs whenever the list cannot be read.
    local statusRow,statusControls=BlockRow(page,32)
    statusRow.visibleWhen=function() return M.status~=nil end
    local status=W.Label(statusControls,"",nil,0,-9,520,T.muted)
    function statusRow:layoutChildren(width) status:SetWidth(width) end
    page.statusLabel=status

    page:Section("Members",nil,false)
    local toolbarRow,toolbar=BlockRow(page,CONTROL_HEIGHT+14)
    local search=CreateFrame("EditBox",nil,toolbar)
    search:SetHeight(CONTROL_HEIGHT);search:SetAutoFocus(false);search:SetMaxLetters(60)
    search:SetFontObject(GameFontHighlight);search:SetTextInsets(8,8,0,0)
    addon.Media:BindInterfaceFont(search,GameFontHighlight)
    W.CrispText(search);W.Texture(search,"InputField")
    local hint=W.Label(search,"Search name, zone, rank, note or level",nil,8,-8,300,T.muted)
    hint:SetWordWrap(false)
    search:SetScript("OnTextChanged",function(box)
        local text=box:GetText() or ""
        hint:SetShown(text=="")
        M:SetFilter("text",text)
    end)
    search:SetScript("OnEnterPressed",function(box) box:ClearFocus() end)
    search:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    page.searchBox,page.searchHint=search,hint

    local classChoices={{id=M.ALL_CLASSES,label="All Classes"}}
    for _,classFile in ipairs(M.CLASSES) do classChoices[#classChoices+1]={id=classFile,label=M:ClassName(classFile)} end
    local function Chooser(width,choices,key)
        return W.Select(toolbar,width,function() return choices end,function()
            local id=M.filter[key]
            for _,choice in ipairs(choices) do if choice.id==id then return id,choice.label end end
            return id,tostring(id)
        end,function(id) M:SetFilter(key,id) end)
    end
    local classSelect=Chooser(CLASS_SELECT,classChoices,"class")
    local statusSelect=Chooser(STATUS_SELECT,M.STATUS_FILTERS,"status")
    page.classFilter,page.statusFilter=classSelect,statusSelect
    page.refreshers[#page.refreshers+1]=function() classSelect:Refresh();statusSelect:Refresh() end
    -- The filters follow the search box, or drop below it on a narrow page.
    function toolbarRow:layoutChildren(width)
        local filters=CLASS_SELECT+STATUS_SELECT+CONTROL_GAP
        local inline=width>=SEARCH_MINIMUM+CONTROL_GAP+filters
        local searchWidth=inline and width-filters-CONTROL_GAP or width
        search:ClearAllPoints();search:SetPoint("TOPLEFT",0,-8);search:SetWidth(searchWidth)
        hint:SetWidth(searchWidth-16)
        local x=inline and searchWidth+CONTROL_GAP or 0
        local y=inline and -8 or -16-CONTROL_HEIGHT
        classSelect:ClearAllPoints();classSelect:SetPoint("TOPLEFT",x,y)
        statusSelect:ClearAllPoints();statusSelect:SetPoint("TOPLEFT",x+CLASS_SELECT+CONTROL_GAP,y)
        self:SetHeight(-y+CONTROL_HEIGHT+6)
    end

    local resultRow,resultControls=BlockRow(page,28)
    resultRow.visibleWhen=HasMembers
    local results=W.Label(resultControls,"",nil,0,-8,520,T.muted)
    function resultRow:layoutChildren(width) results:SetWidth(width) end
    page.resultLabel=results

    local membersRow,membersControls=BlockRow(page,40)
    local headings,cells,groups={},{},{}
    page.classHeadings,page.memberCells,page.nameLabels,page.membersRow=headings,cells,{},membersRow
    local function Heading(classFile)
        local heading=headings[classFile]
        if not heading then
            heading=W.Heading(membersControls,"",T.fontSize.group,0,0,360,T.text)
            heading:SetWordWrap(false)
            heading:SetTextColor(M:ClassColor(classFile))
            headings[classFile]=heading
        end
        return heading
    end
    local function MemberCell(index)
        local cell=cells[index]
        if not cell then
            cell=CreateFrame("Frame",nil,membersControls)
            cell:SetHeight(LINE);cell:EnableMouse(true)
            cell.dot=cell:CreateTexture(nil,"ARTWORK")
            cell.dot:SetSize(DOT,DOT);cell.dot:SetPoint("TOPLEFT",0,-5);W.Paint(cell.dot,T.primary)
            cell.name=W.Label(cell,"",nil,DOT+4,0,NAME_CELL);cell.name:SetWordWrap(false)
            cell.level=W.Label(cell,"",nil,0,0,LEVEL_WIDTH,T.muted);cell.level:SetJustifyH("RIGHT")
            cell:SetScript("OnEnter",ShowMemberTooltip);cell:SetScript("OnLeave",HideMemberTooltip)
            cells[index]=cell;page.nameLabels[index]=cell.name
        end
        return cell
    end
    function membersRow:layoutChildren(width)
        local columns=math.max(1,math.floor(width/NAME_CELL))
        local cellWidth=width/columns
        local y=-8
        for _,group in ipairs(groups) do
            group.heading:ClearAllPoints();group.heading:SetPoint("TOPLEFT",0,y);group.heading:SetWidth(width)
            y=y-HEADING_HEIGHT
            for i=1,group.count do
                local cell=cells[group.first+i-1]
                local inner=cellWidth-8
                cell:ClearAllPoints()
                cell:SetPoint("TOPLEFT",((i-1)%columns)*cellWidth,y-math.floor((i-1)/columns)*LINE)
                cell:SetWidth(inner)
                cell.name:SetWidth(math.max(1,inner-DOT-4-LEVEL_WIDTH-4))
                cell.level:ClearAllPoints();cell.level:SetPoint("TOPLEFT",inner-LEVEL_WIDTH,0)
            end
            y=y-math.ceil(group.count/columns)*LINE-GROUP_GAP
        end
        self:SetHeight(math.max(1,-y))
    end

    page:Section("Analytics",nil,false)
    page:Group("Class Summary")
    local summaryRow,summaryControls=BlockRow(page,SUMMARY_TOP+LINE*3)
    local total=W.Heading(summaryControls,"",T.fontSize.group,0,-10,220,T.text)
    local online=W.Label(summaryControls,"",nil,0,-12,200,T.muted)
    page.totalLabel,page.onlineLabel=total,online
    local summaryCells={}
    local function SummaryCell(classFile)
        local name=W.Label(summaryControls,M:ClassName(classFile),nil,0,0,120)
        name:SetTextColor(M:ClassColor(classFile));name:SetWordWrap(false)
        local count=W.Label(summaryControls,"0",nil,0,0,COUNT_WIDTH,T.text)
        count:SetJustifyH("RIGHT")
        summaryCells[#summaryCells+1]={classFile=classFile,name=name,count=count}
    end
    for _,classFile in ipairs(M.CLASSES) do SummaryCell(classFile) end
    SummaryCell(M.UNKNOWN)
    page.summaryCells=summaryCells
    function summaryRow:layoutChildren(width)
        local columns=math.max(1,math.min(3,math.floor(width/SUMMARY_CELL)))
        local cellWidth=width/columns
        local onlineX=math.min(cellWidth,240)
        total:SetWidth(onlineX-8)
        online:ClearAllPoints();online:SetPoint("TOPLEFT",onlineX,-12);online:SetWidth(math.max(1,width-onlineX))
        local shown=0
        for _,cell in ipairs(summaryCells) do
            -- Unknown is reported only when some member actually lacks a class.
            local visible=cell.classFile~=M.UNKNOWN or M:Count(M.UNKNOWN)>0
            cell.name:SetShown(visible);cell.count:SetShown(visible)
            if visible then
                local x=(shown%columns)*cellWidth
                local y=-SUMMARY_TOP-math.floor(shown/columns)*LINE
                cell.name:ClearAllPoints();cell.name:SetPoint("TOPLEFT",x,y)
                cell.name:SetWidth(cellWidth-COUNT_WIDTH-20)
                cell.count:ClearAllPoints();cell.count:SetPoint("TOPLEFT",x+cellWidth-COUNT_WIDTH-16,y)
                shown=shown+1
            end
        end
        self:SetHeight(SUMMARY_TOP+math.ceil(shown/columns)*LINE+4)
    end

    -- Each breakdown is a list of bars: label, hairline track with an accent
    -- fill scaled to the largest entry, and the count with its share.
    local charts={}
    page.charts=charts
    local function Chart(title,key)
        page:Group(title)
        page.rows[#page.rows].visibleWhen=HasMembers
        local row,controls=BlockRow(page,CHART_LINE)
        row.visibleWhen=HasMembers
        local chart={row=row,bars={},entries={},max=0}
        chart.empty=W.Label(controls,"",nil,0,-6,360,T.muted)
        local function Bar(index)
            local bar=chart.bars[index]
            if not bar then
                bar={}
                bar.label=W.Label(controls,"",nil,0,0,CHART_LABEL,T.secondary);bar.label:SetWordWrap(false)
                bar.track=controls:CreateTexture(nil,"BORDER");W.Paint(bar.track,T.line)
                bar.fill=controls:CreateTexture(nil,"ARTWORK");W.Paint(bar.fill,T.primary)
                bar.count=W.Label(controls,"",nil,0,0,CHART_COUNT,T.text);bar.count:SetJustifyH("RIGHT")
                chart.bars[index]=bar
            end
            return bar
        end
        function chart:Render()
            local entries=M:Stat(key)
            local sum,max=0,0
            for _,entry in ipairs(entries) do sum=sum+entry.count;max=math.max(max,entry.count) end
            self.entries,self.max=entries,max
            for i,entry in ipairs(entries) do
                local bar=Bar(i)
                bar.label:SetText(entry.label)
                bar.count:SetText(string.format("%d (%d%%)",entry.count,sum>0 and math.floor(entry.count*100/sum+0.5) or 0))
                bar.label:Show();bar.track:Show();bar.count:Show();bar.fill:SetShown(entry.count>0)
            end
            for i=#entries+1,#self.bars do
                local bar=self.bars[i]
                bar.label:Hide();bar.track:Hide();bar.fill:Hide();bar.count:Hide()
            end
            self.empty:SetText(#entries==0 and key=="zone" and M.NOBODY_ONLINE or "")
            self.empty:SetShown(#entries==0)
        end
        function row:layoutChildren(width)
            local labelWidth=math.min(CHART_LABEL,math.floor(width*0.3))
            local trackX=labelWidth+12
            local trackWidth=math.max(20,width-trackX-CHART_COUNT-12)
            for i,entry in ipairs(chart.entries) do
                local bar,y=chart.bars[i],-(i-1)*CHART_LINE
                bar.label:ClearAllPoints();bar.label:SetPoint("TOPLEFT",0,y-5);bar.label:SetWidth(labelWidth)
                bar.track:ClearAllPoints();bar.track:SetPoint("TOPLEFT",trackX,y-8);bar.track:SetSize(trackWidth,BAR_HEIGHT)
                local fill=chart.max>0 and math.max(2,math.floor(trackWidth*entry.count/chart.max+0.5)) or 0
                bar.fill:ClearAllPoints();bar.fill:SetPoint("TOPLEFT",trackX,y-8);bar.fill:SetSize(math.max(1,fill),BAR_HEIGHT)
                bar.count:ClearAllPoints();bar.count:SetPoint("TOPLEFT",width-CHART_COUNT,y-5);bar.count:SetWidth(CHART_COUNT)
            end
            chart.empty:SetWidth(width)
            self:SetHeight(math.max(1,#chart.entries)*CHART_LINE+8)
        end
        charts[key]=chart
        return chart
    end
    local chartOrder={Chart("Level","level"),Chart("Rank","rank"),Chart("Race","race"),
        Chart("Last Online","lastOnline"),Chart("Online by Zone","zone")}

    -- Text changes only with the roster or the filters; Layout owns every position.
    function page:RenderRoster()
        status:SetText(M.status or "")
        total:SetText(string.format("Total Members: %d",M.snapshot.total))
        online:SetText(string.format("Online Now: %d",M.snapshot.online))
        for _,cell in ipairs(summaryCells) do cell.count:SetText(M:Count(cell.classFile)) end
        local filtered,shown=M:Filtered()
        results:SetText(M:ResultText(shown))
        for _,heading in pairs(headings) do heading:Hide() end
        for i=#groups,1,-1 do groups[i]=nil end
        local used=0
        for _,group in ipairs(filtered) do
            local classFile=group.classFile
            local heading=Heading(classFile)
            heading:SetText(string.format("%s (%d)",M:ClassName(classFile),#group.members))
            heading:Show()
            groups[#groups+1]={heading=heading,first=used+1,count=#group.members}
            for _,member in ipairs(group.members) do
                used=used+1
                local cell=MemberCell(used)
                cell.member=member
                cell.name:SetText(member.name);cell.name:SetTextColor(M:ClassColor(classFile))
                cell.level:SetText(member.level and tostring(member.level) or "")
                cell.dot:SetShown(member.online)
                cell:Show()
            end
        end
        for i=used+1,#cells do cells[i].member=nil;cells[i]:Hide() end
        -- A hovered name follows the roster: refreshed details, or closed when gone.
        if tooltipCell then
            if tooltipCell.member and tooltipCell:IsShown() then ShowMemberTooltip(tooltipCell) else HideMemberTooltip() end
        end
        for _,chart in ipairs(chartOrder) do chart:Render() end
        self:Layout()
    end

    W.SectionTabs(page)
    page.sectionTabs:SetPoint("TOPLEFT",0,0);page.sectionTabs:SetPoint("TOPRIGHT",-24,0)
    page.scroll:ClearAllPoints();page.scroll:SetPoint("TOPLEFT",0,-40);page.scroll:SetPoint("BOTTOMRIGHT",-24,0)
    page.scrollbar:ClearAllPoints();page.scrollbar:SetPoint("TOPRIGHT",-4,-44);page.scrollbar:SetPoint("BOTTOMRIGHT",-4,4)
    page:HookScript("OnShow",function() M:SetPageShown(true) end)
    page:HookScript("OnHide",function() M:SetPageShown(false);HideMemberTooltip() end)
    page:Finish()
    page:RenderRoster()
    return page
end
