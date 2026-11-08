local _,addon=...
local M,P=addon.ForeverClassTraining,addon.ForeverTrainingData

local function CancelResizeLayout(f)
    f.layoutGeneration=(f.layoutGeneration or 0)+1
    f.layoutQueued=nil
end

-- UIParent coordinates throughout, so inherited UI scale does not mix units.
function P.TrainingFlyoutBounds(x,y,left,bottom,width,height,wantedWidth,wantedHeight)
    local G=P.NewGuard(_G)
    local values={x,y,left,bottom,width,height}
    for i=1,6 do
        local v=values[i]
        if not G:Public(v) or type(v)~="number" or v~=v or math.abs(v)==math.huge then return end
    end
    if width<160 or height<160 then return end
    local above=bottom+height-y-26;local below=y-bottom-26
    if not G:Integer(wantedWidth,280,1600) then wantedWidth=320 end
    local customHeight=G:Integer(wantedHeight,240,1600)
    if not customHeight then wantedHeight=440 end
    local upwards=above>=wantedHeight or above>=below
    local room=math.max(above,below)
    local h=math.min(wantedHeight,height-16,customHeight and height-16 or math.max(140,room))
    local w=math.min(wantedWidth,width-16)
    local px=math.max(left+8,math.min(x-20,left+width-w-8))
    local py=upwards and y+26 or y-26-h
    py=math.max(bottom+8,math.min(py,bottom+height-h-8))
    return px-left,py-bottom,w,h,upwards
end

function M:CloseTrainingFlyout()
    if self.trainingFlyout then
        CancelResizeLayout(self.trainingFlyout)
        self.trainingFlyout:StopMovingOrSizing();self.trainingFlyout.resizing=nil
        self.trainingFlyout:Hide()
    end
    addon.QuickActions:SetActive("classTraining",false)
end

function M:PlaceTrainingFlyout()
    if not self.shortcut or not self.trainingFlyout or not self:OutsideCombat() then return false end
    -- Anchored to the launcher: the Class Training icon hides as soon as the ring closes.
    local x,y=addon.QuickActions:Center()
    local px,py,w,h,up=P.TrainingFlyoutBounds(x,y,UIParent:GetLeft(),UIParent:GetBottom(),UIParent:GetWidth(),UIParent:GetHeight(),self.db.flyoutWidth,self.db.flyoutHeight)
    if not px then self:CloseTrainingFlyout();return false end
    local f=self.trainingFlyout
    f.placing=true
    f:SetResizeBounds(math.min(280,UIParent:GetWidth()-16),math.min(240,UIParent:GetHeight()-16),math.min(1600,UIParent:GetWidth()-16),math.min(1600,UIParent:GetHeight()-16))
    f:SetSize(w,h);f:ClearAllPoints();f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",px,py)
    f.placing=nil
    f.opensUpwards=up
    f.content:SetWidth(w-28)
    f.title:SetWidth(w-110);f.subtitle:SetWidth(w-24);f.wallet:SetWidth(w-24)
    f.configurationButton:SetWidth(math.min(170,w-24));f.emptyLabel:SetWidth(w-40)
    return true
end

function M:FlyoutOpacity()
    local value=self.db.flyoutOpacity
    return P.NewGuard(_G):Integer(value,10,100) and value or 35
end

function M:FlyoutTextSize()
    local value=self.db.flyoutTextSize
    return P.NewGuard(_G):Integer(value,10,18) and value or 12
end

