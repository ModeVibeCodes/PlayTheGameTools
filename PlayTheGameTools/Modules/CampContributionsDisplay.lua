local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local A,D=addon.CampContributions,addon.ForeverQuickAccessData
local PM=addon.PositionManager
function A:StopDrag()
    local f=self.window
    if not f or not f.dragging then return end
    f:StopMovingOrSizing();f.dragging=nil
    if not D.OutsideCombat() then return end
    local e=PM.elements.campfireContributions
    if e then
        local x,y=addon.Positioning:ReadFrame(e.subject)
        PM:SetOffsets(e.id,x,y)
    end
end
function A:RegisterWindow()
    if not self.window or not self.window:IsShown() or not D.OutsideCombat() then return false,"layout-pending" end
    local e=PM.elements.campfireContributions
    if e and e.position~=(addon.db.positions or {}).campfireContributions then
        PM:UnregisterElement(e.id);e=nil
    end
    if not e then
        local ok,value=PM:RegisterElement("campfireContributions",self.window,{
            moduleId=self.camp.owner.id,
            defaultPosition={target="screen",placement="center",x=self.db.contributionX,y=self.db.contributionY},
            canDrag=function() return self.active end,
            onPositionChanged=function(element,position)
                element.position.x=math.max(-10000,math.min(10000,math.floor(position.x+0.5)))
                element.position.y=math.max(-10000,math.min(10000,math.floor(position.y+0.5)))
                self.db.contributionX,self.db.contributionY=element.position.x,element.position.y
                if not element.dragging then PM:ApplyPosition(element.id) end
            end,
        })
        if not ok then return false,value end
        e=value
    end
    e.label="Camp Contributions";e.editMode=self.active==true
    e.position.x=math.max(-10000,math.min(10000,math.floor(e.position.x+0.5)))
    e.position.y=math.max(-10000,math.min(10000,math.floor(e.position.y+0.5)))
    self.db.contributionX,self.db.contributionY=e.position.x,e.position.y
    return true
end
function A:FinishPositionRegistration(ok,reason)
    if not ok then
        self.positionFailure=tostring(reason or "unavailable")
        self:Hide(false)
    elseif self.camp.editing then
        PM:SelectElement("campfireContributions");PM:RefreshSelection()
    end
    if self.camp.owner.page then self.camp.owner.page:Refresh() end
end
function A:EnsurePositionRegistration()
    if self.positionFailure or self.positionRetryPending then return end
    local ok,reason=self:RegisterWindow()
    if ok then return end
    if reason~="invalid-frame" then self:FinishPositionRegistration(false,reason);return end
    -- Rectangles can be unavailable until a shown frame receives a layout pass.
    -- One next-frame retry, never an assertion or a bag-event retry loop.
    self.positionDriver=self.positionDriver or CreateFrame("Frame")
    self.positionRetryPending=true
    self.positionDriver:SetScript("OnUpdate",function(driver)
        driver:SetScript("OnUpdate",nil);self.positionRetryPending=nil
        if not self.active or not D.OutsideCombat() or not self.window:IsShown() then return end
        local registered,status=self:RegisterWindow()
        self:FinishPositionRegistration(registered,status)
    end)
