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
-- Native map pins are acquired only after Blizzard_MapCanvas is loaded. Keep
-- our template mixin available to XML now, then compose the client base at Open.
local Pin={}
_G.PlayTheGameToolsDungeonLootMapPinMixin=Pin
local TEMPLATE="PlayTheGameToolsDungeonLootMapPinTemplate"
function Pin:OnLoad()
    self:SetSize(36,36)
    self.rim=self:CreateTexture(nil,"BACKGROUND");self.rim:SetAllPoints(self);self.rim:SetColorTexture(1,1,1,1)
    self.rim:SetGradient("HORIZONTAL",CreateColor(159/255,204/255,250/255,1),CreateColor(9/255,116/255,241/255,1))
    self.back=self:CreateTexture(nil,"BORDER");self.back:SetPoint("TOPLEFT",2,-2);self.back:SetPoint("BOTTOMRIGHT",-2,2);self.back:SetColorTexture(.035,.06,.10,.95)
    self.icon=self:CreateTexture(nil,"OVERLAY");self.icon:SetSize(24,24);self.icon:SetPoint("CENTER",self,"CENTER",0,0)
end
function Pin:UpdateTarget(owner,x,y,kind)
    self.owner=owner
    self.label="Approximate location - Right Click to Hide Icon"
    self:UseFrameLevelType("PIN_FRAME_LEVEL_TOPMOST")
    self:SetIgnoreGlobalPinScale(true)
    self:SetScalingLimits(1,1,1) -- compensate canvas zoom; keep 36px on screen
    self:SetAlpha(1)
    self.icon:SetTexture(kind=="pickup" and "Interface\\GossipFrame\\AvailableQuestIcon" or kind=="turnin" and "Interface\\GossipFrame\\ActiveQuestIcon" or "Interface\\WorldMap\\Skull_64")
    self:SetPosition(x,y)
    self:ApplyCurrentScale()
    self:Show()
end
function Pin:OnAcquired(...) self:UpdateTarget(...) end
function Pin:OnReleased()
    MapCanvasPinMixin.OnReleased(self)
    self.owner=nil
end
function Pin:OnCanvasSizeChanged() self:ApplyCurrentPosition() end
function Pin:ShouldMouseButtonBePassthrough() return false end
function Pin:OnMouseClickAction(button)
    if button=="RightButton" and self.owner then self.owner:Dismiss() end
end
function Pin:OnMouseEnter()
    if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(self.label);GameTooltip:Show() end
end
function Pin:OnMouseLeave() if GameTooltip then GameTooltip:Hide() end end
function Map:ReleasePins()
    for index=#self.markers,1,-1 do
        local pin=self.markers[index]
        self.markers[index]=nil
        self.map:RemovePin(pin)
    end
end
function Map:Clear()
    self.generation=(self.generation or 0)+1
    self.target=nil;self.returnToConfig=nil
    if self.overlay then self.overlay:Hide() end
    self:ReleasePins()
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
    if not target or not map or not map:IsShown() or map:GetMapID()~=target.mapID then self:ReleasePins();return end
    local canvas=map:GetCanvas()
    if not canvas then return end
    local width,height=canvas:GetWidth(),canvas:GetHeight()
    if not Public(width) or not Public(height) or type(width)~="number" or type(height)~="number" or width<=0 or height<=0 then return end
    if not self.overlay then
        self.overlay=CreateFrame("Frame",nil,canvas);self.overlay:SetAllPoints(canvas)
        self.overlay:SetFrameLevel(canvas:GetFrameLevel()+50);self.overlay:EnableMouse(false)
    end
    local layer=self.overlay
    layer:SetParent(canvas);layer:ClearAllPoints();layer:SetAllPoints(canvas)
    layer:SetFrameStrata(type(map.GetFrameStrata)=="function" and map:GetFrameStrata() or "HIGH")
    layer:SetFrameLevel(math.max(canvas:GetFrameLevel(),map:GetFrameLevel())+200);layer:Show()
    local points=target.points
    if #points==0 then points={{target.x,target.y}} end
    for index=#self.markers,#points+1,-1 do
        map:RemovePin(self.markers[index]);self.markers[index]=nil
    end
    for index,point in ipairs(points) do
        local pin=self.markers[index]
        if not pin then
            pin=map:AcquirePin(TEMPLATE,self,point[1],point[2],self.kind)
            self.markers[index]=pin
        else pin:UpdateTarget(self,point[1],point[2],self.kind) end
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
function Map:Refresh()
    local ok,reason=pcall(self.Render,self)
    if ok then return true end
    -- Surface real rendering failures rather than treating an opened zone as
    -- proof that its marker rendered. Clean up only our dedicated pin pool.
    if self.map and type(self.map.RemoveAllPinsByTemplate)=="function" then
        pcall(self.map.RemoveAllPinsByTemplate,self.map,TEMPLATE)
        self.markers={}
    end
    self:Dismiss()
    local detail=Public(reason) and type(reason)=="string" and reason:sub(1,240) or "Unknown rendering error."
    self.lastError="Could not draw quest marker: "..detail
    addon.DungeonLoot.mapStatus=self.lastError
    return false,self.lastError
