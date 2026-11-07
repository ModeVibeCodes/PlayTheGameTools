local _, addon = ...
local PM = { elements = {}, order = {}, frames = setmetatable({}, { __mode = "k" }) }
addon.PositionManager = PM
addon.EditMode.elements, addon.EditMode.order = PM.elements, PM.order
local P = addon.Positioning
local function Combat() return InCombatLockdown() or UnitAffectingCombat("player") end
local function Plain(value) return not (issecretvalue and issecretvalue(value)) end
local function Number(value)
    return Plain(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function Copy(position)
    return { target = position.target or "screen", placement = position.placement or "center",
        x = position.x, y = position.y, fallbackX = position.fallbackX, fallbackY = position.fallbackY,
        point = position.point, relativePoint = position.relativePoint }
end
local function Known(items, id)
    if not Plain(id) or type(id) ~= "string" then return false end
    for _, item in ipairs(items) do if item.id == id then return true end end
    return false
end
local function Lookup(self, id)
    if not Plain(id) or type(id) ~= "string" then return nil end
    return self.elements[id]
end
local function Target(id) return Known(P.targets,id) or (addon.FrameAnchors and addon.FrameAnchors:ValidID(id)) end
local function Allowed(element,id)
    return element.allowedTargets[id] or (element.allowedTargets.selected and addon.FrameAnchors and addon.FrameAnchors:ValidID(id))
end

function PM:ValidatePosition(position, saved)
    if not Plain(position) or type(position) ~= "table" then return false, "invalid-position" end
    if not Number(position.x) or not Number(position.y) then return false, "invalid-offsets" end
    if not Target(position.target or "screen") and not (saved and Plain(position.target) and type(position.target)=="string" and position.target~="") then return false, "invalid-target" end
    if not Known(P.placements, position.placement or "center") and not (saved and Plain(position.placement) and type(position.placement)=="string" and position.placement~="") then return false, "invalid-placement" end
    if position.point~=nil or position.relativePoint~=nil then
        if not Plain(position.point) or not Plain(position.relativePoint) or not P.vectors[position.point] or not P.vectors[position.relativePoint] then return false,"invalid-points" end
    end
    for _, key in ipairs({ "fallbackX", "fallbackY" }) do
        local value = position[key]
        if not Plain(value) or (value ~= nil and not Number(value)) then return false, "invalid-fallback" end
    end
    return true
end

function PM:RegisterElement(id, frame, options)
    if not Plain(id) or type(id) ~= "string" or id == "" then return false, "invalid-id" end
    if self.elements[id] then return false, "duplicate-id" end
    options = options or {}
    if not Plain(options) or type(options) ~= "table" then return false, "invalid-options" end
    if not Plain(options.originPoint) or (options.originPoint~=nil and options.originPoint~="TOP" and options.originPoint~="BOTTOM") then return false,"invalid-origin" end
    if not Plain(frame) or not frame or not frame.GetScript or not frame.SetScript or not P:Geometry(frame) then return false, "invalid-frame" end
    if self.frames[frame] then return false, "duplicate-frame" end
    for _, target in ipairs(P.targets) do
        local external = _G[target.name]
        if Plain(external) and frame == external then return false, "external-frame" end
    end
    if frame.IsProtected then
        local protected = frame:IsProtected()
        if not Plain(protected) or protected then return false, "protected-frame" end
    end
    if not Plain(options.moduleId) or type(options.moduleId) ~= "string" then return false, "unknown-module" end
    local module = addon.modules[options.moduleId]
    if not module or not module.db or not addon.db then return false, "unknown-module" end
    for _, key in ipairs({ "draggable", "editMode", "anchoring", "legacyPosition" }) do
        if options[key] ~= nil and type(options[key]) ~= "boolean" then return false, "invalid-options" end
    end
    for _, key in ipairs({ "canDrag", "onPositionChanged", "onHighlight" }) do
        if options[key] ~= nil and type(options[key]) ~= "function" then return false, "invalid-options" end
    end
    local defaults = options.defaultPosition or { target = "screen", placement = "center", x = 0, y = 0 }
    local valid, reason = self:ValidatePosition(defaults)
    if not valid then return false, reason end
    local allowed = { selected = options.allowedTargets == nil }
    if options.allowedTargets ~= nil and type(options.allowedTargets) ~= "table" then return false, "invalid-targets" end
    for _, target in ipairs(options.allowedTargets or { "screen", "player", "target", "focus", "minimap", "party" }) do
        if not Known(P.targets, target) then return false, "invalid-targets" end
        allowed[target] = true
    end
    if not allowed.screen or not (allowed[defaults.target or "screen"] or (allowed.selected and addon.FrameAnchors and addon.FrameAnchors:ValidID(defaults.target))) then return false, "invalid-targets" end
    local draggable = options.draggable ~= false and not options.legacy
    if draggable and (frame:GetScript("OnDragStart") or frame:GetScript("OnDragStop")) then return false, "drag-handlers-owned" end
    local position
    if options.legacyPosition then
        position = module.db.position
    else
        if addon.db.positions ~= nil and type(addon.db.positions) ~= "table" then return false, "invalid-storage" end
        position = addon.db.positions and addon.db.positions[id]
    end
    if position == nil then position = Copy(defaults) end
    valid, reason = self:ValidatePosition(position, true)
    if not valid then return false, reason end -- Never replace malformed saved data.
    position.target, position.placement = position.target or "screen", position.placement or "center"
    if options.legacyPosition then module.db.position = position
    else addon.db.positions = addon.db.positions or {}; addon.db.positions[id] = position end
    local element = { id = id, module = module, frame = frame, position = position, defaults = Copy(defaults),
        allowedTargets = allowed, draggable = draggable, editMode = options.editMode ~= false,
        supportsAnchoring = options.anchoring ~= false, legacy = options.legacy,
        canDrag = options.canDrag, onPositionChanged = options.onPositionChanged, onHighlight = options.onHighlight,
        scripts = {}, handlers = {} }
    element.subject = { frame = frame, db = { position = position } }
    element.subject.originPoint=options.originPoint
    element.subject.allowedTargets = allowed
    self.elements[id], self.frames[frame] = element, id
    self.order[#self.order + 1] = id
    if draggable then
        frame:SetMovable(true); frame:SetClampedToScreen(true); frame:RegisterForDrag("LeftButton")
        local function Bind(name, handler)
            local prior = frame:GetScript(name)
            element.scripts[name] = prior
            local wrapped = function(...)
                if prior then prior(...) end
                if self.elements[id] == element then handler(...) end
            end
            element.handlers[name] = wrapped
            frame:SetScript(name, wrapped)
        end
        Bind("OnDragStart", function() self:StartDragging(id) end)
        Bind("OnDragStop", function() self:StopDragging(id) end)
        Bind("OnMouseDown", function() if self:CanDrag(element) then self:SelectElement(id) end end)
        Bind("OnHide", function() self:StopDragging(id) end)
        element.dragUpdate = function() self:NotifyPosition(id, false) end
    end
    if not element.legacy then self:ApplyPosition(id) end
    return true, element
end
function PM:SetOriginPoint(id,point)
    local element=Lookup(self,id)
    if not element then return false,"unknown-element" end
    if Combat() then return false,"combat" end
    if not Plain(point) or (point~="TOP" and point~="BOTTOM") then return false,"invalid-origin" end
    element.subject.originPoint=point
    return true
end

function PM:UnregisterElement(id)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if Combat() then return false, "combat" end
    self:StopDragging(id)
    if self.ReleaseEditDecoration then self:ReleaseEditDecoration(element) end
    if element.sizeObserver then
        element.sizeObserver:SetScript("OnSizeChanged", nil)
        element.sizeObserver:ClearAllPoints(); element.sizeObserver:Hide()
    end
    for name, handler in pairs(element.handlers) do
        if element.frame:GetScript(name) == handler then element.frame:SetScript(name, element.scripts[name]) end
    end
    if element.onHighlight then element.onHighlight(element, false, false) end
    self.frames[element.frame], self.elements[id] = nil, nil
    for index, key in ipairs(self.order) do if key == id then table.remove(self.order, index); break end end
    if self.selected == id then self.selected = nil end
    -- The caller retains ownership of its frame and saved record; all runtime closures are released.
    self:RefreshSelection()
    for key in pairs(element) do element[key] = nil end
    return true
end

function PM:GetPosition(id)
    local element = Lookup(self, id)
    if not element then return nil, "unknown-element" end
    local valid, reason = self:ValidatePosition(element.position, true)
    if not valid then return nil, reason end
    return Copy(element.position)
end

-- Opt-in runtime target for provider-owned/anonymous frames. Saved positions
-- remain untouched; only addon-owned elements are moved by ApplyPosition.
function PM:SetRuntimeAnchor(id,frame,point,relativePoint,x,y)
    local element=Lookup(self,id)
    if not element or element.legacy then return false,"unknown-element" end
    if Combat() then return false,"combat" end
    if not Plain(frame) then return false,"unsafe-frame" end
    if frame==nil then
        element.subject.runtimeAnchor=nil
        return self:ApplyPosition(id)
    end
    if not Plain(frame) or P.rejected[frame] or not addon.FrameAnchors:SafeFrame(frame) then return false,"unsafe-frame" end
    if not Plain(point) or not Plain(relativePoint) or not P.vectors[point] or not P.vectors[relativePoint]
        or not Number(x) or not Number(y) then return false,"invalid-anchor" end
    local previous=element.subject.runtimeAnchor
    element.subject.runtimeAnchor={frame=frame,target="screen",point=point,relativePoint=relativePoint,placement="center",x=x,y=y}
    local ok,reason=self:ApplyPosition(id)
    if not ok then element.subject.runtimeAnchor=previous;self:ApplyPosition(id) end
    return ok,reason
end

function PM:GetOffsets(id)
    local element = Lookup(self, id)
    if not element then return nil, nil, "unknown-element" end
    if element.legacy then return element.module:GetEditPosition() end
    if element.dragging then return P:ReadFrame(element.subject) end
    return element.position.x, element.position.y
end

function PM:ApplyPosition(id, force)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if Combat() then self.pending = true; P.pending = true; return false, "combat" end
    if element.legacy then return true, "legacy" end
    local valid, reason = self:ValidatePosition(element.position, true)
    if not valid then return false, reason end
    local ok, status = P:ApplyFrame(element.subject, force)
    self:RefreshAnchorSize(id)
    return ok, status
end

-- Width in UIParent units. Screen/missing/restricted targets have no matched width.
function PM:GetAnchorWidth(id)
    local element = Lookup(self, id)
    if not element then return nil, "unknown-element" end
    if Combat() then return nil, "combat" end
    if element.position.target == "screen" then return nil, "screen" end
    local target = P:Resolve(element.position.target)
    if element.sizeCallback and element.sizeObserver and element.sizeTarget ~= target then return nil, "observer-unavailable" end
    local _, _, width = P:Geometry(target)
    return width
end

-- A hidden, addon-owned two-point frame receives native size changes. Never hook
-- or resize the target. No polling; inaccessible geometry defers/falls back.
function PM:SetAnchorSizeListener(id, callback)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if Combat() then return false, "combat" end
    if callback ~= nil and type(callback) ~= "function" then return false, "invalid-callback" end
    element.sizeCallback = callback
    self:RefreshAnchorSize(id)
    return true
end

function PM:RefreshAnchorSize(id)
    local element = Lookup(self, id)
    if not element then return end
    if Combat() then self.pending = true; return end
    local target = element.sizeCallback and element.position.target ~= "screen" and P:Resolve(element.position.target) or nil
    if not element.sizeObserver and target then
        local observer = CreateFrame("Frame", nil, UIParent)
        observer:EnableMouse(false); observer:Hide()
        element.sizeObserver = observer
        observer:SetScript("OnSizeChanged", function() self:RefreshAnchorSize(id) end)
    end
    if element.sizeObserver and element.sizeTarget ~= target then
        element.sizeTarget = target
        local observer = element.sizeObserver
        observer:ClearAllPoints()
        if target then
            local ok = pcall(function()
                observer:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)
                observer:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0)
            end)
            if not ok then observer:ClearAllPoints(); element.sizeTarget = nil end
        end
    end
    local width = target and self:GetAnchorWidth(id) or nil
    if element.lastAnchorWidth ~= width then
        element.lastAnchorWidth = width
        if element.sizeCallback then
            local ok, message = pcall(element.sizeCallback, element, width)
            if not ok then print("Play The Game Tools: anchor size callback failed: " .. tostring(message)) end
        end
    end
