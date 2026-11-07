local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,P=addon.CampfireMonitor,addon.LootSparkles
local function Number(v,lo,hi)
    return P.Public(v) and type(v)=="number" and v==v and v>=lo and v<=hi
end
function C:StopDrag(frame)
    if not frame then
        if self.frame then self:StopDrag(self.frame) end
        if self.benefitsFrame then self:StopDrag(self.benefitsFrame) end
        return
    end
    if not frame.dragging then return end
    frame:StopMovingOrSizing();frame.dragging=nil
    if not P:OutsideCombat() then return end
    local x,y=frame:GetCenter();local px,py=UIParent:GetCenter();local scale=frame:GetScale()
    if Number(x,-100000,100000) and Number(y,-100000,100000) and
        Number(px,-100000,100000) and Number(py,-100000,100000) and Number(scale,0.01,10) then
        self.db[frame.xKey]=math.max(-10000,math.min(10000,math.floor(x*scale-px+0.5)))
        self.db[frame.yKey]=math.max(-10000,math.min(10000,math.floor(y*scale-py+0.5)))
    end
end
function C:HideDisplays()
    for _,f in pairs({self.frame,self.benefitsFrame}) do if f then f:Hide() end end
end
function C:CreateDisplay(separate)
    local key=separate and "benefitsFrame" or "frame"
    if self[key] then return self[key] end
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self[key]=f
    f.xKey=separate and "benefitsX" or "x";f.yKey=separate and "benefitsY" or "y"
    f.lockKey=separate and "benefitsLocked" or "locked"
    f:SetClampedToScreen(true);f:SetMovable(true);f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function()
        if P:OutsideCombat() and (self.placing or self.previewing or not self.db[f.lockKey]) then
            f:StartMoving();f.dragging=true
        end
    end)
    f:SetScript("OnDragStop",function() self:StopDrag(f);self:Render() end)
    f:SetScript("OnMouseUp",function(_,button)
        if button=="RightButton" and self.placing then self:SetPlacementMode(false) end
    end)
    f:SetScript("OnHide",function() self:StopDrag(f) end)
    f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetTexCoord(0.06,0.94,0.06,0.94)
    f.text=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    f.text:SetJustifyH("LEFT");f.text:SetWordWrap(true)
    f.moveLabel=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    addon.Media:RegisterFontListener(f,function() if self.active or self.previewing or self.placing then self:Render() end end)
    return f
end
function C:PaintDisplay(f,separate,text)
    -- UNIT_AURA and font callbacks can arrive while the mouse is held down.
    -- Leave all geometry alone until drag stop has saved the new position.
    if f.dragging then return end
    local db=self.db
    local scale=(separate and db.benefitsScale or db.scale)/100
    local width=separate and db.benefitsWidth or db.width
    local fontSize=separate and db.benefitsFontSize or db.fontSize
    local background=separate and db.benefitsBackgroundOpacity or db.backgroundOpacity
    local opacity=separate and db.benefitsOpacity or db.opacity
    f:SetScale(scale);f:SetWidth(width);f:ClearAllPoints()
    f:SetPoint("CENTER",UIParent,"CENTER",db[f.xKey]/scale,db[f.yKey]/scale)
    f:EnableMouse(P:OutsideCombat() and (self.placing or self.previewing or not db[f.lockKey]))
    f:SetBackdropColor(0.035,0.045,0.06,background/100)
    f:SetBackdropBorderColor(0.32,0.6,0.7,self.placing and 1 or (background>0 and 0.6 or 0))
    f:SetAlpha(opacity/100)
    local moveHeight=self.placing and 24 or 0
    local font=addon.Media:GetInterfaceFont()
    f.moveLabel:SetFont(font,12,"OUTLINE");f.moveLabel:SetTextColor(0.65,0.9,1)
    f.moveLabel:ClearAllPoints();f.moveLabel:SetPoint("TOPLEFT",10,-8);f.moveLabel:SetWidth(width-20)
    f.moveLabel:SetText((separate and "Drag buffs" or "Drag monitor").." (right-click to finish)")
    f.moveLabel:SetShown(self.placing==true)
    local s=self.snapshot or {};local icon=s.near and s.near.icon
    if not P.Public(icon) or (type(icon)~="number" and type(icon)~="string") then icon=135805 end
    local showIcon=not separate and db.showIcon
    f.icon:SetTexture(icon);f.icon:ClearAllPoints();f.icon:SetPoint("TOPLEFT",10,-10-moveHeight)
    f.icon:SetSize(db.iconSize,db.iconSize);f.icon:SetShown(showIcon)
    f.icon:SetDesaturated(not self.previewing and not s.nearby)
    local left=showIcon and db.iconSize+20 or 10
    f.text:ClearAllPoints();f.text:SetPoint("TOPLEFT",left,-10-moveHeight);f.text:SetWidth(width-left-10)
    if not f.text:SetFont(font,fontSize,"OUTLINE") then f.text:SetFont(GameFontHighlight:GetFont(),fontSize,"OUTLINE") end
    f.text:SetTextColor(unpack(db.textColor));f.text:SetText(text)
    local ok,h=pcall(f.text.GetStringHeight,f.text)
    if not ok or not Number(h,1,10000) then
        local _,lines=text:gsub("\n","");h=(lines+1)*(fontSize+3)
    end
    f:SetHeight(math.max(showIcon and db.iconSize or 0,h)+20+moveHeight)
    f:Show()
end
function C:Render()
    local s,db=self.snapshot or {},self.db
    if not P:OutsideCombat() and not db.showInCombat then self:HideDisplays();return end
    local enabled=self.active or self.previewing or self.placing
    local earned=db.showBenefits and s.benefits~=nil
    local show=enabled and (self.placing or self.previewing or db.alwaysShow or not db.locked or
        s.nearby==true or (earned and not db.separateBenefits))
    if show then self:PaintDisplay(self:CreateDisplay(false),false,self:BuildText())
    elseif self.frame then self.frame:Hide() end
    local showBuffs=enabled and db.showBenefits and db.separateBenefits and (earned or self.previewing or self.placing)
    if showBuffs then self:PaintDisplay(self:CreateDisplay(true),true,self:BuildBenefitsText())
    elseif self.benefitsFrame then self.benefitsFrame:Hide() end
end
