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
    -- owner: an addon-owned table with id/title/db/enabled that has no module page.
    if options.owner == nil and (not Plain(options.moduleId) or type(options.moduleId) ~= "string") then return false, "unknown-module" end
    local module = options.owner or addon.modules[options.moduleId]
    if not module or not module.db or not addon.db then return false, "unknown-module" end
    for _, key in ipairs({ "draggable", "editMode", "anchoring", "legacyPosition", "styleText" }) do
        if options[key] ~= nil and type(options[key]) ~= "boolean" then return false, "invalid-options" end
    end
    for _, key in ipairs({ "canDrag", "onPositionChanged", "onHighlight", "onStyleChanged" }) do
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
        onStyleChanged = options.onStyleChanged, styleText = options.styleText ~= false,
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
    if not element.legacy then
        self:InstallStyle(element)
        self:ApplyPosition(id)
    end
    return true, element
end
-- Shared registration for module displays that saved screen offsets in their
-- own settings before Edit Mode owned placement. The first registration seeds
-- the managed position from those keys; afterwards the keys only mirror plain
-- screen-centre offsets, so older profiles and exports keep working. Dragging
-- and offsets are then identical to every other Edit Mode element.
function PM:RegisterModuleDisplay(id, frame, module, options)
    local element = Lookup(self, id)
    if element and element.position ~= (addon.db.positions and addon.db.positions[id]) then
        self:UnregisterElement(id); element = nil
    end
    if element then return true, element end
    if Combat() then return false, "combat" end
    -- options.db: a nested settings table that holds the legacy keys.
    local db, xKey, yKey = options.db or module.db, options.xKey or "x", options.yKey or "y"
    if addon.db.positions ~= nil and type(addon.db.positions) ~= "table" then return false, "invalid-storage" end
    addon.db.positions = addon.db.positions or {}
    if addon.db.positions[id] == nil and Number(db[xKey]) and Number(db[yKey]) then
        addon.db.positions[id] = { target = "screen", placement = "center", x = db[xKey], y = db[yKey] }
    end
    -- Native rectangles exist only for shown frames; restore visibility after.
    local shown = frame:IsShown()
    frame:Show()
    local ok, value = self:RegisterElement(id, frame, { moduleId = module.id,
        defaultPosition = { target = "screen", placement = "center", x = options.defaultX or 0, y = options.defaultY or 0 },
        canDrag = options.canDrag, onHighlight = options.onHighlight,
        onStyleChanged = options.onStyleChanged, styleText = options.styleText,
        onPositionChanged = function(changed, position)
            if position.target == "screen" and position.placement == "center" and not position.point then
                db[xKey], db[yKey] = math.floor(position.x + 0.5), math.floor(position.y + 0.5)
            end
            if options.onPositionChanged then options.onPositionChanged(changed, position) end
        end })
    if not ok and value == "invalid-frame" and not options.retried then
        -- A frame shown this frame may not have a rectangle until the next
        -- layout pass. Keep it shown and retry once; never loop.
        self.layoutRetries = self.layoutRetries or {}
        self.layoutRetries[id] = { frame = frame, module = module, options = options, shown = shown }
        self.layoutDriver = self.layoutDriver or CreateFrame("Frame")
        self.layoutDriver:SetScript("OnUpdate", function(driver)
            driver:SetScript("OnUpdate", nil)
            local queue = self.layoutRetries; self.layoutRetries = {}
            for retryId, entry in pairs(queue) do
                local retryOptions = setmetatable({ retried = true }, { __index = entry.options })
                local registered, element = false, nil
                if not Combat() then registered, element = self:RegisterModuleDisplay(retryId, entry.frame, entry.module, retryOptions) end
                if not entry.shown then entry.frame:Hide() end
                if registered and entry.options.onRegistered then entry.options.onRegistered(element) end
            end
        end)
        return false, "layout-pending"
    end
    if not shown then frame:Hide() end
    if ok then value.label = options.label end
    return ok, value
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
    self:RemoveStyle(element)
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
-- The gap a placement applies with no user nudge; custom points define their own.
local function PlacementOffsets(position)
    if position.point then return 0,0 end
    local item,sign=P:Placement(position.placement),position.target=="screen" and -1 or 1
    return item.x*sign,item.y*sign
end
-- A preset replaces custom points (they would override it) and carries nudges across.
function PM:SetPlacement(id,placement)
    if not Known(P.placements,placement) then return false,"invalid-placement" end
    local position,reason=self:GetPosition(id)
    if not position then return false,reason end
    local oldX,oldY=PlacementOffsets(position)
    position.placement,position.point,position.relativePoint=placement,nil,nil
    local newX,newY=PlacementOffsets(position)
    position.x,position.y=position.x-oldX+newX,position.y-oldY+newY
    return self:SetPosition(id,position)
end
function PM:ResetOffsets(id)
    local position,reason=self:GetPosition(id)
    if not position then return false,reason end
    position.x,position.y=PlacementOffsets(position)
    return self:SetPosition(id,position)
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
        local x, y = self:SnapToGrid(element, P:ReadFrame(element.subject))
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

