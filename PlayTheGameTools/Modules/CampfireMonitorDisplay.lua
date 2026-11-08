local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,P,PM=addon.CampfireMonitor,addon.LootSparkles,addon.PositionManager
local function Number(v,lo,hi) return P.Public(v) and type(v)=="number" and v==v and v>=lo and v<=hi end
local function Element(f) return f and PM.elements[f.elementId] end
function C:RegisterDisplay(f,separate)
    if not P:OutsideCombat() then return end
    local e=Element(f)
    if e and addon.db.positions and e.position~=addon.db.positions[f.elementId] then
        PM:UnregisterElement(f.elementId);e=nil
    end
    if not e then
        local ok,registered=PM:RegisterElement(f.elementId,f,{
            moduleId=self.owner.id,
            defaultPosition={target="screen",placement="center",x=self.db[f.xKey],y=self.db[f.yKey]},
            canDrag=function() return self.active and (not separate or (self.db.separateBenefits and self.db.showBenefits)) end,
            onPositionChanged=function(element,position)
                element.position.x=math.floor(position.x+0.5);element.position.y=math.floor(position.y+0.5)
                self.db[f.xKey],self.db[f.yKey]=element.position.x,element.position.y
                if not element.dragging then PM:ApplyPosition(element.id) end
                if self.owner.page then self.owner.page:Refresh() end
                if not element.dragging and not self.rendering and not self.hiding and not self.syncingEdit then self:Render() end
            end,
            onHighlight=function()
                -- The manager owns Edit Mode input. Preserve existing explicit
                -- preview/placement input outside that mode.
                if not addon.editMode then
                    f:EnableMouse(P:OutsideCombat() and (self.placing or self.previewing or not self.db[f.lockKey]))
                end
            end,
        })
        assert(ok,"Play The Game Tools: campfire position registration failed: "..tostring(registered))
        e=registered
    end
    e.label=separate and "Camp Buffs" or "Campfire Monitor"
    e.editMode=self.active and (not separate or (self.db.separateBenefits and self.db.showBenefits)) or false
    self.db[f.xKey],self.db[f.yKey]=math.floor(e.position.x+0.5),math.floor(e.position.y+0.5)
end
function C:SyncEditDisplays()
    self.syncingEdit=true
    if self.active and P:OutsideCombat() then
        self:CreateDisplay(false)
        if self.db.separateBenefits and self.db.showBenefits then self:CreateDisplay(true) end
    end
    for _,f in pairs({self.frame,self.benefitsFrame}) do
        local e=Element(f)
        if e then e.editMode=self.active and (f==self.frame or (self.db.separateBenefits and self.db.showBenefits)) or false end
    end
    self.syncingEdit=nil
    if P:OutsideCombat() then PM:RefreshSelection() end
end
function C:SyncPositionOption(key)
    local separate=key=="benefitsX" or key=="benefitsY"
    if not separate and key~="x" and key~="y" then return end
    local f=separate and self.benefitsFrame or self.frame
    local id=separate and "campfireBuffs" or "campfireMonitor"
    local x,y=self.db[separate and "benefitsX" or "x"],self.db[separate and "benefitsY" or "y"]
    if f and Element(f) then PM:SetOffsets(id,x,y)
    else
        local saved=addon.db.positions and addon.db.positions[id]
        if saved and PM:ValidatePosition(saved,true) then saved.x=x;saved.y=y end
    end
end
function C:ResetWindowPosition(separate)
    self:StopDrag()
    local f=separate and self.benefitsFrame or self.frame
    local id=separate and "campfireBuffs" or "campfireMonitor"
    local x,y=separate and 260 or 0,-240
    local reset={target="screen",placement="center",x=x,y=y}
    if f and Element(f) then PM:SetPosition(id,reset)
    else
        self.db[separate and "benefitsX" or "x"]=x;self.db[separate and "benefitsY" or "y"]=y
        if addon.db.positions and addon.db.positions[id] and PM:ValidatePosition(addon.db.positions[id],true) then
            addon.db.positions[id]=reset
        end
    end
    self:Refresh()
end
function C:SetEditMode(enabled)
    self:StopDrag()
    self.editing=enabled and self.active and P:OutsideCombat() or false
    self:SyncEditDisplays();self:Refresh()
end
function C:StopDrag(f)
    if not f then
        if self.frame then self:StopDrag(self.frame) end
        if self.benefitsFrame then self:StopDrag(self.benefitsFrame) end
        return
    end
    local e=Element(f)
    if e and e.dragging then PM:StopDragging(f.elementId);return end
    if not f.dragging then return end
    f:StopMovingOrSizing();f.dragging=nil
    if not P:OutsideCombat() then return end
    if e then
        local x,y=addon.Positioning:ReadFrame(e.subject)
        PM:SetOffsets(f.elementId,x,y)
    end
end
function C:HideDisplays()
    self.hiding=true
    for _,f in pairs({self.frame,self.benefitsFrame}) do if f then f:Hide() end end
    self.hiding=nil
