local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
-- One Edit Mode launcher opens every module's circular icon in a ring around it.
-- Owning modules supply art/behavior; this file owns placement and visibility.
-- Not a registered module: it has no page or switch and appears when an icon exists.
local Q={id="quickActions",title="Quick Actions",enabled=true,db={},actions={},count=0}
addon.QuickActions=Q
local ELEMENT="quickActionsLauncher"
local DEFAULT_X,DEFAULT_Y=-180,-140
local LAUNCHER_ICON="Interface\\Icons\\INV_Misc_Gear_01"
local LAUNCHER_COLOR={.85,.85,.85}
local MASK="Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local SIZE,DOTS,RING_GAP,ICON_GAP=40,48,34,6

local function Number(v)
    return not (issecretvalue and issecretvalue(v)) and type(v)=="number" and v==v and math.abs(v)<=100000
end
local function OutsideCombat()
    local ok,lock=pcall(InCombatLockdown)
    local valid,combat=pcall(UnitAffectingCombat,"player")
    return ok and valid and lock==false and combat==false
end

-- Native owned textures only: a masked icon inside a thin ring of dots.
function Q.SizeIcon(b,size)
    b:SetSize(size,size)
    local diameter=size*.9-2 -- inset from the ring's inner edge at every supported size
    if not b.mask then diameter=diameter/math.sqrt(2) end
    b.icon:SetSize(diameter,diameter)
    for i,dot in ipairs(b.ring) do
        local angle=i*2*math.pi/DOTS;dot:ClearAllPoints()
        dot:SetPoint("CENTER",b,"CENTER",size*.45*math.cos(angle),size*.45*math.sin(angle))
    end
end
local function CreateRoundButton(parent,spec)
    local b=CreateFrame("Button",nil,parent)
    b:SetFrameStrata("MEDIUM");b:EnableMouse(true);b:RegisterForClicks("LeftButtonUp")
    b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetPoint("CENTER")
    b.icon:SetTexture(spec.texture);b.icon:SetTexCoord(.07,.93,.07,.93)
    if b.icon.AddMaskTexture and b.CreateMaskTexture then
        b.mask=b:CreateMaskTexture();b.mask:SetAllPoints(b.icon)
        b.mask:SetTexture(MASK);b.icon:AddMaskTexture(b.mask)
    end
    b.ring={}
    for i=1,DOTS do
        local dot=b:CreateTexture(nil,"OVERLAY");dot:SetSize(1.5,1.5)
        dot:SetColorTexture(spec.color[1],spec.color[2],spec.color[3],1);b.ring[i]=dot
    end
    Q.SizeIcon(b,SIZE)
    b:SetScript("OnEnter",function()
        b.hovered=true
        if GameTooltip then
            GameTooltip:SetOwner(b,"ANCHOR_RIGHT");GameTooltip:SetText(spec.title)
            GameTooltip:AddLine(spec.hint,.8,.85,.9,true);GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function() b.hovered=nil;if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnHide",function() if b.hovered then b.hovered=nil;if GameTooltip then GameTooltip:Hide() end end end)
    return b
end

-- The first run of the merged button starts where the Class Training icon was.
-- Older per-icon positions are left in the profile untouched.
local function SeedPosition()
    local modules=addon.db and addon.db.modules
    local saved=type(modules)=="table" and type(modules.foreverClassTraining)=="table" and modules.foreverClassTraining.shortcutPosition
    if type(saved)=="table" and Number(saved.x) and Number(saved.y) then return saved.x,saved.y end
    return DEFAULT_X,DEFAULT_Y
end

function Q:RegisterLauncher()
    if self.element or not self.launcher or not OutsideCombat() then return end
    local b,pm=self.launcher,addon.PositionManager
    local x,y=SeedPosition()
    local ok,e=pm:RegisterElement(ELEMENT,b,{owner=self,anchoring=false,allowedTargets={"screen"},
        defaultPosition={target="screen",placement="center",x=x,y=y},
        canDrag=function() return self.count>0 end,
        onHighlight=function()
            -- The manager disables the mouse outside Edit Mode; this button must stay clickable.
            b:EnableMouse(self.count>0)
            if addon.editMode then self:CloseRing() end
        end})
    if not ok then self.launcherFailure=tostring(e);return end
    self.launcherFailure=nil
    self.element=e
    e.label="Quick Actions"
    e.defaults={target="screen",placement="center",x=DEFAULT_X,y=DEFAULT_Y}
    b:HookScript("OnDragStart",function() if e.dragging then b.wasDragged=true end end)
    b:HookScript("OnDragStop",function() if b.wasDragged then C_Timer.After(0,function() b.wasDragged=nil end) end end)
end

function Q:EnsureLauncher()
    if self.launcher then return true end
    if not OutsideCombat() then return false end
    local b=CreateRoundButton(UIParent,{texture=LAUNCHER_ICON,color=LAUNCHER_COLOR,title="Quick Actions",
        hint="Click to show your icons. Move this button in Edit Mode."})
    b:SetClampedToScreen(true)
    local x,y=SeedPosition();b:SetPoint("CENTER",UIParent,"CENTER",x,y)
    b.openGlow=b:CreateTexture(nil,"BACKGROUND");b.openGlow:SetTexture(MASK)
    b.openGlow:SetSize(SIZE+4,SIZE+4);b.openGlow:SetPoint("CENTER")
    b.openGlow:SetVertexColor(.25,.9,.4,.2);b.openGlow:Hide()
    -- Hiding this holder closes the ring; each icon's own shown flag means "available".
    local ring=CreateFrame("Frame",nil,b);ring:SetSize(1,1);ring:SetPoint("CENTER");ring:Hide()
    self.launcher,self.ring=b,ring
    b:SetScript("OnClick",function()
        if b.wasDragged then b.wasDragged=nil;return end
        if addon.editMode then
            if self.element then addon.PositionManager:SelectElement(ELEMENT) end
        else self:ToggleRing() end
    end)
    self.events=CreateFrame("Frame")
    self.events:RegisterEvent("PLAYER_REGEN_DISABLED");self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.events:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_DISABLED" then self:CloseRing() else self:Sync() end
    end)
    return true