-- Layout starts with nothing selected: a selection is the open Style card.
function PM:ClearSelection()
    if self.selected == nil then return true end
    self.selected = nil
    self:RefreshSelection()
    return true
end

function PM:RefreshSelection()
    if not addon.editMode or not self:GetSelectedElement() then self.selected = nil end
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
    self:FlushStyles()
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

-- Layout Style card: Scale, Opacity, Text size and Background for every display.
-- Saved in the display's own position record as `style`, so it follows the
-- position through profiles, exports and imports. Values are whole percents;
-- a record without `style` (every display until it is styled) uses defaults.
PM.STYLE = {
    scale = { minimum = 50, maximum = 200, default = 100 },
    opacity = { minimum = 10, maximum = 100, default = 100 },
    text = { minimum = 50, maximum = 200, default = 100 },
}
local STYLE_KEYS = { "scale", "opacity", "text" }

local function StyleNumber(key, value)
    local range = PM.STYLE[key]
    return Number(value) and value == math.floor(value) and value >= range.minimum and value <= range.maximum
end

-- Strict check for a saved or imported `style` record.
function PM:ValidateStyle(style)
    if not Plain(style) or type(style) ~= "table" then return false, "invalid-style" end
    for _, key in ipairs(STYLE_KEYS) do
        if style[key] ~= nil and not StyleNumber(key, style[key]) then return false, "invalid-" .. key end
    end
    if not Plain(style.background) or (style.background ~= nil and type(style.background) ~= "boolean") then
        return false, "invalid-background"
    end
    return true
end

local function SavedRecord(self, id)
    local element = Lookup(self, id)
    if element then return element.position end
    if not Plain(id) or type(id) ~= "string" then return nil end
    local positions = addon.db and addon.db.positions
    return Plain(positions) and type(positions) == "table" and positions[id] or nil
end

-- Always a complete, valid copy. A malformed saved field reads as its default
-- and stays in place, untouched, until the card writes a valid value.
function PM:GetStyle(id)
    local record = SavedRecord(self, id)
    local saved = Plain(record) and type(record) == "table" and Plain(record.style) and type(record.style) == "table" and record.style or {}
    local style = {}
    for _, key in ipairs(STYLE_KEYS) do
        style[key] = StyleNumber(key, saved[key]) and saved[key] or self.STYLE[key].default
    end
    style.background = not (Plain(saved.background) and saved.background == false)
    return style
end

function PM:IsDefaultStyle(style)
    for _, key in ipairs(STYLE_KEYS) do if style[key] ~= self.STYLE[key].default then return false end end
    return style.background ~= false
end

-- Scale and Opacity apply to the display frame itself. A display that sets its
-- own scale or alpha keeps doing so: its value is multiplied by the style here,
-- and GetScale/GetAlpha keep returning the display's own value.
function PM:InstallStyle(element)
    if element.styleInstalled then return end
    local frame = element.frame
    local setScale, setAlpha, getScale, getAlpha = frame.SetScale, frame.SetAlpha, frame.GetScale, frame.GetAlpha
    if type(setScale) ~= "function" or type(setAlpha) ~= "function" or type(getScale) ~= "function" or type(getAlpha) ~= "function" then return end
    element.styleMethods = { SetScale = setScale, SetAlpha = setAlpha, GetScale = getScale, GetAlpha = getAlpha }
    element.baseScale, element.baseAlpha = getScale(frame), getAlpha(frame)
    element.styleScale, element.styleAlpha = 1, 1
    frame.SetScale = function(owner, value)
        element.baseScale = value
        return setScale(owner, value * element.styleScale)
    end
    frame.SetAlpha = function(owner, value)
        element.baseAlpha = value
        return setAlpha(owner, value * element.styleAlpha)
    end
    frame.GetScale = function() return element.baseScale end
    frame.GetAlpha = function() return element.baseAlpha end
    element.styleInstalled = true
    self:ApplyStyle(element.id)
end

-- Unregistering returns the frame to its own methods, scale and alpha.
function PM:RemoveStyle(element)
    if not element.styleInstalled then return end
    local frame, methods = element.frame, element.styleMethods
    for name in pairs(methods) do frame[name] = nil end
    for name, method in pairs(methods) do
        if frame[name] ~= method then frame[name] = method end
    end
    methods.SetScale(frame, element.baseScale); methods.SetAlpha(frame, element.baseAlpha)
    element.styleInstalled, element.styleMethods = nil, nil
    if self.stylePending then self.stylePending[element.id] = nil end
end

