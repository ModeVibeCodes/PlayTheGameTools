local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local D=addon.ForeverQuickAccessData
local M={title="Quick Access Bars",category="qualityOfLife",defaultEnabled=false,
    configDescription="Movable profession shortcuts and an out-of-combat food bar."}
addon.ForeverQuickAccess=M
addon:RegisterModule("foreverQuickAccess",M)

function M:OnInitialize()
    D.Initialize(self.db);self.professions={}
    if addon.ForeverFoodBar then addon.ForeverFoodBar:Attach(self) end
end
function M:CanConfigure() return D.OutsideCombat() end
function M:GetFonts() return addon.Media:GetFonts() end
function M:SetOption(key,value)
    if not self:CanConfigure() then return false end
    local candidate=addon.ProfileCodec.Copy(self.db);candidate[key]=value
    if not pcall(D.Initialize,candidate) then return false end
    self.db[key]=value
    if key=="font" then self.db.fontMedia="" end
    self:Render();return true
end
function M:SetHidden(id,hidden)
    if not self:CanConfigure() or not D.Number(id,1,2147483647) or type(hidden)~="boolean" then return false end
    self.db.hidden[id]=hidden;self:Render();return true
end
function M:OpenProfession(id)
    if not self.active or not D.OutsideCombat() then return false end
    -- Re-read on the hardware click; an unlearned/stale skill never opens another page.
    local current=D.ReadProfessions()
    if not current then return false end
    for _,p in ipairs(current) do
        if p.id==id and not self.db.hidden[id] then
            if not C_TradeSkillUI or type(C_TradeSkillUI.OpenTradeSkill)~="function" then
                print("Play The Game Tools: native profession page opening is unavailable.");return false
            end
            local ok,opened=pcall(C_TradeSkillUI.OpenTradeSkill,id)
            if not ok or not D.Public(opened) or opened~=true then
                print("Play The Game Tools: the client could not open "..p.name..". Use the native Professions book.")
                return false
            end
            return true
        end
    end
    return false
end

function M:RefreshProfessions()
    if not self.active then return end
    if not D.OutsideCombat() then self.dirty=true;return end
    self.dirty=false
    local professions,message=D.ReadProfessions()
    self.professions=professions or {};self.message=message
    self:Render()
    if self.page then self.page:Refresh() end
end
function M:StopDrag()
    local f=self.bar
    if not f or not f.dragging then return end
    f:StopMovingOrSizing();f.dragging=nil
    local x,y=f:GetCenter();local cx,cy=UIParent:GetCenter()
    local scale=f:GetScale()
    if D.Number(x,-100000,100000) and D.Number(y,-100000,100000) and
        D.Number(cx,-100000,100000) and D.Number(cy,-100000,100000) then
        self.db.x=math.floor(x*scale-cx+0.5);self.db.y=math.floor(y*scale-cy+0.5)
    end