end
function Map:Open(target,kind)
    if not addon.DungeonLoot.active then return false,"Enable Dungeon Loot first." end
    if not OOC() then return false,"Leave combat to open quest locations." end
    if not target then return false,"No recorded location." end
    if not WorldMapFrame and C_AddOns and type(C_AddOns.LoadAddOn)=="function" then pcall(C_AddOns.LoadAddOn,"Blizzard_WorldMap") end
    local map=WorldMapFrame
    if not map or type(map.SetMapID)~="function" or type(map.GetCanvas)~="function" or type(map.AddDataProvider)~="function" or type(map.AcquirePin)~="function" or type(map.RemovePin)~="function" or not MapCanvasPinMixin or not MapCanvasDataProviderMixin or type(CreateFromMixins)~="function" or type(ShowUIPanel)~="function" then return false,"World map is unavailable on this client." end
    if C_XMLUtil and type(C_XMLUtil.GetTemplateInfo)=="function" and not C_XMLUtil.GetTemplateInfo(TEMPLATE) then
        return false,"Map pin template is missing. Restart WoW to load the updated addon files."
    end
    for key,value in pairs(MapCanvasPinMixin) do if Pin[key]==nil then Pin[key]=value end end
    local ok,reason=pcall(function()
        if not self.provider then
            self.map=map
            local provider=CreateFromMixins(MapCanvasDataProviderMixin)
            provider.RefreshAllData=function() self:Refresh() end
            provider.RemoveAllData=function() self:ReleasePins() end
            provider.OnCanvasSizeChanged=provider.RefreshAllData
            provider.OnCanvasScaleChanged=provider.RefreshAllData
            provider.OnHide=function()
                local restore=self.returnToConfig;self:Clear()
                if restore and OOC() and addon.DungeonLoot.active and addon.configWindow then addon.configWindow:Show() end
            end
            map:AddDataProvider(provider);self.provider=provider
        end
        self.lastError=nil
        self.target,self.kind=target,kind
        self.generation=(self.generation or 0)+1
        local generation=self.generation
        -- Let the map select its zone through the client entry point, after its
        -- OnShow initialization. Our overlay never consults quest ownership.
        if C_Map and type(C_Map.OpenWorldMap)=="function" then C_Map.OpenWorldMap(target.mapID)
        else ShowUIPanel(map) end
        map:SetMapID(target.mapID)
        if self.lastError or self.target~=target then error(self.lastError or "Map target cleared during open") end
        if not map:IsShown() or map:GetMapID()~=target.mapID then error("Map open rejected") end
        local rendered,message=self:Refresh()
        if not rendered then error(message) end
        -- Opening/resizing the map can settle its canvas after SetMapID returns.
        -- Bounded redraws, cancelled on close/dismiss/new selection; no polling.
        if C_Timer and type(C_Timer.After)=="function" then
            for _,delay in ipairs({0,.05,.2}) do
                C_Timer.After(delay,function()
                    if self.generation==generation and self.target==target then self:Refresh() end
                end)
            end
        end
        if addon.configWindow and addon.configWindow:IsShown() then
            self.returnToConfig=true;addon.configWindow:Hide()
        end
    end)
    if not ok then self:Clear();return false,self.lastError or "The client could not open this quest location." end
    return true
end
