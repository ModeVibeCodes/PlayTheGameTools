local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme

-- Ordinary addon-owned menu with a fixed width and bounded scrolling viewport.
local function MediaDropdown(parent, timer, border)
    local statusbar=border=="statusbar"
    border=border==true
    local button = W.Button(parent, "", 260, 30)
    button:SetPoint("LEFT")
    button.label:SetWidth(232)
    button.label:SetJustifyH("CENTER")
    local menu = W.Popup(button,280,224)
    W.Texture(menu, "Window")
    W.Texture(menu, "BorderSilver", "BORDER")
    local scroll = CreateFrame("ScrollFrame", nil, menu)
    scroll:SetPoint("TOPLEFT", 12, -12)
    scroll:SetPoint("BOTTOMRIGHT", -28, 12)
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(240, 1)
    scroll:SetScrollChild(content)
    local bar = CreateFrame("Slider", nil, menu)
    bar:SetPoint("TOPRIGHT", -12, -12)
    bar:SetPoint("BOTTOMRIGHT", -12, 12)
    bar:SetWidth(8)
    bar:SetOrientation("VERTICAL")
    bar:SetValueStep(30)
    W.ScrollThumb(bar, 28)
    bar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    scroll:SetScript("OnMouseWheel", function(_, delta) bar:SetValue(bar:GetValue() - delta * 30) end)
    local rows = {}
    local function Refresh()
        local a = timer.db.appearance
        local media = a.fontMedia or ""
        if statusbar then
            local style=a.barTexture
            button.label:SetText(addon.Media:MediaLabel(style=="default" and "Play The Game Tools Default" or style:sub(7)))
        elseif border then
            local style = timer.db.display.icon.borderStyle
            local label = style == "none" and "None" or style == "thin" and "Play The Game Tools Thin" or style:sub(7)
            button.label:SetText(addon.Media:MediaLabel(label))
        elseif media=="builtin:game" or media=="builtin:chat" then
            button.label:SetText(media=="builtin:chat" and "Chat font" or "Game font")
        elseif media=="" and a.font=="game" then
            button.label:SetText("Use Global Setting")
        else
            button.label:SetText(addon.Media:MediaLabel(media~="" and media or (a.font=="chat" and "Chat font" or "Game font")))
        end
        if not menu:IsShown() then return end
        W.PlacePopup(menu,button)
        local choices = statusbar and addon.Media:GetStatusBars() or border and addon.Media:GetBorders() or timer:GetFonts()
        if not statusbar and not border then table.insert(choices,1,{key="global",label="Use Global Setting"}) end
        for index, choice in ipairs(choices) do
            local row = rows[index]
            if not row then
                row = W.Button(content, "", 240, 28, "tab")
                row:SetPoint("TOPLEFT", 0, -(index - 1) * 30)
                row.label:SetWidth(220)
                row.label:SetJustifyH("LEFT")
                rows[index] = row
                row:SetScript("OnClick", function()
                    local item = row.choice
                    if statusbar then timer:SetAppearance("barTexture",item.key)
                    elseif border then timer:SetComponent("icon", "borderStyle", item.key)
                    elseif item.key=="global" then
                        timer:SetAppearance("font","game");timer:SetAppearance("fontMedia","")
                    elseif item.media then timer:SetAppearance("fontMedia", item.media)
                    else timer:SetAppearance("font", item.key);timer:SetAppearance("fontMedia","builtin:"..item.key) end
                    menu:Hide()
                    Refresh()
                end)
            end
            row.choice = choice
            row.label:SetText(addon.Media:MediaLabel(choice.label))
            local fontSelected=choice.media and media==choice.media
                or choice.key=="global" and media=="" and a.font=="game"
                or choice.key=="game" and media=="builtin:game"
                or choice.key=="chat" and (media=="builtin:chat" or media=="" and a.font=="chat")
            row:SetSelected(statusbar and a.barTexture==choice.key or border and timer.db.display.icon.borderStyle == choice.key
                or not statusbar and not border and fontSelected or false)
            row:Show()
        end
        for index = #choices + 1, #rows do rows[index]:Hide() end
        content:SetHeight(#choices * 30)
        local maximum = math.max(0, content:GetHeight() - 200)
        bar:SetMinMaxValues(0, maximum)
        bar:SetValue(math.min(bar:GetValue(), maximum))
        bar:SetShown(maximum > 0)
    end
    button:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide(); return end
        if not button:IsEnabled() or not timer:CanConfigure() then return end
        if addon.CloseFontDropdown then addon:CloseFontDropdown() end
        W.PlacePopup(menu,button)
        menu:Show()
        bar:SetValue(0)
        Refresh()
    end)
    button:SetScript("OnHide", function() menu:Hide() end)
    addon.fontDropdownMenus = addon.fontDropdownMenus or {}
    addon.fontDropdownMenus[menu] = true
    function addon:CloseFontDropdown()
        for dropdown in pairs(self.fontDropdownMenus) do dropdown:Hide() end
    end
    menu:SetScript("OnHide", function() bar:SetValue(0) end)
    button.menu, button.rows, button.scrollbar = menu, rows, bar
    if statusbar then addon.Media:RegisterStatusBarListener(button,function() Refresh() end)
    elseif border then addon.Media:RegisterBorderListener(button, function() Refresh() end)
    else addon.Media:RegisterFontListener(button, function() Refresh() end) end
    return button, Refresh
end

function W.FontDropdown(parent, timer) return MediaDropdown(parent, timer, false) end
function W.BorderDropdown(parent, timer) return MediaDropdown(parent, timer, true) end
function W.StatusBarDropdown(parent,timer) return MediaDropdown(parent,timer,"statusbar") end