-- Resizing changes geometry only: cached text/icons/totals and fonts stay intact.
-- Height-only changes need no row measurements. Width bursts coalesce while dragging.
function M:LayoutTrainingFlyout()
    local f=self.trainingFlyout
    if not f or not self:OutsideCombat() then return end
    local width=f:GetWidth()-28
    local headerBottom=59
    f.wallet:SetShown(self.db.flyoutShowMoney~=false)
    if self.db.flyoutShowMoney~=false then f.wallet:ClearAllPoints();f.wallet:SetPoint("TOPLEFT",12,-headerBottom);headerBottom=headerBottom+20 end
    f.trainingTotal:SetShown(self.db.flyoutShowTrainingTotal~=false)
    if self.db.flyoutShowTrainingTotal~=false then
        f.trainingTotal:ClearAllPoints();f.trainingTotal:SetPoint("TOPLEFT",12,-headerBottom);headerBottom=headerBottom+20
    end
    f.scroll:ClearAllPoints();f.scroll:SetPoint("TOPLEFT",8,-(headerBottom+5));f.scroll:SetPoint("BOTTOMRIGHT",-22,48)
    f.scrollbar:ClearAllPoints();f.scrollbar:SetPoint("TOPRIGHT",-9,-(headerBottom+7));f.scrollbar:SetPoint("BOTTOMRIGHT",-9,50)
    f.content:SetWidth(width)
    f.title:SetWidth(f:GetWidth()-110);f.subtitle:SetWidth(f:GetWidth()-24);f.wallet:SetWidth(f:GetWidth()-24);f.trainingTotal:SetWidth(f:GetWidth()-24)
    f.configurationButton:SetWidth(math.min(170,f:GetWidth()-48));f.emptyLabel:SetWidth(width-8)
    local size=self:FlyoutTextSize()
    if f.layoutWidth~=width or f.layoutSize~=size or f.layoutDirty then
        local cursor=0
        for i=1,f.visibleEntries or 0 do
            local item=f.entries[i]
            item.frame:SetWidth(width);item.frame:ClearAllPoints();item.frame:SetPoint("TOPLEFT",0,-cursor)
            local fontSize=item.heading and size+5 or size
            if item.fontSize~=fontSize then
                addon.Media:BindInterfaceFont(item.label,GameFontHighlight,fontSize)
                addon.Media:BindInterfaceFont(item.cost,GameFontHighlight,item.heading and size+2 or size)
                item.fontSize=fontSize
            end
            local costWidth=math.min(160,math.floor(width*0.44))
            if item.heading then
                item.label:SetWidth(0)
                local labelWidth=math.min(width*0.45,item.label:GetStringWidth())
                item.label:SetWidth(labelWidth)
                item.cost:ClearAllPoints();item.cost:SetPoint("LEFT",item.label,"RIGHT",8,0)
                item.cost:SetWidth(math.max(40,width-labelWidth-16));item.cost:SetJustifyH("LEFT")
            else
                item.label:SetWidth(math.max(40,width-costWidth-36))
                item.cost:ClearAllPoints();item.cost:SetPoint("RIGHT",-2,0);item.cost:SetWidth(costWidth);item.cost:SetJustifyH("RIGHT")
            end
            local h=math.max(item.heading and size+21 or size+18,item.label:GetStringHeight()+14,
                item.cost:IsShown() and item.cost:GetStringHeight()+14 or 0)
            item.frame:SetHeight(h);cursor=cursor+h
        end
        f.content:SetHeight(math.max(48,cursor+8))
        f.layoutWidth,f.layoutSize,f.layoutDirty=width,size,nil
    end
    f.maxScroll=math.max(0,f.content:GetHeight()-f.scroll:GetHeight())
    f.scrollbar:SetMinMaxValues(0,f.maxScroll);f.scrollbar:SetValue(math.min(f.scrollbar:GetValue(),f.maxScroll));f.scrollbar:SetShown(f.maxScroll>0)
end

function M:QueueFlyoutResizeLayout()
    local f=self.trainingFlyout
    if not f or f.layoutQueued then return end
    f.layoutQueued=true
    local generation=f.layoutGeneration or 0
    C_Timer.After(0.06,function()
        if generation~=(f.layoutGeneration or 0) then return end
        f.layoutQueued=nil
        if f.resizing and f:IsShown() and self:OutsideCombat() then self:LayoutTrainingFlyout() end
    end)
end

function M:UpdateFlyoutMoney()
    if not self.trainingFlyout or not self.trainingFlyout:IsShown() or self.db.flyoutShowMoney==false or not self:OutsideCombat() then return end
    local G=P.NewGuard(_G);local ok,money=G:Call(GetMoney)
    self.trainingFlyout.wallet:SetText("Money  "..(ok and G:Integer(money,0,1e12) and self:MoneyText(money,true) or "Unavailable"))
end