end
function A:CreateWindow()
    if self.window then return end
    if not D.OutsideCombat() then return end
    local W,T=addon.ConfigWidgets,addon.InterfaceTheme
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.window=f
    f:Hide();f:SetSize(self.db.contributionWidth,166);f:SetPoint("CENTER",UIParent,"CENTER",self.db.contributionX,self.db.contributionY);f:SetMovable(true);f:SetClampedToScreen(true);f:SetFrameStrata("DIALOG");f:SetFrameLevel(90)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(0.035,0.045,0.06,0.96);f:SetBackdropBorderColor(0.32,0.40,0.48,1)
    local header=CreateFrame("Frame",nil,f);f.header=header
    header:SetPoint("TOPLEFT",8,-6);header:SetPoint("TOPRIGHT",-78,-6);header:SetHeight(30)
    header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function()
        if D.OutsideCombat() and (self.camp.editing or self.previewing or not self.db.contributionLocked) then f:StartMoving();f.dragging=true end
    end)
    header:SetScript("OnDragStop",function() self:StopDrag() end)
    f:SetScript("OnHide",function() self:StopDrag() end)
    f.title=W.Label(header,"",nil,4,-5,330,T.text)
    f.title:SetText(self.camp:HeaderText("Camp Contributions"))
    local close=W.Button(f,"Dismiss",68,24);close:SetPoint("TOPRIGHT",-8,-8)
    close:SetScript("OnClick",function() self:Dismiss() end);f.close=close
    for _,event in ipairs({"OnEnter","OnLeave","OnMouseDown","OnMouseUp"}) do
        close:HookScript(event,function() close.label:SetTextColor(unpack(self.db.contributionDismissColor)) end)
    end
    local hint=W.Label(f,"Click a kit to use it; finish any native ground placement.",nil,12,-40,426,T.muted)
    hint:SetWordWrap(true);f.hint=hint
    local viewport=CreateFrame("ScrollFrame",nil,f);f.viewport=viewport
    viewport:SetPoint("TOPLEFT",10,-74);viewport:SetWidth(430)
    local content=CreateFrame("Frame",nil,viewport);content:SetWidth(430);viewport:SetScrollChild(content)
    f.content=content;self.buttons={};f.scroll=0
    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel",function(_,delta)
        f.scroll=math.max(0,math.min(f.maxScroll or 0,f.scroll-delta*(f.rowPitch or 48)));viewport:SetVerticalScroll(f.scroll)
    end)
    f.footer=W.Label(f,"",nil,12,0,426,T.muted)
    f.footer:ClearAllPoints();f.footer:SetPoint("BOTTOMLEFT",12,12);f.footer:SetWordWrap(true)
    addon.Media:RegisterFontListener(f,function()
        if self.active and f:IsShown() and D.OutsideCombat() then self:OnSnapshot(self.camp.snapshot) end
    end)