end

function PM:SetPosition(id, position, allowUnavailable)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if element.notifying then return false, "notification-in-progress" end
    if Combat() then return false, "combat" end
    local valid, reason = self:ValidatePosition(position, true)
    if not valid then return false, reason end
    if not Target(position.target or "screen") and position.target~=element.position.target then return false,"invalid-target" end
    if not Known(P.placements,position.placement or "center") and position.placement~=element.position.placement then return false,"invalid-placement" end
    local nextPosition = Copy(position)
    local retainedUnknown=nextPosition.target==element.position.target and not Target(nextPosition.target)
    if (not Allowed(element,nextPosition.target) and not retainedUnknown) or (not element.supportsAnchoring and nextPosition.target ~= "screen") then return false, "target-not-allowed" end
    if addon.FrameAnchors and addon.FrameAnchors:ValidID(nextPosition.target) and nextPosition.target~=element.position.target then
        local frame=_G[nextPosition.target:sub(7)]
        if Plain(frame) and frame and not addon.FrameAnchors:SafeFrame(frame) then return false,"unsafe-frame" end
    end
    if not P:Resolve(nextPosition.target) and not allowUnavailable then return false, "target-unavailable" end
    self:StopDragging(id)
    local previous = Copy(element.position)
    if previous.x == nextPosition.x and previous.y == nextPosition.y and previous.target == nextPosition.target
        and previous.placement == nextPosition.placement and previous.point==nextPosition.point and previous.relativePoint==nextPosition.relativePoint then return true, "unchanged" end
    if element.legacy then
        if element.module:SetEditPosition(nextPosition.x, nextPosition.y) == false then return false, "rejected" end
    else
        for _, key in ipairs({ "x", "y", "target", "placement", "point", "relativePoint" }) do element.position[key] = nextPosition[key] end
        local applied, status = self:ApplyPosition(id)
        if not applied then
            for _, key in ipairs({ "x", "y", "target", "placement", "point", "relativePoint" }) do element.position[key] = previous[key] end
            self:ApplyPosition(id)
            self:NotifyPosition(id, false)
            return false, status or "anchor-rejected"
        end
    end
    self:NotifyPosition(id, true)
    return true
