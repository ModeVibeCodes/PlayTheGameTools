local _, addon = ...
local E = { highlights = true }
addon.EditMode = E

function E:RegisterElement(module, frame)
    -- Compatibility for consumers of the earlier module-owned position contract.
    return addon.PositionManager:RegisterElement(module.id, frame, { moduleId = module.id,
        legacyPosition = true, legacy = true, anchoring = false,
        defaultPosition = module.db.position or { x = 0, y = 0 } })
end

function E:Selected()
    return addon.PositionManager:GetSelectedElement()
end

function E:Select(id)
    return addon.PositionManager:SelectElement(id)
end

function E:RefreshElements()
    addon.PositionManager:RefreshSelection()
end

function E:NotifyPosition()
    addon.PositionManager:NotifyPosition()
end

function E:SetHighlights(show)
    self.highlights = show
    self:RefreshElements()
end

function E:Bounds(element)
    return addon.PositionManager:GetScreenBounds(element.id)
end

function E:SetCoordinate(axis, value)
    local element = self:Selected()
    if not addon.editMode or not element then return false end
    if InCombatLockdown() or UnitAffectingCombat("player") then
        print("Play The Game Tools: position elements outside combat.")
        return false
    end
    return addon.PositionManager:SetCoordinate(element.id, axis, value)
end

function E:CoordinateBounds(element)
    return addon.PositionManager:GetCoordinateBounds(element.id)
end

function E:SetAnchor(target, placement)
    local element = self:Selected()
    if not addon.editMode or not element or not element.supportsAnchoring then return false end
    return addon.PositionManager:SetAnchor(element.id, target, placement)
end

function E:FinishDrags()
    addon.PositionManager:FinishDrags()
end

function E:ViewportChanged()
    if not addon.editMode or InCombatLockdown() or UnitAffectingCombat("player") then return end
    self:FinishDrags()
    addon.Positioning:Refresh()
    if addon.UpdateEditWindowBounds then addon:UpdateEditWindowBounds() end
    self:NotifyPosition()
end
