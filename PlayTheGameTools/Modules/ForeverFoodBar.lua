local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local F,D=addon.ForeverFoodBar,addon.ForeverQuickAccessData

function F:SetOption(key,value)
    if not D.OutsideCombat() then return false end
    local copy=addon.ProfileCodec.Copy(self.owner.db)
    copy.food[key]=value
    if not pcall(F.Initialize,copy) then return false end
    self.db[key]=value
    if key=="font" then self.db.fontMedia="" end
    self:SyncEnabled();return true
end
function F:Select(id,value)
    if not D.OutsideCombat() or not D.Number(id,1,2147483647) or type(value)~="boolean" then return false end
    local candidate=addon.ProfileCodec.Copy(self.owner.db)
    candidate.food.selected[id]=value
    if not pcall(F.Initialize,candidate) then return false end
    self.db.selected[id]=value;self:Render();return true
end
function F:StopDrag()
    local f=self.bar;if not f or not f.dragging then return end
    f:StopMovingOrSizing();f.dragging=nil
    local x,y=f:GetCenter();local cx,cy=UIParent:GetCenter();local scale=f:GetScale()
    if D.Number(x,-100000,100000) and D.Number(y,-100000,100000) and
        D.Number(cx,-100000,100000) and D.Number(cy,-100000,100000) then
        self.db.x=math.floor(x*scale-cx+0.5);self.db.y=math.floor(y*scale-cy+0.5)
    end
end
function F:CreateBar()
    if self.bar or not D.OutsideCombat() then return end
    local bar=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.bar=bar
    bar:Hide();bar:SetMovable(true);bar:SetClampedToScreen(true);bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton");bar:SetFrameStrata("MEDIUM")
    addon.Media:ApplyBackdrop(bar,{bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1},"foreverQuickAccess")
    local function start()
        if self.active and D.OutsideCombat() and (not self.db.locked or self.owner.editing) then
            bar:StartMoving();bar.dragging=true
        end
    end
    local function stop() self:StopDrag() end
    bar:SetScript("OnDragStart",start);bar:SetScript("OnDragStop",stop)
    bar:SetScript("OnHide",stop)
    self.buttons={}
    for i=1,self.limit do
        -- Native template owns item-use dispatch and enforces its OOC guard.
        -- Never replace/hook its OnClick or synthesize a click/use API call.
        local b=CreateFrame("Button",nil,bar,"InsecureActionButtonTemplate")
        local protected=b:IsProtected()
        if not D.Public(protected) or protected~=false or type(b:GetScript("OnClick"))~="function" then
            self.blocked=true;self.message="Native out-of-combat item buttons unavailable.";bar:Hide();return
        end
        self.buttons[i]=b;b:Hide()
        b:RegisterForClicks("LeftButtonDown","LeftButtonUp")
        b:RegisterForDrag("LeftButton");b:SetScript("OnDragStart",start);b:SetScript("OnDragStop",stop)
        b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetAllPoints();b.icon:SetTexCoord(0.06,0.94,0.06,0.94)
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        b.count=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.count:SetPoint("BOTTOMRIGHT",-2,2)
        b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlight");b.label:SetPoint("TOP",b,"BOTTOM",0,-3)
        b:SetScript("OnEnter",function()
            if b.item and self.db.showTooltips and GameTooltip and GameTooltip.SetItemByID then
                GameTooltip:SetOwner(b,"ANCHOR_TOP");GameTooltip:SetItemByID(b.item.id);GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    end
    local hide=addon.ConfigWidgets.Button(bar,"Hide",48,20,"secondary")
    hide:SetPoint("TOPRIGHT",bar,"BOTTOMRIGHT",0,-3)
    hide:SetScript("OnClick",function() self:SetOption("shown",false);if self.owner.page then self.owner.page:Refresh() end end)
    self.hideButton=hide
end
function F:Render()
    if not self.active or not self.db.enabled or not self.db.shown or not D.OutsideCombat() then
        if self.bar then self.bar:Hide() end
        return
    end
    if not C_Macro or type(C_Macro.RunMacroText)~="function" then
        self.message="Native macro action dispatcher unavailable.";if self.bar then self.bar:Hide() end;return
    end
    self:CreateBar();if self.blocked or not self.bar then return end
    local items=self:VisibleItems();local bar,db=self.bar,self.db
    local w,h,columns,cellHeight=D.Geometry(#items,db)
    bar:SetSize(w,h);bar:SetScale(db.scale/100);bar:ClearAllPoints()
    bar:SetPoint("CENTER",UIParent,"CENTER",db.x/(db.scale/100),db.y/(db.scale/100))
    bar:SetBackdropColor(db.backgroundColor[1],db.backgroundColor[2],db.backgroundColor[3],db.backgroundOpacity/100)
    bar:SetBackdropBorderColor(db.borderColor[1],db.borderColor[2],db.borderColor[3],db.borderOpacity/100)
    for i,b in ipairs(self.buttons) do
        local p=items[i];b.item=p
        b:SetAttribute("type1",nil);b:SetAttribute("macrotext1",nil)
        b:SetShown(p~=nil)
        if p then
            b:SetSize(db.iconSize,db.iconSize);b:ClearAllPoints()
            b:SetPoint("TOPLEFT",db.padding+((i-1)%columns)*(db.iconSize+db.spacing),-db.padding-math.floor((i-1)/columns)*(cellHeight+db.spacing))
            b.icon:SetTexture(p.icon)
            for _,label in ipairs({b.label,b.count}) do
                if not label:SetFont(addon.Media:GetDisplayFont(db),db.fontSize,db.outline and "OUTLINE" or "") then
                    label:SetFont(GameFontHighlight:GetFont(),db.fontSize,db.outline and "OUTLINE" or "")
                end
                label:SetTextColor(unpack(db.textColor))
            end
            b.label:SetWidth(db.iconSize);b.label:SetText(p.name);b.label:SetShown(db.showNames)
            b.count:SetText(tostring(p.count))
            if db.locked and not self.owner.editing and not self.owner.previewing then
                b:SetAttribute("macrotext1","/stopmacro [combat]\n/use [nocombat,@player] item:"..p.id)
                b:SetAttribute("type1","macro")
            end
        end
    end
    bar:SetShown(#items>0)
end
function F:Refresh()
    if not self.active then return end
    if not D.OutsideCombat() then self.dirty=true;if self.bar then self.bar:Hide() end;return end
    self:Scan();self:Render()
    if self.owner.page then self.owner.page:Refresh() end
end
function F:SyncEnabled()
    local enabled=self.owner.active and self.db.enabled
    if not self.events then self.events=CreateFrame("Frame") end
    self.events:UnregisterAllEvents();self.events:SetScript("OnEvent",nil);self.active=enabled
    if not enabled then if self.bar then self:StopDrag();self.bar:Hide() end;return end
    for _,event in ipairs({"BAG_UPDATE_DELAYED","ITEM_DATA_LOAD_RESULT","PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent",function(_,event,id)
        if event=="PLAYER_REGEN_DISABLED" then
            self:StopDrag();if self.bar then self.bar:Hide() end
            if GameTooltip then GameTooltip:Hide() end
        elseif event~="ITEM_DATA_LOAD_RESULT" or (D.Public(id) and self.requested and self.requested[id]) then self:Refresh() end
    end)
    self:Refresh()
end
function F:Attach(owner)
    self.owner=owner;self.db=owner.db.food;self.inventory={};self.foodChoices={}
end
