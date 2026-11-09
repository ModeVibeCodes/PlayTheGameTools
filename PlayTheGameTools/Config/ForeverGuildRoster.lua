local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.ForeverGuildRoster,addon.ConfigWidgets,addon.InterfaceTheme

local LINE=22
local SUMMARY_TOP=38   -- room for the total above the class grid
local SUMMARY_CELL=180
local COUNT_WIDTH=40
local NAME_CELL=150
local HEADING_HEIGHT=30
local GROUP_GAP=12

-- A page row with no label: its controls span the row and position themselves.
local function BlockRow(page,height)
    local controls=page:Row("",height)
    table.remove(page.searchEntries) -- the empty label would be a blank search result
    local row=controls.row
    controls.rowLabel:Hide()
    controls:ClearAllPoints();controls:SetAllPoints(row)
    return row,controls
end

function M:CreateConfigPage(parent)
    local page=W.Page(parent,320);self.page=page

    page:Section("Class Summary",nil,false)
    local statusRow,statusControls=BlockRow(page,32)
    statusRow.visibleWhen=function() return M.status~=nil end
    local status=W.Label(statusControls,"",nil,0,-9,520,T.muted)
    function statusRow:layoutChildren(width) status:SetWidth(width) end
    page.statusLabel=status

    local summaryRow,summaryControls=BlockRow(page,SUMMARY_TOP+LINE*3)
    local total=W.Heading(summaryControls,"",T.fontSize.group,0,-10,360,T.text)
    page.totalLabel=total
    local cells={}
    local function SummaryCell(classFile)
        local name=W.Label(summaryControls,M:ClassName(classFile),nil,0,0,120)
        name:SetTextColor(M:ClassColor(classFile));name:SetWordWrap(false)
        local count=W.Label(summaryControls,"0",nil,0,0,COUNT_WIDTH,T.text)
        count:SetJustifyH("RIGHT")
        cells[#cells+1]={classFile=classFile,name=name,count=count}
    end
    for _,classFile in ipairs(M.CLASSES) do SummaryCell(classFile) end
    SummaryCell(M.UNKNOWN)
    page.summaryCells=cells
    function summaryRow:layoutChildren(width)
        local columns=math.max(1,math.min(3,math.floor(width/SUMMARY_CELL)))
        local cellWidth=width/columns
        local shown=0
        for _,cell in ipairs(cells) do
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

    page:Section("Members by Class",nil,false)
    local membersRow,membersControls=BlockRow(page,40)
    local headings,names,groups={},{},{}
    page.classHeadings,page.nameLabels=headings,names
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
    local function NameLabel(index)
        local label=names[index]
        if not label then
            label=W.Label(membersControls,"",nil,0,0,NAME_CELL)
            label:SetWordWrap(false)
            names[index]=label
        end
        return label
    end
    function membersRow:layoutChildren(width)
        local columns=math.max(1,math.floor(width/NAME_CELL))
        local cellWidth=width/columns
        local y=-8
        for _,group in ipairs(groups) do
            group.heading:ClearAllPoints();group.heading:SetPoint("TOPLEFT",0,y);group.heading:SetWidth(width)
            y=y-HEADING_HEIGHT
            for i=1,group.count do
                local label=names[group.first+i-1]
                label:ClearAllPoints()
                label:SetPoint("TOPLEFT",((i-1)%columns)*cellWidth,y-math.floor((i-1)/columns)*LINE)
                label:SetWidth(cellWidth-8)
            end
            y=y-math.ceil(group.count/columns)*LINE-GROUP_GAP
        end
        self:SetHeight(math.max(1,-y))
    end

    -- Text changes only with the roster; Layout owns every position.
    function page:RenderRoster()
        status:SetText(M.status or "")
        total:SetText(string.format("Total Members: %d",M.snapshot.total))
        for _,cell in ipairs(cells) do cell.count:SetText(M:Count(cell.classFile)) end
        for _,heading in pairs(headings) do heading:Hide() end
        for i=#groups,1,-1 do groups[i]=nil end
        local used=0
        local function AddGroup(classFile)
            local list=M.snapshot.members[classFile]
            if not list or #list==0 then return end
            local heading=Heading(classFile)
            heading:SetText(string.format("%s (%d)",M:ClassName(classFile),#list))
            heading:Show()
            groups[#groups+1]={heading=heading,first=used+1,count=#list}
            for _,name in ipairs(list) do
                used=used+1
                local label=NameLabel(used)
                label:SetText(name);label:SetTextColor(M:ClassColor(classFile));label:Show()
            end
        end
        for _,classFile in ipairs(M.CLASSES) do AddGroup(classFile) end
        AddGroup(M.UNKNOWN)
        for i=used+1,#names do names[i]:Hide() end
        self:Layout()
    end

    page:HookScript("OnShow",function() M:SetPageShown(true) end)
    page:HookScript("OnHide",function() M:SetPageShown(false) end)
    page:Finish()
    page:RenderRoster()
    return page
end
