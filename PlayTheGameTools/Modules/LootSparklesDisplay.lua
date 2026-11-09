local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local M=addon.LootSparkles

function M:Release()
    if not self.overlay then return end
    self.overlay:Hide(); self.overlay:SetScript("OnUpdate",nil)
    self.overlay:ClearAllPoints(); self.overlay:SetParent(UIParent)
    self.anchor=nil
end
function M:ShowTarget(plate,name,state)
    if not self.overlay then
        local f=CreateFrame("Frame",nil,UIParent); self.overlay=f
        f:SetSize(1,1); f:EnableMouse(false)
        f.label=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        f.label:SetWidth(240); f.label:SetJustifyH("CENTER"); f.label:SetWordWrap(true)
        f.glints={}
        for i=1,5 do
            local t=f:CreateTexture(nil,"ARTWORK")
            t:SetTexture("Interface\\Cooldown\\star4"); t:SetBlendMode("ADD")
            f.glints[i]=t
        end
    end
    local f,db=self.overlay,self.db
    if self.anchor~=plate then
        f:SetParent(plate); f:ClearAllPoints(); f:SetPoint("CENTER",plate,"CENTER",0,db.offsetY)
        f:SetIgnoreParentAlpha(true); self.anchor=plate; self.phase=0
    else
        f:ClearAllPoints(); f:SetPoint("CENTER",plate,"CENTER",0,db.offsetY)
    end
    self.state=state
    local r,g,b=1,0.82,0.3
    if state=="Unavailable" then r,g,b=0.6,0.6,0.6 end
    self.tint={r,g,b}
    f.label:SetFont(addon.Media:GetInterfaceFont(nil,"lootSparkles"),db.fontSize,"OUTLINE")
    f.label:SetTextColor(r,g,b)
    f.label:ClearAllPoints(); f.label:SetPoint("TOP",f,"BOTTOM",0,-db.size*0.65)
    f.label:SetText(name~="" and (name.."\n"..state) or state)
    f.label:SetShown(db.showNames)
    f:SetAlpha(db.opacity/100)
    f:SetScript("OnUpdate",function(_,elapsed)
        if not self.nodes or not self:OutsideCombat() then self:Release(); return end
        self.phase=self.phase+math.min(elapsed,0.1)
        local intensity=self.state=="In reach" and 1 or 0.45
        for i,t in ipairs(f.glints) do
            local phase=self.phase*(0.8+i*0.13)+i*1.9
            local pulse=0.25+0.75*(0.5+0.5*math.sin(phase*3))
            t:ClearAllPoints()
            t:SetPoint("CENTER",f,"CENTER",math.cos(i*2.4)*db.size*0.75,
                math.sin(i*2.4)*db.size*0.4+math.sin(phase)*7)
            t:SetSize(db.size*pulse,db.size*pulse)
            t:SetRotation(phase*0.35)
            t:SetVertexColor(self.tint[1],self.tint[2],self.tint[3],intensity*pulse)
        end
    end)
    f:Show()
end
