local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.ForeverRecruitment,addon.ConfigWidgets,addon.InterfaceTheme

local ROW_HEIGHT=22
local WINDOW_W,WINDOW_H=470,540

---------------------------------------------------------------------------
-- Copy-name box: the name is pre-highlighted so Ctrl+C copies it.
---------------------------------------------------------------------------
function M:ShowCopyBox(name)
    local cf=self.copyFrame
    if not cf then
        cf=CreateFrame("Frame","ModeToolsRecruitmentCopyFrame",UIParent)
        cf:SetSize(320,104);cf:SetFrameStrata("DIALOG");cf:SetClampedToScreen(true)
        cf:SetMovable(true);cf:EnableMouse(true);cf:RegisterForDrag("LeftButton")
        cf:SetScript("OnDragStart",cf.StartMoving);cf:SetScript("OnDragStop",cf.StopMovingOrSizing)
        W.Texture(cf,"Window")
        if UISpecialFrames then table.insert(UISpecialFrames,"ModeToolsRecruitmentCopyFrame") end
        local title=W.Label(cf,"Press Ctrl+C to copy",nil,0,-12,320,T.text);title:SetJustifyH("CENTER")
        local hint=W.Label(cf,"Then paste it into Guild > Add Member",nil,0,-80,320,T.muted);hint:SetJustifyH("CENTER")
        local eb=CreateFrame("EditBox",nil,cf)
        eb:SetSize(260,28);eb:SetPoint("TOP",0,-38);eb:SetAutoFocus(false)
        eb:SetFontObject(GameFontHighlight);eb:SetJustifyH("CENTER");eb:SetTextInsets(6,6,0,0)
        W.Texture(eb,"InputField")
        -- Keep the text fixed to the name even if a key is typed into it.
        eb:SetScript("OnTextChanged",function(box,userInput)
            if userInput and box:GetText()~=cf.name then box:SetText(cf.name);box:HighlightText() end
        end)
        eb:SetScript("OnKeyDown",function(_,key)
            if key=="C" and IsControlKeyDown and IsControlKeyDown() then C_Timer.After(0.1,function() cf:Hide() end) end
        end)
        eb:SetScript("OnEscapePressed",function() cf:Hide() end)
        eb:SetScript("OnEnterPressed",function() cf:Hide() end)
        eb:SetScript("OnEditFocusGained",function(box) box:HighlightText() end)
        eb:SetScript("OnMouseUp",function(box) box:HighlightText() end)
        cf:SetScript("OnHide",function() eb:ClearFocus() end)
        cf.eb=eb;self.copyFrame=cf
        if self.window then cf:SetPoint("BOTTOM",self.window,"TOP",0,6) else cf:SetPoint("CENTER",0,150) end
    end
    cf.name=name;cf.eb:SetText(name);cf:Show();cf.eb:SetFocus();cf.eb:HighlightText()
end

---------------------------------------------------------------------------
-- Recruiter window
---------------------------------------------------------------------------
local function Tooltip(button,title,text)
    button:HookScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(title)
        if text then GameTooltip:AddLine(text,1,1,1,true) end
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