function M:CreateTrainingFlyout()
    if self.trainingFlyout then return end
    local W,T=addon.ConfigWidgets,addon.Theme
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");f:SetSize(320,440)
    f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
    f:SetResizable(true)
    local background=f:CreateTexture(nil,"BACKGROUND");background:SetPoint("TOPLEFT",1,-1);background:SetPoint("BOTTOMRIGHT",-1,1)
    background:SetColorTexture(0.03,0.04,0.05,self:FlyoutOpacity()/100);f.background=background
    -- A native edge fits the actual frame; stretching the square artwork inset its visible border.
    f:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropBorderColor(0.45,0.52,0.58,0.85)
    f.title=W.Heading(f,"Class Training",16,12,-12,220,T.primary)
    local minimize=W.Button(f,"Minimize",72,24,"secondary");minimize:SetPoint("TOPRIGHT",-10,-8)
    minimize:SetScript("OnClick",function() self:CloseTrainingFlyout() end)
    f.minimizeButton=minimize
    f.subtitle=W.Label(f,"",nil,12,-40,290,T.muted)
    f.wallet=W.Label(f,"Money  Unavailable",nil,12,-59,290,T.text)
    f.trainingTotal=W.Label(f,"",nil,12,-79,290,T.text)
    local scroll=CreateFrame("ScrollFrame",nil,f)
    scroll:SetPoint("TOPLEFT",8,-84);scroll:SetPoint("BOTTOMRIGHT",-22,48);scroll:EnableMouseWheel(true)
    local content=CreateFrame("Frame",nil,scroll);content:SetSize(292,1);scroll:SetScrollChild(content)
    local bar=CreateFrame("Slider",nil,f);bar:SetPoint("TOPRIGHT",-9,-86);bar:SetPoint("BOTTOMRIGHT",-9,50)
    bar:SetWidth(7);bar:SetOrientation("VERTICAL");bar:SetValueStep(24);W.ScrollThumb(bar,28)
    f.scroll,f.content,f.scrollbar=scroll,content,bar
    f.entries={}
    bar:SetScript("OnValueChanged",function(_,value) scroll:SetVerticalScroll(value) end)
    local function wheel(_,delta) bar:SetValue(math.max(0,math.min(f.maxScroll or 0,bar:GetValue()-delta*48))) end
    scroll:SetScript("OnMouseWheel",wheel);f:EnableMouseWheel(true);f:SetScript("OnMouseWheel",wheel)
    content:EnableMouseWheel(true);content:SetScript("OnMouseWheel",wheel)
    local config=W.Button(f,"Jump to Settings",170,28,"button");config:SetPoint("BOTTOM",0,10)
    config:SetScript("OnClick",function() self:CloseTrainingFlyout();self:OpenTraining(3) end)
    f.configurationButton=config
    f.emptyLabel=W.Label(content,"",nil,4,-8,270,T.muted)
    f.emptyLabel:SetWordWrap(true)
    local grip=CreateFrame("Button",nil,f);grip:SetSize(18,18);grip:SetPoint("BOTTOMRIGHT",-1,1);grip:EnableMouse(true)
    local gripIcon=grip:CreateTexture(nil,"ARTWORK");gripIcon:SetAllPoints()
    gripIcon:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");gripIcon:SetVertexColor(0.75,0.85,0.9,1)
    f.resizeIcon=gripIcon
    f.resizeGrip=grip
    grip:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or not self:OutsideCombat() then return end
        local left,top=f:GetLeft(),f:GetBottom()+f:GetHeight()
        f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left-UIParent:GetLeft(),top-UIParent:GetBottom())
        f.resizing=true;f:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp",function(_,button)
        if button~="LeftButton" or not f.resizing then return end
        f:StopMovingOrSizing();f.resizing=nil
        CancelResizeLayout(f)
        if not self:OutsideCombat() then self:CloseTrainingFlyout();return end
        self.db.flyoutWidth=math.floor(f:GetWidth()+0.5);self.db.flyoutHeight=math.floor(f:GetHeight()+0.5)
        if f.renderPending then f.renderPending=nil;self:RenderTrainingFlyout()
        else self:PlaceTrainingFlyout();self:LayoutTrainingFlyout() end
    end)
    f:SetScript("OnSizeChanged",function()
        if f.resizing and not f.placing and self:OutsideCombat() then self:QueueFlyoutResizeLayout() end
    end)
    f:SetScript("OnHide",function()
        CancelResizeLayout(f)
        addon.QuickActions:SetActive("classTraining",false)
    end)
    f:Hide();self.trainingFlyout=f
end

