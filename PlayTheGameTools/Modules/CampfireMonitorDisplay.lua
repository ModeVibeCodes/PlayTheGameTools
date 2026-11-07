local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local C,P=addon.CampfireMonitor,addon.LootSparkles
function C:StopDrag()
    local f=self.frame
    if not f or not f.dragging then return end
    f:StopMovingOrSizing();f.dragging=nil
    if not P:OutsideCombat() then return end
    local x,y=f:GetCenter();local px,py=UIParent:GetCenter();local scale=f:GetScale()
    if P.Public(x) and P.Public(y) and P.Public(px) and P.Public(py) and P.Public(scale) and
        type(x)=="number" and type(y)=="number" and type(px)=="number" and type(py)=="number" and
        type(scale)=="number" and scale>0 and scale<=10 and x==x and y==y and px==px and py==py and
        math.abs(x)<100000 and math.abs(y)<100000 and math.abs(px)<100000 and math.abs(py)<100000 then
        self.db.x=math.max(-10000,math.min(10000,math.floor(x*scale-px+0.5)))
        self.db.y=math.max(-10000,math.min(10000,math.floor(y*scale-py+0.5)))
    end
end
function C:CreateDisplay()
    if self.frame then return end
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.frame=f
    f:SetClampedToScreen(true);f:SetMovable(true);f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function()
        if P:OutsideCombat() and not self.db.locked then f:StartMoving();f.dragging=true end
    end)
    f:SetScript("OnDragStop",function() self:StopDrag() end)
    f:SetScript("OnHide",function() self:StopDrag() end)
    f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetTexCoord(0.06,0.94,0.06,0.94)
    f.text=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    f.text:SetJustifyH("LEFT");f.text:SetWordWrap(true)
    addon.Media:RegisterFontListener(f,function() if self.active or self.previewing then self:Render() end end)
end
function C:Render()
    local s,db=self.snapshot or {},self.db
    if not P:OutsideCombat() and not db.showInCombat then
        if self.frame then self.frame:Hide() end;return
    end
    local show=(self.active or self.previewing) and
        (self.previewing or db.alwaysShow or not db.locked or s.nearby==true)
    if not show then if self.frame then self.frame:Hide() end;return end
    self:CreateDisplay()
    local f=self.frame;local scale=db.scale/100
    f:SetScale(scale);f:SetWidth(db.width);f:ClearAllPoints()
    f:SetPoint("CENTER",UIParent,"CENTER",db.x/scale,db.y/scale)
    f:EnableMouse(not db.locked and P:OutsideCombat())
    f:SetBackdropColor(0.035,0.045,0.06,db.backgroundOpacity/100)
    f:SetBackdropBorderColor(0.32,0.40,0.48,0.6);f:SetAlpha(db.opacity/100)
    local icon=s.near and s.near.icon
    if not P.Public(icon) or (type(icon)~="number" and type(icon)~="string") then icon=135805 end
    f.icon:SetTexture(icon);f.icon:ClearAllPoints();f.icon:SetPoint("TOPLEFT",10,-10)
    f.icon:SetSize(db.iconSize,db.iconSize);f.icon:SetShown(db.showIcon)
    f.icon:SetDesaturated(not self.previewing and not s.nearby)
    local left=db.showIcon and db.iconSize+20 or 10
    f.text:ClearAllPoints();f.text:SetPoint("TOPLEFT",left,-10);f.text:SetWidth(db.width-left-10)
    if not f.text:SetFont(addon.Media:GetInterfaceFont(),db.fontSize,"OUTLINE") then
        f.text:SetFont(GameFontHighlight:GetFont(),db.fontSize,"OUTLINE")
    end
    f.text:SetTextColor(unpack(db.textColor));f.text:SetText(self:BuildText())
    -- Native text height accounts for wrapping; the bounded fallback supports
    -- clients that cannot yet measure fonts during initial rendering.
    local ok,h=pcall(f.text.GetStringHeight,f.text)
    if not ok or not P.Public(h) or type(h)~="number" or h~=h or h<=0 or h>10000 then
        local _,lines=f.text:GetText():gsub("\n","");h=(lines+1)*(db.fontSize+3)
    end
    f:SetHeight(math.max(db.showIcon and db.iconSize or 0,h)+20)
    f:Show()
end
