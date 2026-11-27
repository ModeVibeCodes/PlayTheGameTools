local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
-- The Cooldown Profits window and settings page. The page holds only the
-- reminder; the auction house cut and how to count your own materials live
-- in the window, next to the numbers they change.
local M,D,W,T=addon.CooldownProfits,addon.CooldownProfitsData,addon.ConfigWidgets,addon.InterfaceTheme

M.WINDOW_W,M.WINDOW_H=900,660
M.PAGE_NOTE="Prices come from Auctionator. Scan the auction house with Auctionator and the window updates. Open each profession window once so the window knows your recipes and their timers."
local ROW_H,MAX_ROWS=26,#D.RECIPES
-- name, profession, materials, sells for, profit, cooldown, per day, status
local COLUMNS={{"Cooldown craft",220,"LEFT"},{"Profession",100,"LEFT"},{"Materials",82,"RIGHT"},{"Sells for",88,"RIGHT"},
    {"Profit",82,"RIGHT"},{"Cooldown",64,"RIGHT"},{"Per day",86,"RIGHT"},{"Status",146,"RIGHT"}}
local GAP=6
local VIEW_CHOICES={{label="Learned",value="learned",width=90},{label="My professions",value="mine",width=124},{label="All",value="all",width=60}}
local SORT_CHOICES={{label="Per day",value="day",width=86},{label="Per craft",value="craft",width=90}}

local function Short(name) return (name:gsub("^Transmute: ","")) end
local function ItemName(id) return D.ITEMS[id] or ("Item "..id) end
local function Hex(color) return string.format("|cff%02x%02x%02x",color[1]*255,color[2]*255,color[3]*255) end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function Panel(parent,width,height)
    local frame=CreateFrame("Frame",nil,parent);frame:SetSize(width,height)
    W.Fill(frame,T.panel or T.surface,"BACKGROUND")
    W.Outline(frame,T.line,"BORDER")
    return frame
end

