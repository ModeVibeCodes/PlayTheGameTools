local _, addon = ...
local W = addon.ConfigWidgets

-- Module pages have no section tabs: each is one scroll (Config/Pages.lua).
-- What remains is the capsule pill layout of the Dungeon Loot browser's own
-- navigation (Config/DungeonLoot.lua).

function W.FitModeTab(button,width)
    local available=math.max(1,width-16)
    button.label:SetWordWrap(false);button.label:SetWidth(0)
    addon.Media:BindInterfaceFont(button.label,GameFontHighlight,12)
    local measured=button.label:GetStringWidth()
    if not (issecretvalue and issecretvalue(measured)) and type(measured)=="number" and measured==measured and measured>available and measured<math.huge then
        addon.Media:BindInterfaceFont(button.label,GameFontHighlight,math.max(8,12*available/measured))
    end
    button.label:SetWidth(available)
    if button.selectionEdge then W.AlignTextLine(button,button.selectionEdge) end
end

-- The capsule export is 4:1. Keep that aspect ratio instead of stretching its
-- round ends into ellipses when there are only two or three pills.
function W.LayoutModePills(buttons,available)
    if available<64 or #buttons==0 then return end
    local gap=8
    local width=math.min(128,math.max(1,(available-24-gap*(#buttons-1))/#buttons))
    local height=width/4
    local start=(available-width*#buttons-gap*(#buttons-1))/2
    for i,button in ipairs(buttons) do
        local x=start+(i-1)*(width+gap)
        button:ClearAllPoints();button:SetPoint("TOPLEFT",x,(height-36)/2);button:SetSize(width,height)
        W.FitModeTab(button,width)
        button.tabX,button.tabWidth=x,width
    end
    return width
end