-- Never rescales or moves a display in combat; the change waits for combat to end.
function PM:ApplyStyle(id, notify)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if not element.styleInstalled then return false, "unstyled" end
    if Combat() then
        self.stylePending = self.stylePending or {}
        self.stylePending[id] = self.stylePending[id] or notify or false
        self.pending, P.pending = true, true
        return false, "combat"
    end
    local style = self:GetStyle(id)
    local scale, alpha = style.scale / 100, style.opacity / 100
    if scale ~= element.styleScale or alpha ~= element.styleAlpha then
        element.styleScale, element.styleAlpha = scale, alpha
        element.styleMethods.SetScale(element.frame, element.baseScale * scale)
        element.styleMethods.SetAlpha(element.frame, element.baseAlpha * alpha)
        if not element.dragging then self:ApplyPosition(id, true) end
    end
    if notify and element.onStyleChanged then
        local ok, message = pcall(element.onStyleChanged, element, style)
        if not ok then print("Play The Game Tools: display style callback failed: " .. tostring(message)) end
    end
    return true
end

function PM:FlushStyles()
    local pending = self.stylePending
    if not pending or Combat() then return end
    self.stylePending = nil
    for id, notify in pairs(pending) do self:ApplyStyle(id, notify) end
end

-- One Style card value. Layout only, outside combat; values are validated.
function PM:SetStyle(id, key, value)
    local element = Lookup(self, id)
    if not element or not element.styleInstalled then return false, "unknown-element" end
    if Combat() then return false, "combat" end
    if not addon.editMode then return false, "layout-only" end
    if not Plain(key) or (key ~= "background" and not self.STYLE[key]) then return false, "invalid-key" end
    if key == "background" then
        if not Plain(value) or type(value) ~= "boolean" then return false, "invalid-background" end
    else
        if not Number(value) then return false, "invalid-" .. key end
        local range = self.STYLE[key]
        value = math.max(range.minimum, math.min(range.maximum, math.floor(value + 0.5)))
    end
    if key == "text" and not element.styleText then return false, "no-text" end
    local current = self:GetStyle(id)
    if current[key] == value then return true, "unchanged" end
    current[key] = value
    -- A default style leaves the saved record exactly as it was before styling.
    if self:IsDefaultStyle(current) then element.position.style = nil
    else element.position.style = current end
    self:ApplyStyle(id, true)
    self:NotifyPosition()
    return true
end

-- Reset on the Style card: this display's style and its default position.
function PM:ResetLayout(id)
    local element = Lookup(self, id)
    if not element then return false, "unknown-element" end
    if Combat() then return false, "combat" end
    if element.position.style ~= nil then
        element.position.style = nil
        self:ApplyStyle(id, true)
    end
    -- A display with its own Style card rows resets those too.
    if element.onLayoutReset then
        local done, message = pcall(element.onLayoutReset, element)
        if not done then print("Play The Game Tools: display reset callback failed: " .. tostring(message)) end
    end
    local ok, reason = self:ResetPosition(id)
    self:NotifyPosition()
    return ok, reason
end

-- Text size and Background, read through a display's own settings table:
--   keys.text        font sizes, scaled by Text size;
--   keys.background  background/border opacities, read as 0 while Background is off;
--   keys.scale / keys.opacity  percent settings of a window that belongs to the
--                    display but is not its registered frame (a flyout menu),
--                    multiplied by Scale / Opacity.
-- While Background is off the view also reads layoutBackground = false, for
-- display code that draws a border without an opacity setting.
-- Writes through the view still reach the settings table.
function PM:StyleView(id, settings, keys)
    local style = self:GetStyle(id)
    if self:IsDefaultStyle(style) then return settings end
    local view = {}
    for _, key in ipairs(keys.text or {}) do
        local size = settings[key]
        if Number(size) then view[key] = self:StyleFontSize(id, size, style) end
    end
    if not style.background then
        view.layoutBackground = false
        for _, key in ipairs(keys.background or {}) do
            if Number(settings[key]) then view[key] = 0 end
        end
    end
    for _, pair in ipairs({ { keys.scale, style.scale }, { keys.opacity, style.opacity } }) do
        for _, key in ipairs(pair[1] or {}) do
            if Number(settings[key]) then view[key] = settings[key] * pair[2] / 100 end
        end
    end
    return setmetatable(view, { __index = settings, __newindex = settings })
end

function PM:StyleFontSize(id, size, style)
    if not Number(size) then return size end
    style = style or self:GetStyle(id)
    if style.text == 100 then return size end
    return math.max(1, math.floor(size * style.text / 100 + 0.5))
end

function PM:StyleBackground(id)
    return self:GetStyle(id).background
end

-- Grid: session-only and off by default. While it is on, a display dropped on
-- the screen snaps its centre to the nearest grid line. Displays anchored to
-- another frame, or placed by an edge, keep the exact spot they were dropped on.
PM.GRID = 32
function PM:SnapToGrid(element, x, y)
    if not addon.EditMode.grid or not Number(x) or not Number(y) then return x, y end
    local position = element.position
    if position.target ~= "screen" or position.placement ~= "center" or position.point or element.subject.originPoint then return x, y end
    local size = self.GRID
    return math.floor(x / size + 0.5) * size, math.floor(y / size + 0.5) * size
end
