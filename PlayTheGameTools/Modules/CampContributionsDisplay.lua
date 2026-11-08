local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local A,D=addon.CampContributions,addon.ForeverQuickAccessData
function A:StopDrag()
    local f=self.window
    if not f or not f.dragging then return end
    f:StopMovingOrSizing();f.dragging=nil
    if not D.OutsideCombat() then return end
    local x,y=f:GetCenter();local cx,cy=UIParent:GetCenter();local scale=f:GetScale()
    if D.Number(x,-100000,100000) and D.Number(y,-100000,100000) and
        D.Number(cx,-100000,100000) and D.Number(cy,-100000,100000) and D.Number(scale,0.1,2) then
        self.db.contributionX=math.max(-10000,math.min(10000,math.floor(x*scale-cx+0.5)))
        self.db.contributionY=math.max(-10000,math.min(10000,math.floor(y*scale-cy+0.5)))
    end
end
function A:CreateWindow()
    if self.window or self.blocked or not D.OutsideCombat() then return end
    if not C_Macro or type(C_Macro.RunMacroText)~="function" then
        self.message="Camp contribution shortcuts are unavailable in this client. Use your bags.";return
    end
    local W,T=addon.ConfigWidgets,addon.InterfaceTheme
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.window=f
    f:Hide();f:SetWidth(450);f:SetMovable(true);f:SetClampedToScreen(true);f:SetFrameStrata("DIALOG")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(0.035,0.045,0.06,0.96);f:SetBackdropBorderColor(0.32,0.40,0.48,1)
    local header=CreateFrame("Frame",nil,f);f.header=header
    header:SetPoint("TOPLEFT",8,-6);header:SetPoint("TOPRIGHT",-78,-6);header:SetHeight(30)
    header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function()
        if D.OutsideCombat() then f:StartMoving();f.dragging=true end
    end)
    header:SetScript("OnDragStop",function() self:StopDrag() end)
    f:SetScript("OnHide",function() self:StopDrag() end)
    f.title=W.Label(header,"",nil,4,-5,330,T.text)
    f.title:SetText(addon.CampfireMonitor.Gradient("Camp Contributions",{1,0.58,0.12},{1,0.12,0.08}))
    local close=W.Button(f,"Dismiss",68,24);close:SetPoint("TOPRIGHT",-8,-8)
    close:SetScript("OnClick",function() self:Dismiss() end);f.close=close
    local hint=W.Label(f,"Click a kit to use it; finish any native ground placement.",nil,12,-40,426,T.muted)
    hint:SetWordWrap(true)
    local viewport=CreateFrame("ScrollFrame",nil,f);f.viewport=viewport
    viewport:SetPoint("TOPLEFT",10,-74);viewport:SetWidth(430)
    local content=CreateFrame("Frame",nil,viewport);content:SetWidth(430);viewport:SetScrollChild(content)
    f.content=content;self.buttons={};f.scroll=0
    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel",function(_,delta)
        f.scroll=math.max(0,math.min(f.maxScroll or 0,f.scroll-delta*48));viewport:SetVerticalScroll(f.scroll)
    end)
    f.footer=W.Label(f,"",nil,12,0,426,T.muted)
    f.footer:ClearAllPoints();f.footer:SetPoint("BOTTOMLEFT",12,12);f.footer:SetWordWrap(true)
end
function A:CreateButton(index)
    local b=CreateFrame("Button",nil,self.window.content,"InsecureActionButtonTemplate")
    if not D.Public(b:IsProtected()) or b:IsProtected()~=false or type(b:GetScript("OnClick"))~="function" then
        self.blocked=true;self.message="Camp contribution shortcuts were rejected by this client. Use your bags.";b:Hide();return
    end
    -- The Blizzard template alone dispatches the user's hardware click. No
    -- OnClick hook/replacement, synthetic click, alternate use API or @cursor.
    b:RegisterForClicks("LeftButtonDown","LeftButtonUp")
    b:SetSize(430,44);b:SetPoint("TOPLEFT",0,-(index-1)*48)
    local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.10,0.14,0.18,0.95)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(36,36);b.icon:SetPoint("LEFT",4,0)
    b.icon:SetTexCoord(0.06,0.94,0.06,0.94)
    b.name=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.name:SetPoint("TOPLEFT",48,-5);b.name:SetWidth(300);b.name:SetJustifyH("LEFT")
    b.info=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.info:SetPoint("TOPLEFT",48,-25);b.info:SetWidth(300);b.info:SetJustifyH("LEFT")
    b.action=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.action:SetPoint("RIGHT",-8,0)
    b:SetScript("OnEnter",function()
        if b.item and GameTooltip and GameTooltip.SetItemByID then
            GameTooltip:SetOwner(b,"ANCHOR_RIGHT");GameTooltip:SetItemByID(b.item.id);GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    self.buttons[index]=b;return b
end
function A:Render()
    if not self.active or not D.OutsideCombat() or self.dismissed or self.blocked or
        not self.camp.snapshot or self.camp.snapshot.nearby~=true or self.camp.previewing or self.camp.editing or self.camp.placing then
        self:Hide(false);return
    end
    if #self.items==0 then self:Hide(false);return end
    self:CreateWindow();if not self.window or self.blocked then return end
    local f=self.window;local font=addon.Media:GetInterfaceFont()
    for i,item in ipairs(self.items) do
        local b=self.buttons[i] or self:CreateButton(i)
        if not b then self:Hide(false);return end
        b.item=item;b.icon:SetTexture(item.icon)
        for _,label in ipairs({b.name,b.info,b.action}) do
            if not label:SetFont(font,label==b.name and 13 or 11,"") then label:SetFont(GameFontHighlight:GetFont(),12,"") end
        end
        b.name:SetText(item.name);b.info:SetText(item.profession.." - "..item.count.." in bags");b.action:SetText("Place")
        b.info:SetTextColor(0.65,0.72,0.8);b.action:SetTextColor(1,0.82,0.35)
        b:SetAttribute("type1",nil)
        b:SetAttribute("macrotext1","/stopmacro [combat]\n/use [nocombat] item:"..item.id)
        b:SetAttribute("type1","macro");b:Show()
    end
    for i=#self.items+1,#self.buttons do
        local b=self.buttons[i];b.item=nil;b:SetAttribute("type1",nil);b:SetAttribute("macrotext1",nil);b:Hide()
    end
    local rows=math.min(6,#self.items);local height=74+rows*48+44
    f.content:SetHeight(#self.items*48);f.viewport:SetHeight(rows*48)
    f.maxScroll=math.max(0,(#self.items-rows)*48);f.scroll=math.min(f.scroll,f.maxScroll)
    f.viewport:SetVerticalScroll(f.scroll)
    f.footer:SetText(#self.items>6 and "Scroll for more kits. Native range, camp slots and cooldown rules apply." or
        "Native range, camp slots and cooldown rules apply.")
    if not f.dragging then
        local scale=math.max(0.5,math.min(1,(UIParent:GetHeight()-40)/height))
        f:SetScale(scale);f:SetHeight(height);f:ClearAllPoints()
        f:SetPoint("CENTER",UIParent,"CENTER",self.db.contributionX/scale,self.db.contributionY/scale)
    end
    f:Show()
end
