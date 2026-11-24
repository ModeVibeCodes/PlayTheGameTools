local _, addon = ...
local D = {}
addon.CombatTimerDisplay = D

-- Presentation only: no clock, events, enable state or position persistence.
-- Always plain MM:SS. An older saved appearance.format (square/round brackets)
-- may remain in profiles; it is no longer read.
function D.Format(seconds)
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
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
    addon.Media:PaintSurface(view.background,appearance.backgroundColor,appearance.backgroundOpacity,"combatTimer")
    if not view.globalBorder then view.globalBorder={};addon.Border.Create(view.globalBorder,view.frame) end
    local border = appearance.layoutBackground == false and "none" or addon.Media:GlobalStyle("border","combatTimer")
    addon.Border.Apply(view.globalBorder,{borderStyle=border,borderColor={1,1,1},borderOpacity=1,inset=true})
    addon.Border.Render(view.globalBorder)
end