end
function M:CreateBar()
    if self.bar then return end
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.bar=f
    f:SetMovable(true);f:SetClampedToScreen(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetFrameStrata("MEDIUM");f.buttons={}
    addon.Media:ApplyBackdrop(f,{bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1},"foreverQuickAccess")
    local function start()
        if self.active and D.OutsideCombat() and (not self.db.locked or self.editing) then
            f:StartMoving();f.dragging=true
        end
    end
    local function stop() self:StopDrag() end
    f:SetScript("OnDragStart",start);f:SetScript("OnDragStop",stop)
    f:SetScript("OnHide",function() stop();f:SetScript("OnUpdate",nil) end)
    local function enter() self.hover=true;self:UpdateVisibility() end
    local function leave() self.hover=false;self:UpdateVisibility() end
    f:SetScript("OnEnter",enter);f:SetScript("OnLeave",leave)
    for i=1,5 do
        local button=CreateFrame("Button",nil,f,"BackdropTemplate");f.buttons[i]=button
        button:RegisterForClicks("LeftButtonUp");button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart",start);button:SetScript("OnDragStop",stop)
        button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetAllPoints()
        button.icon:SetTexCoord(0.06,0.94,0.06,0.94)
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        button.label=button:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        button.label:SetPoint("TOP",button,"BOTTOM",0,-3)
        button:SetScript("OnClick",function()
            if self.db.locked and not self.editing and button.profession then self:OpenProfession(button.profession.id) end
        end)
        button:SetScript("OnEnter",function()
            enter()
            local p=button.profession
            if self.db.showTooltips and p and GameTooltip then
                GameTooltip:SetOwner(button,"ANCHOR_TOP");GameTooltip:SetText(p.name)
                if p.rank and p.maxRank then GameTooltip:AddLine(p.rank.." / "..p.maxRank,0.7,0.8,0.9) end
                GameTooltip:AddLine(not D.OutsideCombat() and "Unavailable in combat" or
                    ((not self.db.locked or self.editing) and "Drag to move; lock to open professions" or "Click to open profession"),0.7,0.8,0.9)
                GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end;leave() end)
    end
end
function M:Render()
    if not self.active then return end
    self:CreateBar()
    local f,db=self.bar,self.db
    local visible={}
    for _,p in ipairs(self.professions) do if not db.hidden[p.id] then visible[#visible+1]=p end end
    self.visibleCount=#visible
    local w,h,columns,cellHeight=D.Geometry(#visible,db)
    f:SetScale(db.scale/100);f:SetSize(w,h);f:ClearAllPoints()
    f:SetPoint("CENTER",UIParent,"CENTER",db.x/(db.scale/100),db.y/(db.scale/100))
    f:SetBackdropColor(db.backgroundColor[1],db.backgroundColor[2],db.backgroundColor[3],db.backgroundOpacity/100)
    f:SetBackdropBorderColor(db.borderColor[1],db.borderColor[2],db.borderColor[3],db.borderOpacity/100)
    for i,button in ipairs(f.buttons) do
        local p=visible[i];button.profession=p;button:SetShown(p~=nil)
        if p then
            button:SetSize(db.iconSize,db.iconSize);button:ClearAllPoints()
            button:SetPoint("TOPLEFT",db.padding+((i-1)%columns)*(db.iconSize+db.spacing),-db.padding-math.floor((i-1)/columns)*(cellHeight+db.spacing))
            button.icon:SetTexture(p.icon);button.label:SetWidth(db.iconSize)
            local path=addon.Media:GetDisplayFont(db)
            if not button.label:SetFont(path,db.fontSize,db.outline and "OUTLINE" or "") then
                button.label:SetFont(GameFontHighlight:GetFont(),db.fontSize,db.outline and "OUTLINE" or "")
            end
            -- Native FontStrings require a font before SetText, even when names are hidden.
            button.label:SetText(p.name)
            button.label:SetTextColor(unpack(db.textColor));button.label:SetShown(db.showNames)
        end
    end
    self:UpdateVisibility()
end
function M:UpdateVisibility()
    local f=self.bar;if not f then return end
    local outside=D.OutsideCombat()
    local target=outside and self.db.outOpacity/100 or self.db.combatOpacity/100
    if outside and (not self.db.locked or self.editing or self.previewing or (self.hover and self.db.hoverReveal)) then target=1 end
    local shown=self.active and self.db.showProfessionBar and (self.visibleCount or 0)>0
    f:SetShown(shown)
    if not shown then return end
    -- Fully invisible bars pass clicks through. Visible combat icons cannot open pages.
    f:EnableMouse(target>0)
    for _,button in ipairs(f.buttons) do button:EnableMouse(target>0) end
    f:SetScript("OnUpdate",nil)
    local from=f:GetAlpha();local duration=self.db.fadeDuration
    if duration==0 or math.abs(from-target)<0.001 then f:SetAlpha(target);return end
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt;local t=math.min(1,elapsed/duration)
        f:SetAlpha(from+(target-from)*t)
        if t==1 then f:SetScript("OnUpdate",nil) end
    end)
end
function M:SetEditMode(value)
    self.editing=value;self:UpdateVisibility()
    if addon.ForeverFoodBar then addon.ForeverFoodBar:Render() end
end
function M:SetPreviewMode(value)
    self.previewing=value;self:UpdateVisibility()
    if addon.ForeverFoodBar then addon.ForeverFoodBar:Render() end
end
function M:OnEnable()
    self.active=true
    if not self.events then self.events=CreateFrame("Frame") end
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","SKILL_LINES_CHANGED","SPELLS_CHANGED","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_DISABLED" then self:StopDrag();self.hover=false;self:UpdateVisibility()
        else self:RefreshProfessions() end
    end)
    self:RefreshProfessions()
    if addon.ForeverFoodBar then addon.ForeverFoodBar:SyncEnabled() end
end
function M:OnDisable()
    self.active=false;self.hover=false
    if addon.ForeverFoodBar then addon.ForeverFoodBar:SyncEnabled() end
    if self.events then self.events:UnregisterAllEvents();self.events:SetScript("OnEvent",nil) end
    if self.bar then self:StopDrag();self.bar:Hide() end
end
