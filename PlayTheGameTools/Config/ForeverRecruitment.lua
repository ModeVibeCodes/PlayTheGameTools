local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W,T=addon.ForeverRecruitment,addon.ConfigWidgets,addon.InterfaceTheme

local ROW_HEIGHT=22
local WINDOW_W,WINDOW_H=536,712 -- room for the row Whisper button and message box
local MESSAGE_H=84

---------------------------------------------------------------------------
-- Copy-name box: the name is pre-highlighted so Ctrl+C copies it.
---------------------------------------------------------------------------
function M:ShowCopyBox(name)
    local cf=self.copyFrame
    if not cf then
        cf=CreateFrame("Frame","PlayTheGameToolsRecruitmentCopyFrame",UIParent)
        cf:SetSize(320,104);cf:SetFrameStrata("FULLSCREEN_DIALOG");cf:SetClampedToScreen(true)
        cf:SetMovable(true);cf:EnableMouse(true);cf:RegisterForDrag("LeftButton")
        cf:SetScript("OnDragStart",cf.StartMoving);cf:SetScript("OnDragStop",cf.StopMovingOrSizing)
        W.Texture(cf,"Window")
        if UISpecialFrames then table.insert(UISpecialFrames,"PlayTheGameToolsRecruitmentCopyFrame") end
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
    local f=CreateFrame("Frame","PlayTheGameToolsRecruitmentFrame",UIParent)
    self.window=f
    -- Same strata as the settings window (DIALOG); raised on show so it opens in front.
    f:SetSize(WINDOW_W,WINDOW_H);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
    if f.SetToplevel then f:SetToplevel(true) end
    f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
    f:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames,"PlayTheGameToolsRecruitmentFrame") end
    W.Texture(f,"Window")
    f.title=W.Heading(f,"Recruiter",T.fontSize.section,16,-14,150,T.text)

    local close=W.Button(f,"Close",64,24,"secondary");close:SetPoint("TOPRIGHT",-12,-10)
    close:SetScript("OnClick",function() f:Hide() end)
    local settings=W.Button(f,"Settings",76,24,"secondary");settings:SetPoint("RIGHT",close,"LEFT",-6,0)
    settings:SetScript("OnClick",function()
        if not addon.configWindow or not addon.configWindow:IsShown() then addon:ToggleConfig() end
        if addon.SelectConfigPage then addon:SelectConfigPage(M.id) end
    end)

    -- Module switch, so recruiting can be turned on without the settings window.
    local power=W.Button(f,"",44,24,"toggle");power:SetPoint("RIGHT",settings,"LEFT",-10,0)
    power:SetScript("OnClick",function() if M:OutsideCombat() then addon:SetModuleEnabled(M.id,not M.enabled);M:RefreshWindow() end end)
    f.power=power
    local powerLabel=W.Label(f,"",nil,0,0,70,T.muted);powerLabel:ClearAllPoints()
    powerLabel:SetPoint("RIGHT",power,"LEFT",-6,0);powerLabel:SetJustifyH("RIGHT")
    f.refreshers={}
    local function Refresher(fn) f.refreshers[#f.refreshers+1]=fn end
    Refresher(function()
        power:SetSelected(M.enabled==true);powerLabel:SetText(M.enabled and "Enabled" or "Disabled")
        powerLabel:SetTextColor(unpack(W.StateColor(M.enabled==true)))
    end)

    -- Search settings: level range, levels per search, classes and whisper.
    local function Numeric(key,low,high,width)
        local input=W.NumericInput(f,function() return M.db[key] end,function(v) M:SetOption(key,v) end,low,high,width or 44)
        Refresher(function() input:Refresh() end);return input
    end
    local levelLabel=W.Label(f,"Level range",nil,16,-56,90,T.secondary)
    local minInput=Numeric("minLevel",1,function() return M.db.maxLevel end)
    minInput:SetPoint("TOPLEFT",104,-50)
    local to=W.Label(f,"to",nil,0,0,20,T.secondary);to:ClearAllPoints();to:SetPoint("LEFT",minInput,"RIGHT",6,0)
    local maxInput=Numeric("maxLevel",function() return M.db.minLevel end,60)
    maxInput:SetPoint("LEFT",minInput,"RIGHT",28,0)
    local chunkLabel=W.Label(f,"Levels per search",nil,0,0,120,T.secondary);chunkLabel:ClearAllPoints()
    chunkLabel:SetPoint("LEFT",maxInput,"RIGHT",24,0)
    local chunkInput=Numeric("chunkSize",1,60);chunkInput:SetPoint("LEFT",chunkLabel,"RIGHT",4,0)
    f.minInput,f.maxInput,f.chunkInput=minInput,maxInput,chunkInput

    local function CheckBox(text,get,set,x,y,r,g,b)
        local cell=CreateFrame("Button",nil,f);cell:SetSize(140,24);cell:SetPoint("TOPLEFT",x,y)
        cell:EnableMouse(true);cell:RegisterForClicks("LeftButtonUp")
        local box=W.Button(cell,"",24,24,"checkbox");box:SetPoint("LEFT",-4,0)
        local label=W.Label(cell,text,nil,22,-5,116)
        if r then label:SetTextColor(r,g,b) end
        local function Click() set(not get()) end
        cell:SetScript("OnClick",Click);box:SetScript("OnClick",Click)
        cell:HookScript("OnEnter",function() box.hovered=true;box:RefreshAppearance() end)
        cell:HookScript("OnLeave",function() box.hovered=false;box:RefreshAppearance() end)
        Refresher(function() box:SetSelected(get()) end)
        return cell,label
    end
    W.Label(f,"Classes",nil,16,-94,90,T.secondary)
    local all=W.Button(f,"All",56,22,"secondary");all:SetPoint("TOPLEFT",104,-90)
    all:SetScript("OnClick",function() for _,c in ipairs(M.CLASSES) do M.db.classes[c]=true end;M:ResetScan();M:Refresh() end)
    local none=W.Button(f,"None",56,22,"secondary");none:SetPoint("LEFT",all,"RIGHT",6,0)
    none:SetScript("OnClick",function() for _,c in ipairs(M.CLASSES) do M.db.classes[c]=false end;M:ResetScan();M:Refresh() end)
    f.classChecks={}
    for i,classFile in ipairs(M.CLASSES) do
        local r,g,b=M:ClassColor(classFile)
        f.classChecks[i]=CheckBox(M:ClassName(classFile),function() return M:IsClassEnabled(classFile) end,
            function(value) M:SetClassEnabled(classFile,value) end,20+((i-1)%3)*146,-120-math.floor((i-1)/3)*26,r,g,b)
    end

    W.Label(f,"Whisper message",nil,16,-208,WINDOW_W-32,T.secondary)
    local holder=CreateFrame("Frame",nil,f);holder:SetSize(WINDOW_W-48,MESSAGE_H);holder:SetPoint("TOPLEFT",24,-226)
    W.Texture(holder,"InputField")
    local viewHeight=MESSAGE_H-10
    local messageScroll=CreateFrame("ScrollFrame",nil,holder)
    messageScroll:SetPoint("TOPLEFT",6,-5);messageScroll:SetPoint("BOTTOMRIGHT",-6,5);messageScroll:EnableMouseWheel(true)
    local message=CreateFrame("EditBox",nil,messageScroll);message:SetSize(WINDOW_W-60,viewHeight);message:SetMultiLine(true)
    message:SetFontObject(GameFontHighlight);message:SetAutoFocus(false);message:SetMaxLetters(M.MESSAGE_LETTERS)
    addon.Media:BindInterfaceFont(message,GameFontHighlight)
    messageScroll:SetScrollChild(message)
    local function ScrollMessage(offset)
        messageScroll:SetVerticalScroll(math.max(0,math.min(offset,message:GetHeight()-viewHeight)))
    end
    -- The box grows with its text and scrolls inside the fixed input field.
    local function ResizeMessage()
        local _,fontHeight=message:GetFont()
        local lines=message:GetNumLines()
        local height=math.max(viewHeight,lines*(fontHeight or 14)+math.max(0,lines-1)*message:GetSpacing()+4)
        if message:GetHeight()~=height then message:SetHeight(height) end
        ScrollMessage(messageScroll:GetVerticalScroll())
    end
    message:SetScript("OnTextChanged",ResizeMessage)
    message:SetScript("OnCursorChanged",function(_,_,y,_,cursorHeight)
        ResizeMessage()
        local top,offset=-y,messageScroll:GetVerticalScroll()
        if top<offset then ScrollMessage(top)
        elseif top+cursorHeight>offset+viewHeight then ScrollMessage(top+cursorHeight-viewHeight) end
    end)
    messageScroll:SetScript("OnMouseWheel",function(_,delta) ScrollMessage(messageScroll:GetVerticalScroll()-delta*24) end)
    local function SaveMessage()
        local text=M.CleanMessage(message:GetText())
        if text~=M.db.message then M:SetOption("message",text) end
    end
    local function ResetMessage() message:SetText(M.db.message);message:ClearFocus() end
    message:SetScript("OnEnterPressed",function() SaveMessage();ResetMessage() end)
    message:SetScript("OnEditFocusLost",SaveMessage)
    message:SetScript("OnEscapePressed",ResetMessage)
    Refresher(function() if not message:HasFocus() then message:SetText(M.db.message) end end)
    f.message,f.SaveMessage=message,SaveMessage

    local TOP=-326 -- action buttons, status and list sit below the settings
    local scan=W.Button(f,"Scan",104,28);scan:SetPoint("TOPLEFT",16,TOP)
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

    f.status=W.Label(f,"",nil,16,TOP-40,WINDOW_W-32,T.secondary);f.status:SetWordWrap(true)
    f.listHeader=W.Label(f,"",nil,16,TOP-74,WINDOW_W-32,T.text)

    local list=CreateFrame("Frame",nil,f)
    list:SetPoint("TOPLEFT",12,TOP-94);list:SetPoint("BOTTOMRIGHT",-12,36)
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
    f:SetScript("OnShow",function() M:RefreshWindow();M:SyncQuickAction() end)
    f:SetScript("OnHide",function() M:SyncQuickAction() end)
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
    row.whisper=W.Button(row,"Whisper",64,20);row.whisper:SetPoint("RIGHT",row.invite,"LEFT",-3,0)
    -- Clicking a button doesn't take focus from the box, so save unsaved edits first.
    row.whisper:SetScript("OnClick",function(self) f.SaveMessage();M:WhisperCandidate(self:GetParent().index) end)
    Tooltip(row.whisper,"Whisper this player","Sends the message above instead of inviting. Long messages go out as several whispers.")
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
    for _,refresh in ipairs(f.refreshers) do refresh() end
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

function M:OpenWindow()
    if not self.window then self:CreateWindow() end
    local f=self.window
    -- Open beside the settings window when it is showing, otherwise centered.
    f:ClearAllPoints()
    if addon.configWindow and addon.configWindow:IsShown() then f:SetPoint("LEFT",addon.configWindow,"RIGHT",8,0)
    else f:SetPoint("CENTER") end
    f:Show()
    if f.Raise then f:Raise() end
end
function M:ToggleWindow()
    if self.window and self.window:IsShown() then self.window:Hide() else self:OpenWindow() end
end

SLASH_PLAYTHEGAMETOOLSRECRUIT1="/ptgr"
SlashCmdList.PLAYTHEGAMETOOLSRECRUIT=function()
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

    -- Searching, status, statistics and invite options live in the Recruiter
    -- window; this page only opens it and clears stored history.
    page:Section("Recruiter")
    Button("Recruiter Window","Open Recruiter",function() self:OpenWindow() end)

    page:Section("History")
    Button("Invited Players","Clear Invite History",function() self:ClearInvited() end)
    Button("Never-Invite List","Clear Never-Invite List",function() self:ClearBlacklist() end)
    Button("Invite Statistics","Reset Statistics",function() self:ResetStats() end)
    page:Finish();return page
end