local function CheckBox(parent,text,get,set,refreshers)
    local cell=CreateFrame("Button",nil,parent);cell:SetSize(190,30)
    cell:EnableMouse(true);cell:RegisterForClicks("LeftButtonUp")
    local box=W.Button(cell,"",24,24,"checkbox");box:SetPoint("LEFT",-4,0)
    W.Label(cell,text,nil,22,-8,168)
    local function Click() set(not get()) end
    cell:SetScript("OnClick",Click);box:SetScript("OnClick",Click)
    cell:HookScript("OnEnter",function() box.hovered=true;box:RefreshAppearance() end)
    cell:HookScript("OnLeave",function() box.hovered=false;box:RefreshAppearance() end)
    refreshers[#refreshers+1]=function() box:SetSelected(get()) end
    return cell
end

local function Choices(parent,label,choices,key,refreshers)
    local host=CreateFrame("Frame",nil,parent)
    local title=W.Label(host,label,nil,0,0,40,T.secondary)
    title:ClearAllPoints();title:SetPoint("LEFT",0,0)
    local buttons=CreateFrame("Frame",nil,host)
    buttons:SetPoint("LEFT",44,0);buttons:SetSize(1,30)
    local width=0
    for _,choice in ipairs(choices) do width=width+choice.width+8 end
    local _,refresh=W.Exclusive(buttons,choices,function() return M.db[key] end,function(value) M:SetOption(key,value) end)
    refreshers[#refreshers+1]=refresh
    host:SetSize(44+width,30)
    return host
end

-- Breakdown on hover: materials, sale, cut, profit and the timer.
local function ShowTooltip(row)
    local entry=row.entry
    if not entry or not GameTooltip then return end
    local recipe=entry.recipe
    GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
    GameTooltip:SetText(recipe.name)
    if recipe.note then GameTooltip:AddLine(recipe.note,0.7,0.7,0.7) end
    local free=M.db.freeMaterials
    for _,reagent in ipairs(recipe.reagents) do
        local price=not free and entry.cost and M.lastPrices and M.lastPrices[reagent[1]] and M.lastPrices[reagent[1]].price
        GameTooltip:AddDoubleLine(reagent[2].." × "..ItemName(reagent[1]),free and "counted as free" or (price and D.Money(-price*reagent[2]) or "no price"),1,1,1,1,1,1)
    end
    if D.Priced(entry) then
        GameTooltip:AddDoubleLine("Sells: "..recipe.output[2].." × "..ItemName(recipe.output[1]),D.Money(entry.gross),1,1,1,1,1,1)
        if entry.cut>0 then GameTooltip:AddDoubleLine("Auction house cut, 5%",D.Money(-entry.cut),1,1,1,1,1,1) end
        GameTooltip:AddDoubleLine("Profit per craft",D.Money(entry.profit),1,0.82,0,1,1,1)
        GameTooltip:AddDoubleLine("Every "..D.Duration(entry.seconds)..", so per day",D.Money(entry.perDay),1,0.82,0,1,1,1)
    end
    if not entry.measured then
        GameTooltip:AddLine("The cooldown is the usual length until you craft this once with its window open; then it's the length you saw.",0.7,0.7,0.7,true)
    end
    local shared={}
    for _,other in ipairs(D.RECIPES) do
        if other~=recipe and D.Shares(recipe,other,M:ObservedShares()) then shared[#shared+1]=Short(other.name) end
    end
    if #shared>0 then GameTooltip:AddLine("Shares a timer with "..table.concat(shared,", ")..".",0.7,0.7,0.7,true) end
    for _,id in ipairs(entry.missing) do
        GameTooltip:AddLine(ItemName(id).." had no listings in Auctionator's last scan, so this can't be priced yet.",1,0.6,0.4,true)
    end
    for _,id in ipairs(entry.stale) do
        local age=M.lastPrices and M.lastPrices[id] and M.lastPrices[id].age
        GameTooltip:AddLine(ItemName(id).."'s price is "..(age and age<=21 and (age.." days") or "over 21 days").." old. Scan again for a current number.",0.9,0.75,0.4,true)
    end
    GameTooltip:Show()
end

function M:CreateWindow()
    if self.window then return self.window end
    local window=W.BrowserWindow({name="PlayTheGameToolsCooldownProfitsWindow",title="Cooldown Profits",
        width=M.WINDOW_W,height=M.WINDOW_H,module=self,
        onShow=function()
            M:ReadProfessions();M:ScanSaltShaker();M:ScanTradeSkill();M:RenderWindow()
            if addon.QuickActions then addon.QuickActions:SetActive("cooldownProfits",true) end
        end,
        onHide=function() if addon.QuickActions then addon.QuickActions:SetActive("cooldownProfits",false) end end})
    self.window=window
    local body,refreshers=window.body,{}
    window.refreshers=refreshers
    local width=M.WINDOW_W-32-(window.blizzardBackdrop and 16 or 0)

    window.status=W.Label(body,"",nil,0,0,width,T.muted);window.status:SetWordWrap(false)

    local earn=Panel(body,310,100);earn:SetPoint("TOPLEFT",0,-24)
    W.Label(earn,"Your learned cooldowns earn",nil,12,-10,290,T.muted)
    window.earn=W.Heading(earn,"",20,12,-28,290,T.text)
    window.earnLines={}
    for i=1,4 do
        local line=W.Label(earn,"","GameFontHighlightSmall",12,-52-(i-1)*12,290,T.secondary);line:SetWordWrap(false)
        window.earnLines[i]=line
    end
    local upgrades=Panel(body,width-322,100);upgrades:SetPoint("TOPLEFT",322,-24)
    W.Label(upgrades,"Worth learning",nil,12,-10,width-346,T.muted)
    window.upgradeLines={}
    for i=1,3 do
        local line=W.Label(upgrades,"",nil,12,-30-(i-1)*22,width-346,T.text);line:SetWordWrap(false)
        window.upgradeLines[i]=line
    end

    local controls=CreateFrame("Frame",nil,body);controls:SetPoint("TOPLEFT",0,-134);controls:SetSize(width,30)
    local show=Choices(controls,"Show",VIEW_CHOICES,"view",refreshers);show:SetPoint("LEFT",0,0)
    local sort=Choices(controls,"Sort",SORT_CHOICES,"sort",refreshers);sort:SetPoint("LEFT",show,"RIGHT",28,0)
    local options=CreateFrame("Frame",nil,body);options:SetPoint("TOPLEFT",0,-168);options:SetSize(width,30)
    local cut=CheckBox(options,"Take off the 5% auction house cut",function() return M.db.cut end,function(v) M:SetOption("cut",v) end,refreshers)
    cut:SetWidth(260);cut:SetPoint("LEFT",4,0)
    local free=CheckBox(options,"Count my own materials as free",function() return M.db.freeMaterials end,function(v) M:SetOption("freeMaterials",v) end,refreshers)
    free:SetWidth(260);free:SetPoint("LEFT",cut,"RIGHT",16,0)

    local head=CreateFrame("Frame",nil,body);head:SetPoint("TOPLEFT",0,-206);head:SetSize(width,20)
    local x=0
    for _,column in ipairs(COLUMNS) do
        local label=W.Label(head,column[1],nil,x,-4,column[2]-GAP,T.muted);label:SetJustifyH(column[3])
        x=x+column[2]
    end
    local divider=W.Fill(head,T.line,"BORDER");divider:ClearAllPoints()
    divider:SetPoint("BOTTOMLEFT");divider:SetPoint("BOTTOMRIGHT");divider:SetHeight(1)

    window.rows={}
    for i=1,MAX_ROWS do
        local row=CreateFrame("Frame",nil,body);row:SetSize(width,ROW_H)
        row:SetPoint("TOPLEFT",0,-226-(i-1)*ROW_H)
        row.hover=W.Fill(row,T.surface,"BACKGROUND");row.hover:Hide()
        local line=W.Fill(row,T.line,"BORDER");line:ClearAllPoints()
        line:SetPoint("BOTTOMLEFT");line:SetPoint("BOTTOMRIGHT");line:SetHeight(1)
        row.cells={}
        x=0
        for c,column in ipairs(COLUMNS) do
            local cell=W.Label(row,"",nil,x,-7,column[2]-GAP,T.text);cell:SetJustifyH(column[3]);cell:SetWordWrap(false)
            row.cells[c]=cell
            x=x+column[2]
        end
        row:EnableMouse(true)
        row:SetScript("OnEnter",function(self) self.hover:Show();ShowTooltip(self) end)
        row:SetScript("OnLeave",function(self) self.hover:Hide();if GameTooltip then GameTooltip:Hide() end end)
        row:Hide()
        window.rows[i]=row
    end
    window.empty=W.Label(body,"",nil,0,-236,width,T.muted)
    W.Label(body,"Hover a row for its breakdown. A craft with no price says so instead of guessing.",nil,0,-232-MAX_ROWS*ROW_H,width,T.muted)
    return window
end

function M:RenderWindow()
    local window=self.window
    if not window then return end
    for _,refresh in ipairs(window.refreshers) do refresh() end
    local entries,priced=self:Entries()
    local now=M.Now()

    local known={}
    for _,profession in ipairs(D.PROFESSIONS) do
        local mine=self.professions and self.professions[profession.key]
        if mine then known[#known+1]=profession.name.." "..mine.rank end
    end
    local status=#known>0 and table.concat(known," · ") or "No Alchemy, Tailoring or Leatherworking on this character"
    status=status..(priced and " · Prices from Auctionator's last scan" or " · Auctionator isn't loaded, so there are no prices yet")
    window.status:SetText(status)

    local plan,total,ups=self:Summary(entries)
    window.earn:SetText(#plan>0 and (D.Money(total).." a day") or "—")
    for i,line in ipairs(window.earnLines) do
        local entry=plan[i]
        line:SetText(entry and (Short(entry.recipe.name).."  "..D.Money(entry.perDay)) or
            (i==1 and #plan==0 and (priced and "No learned cooldowns with prices yet." or "Prices appear after an Auctionator scan.") or ""))
    end
    local accent=Hex(T.primary)
    for i,line in ipairs(window.upgradeLines) do
        local up=ups[i]
        if up then
            local why
            if up.rival then why="shares a timer with "..Short(up.rival.recipe.name)..", which earns more"
            elseif up.replaces then why="takes the shared timer from "..Short(up.replaces.recipe.name)
            else why="its own timer, so it adds to what you earn now" end
            line:SetText(accent.."+"..D.Money(up.gain,true).." a day|r   "..Short(up.entry.recipe.name).."  ·  "..why)
        else
            line:SetText(i==1 and (priced and "Nothing you could learn beats what you have." or "Prices appear after an Auctionator scan.") or "")
        end
    end

    local best={}
    for _,entry in ipairs(plan) do best[entry]=true end
    local rows=self:Rows(entries)
    for i,row in ipairs(window.rows) do
        local entry=rows[i]
        row.entry=entry
        row:SetShown(entry~=nil)
        if entry then
            local recipe,c=entry.recipe,row.cells
            local priceOK=D.Priced(entry)
            c[1]:SetText(recipe.name..(best[entry] and ("  "..accent.."Your best|r") or ""))
            c[2]:SetText(D.PROFESSION_BY_KEY[recipe.profession].name)
            c[3]:SetText(priceOK and D.Money(entry.cost) or "—")
            c[4]:SetText((priceOK and D.Money(entry.gross) or "No price")..(#entry.stale>0 and " |cffe6c062*|r" or ""))
            c[5]:SetText(priceOK and D.Money(entry.profit) or "—")
            c[6]:SetText((entry.measured and "" or "~")..D.Duration(entry.seconds))
            c[7]:SetText(priceOK and D.Money(entry.perDay) or "—")
            local text,tone=self:Status(entry,now)
            c[8]:SetText(text);c[8]:SetTextColor(unpack(T[tone] or T.text))
            c[4]:SetTextColor(unpack(priceOK and T.text or T.muted))
        end
    end
    window.empty:SetText(#rows==0 and (self.db.view=="learned" and "No learned cooldowns yet. Open your profession windows once, or choose My professions." or
        "No cooldown crafts for your professions. Choose All to see every one.") or "")
end

function M:OpenWindow()
    if not self.active then return false end
    local window=self:CreateWindow()
    if window:IsShown() then self:RenderWindow() else window:Show() end
    return true
end
function M:ToggleWindow()
    if self.window and self.window:IsShown() then self.window:Hide() else self:OpenWindow() end
end

---------------------------------------------------------------------------
-- Settings page: the page header's Open Cooldown Profits button (openLabel)
-- opens the window; the page holds only the reminder.
---------------------------------------------------------------------------
function M:CreateConfigPage(parent)
    local page=W.Page(parent,480);self.page=page
    page:Section("Reminders")
    page:ToggleGrid({{label="Tell me when a cooldown is ready",get=function() return self.db.remind end,
        set=function(v) self:SetOption("remind",v) end}},{maxColumns=1,minimumCellWidth=320})
    page:ToggleGrid({{label="Only for the most profitable one",get=function() return self.db.remindBest end,
        set=function(v) self:SetOption("remindBest",v) end}},{maxColumns=1,minimumCellWidth=320})
    local bestRow=page.rows[#page.rows]
    bestRow.visibleWhen=function() return self.db.remind end
    page.searchEntries[#page.searchEntries].available=bestRow.visibleWhen
    page.refreshers[#page.refreshers+1]=function() page:Layout() end

    page:Section("Prices")
    local controls=page:Row("",64)
    table.remove(page.searchEntries) -- an empty label would be a blank search result
    local row=controls.row
    controls.rowLabel:Hide();row.divider:Hide()
    controls:ClearAllPoints();controls:SetAllPoints(row)
    local note=W.Label(controls,M.PAGE_NOTE,nil,0,-6,520,T.muted);note:SetWordWrap(true)
    function row:layoutChildren(width) note:SetWidth(width) end
    page.note=note
    page.searchEntries[#page.searchEntries+1]={label="Open Cooldown Profits",row=row,kind="setting",
        flash=function() return addon.configWindow and addon.configWindow.moduleHeader.openButton end,
        keywords={"transmute","arcanite","mooncloth","salt shaker","auctionator","profession cooldowns","profit"}}
    page:Finish()
    return page
end
