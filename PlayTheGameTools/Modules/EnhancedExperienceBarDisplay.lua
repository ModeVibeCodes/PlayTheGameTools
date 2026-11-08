local _, addon = ...
local M = addon.EnhancedExperienceBar
if not M then return end
local FLAT = "Interface\\Buttons\\WHITE8X8"
function M:CreateDisplay()
    local f = CreateFrame("Frame", "PlayTheGameToolsEnhancedExperienceBar", UIParent, "BackdropTemplate")
    self.frame = f; f:SetSize(self.db.width, self.db.height)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -300); f:SetFrameStrata("MEDIUM")
    self.background = f:CreateTexture(nil, "BACKGROUND"); self.background:SetAllPoints()
    self.xpFill = f:CreateTexture(nil, "ARTWORK", nil, 0)
    self.restedFill = f:CreateTexture(nil, "ARTWORK", nil, 1)
    self.questFill = f:CreateTexture(nil, "ARTWORK", nil, 2)
    self.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.sessionText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    -- Establish native geometry before registering an owned frame.
    f:Show()
    local ok, reason = addon.PositionManager:RegisterElement(self.id, f, {moduleId = self.id,
        defaultPosition = {target = "screen", placement = "center", x = 0, y = -300},
        canDrag = function() return self.active == true end})
    assert(ok, "Play The Game Tools: experience position registration failed: " .. tostring(reason))
    self:ApplyAppearance(); f:Hide()
end
function M:ApplyAppearance()
    if not self.frame or not self:CanConfigure() then return end
    addon.PositionManager:StopDragging(self.id)
    local db, f = self.db, self.frame
    f:SetSize(db.width, db.height); f:SetScale(db.scale / 100); f:SetAlpha(db.opacity / 100)
    f:SetBackdrop({edgeFile = FLAT, edgeSize = 1}); f:SetBackdropBorderColor(unpack(db.borderColor))
    self.background:SetColorTexture(unpack(db.backgroundColor))
    local font = addon.Media:GetDisplayFont(db)
    for _, spec in ipairs({{self.text, db.fontSize}, {self.sessionText, db.sessionFontSize}}) do
        local text, size = spec[1], spec[2]
        if not text:SetFont(font, size, db.outline and "OUTLINE" or "") then
            text:SetFont(GameFontHighlight:GetFont(), size, db.outline and "OUTLINE" or "")
        end
        text:SetTextColor(unpack(db.textColor)); text:SetJustifyH(db.align); text:SetWidth(db.width - 12)
    end
    self.text:ClearAllPoints(); self.text:SetPoint("CENTER", f, "CENTER", 0, db.textOffset)
    self.sessionText:ClearAllPoints()
    self.sessionText:SetPoint(db.sessionAbove and "BOTTOM" or "TOP", f, db.sessionAbove and "TOP" or "BOTTOM",
        0, (db.sessionAbove and 1 or -1) * db.sessionGap)
    addon.PositionManager:ApplyPosition(self.id); self:Render()
end
local function Segment(texture, frame, start, length, y, height, color, alpha, atlas, tint)
    texture:Hide(); if length <= 0 then return end
    texture:ClearAllPoints(); texture:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", start, y); texture:SetSize(length, height)
    local styled = false
    if atlas and C_Texture and M.Read(C_Texture.GetAtlasInfo, atlas) then styled = pcall(texture.SetAtlas, texture, atlas, false) end
    if not styled then texture:SetTexture(FLAT) end
    if styled and not tint then texture:SetVertexColor(1, 1, 1, alpha)
    else texture:SetVertexColor(color[1], color[2], color[3], alpha) end
    texture:Show()
end
function M:RenderSession()
    if not self.sessionText then return end
    local parts, db = {}, self.db
    local seconds = math.max(0, GetTime() - (self.sessionStart or GetTime()))
    if db.showSession then
        parts[#parts + 1] = string.format("Session %02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, math.floor(seconds) % 60)
    end
    if db.showRate then parts[#parts + 1] = string.format("%s%.0f XP/hr", self.sessionIncomplete and "~" or "", seconds > 0 and self.sessionXP * 3600 / seconds or 0) end
    self.sessionText:SetText(table.concat(parts, "  |  ")); self.sessionText:SetShown(self.active and #parts > 0)
end
function M:Render()
    if not self.frame then return end
    if not self.active then self.frame:Hide(); return end
    local db, data = self.db, self:ReadXP()
    local sample = self.preview or self.editing
    if sample then data = {xp = 4200, maximum = 10000, level = 20} end
    if not data or (not sample and db.hideAtMax and data.capped) then self.frame:Hide(); return end
    local maxXP = data.maximum
    local rested, _, readable = self.Read(GetXPExhaustion)
    local restedKnown = readable and (rested == nil or self.Number(rested, 0, 1e12))
    if sample then rested = 3500 end
    if not self.Number(rested, 0, 1e12) then rested = 0 end
    local state = sample and 1 or self.Read(GetRestState)
    local normalColor = db.nativeColors and {0.58, 0, 0.55} or db.normalColor
    local restedColor = db.nativeColors and {0, 0.39, 0.88} or db.restedColor
    local color = state == 1 and restedColor or normalColor
    local width, height = db.width - 2, db.height - 2
    local fraction = maxXP > 0 and math.min(1, data.xp / maxXP) or 0
    local current = fraction * width
    local quests, known = self.questXP or 0, self.questKnown
    if sample then quests, known, restedKnown = 1800, true, true end
    local function Length(amount) return maxXP > 0 and math.max(0, math.min(width - current, amount / maxXP * width)) or 0 end
    local atlas = db.blizzardStyle and (state == 1 and "UI-HUD-ExperienceBar-Fill-Rested" or "UI-HUD-ExperienceBar-Fill-Experience")
    Segment(self.xpFill, self.frame, 1, current, 1, height, color, 1, atlas, not db.nativeColors)
    -- Independent forecasts share the XP origin: upper rested pool, lower quest rewards.
    -- Neither forecast adds to the other; rested bonus does not multiply quest XP.
    Segment(self.restedFill, self.frame, 1 + current, db.showRestedOverlay and not data.disabled and Length(rested) or 0,
        1 + height / 2, height / 2, restedColor, db.overlayOpacity / 100)
    Segment(self.questFill, self.frame, 1 + current, db.showQuestOverlay and not data.disabled and Length(quests) or 0,
        1, height / 2, db.questColor, db.overlayOpacity / 100)
    local parts = {}
    if sample then parts[#parts + 1] = "PREVIEW" end
    if data.capped then parts[#parts + 1] = "Maximum level"
    elseif maxXP > 0 then
        if db.showXP then parts[#parts + 1] = string.format("XP %.1f%%", fraction * 100) end
        if db.showValues then parts[#parts + 1] = string.format("%.0f / %.0f", data.xp, maxXP) end
        if db.showRested then parts[#parts + 1] = restedKnown and string.format("Rested %.1f%%", rested / maxXP * 100) or "Rested unavailable" end
        if db.showQuests then parts[#parts + 1] = string.format("Quests %s%.1f%%%s", known and "+" or ">=", quests / maxXP * 100, known and "" or " (incomplete)") end
    end
    if data.disabled then parts[#parts + 1] = "XP locked" end
    self.text:SetText(table.concat(parts, "  |  ")); self:RenderSession(); self.frame:Show()
end
