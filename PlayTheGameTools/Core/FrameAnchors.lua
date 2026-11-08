local _,addon=...
local F,P,PM={},addon.Positioning,addon.PositionManager
addon.FrameAnchors=F
local function Combat() return InCombatLockdown() or UnitAffectingCombat("player") end
local function Plain(v) return not (issecretvalue and issecretvalue(v)) end
local function Name(v) return Plain(v) and type(v)=="string" and #v<=128 and v:match("^[%a_][%w_]*$") end
local function Geometry(frame)
    if not Plain(frame) or not frame then return end
    local ok,x,y,w,h=pcall(P.Geometry,P,frame)
    if ok then return x,y,w,h end
end
function F:ValidID(id) return Plain(id) and type(id)=="string" and id:sub(1,6)=="frame:" and Name(id:sub(7)) and true or false end

-- Bounded native parent/anchor graph inspection. Never inspect arbitrary fields
-- or guess persistent paths for anonymous/pool frames.
function F:SafeFrame(frame)
    if Combat() or not Geometry(frame) then return false end
    local visited,count={},0
    local function Visit(node,depth)
        if not node then return true end
        if not Plain(node) or depth>16 then return false end
        if visited[node] then return true end
        visited[node]=true;count=count+1
        if count>64 or PM.frames[node] or node==addon.configWindow or node==addon.editWindow or node==addon.previewPopout or node==self.picker then return false end
        if not Geometry(node) then return false end
        if node==UIParent then return true end
        local ok,parent=pcall(function() return node:GetParent() end)
        if not ok or not Visit(parent,depth+1) then return false end
        local success,n=pcall(function() return node:GetNumPoints() end)
        if not success or not Plain(n) or type(n)~="number" or n~=n or n<0 or n>32 or n~=math.floor(n) then return false end
        for i=1,n do
            local good,point,relative=pcall(node.GetPoint,node,i)
            if not good or not Plain(point) or not Visit(relative,depth+1) then return false end
        end
        return true
    end
    return Visit(frame,0)
end
function F:Resolve(id)
    if not self:ValidID(id) then return end
    local name=id:sub(7)
    local lower=name:lower()
    if lower:find("playthegametools",1,true) or lower:find("tooltip",1,true) or lower:find("nameplate",1,true)
        or lower:find("dropdown",1,true) or lower:find("worldframe",1,true) then return end
    local frame=_G[name]
    if frame==UIParent or P.rejected[frame] or not self:SafeFrame(frame) then return end
    local ok,shown=pcall(frame.IsVisible or frame.IsShown,frame)
    if not ok or not Plain(shown) or not shown then return end
    return frame,{id=id,label=name}
end
function F:Identify(frame)
    for _=1,12 do
        if not frame or not Geometry(frame) then return end
        local ok,name=pcall(function() return frame:GetName() end)
        if not ok then return end
        if Name(name) and _G[name]==frame then
            local id="frame:"..name
            if self:Resolve(id) then return id,frame end
        end
        local success,parent=pcall(function() return frame:GetParent() end)
        if not success or not Plain(parent) or parent==frame then return end
        frame=parent
    end
end
function F:PickCandidate()
    if Combat() or type(GetMouseFoci)~="function" then return end
    local ok,list=pcall(GetMouseFoci)
    if not ok or not Plain(list) or type(list)~="table" or (issecrettable and issecrettable(list)) or (canaccesstable and not canaccesstable(list)) then return end
    for i=1,math.min(16,#list) do
        local id,frame=self:Identify(list[i])
        if id then return id,frame end
    end
end
function F:Stop()
    if not self.picker then return end
    self.active,self.elementId,self.candidate,self.callback=false,nil,nil,nil
    self.picker:SetScript("OnUpdate",nil);self.picker:UnregisterAllEvents();self.picker:Hide();self.outline:Hide()
end
function F:Start(id,callback)
    if callback~=nil and type(callback)~="function" then return false,"invalid-callback" end
    if Combat() or not PM.elements[id] or not PM.elements[id].supportsAnchoring or not PM.elements[id].allowedTargets.selected or type(GetMouseFoci)~="function" then return false,"picker-unavailable" end
    self:Stop(); PM:FinishDrags()
    if not self.picker then
        local frame=CreateFrame("Frame","PlayTheGameToolsFramePicker",UIParent)
        self.picker=frame;frame:SetAllPoints(UIParent);frame:SetFrameStrata("TOOLTIP");frame:EnableMouse(false)
        frame:EnableKeyboard(true);frame:SetPropagateKeyboardInput(true)
        local text=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        text:SetPoint("TOP",UIParent,"TOP",0,-50);addon.Media:BindInterfaceFont(text,GameFontHighlight,16)
        text:SetTextColor(unpack(addon.Theme.primary));self.instructions=text
        local outline=CreateFrame("Frame",nil,frame);outline:EnableMouse(false);self.outline=outline
        for i,points in ipairs({{"TOPLEFT","TOPRIGHT"},{"BOTTOMLEFT","BOTTOMRIGHT"},{"TOPLEFT","BOTTOMLEFT"},{"TOPRIGHT","BOTTOMRIGHT"}}) do
            local edge=outline:CreateTexture(nil,"OVERLAY");edge:SetPoint(points[1]);edge:SetPoint(points[2]);edge:SetColorTexture(unpack(addon.Theme.primary))
            if i<=2 then edge:SetHeight(2) else edge:SetWidth(2) end
        end
        frame:SetScript("OnKeyDown",function(_,key)
            if Combat() then self:Stop();return end
            frame:SetPropagateKeyboardInput(key~="ESCAPE")
            if key=="ESCAPE" then self:Stop() end
        end)
        frame:SetScript("OnEvent",function(_,event,button)
            if event=="PLAYER_REGEN_DISABLED" or button=="RightButton" then self:Stop();return end
            if button=="LeftButton" then
                local target=self:PickCandidate()
                if not target then return end
                local ok=PM:ChangeTarget(self.elementId,target)
                local notify=self.callback;self:Stop()
                if notify then notify(ok,target) end
                if addon.RefreshConfig then addon:RefreshConfig() end
            end
        end)
    end
    self.active,self.elementId,self.callback=true,id,callback
    self.picker:SetPropagateKeyboardInput(true);self.picker:RegisterEvent("GLOBAL_MOUSE_DOWN");self.picker:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.instructions:SetText("Select an accessible named frame — click to confirm; Escape / right-click cancels")
    local elapsed=0
    self.picker:SetScript("OnUpdate",function(_,dt)
        if Combat() or not PM.elements[self.elementId] then self:Stop();return end
        elapsed=elapsed+dt;if elapsed<0.05 then return end;elapsed=0
        local candidate,frame=self:PickCandidate();self.candidate=candidate
        self.outline:Hide()
        if candidate then
            local x,y,w,h=Geometry(frame)
            if x then
                local cx,cy=UIParent:GetCenter()
                self.outline:ClearAllPoints();self.outline:SetPoint("CENTER",UIParent,"CENTER",x-cx,y-cy);self.outline:SetSize(w,h);self.outline:Show()
                self.instructions:SetText(candidate:sub(7).." — click to anchor; Escape cancels")
            end
        else self.instructions:SetText("No stable supported frame — choose a named frame; Escape cancels") end
    end)
    self.picker:Show();return true
end
