local _, addon = ...
local Map = { markers={}, lines={} }
addon.DungeonLootMap = Map
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function OOC()
    if type(InCombatLockdown)~="function" or type(UnitAffectingCombat)~="function" then return false end
    for _,fn in ipairs({InCombatLockdown,UnitAffectingCombat}) do
        local ok,value=pcall(fn,"player")
        if not ok or not Public(value) or value~=false then return false end
    end
    return true
end
function Map:Clear()
    self.target=nil;self.returnToConfig=nil
    if self.overlay then self.overlay:Hide() end
    for _,pin in ipairs(self.markers) do pin:Hide() end
    for _,line in ipairs(self.lines) do line:Hide() end
end
function Map:Dismiss()
    local restore=self.returnToConfig
    self:Clear();self.returnToConfig=restore
    if GameTooltip then GameTooltip:Hide() end
end
function Map:Render()
    for _,pin in ipairs(self.markers) do pin:Hide() end
    for _,line in ipairs(self.lines) do line:Hide() end
    local target,map=self.target,self.map
    if not target or not map or not map:IsShown() or map:GetMapID()~=target.mapID then return end
    local canvas=map:GetCanvas()
    local width,height=canvas:GetWidth(),canvas:GetHeight()
    if not Public(width) or not Public(height) or type(width)~="number" or type(height)~="number" or width<=0 or height<=0 then return end
    if not self.overlay then
        self.overlay=CreateFrame("Frame",nil,canvas);self.overlay:SetAllPoints(canvas)
        self.overlay:SetFrameLevel(canvas:GetFrameLevel()+50);self.overlay:EnableMouse(false)
    end
    local layer=self.overlay
    layer:SetFrameStrata(type(map.GetFrameStrata)=="function" and map:GetFrameStrata() or "HIGH")
    layer:SetFrameLevel(math.max(canvas:GetFrameLevel(),map:GetFrameLevel())+200);layer:Show()
    local points=target.points
    if #points==0 then points={{target.x,target.y}} end
    for index,point in ipairs(points) do
        local pin=self.markers[index]
        if not pin then
            pin=CreateFrame("Button",nil,layer);pin:SetSize(40,40);pin:EnableMouse(true);pin:RegisterForClicks("RightButtonUp")
            pin.back=pin:CreateTexture(nil,"BORDER");pin.back:SetAllPoints(pin);pin.back:SetColorTexture(.08,.04,.14,.92)
            pin.rim=pin:CreateTexture(nil,"BACKGROUND");pin.rim:SetPoint("TOPLEFT",-2,2);pin.rim:SetPoint("BOTTOMRIGHT",2,-2);pin.rim:SetColorTexture(1,.72,.26,.9)
            pin.caption=pin:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            pin.caption:SetPoint("TOP",pin,"BOTTOM",0,-4);pin.caption:SetWidth(200);pin.caption:SetJustifyH("CENTER")
            pin.caption:SetTextColor(1,.86,.5,1);pin.caption:SetShadowColor(0,0,0,1);pin.caption:SetShadowOffset(1,-1)
            pin:SetScript("OnClick",function(_,button) if button=="RightButton" then self:Dismiss() end end)
            pin.icon=pin:CreateTexture(nil,"OVERLAY");pin.icon:SetPoint("TOPLEFT",4,-4);pin.icon:SetPoint("BOTTOMRIGHT",-4,4)
            pin:SetScript("OnEnter",function(owner)
                if GameTooltip then GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(owner.label);GameTooltip:Show() end
            end)
            pin:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
            self.markers[index]=pin
        end
        pin:SetFrameStrata(type(map.GetFrameStrata)=="function" and map:GetFrameStrata() or "HIGH");pin:SetFrameLevel(layer:GetFrameLevel()+1)
        pin.label=target.label..(target.approximate and " — approximate location" or "")..(#target.paths>0 and " — recorded patrol" or "")
        pin.label=pin.label..(target.detail and ("\n"..target.detail) or "").."\nRight-click to dismiss."
        pin.caption:SetText(target.label..(target.approximate and "\nApproximate location" or ""))
        pin.icon:SetTexture(self.kind=="pickup" and "Interface\\GossipFrame\\AvailableQuestIcon" or self.kind=="turnin" and "Interface\\GossipFrame\\ActiveQuestIcon" or "Interface\\WorldMap\\Skull_64")
        pin:ClearAllPoints();pin:SetPoint("CENTER",layer,"TOPLEFT",width*point[1],-height*point[2]);pin:Show()
    end
    local count=0
    for _,path in ipairs(target.paths) do
        for index=2,#path do
            if type(layer.CreateLine)=="function" then
                count=count+1
                local line=self.lines[count] or layer:CreateLine(nil,"OVERLAY")
                self.lines[count]=line;line:SetColorTexture(1,0.8,0.2,0.95);line:SetThickness(2)
                line:SetStartPoint("TOPLEFT",layer,width*path[index-1][1],-height*path[index-1][2])
                line:SetEndPoint("TOPLEFT",layer,width*path[index][1],-height*path[index][2]);line:Show()
            end
        end
    end
end
function Map:Open(target,kind)
    if not addon.DungeonLoot.active then return false,"Enable Dungeon Loot first." end
    if not OOC() then return false,"Leave combat to open quest locations." end
    if not target then return false,"No recorded location." end
    if not WorldMapFrame and C_AddOns and type(C_AddOns.LoadAddOn)=="function" then pcall(C_AddOns.LoadAddOn,"Blizzard_WorldMap") end
    local map=WorldMapFrame
    if not map or type(map.SetMapID)~="function" or type(map.GetCanvas)~="function" or type(map.AddDataProvider)~="function" or not MapCanvasDataProviderMixin or type(CreateFromMixins)~="function" or type(ShowUIPanel)~="function" then return false,"World map is unavailable on this client." end
    local ok,reason=pcall(function()
        if not self.provider then
            self.map=map
            local provider=CreateFromMixins(MapCanvasDataProviderMixin)
            provider.RefreshAllData=function() self:Render() end
            provider.OnCanvasSizeChanged=provider.RefreshAllData
            provider.OnCanvasScaleChanged=provider.RefreshAllData
            provider.OnHide=function()
                local restore=self.returnToConfig;self:Clear()
                if restore and OOC() and addon.DungeonLoot.active and addon.configWindow then addon.configWindow:Show() end
            end
            map:AddDataProvider(provider);self.provider=provider
        end
        self.target,self.kind=target,kind
        ShowUIPanel(map);map:SetMapID(target.mapID)
        if not map:IsShown() or map:GetMapID()~=target.mapID then error("Map open rejected") end
        self:Render()
        if addon.configWindow and addon.configWindow:IsShown() then
            self.returnToConfig=true;addon.configWindow:Hide()
        end
    end)
    if not ok then self:Clear();return false,"The client could not open this quest location." end
    return true
end