end

function PM:SetOffsets(id, x, y)
    local position, reason = self:GetPosition(id)
    if not position then return false, reason end
    position.x, position.y = x, y
    return self:SetPosition(id, position)
end

function PM:SetCoordinate(id, axis, value)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if not Plain(axis) or (axis ~= "x" and axis ~= "y") or not Number(value) then return false, "invalid-coordinate" end
    if Combat() then return false, "combat" end
    if not P:Resolve(element.position.target) then return false, "target-unavailable" end
    self:StopDragging(id)
    local x, y = self:GetOffsets(id)
    local lowX, highX, lowY, highY = self:GetCoordinateBounds(id)
    if axis == "x" then x = math.max(lowX, math.min(highX, value))
    else y = math.max(lowY, math.min(highY, value)) end
    return self:SetOffsets(id, x, y)
end

function PM:SetAnchor(id, target, placement, allowUnavailable)
    if not Lookup(self, id) then return false, "unknown-element" end
    if not Target(target) then return false, "invalid-target" end
    if not Known(P.placements, placement) then return false, "invalid-placement" end
    local position, reason = self:GetPosition(id)
    if not position then return false, reason end
    local item, sign = P:Placement(placement), target == "screen" and -1 or 1
    position.target, position.placement = target, placement
    position.point, position.relativePoint = nil,nil -- retain legacy outside-edge semantics
    position.x, position.y = item.x * sign, item.y * sign
    return self:SetPosition(id, position, allowUnavailable)
