local _,addon=...
local W,T=addon.ConfigWidgets,addon.InterfaceTheme

-- Chips: a wrapping row of toggle chips for a set of on/off settings, one chip
-- per saved key. The whole chip is the click target; a small square and the
-- theme's selected state show which are on. Each chip is its own search entry
-- and flashes the row. items = {{label=, get=function, set=function(v)}, ...}.
local HEIGHT,GAP,PAD,MARK,TOP=26,6,10,8,6

local function Measure(chip)
    chip.label:SetWidth(0)
    local width=chip.label:GetStringWidth()
    if (issecretvalue and issecretvalue(width)) or type(width)~="number" or width~=width or width<=0 or width==math.huge then
        width=#chip.item.label*7
    end
    return math.ceil(width)+PAD*2+MARK+6
end

function W.Chips(page,items)
    local controls=page:Row("",HEIGHT+TOP*2)
    local row=controls.row
    controls.rowLabel:Hide()
    controls:ClearAllPoints();controls:SetAllPoints(row)
    table.remove(page.searchEntries) -- chips carry their own entries
    local chips={}
    for i,item in ipairs(items) do
        local chip=W.Button(controls,item.label,80,HEIGHT,"choice")
        chip.item=item
        chip.label:ClearAllPoints();chip.label:SetPoint("LEFT",PAD+MARK+6,0)
        chip.label:SetJustifyH("LEFT");chip.label:SetWordWrap(false)
        chip.mark=chip:CreateTexture(nil,"OVERLAY")
        chip.mark:SetSize(MARK,MARK);chip.mark:SetPoint("LEFT",PAD,0)
        function chip:RefreshChip()
            local on=item.get()==true
            self:SetSelected(on)
            W.Paint(self.mark,on and T.primary or T.lineStrong or T.line)
        end
        chip:SetScript("OnClick",function() item.set(not item.get());page:Refresh() end)
        page.searchEntries[#page.searchEntries+1]={label=item.label,keywords=item.keywords,section=page.activeSection,row=row,kind="setting"}
        chips[i]=chip
    end
    page.refreshers[#page.refreshers+1]=function() for _,chip in ipairs(chips) do chip:RefreshChip() end end
    -- Chips keep their natural width and wrap onto as many lines as they need.
    function row:layoutChildren(width)
        local x,y=0,0
        for _,chip in ipairs(chips) do
            local chipWidth=math.min(width,Measure(chip))
            if x>0 and x+chipWidth>width then x=0;y=y+HEIGHT+GAP end
            chip:ClearAllPoints();chip:SetPoint("TOPLEFT",x,-(y+TOP));chip:SetSize(chipWidth,HEIGHT)
            chip.label:SetWidth(math.max(1,chipWidth-PAD*2-MARK-6))
            x=x+chipWidth+GAP
        end
        self:SetHeight(y+HEIGHT+TOP*2)
    end
    row.settingsChips=chips
    page.chipRows=page.chipRows or {};page.chipRows[#page.chipRows+1]=chips
    return chips
end
