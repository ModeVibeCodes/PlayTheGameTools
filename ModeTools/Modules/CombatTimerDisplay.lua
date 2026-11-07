local _, addon = ...
local D = {}
addon.CombatTimerDisplay = D

-- Presentation only: no clock, events, enable state or position persistence.
function D.Format(seconds, format)
    local value = string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
    if format == "square" then return "[" .. value .. "]" end
    if format == "round" then return "(" .. value .. ")" end
    return value
end

function D.Apply(view, appearance, layout)
    if layout ~= false then
        local flags = appearance.outline and "OUTLINE" or ""
        local path = addon.Media:GetDisplayFont(appearance)
        if not view.text:SetFont(path, appearance.fontSize, flags) then
            view.text:SetFont(GameFontHighlight:GetFont(), appearance.fontSize, flags)
        end
        view.frame:SetSize(math.max(96, appearance.fontSize * 7), appearance.fontSize + 16)
        view.frame:SetScale(appearance.scale)
    end
    view.text:SetTextColor(appearance.textColor[1], appearance.textColor[2], appearance.textColor[3], 1)
    view.background:SetColorTexture(appearance.backgroundColor[1], appearance.backgroundColor[2], appearance.backgroundColor[3], appearance.backgroundOpacity)
end
