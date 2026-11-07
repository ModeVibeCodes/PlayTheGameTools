local _, addon = ...
local W, T = addon.ConfigWidgets, addon.InterfaceTheme
local UI = {}
addon.DungeonLootWidgets = UI
local FACTIONS = { Alliance = "Interface\\TargetingFrame\\UI-PVP-Alliance", Horde = "Interface\\TargetingFrame\\UI-PVP-Horde" }

function UI.Factions(host, faction)
    host.factionIcons = host.factionIcons or {}
    local factions = faction == "Both" and { "Alliance", "Horde" } or { faction }
    for _, texture in ipairs(host.factionIcons) do texture:Hide() end
    local count = 0
    for _, name in ipairs(factions) do
        if FACTIONS[name] then
            count = count + 1
            local texture = host.factionIcons[count] or host:CreateTexture(nil, "OVERLAY")
            host.factionIcons[count] = texture
            texture:SetTexture(FACTIONS[name]); texture:SetTexCoord(0, 0.6, 0, 0.6)
            texture:SetSize(24, 24); texture:ClearAllPoints(); texture:SetPoint("TOPRIGHT", -10 - (count-1)*28, -10)
            texture:Show()
        end
    end
    return count * 28
end
function UI.Portrait(texture, entry)
    texture:SetTexCoord(0, 1, 0, 1)
    texture:SetTexture("Interface\\EncounterJournal\\UI-EJ-BOSS-Default")
    if entry.displayID and type(SetPortraitTextureFromCreatureDisplayID) == "function" then
        local ok = pcall(SetPortraitTextureFromCreatureDisplayID, texture, entry.displayID)
        if not ok then texture:SetTexture("Interface\\EncounterJournal\\UI-EJ-BOSS-Default") end
    elseif entry.icon then texture:SetTexture(entry.icon) end
end
local function Hex(r,g,b) return string.format("%02x%02x%02x",math.floor(r*255+.5),math.floor(g*255+.5),math.floor(b*255+.5)) end
local PALETTES={header={{159,204,250},{9,116,241}},boss={{248,61,92},{253,75,47}},quest={{250,218,94},{250,242,223}}}
function UI.Gradient(text,kind)
    local colors=PALETTES[kind] or PALETTES.header
    local chars={};for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars+1]=char end
    local out={}
    for index,char in ipairs(chars) do
        local t=(index-1)/math.max(1,#chars-1)
        local r,g,b
        r=(colors[1][1]+(colors[2][1]-colors[1][1])*t)/255
        g=(colors[1][2]+(colors[2][2]-colors[1][2])*t)/255
        b=(colors[1][3]+(colors[2][3]-colors[1][3])*t)/255
        out[index]="|cff"..Hex(r,g,b)..char.."|r"
    end
    return table.concat(out)
end
function UI.ClassText(token)
    if not token then return "All classes" end
    local name=LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] or (token:sub(1,1)..token:sub(2):lower())
    local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    return c and ("|cff"..Hex(c.r,c.g,c.b)..name.."|r") or name