end

-- New UI operations preserve offsets. Legacy SetAnchor remains compatible.
function PM:ChangeTarget(id,target)
    local position,reason=self:GetPosition(id)
    if not position then return false,reason end
    position.target=target
    return self:SetPosition(id,position,true)
end
function PM:SetAttachment(id,point,relativePoint)
    local position,reason=self:GetPosition(id)
    if not position then return false,reason end
    position.point,position.relativePoint=point,relativePoint
    return self:SetPosition(id,position,true)
end
function PM:SetAlignment(id,point,outside)
    local opposite={TOP="BOTTOM",BOTTOM="TOP",LEFT="RIGHT",RIGHT="LEFT",TOPLEFT="BOTTOMRIGHT",TOPRIGHT="BOTTOMLEFT",BOTTOMLEFT="TOPRIGHT",BOTTOMRIGHT="TOPLEFT",CENTER="CENTER"}
    if not Plain(point) or not opposite[point] then return false,"invalid-points" end
    return self:SetAttachment(id,outside and opposite[point] or point,point)
end
function PM:DetachAnchor(id)
    local element=Lookup(self,id)
    if not element then return false,"unknown-element" end
    if Combat() then return false,"combat" end
    local x,y,_,height=P:Geometry(element.frame)
    local px,py=P:Geometry(UIParent)
    if not x or not px then return false,"unavailable-geometry" end
    local position=self:GetPosition(id)
    position.target,position.placement="screen","center"
    position.point,position.relativePoint=nil,nil
    position.x,position.y=x-px,y-py
    if element.subject.originPoint then position.y=position.y+(element.subject.originPoint=="TOP" and height/2 or -height/2) end
    return self:SetPosition(id,position)