end
function C:CreateDisplay(separate)
    local key=separate and "benefitsFrame" or "frame"
    if self[key] then self:RegisterDisplay(self[key],separate);return self[key] end
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self[key]=f
    f.elementId=separate and "campfireBuffs" or "campfireMonitor"
    f.xKey=separate and "benefitsX" or "x";f.yKey=separate and "benefitsY" or "y"
    f.lockKey=separate and "benefitsLocked" or "locked"
    f:SetSize(separate and self.db.benefitsWidth or self.db.width,80)
    f:SetScale((separate and self.db.benefitsScale or self.db.scale)/100)
    f:SetPoint("CENTER",UIParent,"CENTER",self.db[f.xKey]/f:GetScale(),self.db[f.yKey]/f:GetScale())
    f:SetClampedToScreen(true);f:SetMovable(true);f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:Hide()
    f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetTexCoord(0.06,0.94,0.06,0.94)
    for _,name in ipairs({"text","caption","buffTitle","details","moveLabel"}) do
        f[name]=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        f[name]:SetJustifyH("CENTER");f[name]:SetWordWrap(true)
    end
    self:RegisterDisplay(f,separate)
    f:RegisterForDrag("LeftButton")
    f:HookScript("OnDragStart",function()
        if not addon.editMode and P:OutsideCombat() and (self.placing or self.previewing or not self.db[f.lockKey]) then
            f:StartMoving();f.dragging=true
        end
    end)
    f:HookScript("OnDragStop",function() self:StopDrag(f);self:Render() end)
    f:HookScript("OnMouseUp",function(_,button)
        if button=="RightButton" and self.placing then self:SetPlacementMode(false) end
    end)
    f:HookScript("OnHide",function() self:StopDrag(f) end)
    addon.Media:RegisterFontListener(f,function() if self.active or self.previewing or self.placing then self:Render() end end)
    return f
end
local function SetFont(label,path,size)
    if not label:SetFont(path,size,"OUTLINE") then label:SetFont(GameFontHighlight:GetFont(),size,"OUTLINE") end
end
local function Height(label,size)
    local ok,h=pcall(label.GetStringHeight,label)
    if ok and Number(h,1,10000) then return math.max(size+3,h) end
    local _,lines=label:GetText():gsub("\n","");return (lines+1)*(size+3)
end
function C:PaintDisplay(f,separate)
    local e=Element(f)
    if f.dragging or (e and e.dragging) then return end
    local db=self.db
    local scale=(separate and db.benefitsScale or db.scale)/100
    local width=separate and db.benefitsWidth or db.width
    local size=separate and db.benefitsFontSize or db.fontSize
    local background=separate and db.benefitsBackgroundOpacity or db.backgroundOpacity
    local opacity=separate and db.benefitsOpacity or db.opacity
    local font=addon.Media:GetInterfaceFont()
    f:SetScale(scale);f:SetWidth(width)
    f:EnableMouse(P:OutsideCombat() and (self.editing or self.placing or self.previewing or not db[f.lockKey]))
    f:SetBackdropColor(0.035,0.045,0.06,background/100)
    f:SetBackdropBorderColor(0.32,0.6,0.7,self.placing and 1 or (background>0 and 0.6 or 0))
    f:SetAlpha(opacity/100)
    local cursor=10
    local function Row(label,text,fontSize)
        SetFont(label,font,fontSize);label:SetWidth(width-20);label:ClearAllPoints()
        label:SetPoint("TOPLEFT",10,-cursor);label:SetText(text);label:Show()
        cursor=cursor+Height(label,fontSize)+5
    end
    if self.placing then Row(f.moveLabel,(separate and "Drag buffs" or "Drag monitor").." (right-click to finish)",12)
    else f.moveLabel:Hide() end
    local s=self.snapshot or {};local icon=s.near and s.near.icon
    if not P.Public(icon) or (type(icon)~="number" and type(icon)~="string") then icon=135805 end
    if not separate and db.showIcon then
        f.icon:SetTexture(icon);f.icon:ClearAllPoints();f.icon:SetPoint("TOP",f,"TOP",0,-cursor)
        f.icon:SetSize(db.iconSize,db.iconSize);f.icon:SetDesaturated(not self.previewing and not s.nearby)
        f.icon:Show();cursor=cursor+db.iconSize+7
    else f.icon:Hide() end
    if not separate and (db.showText or not db.showIcon) then
        f.caption:SetTextColor(unpack(db.textColor));Row(f.caption,self:MonitorStatus(),size)
    else f.caption:Hide() end
    if db.showBenefits and (separate or not db.separateBenefits) and (s.benefits or self:IsBuffSample() or self.placing) then
        Row(f.buffTitle,self:HeaderText("Camp Buffs"),db.benefitsFontSize+3)
        Row(f.text,self:ColorBuffText(self:BuildBenefitsText()),db.benefitsFontSize)
    else f.buffTitle:Hide();f.text:Hide() end
    local details=not separate and self:BuildText() or ""
    if details~="" then f.details:SetTextColor(unpack(db.textColor));Row(f.details,details,size)
    else f.details:Hide() end
    f:SetHeight(cursor+5)
    if e and P:OutsideCombat() then PM:ApplyPosition(f.elementId)
    elseif not e then f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",db[f.xKey]/scale,db[f.yKey]/scale) end
    f:Show()
end
function C:Render()
    if self.rendering then return end
    self.rendering=true
    local s,db=self.snapshot or {},self.db
    if not P:OutsideCombat() and not db.showInCombat then self:HideDisplays();self.rendering=nil;return end
    local enabled=self.active or self.previewing or self.placing or self.editing
    local earned=db.showBenefits and s.benefits~=nil
    local show=enabled and (self.editing or self.placing or self.previewing or db.alwaysShow or not db.locked or
        s.nearby==true or (earned and not db.separateBenefits))
    if show then self:PaintDisplay(self:CreateDisplay(false),false)
    elseif self.frame then self.frame:Hide() end
    local showBuffs=enabled and db.showBenefits and db.separateBenefits and (earned or self.editing or self.previewing or self.placing)
    if showBuffs then self:PaintDisplay(self:CreateDisplay(true),true)
    elseif self.benefitsFrame then self.benefitsFrame:Hide() end
    self.rendering=nil
end