function M:CreateWindow()
    local f=CreateFrame("Frame","ModeToolsRecruitmentFrame",UIParent)
    self.window=f
    f:SetSize(WINDOW_W,WINDOW_H);f:SetPoint("CENTER");f:SetFrameStrata("HIGH");f:SetClampedToScreen(true)
    f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
    f:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames,"ModeToolsRecruitmentFrame") end
    W.Texture(f,"Window")
    f.title=W.Heading(f,"Recruiter",T.fontSize.section,16,-14,300,T.text)

    local close=W.Button(f,"Close",64,24,"secondary");close:SetPoint("TOPRIGHT",-12,-10)
    close:SetScript("OnClick",function() f:Hide() end)
    local settings=W.Button(f,"Settings",76,24,"secondary");settings:SetPoint("RIGHT",close,"LEFT",-6,0)
    settings:SetScript("OnClick",function()
        if not addon.configWindow or not addon.configWindow:IsShown() then addon:ToggleConfig() end
        if addon.SelectConfigPage then addon:SelectConfigPage(M.id) end
    end)

    local scan=W.Button(f,"Scan",104,28);scan:SetPoint("TOPLEFT",16,-50)
    scan:SetScript("OnClick",function() M:Scan() end)
    Tooltip(scan,"Scan","Clears the candidate list, then runs the next Who search.")
    local invite=W.Button(f,"Invite Next",104,28);invite:SetPoint("LEFT",scan,"RIGHT",6,0)
    invite:SetScript("OnClick",function() M:InviteCandidate(1) end)
    local nextButton=W.Button(f,"Next",104,28,"primary");nextButton:SetPoint("LEFT",invite,"RIGHT",6,0)
    nextButton:SetScript("OnClick",function() M:Next() end)
    Tooltip(nextButton,"Next","Shows the next candidate's name ready to copy (Ctrl+C), or runs the next search if the list is empty.")
    local clear=W.Button(f,"Clear",80,28,"secondary");clear:SetPoint("LEFT",nextButton,"RIGHT",6,0)
    clear:SetScript("OnClick",function() M:ClearCandidates() end)
    f.scan,f.invite,f.next,f.clear=scan,invite,nextButton,clear

    f.status=W.Label(f,"",nil,16,-90,WINDOW_W-32,T.secondary);f.status:SetWordWrap(true)
    f.listHeader=W.Label(f,"",nil,16,-124,WINDOW_W-32,T.text)

    local list=CreateFrame("Frame",nil,f)
    list:SetPoint("TOPLEFT",12,-144);list:SetPoint("BOTTOMRIGHT",-12,36)
    W.Texture(list,"InsetPanel")
    local scroll=CreateFrame("ScrollFrame",nil,list)
    scroll:SetPoint("TOPLEFT",4,-4);scroll:SetPoint("BOTTOMRIGHT",-14,4)
    local content=CreateFrame("Frame",nil,scroll)
    content:SetSize(WINDOW_W-50,1);scroll:SetScrollChild(content)
    local bar=CreateFrame("Slider",nil,list)
    bar:SetPoint("TOPRIGHT",-4,-4);bar:SetPoint("BOTTOMRIGHT",-4,4);bar:SetWidth(4)
    bar:SetOrientation("VERTICAL");bar:SetValueStep(ROW_HEIGHT);W.ScrollThumb(bar,40)
    bar:SetScript("OnValueChanged",function(_,value) scroll:SetVerticalScroll(value) end)
    local function Wheel(_,delta) bar:SetValue(bar:GetValue()-delta*ROW_HEIGHT*3) end
    for _,frame in ipairs({list,scroll,content}) do frame:EnableMouseWheel(true);frame:SetScript("OnMouseWheel",Wheel) end
    f.scroll,f.content,f.bar,f.rows=scroll,content,bar,{}

    f.stats=W.Label(f,"",nil,16,-(WINDOW_H-24),WINDOW_W-32,T.muted)

    -- Show the Who cooldown on the Scan button.
    f:SetScript("OnUpdate",function(self,elapsed)
        self.tick=(self.tick or 0)+elapsed
        if self.tick<0.2 then return end
        self.tick=0
        local cd=M:WhoCooldownRemaining()
        if cd>0 then scan.label:SetText(string.format("Scan (%.0f)",math.ceil(cd)));scan:SetEnabled(false)
        else scan.label:SetText("Scan");scan:SetEnabled(true) end
    end)
    f:SetScript("OnShow",function() M:RefreshWindow() end)
    return f
end

local function GetRow(f,i)
    local row=f.rows[i]
    if row then return row end
    row=CreateFrame("Frame",nil,f.content)
    row:SetSize(WINDOW_W-50,ROW_HEIGHT);row:SetPoint("TOPLEFT",0,-(i-1)*ROW_HEIGHT)
    if i%2==0 then W.Fill(row,T.hover,"BACKGROUND") end
    row.name=W.Label(row,"",nil,4,-4,130)
    row.level=W.Label(row,"",nil,138,-4,28,T.secondary)
    row.zone=W.Label(row,"",nil,170,-4,110,T.muted);row.zone:SetWordWrap(false)
    row.never=W.Button(row,"X",24,20,"secondary");row.never:SetPoint("RIGHT",-2,0)
    row.never:SetScript("OnClick",function(self) M:SkipCandidate(self:GetParent().index,true) end)
    Tooltip(row.never,"Never invite this player")
    row.skip=W.Button(row,"Skip",44,20,"secondary");row.skip:SetPoint("RIGHT",row.never,"LEFT",-3,0)
    row.skip:SetScript("OnClick",function(self) M:SkipCandidate(self:GetParent().index,false) end)
    row.invite=W.Button(row,"Invite",56,20);row.invite:SetPoint("RIGHT",row.skip,"LEFT",-3,0)
    row.invite:SetScript("OnClick",function(self) M:InviteCandidate(self:GetParent().index) end)
    f.rows[i]=row
    return row
end

function M:StatsText()
    local s=self.db.records
    return string.format("Invited: %d   Joined: %d   Declined: %d",s.invited,s.joined,s.declined)
end
function M:QueueText()
    local remaining=self:QueueRemaining()
    if self.queue and remaining>0 then return string.format("%d searches left in this scan",remaining)
    elseif self.queue then return "scan complete - next Scan starts over" end
    return "no scan running"
end