end
function A:CreateButton(index)
    if not C_Macro or type(C_Macro.RunMacroText)~="function" then
        self.message="Camp shortcuts unavailable; use your bags.";return
    end
    local b=CreateFrame("Button",nil,self.window.content,"InsecureActionButtonTemplate")
    if not D.Public(b:IsProtected()) or b:IsProtected()~=false or type(b:GetScript("OnClick"))~="function" then
        self.blocked=true;self.message="Camp contribution shortcuts were rejected by this client. Use your bags.";b:Hide();return
    end
    -- The Blizzard template alone dispatches the user's hardware click. No
    -- OnClick hook/replacement, synthetic click, alternate use API or @cursor.
    b:RegisterForClicks("LeftButtonDown","LeftButtonUp")
    b:SetSize(430,44);b:SetPoint("TOPLEFT",0,-(index-1)*48)
    local bg=b:CreateTexture(nil,"BACKGROUND");b.bg=bg;bg:SetAllPoints()
    b.highlight=b:CreateTexture(nil,"HIGHLIGHT");b.highlight:SetAllPoints()
    b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(36,36);b.icon:SetPoint("LEFT",4,0)
    b.icon:SetTexCoord(0.06,0.94,0.06,0.94)
    b.name=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.name:SetPoint("TOPLEFT",48,-5);b.name:SetWidth(300);b.name:SetJustifyH("LEFT")
    b.info=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.info:SetPoint("TOPLEFT",48,-25);b.info:SetWidth(300);b.info:SetJustifyH("LEFT")
    b.action=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.action:SetPoint("RIGHT",-8,0)
    b:SetScript("OnEnter",function()
        if self.db.contributionTooltips and b.item and GameTooltip and GameTooltip.SetItemByID then
            GameTooltip:SetOwner(b,"ANCHOR_RIGHT");GameTooltip:SetItemByID(b.item.id);GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    self.buttons[index]=b;return b
end
function A:Render()
    if not self.active or not D.OutsideCombat() or self.dismissed or self.blocked or self.positionFailure or
        not self.camp.snapshot or self.camp.snapshot.nearby~=true or self.camp.previewing or self.camp.editing or self.camp.placing then
        self:Hide(false);return
    end
    if #self.items==0 then self:Hide(false);return end
    self:CreateWindow();if not self.window or self.blocked then return end
    local f=self.window
    if f.sample then f.sample:Hide() end
    f.hint:SetText("Click a kit; finish any native ground placement.")
    f.title:SetText(self.camp:HeaderText("Camp Contributions"))
    for i,item in ipairs(self.items) do
        local b=self.buttons[i] or self:CreateButton(i)
        if not b then self:Hide(false);return end
        b.item=item;b.icon:SetTexture(item.icon)
        b:SetAttribute("type1",nil)
        b:SetAttribute("macrotext1","/stopmacro [combat]\n/use [nocombat] item:"..item.id)
        b:SetAttribute("type1","macro");b:Show()
    end
    for i=#self.items+1,#self.buttons do
        local b=self.buttons[i];b.item=nil;b:SetAttribute("type1",nil);b:SetAttribute("macrotext1",nil);b:Hide()
    end
    self:Layout(#self.items,#self.items>self.db.contributionVisibleRows and "Scroll for more kits. Native placement rules apply." or "Native placement rules apply.")
end
function A:StyleLabel(label,size,color)
    local db=self.db
    local font=db.contributionUseInterfaceFont and addon.Media:GetInterfaceFont() or
        addon.Media:GetDisplayFont({font=db.contributionFont,fontMedia=db.contributionFontMedia})
    local flags=db.contributionOutline and "OUTLINE" or ""
    if not label:SetFont(font,size,flags) then label:SetFont(GameFontHighlight:GetFont(),size,flags) end
    label:SetTextColor(unpack(color))
end
function A:StyleRow(row,index,preview,width,height,pitch)
    local db=self.db;row:SetSize(width,height);row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-(index-1)*pitch)
    row.bg:SetColorTexture(unpack(db.contributionRowColor));row.bg:SetAlpha(db.contributionRowOpacity/100)
    if row.highlight then row.highlight:SetColorTexture(unpack(db.contributionHoverColor));row.highlight:SetAlpha(db.contributionHoverOpacity/100) end
    row.icon:SetSize(db.contributionIconSize,db.contributionIconSize);row.icon:SetAlpha(db.contributionIconOpacity/100)
    row.icon:SetShown(db.contributionShowIcons)
    local names=db.contributionShowNames or not db.contributionShowIcons -- retain an identifiable kit
    local info={}
    if db.contributionShowProfession then info[#info+1]=preview and "Sample profession" or row.item.profession end
    if db.contributionShowCount then info[#info+1]=preview and "Preview count: 1" or (row.item.count.." in bags") end
    row.name:SetText(preview and "Preview kit - no item use" or row.item.name)
    row.info:SetText(table.concat(info," - "));row.action:SetText(preview and "Preview" or "Place")
    self:StyleLabel(row.name,db.contributionNameSize,db.contributionNameColor)
    self:StyleLabel(row.info,db.contributionInfoSize,db.contributionInfoColor)
    self:StyleLabel(row.action,db.contributionActionSize,db.contributionActionColor)
    local left=db.contributionShowIcons and db.contributionIconSize+12 or 8
    local right=db.contributionShowAction and math.max(52,db.contributionActionSize*5)+8 or 8
    for _,label in ipairs({row.name,row.info}) do label:ClearAllPoints();label:SetWidth(math.max(20,width-left-right));label:SetWordWrap(false);label:SetJustifyH(db.contributionTextAlign) end
    row.action:SetWidth(math.max(1,right-8));row.action:SetJustifyH("RIGHT")
    row.name:SetPoint("TOPLEFT",left,-5);row.info:SetPoint("TOPLEFT",left,-(names and db.contributionNameSize+9 or 5))
    row.name:SetShown(names);row.info:SetShown(#info>0);row.action:SetShown(db.contributionShowAction)
    row:Show()
end
local function TextHeight(label,size)
    local h=label:GetStringHeight()
    return D.Number(h,1,500) and math.max(size+4,h) or (size+4)
end
function A:Layout(count,footer)
    local f,db=self.window,self.db;local pad=db.contributionPadding;local width=db.contributionWidth
    local inner=width-pad*2;local names=db.contributionShowNames or not db.contributionShowIcons
    local info=db.contributionShowProfession or db.contributionShowCount
    local textHeight=(names and db.contributionNameSize+4 or 0)+(info and db.contributionInfoSize+4 or 0)+8
    local rowHeight=math.max(db.contributionRowHeight,textHeight,db.contributionShowIcons and db.contributionIconSize+8 or 0,db.contributionActionSize+10)
    local pitch=rowHeight+db.contributionRowGap;f.rowPitch=pitch
    local rows=math.min(db.contributionVisibleRows,count);local bodyHeight=rows*pitch-db.contributionRowGap
    local headerHeight=math.max(30,db.contributionTitleSize+14,db.contributionDismissSize+14)
    local closeWidth=math.max(68,db.contributionDismissSize*5)
    f.close:SetWidth(closeWidth)
    f.header:ClearAllPoints();f.header:SetPoint("TOPLEFT",pad,-pad);f.header:SetPoint("TOPRIGHT",-pad-closeWidth-10,-pad);f.header:SetHeight(headerHeight)
    f.close:ClearAllPoints();f.close:SetPoint("TOPRIGHT",-pad,-pad)
    self:StyleLabel(f.close.label,db.contributionDismissSize,db.contributionDismissColor)
    self:StyleLabel(f.title,db.contributionTitleSize,db.contributionTitleColor)
    f.title:SetWidth(inner-closeWidth-10);f.title:SetWordWrap(false);f.title:SetJustifyH(db.contributionTitleAlign)
    local title=self.camp:StyledText("Camp Contributions",db.contributionTitleColor,
        db.contributionHeaderGradient and db.contributionTitleEndColor or db.contributionTitleColor,db.contributionHeaderGradient)
    f.title:SetText(title);f.title:SetShown(db.contributionShowTitle)
    self:StyleLabel(f.hint,db.contributionHintSize,db.contributionHintColor);f.hint:SetWidth(inner)
    local top=pad+headerHeight
    f.hint:ClearAllPoints();f.hint:SetPoint("TOPLEFT",pad,-top);f.hint:SetShown(db.contributionShowHint)
    if db.contributionShowHint then top=top+TextHeight(f.hint,db.contributionHintSize)+6 end
    f.viewport:ClearAllPoints();f.viewport:SetPoint("TOPLEFT",pad,-top);f.viewport:SetSize(inner,bodyHeight)
    f.content:SetSize(inner,count*pitch-db.contributionRowGap)
    f.maxScroll=math.max(0,(count-rows)*pitch);f.scroll=math.min(f.scroll,f.maxScroll)
    f.viewport:SetVerticalScroll(f.scroll)
    f.footer:SetText(footer);self:StyleLabel(f.footer,db.contributionFooterSize,db.contributionFooterColor)
    f.footer:SetWidth(inner);f.footer:ClearAllPoints();f.footer:SetPoint("BOTTOMLEFT",pad,pad);f.footer:SetShown(db.contributionShowFooter)
    local bottom=db.contributionShowFooter and TextHeight(f.footer,db.contributionFooterSize)+8 or 0
    local height=top+bodyHeight+bottom+pad
    if f.sample and f.sample:IsShown() then self:StyleRow(f.sample,1,true,inner,rowHeight,pitch)
    else for i,row in ipairs(self.buttons) do if i<=count then self:StyleRow(row,i,false,inner,rowHeight,pitch) end end end
    f:SetAlpha(db.contributionOpacity/100)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=db.contributionBorderSize})
    f:SetBackdropColor(db.contributionBackgroundColor[1],db.contributionBackgroundColor[2],db.contributionBackgroundColor[3],db.contributionBackgroundOpacity/100)
    f:SetBackdropBorderColor(db.contributionBorderColor[1],db.contributionBorderColor[2],db.contributionBorderColor[3],db.contributionBorderOpacity/100)
    -- The workspace is DIALOG level 80; the live/preview popup is level 90.
    -- Keep its editable subject below that workspace so it cannot eat its input.
    f:SetFrameStrata(self.camp.editing and "MEDIUM" or "DIALOG")
    local e=PM.elements.campfireContributions
    local dragging=f.dragging or (e and e.dragging)
    if not dragging then
        f:SetWidth(width);f:SetScale(math.max(0.25,math.min(db.contributionScale/100,(UIParent:GetHeight()-40)/height,(UIParent:GetWidth()-40)/width)));f:SetHeight(height)
    end
    f:Show()
    -- Both registration and subsequent re-anchoring need the shown rectangle.
    self:EnsurePositionRegistration()
    if not dragging and self.window:IsShown() and PM.elements.campfireContributions then
        PM:ApplyPosition("campfireContributions")
    end
end
function A:RenderPreview()
    if not self.active or not D.OutsideCombat() or self.positionFailure then return end
    -- Clear native attributes before showing a separate, non-action sample.
    for _,button in ipairs(self.buttons or {}) do
        button:SetAttribute("type1",nil);button:SetAttribute("macrotext1",nil)
    end
    self:CreateWindow();if not self.window then return end
    local f=self.window
    for _,button in ipairs(self.buttons or {}) do button:Hide() end
    if not f.sample then
        local row=CreateFrame("Frame",nil,f.content);f.sample=row
        row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints()
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetPoint("LEFT",4,0);row.icon:SetTexture(135805)
        for _,key in ipairs({"name","info","action"}) do row[key]=row:CreateFontString(nil,"OVERLAY","GameFontHighlight") end
        row.action:SetPoint("RIGHT",-8,0)
    end
    f.sample:Show();f.title:SetText(self.camp:HeaderText("Camp Contributions"))
    f.hint:SetText("Preview only. Drag the header or use Edit Mode.")
    self:Layout(1,"Sample kit; no profession, item or nearby fire required.")
    PM:RefreshSelection()
end