end

function PM:ResetPosition(id)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    return self:SetPosition(id, element.defaults)
end

function PM:CanDrag(element)
    if Combat() or not addon.editMode or not element.editMode or not element.module.enabled or not element.draggable then return false end
    if not element.canDrag then return true end
    local ok, allowed = pcall(element.canDrag, element)
    return ok and Plain(allowed) and allowed == true
end

function PM:StartDragging(id)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if not self:CanDrag(element) then return false, "drag-not-allowed" end
    if element.dragging then return true, "unchanged" end
    if element.frame:GetScript("OnUpdate") then return false, "update-in-use" end
    if not P:Resolve(element.position.target) then return false, "target-unavailable" end
    self:FinishDrags()
    self:SelectElement(id)
    element.subject.appliedAnchor = nil
    element.dragging, element.module.dragging = true, true
    element.frame:StartMoving()
    element.frame:SetScript("OnUpdate", element.dragUpdate)
    return true
end

function PM:StopDragging(id)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if element.legacy then element.module:StopDragging(); return true end
    if not element.dragging then return true, "unchanged" end
    element.frame:StopMovingOrSizing()
    if element.frame:GetScript("OnUpdate") == element.dragUpdate then element.frame:SetScript("OnUpdate", nil) end
    element.dragging, element.module.dragging = false, false
    local changed
    if not Combat() then
        local x, y = P:ReadFrame(element.subject)
        changed = x ~= element.position.x or y ~= element.position.y
        element.position.x, element.position.y = x, y
        self:ApplyPosition(id, true)
    else self.pending = true; P.pending = true end
    self:NotifyPosition(id, changed)
    return true