end

function Q:AddAction(id,spec)
    if self.actions[id] then return self.actions[id].button end
    if not self:EnsureLauncher() then return nil end
    local b=CreateRoundButton(self.ring,spec)
    b:SetScript("OnClick",function() self:CloseRing();spec.onClick() end)
    b:Hide()
    self.actions[id]={id=id,order=spec.order,button=b,available=false}
    self:Sync()
    return b
end

function Q:SetAvailable(id,available)
    local action=self.actions[id]
    if not action or action.available==available then return end
    action.available=available
    self:Sync()
end

-- Lights the main button while an action's own window stays open.
function Q:SetActive(id,active)
    local action=self.actions[id]
    if not action then return end
    action.active=active==true
    if not self.launcher then return end
    local any=false
    for _,item in pairs(self.actions) do any=any or item.active==true end
    self.launcher.openGlow:SetShown(any)
end

function Q:Sync()
    if not self.launcher then return end
    local count=0
    for _,action in pairs(self.actions) do
        action.button:SetShown(action.available)
        if action.available then count=count+1 end
    end
    self.count=count
    self:RegisterLauncher()
    if count==0 then self:CloseRing() end
    self.launcher:SetShown(count>0)
    self:Layout()
    local e=self.element
    if e and e.editMode~=(count>0) then
        e.editMode=count>0
        addon.PositionManager:RefreshSelection()
    end
end

-- Even spacing clockwise from the top. The ring widens for larger icons or longer
-- lists, and the launcher's clamp extends so no icon can open off-screen.
function Q:Layout()
    if not self.launcher or not OutsideCombat() then return end
    local list,largest={},0
    for _,action in pairs(self.actions) do
        if action.available then list[#list+1]=action;largest=math.max(largest,action.button:GetWidth()) end
    end
    table.sort(list,function(a,b) return a.order<b.order end)
    local n=#list
    local radius=SIZE/2+largest/2+RING_GAP
    if n>1 then radius=math.max(radius,(largest+ICON_GAP)/(2*math.sin(math.pi/n))) end
    for i,action in ipairs(list) do
        local angle=math.pi/2-(i-1)*2*math.pi/n
        action.button:ClearAllPoints()
        action.button:SetPoint("CENTER",self.ring,"CENTER",radius*math.cos(angle),radius*math.sin(angle))
    end
    local reach=n>0 and math.ceil(radius+largest/2-SIZE/2) or 0
    if self.launcher.SetClampRectInsets then self.launcher:SetClampRectInsets(-reach,reach,reach,-reach) end
end

function Q:CloseRing()
    if self.ring then self.ring:Hide() end
end
function Q:ToggleRing()
    if not self.ring then return false end
    if self.ring:IsShown() then self.ring:Hide();return true end
    if self.count==0 or addon.editMode or not OutsideCombat() then return false end
    self:Layout();self.ring:Show()
    return true
end

function Q:Center()
    if self.launcher then return self.launcher:GetCenter() end
end
function Q:EditPosition()
    if not OutsideCombat() or not self.element or self.count==0 then return false end
    addon:SetEditMode(true)
    return addon.PositionManager:SelectElement(ELEMENT)
end
function Q:ResetPosition()
    if not OutsideCombat() or not self.element then return false end
    return addon.PositionManager:ResetPosition(ELEMENT)
end
