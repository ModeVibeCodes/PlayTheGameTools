local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local D=addon.ForeverQuickAccessData
local M={title="Profession & Food Bars",category="qualityOfLife",defaultEnabled=false,
    searchAliases={"quick access bars","profession bar","food bar"},
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
    self.db.hidden[id]=hidden;self:Render();self:SyncQuickActions();return true
end
-- Opening a profession casts its spell, which the game protects: only a
-- hardware click on Blizzard's unprotected action template may do it. Buttons
-- get a /cast macro outside combat; /stopmacro keeps the click inert in combat.
-- Attributes are written only outside combat.
local MACRO_GUARD="/stopmacro [combat]"
function M:ArmButton(button,profession)
    if not button or not button.nativeReady or not D.OutsideCombat() then return end
    button:SetAttribute("type1",nil);button:SetAttribute("macrotext1",nil)
    if profession and profession.spell then
        button:SetAttribute("macrotext1",MACRO_GUARD.."\n/cast "..profession.spell)
        button:SetAttribute("type1","macro")
    end
end
local function NativeReady(button)
    local ok,protected=pcall(button.IsProtected,button)
    return ok and D.Public(protected) and protected==false and type(button:GetScript("OnClick"))=="function"
end

function M:RefreshProfessions()
    if not self.active then return end
    if not D.OutsideCombat() then self.dirty=true;return end
    self.dirty=false
    local professions,message=D.ReadProfessions()
    self.professions=professions or {};self.message=message
    self:Render();self:SyncQuickActions()
    if self.page then self.page:Refresh() end
end
-- Edit Mode owns placement: icons forward drags to the Position Manager.
local ELEMENT="foreverQuickAccess"
function M:StopDrag()
    if addon.PositionManager.elements[ELEMENT] then addon.PositionManager:StopDragging(ELEMENT) end
end
function M:RegisterPosition()
    local ok,element=addon.PositionManager:RegisterModuleDisplay(ELEMENT,self.bar,self,{
        label="Profession Bar",defaultX=0,defaultY=-180,
        canDrag=function() return self.active==true end,
        onHighlight=function() self:UpdateVisibility() end,
        onStyleChanged=function() self:Render() end,
        onRegistered=function() self:Render();addon.PositionManager:RefreshSelection() end})
    if ok then element.editMode=self.active and self.db.showProfessionBar and ((self.visibleCount or 0)>0 or self.editing==true) or false end
end
function M:CreateBar()
    if self.bar then return end
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.bar=f
    f:SetClampedToScreen(true);f:EnableMouse(true)
    f:SetFrameStrata("MEDIUM");f.buttons={}
    f.placeholder=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    local path,size,flags=GameFontHighlightSmall:GetFont()
    if not f.placeholder:SetFont(addon.Media:GetDisplayFont({}),size,flags or "") then f.placeholder:SetFont(path,size,flags or "") end
    f.placeholder:SetPoint("CENTER");f.placeholder:SetText("Professions");f.placeholder:Hide()
    addon.Media:ApplyBackdrop(f,{bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1},"foreverQuickAccess")
    local function start() addon.PositionManager:StartDragging(ELEMENT) end
    local function stop() self:StopDrag() end
    f.fader=CreateFrame("Frame",nil,f)
    f:SetScript("OnHide",function() f.fader:SetScript("OnUpdate",nil) end)
    local function enter() self.hover=true;self:UpdateVisibility() end
    local function leave() self.hover=false;self:UpdateVisibility() end
    f:SetScript("OnEnter",enter);f:SetScript("OnLeave",leave)
    for i=1,5 do
        -- Blizzard's unprotected action template runs the /cast; its OnClick is never replaced.
        local button=CreateFrame("Button",nil,f,"InsecureActionButtonTemplate");f.buttons[i]=button
        button.nativeReady=NativeReady(button)
        if button.nativeReady then button:SetAttribute("useOnKeyDown",false) end
        button:RegisterForClicks("LeftButtonUp");button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart",start);button:SetScript("OnDragStop",stop)
        button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetAllPoints()
        button.icon:SetTexCoord(0.06,0.94,0.06,0.94)
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        button.label=button:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        button.label:SetPoint("TOP",button,"BOTTOM",0,-3)
        -- In Layout the buttons hold no action, and a click opens the bar's Style card.
        button:SetScript("PostClick",function()
            if self.editing then addon.PositionManager:SelectElement(ELEMENT) end
        end)
        button:SetScript("OnEnter",function()
            enter()
            local p=button.profession
            if self.db.showTooltips and p and GameTooltip then
                GameTooltip:SetOwner(button,"ANCHOR_TOP");GameTooltip:SetText(p.name)
                if p.rank and p.maxRank then GameTooltip:AddLine(p.rank.." / "..p.maxRank,0.7,0.8,0.9) end
                GameTooltip:AddLine(not D.OutsideCombat() and "Unavailable in combat" or
                    (self.editing and "Drag to move" or (p.spell and "Click to open profession" or "No profession window to open")),0.7,0.8,0.9)
                GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end;leave() end)
    end
end
function M:Render()
    if not self.active then return end
    self:CreateBar()
    -- Layout's Style card: Text size scales the names, Background hides the fill and border.
    local f,db=self.bar,addon.PositionManager:StyleView(ELEMENT,self.db,{text={"fontSize"},background={"backgroundOpacity","borderOpacity"}})
    local visible={}
    for _,p in ipairs(self.professions) do if not db.hidden[p.id] then visible[#visible+1]=p end end
    self.visibleCount=#visible
    local w,h,columns,cellHeight=D.Geometry(#visible,db)
    f:SetScale(db.scale/100);f:SetSize(w,h)
    if not addon.PositionManager.elements[ELEMENT] then
        f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",db.x/(db.scale/100),db.y/(db.scale/100))
    end
    f:SetBackdropColor(db.backgroundColor[1],db.backgroundColor[2],db.backgroundColor[3],db.backgroundOpacity/100)
    f:SetBackdropBorderColor(db.borderColor[1],db.borderColor[2],db.borderColor[3],db.borderOpacity/100)
    for i,button in ipairs(f.buttons) do
        local p=visible[i];button.profession=p;button:SetShown(p~=nil)
        self:ArmButton(button,not self.editing and not self.previewing and p or nil)
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
    if D.OutsideCombat() then
        self:RegisterPosition()
        if addon.PositionManager.elements[ELEMENT] then addon.PositionManager:ApplyPosition(ELEMENT) end
    end
    self:UpdateVisibility()
end
function M:UpdateVisibility()
    local f=self.bar;if not f then return end
    local element=addon.PositionManager.elements[ELEMENT]
    if element and element.dragging then return end
    local outside=D.OutsideCombat()
    local target=outside and self.db.outOpacity/100 or self.db.combatOpacity/100
    if outside and (self.editing or self.previewing or (self.hover and self.db.hoverReveal)) then target=1 end
    -- Edit Mode shows an empty bar as a labeled placeholder so it can be placed.
    local shown=self.active and self.db.showProfessionBar and ((self.visibleCount or 0)>0 or self.editing==true)
    if f.placeholder then f.placeholder:SetShown(shown and (self.visibleCount or 0)==0) end
    f:SetShown(shown)
    if not shown then return end
    -- Fully invisible bars pass clicks through. Visible combat icons cannot open pages.
    f:EnableMouse(target>0)
    for _,button in ipairs(f.buttons) do button:EnableMouse(target>0) end
    local fader=f.fader
    fader:SetScript("OnUpdate",nil)
    local from=f:GetAlpha();local duration=self.db.fadeDuration
    if duration==0 or math.abs(from-target)<0.001 then f:SetAlpha(target);return end
    local elapsed=0
    fader:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt;local t=math.min(1,elapsed/duration)
        f:SetAlpha(from+(target-from)*t)
        if t==1 then fader:SetScript("OnUpdate",nil) end
    end)
end
function M:SetEditMode(value)
    self.editing=value
    if self.active then self:Render() else self:UpdateVisibility() end
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
    self:SyncQuickActions()
end

-- Quick Actions ring: one icon per shown profession that has a window to open,
-- after Class Training, Dungeon Loot and Guild. Icons are action-template
-- buttons armed like the bar's. Professions hidden on the page stay out of the
-- ring too. Built and armed outside combat only; PLAYER_REGEN_ENABLED re-reads.
local RING_SLOTS,RING_ORDER=5,40
function M:SyncQuickActions()
    local Q=addon.QuickActions
    if not Q or not Q.OutsideCombat() then return end
    self.ringSlots=self.ringSlots or {}
    local shown={}
    if self.active then
        for _,p in ipairs(self.professions or {}) do
            if not self.db.hidden[p.id] and p.spell then shown[#shown+1]=p end
        end
    end
    for i=1,RING_SLOTS do
        local id="profession"..i
        local p,slot=shown[i],self.ringSlots[i]
        if p and not slot and not self.ringRefused then
            slot={spec={order=RING_ORDER+i,secure=true,texture=p.icon,color={.48,.82,.52},title=p.name}}
            slot.spec.hint=function()
                local current=slot.profession
                local rank=current and current.rank and current.maxRank and (current.rank.." / "..current.maxRank.."\n") or ""
                return rank.."Click to open profession."
            end
            slot.button=Q:AddAction(id,slot.spec)
            -- A refused template never retries: one frame per attempt would pile up.
            if slot.button then slot.button.nativeReady=true;self.ringSlots[i]=slot else slot=nil;self.ringRefused=true end
        end
        if slot then
            slot.profession=p
            if p then slot.spec.title=p.name;slot.button.icon:SetTexture(p.icon) end
            self:ArmButton(slot.button,p)
            Q:SetAvailable(id,p~=nil)
        end
    end
end