end

function PM:FinishDrags()
    for _, id in ipairs(self.order) do self:StopDragging(id) end
end

function PM:GetSelectedElement()
    local element = self.elements[self.selected]
    return element and element.editMode and element.module.enabled and element or nil
end

function PM:SelectElement(id)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if Combat() or not addon.editMode or not element.editMode or not element.module.enabled then return false, "selection-not-allowed" end
    self.selected = id
    self:RefreshSelection()
    return true
end

function PM:RefreshSelection()
    if addon.editMode and not self:GetSelectedElement() then
        self.selected = nil
        for _, id in ipairs(self.order) do
            local element = self.elements[id]
            if element.editMode and element.module.enabled then self.selected = id; break end
        end
    elseif not addon.editMode then self.selected = nil end
    addon.EditMode.selected = self.selected -- compatibility view, not another selector
    for id, element in pairs(self.elements) do
        if not addon.editMode or not element.module.enabled then self:StopDragging(id) end
        if element.draggable then element.frame:EnableMouse(self:CanDrag(element) == true) end
        local selected = id == self.selected
        local show = addon.editMode and element.editMode and element.module.enabled and addon.EditMode.highlights
        if self.UpdateEditDecoration then self:UpdateEditDecoration(element, selected, show) end
        if element.onHighlight then element.onHighlight(element, selected, show)
        elseif (element.legacy or element.frame == element.module.frame) and element.module.SetEditHighlight then
            element.module:SetEditHighlight(selected, show)
        end
    end
    self:NotifyPosition()
end

function PM:NotifyPosition(id, changed)
    local element = Lookup(self, id)
    if changed and element and element.onPositionChanged and not element.notifying then
        element.notifying = true
        local ok, message = pcall(element.onPositionChanged, element, Copy(element.position))
        element.notifying = false
        if not ok then print("Play The Game Tools: position callback failed: " .. tostring(message)) end
    end
    P:UpdateHighlight()
    if addon.RefreshEditWindow then addon:RefreshEditWindow() end
end

function PM:GetCoordinateBounds(id)
    local element = Lookup(self, id)
    if not element then return nil, nil, nil, nil, "unknown-element" end
    return P:LimitsFrame(element.subject)
end

function PM:GetScreenBounds(id)
    local element = Lookup(self, id)
    if not element then return nil, nil, "unknown-element" end
    local _, _, width, height = P:Geometry(element.frame)
    if not width then return 0, 0 end
    return math.floor(math.max(0, (UIParent:GetWidth() - width) / 2)),
        math.floor(math.max(0, (UIParent:GetHeight() - height) / 2))
end

function PM:GetAllowedTargets(id)
    local element = Lookup(self, id)
    if not element then return {} end
    local targets = {}
    for _, target in ipairs(P:AvailableTargets()) do
        if element.allowedTargets[target.id] and (element.supportsAnchoring or target.id == "screen") then targets[#targets + 1] = target end
    end
    if element.allowedTargets.selected and addon.FrameAnchors and addon.FrameAnchors:ValidID(element.position.target) then
        targets[#targets+1]={id=element.position.target,label=element.position.target:sub(7)}
    end
    return targets
end

function PM:Refresh(discover)
    if Combat() then self.pending = true; P.pending = true; return end
    self.pending, P.pending = false, false
    local changed = not discover
    for _, element in pairs(self.elements) do
        if not element.legacy and not element.dragging then
            local target = P:Resolve(element.position.target)
            if not discover or target ~= element.subject.positionTargetFrame then self:ApplyPosition(element.id); changed = true end
            self:RefreshAnchorSize(element.id)
        end
    end
    if changed then self:NotifyPosition() end
end
