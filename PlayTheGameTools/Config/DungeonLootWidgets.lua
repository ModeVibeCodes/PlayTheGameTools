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
local PALETTES={header={{159,204,250},{9,116,241}},boss={{248,61,92},{253,75,47}},quest={{250,218,94},{250,242,223}},npc={{245,247,250},{160,168,180}}}
function UI.Gradient(text,kind)
    local colors=kind=="bracket" and {PALETTES.header[2],PALETTES.header[1]} or PALETTES[kind] or PALETTES.header
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
function UI.ClassesText(q)
    local names={}
    for _,token in ipairs(q.classes or {}) do names[#names+1]=UI.ClassText(token) end
    return #names>0 and table.concat(names,", ") or UI.ClassText(q.classOnly)
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
            local button = W.Button(control, "", 300, 38, "row")
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
        if slot.copyButton then slot.copyButton:Hide() end
        slot.button:ClearAllPoints();slot.button:SetAllPoints(slot.control)
        slot.button:Show(); slot.icon:Hide(); slot.subtitle:Hide(); UI.Factions(slot.button)
        for _,glow in ipairs(slot.headerGlow or {}) do glow:Hide() end
        for _, cell in ipairs(slot.cells) do cell:Hide() end
        if slot.questProgress then slot.questProgress:Hide() end
        if slot.headingLine then slot.headingLine:Hide() end
        if slot.art then slot.art:Hide(); slot.topBand:Hide(); slot.bottomBand:Hide() end
        return slot
    end
    function pool:Add(text, callback, item, color, icon, options)
        options = options or {}
        local slot = self:Row()
        slot.callback, slot.item, slot.expandedItem = callback, item, options.expandedItem == true
        local button = slot.button
        button.label:SetJustifyH("LEFT");button.label:SetJustifyV("TOP");button.label:SetWordWrap(true)
        button.label:ClearAllPoints(); button.label:SetPoint("TOPLEFT", item and 48 or 12, item and -10 or -12)
        local factionWidth = UI.Factions(button, options.faction)
        button.label:SetPoint("TOPRIGHT", -12-factionWidth, item and -10 or -12)
        button.label:SetText((options.heading or options.gradient) and UI.Gradient(text,options.gradient) or text); button:SetLabelColor(color or T.text)
        button:SetSelected(options.selected == true)
        addon.Media:BindInterfaceFont(button.label, GameFontHighlight, options.heading and 16 or (options.subheader and 14 or (options.expandedItem and 14 or 12)))
        button:EnableMouse(callback ~= nil or item ~= nil)
        button.fill:SetShown(callback ~= nil or item ~= nil); button.outline:SetShown(callback ~= nil or item ~= nil)
        if item or options.portrait then
            slot.icon:SetSize(options.portrait and (options.compact and 40 or 64) or 28, options.portrait and (options.compact and 40 or 64) or 28)
            slot.icon:ClearAllPoints(); slot.icon:SetPoint("TOPLEFT", 10, -10)
            if options.portrait then UI.Portrait(slot.icon, options.portrait) else slot.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark") end
            slot.icon:Show()
            if options.portrait then button.label:ClearAllPoints();button.label:SetPoint("TOPLEFT", options.compact and 60 or 86, options.compact and -10 or -24);button.label:SetPoint("TOPRIGHT", -12, options.compact and -10 or -24) end
        end
        if options.heading or options.subheader then
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
        -- Modest line leading with tighter surrounding padding in quest detail.
        local questDetail=module.view.tab=="quests" and page==module.page.detailPane
        button.label:SetSpacing(questDetail and 4 or 0)
        slot.subtitle:SetSpacing(questDetail and 4 or 0)
        for _,glow in ipairs(slot.headerGlow or {}) do glow:SetSpacing(questDetail and 4 or 0) end
        slot.row.gapAfter=questDetail and 2 or 4
        local questText=questDetail and not item and not options.portrait
        slot.control:ClearAllPoints()
        slot.control:SetPoint("TOPLEFT",slot.row,"TOPLEFT",0,questText and 0 or -4)
        slot.control:SetPoint("BOTTOMRIGHT",slot.row,"BOTTOMRIGHT",0,questText and 0 or 4)
        if questText then
            for index,texture in ipairs(button.factionIcons or {}) do
                texture:ClearAllPoints();texture:SetPoint("TOPRIGHT",-10-(index-1)*28,-4)
            end
            button.label:ClearAllPoints();button.label:SetPoint("TOPLEFT",12,-4);button.label:SetPoint("TOPRIGHT",-12-factionWidth,-4)
        end
        if options.underline then
            slot.headingLine=slot.headingLine or button:CreateTexture(nil,"OVERLAY")
            slot.headingLine:SetColorTexture(1,1,1,1)
            slot.headingLine:SetGradient("HORIZONTAL",CreateColor(9/255,116/255,241/255,.5),CreateColor(159/255,204/255,250/255,.08))
            slot.headingLine:ClearAllPoints();slot.headingLine:SetPoint("BOTTOMLEFT",12,1);slot.headingLine:SetPoint("BOTTOMRIGHT",-12,1);slot.headingLine:SetHeight(1);slot.headingLine:Show()
        end
        slot.subtitle:SetText(options.subtitle or "")
        slot.subtitle:ClearAllPoints(); slot.subtitle:SetPoint("TOPLEFT", button.label, "BOTTOMLEFT", 0, -6);slot.subtitle:SetPoint("TOPRIGHT", button.label, "BOTTOMRIGHT", 0, -6)
        slot.subtitle:SetShown(options.subtitle ~= nil)
        function slot.row:layoutChildren(width)
            button.label:SetWidth(math.max(80, width - (options.portrait and (options.compact and 76 or 104) or (item and 64 or 28)) - factionWidth))
            local padding=questText and (options.subheader and 8 or 6) or 32
            local height = button.label:GetStringHeight() + padding
            if options.subtitle then height = height + slot.subtitle:GetStringHeight() + 6 end
            self:SetHeight(math.max(options.portrait and (options.compact and 68 or 90) or (item and 54 or (questText and (options.heading and 28 or 18) or (options.heading and 40 or (options.subtitle and 56 or 40)))), height + (item and 8 or 0)))
        end
        return slot
    end
    function pool:MapAction(target,kind,callback)
        local slot=self:Add("View on Map",callback)
        local button=slot.button
        slot.mapKind=kind
        button:ClearAllPoints();button:SetPoint("TOPLEFT",12,-2);button:SetSize(128,28)
        button.label:ClearAllPoints();button.label:SetAllPoints(button);button.label:SetJustifyH("CENTER");button.label:SetJustifyV("MIDDLE");button.label:SetSpacing(0)
        if not slot.copyButton then slot.copyButton=W.Button(slot.control,"Copy Coordinates",128,28) end
        slot.copyButton:ClearAllPoints();slot.copyButton:SetPoint("TOPLEFT",button,"TOPRIGHT",8,0)
        slot.copyButton:SetScript("OnClick",function() if module.active then module:ShowCoordinates(target) end end)
        slot.copyButton:Show()
        function slot.row:layoutChildren(width)
            -- Stack the two compact actions on narrow detail panes.
            slot.copyButton:ClearAllPoints()
            if width<292 then slot.copyButton:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-6);self:SetHeight(70)
            else slot.copyButton:SetPoint("TOPLEFT",button,"TOPRIGHT",8,0);self:SetHeight(36) end
        end
        return slot
    end
    function pool:Stages(stages,selected,callback)
        local slot=self:Add("")
        slot.button:Hide()
        for index,stage in ipairs(stages) do
            local id=stage.id
            local b=slot.cells[index] or W.Button(slot.control,"",72,26)
            slot.cells[index]=b;b.label:SetText("Stage "..index);b:SetSelected(id==selected)
            b:SetScript("OnClick",function() if module.active then callback(id) end end);b:Show()
        end
        function slot.row:layoutChildren(width)
            local columns=math.max(1,math.floor((width-24)/78))
            for index=1,#stages do
                local b=slot.cells[index];b:ClearAllPoints();b:SetSize(72,26)
                b:SetPoint("TOPLEFT",12+((index-1)%columns)*78,-2-math.floor((index-1)/columns)*30)
            end
            self:SetHeight(math.ceil(#stages/columns)*30+4)
        end
    end
    function pool:Dungeon(data, callback)
        local card = data.card
        local slot = self:Add(data.name, callback, nil, T.text, nil, { heading = true, faction = card.faction })
        if not slot.art then
            slot.art = slot.button:CreateTexture(nil, "BACKGROUND", nil, 1)
            slot.art:SetAllPoints(slot.button)
            slot.topBand = W.Fill(slot.button, T.background, "ARTWORK", 0, 0.55)
            slot.bottomBand = W.Fill(slot.button, T.background, "ARTWORK", 0, 0.55)
            slot.questProgress=W.Label(slot.button,"",nil,14,-50,400,T.text)
            slot.questProgress:SetPoint("TOPRIGHT",-14,-50)
            slot.questProgress:SetJustifyV("TOP");slot.questProgress:SetWordWrap(true)
            slot.questProgress:SetShadowColor(0,0,0,1);slot.questProgress:SetShadowOffset(1,-1)
        end
        slot.art:ClearAllPoints();slot.art:SetTexture(card.art)
        if card.iconOnly then
            slot.art:SetSize(64,64);slot.art:SetPoint("CENTER",0,0);slot.art:SetTexCoord(0,1,0,1)
        else slot.art:SetAllPoints(slot.button);slot.art:SetTexCoord(unpack(card.crop)) end
        slot.art:SetShown(card.art~=nil)
        slot.topBand:ClearAllPoints();slot.topBand:SetPoint("TOPLEFT");slot.topBand:SetPoint("TOPRIGHT");slot.topBand:SetHeight(34);slot.topBand:Show()
        slot.bottomBand:ClearAllPoints();slot.bottomBand:SetPoint("BOTTOMLEFT");slot.bottomBand:SetPoint("BOTTOMRIGHT");slot.bottomBand:SetHeight(44);slot.bottomBand:Show()
        addon.Media:BindInterfaceFont(slot.button.label, GameFontHighlight, 20)
        for _,glow in ipairs(slot.headerGlow or {}) do local face=slot.button.label:GetFont();glow:SetFont(face,20,"OUTLINE") end
        slot.button.label:SetJustifyH("CENTER");slot.button.label:SetJustifyV("MIDDLE");slot.button.label:SetWordWrap(false)
        for _,glow in ipairs(slot.headerGlow or {}) do glow:Hide() end
        slot.questProgress:ClearAllPoints();slot.questProgress:SetPoint("BOTTOMRIGHT",-14,8)
        slot.questProgress:SetJustifyH("RIGHT");slot.questProgress:SetJustifyV("BOTTOM")
        addon.Media:BindInterfaceFont(slot.questProgress,GameFontHighlight,14)
        slot.subtitle:ClearAllPoints();slot.subtitle:SetPoint("BOTTOMLEFT",14,8)
        local counts=data.available and (data.bossCount.." bosses"..(data.rareCount>0 and (" + "..data.rareCount.." rare") or "").." · "..
            (data.questCountKnown==false and "Quests not recorded" or ((data.questState and data.questState.known and data.questState.total or "?").." quests"))) or
            (data.previewOnly and "Data not available yet" or "Loot and quests unavailable")
        local progress=""
        local state=data.questState
        if data.available and data.questCountKnown~=false and state then
            local tint=state.inLog==state.total and state.total>0 and "|cff79d98c" or (state.inLog>0 and "|cffFADA5E" or "|cff9fccfa")
            if not state.known then progress="|cff9fccfaQuest eligibility unavailable|r"
            elseif state.completionKnown and state.total>0 and state.completed==state.total then progress="|cff79d98cAll quests completed|r"
            elseif not state.logKnown then progress="|cff9fccfaQuest log unavailable · "..state.total.." possible|r"
            else progress=tint.."You have "..state.inLog.."/"..state.total.." possible quests|r" end
            if state.known and state.classTotal>0 and state.completed~=state.total then
                progress=progress.."\n"..UI.ClassText(module.data.player.class).." quests: "..
                    (state.logKnown and (state.classInLog.."/"..state.classTotal.." in log") or (state.classTotal.." possible"))
            end
            if state.known and state.completionKnown and state.completed>0 and state.completed<state.total then
                progress=progress.."\n|cff79d98c"..state.completed.."/"..state.total.." completed|r"
            end
        end
        slot.subtitle:SetText(card.suggestedLevel.." · "..data.location.."\n"..counts);slot.subtitle:Show()
        slot.questProgress:SetText(progress);slot.questProgress:SetShown(progress~="")
        function slot.row:layoutChildren(width)
            local footerWidth=math.max(80,(width-40)*.5)
            slot.questProgress:ClearAllPoints();slot.questProgress:SetPoint("BOTTOMRIGHT",-14,8)
            slot.subtitle:ClearAllPoints();slot.subtitle:SetPoint("BOTTOMLEFT",14,8)
            slot.questProgress:SetWidth(footerWidth);slot.subtitle:SetWidth(footerWidth)
            local height=math.max(slot.questProgress:GetStringHeight(),slot.subtitle:GetStringHeight())+16
            if width<560 and progress~="" then
                slot.questProgress:SetWidth(math.max(80,width-28));slot.subtitle:SetWidth(math.max(80,width-28))
                slot.subtitle:ClearAllPoints();slot.subtitle:SetPoint("BOTTOMLEFT",slot.questProgress,"TOPLEFT",0,8)
                height=slot.questProgress:GetStringHeight()+slot.subtitle:GetStringHeight()+24
            end
            slot.bottomBand:SetHeight(math.max(44,height))
            self:SetHeight(math.max(180,height+70))
            local iconCount=0;for _,icon in ipairs(slot.button.factionIcons or {}) do if icon:IsShown() then iconCount=iconCount+1 end end
            local nameWidth=math.min(slot.button.label:GetStringWidth(),math.max(60,width-40-iconCount*28))
            local groupWidth=nameWidth+(iconCount>0 and (8+iconCount*24+(iconCount-1)*4) or 0)
            slot.button.label:ClearAllPoints();slot.button.label:SetSize(nameWidth,30)
            slot.button.label:SetPoint("CENTER",slot.topBand,"CENTER",-(groupWidth-nameWidth)*.5,0)
            for index,glow in ipairs(slot.headerGlow or {}) do
                local offsets={{-1,0},{1,0},{0,-1},{0,1}}
                glow:ClearAllPoints();glow:SetSize(nameWidth,30);glow:SetPoint("CENTER",slot.button.label,"CENTER",offsets[index][1],offsets[index][2])
                glow:SetJustifyH("CENTER");glow:SetJustifyV("MIDDLE");glow:SetWordWrap(false);glow:Show()
            end
            local n=0
            for _,icon in ipairs(slot.button.factionIcons or {}) do if icon:IsShown() then
                icon:ClearAllPoints();icon:SetPoint("LEFT",slot.button.label,"RIGHT",8+n*28,0);n=n+1
            end end
        end
        return slot
    end
    return pool
end

-- Clipboard writes are not available to ordinary addon code. A focused native
-- edit box lets the player copy with Ctrl+C without protected API workarounds.
function addon.DungeonLoot:ShowCoordinates(target)
    local frame=self.coordinateFrame
    if not frame then
        frame=CreateFrame("Frame",nil,self.page)
        frame:SetSize(340,126);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(self.page:GetFrameLevel()+100);frame:EnableMouse(true)
        W.Texture(frame,"Window")
        local title=W.Label(frame,"Copy Coordinates",nil,12,-10,310,T.text)
        frame.hint=W.Label(frame,"Press Ctrl+C to copy; Escape to close.",nil,12,-78,310,T.muted)
        local edit=CreateFrame("EditBox",nil,frame)
        edit:SetPoint("TOPLEFT",12,-38);edit:SetPoint("TOPRIGHT",-12,-38);edit:SetHeight(28)
        edit:SetFontObject(GameFontHighlight);edit:SetAutoFocus(false);edit:SetTextInsets(6,6,0,0)
        W.Texture(edit,"InputField")
        edit:SetScript("OnEscapePressed",function() frame:Hide() end)
        edit:SetScript("OnEnterPressed",function() frame:Hide() end)
        edit:SetScript("OnEditFocusGained",function(box) box:HighlightText() end)
        edit:SetScript("OnMouseUp",function(box) box:HighlightText() end)
        frame:SetScript("OnHide",function() edit:ClearFocus() end)
        local close=W.Button(frame,"Close",58,22);close:SetPoint("BOTTOMRIGHT",-10,8)
        close:SetScript("OnClick",function() frame:Hide() end)
        frame.edit=edit;self.coordinateFrame=frame
    end
    local name="Map "..target.mapID
    if C_Map and type(C_Map.GetMapInfo)=="function" then
        local ok,info=pcall(C_Map.GetMapInfo,target.mapID)
        if ok and type(info)=="table" and type(info.name)=="string" then name=info.name end
    end
    -- Copy the selected planning point, not the player's current position.
    frame.edit:SetText(string.format("%s: %.1f, %.1f",name,target.x*100,target.y*100))
    frame:Show();frame.edit:SetFocus();frame.edit:HighlightText()
end