function M:RenderTrainingFlyout()
    if not self.trainingFlyout or not self:OutsideCombat() then return end
    if self.trainingFlyout.resizing then self.trainingFlyout.renderPending=true;return end
    self.trainingFlyout.renderPending=nil
    if not self:PlaceTrainingFlyout() then return end
    local f=self.trainingFlyout;local W,T=addon.ConfigWidgets,addon.Theme
    f.content:SetWidth(f:GetWidth()-28)
    f.title:SetWidth(f:GetWidth()-110);f.subtitle:SetWidth(f:GetWidth()-24);f.wallet:SetWidth(f:GetWidth()-24)
    f.background:SetColorTexture(0.03,0.04,0.05,self:FlyoutOpacity()/100)
    f.subtitle:SetText(self.message or "No class data")
    f.trainingTotal:SetText("Training total  "..self:MoneyText(P.TrainingTotal(self.rows or {})))
    for _,item in ipairs(f.entries) do item.frame:Hide() end
    local index,level=0,nil
    local function entry(heading)
        index=index+1;local item=f.entries[index]
        if not item then
            local frame=CreateFrame("Frame",nil,f.content);frame:SetSize(292,30)
            local icon=frame:CreateTexture(nil,"ARTWORK");icon:SetSize(22,22);icon:SetPoint("LEFT",2,0)
            local label=W.Label(frame,"",nil,28,-7,180,T.text)
            label:SetWordWrap(true)
            local cost=W.Label(frame,"",nil,0,0,98,T.text);cost:ClearAllPoints();cost:SetPoint("RIGHT",-2,0);cost:SetJustifyH("RIGHT")
            local divider=frame:CreateTexture(nil,"ARTWORK");divider:SetColorTexture(0.45,0.65,0.6,0.25)
            divider:SetHeight(1);divider:SetPoint("BOTTOMLEFT",4,1);divider:SetPoint("BOTTOMRIGHT",-4,1)
            item={frame=frame,icon=icon,label=label,cost=cost,divider=divider};f.entries[index]=item
            frame:EnableMouse(true)
            frame:SetScript("OnEnter",function(owner)
                if not GameTooltip then return end
                GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
                if item.heading then
                    GameTooltip:SetText("Estimated level cost")
                    GameTooltip:AddLine("This level's displayed unlearned abilities only. Earlier levels and learned abilities are excluded. Actual trainer prices may differ.",0.8,0.8,0.8,true)
                elseif item.record then
                    local name=self:SpellPresentation(item.record);GameTooltip:SetText(name)
                    GameTooltip:AddLine(self:MoneyText(item.record.cost),0.8,0.8,0.8)
                    GameTooltip:AddLine("Estimated price before trainer discounts.",0.8,0.8,0.8,true)
                else return end
                GameTooltip:Show()
            end)
            frame:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        end
        item.icon:SetShown(not heading);item.cost:SetShown(not heading or self.db.flyoutShowLevelCost~=false);item.divider:SetShown(heading)
        item.record=nil
        item.label:ClearAllPoints();item.label:SetPoint("LEFT",heading and 4 or 28,0)
        item.cost:SetWordWrap(true)
        item.heading=heading;item.frame:Show()
        return item
    end
    local totals={};local G=P.NewGuard(_G)
    for _,row in ipairs(self.rows or {}) do
        if row.tab~="Learned" then
            local n=row.record.level;totals[n]=totals[n] or {cost=0,unknown=false}
            if G:Integer(row.record.cost,0,1e12) then totals[n].cost=totals[n].cost+row.record.cost else totals[n].unknown=true end
        end
    end
    for _,row in ipairs(self.rows or {}) do
        if row.tab~="Learned" then
            if level~=row.record.level then
                level=row.record.level;local heading=entry(true)
                local estimate=self:MoneyText(totals[level].cost)..(totals[level].unknown and " + ?" or "")
                local iconSize=tostring(self:FlyoutTextSize()+1)
                estimate=estimate:gsub(":12:12:",":"..iconSize..":"..iconSize..":")
                heading.label:SetText("Level "..level)
                heading.cost:SetText("· "..estimate)
            end
            local item=entry(false);local name,icon=self:SpellPresentation(row.record)
            item.record=row.record
            item.icon:SetTexture(icon);item.label:SetText(name);item.cost:SetText(self:MoneyText(row.record.cost))
        end
    end
    f.emptyLabel:SetShown(index==0)
    f.emptyLabel:SetText(self.rows and "No unlearned abilities." or "Training data unavailable.")
    f.visibleEntries=index
    f.layoutDirty=true;self:LayoutTrainingFlyout()
    self:UpdateFlyoutMoney()
end

function M:ToggleTrainingFlyout()
    if not self.active or not self:OutsideCombat() or not self.shortcut or not self.shortcut:IsShown() then return false end
    if self.trainingFlyout and self.trainingFlyout:IsShown() then self:CloseTrainingFlyout();return true end
    self:RefreshTraining()
    if not self.rows then return false end
    self:CreateTrainingFlyout();self.trainingFlyout.scrollbar:SetValue(0)
    self:RenderTrainingFlyout();if not self:PlaceTrainingFlyout() then return false end
    self.trainingFlyout:Show();addon.QuickActions:SetActive("classTraining",true)
    self:UpdateFlyoutMoney()
    return true
end