function M:RefreshWindow()
    local f=self.window
    if not f or not f:IsShown() or not self.candidates then return end
    f.status:SetText(self.status or "")
    for i,c in ipairs(self.candidates) do
        local row=GetRow(f,i)
        row.index=i
        row.name:SetText(c.name);row.name:SetTextColor(self:ClassColor(c.classFile))
        row.level:SetText(c.level);row.zone:SetText(c.zone)
        row:Show()
    end
    for i=#self.candidates+1,#f.rows do f.rows[i]:Hide() end
    local height=math.max(1,#self.candidates*ROW_HEIGHT)
    f.content:SetHeight(height)
    local maximum=math.max(0,height-f.scroll:GetHeight())
    f.bar:SetMinMaxValues(0,maximum);f.bar:SetValue(math.min(f.bar:GetValue(),maximum));f.bar:SetShown(maximum>0)
    f.listHeader:SetText(string.format("Unguilded candidates: %d   (%s)",#self.candidates,self:QueueText()))
    f.stats:SetText(self:StatsText())
    local ready=self.active==true
    f.invite:SetEnabled(ready and #self.candidates>0);f.next:SetEnabled(ready)
end

function M:ToggleWindow()
    if not self.window then self:CreateWindow() end
    self.window:SetShown(not self.window:IsShown())
end

SLASH_MODETOOLSRECRUIT1="/ptgr"
SlashCmdList.MODETOOLSRECRUIT=function()
    if addon.initialized then M:ToggleWindow() end
end

---------------------------------------------------------------------------
-- Settings page
---------------------------------------------------------------------------
function M:CreateConfigPage(parent)
    local page=W.Page(parent,620);self.page=page
    local function Button(label,text,fn,width)
        local b=W.Button(page:Row(label,48),text,width or 180,28);b:SetPoint("LEFT")
        b:SetScript("OnClick",function() fn();page:Refresh() end);return b
    end
    local function Numeric(label,key,low,high)
        local input=W.NumericInput(page:Row(label,48),function() return self.db[key] end,function(v) self:SetOption(key,v) end,low,high,70)
        input:SetPoint("LEFT");page.refreshers[#page.refreshers+1]=function() input:Refresh() end
    end

    page:Section("Recruiter")
    Button("Recruiter Window","Open Recruiter",function() self:ToggleWindow() end)
    local status=W.Label(page:Row("Recruitment Status",72),"",nil,0,-4,390,T.muted);status:SetWordWrap(true)
    page.refreshers[#page.refreshers+1]=function() status:SetText(self.status or "") end
    local stats=W.Label(page:Row("Statistics",48),"",nil,0,-4,390,T.muted)
    page.refreshers[#page.refreshers+1]=function() stats:SetText(self:StatsText()) end
    local note=W.Label(page:Row("How It Works",110),"Each Scan click clears the list and runs one Who search (also /ptgr). Invite shows the name highlighted: press Ctrl+C, then paste it into Guild > Add Member. Capped results are split and searched again.",nil,0,-4,390,T.muted)
    note:SetWordWrap(true)

    page:Section("Search")
    Numeric("Minimum Level","minLevel",1,function() return self.db.maxLevel end)
    Numeric("Maximum Level","maxLevel",function() return self.db.minLevel end,60)
    Numeric("Levels Per Search","chunkSize",1,60)
    local classButtons=page:Row("Classes",48)
    local all=W.Button(classButtons,"All",80,28,"secondary");all:SetPoint("LEFT")
    all:SetScript("OnClick",function() for _,c in ipairs(self.CLASSES) do self.db.classes[c]=true end;self:ResetScan();self:Refresh() end)
    local none=W.Button(classButtons,"None",80,28,"secondary");none:SetPoint("LEFT",all,"RIGHT",8,0)
    none:SetScript("OnClick",function() for _,c in ipairs(self.CLASSES) do self.db.classes[c]=false end;self:ResetScan();self:Refresh() end)
    local items={}
    for _,classFile in ipairs(self.CLASSES) do
        items[#items+1]={label=self:ClassName(classFile),get=function() return self:IsClassEnabled(classFile) end,
            set=function(value) self:SetClassEnabled(classFile,value) end}
    end
    local cells=page:ToggleGrid(items)
    for i,classFile in ipairs(self.CLASSES) do cells[i].label:SetTextColor(self:ClassColor(classFile)) end

    page:Section("Invites")
    page:ToggleGrid({{label="Whisper After Invite",get=function() return self.db.whisperEnabled end,
        set=function(value) self:SetOption("whisperEnabled",value) end}})
    local row=page:Row("Whisper Text (Enter saves)",48)
    local e=CreateFrame("EditBox",nil,row);e:SetSize(340,28);e:SetPoint("LEFT")
    e:SetFontObject(GameFontHighlight);e:SetAutoFocus(false);e:SetMaxLetters(200);e:SetTextInsets(6,6,0,0)
    W.Texture(e,"InputField")
    local function reset() e:SetText(self.db.message);e:ClearFocus() end
    e:SetScript("OnEnterPressed",function() self:SetOption("message",e:GetText());reset() end)
    e:SetScript("OnEscapePressed",reset)
    page.refreshers[#page.refreshers+1]=function() if not e:HasFocus() then e:SetText(self.db.message) end end
    Numeric("Re-invite After (days)","reinviteDays",0,365)

    page:Section("History")
    Button("Invited Players","Clear Invite History",function() self:ClearInvited() end)
    Button("Never-Invite List","Clear Never-Invite List",function() self:ClearBlacklist() end)
    Button("Invite Statistics","Reset Statistics",function() self:ResetStats() end)
    page:Finish();return page
end