end
function UI.New(page, module)
    local pool = { page = page, module = module, used = 0 }
    page.slots = {}
    function pool:Reset()
        self.used = 0
        for _, slot in ipairs(page.slots) do slot.visible = false; slot.item = nil; slot.callback = nil; slot.mapKind=nil end
    end
    function pool:Row()
        self.used = self.used + 1
        local slot = page.slots[self.used]
        if not slot then
            local control = page:Row("", 44)
            control.rowLabel:Hide(); control.row.divider:Hide(); control:ClearAllPoints()
            control:SetPoint("TOPLEFT", control.row, "TOPLEFT", 0, -4); control:SetPoint("BOTTOMRIGHT", control.row, "BOTTOMRIGHT", 0, 4)
            local button = W.Button(control, "", 300, 38)
            button:SetAllPoints(control); button.label:SetJustifyH("LEFT"); button.label:SetJustifyV("TOP");button.label:SetWordWrap(true)
            local icon = button:CreateTexture(nil, "ARTWORK")
            local subtitle = W.Label(button, "", nil, 12, -36, 280, T.secondary)
            subtitle:SetWordWrap(true);subtitle:SetJustifyV("TOP")
            slot = { control = control, row = control.row, button = button, icon = icon, subtitle = subtitle, cells = {} }
            page.slots[self.used] = slot
            control.row.visibleWhen = function() return slot.visible end
            button:SetScript("OnClick", function() if slot.callback and module.active then slot.callback() end end)
            button:HookScript("OnEnter", function(owner)
                if slot.item and module.active and GameTooltip then
                    module:HideTooltip(); module.tooltipOwner = owner
                    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink("item:" .. slot.item.id); GameTooltip:Show()
                end
            end)
            button:HookScript("OnLeave", function(owner) if module.tooltipOwner == owner then module:HideTooltip() end end)
        end
        slot.visible = true
        slot.button:ClearAllPoints();slot.button:SetAllPoints(slot.control)
        slot.button:Show(); slot.icon:Hide(); slot.subtitle:Hide(); UI.Factions(slot.button)
        for _,glow in ipairs(slot.headerGlow or {}) do glow:Hide() end
        for _, cell in ipairs(slot.cells) do cell:Hide() end
        if slot.art then slot.art:Hide(); slot.topBand:Hide(); slot.bottomBand:Hide() end
        return slot
    end
    function pool:Add(text, callback, item, color, icon, options)
        options = options or {}
        local slot = self:Row()
        slot.callback, slot.item, slot.expandedItem = callback, item, options.expandedItem == true
        local button = slot.button
        button.label:SetJustifyH("LEFT");button.label:SetJustifyV("TOP")
        button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", item and 48 or 12, item and -10 or -12)
        local factionWidth = UI.Factions(button, options.faction)
        button.label:SetPoint("TOPRIGHT", -12-factionWidth, item and -10 or -12)
        button.label:SetText((options.heading or options.gradient) and UI.Gradient(text,options.gradient) or text); button:SetLabelColor(color or T.text)
        button:SetSelected(options.selected == true)
        addon.Media:BindInterfaceFont(button.label, GameFontHighlight, options.heading and 16 or (options.expandedItem and 14 or 12))
        button:EnableMouse(callback ~= nil or item ~= nil)
        button.fill:SetShown(callback ~= nil or item ~= nil); button.outline:SetShown(callback ~= nil or item ~= nil)
        if item or options.portrait then
            slot.icon:SetSize(options.portrait and (options.compact and 40 or 64) or 28, options.portrait and (options.compact and 40 or 64) or 28)
            slot.icon:ClearAllPoints(); slot.icon:SetPoint("TOPLEFT", 10, -10)
            if options.portrait then UI.Portrait(slot.icon, options.portrait) else slot.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark") end
            slot.icon:Show()
            if options.portrait then button.label:ClearAllPoints();button.label:SetPoint("TOPLEFT", options.compact and 60 or 86, options.compact and -10 or -24);button.label:SetPoint("TOPRIGHT", -12, options.compact and -10 or -24) end
        end
        if options.heading then
            slot.headerGlow=slot.headerGlow or {}
            local offsets={{-1,0},{1,0},{0,-1},{0,1}}
            local face,size=button.label:GetFont()
            for index,offset in ipairs(offsets) do
                local glow=slot.headerGlow[index] or button:CreateFontString(nil,"ARTWORK","GameFontHighlight")
                slot.headerGlow[index]=glow
                glow:SetFont(face,size,"OUTLINE");glow:SetAlpha(.12);glow:SetJustifyH("LEFT");glow:SetJustifyV("TOP");glow:SetWordWrap(true)
                glow:ClearAllPoints();glow:SetPoint("TOPLEFT",button.label,"TOPLEFT",offset[1],offset[2]);glow:SetPoint("TOPRIGHT",button.label,"TOPRIGHT",offset[1],offset[2])
                glow:SetText(button.label:GetText());glow:Show()
            end
        end
        slot.subtitle:SetText(options.subtitle or "")
        slot.subtitle:ClearAllPoints(); slot.subtitle:SetPoint("TOPLEFT", button.label, "BOTTOMLEFT", 0, -6);slot.subtitle:SetPoint("TOPRIGHT", button.label, "BOTTOMRIGHT", 0, -6)
        slot.subtitle:SetShown(options.subtitle ~= nil)
        function slot.row:layoutChildren(width)
            button.label:SetWidth(math.max(80, width - (options.portrait and (options.compact and 76 or 104) or (item and 64 or 28)) - factionWidth))
            local height = button.label:GetStringHeight() + 32
            if options.subtitle then height = height + slot.subtitle:GetStringHeight() + 6 end
            self:SetHeight(math.max(options.portrait and (options.compact and 68 or 90) or (item and 54 or (options.heading and 40 or (options.subtitle and 56 or 40))), height + (item and 8 or 0)))
        end
        return slot
    end
    function pool:MapAction(target,kind,callback)
        local slot=self:Add("View on Map",callback)
        local button=slot.button
        slot.mapKind=kind
        button:ClearAllPoints();button:SetPoint("TOPLEFT",12,-4);button:SetSize(128,28)
        button.label:ClearAllPoints();button.label:SetAllPoints(button);button.label:SetJustifyH("CENTER");button.label:SetJustifyV("MIDDLE")
        slot.subtitle:ClearAllPoints();slot.subtitle:SetPoint("TOPLEFT",button,"TOPRIGHT",10,0)
        slot.subtitle:SetPoint("TOPRIGHT",slot.control,"TOPRIGHT",-12,-4)
        slot.subtitle:SetText(target.label..(#target.paths>0 and " · Patrol" or ""));slot.subtitle:Show()
        function slot.row:layoutChildren(width)
            slot.subtitle:SetWidth(math.max(40,width-174))
            self:SetHeight(math.max(44,slot.subtitle:GetStringHeight()+16))
        end
        return slot
    end
    function pool:Dungeon(data, callback)
        local card = data.card
        local slot = self:Add("Shadowfang Keep", callback, nil, T.text, nil, { heading = true, faction = card.faction })
        if not slot.art then
            slot.art = slot.button:CreateTexture(nil, "BACKGROUND", nil, 1)
            slot.art:SetAllPoints(slot.button)
            slot.topBand = W.Fill(slot.button, T.background, "ARTWORK", 0, 0.86)
            slot.bottomBand = W.Fill(slot.button, T.background, "ARTWORK", 0, 0.88)
        end
        slot.art:SetTexture(card.art);slot.art:SetTexCoord(0.04, 0.96, 0.28, 0.78);slot.art:Show()
        slot.topBand:ClearAllPoints();slot.topBand:SetPoint("TOPLEFT");slot.topBand:SetPoint("TOPRIGHT");slot.topBand:SetHeight(40);slot.topBand:Show()
        slot.bottomBand:ClearAllPoints();slot.bottomBand:SetPoint("BOTTOMLEFT");slot.bottomBand:SetPoint("BOTTOMRIGHT");slot.bottomBand:SetHeight(52);slot.bottomBand:Show()
        addon.Media:BindInterfaceFont(slot.button.label, GameFontHighlight, 20)
        for _,glow in ipairs(slot.headerGlow or {}) do local face=slot.button.label:GetFont();glow:SetFont(face,20,"OUTLINE") end
        slot.subtitle:ClearAllPoints();slot.subtitle:SetPoint("BOTTOMLEFT", 14, 12);slot.subtitle:SetPoint("BOTTOMRIGHT", -14, 12)
        local counts = data.available and (data.bossCount .. " bosses" .. (data.rareCount > 0 and (" + " .. data.rareCount .. " rare") or "") .. "   ·   " .. #data.quests .. " quests") or "Loot and quests unavailable"
        slot.subtitle:SetText("Silverpine Forest · Horde territory\n" .. counts);slot.subtitle:Show()
        function slot.row:layoutChildren(width) self:SetHeight(180);slot.button.label:SetWidth(math.max(80,width-70)) end
        return slot
    end
    return pool
end
